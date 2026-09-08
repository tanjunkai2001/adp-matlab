function [u,p,a]=rk_control(solution,x)
%RK_CONTROL Exact scalar minimizer including the zero-control branch.
% min_u 0.5*R*u^2+a*u+c2*norm(p)*abs(u).
z=rk_lift(x);[~,D]=rk_basis(z);p=zeros(size(z));
for j=1:9,p(:,j)=D(:,:,j)*solution.theta;end
B=z*solution.model.B1'+solution.model.B0';a=sum(B.*p,2);
b=solution.c2*vecnorm(p,2,2);
u=-sign(a).*max(abs(a)-b,0)/solution.R;
end
