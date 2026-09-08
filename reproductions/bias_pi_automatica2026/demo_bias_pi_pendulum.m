function [result,runDir] = demo_bias_pi_pendulum(outputDirectory,overrides)
%DEMO_BIAS_PI_PENDULUM Fresh data-driven Bias-PI; optional immutable saving.
if nargin<1, outputDirectory=''; end
if nargin<2, overrides=struct(); end
runDir=outputDirectory;
[cfg,spec]=bp_pendulum_config();
for key=fieldnames(overrides)'
    if ~isfield(cfg,key{1}), error('biaspi:UnknownOption','Unknown option %s.',key{1}); end
    cfg.(key{1})=overrides.(key{1});
end
[a,b]=meshgrid(linspace(-cfg.checkRadius,cfg.checkRadius,cfg.checkGridCount));
spec.checkX=[a(:)';b(:)'];
oldRng=rng; cleanup=onCleanup(@()rng(oldRng)); %#ok<NASGU>
rng(cfg.seed,'twister');
omega=cfg.frequencyRange(1)+diff(cfg.frequencyRange)*rand(cfg.frequencyCount,1);
exploration=@(t) cfg.explorationAmplitude*sum(sin(omega*t));
if strcmp(cfg.behaviorMode,'exploration_only')
    behavior=@(t,x) exploration(t);
elseif strcmp(cfg.behaviorMode,'initial_plus_exploration')
    behavior=@(t,x) cfg.actor0'*spec.psi(x)+exploration(t);
else, error('biaspi:Behavior','Unknown behaviorMode.'); end
dynamics=@(t,x,u) [x(2);sin(x(1))+u];
if strcmp(cfg.collectionMode,'single_trajectory')
    data=bp_collect(dynamics,behavior,spec.stateCost,cfg.x0,cfg);
elseif strcmp(cfg.collectionMode,'local_multistart')
    validateattributes(cfg.multiStartCount,{'double'},{'scalar','integer','positive','finite'});
    validateattributes(cfg.multiStartRadius,{'double'},{'scalar','positive','finite'});
    rng(cfg.multiStartSeed,'twister');
    starts=cfg.multiStartRadius*(2*rand(2,cfg.multiStartCount)-1);
    blockCfg=cfg; blockCfg.collectionTime=cfg.collectionTime/cfg.multiStartCount;
    blocks=cell(1,cfg.multiStartCount);
    for segment=1:cfg.multiStartCount
        timeOffset=(segment-1)*blockCfg.collectionTime;
        blocks{segment}=bp_collect(dynamics,@(t,x)behavior(t+timeOffset,x), ...
            spec.stateCost,starts(:,segment),blockCfg);
        blocks{segment}.t=blocks{segment}.t+timeOffset;
        if segment<cfg.multiStartCount, blocks{segment}.resetAfterWindow(end)=true; end
    end
    data=blocks{1};
    for field={'x','u','t','q'}
        values=cellfun(@(b)b.(field{1}),blocks,'UniformOutput',false);
        data.(field{1})=cat(3,values{:});
    end
    flags=cellfun(@(b)b.resetAfterWindow,blocks,'UniformOutput',false);
    data.resetAfterWindow=cat(2,flags{:});
    data.config=cfg; data.initialStates=starts;
    data.contract.reset='Explicit independently reset initial states, and window-end radius resets; never cross resets in regression';
    data.contract.collectionVariant='local_multistart; chosen coverage experiment, not the paper single initial trajectory';
else, error('biaspi:CollectionMode','Unknown collectionMode.'); end
data.frequencies=omega;
tableInitial=struct('c',cfg.critic0,'W',cfg.actor0);
bootstrap=[];
if ~isempty(outputDirectory)
    if isfolder(outputDirectory) || isfile(outputDirectory)
        error('biaspi:ExistingRun','Refusing to overwrite %s.',outputDirectory);
    end
    mkdir(outputDirectory);
    save(fullfile(outputDirectory,'inputs.mat'),'data','cfg','tableInitial','-v7.3');
end
try
if strcmp(cfg.initialization,'discounted_bootstrap')
    [A,y,reg]=bp_regression(data,spec,cfg.actor0,cfg.critic0,cfg.gamma0,'discounted');
    [weights,fit]=bp_solve(A,y,cfg);
    cfg.critic0=weights(1:7); cfg.actor0=reshape(weights(8:end),5,1);
    bootstrap=struct('c',cfg.critic0,'W',cfg.actor0,'regression',reg,'fit',fit);
elseif ~strcmp(cfg.initialization,'paper_table')
    error('biaspi:Initialization','Choose paper_table or discounted_bootstrap.');
