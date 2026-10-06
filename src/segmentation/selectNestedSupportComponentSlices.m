function [candidate, diagnostics, selectedMask, enclosedMask] = selectNestedSupportComponentSlices(rawMask, connectivity)
%SELECTNESTEDSUPPORTCOMPONENTSLICES Selezione topologica 2D della componente annidata (EXP-012).
%
%   [candidate, diagnostics, selectedMask, enclosedMask] =
%   SELECTNESTEDSUPPORTCOMPONENTSLICES(rawMask, connectivity) elabora ogni
%   slice assiale separatamente:
%
%     1. componenti connesse 2D del primo piano (bwconncomp) C1..Cn con la
%        connettività data; nessuna componente è presupposta cervello o
%        scalpo
%     2. per OGNI Ci, da sola: regione racchiusa
%            enclosedRegion_i = imfill(Ci, 'holes') AND NOT Ci
%        (riempimento usato SOLO per verificare il racchiudimento, mai
%        come uscita)
%     3. Cj è annidata in Ci (j ~= i) solo se TUTTI i pixel di Cj stanno in
%        enclosedRegion_i (contenimento completo, non sovrapposizione
%        parziale); basta un solo genitore
%     4. tra le componenti annidate si sceglie quella di area massima (in
%        caso di parità, la prima nell'ordine di bwconncomp)
%     5. riempimento finale dei buchi (imfill 'holes') SOLO della
%        componente scelta
%
%   Se una slice non ha componenti annidate, l'uscita della slice è VUOTA:
%   nessun ripiego sulla componente più grande, sulle slice vicine o altro.
%
%   Input:
%     rawMask       maschera logica grezza (fase 49 / EXP-010)
%     connectivity  connettività 2D del primo piano, 4 oppure 8
%
%   Output:
%     candidate     componente scelta dopo il riempimento finale
%     diagnostics   struttura con vettori per slice: nComponents,
%                   nEnclosing, nNested, selectedIndex, selectedArea,
%                   nParentsOfSelected, noNestedCandidate, addedByFilling,
%                   finalArea, largestIndex, largestArea; più il campo
%                   connectivity
%     selectedMask  componente scelta PRIMA del riempimento finale
%     enclosedMask  unione delle regioni racchiuse da tutte le componenti
%                   (solo diagnostica e figure)
%
%   imfill usa la connettività predefinita per lo sfondo (4 in 2D),
%   topologicamente coerente con un primo piano a 8-connettività.
%   Nessuna soglia di area, nessuna regola di posizione, nessun 3D, nessuna
%   informazione da altre slice.

    arguments
        rawMask (:,:,:) logical
        connectivity (1,1) double {mustBeMember(connectivity, [4 8])}
    end

    nSlices = size(rawMask, 3);
    candidate = false(size(rawMask));
    selectedMask = false(size(rawMask));
    enclosedMask = false(size(rawMask));

    diagnostics.connectivity = connectivity;
    diagnostics.nComponents = zeros(nSlices, 1);
    diagnostics.nEnclosing = zeros(nSlices, 1);
    diagnostics.nNested = zeros(nSlices, 1);
    diagnostics.selectedIndex = zeros(nSlices, 1);
    diagnostics.selectedArea = zeros(nSlices, 1);
    diagnostics.nParentsOfSelected = zeros(nSlices, 1);
    diagnostics.noNestedCandidate = true(nSlices, 1);
    diagnostics.addedByFilling = zeros(nSlices, 1);
    diagnostics.finalArea = zeros(nSlices, 1);
    diagnostics.largestIndex = zeros(nSlices, 1);
    diagnostics.largestArea = zeros(nSlices, 1);

    for k = 1:nSlices
        slice = rawMask(:, :, k);
        components = bwconncomp(slice, connectivity);
        n = components.NumObjects;
        diagnostics.nComponents(k) = n;
        if n == 0
            continue
        end

        areas = cellfun(@numel, components.PixelIdxList);
        [diagnostics.largestArea(k), diagnostics.largestIndex(k)] = max(areas);

        % Relazione genitore -> annidata: nests(i, j) vero se Cj è in Ci
        nests = false(n, n);
        enclosedUnion = false(size(slice));
        for i = 1:n
            componentMask = false(size(slice));
            componentMask(components.PixelIdxList{i}) = true;
            enclosedRegion = imfill(componentMask, 'holes') & ~componentMask;
            if ~any(enclosedRegion(:))
                continue
            end
            enclosedUnion = enclosedUnion | enclosedRegion;
            for j = [1:i-1, i+1:n]
                nests(i, j) = all(enclosedRegion(components.PixelIdxList{j}));
            end
        end
        enclosedMask(:, :, k) = enclosedUnion;

        isNested = any(nests, 1);
        diagnostics.nEnclosing(k) = nnz(any(nests, 2));
        diagnostics.nNested(k) = nnz(isNested);
        if ~any(isNested)
            continue                    % nessun candidato: slice vuota
        end

        nestedIndices = find(isNested);
        [selectedArea, position] = max(areas(nestedIndices));
        index = nestedIndices(position);

        selected = false(size(slice));
        selected(components.PixelIdxList{index}) = true;
        filled = imfill(selected, 'holes');

        diagnostics.noNestedCandidate(k) = false;
        diagnostics.selectedIndex(k) = index;
        diagnostics.selectedArea(k) = selectedArea;
        diagnostics.nParentsOfSelected(k) = nnz(nests(:, index));
        diagnostics.addedByFilling(k) = nnz(filled) - selectedArea;
        diagnostics.finalArea(k) = nnz(filled);
        selectedMask(:, :, k) = selected;
        candidate(:, :, k) = filled;
    end

end
