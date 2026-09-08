function trajectory = rollout(plant, K, config)
%ROLLOUT Integrate a frozen continuous-feedback policy u(t)=-K*x(t).
% t, x and all u_* logs store one sample per row. outputTimes is an output
% grid, not a fixed internal step or a zero-order-hold execution period.
% This baseline has identity behavior/filter/execution maps and no noise.
if ~isfield(config,'executionMode')
    config.executionMode = 'continuous_feedback';
end
if ~strcmp(config.executionMode,'continuous_feedback')
    error('adp:sim:UnsupportedExecutionMode', ...
        'This rollout implements only continuous_feedback, received %s.', ...
        config.executionMode);
end
validateattributes(K, {'double'}, {'real','finite','2d', ...
    'size',[plant.inputDimension,plant.stateDimension]});
validateattributes(config.x0, {'double'}, ...
    {'real','finite','column','numel',plant.stateDimension});
validateattributes(config.outputTimes, {'double'}, ...
    {'real','finite','vector','nonempty'});
tRequested = config.outputTimes(:);
if numel(tRequested) < 2 || any(diff(tRequested) <= 0)
    error('adp:sim:InvalidTimes','outputTimes must contain at least two increasing times.');
end
validateattributes(config.relativeTolerance, {'double'}, ...
    {'real','finite','scalar','positive','<',1});
validateattributes(config.absoluteTolerance, {'double'}, ...
    {'real','finite','scalar','positive'});
validateattributes(config.maxStep, {'double'}, ...
    {'real','finite','scalar','positive'});
odeOptions = odeset('RelTol',config.relativeTolerance, ...
    'AbsTol',config.absoluteTolerance,'MaxStep',config.maxStep);
initialAugmented = [config.x0;0];
[t,z] = ode45(@rhs, tRequested, initialAugmented, odeOptions);
nx = plant.stateDimension;
x = z(:,1:nx);
u = -(K*x')';
if any(~isfinite(z(:))) || any(~isfinite(u(:)))
    error('adp:sim:NonfiniteTrajectory','The integration returned a nonfinite value.');
end
if abs(t(end)-tRequested(end)) > 16*eps(max(abs(tRequested(end)),1))
    error('adp:sim:IncompleteIntegration','Integration stopped before the requested final time.');
end
stageCost = zeros(numel(t),1);
for k = 1:numel(t)
    stageCost(k) = plant.stageCost(t(k),x(k,:)',u(k,:)');
end
trajectory.t = t;
trajectory.x = x;
trajectory.u_nominal = u;
trajectory.u_behavior = u;
trajectory.u_filtered = u;
trajectory.u_applied = u;
trajectory.stageCost = stageCost;
trajectory.integratedCost = z(:,nx+1);
trajectory.integralSource = 'ode_augmented_state';
trajectory.quadratureRule = 'adaptive_ode45_augmented_cost_state';
trajectory.integrationErrorBound = [];
trajectory.integrationErrorStatus = 'not certified; solver tolerances are not an integral error bound';
trajectory.policyK = K;
trajectory.policyFrozen = true;
trajectory.learningEnabled = false;
trajectory.executionMode = config.executionMode;
trajectory.inputPipeline = 'identity; no exploration, saturation, filter or delay';
trajectory.resetWithinTrajectory = false;
trajectory.config = config;
trajectory.solver = 'ode45';

    function dz = rhs(time,state)
        % Pure RHS: no globals, persistent state, logging, RNG or updates.
        xLocal = state(1:plant.stateDimension);
        uLocal = -K*xLocal;
        dx = plant.dynamics(time,xLocal,uLocal);
        cost = plant.stageCost(time,xLocal,uLocal);
        dz = [dx;cost];
    end
end
