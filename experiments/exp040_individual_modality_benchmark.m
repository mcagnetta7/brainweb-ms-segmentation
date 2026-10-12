%% EXP-040 (fase 78): confronto delle singole modalità T1 / T2 / PD
% Stessa architettura per tutte le modalità, nessuna fusione:
%   maschera cerebrale EXP-021 (la stessa per T1/T2/PD in ogni condizione)
%   -> uint16 -> double -> /4095, nessun preprocessing
%   -> multithresh(volume(brainMask), 2) -> imquantize -> 3 classi
%   -> candidati predichiarati: SOLO classe 1, SOLO classe 2, SOLO classe 3
%   -> una apertura 2D assiale strel('square', 3) -> AND brainMask
%   - le 18 previsioni (3 modalità x 2 condizioni x 3 classi) sono salvate
%     PRIMA di caricare il GT; T2 classe 3 deve coincidere con M_pred (fase 71)
%   - le statistiche d'intensità del GT della fase 41 NON sono usate: le tre
%     classi sono generate in modo simmetrico per ogni modalità
%   - selezione (fase 37): DevelopmentScore, poi Dice della condizione più
%     debole; nessuna tolleranza; migliore classe per modalità, poi
%     classifica delle modalità
%   - nessun filtro sulle componenti, nessun region growing, nessuna fusione;
%     solo pn0 + pn3.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

modalities = ["T1" "T2" "PD"];
noiseLevels = ["pn0" "pn3"];
classes = 1:3;
numberOfThresholds = 2;
se = strel('square', 3);
expectedSize = [181 217 181];
nSlices = expectedSize(3);
fixedSlices = [46 91 102 136];
maskFile = @(noise) fullfile(cfg.paths.processedData, sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));
phase71File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));
outputFile = @(mod, noise, c) fullfile(cfg.paths.processedData, ...
    sprintf('exp040_%s_%s_class%d_opened_candidate.mat', lower(mod), noise, c));
aliasFile = @(mod, noise) fullfile(cfg.paths.processedData, ...
    sprintf('phase78_%s_%s_selected_single_modality.mat', lower(mod), noise));
mriFile = @(mod, noise) mriPath(cfg, mod, noise);

checks = cell(0, 2);
gtLoaded = false;


%% 0. Ingressi

missing = strings(0, 1);
for m = modalities
    for noise = noiseLevels
        f = mriFile(m, noise);
        if ~isfile(f)
            missing(end+1) = string(f); %#ok<SAGROW>
        end
    end
end
checks(end+1, :) = {"all 6 MRI files exist (T1/T2/PD x pn0/pn3)", isempty(missing)};
if ~isempty(missing)
    error('exp040:technicallyBlocked', 'PHASE 78 TECHNICALLY BLOCKED: missing %s', strjoin(missing, ', '));
end

brainMasks = cell(1, 2);
phase71 = cell(1, 2);
for n = 1:2
    noise = noiseLevels(n);
    s = load(maskFile(noise), 'candidate');
    brainMasks{n} = s.candidate;
    p = load(phase71File(noise), 'M_pred');
    phase71{n} = p.M_pred;
    checks(end+1, :) = {noise + " EXP-021 brain mask logical 181x217x181", ...
        islogical(brainMasks{n}) && isequal(size(brainMasks{n}), expectedSize)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " Phase-71 M_pred available", islogical(phase71{n}) && isequal(size(phase71{n}), expectedSize)}; %#ok<SAGROW>
end
brainCopies = brainMasks;
phase71Copies = phase71;


%% 1. Le 18 previsioni (senza GT)

