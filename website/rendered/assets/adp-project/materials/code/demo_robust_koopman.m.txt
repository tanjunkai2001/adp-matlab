function [result,runDir]=demo_robust_koopman(options)
%DEMO_ROBUST_KOOPMAN Original scalar/branch-complete arXiv2604.05633v2 variant.
if nargin<1,options=struct;end
root=fileparts(mfilename('fullpath'));oldPath=path;oldRng=rng;
cleanup=onCleanup(@()restore(oldPath,oldRng));addpath(root);
c=struct('seed',260405633,'trajectories',100,'samplesPerTrajectory',50,'dataStep',0.02, ...
 'dataDomain',0.8,'inputBiasAmplitude',0.75,'inputSinAmplitude',0.2,'noiseAmplitude',0.01,'collocationCount',5000,'collocationDomain',1, ...
 'punctureRadius',0.05,'epsilon',1e-3,'iterations',30,'innerIterations',40, ...
 'innerTolerance',1e-9,'policyTolerance',1e-6,'initialGain',2,'Q',eye(2),'R',1, ...
 'horizon',15,'step',0.005);
if isfield(options,'config'),names=fieldnames(options.config);for j=1:numel(names),c.(names{j})=options.config.(names{j});end,end
rng(c.seed,'twister');data=collect(c);model=rk_identify(data);
fprintf('Identified bilinear rank %d, training-fit c1=c2=%.6g.\n',model.rank,model.c1);
x=2*c.collocationDomain*rand(c.collocationCount,2)-c.collocationDomain;
keep=vecnorm(rk_lift(x),2,2)>=c.punctureRadius;x=x(keep,:);
while size(x,1)<c.collocationCount
 extra=2*c.collocationDomain*rand(c.collocationCount-size(x,1),2)-c.collocationDomain;
 x=[x;extra(vecnorm(rk_lift(extra),2,2)>=c.punctureRadius,:)];
end
solver=struct('Q',c.Q,'R',c.R,'epsilon',c.epsilon,'iterations',c.iterations, ...
 'innerIterations',c.innerIterations,'innerTolerance',c.innerTolerance, ...
 'policyTolerance',c.policyTolerance,'initialGain',c.initialGain,'c1',model.c1,'c2',model.c2);
robust=rk_solve(model,x,solver);nominalConfig=solver;nominalConfig.c1=0;nominalConfig.c2=0;
nominal=rk_solve(model,x,nominalConfig);
x0=[-1.5,-1.2;-.5,1.2;1.5,-.6;1.2,.9;.2,-1.4;-1.2,.6];
tr.robust=rk_rollout(robust,x0,c);tr.nominal=rk_rollout(nominal,x0,c);tr.oracle=rk_rollout('analytic_oracle',x0,c);
analyticValue=.25*x0(:,1).^2+.5*x0(:,2).^2;
metrics=struct('c1',model.c1,'c2',model.c2,'rank',model.rank,'robustConverged',robust.converged, ...
 'robustIterations',robust.iterations,'robustPdeRms',robust.residualRms, ...
 'nominalPdeRms',nominal.residualRms,'actualOptimalValues',analyticValue, ...
 'robustCosts',tr.robust.cost(:,end),'nominalCosts',tr.nominal.cost(:,end), ...
 'oracleCosts',tr.oracle.cost(:,end),'maxOracleValueError',max(abs(tr.oracle.cost(:,end)-analyticValue)), ...
 'robustRelativeExtra',(tr.robust.cost(:,end)-analyticValue)./analyticValue, ...
 'nominalRelativeExtra',(tr.nominal.cost(:,end)-analyticValue)./analyticValue, ...
 'robustMaxTerminalNorm',max(vecnorm(tr.robust.x(:,:,end),2,2)));
holdoutX=2*rand(2000,2)-1;holdoutU=2*rand(2000,1)-1;
[holdoutZ,D1,D2]=rk_lift(holdoutX);dx=truth(holdoutX,holdoutU);
trueLift=D1.*dx(:,1)+D2.*dx(:,2);prediction=holdoutZ*model.A'+holdoutU.*(holdoutZ*model.B1'+model.B0');
residualNorm=vecnorm(trueLift-prediction,2,2);bound=model.c1*vecnorm(holdoutZ,2,2)+model.c2*abs(holdoutU);
metrics.holdoutBoundViolationFraction=mean(residualNorm>bound);
metrics.holdoutLiftResidualRms=sqrt(mean(residualNorm.^2));
result=struct('config',c,'solverConfig',solver,'data',data,'model',model,'collocation',x, ...
 'robust',robust,'nominal',nominal,'holdoutX',holdoutX,'holdoutU',holdoutU, ...
 'holdoutResidualNorm',residualNorm,'holdoutBound',bound,'initialStates',x0,'trajectories',tr,'metrics',metrics);
