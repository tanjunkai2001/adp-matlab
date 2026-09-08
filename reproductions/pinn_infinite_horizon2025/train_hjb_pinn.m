function [net,history,data] = train_hjb_pinn(cfg,previous)
%TRAIN_HJB_PINN Adam training on model-based finite-horizon HJB collocation.
% The previous finite-horizon t=0 network supplies a frozen terminal target
% for horizon continuation (paper equations 23-26). No oracle labels are used.
arguments
    cfg struct
    previous = []
end
rng(cfg.seed,'twister');
n=cfg.stateDimension;
layers=featureInputLayer(n+1,Normalization='none',Name='input');
for k=1:cfg.depth
    layers=[layers;fullyConnectedLayer(cfg.width,Name="fc"+k);tanhLayer(Name="tanh"+k)]; %#ok<AGROW>
end
layers=[layers;fullyConnectedLayer(1,Name='value')];
net=dlnetwork(layers); net=dlupdate(@double,net);
if ~isempty(previous) && cfg.warmStart, net=previous; end
% Fixed collocation sets, independently seeded test set is created later.
data.flow=[(2*rand(n,cfg.flowPoints)-1)*cfg.trainingDomain;rand(1,cfg.flowPoints)*cfg.increment];
data.boundary=[(2*rand(n,cfg.boundaryPoints)-1)*cfg.trainingDomain;cfg.increment*ones(1,cfg.boundaryPoints)];
if isempty(previous)
    data.terminal=zeros(1,cfg.boundaryPoints);
else
    terminalInput=data.boundary;terminalInput(end,:)=0;
    data.terminal=extractdata(pinn_value(previous,dlarray(terminalInput,'CB'),cfg));
end
data.initialRngState=rng;
acceleratedLoss=dlaccelerate(@pinn_loss);
average=[];averageSq=[];history=zeros(cfg.iterations,6);timer=tic;
for iteration=1:cfg.iterations
    fi=randperm(cfg.flowPoints,cfg.batchSize);
    bi=randperm(cfg.boundaryPoints,cfg.boundaryBatchSize);
    xt=dlarray(data.flow(:,fi),'CB'); xb=dlarray(data.boundary(:,bi),'CB');
    terminal=dlarray(data.terminal(:,bi),'CB');
    [loss,gradients,parts]=dlfeval(acceleratedLoss,net,xt,xb,terminal,cfg);
    learningRate=cfg.learningRate/(1+cfg.decay*iteration);
    [net,average,averageSq]=adamupdate(net,gradients,average,averageSq,iteration,learningRate);
    history(iteration,:)=[iteration,double(extractdata(loss)),double(extractdata(parts(1))),double(extractdata(parts(2))),learningRate,toc(timer)];
    if ~all(isfinite(history(iteration,2:4)))
        error('pinn:NonfiniteLoss','Nonfinite PINN loss at iteration %d.',iteration);
    end
    if mod(iteration,cfg.reportEvery)==0 || iteration==1
        fprintf('%s T=%g iteration=%d loss=%.4g flow=%.4g terminal=%.4g elapsed=%.1fs\n',cfg.problem,cfg.totalHorizon,iteration,history(iteration,2:4),history(iteration,6));
    end
end
data.finalRngState=rng;
end
