function learning = integralPI(collector, B, R, config)
%INTEGRALPI CT on-policy integral policy iteration with a known input matrix.
% collector(K) returns an IntegralBatch from the fixed policy u=-K*x.
% This learner does not receive A. Its greedy map requires known B and R.
% An admissible initial K and valid on-policy data are caller obligations.
% This implementation is two-state, linear-quadratic and undiscounted.
validateattributes(collector, {'function_handle'}, {'scalar'});
validateattributes(B, {'double'}, {'real','finite','2d','nrows',2,'nonempty'});
nu = size(B,2);
validateattributes(R, {'double'}, {'real','finite','size',[nu,nu]});
if norm(R-R','fro') > 64*eps(max(abs(R(:))))
    error('adp:learn:InvalidInputCost','R must be symmetric positive definite.');
end
[~,cholFlag] = chol(R);
if cholFlag ~= 0
    error('adp:learn:InvalidInputCost','R must be symmetric positive definite.');
end
validateattributes(config.K0, {'double'}, {'real','finite','size',[nu,2]});
validateattributes(config.maxIterations, {'double'}, ...
    {'real','finite','scalar','integer','positive'});
validateattributes(config.policyTolerance, {'double'}, ...
    {'real','finite','scalar','positive'});
K = config.K0;
history = cell(config.maxIterations,1);
converged = false;
for iteration = 1:config.maxIterations
    batch = collector(K);
    if ~isfield(batch,'policyK') || ~isequal(batch.policyK,K) || ...
            ~isfield(batch,'targetPolicyK') || ~isequal(batch.targetPolicyK,K) || ...
            ~isfield(batch,'behaviorPolicyK') || ~isequal(batch.behaviorPolicyK,K) || ...
            ~isfield(batch,'onPolicy') || ~isequal(batch.onPolicy,true)
        error('adp:learn:PolicyMismatch', ...
            'Collector must identify equal policyK, targetPolicyK and behaviorPolicyK, and onPolicy=true.');
    end
    if ~isfield(batch,'executionMode') || ...
            ~strcmp(batch.executionMode,'continuous_feedback')
        error('adp:learn:ExecutionMismatch', ...
            'The current integral identity requires continuous state feedback.');
    end
    validateProblemContract(batch,B,R);
    inputConsistency = validateRecordedData(batch,K);
    [value,diagnostics] = adp.learn.fitValue(batch,config.fit);
    [~,positiveFlag] = chol(value.P);
    if positiveFlag ~= 0
        error('adp:learn:NonpositiveValue', ...
            'The fitted P is not positive definite; strategy update rejected.');
    end
    improvedK = R\(B'*value.P);
    policyChange = norm(improvedK-K,'fro');
    entry.iteration = iteration;
    entry.policyK = K;
    entry.value = value;
    entry.improvedK = improvedK;
    entry.policyChange = policyChange;
    entry.fit = diagnostics;
    entry.inputConsistency = inputConsistency;
    entry.batch = batch;
    history{iteration} = entry;
    if policyChange <= config.policyTolerance
        converged = true;
        break
    end
    % Keep final P and final K paired even when the iteration budget expires.
    if iteration < config.maxIterations, K = improvedK; end
end
learning.K = K;
learning.P = value.P;
learning.weights = value.weights;
learning.nextPolicyK = improvedK;
learning.converged = converged;
if converged
    learning.status = 'converged';
else
    learning.status = 'max_iterations';
end
learning.iterations = iteration;
learning.history = history(1:iteration);
learning.finalFit = diagnostics;
learning.config = config;
learning.informationContract = struct('knownB',B,'knownR',R, ...
    'receivesA',false,'initialAdmissibility','assumed and checked by the experiment', ...
    'data','on-policy fixed-gain continuous-feedback segments');
learning.informationContract.costAndInputStampsChecked = true;
learning.claim = 'original LQ reference implementation; no upstream paper reproduction claim';
end

function validateProblemContract(batch,B,R)
if ~isfield(batch,'inputMatrix') || ~isequal(batch.inputMatrix,B)
    error('adp:learn:InputMatrixMismatch','Collector inputMatrix must match the learner known B.');
end
if ~isfield(batch,'costContract') || ~isstruct(batch.costContract) || ...
        ~isscalar(batch.costContract) || ...
        ~all(isfield(batch.costContract,{'type','Q','R','discountRate'})) || ...
        ~strcmp(batch.costContract.type,'quadratic_no_half') || ...
        ~isequal(batch.costContract.R,R) || ~isequal(batch.costContract.discountRate,0)
    error('adp:learn:CostMismatch', ...
        'Collector must declare the same R, quadratic_no_half cost, and zero discount.');
end
Q = batch.costContract.Q;
if ~isa(Q,'double') || ~isequal(size(Q),[2,2]) || ~isreal(Q) || any(~isfinite(Q(:)))
    error('adp:learn:CostMismatch','Cost Q must be a finite real 2-by-2 matrix.');
end
matrixTolerance = 64*eps(max(abs(Q(:))));
if norm(Q-Q','fro') > matrixTolerance || min(eig((Q+Q')/2)) < -matrixTolerance
    error('adp:learn:CostMismatch','Cost Q must be symmetric positive semidefinite.');
