function [weights,diagnostics] = bp_solve(A,y,cfg)
%BP_SOLVE Column-scaled SVD least squares; reject unidentified parameters.
if nargin<3, cfg=struct(); end
if ~isfield(cfg,'relativeRankTolerance'), cfg.relativeRankTolerance=1e-11; end
if ~isfield(cfg,'conditionLimit'), cfg.conditionLimit=1e10; end
validateattributes(A,{'double'},{'2d','real','finite','nonempty'});
validateattributes(y,{'double'},{'column','real','finite','numel',size(A,1)});
validateattributes(cfg.relativeRankTolerance,{'double'},{'scalar','positive','<',1,'finite'});
validateattributes(cfg.conditionLimit,{'double'},{'scalar','>=',1,'finite'});
p=size(A,2);
columnScale=zeros(1,p);
for j=1:p, columnScale(j)=norm(A(:,j)); end
if size(A,1)<p || any(columnScale==0)
    error('biaspi:RankDeficient','Regression has too few rows or a zero column.');
end
scaled=A./columnScale;
[U,S,V]=svd(scaled,'econ'); s=diag(S);
rankThreshold=cfg.relativeRankTolerance*s(1);
effectiveRank=sum(s>rankThreshold);
if effectiveRank<p
    error('biaspi:RankDeficient','Regression rank %d/%d; scaled singular values %s.',effectiveRank,p,mat2str(s',6));
end
scaledCondition=s(1)/s(end);
if scaledCondition>cfg.conditionLimit
    error('biaspi:IllConditioned','Scaled condition %.8g exceeds %.8g.',scaledCondition,cfg.conditionLimit);
end
weights=(V*((U'*y)./s))./columnScale';
residual=A*weights-y; targetNorm=norm(y);
if targetNorm>0, relativeResidual=norm(residual)/targetNorm;
elseif norm(residual)==0, relativeResidual=0;
else, relativeResidual=Inf; end
diagnostics=struct('rank',effectiveRank,'parameterCount',p,'sampleCount',size(A,1), ...
    'columnScale',columnScale,'singularValues',s,'rankThreshold',rankThreshold, ...
    'scaledCondition',scaledCondition,'rawCondition',cond(A), ...
    'residualNorm',norm(residual),'relativeResidual',relativeResidual, ...
    'solver','column-scaled economy SVD; no normal equations');
end
