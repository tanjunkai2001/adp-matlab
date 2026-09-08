function [loss,gradients,parts] = pinn_loss(net,xt,xb,terminal,cfg)
%PINN_LOSS HJB differential residual + terminal residual, equation (8).
% Origin residual is exactly zero by pinn_value, not omitted unconstrained.
v=pinn_value(net,xt,cfg);
dv=dlgradient(sum(v,'all'),xt,'EnableHigherDerivatives',true);
[f,g,q]=pinn_problem(cfg.problem,xt(1:end-1,:));
gradx=dv(1:end-1,:); actionGradient=sum(g.*gradx,1);
flow=dv(end,:)+sum(f.*gradx,1)+q-actionGradient.^2/(4*cfg.R);
vb=pinn_value(net,xb,cfg);
boundary=vb-terminal;
flowMSE=mean(flow.^2,'all'); boundaryMSE=mean(boundary.^2,'all');
loss=flowMSE+boundaryMSE;
gradients=dlgradient(loss,net.Learnables);
parts=[flowMSE;boundaryMSE];
end
