function tests=test_bias_pi
%TEST_BIAS_PI Independent Eq(43)/(48), MIMO, numerical and LQR checks.
tests=functiontests(localfunctions);
end
function setupOnce(tc)
[data,spec,reference]=mimoData;
tc.TestData.data=data;tc.TestData.spec=spec;tc.TestData.reference=reference;
[tc.TestData.lqrData,tc.TestData.lqrSpec]=lqrData;
end
function testMimoOuterRecoversBiasedLyapunovAndGreedyActor(tc)
r=tc.TestData.reference;s=tc.TestData.spec;d=tc.TestData.data;
[A,y]=bp_regression(d,s,r.W,r.cPrev,r.gamma,'bias');
P=lyapunovReference(r.A+r.B*r.W',r.gamma,r.Q+r.W*r.R*r.W'+r.gamma*r.Pprev);
expected=[P(1,1);P(2,2);2*P(1,2);reshape((-r.R\(r.B'*P))',[],1)];
verifyEqual(tc,size(A),[24,7]);
verifyLessThan(tc,norm(A*expected-y)/norm(y),2e-9);
verifyEqual(tc,A\y,expected,'AbsTol',1e-7);
% Off-diagonal R and unequal input gains make column-major W ordering visible.
verifyGreaterThan(tc,abs(r.R(1,2)),0.1);
verifyGreaterThan(tc,norm(expected(4:5)-expected(6:7)),0.1);
end
function testInnerRemovesPreviousValueAndRecoversDiscountedLyapunov(tc)
r=tc.TestData.reference;s=tc.TestData.spec;d=tc.TestData.data;
[A,y]=bp_regression(d,s,r.W,r.cPrev,r.gamma,'discounted');
P=lyapunovReference(r.A+r.B*r.W',r.gamma,r.Q+r.W*r.R*r.W');
expected=[P(1,1);P(2,2);2*P(1,2);reshape((-r.R\(r.B'*P))',[],1)];
verifyLessThan(tc,norm(A*expected-y)/norm(y),2e-9);
verifyEqual(tc,A\y,expected,'AbsTol',1e-7);
[again,yOther]=bp_regression(d,s,r.W,10*r.cPrev,r.gamma,'discounted');
verifyEqual(tc,again,A);verifyEqual(tc,yOther,y);
end
function testPreviousValueTermAgainstIndependentAugmentedOde(tc)
r=tc.TestData.reference;s=tc.TestData.spec;d=tc.TestData.data;
[Ab,yb]=bp_regression(d,s,r.W,r.cPrev,r.gamma,'bias');
[Ad,yd]=bp_regression(d,s,r.W,r.cPrev,r.gamma,'discounted');
verifyEqual(tc,Ab,Ad);
verifyEqual(tc,yb-yd,-r.gamma*r.previousValueIntegrals,'AbsTol',1e-9);
% Every recorded window has a nonzero global start: weights must use t-t_start.
shifted=d;shifted.t=d.t+100;
[Ashift,yshift]=bp_regression(shifted,s,r.W,r.cPrev,r.gamma,'bias');
verifyEqual(tc,Ashift,Ab,'AbsTol',1e-11);verifyEqual(tc,yshift,yb,'AbsTol',1e-11);
end
function testZeroBiasAndQuadratureRefinement(tc)
r=tc.TestData.reference;s=tc.TestData.spec;d=tc.TestData.data;
[A0,y0]=bp_regression(d,s,r.W,r.cPrev,0,'bias');
[Ad,yd]=bp_regression(d,s,r.W,r.cPrev,0,'discounted');
verifyEqual(tc,A0,Ad);verifyEqual(tc,y0,yd);
P=lyapunovReference(r.A+r.B*r.W',r.gamma,r.Q+r.W*r.R*r.W'+r.gamma*r.Pprev);
expected=[P(1,1);P(2,2);2*P(1,2);reshape((-r.R\(r.B'*P))',[],1)];
coarse=subsample(d,8);fine=subsample(d,2);
[Ac,yc]=bp_regression(coarse,s,r.W,r.cPrev,r.gamma,'bias');
[Af,yf]=bp_regression(fine,s,r.W,r.cPrev,r.gamma,'bias');
eCoarse=norm(Ac*expected-yc);eFine=norm(Af*expected-yf);
verifyLessThan(tc,eFine,eCoarse/50);
fprintf('BIAS_PI_QUADRATURE %s\n',jsonencode(struct('coarseSubsteps',16,'fineSubsteps',64,'coarseResidual',eCoarse,'fineResidual',eFine)));
end
function testScaledSvdRankConditionAndNonfiniteRejection(tc)
r=tc.TestData.reference;[A,y]=bp_regression(tc.TestData.data,tc.TestData.spec,r.W,r.cPrev,r.gamma,'bias');
[w,fit]=bp_solve(A,y);verifyEqual(tc,w,A\y,'AbsTol',1e-10);
verifyEqual(tc,fit.rank,7);verifyGreaterThanOrEqual(tc,fit.rawCondition,1);
verifyError(tc,@()bp_solve(A(:,[1,1]),y),'biaspi:RankDeficient');
verifyError(tc,@()bp_solve(A(1:3,:),y(1:3)),'biaspi:RankDeficient');
% Independent nearly-collinear columns: full numerical rank but above cond gate.
s=(1:20)';near=[ones(20,1),ones(20,1)+1e-6*s];
verifyError(tc,@()bp_solve(near,s,struct('conditionLimit',1e4)),'biaspi:IllConditioned');
bad=y;bad(1)=NaN;verifyError(tc,@()bp_solve(A,bad),'MATLAB:expectedFinite');
scales=[1e-8,1e4,1e-3,1e6,1e-6,1e2,1];
[scaled,diagnostics]=bp_solve(A.*scales,y);
verifyEqual(tc,scales'.*scaled,w,'AbsTol',1e-8);
verifyEqual(tc,diagnostics.scaledCondition,fit.scaledCondition,'RelTol',1e-9);
end
function testRegressionRejectsInvalidRecordedChannelsAndCosts(tc)
r=tc.TestData.reference;s=tc.TestData.spec;d=tc.TestData.data;
verifyError(tc,@()bp_regression(d,s,r.W,r.cPrev,r.gamma,'typo'),'biaspi:Mode');
bad=d;bad.t(1,2,1)=bad.t(1,1,1);
verifyError(tc,@()bp_regression(bad,s,r.W,r.cPrev,r.gamma,'bias'),'biaspi:TimeGrid');
bad=d;bad.u(1,1,1)=NaN;
verifyError(tc,@()bp_regression(bad,s,r.W,r.cPrev,r.gamma,'bias'),'MATLAB:expectedFinite');
bad=d;bad.x=bad.x(:,1:end-1,:);bad.u=bad.u(:,1:end-1,:);bad.t=bad.t(:,1:end-1,:);bad.q=bad.q(:,1:end-1,:);
verifyError(tc,@()bp_regression(bad,s,r.W,r.cPrev,r.gamma,'bias'),'biaspi:DataShape');
s.R=[1,.2;0,1];
verifyError(tc,@()bp_regression(d,s,r.W,r.cPrev,r.gamma,'bias'),'biaspi:InputCost');
s.R=diag([1,-1]);
verifyError(tc,@()bp_regression(d,s,r.W,r.cPrev,r.gamma,'bias'),'biaspi:InputCost');
end
function testFixedDataFromInadmissiblePolicyConvergesToAnalyticLqr(tc)
d=tc.TestData.lqrData;s=tc.TestData.lqrSpec;c=lqrConfig;
snapshot=d;
% Neither A nor B nor a dynamics callback is supplied to the learner.
verifyFalse(tc,isfield(s,'A'));verifyFalse(tc,isfield(s,'B'));
solution=bp_learn(d,s,c);
a=1+sqrt(2);P=[2+sqrt(2),a;a,a];expected=[P(1,1);P(2,2);2*P(1,2)];
verifyTrue(tc,solution.converged);verifyEqual(tc,solution.c,expected,'AbsTol',3e-6);
verifyEqual(tc,solution.W,-[a;a],'AbsTol',3e-6);
verifyEqual(tc,d,snapshot);verifyFalse(tc,solution.dataContract.usesDynamics);
verifyLessThan(tc,max(real(eig([0,1;1,0]+[0;1]*solution.W'))),0);
verifyGreaterThan(tc,max(real(eig([0,1;1,0]+[0;1]*c.actor0'))),0);
verifyFalse(tc,solution.dataContract.theoremVerified);
fprintf('BIAS_PI_LQR %s\n',jsonencode(struct('iterations',solution.iterations,'gamma',solution.gamma,'criticError',norm(solution.c-expected),'actorError',norm(solution.W+[a;a]))));
end
function testOuterBudgetDoesNotClaimConvergence(tc)
c=lqrConfig;c.maxIterations=1;c.tolerance=1e-25;
s=bp_learn(tc.TestData.lqrData,tc.TestData.lqrSpec,c);
verifyFalse(tc,s.converged);verifyEqual(tc,s.iterations,1);verifyEqual(tc,s.status,'max_iterations');
verifyGreaterThan(tc,s.history{1}.criticChangeSquared,c.tolerance);
end
function testTriggeredScheduleUsesNewestInnerValue(tc)
% Deliberately large positive initial critic exercises a branch; this is not
% an assertion that its seed satisfies the paper's global initialization.
c=lqrConfig;c.critic0=[40;40;0];c.actor0=[-1;-1];c.maxIterations=2;
s=bp_learn(tc.TestData.lqrData,tc.TestData.lqrSpec,c);first=s.history{1};
verifyTrue(tc,first.thresholdTriggered);verifyGreaterThan(tc,numel(first.inner),0);
verifyLessThan(tc,first.gamma,first.gammaBefore);verifyGreaterThan(tc,first.gamma,0);
expectedGamma=c.gamma0*(c.gamma0*40)/(1+c.gamma0*40);
verifyEqual(tc,first.gamma,expectedGamma,'RelTol',1e-12);
verifyEqual(tc,first.biasPreviousC,first.inner{end}.c);
verifyGreaterThan(tc,norm(first.biasPreviousC-first.previousC),1);
verifyEqual(tc,first.targetW,first.inner{end}.W);
for j=1:numel(first.inner)
 verifyEqual(tc,first.inner{j}.regression.mode,'discounted');
 verifyFalse(tc,first.inner{j}.regression.biasIncluded);
end
verifyTrue(tc,first.regression.biasIncluded);
gammas=cellfun(@(h)h.gamma,s.history);verifyTrue(tc,all(diff(gammas)<=0));
end
function testThresholdConfigurationAndInnerBudgetReject(tc)
c=lqrConfig;c.deltaH=c.deltaBar;
verifyError(tc,@()bp_learn(tc.TestData.lqrData,tc.TestData.lqrSpec,c),'MATLAB:notGreater');
c=lqrConfig;c.critic0=[40;40;0];c.gamma0=0;
verifyError(tc,@()bp_learn(tc.TestData.lqrData,tc.TestData.lqrSpec,c),'biaspi:GammaSchedule');
c=lqrConfig;c.critic0=[40;40;0];c.deltaBar=1e-12;c.deltaH=1e-11;c.maxInnerIterations=1;
verifyError(tc,@()bp_learn(tc.TestData.lqrData,tc.TestData.lqrSpec,c),'biaspi:InnerBudget');
end
function testCollectorContinuousFeedbackAndResetBoundary(tc)
c=struct('sampleTime',.1,'collectionTime',.6,'substeps',4, ...
 'resetRadius',.24,'maximumStateNorm',2);
d=bp_collect(@(~,x,u)x+u,@(~,x).1*x,@(x)x.^2,.2,c);
verifyEqual(tc,d.u,.1*d.x,'AbsTol',eps);verifyEqual(tc,d.q,d.x.^2,'AbsTol',eps);
verifyEqual(tc,d.resetAfterWindow,[false,true,false,true,false,false]);
for k=1:6
 local=reshape(d.t(1,:,k)-d.t(1,1,k),1,[]);
 expected=d.x(1,1,k)*exp(1.1*local);
 verifyEqual(tc,reshape(d.x(1,:,k),1,[]),expected,'RelTol',5e-9);
 if k>1
  if d.resetAfterWindow(k-1),expectedStart=.2;else,expectedStart=d.x(1,end,k-1);end
  verifyEqual(tc,d.x(1,1,k),expectedStart);
 end
end
verifyFalse(tc,d.contract.truthCallbacksSaved);
c.substeps=3;
verifyError(tc,@()bp_collect(@(~,x,u)x+u,@(~,x).1*x,@(x)x.^2,.2,c),'biaspi:Substeps');
c.substeps=4;c.collectionTime=.25;
verifyError(tc,@()bp_collect(@(~,x,u)x+u,@(~,x).1*x,@(x)x.^2,.2,c),'biaspi:Duration');
end
function cfg=lqrConfig
cfg=struct('critic0',[1;1;0],'actor0',[0;0],'gamma0',6,'deltaBar',8,'deltaH',30, ...
 'tolerance',1e-18,'maxIterations',500,'maxInnerIterations',100);
end
function [data,spec]=lqrData
n=24;nodes=129;data=struct('t',zeros(1,nodes,n),'x',zeros(2,nodes,n),'u',zeros(1,nodes,n),'q',zeros(1,nodes,n));
for k=1:n
 t=.23*k+linspace(0,.3,nodes);initial=[sin(sqrt(2)*k);cos(sqrt(3)*k)];
 [~,x]=ode45(@rhs,t,initial,odeset('RelTol',1e-12,'AbsTol',1e-13));
 X=x';data.t(1,:,k)=t;data.x(:,:,k)=X;data.u(1,:,k)=behavior(t);data.q(1,:,k)=sum(X.^2,1);
end
angles=linspace(0,2*pi,65);spec=struct('phi',@(X)[X(1,:).^2;X(2,:).^2;X(1,:).*X(2,:)], ...
 'psi',@(X)X,'R',1,'checkX',[cos(angles);sin(angles)],'stateCost',@(X)sum(X.^2,1));
 function dx=rhs(t,x),dx=[x(2);x(1)+behavior(t)];end
 function u=behavior(t),u=.5*sin(1.7*t)+.3*cos(.8*t)+.2*sin(2.9*t);end
end
function P=lyapunovReference(Aclosed,gamma,Q)
% Independent matrix equation, no Control System Toolbox and no ADP routines.
S=Aclosed-gamma*eye(size(Aclosed))/2;n=size(S,1);
P=reshape(-(kron(eye(n),S')+kron(S',eye(n)))\Q(:),n,n);
P=(P+P')/2;
end
function [data,spec,r]=mimoData
% Exact linear dynamics are visible only to this independent test simulator.
A=[-.4,.7;-.2,.3];B=[1,.2;.4,.9];R=[2,.3;.3,1];Q=[1.7,.2;.2,.8];
W=[-1.1,-.1;.2,-.9];Pprev=[.8,.1;.1,1.2];gamma=.7;
count=24;substeps=128;duration=.3;
data=struct('t',zeros(1,substeps+1,count),'x',zeros(2,substeps+1,count), ...
 'u',zeros(2,substeps+1,count),'q',zeros(1,substeps+1,count));
previousValueIntegrals=zeros(count,1);
for j=1:count
 t0=.37*j;t=t0+linspace(0,duration,substeps+1);x0=[sin(sqrt(2)*j);cos(sqrt(3)*j)];
 [~,z]=ode45(@rhs,t,[x0;0],odeset('RelTol',1e-12,'AbsTol',1e-13));
 X=z(:,1:2)';U=behavior(t,X);data.t(1,:,j)=t;data.x(:,:,j)=X;data.u(:,:,j)=U;
 data.q(1,:,j)=sum(X.*(Q*X),1);previousValueIntegrals(j)=z(end,3);
end
spec=struct('phi',@(X)[X(1,:).^2;X(2,:).^2;X(1,:).*X(2,:)], ...
 'psi',@(X)X,'R',R);
r=struct('A',A,'B',B,'R',R,'Q',Q,'W',W,'Pprev',Pprev, ...
 'cPrev',[Pprev(1,1);Pprev(2,2);2*Pprev(1,2)],'gamma',gamma, ...
 'previousValueIntegrals',previousValueIntegrals);
 function dz=rhs(t,z)
  x=z(1:2);u=behavior(t,x);dz=[A*x+B*u;exp(-gamma*(t-t0))*(x'*Pprev*x)];
 end
 function u=behavior(t,x)
  u=[.4*sin(1.3*t)+.15*x(1,:);-.6*cos(.7*t)+.2*x(2,:)];
 end
end
function out=subsample(data,stride)
out=data;out.t=data.t(:,1:stride:end,:);out.x=data.x(:,1:stride:end,:);
out.u=data.u(:,1:stride:end,:);out.q=data.q(:,1:stride:end,:);
end