predictions = cell(numel(modalities), 2, 3);     % modalità x condizione x classe
thresholds = zeros(numel(modalities), 2, 2);
volumes = cell(numel(modalities), 2);
for mi = 1:numel(modalities)
    mod = modalities(mi);
    for n = 1:2
        noise = noiseLevels(n);
        raw = loadBrainwebMri(cfg, mod, noise);
        vol = prepare(raw);
        brainMask = brainMasks{n};
        label = mod + " " + noise;
        checks = [checks; {
            label + " volume 181x217x181, finite, in [0,1]", isequal(size(vol), expectedSize) && ...
                all(isfinite(vol(:))) && min(vol(:)) >= 0 && max(vol(:)) <= 1
            }]; %#ok<AGROW>

        brainValues = vol(brainMask);
        levels = double(multithresh(brainValues, numberOfThresholds));
        classVolume = imquantize(vol, levels);
        thresholds(mi, n, :) = levels;
        classCounts = arrayfun(@(c) nnz(brainMask & classVolume == c), classes);
        checks = [checks; {
            label + " multithresh input = brain voxels only",   numel(brainValues) == nnz(brainMask)
            label + " exactly two increasing finite thresholds", numel(levels) == 2 && all(isfinite(levels)) && levels(1) < levels(2)
            label + " classes 1..3 partition the brain mask",     sum(classCounts) == nnz(brainMask) && all(classCounts > 0)
            }]; %#ok<AGROW>

        for c = classes
            rawCandidate = brainMask & classVolume == c;
            opened = false(expectedSize);
            for k = 1:nSlices
                opened(:, :, k) = imopen(rawCandidate(:, :, k), se);
            end
            candidateMask = opened & brainMask;
            checks = [checks; {
                label + " class " + c + " raw inside brain, opened subset, logical", ...
                    ~any(rawCandidate & ~brainMask, 'all') && ~any(candidateMask & ~rawCandidate, 'all') && ...
                    islogical(candidateMask) && isequal(size(candidateMask), expectedSize)
                }]; %#ok<AGROW>
            metadata = struct('phase', 78, 'experiment', "EXP-040", 'modality', mod, 'condition', noise, ...
                'candidateClass', c, 'sourceDataset', "msles2", 'resolution', "1mm", 'rf', 0, ...
                'sourceFile', string(mriFile(mod, noise)), 'brainSupport', "EXP-021", 'workingConversion', "double", ...
                'normalization', "/4095", 'preprocessing', "none", 'thresholdMethod', "multithresh", ...
                'numberOfThresholds', numberOfThresholds, 'numberOfClasses', 3, 'thresholdsNormalized', levels, ...
                'candidateRule', "single imquantize class", 'morphology', "standard 2D opening", ...
                'structuringElement', "square3", 'componentFiltering', "none", 'regionGrowing', "none", ...
                'multimodalFusion', "none", 'gtUsedForGeneration', false, 'finalPipelineFrozen', false);
            save(outputFile(mod, noise, c), 'candidateMask', 'metadata');
            predictions{mi, n, c} = candidateMask;
        end
        checks(end+1, :) = {label + " raw MRI unchanged", isequal(raw, loadBrainwebMri(cfg, mod, noise))}; %#ok<SAGROW>
        volumes{mi, n} = vol;
    end
end

allSaved = true;
for mi = 1:numel(modalities)
    for n = 1:2
        for c = classes
            allSaved = allSaved && isfile(outputFile(modalities(mi), noiseLevels(n), c));
        end
    end
end
t2 = find(modalities == "T2");
checks = [checks; {
    "all 18 predictions generated and saved before GT", allSaved && ~gtLoaded
    "T2 class 3 = Phase-71 M_pred (pn0)",               isequal(predictions{t2, 1, 3}, phase71{1})
    "T2 class 3 = Phase-71 M_pred (pn3)",               isequal(predictions{t2, 2, 3}, phase71{2})
    }];
if ~isequal(predictions{t2, 1, 3}, phase71{1}) || ~isequal(predictions{t2, 2, 3}, phase71{2})
    error('exp040:technicallyBlocked', 'EXP-040 TECHNICALLY BLOCKED / REPRODUCIBILITY FAILURE: T2 class 3 != Phase-71 M_pred.');
end


%% 2. Valutazione (GT caricato SOLO ora)

gtLoaded = true;
labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;                           % GT completo, non intersecato con la maschera
gtVoxels = nnz(gtMask);
gtCopy = gtMask;
checks(end+1, :) = {"GT = label 10, 181x217x181, non-empty", isequal(size(labels), expectedSize) && ...
    isequal(gtMask, labels == 10) && gtVoxels > 0};

candRows = cell(0, 11);
dice = zeros(numel(modalities), 3, 2);           % modalità x classe x condizione
counts = zeros(numel(modalities), 3, 2, 4);      % ... x (voxel, TP, FP, FN)
for mi = 1:numel(modalities)
    for c = classes
        for n = 1:2
            m = predictions{mi, n, c};
            tp = nnz(m & gtMask); fp = nnz(m & ~gtMask); fn = nnz(~m & gtMask);
            dice(mi, c, n) = 2 * tp / (nnz(m) + gtVoxels);
            counts(mi, c, n, :) = [nnz(m) tp fp fn];
            checks(end+1, :) = {modalities(mi) + " class " + c + " " + noiseLevels(n) + " Dice full volume in [0,1]", ...
                isfinite(dice(mi, c, n)) && dice(mi, c, n) >= 0 && dice(mi, c, n) <= 1 && numel(m) == prod(expectedSize) && ...
                tp + fn == gtVoxels}; %#ok<SAGROW>
            candRows(end+1, :) = {modalities(mi), c, noiseLevels(n), thresholds(mi, n, 1), thresholds(mi, n, 2), ...
                nnz(m), gtVoxels, tp, fp, fn, dice(mi, c, n)}; %#ok<SAGROW>
        end
    end
