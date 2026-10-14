function [M_pred, details] = generatePhase95Prediction(volumeNorm, brainMask, config)
%GENERATEPHASE95PREDICTION Predizione per una configurazione della griglia della fase 95.
%
%   [M_pred, details] = GENERATEPHASE95PREDICTION(volumeNorm, brainMask,
%   config) applica, nell'ordine:
%     P  filtro gaussiano 2D per slice (gaussianFilterSlices) oppure nessuno
%     T  multithresh(volume(brainMask), N) -> classe più alta, dentro
%        brainMask (generateLesionCandidateMask)
%     M  una apertura 2D assiale per slice (diamond 1 o square 3) oppure
%        nessuna, poi AND brainMask
%     G  rimozione delle componenti 3D (connettività 26) che occupano una
%        sola slice (removeSingleSliceComponents3D) oppure nessuna
%
%   Il comportamento dipende SOLO da config; sono accettati solo i valori
%   della griglia preregistrata (EXP-056). La funzione non usa il GT, non
%   calcola metriche, non legge né salva file.
%
%   config: id, gaussianEnabled, gaussianSigma, gaussianFilterSize,
%   gaussianPadding, numberOfThresholds, selectedHighestClass, openingType
%   ("none" | "diamond" | "square"), openingParameter, componentFilter
%   ("none" | "minOccupiedSlices"), componentConnectivity,
%   minimumOccupiedSlices.

    arguments
        volumeNorm (:, :, :) double
        brainMask (:, :, :) logical
        config (1, 1) struct
    end

    validateConfig(config);
    if ~isequal(size(volumeNorm), size(brainMask))
        error('generatePhase95Prediction:sizeMismatch', 'Volume and brain mask must have the same size.');
    end

    % P: preprocessing
    if config.gaussianEnabled
        thresholdInput = gaussianFilterSlices(volumeNorm, config.gaussianSigma, config.gaussianFilterSize, ...
            config.gaussianPadding);
        % Media pesata di valori in [0,1]: può uscire da [0,1] solo per
        % arrotondamento (~1e-16). Escursioni maggiori sono un errore.
        excursion = max([0, -min(thresholdInput(:)), max(thresholdInput(:)) - 1]);
        if excursion > 1e-12
            error('generatePhase95Prediction:rangeError', 'Gaussian output leaves [0,1] by %g.', excursion);
        end
        thresholdInput = min(max(thresholdInput, 0), 1);
    else
        thresholdInput = volumeNorm;
    end

    % T: soglia automatica, classe più alta
    segmentationConfig = struct('thresholdMethod', "multithresh", 'multithresh', ...
        struct('numberOfThresholds', config.numberOfThresholds, 'candidateClass', config.selectedHighestClass));
    [candidate, thresholdDetails] = generateLesionCandidateMask(thresholdInput, brainMask, segmentationConfig);

    % M: morfologia (una sola apertura 2D per slice)
    if config.openingType == "none"
        opened = candidate;
    else
        se = strel(char(config.openingType), config.openingParameter);
        opened = false(size(candidate));
        for k = 1:size(candidate, 3)
            opened(:, :, k) = imopen(candidate(:, :, k), se);
        end
        opened = opened & brainMask;
    end

    % G: regola geometrica 3D generica
    if config.componentFilter == "none"
        M_pred = opened;
        componentDetails = struct('componentCount', NaN, 'removedComponentCount', 0, 'keptComponentCount', NaN, ...
            'removedVoxels', 0);
    else
        [M_pred, componentDetails] = removeSingleSliceComponents3D(opened, config.componentConnectivity, ...
            config.minimumOccupiedSlices);
    end

    details = struct('configId', string(config.id), 'thresholdsNormalized', thresholdDetails.thresholdsNormalized, ...
        'candidateVoxels', nnz(candidate), 'afterMorphologyVoxels', nnz(opened), 'finalVoxels', nnz(M_pred), ...
        'componentDetails', componentDetails);
end

function validateConfig(c)
%VALIDATECONFIG Accetta solo i valori della griglia preregistrata della fase 95.
    required = {'id', 'gaussianEnabled', 'gaussianSigma', 'gaussianFilterSize', 'gaussianPadding', ...
        'numberOfThresholds', 'selectedHighestClass', 'openingType', 'openingParameter', 'componentFilter', ...
        'componentConnectivity', 'minimumOccupiedSlices'};
    if ~all(isfield(c, required))
        error('generatePhase95Prediction:invalidConfig', 'Configuration is missing required fields.');
    end
    okP = (~c.gaussianEnabled) || (c.gaussianSigma == 0.5 && c.gaussianFilterSize == 3 && string(c.gaussianPadding) == "replicate");
    okT = ismember(c.numberOfThresholds, [2 3]) && c.selectedHighestClass == c.numberOfThresholds + 1;
    okM = (string(c.openingType) == "none") || (string(c.openingType) == "diamond" && c.openingParameter == 1) || ...
        (string(c.openingType) == "square" && c.openingParameter == 3);
    okG = (string(c.componentFilter) == "none") || (string(c.componentFilter) == "minOccupiedSlices" && ...
        c.componentConnectivity == 26 && c.minimumOccupiedSlices == 2);
    if ~(islogical(c.gaussianEnabled) && okP && okT && okM && okG)
        error('generatePhase95Prediction:invalidConfig', 'Configuration "%s" is not part of the EXP-056 grid.', string(c.id));
    end
end
