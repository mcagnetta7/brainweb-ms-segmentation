%% EXP-035 (fase 68): proprietà delle componenti connesse 2D
% Descrive le componenti 2D GIÀ identificate nella fase 67 (EXP-034) con
% regionprops e solo le proprietà Area, Centroid, BoundingBox.
%   - riusa ccBySlice salvato (nessun ricalcolo delle componenti)
%   - convenzioni MATLAB: Centroid = [x colonna, y riga]; BoundingBox =
%     [x, y, larghezza, altezza]; nelle figure la slice è trasposta, quindi
%     le coordinate disegnate sono scambiate
%   - nessun ground truth, nessuna classificazione, nessun filtro, nessuna
%     soglia, nessuna statistica d'intensità, nessuna proprietà 3D
%   - righe = istanze di componenti 2D: NON lesioni 3D uniche; solo pn0 + pn3.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
nSlices = expectedSize(3);
fixedSlices = [46 91 102 136];
componentsFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase67_t2_%s_components2d.mat', noise));
maskFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase65_t2_%s_selected_opening_candidate.mat', noise));
outputFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase68_t2_%s_component_properties.mat', noise));
summary034 = readtable(fullfile(cfg.paths.metrics, 'exp034_component_summary.csv'), 'TextType', 'string');
bySlice034 = readtable(fullfile(cfg.paths.metrics, 'exp034_components_by_slice.csv'), 'TextType', 'string');
tol = 1e-12;

checks = cell(0, 2);
tables = cell(1, 2);
ccAll = cell(1, 2);
masks = cell(1, 2);
volumes = cell(1, 2);
sliceRows = cell(1, 2);
summaryRows = cell(2, 1);


%% 1. Proprietà per condizione

