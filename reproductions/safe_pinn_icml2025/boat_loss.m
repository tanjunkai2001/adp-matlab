function [loss,gradients,residual]=boat_loss(net,S)
%BOAT_LOSS Eq.(6),(8); tau=T-t gives min(V_tau-H,V-g)=0.
V=boat_value(net,S);
p=dlgradient(sum(V,'all'),S,EnableHigherDerivatives=true);
[g,l]=boat_geometry(S(2:3,:));
H=(2-.5*S(3,:).^2).*p(2,:)-sqrt(p(2,:).^2+p(3,:).^2+1e-12)-p(4,:).*l;
residual=min(p(1,:)-H,V-g);
loss=mean(residual.^2,'all');
gradients=dlgradient(loss,net.Learnables);
end
