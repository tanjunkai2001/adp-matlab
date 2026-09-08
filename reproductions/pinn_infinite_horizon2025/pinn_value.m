function value = pinn_value(net,xt,cfg)
%PINN_VALUE Genuine trainable tanh MLP, with exact origin/even symmetry.
% These examples have V(-x,t)=V(x,t). This ansatz is an explicitly recorded
% architecture variant of the paper; no analytical value function is added.
n=size(xt,1)-1; b=size(xt,2);
x=xt(1:n,:)/cfg.trainingDomain;
t=2*xt(end,:)/cfg.increment-1;
z=[x,-x,0*x;t,t,t];
y=forward(net,z);
value=(y(1,1:b)+y(1,b+(1:b)))/2-y(1,2*b+(1:b));
end
