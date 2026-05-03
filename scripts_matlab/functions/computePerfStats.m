function [mn, vol, sharpe, sortino, treynor] = computePerfStats(linReturnsVec, linReturnsVecEqual, varargin)
%COMPUTEPERFSTATS Compute annualized performance statistics.

[name, verbose] = parseInputs(varargin{:}); %#ok<ASGLU>

freq = 52;

linReturnsVec = linReturnsVec(:);
linReturnsVecEqual = linReturnsVecEqual(:);

mn = prod(1 + linReturnsVec, 'omitnan')^(freq / numel(linReturnsVec)) - 1;
vol = std(linReturnsVec, 'omitnan') * sqrt(freq);
sharpe = mn / vol;

downsideReturns = linReturnsVec;
downsideReturns(downsideReturns >= 0) = NaN;

downsideVol = std(downsideReturns, 'omitnan') * sqrt(freq);
sortino = mn / downsideVol;

if ~isempty(linReturnsVecEqual)
  treynor = computeTreynorRatio(linReturnsVec, linReturnsVecEqual, freq);
else
  treynor = NaN;
end
end


function [name, verbose] = parseInputs(varargin)
if nargin >= 1 && ~isempty(varargin{1})
  name = varargin{1};
else
  name = 'Given scheme';
end

if nargin >= 2 && ~isempty(varargin{2})
  verbose = varargin{2};
else
  verbose = true;
end
end


function treynor = computeTreynorRatio(rp, rm, freq)
if nargin < 3 || isempty(freq)
  freq = 52;
end

rp = rp(:);
rm = rm(:);

validIdx = ~isnan(rp) & ~isnan(rm);
rp = rp(validIdx);
rm = rm(validIdx);

if isempty(rp)
  treynor = NaN;
  return
end

xCentered = rm - mean(rm, 'omitnan');
yCentered = rp - mean(rp, 'omitnan');
denom = sum(xCentered .^ 2);

if denom == 0
  treynor = NaN;
  return
end

beta = sum(xCentered .* yCentered) / denom;
exRetAnnual = mean(rp, 'omitnan') * freq;

if abs(beta) < 1e-8
  treynor = NaN;
else
  treynor = exRetAnnual / beta;
end
end