function [value, diagnostics] = fitValue(batch, options)
%FITVALUE Fit Phi*W=y for a two-state, undiscounted integral value model.
% batch.Phi is N-by-3; batch.y is N-by-1. No normal equations or pinv.
% Rank loss and excessive conditioning stop the fit with explicit errors.
if nargin < 2, options = struct(); end
if ~isfield(options,'relativeRankTolerance')
    options.relativeRankTolerance = 1e-12;
end
if ~isfield(options,'conditionLimit'), options.conditionLimit = 1e8; end
validateattributes(options.relativeRankTolerance, {'double'}, ...
    {'scalar','real','finite','positive','<',1});
validateattributes(options.conditionLimit, {'double'}, ...
    {'scalar','real','finite','>=',1});
Phi = batch.Phi;
y = batch.y;
validateattributes(Phi, {'double'}, {'real','finite','2d','ncols',3});
validateattributes(y, {'double'}, {'real','finite','column','numel',size(Phi,1)});
if isempty(Phi)
    error('adp:learn:RankDeficient', ...
        'Integral regression has no samples: rank=0/3, singularValues=[], condition=Inf.');
end
[U,S,V] = svd(Phi,'econ');
singularValues = diag(S);
threshold = options.relativeRankTolerance*max(singularValues);
effectiveRank = sum(singularValues > threshold);
if effectiveRank < 3
    error('adp:learn:RankDeficient', ...
        'Integral regression rejected: rank=%d/3, singularValues=%s, threshold=%.3g, condition=Inf.', ...
        effectiveRank, mat2str(singularValues',8), threshold);
end
conditionNumber = singularValues(1)/singularValues(3);
if conditionNumber > options.conditionLimit
    error('adp:learn:IllConditioned', ...
        'Integral regression rejected: condition=%.8g exceeds %.8g; singularValues=%s.', ...
        conditionNumber, options.conditionLimit, mat2str(singularValues',8));
end
weights = V*((U'*y)./singularValues);
residual = Phi*weights-y;
value.weights = weights;
value.P = [weights(1),weights(2);weights(2),weights(3)];
value.basis = 'quadratic2: [x1^2; 2*x1*x2; x2^2]';
diagnostics.accepted = true;
diagnostics.singularValues = singularValues;
diagnostics.rank = effectiveRank;
diagnostics.rankThreshold = threshold;
diagnostics.relativeRankTolerance = options.relativeRankTolerance;
diagnostics.conditionNumber = conditionNumber;
diagnostics.conditionLimit = options.conditionLimit;
diagnostics.residual = residual;
diagnostics.residualNorm = norm(residual,2);
diagnostics.targetNorm = norm(y,2);
if diagnostics.targetNorm > 0
    diagnostics.relativeResidual = diagnostics.residualNorm/diagnostics.targetNorm;
elseif diagnostics.residualNorm == 0
    diagnostics.relativeResidual = 0;
else
    diagnostics.relativeResidual = Inf;
end
diagnostics.sampleCount = size(Phi,1);
diagnostics.parameterCount = 3;
diagnostics.solver = 'economy SVD; no normal equations';
end
