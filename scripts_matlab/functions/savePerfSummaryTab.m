function savePerfSummaryTab(summaryTab, filePath)
%SAVEPERFSUMMARYTAB Write portfolio performance summary table as a LaTeX table.

narginchk(2, 2);

portfolioOrder = ["Equal-weight", "1st eigenportfolio", ...
  "Min-variance", "Regime-aware"];

markets = unique(summaryTab.Market, 'stable');

fid = fopen(filePath, 'w');
if fid == -1
  error('Could not open output file: %s', filePath);
end

cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, '\\begin{table}\n');
fprintf(fid, '    \\centering\n');
fprintf(fid, '    \\caption{Summary performance and risk statistics for the portfolio strategies under consideration.}\n');
fprintf(fid, '    \\label{tab:summary_performance}\n');
fprintf(fid, '    \\footnotesize\n');
fprintf(fid, '    \\begin{tabular}{lrrrrr}\n');
fprintf(fid, '        \\hline\n');
fprintf(fid, '     \\textbf{Portfolio}  & \\textbf{Mean (ann.), \\%%} & \\textbf{Vol (ann.), \\%%} & \\textbf{Sharpe} & \\textbf{Sortino} & \\textbf{Treynor, \\%%}\\\\\n');
fprintf(fid, '        \\hline\n');

for iMarket = 1:numel(markets)
  market = markets(iMarket);
  marketTab = summaryTab(summaryTab.Market == market, :);
  marketTab = sortPortfolioRows(marketTab, portfolioOrder);

  bestMeanIdx = argmax(marketTab.MeanAnnPct);
  bestVolIdx = argmin(marketTab.VolAnnPct);
  bestSharpeIdx = argmax(marketTab.Sharpe);
  bestSortinoIdx = argmax(marketTab.Sortino);
  bestTreynorIdx = argmax(marketTab.TreynorPct);

  fprintf(fid, '    \\textbf{%s} & & & & & \\\\\n', escapeLatex(char(market)));

  for iRow = 1:height(marketTab)
    portfolioStr = escapeLatex(char(marketTab.Portfolio(iRow)));

    meanStr = formatNumber(100 * marketTab.MeanAnnPct(iRow), 3, iRow == bestMeanIdx);
    volStr = formatNumber(100 * marketTab.VolAnnPct(iRow), 3, iRow == bestVolIdx);
    sharpeStr = formatNumber(marketTab.Sharpe(iRow), 3, iRow == bestSharpeIdx);
    sortinoStr = formatNumber(marketTab.Sortino(iRow), 3, iRow == bestSortinoIdx);
    treynorStr = formatNumber(100 * marketTab.TreynorPct(iRow), 3, iRow == bestTreynorIdx);

    fprintf(fid, '%s & %s & %s & %s & %s & %s \\\\\n', ...
      portfolioStr, meanStr, volStr, sharpeStr, sortinoStr, treynorStr);
  end

  fprintf(fid, '        \\hline\n');
end

fprintf(fid, '    \\end{tabular}\n');
fprintf(fid, '\n');
fprintf(fid, '    Note: Best-performing schemes per metric are highlighted in bold font.\n');
fprintf(fid, '\\end{table}\n');

fprintf('LaTeX table saved to %s\n', filePath);
end


function tab = sortPortfolioRows(tab, portfolioOrder)
orderIdx = inf(height(tab), 1);

for i = 1:height(tab)
  idx = find(tab.Portfolio(i) == portfolioOrder, 1);
  if ~isempty(idx)
    orderIdx(i) = idx;
  end
end

tab.OrderIdx = orderIdx;
tab = sortrows(tab, {'OrderIdx', 'Portfolio'});
tab.OrderIdx = [];
end


function idx = argmax(x)
[~, idx] = max(x);
end


function idx = argmin(x)
[~, idx] = min(x);
end


function str = formatNumber(x, nDecimals, makeBold)
str = sprintf(['%0.', num2str(nDecimals), 'f'], x);
if makeBold
  str = ['\textbf{' str '}'];
end
end


function str = escapeLatex(str)
str = strrep(str, '\', '\textbackslash{}');
str = strrep(str, '_', '\_');
str = strrep(str, '%', '\%');
str = strrep(str, '&', '\&');
str = strrep(str, '#', '\#');
str = strrep(str, '$', '\$');
str = strrep(str, '{', '\{');
str = strrep(str, '}', '\}');
end