function [candidate, closedEdges, enclosingCount, diagnostics] = ...
    selectCannyEnclosingBrainCandidateSlices(edges, anchorMask, closingElement, connectivity)
%SELECTCANNYENCLOSINGBRAINCANDIDATESLICES Contorno di Canny più piccolo che racchiude l'ancora (EXP-017).
%
%   [candidate, closedEdges, enclosingCount, diagnostics] =
%   SELECTCANNYENCLOSINGBRAINCANDIDATESLICES(edges, anchorMask,
%   closingElement, connectivity) elabora ogni slice assiale separatamente:
%
%     1. closedEdges = imclose(edges, closingElement), UNA sola chiusura
%     2. se la slice non ha ancora: candidato VUOTO
%     3. componenti connesse di closedEdges (bwconncomp, connectivity);
%        ogni componente Ei è riempita DA SOLA: filled_i = imfill(Ei,'holes')
%        (mai la mappa intera, mai unioni di componenti)
%     4. filled_i racchiude l'ancora solo se TUTTI i pixel dell'ancora
%        stanno in filled_i (nessuna tolleranza)
%     5. candidato = filled_i racchiudente di area minima (parità: indice
%        più basso), senza altre operazioni; nessuna racchiudente ->
%        candidato VUOTO
%
%   Input:
%     edges           mappa di Canny grezza (EXP-016), logica
%     anchorMask      ancora EXP-012, logica
%     closingElement  strel della chiusura, es. strel('square',3)
%     connectivity    connettività delle componenti dei bordi, 4 oppure 8
%
%   Output:
%     candidate       regione riempita scelta
%     closedEdges     bordi dopo la chiusura
%     enclosingCount  numero di regioni racchiudenti che coprono ogni pixel
%                     (solo figure)
%     diagnostics     vettori per slice e la cella enclosingAreas (aree
%                     delle regioni racchiudenti in ordine crescente)
%
%   Diagnostica solo descrittiva (non usata nella scelta): bestCoverage =
%   frazione massima dell'ancora contenuta in una singola regione riempita.
%   Nessuna soglia di area, nessuna regola di posizione, nessun 3D, nessuna
%   informazione da altre slice, nessun vincolo da Otsu o dal genitore.

    arguments
        edges (:,:,:) logical
        anchorMask (:,:,:) logical
        closingElement
        connectivity (1,1) double {mustBeMember(connectivity, [4 8])}
    end

    if ~isequal(size(edges), size(anchorMask))
        error('segmentation:sizeMismatch', 'Edges and anchor must have the same size.');
    end

    nSlices = size(edges, 3);
    candidate = false(size(edges));
    closedEdges = false(size(edges));
    enclosingCount = zeros(size(edges), 'uint8');

    names = {'rawEdgePixels', 'closedEdgePixels', 'addedByClosing', 'removedByClosing', ...
        'nRawComponents', 'nClosedComponents', 'anchorArea', 'nEnclosing', 'selectedIndex', ...
        'selectedFilledArea', 'selectedEdgeArea', 'candidateArea', 'tieCount', 'bestCoverage'};
    for f = 1:numel(names)
        diagnostics.(names{f}) = zeros(nSlices, 1);
    end
    diagnostics.hasAnchor = false(nSlices, 1);
    diagnostics.hasCandidate = false(nSlices, 1);
    diagnostics.enclosingAreas = cell(nSlices, 1);

    for k = 1:nSlices
        rawSlice = edges(:, :, k);
        closed = imclose(rawSlice, closingElement);
        closedEdges(:, :, k) = closed;

        diagnostics.rawEdgePixels(k) = nnz(rawSlice);
        diagnostics.closedEdgePixels(k) = nnz(closed);
        diagnostics.addedByClosing(k) = nnz(closed & ~rawSlice);
        diagnostics.removedByClosing(k) = nnz(rawSlice & ~closed);
        diagnostics.nRawComponents(k) = bwconncomp(rawSlice, connectivity).NumObjects;
        components = bwconncomp(closed, connectivity);
        diagnostics.nClosedComponents(k) = components.NumObjects;

        anchor = anchorMask(:, :, k);
        if ~any(anchor(:))
            continue                    % nessuna ancora: candidato vuoto
        end
        diagnostics.hasAnchor(k) = true;
        anchorArea = nnz(anchor);
        diagnostics.anchorArea(k) = anchorArea;

        filledAreas = inf(components.NumObjects, 1);
        bestCoverage = 0;
        count = zeros(size(anchor), 'uint8');
        for i = 1:components.NumObjects
            edgeComponent = false(size(anchor));
            edgeComponent(components.PixelIdxList{i}) = true;
            filled = imfill(edgeComponent, 'holes');
            covered = nnz(filled & anchor);
            bestCoverage = max(bestCoverage, covered / anchorArea);
            if covered == anchorArea
                filledAreas(i) = nnz(filled);
                count = count + uint8(filled);
            end
        end
        enclosingCount(:, :, k) = count;
        diagnostics.bestCoverage(k) = bestCoverage;

        enclosing = find(isfinite(filledAreas));
        diagnostics.nEnclosing(k) = numel(enclosing);
        diagnostics.enclosingAreas{k} = sort(filledAreas(enclosing)).';
        if isempty(enclosing)
            continue                    % nessuna regione racchiudente: candidato vuoto
        end

        [smallest, position] = min(filledAreas(enclosing));
        index = enclosing(position);
        diagnostics.tieCount(k) = nnz(filledAreas(enclosing) == smallest) - 1;

        selected = false(size(anchor));
        selected(components.PixelIdxList{index}) = true;
        filled = imfill(selected, 'holes');

        diagnostics.hasCandidate(k) = true;
        diagnostics.selectedIndex(k) = index;
        diagnostics.selectedFilledArea(k) = smallest;
        diagnostics.selectedEdgeArea(k) = numel(components.PixelIdxList{index});
        diagnostics.candidateArea(k) = nnz(filled);
        candidate(:, :, k) = filled;
    end

end