for n = 1:2
    noise = noiseLevels(n);
    exists = isfile(componentsFile(noise)) && isfile(maskFile(noise));
    checks(end+1, :) = {noise + " Phase-67 / Phase-65 artifacts exist", exists}; %#ok<SAGROW>
    if ~exists
        error('exp035:technicallyBlocked', 'EXP-035 TECHNICALLY BLOCKED: missing input for %s.', noise);
    end
    vars = whos('-file', componentsFile(noise));
    savedCC = load(componentsFile(noise), 'ccBySlice', 'numComponentsPerSlice', 'metadata');
    savedMask = load(maskFile(noise), 'candidateMask');
    ccBySlice = savedCC.ccBySlice;
    md = savedCC.metadata;
    candidateMask = savedMask.candidateMask;
    ccCopy = ccBySlice;
    maskCopy = candidateMask;

    inputChecks = {
        noise + " ccBySlice and numComponentsPerSlice present", all(ismember({'ccBySlice', 'numComponentsPerSlice'}, {vars.name}))
        noise + " Phase-67 metadata valid",                    md.phase == 67 && md.experiment == "EXP-034" && ...
                                                              md.sourceExperiment == "EXP-032" && md.candidateGenerationSource == "EXP-026" && ...
                                                              md.selectedStructuringElement == "square3" && ~md.componentFilteringApplied && ...
                                                              ~md.componentPropertiesComputed && ~md.gtUsed && ~md.unique3DLesionsEstimated
        noise + " connectivity 8, 2D axial slice-wise",         md.connectivity == 8 && md.componentDimensionality == "2D axial slice-wise"
        noise + " exactly 181 CC structures",                  iscell(ccBySlice) && numel(ccBySlice) == nSlices
        noise + " Phase-65 mask logical 181x217x181",          islogical(candidateMask) && isequal(size(candidateMask), expectedSize)
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('exp035:technicallyBlocked', 'EXP-035 TECHNICALLY BLOCKED: invalid input for %s.', noise);
    end

    componentTable = extractComponentProperties2D(ccBySlice, noise);

    % Validazione indipendente da PixelIdxList
    areaOk = true; centroidOk = true; boxOk = true; insideOk = true; finiteOk = true; orderOk = true;
    perSliceRows = zeros(nSlices, 1);
    perSliceArea = zeros(nSlices, 1);
    for r = 1:height(componentTable)
        k = componentTable.slice(r);
        i = componentTable.componentIndexInSlice(r);
        c = ccBySlice{k};
        idx = c.PixelIdxList{i};
        [row, col] = ind2sub(c.ImageSize, idx);
        a = componentTable.areaPixels(r);
        cx = componentTable.centroidX(r); cy = componentTable.centroidY(r);
        box = [componentTable.boundingBoxX(r) componentTable.boundingBoxY(r) ...
            componentTable.boundingBoxWidth(r) componentTable.boundingBoxHeight(r)];
        expectedBox = [min(col) - 0.5, min(row) - 0.5, max(col) - min(col) + 1, max(row) - min(row) + 1];
        finiteOk = finiteOk && all(isfinite([a cx cy box])) && a >= 1 && a == round(a) && box(3) > 0 && box(4) > 0;
        areaOk = areaOk && a == numel(idx);
        centroidOk = centroidOk && abs(cx - mean(col)) < tol && abs(cy - mean(row)) < tol;
        boxOk = boxOk && max(abs(box - expectedBox)) < tol;
        insideOk = insideOk && cx >= 1 && cx <= c.ImageSize(2) && cy >= 1 && cy <= c.ImageSize(1) && ...
            box(1) >= 0.5 && box(1) + box(3) <= c.ImageSize(2) + 0.5 && ...
            box(2) >= 0.5 && box(2) + box(4) <= c.ImageSize(1) + 0.5;
        perSliceRows(k) = perSliceRows(k) + 1;
        perSliceArea(k) = perSliceArea(k) + a;
        orderOk = orderOk && i == perSliceRows(k);   % indici 1..NumObjects nell'ordine di PixelIdxList
    end
    ref = bySlice034(bySlice034.condition == noise, :);
    numObjects = cellfun(@(cc) cc.NumObjects, ccBySlice);
    checks = [checks; {
        noise + " rows = EXP-034 total2DComponents",            height(componentTable) == summary034.total2DComponents(summary034.condition == noise)
        noise + " rows per slice = Phase-67 NumObjects",         isequal(perSliceRows, numObjects) && isequal(perSliceRows, ref.numComponents)
        noise + " componentIndexInSlice runs 1..NumObjects",     orderOk
        noise + " Area/Centroid/BoundingBox finite, Area integer >= 1, box > 0", finiteOk
        noise + " Area = numel(PixelIdxList{i})",                areaOk
        noise + " Centroid = mean column / mean row",            centroidOk
        noise + " BoundingBox = PixelIdxList min/max",           boxOk
        noise + " centroids and boxes inside the image",         insideOk
        noise + " per-slice Area sum = Phase-67 candidateVoxels", isequal(perSliceArea, ref.candidateVoxels)
        noise + " total Area = nnz(Phase-65 mask)",              sum(componentTable.areaPixels) == nnz(candidateMask)
        noise + " empty slices give zero rows",                  all(perSliceRows(numObjects == 0) == 0)
        noise + " ccBySlice / PixelIdxList unchanged",           isequal(ccBySlice, ccCopy)
        noise + " Phase-65 mask unchanged",                      isequal(candidateMask, maskCopy)
        }]; %#ok<AGROW>

    metadata = struct('phase', 68, 'experiment', "EXP-035", 'condition', noise, ...
        'source', "Phase-67 2D connected components", 'sourceFile', string(componentsFile(noise)), ...
        'sourceExperiment', "EXP-034", 'candidateGenerationSource', "EXP-026", ...
        'morphology', "standard opening square3", 'connectivity', 8, 'componentDimensionality', "2D axial slice-wise", ...
        'properties', ["Area" "Centroid" "BoundingBox"], 'gtUsed', false, 'componentFilteringApplied', false, ...
        'componentClassificationApplied', false, 'intensityPropertiesComputed', false, ...
        'unique3DLesionsEstimated', false, 'finalPipelineFrozen', false, ...
        'note', "Each table row represents one 2D connected-component instance in one axial slice. Component indices are local to the slice and must not be interpreted as unique 3D lesion identifiers.");
    save(outputFile(noise), 'componentTable', 'metadata');
    reloaded = load(outputFile(noise), 'componentTable');
    checks(end+1, :) = {noise + " saved property table reloads identically", isequal(reloaded.componentTable, componentTable)}; %#ok<SAGROW>

    % Riepiloghi descrittivi (nessuna soglia, nessuna classe)
    perSlice = zeros(nSlices, 5);
    for k = 1:nSlices
        v = componentTable.areaPixels(componentTable.slice == k);
        if isempty(v)
            perSlice(k, :) = [0 NaN NaN NaN NaN];
        else
            perSlice(k, :) = [sum(v) min(v) max(v) mean(v) median(v)];
        end
    end
    sliceRows{n} = table(repmat(noise, nSlices, 1), (1:nSlices).', perSliceRows, perSlice(:, 1), perSlice(:, 2), ...
        perSlice(:, 3), perSlice(:, 4), perSlice(:, 5), 'VariableNames', {'condition', 'slice', 'numComponents', ...
        'totalAreaPixels', 'minAreaPixels', 'maxAreaPixels', 'meanAreaPixels', 'medianAreaPixels'});
    a = componentTable.areaPixels;
    summaryRows{n} = {noise, height(componentTable), sum(a), min(a), max(a), mean(a), median(a), std(a), ...
        min(componentTable.centroidX), max(componentTable.centroidX), min(componentTable.centroidY), ...
        max(componentTable.centroidY), min(componentTable.boundingBoxWidth), max(componentTable.boundingBoxWidth), ...
        min(componentTable.boundingBoxHeight), max(componentTable.boundingBoxHeight)};

    tables{n} = componentTable;
    ccAll{n} = ccBySlice;
    masks{n} = candidateMask;
    volumes{n} = prepare(loadBrainwebMri(cfg, "T2", noise));      % solo per le figure
end

allProperties = [tables{1}; tables{2}];
allProperties = sortrows(allProperties, {'condition', 'slice', 'componentIndexInSlice'});
writetable(allProperties, fullfile(cfg.paths.metrics, 'exp035_component_properties.csv'));
summary = cell2table(vertcat(summaryRows{:}), 'VariableNames', {'condition', 'total2DComponents', 'totalAreaPixels', ...
    'minAreaPixels', 'maxAreaPixels', 'meanAreaPixels', 'medianAreaPixels', 'stdAreaPixels', 'minCentroidX', ...
    'maxCentroidX', 'minCentroidY', 'maxCentroidY', 'minBoundingBoxWidth', 'maxBoundingBoxWidth', ...
    'minBoundingBoxHeight', 'maxBoundingBoxHeight'});
writetable(summary, fullfile(cfg.paths.metrics, 'exp035_component_property_summary.csv'));
writetable([sliceRows{1}; sliceRows{2}], fullfile(cfg.paths.metrics, 'exp035_component_properties_by_slice.csv'));
disp(summary);
fprintf('NOTE: rows are 2D slice-wise component instances, not unique 3D lesions.\n\n');


%% 2. Figure

fig = figure('Color', 'w');
ax = axes(fig);
semilogy(ax, 1:height(tables{1}), sort(tables{1}.areaPixels), 'b-', 1:height(tables{2}), sort(tables{2}.areaPixels), 'r-');
xlabel(ax, 'component rank (ascending Area)');
ylabel(ax, 'Area (pixels, log scale)');
legend(ax, 'pn0', 'pn3', 'Location', 'northwest');
title(ax, 'EXP-035 - sorted Area of 2D component instances (descriptive, no threshold)');
grid(ax, 'on');
fig.Position(3:4) = [900 450];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp035_component_area_rank.png'));

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 3, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, {sprintf('EXP-035 T2 %s - T2 / Phase-65 candidates / BoundingBox (yellow) and Centroid (cyan)', ...
        noiseLevels(n)), 'display is transposed: a pixel (row r, column c) is drawn at x = r, y = c'}, ...
        'Interpreter', 'none');
    for k = fixedSlices
        t = tables{n}(tables{n}.slice == k, :);
        for p = 1:3
            ax = nexttile(layout);
            if p == 1
                image(ax, grayOverlay(volumes{n}(:, :, k), false(expectedSize(1:2))));
            else
                image(ax, grayOverlay(volumes{n}(:, :, k), masks{n}(:, :, k)));
            end
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            if p == 3
                hold(ax, 'on');
                for r = 1:height(t)
                    rectangle(ax, 'Position', [t.boundingBoxY(r) t.boundingBoxX(r) t.boundingBoxHeight(r) ...
                        t.boundingBoxWidth(r)], 'EdgeColor', 'y', 'LineWidth', 0.8);
                end
                plot(ax, t.centroidY, t.centroidX, 'c+', 'MarkerSize', 4);
                hold(ax, 'off');
            end
            names = ["T2", "candidates", sprintf("%d components", height(t))];
            title(ax, sprintf('k=%d %s', k, names(p)), 'FontSize', 8);
        end
    end
    fig.Position(3:4) = [1000 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp035_component_properties_%s.png', noiseLevels(n))), ...
        'Resolution', 150);
