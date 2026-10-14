function [M_pred, details] = generateExp057Prediction(t2Norm, support, config)
%GENERATEEXP057PREDICTION Predizione T2 dentro un supporto anatomico (griglia EXP-057).
%
%   [M_pred, details] = GENERATEEXP057PREDICTION(t2Norm, support, config)
%   applica, dentro il supporto scelto (S0 / S1 / S2, calcolato a parte da
%   computeT1AnatomicalSupport):
%     T  TA: multithresh(t2Norm(support), 2), classe più alta
%           (generateLesionCandidateMask);
%        TB: graythresh(t2Norm(support)), voxel > soglia, dentro il supporto
%        (la soglia è sempre stimata dai soli voxel del supporto)
%     M  nessuna / una apertura 2D diamond 1 / square 3 per slice, poi AND support
%     G  nessuna / rimozione delle componenti 3D (26) su una sola slice
%
%   Accetta solo i valori della griglia preregistrata. Nessun GT, nessuna
%   metrica, nessun file.
%
%   config: id, supportLevel ("S0" | "S1" | "S2"), thresholdRule ("TA" | "TB"),
%   openingType, openingParameter, componentFilter, componentConnectivity,
%   minimumOccupiedSlices.

    arguments
        t2Norm (:, :, :) double
        support (:, :, :) logical
        config (1, 1) struct
    end

    validateConfig(config);
    if ~isequal(size(t2Norm), size(support)) || ~any(support(:))
        error('generateExp057Prediction:invalidInput', 'Volume and support must match in size; support non-empty.');
    end

    % T: soglia stimata dentro il supporto
    if config.thresholdRule == "TA"
        segmentationConfig = struct('thresholdMethod', "multithresh", 'multithresh', ...
            struct('numberOfThresholds', 2, 'candidateClass', 3));
        [candidate, thresholdDetails] = generateLesionCandidateMask(t2Norm, support, segmentationConfig);
        thresholds = thresholdDetails.thresholdsNormalized;
    else
        thresholds = graythresh(t2Norm(support));
        candidate = support & t2Norm > thresholds;
    end

    % M: una sola apertura 2D per slice
    if config.openingType == "none"
        opened = candidate;
    else
        se = strel(char(config.openingType), config.openingParameter);
        opened = false(size(candidate));
        for k = 1:size(candidate, 3)
            opened(:, :, k) = imopen(candidate(:, :, k), se);
        end
        opened = opened & support;
    end

    % G: regola geometrica 3D generica
    if config.componentFilter == "none"
        M_pred = opened;
        removed = 0;
    else
        [M_pred, componentDetails] = removeSingleSliceComponents3D(opened, config.componentConnectivity, ...
            config.minimumOccupiedSlices);
        removed = componentDetails.removedComponentCount;
    end

    details = struct('configId', string(config.id), 'thresholdsNormalized', thresholds, ...
        'supportVoxels', nnz(support), 'candidateVoxels', nnz(candidate), 'afterMorphologyVoxels', nnz(opened), ...
        'finalVoxels', nnz(M_pred), 'removedComponents', removed);
end

function validateConfig(c)
%VALIDATECONFIG Accetta solo i valori della griglia EXP-057.
    required = {'id', 'supportLevel', 'thresholdRule', 'openingType', 'openingParameter', 'componentFilter', ...
        'componentConnectivity', 'minimumOccupiedSlices'};
    if ~all(isfield(c, required))
        error('generateExp057Prediction:invalidConfig', 'Configuration is missing required fields.');
    end
    okS = ismember(string(c.supportLevel), ["S0" "S1" "S2"]);
    okT = ismember(string(c.thresholdRule), ["TA" "TB"]);
    okM = (string(c.openingType) == "none") || (string(c.openingType) == "diamond" && c.openingParameter == 1) || ...
        (string(c.openingType) == "square" && c.openingParameter == 3);
    okG = (string(c.componentFilter) == "none") || (string(c.componentFilter) == "minOccupiedSlices" && ...
        c.componentConnectivity == 26 && c.minimumOccupiedSlices == 2);
    if ~(okS && okT && okM && okG)
        error('generateExp057Prediction:invalidConfig', 'Configuration "%s" is not part of the EXP-057 grid.', string(c.id));
    end
end
