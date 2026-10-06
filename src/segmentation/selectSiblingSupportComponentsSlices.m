function [candidate, diagnostics, anchorMask, parentMask, selectedChildrenMask] = selectSiblingSupportComponentsSlices(rawMask, connectivity)
%SELECTSIBLINGSUPPORTCOMPONENTSSLICES Unione dei figli diretti del genitore immediato (EXP-013).
%
%   [candidate, diagnostics, anchorMask, parentMask, selectedChildrenMask] =
%   SELECTSIBLINGSUPPORTCOMPONENTSSLICES(rawMask, connectivity) elabora ogni
%   slice assiale separatamente:
%
%     1. componenti connesse 2D (bwconncomp) C1..Cn con la connettività data
%     2. relazione di racchiudimento IDENTICA a EXP-012: per ogni Ci da sola
%            enclosedRegion_i = imfill(Ci, 'holes') AND NOT Ci
%        Ci racchiude Cj (j ~= i) solo se TUTTI i pixel di Cj stanno in
%        enclosedRegion_i (contenimento completo, nessuna tolleranza)
%     3. ancora = componente annidata di area massima (parità: prima
%        nell'ordine di bwconncomp), esattamente come EXP-012
%     4. genitore immediato di ogni componente annidata Cj = tra le
%        componenti che la racchiudono, quella con la regione racchiusa più
%        piccola (parità: indice più basso, registrata). L'area serve solo a
%        ordinare la gerarchia, non a scartare componenti
%     5. selezione = tutti i figli DIRETTI del genitore immediato
%        dell'ancora (ancora compresa); mai il genitore, mai i figli di altri
%        genitori, mai i discendenti solo perché discendenti
%     6. ogni figlio scelto è riempito SINGOLARMENTE (imfill 'holes'), poi
%        si fa l'unione; l'unione NON viene riempita di nuovo
%
%   Se una slice non ha componenti annidate (nessuna ancora), l'uscita della
%   slice è VUOTA: nessun ripiego.
%
%   Input:
%     rawMask       maschera logica grezza (EXP-010)
%     connectivity  connettività 2D del primo piano, 4 oppure 8
%
%   Output:
%     candidate             unione dei figli diretti riempiti singolarmente
%     diagnostics           struttura con vettori per slice (vedi sotto) e
%                           il campo connectivity
%     anchorMask            ancora (selezione di EXP-012) prima del riempimento
%     parentMask            genitore immediato dell'ancora (solo diagnostica)
%     selectedChildrenMask  figli diretti scelti prima del riempimento
%
%   La logica di racchiudimento è duplicata da
%   selectNestedSupportComponentSlices (EXP-012), che resta invariata.
%   imfill usa la connettività predefinita per lo sfondo (4 in 2D).
%   Nessuna soglia di area, nessuna regola di posizione, nessun 3D, nessuna
%   informazione da altre slice.

    arguments
        rawMask (:,:,:) logical
        connectivity (1,1) double {mustBeMember(connectivity, [4 8])}
    end

    nSlices = size(rawMask, 3);
    candidate = false(size(rawMask));
    anchorMask = false(size(rawMask));
    parentMask = false(size(rawMask));
    selectedChildrenMask = false(size(rawMask));

    diagnostics.connectivity = connectivity;
    diagnostics.nComponents = zeros(nSlices, 1);
    diagnostics.nRelations = zeros(nSlices, 1);
    diagnostics.nNested = zeros(nSlices, 1);
    diagnostics.hasAnchor = false(nSlices, 1);
    diagnostics.anchorIndex = zeros(nSlices, 1);
    diagnostics.anchorArea = zeros(nSlices, 1);
    diagnostics.anchorFilledArea = zeros(nSlices, 1);
    diagnostics.nAnchorParents = zeros(nSlices, 1);
    diagnostics.parentIndex = zeros(nSlices, 1);
    diagnostics.parentArea = zeros(nSlices, 1);
    diagnostics.parentEnclosedArea = zeros(nSlices, 1);
    diagnostics.parentTie = false(nSlices, 1);
    diagnostics.nDirectChildren = zeros(nSlices, 1);
    diagnostics.nAddedSiblings = zeros(nSlices, 1);
    diagnostics.childrenRawArea = zeros(nSlices, 1);
    diagnostics.finalArea = zeros(nSlices, 1);

    for k = 1:nSlices
        slice = rawMask(:, :, k);
        components = bwconncomp(slice, connectivity);
        n = components.NumObjects;
        diagnostics.nComponents(k) = n;
        if n == 0
            continue
        end
        areas = cellfun(@numel, components.PixelIdxList);

        % Relazione di racchiudimento: nests(i, j) vero se Ci racchiude Cj
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
        diagnostics.nRelations(k) = nnz(nests);
        diagnostics.nNested(k) = nnz(isNested);
        if ~any(isNested)
            continue                    % nessuna ancora: slice vuota
        end

        % Genitore immediato di ogni componente annidata
        immediateParent = zeros(1, n);
        for j = find(isNested)
            parents = find(nests(:, j)).';
            [smallest, position] = min(enclosedArea(parents));
            immediateParent(j) = parents(position);
            if nnz(enclosedArea(parents) == smallest) > 1
                diagnostics.parentTie(k) = true;
            end
        end

        % Ancora: come EXP-012
        nestedIndices = find(isNested);
        [anchorArea, position] = max(areas(nestedIndices));
        anchor = nestedIndices(position);
        parent = immediateParent(anchor);

        % Figli diretti dello stesso genitore immediato, riempiti uno per uno
        children = find(immediateParent == parent);
        selectedChildren = false(size(slice));
        filledUnion = false(size(slice));
        for j = children
            childMask = false(size(slice));
            childMask(components.PixelIdxList{j}) = true;
            selectedChildren = selectedChildren | childMask;
            filledUnion = filledUnion | imfill(childMask, 'holes');
            if j == anchor
                diagnostics.anchorFilledArea(k) = nnz(imfill(childMask, 'holes'));
            end
        end

        anchorSlice = false(size(slice));
        anchorSlice(components.PixelIdxList{anchor}) = true;
        parentSlice = false(size(slice));
        parentSlice(components.PixelIdxList{parent}) = true;

        diagnostics.hasAnchor(k) = true;
        diagnostics.anchorIndex(k) = anchor;
        diagnostics.anchorArea(k) = anchorArea;
        diagnostics.nAnchorParents(k) = nnz(nests(:, anchor));
        diagnostics.parentIndex(k) = parent;
        diagnostics.parentArea(k) = areas(parent);
        diagnostics.parentEnclosedArea(k) = enclosedArea(parent);
        diagnostics.nDirectChildren(k) = numel(children);
        diagnostics.nAddedSiblings(k) = numel(children) - 1;
        diagnostics.childrenRawArea(k) = sum(areas(children));
        diagnostics.finalArea(k) = nnz(filledUnion);

        anchorMask(:, :, k) = anchorSlice;
        parentMask(:, :, k) = parentSlice;
        selectedChildrenMask(:, :, k) = selectedChildren;
        candidate(:, :, k) = filledUnion;
    end

end
