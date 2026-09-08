function [Phi,D1,D2]=koopman_features(features,x)
%KOOPMAN_FEATURES Quadratics + anchored tanh random features (explicit variant).
% All features and gradients vanish at 0; only output weights are trained.
z=x*features.W'+features.b'; h=tanh(z); h0=tanh(features.b)';
d0=1-h0.^2; linear=x*features.W';
Phi=[x(:,1).^2,2*x(:,1).*x(:,2),x(:,2).^2,h-h0-linear.*d0];
delta=1-h.^2-d0;
D1=[2*x(:,1),2*x(:,2),zeros(size(x,1),1),delta.*features.W(:,1)'];
D2=[zeros(size(x,1),1),2*x(:,1),2*x(:,2),delta.*features.W(:,2)'];
end
