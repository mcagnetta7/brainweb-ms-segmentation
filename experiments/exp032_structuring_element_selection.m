%% EXP-032 (fase 65): scelta dell'elemento strutturante per l'apertura standard
% Famiglia morfologica fissata: apertura standard (EXP-030). Unica variabile:
% l'elemento strutturante, scelto in una griglia preregistrata di quattro:
%   square3  = strel('square', 3)   3x3, 9 elementi  (riferimento EXP-030)
%   diamond1 = strel('diamond', 1)  3x3, 5 elementi
%   square5  = strel('square', 5)   5x5, 25 elementi
%   diamond2 = strel('diamond', 2)  5x5, 13 elementi
%   - ogni candidato parte dalla candidateMask canonica della fase 60
%     (= EXP-026), una sola imopen 2D slice per slice, poi AND brainMask
%   - le 8 previsioni (4 SE x pn0/pn3) sono salvate PRIMA di caricare il GT
%   - selezione (fase 37): DevelopmentScore più alto, nessuna tolleranza;
%     un solo SE condiviso da pn0 e pn3; nessuna estensione della griglia
%   - nessuna chiusura, ricostruzione, componente connessa; solo pn0 + pn3.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

% Griglia preregistrata (NON modificare dopo i risultati)
grid = table(["square3"; "diamond1"; "square5"; "diamond2"], ["square"; "diamond"; "square"; "diamond"], ...
    [3; 1; 5; 2], [3; 3; 5; 5], [9; 5; 25; 13], ...
    'VariableNames', {'candidate', 'shape', 'sizeParameter', 'boundingSize', 'foregroundElements'});
ses = arrayfun(@(s) strel(char(grid.shape(s)), grid.sizeParameter(s)), (1:4).', 'UniformOutput', false);
nCand = height(grid);

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
nSlices = expectedSize(3);
fixedSlices = [46 91 102 136];
baselineFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase60_t2_%s_candidate_mask.mat', noise));
maskFile = @(noise) fullfile(cfg.paths.processedData, ...
    sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));
exp030File = @(noise) fullfile(cfg.paths.processedData, sprintf('exp030_t2_%s_opened_square3_candidate.mat', noise));
outputFile = @(noise, cand) fullfile(cfg.paths.processedData, sprintf('exp032_t2_%s_opening_%s_candidate.mat', noise, cand));
selectedFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase65_t2_%s_selected_opening_candidate.mat', noise));
neighborKernel = [1 1 1; 1 0 1; 1 1 1];

checks = {"exactly 4 SE candidates", nCand == 4};
for s = 1:nCand
    nh = ses{s}.Neighborhood;
    checks(end+1, :) = {grid.candidate(s) + " neighbourhood " + grid.boundingSize(s) + "x" + grid.boundingSize(s) + ...
        " / " + grid.foregroundElements(s), isequal(size(nh), [1 1] * grid.boundingSize(s)) && ...
        nnz(nh) == grid.foregroundElements(s) && ismatrix(nh)}; %#ok<SAGROW>
end
distinct = true;
for a = 1:nCand
    for b = a + 1:nCand
        distinct = distinct && ~isequal(ses{a}.Neighborhood, ses{b}.Neighborhood);
    end
end
checks(end+1, :) = {"all neighbourhoods distinct", distinct};

baselines = cell(1, 2);
brainMasks = cell(1, 2);
opened = cell(2, nCand);                         % condizione x candidato
volumes = cell(1, 2);
gtLoaded = false;


%% 1. Le 8 previsioni (senza GT)

