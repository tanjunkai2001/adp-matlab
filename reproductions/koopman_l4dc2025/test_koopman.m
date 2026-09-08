function tests=test_koopman
tests=functiontests(localfunctions);
end
function setupOnce(testCase)
testCase.TestData.result=demo_koopman(struct('saveOutputs',false));
end
function testHeldOutIdentificationAndFrozenControl(testCase)
r=testCase.TestData.result; m=r.metrics;
verifyLessThan(testCase,m.Ef,0.02); verifyLessThan(testCase,m.Eg,0.02);
verifyEqual(testCase,m.dictionaryRank,71);
verifyLessThan(testCase,m.learnedMeanCost,m.initialMeanCost);
verifyLessThan(testCase,m.meanCostGap,0.02);
verifyLessThan(testCase,m.maximumTerminalNorm,0.002);
verifyLessThan(testCase,m.trueHjbResidualRms,0.03);
verifyFalse(testCase,r.rollouts.learned.learningEnabled);
verifyEqual(testCase,r.rollouts.learned.u_applied,r.rollouts.learned.u_nominal);
verifyEqual(testCase,r.learned.modelKnowledge,'identified_control_affine');
verifyEqual(testCase,r.oracle.modelKnowledge,'oracle_pendulum');
end
function testAnchoredFeatureGradient(testCase)
f=testCase.TestData.result.features; x=[0.23,-0.51;-0.61,0.4];
[~,D1,D2]=koopman_features(f,x); delta=1e-6;
for k=1:2
    offset=zeros(size(x)); offset(:,k)=delta;
    numerical=(koopman_features(f,x+offset)-koopman_features(f,x-offset))/(2*delta);
    if k==1, expected=D1; else, expected=D2; end
    verifyLessThan(testCase,max(abs(numerical-expected),[],'all'),2e-8);
