function batch = collectBatch(plant, K, config)
%COLLECTBATCH Independent fixed-policy segments for integral policy evaluation.
% initialStates is 2-by-N. Each segment starts a separate simulation; this
% resettable simulation data collection is not one hardware trajectory.
validateattributes(config.initialStates, {'double'}, ...
    {'real','finite','2d','nrows',2,'nonempty'});
numberOfSegments = size(config.initialStates,2);
batch.Phi = zeros(numberOfSegments,3);
batch.y = zeros(numberOfSegments,1);
batch.trajectories = cell(numberOfSegments,1);
for k = 1:numberOfSegments
    simulationConfig = config.simulation;
    simulationConfig.x0 = config.initialStates(:,k);
    trajectory = adp.sim.rollout(plant,K,simulationConfig);
    phiStart = adp.basis.quadratic2(trajectory.x(1,:)');
    phiEnd = adp.basis.quadratic2(trajectory.x(end,:)');
    batch.Phi(k,:) = (phiStart-phiEnd)';
    batch.y(k) = trajectory.integratedCost(end);
    batch.trajectories{k} = trajectory;
end
batch.policyK = K;
batch.targetPolicyK = K;
batch.behaviorPolicyK = K;
batch.inputMatrix = plant.B;
batch.costContract = struct('type','quadratic_no_half','Q',plant.Q, ...
    'R',plant.R,'discountRate',0);
batch.onPolicy = true;
batch.executionMode = 'continuous_feedback';
batch.integralSource = 'ode_augmented_state';
batch.quadratureRule = 'adaptive_ode45_augmented_cost_state';
batch.integrationErrorBound = [];
batch.integrationErrorStatus = 'not certified; solver tolerances are not an integral error bound';
batch.dataCollection = 'independent simulation segments with explicit initial states';
batch.resetBetweenSegments = true;
batch.config = config;
end
