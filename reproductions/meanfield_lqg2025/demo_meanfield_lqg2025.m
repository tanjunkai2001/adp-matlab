function report = demo_meanfield_lqg2025(outputDirectory,cfg)
%DEMO_MEANFIELD_LQG2025 Executable paper reproduction with observed raw data.
% Run from any folder after adding this method folder to the MATLAB path.
% The learner receives cost/observations only. References are computed later.
if nargin<2, cfg=mf_config; end
if nargin<1 || isempty(outputDirectory)
    root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    outputDirectory=fullfile(root,'runs','meanfield_lqg2025', ...
        ['run-' char(datetime('now','Format','yyyyMMdd-HHmmss-SSS'))]);
end
if isfolder(outputDirectory) || isfile(outputDirectory)
    error('mf:PreserveRun','Choose a new output directory; existing data are preserved.');
end
mkdir(outputDirectory);
diary(fullfile(outputDirectory,'matlab.log'));
guard=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('Automatica 172 (2025) 111924, Algorithm 1\n');
fprintf('Observed Monte Carlo data: %d paths, dt %.4g, %d independent training runs\n', ...
    cfg.train.paths,cfg.train.dt,cfg.train.repeats);
started=tic;
raw=mf_collect(cfg.plant,cfg.K0,cfg.train,cfg.seed);
data=mf_build_data(raw,cfg.train);
learned=mf_learn(data,cfg.cost,cfg.K0,cfg.learn);
save(fullfile(outputDirectory,'training-data.mat'),'cfg','raw','data','learned','-v7.3');
% Refit an independent dataset in every repeat; the first is the main run.
replicateGains=nan(cfg.train.repeats,4);
replicateGains(1,:)=[learned.K learned.Ks];
replicateRecords=cell(cfg.train.repeats,1);
replicateRecords{1}=struct('seed',cfg.seed,'success',true,'learned',learned);
for j=2:cfg.train.repeats
    rawj=mf_collect(cfg.plant,cfg.K0,cfg.train,cfg.seed+j-1);
    dataj=mf_build_data(rawj,cfg.train);
    try
        fit=mf_learn(dataj,cfg.cost,cfg.K0,cfg.learn);
        replicateGains(j,:)=[fit.K fit.Ks];
        replicateRecords{j}=struct('seed',cfg.seed+j-1,'success',true,'learned',fit);
    catch failure
        replicateRecords{j}=struct('seed',cfg.seed+j-1,'success',false, ...
            'identifier',failure.identifier,'message',failure.message);
        fprintf('Training repeat %d rejected: %s: %s\n', ...
            j,failure.identifier,failure.message);
    end
    % Sufficient statistics plus seeds/probes preserve every replicate fit.
    save(fullfile(outputDirectory,sprintf('training-repeat-%02d.mat',j)), ...
        'dataj','-v7');
    fprintf('Training repeat %d: %s\n',j,mat2str(replicateGains(j,:),7));
end
% A failure is visible. Do not silently drop it to form an uncertainty claim.
allSucceeded=all(isfinite(replicateGains(:)));
if allSucceeded
    gainMean=mean(replicateGains,1);
    gainSE=std(replicateGains,0,1)/sqrt(cfg.train.repeats);
else
    gainMean=nan(1,4); gainSE=nan(1,4);
end
ref=mf_reference(cfg.plant,cfg.cost,cfg.K0,learned);
meanfield=mf_mean_trajectory(cfg.plant,learned.K+learned.Ks, ...
    cfg.initialMean,cfg.eval,cfg.meanSeed);
evaluation=mf_evaluate(cfg.plant,cfg.cost,learned,ref,meanfield,cfg.eval,cfg.K0);
F=cfg.plant.A-cfg.plant.B*learned.K;
G=cfg.plant.C-cfg.plant.D*learned.K;
mss=max(real(eig(kron(eye(2),F)+kron(F,eye(2))+kron(G,G))));
meanAbscissa=max(real(eig(cfg.plant.A-cfg.plant.B*(learned.K+learned.Ks))));
% These are simulator-oracle diagnostics, unavailable to the data-only learner.
gainError=[norm(learned.K-ref.K)/norm(ref.K),norm(learned.Ks-ref.Ks)/norm(ref.Ks)];
report=struct('paper',cfg.paper,'config',cfg,'learned',learned,'reference',ref, ...
    'relativeGainError',gainError,'replicateGains',replicateGains, ...
    'replicateGainMean',gainMean,'replicateGainStandardError',gainSE, ...
    'allTrainingRepeatsSucceeded',allSucceeded,'replicateRecords',{replicateRecords}, ...
    'learnedMeanSquareAbscissa',mss,'learnedMeanAbscissa',meanAbscissa, ...
    'evaluation',evaluation,'elapsedSeconds',toc(started), ...
    'matlabVersion',version,'computer',computer, ...
    'evidenceScope','Executed finite-MC reproduction, not an exact-expectation or infinite-N optimality proof.');
