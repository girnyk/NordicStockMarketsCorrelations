function corrMat = computeCorrMat(logReturnsMat)
%COMPUTECORRMAT Compute a symmetric pairwise correlation matrix.

corrMat = corr(logReturnsMat, 'Rows', 'pairwise');
corrMat = 0.5 * (corrMat + corrMat.');
end