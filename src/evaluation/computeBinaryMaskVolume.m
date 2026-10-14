function volumeInfo = computeBinaryMaskVolume(mask, voxelSpacingMm)
%COMPUTEBINARYMASKVOLUME Volume fisico occupato da una maschera binaria.
%
%   volumeInfo = COMPUTEBINARYMASKVOLUME(mask, voxelSpacingMm) converte
%   l'occupazione di una maschera logica in volume fisico:
%
%       voxelVolumeMm3 = prod(voxelSpacingMm)
%       volumeMm3      = voxelCount * voxelVolumeMm3
%
%   Restituisce una struttura con voxelCount, voxelVolumeMm3, volumeMm3 e,
%   come semplice conversione di unità della stessa grandezza,
%   volumeCm3 = volumeMl = volumeMm3 / 1000 (1 cm^3 = 1 mL).
%
%   mask: array logico non vuoto (nessuna soglia o conversione implicita).
%   voxelSpacingMm: esattamente 3 valori numerici reali, finiti e
%   strettamente positivi (mm). Nessuna ipotesi implicita di voxel da 1 mm^3.
%   Nessun accesso a file, nessun confronto tra maschere, nessuna metrica.

    arguments
        mask {mustBeA(mask, 'logical')}
        voxelSpacingMm {mustBeNumeric}
    end

    if isempty(mask)
        error('computeBinaryMaskVolume:emptyMask', 'The mask must be a non-empty logical array.');
    end
    if numel(voxelSpacingMm) ~= 3 || ~isreal(voxelSpacingMm) || any(~isfinite(voxelSpacingMm(:))) || ...
            any(voxelSpacingMm(:) <= 0)
        error('computeBinaryMaskVolume:invalidSpacing', ...
            'voxelSpacingMm must contain exactly 3 real, finite, strictly positive values (mm).');
    end

    volumeInfo = struct();
    volumeInfo.voxelCount = nnz(mask);
    volumeInfo.voxelVolumeMm3 = prod(double(voxelSpacingMm(:)));
    volumeInfo.volumeMm3 = volumeInfo.voxelCount * volumeInfo.voxelVolumeMm3;
    volumeInfo.volumeCm3 = volumeInfo.volumeMm3 / 1000;
    volumeInfo.volumeMl = volumeInfo.volumeCm3;          % 1 cm^3 = 1 mL
end
