function result = computeLesionWiseMatches(predMask, gtMask, connectivity)
%COMPUTELESIONWISEMATCHES Corrispondenze tra componenti 3D del GT e della predizione.
%
%   result = COMPUTELESIONWISEMATCHES(predMask, gtMask, connectivity) calcola
%   le componenti connesse 3D (bwconncomp) di GT e predizione con la stessa
%   connettività e trova tutte le coppie (GT, predetta) che condividono
%   almeno un voxel. Regola fissa: corrispondenza se e solo se
%   l'intersezione ha > 0 voxel. Nessuna soglia di sovrapposizione, distanza
%   o dimensione; nessuna assegnazione uno-a-uno (relazioni molti-a-molti).
%
%   result contiene: connectivity, gtComponentCount, predictedComponentCount,
%   detectedGtLesionCount, missedGtLesionCount, matchedPredictedComponentCount,
%   falsePredictedComponentCount, gtComponentTable, predictedComponentTable,
%   matchTable (una riga per relazione con overlapVoxels > 0),
%   gtComponents e predictedComponents (PixelIdxList, per i controlli).
%
%   Nessun accesso a file, nessuna modifica delle maschere, nessun filtro
%   delle componenti, nessuna metrica derivata.

    arguments
        predMask {mustBeA(predMask, 'logical')}
        gtMask {mustBeA(gtMask, 'logical')}
        connectivity (1, 1) {mustBeMember(connectivity, [6 18 26])}
    end

    if isempty(predMask) || ndims(predMask) ~= 3 || ~isequal(size(predMask), size(gtMask))
        error('computeLesionWiseMatches:invalidInput', ...
            'Prediction and GT must be non-empty 3D logical arrays of the same size.');
    end

    ccGt = bwconncomp(gtMask, connectivity);
    ccPred = bwconncomp(predMask, connectivity);
    gtLabel = labelFromComponents(ccGt);
    predLabel = labelFromComponents(ccPred);

    % Coppie (GT, predetta) sui voxel condivisi: ogni voxel TP appartiene a una
    % sola componente GT e a una sola componente predetta.
    shared = find(gtLabel > 0 & predLabel > 0);
    pairs = [double(gtLabel(shared)), double(predLabel(shared))];
    if isempty(pairs)
        uniquePairs = zeros(0, 2);
        overlap = zeros(0, 1);
    else
        [uniquePairs, ~, j] = unique(pairs, 'rows');
        overlap = accumarray(j, 1);
    end
    matchTable = table(uniquePairs(:, 1), uniquePairs(:, 2), overlap, ...
        'VariableNames', {'gtLesionId', 'predictedComponentId', 'overlapVoxels'});

    nGt = ccGt.NumObjects;
    nPred = ccPred.NumObjects;
    gtMatchCount = accumarray(uniquePairs(:, 1), 1, [nGt 1]);
    gtOverlap = accumarray(uniquePairs(:, 1), overlap, [nGt 1]);
    predMatchCount = accumarray(uniquePairs(:, 2), 1, [nPred 1]);
    predOverlap = accumarray(uniquePairs(:, 2), overlap, [nPred 1]);

    gtComponentTable = table((1:nGt).', gtMatchCount > 0, gtMatchCount == 0, gtMatchCount, gtOverlap, ...
        'VariableNames', {'gtLesionId', 'isDetected', 'isMissed', 'matchedPredictionCount', 'totalOverlapVoxels'});
    predictedComponentTable = table((1:nPred).', predMatchCount > 0, predMatchCount == 0, predMatchCount, predOverlap, ...
        'VariableNames', {'predictedComponentId', 'isMatched', 'isFalseLesion', 'matchedGtCount', 'totalOverlapVoxels'});

    result = struct();
    result.connectivity = connectivity;
    result.gtComponentCount = nGt;
    result.predictedComponentCount = nPred;
    result.detectedGtLesionCount = nnz(gtComponentTable.isDetected);
    result.missedGtLesionCount = nnz(gtComponentTable.isMissed);
    result.matchedPredictedComponentCount = nnz(predictedComponentTable.isMatched);
    result.falsePredictedComponentCount = nnz(predictedComponentTable.isFalseLesion);
    result.gtComponentTable = gtComponentTable;
    result.predictedComponentTable = predictedComponentTable;
    result.matchTable = matchTable;
    result.gtComponents = ccGt.PixelIdxList;
    result.predictedComponents = ccPred.PixelIdxList;
end

function labels = labelFromComponents(cc)
%LABELFROMCOMPONENTS Volume di etichette (0 = sfondo) dalle PixelIdxList.
    labels = zeros(cc.ImageSize, 'uint32');
    for i = 1:cc.NumObjects
        labels(cc.PixelIdxList{i}) = i;
    end
end
