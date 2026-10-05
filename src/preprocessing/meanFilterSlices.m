function filteredVolume = meanFilterSlices(volume, windowSize, padding)
%MEANFILTERSLICES Filtro di media (moving average) 2D applicato slice per slice.
%
%   filteredVolume = MEANFILTERSLICES(volume, windowSize, padding) filtra
%   ogni slice assiale volume(:,:,k) separatamente con imfilter e il
%   kernel fspecial('average', windowSize), in cui tutti i pixel
%   dell'intorno hanno lo stesso peso. Nessun filtraggio tra slice
%   adiacenti.
%
%   Input:
%     volume      volume double già convertito e normalizzato
%     windowSize  dimensioni [m n] dell'intorno, dispari, es. [3 3]
%     padding     gestione dei bordi di imfilter, es. "replicate"
%
%   Output: volume double delle stesse dimensioni. Nessuna conversione,
%   normalizzazione, soglia o altra elaborazione.

    arguments
        volume (:,:,:) double {mustBeReal}
        windowSize (1,2) double {mustBeInteger, mustBePositive}
        padding {mustBeTextScalar, mustBeMember(padding, ["replicate", "symmetric", "circular"])}
    end

    if any(mod(windowSize, 2) ~= 1)
        error('preprocessing:evenWindowSize', ...
            'Window size must be odd, got [%d %d].', windowSize(1), windowSize(2));
    end

    kernel = fspecial('average', windowSize);

    filteredVolume = zeros(size(volume));
    for k = 1:size(volume, 3)
        filteredVolume(:, :, k) = imfilter(volume(:, :, k), kernel, char(padding));
    end

end
