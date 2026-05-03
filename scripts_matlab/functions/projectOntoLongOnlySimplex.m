function y = projectOntoLongOnlySimplex(x)
%PROJECTONTOLONGONLYSIMPLEX Map a vector to long-only weights summing to one.

narginchk(1, 1);

lambda = 1e-6;

x = x(:);
nAssets = numel(x);

x = max(x, 0);
x = (1 - lambda) * x + lambda / nAssets;

y = x / sum(x);
end