end


%% Esito dei controlli

checks(end+1, :) = {"config.m unchanged", isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)};
scriptText = fileread([mfilename('fullpath') '.m']);
functionText = fileread(fullfile(cfg.paths.segmentation, 'extractComponentProperties2D.m'));
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['bwconn' 'comp('], ['region' 'props3'], ['bwarea' 'open('], ['loadBrainweb' 'GroundTruth('], ...
    ['imopen' '('], ['imclose' '('], ['imerode' '('], ['imdilate' '('], ['imfill' '('], ['imreconstruct' '('], ...
    ['bwmorph' '('], ['multi' 'thresh('], ['imquantize' '('], ['gray' 'thresh('], ['imbinarize' '('], ...
    ['Mean' 'Intensity'], ['Pixel' 'Values'], ['Weighted' 'Centroid']};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};
checks(end+1, :) = {"no CC recomputation/GT/filter/morphology/threshold/3D/intensity", ...
    ~any(cellfun(@(f) contains(scriptText, f) || contains(functionText, f), forbidden))};
checks(end+1, :) = {"regionprops only in the function, exactly 3 properties", ...
    ~contains(scriptText, ['region' 'props(']) && contains(functionText, ['properties = {''Area'', ' ...
    '''Centroid'', ''BoundingBox''};'])};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-66s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp035:checksFailed', 'EXP-035 checks failed.');
end
fprintf('\nEXP-035 CHECKS: PASS (%d)\n', size(checks, 1));


function rgb = grayOverlay(sliceImage, maskSlice)
%GRAYOVERLAY T2 in scala di grigi con la maschera in rosso (solo visualizzazione).
    gray = sliceImage.';
    m = maskSlice.';
    red = gray; green = gray; blue = gray;
    red(m) = 1; green(m) = 0; blue(m) = 0;
    rgb = cat(3, red, green, blue);
end
