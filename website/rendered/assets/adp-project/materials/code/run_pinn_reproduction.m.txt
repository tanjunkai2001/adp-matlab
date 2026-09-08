function [result,runDir] = run_pinn_reproduction(mode,outputDirectory)
%RUN_PINN_REPRODUCTION Train real finite-horizon neural HJB PINNs on CPU.
%   run_pinn_reproduction('reduced') runs scalar LQR and paper pendulum T=1:4.
%   'smoke' uses 10 iterations solely to exercise code paths.
%   'quartic' runs the corrected-cost quartic problem T=0.5:0.5:4.
% Requires MATLAB + Deep Learning Toolbox. No oracle values enter training.
if nargin<1,mode='reduced';end
if isstring(mode) && isscalar(mode), mode=char(mode); end
if ~ischar(mode) || ~ismember(mode,{'reduced','smoke','quartic'})
    error('pinn:Mode','Use reduced, smoke, or quartic.');
end
if nargin<2, outputDirectory=''; end
here=fileparts(mfilename('fullpath'));root=fileparts(fileparts(here));
oldpath=path;oldRng=rng;guard=onCleanup(@()restoreSession(oldpath,oldRng));addpath(here);
runId=char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
if isempty(outputDirectory)
    outputDirectory=fullfile(root,'runs','pinn_infinite_horizon2025',[mode '_' runId]);
end
runDir=char(outputDirectory);
if isfolder(runDir) || isfile(runDir)
    error('pinn:ExistingRun','Choose a new output directory.');
end
mkdir(runDir);
diary(fullfile(runDir,'training.log'));diaryGuard=onCleanup(@() diary('off')); %#ok<NASGU>
result=struct('mode',mode,'matlabVersion',version,'toolboxes',ver, ...
    'sourceVersion','arXiv:2505.21842v1','started',char(datetime('now')));
result.diagnostics=oracleDiagnostics();
fprintf('Oracle: scalar finite-HJB max %.3g; quartic paper HJB %.3g; corrected %.3g\n', ...
    result.diagnostics.lqrHJBMax,result.diagnostics.quarticPaperHJBMax,result.diagnostics.quarticCorrectedHJBMax);
base=struct('stateDimension',2,'R',1,'width',48,'depth',3, ...
    'trainingDomain',1.5,'evaluationDomain',1,'increment',1, ...
    'iterations',3000,'flowPoints',10000,'boundaryPoints',1600, ...
    'batchSize',256,'boundaryBatchSize',128,'testPoints',2048, ...
    'learningRate',0.003,'decay',0.0005,'warmStart',true, ...
    'seed',2718,'reportEvery',250,'simulationStep',0.05, ...
    'simulationHorizon',8,'stopRadius',5,'totalHorizon',1, ...
    'variant','reduced_tanh_even_origin_exact_terminal_soft', ...
    'initialStates',[-0.8,-0.4,0.8,0.4;0.2,0.8,-0.2,-0.8]);
if strcmp(mode,'smoke')
    base.iterations=10;base.flowPoints=256;base.boundaryPoints=128;
    base.batchSize=64;base.boundaryBatchSize=64;base.testPoints=32;
    base.width=12;base.depth=2;base.reportEvery=10;base.simulationHorizon=0.2;
