function [candidate, diagnostics] = markerWatershedUnionSlices( ...
    volume, foregroundMarker, nonBrainMarker, headSupport, gradientNeighborhood)
%MARKERWATERSHEDUNIONSLICES Watershed a marker con unione dei bacini del primo piano (2D).
%
%   [candidate, diagnostics] = MARKERWATERSHEDUNIONSLICES(volume,
%   foregroundMarker, nonBrainMarker, headSupport, gradientNeighborhood)
%   per ogni slice assiale:
%
%     1. gradiente morfologico dell'immagine ORIGINALE:
%          imdilate(I, nhood) - imerode(I, nhood)   (come EXP-008)
%     2. imimposemin(gradiente, foregroundMarker | nonBrainMarker),
%        poi watershed (connettività predefinita, 8 in 2D)
%     3. etichette positive toccate da QUALSIASI marker del primo piano;
%        candidato = unione dei rispettivi bacini (linee di cresta, etichetta
%        0, escluse), intersecata con headSupport, poi imfill 'holes'
%
%   Diagnostica per slice: nBasins (bacini selezionati), conflictBasins
%   (bacini selezionati che contengono pixel del marker non-cervello),
%   unionArea, addedByFilling. Nessuna scelta manuale di bacini.

    arguments
        volume (:,:,:) double {mustBeReal}
        foregroundMarker (:,:,:) logical
        nonBrainMarker (:,:,:) logical
        headSupport (:,:,:) logical
        gradientNeighborhood (:,:) double
    end

    nSlices = size(volume, 3);
    candidate = false(size(volume));
    diagnostics.nBasins = zeros(nSlices, 1);
    diagnostics.conflictBasins = zeros(nSlices, 1);
    diagnostics.unionArea = zeros(nSlices, 1);
    diagnostics.addedByFilling = zeros(nSlices, 1);

    for k = 1:nSlices
        foreground = foregroundMarker(:, :, k);
        if ~any(foreground, 'all')
            continue
        end
        sliceImage = volume(:, :, k);
        nonBrain = nonBrainMarker(:, :, k);

        gradientImage = imdilate(sliceImage, gradientNeighborhood) ...
            - imerode(sliceImage, gradientNeighborhood);
        labels = watershed(imimposemin(gradientImage, foreground | nonBrain));

        selectedLabels = unique(labels(foreground));
        selectedLabels = selectedLabels(selectedLabels > 0);
        diagnostics.nBasins(k) = numel(selectedLabels);

        selectedUnion = ismember(labels, selectedLabels);
        conflictLabels = unique(labels(selectedUnion & nonBrain));
        diagnostics.conflictBasins(k) = numel(conflictLabels(conflictLabels > 0));

        selectedUnion = selectedUnion & headSupport(:, :, k);
        filled = imfill(selectedUnion, 'holes');
        diagnostics.unionArea(k) = nnz(selectedUnion);
        diagnostics.addedByFilling(k) = nnz(filled) - nnz(selectedUnion);
        candidate(:, :, k) = filled;
    end

end
