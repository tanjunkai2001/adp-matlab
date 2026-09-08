function [result, runDir] = demo_qlearning_tac2023(outputRoot)
%DEMO_QLEARNING_TAC2023 Data-only Q-learning plus independent DARE checks.
% Example and noise benchmark use a fixed seed; all samples are saved.
if nargin<1, outputRoot=fullfile(fileparts(mfilename('fullpath')),'runs'); end
rng(73023,'twister');
A=[1 .1 0;0 1.05 .1;0 0 .98]; B=[.05;.1;.2]; Q=eye(3); R=1;
U=2*rand(1,80)-1; X=collect(A,B,U,[.2;-.1;.1]);
[K0,initialization]=dataStabilizer(X,U);
learning=learnQL(X,U,Q,R,K0);
[Kstar,Pstar]=dlqr(A,B,Q,R);
T=160; trajectory=zeros(3,T+1); trajectory(:,1)=[1;-.5;.3];
applied=zeros(1,T); costs=zeros(1,T);
for k=1:T
    applied(k)=-learning.K*trajectory(:,k);
    costs(k)=trajectory(:,k)'*Q*trajectory(:,k)+applied(k)'*R*applied(k);
    trajectory(:,k+1)=A*trajectory(:,k)+B*applied(k);
end
costTailIdentity=sum(costs)+trajectory(:,end)'*learning.P*trajectory(:,end) ...
    -trajectory(:,1)'*learning.P*trajectory(:,1);
metrics=struct('gainError',norm(learning.K-Kstar,'fro'), ...
    'valueError',norm(learning.P-Pstar,'fro'),'initialRadius',max(abs(eig(A-B*K0))), ...
    'finalRadius',max(abs(eig(A-B*learning.K))), ...
    'costWithTailError',abs(costTailIdentity),'conditionZ',learning.conditionZ, ...
    'bellmanResidual',max([learning.history.relativeResidual]));
assert(metrics.gainError<1e-7 && metrics.valueError<1e-6,'ql:Oracle','DARE mismatch.');
assert(metrics.initialRadius<1e-3 && metrics.finalRadius<1,'ql:Stability','Closed loop failed.');
assert(metrics.costWithTailError<1e-7,'ql:CostIdentity','Cost identity failed.');

% Section VIII.B style: random n=5,m=2 systems; 20 trials per noise level.
% Extra samples and explicit seed are our variant; original data/seed absent.
levels=[0 1e-3 1e-2 1e-1]; trials=20; records=cell(0,1); raw=cell(trials,1);
for trial=1:trials
    Ap=2*rand(5)-1; Bp=2*rand(5,2)-1; Up=2*rand(2,20)-1;
    Xp=collect(Ap,Bp,Up,20*rand(5,1)-10); W=2*rand(size(Xp))-1;
    [Ks,~]=dlqr(Ap,Bp,eye(5),eye(2));
    raw{trial}=struct('A',Ap,'B',Bp,'U',Up,'X',Xp,'unitNoise',W,'Kstar',Ks);
    for j=1:numel(levels)
        chi=Xp+levels(j)*W; h=numel(records)+1;
        rec=struct('trial',trial,'noiseBound',levels(j),'success',false, ...
            'gainErrorQL',NaN,'gainErrorID',NaN,'radiusQL',NaN, ...
            'radiusID',NaN,'conditionZ',NaN,'secondsQL',NaN,'message','');
        try
            [Kinit,~]=dataStabilizer(chi,Up);
            start=tic; fit=learnQL(chi,Up,eye(5),eye(2),Kinit,10,0);
            rec.secondsQL=toc(start); rec.gainErrorQL=norm(fit.K-Ks,'fro');
            rec.radiusQL=max(abs(eig(Ap-Bp*fit.K))); rec.conditionZ=fit.conditionZ;
            rec.success=true;
        catch err
            rec.message=err.identifier;
        end
        model=chi(:,2:end)/[chi(:,1:end-1);Up];
        try
            Kid=dlqr(model(:,1:5),model(:,6:7),eye(5),eye(2));
            rec.gainErrorID=norm(Kid-Ks,'fro'); rec.radiusID=max(abs(eig(Ap-Bp*Kid)));
        catch err
            rec.message=[rec.message,' ID:',err.identifier];
        end
        records{h}=rec; %#ok<AGROW>
    end
end
records=vertcat(records{:});
result=struct('config',struct('seed',73023,'A',A,'B',B,'Q',Q,'R',R, ...
    'samples',80,'trials',trials,'noiseLevels',levels,'time','discrete', ...
    'cost','xQx+uRu, infinite horizon, no discount'), ...
    'data',struct('X',X,'U',U),'initialization',initialization,'learning',learning, ...
    'oracle',struct('K',Kstar,'P',Pstar),'metrics',metrics, ...
    'evaluation',struct('x',trajectory','u_applied',applied','stageCost',costs'), ...
    'noiseRecords',records,'noiseRaw',{raw},'environment',version);
if ~isfolder(outputRoot),mkdir(outputRoot);end
runDir=tempname(outputRoot); mkdir(runDir);
save(fullfile(runDir,'result.mat'),'result','-v7');
writetable(struct2table(records),fullfile(runDir,'noise-benchmark.csv'));
fid=fopen(fullfile(runDir,'metrics.json'),'w'); fprintf(fid,'%s\n',jsonencode(metrics,PrettyPrint=true)); fclose(fid);
fig=figure('Visible','off'); tiledlayout(1,2);
nexttile; semilogy(1:learning.iterations,arrayfun(@(h)norm(h.Knext-Kstar,'fro'),learning.history),'o-');
xlabel('Policy iteration');ylabel('Gain error to DARE');grid on;
nexttile;plot(0:T,trajectory');xlabel('Sample');ylabel('State');grid on;
exportgraphics(fig,fullfile(runDir,'qlearning.png'),'Resolution',160); close(fig);
fprintf('TAC Q-learning: K error %.3g, P error %.3g, radius %.6f; saved %s\n', ...
    metrics.gainError,metrics.valueError,metrics.finalRadius,runDir);
end

function X=collect(A,B,U,x0)
X=zeros(size(A,1),size(U,2)+1);X(:,1)=x0;
for k=1:size(U,2),X(:,k+1)=A*X(:,k)+B*U(:,k);end
end
