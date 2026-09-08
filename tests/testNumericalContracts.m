function tests = testNumericalContracts
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.baseline = demo_integral_pi(struct('saveOutputs',false));
end

function testEmptyUnderdeterminedAndZeroData(testCase)
for n = [0,1,2,5]
    batch.Phi = zeros(n,3);
    batch.y = zeros(n,1);
    verifyError(testCase,@() adp.learn.fitValue(batch),'adp:learn:RankDeficient');
end
batch.Phi = [1,0,0;0,1,0]; batch.y = [1;1];
verifyError(testCase,@() adp.learn.fitValue(batch),'adp:learn:RankDeficient');
end

function testNonfiniteRegressionData(testCase)
for bad = [NaN,Inf,-Inf]
    batch.Phi = eye(3); batch.y = ones(3,1);
    batch.Phi(1,1) = bad;
    verifyError(testCase,@() adp.learn.fitValue(batch),'MATLAB:expectedFinite');
    batch.Phi = eye(3); batch.y(2) = bad;
    verifyError(testCase,@() adp.learn.fitValue(batch),'MATLAB:expectedFinite');
end
end

function testRankThresholdIsRelativeAndStrict(testCase)
options = struct('relativeRankTolerance',1e-6,'conditionLimit',1e8);
batch.Phi = diag([1,0.1,1e-6]); batch.y = batch.Phi*[2;0.2;1];
verifyError(testCase,@() adp.learn.fitValue(batch,options),'adp:learn:RankDeficient');
batch.Phi(3,3) = 2e-6; batch.y = batch.Phi*[2;0.2;1];
[value,diagnostics] = adp.learn.fitValue(batch,options);
verifyEqual(testCase,value.weights,[2;0.2;1],'AbsTol',1e-12);
verifyEqual(testCase,diagnostics.rank,3);
verifyEqual(testCase,diagnostics.rankThreshold,1e-6,'AbsTol',eps);
end

function testConditionThresholdBoundary(testCase)
options = struct('relativeRankTolerance',1e-12,'conditionLimit',100);
batch.Phi = diag([1,0.1,0.01]); batch.y = batch.Phi*[2;0.2;1];
[~,diagnostics] = adp.learn.fitValue(batch,options);
verifyEqual(testCase,diagnostics.conditionNumber,100,'AbsTol',1e-10);
batch.Phi(3,3) = 0.009; batch.y = batch.Phi*[2;0.2;1];
verifyError(testCase,@() adp.learn.fitValue(batch,options),'adp:learn:IllConditioned');
end

