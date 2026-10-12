%% Fase 68: controllo di extractComponentProperties2D (solo dati sintetici)
% Verifica Area, Centroid e BoundingBox su componenti sintetiche note.
% Solo piccoli volumi artificiali: nessun dato BrainWeb, nessun ground
% truth, nessun filtraggio.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);

checks = cell(0, 2);

% Slice 1: pixel isolato in riga 3, colonna 4; slice 2: rettangolo pieno
% righe 5..7, colonne 2..5 (3 x 4 = 12 pixel) e un secondo pixel isolato;
% slice 3: vuota; slice 4: pixel nella stessa posizione della slice 1
mask = false(10, 12, 4);
mask(3, 4, 1) = true;
mask(5:7, 2:5, 2) = true; mask(1, 11, 2) = true;
mask(3, 4, 4) = true;
cc = cell(4, 1);
for k = 1:4
    cc{k} = bwconncomp(mask(:, :, k), 8);
end
ccCopy = cc;

t = extractComponentProperties2D(cc, "synthetic");
functionText = fileread(fullfile(cfg.paths.segmentation, 'extractComponentProperties2D.m'));

checks(end+1, :) = {"exactly Area, Centroid, BoundingBox requested", ...
    contains(functionText, "properties = {'Area', 'Centroid', 'BoundingBox'};") && ~contains(functionText, ['region' 'props3'])};
p1 = t(t.slice == 1, :);
checks(end+1, :) = {"isolated pixel: Area 1", height(p1) == 1 && p1.areaPixels == 1};
checks(end+1, :) = {"isolated pixel (row 3, col 4): Centroid [4, 3]", p1.centroidX == 4 && p1.centroidY == 3};
checks(end+1, :) = {"isolated pixel: BoundingBox [3.5 2.5 1 1]", ...
    isequal([p1.boundingBoxX p1.boundingBoxY p1.boundingBoxWidth p1.boundingBoxHeight], [3.5 2.5 1 1])};
p2 = t(t.slice == 2, :);
rect = p2(p2.areaPixels == 12, :);
checks(end+1, :) = {"rectangle: Area 12", height(rect) == 1};
checks(end+1, :) = {"rectangle: Centroid at geometric centre [3.5, 6]", ...
    abs(rect.centroidX - 3.5) < 1e-12 && abs(rect.centroidY - 6) < 1e-12};
checks(end+1, :) = {"rectangle: BoundingBox [1.5 4.5 4 3]", ...
    isequal([rect.boundingBoxX rect.boundingBoxY rect.boundingBoxWidth rect.boundingBoxHeight], [1.5 4.5 4 3])};
checks(end+1, :) = {"two components in one slice -> two rows", height(p2) == 2 && isequal(p2.componentIndexInSlice.', [1 2])};
checks(end+1, :) = {"empty slice -> zero rows", ~any(t.slice == 3)};
checks(end+1, :) = {"adjacent slices independent (one row each)", nnz(t.slice == 1) == 1 && nnz(t.slice == 4) == 1};

% Validazione indipendente da PixelIdxList
validOk = true;
for r = 1:height(t)
    c = cc{t.slice(r)};
    idx = c.PixelIdxList{t.componentIndexInSlice(r)};
    [row, col] = ind2sub(c.ImageSize, idx);
    expectedBox = [min(col) - 0.5, min(row) - 0.5, max(col) - min(col) + 1, max(row) - min(row) + 1];
    validOk = validOk && t.areaPixels(r) == numel(idx) && abs(t.centroidX(r) - mean(col)) < 1e-12 && ...
        abs(t.centroidY(r) - mean(row)) < 1e-12 && ...
        max(abs([t.boundingBoxX(r) t.boundingBoxY(r) t.boundingBoxWidth(r) t.boundingBoxHeight(r)] - expectedBox)) < 1e-12;
end
checks(end+1, :) = {"Area / Centroid / BoundingBox = PixelIdxList-derived", validOk};
checks(end+1, :) = {"original CC structures unchanged", isequal(cc, ccCopy)};
checks(end+1, :) = {"repeated execution deterministic", isequal(t, extractComponentProperties2D(cc, "synthetic"))};
checks(end+1, :) = {"no filtering: one row per component", height(t) == sum(cellfun(@(c) c.NumObjects, cc))};
checks(end+1, :) = {"no GT / bwconncomp in the function", ...
    ~contains(functionText, ['loadBrainweb' 'GroundTruth']) && ~contains(functionText, ['bwconn' 'comp('])};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-50s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase68:checksFailed', 'Component-property sanity checks failed.');
end
fprintf('\nCOMPONENT PROPERTIES 2D CHECKS: PASS (synthetic data only)\n');
