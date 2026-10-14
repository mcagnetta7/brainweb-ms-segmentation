function iouValue = computeIoUFromConfusion(counts)
%COMPUTEIOUFROMCONFUSION Intersection over Union (indice di Jaccard) dai conteggi di confusione.
%
%   iouValue = COMPUTEIOUFROMCONFUSION(counts) usa la struttura prodotta da
%   computeVoxelConfusion (servono solo i campi TP, FP, FN; TN non entra
%   nella formula):
%
%       IoU = TP / (TP + FP + FN) = |pred ∩ GT| / |pred ∪ GT|
%
%   Per insiemi binari IoU e indice di Jaccard sono la stessa misura: questa
%   è l'unica implementazione del progetto.
%
%   Convenzione di progetto per il caso 0/0 (TP = FP = FN = 0, unione vuota):
%   IoU = 1, coerente con la convenzione del Dice (fase 83). È una
%   convenzione implementativa, non una definizione del materiale del corso.
%
%   TP, FP, FN devono essere scalari numerici reali, finiti, non negativi e
%   interi: valori non validi generano un errore (nessun arrotondamento).

    arguments
        counts (1, 1) struct
    end

    required = {'TP', 'FP', 'FN'};
    for f = required
        name = f{1};
        if ~isfield(counts, name)
            error('computeIoUFromConfusion:missingField', 'Confusion counts must contain field %s.', name);
        end
        v = counts.(name);
        if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ~isfinite(v) || v < 0 || v ~= fix(v)
            error('computeIoUFromConfusion:invalidCount', ...
                'Field %s must be a real, finite, non-negative integer scalar.', name);
        end
    end

    intersectionCount = double(counts.TP);
    unionCount = double(counts.TP) + double(counts.FP) + double(counts.FN);
    if unionCount == 0
        iouValue = 1;                            % convenzione: insiemi positivi entrambi vuoti
    else
        iouValue = intersectionCount / unionCount;
    end
end
