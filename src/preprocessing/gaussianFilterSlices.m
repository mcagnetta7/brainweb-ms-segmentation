function filteredVolume = gaussianFilterSlices(volume, sigma, filterSize, padding)
%GAUSSIANFILTERSLICES Filtro gaussiano 2D applicato slice per slice.
%
%   filteredVolume = GAUSSIANFILTERSLICES(volume, sigma, filterSize,
%   padding) applica imgaussfilt a ogni slice assiale volume(:,:,k)
%   separatamente (nessun filtraggio tra slice adiacenti, nessun
%   imgaussfilt3) e ricompone il volume.
%
%   Input:
%     volume      volume double già convertito e normalizzato
%     sigma       deviazione standard del kernel, in pixel
%     filterSize  dimensione del kernel (dispari), es. 3 per 3x3
%     padding     gestione dei bordi di imgaussfilt, es. "replicate"
%
%   Output: volume double delle stesse dimensioni. Nessuna conversione,
%   normalizzazione, soglia o altra elaborazione.

    arguments
        volume (:,:,:) double {mustBeReal}
        sigma (1,1) double {mustBePositive, mustBeFinite}
        filterSize (1,1) double {mustBeInteger, mustBePositive}
        padding {mustBeTextScalar}
    end

    if mod(filterSize, 2) ~= 1
        error('preprocessing:evenFilterSize', ...
            'Filter size must be odd, got %d.', filterSize);
    end

    filteredVolume = zeros(size(volume));
    for k = 1:size(volume, 3)
        filteredVolume(:, :, k) = imgaussfilt(volume(:, :, k), sigma, ...
            'FilterSize', filterSize, 'Padding', char(padding));
    end

end
