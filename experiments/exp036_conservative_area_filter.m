%% EXP-036 (fase 69): filtro conservativo delle componenti 2D per area
% Regola preregistrata (unica): rimuovere le componenti 2D con Area == 9,
% tenere quelle con Area > 9. Motivazione solo dalla fase 68 (senza GT):
% area minima = 9 in pn0 e pn3 dopo l'apertura square3.
%   - ingressi: maschere della fase 65, componenti della fase 67 (PixelIdxList),
%     proprietà della fase 68 (areaPixels); nessun ricalcolo di componenti
%     o proprietà
%   - solo Area: nessun centroide, BoundingBox, intensità o indice di slice
%   - le due maschere filtrate sono salvate PRIMA di caricare il GT
%   - decisione: DevelopmentScore filtrato > non filtrato -> mantenuto in via
%     provvisoria per la fase 70; altrimenti respinto; nessuna tolleranza
%   - nessuna seconda soglia, nessuna morfologia, nessuna soglia d'intensità.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

minAreaExclusive = 9;                            % preregistrato: rimuovi Area == 9
noiseLevels = ["pn0" "pn3"];
stages = ["unfiltered" "area9_filtered"];
expectedSize = [181 217 181];
nSlices = expectedSize(3);
fixedSlices = [46 91 102 136];
maskFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase65_t2_%s_selected_opening_candidate.mat', noise));
ccFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase67_t2_%s_components2d.mat', noise));
propFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase68_t2_%s_component_properties.mat', noise));
outputFile = @(noise) fullfile(cfg.paths.processedData, sprintf('exp036_t2_%s_area9_filtered_candidate.mat', noise));

checks = {"rule fixed: keep Area > 9 (remove Area == 9)", minAreaExclusive == 9};
unfiltered = cell(1, 2);
filtered = cell(1, 2);
components = cell(1, 2);
removedMasks = cell(1, 2);
volumes = cell(1, 2);
preRows = cell(2, 1);
sliceCounts = cell(1, 2);
gtLoaded = false;


%% 1. Filtro (senza GT)

