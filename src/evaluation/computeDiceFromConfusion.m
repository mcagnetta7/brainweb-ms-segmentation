function diceValue = computeDiceFromConfusion(counts)
%COMPUTEDICEFROMCONFUSION Coefficiente di Dice dai conteggi di confusione.
%
%   diceValue = COMPUTEDICEFROMCONFUSION(counts) usa la struttura prodotta da
%   computeVoxelConfusion (servono solo i campi TP, FP, FN; TN non entra
%   nella formula):
%
%       Dice = 2*TP / (2*TP + FP + FN)
%
%   Convenzione di progetto per il caso 0/0 (TP = FP = FN = 0, entrambi gli
%   insiemi positivi vuoti): Dice = 1. È una convenzione implementativa,
%   non una definizione del materiale del corso.
%
%   TP, FP, FN devono essere scalari reali, finiti, non negativi e interi:
%   valori non validi generano un errore (nessun arrotondamento).

    arguments
        counts (1, 1) struct
    end

    required = {'TP', 'FP', 'FN'};
    for f = required
        name = f{1};
        if ~isfield(counts, name)
            error('computeDiceFromConfusion:missingField', 'Confusion counts must contain field %s.', name);
        end
        v = counts.(name);
        if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ~isfinite(v) || v < 0 || v ~= fix(v)
            error('computeDiceFromConfusion:invalidCount', ...
                'Field %s must be a real, finite, non-negative integer scalar.', name);
        end
    end

    numerator = 2 * double(counts.TP);
    denominator = 2 * double(counts.TP) + double(counts.FP) + double(counts.FN);
    if denominator == 0
        diceValue = 1;                           % convenzione: insiemi positivi entrambi vuoti
    else
        diceValue = numerator / denominator;
    end
end