end
candidateMetrics = cell2table(candRows,'VariableNames', {'modality', 'candidateClass', 'condition', ...
    'threshold1', 'threshold2', 'candidateVoxels', 'gtVoxels', 'tpVoxels', 'fpVoxels', 'fnVoxels', 'dice'});
writetable(candidateMetrics, fullfile(cfg.paths.metrics, 'exp040_single_modality_candidate_metrics.csv'));

devRows = cell(0, 7);
selected = zeros(1, numel(modalities));
unresolved = false(1, numel(modalities));
for mi = 1:numel(modalities)
    score = (squeeze(dice(mi, :, 1)) + squeeze(dice(mi, :, 2))) / 2;
    weaker = min(squeeze(dice(mi, :, 1)), squeeze(dice(mi, :, 2)));
    [~, order] = sortrows([-score(:), -weaker(:)]);
    best = order(1);
    unresolved(mi) = any(score == score(best) & weaker == weaker(best) & (1:3) ~= best);
    selected(mi) = best;
    for c = classes
        devRows(end+1, :) = {modalities(mi), c, dice(mi, c, 1), dice(mi, c, 2), weaker(c), score(c), ...
            c == best && ~unresolved(mi)}; %#ok<SAGROW>
    end
    checks(end+1, :) = {modalities(mi) + " DevelopmentScore = (pn0 + pn3)/2 exactly", ...
        all(score == (squeeze(dice(mi, :, 1)) + squeeze(dice(mi, :, 2))) / 2)}; %#ok<SAGROW>
end
devSummary = cell2table(devRows, 'VariableNames', {'modality', 'candidateClass', 'dicePn0', 'dicePn3', ...
    'weakerConditionDice', 'developmentScore', 'selectedWithinModality'});
writetable(devSummary, fullfile(cfg.paths.metrics, 'exp040_single_modality_development_summary.csv'));

modRows = cell(numel(modalities), 16);
for mi = 1:numel(modalities)
    b = selected(mi);
    cn = squeeze(counts(mi, b, :, :));             % righe pn0/pn3; colonne voxel TP FP FN
    modRows(mi, :) = {modalities(mi), b, dice(mi, b, 1), dice(mi, b, 2), min(dice(mi, b, :)), ...
        (dice(mi, b, 1) + dice(mi, b, 2)) / 2, cn(1, 1), cn(2, 1), cn(1, 2), cn(1, 3), cn(1, 4), ...
        cn(2, 2), cn(2, 3), cn(2, 4), 0, unresolved(mi)};
end
modSummary = cell2table(modRows,'VariableNames', {'modality', 'selectedClass', 'dicePn0', 'dicePn3', ...
    'weakerConditionDice', 'developmentScore', 'candidateVoxelsPn0', 'candidateVoxelsPn3', 'tpPn0', 'fpPn0', ...
    'fnPn0', 'tpPn3', 'fpPn3', 'fnPn3', 'individualModalityRank', 'unresolvedExactTie'});
[~, rankOrder] = sortrows([-modSummary.developmentScore, -modSummary.weakerConditionDice]);
modSummary.individualModalityRank(rankOrder) = (1:height(modSummary)).';
writetable(sortrows(modSummary, 'individualModalityRank'), fullfile(cfg.paths.metrics, 'exp040_modality_summary.csv'));

% Alias dei vincitori: copie esatte delle previsioni congelate
for mi = 1:numel(modalities)
    if unresolved(mi)
        continue
    end
    for n = 1:2
        frozen = load(outputFile(modalities(mi), noiseLevels(n), selected(mi)), 'candidateMask', 'metadata');
        candidateMask = frozen.candidateMask;
        metadata = frozen.metadata;
        metadata.selectedUsingDevelopmentGT = true;
        metadata.note = "Phase-78 development selection within modality (exact copy of the frozen EXP-040 candidate).";
        save(aliasFile(modalities(mi), noiseLevels(n)), 'candidateMask', 'metadata');
        checks(end+1, :) = {modalities(mi) + " " + noiseLevels(n) + " alias = frozen winner", ...
            isequal(candidateMask, predictions{mi, n, selected(mi)})}; %#ok<SAGROW>
    end
