function [result,runDir]=demo_koopman(options)
%DEMO_KOOPMAN Original MATLAB method-level reproduction of Zeng et al. L4DC25.
% Physics/Q/R/lambda were not specified in paper: see METHOD.md for deviations.
if nargin<1, options=struct; end
root=fileparts(mfilename('fullpath')); oldPath=path; oldRng=rng;
cleanup=onCleanup(@() restoreSession(oldPath,oldRng)); addpath(root);
config=struct('seed',20250907,'damping',1,'degree',5,'lambda',1000, ...
    'identificationSamples',1000,'identificationTimes',0:0.01:1, ...
    'simulationStep',0.001,'rankTolerance',1e-11,'hiddenUnits',200, ...
    'collocationSamples',3000,'iterations',10,'svdTolerance',1e-10, ...
    'K0',[4,3],'Q',eye(2),'R',1,'evaluationSamples',50, ...
    'horizon',10,'step',0.005,'outputStep',0.01);
if isfield(options,'config')
    names=fieldnames(options.config);
    for j=1:numel(names), config.(names{j})=options.config.(names{j}); end
end
rng(config.seed,'twister'); fprintf('Collecting %d held-input trajectories.\n',config.identificationSamples);
initial=2*rand(config.identificationSamples,3)-1;
data=collectData(initial,config);
idConfig=struct('degree',config.degree,'lambda',config.lambda,'rankTolerance',config.rankTolerance);
model=koopman_identify(data,idConfig);
piConfig=struct('Q',config.Q,'R',config.R,'K0',config.K0, ...
    'iterations',config.iterations,'svdTolerance',config.svdTolerance);
features.W=1.5*randn(config.hiddenUnits-3,2); features.b=2*rand(config.hiddenUnits-3,1)-1;
collocation=2*rand(config.collocationSamples,2)-1;
heldout=2*rand(2000,2)-1; evaluationInitial=2*rand(config.evaluationSamples,2)-1;
[fhat,ghat]=koopman_model(model,heldout);
ftrue=[heldout(:,2),sin(heldout(:,1))-config.damping*heldout(:,2)];
gtrue=repmat([0,1],size(heldout,1),1);
metrics.Ef=mean(sum(abs(fhat-ftrue),2)); metrics.Eg=mean(sum(abs(ghat-gtrue),2));
metrics.modelCoordinateResidual=model.coordinateResidual;
metrics.dictionaryRank=model.rank; metrics.dictionaryColumns=model.dictionaryColumns;
fprintf('Yosida model Ef=%.5g, Eg=%.5g, rank=%d.\n',metrics.Ef,metrics.Eg,model.rank);
learned=koopman_policy_iteration(model,features,collocation,piConfig);
oracleModel=struct('kind','oracle_pendulum','damping',config.damping);
oracle=koopman_policy_iteration(oracleModel,features,collocation,piConfig);
initialPolicy=struct('kind','linear','K',config.K0);
rollouts.learned=koopman_rollout(learned.policy,evaluationInitial,config);
rollouts.oracle=koopman_rollout(oracle.policy,evaluationInitial,config);
rollouts.initial=koopman_rollout(initialPolicy,evaluationInitial,config);
metrics.learnedMeanCost=mean(rollouts.learned.integratedCost(:,end));
metrics.oracleMeanCost=mean(rollouts.oracle.integratedCost(:,end));
metrics.initialMeanCost=mean(rollouts.initial.integratedCost(:,end));
metrics.meanCostGap=abs(metrics.learnedMeanCost-metrics.oracleMeanCost);
metrics.maximumMeanCostGapAcrossTime=max(abs(mean(rollouts.learned.integratedCost-rollouts.oracle.integratedCost,1)));
metrics.maximumTrajectoryCostGap=max(abs(rollouts.learned.integratedCost(:,end)-rollouts.oracle.integratedCost(:,end)));
metrics.maximumTerminalNorm=max(vecnorm(rollouts.learned.x(:,:,end),2,2));
metrics.policyRmsDifference=sqrt(mean((koopman_policy(learned.policy,heldout)-koopman_policy(oracle.policy,heldout)).^2));
[Phi,D1,D2]=koopman_features(features,heldout); u=koopman_policy(learned.policy,heldout);
residual=sum((heldout*config.Q).*heldout,2)+config.R*u.^2+ ...
    (D1*learned.valueBeta).*(ftrue(:,1)+gtrue(:,1).*u)+ ...
    (D2*learned.valueBeta).*(ftrue(:,2)+gtrue(:,2).*u);
