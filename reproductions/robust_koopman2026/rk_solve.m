function solution=rk_solve(model,x,config)
%RK_SOLVE Branch-complete scalar variant of Eq(46) + implicit Eq(34).
% Uses the lifted Laplacian, nonlinear least-squares HJB inner solve, and
% frozen uncertainty penalty outside. It does not implement the lagged-sign
% update Eq(47) or certify a complete elliptic boundary-value problem.
z=rk_lift(x);[phi,D,lap,pairs]=rk_basis(z);n=size(x,1);m=size(phi,2);
Az=z*model.A';B=z*model.B1'+model.B0';F=zeros(n,m);G=F;
for j=1:9,F=F+D(:,:,j).*Az(:,j);G=G+D(:,:,j).*B(:,j);end
F=F-config.epsilon*lap; cost=0.5*sum((x*config.Q).*x,2);
% Initialize from a generic quadratic candidate and the identified B only.
guess=zeros(m,1);guess(all(pairs==[1,1],2))=0.5*config.initialGain;
guess(all(pairs==[2,2],2))=0.5*config.initialGain;
u0=-(G*guess)/config.R;
theta=(F+u0.*G)\(-cost-0.5*config.R*u0.^2);
history=cell(config.iterations,1);converged=false;
for k=1:config.iterations
 oldTheta=theta;p=zeros(n,9);for j=1:9,p(:,j)=D(:,:,j)*theta;end
 a=G*theta;b=config.c2*vecnorm(p,2,2);shrink=max(abs(a)-b,0);
 penalty=config.c1*vecnorm(z,2,2).*vecnorm(p,2,2)+(a.^2-shrink.^2)/(2*config.R);
 oldU=-sign(a).*shrink/config.R;
 innerHistory=zeros(config.innerIterations,2);
 for inner=1:config.innerIterations
  a=G*theta; residual=F*theta-0.5*a.^2/config.R+cost+penalty;
  J=F-(a/config.R).*G;
  step=-[J;1e-7*eye(m)]\[residual;zeros(m,1)];
  alpha=1;objective=norm(residual);
  while alpha>=2^-14
   trial=theta+alpha*step;
   candidate=F*trial-0.5*(G*trial).^2/config.R+cost+penalty;
   if norm(candidate)<=objective,break;end
   alpha=alpha/2;
  end
  if alpha<2^-14,break;end
  theta=trial;innerHistory(inner,:)=[norm(candidate)/sqrt(n),alpha];
  if norm(alpha*step)<config.innerTolerance*(1+norm(theta)),break;end
 end
 solution=struct('theta',theta,'model',model,'c1',config.c1,'c2',config.c2,'R',config.R);
 newU=rk_control(solution,x);change=sqrt(mean((newU-oldU).^2));
 history{k}=struct('inner',innerHistory(1:inner,:),'policyChangeRms',change, ...
  'thetaChange',norm(theta-oldTheta)/(1+norm(oldTheta)),'theta',theta, ...
  'frozenPdeResidualRms',sqrt(mean((F*theta-0.5*(G*theta).^2/config.R+cost+penalty).^2)));
 if change<config.policyTolerance,converged=true;break;end
end
[~,p,a]=rk_control(solution,x);b=config.c2*vecnorm(p,2,2);
robustResidual=F*theta+cost+config.c1*vecnorm(z,2,2).*vecnorm(p,2,2)- ...
 0.5*max(abs(a)-b,0).^2/config.R;
solution.history=history(1:k);solution.converged=converged;solution.iterations=k;
solution.residualRms=sqrt(mean(robustResidual.^2));solution.pairs=pairs;
solution.config=config;solution.minimumCollocationValue=min(phi*theta);
solution.method='nonlinear lifted Galerkin collocation, frozen robust penalty, exact scalar subgradient update';
end
