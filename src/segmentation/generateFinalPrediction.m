function [M_pred, details] = generateFinalPrediction(rawT1, rawT2)
%GENERATEFINALPREDICTION Predizione della pipeline finale congelata v3 (fase 96).
%
%   [M_pred, details] = GENERATEFINALPREDICTION(rawT1, rawT2) genera la
%   predizione delle lesioni dai volumi MRI grezzi (uint16, 0..4095) di una
%   qualsiasi condizione, usando SOLO la definizione congelata di
%   finalSegmentationConfig e gli helper già selezionati:
%
%     1. normalizzazione fissa 0..4095 -> 0..1 (double) di T1 e T2
%     2. maschera cerebrale EXP-021 generata dal T1 della condizione stessa:
%        initialSupportMask (Otsu globale) -> brainMask3DErodeSelectDilate
%        (sfera 3, componente 3D più grande a 26-connettività, dilatazione
%        AND primo piano, riempimento 2D per slice)
%     3. generateExp059Prediction con la configurazione D3_M1_G0: supporto S2
%        dal T1 non filtrato, diffusione anisotropa 3D del T2, soglia TA dentro
%        S2, una apertura 2D diamond 1 per slice AND S2, nessun filtro sulle
%        componenti
%
%   Non riprogetta la pipeline: compone soltanto passi già validati. Nessun
%   GT, nessuna soglia numerica salvata, nessun accesso a file.
%
%   details: brainMask, brainMaskThreshold, thresholdsNormalized (T1, T2),
%   S2Voxels, finalVoxels, config.

    arguments
        rawT1 (:, :, :) {mustBeNumeric, mustBeReal}
        rawT2 (:, :, :) {mustBeNumeric, mustBeReal}
    end

    finalConfig = finalSegmentationConfig();
    validateFrozenConfig(finalConfig);
    if ~isequal(size(rawT1), size(rawT2))
        error('generateFinalPrediction:sizeMismatch', 'T1 and T2 volumes must have the same size.');
    end

    % 1. Normalizzazione fissa
    normalize = @(raw) normalizeFixedRange(convertToWorkingClass(raw, finalConfig.workingClass), ...
        finalConfig.normalizationInputRange, finalConfig.normalizationOutputRange);
    t1Norm = normalize(rawT1);
    t2Norm = normalize(rawT2);

    % 2. Maschera cerebrale EXP-021 dal T1 della condizione
    [rawForeground, brainMaskThreshold] = initialSupportMask(t1Norm);
    brainMask = brainMask3DErodeSelectDilate(rawForeground, finalConfig.brainMaskRadius, ...
        finalConfig.brainMaskComponentConnectivity);

    % 3. Pipeline v3 = D3_M1_G0
    pipelineConfig = struct('id', finalConfig.sourceConfiguration, 'diffusion', finalConfig.t2FilterId, ...
        'openingType', finalConfig.structuringElement, 'openingParameter', finalConfig.structuringElementParameter, ...
        'componentFilter', finalConfig.componentFilter, 'componentConnectivity', 26, 'minimumOccupiedSlices', 2);
    [M_pred, pipelineDetails] = generateExp059Prediction(t1Norm, t2Norm, brainMask, pipelineConfig);

    details = struct('brainMask', brainMask, 'brainMaskThreshold', brainMaskThreshold, ...
        't1ThresholdsNormalized', pipelineDetails.t1ThresholdsNormalized, ...
        't2ThresholdsNormalized', pipelineDetails.t2ThresholdsNormalized, 'S2Voxels', pipelineDetails.S2Voxels, ...
        'finalVoxels', pipelineDetails.finalVoxels, 'config', finalConfig);
end

function validateFrozenConfig(c)
%VALIDATEFROZENCONFIG Il record congelato deve coincidere con gli helper usati.
%   I valori qui sotto sono quelli implementati da anisotropicDiffusionVolume3D,
%   computeT1AnatomicalSupport, generateLesionCandidateMask e
%   brainMask3DErodeSelectDilate: un record diverso non è la pipeline v3.
    ok = c.version == "v3" && c.sourceConfiguration == "D3_M1_G0" && ~c.heldOutUsedForSelection && ...
        isequal(c.modalities, ["T1" "T2"]) && ~c.pdUsed && c.workingClass == "double" && ...
        isequal(c.normalizationInputRange, [0 4095]) && isequal(c.normalizationOutputRange, [0 1]) && ...
        c.brainMaskRadius == 3 && c.brainMaskComponentConnectivity == 26 && ~c.t1Filtered && ...
        c.t1PartitionNumberOfThresholds == 2 && c.t1LowClass == 1 && c.t1HighClass == 3 && c.support == "S2" && ...
        c.t2FilterId == "D3" && c.gradientThresholdFraction == 0.10 && c.numberOfIterations == 5 && ...
        c.connectivity == "maximal" && c.connectivityNeighbours3D == 26 && c.conductionMethod == "exponential" && ...
        c.t2ThresholdRule == "TA" && c.t2ThresholdNumberOfThresholds == 2 && c.t2SelectedClass == 3 && ...
        c.t2ThresholdEstimatedInside == "S2" && c.morphology == "opening" && c.structuringElement == "diamond" && ...
        c.structuringElementParameter == 1 && c.componentFilter == "none" && c.recovery == "none" && ...
        c.regionGrowing == "none";
    if ~ok
        error('generateFinalPrediction:configMismatch', 'finalSegmentationConfig does not describe the frozen v3 pipeline.');
    end
end
