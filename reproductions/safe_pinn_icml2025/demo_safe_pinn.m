function [result,runDir]=demo_safe_pinn(outputRoot,iterations)
%DEMO_SAFE_PINN ICML 2025 epigraph-HJB boat, reduced MATLAB training variant.
% No conformal safety certificate is claimed by this reduced experiment.
if nargin<1,outputRoot=fullfile(fileparts(mfilename('fullpath')),'runs');end
if nargin<2,iterations=5000;end
rng(25051,'twister');cfg=struct('seed',25051,'iterations',iterations,'width',64, ...
    'depth',2,'batchSize',512,'totalHorizon',2,'hardTerminal',true, ...
    'activation','tanh','cost','distance to goal plus terminal distance', ...
    'domain',[-3 2;-2 2;-.1 14.86],'curriculumIterations',round(.8*iterations));
layers=[featureInputLayer(4,Normalization='none');fullyConnectedLayer(64);tanhLayer; ...
    fullyConnectedLayer(64);tanhLayer;fullyConnectedLayer(1)];
net=dlupdate(@double,dlnetwork(layers));initialNet=net;
% A fixed independent validation set also makes the before/after comparable.
testS=sample(4096,2);testX=sample(10000,2);testX=testX(2:3,:);
g=boat_geometry(testX);testX=testX(:,g<-.03 & testX(1,:)<1);testX=testX(:,1:64);
accelerated=dlaccelerate(@boat_loss);average=[];averageSq=[];history=zeros(iterations,3);
[initialLoss,~,~]=dlfeval(accelerated,net,dlarray(testS,'CB'));
timer=tic;
for k=1:iterations
    rngBeforeBatch=rng;
    tauMax=2*min(1,k/max(1,cfg.curriculumIterations));S=sample(cfg.batchSize,tauMax);
    [loss,gradient]=dlfeval(accelerated,net,dlarray(S,'CB'));
    rate=1e-3/(1+4*k/iterations);
    stage='loss';
    try
        assert(isfinite(extractdata(loss)),'boat:Training','Nonfinite training loss.');
        stage='gradient';
        assert(finiteParameters(gradient),'boat:Training','Nonfinite training gradient.');
        stage='adam_update';
        [nextNet,nextAverage,nextAverageSq]=adamupdate(net,gradient,average,averageSq,k,rate);
        assert(finiteParameters(nextNet.Learnables) && finiteParameters(nextAverage) && ...
            finiteParameters(nextAverageSq),'boat:Training','Nonfinite Adam update.');
    catch failure
        try
            % These are the last accepted parameters; the failed batch is diagnostic data.
            failureState=struct('config',cfg,'network',net,'initialNetwork',initialNet, ...
                'average',average,'averageSq',averageSq,'lastCompletedIteration',k-1, ...
                'attemptedIteration',k,'trainingHistory',history(1:k-1,:), ...
                'batch',S,'loss',double(extractdata(loss)),'gradient',gradient, ...
                'stage',stage,'identifier',failure.identifier,'message',failure.message, ...
                'heldoutInputs',testS,'testInitial',testX, ...
                'initialHeldoutHjbMSE',double(extractdata(initialLoss)), ...
                'rngBeforeBatch',rngBeforeBatch,'rngState',rng,'environment',version);
            if ~isfolder(outputRoot),mkdir(outputRoot);end
            runDir=tempname(outputRoot);mkdir(runDir);
            save(fullfile(runDir,'training-failure.mat'),'failureState','-v7.3');
            fprintf('Saved Safe PINN training failure: %s\n',runDir);
        catch saveFailure
            failure=addCause(failure,saveFailure);
        end
        rethrow(failure);
    end
    net=nextNet;average=nextAverage;averageSq=nextAverageSq;
    history(k,:)=[k,double(extractdata(loss)),toc(timer)];
    if mod(k,500)==0 || k==1,fprintf('Safe PINN %d/%d loss=%.4g time=%.1fs\n',k,iterations,history(k,2:3));end
