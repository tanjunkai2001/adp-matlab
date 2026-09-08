function tests=testQL
tests=functiontests(localfunctions);
end
function setupOnce(t)
rng(19);A=[1 .1;0 1.02];B=[.1;.2];U=2*rand(1,45)-1;X=zeros(2,46);X(:,1)=[1;-.5];
for k=1:45,X(:,k+1)=A*X(:,k)+B*U(:,k);end
t.TestData=struct('A',A,'B',B,'U',U,'X',X);
end
function testIndependentDARE(t)
d=t.TestData;[K0,~]=dataStabilizer(d.X,d.U);fit=learnQL(d.X,d.U,eye(2),1,K0);
[Ks,Ps]=dlqr(d.A,d.B,eye(2),1);
verifyLessThan(t,norm(fit.K-Ks),1e-8);verifyLessThan(t,norm(fit.P-Ps),1e-7);
verifyLessThan(t,max(abs(eig(d.A-d.B*K0))),1e-4);
end
function testReturnedPolicyValuePair(t)
d=t.TestData;K0=dataStabilizer(d.X,d.U);f=learnQL(d.X,d.U,eye(2),1,K0,1,0);
Acl=d.A-d.B*f.K;P=dlyap(Acl',eye(2)+f.K'*f.K);
verifyEqual(t,f.P,P,'AbsTol',1e-7);verifyFalse(t,f.converged);
end
function testRankDeficientInput(t)
d=t.TestData;verifyError(t,@()learnQL(d.X,zeros(size(d.U)),eye(2),1,[1 1]),'ql:Excitation');
end
function testUnstableInitialPolicy(t)
d=t.TestData;verifyError(t,@()learnQL(d.X,d.U,eye(2),1,[0 0]),'ql:UnstableTarget');
end
function testScalarEquationsAreInsufficient(t)
% At Z=I, an off-diagonal symmetric perturbation has zero diagonal.
Z=eye(3);Delta=[0 1 0;1 0 0;0 0 0];
verifyEqual(t,diag(Z'*Delta*Z),zeros(3,1));
verifyGreaterThan(t,norm(Z'*Delta*Z,'fro'),1);
end
function testBellmanOnUnselectedData(t)
d=t.TestData;K0=dataStabilizer(d.X,d.U);f=learnQL(d.X,d.U,eye(2),1,K0);
Z=[d.X(:,1:end-1);d.U];Y=[d.X(:,2:end);-f.K*d.X(:,2:end)];
res=sum(Z.*(f.Theta*Z))-sum(Z.^2)-sum(Y.*(f.Theta*Y));
verifyLessThan(t,norm(res)/norm(sum(Z.^2)),1e-9);
end

function testMIMODataStabilizerKeepsInputDimension(t)
rng(44);A=[1.1 .2 0;0 .8 .1;0 0 .9];B=[1 0;0 1;.3 .2];U=2*rand(2,20)-1;X=zeros(3,21);X(:,1)=[1;-.4;.2];
for k=1:20,X(:,k+1)=A*X(:,k)+B*U(:,k);end
[K0,info]=dataStabilizer(X,U);f=learnQL(X,U,eye(3),eye(2),K0);
Ks=dlqr(A,B,eye(3),eye(2));
verifyLessThanOrEqual(t,info.rankBbar,2);verifyLessThan(t,max(abs(eig(A-B*K0))),1);
verifyLessThan(t,norm(f.K-Ks),1e-7);
end