end
problems={'scalar_lqr','pendulum'};horizons={1,1:4};
if strcmp(mode,'quartic'),problems={'quartic_corrected'};horizons={0.5:0.5:4};end
if strcmp(mode,'smoke'),horizons={1,1:2};end
result.experiments=cell(1,numel(problems));
for k=1:numel(problems)
    cfg=base;cfg.problem=problems{k};
    if strcmp(cfg.problem,'scalar_lqr')
        cfg.stateDimension=1;cfg.width=32;cfg.depth=2;cfg.initialStates=[-1,-0.5,0.5,1];
        cfg.trainingDomain=1.5;cfg.evaluationDomain=1;
        if ~strcmp(mode,'smoke'),cfg.iterations=2000;end
    elseif strcmp(cfg.problem,'quartic_corrected')
        cfg.increment=0.5;cfg.evaluationDomain=1.2;cfg.learningRate=0.002;
        cfg.iterations=4000;cfg.width=64;
    end
    stages=cell(1,numel(horizons{k}));previous=[];
    for stage=1:numel(horizons{k})
        cfg.totalHorizon=horizons{k}(stage);cfg.seed=base.seed+100*k+stage;
        fprintf('\nTRAIN %s horizon=%g, %d layers x %d neurons, %d updates\n', ...
            cfg.problem,cfg.totalHorizon,cfg.depth,cfg.width,cfg.iterations);
        [net,history,data]=train_hjb_pinn(cfg,previous);
        evaluation=evaluate_hjb_pinn(net,cfg,previous);
        stages{stage}=struct('config',cfg,'network',net,'history',history,'data',data,'evaluation',evaluation);
        stem=sprintf('%s_T%g',cfg.problem,cfg.totalHorizon);
        checkpoint=stages{stage};save(fullfile(runDir,[stem '.mat']),'checkpoint','-v7.3');
        writetable(array2table(history,'VariableNames',{'iteration','loss','flowMSE','terminalMSE','learningRate','seconds'}),fullfile(runDir,[stem '_loss.csv']));
        saveEvaluation(evaluation,cfg,runDir,stem);
        fprintf('TEST %s T=%g flow=%.4g terminal=%.4g steady=%.4g derivativeFD=%.3g\n', ...
            cfg.problem,cfg.totalHorizon,evaluation.metrics.flowMSE,evaluation.metrics.terminalMSE, ...
            evaluation.metrics.steadyMSE,evaluation.metrics.derivativeFDMaxError);
        previous=net;
        save(fullfile(runDir,'progress.mat'),'result','cfg','-v7.3');
    end
    result.experiments{k}=struct('problem',cfg.problem,'stages',{stages});
end
% Deterministic short-prefix replay: same seed/data/Adam updates, independent call.
checkCfg=base;checkCfg.problem='scalar_lqr';checkCfg.stateDimension=1;
checkCfg.width=12;checkCfg.depth=2;checkCfg.iterations=12;checkCfg.flowPoints=128;
checkCfg.boundaryPoints=64;checkCfg.batchSize=64;checkCfg.boundaryBatchSize=32;checkCfg.reportEvery=12;
[a,ha,da]=train_hjb_pinn(checkCfg,[]);[b,hb,db]=train_hjb_pinn(checkCfg,[]);
replayError=0;for k=1:height(a.Learnables),replayError=max(replayError,max(abs(extractdata(a.Learnables.Value{k})-extractdata(b.Learnables.Value{k})),[],'all'));end
result.diagnostics.seedReplayParameterMaxError=replayError;
result.diagnostics.seedReplayLossMaxError=max(abs(ha(:,2:5)-hb(:,2:5)),[],'all');
result.diagnostics.seedReplayDataEqual=isequal(da.flow,db.flow)&&isequal(da.boundary,db.boundary);
result.diagnostics.seedReplayScope='12-update independent deterministic prefix, not full second training';
result.finished=char(datetime('now'));result.sourceHashes=sourceHashes(here);
save(fullfile(runDir,'result.mat'),'result','-v7.3');
summary=result;summary=rmfield(summary,'experiments');
summary.experiments=cellfun(@summarize,result.experiments,'UniformOutput',false);
writeJson(fullfile(runDir,'summary.json'),summary);
plotResults(result,runDir);
fprintf('\nSAVED %s\n',runDir);
end
function restoreSession(oldPath,oldRng)
path(oldPath);rng(oldRng);
end
function out=summarize(experiment)
out=struct('problem',experiment.problem,'stages',[]);
for k=1:numel(experiment.stages)
 s=experiment.stages{k};m=s.evaluation.metrics;m.trainingSeconds=s.history(end,6);
 m.closedLoopFinalNorm=cellfun(@(r)r.finalNorm,s.evaluation.closedLoop);
 m.closedLoopCost=cellfun(@(r)r.integratedCost,s.evaluation.closedLoop);
 m.closedLoopCompleted=cellfun(@(r)r.completed,s.evaluation.closedLoop);
 m.leftTrainingDomain=cellfun(@(r)r.leftTrainingDomain,s.evaluation.closedLoop);
 out.stages=[out.stages;m]; %#ok<AGROW>
