function model=rk_identify(data)
%RK_IDENTIFY Eq(20)-(24), measured derivative channel is explicitly required.
validateattributes(data.xdot,{'double'},{'real','finite','size',size(data.x)});
validateattributes(data.u,{'double'},{'real','finite','column','numel',size(data.x,1)});
[z,D1,D2]=rk_lift(data.x); zdot=D1.*data.xdot(:,1)+D2.*data.xdot(:,2);
W=[z,data.u,z.*data.u];
[U,S,V]=svd(W,'econ');s=diag(S); rankValue=sum(s>s(1)*1e-11);
if rankValue~=19,error('robustkoopman:Rank','Bilinear data rank %d/19.',rankValue);end
coef=V*((U'*zdot)./s); residual=zdot-W*coef;
ratios=vecnorm(residual,2,2)./(vecnorm(z,2,2)+abs(data.u));
c=max(ratios); % Minimum feasible c on the declared restricted LP slice c1=c2=c.
model=struct('A',coef(1:9,:)','B0',coef(10,:)','B1',coef(11:19,:)', ...
 'c1',c,'c2',c,'singularValues',s,'rank',rankValue,'condition',s(1)/s(end), ...
 'residual',residual,'z',z,'zdot',zdot,'W',W,'coefficients',coef, ...
 'boundStatus','fits retained training residuals only; not a global or probabilistic certificate', ...
 'knowledge','x, measured noisy xdot, u; no analytic f/g/value/control');
end
