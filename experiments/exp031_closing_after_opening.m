%% EXP-031 (fase 64): chiusura standard dopo l'apertura della fase 63
% Una sola chiusura morfologica standard (imclose = dilatazione -> erosione)
% applicata alla maschera APERTA di EXP-030 (non alla baseline della fase
% 60). Sorgente della generazione dei candidati: EXP-026.
%   - elemento strutturante: strel('square', 3), lo stesso delle fasi 62-63
%     (provvisorio, NON la scelta della fase 65); una applicazione
%   - 2D, slice assiale per slice assiale con imclose (autorevole); la
%     maschera cerebrale EXP-021 è applicata SOLO dopo la chiusura completa,
%     mai tra dilatazione ed erosione
%   - la chiusura è estensiva (aperto <= chiuso): non può togliere FP di
%     EXP-030, può solo aggiungere voxel
%   - le due uscite sono salvate PRIMA di caricare il GT; nessuna tolleranza,
%     nessuna scelta di pipeline
%   - nessuna ricostruzione, riempimento, componente connessa; solo pn0 + pn3.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing);

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

se = strel('square', 3);                         % preregistrato, unico
variants = ["baseline" "opening" "opening_closing"];
noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
nSlices = expectedSize(3);
fixedSlices = [46 91 102 136];
baselineFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase60_t2_%s_candidate_mask.mat', noise));
maskFile = @(noise) fullfile(cfg.paths.processedData, ...
    sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));
openingFile = @(noise) fullfile(cfg.paths.processedData, sprintf('exp030_t2_%s_opened_square3_candidate.mat', noise));
outputFile = @(noise) fullfile(cfg.paths.processedData, ...
    sprintf('exp031_t2_%s_opened_closed_square3_candidate.mat', noise));
neighborKernel = [1 1 1; 1 0 1; 1 1 1];

checks = {"SE is square 3x3", isequal(se.Neighborhood, true(3))};
exp030Summary = readtable(fullfile(cfg.paths.metrics, 'exp030_opening_summary.csv'), 'TextType', 'string');

masks = cell(2, 3);                              % condizione x variante
dilatedStages = cell(1, 2);                      % dilatazione intermedia dentro il cervello (solo memoria)
openingNeighbors = cell(1, 2);                   % vicini candidati 2D a 8 nella maschera aperta
volumes = cell(1, 2);
gtLoaded = false;


%% 1. Chiusura (senza GT)

