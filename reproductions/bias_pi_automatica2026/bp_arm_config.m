function [plant,spec,cfg] = bp_arm_config(overrides)
%BP_ARM_CONFIG Automatica 185:112821, Section 4.2, absolute joint angles.
%   Table parameters and explicitly selected numerical parameters are kept
%   separate in cfg.provenance. The plant is used only by data/rollout code.
if nargin<1, overrides=struct; end
cfg=struct('sampleTime',0.05,'collectionTime',10,'substeps',20, ...
    'resetRadius',0.8,'maximumStateNorm',100,'seed',20260907, ...
    'gamma0',15,'deltaBar',16,'deltaH',60,'tolerance',1e-10, ...
    'maxIterations',1000,'maxInnerIterations',100, ...
    'relativeRankTolerance',1e-12,'conditionLimit',1e13, ...
    'initialization','discounted_bootstrap','rolloutTime',5, ...
    'explorationAmplitude',0.01,'dataMode','local_multistart', ...
    'dataTrajectories',20,'localStateScale',[.15;.15;.2;.2]);
cfg.critic0=[1;1;zeros(8,1)];
cfg.actor0=[-1,-1;-1,-1;zeros(6,2)];
names=fieldnames(overrides);
for k=1:numel(names), cfg.(names{k})=overrides.(names{k}); end
if strcmp(cfg.dataMode,'paper_initial') && ~isfield(overrides,'resetRadius')
    cfg.resetRadius=2;
end
plant.target=[pi/4;3*pi/4]; plant.initial=[-pi/4;-pi/4;0;0];
plant.inertia=[0.265,0.052,0.0844]; plant.lengths=[0.33,0.32];
plant.dynamics=@armDynamics;
spec.phi=@armValueBasis; spec.psi=@(X)[X;X.^2];
spec.R=eye(2); spec.stateCost=@(X)sum([5000;2000;20;10].*X.^2,1);
% A deterministic finite set for Algorithm 2's unspecified max_x domain.
% Quadratic V and Q make their ratio invariant under radial scaling.
[a,b,c,d]=ndgrid([-1,-.5,0,.5,1]);
spec.checkX=[a(:),b(:),c(:),d(:)]';
cfg.provenance=struct('paper','Section 4.2 and Table 1', ...
    'selected','seed, independent channel frequencies, reset radius, Simpson substeps, finite threshold grid, rank tolerance, rollout duration', ...
    'initialization','Remark 6 discounted bootstrap by default; paper_table keeps the semidefinite table critic for comparison', ...
    'stateOrder','theta1-target1,theta2-target2,thetaDot1,thetaDot2');
end

function dx=armDynamics(~,x,u)
delta=x(2)-x(1)+pi/2;
D=[.265,.0844*cos(delta);.0844*cos(delta),.052];
C=[0,-.0844*sin(delta)*x(4);.0844*sin(delta)*x(3),0];
dx=[x(3:4);D\(u-C*x(3:4))];
end

function phi=armValueBasis(X)
phi=[X.^2; X(1,:).*X(2,:); X(1,:).*X(3,:); X(1,:).*X(4,:); ...
    X(2,:).*X(3,:); X(2,:).*X(4,:); X(3,:).*X(4,:)];
end
