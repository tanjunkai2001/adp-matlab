function u=koopman_policy(policy,x)
%KOOPMAN_POLICY Frozen continuous feedback, no actor training during rollout.
if strcmp(policy.kind,'linear'), u=-x*policy.K'; return; end
[~,D1,D2]=koopman_features(policy.features,x);
if strcmp(policy.model.kind,'oracle_pendulum')
    g=repmat([0,1],size(x,1),1); % Only explicit oracle comparator carries this tag.
else
    [~,g]=koopman_model(policy.model,x);
end
u=-0.5*(g(:,1).*(D1*policy.beta)+g(:,2).*(D2*policy.beta))/policy.R;
end
