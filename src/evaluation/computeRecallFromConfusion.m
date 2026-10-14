function recallValue = computeRecallFromConfusion(counts)
%COMPUTERECALLFROMCONFUSION Recall (Sensitivity) dai conteggi di confusione.
%
%   recallValue = COMPUTERECALLFROMCONFUSION(counts) usa la struttura
%   prodotta da computeVoxelConfusion (servono solo i campi TP e FN; FP e TN
%   non entrano nella formula):
%
%       Recall = TP / (TP + FN)
%
%   cioè la frazione dei voxel di lesione del GT recuperati dalla predizione
%   (misura per voxel, non per lesione). Recall e Sensitivity sono la stessa
%   misura: questa è l'unica implementazione del progetto.
%
%   Convenzione di progetto per il caso 0/0 (TP = FN = 0, nessun voxel
%   positivo nel GT): Recall = 1. Risolve solo il denominatore indefinito e
%   NON indica una buona predizione. È una convenzione implementativa, non
%   una definizione del materiale del corso.
%
%   TP e FN devono essere scalari numerici reali, finiti, non negativi e
%   interi: valori non validi generano un errore (nessun arrotondamento).

    arguments
        counts (1, 1) struct
    end

    required = {'TP', 'FN'};
    for f = required
        name = f{1};
        if ~isfield(counts, name)
            error('computeRecallFromConfusion:missingField', 'Confusion counts must contain field %s.', name);
        end
        v = counts.(name);
        if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ~isfinite(v) || v < 0 || v ~= fix(v)
            error('computeRecallFromConfusion:invalidCount', ...
                'Field %s must be a real, finite, non-negative integer scalar.', name);
        end
    end

    gtPositive = double(counts.TP) + double(counts.FN);
    if gtPositive == 0
        recallValue = 1;                         % convenzione: nessun voxel positivo nel GT
    else
        recallValue = double(counts.TP) / gtPositive;
    end
end
