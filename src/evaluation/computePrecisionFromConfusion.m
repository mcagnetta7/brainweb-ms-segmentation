function precisionValue = computePrecisionFromConfusion(counts)
%COMPUTEPRECISIONFROMCONFUSION Precision dai conteggi di confusione.
%
%   precisionValue = COMPUTEPRECISIONFROMCONFUSION(counts) usa la struttura
%   prodotta da computeVoxelConfusion (servono solo i campi TP e FP; FN e TN
%   non entrano nella formula):
%
%       Precision = TP / (TP + FP)
%
%   cioè la frazione dei voxel predetti come lesione che sono lesione nel GT.
%
%   Convenzione di progetto per il caso 0/0 (TP = FP = 0, nessun voxel
%   predetto positivo): Precision = 1. Risolve solo il denominatore
%   indefinito e NON indica una rilevazione riuscita. È una convenzione
%   implementativa, non una definizione del materiale del corso.
%
%   TP e FP devono essere scalari numerici reali, finiti, non negativi e
%   interi: valori non validi generano un errore (nessun arrotondamento).

    arguments
        counts (1, 1) struct
    end

    required = {'TP', 'FP'};
    for f = required
        name = f{1};
        if ~isfield(counts, name)
            error('computePrecisionFromConfusion:missingField', 'Confusion counts must contain field %s.', name);
        end
        v = counts.(name);
        if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ~isfinite(v) || v < 0 || v ~= fix(v)
            error('computePrecisionFromConfusion:invalidCount', ...
                'Field %s must be a real, finite, non-negative integer scalar.', name);
        end
    end

    predictedPositive = double(counts.TP) + double(counts.FP);
    if predictedPositive == 0
        precisionValue = 1;                      % convenzione: nessun voxel predetto positivo
    else
        precisionValue = double(counts.TP) / predictedPositive;
    end
end
