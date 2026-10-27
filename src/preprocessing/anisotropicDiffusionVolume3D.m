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
%
%   Nella v4 riceve la T2 normalizzata. Idea della diffusione anisotropa: a ogni
%   iterazione ogni voxel si avvicina alla media dei vicini, ma lo scambio è forte
%   dove la differenza di intensità è piccola (rumore dentro un tessuto) e quasi
%   nullo dove è grande (bordo tra tessuti). Il rumore viene livellato, i bordi delle
%   lesioni restano netti. Con la conduzione esponenziale il coefficiente vale
%   c = exp(-(|grad I| / K)^2), con K = GradientThreshold.

    % --- Validazione degli ingressi ------------------------------------------------
    % Volume 3D di double reali e finiti (niente NaN o infiniti).
    arguments
        volume (:, :, :) double {mustBeReal, mustBeFinite}
    end

    % Valori predefiniti, usati solo nel caso limite di un volume costante.
    filteredVolume = volume;
    gradientThreshold = NaN;
    % Escursione delle intensità del volume (massimo - minimo).
    dynamicRange = max(volume(:)) - min(volume(:));
    % Un volume costante non ha nulla da filtrare (e la soglia sarebbe 0): resta invariato.
    if dynamicRange > 0
        % Soglia del gradiente K = 10 % dell'escursione del volume: le variazioni molto
        % più piccole di K vengono livellate, quelle molto più grandi conservate.
        gradientThreshold = 0.10 * dynamicRange;
        % Diffusione anisotropa sull'intero volume 3D, parametri fissi:
        % 5 iterazioni, connettività massima (26 vicini), conduzione esponenziale.
        filteredVolume = imdiffusefilt(volume, 'GradientThreshold', gradientThreshold, ...
            'NumberOfIterations', 5, 'Connectivity', 'maximal', 'ConductionMethod', 'exponential');
    end
end
