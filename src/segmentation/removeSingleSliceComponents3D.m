function [keptMask, details] = removeSingleSliceComponents3D(mask, connectivity, minimumOccupiedSlices)
%REMOVESINGLESLICECOMPONENTS3D Rimuove le componenti 3D che occupano meno di N slice assiali.
%
%   [keptMask, details] = REMOVESINGLESLICECOMPONENTS3D(mask, connectivity,
%   minimumOccupiedSlices) calcola le componenti connesse 3D della maschera
%   (bwconncomp, connettività indicata) e conserva solo quelle che occupano
%   almeno minimumOccupiedSlices slice assiali distinte (dimensione 3).
%   Regola generica di continuità sull'oggetto predetto: nessun criterio di
%   numero di voxel, dimensione, posizione assoluta in z o forma.
%
%   details: componentCount, removedComponentCount, keptComponentCount,
%   removedVoxels.

    arguments
        mask {mustBeA(mask, 'logical')}
        connectivity (1, 1) {mustBeMember(connectivity, [6 18 26])}
        minimumOccupiedSlices (1, 1) {mustBeInteger, mustBePositive}
    end

    if ndims(mask) ~= 3
        error('removeSingleSliceComponents3D:invalidMask', 'The mask must be a 3D logical array.');
    end

    cc = bwconncomp(mask, connectivity);
    sliceVoxels = size(mask, 1) * size(mask, 2);
    keep = false(cc.NumObjects, 1);
    for i = 1:cc.NumObjects
        sliceOfVoxel = floor((cc.PixelIdxList{i} - 1) / sliceVoxels) + 1;   % indice di slice di ogni voxel
        keep(i) = numel(unique(sliceOfVoxel)) >= minimumOccupiedSlices;
    end
    keptMask = false(size(mask));
    keptMask(vertcat(cc.PixelIdxList{keep}, zeros(0, 1))) = true;

    details = struct('componentCount', cc.NumObjects, 'removedComponentCount', nnz(~keep), ...
        'keptComponentCount', nnz(keep), 'removedVoxels', nnz(mask) - nnz(keptMask));
end
