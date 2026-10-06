function [candidate, foregroundMarker, nonBrainMarker, parentMask, ridgeMask, diagnostics] = ...
    watershedFromTopologyMarkersSlices(volume, rawMask, connectivity, gradientNeighborhood, boundaryElement)
%WATERSHEDFROMTOPOLOGYMARKERSSLICES Watershed a marker con marker topologici (EXP-014).
%
%   [candidate, foregroundMarker, nonBrainMarker, parentMask, ridgeMask,
%   diagnostics] = WATERSHEDFROMTOPOLOGYMARKERSSLICES(volume, rawMask,
%   connectivity, gradientNeighborhood, boundaryElement) elabora ogni slice
%   assiale separatamente:
%
%     1. componenti (bwconncomp) e relazione di racchiudimento IDENTICA a
%        EXP-012: Ci racchiude Cj (j ~= i) se TUTTI i pixel di Cj stanno in
%        imfill(Ci,'holes') AND NOT Ci
%     2. ancora = componente annidata di area massima (parità: prima
%        nell'ordine di bwconncomp), come EXP-012; nessuna ancora -> slice
%        VUOTA, nessun watershed
%     3. genitore immediato P dell'ancora = racchiudente con la regione
%        racchiusa più piccola (parità: indice più basso), come EXP-013
%     4. marker del primo piano = l'ancora grezza, senza modifiche
%     5. filledParent = imfill(P,'holes') (solo dominio di supporto)
%        marker non-cervello = NOT filledParent
%            OR (P AND filledParent AND NOT imerode(filledParent, boundaryElement))
%        cioè solo il bordo ESTERNO di P; i bordi attorno ai buchi interni
%        di P restano liberi (chiarimento della specifica EXP-014)
%     6. gradiente morfologico della slice T1 originale:
%            imdilate(I, nhood) - imerode(I, nhood)
%     7. imimposemin sui due marker, poi watershed (connettività
%        predefinita, 8 in 2D)
%     8. candidato = unione delle etichette positive toccate dall'ancora
%        (cresta 0 esclusa) AND filledParent AND NOT marker non-cervello,
%        poi un solo imfill 'holes'
%
%   Input:
%     volume                volume T1 double normalizzato in [0,1]
%     rawMask               maschera grezza T1 (EXP-010), logica
%     connectivity          connettività 2D delle componenti, 4 oppure 8
%     gradientNeighborhood  intorno del gradiente morfologico, es. ones(3)
%     boundaryElement       strel per il bordo esterno, es. strel('square',3)
%
%   Output:
%     candidate         maschera candidata
%     foregroundMarker  ancora (marker del primo piano)
%     nonBrainMarker    marker non-cervello
%     parentMask        genitore immediato dell'ancora (solo diagnostica)
%     ridgeMask         linee di cresta del watershed (etichetta 0)
%     diagnostics       vettori per slice: hasAnchor, anchorIndex,
%                       anchorArea, nAnchorParents, parentTie, parentArea,
%                       filledParentArea, boundaryBandArea, markerOverlap,
%                       labelsUnderAnchor, basinRawArea, constrainedArea,
%                       addedByFilling, finalArea
%
%   La logica topologica è duplicata da EXP-012/013, che restano invariati.
%   Nessuna scelta manuale di bacini, nessuna soglia di area, nessuna regola
%   di posizione, nessun 3D, nessuna informazione da altre slice.

    arguments
        volume (:,:,:) double {mustBeReal}
        rawMask (:,:,:) logical
        connectivity (1,1) double {mustBeMember(connectivity, [4 8])}
        gradientNeighborhood (:,:) double
        boundaryElement
    end

    if ~isequal(size(volume), size(rawMask))
        error('segmentation:sizeMismatch', 'Volume and mask must have the same size.');
    end

    nSlices = size(volume, 3);
    candidate = false(size(volume));
    foregroundMarker = false(size(volume));
    nonBrainMarker = false(size(volume));
    parentMask = false(size(volume));
    ridgeMask = false(size(volume));

    names = {'anchorIndex', 'anchorArea', 'nAnchorParents', 'parentArea', 'filledParentArea', ...
        'boundaryBandArea', 'markerOverlap', 'labelsUnderAnchor', 'basinRawArea', ...
        'constrainedArea', 'addedByFilling', 'finalArea'};
    for f = 1:numel(names)
        diagnostics.(names{f}) = zeros(nSlices, 1);
    end
    diagnostics.hasAnchor = false(nSlices, 1);
    diagnostics.parentTie = false(nSlices, 1);

    for k = 1:nSlices
        slice = rawMask(:, :, k);
        components = bwconncomp(slice, connectivity);
        n = components.NumObjects;
        if n == 0
            continue
        end
        areas = cellfun(@numel, components.PixelIdxList);

        % 1. Relazione di racchiudimento (come EXP-012)
        nests = false(n, n);
        enclosedArea = zeros(n, 1);
        for i = 1:n
            componentMask = false(size(slice));
            componentMask(components.PixelIdxList{i}) = true;
            enclosedRegion = imfill(componentMask, 'holes') & ~componentMask;
            enclosedArea(i) = nnz(enclosedRegion);
            if enclosedArea(i) == 0
                continue
            end
            for j = [1:i-1, i+1:n]
                nests(i, j) = all(enclosedRegion(components.PixelIdxList{j}));
            end
        end

        isNested = any(nests, 1);
        if ~any(isNested)
            continue                    % nessuna ancora: slice vuota
        end

        % 2. Ancora (come EXP-012)
        nestedIndices = find(isNested);
        [anchorArea, position] = max(areas(nestedIndices));
        anchor = nestedIndices(position);

        % 3. Genitore immediato dell'ancora (come EXP-013)
        parents = find(nests(:, anchor)).';
        [smallest, position] = min(enclosedArea(parents));
        parent = parents(position);

        anchorSlice = false(size(slice));
        anchorSlice(components.PixelIdxList{anchor}) = true;
        parentSlice = false(size(slice));
        parentSlice(components.PixelIdxList{parent}) = true;

        % 5. Supporto e marker non-cervello (solo bordo esterno di P)
        filledParent = imfill(parentSlice, 'holes');
        outerBand = parentSlice & filledParent & ~imerode(filledParent, boundaryElement);
        nonBrain = ~filledParent | outerBand;

        diagnostics.hasAnchor(k) = true;
        diagnostics.anchorIndex(k) = anchor;
        diagnostics.anchorArea(k) = anchorArea;
        diagnostics.nAnchorParents(k) = numel(parents);
        diagnostics.parentTie(k) = nnz(enclosedArea(parents) == smallest) > 1;
        diagnostics.parentArea(k) = areas(parent);
        diagnostics.filledParentArea(k) = nnz(filledParent);
        diagnostics.boundaryBandArea(k) = nnz(outerBand);
        diagnostics.markerOverlap(k) = nnz(anchorSlice & nonBrain);
        foregroundMarker(:, :, k) = anchorSlice;
        nonBrainMarker(:, :, k) = nonBrain;
        parentMask(:, :, k) = parentSlice;
        if diagnostics.markerOverlap(k) > 0
            continue                    % slice tecnicamente non valida, nessuna riparazione
        end

        % 6-7. Gradiente morfologico della T1 originale e watershed
        sliceImage = volume(:, :, k);
        gradientImage = imdilate(sliceImage, gradientNeighborhood) - imerode(sliceImage, gradientNeighborhood);
        labels = watershed(imimposemin(gradientImage, anchorSlice | nonBrain));
        ridgeMask(:, :, k) = labels == 0;

        % 8. Bacini toccati dall'ancora, vincolo al supporto, riempimento
        underAnchor = unique(labels(anchorSlice));
        underAnchor = underAnchor(underAnchor > 0);
        diagnostics.labelsUnderAnchor(k) = numel(underAnchor);
        if isempty(underAnchor)
            continue
        end
        basin = ismember(labels, underAnchor);
        constrained = basin & filledParent & ~nonBrain;
        filled = imfill(constrained, 'holes');

        diagnostics.basinRawArea(k) = nnz(basin);
        diagnostics.constrainedArea(k) = nnz(constrained);
        diagnostics.addedByFilling(k) = nnz(filled) - nnz(constrained);
        diagnostics.finalArea(k) = nnz(filled);
        candidate(:, :, k) = filled;
    end

end
