function [thresholdVoxels, sizeClass] = classifyGtLesionSizes(gtLesionVoxels)
%CLASSIFYGTLESIONSIZES Classi SMALL / LARGE delle lesioni GT dalla mediana delle dimensioni.
%
%   [thresholdVoxels, sizeClass] = CLASSIFYGTLESIONSIZES(gtLesionVoxels)
%   riceve SOLO il vettore delle dimensioni (voxel) delle componenti GT e
%   restituisce la soglia (mediana) e, per ogni lesione, "SMALL" se la
%   dimensione è <= mediana, "LARGE" se è > mediana. Le lesioni uguali alla
%   mediana restano tutte SMALL (nessuna suddivisione artificiale).
%
%   La funzione non riceve predizioni, esiti di rilevazione o
%   sovrapposizioni: la soglia non può dipendere dalla segmentazione. È una
%   suddivisione diagnostica relativa a questo dataset, non clinica, e non
%   deve mai diventare una soglia di segmentazione o di filtro.

    arguments
        gtLesionVoxels {mustBeNumeric}
    end

    v = gtLesionVoxels(:);
    if isempty(v) || ~isreal(v) || any(~isfinite(v)) || any(v <= 0) || any(v ~= fix(v))
        error('classifyGtLesionSizes:invalidSizes', ...
            'GT lesion sizes must be a non-empty vector of positive finite integers.');
    end

    thresholdVoxels = median(double(v));
    sizeClass = repmat("SMALL", numel(v), 1);
    sizeClass(v > thresholdVoxels) = "LARGE";
    sizeClass = reshape(sizeClass, size(gtLesionVoxels));
end
