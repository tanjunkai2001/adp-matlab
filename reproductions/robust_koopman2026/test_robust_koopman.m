function tests=test_robust_koopman
tests=functiontests(localfunctions);
end
function setupOnce(tc)
tc.TestData.result=demo_robust_koopman(struct('saveOutputs',false));
end
function testAnalyticHalfCostHjbAndValue(tc)
x=[-1.5,-1.2;-.5,1.2;1.5,-.6;1.2,.9;.2,-1.4;-1.2,.6];
f=[-x(:,1)+x(:,2),-.5*(x(:,1)+x(:,2))+.5*x(:,1).^2.*x(:,2)];
p=[.5*x(:,1),x(:,2)];u=-x(:,1).*x(:,2);
residual=sum(p.*f,2)+.5*sum(x.^2,2)-.5*u.^2;
verifyLessThan(tc,max(abs(residual)),1e-14);
r=tc.TestData.result;verifyLessThan(tc,r.metrics.maxOracleValueError,1e-6);
verifyEqual(tc,r.metrics.actualOptimalValues,[1.2825;.7825;.7425;.765;.99;.54],'AbsTol',1e-14);
end
function testLiftAndAmbientValueDerivatives(tc)
x=[.2,-.3;-.8,.7];[z,D1,D2]=rk_lift(x);h=1e-6;
for j=1:2
 offset=zeros(size(x));offset(:,j)=h;
 estimate=(rk_lift(x+offset)-rk_lift(x-offset))/(2*h);
 if j==1,exact=D1;else,exact=D2;end
 verifyLessThan(tc,max(abs(estimate-exact),[],'all'),1e-9);
end
[P,D,lap,pairs]=rk_basis(z);verifyEqual(tc,size(pairs,1),25);
second=zeros(size(P));
for j=1:9
 offset=zeros(size(z));offset(:,j)=h;
 plus=rk_basis(z+offset);minus=rk_basis(z-offset);
 verifyLessThan(tc,max(abs((plus-minus)/(2*h)-D(:,:,j)),[],'all'),1e-9);
 second=second+(plus-2*P+minus)/h^2;
end
verifyLessThan(tc,max(abs(second-lap),[],'all'),1e-3);
end
function testBilinearDerivativeRegressionOnExactModel(tc)
s=(1:500)';x=[sin(s*sqrt(2)),cos(s*sqrt(3))];u=sin(s*sqrt(5));
xdot=[-x(:,1)+x(:,2),-.5*(x(:,1)+x(:,2))+x(:,1).*u];
fit=rk_identify(struct('x',x,'u',u,'xdot',xdot));
z=rk_lift(x);predicted=z*fit.A'+u.*(z*fit.B1'+fit.B0');
verifyEqual(tc,predicted(:,1:2),xdot,'AbsTol',1e-12);
verifyEqual(tc,fit.rank,19);verifyLessThan(tc,fit.c1,1e-12);
end
function testSubgradientControlBothBranches(tc)
r=tc.TestData.result;solution=r.robust;
x=[0,0;0,.7;.5,.7;-.5,.7;1.2,-.8];
[u,p,a]=rk_control(solution,x);b=solution.c2*vecnorm(p,2,2);
verifyEqual(tc,u(1),0,'AbsTol',eps);verifyTrue(tc,all(isfinite(u)));
active=abs(u)>1e-12;
verifyLessThan(tc,max(abs(solution.R*u(active)+a(active)+b(active).*sign(u(active)))),1e-12);
verifyTrue(tc,all(abs(a(~active))<=b(~active)+1e-12));
% For scalar convex Hamiltonians, independently compare a dense control grid.
for j=2:size(x,1)
 grid=linspace(u(j)-2,u(j)+2,20001)';
 costs=.5*solution.R*grid.^2+a(j)*grid+b(j)*abs(grid);
 chosen=.5*solution.R*u(j)^2+a(j)*u(j)+b(j)*abs(u(j));
 verifyLessThanOrEqual(tc,chosen,min(costs)+1e-10);
end
end
function testInvalidRegressionRejected(tc)
r=tc.TestData.result;data=r.data;data.x(:)=0;data.u(:)=0;
verifyError(tc,@()rk_identify(data),'robustkoopman:Rank');
data=r.data;data.xdot(1)=NaN;
verifyError(tc,@()rk_identify(data),'MATLAB:expectedFinite');
end
function testBoundIsSampleFitAndNotCertificate(tc)
r=tc.TestData.result;z=r.model.z;
left=vecnorm(r.model.residual,2,2);right=r.model.c1*vecnorm(z,2,2)+r.model.c2*abs(r.data.u);
verifyLessThanOrEqual(tc,max(left-right),1e-12);
verifySubstring(tc,r.model.boundStatus,'training');
verifyFalse(tc,isfield(r.solverConfig,'noiseAmplitude'));
verifyFalse(tc,isfield(r.model,'analyticValue'));
end
function testExecutedNonlinearScenario(tc)
r=tc.TestData.result;
verifyTrue(tc,all(isfinite(r.metrics.robustCosts)));
verifyLessThan(tc,r.metrics.robustMaxTerminalNorm,0.01);
verifyLessThan(tc,r.metrics.robustPdeRms,0.1);
verifyEqual(tc,r.trajectories.robust.u_applied,r.trajectories.robust.u_nominal);
verifyFalse(tc,r.trajectories.robust.learningEnabled);
end
function testViscosityAndZeroUncertaintyLimits(tc)
r=tc.TestData.result;c=r.solverConfig;c.c1=0;c.c2=0;
values=zeros(1,3);policies=cell(1,3);
for k=1:3
 allEpsilon=[0,1e-4,1e-3];c.epsilon=allEpsilon(k);
 solution=rk_solve(r.model,r.collocation,c);
 values(k)=solution.residualRms;policies{k}=rk_control(solution,r.initialStates);
 verifyTrue(tc,solution.converged);verifyLessThan(tc,solution.residualRms,0.01);
end
verifyGreaterThan(tc,norm(policies{3}-policies{1}),1e-6);
fprintf('ROBUST_KOOPMAN_EPSILON %s\n',jsonencode(struct('epsilon',[0,1e-4,1e-3],'nominalResidualRms',values)));
end