for n = 1:2
    noise = noiseLevels(n);
    if ~isfile(openingFile(noise)) || ~isfile(maskFile(noise)) || ~isfile(baselineFile(noise))
        error('exp031:technicallyBlocked', 'EXP-031 TECHNICALLY BLOCKED: missing input for %s.', noise);
    end
    contents = whos('-file', openingFile(noise));
    savedOpening = load(openingFile(noise), 'candidateMask', 'metadata');
    opened = savedOpening.candidateMask;
    md = savedOpening.metadata;
    savedMask = load(maskFile(noise), 'candidate');
    brainMask = savedMask.candidate;
    savedBaseline = load(baselineFile(noise), 'candidateMask');
    openedCopy = opened;
    brainCopy = brainMask;

    inputChecks = {
        noise + " EXP-030 candidateMask variable present",   any(strcmp({contents.name}, 'candidateMask'))
        noise + " source logical, 181x217x181",              islogical(opened) && isequal(size(opened), expectedSize)
        noise + " metadata EXP-030 / phase 63 / opening",    md.experiment == "EXP-030" && md.phase == 63 && md.operation == "opening"
        noise + " candidate-generation source EXP-026",      md.sourceExperiment == "EXP-026"
        noise + " source SE provisional",                    md.provisionalStructuringElement
        noise + " count = EXP-030 summary CSV",              nnz(opened) == exp030Summary.candidateVoxels( ...
                                                             exp030Summary.condition == noise & exp030Summary.variant == "opening")
        noise + " EXP-021 mask, same size, logical",         islogical(brainMask) && isequal(size(brainMask), expectedSize)
        noise + " opened inside brainMask",                  ~any(opened & ~brainMask, 'all')
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('exp031:technicallyBlocked', 'EXP-031 TECHNICALLY BLOCKED: invalid input for %s.', noise);
    end

    % Chiusura autorevole per slice; verifica manuale SENZA ritaglio intermedio
    closedRaw = false(size(opened));
    dilatedRaw = false(size(opened));
    manualRaw = false(size(opened));
    neighborCount = zeros(size(opened));
    slicesProcessed = 0;
    for k = 1:nSlices
        closedRaw(:, :, k) = imclose(opened(:, :, k), se);
        dilatedRaw(:, :, k) = imdilate(opened(:, :, k), se);
        manualRaw(:, :, k) = imerode(dilatedRaw(:, :, k), se);
        neighborCount(:, :, k) = conv2(double(opened(:, :, k)), neighborKernel, 'same');
        slicesProcessed = slicesProcessed + 1;
    end
    closed = closedRaw & brainMask;
    removedByClosing = opened & ~closed;

    checks = [checks; {
        noise + " exactly 181 slices processed",              slicesProcessed == nSlices
        noise + " imclose = raw dilation -> erosion",         isequal(closedRaw, manualRaw)
        noise + " brainMask applied after complete closing",  isequal(closed, manualRaw & brainMask)
        noise + " closed logical, 181x217x181",               islogical(closed) && isequal(size(closed), expectedSize)
        noise + " closed inside brainMask",                   ~any(closed & ~brainMask, 'all')
        noise + " opened subset of closed (raw)",             ~any(opened & ~closedRaw, 'all')
        noise + " no opened voxel removed",                   nnz(removedByClosing) == 0
        noise + " opened unchanged",                          isequal(opened, openedCopy)
        noise + " brainMask unchanged",                       isequal(brainMask, brainCopy)
        }]; %#ok<AGROW>
    if nnz(removedByClosing) > 0
        error('exp031:technicallyBlocked', 'EXP-031 TECHNICALLY BLOCKED: closing removed opened voxels in %s.', noise);
    end

    metadata = struct('experiment', "EXP-031", 'phase', 64, 'condition', noise, ...
        'source', "EXP-030 opened candidate mask", 'sourceFile', string(openingFile(noise)), ...
        'sourceExperiment', "EXP-030", 'candidateGenerationSource', "EXP-026", ...
        'operation', "closing after opening", 'implementation', "imclose", ...
        'processingDimensionality', "2D axial slice-wise", 'structuringElementShape', "square", ...
        'structuringElementSize', 3, 'iterations', 1, 'brainMaskConstrainedAfterCompleteClosing', true, ...
        'intermediateDilationBrainMaskClipped', false, 'sourceBrainMask', string(maskFile(noise)), ...
        'provisionalStructuringElement', true, 'gtUsedForGeneration', false, 'finalMorphology', false, ...
        'note', "Phase-64 standard closing applied to the Phase-63 opened mask. The square-3 SE remains provisional until Phase 65.");
    candidateMask = closed;
    save(outputFile(noise), 'candidateMask', 'metadata');
    reloaded = load(outputFile(noise), 'candidateMask');
    checks(end+1, :) = {noise + " closed mask reloads identically", isequal(reloaded.candidateMask, closed)}; %#ok<SAGROW>

    masks(n, :) = {savedBaseline.candidateMask, opened, closed};
    dilatedStages{n} = dilatedRaw & brainMask;
    openingNeighbors{n} = neighborCount;
    volumes{n} = prepare(loadBrainwebMri(cfg, "T2", noise));      % solo per le figure
end
checks(end+1, :) = {"both closed masks saved before GT loading", ...
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
writetable(summary, fullfile(cfg.paths.metrics, 'exp031_closing_summary.csv'));

developmentScore = ((dice(1, :) + dice(2, :)) / 2).';
weakerConditionDice = min(dice, [], 1).';
deltaVsBaseline = developmentScore - developmentScore(1);
deltaVsOpening = developmentScore - developmentScore(2);
deltaVsOpening(1) = NaN;                         % non applicabile alla baseline
scores = table(variants.', dice(1, :).', dice(2, :).', weakerConditionDice, developmentScore, deltaVsBaseline, ...
    deltaVsOpening, 'VariableNames', {'variant', 'dicePn0', 'dicePn3', 'weakerConditionDice', ...
    'developmentScore', 'deltaVsBaseline', 'deltaVsOpening'});
writetable(scores, fullfile(cfg.paths.metrics, 'exp031_closing_score_comparison.csv'));

exp026 = readtable(fullfile(cfg.paths.metrics, 'exp026_vs_otsu_comparison.csv'), 'TextType', 'string');
ref026 = exp026(exp026.experiment == "EXP-026", :);
exp030 = readtable(fullfile(cfg.paths.metrics, 'exp030_opening_score_comparison.csv'), 'TextType', 'string');
ref030 = exp030(exp030.variant == "opening", :);
checks = [checks; {
    "baseline Dice reproduces EXP-026",         abs(dice(1, 1) - ref026.dicePn0) < 1e-12 && abs(dice(2, 1) - ref026.dicePn3) < 1e-12
    "opening Dice reproduces EXP-030",          abs(dice(1, 2) - ref030.dicePn0) < 1e-12 && abs(dice(2, 2) - ref030.dicePn3) < 1e-12
    "DevelopmentScore = (pn0 + pn3)/2 exactly", all(developmentScore == ((dice(1, :) + dice(2, :)) / 2).')
    "deltaVsBaseline correct",                  all(deltaVsBaseline == developmentScore - developmentScore(1))
    "deltaVsOpening correct",                   deltaVsOpening(3) == developmentScore(3) - developmentScore(2)
    }];

% Analisi delle aggiunte e recupero dei FN per numero di vicini prima della chiusura
changeRows = cell(2, 1);
gapRows = cell(0, 6);
for n = 1:2
    opened = masks{n, 2};
    closed = masks{n, 3};
    c = squeeze(counts(n, :, :));                % righe: baseline, apertura, chiusura; colonne: TP FP FN
    added = closed & ~opened;
    addedTP = nnz(added & gtMask);
    addedFP = nnz(added & ~gtMask);
    dilationAdded = dilatedStages{n} & ~opened;
    dilTP = nnz(dilationAdded & gtMask);
    dilFP = nnz(dilationAdded & ~gtMask);
    openingFN = ~opened & gtMask;
    checks = [checks; {
        noiseLevels(n) + " |closed| = |opened| + |added|",   nnz(closed) == nnz(opened) + nnz(added)
        noiseLevels(n) + " addedTP + addedFP = added",       addedTP + addedFP == nnz(added)
        noiseLevels(n) + " closedTP = openingTP + addedTP",  c(3, 1) == c(2, 1) + addedTP
        noiseLevels(n) + " closedFP = openingFP + addedFP",  c(3, 2) == c(2, 2) + addedFP
        noiseLevels(n) + " closedFN = openingFN - addedTP",  c(3, 3) == c(2, 3) - addedTP
        noiseLevels(n) + " closing additions within dilation stage", ~any(added & ~dilatedStages{n}, 'all')
        }]; %#ok<AGROW>
    changeRows{n} = {noiseLevels(n), nnz(opened), nnz(closed), c(2, 1), c(2, 2), c(2, 3), c(3, 1), c(3, 2), ...
        c(3, 3), nnz(added), addedTP, addedFP, addedTP / c(2, 3), addedTP / nnz(added), addedFP / nnz(added), ...
        nnz(dilationAdded), dilTP, dilFP, addedTP / dilTP, addedFP / dilFP, nnz(opened & ~closed)};

    nbFN = openingNeighbors{n}(openingFN);
    recovered = closed(openingFN);
    binTotal = 0;
    for b = 0:8
        inBin = nbFN == b;
        rec = nnz(inBin & recovered);
        gapRows(end+1, :) = {noiseLevels(n), b, nnz(inBin), rec, nnz(inBin) - rec, rec / max(nnz(inBin), 1)}; %#ok<SAGROW>
        binTotal = binTotal + nnz(inBin);
    end
    checks(end+1, :) = {noiseLevels(n) + " FN-neighbour bins total = opening FN", binTotal == c(2, 3)}; %#ok<SAGROW>
end
changes = cell2table(vertcat(changeRows{:}), 'VariableNames', {'condition', 'openingVoxels', 'closedVoxels', ...
    'openingTP', 'openingFP', 'openingFN', 'closedTP', 'closedFP', 'closedFN', 'addedByClosing', 'addedTP', ...
    'addedFP', 'fractionOpeningFNRecovered', 'fractionAddedThatIsTP', 'fractionAddedThatIsFP', ...
    'dilationStageAddedVoxels', 'dilationStageAddedTP', 'dilationStageAddedFP', ...
    'fractionDilatedAddedTPRetainedByClosing', 'fractionDilatedAddedFPRetainedByClosing', 'removedByClosing'});
gapTable = cell2table(gapRows, 'VariableNames', {'condition', 'openingNeighborCount', 'openingFNVoxels', ...
    'recoveredByClosing', 'remainingFN', 'fractionRecovered'});
checks(end+1, :) = {"recovered + remaining = opening FN in every bin", ...
    all(gapTable.recoveredByClosing + gapTable.remainingFN == gapTable.openingFNVoxels)};
writetable(changes, fullfile(cfg.paths.metrics, 'exp031_closing_change_analysis.csv'));
writetable(gapTable, fullfile(cfg.paths.metrics, 'exp031_fn_gap_recovery.csv'));

disp(summary);
disp(scores);
disp(changes(:, {'condition', 'addedByClosing', 'addedTP', 'addedFP', 'fractionOpeningFNRecovered', ...
    'fractionAddedThatIsTP', 'dilationStageAddedVoxels', 'dilationStageAddedTP', 'dilationStageAddedFP', ...
    'fractionDilatedAddedTPRetainedByClosing', 'fractionDilatedAddedFPRetainedByClosing'}));
for n = 1:2
    rowsN = gapTable.condition == noiseLevels(n);
    fprintf('%s opening FN by neighbours 0..8: %s\n', noiseLevels(n), strjoin(string(gapTable.openingFNVoxels(rowsN).'), ' / '));
    fprintf('%s recovered by closing 0..8:     %s\n', noiseLevels(n), strjoin(string(gapTable.recoveredByClosing(rowsN).'), ' / '));
end
if deltaVsOpening(3) > 0
    fprintf(['Opening + closing with the provisional square-3 SE is the best observed morphology candidate so far ' ...
        '(delta vs opening %.10f)\n\n'], deltaVsOpening(3));
else
    fprintf('EXP-030 opening remains the best observed morphology candidate so far (delta vs opening %.10f)\n\n', ...
        deltaVsOpening(3));
end


%% 3. Figure (slice fisse)

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 4, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf('EXP-031 T2 %s - T2 / baseline / opening / opening + closing (square 3x3, 2D)', ...
        noiseLevels(n)), 'Interpreter', 'none');
    for k = fixedSlices
        panels = {maskOverlay(volumes{n}(:, :, k), false(expectedSize(1:2))), ...
            maskOverlay(volumes{n}(:, :, k), masks{n, 1}(:, :, k)), ...
            maskOverlay(volumes{n}(:, :, k), masks{n, 2}(:, :, k)), ...
            maskOverlay(volumes{n}(:, :, k), masks{n, 3}(:, :, k))};
        showPanels(layout, panels, ["T2", "baseline", "opening", "opening+closing"], k);
    end
    fig.Position(3:4) = [1300 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp031_closing_probe_%s.png', noiseLevels(n))), ...
        'Resolution', 150);

    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 3, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, {sprintf('EXP-031 T2 %s - errors (after scoring)', noiseLevels(n)), ...
        'yellow = TP, red = FP, green = FN'}, 'Interpreter', 'none');
    for k = fixedSlices
        panels = arrayfun(@(v) errorOverlay(volumes{n}(:, :, k), masks{n, v}(:, :, k), gtMask(:, :, k)), 1:3, ...
            'UniformOutput', false);
        showPanels(layout, panels, ["baseline", "opening", "opening+closing"], k);
    end
    fig.Position(3:4) = [1000 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp031_closing_errors_%s.png', noiseLevels(n))), ...
        'Resolution', 150);

    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, {sprintf('EXP-031 T2 %s - voxels added by closing (vs EXP-030)', noiseLevels(n)), ...
        'orange = lesion GT voxel, red = non-lesion'}, 'Interpreter', 'none');
    for k = fixedSlices
        ax = nexttile(layout);
        addedSlice = masks{n, 3}(:, :, k) & ~masks{n, 2}(:, :, k);
        image(ax, changeOverlay(volumes{n}(:, :, k), addedSlice, gtMask(:, :, k)));
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('k=%d added by closing', k), 'FontSize', 8);
    end
    fig.Position(3:4) = [900 1000];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp031_closing_added_%s.png', noiseLevels(n))), ...
        'Resolution', 150);
end


%% Esito dei controlli

checks(end+1, :) = {"GT unchanged, same for pn0 and pn3", isequal(gtMask, gtCopy)};
scriptText = fileread([mfilename('fullpath') '.m']);
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['imreconstruct' '('], ['imfill' '('], ['bwmorph' '('], ['bwconn' 'comp('], ['bwlabel' '('], ...
    ['region' 'props('], ['bwarea' 'open('], ['multi' 'thresh('], ['imquantize' '('], ['gray' 'thresh('], ...
    ['imopen' '('], ['applySlice' 'Morphology2D(']};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};
checks(end+1, :) = {"no reconstruction/fill/components/threshold/reopening", ...
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
    error('exp031:checksFailed', 'EXP-031 checks failed.');
end
fprintf('\nEXP-031 CHECKS: PASS (%d)\n', size(checks, 1));


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