end
end
function diagnostic=oracleDiagnostics()
rng(71);x=2*rand(2,100)-1;t=rand(1,100);H=1;
xt=dlarray([x(1,:);t],'CB');[~,derivative]=dlfeval(@oracleDerivative,xt,H);
d=extractdata(derivative);P=tanh(H-t);expected=[2*P.*x(1,:);-(1-P.^2).*x(1,:).^2];
diagnostic.lqrADMaxError=max(abs(d-expected),[],'all');
residual=d(2,:)+x(1,:).^2-d(1,:).^2/4;
diagnostic.lqrHJBMax=max(abs(residual));
grad=[x(1,:);2*x(2,:)+4*x(2,:).^3];
[f,g,q]=pinn_problem('quartic_paper',x);r=sum(f.*grad,1)+q-sum(g.*grad,1).^2/4;
diagnostic.quarticPaperHJBMax=max(abs(r));
diagnostic.quarticPaperResidualIdentityMax=max(abs(r+x(2,:).^4));
[~,~,qc]=pinn_problem('quartic_corrected',x);r2=sum(f.*grad,1)+qc-sum(g.*grad,1).^2/4;
diagnostic.quarticCorrectedHJBMax=max(abs(r2));
assert(diagnostic.lqrADMaxError<1e-12&&diagnostic.lqrHJBMax<1e-12);
assert(diagnostic.quarticPaperResidualIdentityMax<1e-12&&diagnostic.quarticCorrectedHJBMax<1e-12);
end
function [v,d]=oracleDerivative(xt,H)
v=tanh(H-xt(2,:)).*xt(1,:).^2;d=dlgradient(sum(v,'all'),xt);
end
function saveEvaluation(e,cfg,runDir,stem)
t=e.test;n=cfg.stateDimension;
values=[t.xt',t.value',t.flowResidual',t.terminalResidual',t.valueAtZeroTime',t.policyAtZeroTime',t.steadyResidual'];
names=[cellstr("x"+(1:n)),{'localTime','value','finiteHJBResidual','terminalResidual','valueAtZeroTime','policyAtZeroTime','steadyHJBResidual'}];
writetable(array2table(values,'VariableNames',names),fullfile(runDir,[stem '_heldout.csv']));
for k=1:numel(e.closedLoop)
 r=e.closedLoop{k};names=[{'time'},cellstr("x"+(1:n)),{'input','integratedCost'}];
 writetable(array2table([r.time,r.state,r.input,r.accumulatedCost],'VariableNames',names),fullfile(runDir,sprintf('%s_trajectory%d.csv',stem,k)));
end
end
function hashes=sourceHashes(here)
f=dir(fullfile(here,'*.m'));hashes=struct;
for k=1:numel(f)
 fid=fopen(fullfile(here,f(k).name),'rb');bytes=fread(fid,Inf,'*uint8');fclose(fid);
 digest=java.security.MessageDigest.getInstance('SHA-256');digest.update(typecast(bytes,'int8'));
 h=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
 hashes.(matlab.lang.makeValidName(f(k).name))=h;
end
end
function writeJson(file,value)
fid=fopen(file,'w');closer=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',jsonencode(value,PrettyPrint=true)); %#ok<NASGU>
end
function plotResults(result,runDir)
for k=1:numel(result.experiments)
 exp=result.experiments{k};fig=figure('Visible','off','Color','w','Position',[100 100 1050 700]);
 tiledlayout(2,2);nexttile;hold on;
 for s=1:numel(exp.stages),h=exp.stages{s}.history;semilogy(h(:,1),h(:,2),'DisplayName',sprintf('T=%g',exp.stages{s}.config.totalHorizon));end
 set(gca,'YScale','log');xlabel('Adam update');ylabel('Training MSE');legend('Location','best');grid on;
 nexttile;T=cellfun(@(s)s.config.totalHorizon,exp.stages);E=cellfun(@(s)s.evaluation.metrics.steadyMSE,exp.stages);
 semilogy(T,E,'o-','LineWidth',1.4);xlabel('Total horizon');ylabel('Held-out steady HJB MSE');grid on;
 last=exp.stages{end};nexttile;hold on;
 for j=1:numel(last.evaluation.closedLoop),r=last.evaluation.closedLoop{j};plot(r.time,vecnorm(r.state,2,2));end
 xlabel('Physical time (s)');ylabel('State norm');grid on;
 nexttile;hold on;
 for j=1:numel(last.evaluation.closedLoop),r=last.evaluation.closedLoop{j};plot(r.time,r.accumulatedCost);end
 xlabel('Physical time (s)');ylabel('Accumulated cost');grid on;
 sgtitle([strrep(exp.problem,'_',' ') ' : neural finite-horizon HJB continuation']);
 exportgraphics(fig,fullfile(runDir,[exp.problem '_diagnostics.png']),'Resolution',160);close(fig);
end
end
