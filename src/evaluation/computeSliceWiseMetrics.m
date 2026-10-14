function sliceTable = computeSliceWiseMetrics(predMask, gtMask)
%COMPUTESLICEWISEMETRICS Conteggi e metriche formali per ogni slice assiale (diagnostica).
%
%   sliceTable = COMPUTESLICEWISEMETRICS(predMask, gtMask) restituisce una
%   tabella con una riga per ogni slice k = 1..size(predMask, 3) (asse
%   assiale, dimensione 3). Per ogni slice usa le funzioni formali già
%   validate: computeVoxelConfusion e computeDice/IoU/Precision/Recall/
%   SpecificityFromConfusion (nessuna nuova definizione).
%
%   Colonne: sliceIndex, totalSliceVoxels, gtPositiveVoxels,
%   predictedPositiveVoxels, tpVoxels, fpVoxels, fnVoxels, tnVoxels, dice,
%   iou, precision, recall, specificity, hasGtLesion, hasPrediction,
%   hasOverlap, diceIouInformative (TP+FP+FN > 0), precisionInformative
%   (TP+FP > 0), recallInformative (TP+FN > 0).
%
%   I valori delle metriche conservano le convenzioni di progetto per i
%   denominatori nulli (per es. 1 su slice vuote): i flag dicono quando una
%   metrica è informativa. Nessuna media tra slice, nessun accesso a file,
%   nessuna componente connessa, nessuna modifica delle maschere.

    arguments
        predMask {mustBeA(predMask, 'logical')}
        gtMask {mustBeA(gtMask, 'logical')}
    end

    if isempty(predMask) || ndims(predMask) ~= 3 || ~isequal(size(predMask), size(gtMask))
        error('computeSliceWiseMetrics:invalidInput', ...
            'Prediction and GT must be non-empty 3D logical arrays of the same size.');
    end

    nSlices = size(predMask, 3);
    rows = cell(nSlices, 19);
    for k = 1:nSlices
        c = computeVoxelConfusion(predMask(:, :, k), gtMask(:, :, k));
        rows(k, :) = {k, c.totalVoxels, c.TP + c.FN, c.TP + c.FP, c.TP, c.FP, c.FN, c.TN, ...
            computeDiceFromConfusion(c), computeIoUFromConfusion(c), computePrecisionFromConfusion(c), ...
            computeRecallFromConfusion(c), computeSpecificityFromConfusion(c), ...
            c.TP + c.FN > 0, c.TP + c.FP > 0, c.TP > 0, ...
            c.TP + c.FP + c.FN > 0, c.TP + c.FP > 0, c.TP + c.FN > 0};
    end
    sliceTable = cell2table(rows, 'VariableNames', {'sliceIndex', 'totalSliceVoxels', 'gtPositiveVoxels', ...
        'predictedPositiveVoxels', 'tpVoxels', 'fpVoxels', 'fnVoxels', 'tnVoxels', 'dice', 'iou', ...
        'precision', 'recall', 'specificity', 'hasGtLesion', 'hasPrediction', 'hasOverlap', ...
        'diceIouInformative', 'precisionInformative', 'recallInformative'});
end
