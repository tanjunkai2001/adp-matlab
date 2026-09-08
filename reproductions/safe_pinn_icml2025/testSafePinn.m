function tests=testSafePinn
tests=functiontests(localfunctions);
end
function setupOnce(t)
rng(7);net=dlnetwork([featureInputLayer(4,Normalization='none');fullyConnectedLayer(8);tanhLayer;fullyConnectedLayer(1)]);
t.TestData.net=dlupdate(@double,net);
end
function testGeometry(t)
[g,l]=boat_geometry([-.5 -1 1.5;.5 -1.2 0]);
verifyEqual(t,g(1:2),[.4 .5],'AbsTol',1e-12);verifyEqual(t,l(3),0,'AbsTol',1e-12);
end
function testTerminalCondition(t)
S=[0 0;-2 .5;1 -.5;3 1];[g,l]=boat_geometry(S(2:3,:));
actual=extractdata(boat_value(t.TestData.net,dlarray(S,'CB')));
verifyEqual(t,actual,max(l-S(4,:),g),'AbsTol',1e-12);
end
function testPhysicalDerivatives(t)
S=[.7;-1.7;.2;2.3];p=dlfeval(@gradient,t.TestData.net,dlarray(S,'CB'));p=extractdata(p);fd=zeros(4,1);
for j=1:4
    e=zeros(4,1);e(j)=1e-6;
    vp=extractdata(boat_value(t.TestData.net,dlarray(S+e,'CB')));
    vm=extractdata(boat_value(t.TestData.net,dlarray(S-e,'CB')));fd(j)=(vp-vm)/2e-6;
end
verifyLessThan(t,norm(p-fd),1e-7);
end
function testHamiltonianMinimization(t)
p=[.4;-.8];theta=linspace(0,2*pi,10001);disk=[cos(theta);sin(theta)];
verifyEqual(t,min(p'*disk),-norm(p),'AbsTol',1e-6);
end
function testBinomialZeroViolations(t)
N=300;beta=.05;
verifyEqual(t,betaincinv(1-beta,1,N),1-beta^(1/N),'AbsTol',1e-12);
end
function testEmptyCalibrationSetReturnsWithoutRollout(t)
% A large positive correction makes every selection value strictly positive.
net=constantCorrection(20);audit=calibrate_boat(net);
verifyEqual(t,audit.status,'empty_predicted_set');
verifyTrue(t,all(isfinite(audit.selectionValues) & audit.selectionValues>0));
verifyFalse(t,isfield(audit,'upperViolationProbability'));
end
function testNonfiniteCalibrationPredictionsAreNotCandidates(t)
% Nonfinite network output must not yield a vacuous probability certificate.
net=dlupdate(@(p)p*NaN,t.TestData.net);audit=calibrate_boat(net);
verifyEqual(t,audit.status,'empty_predicted_set');
verifyFalse(t,any(isfinite(audit.selectionValues)));
verifyFalse(t,isfield(audit,'upperViolationProbability'));
end
function testNonfiniteRolloutIsInvalid(t)
out=boat_rollout(t.TestData.net,[NaN;0],0,.5);
verifyFalse(t,out.numericalValid);
end
function testRejectedDemoPreservesEvaluation(t)
oldRng=rng;t.addTeardown(@()rng(oldRng));
root=tempname;mkdir(root);t.addTeardown(@()rmdir(root,'s'));
% No updates: the same network and heldout set must fail strict improvement.
failure=[];
try
    demo_safe_pinn(root,0);
catch failure
end
assertClass(t,failure,'MException');
verifyEqual(t,failure.identifier,'boat:Training');
verifyEqual(t,failure.message,'No heldout improvement.');
files=dir(fullfile(root,'*','result.mat'));
assertEqual(t,numel(files),1,'A rejected completed evaluation must be saved.');
saved=load(fullfile(files.folder,files.name),'result');r=saved.result;
verifyEqual(t,r.config.iterations,0);
verifySize(t,r.trainingHistory,[0 3]);
verifyEqual(t,r.network.Learnables,r.initialNetwork.Learnables);
verifyEqual(t,r.metrics.finalHeldoutHjbMSE,r.metrics.initialHeldoutHjbMSE);
verifySize(t,r.heldoutInputs,[4 4096]);
verifySize(t,r.testInitial,[2 64]);
verifyEqual(t,r.fineRollout.initial,r.testInitial(:,isfinite(r.budgets)));
metrics=jsondecode(fileread(fullfile(files.folder,'metrics.json')));
verifyEqual(t,metrics,r.metrics);
history=readtable(fullfile(files.folder,'training.csv'));
verifySize(t,history,[0 3]);
verifyFalse(t,isfile(fullfile(files.folder,'safe-pinn.png')));
end
function testAugmentedRK4AgainstHeldInputOracle(t)
% For held u the boat path is a cubic polynomial, independent of the solver.
% This detects the old Euler-midpoint Simpson cost (error about 3.6e-4).
net=constantCorrection(0);x0=[-2;1.5];h=.2;budget=0;
out=boat_rollout(net,x0,budget,h);
u=squeeze(out.u_applied(1,:,1))';
expectedU=-[x0(1)-1.5;x0(2)]/norm([x0(1)-1.5;x0(2)]);
verifyEqual(t,u,expectedU,'AbsTol',1e-12);
exactX=@(s)x0(1)+(u(1)+2-.5*x0(2)^2)*s-.5*x0(2)*u(2)*s.^2-u(2)^2*s.^3/6;
exactY=@(s)x0(2)+u(2)*s;
exactCost=integral(@(s)sqrt((exactX(s)-1.5).^2+exactY(s).^2),0,h, ...
    'AbsTol',1e-13,'RelTol',1e-13);
verifyEqual(t,squeeze(out.x(2,:,1))',[exactX(h);exactY(h)],'AbsTol',1e-12);
verifyLessThan(t,abs(budget-out.budget(2)-exactCost),1e-6);
verifyTrue(t,out.numericalValid);
verifyLessThanOrEqual(t,max(vecnorm(squeeze(out.u_applied(:,:,1)),2,2)),1+1e-12);
[~,terminal]=boat_geometry(squeeze(out.x(end,:,1))');
verifyEqual(t,out.cost,budget-out.budget(end)+terminal,'AbsTol',1e-12);
end
function net=constantCorrection(bias)
net=dlnetwork([featureInputLayer(4,Normalization='none'); ...
    fullyConnectedLayer(1,Weights=zeros(1,4),Bias=double(bias))]);
net=dlupdate(@double,net);
end
function p=gradient(net,S)
v=boat_value(net,S);p=dlgradient(sum(v,'all'),S);
end
