function [result,runDir]=demo_bias_pi_arm(outputDirectory,overrides)
%DEMO_BIAS_PI_ARM Two-joint arm, fixed off-policy data and nonlinear rollout.
if nargin<1, outputDirectory=[]; end
if nargin<2, overrides=struct; end
oldRng=rng; restore=onCleanup(@()rng(oldRng)); %#ok<NASGU>
[plant,spec,cfg]=bp_arm_config(overrides);
rng(cfg.seed,'twister'); frequencies=100*rand(50,2)-50;
tableCritic=cfg.critic0; tableActor=cfg.actor0;
behavior=@(t,x)tableActor'*spec.psi(x)+ ...
    cfg.explorationAmplitude*sum(sin(frequencies*t),1)';
if strcmp(cfg.dataMode,'paper_initial')
    data=bp_collect(plant.dynamics,behavior,spec.stateCost,plant.initial,cfg);
elseif strcmp(cfg.dataMode,'local_multistart')
    initialStates=cfg.localStateScale.*(2*rand(4,cfg.dataTrajectories)-1);
    partCfg=cfg; partCfg.collectionTime=cfg.collectionTime/cfg.dataTrajectories;
    for trial=1:cfg.dataTrajectories
        offset=(trial-1)*partCfg.collectionTime;
        part=bp_collect(plant.dynamics,@(t,x)behavior(t+offset,x), ...
            spec.stateCost,initialStates(:,trial),partCfg);
        part.t=part.t+offset;
        if trial<cfg.dataTrajectories, part.resetAfterWindow(end)=true; end
        if trial==1, data=part;
        else
            for field={'x','u','t','q'}
                data.(field{1})=cat(3,data.(field{1}),part.(field{1}));
            end
            data.resetAfterWindow=[data.resetAfterWindow,part.resetAfterWindow];
        end
    end
    data.config=cfg; data.initialStates=initialStates;
else, error('biaspi:DataMode','Use paper_initial or local_multistart.'); end
bootstrap=[];
if strcmp(cfg.initialization,'discounted_bootstrap')
    [A,y]=bp_regression(data,spec,tableActor,tableCritic,cfg.gamma0,'discounted');
    [weights,bootstrap]=bp_solve(A,y,cfg);
    cfg.critic0=weights(1:10); cfg.actor0=reshape(weights(11:end),8,2);
elseif ~strcmp(cfg.initialization,'paper_table')
    error('biaspi:Initialization','Use discounted_bootstrap or paper_table.');
