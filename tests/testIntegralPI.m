function tests = testIntegralPI
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.originalPath = path;
addpath(root,fullfile(root,'src'));
testCase.TestData.baseline = demo_integral_pi(struct('saveOutputs',false));
end

function teardownOnce(testCase)
path(testCase.TestData.originalPath);
end

function testAnalyticLqrReference(testCase)
result = testCase.TestData.baseline;
verifyTrue(testCase,result.learning.converged);
verifyEqual(testCase,result.learning.K,[1,sqrt(3)],'AbsTol',1e-7);
verifyEqual(testCase,result.learning.P,[sqrt(3),1;1,sqrt(3)],'AbsTol',1e-7);
verifyLessThan(testCase,max(real(result.metrics.finalClosedLoopPoles)),0);
verifyFalse(testCase,result.learning.informationContract.receivesA);
end

function testBellmanIdentityAndFrozenEvaluation(testCase)
result = testCase.TestData.baseline;
verifyLessThan(testCase,result.metrics.finalRelativeBellmanResidual,1e-8);
verifyLessThan(testCase,result.metrics.valueIdentityError,1e-8);
for k = 1:numel(result.learning.history)
    entry = result.learning.history{k};
    verifyEqual(testCase,entry.fit.rank,3);
    verifyLessThan(testCase,entry.fit.conditionNumber,1e8);
    verifyLessThan(testCase,entry.fit.relativeResidual,1e-8);
end
evaluation = result.evaluation;
verifyTrue(testCase,evaluation.policyFrozen);
verifyFalse(testCase,evaluation.learningEnabled);
verifyFalse(testCase,evaluation.resetWithinTrajectory);
verifyEqual(testCase,evaluation.u_applied,-evaluation.x*result.learning.K','AbsTol',1e-13);
verifyEqual(testCase,evaluation.u_nominal,evaluation.u_behavior);
verifyEqual(testCase,evaluation.u_behavior,evaluation.u_filtered);
verifyEqual(testCase,evaluation.u_filtered,evaluation.u_applied);
end

function testContinuousFeedbackAgainstMatrixExponential(testCase)
result = testCase.TestData.baseline;
plant = adp.models.doubleIntegrator();
trajectory = result.evaluation;
expected = expm((plant.A-plant.B*result.learning.K)*trajectory.t(end))*trajectory.x(1,:)';
verifyEqual(testCase,trajectory.x(end,:)',expected,'AbsTol',1e-9);
verifyGreaterThan(testCase,norm(diff(trajectory.u_applied),2),1e-3);
config = result.config.evaluation;
config.executionMode = 'zero_order_hold';
verifyError(testCase,@() adp.sim.rollout(plant,result.learning.K,config), ...
    'adp:sim:UnsupportedExecutionMode');
end

function testRankDeficiencyMustFail(testCase)
batch.Phi = repmat([1,2,3],5,1);
batch.y = ones(5,1);
verifyError(testCase,@() adp.learn.fitValue(batch),'adp:learn:RankDeficient');
end

function testIllConditioningMustFail(testCase)
batch.Phi = diag([1,1,1e-10]);
batch.y = ones(3,1);
verifyError(testCase,@() adp.learn.fitValue(batch),'adp:learn:IllConditioned');
end

function testFeatureGradientByFiniteDifference(testCase)
points = [0.4,-0.9;1.3,0.7];
[phi,gradient] = adp.basis.quadratic2(points);
verifySize(testCase,phi,[3,2]);
step = 1e-6;
for sample = 1:size(points,2)
    for coordinate = 1:2
        increment = zeros(2,1);
        increment(coordinate) = step;
        numerical = (adp.basis.quadratic2(points(:,sample)+increment)- ...
            adp.basis.quadratic2(points(:,sample)-increment))/(2*step);
        verifyEqual(testCase,gradient(:,coordinate,sample),numerical,'AbsTol',1e-8);
    end
end
P = [2,-0.3;-0.3,1];
weights = [P(1,1);P(1,2);P(2,2)];
verifyEqual(testCase,weights'*phi,diag(points'*P*points)','AbsTol',1e-13);
end

function testIterationLimitPreservesPolicyValuePair(testCase)
result = testCase.TestData.baseline;
plant = adp.models.doubleIntegrator();
config = result.config.learning;
config.maxIterations = 1;
collector = @(K) adp.sim.collectBatch(plant,K,result.config.collection);
limited = adp.learn.integralPI(collector,plant.B,plant.R,config);
verifyFalse(testCase,limited.converged);
verifyEqual(testCase,limited.status,'max_iterations');
verifyEqual(testCase,limited.K,config.K0);
closedLoop = plant.A-plant.B*limited.K;
residual = closedLoop'*limited.P+limited.P*closedLoop+plant.Q+limited.K'*plant.R*limited.K;
verifyLessThan(testCase,norm(residual,'fro'),1e-8);
end

function testExamplePersistenceDoesNotOverwrite(testCase)
outputRoot = tempname;
mkdir(outputRoot);
temporaryCleanup = onCleanup(@() rmdir(outputRoot,'s')); %#ok<NASGU>
options = struct('saveOutputs',true,'outputRoot',outputRoot,'runId','immutable-test');
[result,runDir] = demo_integral_pi(options);
verifyTrue(testCase,isfile(fullfile(runDir,'result.mat')));
verifyTrue(testCase,isfile(fullfile(runDir,'config.json')));
verifyTrue(testCase,isfile(fullfile(runDir,'summary.json')));
verifyTrue(testCase,isfile(fullfile(runDir,'environment.json')));
loaded = load(fullfile(runDir,'result.mat'),'result');
verifyEqual(testCase,loaded.result.learning.K,result.learning.K);
verifyEqual(testCase,loaded.result.evaluation.u_applied,result.evaluation.u_applied);
environment = jsondecode(fileread(fullfile(runDir,'environment.json')));
verifyEqual(testCase,environment.matlabRelease,version('-release'));
verifyEqual(testCase,environment.architecture,computer('arch'));
before = fileread(fullfile(runDir,'config.json'));
verifyError(testCase,@() adp.io.saveRun(result,outputRoot,'immutable-test'),'adp:io:RunExists');
verifyEqual(testCase,fileread(fullfile(runDir,'config.json')),before);
end
