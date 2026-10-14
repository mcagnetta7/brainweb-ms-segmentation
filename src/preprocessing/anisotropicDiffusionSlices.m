function [filteredVolume, gradientThresholds] = anisotropicDiffusionSlices(volume)
%ANISOTROPICDIFFUSIONSLICES Diffusione anisotropa 2D (Perona-Malik) slice per slice (EXP-058).
%
%   [filteredVolume, gradientThresholds] = ANISOTROPICDIFFUSIONSLICES(volume)
%   applica imdiffusefilt a ogni slice assiale volume(:,:,k) separatamente,
%   con parametri ESPLICITI e congelati (preregistrazione EXP-058):
%       ConductionMethod   "exponential"
%       Connectivity       "maximal"  (8 vicini in 2D)
%       NumberOfIterations 5
%       GradientThreshold  0.10 * (max - min) della slice
%   Le slice costanti (max = min) sono restituite invariate: la diffusione
%   di un'immagine costante è l'identità, e si evita una soglia nulla.
%
%   Output: volume double delle stesse dimensioni e, per ogni slice, la
%   soglia del gradiente usata (NaN per le slice costanti). Nessuna
%   normalizzazione, soglia o altra elaborazione.

    arguments
        volume (:, :, :) double {mustBeReal, mustBeFinite}
    end

    filteredVolume = volume;
    gradientThresholds = NaN(1, size(volume, 3));
    for k = 1:size(volume, 3)
        slice = volume(:, :, k);
        dynamicRange = max(slice(:)) - min(slice(:));
        if dynamicRange > 0
            gradientThresholds(k) = 0.10 * dynamicRange;
            filteredVolume(:, :, k) = imdiffusefilt(slice, 'GradientThreshold', gradientThresholds(k), ...
                'NumberOfIterations', 5, 'Connectivity', 'maximal', 'ConductionMethod', 'exponential');
        end
    end
end
