function specificityValue = computeSpecificityFromConfusion(counts)
%COMPUTESPECIFICITYFROMCONFUSION Specificity dai conteggi di confusione.
%
%   specificityValue = COMPUTESPECIFICITYFROMCONFUSION(counts) usa la
%   struttura prodotta da computeVoxelConfusion (servono solo i campi TN e
%   FP; TP e FN non entrano nella formula):
%
%       Specificity = TN / (TN + FP)
%
%   cioè la frazione dei voxel non-lesione del GT classificati come
%   non-lesione. Con classi molto sbilanciate non va letta da sola né come
%   accuratezza complessiva.
%
%   Convenzione di progetto per il caso 0/0 (TN = FP = 0, nessun voxel
%   negativo nel GT): Specificity = 1. Non indica una buona segmentazione.
%   È una convenzione implementativa, non una definizione del materiale
%   del corso.
%
%   TN e FP devono essere scalari numerici reali, finiti, non negativi e
%   interi: valori non validi generano un errore (nessun arrotondamento).

    arguments
        counts (1, 1) struct
    end

    required = {'TN', 'FP'};
    for f = required
        name = f{1};
        if ~isfield(counts, name)
            error('computeSpecificityFromConfusion:missingField', 'Confusion counts must contain field %s.', name);
        end
        v = counts.(name);
        if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ~isfinite(v) || v < 0 || v ~= fix(v)
            error('computeSpecificityFromConfusion:invalidCount', ...
                'Field %s must be a real, finite, non-negative integer scalar.', name);
        end
    end

    gtNegative = double(counts.TN) + double(counts.FP);
    if gtNegative == 0
        specificityValue = 1;                    % convenzione: nessun voxel negativo nel GT
    else
        specificityValue = double(counts.TN) / gtNegative;
    end
end