metrics.trueHjbResidualRms=sqrt(mean(residual.^2));
metrics.minimumGridValue=min(Phi*learned.valueBeta);
metrics.lastPolicyChange=learned.history{end}.policyChangeRms;
result=struct('config',config,'rawData',data,'model',model,'features',features, ...
    'collocation',collocation,'heldout',heldout,'evaluationInitial',evaluationInitial, ...
    'learned',learned,'oracle',oracle,'rollouts',rollouts,'metrics',metrics);
result.identificationConfig=idConfig; result.policyIterationConfig=piConfig;
result.environment=struct('version',version,'release',version('-release'),'arch',computer('arch'));
result.claim='method-level MATLAB reproduction, specified normalized pendulum; not exact paper Table 3 reproduction';
runDir=''; saveOutputs=~isfield(options,'saveOutputs')||options.saveOutputs;
if saveOutputs
    if isfield(options,'outputRoot'), outputRoot=options.outputRoot;
    else, outputRoot=fullfile(fileparts(fileparts(root)),'runs','koopman_l4dc2025'); end
    if isfield(options,'runId'), runId=options.runId; else
        runId=['run-',char(datetime('now','TimeZone','UTC','Format',"yyyyMMdd'T'HHmmssSSS"))];
    end
    if isempty(regexp(runId,'^[A-Za-z0-9][A-Za-z0-9_-]*$','once')), error('koopman:RunId','Unsafe run id.'); end
    runDir=fullfile(outputRoot,runId);
    if isfolder(runDir)||isfile(runDir), error('koopman:RunExists','Refuse overwrite.'); end
    mkdir(runDir); save(fullfile(runDir,'result.mat'),'result','-v7');
    writeJson(fullfile(runDir,'config.json'),config); writeJson(fullfile(runDir,'metrics.json'),metrics);
    writeJson(fullfile(runDir,'environment.json'),result.environment);
    drawFigures(result,runDir);
    listing=dir(fullfile(root,'*.m')); records=cell(numel(listing),1);
    for j=1:numel(listing)
        records{j}=struct('path',listing(j).name,'sha256',hashFile(fullfile(root,listing(j).name)));
    end
    writeJson(fullfile(runDir,'source_hashes.json'),records);
end
fprintf('Frozen true-system evaluation: initial %.8g, learned %.8g, oracle %.8g, gap %.3g, terminal %.3g.\n', ...
    metrics.initialMeanCost,metrics.learnedMeanCost,metrics.oracleMeanCost,metrics.meanCostGap,metrics.maximumTerminalNorm);
end

function data=collectData(initial,c)
t=c.identificationTimes; x=initial(:,1:2); u=initial(:,3); n=size(x,1);
data=struct('t',t,'u',u,'x',zeros(n,2,numel(t)),'executionMode','constant_input_per_trajectory');
data.x(:,:,1)=x;
for j=2:numel(t)
    steps=ceil((t(j)-t(j-1))/c.simulationStep); h=(t(j)-t(j-1))/steps;
    for k=1:steps
        k1=rhs(x); k2=rhs(x+h*k1/2); k3=rhs(x+h*k2/2); k4=rhs(x+h*k3);
        x=x+h*(k1+2*k2+2*k3+k4)/6;
    end
    data.x(:,:,j)=x;
end
    function f=rhs(z), f=[z(:,2),sin(z(:,1))-c.damping*z(:,2)+u]; end
end

function drawFigures(r,folder)
f=figure('Visible','off','Color','w'); tiledlayout(1,2);
nexttile; plot(r.rollouts.learned.t,squeeze(r.rollouts.learned.x(:,1,:))'); hold on;
plot(r.rollouts.learned.t,squeeze(r.rollouts.learned.x(:,2,:))','--'); xlabel('Time (s)'); ylabel('State'); title('50 frozen-policy trajectories');
nexttile; plot(r.rollouts.learned.t,abs(mean(r.rollouts.learned.integratedCost-r.rollouts.oracle.integratedCost,1)),'LineWidth',1.5);
xlabel('Time (s)'); ylabel('Absolute difference of mean cost'); title('Data model vs truth-model PI');
exportgraphics(f,fullfile(folder,'trajectories_cost.png'),'Resolution',150); close(f);
end
function writeJson(file,value)
fid=fopen(file,'w'); if fid<0,error('koopman:Write','Cannot save.');end
c=onCleanup(@()fclose(fid)); fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end
function h=hashFile(file)
fid=fopen(file,'rb'); c=onCleanup(@()fclose(fid)); bytes=fread(fid,Inf,'*uint8');
digest=java.security.MessageDigest.getInstance('SHA-256'); digest.update(typecast(bytes,'int8'));
h=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2)',1,[]));
end
function restoreSession(p,r),path(p);rng(r);end