end

disp(candidateMetrics);
disp(devSummary);
disp(sortrows(modSummary, 'individualModalityRank'));
for mi = 1:numel(modalities)
    for n = 1:2
        fprintf('%s %s thresholds: %.6f / %.6f (raw-eq. %.2f / %.2f)\n', modalities(mi), noiseLevels(n), ...
            thresholds(mi, n, 1), thresholds(mi, n, 2), 4095 * thresholds(mi, n, 1), 4095 * thresholds(mi, n, 2));
    end
end
best = modSummary.modality(modSummary.individualModalityRank == 1);
fprintf('BEST INDIVIDUAL MODALITY (development): %s\n\n', best);


%% 3. Figure

fig = figure('Color', 'w');
ax = axes(fig);
scores = reshape(devSummary.developmentScore, 3, numel(modalities)).';
bh = bar(ax, categorical(modalities, modalities), scores);
legend(ax, "Class " + string(classes), 'Location', 'northwest');
ylabel(ax, 'DevelopmentScore (mean full-volume Dice pn0, pn3)');
hold(ax, 'on');
for mi = 1:numel(modalities)
    x = bh(selected(mi)).XEndPoints(mi);
    plot(ax, x, scores(mi, selected(mi)), 'kv', 'MarkerFaceColor', 'k', 'HandleVisibility', 'off');
end
hold(ax, 'off');
title(ax, 'EXP-040 - single-class candidates per modality (black marker = selected within modality)');
grid(ax, 'on');
fig.Position(3:4) = [900 450];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp040_single_modality_candidate_scores.png'));

fig = figure('Color', 'w');
ax = axes(fig);
bar(ax, categorical(modalities, modalities), [modSummary.dicePn0, modSummary.dicePn3, modSummary.developmentScore]);
legend(ax, 'Dice pn0', 'Dice pn3', 'DevelopmentScore', 'Location', 'northwest');
ylabel(ax, 'full-volume Dice');
title(ax, 'EXP-040 - selected single-modality candidates');
grid(ax, 'on');
fig.Position(3:4) = [800 450];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp040_selected_modality_dice.png'));

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), numel(modalities), 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, {sprintf('EXP-040 %s - selected single-modality predictions (each on its own modality)', ...
        noiseLevels(n)), 'yellow = TP, red = FP, green = FN'}, 'Interpreter', 'none');
    for k = fixedSlices
        for mi = 1:numel(modalities)
            ax = nexttile(layout);
            image(ax, errorOverlay(volumes{mi, n}(:, :, k), predictions{mi, n, selected(mi)}(:, :, k), gtMask(:, :, k)));
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('k=%d %s class %d', k, modalities(mi), selected(mi)), 'FontSize', 8);
        end
    end
    fig.Position(3:4) = [1100 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp040_selected_modalities_%s.png', noiseLevels(n))), ...
        'Resolution', 130);
end


%% Esito dei controlli

checks = [checks; {
    "GT unchanged",                         isequal(gtMask, gtCopy)
    "EXP-021 masks unchanged",              isequal(brainMasks, brainCopies)
    "Phase-71 M_pred unchanged",            isequal(phase71, phase71Copies)
    "config.m unchanged during the run",    isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];
scriptText = fileread([mfilename('fullpath') '.m']);
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['filterComponents' 'ByArea2D('], ['bwarea' 'open('], ['region' 'props'], ['bwconn' 'comp('], ...
    ['imclose' '('], ['imfill' '('], ['imreconstruct' '('], ['regionGrow' 'ing('], ['imgaussfilt' '('], ...
    ['medfilt' '2('], ['imhist' 'match(']};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};
checks(end+1, :) = {"no filtering/components/region growing/preprocessing", ~any(cellfun(@(f) contains(scriptText, f), forbidden))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-62s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp040:checksFailed', 'EXP-040 checks failed.');
end
fprintf('\nEXP-040 CHECKS: PASS (%d)\n', size(checks, 1));


function f = mriPath(cfg, mod, noise)
%MRIPATH Percorso del file MRI configurato per modalità e condizione.
    if noise == cfg.dataset.noiseLevel
        files = cfg.dataset.mriFiles;
    else
        files = cfg.dataset.noisyMriFiles.(char(noise));
    end
    if isfield(files, char(mod))
        f = files.(char(mod));
    else
        f = fullfile(cfg.dataset.rawDir, 'mri', sprintf('%s_ai_msles2_1mm_%s_rf0.raws', lower(char(mod)), noise));
    end
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