end
[heldout,~,residual]=dlfeval(accelerated,net,dlarray(testS,'CB'));
boundary=testS;boundary(1,:)=0;[g,l]=boat_geometry(boundary(2:3,:));
boundaryError=max(abs(extractdata(boat_value(net,dlarray(boundary,'CB')))-max(l-boundary(4,:),g)));
% Eq.(3): lowest sampled budget whose predicted epigraph value is <=0.
zgrid=linspace(0,14.86,100);budgets=NaN(1,size(testX,2));prediction=budgets;
for j=1:size(testX,2)
    S=[2+zeros(size(zgrid));repmat(testX(:,j),1,numel(zgrid));zgrid];
    vals=extractdata(boat_value(net,dlarray(S,'CB')));idx=find(vals<=0,1);
    if ~isempty(idx),budgets(j)=zgrid(idx);prediction(j)=vals(idx);end
end
accepted=isfinite(budgets);rollout=boat_rollout(net,testX(:,accepted),budgets(accepted),.01);
fine=boat_rollout(net,testX(:,accepted),budgets(accepted),.005);
metrics=struct('initialHeldoutHjbMSE',double(extractdata(initialLoss)), ...
    'finalHeldoutHjbMSE',double(extractdata(heldout)), ...
    'terminalMaxError',boundaryError,'candidateCount',numel(accepted), ...
    'predictedFeasibleCount',sum(accepted),'fineRolloutCollisionCount',sum(fine.maxObstacleG>0), ...
    'fineBudgetViolationCount',sum(fine.cost>fine.initialBudget), ...
    'leftTrainingDomainCount',sum(fine.leftTrainingDomain), ...
    'costStepDifferenceMax',max(abs(rollout.cost-fine.cost)), ...
    'maxGStepDifferenceMax',max(abs(rollout.maxObstacleG-fine.maxObstacleG)), ...
    'conformalCalibrationExecuted',false);
result=struct('config',cfg,'network',net,'initialNetwork',initialNet,'trainingHistory',history, ...
    'heldoutInputs',testS,'heldoutResidual',extractdata(residual),'testInitial',testX, ...
    'budgets',budgets,'prediction',prediction,'coarseRollout',rollout,'fineRollout',fine, ...
    'metrics',metrics,'environment',version,'rngState',rng);
if ~isfolder(outputRoot),mkdir(outputRoot);end
runDir=tempname(outputRoot);mkdir(runDir);save(fullfile(runDir,'result.mat'),'result','-v7.3');
fid=fopen(fullfile(runDir,'metrics.json'),'w');fprintf(fid,'%s\n',jsonencode(metrics,PrettyPrint=true));fclose(fid);
writetable(array2table(history,VariableNames={'iteration','hjbMSE','seconds'}),fullfile(runDir,'training.csv'));
fprintf('Saved Safe PINN evaluation: %s\n',runDir);
assert(metrics.finalHeldoutHjbMSE<metrics.initialHeldoutHjbMSE,'boat:Training','No heldout improvement.');
assert(boundaryError<1e-12,'boat:Terminal','Incorrect terminal condition.');
fig=figure(Visible='off');tiledlayout(1,2);nexttile;semilogy(history(:,1),history(:,2));grid on;xlabel('Update');ylabel('HJB MSE');
nexttile;hold on;a=linspace(0,2*pi,120);fill(-.5+.4*cos(a),.5+.4*sin(a),[.8 .7 .7]);fill(-1+.5*cos(a),-1.2+.5*sin(a),[.8 .7 .7]);
for j=1:min(12,sum(accepted)),plot(fine.x(:,1,j),fine.x(:,2,j));end
plot(1.5,0,'kp',MarkerSize=10);axis equal;grid on;xlabel('x');ylabel('y');
exportgraphics(fig,fullfile(runDir,'safe-pinn.png'),Resolution=160);close(fig);
fprintf('Safe PINN metrics: %s\n',jsonencode(metrics));
end
function S=sample(N,tauMax)
S=[tauMax*rand(1,N);-3+5*rand(1,N);-2+4*rand(1,N);-.1+14.96*rand(1,N)];
end
function ok=finiteParameters(parameters)
ok=true;
for j=1:height(parameters)
    ok=ok && all(isfinite(extractdata(parameters.Value{j})),'all');
end
end