function testRegressionScalingAndNoisyResidual(testCase)
Phi = [1,0,0;0,1,0;0,0,1;1,1,1;1,-1,2];
trueWeights = [2;0.2;1];
y = Phi*trueWeights+[0.01;-0.02;0.01;0.03;-0.01];
for scale = [1e-30,1e-6,1,1e6]
    batch = struct('Phi',scale*Phi,'y',scale*y);
    [fit,diagnostics] = adp.learn.fitValue(batch);
    verifyEqual(testCase,fit.weights,Phi\y,'AbsTol',1e-10);
    verifyLessThan(testCase,norm(Phi'*(Phi*fit.weights-y)),1e-11);
    verifyGreaterThan(testCase,diagnostics.relativeResidual,1e-4);
end
end

function testRequiredTargetAndBehaviorPolicyStamps(testCase)
baseline = testCase.TestData.baseline;
config = baseline.config.learning;
config.maxIterations = 1;
K = config.K0;
batch = syntheticBatch(K,eye(2));
for field = {'policyK','targetPolicyK','behaviorPolicyK','onPolicy'}
    missing = rmfield(batch,field{1});
    verifyError(testCase,@() adp.learn.integralPI(@(~) missing,[0;1],1,config), ...
        'adp:learn:PolicyMismatch');
end
for field = {'policyK','targetPolicyK','behaviorPolicyK'}
    wrong = batch; wrong.(field{1}) = K+[0,0.1];
    verifyError(testCase,@() adp.learn.integralPI(@(~) wrong,[0;1],1,config), ...
        'adp:learn:PolicyMismatch');
end
batch.onPolicy = false;
verifyError(testCase,@() adp.learn.integralPI(@(~) batch,[0;1],1,config), ...
    'adp:learn:PolicyMismatch');
end

function testExecutionStampMustMatchIdentity(testCase)
config = testCase.TestData.baseline.config.learning;
batch = syntheticBatch(config.K0,eye(2));
batch.executionMode = 'zero_order_hold';
verifyError(testCase,@() adp.learn.integralPI(@(~) batch,[0;1],1,config), ...
    'adp:learn:ExecutionMismatch');
end

function testExecutedInputMismatchCannotBeRelabeledOnPolicy(testCase)
baseline = testCase.TestData.baseline;
config = baseline.config.learning;
config.maxIterations = 1;
plant = adp.models.doubleIntegrator();
batch = adp.sim.collectBatch(plant,config.K0,baseline.config.collection);
batch.trajectories{1}.u_applied(2,1) = batch.trajectories{1}.u_applied(2,1)+0.1;
verifyError(testCase,@() adp.learn.integralPI(@(~) batch,[0;1],1,config), ...
    'adp:learn:InputMismatch');
end

function testStaleRegressionAndTrajectoryStampMustFail(testCase)
baseline = testCase.TestData.baseline;
config = baseline.config.learning;
config.maxIterations = 1;
plant = adp.models.doubleIntegrator();
batch = adp.sim.collectBatch(plant,config.K0,baseline.config.collection);
stale = batch; stale.y(1) = stale.y(1)+1;
verifyError(testCase,@() adp.learn.integralPI(@(~) stale,[0;1],1,config), ...
    'adp:learn:DataMismatch');
stale = batch; stale.Phi(2,2) = stale.Phi(2,2)+1;
verifyError(testCase,@() adp.learn.integralPI(@(~) stale,[0;1],1,config), ...
    'adp:learn:DataMismatch');
stale = batch; stale.trajectories{1}.policyFrozen = false;
verifyError(testCase,@() adp.learn.integralPI(@(~) stale,[0;1],1,config), ...
    'adp:learn:PolicyMismatch');
end

function testConsistencyToleranceRespectsTinyDataScale(testCase)
baseline = testCase.TestData.baseline; config = baseline.config.learning;
config.maxIterations = 1; plant = adp.models.doubleIntegrator();
collection = baseline.config.collection;
collection.initialStates = 1e-10*collection.initialStates;
batch = adp.sim.collectBatch(plant,config.K0,collection);
batch.y = 2*batch.y;
verifyError(testCase,@() adp.learn.integralPI(@(~) batch,plant.B,plant.R,config), ...
    'adp:learn:DataMismatch');
collection.initialStates = 1e-20*baseline.config.collection.initialStates;
batch = adp.sim.collectBatch(plant,config.K0,collection);
batch.trajectories{1}.u_applied = 2*batch.trajectories{1}.u_applied;
verifyError(testCase,@() adp.learn.integralPI(@(~) batch,plant.B,plant.R,config), ...
    'adp:learn:InputMismatch');
end

function testCostParameterCannotDifferFromCollectedCost(testCase)
baseline = testCase.TestData.baseline; config = baseline.config.learning;
config.maxIterations = 100; plant = adp.models.doubleIntegrator();
collector = @(K) adp.sim.collectBatch(plant,K,baseline.config.collection);
verifyError(testCase,@() adp.learn.integralPI(collector,plant.B,2,config), ...
    'adp:learn:CostMismatch');
end

function testInputMatrixParameterCannotDifferFromCollector(testCase)
baseline = testCase.TestData.baseline; config = baseline.config.learning;
config.maxIterations = 1; plant = adp.models.doubleIntegrator();
collector = @(K) adp.sim.collectBatch(plant,K,baseline.config.collection);
verifyError(testCase,@() adp.learn.integralPI(collector,2*plant.B,plant.R,config), ...
    'adp:learn:InputMatrixMismatch');
end

function testChangedCostMetadataRequiresChangedCallback(testCase)
baseline = testCase.TestData.baseline; config = baseline.config.learning;
config.maxIterations = 1; plant = adp.models.doubleIntegrator();
plant.R = 2; % Deliberately leave the original R=1 stageCost callback intact.
collector = @(K) adp.sim.collectBatch(plant,K,baseline.config.collection);
verifyError(testCase,@() adp.learn.integralPI(collector,plant.B,plant.R,config), ...
    'adp:learn:CostMismatch');
end

function testNonpositiveValueMustStopUpdate(testCase)
config = testCase.TestData.baseline.config.learning;
for P = {-[1,0;0,1],[1,0;0,0],[1,2;2,1]}
    batch = syntheticBatch(config.K0,P{1});
    verifyError(testCase,@() adp.learn.integralPI(@(~) batch,[0;1],1,config), ...
        'adp:learn:NonpositiveValue');
end
end

function testInadmissibleInitialPolicyFailsOnRealCollectedData(testCase)
baseline = testCase.TestData.baseline;
plant = adp.models.doubleIntegrator();
config = baseline.config.learning; config.K0 = [-1,-1];
verifyGreaterThan(testCase,max(real(eig(plant.A-plant.B*config.K0))),0);
collector = @(K) adp.sim.collectBatch(plant,K,baseline.config.collection);
verifyError(testCase,@() adp.learn.integralPI(collector,plant.B,plant.R,config), ...
    'adp:learn:NonpositiveValue');
end

function testInvalidInputCostAndIterationBudget(testCase)
config = testCase.TestData.baseline.config.learning;
collector = @(K) syntheticBatch(K,eye(2));
for R = [0,-1]
    verifyError(testCase,@() adp.learn.integralPI(collector,[0;1],R,config), ...
        'adp:learn:InvalidInputCost');
end
twoInput = config; twoInput.K0 = eye(2);
for invalidR = {[1,0.1;0,1],1e-20*[1,0.1;0,1]}
    verifyError(testCase,@() adp.learn.integralPI(collector,eye(2),invalidR{1},twoInput), ...
        'adp:learn:InvalidInputCost');
end
for budget = [0,-1,1.5,NaN,Inf]
    invalid = config; invalid.maxIterations = budget;
    failure = captureFailure(@() adp.learn.integralPI(collector,[0;1],1,invalid));
    verifyNotEmpty(testCase,failure,'An invalid iteration budget must fail before collection.');
end
end

function testLinearLqrSensitivityCampaign(testCase)
baseline = testCase.TestData.baseline;
plant = adp.models.doubleIntegrator();
scenarios = { ...
    struct('name','soft_initial_gain','K0',[0.25,0.5],'scale',1,'horizon',0.25,'relTol',1e-10,'maxStep',0.01), ...
    struct('name','large_initial_gain','K0',[3,4],'scale',1,'horizon',0.25,'relTol',1e-10,'maxStep',0.01), ...
    struct('name','small_states_short_segments','K0',[1,2],'scale',0.01,'horizon',0.025,'relTol',1e-10,'maxStep',0.002), ...
    struct('name','large_states_long_segments','K0',[1,2],'scale',10,'horizon',1,'relTol',1e-10,'maxStep',0.02), ...
    struct('name','coarse_solver','K0',[1,2],'scale',1,'horizon',0.25,'relTol',1e-5,'maxStep',0.1), ...
    struct('name','fine_solver','K0',[1,2],'scale',1,'horizon',0.25,'relTol',1e-12,'maxStep',0.002)};
for k = 1:numel(scenarios)
    scenario = scenarios{k};
    config = baseline.config.learning; config.K0 = scenario.K0;
    collection = baseline.config.collection;
    collection.initialStates = scenario.scale*collection.initialStates;
    collection.simulation.outputTimes = linspace(0,scenario.horizon,26);
    collection.simulation.relativeTolerance = scenario.relTol;
    collection.simulation.absoluteTolerance = min(1e-12,scenario.relTol*1e-3);
    collection.simulation.maxStep = scenario.maxStep;
    learning = adp.learn.integralPI(@(K) adp.sim.collectBatch(plant,K,collection), ...
        plant.B,plant.R,config);
    gainError = norm(learning.K-[1,sqrt(3)]);
    valueError = norm(learning.P-[sqrt(3),1;1,sqrt(3)],'fro');
    verifyTrue(testCase,learning.converged,scenario.name);
    verifyLessThan(testCase,gainError,2e-5,scenario.name);
    verifyLessThan(testCase,valueError,2e-5,scenario.name);
    verifyEqual(testCase,learning.finalFit.rank,3,scenario.name);
    record = scenario; record.gainError = gainError; record.valueError = valueError;
    record.iterations = learning.iterations; record.condition = learning.finalFit.conditionNumber;
    record.relativeResidual = learning.finalFit.relativeResidual;
    fprintf('ADP_SENSITIVITY %s\n',jsonencode(record));
end
end

function testOutputGridAndInitialStateAgainstIndependentSolution(testCase)
baseline = testCase.TestData.baseline;
plant = adp.models.doubleIntegrator(); K = [1.7,2.4];
config = baseline.config.evaluation;
config.outputTimes = [0,1.7];
for x0 = {[2;-0.5],[-1;3],[0;0]}
    config.x0 = x0{1};
    coarse = adp.sim.rollout(plant,K,config);
    denseConfig = config; denseConfig.outputTimes = linspace(0,1.7,103);
    dense = adp.sim.rollout(plant,K,denseConfig);
    expected = expm((plant.A-plant.B*K)*1.7)*x0{1};
    verifyEqual(testCase,coarse.x(end,:)',expected,'AbsTol',1e-8);
    verifyEqual(testCase,dense.x(end,:)',expected,'AbsTol',1e-8);
    verifyEqual(testCase,dense.integratedCost(end),coarse.integratedCost(end),'AbsTol',1e-8);
end
end

function testInvalidTimesAndTolerances(testCase)
baseline = testCase.TestData.baseline; plant = adp.models.doubleIntegrator();
for times = {[0,0.1,0.1],[0,1,0.5],0}
    config = baseline.config.evaluation; config.outputTimes = times{1};
    verifyError(testCase,@() adp.sim.rollout(plant,[1,2],config),'adp:sim:InvalidTimes');
end
for field = {'relativeTolerance','absoluteTolerance','maxStep'}
    config = baseline.config.evaluation; config.(field{1}) = 0;
    verifyNotEmpty(testCase,captureFailure(@() adp.sim.rollout(plant,[1,2],config)));
end
end

function testSparseQuadratureIsDifferentFromAugmentedCost(testCase)
plant = adp.models.doubleIntegrator();
config = testCase.TestData.baseline.config.evaluation;
config.x0 = [2;0.7]; config.outputTimes = linspace(0,1.6,801);
trajectory = adp.sim.rollout(plant,[1,2],config);
errors = zeros(1,5); counts = [6,11,41,161,801];
for k = 1:numel(counts)
    indices = round(linspace(1,801,counts(k)));
    estimate = trapz(trajectory.t(indices),trajectory.stageCost(indices));
    errors(k) = abs(estimate-trajectory.integratedCost(end));
end
verifyGreaterThan(testCase,errors(1),1e-4);
verifyLessThan(testCase,errors(end),errors(1)/100);
verifyTrue(testCase,all(diff(errors)<0));
verifyEqual(testCase,trajectory.integralSource,'ode_augmented_state');
verifyEmpty(testCase,trajectory.integrationErrorBound);
fprintf('ADP_QUADRATURE %s\n',jsonencode(struct('sampleCounts',counts, ...
    'absoluteErrors',errors,'reference','ode augmented cost, not a proven exact integral')));
end

function batch = syntheticBatch(K,P)
batch = struct('Phi',eye(3),'y',[P(1,1);P(1,2);P(2,2)], ...
    'policyK',K,'targetPolicyK',K,'behaviorPolicyK',K, ...
    'onPolicy',true,'executionMode','continuous_feedback');
batch.inputMatrix = [0;1];
batch.costContract = struct('type','quadratic_no_half','Q',eye(2),'R',1,'discountRate',0);
end

function identifier = captureFailure(action)
identifier = '';
try, action(); catch exception, identifier = exception.identifier; end
end
