function audit=calibrate_boat(net,outputRoot)
%CALIBRATE_BOAT Independent level selection and conditional rollout audit.
% Implements the binomial tail underlying paper Eq.(14), with a fresh audit
% sample after selecting delta. The bound concerns this numerical rollout
% label and uniform augmented initial states, not every continuous trajectory.
rng(25052,'twister');selection=draw(2000);v=value(net,selection);
eligible=isfinite(v) & v<=0;
if ~any(eligible)
    audit=struct('status','empty_predicted_set','seed',25052,'selectionInputs',selection,'selectionValues',v);
    if nargin>=2,save(fullfile(outputRoot,'calibration.mat'),'audit');end
    return
end
roll=boat_rollout(net,selection(1:2,eligible),selection(3,eligible),.005);
selectedV=v(eligible);bad=~roll.numericalValid | ~isfinite(roll.epigraphRollout) | roll.epigraphRollout>=0;
delta=0;if any(bad),delta=min(selectedV(bad))-1e-8;end
N=300;accepted=zeros(3,0);proposed=0;
while size(accepted,2)<N && proposed<100000
    S=draw(2000);p=value(net,S);accepted=[accepted,S(:,isfinite(p)&p<=delta)]; %#ok<AGROW>
    proposed=proposed+2000;
end
audit=struct('seed',25052,'delta',delta,'selectionInputs',selection, ...
    'selectionValues',v,'selectionEligible',eligible,'selectionRollout',roll, ...
    'targetSamples',N,'proposalCount',proposed,'beta',.05, ...
    'sampling','uniform x in [-3,2], y in [-2,2], z in [0,14.86], conditioned on V<=delta', ...
    'status','empty_or_small_selected_set','sampleCount',size(accepted,2));
if size(accepted,2)>=N
    accepted=accepted(:,1:N);r=boat_rollout(net,accepted(1:2,:),accepted(3,:),.005);
    fine=boat_rollout(net,accepted(1:2,:),accepted(3,:),.0025);
    bad=~r.numericalValid | ~isfinite(r.epigraphRollout) | r.epigraphRollout>=0;
    fineBad=~fine.numericalValid | ~isfinite(fine.epigraphRollout) | fine.epigraphRollout>=0;
    k=sum(bad);kf=sum(fineBad);
    if k==N,upper=1;else,upper=betaincinv(1-audit.beta,k+1,N-k);end
    audit.status='conditional_numerical_rollout_bound';audit.sampleCount=N;
    audit.inputs=accepted;audit.rollout=r;audit.fineRollout=fine;
    audit.violationCount=k;audit.fineViolationCount=kf;audit.upperViolationProbability=upper;
    audit.collisionCount=sum(r.maxObstacleG>=0);audit.budgetViolationCount=sum(r.cost>=r.initialBudget);
    audit.fineCollisionCount=sum(fine.maxObstacleG>=0);audit.fineBudgetViolationCount=sum(fine.cost>=fine.initialBudget);
    audit.stepLabelDisagreements=sum(bad~=fineBad);
    audit.nonfiniteCount=sum(~r.numericalValid);audit.fineNonfiniteCount=sum(~fine.numericalValid);
    audit.alpha=(k+1)/(N+1);
end
if nargin>=2
    save(fullfile(outputRoot,'calibration.mat'),'audit','-v7.3');
    summary=rmfield(audit,intersect(fieldnames(audit), ...
        {'selectionInputs','selectionValues','selectionEligible','selectionRollout','inputs','rollout','fineRollout'}));
    fid=fopen(fullfile(outputRoot,'calibration.json'),'w');fprintf(fid,'%s\n',jsonencode(summary,PrettyPrint=true));fclose(fid);
end
end
function S=draw(N)
S=[-3+5*rand(1,N);-2+4*rand(1,N);14.86*rand(1,N)];
end
function v=value(net,S)
v=extractdata(boat_value(net,dlarray([2+zeros(1,size(S,2));S],'CB')));
end
