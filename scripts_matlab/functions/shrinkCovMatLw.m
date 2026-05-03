function [covShrink, shrinkageIntensity] = shrinkCovMatLw(sampleCov, targetType, shrinkageIntensity)
%SHRINKCOVMATLW Shrink a covariance matrix toward a target via Ledoit-Wolf shrinkage procedure.

narginchk(2, 3);

[nRows, nCols] = size(sampleCov);
if nRows ~= nCols
  error('sampleCov must be a square matrix.');
end

if ~(isnumeric(sampleCov) && ismatrix(sampleCov))
  error('sampleCov must be a numeric matrix.');
end

targetCov = getTargetCovariance(sampleCov, targetType);

if nargin < 3 || isempty(shrinkageIntensity)
  diagCov = diag(diag(sampleCov));
  varSample = mean((sampleCov(:) - targetCov(:)).^2);
  biasTarget = mean((targetCov(:) - diagCov(:)).^2);

  shrinkageIntensity = varSample / (varSample + biasTarget);
  shrinkageIntensity = min(max(shrinkageIntensity, 0), 1);
end

covShrink = shrinkageIntensity * targetCov + (1 - shrinkageIntensity) * sampleCov;
end

function targetCov = getTargetCovariance(sampleCov, targetType)
nAssets = size(sampleCov, 1);
avgVar = mean(diag(sampleCov));

switch lower(targetType)
  case 'identity'
    targetCov = avgVar * eye(nAssets);

  case 'constant'
    offDiagMask = triu(true(nAssets), 1);
    avgCovOff = mean(sampleCov(offDiagMask));
    targetCov = avgCovOff * (ones(nAssets) - eye(nAssets)) + avgVar * eye(nAssets);

  otherwise
    error('targetType must be ''identity'' or ''constant''.');
end
end