end
learning=bp_learn(data,spec,cfg);
catch failure
    if ~isempty(outputDirectory)
        failureRecord=struct('status','failed','identifier',failure.identifier, ...
            'message',failure.message,'report',getReport(failure,'extended','hyperlinks','off'), ...
            'config',cfg,'bootstrap',bootstrap,'rawData','inputs.mat');
        save(fullfile(outputDirectory,'failure.mat'),'failureRecord');
        failureFile=fopen(fullfile(outputDirectory,'failure.json'),'w');
        if failureFile>=0
            fprintf(failureFile,'%s\n',jsonencode(failureRecord,'PrettyPrint',true)); fclose(failureFile);
        end
    end
    rethrow(failure);
end
% These truth-based comparisons occur only after data learning.
root2=sqrt(2); referenceK=[1+root2,1+root2];
referenceP=[2+root2,1+root2;1+root2,1+root2];
rng(cfg.evaluationSeed,'twister');
initialStates=6*rand(2,cfg.evaluationCount)-3;
evaluation=repmat(struct('learned',[],'lqr',[]),1,cfg.evaluationCount);
learnedCosts=nan(1,cfg.evaluationCount); lqrCosts=learnedCosts;
for k=1:cfg.evaluationCount
    evaluation(k).learned=rollout(initialStates(:,k),@(x)learning.W'*spec.psi(x));
    evaluation(k).lqr=rollout(initialStates(:,k),@(x)-referenceK*x);
    if evaluation(k).learned.complete, learnedCosts(k)=evaluation(k).learned.cost; end
    if evaluation(k).lqr.complete, lqrCosts(k)=evaluation(k).lqr.cost; end
end
paired=learnedCosts-lqrCosts; finite=isfinite(paired);
if sum(finite)>1, pairedSE=std(paired(finite))/sqrt(sum(finite)); else, pairedSE=NaN; end
policies=cellfun(@(h)h.gamma,learning.history);
metrics=struct('converged',learning.converged,'iterations',learning.iterations, ...
    'innerIterations',learning.innerIterations,'finalGamma',learning.gamma,'gammaSequence',policies, ...
    'criticWeights',learning.c,'actorWeights',learning.W, ...
    'rank',learning.finalFit.rank,'scaledCondition',learning.finalFit.scaledCondition, ...
    'relativeResidual',learning.finalFit.relativeResidual, ...
    'resetCount',sum(data.resetAfterWindow),'maximumObservedStateNorm',max(vecnorm(reshape(data.x,2,[]))), ...
    'learnedCompleted',sum(isfinite(learnedCosts)),'lqrCompleted',sum(isfinite(lqrCosts)), ...
    'pairedSampleCount',sum(finite),'pairedMeanCostDifference',mean(paired(finite)), ...
    'pairedCostDifferenceStandardError',pairedSE,'learnedFiniteCosts',learnedCosts,'lqrFiniteCosts',lqrCosts, ...
    'paperReportedIterations',54,'matchesPaperIterationCount',learning.iterations==54, ...
    'paperCriticWeights',[3.415;2.414;-0.206;-0.007;4.829;-0.125;-0.061], ...
    'paperActorVectorIncomplete',true,'theoremVerified',false);
metrics.criticDistanceToPrintedRoundedWeights=norm(learning.c-metrics.paperCriticWeights);
localPoles=eig([0,1;1+learning.W(1),learning.W(2)]);
metrics.learnedOriginPoleRealParts=real(localPoles);
metrics.learnedOriginPoleImaginaryParts=imag(localPoles);
metrics.learnedTerminalNorms=arrayfun(@(v)v.learned.terminalNorm,evaluation);
metrics.learnedTerminalWithin01=sum(metrics.learnedTerminalNorms<0.01);
metrics.valueMinimumOnCheckSet=min(learning.c'*spec.phi(spec.checkX));
metrics.initialValueMinimumOnCheckSet=min(cfg.critic0'*spec.phi(spec.checkX));
metrics.stateExcitationSingularValues=svd(reshape(data.x,2,[]),'econ');
rng(cfg.diagnosticSeed,'twister');
diagnosticStates=2*rand(2,cfg.diagnosticCount)-1;
metrics.oracleDiagnostics=struct();
for radius=[0.5,3]
    X=radius*diagnosticStates; x1=X(1,:); x2=X(2,:); c=learning.c;
    gradient=[2*c(1)*x1+3*c(3)*x1.^2+c(5)*x2+2*c(6)*x1.*x2+c(7)*x2.^2; ...
        2*c(2)*x2+3*c(4)*x2.^2+c(5)*x1+c(6)*x1.^2+2*c(7)*x1.*x2];
    u=learning.W'*spec.psi(X);
    policyResidual=sum(gradient.*[x2;sin(x1)+u],1)+sum(X.^2,1)+u.^2;
    hjbResidual=sum(gradient.*[x2;sin(x1)],1)+sum(X.^2,1)-0.25*gradient(2,:).^2;
    item=struct('stateRadius',radius,'sampleCount',cfg.diagnosticCount, ...
        'policyBellmanRMS',sqrt(mean(policyResidual.^2)), ...
        'optimizedHJBRMS',sqrt(mean(hjbResidual.^2)), ...
        'actorGreedyMismatchRMS',sqrt(mean((u+0.5*gradient(2,:)).^2)), ...
        'scope','held-out uniform states; known dynamics used only after learning; no global certificate');
    if radius==0.5, metrics.oracleDiagnostics.local=item;
    else, metrics.oracleDiagnostics.evaluationDomain=item; end
end
result=struct('config',cfg,'data',data,'tableInitial',tableInitial,'bootstrap',bootstrap, ...
    'learning',learning,'metrics',metrics,'evaluationInitialStates',initialStates,'evaluation',evaluation, ...
    'reference',struct('K',referenceK,'P',referenceP,'scope','linearized pendulum CARE; applied to nonlinear plant after learning'), ...
    'basis',struct('critic',spec.criticBasis,'actor',spec.actorBasis), ...
    'normalizedOracleDiagnosticStates',diagnosticStates, ...
    'environment',struct('matlab',version,'release',version('-release'),'seed',cfg.seed), ...
    'scope','Fresh fixed-data Bias-PI numerical variant; finite check set and finite closed-loop horizon, no theorem certificate');
if ~isempty(outputDirectory)
    save(fullfile(outputDirectory,'result.mat'),'result','-v7.3');
    fid=fopen(fullfile(outputDirectory,'metrics.json'),'w');
    if fid<0, error('biaspi:Save','Could not open metrics file.'); end
    fileCleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
    fprintf(fid,'%s\n',jsonencode(metrics,'PrettyPrint',true));
    makePlots(outputDirectory);
end
fprintf('Bias-PI pendulum: %s, %d outer/%d inner, gamma %.6g, residual %.6g, paired cost %.6g +/- %.6g SE (%d/%d).\n', ...
    learning.status,learning.iterations,learning.innerIterations,learning.gamma, ...
    learning.finalFit.relativeResidual,metrics.pairedMeanCostDifference,pairedSE,sum(finite),cfg.evaluationCount);
    function makePlots(folder)
        fig=figure('Visible','off','Color','w','Position',[100,100,1000,700]);
        figCleanup=onCleanup(@()close(fig)); %#ok<NASGU>
        tile=tiledlayout(fig,2,2,'TileSpacing','compact');
        nexttile(tile); coefficients=cellfun(@(h)h.c,learning.history,'UniformOutput',false);
        plot(1:learning.iterations,cat(2,coefficients{:})','LineWidth',1.1);
        xlabel('Outer iteration'); ylabel('Critic weights'); grid on;
        nexttile(tile); actors=cellfun(@(h)h.W(:),learning.history,'UniformOutput',false);
        plot(1:learning.iterations,cat(2,actors{:})','LineWidth',1.1);
        xlabel('Outer iteration'); ylabel('Actor weights'); grid on;
        nexttile(tile); plot(1:cfg.evaluationCount,learnedCosts,'o-',1:cfg.evaluationCount,lqrCosts,'s-','LineWidth',1);
        xlabel('Held-out initial state'); ylabel(sprintf('%g-second cost',cfg.evaluationHorizon));
        legend('Bias-PI variant','Linearized LQR','Location','best'); grid on;
        nexttile(tile); plot(1:cfg.evaluationCount,paired,'o','LineWidth',1); yline(0,'k:');
        xlabel('Held-out initial state'); ylabel('Cost difference: Bias-PI minus LQR'); grid on;
        title(tile,sprintf('%s / %s; finite-data numerical variant',cfg.collectionMode,cfg.initialization),'Interpreter','none');
        savefig(fig,fullfile(folder,'pendulum-results.fig'));
        exportgraphics(fig,fullfile(folder,'pendulum-results.png'),'Resolution',180);
    end
    function trace=rollout(xInitial,policy)
        options=odeset('RelTol',1e-8,'AbsTol',1e-10,'MaxStep',cfg.evaluationMaxStep,'Events',@limit);
        [t,z]=ode45(@rhs,[0,cfg.evaluationHorizon],[xInitial;0],options);
        complete=t(end)>=cfg.evaluationHorizon-1e-9;
        trace=struct('t',t,'x',z(:,1:2),'cost',z(end,3),'complete',complete, ...
            'terminalNorm',norm(z(end,1:2)),'termination','horizon_or_explicit_state_limit');
        function dz=rhs(tLocal,zLocal)
            xLocal=zLocal(1:2); uLocal=policy(xLocal);
            dz=[dynamics(tLocal,xLocal,uLocal);sum(xLocal.^2)+uLocal'*uLocal];
        end
        function [value,isterminal,direction]=limit(~,zLocal)
            value=cfg.maximumStateNorm-norm(zLocal(1:2)); isterminal=1; direction=-1;
        end
    end
end
