function data = bp_collect(dynamics,behavior,stateCost,x0,cfg)
%BP_COLLECT Fixed exploratory batch; no model callback enters the learner.
% RK4 substeps are saved as quadrature nodes. Reset only BETWEEN windows.
validateattributes(x0,{'double'},{'column','real','finite','nonempty'});
validateattributes(cfg.sampleTime,{'double'},{'scalar','positive','finite'});
validateattributes(cfg.collectionTime,{'double'},{'scalar','positive','finite'});
validateattributes(cfg.substeps,{'double'},{'scalar','integer','positive','finite'});
if mod(cfg.substeps,2)~=0, error('biaspi:Substeps','Use an even number of Simpson substeps.'); end
if ~isfield(cfg,'resetRadius'), cfg.resetRadius=Inf; end
if ~isfield(cfg,'maximumStateNorm'), cfg.maximumStateNorm=1e6; end
if cfg.resetRadius<=norm(x0) || cfg.maximumStateNorm<=cfg.resetRadius
    if isfinite(cfg.resetRadius) || ~isinf(cfg.resetRadius)
        error('biaspi:ResetRadius','Need norm(x0)<resetRadius<maximumStateNorm.');
    end
end
nWindows=round(cfg.collectionTime/cfg.sampleTime);
if nWindows<1 || abs(nWindows*cfg.sampleTime-cfg.collectionTime)>64*eps(cfg.collectionTime)
    error('biaspi:Duration','Collection duration must be an integer number of windows.');
end
nodes=cfg.substeps+1; h=cfg.sampleTime/cfg.substeps;
nx=numel(x0); firstInput=behavior(0,x0); nu=numel(firstInput);
data.x=zeros(nx,nodes,nWindows); data.u=zeros(nu,nodes,nWindows);
data.t=zeros(1,nodes,nWindows); data.q=zeros(1,nodes,nWindows);
data.resetAfterWindow=false(1,nWindows); x=x0;
for k=1:nWindows
    startTime=(k-1)*cfg.sampleTime;
    for j=1:nodes
        t=startTime+(j-1)*h; u=behavior(t,x);
        validateattributes(u,{'double'},{'column','numel',nu,'real','finite'});
        q=stateCost(x);
        validateattributes(q,{'double'},{'scalar','real','finite','nonnegative'});
        data.x(:,j,k)=x; data.u(:,j,k)=u; data.t(1,j,k)=t; data.q(1,j,k)=q;
        if j<nodes
            k1=rhs(t,x); k2=rhs(t+h/2,x+h*k1/2);
            k3=rhs(t+h/2,x+h*k2/2); k4=rhs(t+h,x+h*k3);
            x=x+h*(k1+2*k2+2*k3+k4)/6;
            if any(~isfinite(x)) || norm(x)>cfg.maximumStateNorm
                error('biaspi:TrajectoryDiverged','Physical state limit exceeded at window %d substep %d.',k,j);
            end
        end
    end
    if norm(x)>cfg.resetRadius && k<nWindows
        data.resetAfterWindow(k)=true; x=x0;
    end
end
data.config=cfg;
data.contract=struct('policy','fixed exploratory behavior; reused across policy iterations', ...
    'input','actual continuous behavior input sampled at saved RK4 nodes', ...
    'noise','deterministic multisine if selected by caller; no physical stochastic noise', ...
    'reset','threshold checked at window end; no regression crosses a reset', ...
    'stateCost','known Q(x) only; learner constructs target-policy input cost', ...
    'truthCallbacksSaved',false);
    function dx=rhs(tLocal,xLocal)
        dx=dynamics(tLocal,xLocal,behavior(tLocal,xLocal));
        validateattributes(dx,{'double'},{'column','numel',nx,'real','finite'});
    end
end
