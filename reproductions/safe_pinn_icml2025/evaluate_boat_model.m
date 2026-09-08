function result=evaluate_boat_model(net,outputRoot,comparisonFile)
%EVALUATE_BOAT_MODEL Fixed-input evaluation shared by author/reduced models.
% comparisonFile is a saved demo_safe_pinn result to reuse identical inputs.
s=load(comparisonFile,'result');testS=s.result.heldoutInputs;X=s.result.testInitial;
[mse,residual]=dlfeval(@residualLoss,net,dlarray(testS,'CB'));
boundary=testS;boundary(1,:)=0;[g,l]=boat_geometry(boundary(2:3,:));
boundaryError=max(abs(extractdata(boat_value(net,dlarray(boundary,'CB')))-max(l-boundary(4,:),g)));
zgrid=linspace(0,14.86,100);budgets=NaN(1,size(X,2));prediction=budgets;
for j=1:size(X,2)
    S=[2+zeros(size(zgrid));repmat(X(:,j),1,numel(zgrid));zgrid];
    vals=extractdata(boat_value(net,dlarray(S,'CB')));idx=find(isfinite(vals)&vals<=0,1);
    if ~isempty(idx),budgets(j)=zgrid(idx);prediction(j)=vals(idx);end
end
accepted=isfinite(budgets);coarse=boat_rollout(net,X(:,accepted),budgets(accepted),.01);
fine=boat_rollout(net,X(:,accepted),budgets(accepted),.005);
metrics=struct('heldoutHjbMSE',mse,'terminalMaxError',boundaryError, ...
    'candidateCount',size(X,2),'predictedFeasibleCount',sum(accepted), ...
    'fineRolloutCollisionCount',sum(fine.maxObstacleG>0), ...
    'fineBudgetViolationCount',sum(fine.cost>fine.initialBudget), ...
    'nonfiniteCount',sum(~fine.numericalValid), ...
    'leftTrainingDomainCount',sum(fine.leftTrainingDomain), ...
    'costStepDifferenceMax',max(abs(coarse.cost-fine.cost)), ...
    'maxGStepDifferenceMax',max(abs(coarse.maxObstacleG-fine.maxObstacleG)));
result=struct('network',net,'metrics',metrics,'inputs',testS,'residual',residual, ...
    'testInitial',X,'budgets',budgets,'prediction',prediction, ...
    'coarseRollout',coarse,'fineRollout',fine,'matlabVersion',version);
if ~isfolder(outputRoot),mkdir(outputRoot);end
save(fullfile(outputRoot,'evaluation.mat'),'result','-v7.3');
fid=fopen(fullfile(outputRoot,'metrics.json'),'w');fprintf(fid,'%s\n',jsonencode(metrics,PrettyPrint=true));fclose(fid);
fig=figure(Visible='off');hold on;a=linspace(0,2*pi,120);
fill(-.5+.4*cos(a),.5+.4*sin(a),[.8 .7 .7]);fill(-1+.5*cos(a),-1.2+.5*sin(a),[.8 .7 .7]);
for j=1:min(20,sum(accepted)),plot(fine.x(:,1,j),fine.x(:,2,j));end
plot(1.5,0,'kp',MarkerSize=10);axis equal;grid on;xlabel('x');ylabel('y');
title(sprintf('Predicted feasible %d; collisions %d',sum(accepted),metrics.fineRolloutCollisionCount));
savefig(fig,fullfile(outputRoot,'trajectories.fig'));exportgraphics(fig,fullfile(outputRoot,'trajectories.png'),Resolution=160);close(fig);
end
function [mse,residual]=residualLoss(net,S)
V=boat_value(net,S);p=dlgradient(sum(V,'all'),S);[g,l]=boat_geometry(S(2:3,:));
H=(2-.5*S(3,:).^2).*p(2,:)-sqrt(p(2,:).^2+p(3,:).^2+1e-12)-p(4,:).*l;
residual=extractdata(min(p(1,:)-H,V-g));mse=mean(residual.^2,'all');
end
