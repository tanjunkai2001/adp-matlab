function [f,g]=koopman_model(model,x)
%KOOPMAN_MODEL Evaluate an identified polynomial model; rows are samples.
validateattributes(x,{'double'},{'real','finite','2d','ncols',2});
e=model.exponents; base=(x(:,1).^(e(:,1)')).*(x(:,2).^(e(:,2)'));
f=base(:,e(:,3)==0)*model.coefficients(e(:,3)==0,:);
g=base(:,e(:,3)==1)*model.coefficients(e(:,3)==1,:);
end
