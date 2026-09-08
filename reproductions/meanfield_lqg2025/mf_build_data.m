function data = mf_build_data(raw, cfg)
%MF_BUILD_DATA Equations (29)/(38), empirical expectations then left sums.
% q = [x1^2,x1*x2,x2^2]; its dual is [P11,2*P12,P22].
% Stage 1 E[xx'] MUST NOT be replaced by Stage 2 E[x]E[x]'.
x1 = reshape(raw.x(1,:,:),size(raw.x,2),[]).';
x2 = reshape(raw.x(2,:,:),size(raw.x,2),[]).';
u = raw.u.';
assert(size(u,1)==size(x1,1) && size(u,2)==size(x1,2), ...
    'mf:Dimensions','Observed state and input paths must align.');
assert(all(isfinite([x1(:);x2(:);u(:)])), ...
    'mf:NonfiniteData','Observed trajectories must be finite.');
second = [mean(x1.^2,2),mean(x1.*x2,2),mean(x2.^2,2)];
xu = [mean(x1.*u,2),mean(x2.*u,2)];
uu = mean(u.^2,2);
mx = [mean(x1,2),mean(x2,2)];
mu = mean(u,2);
m = struct('t',raw.t,'second',second,'xu',xu,'uu',uu, ...
    'mean',mx,'meanInput',mu);
data = mf_window_moments(m,raw.dt,cfg);
data.pathCount = size(raw.x,2);
data.provenance = 'Empirical independent paths; no model moments or fitted oracle.';
end
