function outcome=run_verified_meanfield(outputDirectory)
%RUN_VERIFIED_MEANFIELD Complete local verification and two MC scales.
if nargin<1
    root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    outputDirectory=fullfile(root,'runs','meanfield_lqg2025', ...
        ['verified-' char(datetime('now','Format','yyyyMMdd-HHmmss-SSS'))]);
end
if isfolder(outputDirectory) || isfile(outputDirectory)
    error('mf:PreserveRun','Choose a new output directory; existing data are preserved.');
end
mkdir(outputDirectory);
cfg=mf_config;
tests=runtests(fullfile(fileparts(mfilename('fullpath')),'test_meanfield_lqg2025.m'));
writetable(table(tests),fullfile(outputDirectory,'tests.csv'));
assert(all([tests.Passed]),'mf:TestsFailed','Method tests failed; inspect tests.csv.');
paper=demo_meanfield_lqg2025(fullfile(outputDirectory,'paper-scale-100'),cfg);
precision=mf_precision_check(fullfile(outputDirectory,'precision-4000'),cfg,40);
% Four independent 4000-path experiments including the first precision fit.
% A changed probe is allowed between experiments, fixed within each one.
gainRep=zeros(4,4); gainRep(1,:)=precision.gains(end,:);
for j=2:4
    trialCfg=cfg; trialCfg.seed=cfg.seed+1000*(j-1);
    trial=mf_precision_check(fullfile(outputDirectory,sprintf('gain-repeat-%02d',j)), ...
        trialCfg,40,true);
    gainRep(j,:)=trial.gains(end,:);
end
names={'K1';'K2';'Ks1';'Ks2'};
gainMean=mean(gainRep,1); gainSE=std(gainRep,0,1)/sqrt(size(gainRep,1));
gainTable=table(names,[precision.reference.K precision.reference.Ks].', ...
    gainMean.',gainSE.','VariableNames',{'parameter','modelReference','meanOf4Fits','meanSE'});
writetable(gainTable,fullfile(outputDirectory,'gain-uncertainty-4000.csv'));
disp(gainTable);
outcome=struct('paperScale',paper,'precision',precision,'gainReplicates',gainRep, ...
    'gainMean',gainMean,'gainMeanStandardError',gainSE,'tests',tests, ...
    'scope','Gain SE across 4 independent fits; cost SE across 48 populations conditional on primary fitted policy and mean curve.');
save(fullfile(outputDirectory,'verified-results.mat'),'outcome','-v7.3');
end