for n = 1:2
    noise = noiseLevels(n);
    exists = isfile(maskFile(noise)) && isfile(ccFile(noise)) && isfile(propFile(noise));
    checks(end+1, :) = {noise + " Phase-65 / 67 / 68 artifacts exist", exists}; %#ok<SAGROW>
    if ~exists
        error('exp036:technicallyBlocked', 'EXP-036 TECHNICALLY BLOCKED: missing input for %s.', noise);
    end
    m65 = load(maskFile(noise), 'candidateMask', 'metadata');
    m67 = load(ccFile(noise), 'ccBySlice', 'metadata');
    m68 = load(propFile(noise), 'componentTable', 'metadata');
    source = m65.candidateMask;
    ccBySlice = m67.ccBySlice;
    t = m68.componentTable;
    sourceCopy = source; ccCopy = ccBySlice; tCopy = t;

    % Corrispondenza riga fase 68 <-> PixelIdxList fase 67
    mapOk = height(t) == sum(cellfun(@(c) c.NumObjects, ccBySlice));
    for r = 1:height(t)
        c = ccBySlice{t.slice(r)};
        mapOk = mapOk && t.componentIndexInSlice(r) <= c.NumObjects && ...
            t.areaPixels(r) == numel(c.PixelIdxList{t.componentIndexInSlice(r)});
    end
    inputChecks = {
        noise + " Phase-65 mask logical 181x217x181, EXP-032",   islogical(source) && isequal(size(source), expectedSize) && ...
                                                                m65.metadata.sourceExperiment == "EXP-032"
        noise + " Phase-67 metadata valid (EXP-034, conn. 8, 2D)", m67.metadata.experiment == "EXP-034" && m67.metadata.connectivity == 8 && ...
                                                                m67.metadata.componentDimensionality == "2D axial slice-wise"
        noise + " Phase-68 metadata valid (EXP-035, no filter)",  m68.metadata.experiment == "EXP-035" && ~m68.metadata.componentFilteringApplied
        noise + " Phase-68 rows map exactly to PixelIdxList",     mapOk
        noise + " min Area == 9 (precondition)",                  min(t.areaPixels) == 9
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('exp036:technicallyBlocked', ['EXP-036 TECHNICALLY BLOCKED / METHODOLOGICAL ASSUMPTION INVALID ' ...
            'for %s (threshold NOT changed).'], noise);
    end

    [result, keepBySlice, removedBySlice] = filterComponentsByArea2D(ccBySlice, t, expectedSize, minAreaExclusive);

    % Controlli sulle componenti rimosse/tenute
    removedAreasOk = true; keptAreasOk = true; square3Ok = true;
    perSlice = zeros(nSlices, 4);                % prima, rimosse, voxel prima, voxel rimossi
    for k = 1:nSlices
        c = ccBySlice{k};
        for i = 1:c.NumObjects
            a = numel(c.PixelIdxList{i});
            if removedBySlice{k}(i)
                removedAreasOk = removedAreasOk && a == 9;
                [row, col] = ind2sub(c.ImageSize, c.PixelIdxList{i});
                square3Ok = square3Ok && max(row) - min(row) == 2 && max(col) - min(col) == 2;   % quadrato 3x3
            else
                keptAreasOk = keptAreasOk && a > 9;
            end
        end
        perSlice(k, :) = [c.NumObjects, nnz(removedBySlice{k}), nnz(source(:, :, k)), ...
            nnz(source(:, :, k) & ~result(:, :, k))];
    end
    removed = source & ~result;
    nRemoved = sum(perSlice(:, 2));
    checks = [checks; {
        noise + " output logical 181x217x181",                     islogical(result) && isequal(size(result), expectedSize)
        noise + " filtered subset of source (no added voxel)",     ~any(result & ~source, 'all')
        noise + " removed components all Area == 9",               removedAreasOk
        noise + " retained components all Area > 9",               keptAreasOk
        noise + " removed components = rows with Area == 9",       nRemoved == nnz(t.areaPixels == 9)
        noise + " removed Area-9 components are exact 3x3 squares", square3Ok
        noise + " removedVoxels = 9 * removedComponents",          nnz(removed) == 9 * nRemoved
        noise + " Phase-65 mask / ccBySlice / property table unchanged", isequal(source, sourceCopy) && ...
                                                                   isequal(ccBySlice, ccCopy) && isequal(t, tCopy)
        }]; %#ok<AGROW>

    metadata = struct('phase', 69, 'experiment', "EXP-036", 'condition', noise, ...
        'source', "Phase-65 selected opening candidate", 'sourceExperiment', "EXP-032", ...
        'componentSourceExperiment', "EXP-034", 'propertySourceExperiment', "EXP-035", ...
        'candidateGenerationSource', "EXP-026", 'filterType', "2D component area", ...
        'filterRule', "remove Area == 9", 'retentionRule', "Area > 9", 'areaThresholdPixels', 9, ...
        'connectivity', 8, 'componentDimensionality', "2D axial slice-wise", 'gtUsedForGeneration', false, ...
        'gtUsedForDevelopmentEvaluation', true, 'centroidRuleUsed', false, 'boundingBoxRuleUsed', false, ...
        'intensityRuleUsed', false, 'componentFilteringApplied', true, 'finalPipelineFrozen', false, ...
        'note', "EXP-036 evaluates the weakest non-trivial post-opening area filter observed from the GT-free Phase-68 property distribution. Retention is provisional pending Phase 70 small-lesion protection analysis.");
    candidateMask = result;
    save(outputFile(noise), 'candidateMask', 'metadata');
    reloaded = load(outputFile(noise), 'candidateMask');
    checks(end+1, :) = {noise + " filtered mask saved and reloads identically", isequal(reloaded.candidateMask, result)}; %#ok<SAGROW>

    preRows{n} = {noise, height(t), nRemoved, height(t) - nRemoved, nRemoved / height(t), nnz(source), ...
        nnz(removed), nnz(result), nnz(removed) / nnz(source)};
    unfiltered{n} = source;
    filtered{n} = result;
    components{n} = ccBySlice;
    removedMasks{n} = removed;
    sliceCounts{n} = perSlice;
    volumes{n} = prepare(loadBrainwebMri(cfg, "T2", noise));      % solo per le figure
end
checks(end+1, :) = {"both filtered masks frozen before GT loading", ...
    all(arrayfun(@(noise) isfile(outputFile(noise)), noiseLevels)) && ~gtLoaded};
pre = cell2table(vertcat(preRows{:}), 'VariableNames', {'condition', 'componentsBefore', 'componentsRemoved', ...
    'componentsRetained', 'fractionComponentsRemoved', 'candidateVoxelsBefore', 'candidateVoxelsRemoved', ...
    'candidateVoxelsAfter', 'fractionCandidateVoxelsRemoved'});
disp(pre);


%% 2. Valutazione (GT caricato SOLO ora)

gtLoaded = true;
labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
gtVoxels = nnz(gtMask);
gtCopy = gtMask;
checks(end+1, :) = {"GT = label 10, 181x217x181, non-empty", isequal(size(labels), expectedSize) && ...
    isequal(gtMask, labels == 10) && gtVoxels > 0};

metricRows = cell(0, 8);
dice = zeros(2, 2);
counts = zeros(2, 2, 3);
changeRows = cell(2, 1);
sliceTables = cell(1, 2);
for n = 1:2
    masksN = {unfiltered{n}, filtered{n}};
    for s = 1:2
        m = masksN{s};
        tp = nnz(m & gtMask); fp = nnz(m & ~gtMask); fn = nnz(~m & gtMask);
        counts(n, s, :) = [tp fp fn];
        dice(n, s) = 2 * tp / (nnz(m) + gtVoxels);
        checks(end+1, :) = {noiseLevels(n) + " " + stages(s) + " Dice finite in [0,1], full volume", ...
            isfinite(dice(n, s)) && dice(n, s) >= 0 && dice(n, s) <= 1 && numel(m) == prod(expectedSize)}; %#ok<SAGROW>
        metricRows(end+1, :) = {noiseLevels(n), stages(s), nnz(m), gtVoxels, tp, fp, fn, dice(n, s)}; %#ok<SAGROW>
    end
    removed = removedMasks{n};
    removedTP = nnz(removed & gtMask);
    removedFP = nnz(removed & ~gtMask);
    c = squeeze(counts(n, :, :));
    checks = [checks; {
        noiseLevels(n) + " removedTP + removedFP = removedVoxels",  removedTP + removedFP == nnz(removed)
        noiseLevels(n) + " filteredTP = unfilteredTP - removedTP",  c(2, 1) == c(1, 1) - removedTP
        noiseLevels(n) + " filteredFP = unfilteredFP - removedFP",  c(2, 2) == c(1, 2) - removedFP
        noiseLevels(n) + " filteredFN = unfilteredFN + removedTP",  c(2, 3) == c(1, 3) + removedTP
        }]; %#ok<AGROW>
    p = preRows{n};
    changeRows{n} = [p, {c(1, 1), c(2, 1), c(1, 2), c(2, 2), c(1, 3), c(2, 3), removedTP, removedFP, ...
        removedTP / nnz(removed), removedFP / nnz(removed), removedFP / removedTP, dice(n, 2) - dice(n, 1)}];
    ps = sliceCounts{n};
    sliceTables{n} = table(repmat(noiseLevels(n), nSlices, 1), (1:nSlices).', ps(:, 1), ps(:, 2), ps(:, 1) - ps(:, 2), ...
        ps(:, 3), ps(:, 4), ps(:, 3) - ps(:, 4), squeeze(sum(removed & gtMask, [1 2])), ...
        squeeze(sum(removed & ~gtMask, [1 2])), 'VariableNames', {'condition', 'slice', 'componentsBefore', ...
        'componentsRemoved', 'componentsAfter', 'candidateVoxelsBefore', 'candidateVoxelsRemoved', ...
        'candidateVoxelsAfter', 'removedTP', 'removedFP'});
end
metrics = cell2table(metricRows, 'VariableNames', {'condition', 'stage', 'candidateVoxels', 'gtVoxels', ...
    'tpVoxels', 'fpVoxels', 'fnVoxels', 'dice'});
changes = cell2table(vertcat(changeRows{:}), 'VariableNames', {'condition', 'componentsBefore', 'componentsRemoved', ...
    'componentsRetained', 'fractionComponentsRemoved', 'candidateVoxelsBefore', 'candidateVoxelsRemoved', ...
    'candidateVoxelsAfter', 'fractionCandidateVoxelsRemoved', 'unfilteredTP', 'filteredTP', 'unfilteredFP', ...
    'filteredFP', 'unfilteredFN', 'filteredFN', 'removedTP', 'removedFP', 'fractionRemovedVoxelsThatAreTP', ...
    'fractionRemovedVoxelsThatAreFP', 'fpRemovedPerTpLost', 'deltaDice'});
developmentScore = ((dice(1, :) + dice(2, :)) / 2).';
weakerConditionDice = min(dice, [], 1).';
deltaVsUnfiltered = developmentScore - developmentScore(1);
development = table(stages.', dice(1, :).', dice(2, :).', weakerConditionDice, developmentScore, deltaVsUnfiltered, ...
    'VariableNames', {'stage', 'dicePn0', 'dicePn3', 'weakerConditionDice', 'developmentScore', 'deltaVsUnfiltered'});
writetable(metrics, fullfile(cfg.paths.metrics, 'exp036_area9_filter_metrics.csv'));
writetable(development, fullfile(cfg.paths.metrics, 'exp036_area9_filter_development_summary.csv'));
writetable(changes, fullfile(cfg.paths.metrics, 'exp036_area9_filter_change_summary.csv'));
writetable([sliceTables{1}; sliceTables{2}], fullfile(cfg.paths.metrics, 'exp036_area9_filter_by_slice.csv'));

exp033 = readtable(fullfile(cfg.paths.metrics, 'exp033_before_after_development_summary.csv'), 'TextType', 'string');
ref = exp033(exp033.stage == "after_morphology", :);
checks = [checks; {
    "unfiltered Dice reproduces Phase 65/66",   abs(dice(1, 1) - ref.dicePn0) < 1e-12 && abs(dice(2, 1) - ref.dicePn3) < 1e-12
    "DevelopmentScore = (pn0 + pn3)/2 exactly", all(developmentScore == ((dice(1, :) + dice(2, :)) / 2).')
    "deltaVsUnfiltered correct",                deltaVsUnfiltered(2) == developmentScore(2) - developmentScore(1)
    }];

disp(metrics);
disp(development);
disp(changes(:, {'condition', 'componentsRemoved', 'candidateVoxelsRemoved', 'removedTP', 'removedFP', ...
    'fractionRemovedVoxelsThatAreFP', 'fpRemovedPerTpLost', 'deltaDice'}));
if developmentScore(2) > developmentScore(1)
    fprintf('EXP-036 AREA-9 FILTER = PROVISIONALLY RETAINED FOR PHASE 70 ANALYSIS (delta %.10f)\n\n', deltaVsUnfiltered(2));
elseif developmentScore(2) < developmentScore(1)
    fprintf('EXP-036 REJECTED (delta %.10f)\n\n', deltaVsUnfiltered(2));
else
    fprintf('EXP-036 NOT RETAINED: no measurable improvement (exact tie)\n\n');
end


%% 3. Figure (slice fisse)

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 4, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf('EXP-036 T2 %s - T2 / unfiltered (Phase 65) / Area-9 filtered / removed Area-9 components', ...
        noiseLevels(n)), 'Interpreter', 'none');
    for k = fixedSlices
        panels = {maskOverlay(volumes{n}(:, :, k), false(expectedSize(1:2))), ...
            maskOverlay(volumes{n}(:, :, k), unfiltered{n}(:, :, k)), maskOverlay(volumes{n}(:, :, k), filtered{n}(:, :, k)), ...
            maskOverlay(volumes{n}(:, :, k), removedMasks{n}(:, :, k))};
        showPanels(layout, panels, ["T2", "unfiltered", "filtered", "removed"], k);
    end
    fig.Position(3:4) = [1300 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp036_area9_filter_%s.png', noiseLevels(n))), 'Resolution', 150);

    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, {sprintf('EXP-036 T2 %s - voxels removed by the Area-9 filter (after scoring)', noiseLevels(n)), ...
        'orange = lesion GT voxel, red = non-lesion'}, 'Interpreter', 'none');
    for k = fixedSlices
        ax = nexttile(layout);
        image(ax, changeOverlay(volumes{n}(:, :, k), removedMasks{n}(:, :, k), gtMask(:, :, k)));
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('k=%d removed', k), 'FontSize', 8);
    end
    fig.Position(3:4) = [900 1000];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp036_area9_removed_errors_%s.png', noiseLevels(n))), ...
        'Resolution', 150);
