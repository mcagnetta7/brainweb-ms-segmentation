%% EXP-030 (fase 63): sonda di apertura standard sulla maschera dei candidati
% Una sola apertura morfologica standard (imopen = erosione -> dilatazione)
% sulla candidateMask canonica della fase 60 (= EXP-026), che NON viene
% modificata né sostituita.
%   - elemento strutturante: strel('square', 3), lo stesso della sonda
%     EXP-029 (provvisorio, NON la scelta della fase 65); una applicazione
%   - 2D, slice assiale per slice assiale con imopen (autorevole); risultato
%     intersecato con la maschera cerebrale EXP-021
%   - verifiche: imopen = erosione -> dilatazione (applySliceMorphology2D);
%     prima fase = erosione congelata di EXP-029; eroso <= aperto <= baseline
%   - opened è sottoinsieme della baseline: l'apertura NON può recuperare
%     falsi negativi della baseline
%   - le due uscite sono salvate PRIMA di caricare il GT; nessuna tolleranza,
%     nessuna scelta di pipeline
%   - nessuna chiusura, ricostruzione, componente connessa; solo pn0 + pn3.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

se = strel('square', 3);                         % preregistrato, unico
variants = ["baseline" "erosion_reference" "opening"];
noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
nSlices = expectedSize(3);
fixedSlices = [46 91 102 136];
candidateFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase60_t2_%s_candidate_mask.mat', noise));
maskFile = @(noise) fullfile(cfg.paths.processedData, ...
    sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));
erosionFile = @(noise) fullfile(cfg.paths.processedData, sprintf('exp029_t2_%s_eroded_square3_candidate.mat', noise));
outputFile = @(noise) fullfile(cfg.paths.processedData, sprintf('exp030_t2_%s_opened_square3_candidate.mat', noise));
neighborKernel = [1 1 1; 1 0 1; 1 1 1];

checks = {"SE is square 3x3", isequal(se.Neighborhood, true(3))};
phase60Summary = readtable(fullfile(cfg.paths.metrics, 'phase60_candidate_mask_summary.csv'), 'TextType', 'string');

masks = cell(2, 3);                              % condizione x variante
isolatedCounts = zeros(2, 2);                    % condizione x (baseline, apertura)
neighborDist = zeros(2, 2, 9);                   % condizione x (baseline, apertura) x 0..8
volumes = cell(1, 2);
gtLoaded = false;


%% 1. Apertura (senza GT)

