function learning = bp_learn(data,spec,cfg)
%BP_LEARN Algorithm2 with Eq43 outer bias step / Eq48 inner discounted PI.
% Corrects the printed swapped equation references and stale inner stopping
% index. Thresholds are checked on spec.checkX, not over all R^n.
required={'critic0','actor0','gamma0','deltaBar','deltaH','tolerance', ...
    'maxIterations','maxInnerIterations'};
if ~all(isfield(cfg,required)), error('biaspi:Configuration','Missing learner configuration.'); end
c=cfg.critic0; W=cfg.actor0; gamma=cfg.gamma0;
validateattributes(gamma,{'double'},{'scalar','real','finite','nonnegative'});
validateattributes(cfg.deltaBar,{'double'},{'scalar','real','finite','positive'});
validateattributes(cfg.deltaH,{'double'},{'scalar','real','finite','>',cfg.deltaBar});
validateattributes(cfg.tolerance,{'double'},{'scalar','real','finite','positive'});
validateattributes(cfg.maxIterations,{'double'},{'scalar','integer','positive','finite'});
validateattributes(cfg.maxInnerIterations,{'double'},{'scalar','integer','positive','finite'});
checkPhi=spec.phi(spec.checkX); checkQ=spec.stateCost(spec.checkX);
validateattributes(checkQ,{'double'},{'row','real','finite','nonnegative','numel',size(checkPhi,2)});
positiveQ=checkQ>0;
if ~any(positiveQ), error('biaspi:CheckSet','Threshold set must contain a nonzero-cost state.'); end
delta=max((c'*checkPhi(:,positiveQ))./checkQ(positiveQ));
if delta<=0, error('biaspi:InitialValue','The maximum sampled V0/Q ratio must be positive to initialize beta; this is not a positivity test.'); end
beta=1+gamma*delta;
history=cell(cfg.maxIterations,1); totalInner=0; converged=false;
for iteration=1:cfg.maxIterations
    previousC=c; previousW=W; gammaBefore=gamma;
    inner={}; trigger=max(c'*checkPhi-cfg.deltaH*checkQ)>0;
    if trigger
        if gamma==0 || beta<=1
            error('biaspi:GammaSchedule','A threshold violation cannot reduce nonpositive gamma/beta.');
        end
        gamma=gamma*(beta-1)/beta;
        for j=1:cfg.maxInnerIterations
            [A,y,reg]=bp_regression(data,spec,W,c,gamma,'discounted');
            [weights,fit]=bp_solve(A,y,cfg);
            nc=numel(c); c=weights(1:nc); W=reshape(weights(nc+1:end),size(W));
            inner{j}=struct('c',c,'W',W,'fit',fit,'regression',reg); %#ok<AGROW>
            if max(c'*checkPhi-cfg.deltaBar*checkQ)<=0, break; end
        end
        if max(c'*checkPhi-cfg.deltaBar*checkQ)>0
            error('biaspi:InnerBudget', ...
                'Inner PI budget at outer %d: gamma %.16g, final check margin %.8g, c=%s, W=%s.', ...
                iteration,gamma,max(c'*checkPhi-cfg.deltaBar*checkQ),mat2str(c',10),mat2str(W,10));
        end
        totalInner=totalInner+numel(inner);
        % The paper does not give an executable beta restart convention when
        % gamma changes. Restart Eq30 from this accepted value's sampled ratio.
        delta=max((c'*checkPhi(:,positiveQ))./checkQ(positiveQ));
        beta=1+gamma*max(delta,0);
    end
    biasPreviousC=c; targetW=W;
    [A,y,reg]=bp_regression(data,spec,targetW,biasPreviousC,gamma,'bias');
    [weights,fit]=bp_solve(A,y,cfg);
    nc=numel(c); c=weights(1:nc); W=reshape(weights(nc+1:end),size(W));
    criticChangeSquared=sum((c-biasPreviousC).^2);
    entry=struct('iteration',iteration,'c',c,'W',W,'previousC',previousC, ...
        'previousW',previousW,'biasPreviousC',biasPreviousC,'targetW',targetW, ...
        'gammaBefore',gammaBefore,'gamma',gamma,'beta',beta,'thresholdTriggered',trigger, ...
        'inner',{inner},'fit',fit,'regression',reg,'criticChangeSquared',criticChangeSquared, ...
        'checkValueMinimum',min(c'*checkPhi),'checkHighMargin',max(c'*checkPhi-cfg.deltaH*checkQ));
    history{iteration}=entry;
    if criticChangeSquared<=cfg.tolerance, converged=true; break; end
    beta=(1+gamma*cfg.deltaBar*beta)/(1+gamma*cfg.deltaBar);
end
learning=struct('c',c,'W',W,'history',{history(1:iteration)}, ...
    'converged',converged,'iterations',iteration,'innerIterations',totalInner, ...
    'gamma',gamma,'config',cfg,'finalFit',fit);
if converged, learning.status='converged'; else, learning.status='max_iterations'; end
learning.dataContract=struct('usesDynamics',false,'known','R,Q(x),basis functions, observed state and actual input', ...
    'outerEquation','43 with gamma*Vprevious','innerEquation','48 without gamma*Vprevious', ...
    'thresholdScope','finite supplied checkX only; no global inequality certificate', ...
    'gammaSchedule','Eq30 beta recurrence; gamma*(beta-1)/beta when triggered; beta restarted after inner acceptance', ...
    'theoremVerified',false);
end
