function [phi,D,laplacian,pairs]=rk_basis(z)
%RK_BASIS 25 distinct state monomials from quadratic products in lifted z.
% A canonical first-occurrence product fixes the otherwise ambiguous extension
% away from the two-dimensional lifted manifold. Derivatives are in R^9.
e=[1,0;0,1;2,0;1,1;0,2;3,0;2,1;1,2;0,3];
pairs=zeros(0,2); seen=zeros(0,2);
for a=1:9
 for b=a:9
  exponent=e(a,:)+e(b,:);
  if isempty(seen)||~any(all(seen==exponent,2))
   pairs(end+1,:)=[a,b];seen(end+1,:)=exponent;
  end
 end
end
n=size(z,1);m=size(pairs,1);phi=zeros(n,m);D=zeros(n,m,9);laplacian=zeros(1,m);
for j=1:m
 a=pairs(j,1);b=pairs(j,2);phi(:,j)=z(:,a).*z(:,b);
 D(:,j,a)=D(:,j,a)+z(:,b);D(:,j,b)=D(:,j,b)+z(:,a);
 if a==b,laplacian(j)=2;end
end
end
