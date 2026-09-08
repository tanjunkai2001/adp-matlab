function result = learnQL(X, U, Q, R, K0, maxIterations, tolerance)
%LEARNQL Lopez--Alsalti--Mueller, TAC 2023, matrix equation (29).
% X: n-by-(N+1), U: m-by-N. One fixed batch; u=-K*x.
% No plant matrices enter this function. Control System Toolbox: dlyap.
if nargin < 6, maxIterations = 30; end
if nargin < 7, tolerance = 1e-10; end
[n, nx] = size(X); [m, N] = size(U); eta = n+m;
assert(nx==N+1 && isequal(size(K0),[m n]), 'ql:Dimensions','Incorrect data dimensions.');
assert(all(isfinite([X(:);U(:);Q(:);R(:);K0(:)])), 'ql:Finite','Data must be finite.');
assert(isequal(size(Q),[n n]) && isequal(size(R),[m m]), 'ql:Cost','Incorrect cost dimensions.');
assert(norm(Q-Q','fro')<1e-12*norm(Q,'fro') && all(eig(Q)>0) && ...
    norm(R-R','fro')<1e-12*norm(R,'fro') && all(eig(R)>0),'ql:Cost','Q and R must be symmetric positive definite.');
H = zeros(m*(n+1),N-n);
for j=0:n, H(j*m+(1:m),:) = U(:,j+(1:N-n)); end
assert(rank(H)==m*(n+1),'ql:Excitation','Input Hankel matrix lacks PE of order n+1.');
allZ = [X(:,1:N);U];
assert(rank(allZ)==eta,'ql:Rank','State/input data lack full row rank.');
[~,~,pivot] = qr(allZ,'vector'); selected = pivot(1:eta);
Z = allZ(:,selected); Xnext = X(:,selected+1); Qbar = blkdiag(Q,R);
K = K0; history = struct([]); converged = false;
for i=1:maxIterations
    Y = [Xnext;-K*Xnext];
    % Generalized Lyapunov solve retains the cross-equations in Eq. (29).
    % Using only the eta scalar diagonal equations (16) is underdetermined.
    rho = max(abs(eig(Y,Z)));
    assert(rho<1,'ql:UnstableTarget','Target policy is unstable for the data transition.');
    Theta = dlyap(Y',Z'*Qbar*Z,[],Z'); Theta = (Theta+Theta')/2;
    uu = Theta(n+1:end,n+1:end);
    assert(all(eig(uu)>0),'ql:Greedy','Q-function input block is not positive definite.');
    Knext = uu\Theta(n+1:end,1:n);
    defect = Z'*Theta*Z-Z'*Qbar*Z-Y'*Theta*Y;
    history(i).K = K; history(i).Theta = Theta;
    history(i).Knext = Knext;
    history(i).dataSpectralRadius = rho;
    history(i).relativeResidual = norm(defect,'fro')/norm(Z'*Qbar*Z,'fro');
    history(i).policyChange = norm(Knext-K,'fro');
    if norm(Knext-K,'fro')<=tolerance
        converged = true; K = Knext; break
    end
    K = Knext;
end
% Re-evaluate the returned K so K, Theta and P always describe one policy.
Y = [Xnext;-K*Xnext];
Theta = dlyap(Y',Z'*Qbar*Z,[],Z'); Theta = (Theta+Theta')/2;
Pi = [eye(n);-K];
result = struct('K',K,'Theta',Theta,'P',Pi'*Theta*Pi, ...
    'K0',K0,'history',history,'iterations',numel(history), ...
    'converged',converged,'selectedIndices',selected, ...
    'rankHankel',rank(H),'rankStateInput',rank(allZ), ...
    'conditionZ',cond(Z),'singularValuesZ',svd(Z), ...
    'batchReuse','fixed_batch','equation','TAC2023 Eq.29 generalized Lyapunov');
end
