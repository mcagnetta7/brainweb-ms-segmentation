function counts = computeVoxelConfusion(predMask, gtMask)
%COMPUTEVOXELCONFUSION Conteggi di confusione voxel per voxel tra due maschere binarie.
%
%   counts = COMPUTEVOXELCONFUSION(predMask, gtMask) confronta una
%   predizione binaria con il ground truth binario su tutti gli elementi
%   dell'array e restituisce una struttura con:
%
%     TP  predizione 1, GT 1
%     FP  predizione 1, GT 0
%     FN  predizione 0, GT 1
%     TN  predizione 0, GT 0
%     totalVoxels      numel(predMask)
%     confusionMatrix  [TN FP; FN TP]
%                      righe = GT [0, 1], colonne = predizione [0, 1]
%
%   Le maschere devono essere logiche, non vuote e della stessa
%   dimensione. Nessuna conversione, soglia o rimodellamento: un input
%   non valido genera un errore. Nessuna metrica derivata.

    arguments
        predMask {mustBeA(predMask, 'logical')}
        gtMask {mustBeA(gtMask, 'logical')}
    end

    if isempty(predMask) || isempty(gtMask)
        error('computeVoxelConfusion:emptyInput', 'Prediction and GT masks must be non-empty.');
    end
    if ~isequal(size(predMask), size(gtMask))
        error('computeVoxelConfusion:sizeMismatch', ...
            'Prediction and GT masks must have the same size (%s vs %s).', ...
            mat2str(size(predMask)), mat2str(size(gtMask)));
    end

    counts = struct();
    counts.TP = nnz(predMask & gtMask);
    counts.FP = nnz(predMask & ~gtMask);
    counts.FN = nnz(~predMask & gtMask);
    counts.TN = nnz(~predMask & ~gtMask);
    counts.totalVoxels = numel(predMask);
    counts.confusionMatrix = [counts.TN counts.FP; counts.FN counts.TP];
end