for n = 1:2
    noise = noiseLevels(n);
    if ~isfile(candidateFile(noise)) || ~isfile(maskFile(noise)) || ~isfile(erosionFile(noise))
        error('exp030:technicallyBlocked', 'EXP-030 TECHNICALLY BLOCKED: missing input for %s.', noise);
    end
    saved = load(candidateFile(noise), 'candidateMask', 'metadata');
    baseline = saved.candidateMask;
    savedMask = load(maskFile(noise), 'candidate');
    brainMask = savedMask.candidate;
    savedErosion = load(erosionFile(noise), 'candidateMask', 'metadata');
    frozenEroded = savedErosion.candidateMask;
    baselineCopy = baseline;
    brainCopy = brainMask;

    inputChecks = {
        noise + " source = Phase-60 canonical, EXP-026",   saved.metadata.phase == 60 && saved.metadata.sourceExperiment == "EXP-026"
        noise + " source logical, 181x217x181",            islogical(baseline) && isequal(size(baseline), expectedSize)
        noise + " EXP-021 mask for " + noise + ", same size", contains(string(maskFile(noise)), "exp021_t1_" + noise) && ...
                                                           islogical(brainMask) && isequal(size(brainMask), expectedSize)
        noise + " source inside brainMask",                ~any(baseline & ~brainMask, 'all')
        noise + " count = Phase-60 summary CSV",           nnz(baseline) == ...
                                                           phase60Summary.candidateVoxels(phase60Summary.condition == noise)
        noise + " EXP-029 erosion reference loaded",       savedErosion.metadata.experiment == "EXP-029" && ...
                                                           savedErosion.metadata.operation == "erosion" && ...
                                                           savedErosion.metadata.condition == noise
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('exp030:technicallyBlocked', 'EXP-030 TECHNICALLY BLOCKED: invalid input for %s.', noise);
    end

    % Apertura autorevole: imopen per slice, poi AND con la maschera cerebrale
    openedRaw = false(size(baseline));
    slicesProcessed = 0;
    for k = 1:nSlices
        openedRaw(:, :, k) = imopen(baseline(:, :, k), se);
        slicesProcessed = slicesProcessed + 1;
    end
    opened = openedRaw & brainMask;

    % Verifica indipendente: erosione -> dilatazione con l'helper della fase 62
    manualEroded = applySliceMorphology2D(baseline, brainMask, "erode", se);
    manualOpened = applySliceMorphology2D(manualEroded, brainMask, "dilate", se);
    dilatedFrozen = applySliceMorphology2D(frozenEroded, brainMask, "dilate", se);

    checks = [checks; {
        noise + " exactly 181 slices processed",            slicesProcessed == nSlices
        noise + " opened logical, 181x217x181",             islogical(opened) && isequal(size(opened), expectedSize)
        noise + " brain constraint changes nothing",        isequal(openedRaw, opened)
        noise + " opened inside brainMask",                 ~any(opened & ~brainMask, 'all')
        noise + " manual erosion = frozen EXP-029 erosion", isequal(manualEroded, frozenEroded)
        noise + " imopen = erosion -> dilation",            isequal(opened, manualOpened)
        noise + " imopen = dilation of frozen EXP-029",     isequal(opened, dilatedFrozen)
        noise + " opened subset of baseline",               ~any(opened & ~baseline, 'all')
        noise + " eroded subset of opened",                 ~any(frozenEroded & ~opened, 'all')
        noise + " counts eroded <= opened <= baseline",     nnz(frozenEroded) <= nnz(opened) && nnz(opened) <= nnz(baseline)
        noise + " baseline unchanged",                      isequal(baseline, baselineCopy)
        noise + " brainMask unchanged",                     isequal(brainMask, brainCopy)
        }]; %#ok<AGROW>

    metadata = struct('experiment', "EXP-030", 'phase', 63, 'condition', noise, ...
        'source', "Phase-60 canonical candidate mask", 'sourceFile', string(candidateFile(noise)), ...
        'sourceExperiment', "EXP-026", 'operation', "opening", 'implementation', "imopen", ...
        'processingDimensionality', "2D axial slice-wise", 'structuringElementShape', "square", ...
        'structuringElementSize', 3, 'iterations', 1, 'brainMaskConstrained', true, ...
        'sourceBrainMask', string(maskFile(noise)), 'provisionalStructuringElement', true, ...
        'gtUsedForGeneration', false, 'finalMorphology', false, ...
        'note', "Phase-63 opening probe; structuring element remains provisional until Phase 65.");
    candidateMask = opened;
    save(outputFile(noise), 'candidateMask', 'metadata');
    reloaded = load(outputFile(noise), 'candidateMask');
    checks(end+1, :) = {noise + " opened mask reloads identically", isequal(reloaded.candidateMask, opened)}; %#ok<SAGROW>

    % Topologia locale descrittiva (vicini 2D a 8, come nella fase 61)
    pair = {baseline, opened};
    for p = 1:2
        nb = zeros(size(baseline));
        for k = 1:nSlices
            nb(:, :, k) = conv2(double(pair{p}(:, :, k)), neighborKernel, 'same');
        end
        values = nb(pair{p});
        neighborDist(n, p, :) = histcounts(values, -0.5:1:8.5);
        isolatedCounts(n, p) = nnz(values == 0);
    end

    masks(n, :) = {baseline, frozenEroded, opened};
    volumes{n} = prepare(loadBrainwebMri(cfg, "T2", noise));      % solo per le figure
end
checks(end+1, :) = {"both opened masks saved before GT loading", ...
    all(arrayfun(@(noise) isfile(outputFile(noise)), noiseLevels)) && ~gtLoaded};


%% 2. Valutazione (GT caricato SOLO ora)

gtLoaded = true;
labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
gtVoxels = nnz(gtMask);
gtCopy = gtMask;
checks(end+1, :) = {"GT = label 10, 181x217x181, non-empty", isequal(size(labels), expectedSize) && ...
    isequal(gtMask, labels == 10) && gtVoxels > 0};

summaryRows = cell(0, 8);
dice = zeros(2, 3);
counts = zeros(2, 3, 3);                         % condizione x variante x (TP, FP, FN)
for n = 1:2
    for v = 1:3
        m = masks{n, v};
        tp = nnz(m & gtMask);
        fp = nnz(m & ~gtMask);
        fn = nnz(~m & gtMask);
        counts(n, v, :) = [tp fp fn];
        dice(n, v) = 2 * tp / (nnz(m) + gtVoxels);
        checks(end+1, :) = {noiseLevels(n) + " " + variants(v) + " Dice finite in [0,1], full volume", ...
            isfinite(dice(n, v)) && dice(n, v) >= 0 && dice(n, v) <= 1 && numel(m) == prod(expectedSize)}; %#ok<SAGROW>
        summaryRows(end+1, :) = {noiseLevels(n), variants(v), nnz(m), gtVoxels, tp, fp, fn, dice(n, v)}; %#ok<SAGROW>
    end
end
summary = cell2table(summaryRows, 'VariableNames', {'condition', 'variant', 'candidateVoxels', 'gtVoxels', ...
    'tpVoxels', 'fpVoxels', 'fnVoxels', 'dice'});
writetable(summary, fullfile(cfg.paths.metrics, 'exp030_opening_summary.csv'));

developmentScore = ((dice(1, :) + dice(2, :)) / 2).';
weakerConditionDice = min(dice, [], 1).';
deltaVsBaseline = developmentScore - developmentScore(1);
scores = table(variants.', dice(1, :).', dice(2, :).', weakerConditionDice, developmentScore, deltaVsBaseline, ...
    'VariableNames', {'variant', 'dicePn0', 'dicePn3', 'weakerConditionDice', 'developmentScore', 'deltaVsBaseline'});
writetable(scores, fullfile(cfg.paths.metrics, 'exp030_opening_score_comparison.csv'));

exp026 = readtable(fullfile(cfg.paths.metrics, 'exp026_vs_otsu_comparison.csv'), 'TextType', 'string');
ref026 = exp026(exp026.experiment == "EXP-026", :);
exp029 = readtable(fullfile(cfg.paths.metrics, 'exp029_morphology_effect_comparison.csv'), 'TextType', 'string');
ref029 = exp029(exp029.variant == "erosion", :);
checks = [checks; {
    "baseline Dice reproduces EXP-026",        abs(dice(1, 1) - ref026.dicePn0) < 1e-12 && abs(dice(2, 1) - ref026.dicePn3) < 1e-12
    "erosion Dice reproduces EXP-029",         abs(dice(1, 2) - ref029.dicePn0) < 1e-12 && abs(dice(2, 2) - ref029.dicePn3) < 1e-12
    "DevelopmentScore = (pn0 + pn3)/2 exactly", all(developmentScore == ((dice(1, :) + dice(2, :)) / 2).')
    "deltas = score - baseline score",         all(deltaVsBaseline == developmentScore - developmentScore(1))
    }];

% Analisi delle variazioni
changeRows = cell(2, 1);
for n = 1:2
    baseline = masks{n, 1};
    eroded = masks{n, 2};
    opened = masks{n, 3};
    c = squeeze(counts(n, :, :));                % righe: baseline, erosione, apertura; colonne: TP FP FN
    removed = baseline & ~opened;
    restored = opened & ~eroded;
    removedTP = nnz(removed & gtMask);
    removedFP = nnz(removed & ~gtMask);
    restoredTP = nnz(restored & gtMask);
    restoredFP = nnz(restored & ~gtMask);
    erosionLostTP = c(1, 1) - c(2, 1);
    erosionLostFP = c(1, 2) - c(2, 2);
    checks = [checks; {
        noiseLevels(n) + " |baseline| = |opened| + |removed|",  nnz(baseline) == nnz(opened) + nnz(removed)
        noiseLevels(n) + " |opened| = |eroded| + |restored|",   nnz(opened) == nnz(eroded) + nnz(restored)
        noiseLevels(n) + " removedTP + removedFP = removed",    removedTP + removedFP == nnz(removed)
        noiseLevels(n) + " restoredTP + restoredFP = restored", restoredTP + restoredFP == nnz(restored)
        noiseLevels(n) + " TP eroded <= opened <= baseline",    c(2, 1) <= c(3, 1) && c(3, 1) <= c(1, 1)
        noiseLevels(n) + " FP eroded <= opened <= baseline",    c(2, 2) <= c(3, 2) && c(3, 2) <= c(1, 2)
        noiseLevels(n) + " FN baseline <= opened <= eroded",    c(1, 3) <= c(3, 3) && c(3, 3) <= c(2, 3)
        noiseLevels(n) + " isolated after opening = 0",         isolatedCounts(n, 2) == 0
        }]; %#ok<AGROW>
    changeRows{n} = {noiseLevels(n), nnz(baseline), nnz(eroded), nnz(opened), c(1, 1), c(1, 2), c(1, 3), ...
        c(2, 1), c(2, 2), c(3, 1), c(3, 2), c(3, 3), nnz(removed), removedTP, removedFP, nnz(restored), ...
        restoredTP, restoredFP, c(3, 1) / c(1, 1), removedTP / c(1, 1), removedFP / c(1, 2), ...
        removedFP / nnz(removed), restoredTP / erosionLostTP, restoredFP / erosionLostFP, ...
        isolatedCounts(n, 1), isolatedCounts(n, 2)};
end
changes = cell2table(vertcat(changeRows{:}), 'VariableNames', {'condition', 'baselineVoxels', 'erosionVoxels', ...
    'openingVoxels', 'baselineTP', 'baselineFP', 'baselineFN', 'erosionTP', 'erosionFP', 'openingTP', ...
    'openingFP', 'openingFN', 'removedByOpening', 'removedTP', 'removedFP', 'restoredAfterErosion', ...
    'restoredTP', 'restoredFP', 'fractionBaselineTPPreserved', 'fractionBaselineTPLost', ...
    'fractionBaselineFPRemoved', 'fractionRemovedThatIsFP', 'fractionErosionLostTPRestored', ...
    'fractionErosionLostFPRestored', 'isolatedBaseline', 'isolatedOpening'});
writetable(changes, fullfile(cfg.paths.metrics, 'exp030_opening_change_analysis.csv'));

disp(summary);
disp(scores);
disp(changes(:, {'condition', 'removedByOpening', 'removedTP', 'removedFP', 'restoredAfterErosion', ...
    'restoredTP', 'restoredFP', 'isolatedBaseline', 'isolatedOpening'}));
for n = 1:2
    fprintf(['%s: baseline TP preserved %.4f, TP lost %.4f, FP removed %.4f, removed that is FP %.4f; ' ...
        'erosion-lost TP restored %.4f, erosion-lost FP restored %.4f\n'], noiseLevels(n), ...
        changes.fractionBaselineTPPreserved(n), changes.fractionBaselineTPLost(n), ...
        changes.fractionBaselineFPRemoved(n), changes.fractionRemovedThatIsFP(n), ...
        changes.fractionErosionLostTPRestored(n), changes.fractionErosionLostFPRestored(n));
    for p = 1:2
        fprintf('%s %s neighbour distribution 0..8: %s\n', noiseLevels(n), ...
            string(ifelseText(p == 1, "baseline", "opening")), strjoin(string(squeeze(neighborDist(n, p, :)).'), ' / '));
    end
end
delta = deltaVsBaseline(3);
if delta > 0
    fprintf('OPENING IMPROVES THE BASELINE WITH THE PROVISIONAL SQUARE-3 PROBE (delta %.10f)\n\n', delta);
elseif delta < 0
    fprintf('OPENING WORSENS THE BASELINE WITH THE PROVISIONAL SQUARE-3 PROBE (delta %.10f)\n\n', delta);
else
    fprintf('OPENING LEAVES THE BASELINE SCORE UNCHANGED\n\n');
end


%% 3. Figure (slice fisse)

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 4, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf('EXP-030 T2 %s - T2 / baseline / erosion / opening (square 3x3, 2D)', ...
        noiseLevels(n)), 'Interpreter', 'none');
    for k = fixedSlices
        panels = {maskOverlay(volumes{n}(:, :, k), false(expectedSize(1:2))), ...
            maskOverlay(volumes{n}(:, :, k), masks{n, 1}(:, :, k)), ...
            maskOverlay(volumes{n}(:, :, k), masks{n, 2}(:, :, k)), ...
            maskOverlay(volumes{n}(:, :, k), masks{n, 3}(:, :, k))};
        showPanels(layout, panels, ["T2", "baseline", "erosion", "opening"], k);
    end
    fig.Position(3:4) = [1300 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp030_opening_probe_%s.png', noiseLevels(n))), ...
        'Resolution', 150);

    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 3, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, {sprintf('EXP-030 T2 %s - errors (after scoring)', noiseLevels(n)), ...
        'yellow = TP, red = FP, green = FN'}, 'Interpreter', 'none');
    for k = fixedSlices
        panels = arrayfun(@(v) errorOverlay(volumes{n}(:, :, k), masks{n, v}(:, :, k), gtMask(:, :, k)), 1:3, ...
            'UniformOutput', false);
        showPanels(layout, panels, ["baseline", "erosion", "opening"], k);
    end
    fig.Position(3:4) = [1000 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp030_opening_errors_%s.png', noiseLevels(n))), ...
        'Resolution', 150);

    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 2, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, {sprintf('EXP-030 T2 %s - removed by opening / restored after erosion', noiseLevels(n)), ...
        'orange = lesion GT voxel, red = non-lesion'}, 'Interpreter', 'none');
    for k = fixedSlices
        removedSlice = masks{n, 1}(:, :, k) & ~masks{n, 3}(:, :, k);
        restoredSlice = masks{n, 3}(:, :, k) & ~masks{n, 2}(:, :, k);
        panels = {changeOverlay(volumes{n}(:, :, k), removedSlice, gtMask(:, :, k)), ...
            changeOverlay(volumes{n}(:, :, k), restoredSlice, gtMask(:, :, k))};
        showPanels(layout, panels, ["removed by opening", "restored after erosion"], k);
    end
    fig.Position(3:4) = [700 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp030_opening_changes_%s.png', noiseLevels(n))), ...
        'Resolution', 150);
end


%% Esito dei controlli

checks(end+1, :) = {"GT unchanged, same for pn0 and pn3", isequal(gtMask, gtCopy)};
scriptText = fileread([mfilename('fullpath') '.m']);
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['imclose' '('], ['imreconstruct' '('], ['imfill' '('], ['bwmorph' '('], ['bwconn' 'comp('], ...
    ['bwlabel' '('], ['region' 'props('], ['bwarea' 'open('], ['multi' 'thresh('], ['imquantize' '('], ...
    ['gray' 'thresh('], ['thresholdLesion' 'Candidates('], ['generateLesion' 'CandidateMask(']};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};
checks(end+1, :) = {"no closing/reconstruction/components/thresholding", ...
    ~any(cellfun(@(f) contains(scriptText, f), forbidden))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-58s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp030:checksFailed', 'EXP-030 checks failed.');
end
fprintf('\nEXP-030 CHECKS: PASS (%d)\n', size(checks, 1));


function out = ifelseText(condition, whenTrue, whenFalse)
%IFELSETEXT Selettore compatto per le etichette stampate.
    if condition
        out = whenTrue;
    else
        out = whenFalse;
    end
end

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

function rgb = errorOverlay(sliceImage, candidateSlice, gtSlice)
%ERROROVERLAY TP giallo, FP rosso, FN verde (solo visualizzazione diagnostica).
    gray = sliceImage.';
    p = candidateSlice.';
    g = gtSlice.';
    red = gray; green = gray; blue = gray;
    tp = p & g; fp = p & ~g; fn = ~p & g;
    red(tp) = 1; green(tp) = 1; blue(tp) = 0;
    red(fp) = 1; green(fp) = 0; blue(fp) = 0;
    red(fn) = 0; green(fn) = 1; blue(fn) = 0;
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