end

fig = figure('Color', 'w');
layout = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact');
title(layout, 'EXP-036 - Area-9 components and voxels removed per axial slice (descriptive)');
ax = nexttile(layout);
plot(ax, 1:nSlices, sliceCounts{1}(:, 2), 'b-', 1:nSlices, sliceCounts{2}(:, 2), 'r-');
ylabel(ax, 'components removed'); legend(ax, 'pn0', 'pn3'); xlim(ax, [1 nSlices]); grid(ax, 'on');
ax = nexttile(layout);
plot(ax, 1:nSlices, sliceCounts{1}(:, 4), 'b-', 1:nSlices, sliceCounts{2}(:, 4), 'r-');
ylabel(ax, 'voxels removed'); xlabel(ax, 'axial slice k'); legend(ax, 'pn0', 'pn3'); xlim(ax, [1 nSlices]); grid(ax, 'on');
fig.Position(3:4) = [1000 600];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp036_area9_filter_by_slice.png'));


%% Esito dei controlli

checks(end+1, :) = {"GT unchanged, same for pn0 and pn3", isequal(gtMask, gtCopy)};
checks(end+1, :) = {"config.m unchanged", isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)};
scriptText = fileread([mfilename('fullpath') '.m']);
functionText = fileread(fullfile(cfg.paths.segmentation, 'filterComponentsByArea2D.m'));
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['bwconn' 'comp('], ['region' 'props'], ['bwarea' 'open('], ['imopen' '('], ['imclose' '('], ...
    ['imerode' '('], ['imdilate' '('], ['imfill' '('], ['imreconstruct' '('], ['bwmorph' '('], ['multi' 'thresh('], ...
    ['imquantize' '('], ['gray' 'thresh('], ['imbinarize' '('], ['t.cent' 'roid'], ['t.bounding' 'Box'], ['Mean' 'Intensity']};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};
