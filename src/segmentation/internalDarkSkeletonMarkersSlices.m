function [internalDark, internalBackgroundMarker, anchorMask, parentMask, diagnostics] = ...
    internalDarkSkeletonMarkersSlices(rawMask, connectivity)
%INTERNALDARKSKELETONMARKERSSLICES Marker di sfondo interno scheletrizzato (EXP-015).
%
%   [internalDark, internalBackgroundMarker, anchorMask, parentMask,
%   diagnostics] = INTERNALDARKSKELETONMARKERSSLICES(rawMask, connectivity)
%   elabora ogni slice assiale separatamente. Il marker dipende SOLO dalla
%   maschera binaria Otsu grezza e dai supporti topologici:
%
%     1. componenti (bwconncomp) e relazione di racchiudimento IDENTICA a
%        EXP-012: Ci racchiude Cj (j ~= i) se TUTTI i pixel di Cj stanno in
%        imfill(Ci,'holes') AND NOT Ci
%     2. ancora = componente annidata di area massima (parità: prima
%        nell'ordine di bwconncomp), come EXP-012; nessuna ancora ->
%        nessun marker
%     3. genitore immediato P = racchiudente con la regione racchiusa più
%        piccola (parità: indice più basso), come EXP-013/014
%     4. filledParent = imfill(P,'holes'); filledAnchor = imfill(ancora,'holes')
%     5. internalDark = filledParent AND NOT rawMask AND NOT filledAnchor
%        (lo sfondo Otsu già esistente; nessuna seconda soglia)
%     6. internalBackgroundMarker = bwmorph(internalDark, 'skel', Inf),
%        senza potatura, filtri o selezione di componenti
%
%   Diagnostica (solo descrittiva, non modifica il marker):
%     - test di barriera: nel dominio filledParent AND NOT marker, con
%       4-connettività (il complemento topologico di una curva a
%       8-connettività: una linea scheletrica a 8-connettività separa solo
%       cammini 4-connessi), esiste una regione che contiene pixel sia
%       dell'ancora sia del genitore? Se no, lo scheletro è una barriera
%       completa
%     - area dei fratelli diretti dell'ancora (stesso genitore immediato,
%       come EXP-013) e quanta di essa è separata dall'ancora dallo
%       scheletro, con la stessa 4-connettività
%
%   Input:
%     rawMask       maschera logica grezza T1 (EXP-010)
%     connectivity  connettività 2D delle componenti di primo piano, 4 o 8
%
%   Output:
%     internalDark              regione scura interna (prima dello scheletro)
%     internalBackgroundMarker  scheletro di internalDark
%     anchorMask                ancora (EXP-012)
%     parentMask                genitore immediato dell'ancora
%     diagnostics               vettori per slice e campo connectivity
%
%   La logica topologica è duplicata da EXP-012/013/014, che restano
%   invariati. Nessun watershed, nessuna soglia aggiuntiva, nessuna regola
%   di posizione, nessun 3D, nessuna informazione da altre slice.

    arguments
        rawMask (:,:,:) logical
        connectivity (1,1) double {mustBeMember(connectivity, [4 8])}
    end

    nSlices = size(rawMask, 3);
    internalDark = false(size(rawMask));
    internalBackgroundMarker = false(size(rawMask));
    anchorMask = false(size(rawMask));
    parentMask = false(size(rawMask));

    diagnostics.connectivity = connectivity;
    diagnostics.barrierConnectivity = 4;
    names = {'anchorArea', 'parentArea', 'filledParentArea', 'filledAnchorArea', 'internalDarkArea', ...
        'skeletonArea', 'nSkeletonComponents', 'largestSkeletonComponent', 'anchorOverlap', ...
        'parentOverlap', 'siblingArea', 'siblingAreaSeparated'};
    for f = 1:numel(names)
        diagnostics.(names{f}) = zeros(nSlices, 1);
    end
    diagnostics.hasAnchor = false(nSlices, 1);
    diagnostics.skeletonEmpty = true(nSlices, 1);
    diagnostics.barrier = false(nSlices, 1);

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
            continue                    % nessuna ancora: nessun marker
        end

        % 2-3. Ancora (EXP-012) e genitori immediati (EXP-013)
        immediateParent = zeros(1, n);
        for j = find(isNested)
            parents = find(nests(:, j)).';
            [~, position] = min(enclosedArea(parents));
            immediateParent(j) = parents(position);
        end
        nestedIndices = find(isNested);
        [anchorArea, position] = max(areas(nestedIndices));
        anchor = nestedIndices(position);
        parent = immediateParent(anchor);

        anchorSlice = false(size(slice));
        anchorSlice(components.PixelIdxList{anchor}) = true;
        parentSlice = false(size(slice));
        parentSlice(components.PixelIdxList{parent}) = true;

        % 4-6. Regione scura interna e scheletro
        filledParent = imfill(parentSlice, 'holes');
        filledAnchor = imfill(anchorSlice, 'holes');
        dark = filledParent & ~slice & ~filledAnchor;
        skeleton = bwmorph(dark, 'skel', Inf);

        % Diagnostica: componenti dello scheletro
        skeletonComponents = bwconncomp(skeleton, 8);
        skeletonAreas = cellfun(@numel, skeletonComponents.PixelIdxList);

        % Diagnostica: test di barriera (4-connettività nel dominio)
        domain = bwconncomp(filledParent & ~skeleton, 4);
        domainLabels = labelmatrix(domain);
        anchorRegions = unique(domainLabels(anchorSlice & domainLabels > 0));
        parentRegions = unique(domainLabels(parentSlice & domainLabels > 0));
        connected = ~isempty(intersect(anchorRegions, parentRegions));

        % Diagnostica: fratelli diretti separati dall'ancora dallo scheletro
        siblings = find(immediateParent == parent);
        siblings = siblings(siblings ~= anchor);
        siblingArea = 0;
        siblingSeparated = 0;
        for j = siblings
            siblingArea = siblingArea + areas(j);
            siblingRegions = unique(domainLabels(components.PixelIdxList{j}));
            siblingRegions = siblingRegions(siblingRegions > 0);
            siblingSeparated = siblingSeparated + ...
                areas(j) * isempty(intersect(siblingRegions, anchorRegions));
        end

        diagnostics.hasAnchor(k) = true;
        diagnostics.anchorArea(k) = anchorArea;
        diagnostics.parentArea(k) = areas(parent);
        diagnostics.filledParentArea(k) = nnz(filledParent);
        diagnostics.filledAnchorArea(k) = nnz(filledAnchor);
        diagnostics.internalDarkArea(k) = nnz(dark);
        diagnostics.skeletonArea(k) = nnz(skeleton);
        diagnostics.nSkeletonComponents(k) = skeletonComponents.NumObjects;
        if ~isempty(skeletonAreas)
            diagnostics.largestSkeletonComponent(k) = max(skeletonAreas);
        end
        diagnostics.skeletonEmpty(k) = ~any(skeleton(:));
        diagnostics.anchorOverlap(k) = nnz(skeleton & anchorSlice);
        diagnostics.parentOverlap(k) = nnz(skeleton & parentSlice);
        diagnostics.barrier(k) = ~connected;
        diagnostics.siblingArea(k) = siblingArea;
        diagnostics.siblingAreaSeparated(k) = siblingSeparated;

        internalDark(:, :, k) = dark;
        internalBackgroundMarker(:, :, k) = skeleton;
        anchorMask(:, :, k) = anchorSlice;
        parentMask(:, :, k) = parentSlice;
    end

end
