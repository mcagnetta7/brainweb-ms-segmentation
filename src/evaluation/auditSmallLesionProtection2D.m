function auditTable = auditSmallLesionProtection2D(gtMask, beforeMask, afterMask, connectivity, condition)
%AUDITSMALLLESIONPROTECTION2D Audit 2D delle componenti GT prima/dopo un filtro (fase 70).
%
%   auditTable = AUDITSMALLLESIONPROTECTION2D(gtMask, beforeMask,
%   afterMask, connectivity, condition) scompone il ground truth in
%   componenti connesse 2D (slice assiale per slice, connettività
%   esplicita) e, per ciascuna, misura la sovrapposizione con la previsione
%   PRIMA e DOPO un filtro che può solo rimuovere voxel (after ⊆ before).
%
%   Una componente GT 2D è una sezione di lesione in una slice, NON una
%   lesione 3D unica. newlyCompletelyLost = overlapBefore > 0 e
%   overlapAfter == 0: il filtro ha tolto tutto il supporto previsto per
%   quella sezione. Non è il protocollo finale di valutazione per lesione.
%
%   Funzione di VALUTAZIONE (usa il GT): non genera né modifica previsioni,
%   non filtra, non applica morfologia o soglie. Gli ingressi non vengono
%   modificati.
%
%   Input:
%     gtMask, beforeMask, afterMask  maschere logiche 3D della stessa dimensione
%     connectivity                    connettività 2D: 4 oppure 8
%     condition                       etichetta (string) copiata nella tabella
%
%   Output:
%     auditTable  una riga per componente GT 2D

    if ~islogical(gtMask) || ~islogical(beforeMask) || ~islogical(afterMask) || ndims(gtMask) ~= 3
        error('evaluation:invalidMask', 'All masks must be logical 3D arrays.');
    end
    if ~isequal(size(gtMask), size(beforeMask)) || ~isequal(size(gtMask), size(afterMask))
        error('evaluation:sizeMismatch', 'All masks must have the same size.');
    end
    if any(afterMask & ~beforeMask, 'all')
        error('evaluation:notSubset', 'afterMask must be a subset of beforeMask.');
    end
    if ~(isnumeric(connectivity) && isscalar(connectivity) && ismember(connectivity, [4 8]))
        error('evaluation:invalidConnectivity', 'Connectivity must be explicitly 4 or 8 (2D).');
    end

    rows = cell(size(gtMask, 3), 1);
    for k = 1:size(gtMask, 3)
        gtSlice = gtMask(:, :, k);
        cc = bwconncomp(gtSlice, connectivity);
        n = cc.NumObjects;
        if n == 0
            continue
        end
        beforeSlice = beforeMask(:, :, k);
        afterSlice = afterMask(:, :, k);
        area = zeros(n, 1); overlapBefore = zeros(n, 1); overlapAfter = zeros(n, 1);
        for j = 1:n
            idx = cc.PixelIdxList{j};
            area(j) = numel(idx);
            overlapBefore(j) = nnz(beforeSlice(idx));
            overlapAfter(j) = nnz(afterSlice(idx));
        end
        removedOverlap = overlapBefore - overlapAfter;
        coverageBefore = overlapBefore ./ area;
        coverageAfter = overlapAfter ./ area;
        rows{k} = table(repmat(string(condition), n, 1), repmat(k, n, 1), (1:n).', area, overlapBefore, ...
            overlapAfter, removedOverlap, coverageBefore, coverageAfter, coverageAfter - coverageBefore, ...
            overlapBefore > 0, overlapAfter > 0, removedOverlap > 0, overlapBefore > 0 & overlapAfter == 0, ...
            'VariableNames', {'condition', 'slice', 'gtComponentIndexInSlice', 'gtAreaPixels', 'overlapBefore', ...
            'overlapAfter', 'removedOverlap', 'coverageBefore', 'coverageAfter', 'coverageChange', ...
            'hadSupportBefore', 'hasSupportAfter', 'affectedByFilter', 'newlyCompletelyLost'});
    end
    auditTable = vertcat(rows{:});

end
