function model = koopman_identify(data, config)
%KOOPMAN_IDENTIFY Resolvent/Yosida generator from sampled constant-input flows.
% Inputs: data.t (1xT), data.x (Mx2xT), data.u (Mx1). No derivatives or truth.
% L_lambda phi = lambda^2 int exp(-lambda*t) phi(flow(t))dt-lambda*phi(x0).
if ~isfield(data,'executionMode') || ~strcmp(data.executionMode,'constant_input_per_trajectory')
    error('koopman:InputContract','Each identification trajectory must declare a constant held input.');
end
validateattributes(data.x,{'double'},{'real','finite','nonempty'});
validateattributes(data.u,{'double'},{'real','finite','column'});
t = data.t(:)'; M=size(data.x,1); nt=numel(t);
if numel(t)<4 || t(1)~=0 || any(diff(t)<=0) || ...
        ~isequal(size(data.x),[M,2,nt]) || numel(data.u)~=M
    error('koopman:InvalidData','Require Mx2xT states, M constant inputs, and >=4 increasing times from zero.');
end
validateattributes(config.lambda,{'double'},{'real','finite','scalar','positive'});
validateattributes(config.degree,{'double'},{'scalar','integer','positive'});
[a,b,c]=ndgrid(0:config.degree,0:config.degree,0:1);
exponents=[a(:),b(:),c(:)]; exponents(all(exponents==0,2),:)=[];
X=monomials(data.x(:,:,1),data.u,exponents);
weights=exponentialWeights(t,config.lambda);
Y=-config.lambda*exp(-config.lambda*t(end))*X;
% Subtraction before integration avoids lambda*phi0 cancellation. This is
% algebraically the same finite-horizon Yosida operator, including its tail.
for j=1:nt
    if weights(j)~=0
        Y=Y+weights(j)*(monomials(data.x(:,:,j),data.u,exponents)-X);
    end
end
scale=sqrt(sum(X.^2,1));
if any(scale==0), error('koopman:RankDeficient','A dictionary column is zero.'); end
[U,S,V]=svd(X./scale,'econ'); singularValues=diag(S);
keep=singularValues>config.rankTolerance*singularValues(1);
if sum(keep)~=size(X,2)
    error('koopman:RankDeficient','Generator dictionary rank %d/%d.',sum(keep),size(X,2));
end
L=(V*((U'*Y)./singularValues))./scale';
stateIndices=[find(all(exponents==[1,0,0],2)),find(all(exponents==[0,1,0],2))];
model.kind='identified_control_affine'; model.exponents=exponents;
model.generator=L; model.coefficients=L(:,stateIndices);
model.lambda=config.lambda; model.rank=sum(keep); model.singularValues=singularValues;
model.condition=singularValues(1)/singularValues(end);
model.regressionResidual=norm(X*L-Y,'fro')/norm(Y,'fro');
model.coordinateResidual=norm(X*model.coefficients-Y(:,stateIndices),'fro')/norm(Y(:,stateIndices),'fro');
model.quadratureWeights=weights; model.time=t;
model.quadrature='four-point local cubic interpolation, 16-point Gauss-Legendre exponential integration';
model.knowledge='sampled x and held u only; no f/g/derivatives/linearization';
model.dictionaryColumns=size(X,2); model.stateIndices=stateIndices;
end

function Phi=monomials(x,u,e)
Phi=(x(:,1).^(e(:,1)')).*(x(:,2).^(e(:,2)')).*(u.^(e(:,3)'));
end

function weights=exponentialWeights(t,lambda)
n=16; off=(1:n-1)./sqrt(4*(1:n-1).^2-1);
[V,D]=eig(diag(off,1)+diag(off,-1)); [nodes,order]=sort(diag(D));
qweights=2*(V(1,order).^2)'; weights=zeros(1,numel(t));
for j=1:numel(t)-1
    if lambda*t(j)>745, break; end
    ids=max(1,min(j-1,numel(t)-3))+(0:3);
    h=(t(j+1)-t(j))/2; q=t(j)+h*(nodes+1);
    local=lambda^2*h*qweights.*exp(-lambda*q);
    for k=1:4
        others=setdiff(1:4,k); basis=ones(size(q));
        for z=others, basis=basis.*((q-t(ids(z)))/(t(ids(k))-t(ids(z)))); end
        weights(ids(k))=weights(ids(k))+sum(local.*basis);
    end
end
end
