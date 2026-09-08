function ref = mf_reference(plant,cost,K0,upstream)
%MF_REFERENCE Model-based generalized Riccati benchmark, equations (12)-(18).
% This oracle is independent of the empirical learner and is never its input.
A=plant.A; B=plant.B; C=plant.C; D=plant.D;
Q=cost.Q; R=cost.R; G=cost.Gamma;
K=K0;
assert(mssAbscissa(A-B*K,C-D*K)<0,'mf:UnstableInitial', ...
    'K0 must stabilize the continuous Ito second-moment dynamics.');
for it=1:100
    P=solveLyapunov(A-B*K,C-D*K,Q+K.'*R*K);
    U=R+D.'*P*D;
    next=U\(B.'*P+D.'*P*C);
    change=norm(next-K); K=next;
    if change<1e-12, break; end
end
assert(change<1e-12,'mf:NoConvergence','Model-based stochastic PI failed.');
QGamma=G.'*Q+Q*G-G.'*Q*G;
[S,Ks]=secondStage(A,B,K,U,QGamma);
rp=A.'*P+P*A+C.'*P*C-(B.'*P+D.'*P*C).'*(U\(B.'*P+D.'*P*C))+Q;
rs=(A-B*K).'*S+S*(A-B*K)-S*B*(U\(B.'*S))-QGamma;
ref=struct('P',P,'K',K,'S',S,'Ks',Ks,'Lambda',D.'*P*D, ...
    'Upsilon',U,'stochasticAREresidual',norm(rp,'fro'), ...
    'meanAREresidual',norm(rs,'fro'), ...
    'meanSquareAbscissa',mssAbscissa(A-B*K,C-D*K), ...
    'meanAbscissa',max(real(eig(A-B*(K+Ks)))));
if nargin==4
    [Sc,Ksc]=secondStage(A,B,upstream.K,upstream.Upsilon,QGamma);
    ref.conditionalSecond=struct('S',Sc,'Ks',Ksc,'upstreamK',upstream.K, ...
        'upstreamUpsilon',upstream.Upsilon, ...
        'scope','Second ARE reference conditional on the supplied first-stage estimates.');
end
end

function [S,Ks]=secondStage(A,B,K,U,QGamma)
Ks=zeros(1,2);
assert(max(real(eig(A-B*K)))<0,'mf:UnstableInitial', ...
    'The second-stage reference requires a Hurwitz initial mean drift.');
for it=1:100
    S=solveLyapunov(A-B*(K+Ks),zeros(2),-QGamma+Ks.'*U*Ks);
    next=U\(B.'*S);
    change=norm(next-Ks); Ks=next;
    if change<1e-12, break; end
end
assert(change<1e-12,'mf:NoConvergence','Model-based mean PI failed.');
end

function P=solveLyapunov(F,G,Q)
% Three symmetric coordinates, four scalar equations: no Control Toolbox.
basis=cat(3,[1 0;0 0],[0 1;1 0],[0 0;0 1]);
L=zeros(4,3);
for j=1:3
    E=basis(:,:,j); v=F.'*E+E*F+G.'*E*G; L(:,j)=v(:);
end
p=L\(-Q(:));
P=[p(1),p(2);p(2),p(3)];
end
function a=mssAbscissa(F,G)
a=max(real(eig(kron(eye(2),F)+kron(F,eye(2))+kron(G,G))));
end
