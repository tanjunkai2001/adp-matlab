function precision = mf_precision_check(outputDirectory,cfg,batches,gainsOnly)
%MF_PRECISION_CHECK Explicit MC-size check, retaining the same probing signal.
% Pools observed moments, never oracle expectations. Each batch has the
% paper's 100 paths. Full raw paths of the main 100-path run are saved by
% demo_meanfield_lqg2025; here moments plus all generation seeds are retained.
if nargin<2, cfg=mf_config; end
if nargin<3, batches=40; end
if nargin<4, gainsOnly=false; end
if ~exist(outputDirectory,'dir'), mkdir(outputDirectory); end
if exist(fullfile(outputDirectory,'precision.mat'),'file')
    error('mf:PreserveRun','Existing precision evidence is preserved.');
end
diary(fullfile(outputDirectory,'matlab.log'));
guard=onCleanup(@()diary('off')); %#ok<NASGU>
checks=unique([1 4 10 batches]); checks=checks(checks<=batches);
if gainsOnly, checks=batches; end
fields={'second','xu','uu','mean','meanInput'};
fits=cell(numel(checks),1); sizes=zeros(numel(checks),1);
momentCheckpoints=cell(numel(checks),1);
counter=0; seeds=cfg.seed+(0:batches-1);
for j=1:batches
    raw=mf_collect(cfg.plant,cfg.K0,cfg.train,seeds(j));
    d=mf_build_data(raw,cfg.train);
    if j==1
        accum=d.moments;
        cfg.train.frequencies=raw.frequencies;
    else
        for k=1:numel(fields)
            f=fields{k}; accum.(f)=accum.(f)+d.moments.(f);
        end
    end
    if ismember(j,checks)
        pooled=accum;
        for k=1:numel(fields)
            f=fields{k}; pooled.(f)=pooled.(f)/j;
        end
        observed=mf_window_moments(pooled,cfg.train.dt,cfg.train);
        observed.pathCount=j*cfg.train.paths;
        observed.provenance='Pooled independent observed paths with a common probe.';
        counter=counter+1;
        fits{counter}=mf_learn(observed,cfg.cost,cfg.K0,cfg.learn);
        sizes(counter)=observed.pathCount;
        momentCheckpoints{counter}=observed;
        fprintf('MC paths %d: K=%s Ks=%s\n',observed.pathCount, ...
            mat2str(fits{counter}.K,8),mat2str(fits{counter}.Ks,8));
    end
end
ref=mf_reference(cfg.plant,cfg.cost,cfg.K0);
errors=zeros(numel(fits),2); gains=zeros(numel(fits),4);
for j=1:numel(fits)
    errors(j,:)=[norm(fits{j}.K-ref.K)/norm(ref.K),norm(fits{j}.Ks-ref.Ks)/norm(ref.Ks)];
    gains(j,:)=[fits{j}.K fits{j}.Ks];
end
meanfield=[]; evaluation=[];
if ~gainsOnly
    meanfield=mf_mean_trajectory(cfg.plant,fits{end}.K+fits{end}.Ks, ...
        cfg.initialMean,cfg.eval,cfg.meanSeed);
    evaluation=mf_evaluate(cfg.plant,cfg.cost,fits{end},ref,meanfield,cfg.eval,cfg.K0);
end
precision=struct('cfg',cfg,'batchSeeds',seeds,'pathCounts',sizes, ...
    'fits',{fits},'reference',ref,'relativeGainErrors',errors, ...
    'gains',gains,'evaluation',evaluation, ...
    'scope','Nested finite MC precision check; one common probe, not independent error bars or guaranteed monotonic convergence.');
save(fullfile(outputDirectory,'precision.mat'),'precision','momentCheckpoints','meanfield','-v7.3');
writetable(table(sizes,gains(:,1),gains(:,2),gains(:,3),gains(:,4),errors(:,1),errors(:,2), ...
    'VariableNames',{'paths','K1','K2','Ks1','Ks2','relativeKError','relativeKsError'}), ...
    fullfile(outputDirectory,'mc-precision.csv'));
if ~gainsOnly
    writetable(table(evaluation.policyNames.',evaluation.meanCost.',evaluation.standardError.', ...
        'VariableNames',{'policy','meanPerAgentFiniteHorizonCost','populationSE'}), ...
        fullfile(outputDirectory,'cost-comparison.csv'));
    fprintf('Precision study costs: %s; SE: %s\n', ...
        mat2str(evaluation.meanCost,8),mat2str(evaluation.standardError,8));
    f=figure('Visible','off','Color','w','Position',[100 100 1000 400]);
    tiledlayout(1,2,'Padding','loose','TileSpacing','loose');
    nexttile; loglog(sizes,errors,'-o','LineWidth',1.5);
    xlabel('Independent paths, common probe'); ylabel('Relative gain error');
    legend('K','K_s','Location','best'); title('Nested Monte Carlo precision check'); grid on;
    nexttile; errorbar(1:3,evaluation.meanCost,1.96*evaluation.standardError,'o','LineWidth',1.5);
    xticks(1:3); xticklabels({'Learned','Reference','Initial K0'});
    ylabel('Per-agent 0-20 s cost'); title('4000-path gains; 40 agents; 95% error bars');
    exportgraphics(f,fullfile(outputDirectory,'precision.png'),'Resolution',170);
    savefig(f,fullfile(outputDirectory,'precision.fig')); close(f);
end
end