for n = 1:2
    noise = noiseLevels(n);
    if ~isfile(baselineFile(noise)) || ~isfile(maskFile(noise)) || ~isfile(exp030File(noise))
        error('exp032:technicallyBlocked', 'EXP-032 TECHNICALLY BLOCKED: missing input for %s.', noise);
    end
    saved = load(baselineFile(noise), 'candidateMask', 'metadata');
    baseline = saved.candidateMask;
    savedMask = load(maskFile(noise), 'candidate');
    brainMask = savedMask.candidate;
    savedExp030 = load(exp030File(noise), 'candidateMask');
    baselineCopy = baseline;
    brainCopy = brainMask;

    inputChecks = {
        noise + " source = Phase-60 canonical, EXP-026",  saved.metadata.phase == 60 && saved.metadata.sourceExperiment == "EXP-026"
        noise + " source logical, 181x217x181",           islogical(baseline) && isequal(size(baseline), expectedSize)
        noise + " EXP-021 mask valid",                    islogical(brainMask) && isequal(size(brainMask), expectedSize)
        noise + " source inside brainMask",               ~any(baseline & ~brainMask, 'all')
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('exp032:technicallyBlocked', 'EXP-032 TECHNICALLY BLOCKED: invalid input for %s.', noise);
    end

    for s = 1:nCand
        raw = false(size(baseline));
        slicesProcessed = 0;
        for k = 1:nSlices
            raw(:, :, k) = imopen(baseline(:, :, k), ses{s});
            slicesProcessed = slicesProcessed + 1;
        end
        result = raw & brainMask;
        label = noise + " " + grid.candidate(s);
        checks = [checks; {
            label + " 181 slices, one imopen",            slicesProcessed == nSlices
            label + " output logical, 181x217x181",       islogical(result) && isequal(size(result), expectedSize)
            label + " brain constraint changes nothing",  isequal(raw, result)
            label + " subset of source, inside brain",    ~any(result & ~baseline, 'all') && ~any(result & ~brainMask, 'all')
            }]; %#ok<AGROW>

        metadata = struct('experiment', "EXP-032", 'phase', 65, 'condition', noise, ...
            'source', "Phase-60 canonical candidate mask", 'sourceFile', string(baselineFile(noise)), ...
            'sourceExperiment', "EXP-026", 'operation', "opening", 'implementation', "imopen", ...
            'processingDimensionality', "2D axial slice-wise", 'structuringElementCandidate', grid.candidate(s), ...
            'structuringElementShape', grid.shape(s), 'structuringElementParameter', grid.sizeParameter(s), ...
            'structuringElementBoundingSize', grid.boundingSize(s), ...
            'structuringElementForegroundElements', grid.foregroundElements(s), 'iterations', 1, ...
            'brainMaskConstrained', true, 'sourceBrainMask', string(maskFile(noise)), ...
            'gtUsedForGeneration', false, 'gtUsedForSelection', true, 'finalPipelineFrozen', false, ...
            'note', "EXP-032 candidate (protocol: GT used only to select among the 4 frozen candidates).");
        candidateMask = result;
        save(outputFile(noise, grid.candidate(s)), 'candidateMask', 'metadata');
        reloaded = load(outputFile(noise, grid.candidate(s)), 'candidateMask');
        checks(end+1, :) = {label + " saved output reloads identically", isequal(reloaded.candidateMask, result)}; %#ok<SAGROW>
        opened{n, s} = result;
    end
    checks = [checks; {
        noise + " square3 = frozen EXP-030 opening",   isequal(opened{n, 1}, savedExp030.candidateMask)
        noise + " source unchanged",                   isequal(baseline, baselineCopy)
        noise + " brainMask unchanged",                isequal(brainMask, brainCopy)
        }]; %#ok<AGROW>
    if ~isequal(opened{n, 1}, savedExp030.candidateMask)
        error('exp032:technicallyBlocked', 'EXP-032 TECHNICALLY BLOCKED: square3 does not reproduce EXP-030 (%s).', noise);
    end
    baselines{n} = baseline;
    brainMasks{n} = brainMask;
    volumes{n} = prepare(loadBrainwebMri(cfg, "T2", noise));      % solo per le figure
end
allSaved = true;
for n = 1:2
    for s = 1:nCand
        allSaved = allSaved && isfile(outputFile(noiseLevels(n), grid.candidate(s)));
    end
end
checks(end+1, :) = {"all 8 outputs saved before GT loading", allSaved && ~gtLoaded};


%% 2. Valutazione e selezione (GT caricato SOLO ora)

gtLoaded = true;
labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
gtVoxels = nnz(gtMask);
gtCopy = gtMask;
checks(end+1, :) = {"GT = label 10, 181x217x181, non-empty", isequal(size(labels), expectedSize) && ...
    isequal(gtMask, labels == 10) && gtVoxels > 0};

diceOf = @(m) 2 * nnz(m & gtMask) / (nnz(m) + gtVoxels);
dice = zeros(2, nCand);
baseDice = zeros(1, 2);
conditionRows = cell(0, 10);
tradeoffRows = cell(0, 21);
for n = 1:2
    base = baselines{n};
    baseTP = nnz(base & gtMask); baseFP = nnz(base & ~gtMask); baseFN = nnz(~base & gtMask);
    baseDice(n) = diceOf(base);
    for s = 1:nCand
        m = opened{n, s};
        tp = nnz(m & gtMask); fp = nnz(m & ~gtMask); fn = nnz(~m & gtMask);
        dice(n, s) = diceOf(m);
        removed = base & ~m;
        removedTP = nnz(removed & gtMask); removedFP = nnz(removed & ~gtMask);
        nb = zeros(size(m));
        for k = 1:nSlices
            nb(:, :, k) = conv2(double(m(:, :, k)), neighborKernel, 'same');
        end
        isolated = nnz(m & nb == 0);
        checks(end+1, :) = {noiseLevels(n) + " " + grid.candidate(s) + " Dice finite in [0,1], counts consistent", ...
            isfinite(dice(n, s)) && dice(n, s) >= 0 && dice(n, s) <= 1 && numel(m) == prod(expectedSize) && ...
            removedTP + removedFP == nnz(removed) && tp + removedTP == baseTP}; %#ok<SAGROW>
        conditionRows(end+1, :) = {noiseLevels(n), grid.candidate(s), grid.shape(s), grid.sizeParameter(s), ...
            nnz(m), gtVoxels, tp, fp, fn, dice(n, s)}; %#ok<SAGROW>
        tradeoffRows(end+1, :) = {noiseLevels(n), grid.candidate(s), nnz(base), nnz(m), baseTP, baseFP, baseFN, ...
            tp, fp, fn, nnz(removed), removedTP, removedFP, tp / baseTP, removedTP / baseTP, removedFP / baseFP, ...
            removedFP / nnz(removed), isolated, grid.boundingSize(s), grid.foregroundElements(s), dice(n, s)}; %#ok<SAGROW>
    end
end
conditionTable = cell2table(conditionRows, 'VariableNames', {'condition', 'candidate', 'shape', 'sizeParameter', ...
    'candidateVoxels', 'gtVoxels', 'tpVoxels', 'fpVoxels', 'fnVoxels', 'dice'});
tradeoffTable = cell2table(tradeoffRows, 'VariableNames', {'condition', 'candidate', 'baselineVoxels', 'openedVoxels', ...
    'baselineTP', 'baselineFP', 'baselineFN', 'openedTP', 'openedFP', 'openedFN', 'removedVoxels', 'removedTP', ...
    'removedFP', 'fractionBaselineTPPreserved', 'fractionBaselineTPLost', 'fractionBaselineFPRemoved', ...
    'fractionRemovedThatIsFP', 'isolatedOpenedVoxels', 'boundingSize', 'foregroundElements', 'dice'});
writetable(conditionTable, fullfile(cfg.paths.metrics, 'exp032_structuring_element_condition_metrics.csv'));
writetable(tradeoffTable, fullfile(cfg.paths.metrics, 'exp032_structuring_element_tradeoff.csv'));

% Selezione (fase 37): DevelopmentScore, poi Dice della condizione più debole
developmentScore = ((dice(1, :) + dice(2, :)) / 2).';
weakerConditionDice = min(dice, [], 1).';
baseScore = (baseDice(1) + baseDice(2)) / 2;
[~, order] = sortrows([-developmentScore, -weakerConditionDice]);
rank = zeros(nCand, 1);
rank(order) = 1:nCand;
winner = order(1);
unresolvedTie = any(developmentScore == developmentScore(winner) & ...
    weakerConditionDice == weakerConditionDice(winner) & (1:nCand).' ~= winner);
scoreTable = [grid, table(dice(1, :).', dice(2, :).', weakerConditionDice, developmentScore, ...
    developmentScore - baseScore, developmentScore - developmentScore(1), rank, 'VariableNames', ...
    {'dicePn0', 'dicePn3', 'weakerConditionDice', 'developmentScore', 'deltaVsNoMorphology', 'deltaVsSquare3', 'rank'})];
writetable(sortrows(scoreTable, 'rank'), fullfile(cfg.paths.metrics, 'exp032_structuring_element_scores.csv'));
disp(sortrows(scoreTable, 'rank'));
if unresolvedTie
    error('exp032:unresolvedTie', 'Exact tie after the weaker-condition Dice: reported as UNRESOLVED.');
end

exp026 = readtable(fullfile(cfg.paths.metrics, 'exp026_vs_otsu_comparison.csv'), 'TextType', 'string');
ref026 = exp026(exp026.experiment == "EXP-026", :);
exp030 = readtable(fullfile(cfg.paths.metrics, 'exp030_opening_score_comparison.csv'), 'TextType', 'string');
ref030 = exp030(exp030.variant == "opening", :);
checks = [checks; {
    "no-morphology Dice reproduces EXP-026",     abs(baseDice(1) - ref026.dicePn0) < 1e-12 && abs(baseDice(2) - ref026.dicePn3) < 1e-12
    "square3 Dice reproduces EXP-030",           abs(dice(1, 1) - ref030.dicePn0) < 1e-12 && abs(dice(2, 1) - ref030.dicePn3) < 1e-12
    "DevelopmentScore = (pn0 + pn3)/2 exactly",  all(developmentScore == ((dice(1, :) + dice(2, :)) / 2).')
    "rank 1 has max DevelopmentScore",           developmentScore(winner) == max(developmentScore) && rank(winner) == 1
    "exactly one winner",                        nnz(rank == 1) == 1 && ~unresolvedTie
    }];

selected = scoreTable(winner, :);
selectedRow = [selected(:, {'candidate', 'shape', 'sizeParameter', 'boundingSize', 'foregroundElements', 'dicePn0', ...
    'dicePn3', 'weakerConditionDice', 'developmentScore', 'deltaVsNoMorphology', 'deltaVsSquare3'}), ...
    table("Phase-37 DevelopmentScore = mean full-volume Dice (pn0, pn3); exact ties -> weaker-condition Dice", ...
    "none", 'VariableNames', {'selectionRule', 'nearTieTolerance'})];
selectedRow = renamevars(selectedRow, 'candidate', 'selectedCandidate');
writetable(selectedRow, fullfile(cfg.paths.metrics, 'exp032_selected_structuring_element.csv'));

% Maschere selezionate della fase 65: copia esatta delle previsioni congelate del vincitore
for n = 1:2
    frozen = load(outputFile(noiseLevels(n), grid.candidate(winner)), 'candidateMask');
    candidateMask = frozen.candidateMask;
    metadata = struct('phase', 65, 'sourceExperiment', "EXP-032", 'candidateGenerationSource', "EXP-026", ...
        'condition', noiseLevels(n), 'operation', "opening", 'implementation', "imopen", ...
        'selectedStructuringElementCandidate', grid.candidate(winner), 'structuringElementShape', grid.shape(winner), ...
        'structuringElementParameter', grid.sizeParameter(winner), ...
        'structuringElementBoundingSize', grid.boundingSize(winner), ...
        'structuringElementForegroundElements', grid.foregroundElements(winner), ...
        'processingDimensionality', "2D axial slice-wise", 'selectionDevelopmentConditions', ["pn0" "pn3"], ...
        'selectionCriterion', "mean full-volume Dice", 'gtUsedForGeneration', false, ...
        'gtUsedForDevelopmentSelection', true, 'finalPipelineFrozen', false, ...
        'note', "This is the Phase-65 selected development morphology candidate. Final before/after morphology validation is Phase 66; final project parameters are not frozen.");
    save(selectedFile(noiseLevels(n)), 'candidateMask', 'metadata');
    reloaded = load(selectedFile(noiseLevels(n)), 'candidateMask', 'metadata');
    checks(end+1, :) = {noiseLevels(n) + " selected mask = frozen winner, same SE", ...
        isequal(reloaded.candidateMask, opened{n, winner}) && ...
        reloaded.metadata.selectedStructuringElementCandidate == grid.candidate(winner)}; %#ok<SAGROW>
end

fprintf('No-morphology DevelopmentScore %.6f (Dice %.6f / %.6f)\n', baseScore, baseDice(1), baseDice(2));
disp(tradeoffTable(:, {'condition', 'candidate', 'openedVoxels', 'openedTP', 'openedFP', 'openedFN', ...
    'fractionBaselineTPPreserved', 'fractionBaselineFPRemoved', 'isolatedOpenedVoxels'}));
fprintf('SELECTED STRUCTURING ELEMENT: %s (strel(''%s'', %d), %dx%d, %d elements), DevelopmentScore %.10f\n', ...
    grid.candidate(winner), grid.shape(winner), grid.sizeParameter(winner), grid.boundingSize(winner), ...
    grid.boundingSize(winner), grid.foregroundElements(winner), developmentScore(winner));
if grid.boundingSize(winner) == 5
    fprintf('Winner at the larger boundary of the grid: no larger SE was tested (documented limitation).\n');
elseif grid.candidate(winner) == "diamond1"
    fprintf('Winner at the smaller boundary of the grid: no smaller SE was tested (documented limitation).\n');
end
fprintf('\n');


%% 3. Figure (slice fisse; dopo il punteggio per gli overlay d'errore)

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 6, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf('EXP-032 T2 %s - T2 / baseline / square3 / diamond1 / square5 / diamond2 (opening, red)', ...
        noiseLevels(n)), 'Interpreter', 'none');
    for k = fixedSlices
        panels = [{maskOverlay(volumes{n}(:, :, k), false(expectedSize(1:2))), ...
            maskOverlay(volumes{n}(:, :, k), baselines{n}(:, :, k))}, ...
            arrayfun(@(s) maskOverlay(volumes{n}(:, :, k), opened{n, s}(:, :, k)), 1:nCand, 'UniformOutput', false)];
        showPanels(layout, panels, ["T2", "baseline", grid.candidate.'], k);
    end
    fig.Position(3:4) = [1800 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp032_se_candidates_%s.png', noiseLevels(n))), ...
        'Resolution', 130);

    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 5, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, {sprintf('EXP-032 T2 %s - errors (after scoring)', noiseLevels(n)), ...
        'yellow = TP, red = FP, green = FN'}, 'Interpreter', 'none');
    for k = fixedSlices
        panels = [{errorOverlay(volumes{n}(:, :, k), baselines{n}(:, :, k), gtMask(:, :, k))}, ...
            arrayfun(@(s) errorOverlay(volumes{n}(:, :, k), opened{n, s}(:, :, k), gtMask(:, :, k)), 1:nCand, ...
            'UniformOutput', false)];
        showPanels(layout, panels, ["baseline", grid.candidate.'], k);
    end
    fig.Position(3:4) = [1600 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp032_se_errors_%s.png', noiseLevels(n))), ...
        'Resolution', 130);

    if winner ~= 1
        fig = figure('Color', 'w');
        layout = tiledlayout(fig, numel(fixedSlices), 6, 'TileSpacing', 'tight', 'Padding', 'tight');
        title(layout, {sprintf('EXP-032 T2 %s - selected %s vs square3 (EXP-030)', noiseLevels(n), ...
            grid.candidate(winner)), 'masks in red; errors: yellow = TP, red = FP, green = FN'}, 'Interpreter', 'none');
        for k = fixedSlices
            panels = {maskOverlay(volumes{n}(:, :, k), false(expectedSize(1:2))), ...
                maskOverlay(volumes{n}(:, :, k), baselines{n}(:, :, k)), ...
                maskOverlay(volumes{n}(:, :, k), opened{n, 1}(:, :, k)), ...
                maskOverlay(volumes{n}(:, :, k), opened{n, winner}(:, :, k)), ...
                errorOverlay(volumes{n}(:, :, k), opened{n, 1}(:, :, k), gtMask(:, :, k)), ...
                errorOverlay(volumes{n}(:, :, k), opened{n, winner}(:, :, k), gtMask(:, :, k))};
            showPanels(layout, panels, ["T2", "baseline", "square3", grid.candidate(winner), ...
                "square3 errors", grid.candidate(winner) + " errors"], k);
        end
        fig.Position(3:4) = [1800 1300];
        exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp032_selected_vs_square3_%s.png', noiseLevels(n))), ...
            'Resolution', 130);
    end
end


%% Esito dei controlli

checks(end+1, :) = {"GT unchanged, same for pn0 and pn3", isequal(gtMask, gtCopy)};
checks(end+1, :) = {"config.m unchanged", isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)};
scriptText = fileread([mfilename('fullpath') '.m']);
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['imclose' '('], ['imreconstruct' '('], ['imfill' '('], ['bwmorph' '('], ['bwconn' 'comp('], ...
    ['bwlabel' '('], ['region' 'props('], ['bwarea' 'open('], ['multi' 'thresh('], ['imquantize' '('], ...
    ['gray' 'thresh(']};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};
checks(end+1, :) = {"no closing/reconstruction/components/thresholding", ...
    ~any(cellfun(@(f) contains(scriptText, f), forbidden))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-62s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp032:checksFailed', 'EXP-032 checks failed.');
end
fprintf('\nEXP-032 CHECKS: PASS (%d)\n', size(checks, 1));


function showPanels(layout, panels, names, k)
%SHOWPANELS Disegna una riga di pannelli RGB con titolo slice/nome.
    for p = 1:numel(panels)
        ax = nexttile(layout);
        image(ax, panels{p});
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('k=%d %s', k, names(p)), 'FontSize', 7);
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