result.environment=struct('version',version,'arch',computer('arch'));
result.claim='branch-complete Galerkin variant; sample-fit residual bounds; not full boundary-PDE or Table1 reproduction';
runDir='';
if ~isfield(options,'saveOutputs')||options.saveOutputs
 if isfield(options,'runId'),id=options.runId;else,id=['run-',char(datetime('now','Format','yyyyMMddHHmmssSSS'))];end
 if isempty(regexp(id,'^[A-Za-z0-9][A-Za-z0-9_-]*$','once')),error('robustkoopman:RunId','Unsafe id.');end
 runDir=fullfile(fileparts(fileparts(root)),'runs','robust_koopman2026',id);if isfolder(runDir)||isfile(runDir),error('robustkoopman:RunExists','Refuse overwrite.');end
 mkdir(runDir);save(fullfile(runDir,'result.mat'),'result','-v7');writeJson(fullfile(runDir,'metrics.json'),metrics);writeJson(fullfile(runDir,'config.json'),c);writeJson(fullfile(runDir,'environment.json'),result.environment);
 drawFigures(result,runDir);
end
disp(metrics);
end
function data=collect(c)
n=c.trajectories;x=c.dataDomain*(2*rand(n,2)-1);phase=2*pi*rand(n,1);bias=c.inputBiasAmplitude*sign(2*rand(n,1)-1);
T=n*c.samplesPerTrajectory;data=struct('x',zeros(T,2),'xdot',zeros(T,2),'u',zeros(T,1),'t',zeros(T,1),'trajectoryId',zeros(T,1));
for j=1:c.samplesPerTrajectory
 t=(j-1)*c.dataStep;u=c.inputSinAmplitude*sin(2*pi*.7*t+phase)+bias;noise=c.noiseAmplitude*[cos(2*pi*.4*t+phase),sin(2*pi*.4*t+phase)];
 dx=truth(x,u)+noise;idx=(j-1)*n+(1:n);
 data.x(idx,:)=x;data.xdot(idx,:)=dx;data.u(idx)=u;data.t(idx)=t;data.trajectoryId(idx)=(1:n)';
 h=c.dataStep/4;
 for k=1:4
  tau=t+(k-1)*h;k1=rhs(x,tau);k2=rhs(x+h*k1/2,tau+h/2);k3=rhs(x+h*k2/2,tau+h/2);k4=rhs(x+h*k3,tau+h);
  x=x+h*(k1+2*k2+2*k3+k4)/6;
 end
end
data.derivativeSource='simulated observed derivative of noise-corrupted data trajectory; not derivative-free';
data.noiseSemantics='bounded data-collection disturbance only; control evaluation uses original deterministic plant';
 function dx=rhs(x,tau)
  u=c.inputSinAmplitude*sin(2*pi*.7*tau+phase)+bias;
  dx=truth(x,u)+c.noiseAmplitude*[cos(2*pi*.4*tau+phase),sin(2*pi*.4*tau+phase)];
 end
end
function dx=truth(x,u)
dx=[-x(:,1)+x(:,2),-.5*(x(:,1)+x(:,2))+.5*x(:,1).^2.*x(:,2)+x(:,1).*u];
end
function writeJson(file,x),fid=fopen(file,'w');cl=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',jsonencode(x,'PrettyPrint',true));end
function restore(p,r),path(p);rng(r);end

function drawFigures(r,folder)
f=figure('Visible','off','Color','w');tiledlayout(1,2);nexttile;
for j=1:6
 plot(squeeze(r.trajectories.oracle.x(j,1,:)),squeeze(r.trajectories.oracle.x(j,2,:)),'k-');hold on;
 plot(squeeze(r.trajectories.robust.x(j,1,:)),squeeze(r.trajectories.robust.x(j,2,:)),'b--');
end
xlabel('x_1');ylabel('x_2');title('Oracle (black), robust variant (blue)');
nexttile;bar(100*[r.metrics.nominalRelativeExtra,r.metrics.robustRelativeExtra]);xlabel('Initial state index');ylabel('Extra cost (%)');legend('Nominal data model','Robust variant');
exportgraphics(f,fullfile(folder,'control_comparison.png'),'Resolution',150);close(f);
end
