function [result, runDir] = demo_integral_pi(options)
%DEMO_INTEGRAL_PI Original base-MATLAB CT integral policy-iteration example.
% [result,runDir]=demo_integral_pi() runs, evaluates and saves a new run.
% options.saveOutputs=false avoids writing files. options.outputRoot and
% options.runId select the new output location; existing runs are refused.
% No third-party code, Control Toolbox, NN Toolbox or Optimization Toolbox.
if nargin < 1, options = struct(); end
allowed = {'saveOutputs','outputRoot','runId'};
unknown = setdiff(fieldnames(options),allowed);
if ~isempty(unknown)
    error('adp:demo:UnknownOption','Unknown option: %s',unknown{1});
end
root = fileparts(mfilename('fullpath'));
oldPath = path;
pathCleanup = onCleanup(@() path(oldPath)); %#ok<NASGU>
addpath(fullfile(root,'src'));
if ~isfield(options,'saveOutputs'), options.saveOutputs = true; end
if ~isfield(options,'outputRoot'), options.outputRoot = fullfile(root,'runs'); end
if ~isfield(options,'runId'), options.runId = ''; end
validateattributes(options.saveOutputs, {'logical'}, {'scalar'});
oldRandomState = rng;
randomCleanup = onCleanup(@() rng(oldRandomState)); %#ok<NASGU>
rng(0,'twister');
plant = adp.models.doubleIntegrator();
config.name = 'original_ct_on_policy_integral_pi_double_integrator';
config.seed = 0;
config.randomAlgorithm = 'twister';
config.randomDrawsUsed = false;
config.initialRandomState = rng;
config.stateConvention = 'single state is a column; stored trajectories use rows';
config.costConvention = 'undiscounted x''*Q*x+u''*R*u, no half factor';
config.executionMode = 'continuous_feedback';
config.plant = rmfield(plant,{'dynamics','stageCost'});
config.learning.K0 = [1,2];
config.learning.maxIterations = 20;
config.learning.policyTolerance = 1e-9;
config.learning.fit.relativeRankTolerance = 1e-12;
config.learning.fit.conditionLimit = 1e8;
config.collection.initialStates = [1,0,1,-1,0.5,-1;0,1,1,1,-1,0.5];
config.collection.simulation.executionMode = 'continuous_feedback';
config.collection.simulation.outputTimes = linspace(0,0.25,26);
config.collection.simulation.relativeTolerance = 1e-10;
config.collection.simulation.absoluteTolerance = 1e-12;
config.collection.simulation.maxStep = 0.01;
config.evaluation = config.collection.simulation;
config.evaluation.outputTimes = linspace(0,8,401);
config.evaluation.x0 = [1;-1];

% A is used by this experiment's oracle, never passed into the learner.
initialPoles = eig(plant.A-plant.B*config.learning.K0);
if any(real(initialPoles) >= 0)
    error('adp:demo:InitialPolicyNotAdmissible','The selected initial gain is not Hurwitz.');
end
collector = @(K) adp.sim.collectBatch(plant,K,config.collection);
learning = adp.learn.integralPI(collector,plant.B,plant.R,config.learning);
if ~learning.converged
    error('adp:demo:NoConvergence','Policy iteration exhausted %d iterations.',learning.iterations);
end
reference.P = [sqrt(3),1;1,sqrt(3)];
reference.K = [1,sqrt(3)];
reference.origin = 'analytic CARE solution for this explicit benchmark';
reference.dataUsedForLearning = false;
evaluation = adp.sim.rollout(plant,learning.K,config.evaluation);
referenceEvaluation = adp.sim.rollout(plant,reference.K,config.evaluation);
metrics.gainErrorFro = norm(learning.K-reference.K,'fro');
metrics.valueErrorFro = norm(learning.P-reference.P,'fro');
metrics.finalRelativeBellmanResidual = learning.finalFit.relativeResidual;
metrics.finalRegressionCondition = learning.finalFit.conditionNumber;
metrics.finalClosedLoopPoles = eig(plant.A-plant.B*learning.K);
metrics.finiteHorizonSeconds = config.evaluation.outputTimes(end);
metrics.learnedFiniteHorizonCost = evaluation.integratedCost(end);
metrics.referenceFiniteHorizonCost = referenceEvaluation.integratedCost(end);
metrics.referenceInfiniteHorizonValue = config.evaluation.x0'*reference.P*config.evaluation.x0;
metrics.learnedValueAtInitialState = config.evaluation.x0'*learning.P*config.evaluation.x0;
endState = evaluation.x(end,:)';
metrics.learnedTailValue = endState'*learning.P*endState;
metrics.learnedFinitePlusTail = metrics.learnedFiniteHorizonCost+metrics.learnedTailValue;
metrics.valueIdentityError = abs(metrics.learnedFinitePlusTail-metrics.learnedValueAtInitialState);
result.config = config;
result.learning = learning;
result.reference = reference;
result.evaluation = evaluation;
result.referenceEvaluation = referenceEvaluation;
result.metrics = metrics;
result.initialPolicyCheck = struct('poles',initialPoles,'method','eig(A-B*K0) outside learner');
result.environment.matlabVersion = version;
result.environment.matlabRelease = version('-release');
result.environment.architecture = computer('arch');
result.environment.computer = computer;
result.environment.products = ver;
result.environment.createdUTC = char(datetime('now','TimeZone','UTC', ...
    'Format',"yyyy-MM-dd'T'HH:mm:ss.SSSXXX"));
result.environment.finalRandomState = rng;
result.sourceVersion = struct('referenceVersion','0.2.0', ...
    'methodVersion','ct-on-policy-integral-pi-quadratic2-v1', ...
    'upstreamCodeImported',false,'implementation','original MATLAB reference baseline');
result.scope = ['Two-state linear-quadratic simulation benchmark with known B. ', ...
    'Independent resettable training segments, continuous state feedback, ', ...
    'no safety filter, no actuator limits, no hardware claim and no paper-reproduction claim.'];
runDir = '';
if options.saveOutputs
    runDir = adp.io.saveRun(result,options.outputRoot,options.runId);
    adp.io.sealRun(runDir,root);
end
fprintf('Integral PI: %d iterations, gain error %.3g, value error %.3g, Bellman residual %.3g.\n', ...
    learning.iterations,metrics.gainErrorFro,metrics.valueErrorFro,metrics.finalRelativeBellmanResidual);
if ~isempty(runDir), fprintf('Saved new run: %s\n',runDir); end
end
