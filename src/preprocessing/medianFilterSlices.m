function filteredVolume = medianFilterSlices(volume, windowSize, padding)
%MEDIANFILTERSLICES Filtro mediano 2D applicato slice per slice.
%
%   filteredVolume = MEDIANFILTERSLICES(volume, windowSize, padding)
%   applica medfilt2 a ogni slice assiale volume(:,:,k) separatamente
%   (nessun filtraggio tra slice adiacenti, nessun medfilt3) e ricompone
%   il volume.
%
%   Input:
%     volume      volume double già convertito e normalizzato
%     windowSize  dimensioni [m n] dell'intorno, dispari, es. [3 3]
%     padding     gestione dei bordi di medfilt2: "zeros", "symmetric"
%                 o "indexed"
%
%   Output: volume double delle stesse dimensioni. Nessuna conversione,
%   normalizzazione, soglia o altra elaborazione.

    arguments
        volume (:,:,:) double {mustBeReal}
        windowSize (1,2) double {mustBeInteger, mustBePositive}
        padding {mustBeTextScalar, mustBeMember(padding, ["zeros", "symmetric", "indexed"])}
    end

    if any(mod(windowSize, 2) ~= 1)
        error('preprocessing:evenWindowSize', ...
            'Window size must be odd, got [%d %d].', windowSize(1), windowSize(2));
    end

    filteredVolume = zeros(size(volume));
    for k = 1:size(volume, 3)
        filteredVolume(:, :, k) = medfilt2(volume(:, :, k), windowSize, char(padding));
    end

end
