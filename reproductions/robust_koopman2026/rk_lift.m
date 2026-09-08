function [z,D1,D2]=rk_lift(x)
%RK_LIFT Nine degree-1..3 monomials with explicit factorial scaling.
validateattributes(x,{'double'},{'real','finite','2d','ncols',2});
e=[1,0;0,1;2,0;1,1;0,2;3,0;2,1;1,2;0,3];
s=1./(factorial(e(:,1)).*factorial(e(:,2)))';
z=(x(:,1).^(e(:,1)')).*(x(:,2).^(e(:,2)')).*s;
D1=zeros(size(z));D2=D1;
for j=1:9
 if e(j,1)>0,D1(:,j)=s(j)*e(j,1)*x(:,1).^(e(j,1)-1).*x(:,2).^e(j,2);end
 if e(j,2)>0,D2(:,j)=s(j)*e(j,2)*x(:,1).^e(j,1).*x(:,2).^(e(j,2)-1);end
end
end
