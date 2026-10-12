function [filteredMask, keepBySlice, removedBySlice] = filterComponentsByArea2D(ccBySlice, componentTable, imageSize, minAreaExclusive)
%FILTERCOMPONENTSBYAREA2D Rimozione di componenti 2D intere in base all'area (fase 69).
%
%   [filteredMask, keepBySlice, removedBySlice] = FILTERCOMPONENTSBYAREA2D(
%   ccBySlice, componentTable, imageSize, minAreaExclusive) ricostruisce la
%   maschera tenendo solo le componenti con areaPixels > minAreaExclusive.
%   Ogni componente è tenuta o rimossa per intero (PixelIdxList completo).
%
%   Le componenti e le aree NON vengono ricalcolate: si usano le strutture
%   bwconncomp della fase 67 e la colonna areaPixels della fase 68. La
%   tabella deve contenere esattamente una riga per componente (slice,
%   componentIndexInSlice) con areaPixels = numel(PixelIdxList).
%
%   La funzione non usa ground truth né intensità, non applica morfologia o
%   soglie e non modifica gli ingressi.
%
%   Input:
%     ccBySlice         cell array di strutture bwconncomp (una per slice)
%     componentTable    tabella con slice, componentIndexInSlice, areaPixels
%     imageSize         dimensione del volume, es. [181 217 181]
%     minAreaExclusive  scalare: si tengono le componenti con area > valore
%
%   Output:
%     filteredMask    maschera logica di dimensione imageSize
%     keepBySlice     cell array: vettore logico dei componenti tenuti
%     removedBySlice  cell array: vettore logico dei componenti rimossi

    if ~iscell(ccBySlice) || numel(ccBySlice) ~= imageSize(3)
        error('segmentation:invalidComponents', 'ccBySlice must contain one structure per slice.');
    end
    if ~(isnumeric(minAreaExclusive) && isscalar(minAreaExclusive) && isfinite(minAreaExclusive))
        error('segmentation:invalidThreshold', 'minAreaExclusive must be a finite scalar.');
    end
    expectedRows = sum(cellfun(@(c) c.NumObjects, ccBySlice));
    keys = [componentTable.slice, componentTable.componentIndexInSlice];
    if height(componentTable) ~= expectedRows || size(unique(keys, 'rows'), 1) ~= height(componentTable)
        error('segmentation:invalidPropertyTable', 'Property table must have exactly one row per component.');
    end

    filteredMask = false(imageSize);
    keepBySlice = cell(imageSize(3), 1);
    removedBySlice = cell(imageSize(3), 1);
    for k = 1:imageSize(3)
        cc = ccBySlice{k};
        rows = componentTable(componentTable.slice == k, :);
        if height(rows) ~= cc.NumObjects || ~isequal(sort(rows.componentIndexInSlice).', 1:cc.NumObjects)
            error('segmentation:invalidPropertyTable', 'Missing or duplicate property row in slice %d.', k);
        end
        area = zeros(cc.NumObjects, 1);
        area(rows.componentIndexInSlice) = rows.areaPixels;
        sliceMask = false(imageSize(1:2));
        keep = false(cc.NumObjects, 1);
        for i = 1:cc.NumObjects
            if area(i) ~= numel(cc.PixelIdxList{i})
                error('segmentation:inconsistentArea', 'Area mismatch for component %d of slice %d.', i, k);
            end
            if area(i) > minAreaExclusive
                keep(i) = true;
                sliceMask(cc.PixelIdxList{i}) = true;
            end
        end
        filteredMask(:, :, k) = sliceMask;
        keepBySlice{k} = keep;
        removedBySlice{k} = ~keep;
    end

end
