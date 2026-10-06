function [candidate, brainMarker, nonBrainMarker, diagnostics] = watershedBrainMaskSlices( ...
    volume, rawMask, headSupport, markerElement, gradientNeighborhood, connectivity)
%WATERSHEDBRAINMASKSLICES Separazione cervello/periferia con watershed a marker (2D).
%
%   [candidate, brainMarker, nonBrainMarker, diagnostics] =
%   WATERSHEDBRAINMASKSLICES(volume, rawMask, headSupport, markerElement,
%   gradientNeighborhood, connectivity) elabora ogni slice assiale
%   separatamente:
%
%     1. gradiente morfologico: imdilate(I, nhood) - imerode(I, nhood)
%     2. marker del cervello: imerode(raw AND headSupport, markerElement),
%        poi la componente più grande (connectivity). raw AND headSupport
%        è la maschera grezza NON riempita ristretta alla componente del
%        supporto della testa; così il marker sta dentro
%        imerode(headSupport) ed è disgiunto per costruzione dal marker
%        non-cervello.
%     3. marker non-cervello: sfondo esterno (NOT headSupport) più il
%        guscio periferico headSupport AND NOT imerode(headSupport,
%        markerElement)
%     4. imimposemin impone i minimi del gradiente solo nei marker,
%        poi watershed (connettività predefinita, 8 in 2D)
%     5. bacino del cervello = etichetta più frequente sotto il marker del
%        cervello; le linee di cresta (etichetta 0) non sono incluse
%     6. intersezione con headSupport, poi imfill 'holes'
%
%   Input:
%     volume                volume double normalizzato in [0,1]
%     rawMask               maschera grezza della fase 49 (logica)
%     headSupport           candidato A della fase 50 (logica)
%     markerElement         elemento strutturante per i marker (strel)
%     gradientNeighborhood  intorno del gradiente morfologico, es. ones(3)
%     connectivity          connettività 2D delle componenti, 4 o 8
%
%   Output:
%     candidate       maschera logica candidata
%     brainMarker     marker del cervello (logico)
%     nonBrainMarker  marker non-cervello (logico)
%     diagnostics     vettori per slice: markerEmpty, nComponentsEroded,
%                     markerArea, markerOverlap, labelsUnderMarker,
%                     basinArea, addedByFilling
%
%   Nessuna scelta manuale di bacini, nessuna regola di posizione, nessun
%   3D, nessun ground truth.

    arguments
        volume (:,:,:) double {mustBeReal}
        rawMask (:,:,:) logical
        headSupport (:,:,:) logical
        markerElement
        gradientNeighborhood (:,:) double
        connectivity (1,1) double {mustBeMember(connectivity, [4 8])}
    end

    if ~isequal(size(volume), size(rawMask), size(headSupport))
        error('segmentation:sizeMismatch', 'Volume and masks must have the same size.');
    end

    nSlices = size(volume, 3);
    candidate = false(size(volume));
    brainMarker = false(size(volume));
    nonBrainMarker = false(size(volume));
    diagnostics.markerEmpty = false(nSlices, 1);
    diagnostics.nComponentsEroded = zeros(nSlices, 1);
    diagnostics.markerArea = zeros(nSlices, 1);
    diagnostics.markerOverlap = zeros(nSlices, 1);
    diagnostics.labelsUnderMarker = zeros(nSlices, 1);
    diagnostics.basinArea = zeros(nSlices, 1);
    diagnostics.addedByFilling = zeros(nSlices, 1);

    for k = 1:nSlices
        sliceImage = volume(:, :, k);
        head = headSupport(:, :, k);

        % 1. Gradiente morfologico
        gradientImage = imdilate(sliceImage, gradientNeighborhood) - imerode(sliceImage, gradientNeighborhood);

        % 3. Marker non-cervello (sfondo esterno + guscio periferico)
        erodedHead = imerode(head, markerElement);
        outside = ~head;
        shell = head & ~erodedHead;
        nonBrain = outside | shell;
        nonBrainMarker(:, :, k) = nonBrain;

        % 2. Marker del cervello
        eroded = imerode(rawMask(:, :, k) & head, markerElement);
        components = bwconncomp(eroded, connectivity);
        diagnostics.nComponentsEroded(k) = components.NumObjects;
        if components.NumObjects == 0
            diagnostics.markerEmpty(k) = true;
            continue
        end
        areas = cellfun(@numel, components.PixelIdxList);
        [~, index] = max(areas);
        brain = false(size(sliceImage));
        brain(components.PixelIdxList{index}) = true;
        brainMarker(:, :, k) = brain;
        diagnostics.markerArea(k) = nnz(brain);
        diagnostics.markerOverlap(k) = nnz(brain & nonBrain);

        % 4. Watershed con minimi imposti nei marker
        imposed = imimposemin(gradientImage, brain | nonBrain);
        labels = watershed(imposed);

        % 5. Bacino associato al marker del cervello
        underMarker = labels(brain);
        underMarker = underMarker(underMarker > 0);
        diagnostics.labelsUnderMarker(k) = numel(unique(underMarker));
        if isempty(underMarker)
            continue
        end
        basin = labels == mode(underMarker);

        % 6. Vincolo al supporto della testa e riempimento
        basin = basin & head;
        filled = imfill(basin, 'holes');
        diagnostics.basinArea(k) = nnz(basin);
        diagnostics.addedByFilling(k) = nnz(filled) - nnz(basin);
        candidate(:, :, k) = filled;
    end

end