end
end

function report = validateRecordedData(batch,K)
% Verify attached sample identities; this is not proof of intersample or
% hardware behavior, nor protection against an intentionally false collector.
report.rawTrajectoriesChecked = false;
report.maximumRecordedInputDeviation = [];
if ~isfield(batch,'trajectories'), return; end
if ~iscell(batch.trajectories) || numel(batch.trajectories) ~= size(batch.Phi,1)
    error('adp:learn:DataMismatch','One recorded trajectory is required per regression row.');
end
maxDeviation = 0;
for segment = 1:numel(batch.trajectories)
    trajectory = batch.trajectories{segment};
    if ~isfield(trajectory,'policyK') || ~isequal(trajectory.policyK,K) || ...
            ~isfield(trajectory,'policyFrozen') || ~isequal(trajectory.policyFrozen,true) || ...
            ~isfield(trajectory,'learningEnabled') || ~isequal(trajectory.learningEnabled,false)
        error('adp:learn:PolicyMismatch','Attached trajectory must use the exact frozen policy.');
    end
    if ~isfield(trajectory,'executionMode') || ...
            ~strcmp(trajectory.executionMode,'continuous_feedback')
        error('adp:learn:ExecutionMismatch','Attached trajectory uses a different execution mode.');
    end
    n = numel(trajectory.t);
    if n < 2 || ~isequal(size(trajectory.x),[n,2]) || ...
            ~isreal(trajectory.x) || any(~isfinite(trajectory.x(:))) || ...
            ~isequal(size(trajectory.t),[n,1]) || any(~isfinite(trajectory.t)) || ...
            any(diff(trajectory.t)<=0) || ...
            ~isequal(size(trajectory.integratedCost),[n,1]) || ...
            ~isreal(trajectory.integratedCost) || any(~isfinite(trajectory.integratedCost)) || ...
            ~isfield(trajectory,'resetWithinTrajectory') || trajectory.resetWithinTrajectory
        error('adp:learn:DataMismatch','Attached trajectory has invalid time, state, integral or reset data.');
    end
    expectedInput = -trajectory.x*K';
    % Bound rounding in the dot products at their own physical scale.
    % No unit-sized absolute floor: tiny signals retain relative scrutiny.
    inputTolerance = 64*eps(abs(trajectory.x)*abs(K'));
    for name = {'u_nominal','u_behavior','u_filtered','u_applied'}
        field = name{1};
        if ~isfield(trajectory,field) || ~isequal(size(trajectory.(field)),size(expectedInput)) || ...
                ~isreal(trajectory.(field)) || any(~isfinite(trajectory.(field)(:)))
            error('adp:learn:InputMismatch','Invalid recorded input channel: %s.',field);
        end
        deviations = abs(trajectory.(field)-expectedInput);
        deviation = max(deviations(:));
        if any(deviations(:) > inputTolerance(:))
            error('adp:learn:InputMismatch', ...
                'Recorded %s differs from the frozen target policy by %.8g.',field,deviation);
        end
        maxDeviation = max(maxDeviation,deviation);
    end
    Q = batch.costContract.Q; R = batch.costContract.R;
    x = trajectory.x; u = expectedInput;
    expectedCost = sum((x*Q).*x,2)+sum((u*R).*u,2);
    costScale = sum((abs(x)*abs(Q)).*abs(x),2)+sum((abs(u)*abs(R)).*abs(u),2);
    if ~isfield(trajectory,'stageCost') || ~isequal(size(trajectory.stageCost),[n,1]) || ...
            ~isreal(trajectory.stageCost) || any(~isfinite(trajectory.stageCost)) || ...
            any(abs(trajectory.stageCost-expectedCost)>128*eps(costScale))
        error('adp:learn:CostMismatch','Recorded stageCost does not match the declared Q/R quadratic cost.');
    end
    phiStart = adp.basis.quadratic2(trajectory.x(1,:)');
    phiEnd = adp.basis.quadratic2(trajectory.x(end,:)');
    phiDifference = phiStart-phiEnd;
    phiTolerance = 64*eps(abs(phiStart)+abs(phiEnd));
    integral = trajectory.integratedCost(end)-trajectory.integratedCost(1);
    integralTolerance = 64*eps(abs(trajectory.integratedCost(end))+abs(trajectory.integratedCost(1)));
    if numel(batch.y) ~= size(batch.Phi,1) || ...
            any(abs(batch.Phi(segment,:)'-phiDifference) > phiTolerance) || ...
            abs(batch.y(segment)-integral) > integralTolerance
        error('adp:learn:DataMismatch','Regression row %d does not match its recorded trajectory.',segment);
    end
end
report.rawTrajectoriesChecked = true;
report.maximumRecordedInputDeviation = maxDeviation;
report.scope = 'recorded samples and endpoint identities only; no intersample or hardware proof';
end