end
[P,D1,D2]=koopman_features(f,[0,0]);
verifyEqual(testCase,P,zeros(size(P)),'AbsTol',1e-15);
verifyEqual(testCase,D1,zeros(size(D1)),'AbsTol',1e-15);
verifyEqual(testCase,D2,zeros(size(D2)),'AbsTol',1e-15);
end
function testAnalyticYosidaGeneratorAndQuadrature(testCase)
A=[0,1,0;1,-1,1;0,0,0];
x0=[linspace(-0.9,0.9,40)',sin((1:40)'),cos((1:40)')];
errors=zeros(1,2);
for q=1:2
    dt=0.02/q; t=0:dt:1; data=struct('t',t,'u',x0(:,3), ...
        'x',zeros(40,2,numel(t)),'executionMode','constant_input_per_trajectory');
    for j=1:numel(t), z=x0*expm(A*t(j))'; data.x(:,:,j)=z(:,1:2); end
    c=struct('degree',1,'lambda',1000,'rankTolerance',1e-12);
    fit=koopman_identify(data,c); [f,g]=koopman_model(fit,x0(:,1:2));
    exact=c.lambda^2*((c.lambda*eye(3)-A)\(eye(3)-expm((A-c.lambda*eye(3))*t(end))))-c.lambda*eye(3);
    expected=x0*exact(1:2,:)'; actual=f+g.*data.u;
    errors(q)=max(abs(actual-expected),[],'all');
end
verifyLessThan(testCase,errors(2),1e-5);
verifyLessThan(testCase,errors(2),errors(1)/4);
fprintf('KOOPMAN_LINEAR_QUADRATURE %s\n',jsonencode(errors));
end
function testStateInputCouplingIsActuallyIdentified(testCase)
n=200; s=(1:n)'; x0=[sin(s),cos(s*sqrt(2))]; u=sin(s*sqrt(3)); t=0:0.01:1;
data=struct('t',t,'u',u,'x',zeros(n,2,numel(t)), ...
    'executionMode','constant_input_per_trajectory');
% Independent exact flow: x1dot=-x1, x2dot=-x2+(1+0.5*x1^2)*u.
for j=1:numel(t)
    e=exp(-t(j));
    data.x(:,:,j)=[e*x0(:,1),e*x0(:,2)+u*(1-e)+0.5*u.*x0(:,1).^2*(e-e^2)];
end
fit=koopman_identify(data,struct('degree',2,'lambda',1000,'rankTolerance',1e-11));
[~,g]=koopman_model(fit,[0,0;1,0]);
verifyGreaterThan(testCase,g(2,2)-g(1,2),0.49);
verifyLessThan(testCase,abs(g(2,2)-1.5),0.003);
end
function testRankAndNonfiniteFailure(testCase)
r=testCase.TestData.result; data=r.rawData;
data.x(:)=0; data.u(:)=0;
verifyError(testCase,@()koopman_identify(data,r.config),'koopman:RankDeficient');
data=r.rawData; data.x(1)=NaN;
verifyError(testCase,@()koopman_identify(data,r.config),'MATLAB:expectedFinite');
data=r.rawData; data.executionMode='feedback_changed_during_identification';
verifyError(testCase,@()koopman_identify(data,r.config),'koopman:InputContract');
end
function testIndependentOde45AgainstRK4(testCase)
r=testCase.TestData.result; c=r.config; c.horizon=2;
trajectory=koopman_rollout(r.learned.policy,[0.7,-0.5],c);
[~,z]=ode45(@rhs,[0,2],[0.7;-0.5;0],odeset('RelTol',1e-11,'AbsTol',1e-13));
verifyEqual(testCase,squeeze(trajectory.x(:,:,end)),z(end,1:2),'AbsTol',2e-8);
verifyEqual(testCase,trajectory.integratedCost(end),z(end,3),'AbsTol',2e-8);
    function dz=rhs(~,state)
        x=state(1:2)'; u=koopman_policy(r.learned.policy,x);
        dz=[x(2);sin(x(1))-c.damping*x(2)+u;x*c.Q*x'+c.R*u^2];
    end
end
function testKnownTruthFieldsAreNotLearnerInputs(testCase)
r=testCase.TestData.result; data=r.rawData;
data.truthCallback=@()error('koopman:TruthLeak','Learner accessed simulator truth');
model=koopman_identify(data,r.config);
verifyEqual(testCase,model.coefficients,r.model.coefficients,'AbsTol',1e-12);
verifyFalse(testCase,isfield(model,'truthCallback'));
verifyFalse(testCase,isfield(r.identificationConfig,'damping'));
verifyFalse(testCase,isfield(r.policyIterationConfig,'damping'));
verifyEqual(testCase,sort(fieldnames(r.identificationConfig)),sort({'degree';'lambda';'rankTolerance'}));
end
function testDomainAndPolicyIterationSensitivity(testCase)
r=testCase.TestData.result;
for lambda=[20,100,1000]
    c=r.config; c.lambda=lambda;
    model=koopman_identify(r.rawData,c);
    [f,g]=koopman_model(model,r.heldout);
    ftrue=[r.heldout(:,2),sin(r.heldout(:,1))-c.damping*r.heldout(:,2)];
    Ef=mean(sum(abs(f-ftrue),2)); Eg=mean(sum(abs(g-[0,1]),2));
    fprintf('KOOPMAN_LAMBDA %s\n',jsonencode(struct('lambda',lambda,'Ef',Ef,'Eg',Eg)));
    verifyLessThan(testCase,Ef,0.15); verifyLessThan(testCase,Eg,0.15);
end
c=r.config; c.K0=[5,4]; c.iterations=12;
solution=koopman_policy_iteration(r.model,r.features,r.collocation,c);
u=koopman_policy(solution.policy,r.heldout); original=koopman_policy(r.learned.policy,r.heldout);
verifyLessThan(testCase,sqrt(mean((u-original).^2)),0.01);
end
