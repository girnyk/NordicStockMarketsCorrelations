function summaryTab = buildPerfSummaryTab(perfResultsStruct)
%BUILDPERFSUMMARYTAB Build a performance summary table from a nested struct.

summaryTab = initSummaryTable();
marketFields = fieldnames(perfResultsStruct);

for iMarket = 1:numel(marketFields)
  marketField = marketFields{iMarket};
  marketStruct = perfResultsStruct.(marketField);

  if ~isstruct(marketStruct)
    continue
  end

  methodFields = fieldnames(marketStruct);

  for iMethod = 1:numel(methodFields)
    methodField = methodFields{iMethod};
    methodStruct = marketStruct.(methodField);

    if ~isValidMethodStruct(methodStruct)
      continue
    end

    summaryTab = [summaryTab; buildSummaryRow(marketField, methodField, methodStruct)]; %#ok<AGROW>
  end
end
end


function summaryTab = initSummaryTable()
summaryTab = table( ...
  strings(0, 1), ...
  strings(0, 1), ...
  zeros(0, 1), ...
  zeros(0, 1), ...
  zeros(0, 1), ...
  zeros(0, 1), ...
  zeros(0, 1), ...
  'VariableNames', {'Market', 'Portfolio', 'MeanAnnPct', 'VolAnnPct', ...
  'Sharpe', 'Sortino', 'TreynorPct'});
end


function tf = isValidMethodStruct(methodStruct)
tf = isstruct(methodStruct) && ...
  isfield(methodStruct, 'perfStatsTab') && ...
  istable(methodStruct.perfStatsTab) && ...
  ~isempty(methodStruct.perfStatsTab);
end


function row = buildSummaryRow(marketField, methodField, methodStruct)
perfTab = methodStruct.perfStatsTab;
rowTab = perfTab(1, :);

if isfield(methodStruct, 'name') && ~isempty(methodStruct.name)
  portfolioLabel = string(methodStruct.name);
else
  portfolioLabel = string(methodField);
end

row = table( ...
  string(marketField), ...
  portfolioLabel, ...
  getMetricValue(rowTab, {'MeanAnnPct', 'MeanAnn', 'Mean', 'AnnualMean', 'ReturnAnnPct', 'MeanReturnAnnPct'}), ...
  getMetricValue(rowTab, {'VolAnnPct', 'VolAnn', 'Vol', 'AnnualVol', 'VolatilityAnnPct'}), ...
  getMetricValue(rowTab, {'Sharpe', 'SharpeRatio'}), ...
  getMetricValue(rowTab, {'Sortino', 'SortinoRatio'}), ...
  getMetricValue(rowTab, {'TreynorPct', 'Treynor', 'TreynorRatio', 'TreynorAnnPct'}), ...
  'VariableNames', {'Market', 'Portfolio', 'MeanAnnPct', 'VolAnnPct', ...
  'Sharpe', 'Sortino', 'TreynorPct'});
end


function val = getMetricValue(rowTab, candidateNames)
val = NaN;
varNames = rowTab.Properties.VariableNames;

for iName = 1:numel(candidateNames)
  matchIdx = find(strcmpi(varNames, candidateNames{iName}), 1);
  if ~isempty(matchIdx)
    val = extractScalar(rowTab{1, matchIdx});
    return
  end
end

varNamesLower = lower(varNames);
for iName = 1:numel(candidateNames)
  matchIdx = find(contains(varNamesLower, lower(candidateNames{iName})), 1);
  if ~isempty(matchIdx)
    val = extractScalar(rowTab{1, matchIdx});
    return
  end
end
end


function x = extractScalar(value)
if isnumeric(value) && isscalar(value)
  x = double(value);
elseif islogical(value) && isscalar(value)
  x = double(value);
elseif iscell(value) && numel(value) == 1 && isnumeric(value{1}) && isscalar(value{1})
  x = double(value{1});
else
  x = NaN;
end
end