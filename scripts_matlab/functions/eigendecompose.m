function [eigenVals, eigenVecs] = eigendecompose(C)
%EIGENDECOMPOSE Compute eigenvalues and eigenvectors in descending order.

[eigenVecs, D] = eig(C);
eigenVals = diag(D);

[eigenVals, sortIdx] = sort(eigenVals, 'descend');
eigenVecs = eigenVecs(:, sortIdx);
end