checks(end+1, :) = {"no recomputation/centroid/box/intensity/morphology/threshold", ...
    ~any(cellfun(@(f) contains(scriptText, f) || contains(functionText, f), forbidden))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-62s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp036:checksFailed', 'EXP-036 checks failed.');
end
fprintf('\nEXP-036 CHECKS: PASS (%d)\n', size(checks, 1));


function showPanels(layout, panels, names, k)
%SHOWPANELS Disegna una riga di pannelli RGB con titolo slice/nome.
    for p = 1:numel(panels)
        ax = nexttile(layout);
        image(ax, panels{p});
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('k=%d %s', k, names(p)), 'FontSize', 8);
    end
end

function rgb = maskOverlay(sliceImage, maskSlice)
%MASKOVERLAY T2 in scala di grigi con la maschera in rosso (solo visualizzazione).
    gray = sliceImage.';
    m = maskSlice.';
    red = gray; green = gray; blue = gray;
    red(m) = 1; green(m) = 0; blue(m) = 0;
    rgb = cat(3, red, green, blue);
end

function rgb = changeOverlay(sliceImage, changedSlice, gtSlice)
%CHANGEOVERLAY Voxel cambiati: arancione se lesione GT, rosso altrimenti.
    gray = sliceImage.';
    c = changedSlice.';
    g = gtSlice.';
    red = gray; green = gray; blue = gray;
    lesion = c & g; other = c & ~g;
    red(lesion) = 1; green(lesion) = 0.6; blue(lesion) = 0;
    red(other) = 1; green(other) = 0; blue(other) = 0;
    rgb = cat(3, red, green, blue);
end
