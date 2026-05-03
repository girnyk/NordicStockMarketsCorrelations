function wOpt = optimizePortfolioMinVarConstrained(Sigma, gamma1, gamma2, isCrisis)
%OPTIMIZEPORTFOLIOMINVARCONSTRAINED Solve a long-only minimum-variance problem.

narginchk(4, 4);

nAssets = size(Sigma, 1);
if size(Sigma, 2) ~= nAssets
  error('Sigma must be a square matrix.');
end

stdDevs = sqrt(diag(Sigma));
corrMat = Sigma ./ (stdDevs * stdDevs.');

[eigVecs, eigVals] = eig(corrMat);
[~, sortIdx] = sort(diag(eigVals), 'descend');
eigVecs = eigVecs(:, sortIdx);

v1 = alignEigenvectorSign(eigVecs(:, 1));
v2 = alignEigenvectorSign(eigVecs(:, 2));

H = 2 * (Sigma + Sigma.') / 2;
f = zeros(nAssets, 1);

Aeq = ones(1, nAssets);
beq = 1;

lb = zeros(nAssets, 1);
ub = ones(nAssets, 1);

if isCrisis
  A = [v1.'; -v2.'];
  b = [gamma1; -gamma2];
else
  A = [];
  b = [];
end

options = optimoptions( ...
  'quadprog', ...
  'Display', 'off', ...
  'Diagnostics', 'off', ...
  'Algorithm', 'interior-point-convex');

[wOpt, ~, exitflag] = quadprog(H, f, A, b, Aeq, beq, lb, ub, [], options);

if exitflag <= 0
  warning('Optimization failed with exitflag = %d.', exitflag);
end
end


function v = alignEigenvectorSign(v)
[~, idx] = max(abs(v));
if v(idx) < 0
  v = -v;
end
end