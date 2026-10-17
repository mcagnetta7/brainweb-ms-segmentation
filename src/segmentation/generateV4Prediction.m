function [M_pred, details] = generateV4Prediction(rawT1, rawT2, k)
%GENERATEV4PREDICTION Pipeline v3 con soglia minima riferita alla sostanza bianca (EXP-060, v4).
%
%   [M_pred, details] = GENERATEV4PREDICTION(rawT1, rawT2, k) ripete la pipeline
%   congelata v3 (D3_M1_G0) con gli stessi helper, cambiando solo la soglia del T2:
%
%       soglia = max(TA livello 2, muWM + k * sigmaWM)
%
%   dove muWM e sigmaWM sono media e deviazione standard (std, N-1) del T2 filtrato
%   (D3) dentro S2 AND T1-alto (classe 3 della partizione T1 congelata): riferimento
%   ricavato dall'immagine, senza GT. Con k = NaN la soglia è TA livello 2 (= v3).
%
%   Passi: normalizzazione fissa 0..4095 -> 0..1; maschera EXP-021 (initialSupportMask,
%   brainMask3DErodeSelectDilate sfera 3, 26); S2 (computeT1AnatomicalSupport, T1 non
%   filtrato); D3 (anisotropicDiffusionVolume3D, controllo e limitazione a [0,1]);
%   TA = multithresh(T2f(S2), 2); candidato = S2 AND T2f > soglia; una apertura 2D
%   diamond 1 per slice, AND S2. Nessun GT, nessun accesso a file.
%
%   k: NaN (nessun minimo) oppure uno scalare della griglia preregistrata {3, 4, 5, 6}.

    arguments
        rawT1 (:, :, :) {mustBeNumeric, mustBeReal}
        rawT2 (:, :, :) {mustBeNumeric, mustBeReal}
        k (1, 1) double
    end

    if ~(isnan(k) || ismember(k, [3 4 5 6]))
        error('generateV4Prediction:invalidK', 'k must be NaN or one of 3, 4, 5, 6 (EXP-060 grid).');
    end
    if ~isequal(size(rawT1), size(rawT2))
        error('generateV4Prediction:sizeMismatch', 'T1 and T2 volumes must have the same size.');
    end

    normalize = @(raw) normalizeFixedRange(convertToWorkingClass(raw, "double"), [0 4095], [0 1]);
    t1Norm = normalize(rawT1);
    t2Norm = normalize(rawT2);

    [rawForeground, brainMaskThreshold] = initialSupportMask(t1Norm);
    brainMask = brainMask3DErodeSelectDilate(rawForeground, 3, 26);
    [supports, supportDetails] = computeT1AnatomicalSupport(t1Norm, brainMask);
    S2 = supports.S2;

    t2f = anisotropicDiffusionVolume3D(t2Norm);
    excursion = max([0, -min(t2f(:)), max(t2f(:)) - 1]);
    if excursion > 1e-12
        error('generateV4Prediction:rangeError', 'Diffusion output leaves [0,1] by %g.', excursion);
    end
    t2f = min(max(t2f, 0), 1);

    levels = double(multithresh(t2f(S2), 2));
    t1High = brainMask & imquantize(t1Norm, supportDetails.t1ThresholdsNormalized) == 3;
    reference = t2f(S2 & t1High);
    muWM = mean(reference);
    sigmaWM = std(reference);
    if isnan(k)
        floorValue = NaN;
        threshold = levels(2);
    else
        floorValue = muWM + k * sigmaWM;
        threshold = max(levels(2), floorValue);
    end

    candidate = S2 & t2f > threshold;
    opened = false(size(candidate));
    se = strel('diamond', 1);
    for slice = 1:size(candidate, 3)
        opened(:, :, slice) = imopen(candidate(:, :, slice), se);
    end
    M_pred = opened & S2;

    details = struct('k', k, 'brainMaskThreshold', brainMaskThreshold, ...
        't1ThresholdsNormalized', supportDetails.t1ThresholdsNormalized, 'taLevels', levels, ...
        'muWM', muWM, 'sigmaWM', sigmaWM, 'referenceVoxels', numel(reference), 'floorValue', floorValue, ...
        'threshold', threshold, 'floorActive', ~isnan(k) && floorValue > levels(2), ...
        'candidateVoxels', nnz(candidate), 'finalVoxels', nnz(M_pred), 'S2Voxels', nnz(S2), 'S2', S2);
end
