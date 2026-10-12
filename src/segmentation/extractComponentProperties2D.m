function componentTable = extractComponentProperties2D(ccBySlice, condition)
%EXTRACTCOMPONENTPROPERTIES2D Proprietà delle componenti connesse 2D già identificate (fase 68).
%
%   componentTable = EXTRACTCOMPONENTPROPERTIES2D(ccBySlice, condition)
%   applica regionprops alle strutture bwconncomp ESISTENTI (fase 67), slice
%   per slice, con esattamente le proprietà Area, Centroid e BoundingBox, e
%   restituisce una riga per istanza di componente 2D.
%
%   Convenzioni MATLAB (immagine 2D righe x colonne):
%   - Centroid = [x, y] con x = coordinata di colonna, y = coordinata di riga
%     (salvate come centroidX, centroidY, senza conversioni);
%   - BoundingBox = [x, y, larghezza, altezza] con origine al bordo esterno
%     del primo pixel (es. colonna minima - 0.5).
%   componentIndexInSlice è l'ordine di PixelIdxList, locale alla slice: non
%   identifica una lesione 3D.
%
%   La funzione non ricalcola le componenti (nessun bwconncomp), non usa
%   ground truth, non filtra, non classifica, non riordina e non calcola
%   statistiche d'intensità. Gli ingressi non vengono modificati.
%
%   Input:
%     ccBySlice  cell array di strutture bwconncomp (una per slice)
%     condition  etichetta della condizione (string), copiata nella tabella
%
%   Output:
%     componentTable  tabella con condition, slice, componentIndexInSlice,
%                     areaPixels, centroidX, centroidY, boundingBoxX,
%                     boundingBoxY, boundingBoxWidth, boundingBoxHeight

    if ~iscell(ccBySlice)
        error('segmentation:invalidComponents', 'ccBySlice must be a cell array of bwconncomp structures.');
    end
    properties = {'Area', 'Centroid', 'BoundingBox'};
    rows = cell(numel(ccBySlice), 1);
    for k = 1:numel(ccBySlice)
        cc = ccBySlice{k};
        stats = regionprops(cc, properties{:});
        if ~isequal(fieldnames(stats).', properties)
            error('segmentation:unexpectedProperties', 'regionprops returned unexpected fields in slice %d.', k);
        end
        n = numel(stats);
        if n == 0
            continue
        end
        centroid = vertcat(stats.Centroid);
        box = vertcat(stats.BoundingBox);
        rows{k} = table(repmat(string(condition), n, 1), repmat(k, n, 1), (1:n).', [stats.Area].', ...
            centroid(:, 1), centroid(:, 2), box(:, 1), box(:, 2), box(:, 3), box(:, 4), ...
            'VariableNames', {'condition', 'slice', 'componentIndexInSlice', 'areaPixels', 'centroidX', ...
            'centroidY', 'boundingBoxX', 'boundingBoxY', 'boundingBoxWidth', 'boundingBoxHeight'});
    end
    componentTable = vertcat(rows{:});
    if isempty(componentTable)
        componentTable = table(strings(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
            zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), 'VariableNames', {'condition', 'slice', ...
            'componentIndexInSlice', 'areaPixels', 'centroidX', 'centroidY', 'boundingBoxX', 'boundingBoxY', ...
            'boundingBoxWidth', 'boundingBoxHeight'});
    end

end
