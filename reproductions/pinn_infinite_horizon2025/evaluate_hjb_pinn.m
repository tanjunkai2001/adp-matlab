function evaluation = evaluate_hjb_pinn(net,cfg,previous)
%EVALUATE_HJB_PINN Independent residual, policy and closed-loop diagnostics.
if nargin<3,previous=[];end
rng(cfg.seed+100000,'twister');n=cfg.stateDimension;N=cfg.testPoints;
xt=[(2*rand(n,N)-1)*cfg.evaluationDomain;rand(1,N)*cfg.increment];
[v,dv]=dlfeval(@valueDerivative,net,dlarray(xt,'CB'),cfg);
v=extractdata(v);dv=extractdata(dv);
[f,g,q]=pinn_problem(cfg.problem,xt(1:n,:));
flow=dv(end,:)+sum(f.*dv(1:n,:),1)+q-sum(g.*dv(1:n,:),1).^2/(4*cfg.R);
boundaryInput=xt;boundaryInput(end,:)=cfg.increment;
bv=extractdata(pinn_value(net,dlarray(boundaryInput,'CB'),cfg));
if isempty(previous),terminal=zeros(1,N);else
    startInput=xt;startInput(end,:)=0;
    terminal=extractdata(pinn_value(previous,dlarray(startInput,'CB'),cfg));
end
initial=xt;initial(end,:)=0;
[v0,grad0]=dlfeval(@valueDerivative,net,dlarray(initial,'CB'),cfg);
v0=extractdata(v0);grad0=extractdata(grad0);gx=grad0(1:n,:);
u=-sum(g.*gx,1)/(2*cfg.R);
steadyResidual=sum(f.*gx,1)+q+cfg.R*u.^2+sum(g.*gx,1).*u;
[~,~,~,oracle]=pinn_problem(cfg.problem,xt(1:n,:));
evaluation.metrics=struct('flowMSE',mean(flow.^2),'flowMaxAbs',max(abs(flow)), ...
    'terminalMSE',mean((bv-terminal).^2),'terminalMaxAbs',max(abs(bv-terminal)), ...
    'steadyMSE',mean(steadyResidual.^2),'steadyMaxAbs',max(abs(steadyResidual)), ...
    'minimumValue',min(v0),'originValue',0,'totalHorizon',cfg.totalHorizon);
if ~isempty(oracle.value)
    evaluation.metrics.valueOracleRMSE=sqrt(mean((v0-oracle.value).^2));
    evaluation.metrics.policyOracleRMSE=sqrt(mean((u-oracle.control).^2));
end
if string(cfg.problem)=="scalar_lqr"
    exactFinite=tanh(cfg.totalHorizon-xt(end,:)).*xt(1,:).^2;
    evaluation.metrics.finiteValueOracleRMSE=sqrt(mean((v-exactFinite).^2));
end
evaluation.test=struct('xt',xt,'value',v,'flowResidual',flow,'terminalResidual',bv-terminal, ...
    'valueAtZeroTime',v0,'policyAtZeroTime',u,'steadyResidual',steadyResidual);
% Independent finite differences check value derivatives after training.
xcheck=xt(:,1:min(16,N));h=1e-5;ad=dv(:,1:size(xcheck,2));fd=zeros(size(ad));
for k=1:n+1
    xp=xcheck;xm=xcheck;xp(k,:)=xp(k,:)+h;xm(k,:)=xm(k,:)-h;
    fd(k,:)=(extractdata(pinn_value(net,dlarray(xp,'CB'),cfg))-extractdata(pinn_value(net,dlarray(xm,'CB'),cfg)))/(2*h);
end
evaluation.metrics.derivativeFDMaxError=max(abs(ad-fd),[],'all');
% Frozen stationary policy mu(x,0), evaluated under continuous feedback.
x0=cfg.initialStates;time=(0:cfg.simulationStep:cfg.simulationHorizon)';
runs=cell(1,size(x0,2));
for j=1:size(x0,2)
    options=odeset('RelTol',1e-6,'AbsTol',1e-8,'Events',@(t,z) stopOutside(t,z,n,cfg));
    [t,z]=ode45(@(t,z) rhs(t,z,net,cfg),time,[x0(:,j);0],options);
    states=z(:,1:n);inputs=policy(net,states',cfg)';
    run=struct('time',t,'state',states,'input',inputs,'accumulatedCost',z(:,end));
    run.finalNorm=norm(states(end,:));run.integratedCost=z(end,end);
    run.maxNorm=max(vecnorm(states,2,2));run.leftTrainingDomain=any(abs(states)>cfg.trainingDomain,'all');
    run.completed=t(end)>=cfg.simulationHorizon-1e-10;
    if ~isempty(oracle.value)
        [~,~,~,o]=pinn_problem(cfg.problem,x0(:,j));run.claimedOracleInitialValue=o.value;
    end
    runs{j}=run;
end
evaluation.closedLoop=runs;
end
function [v,dv]=valueDerivative(net,xt,cfg)
v=pinn_value(net,xt,cfg);dv=dlgradient(sum(v,'all'),xt);
end
function u=policy(net,x,cfg)
[~,dv]=dlfeval(@valueDerivative,net,dlarray([x;zeros(1,size(x,2))],'CB'),cfg);
[~,g]=pinn_problem(cfg.problem,x);
u=-sum(g.*extractdata(dv(1:end-1,:)),1)/(2*cfg.R);
end
function dz=rhs(~,z,net,cfg)
x=z(1:cfg.stateDimension);u=policy(net,x,cfg);[f,g,q]=pinn_problem(cfg.problem,x);
dz=[f+g*u;q+cfg.R*u^2];
end
function [value,isterminal,direction]=stopOutside(~,z,n,cfg)
value=cfg.stopRadius-norm(z(1:n));isterminal=1;direction=-1;
end
