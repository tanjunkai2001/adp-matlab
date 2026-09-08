function trajectory=koopman_rollout(policy,x0,config)
%KOOPMAN_ROLLOUT Truth simulator only: vectorized continuous-feedback RK4.
% No hold between sample points: policy is reevaluated at every RK4 substage.
t=0:config.outputStep:config.horizon; n=size(x0,1); z=[x0,zeros(n,1)];
states=zeros(n,2,numel(t)); costs=zeros(n,numel(t)); inputs=zeros(n,numel(t));
steps=round(config.outputStep/config.step);
if abs(steps*config.step-config.outputStep)>1e-12, error('koopman:TimeGrid','outputStep must be a multiple of step.'); end
for j=1:numel(t)
    states(:,:,j)=z(:,1:2); costs(:,j)=z(:,3); inputs(:,j)=koopman_policy(policy,z(:,1:2));
    if j==numel(t), break; end
    for k=1:steps
        h=config.step;
        k1=rhs(z); k2=rhs(z+h*k1/2); k3=rhs(z+h*k2/2); k4=rhs(z+h*k3);
        z=z+h*(k1+2*k2+2*k3+k4)/6;
        if any(~isfinite(z(:))) || max(abs(z(:,1:2)),[],'all')>100
            error('koopman:Diverged','Frozen controller trajectory diverged.');
        end
    end
end
trajectory=struct('t',t,'x',states,'integratedCost',costs, ...
    'u_nominal',inputs,'u_behavior',inputs,'u_filtered',inputs,'u_applied',inputs, ...
    'executionMode','continuous_feedback_RK4','learningEnabled',false);
    function dz=rhs(state)
        x=state(:,1:2); u=koopman_policy(policy,x);
        dz=[x(:,2),sin(x(:,1))-config.damping*x(:,2)+u, ...
            sum((x*config.Q).*x,2)+config.R*u.^2];
    end
end