end
learning=bp_learn(data,spec,cfg);
% Simulator truth below supplies independent evaluation, never the learner.
A0=[zeros(2),eye(2);zeros(2,4)]; B0=[zeros(2);diag([1/.265,1/.052])];
[K,P]=lqr(A0,B0,diag([5000,2000,20,10]),eye(2));
policies={@(x)learning.W'*spec.psi(x),@(x)-K*x, ...
    @(x)tableActor'*spec.psi(x)};
labels={'bias_pi','local_lqr','table_initial'}; rollouts=struct;
for k=1:numel(labels)
    rollouts.(labels{k})=rollout(policies{k});
end
criticP=diag(learning.c(1:4)); pairs=nchoosek(1:4,2);
for k=1:6, criticP(pairs(k,1),pairs(k,2))=learning.c(k+4)/2; end
criticP=criticP+triu(criticP,1)';
publishedC=[524.1219;165.9751;.7748;.3010;12.8742;33.0139;1.5429;.2980;3.6639;.0071];
publishedW=[-70.8355,1.1940,-7.3097,.0090,.1090,-.0103,-.1836,-.0653; ...
    -1.8686,-44.7059,-.3362,-3.7168,-.3323,-.0043,.0907,.0029]';
summary=struct('example','two_joint_arm','initialization',cfg.initialization,'dataMode',cfg.dataMode, ...
    'status',learning.status,'iterations',learning.iterations,'innerIterations',learning.innerIterations, ...
    'finalGamma',learning.gamma,'dataWindows',size(data.x,3), ...
    'resets',nnz(data.resetAfterWindow),'regressionRank',learning.finalFit.rank, ...
    'unknownWeights',26,'criticMinEigenvalue',min(eig(criticP)), ...
    'initialCriticMinEigenvalue',min(eig(valueMatrix(cfg.critic0))), ...
    'closedLoopSpectralAbscissa',max(real(eig(A0+B0*learning.W(1:4,:)'))), ...
    'learnedCost',rollouts.bias_pi.cost,'lqrCost',rollouts.local_lqr.cost, ...
    'finalStateNorm',norm(rollouts.bias_pi.x(end,:)), ...
    'stateLimitHit',rollouts.bias_pi.stateLimitHit,'completedHorizon',rollouts.bias_pi.duration, ...
    'criticRelativeToPublished',norm(learning.c-publishedC)/norm(publishedC), ...
    'actorRelativeToPublished',norm(learning.W-publishedW,'fro')/norm(publishedW,'fro'), ...
    'paperIterationCount',45,'paperTableInitialCriticPositiveDefinite',false);
result=struct('config',cfg,'frequencies',frequencies,'data',data,'bootstrap',bootstrap, ...
    'learning',learning,'rollouts',rollouts,'summary',summary, ...
    'localLqr',struct('K',K,'P',P),'published',struct('critic',publishedC,'actor',publishedW), ...
    'tableInitialization',struct('critic',tableCritic,'actor',tableActor));
if isempty(outputDirectory)
    root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    outputDirectory=fullfile(root,'runs',['bias-pi-arm-',char(datetime('now','Format','yyyyMMdd-HHmmss-SSS'))]);
end
runDir=char(outputDirectory);
if isfolder(runDir), error('biaspi:ExistingRun','Choose a new output directory.'); end
mkdir(runDir); save(fullfile(runDir,'result.mat'),'result','-v7.3');
fid=fopen(fullfile(runDir,'summary.json'),'w');
fprintf(fid,'%s\n',jsonencode(summary,PrettyPrint=true)); fclose(fid);
f=figure('Visible','off','Color','w','Position',[100,100,1100,400]);
tiledlayout(1,2);
nexttile; plot(rollouts.bias_pi.t,rollouts.bias_pi.x,'LineWidth',1.3);
xlabel('Time (s)'); ylabel('State'); grid on; legend('e_1','e_2','v_1','v_2');
nexttile; hold on;
for k=1:2
    r=rollouts.(labels{k}); angles=r.x(:,1:2)+plant.target';
    xy=[sum(plant.lengths.*cos(angles),2),sum(plant.lengths.*sin(angles),2)];
    plot(xy(:,1),xy(:,2),'LineWidth',1.3);
end
axis equal; grid on; xlabel('Hand x (m)'); ylabel('Hand y (m)'); legend('Bias-PI','Local LQR');
exportgraphics(f,fullfile(runDir,'arm.png'),'Resolution',180);
savefig(f,fullfile(runDir,'arm.fig')); close(f); disp(summary);

    function r=rollout(policy)
        times=linspace(0,cfg.rolloutTime,501);
        options=odeset('RelTol',1e-8,'AbsTol',1e-10,'MaxStep',0.01,'Events',@limit);
        [t,z,te]=ode45(@rhs,times,[plant.initial;0],options);
        r=struct('t',t,'x',z(:,1:4),'cost',z(end,5),'stateLimitHit',~isempty(te), ...
            'duration',t(end),'requestedDuration',cfg.rolloutTime);
        function dz=rhs(t,x)
            u=policy(x(1:4));
            dz=[plant.dynamics(t,x(1:4),u);spec.stateCost(x(1:4))+u'*u];
        end
        function [value,stop,direction]=limit(~,x)
            value=cfg.maximumStateNorm-norm(x(1:4)); stop=1; direction=-1;
        end
    end
end

function P=valueMatrix(c)
P=diag(c(1:4)); pairs=nchoosek(1:4,2);
for j=1:6, P(pairs(j,1),pairs(j,2))=c(j+4)/2; end
P=P+triu(P,1)';
end
