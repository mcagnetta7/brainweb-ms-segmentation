function [cleanMask, diagnostics] = erodeSelectDilateSlices(rawMask, connectivity, element)
%ERODESELECTDILATESLICES Separazione 2D per erosione, selezione e dilatazione.
%
%   [cleanMask, diagnostics] = ERODESELECTDILATESLICES(rawMask,
%   connectivity, element) elabora ogni slice assiale separatamente:
%
%     1. erosione (imerode) con element, per rompere i ponti sottili
%        tra regioni che si toccano
%     2. componenti connesse 2D (bwconncomp) sulla maschera erosa; si
%        tiene SOLO la componente più grande
%     3. dilatazione (imdilate) della sola componente tenuta, con lo
%        stesso element
%     4. intersezione con la maschera grezza: la dilatazione non può
%        aggiungere voxel che la soglia non aveva
%     5. riempimento dei buchi (imfill 'holes') del risultato
%
%   A differenza di un'apertura seguita dalla selezione, qui la
%   componente viene scelta PRIMA della dilatazione, così le regioni
%   separate dall'erosione non possono ricollegarsi.
%
%   Output:
%     cleanMask    maschera logica, stesse dimensioni
%     diagnostics  vettori per slice: nComponentsEroded, largestEroded,
%                  removedBySelection (voxel erosi scartati),
%                  restoredArea (dopo dilatazione e intersezione),
%                  addedByFilling
%
%   Nessuna soglia di area, nessuna regola di posizione, nessun 3D.

    arguments
        rawMask (:,:,:) logical
        connectivity (1,1) double {mustBeMember(connectivity, [4 8])}
        element
    end

    nSlices = size(rawMask, 3);
    cleanMask = false(size(rawMask));
    diagnostics.nComponentsEroded = zeros(nSlices, 1);
    diagnostics.largestEroded = zeros(nSlices, 1);
    diagnostics.removedBySelection = zeros(nSlices, 1);
    diagnostics.restoredArea = zeros(nSlices, 1);
    diagnostics.addedByFilling = zeros(nSlices, 1);

    for k = 1:nSlices
        raw = rawMask(:, :, k);
        eroded = imerode(raw, element);

        components = bwconncomp(eroded, connectivity);
        diagnostics.nComponentsEroded(k) = components.NumObjects;
        if components.NumObjects == 0
            continue
        end

        areas = cellfun(@numel, components.PixelIdxList);
        [largest, index] = max(areas);
        selected = false(size(raw));
        selected(components.PixelIdxList{index}) = true;

        restored = imdilate(selected, element) & raw;
        filled = imfill(restored, 'holes');

        diagnostics.largestEroded(k) = largest;
        diagnostics.removedBySelection(k) = nnz(eroded) - largest;
        diagnostics.restoredArea(k) = nnz(restored);
        diagnostics.addedByFilling(k) = nnz(filled) - nnz(restored);
        cleanMask(:, :, k) = filled;
    end

end
