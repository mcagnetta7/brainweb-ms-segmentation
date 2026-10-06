function [cleanMask, diagnostics] = cleanSupportMaskSlices(rawMask, connectivity, openingElement)
%CLEANSUPPORTMASKSLICES Pulizia 2D slice per slice della maschera di supporto.
%
%   [cleanMask, diagnostics] = CLEANSUPPORTMASKSLICES(rawMask,
%   connectivity, openingElement) elabora ogni slice assiale
%   separatamente, in questo ordine:
%
%     1. (solo se openingElement non è vuoto) apertura imopen 2D
%     2. componenti connesse 2D (bwconncomp) con la connettività data;
%        si tiene SOLO la componente più grande, le altre sono scartate
%     3. riempimento dei buchi (imfill 'holes') SOLO sulla componente
%        tenuta, mai sulla maschera grezza
%
%   Input:
%     rawMask         maschera logica grezza (fase 49)
%     connectivity    connettività 2D del primo piano, 4 oppure 8
%     openingElement  elemento strutturante 2D per imopen, oppure [] per
%                     nessuna apertura
%
%   Output:
%     cleanMask    maschera logica pulita, stesse dimensioni
%     diagnostics  struttura con vettori per slice: nComponents,
%                  largestArea, openingChanged, removedByComponent,
%                  addedByFilling
%
%   imfill usa la connettività predefinita per lo sfondo (4 in 2D),
%   topologicamente coerente con un primo piano a 8-connettività.
%   Nessuna soglia di area, nessuna regola di posizione, nessun 3D.

    arguments
        rawMask (:,:,:) logical
        connectivity (1,1) double {mustBeMember(connectivity, [4 8])}
        openingElement = []
    end

    nSlices = size(rawMask, 3);
    cleanMask = false(size(rawMask));
    diagnostics.nComponents = zeros(nSlices, 1);
    diagnostics.largestArea = zeros(nSlices, 1);
    diagnostics.openingChanged = zeros(nSlices, 1);
    diagnostics.removedByComponent = zeros(nSlices, 1);
    diagnostics.addedByFilling = zeros(nSlices, 1);

    for k = 1:nSlices
        slice = rawMask(:, :, k);

        if ~isempty(openingElement)
            opened = imopen(slice, openingElement);
            diagnostics.openingChanged(k) = nnz(xor(opened, slice));
            slice = opened;
        end

        components = bwconncomp(slice, connectivity);
        diagnostics.nComponents(k) = components.NumObjects;
        if components.NumObjects == 0
            continue
        end

        areas = cellfun(@numel, components.PixelIdxList);
        [largest, index] = max(areas);
        selected = false(size(slice));
        selected(components.PixelIdxList{index}) = true;

        filled = imfill(selected, 'holes');

        diagnostics.largestArea(k) = largest;
        diagnostics.removedByComponent(k) = nnz(slice) - largest;
        diagnostics.addedByFilling(k) = nnz(filled) - largest;
        cleanMask(:, :, k) = filled;
    end

end
