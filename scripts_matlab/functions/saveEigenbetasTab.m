function saveEigenbetasTab(tabOlsRegEigenbetas, filePath)
%SAVEEIGENBETASTAB Write eigenbeta regression results as a LaTeX table.

narginchk(2, 2);

tabOlsRegEigenbetas = prepareInputTable(tabOlsRegEigenbetas);
[wideTab, marketOrder, eigOrder] = buildWideTable(tabOlsRegEigenbetas);
writeLatexTable(wideTab, marketOrder, eigOrder, filePath);

fprintf('LaTeX table saved to %s\n', filePath);
end


function tab = prepareInputTable(tab)
tab.Index = string(tab.Index);
tab.Eigenvalue = string(tab.Eigenvalue);

marketOrder = unique(tab.Index, 'stable');
refMarket = marketOrder(1);

eigOrder = tab.Eigenvalue(tab.Index == refMarket);
eigOrder = unique(eigOrder, 'stable');

tab.Index = categorical(tab.Index, marketOrder, 'Ordinal', true);
tab.Eigenvalue = categorical(tab.Eigenvalue, eigOrder, 'Ordinal', true);

tab = sortrows(tab, {'Index', 'Eigenvalue'});

tab.Index = string(tab.Index);
tab.Eigenvalue = string(tab.Eigenvalue);
end


function [wideTab, marketOrder, eigOrder] = buildWideTable(tab)
marketOrder = unique(tab.Index, 'stable');

refMarket = marketOrder(1);
eigOrder = tab.Eigenvalue(tab.Index == refMarket);
eigOrder = unique(eigOrder, 'stable');

wideTab = table();

for iMarket = 1:numel(marketOrder)
  market = marketOrder(iMarket);

  marketTab = tab(tab.Index == market, {'Eigenvalue', 'Beta', 'Rsquare', 'PValue'});
  marketTab.Properties.VariableNames = { ...
    'Eigenvalue', ...
    char(matlab.lang.makeValidName(market + "_Beta")), ...
    char(matlab.lang.makeValidName(market + "_Rsquare")), ...
    char(matlab.lang.makeValidName(market + "_PValue"))};

  if iMarket == 1
    wideTab = marketTab;
  else
    wideTab = outerjoin(wideTab, marketTab, 'Keys', 'Eigenvalue', 'MergeKeys', true);
  end
end

wideTab.Eigenvalue = categorical(string(wideTab.Eigenvalue), eigOrder, 'Ordinal', true);
wideTab = sortrows(wideTab, 'Eigenvalue');
wideTab.Eigenvalue = string(wideTab.Eigenvalue);
end


function writeLatexTable(wideTab, marketOrder, eigOrder, filePath)
fid = fopen(filePath, 'w');
if fid == -1
  error('Could not open file %s for writing.', filePath);
end

cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

alignStr = ['l', repmat(' rrr', 1, numel(marketOrder))];

fprintf(fid, '\\begin{table}[t!]\n');
fprintf(fid, '\\centering\n');
fprintf(fid, '\\renewcommand{\\arraystretch}{1.15}\n');
fprintf(fid, '\\setlength{\\tabcolsep}{6pt}\n');
fprintf(fid, '\\caption{OLS regressions of market returns on the returns of the leading correlation-based eigenportfolios.}\n');
fprintf(fid, '\\label{tab:nordic_eigenbeta}\n');
fprintf(fid, '\\small\n');
fprintf(fid, '\\begin{tabular}{%s}\n', alignStr);
fprintf(fid, '\\hline\n');

fprintf(fid, '& ');
for iMarket = 1:numel(marketOrder)
  marketName = strrep(char(marketOrder(iMarket)), '_', '\_');
  if iMarket < numel(marketOrder)
    fprintf(fid, '\\multicolumn{3}{c}{\\textbf{%s}} & ', marketName);
  else
    fprintf(fid, '\\multicolumn{3}{c}{\\textbf{%s}} \\\\\n', marketName);
  end
end

fprintf(fid, '\\textbf{} ');
for iMarket = 1:numel(marketOrder)
  if iMarket < numel(marketOrder)
    fprintf(fid, '& {$\\beta$} & {$R^2$} & {p-val} ');
  else
    fprintf(fid, '& {$\\beta$} & {$R^2$} & {p-val} \\\\\n');
  end
end
fprintf(fid, '\\hline\n');

for iRow = 1:numel(eigOrder)
  eigName = string(wideTab.Eigenvalue(iRow));
  eigLabel = eigenToLatex(eigName);

  fprintf(fid, '%s ', eigLabel);

  for iMarket = 1:numel(marketOrder)
    market = char(marketOrder(iMarket));

    betaVar = matlab.lang.makeValidName([market '_Beta']);
    rsqVar = matlab.lang.makeValidName([market '_Rsquare']);
    pVar = matlab.lang.makeValidName([market '_PValue']);

    if ~all(ismember({betaVar, rsqVar, pVar}, wideTab.Properties.VariableNames))
      betaStr = '';
      rsqStr = '';
      pStr = '';
    else
      betaVal = wideTab.(betaVar)(iRow);
      rsqVal = wideTab.(rsqVar)(iRow);
      pVal = wideTab.(pVar)(iRow);

      betaStr = formatNum(betaVal, 3);
      if iRow == 1 && ~isempty(betaStr)
        betaStr = ['\textbf{' betaStr '}'];
      end

      rsqStr = formatNum(rsqVal, 3);
      pStr = formatPval(pVal);
    end

    if iMarket < numel(marketOrder)
      fprintf(fid, '& %s & %s & %s ', betaStr, rsqStr, pStr);
    else
      fprintf(fid, '& %s & %s & %s \\\\\n', betaStr, rsqStr, pStr);
    end
  end
end

fprintf(fid, '\\hline\n');
fprintf(fid, '\\end{tabular}\n');
fprintf(fid, '\n');
fprintf(fid, 'Note: Betas of the principal eigenportfolio are highlighted in bold font.\n');
fprintf(fid, '\\end{table}\n');
end


function str = eigenToLatex(eigName)
tok = regexp(char(eigName), '^lambda_(\d+)$', 'tokens', 'once');

if ~isempty(tok)
  str = sprintf('$\\lambda_%s$', tok{1});
else
  str = strrep(char(eigName), '_', '\_');
end
end


function str = formatNum(x, nDecimals)
if isempty(x) || any(isnan(x))
  str = '';
else
  str = sprintf(['%.' num2str(nDecimals) 'f'], x);
end
end


function str = formatPval(p)
if isempty(p) || any(isnan(p))
  str = '';
elseif p < 0.001
  str = '$<0.001$';
else
  str = sprintf('%.3f', p);
end
end