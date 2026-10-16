function [M_pred, details] = generateExp059Prediction(t1Norm, t2Norm, brainMask, config)
%GENERATEEXP059PREDICTION Predizione v3 per una configurazione della griglia EXP-059.
%
%   [M_pred, details] = GENERATEEXP059PREDICTION(t1Norm, t2Norm, brainMask,
%   config) applica, nell'ordine:
%     D  diffusione anisotropa del T2: D2 per slice (anisotropicDiffusionSlices,
%        = v2) oppure D3 sull'intero volume (anisotropicDiffusionVolume3D);
%        uscita controllata e limitata a [0,1]
%     supporto S2 dal T1 NON filtrato (computeT1AnatomicalSupport)
%     TA dentro S2 sul T2 filtrato, poi M (nessuna apertura / diamond 1 /
%     square 3, per slice, AND S2) e G (nessuna / rimozione delle componenti
%     3D su una sola slice), tramite generateExp057Prediction
%
%   brainMask è la maschera EXP-021 congelata. Accetta solo i valori della
%   griglia preregistrata. Nessun GT, nessuna metrica, nessun file.
%
%   config: id, diffusion ("D2" | "D3"), openingType, openingParameter,
%   componentFilter, componentConnectivity, minimumOccupiedSlices.

    arguments
        t1Norm (:, :, :) double
        t2Norm (:, :, :) double
        brainMask (:, :, :) logical
        config (1, 1) struct
    end

    required = {'id', 'diffusion', 'openingType', 'openingParameter', 'componentFilter', ...
        'componentConnectivity', 'minimumOccupiedSlices'};
    if ~all(isfield(config, required)) || ~ismember(string(config.diffusion), ["D2" "D3"])
        error('generateExp059Prediction:invalidConfig', 'Configuration is not part of the EXP-059 grid.');
    end
    if ~isequal(size(t1Norm), size(t2Norm), size(brainMask)) || ~any(brainMask(:))
        error('generateExp059Prediction:invalidInput', 'T1, T2 and brain mask must match in size; mask non-empty.');
    end

    % D: diffusione anisotropa del solo T2
    if string(config.diffusion) == "D2"
        t2f = anisotropicDiffusionSlices(t2Norm);
    else
        t2f = anisotropicDiffusionVolume3D(t2Norm);
    end
    excursion = max([0, -min(t2f(:)), max(t2f(:)) - 1]);
    if excursion > 1e-12
        error('generateExp059Prediction:rangeError', 'Diffusion output leaves [0,1] by %g.', excursion);
    end
    t2f = min(max(t2f, 0), 1);

    % Supporto S2 (T1 non filtrato) e pipeline TA / M / G della griglia
    [supports, supportDetails] = computeT1AnatomicalSupport(t1Norm, brainMask);
    pipelineConfig = struct('id', string(config.id), 'supportLevel', "S2", 'thresholdRule', "TA", ...
        'openingType', config.openingType, 'openingParameter', config.openingParameter, ...
        'componentFilter', config.componentFilter, 'componentConnectivity', config.componentConnectivity, ...
        'minimumOccupiedSlices', config.minimumOccupiedSlices);
    [M_pred, pipelineDetails] = generateExp057Prediction(t2f, supports.S2, pipelineConfig);

    details = struct('configId', string(config.id), 't1ThresholdsNormalized', supportDetails.t1ThresholdsNormalized, ...
        't2ThresholdsNormalized', pipelineDetails.thresholdsNormalized, 'S2Voxels', supportDetails.S2Voxels, ...
        'candidateVoxels', pipelineDetails.candidateVoxels, 'afterMorphologyVoxels', pipelineDetails.afterMorphologyVoxels, ...
        'finalVoxels', pipelineDetails.finalVoxels, 'removedComponents', pipelineDetails.removedComponents);
end