save(fullfile(outputDirectory,'results.mat'),'report','meanfield','-v7.3');
writeSummary(outputDirectory,report);
plotResults(outputDirectory,report,meanfield);
fprintf('K learned = %s; K reference = %s\n',mat2str(learned.K,9),mat2str(ref.K,9));
fprintf('Ks learned = %s; Ks reference = %s\n',mat2str(learned.Ks,9),mat2str(ref.Ks,9));
fprintf('Relative gain errors K/Ks = %.4g / %.4g\n',gainError);
fprintf('Mean finite-N costs = %s; population SE = %s\n', ...
    mat2str(evaluation.meanCost,8),mat2str(evaluation.standardError,8));
fprintf('Paired learned-reference cost difference = %.7g +/- %.7g SE\n', ...
    evaluation.pairedLearnedMinusReference,evaluation.pairedStandardError);
fprintf('Elapsed %.2f s. Results: %s\n',report.elapsedSeconds,outputDirectory);
end

function writeSummary(folder,r)
names={'K1';'K2';'Ks1';'Ks2'};
primary=[r.learned.K,r.learned.Ks].';
oracle=[r.reference.K,r.reference.Ks].';
t=table(names,primary,oracle,r.replicateGainMean.',r.replicateGainStandardError.', ...
    'VariableNames',{'parameter','primaryEstimate','modelReference','repeatMean','repeatMeanSE'});
writetable(t,fullfile(folder,'gain-comparison.csv'));
t=table(r.evaluation.policyNames.',r.evaluation.meanCost.',r.evaluation.standardError.', ...
    'VariableNames',{'policy','meanPerAgentFiniteHorizonCost','populationSE'});
writetable(t,fullfile(folder,'cost-comparison.csv'));
fid=fopen(fullfile(folder,'summary.json'),'w');
closer=onCleanup(@()fclose(fid)); %#ok<NASGU>
compact=rmfield(r,{'evaluation'});
compact.evaluation=rmfield(r.evaluation,{'initialStates','terminalStates', ...
    'traceTime','firstPopulationTrace','referenceMean'});
fprintf(fid,'%s\n',jsonencode(compact,'PrettyPrint',true));
end

function plotResults(folder,r,m)
f=figure('Visible','off','Color','w','Position',[100 100 1100 720]);
tiledlayout(2,2,'Padding','loose','TileSpacing','loose');
nexttile;
kh=vertcat(r.learned.history1.K);
plot(0:size(kh,1),[r.config.K0;kh],'-o','LineWidth',1.3);
hold on; yline(r.reference.K(1),'--'); yline(r.reference.K(2),'--');
xlabel('Policy iteration'); ylabel('K'); title('Data-based feedback gain');
legend('K_1','K_2','Location','best');
nexttile;
sh=vertcat(r.learned.history2.Ks);
plot(0:size(sh,1),[0 0;sh],'-o','LineWidth',1.3);
hold on; yline(r.reference.Ks(1),'--'); yline(r.reference.Ks(2),'--');
xlabel('Policy iteration'); ylabel('K_s'); title('Data-based mean-field gain');
legend('K_{s,1}','K_{s,2}','Location','best');
nexttile;
plot(m.t,m.mean,'LineWidth',1.3); hold on;
plot(m.t,r.evaluation.referenceMean,'--','LineWidth',1.1);
xlabel('Time (s)'); ylabel('Mean state');
title('100-path learned mean; model reference dashed');
nexttile;
errorbar(1:3,r.evaluation.meanCost,1.96*r.evaluation.standardError, ...
    'o','LineWidth',1.4,'MarkerSize',7);
xticks(1:3); xticklabels({'Learned','Reference','Initial K0'}); xtickangle(0);
ylabel('Per-agent cost, 0-20 s'); title('Finite N = 40; 95% normal error bars');
exportgraphics(f,fullfile(folder,'reproduction.png'),'Resolution',170);
savefig(f,fullfile(folder,'reproduction.fig')); close(f);
end
