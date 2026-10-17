function [predictions, details] = generateV5Predictions(rawT1, rawT2, configs)
%GENERATEV5PREDICTIONS Configurazioni EXP-061: crescita a isteresi dai nuclei della v4.
%
%   [predictions, details] = GENERATEV5PREDICTIONS(rawT1, rawT2, configs) calcola una
%   sola volta le grandezze della v4 (stessi helper congelati: EXP-021, S1 / S2 dal T1
%   non filtrato, D3 sul T2 con controllo di range, TA2 = multithresh(T2f(S2), 2),
%   muWM / sigmaWM in S2 AND T1-alto) e restituisce una predizione per configurazione:
%
%     nuclei C = S2 AND T2f > alta, alta = max(TA2, muWM + 5 sigmaWM)   (soglia v4)
%     opening  "M1": una apertura 2D diamond 1 per slice, AND S2 (= uscita v4)
%              "M0": nessuna apertura
%     growth   "L0": nessuna crescita; "L4" / "L3": bassa = muWM + 4 / 3 sigmaWM,
%              uscita = imreconstruct(nuclei, (Z AND T2f > bassa) OR nuclei, 26)
%     zone     "S2" / "S1" (zona di crescita; irrilevante con L0)
%
%   configs: array di struct con campi id, growth, zone, opening. Nessun GT, nessun file.

    arguments
        rawT1 (:, :, :) {mustBeNumeric, mustBeReal}
        rawT2 (:, :, :) {mustBeNumeric, mustBeReal}
        configs (:, 1) struct
    end

    for c = configs.'
        if ~(ismember(string(c.growth), ["L0" "L4" "L3"]) && ismember(string(c.zone), ["S2" "S1"]) && ...
                ismember(string(c.opening), ["M1" "M0"]))
            error('generateV5Predictions:invalidConfig', 'Configuration "%s" is not in the EXP-061 grid.', string(c.id));
        end
    end
    if ~isequal(size(rawT1), size(rawT2))
        error('generateV5Predictions:sizeMismatch', 'T1 and T2 volumes must have the same size.');
    end

    % Grandezze della v4 (identiche a generateV4Prediction con k = 5)
    normalize = @(raw) normalizeFixedRange(convertToWorkingClass(raw, "double"), [0 4095], [0 1]);
    t1Norm = normalize(rawT1);
    t2Norm = normalize(rawT2);
    [rawForeground, brainMaskThreshold] = initialSupportMask(t1Norm);
    brainMask = brainMask3DErodeSelectDilate(rawForeground, 3, 26);
    [supports, supportDetails] = computeT1AnatomicalSupport(t1Norm, brainMask);
    S1 = supports.S1; S2 = supports.S2;
    t2f = anisotropicDiffusionVolume3D(t2Norm);
    excursion = max([0, -min(t2f(:)), max(t2f(:)) - 1]);
    if excursion > 1e-12
        error('generateV5Predictions:rangeError', 'Diffusion output leaves [0,1] by %g.', excursion);
    end
    t2f = min(max(t2f, 0), 1);
    levels = double(multithresh(t2f(S2), 2));
    t1High = brainMask & imquantize(t1Norm, supportDetails.t1ThresholdsNormalized) == 3;
    reference = t2f(S2 & t1High);
    muWM = mean(reference);
    sigmaWM = std(reference);
    high = max(levels(2), muWM + 5 * sigmaWM);

    cores = S2 & t2f > high;
    opened = false(size(cores));
    se = strel('diamond', 1);
    for slice = 1:size(cores, 3)
        opened(:, :, slice) = imopen(cores(:, :, slice), se);
    end
    opened = opened & S2;

    predictions = cell(numel(configs), 1);
    for i = 1:numel(configs)
        c = configs(i);
        if string(c.opening) == "M1"
            seeds = opened;
        else
            seeds = cores;
        end
        if string(c.growth) == "L0"
            predictions{i} = seeds;
        else
            low = muWM + str2double(extractAfter(string(c.growth), "L")) * sigmaWM;
            if string(c.zone) == "S2"
                zone = S2;
            else
                zone = S1;
            end
            predictions{i} = imreconstruct(seeds, (zone & t2f > low) | seeds, 26);
        end
    end

    details = struct('brainMaskThreshold', brainMaskThreshold, 'taLevels', levels, 'muWM', muWM, ...
        'sigmaWM', sigmaWM, 'high', high, 'low4', muWM + 4 * sigmaWM, 'low3', muWM + 3 * sigmaWM, ...
        'coreVoxels', nnz(cores), 'S1Voxels', nnz(S1), 'S2Voxels', nnz(S2));
end
