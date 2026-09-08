function solution=koopman_policy_iteration(model,features,x,config)
%KOOPMAN_POLICY_ITERATION GHJB least squares and analytic greedy improvement.
% The data-learning invocation receives ONLY the identified model. A separate
% model.kind='oracle_pendulum' invocation is the named truth comparator.
if strcmp(model.kind,'oracle_pendulum')
    f=[x(:,2),sin(x(:,1))-model.damping*x(:,2)]; g=repmat([0,1],size(x,1),1);
else
    [f,g]=koopman_model(model,x);
end
[~,D1,D2]=koopman_features(features,x);
policy=struct('kind','linear','K',config.K0);
history=cell(config.iterations,1);
for iteration=1:config.iterations
    u=koopman_policy(policy,x); F=f+g.*u;
    A=D1.*F(:,1)+D2.*F(:,2);
    y=-(sum((x*config.Q).*x,2)+config.R*u.^2);
    [U,S,V]=svd(A,'econ'); singular=diag(S);
    keep=singular>config.svdTolerance*singular(1);
    if sum(keep)<3, error('koopman:CriticRank','Insufficient GHJB rank.'); end
    beta=V(:,keep)*((U(:,keep)'*y)./singular(keep));
    next=struct('kind','greedy','features',features,'beta',beta,'model',model,'R',config.R);
    nextU=koopman_policy(next,x);
    history{iteration}=struct('evaluatedPolicy',policy,'beta',beta, ...
        'singularValues',singular,'rank',sum(keep),'residualRms',sqrt(mean((A*beta-y).^2)), ...
        'relativeResidual',norm(A*beta-y)/norm(y), ...
        'policyChangeRms',sqrt(mean((nextU-u).^2)));
    policy=next;
end
solution.policy=policy; solution.history=history; solution.features=features;
solution.valueBeta=beta; solution.valueEvaluatedPolicy=history{end}.evaluatedPolicy;
solution.valuePolicyPair='beta evaluates the prior policy; final greedy policy is logged separately';
solution.method='GHJB random-feature linear least squares, truncated SVD, analytic greedy';
solution.modelKnowledge=model.kind;
end
