function learned = mf_learn(data, cost, K0, opt)
%MF_LEARN Algorithm 1, sequential equations (32) and (39)-(42).
% Inputs contain observations and known Q/R/Gamma/K0, never A/B/C/D.
% Uses column-scaled QR least squares, not normal-equation inversion.
Q = cost.Q; R = cost.R; Gamma = cost.Gamma;
assert(isequal(size(Q),[2 2]) && isscalar(R) && R>0 && ...
    isequal(size(Gamma),[2 2]) && isequal(size(K0),[1 2]), ...
    'mf:Dimensions','This implementation is the paper''s n=2,m=1 example.');
QGamma = Gamma.'*Q + Q*Gamma - Gamma.'*Q*Gamma;
dataRank1 = diagnose([data.intSecond,data.intXu,data.intUu],opt);
dataRank2 = diagnose([data.intMeanOuter,data.intMeanXu],opt);
K = K0;
hist1 = repmat(struct('K',[],'P',[],'Lambda',[],'delta',[], ...
    'relativeResidual',[],'condition',[]),0,1);
for iteration=1:opt.maxIterations
    cross = data.intXu + timesSymmetric(data.intSecond,K);
    kxxk = timesSymmetric(data.intSecond,K)*K.';
    psi = [data.deltaSecond,-2*cross,-data.intUu+kxxk];
    target = -data.intSecond*dual(Q+K.'*R*K);
    [theta,diag1] = solve(psi,target,opt);
    P = unpack(theta(1:3));
    Lambda = theta(6);
    Upsilon = R+Lambda;
    if min(eig(P))<=0 || Upsilon<=0
        error('mf:InadmissibleEstimate', ...
            'Finite-data PI produced nonpositive P or R+Lambda at iteration %d.',iteration);
    end
    next = theta(4:5).'/Upsilon;
    change = norm(next-K);
    hist1(end+1) = struct('K',next,'P',P,'Lambda',Lambda, ...
        'delta',change,'relativeResidual',diag1.relativeResidual, ...
        'condition',diag1.scaledCondition); %#ok<AGROW>
    K = next;
    if change <= opt.tolerance, break; end
end
if change>opt.tolerance
    error('mf:NoConvergence','First data PI did not meet its gain tolerance.');
end
Ks = zeros(1,2);
hist2 = repmat(struct('Ks',[],'S',[],'delta',[], ...
    'relativeResidual',[],'condition',[]),0,1);
for iteration=1:opt.maxIterations
    cross = data.intMeanXu + timesSymmetric(data.intMeanOuter,K+Ks);
    phi = [data.deltaMeanOuter,-2*Upsilon*cross];
    target = -data.intMeanOuter*dual(-QGamma+Ks.'*Upsilon*Ks);
    [theta,diag2] = solve(phi,target,opt);
    S = unpack(theta(1:3));
    next = theta(4:5).';
    change = norm(next-Ks);
    hist2(end+1) = struct('Ks',next,'S',S,'delta',change, ...
        'relativeResidual',diag2.relativeResidual, ...
        'condition',diag2.scaledCondition); %#ok<AGROW>
    Ks = next;
    if change<=opt.tolerance, break; end
end
if change>opt.tolerance
    error('mf:NoConvergence','Second data PI did not meet its gain tolerance.');
end
learned = struct('P',P,'K',K,'Lambda',Lambda,'Upsilon',Upsilon, ...
    'S',S,'Ks',Ks,'history1',hist1,'history2',hist2, ...
    'dataRank1',dataRank1,'dataRank2',dataRank2, ...
    'guarantee','Finite Monte Carlo fit; no exact-expectation theorem certificate.');
end

function d = dual(P)
d = [P(1,1);2*P(1,2);P(2,2)];
end
function P = unpack(p)
P = [p(1),p(2)/2;p(2)/2,p(3)];
end
function v = timesSymmetric(q,k)
v = [q(:,1)*k(1)+q(:,2)*k(2),q(:,2)*k(1)+q(:,3)*k(2)];
end
function d = diagnose(A,opt)
if any(~isfinite(A(:))) || isempty(A)
    error('mf:NonfiniteData','Regression data must be nonempty and finite.');
end
scale = vecnorm(A,2,1);
if any(scale==0), error('mf:RankDeficient','A required excitation column is zero.'); end
s = svd(A./scale,0);
r = sum(s>opt.rankRelativeTolerance*s(1));
if r<size(A,2), error('mf:RankDeficient','Observed excitation rank %d < %d.',r,size(A,2)); end
c = s(1)/s(end);
if c>opt.maxScaledCondition
    error('mf:IllConditioned','Column-scaled regression condition %.3g exceeds %.3g.',c,opt.maxScaledCondition);
end
d = struct('rank',r,'columns',size(A,2),'scaledCondition',c, ...
    'singularValues',s,'columnNorm',scale);
end
function [theta,d] = solve(A,y,opt)
d = diagnose(A,opt);
if any(~isfinite(y)), error('mf:NonfiniteData','Regression target must be finite.'); end
theta = (A./d.columnNorm)\y;
theta = theta./d.columnNorm.';
den = norm(y);
if den==0
    d.relativeResidual = norm(A*theta-y);
else
    d.relativeResidual = norm(A*theta-y)/den;
end
end
