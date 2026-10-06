function [candidate, selectedCore, diagnostics] = brainMask3DErodeSelectDilate(rawMask, radius, connectivity)
%BRAINMASK3DERODESELECTDILATE Erosione 3D -> componente 3D più grande -> dilatazione 3D (EXP-021).
%
%   [candidate, selectedCore, diagnostics] =
%   BRAINMASK3DERODESELECTDILATE(rawMask, radius, connectivity):
%
%     1. eroded = imerode(rawMask, strel('sphere', radius))        (3D)
%     2. componenti connesse 3D di eroded (bwconncomp, connectivity)
%     3. selectedCore = componente 3D più grande (parità: prima
%        nell'ordine di bwconncomp)
%     4. restored = imdilate(selectedCore, strel('sphere', radius))
%        AND rawMask                                                 (3D)
%     5. candidate = imfill(restored(:,:,k), 'holes') slice per slice (2D)
%
%   Estensione volumetrica di operazioni 2D del corso (erosione,
%   dilatazione, componenti connesse, regione più grande, riempimento):
%   l'elaborazione 3D non è trattata nel PDF del corso. Eccezione
%   esplorativa autorizzata dall'utente per EXP-021.
%
%   Input:
%     rawMask       maschera logica grezza 3D (T1 Otsu, EXP-010)
%     radius        raggio della sfera (voxel, 1 mm isotropo)
%     connectivity  connettività 3D delle componenti: 6, 18 oppure 26
%
%   Output:
%     candidate     maschera candidata
%     selectedCore  componente 3D scelta dopo l'erosione (prima della
%                   dilatazione)
%     diagnostics   struttura: erodedVoxels, nComponents, componentSizes
%                   (ordinate, decrescenti), selectedIndex, restoredVoxels,
%                   addedByFilling
%
%   Nessuna soglia di area, nessuna regola di posizione, nessun ground truth.

    arguments
        rawMask (:,:,:) logical
        radius (1,1) double {mustBeInteger, mustBePositive}
        connectivity (1,1) double {mustBeMember(connectivity, [6 18 26])}
    end

    element = strel('sphere', radius);
    eroded = imerode(rawMask, element);

    components = bwconncomp(eroded, connectivity);
    sizes = cellfun(@numel, components.PixelIdxList);
    diagnostics.erodedVoxels = nnz(eroded);
    diagnostics.nComponents = components.NumObjects;
    diagnostics.componentSizes = sort(sizes, 'descend');

    selectedCore = false(size(rawMask));
    candidate = false(size(rawMask));
    diagnostics.selectedIndex = 0;
    diagnostics.restoredVoxels = 0;
    diagnostics.addedByFilling = 0;
    if components.NumObjects == 0
        return
    end

    [~, index] = max(sizes);
    diagnostics.selectedIndex = index;
    selectedCore(components.PixelIdxList{index}) = true;

    restored = imdilate(selectedCore, element) & rawMask;
    diagnostics.restoredVoxels = nnz(restored);

    for k = 1:size(rawMask, 3)
        candidate(:, :, k) = imfill(restored(:, :, k), 'holes');
    end
    diagnostics.addedByFilling = nnz(candidate) - nnz(restored);

end
