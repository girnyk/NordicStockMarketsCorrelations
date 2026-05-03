function rows = buildEigenbetaTable(rows, marketName, logR, K)
%BUILDEIGENBETATABLE Append market-on-eigenportfolio regression rows.

narginchk(4, 4);

validRows = all(isfinite(logR), 2);
R = logR(validRows, :);

[nObs, nAssets] = size(R);

marketWeights = ones(nAssets, 1) / nAssets;
marketReturns = R * marketWeights;

corrMat = computeCorrMat(R);
[eigenVals, eigenVecs] = eigendecompose(corrMat);

sigma = std(R, 0, 1).';
sigma(sigma == 0) = NaN;

nModes = min(K, nAssets);

for iMode = 1:nModes
  eigenVec = eigenVecs(:, iMode);
  portWeights = eigenVec ./ sigma;
  portWeights = portWeights / nansum(abs(portWeights));

  portReturns = R * portWeights;

  [beta, rsq, pValue] = regressMarketOnPortfolio(marketReturns, portReturns);

  rows(end + 1, :) = {marketName, sprintf('lambda_%d', iMode), beta, rsq, pValue}; %#ok<AGROW>
end
end


function [beta, rsq, pValue] = regressMarketOnPortfolio(y, x)
nObs = numel(y);

X = [ones(nObs, 1), x];
coeffs = X \ y;

fittedVals = X * coeffs;
resid = y - fittedVals;

beta = coeffs(2);

totalSS = sum((y - mean(y)).^2);
residSS = sum(resid.^2);
rsq = 1 - residSS / totalSS;

dof = nObs - 2;
sigma2 = residSS / dof;

[Q, R] = qr(X, 0);
XtXInv = R \ (R' \ eye(size(X, 2)));

seBeta = sqrt(sigma2 * XtXInv(2, 2));
tStat = beta / seBeta;
pValue = 2 * (1 - tcdf(abs(tStat), dof));
end