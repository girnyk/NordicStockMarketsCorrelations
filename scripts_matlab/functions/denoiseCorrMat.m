function corrMatDenoised = denoiseCorrMat(corrMatSample, lambdaMax)
%DENOISECORRMAT Replace bulk eigenvalues and renormalize to a correlation matrix.

[eigenVals, eigenVecs] = eigendecompose(corrMatSample);

bulkIdx = eigenVals < lambdaMax;
bulkMean = mean(eigenVals(bulkIdx));

eigenValsDenoised = eigenVals;
eigenValsDenoised(bulkIdx) = bulkMean;

corrMatDenoised = eigenVecs * diag(eigenValsDenoised) * eigenVecs.';

diagMat = diag(diag(corrMatDenoised));
corrMatDenoised = diagMat^(-1 / 2) * corrMatDenoised * diagMat^(-1 / 2);
end