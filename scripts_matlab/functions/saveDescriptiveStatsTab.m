function saveDescriptiveStatsTab(tabDescrStats, filePath)
%SAVEDESCRIPTIVESTATSTAB Write descriptive statistics as a LaTeX table.

narginchk(2, 2);

fid = fopen(filePath, 'w');
if fid == -1
  error('Could not open file %s for writing.', filePath);
end

cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, '\\begin{table}[t!]\n');
fprintf(fid, '\\centering\n');
fprintf(fid, '\\caption{Descriptive statistics of daily log-returns for the Nordic equity markets considered in the analysis.}\n');
fprintf(fid, '\\label{tab:summary_data}\n');
fprintf(fid, '\\small\n');
fprintf(fid, '\\begin{tabular}{ccccccccc}\n');
fprintf(fid, '\\hline\n');
fprintf(fid, '\\textbf{Index} & $\\boldsymbol{N}$ & \\textbf{Days} & \\textbf{Mean} & \\textbf{Std. dev.} & \\textbf{Skewness} & \\textbf{Kurtosis} & \\textbf{Min} & \\textbf{Max} \\\\\n');
fprintf(fid, '\\hline\n');

for iRow = 1:height(tabDescrStats)
  fprintf(fid, '%s & %d & %s & %.4f & %.4f & %.4f & %.3f & %.4f & %.4f \\\\\n', ...
    escapeLatex(getIndexLabel(tabDescrStats.Index, iRow)), ...
    tabDescrStats.Stocks(iRow), ...
    formatInteger(tabDescrStats.Days(iRow)), ...
    tabDescrStats.Mean(iRow), ...
    tabDescrStats.StdDev(iRow), ...
    tabDescrStats.Skewness(iRow), ...
    tabDescrStats.Kurtosis(iRow), ...
    tabDescrStats.Min(iRow), ...
    tabDescrStats.Max(iRow));
end

fprintf(fid, '\\hline\n');
fprintf(fid, '\\end{tabular}\n');
fprintf(fid, '\\end{table}\n');

fprintf('LaTeX table saved to %s\n', filePath);
end


function str = getIndexLabel(indexCol, rowIdx)
if iscell(indexCol)
  str = char(indexCol{rowIdx});
else
  str = char(string(indexCol(rowIdx)));
end
end


function str = formatInteger(x)
str = regexprep(num2str(x), '\d(?=(\d{3})+$)', '$&,');
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