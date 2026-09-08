function [cfg,spec] = bp_pendulum_config()
%BP_PENDULUM_CONFIG Paper Table1 settings, with declared missing choices.
cfg.example='pendulum'; cfg.seed=20260907;
cfg.initialization='discounted_bootstrap';
cfg.behaviorMode='exploration_only';
cfg.collectionMode='local_multistart';
cfg.multiStartCount=20; cfg.multiStartRadius=0.5; cfg.multiStartSeed=20260908;
cfg.sampleTime=0.01; cfg.collectionTime=5; cfg.substeps=4;
cfg.resetRadius=3; cfg.maximumStateNorm=1e4; cfg.x0=[0;0.01];
cfg.frequencyCount=50; cfg.frequencyRange=[-50,50]; cfg.explorationAmplitude=0.01;
cfg.critic0=[1;1;0;0;0;0;0]; cfg.actor0=[-1;-1;0;0;0];
cfg.gamma0=6; cfg.deltaBar=8; cfg.deltaH=30; cfg.tolerance=1e-6;
cfg.maxIterations=1000; cfg.maxInnerIterations=200;
cfg.relativeRankTolerance=1e-11; cfg.conditionLimit=1e10;
cfg.checkRadius=3; cfg.checkGridCount=41;
cfg.evaluationSeed=1729; cfg.evaluationCount=35;
cfg.evaluationHorizon=20; cfg.evaluationMaxStep=0.02;
cfg.diagnosticSeed=4242; cfg.diagnosticCount=1000;
cfg.variant=['Paper table basis/initial weights/gamma/sample period/data duration. ', ...
    'Chosen seed, RK4/Simpson substeps, reset radius, beta restart, finite check grid and rollout horizon. ', ...
    'Default uses explicit local multistart data and Remark6 discounted bootstrap; table initialization and single trajectory remain available. ', ...
    'Exploration-only behavior follows Sec4/Table1; Algorithm2 instead writes u0+e.'];
spec.phi=@(X) [X(1,:).^2;X(2,:).^2;X(1,:).^3;X(2,:).^3; ...
    X(1,:).*X(2,:);X(1,:).^2.*X(2,:);X(1,:).*X(2,:).^2];
spec.psi=@(X) [X(1,:);X(2,:);X(1,:).^2;X(2,:).^2;X(1,:).*X(2,:)];
spec.R=1; spec.stateCost=@(X) sum(X.^2,1);
[a,b]=meshgrid(linspace(-cfg.checkRadius,cfg.checkRadius,cfg.checkGridCount));
spec.checkX=[a(:)';b(:)'];
spec.criticBasis='[x1^2,x2^2,x1^3,x2^3,x1*x2,x1^2*x2,x1*x2^2]';
spec.actorBasis='[x1,x2,x1^2,x2^2,x1*x2]';
end
