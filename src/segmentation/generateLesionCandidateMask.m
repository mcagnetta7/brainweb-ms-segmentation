function [candidateMask, details] = generateLesionCandidateMask(t2Norm, brainMask, segmentationConfig)
%GENERATELESIONCANDIDATEMASK Maschera dei candidati con il metodo di soglia selezionato (fase 60).
%
%   [candidateMask, details] = GENERATELESIONCANDIDATEMASK(t2Norm,
%   brainMask, segmentationConfig) applica il metodo selezionato nella
%   fase 58 (EXP-026), Otsu multi-livello:
%
%       levels        = multithresh(t2Norm(brainMask), N)
%       classVolume   = imquantize(t2Norm, levels)
%       candidateMask = brainMask & (classVolume == N + 1)
%
%   con N = segmentationConfig.multithresh.numberOfThresholds e classe
%   candidata segmentationConfig.multithresh.candidateClass (la più alta).
%   Le soglie sono stimate per ogni volume dai soli valori dentro la
%   maschera e non vengono modificate.
%
%   candidateMask è una maschera di CANDIDATI, non la segmentazione finale
%   delle lesioni.
%
%   La funzione non carica file, non conosce la condizione di rumore, non
%   usa ground truth, T1 o PD, non calcola metriche e non applica
%   morfologia, analisi delle componenti o region growing. Gli ingressi non
%   vengono modificati.
%
%   Input:
%     t2Norm              volume T2 reale finito normalizzato in [0,1]
%     brainMask           maschera logica con le stesse dimensioni (EXP-021)
%     segmentationConfig  cfg.segmentation (thresholdMethod = "multithresh")
%
%   Output:
%     candidateMask  maschera logica dei candidati
%     details        struct: thresholdsNormalized, numberOfThresholds,
%                    numberOfClasses, selectedClass, classCounts (classi
%                    1..N+1 dentro brainMask), brainMaskVoxels

    if ~(isnumeric(t2Norm) && isreal(t2Norm))
        error('segmentation:invalidVolume', 'Volume must be a real numeric array.');
    end
    if any(~isfinite(t2Norm(:)))
        error('segmentation:invalidVolume', 'Volume must contain only finite values.');
    end
    if isempty(t2Norm) || min(t2Norm(:)) < 0 || max(t2Norm(:)) > 1
        error('segmentation:invalidVolume', 'Volume values must lie in the normalized domain [0, 1].');
    end
    if ~islogical(brainMask)
        error('segmentation:invalidMask', 'Brain mask must be a logical array.');
    end
    if ~isequal(size(t2Norm), size(brainMask))
        error('segmentation:sizeMismatch', 'Volume size [%s] differs from brain-mask size [%s].', ...
            num2str(size(t2Norm)), num2str(size(brainMask)));
    end
    if ~any(brainMask(:))
        error('segmentation:emptyMask', 'Brain mask is empty.');
    end
    if string(segmentationConfig.thresholdMethod) ~= "multithresh"
        error('segmentation:unsupportedMethod', 'Unsupported threshold method "%s".', ...
            segmentationConfig.thresholdMethod);
    end
    numberOfThresholds = segmentationConfig.multithresh.numberOfThresholds;
    selectedClass = segmentationConfig.multithresh.candidateClass;
    if selectedClass ~= numberOfThresholds + 1
        error('segmentation:invalidClass', 'The candidate class must be the highest class (%d).', ...
            numberOfThresholds + 1);
    end

    levels = double(multithresh(t2Norm(brainMask), numberOfThresholds));
    if numel(levels) ~= numberOfThresholds || any(~isfinite(levels)) || any(diff(levels) <= 0)
        error('segmentation:invalidThresholds', 'multithresh did not return %d finite increasing thresholds.', ...
            numberOfThresholds);
    end
    classVolume = imquantize(t2Norm, levels);
    candidateMask = brainMask & (classVolume == selectedClass);

    classCounts = zeros(1, numberOfThresholds + 1);
    for c = 1:numberOfThresholds + 1
        classCounts(c) = nnz(brainMask & (classVolume == c));
    end
    details = struct('thresholdsNormalized', levels, 'numberOfThresholds', numberOfThresholds, ...
        'numberOfClasses', numberOfThresholds + 1, 'selectedClass', selectedClass, ...
        'classCounts', classCounts, 'brainMaskVoxels', nnz(brainMask));

end
