function [A,y,diagnostics] = bp_regression(data,spec,W,cPrevious,gamma,mode)
%BP_REGRESSION Paper Eq43 (bias) or Eq48 (discounted inner PI).
% x: nx-by-nodes-by-windows; u: nu-by-nodes-by-windows.
% t,q: 1-by-nodes-by-windows. W: nActor-by-nu; uTarget=W'*psi.
% Critic first, then W(:), with a complete actor block for each input.
validateattributes(gamma,{'double'},{'scalar','real','finite','nonnegative'});
if ~ismember(mode,{'bias','discounted'})
    error('biaspi:Mode','Mode must be bias or discounted.');
end
for field={'x','u','t','q'}
    validateattributes(data.(field{1}),{'double'},{'real','finite','nonempty'});
end
[nx,nodes,nWindows]=size(data.x); nu=size(data.u,1);
if nodes<3 || mod(nodes-1,2)~=0 || ...
        ~isequal(size(data.u,2),nodes) || size(data.u,3)~=nWindows || ...
        size(data.t,1)~=1 || size(data.t,2)~=nodes || size(data.t,3)~=nWindows || ...
        size(data.q,1)~=1 || size(data.q,2)~=nodes || size(data.q,3)~=nWindows
    error('biaspi:DataShape','Each window needs an even number of Simpson substeps and matching recorded channels.');
end
R=spec.R;
validateattributes(R,{'double'},{'real','finite','size',[nu,nu]});
if norm(R-R','fro')>64*eps(max(abs(R(:))))
    error('biaspi:InputCost','R must be symmetric positive definite.');
end
[~,flag]=chol(R);
if flag, error('biaspi:InputCost','R must be symmetric positive definite.'); end
X=reshape(data.x,nx,[]);
phi=spec.phi(X); psi=spec.psi(X);
validateattributes(phi,{'double'},{'real','finite','2d','ncols',nodes*nWindows});
validateattributes(psi,{'double'},{'real','finite','2d','ncols',nodes*nWindows});
nc=size(phi,1); na=size(psi,1);
validateattributes(W,{'double'},{'real','finite','size',[na,nu]});
validateattributes(cPrevious,{'double'},{'real','finite','column','numel',nc});
target=W'*psi; behavior=reshape(data.u,nu,[]);
deltaInput=R*(behavior-target);
running=reshape(data.q,1,[])+sum(target.*(R*target),1);
if strcmp(mode,'bias'), bias=gamma*(cPrevious'*phi);
else, bias=zeros(size(running)); end
running=running+bias;
phi=reshape(phi,nc,nodes,nWindows); psi=reshape(psi,na,nodes,nWindows);
deltaInput=reshape(deltaInput,nu,nodes,nWindows);
running=reshape(running,nodes,nWindows);
bias=reshape(bias,nodes,nWindows);
A=zeros(nWindows,nc+na*nu); y=zeros(nWindows,1);
biasIntegral=zeros(nWindows,1);
simpson=ones(1,nodes); simpson(2:2:end-1)=4; simpson(3:2:end-1)=2;
for k=1:nWindows
    t=reshape(data.t(1,:,k),1,[]); dt=diff(t); h=dt(1);
    if any(dt<=0) || max(abs(dt-h))>256*eps(max(abs(t)))
        error('biaspi:TimeGrid','Each window must have increasing equally spaced node times.');
    end
    relativeTime=t-t(1); duration=relativeTime(end);
    quadrature=(h/3)*simpson.*exp(-gamma*relativeTime);
    A(k,1:nc)=(exp(-gamma*duration)*phi(:,end,k)-phi(:,1,k))';
    for input=1:nu
        actorBlock=2*sum(psi(:,:,k).*(quadrature.*deltaInput(input,:,k)),2);
        A(k,nc+(input-1)*na+(1:na))=actorBlock';
    end
    y(k)=-quadrature*running(:,k);
    biasIntegral(k)=quadrature*bias(:,k);
end
diagnostics=struct('mode',mode,'gamma',gamma,'criticCount',nc,'actorCount',na, ...
    'inputCount',nu,'windowCount',nWindows,'biasIntegral',biasIntegral, ...
    'quadrature','composite Simpson on recorded nodes; local exponential weight', ...
    'equation','Delta_gamma_phi*c + 2 integral psi*R(u-uTarget)*vec(Wnext) = - integral runningCost', ...
    'biasIncluded',strcmp(mode,'bias'),'usesDynamics',false);
end
