function [filteredVolume, gradientThreshold] = anisotropicDiffusionVolume3D(volume)
%ANISOTROPICDIFFUSIONVOLUME3D Diffusione anisotropa 3D (Perona-Malik) sull'intero volume (EXP-059).
%
%   [filteredVolume, gradientThreshold] = ANISOTROPICDIFFUSIONVOLUME3D(volume)
%   applica imdiffusefilt direttamente al volume 3D, con parametri ESPLICITI
%   e congelati (preregistrazione EXP-059, estensione volumetrica di
%   anisotropicDiffusionSlices):
%       ConductionMethod   "exponential"
%       Connectivity       "maximal"  (26 vicini in 3D)
%       NumberOfIterations 5
%       GradientThreshold  0.10 * (max - min) dell'intero volume
%   Un volume costante (max = min) è restituito invariato (soglia NaN).
%
%   Output: volume double delle stesse dimensioni e la soglia del gradiente
%   usata. Nessuna normalizzazione, soglia o altra elaborazione.

    arguments
        volume (:, :, :) double {mustBeReal, mustBeFinite}
    end

    filteredVolume = volume;
    gradientThreshold = NaN;
    dynamicRange = max(volume(:)) - min(volume(:));
    if dynamicRange > 0
        gradientThreshold = 0.10 * dynamicRange;
        filteredVolume = imdiffusefilt(volume, 'GradientThreshold', gradientThreshold, ...
            'NumberOfIterations', 5, 'Connectivity', 'maximal', 'ConductionMethod', 'exponential');
    end
end
