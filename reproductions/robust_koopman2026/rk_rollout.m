function out=rk_rollout(solution,x0,c)
%RK_ROLLOUT True Eq(55) evaluator; no learning, no process noise during control.
t=0:c.step:c.horizon;x=x0;n=size(x,1);z=[x,zeros(n,1)];
out=struct('t',t,'x',zeros(n,2,numel(t)),'cost',zeros(n,numel(t)),'u_applied',zeros(n,numel(t)));
for k=1:numel(t)
 out.x(:,:,k)=z(:,1:2);out.cost(:,k)=z(:,3);out.u_applied(:,k)=policy(z(:,1:2));
 if k==numel(t),break;end
 h=c.step;k1=rhs(z);k2=rhs(z+h*k1/2);k3=rhs(z+h*k2/2);k4=rhs(z+h*k3);
 z=z+h*(k1+2*k2+2*k3+k4)/6;
 if any(~isfinite(z(:)))||max(abs(z(:,1:2)),[],'all')>50,error('robustkoopman:Diverged','Rollout diverged.');end
end
out.u_nominal=out.u_applied;out.u_behavior=out.u_applied;out.u_filtered=out.u_applied;
out.executionMode='continuous_feedback_RK4';out.learningEnabled=false;
 function u=policy(x)
  if ischar(solution)&&strcmp(solution,'analytic_oracle'),u=-x(:,1).*x(:,2);
  else,u=rk_control(solution,x);end
 end
 function dz=rhs(z)
  x=z(:,1:2);u=policy(x);
  dz=[-x(:,1)+x(:,2),-0.5*(x(:,1)+x(:,2))+0.5*x(:,1).^2.*x(:,2)+x(:,1).*u, ...
      0.5*(sum(x.^2,2)+u.^2)];
 end
end
