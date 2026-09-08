function tests=testPinn
tests=functiontests(localfunctions);
end

function setupOnce(tc)
old=rng;tc.addTeardown(@()rng(old));rng(4181);
net=dlnetwork([featureInputLayer(3,Normalization='none'); ...
    fullyConnectedLayer(6);tanhLayer;fullyConnectedLayer(1)]);
tc.TestData.net=dlupdate(@double,net);
tc.TestData.cfg=struct('trainingDomain',1.7,'increment',.6,'problem','pendulum','R',2);
end

function testScalarFiniteHorizonHjb(tc)
X=[-.8,.2,.7;0,.3,.6]; H=.9;
[value,grad]=dlfeval(@scalarValue,dlarray(X,'CB'),H);
[f,g,q]=pinn_problem('scalar_lqr',X(1,:));grad=extractdata(grad);
residual=grad(2,:)+f.*grad(1,:)+q-(g.*grad(1,:)).^2/4;
verifyLessThan(tc,max(abs(residual)),1e-12);
verifyEqual(tc,extractdata(value),tanh(H-X(2,:)).*X(1,:).^2,'AbsTol',1e-13);
end

function testQuarticPaperMismatchAndCorrectedOracle(tc)
X=[-.8,.4,.7;.9,-.3,.6]; grad=[X(1,:);2*X(2,:)+4*X(2,:).^3];
[f,g,q]=pinn_problem('quartic_paper',X);
residual=sum(f.*grad,1)+q-sum(g.*grad,1).^2/4;
verifyEqual(tc,residual,-X(2,:).^4,'AbsTol',1e-12);
[fc,gc,qc,oracle]=pinn_problem('quartic_corrected',X);
verifyLessThan(tc,max(abs(sum(fc.*grad,1)+qc-sum(gc.*grad,1).^2/4)),1e-12);
verifyEqual(tc,oracle.control,-sum(gc.*grad,1)/2,'AbsTol',1e-13);
end

function testValueOriginSymmetryAndPhysicalDerivatives(tc)
cfg=tc.TestData.cfg;net=tc.TestData.net;X=[.3,-.7;.8,.2;.17,.43];
value=extractdata(pinn_value(net,dlarray(X,'CB'),cfg));
mirrored=X;mirrored(1:2,:)=-mirrored(1:2,:);
verifyEqual(tc,value,extractdata(pinn_value(net,dlarray(mirrored,'CB'),cfg)),'AbsTol',1e-13);
origin=X;origin(1:2,:)=0;
verifyEqual(tc,extractdata(pinn_value(net,dlarray(origin,'CB'),cfg)),zeros(1,2),'AbsTol',1e-13);
grad=extractdata(dlfeval(@valueGradient,net,dlarray(X,'CB'),cfg));
verifyEqual(tc,grad,finiteDifference(net,X,cfg),'AbsTol',1e-7);
end

function testHjbLossAgainstIndependentFiniteDifferences(tc)
cfg=tc.TestData.cfg;net=tc.TestData.net;
X=[.3,-.7;.8,.2;.17,.43];B=[.1,.5;-.2,.3;.6,.6];target=[.07,.11];
[loss,gradients,parts]=dlfeval(@pinn_loss,net,dlarray(X,'CB'), ...
    dlarray(B,'CB'),dlarray(target,'CB'),cfg);
derivative=finiteDifference(net,X,cfg);[f,g,q]=pinn_problem(cfg.problem,X(1:2,:));
u=-sum(g.*derivative(1:2,:),1)/(2*cfg.R);
flow=derivative(3,:)+sum(derivative(1:2,:).*(f+g.*u),1)+q+cfg.R*u.^2;
boundary=extractdata(pinn_value(net,dlarray(B,'CB'),cfg))-target;
expected=[mean(flow.^2);mean(boundary.^2)];
verifyEqual(tc,extractdata(parts),expected,'AbsTol',1e-6);
verifyEqual(tc,extractdata(loss),sum(expected),'AbsTol',1e-6);
for k=1:height(gradients),verifyTrue(tc,all(isfinite(extractdata(gradients.Value{k})),'all'));end
end

function testFrozenTerminalTargetAndSingleUpdateReplay(tc)
cfg=tc.TestData.cfg;
cfg.stateDimension=2;cfg.depth=1;cfg.width=6;cfg.seed=118;
cfg.warmStart=true;cfg.flowPoints=24;cfg.boundaryPoints=16;
cfg.batchSize=8;cfg.boundaryBatchSize=8;cfg.iterations=1;
cfg.learningRate=.001;cfg.decay=0;cfg.reportEvery=1;cfg.totalHorizon=1.2;
previous=tc.TestData.net;before=previous.Learnables;
[first,h1,d1]=train_hjb_pinn(cfg,previous);
[second,h2,d2]=train_hjb_pinn(cfg,previous);
terminalInput=d1.boundary;terminalInput(end,:)=0;
expected=extractdata(pinn_value(previous,dlarray(terminalInput,'CB'),cfg));
verifyEqual(tc,d1.terminal,expected,'AbsTol',1e-13);
verifyEqual(tc,d1.flow,d2.flow);verifyEqual(tc,h1(:,2:5),h2(:,2:5),'AbsTol',1e-13);
for k=1:height(before)
    verifyEqual(tc,extractdata(previous.Learnables.Value{k}),extractdata(before.Value{k}));
    verifyEqual(tc,extractdata(first.Learnables.Value{k}),extractdata(second.Learnables.Value{k}),'AbsTol',1e-13);
end
end

function [v,g]=scalarValue(X,H)
v=tanh(H-X(2,:)).*X(1,:).^2;g=dlgradient(sum(v,'all'),X);
end
function g=valueGradient(net,X,cfg)
v=pinn_value(net,X,cfg);g=dlgradient(sum(v,'all'),X);
end
function g=finiteDifference(net,X,cfg)
h=1e-6;g=zeros(size(X));
for j=1:size(X,1)
    offset=zeros(size(X));offset(j,:)=h;
    vp=extractdata(pinn_value(net,dlarray(X+offset,'CB'),cfg));
    vm=extractdata(pinn_value(net,dlarray(X-offset,'CB'),cfg));g(j,:)=(vp-vm)/(2*h);
end
end
