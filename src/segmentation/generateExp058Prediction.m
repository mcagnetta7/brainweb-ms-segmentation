function [M_pred, details, intermediate] = generateExp058Prediction(t1Norm, t2Norm, brainMask, config)
%GENERATEEXP058PREDICTION Predizione v2 per una configurazione della griglia EXP-058.
%
%   [M_pred, details, intermediate] = GENERATEEXP058PREDICTION(t1Norm, t2Norm,
%   brainMask, config) applica, nell'ordine:
%     F  nessun filtro / gaussiano sigma 0.5 3x3 replicate / diffusione
%        anisotropa (anisotropicDiffusionSlices), su T1, su T2 o su entrambi;
%        uscita controllata e limitata a [0,1]
%     v1 pipeline congelata S2_TA_M2_G1: supporto S2 dal T1 filtrato
%        (computeT1AnatomicalSupport), TA dentro S2, apertura square 3,
%        rimozione delle componenti 3D su una sola slice (generateExp057Prediction)
%     R  R0 nessuno | R1 imreconstruct(v1, S2 & T2f > TA_S2, 26)
%        | R2 imreconstruct(v1, S1 & T2f > TA_S2, 26); nulla dopo R
%
%   brainMask è la maschera EXP-021 congelata (non ricalcolata). Accetta
%   solo i valori della griglia preregistrata. Nessun GT, nessuna metrica,
%   nessun file.
%
%   config: id, filterType ("none" | "gaussian" | "anisotropic"), filterT1,
%   filterT2 (logici), recovery ("R0" | "R1" | "R2").
%
%   intermediate: S1, S2, v1Prediction, maskR1, maskR2 (per i controlli
%   degli invarianti).

    arguments
        t1Norm (:, :, :) double
        t2Norm (:, :, :) double
        brainMask (:, :, :) logical
        config (1, 1) struct
    end

    validateConfig(config);
    if ~isequal(size(t1Norm), size(t2Norm), size(brainMask)) || ~any(brainMask(:))
        error('generateExp058Prediction:invalidInput', 'T1, T2 and brain mask must match in size; mask non-empty.');
    end

    % F: filtro (dopo /4095, prima di qualsiasi supporto o soglia)
    t1f = t1Norm;
    t2f = t2Norm;
    if config.filterT1
        t1f = applyFilter(t1Norm, config.filterType);
    end
    if config.filterT2
        t2f = applyFilter(t2Norm, config.filterType);
    end

    % v1 congelata, calcolata sui volumi (eventualmente) filtrati
    [supports, supportDetails] = computeT1AnatomicalSupport(t1f, brainMask);
    v1Config = struct('id', "S2_TA_M2_G1", 'supportLevel', "S2", 'thresholdRule', "TA", 'openingType', "square", ...
        'openingParameter', 3, 'componentFilter', "minOccupiedSlices", 'componentConnectivity', 26, ...
        'minimumOccupiedSlices', 2);
    [v1Prediction, v1Details] = generateExp057Prediction(t2f, supports.S2, v1Config);
    taS2 = v1Details.thresholdsNormalized(end);

    % R: ricostruzione morfologica 3D dai nuclei della v1
    maskR1 = supports.S2 & t2f > taS2;
    maskR2 = supports.S1 & t2f > taS2;
    switch config.recovery
        case "R0"
            M_pred = v1Prediction;
        case "R1"
            M_pred = imreconstruct(v1Prediction, maskR1, 26);
        case "R2"
            M_pred = imreconstruct(v1Prediction, maskR2, 26);
    end

    details = struct('configId', string(config.id), 't1ThresholdsNormalized', supportDetails.t1ThresholdsNormalized, ...
        't2ThresholdsNormalized', v1Details.thresholdsNormalized, 'S1Voxels', supportDetails.S1Voxels, ...
        'S2Voxels', supportDetails.S2Voxels, 'v1Voxels', nnz(v1Prediction), 'maskR1Voxels', nnz(maskR1), ...
        'maskR2Voxels', nnz(maskR2), 'finalVoxels', nnz(M_pred));
    intermediate = struct('S1', supports.S1, 'S2', supports.S2, 'v1Prediction', v1Prediction, ...
        'maskR1', maskR1, 'maskR2', maskR2);
end

function filtered = applyFilter(volume, filterType)
%APPLYFILTER Filtro preregistrato, con controllo e limitazione a [0,1].
    if filterType == "gaussian"
        filtered = gaussianFilterSlices(volume, 0.5, 3, "replicate");
    else
        filtered = anisotropicDiffusionSlices(volume);
    end
    % Entrambi i filtri producono medie pesate di valori in [0,1]: possono
    % uscire da [0,1] solo per arrotondamento. Escursioni maggiori sono un errore.
    excursion = max([0, -min(filtered(:)), max(filtered(:)) - 1]);
    if excursion > 1e-12
        error('generateExp058Prediction:rangeError', '%s output leaves [0,1] by %g.', filterType, excursion);
    end
    filtered = min(max(filtered, 0), 1);
end

function validateConfig(c)
%VALIDATECONFIG Accetta solo i valori della griglia EXP-058.
    required = {'id', 'filterType', 'filterT1', 'filterT2', 'recovery'};
    if ~all(isfield(c, required))
        error('generateExp058Prediction:invalidConfig', 'Configuration is missing required fields.');
    end
    okFlags = islogical(c.filterT1) && isscalar(c.filterT1) && islogical(c.filterT2) && isscalar(c.filterT2);
    okF = okFlags && ((string(c.filterType) == "none" && ~c.filterT1 && ~c.filterT2) || ...
        (ismember(string(c.filterType), ["gaussian" "anisotropic"]) && (c.filterT1 || c.filterT2)));
    okR = ismember(string(c.recovery), ["R0" "R1" "R2"]);
    if ~(okF && okR)
        error('generateExp058Prediction:invalidConfig', 'Configuration "%s" is not part of the EXP-058 grid.', string(c.id));
    end
end
