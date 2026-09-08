function [K, info] = dataStabilizer(X, U)
%DATASTABILIZER Paper Algorithm 2; exact deadbeat specialization for SISO.
% MIMO uses distinct small poles on the same data-derived fictitious pair.
% This explicit MIMO variant avoids implementing a canonical-form library.
[n, nx] = size(X); [m,N] = size(U);
assert(nx==N+1,'ql:Dimensions','Need one successor state per input.');
X0=X(:,1:N); X1=X(:,2:N+1);
assert(rank([X0;U])==n+m,'ql:Rank','Data do not span state and input.');
F=pinv(X0); G=null(X0);
Abar=X1*F; Bbar=X1*G;
% In exact data rank(Bbar)<=m. Floating cancellation/noise must not
% create fictitious extra actuator columns. Keep at most the known m.
[~,~,piv]=qr(Bbar,'vector'); r=min(m,rank(Bbar)); ids=piv(1:r);
BF=Bbar(:,ids);
if r==1
    poles=zeros(1,n); HF=acker(Abar,BF,poles);
    variant='Algorithm2_SISO_deadbeat';
else
    poles=linspace(-0.2,0.2,n); HF=place(Abar,BF,poles);
    variant='Algorithm2_data_pair_distinct_poles_MIMO_variant';
end
Hbar=zeros(size(G,2),n); Hbar(ids,:)=HF;
K=-U*(F-G*Hbar);
info=struct('variant',variant,'desiredPoles',poles,'fictitiousA',Abar, ...
    'fictitiousB',BF,'dataClosedLoop',X1*(F-G*Hbar), ...
    'rankBbar',r,'rightInverseError',norm(X0*F-eye(n),'fro'));
end
