%% EXP-026 (fase 58): soglia multipla (Otsu multi-livello) sulla T2 solo-cervello
% Unico cambiamento rispetto a EXP-024: graythresh (Otsu binario) ->
% multithresh con 2 soglie (3 classi), fissato PRIMA dei risultati.
%   - modalità T2; sviluppo msles2 1 mm rf0, pn0 + pn3; nessun dato held-out
%   - supporto: EXP-021 (pn0 -> pn0, pn3 -> pn3); preprocessing NONE
%   - ingresso a multithresh: brainValues = T2norm(brainMask) (mai zeri
%     artificiali, mai il volume intero); una chiamata per condizione,
%     soglie non modificate (solo conversione esatta single -> double se il
%     built-in restituisce single)
%   - classi: classVolume = imquantize(T2norm, levels); candidato =
%     brainMask & (classVolume == 3), classe più alta scelta a priori
%     (nessuna combinazione di classi)
%   - il GT viene caricato SOLO dopo che entrambe le previsioni sono salvate;
%     serve solo per Dice, DevelopmentScore e conteggi diagnostici
%   - regola di selezione della fase 37 contro EXP-024 (valori letti dal CSV
%     della fase 57), nessuna tolleranza di quasi-parità
%   - nessuna morfologia, nessuna analisi delle componenti, nessuna soglia
%     locale, nessuna armonizzazione.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing);

assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'EXP-026 requires no filter.');

numberOfThresholds = 2;                          % preregistrato: 3 classi
selectedClass = numberOfThresholds + 1;          % classe più alta
prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
t2Files = {cfg.dataset.mriFiles.T2, cfg.dataset.noisyMriFiles.pn3.T2};
expectedSize = [181 217 181];
overlaySlices = [46 91 136];
diagnosticSlice = 102;
maskFile = @(noise) fullfile(cfg.paths.processedData, ...
    sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));
outputFile = @(noise) fullfile(cfg.paths.processedData, ...
    sprintf('exp026_t2_%s_multithresh_candidate.mat', noise));

checks = cell(0, 2);
volumes = cell(1, 2);
brainMasks = cell(1, 2);
classVolumes = cell(1, 2);
candidates = cell(1, 2);
levelsAll = zeros(2, numberOfThresholds);
levelsClass = strings(1, 2);
classCounts = zeros(2, 3);
gtLoaded = false;                                % diventa true solo nella sezione 3


%% 1. Previsioni (senza GT)

for n = 1:2
    noise = noiseLevels(n);
    raw = loadBrainwebMri(cfg, "T2", noise);
    t2 = prepare(raw);
    saved = load(maskFile(noise), 'candidate');
    brainMask = saved.candidate;
    t2Copy = t2;
    maskCopy = brainMask;

    inputChecks = {
        noise + " T2 source file",                     contains(string(t2Files{n}), "t2_ai_msles2_1mm_" + noise + "_rf0")
        noise + " brainMask source = EXP-021 " + noise, isfile(maskFile(noise)) && contains(string(maskFile(noise)), "exp021_t1_" + noise)
        noise + " T2 size 181x217x181",                isequal(size(t2), expectedSize)
        noise + " mask size = T2 size",                isequal(size(brainMask), size(t2))
        noise + " mask logical",                       islogical(brainMask)
        noise + " normalized T2 finite",               all(isfinite(t2(:)))
        noise + " normalized T2 in [0,1]",             min(t2(:)) >= 0 && max(t2(:)) <= 1
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('exp026:technicallyBlocked', 'EXP-026 TECHNICALLY BLOCKED: input checks failed for %s.', noise);
    end

    % Stima automatica a 2 soglie e quantizzazione in 3 classi
    brainValues = t2(brainMask);
    levelsBuiltIn = multithresh(brainValues, numberOfThresholds);
    levelsClass(n) = string(class(levelsBuiltIn));
    levels = double(levelsBuiltIn);              % conversione esatta, nessun arrotondamento
    classVolume = imquantize(t2, levels);
    lesionCandidateMask = brainMask & (classVolume == selectedClass);

    labelsInBrain = unique(classVolume(brainMask));
    for c = 1:3
        classCounts(n, c) = nnz(brainMask & (classVolume == c));
    end

    checks = [checks; {
        noise + " brainValues count = nnz(mask)",         numel(brainValues) == nnz(brainMask)
        noise + " exactly two thresholds",                numel(levels) == 2
        noise + " thresholds finite",                     all(isfinite(levels))
        noise + " thresholds inside [0,1]",               all(levels >= 0 & levels <= 1)
        noise + " threshold 1 < threshold 2",             levels(1) < levels(2)
        noise + " repeated multithresh identical",        isequal(multithresh(brainValues, numberOfThresholds), levelsBuiltIn)
        noise + " exactly labels 1,2,3 inside brain",     isequal(labelsInBrain(:).', 1:3)
        noise + " class counts sum to nnz(mask)",         sum(classCounts(n, :)) == nnz(brainMask)
        noise + " Class 3 = T2norm > T2 inside mask",     isequal(lesionCandidateMask, brainMask & (t2 > levels(2)))
        noise + " candidate logical",                     islogical(lesionCandidateMask)
        noise + " candidate size = T2 size",              isequal(size(lesionCandidateMask), size(t2))
        noise + " no candidate outside brainMask",        ~any(lesionCandidateMask & ~brainMask, 'all')
        noise + " source T2 unchanged",                   isequal(t2, t2Copy) && isequal(raw, loadBrainwebMri(cfg, "T2", noise))
        noise + " brainMask unchanged",                   isequal(brainMask, maskCopy)
        }]; %#ok<AGROW>

    % Mappa delle classi salvata solo dentro il supporto (0 fuori)
    classVolumeInBrain = uint8(classVolume) .* uint8(brainMask);
    metadata = struct('experiment', "EXP-026", 'phase', 58, 'condition', noise, ...
        'sourceT2', string(t2Files{n}), 'sourceBrainMask', string(maskFile(noise)), ...
        'method', "multithresh (multi-level Otsu) on T2norm(brainMask) + imquantize", ...
        'numberOfThresholds', numberOfThresholds, 'numberOfClasses', numberOfThresholds + 1, ...
        'thresholdsNormalized', levels, 'thresholdsRawEquivalent', 4095 * levels, ...
        'thresholdsBuiltInClass', levelsClass(n), 'selectedClass', selectedClass, ...
        'normalization', "uint16 -> double -> /4095", 'preprocessing', "none", ...
        'gtUsedForGeneration', false, ...
        'note', "Highest multithresh class (candidate mask, not a final lesion mask); classVolumeInBrain = 0 outside brainMask.");
    save(outputFile(noise), 'lesionCandidateMask', 'classVolumeInBrain', 'metadata');
    reloaded = load(outputFile(noise), 'lesionCandidateMask', 'classVolumeInBrain', 'metadata');
    checks(end+1, :) = {noise + " saved prediction reloads identically", ...
        isequal(reloaded.lesionCandidateMask, lesionCandidateMask) && ...
        isequal(reloaded.classVolumeInBrain, classVolumeInBrain) && ...
        isequal(reloaded.metadata.thresholdsNormalized, levels)}; %#ok<SAGROW>

    volumes{n} = t2;
    brainMasks{n} = brainMask;
    classVolumes{n} = classVolumeInBrain;
    candidates{n} = lesionCandidateMask;
    levelsAll(n, :) = levels;
end

predictionsFrozen = all(arrayfun(@(noise) isfile(outputFile(noise)), noiseLevels));
checks(end+1, :) = {"GT loaded only after prediction generation", predictionsFrozen && ~gtLoaded};

fprintf('multithresh output class: %s (pn0), %s (pn3)\n', levelsClass(1), levelsClass(2));
for n = 1:2
    fprintf('%s: T1 = %.10f (%.4f raw-eq.), T2 = %.10f (%.4f raw-eq.); classes 1/2/3 = %d / %d / %d\n', ...
        noiseLevels(n), levelsAll(n, 1), 4095 * levelsAll(n, 1), levelsAll(n, 2), 4095 * levelsAll(n, 2), ...
        classCounts(n, 1), classCounts(n, 2), classCounts(n, 3));
end


%% 2. Figure senza GT (istogrammi e mappe delle classi)

exp024 = readtable(fullfile(cfg.paths.metrics, 'exp024_otsu_threshold_summary.csv'), 'TextType', 'string');
histogram40 = readtable(fullfile(cfg.paths.metrics, 'phase40_brain_only_histogram_counts.csv'));
histColumns = {'pn0_T2', 'pn3_T2'};
firstNonZero = min(cellfun(@(col) find(histogram40.(col) > 0, 1), histColumns));
fig = figure('Color', 'w');
layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact');
title(layout, 'EXP-026 - Phase-40 brain-only T2 histograms with multithresh boundaries (dashed: EXP-024 Otsu)', ...
    'Interpreter', 'none');
scales = ["linear" "log"];
for n = 1:2
    counts = histogram40.(histColumns{n});
    for p = 1:2
        ax = nexttile(layout);
        plot(ax, histogram40.RawValue, counts / sum(counts), 'k-');
        xline(ax, 4095 * levelsAll(n, 1), 'b-', sprintf('T1 = %.1f', 4095 * levelsAll(n, 1)), 'LineWidth', 1.3);
        xline(ax, 4095 * levelsAll(n, 2), 'r-', sprintf('T2 = %.1f', 4095 * levelsAll(n, 2)), 'LineWidth', 1.3);
        xline(ax, exp024.thresholdRawEquivalent(exp024.condition == noiseLevels(n)), 'm--', 'Otsu', ...
            'LabelVerticalAlignment', 'bottom');
        set(ax, 'YScale', scales(p));
        xlim(ax, [histogram40.RawValue(firstNonZero) 4095]);
        ylabel(ax, sprintf('fraction (%s)', scales(p)));
        title(ax, sprintf('%s: class 1 | class 2 | class 3 (candidate)', noiseLevels(n)), 'FontSize', 9);
        xlabel(ax, 'raw T2 value');
    end
end
fig.Position(3:4) = [1200 750];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp026_multithresh_histograms.png'));

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 3, numel(overlaySlices), 'TileSpacing', 'compact', 'Padding', 'compact');
    title(layout, sprintf(['EXP-026 T2 %s - multithresh T1 = %.2f, T2 = %.2f raw-eq.: T2 / classes ' ...
        '(blue 1, green 2, yellow 3) / T2 + Class 3 (red)'], noiseLevels(n), 4095 * levelsAll(n, :)), ...
        'Interpreter', 'none');
    for row = 1:3
        for k = overlaySlices
            ax = nexttile(layout);
            switch row
                case 1
                    rgb = candidateOverlay(volumes{n}(:, :, k), candidates{n}(:, :, k), false);
                case 2
                    rgb = classMapRgb(classVolumes{n}(:, :, k));
                case 3
                    rgb = candidateOverlay(volumes{n}(:, :, k), candidates{n}(:, :, k), true);
            end
            image(ax, rgb);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('k=%d', k), 'FontSize', 9);
        end
    end
    fig.Position(3:4) = [1300 1250];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp026_t2_%s_multiclass.png', noiseLevels(n))), ...
        'Resolution', 150);
end


%% 3. Valutazione (GT caricato SOLO ora; previsioni già congelate)

gtLoaded = true;
labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
gtVoxels = nnz(gtMask);
gtCopy = gtMask;
checks = [checks; {
    "GT size = prediction size",            isequal(size(labels), size(candidates{1})) && isequal(size(labels), size(candidates{2}))
    "GT lesion mask = label 10, non-empty", islogical(gtMask) && gtVoxels > 0 && isequal(gtMask, labels == 10)
    }];

% Riferimento EXP-024 dalla fase 57 (valori esatti dal CSV)
phase57 = readtable(fullfile(cfg.paths.metrics, 'exp025_thresholding_method_comparison.csv'), 'TextType', 'string');
phase57ByCondition = readtable(fullfile(cfg.paths.metrics, 'exp025_thresholding_dice_by_condition.csv'), ...
    'TextType', 'string');
otsuRow = phase57(phase57.experiment == "EXP-024", :);
checks(end+1, :) = {"EXP-024 reference row found in Phase-57 CSV", height(otsuRow) == 1};

rows = cell(2, 1);
dice = zeros(1, 2);
for n = 1:2
    prediction = candidates{n};
    intersection = nnz(prediction & gtMask);
    dice(n) = diceCoefficient(prediction, gtMask);
    gtInClass = arrayfun(@(c) nnz(gtMask & classVolumes{n} == c), 1:3);
    gtOutsideBrain = nnz(gtMask & ~brainMasks{n});
    checks = [checks; {
        noiseLevels(n) + " Dice finite in [0,1]",             isfinite(dice(n)) && dice(n) >= 0 && dice(n) <= 1
        noiseLevels(n) + " Dice = 2|P&G|/(|P|+|G|)",          dice(n) == 2 * intersection / (nnz(prediction) + gtVoxels)
        noiseLevels(n) + " GT class counts + outside = GT",   sum(gtInClass) + gtOutsideBrain == gtVoxels
        noiseLevels(n) + " GT in Class 3 = intersection",     gtInClass(3) == intersection
        }]; %#ok<AGROW>
    rows{n} = {noiseLevels(n), levelsAll(n, 1), 4095 * levelsAll(n, 1), levelsAll(n, 2), 4095 * levelsAll(n, 2), ...
        nnz(brainMasks{n}), classCounts(n, 1), classCounts(n, 2), classCounts(n, 3), ...
        classCounts(n, 1) / nnz(brainMasks{n}), classCounts(n, 2) / nnz(brainMasks{n}), ...
        classCounts(n, 3) / nnz(brainMasks{n}), gtVoxels, gtInClass(1), gtInClass(2), gtInClass(3), ...
        gtOutsideBrain, gtVoxels - intersection, nnz(prediction), intersection, dice(n), nnz(prediction) / gtVoxels};
end
summary = cell2table(vertcat(rows{:}), 'VariableNames', {'condition', 'threshold1Normalized', ...
    'threshold1RawEquivalent', 'threshold2Normalized', 'threshold2RawEquivalent', 'brainMaskVoxels', ...
    'class1Voxels', 'class2Voxels', 'class3Voxels', 'class1FractionBrain', 'class2FractionBrain', ...
    'class3FractionBrain', 'gtLesionVoxels', 'gtInClass1', 'gtInClass2', 'gtInClass3', 'gtOutsideBrainMask', ...
    'gtNotCapturedByClass3', 'candidateVoxels', 'intersectionVoxels', 'dice', 'candidateToGtRatio'});
writetable(summary, fullfile(cfg.paths.metrics, 'exp026_multithresh_summary.csv'));

% Regola della fase 37 (preregistrata, nessuna tolleranza)
score026 = (dice(1) + dice(2)) / 2;
weaker026 = min(dice);
score024 = otsuRow.developmentScore;
weaker024 = otsuRow.weakerConditionDice;
if score026 > score024
    decision = "KEEP";
elseif score026 < score024
    decision = "REJECT";
elseif weaker026 > weaker024
    decision = "KEEP";                           % parità esatta: condizione più debole
else
    decision = "REJECT";                         % parità esatta: Otsu binario più semplice
end
comparison = table(["Otsu global threshold"; "Multi-threshold (multithresh N=2, Class 3)"], ...
    ["EXP-024"; "EXP-026"], [otsuRow.dicePn0; dice(1)], [otsuRow.dicePn3; dice(2)], [weaker024; weaker026], ...
    [score024; score026], [decision == "REJECT"; decision == "KEEP"], 'VariableNames', {'method', 'experiment', ...
    'dicePn0', 'dicePn3', 'weakerConditionDice', 'developmentScore', 'selectedCurrentBaseline'});
writetable(comparison, fullfile(cfg.paths.metrics, 'exp026_vs_otsu_comparison.csv'));
reloadedComparison = readtable(fullfile(cfg.paths.metrics, 'exp026_vs_otsu_comparison.csv'), 'TextType', 'string');

checks = [checks; {
    "DevelopmentScore = (pn0 + pn3)/2 exactly",  score026 == (dice(1) + dice(2)) / 2
    "exactly one selected method",               nnz(comparison.selectedCurrentBaseline) == 1
    "saved comparison CSV reproduces scores",    max(abs(reloadedComparison.developmentScore - comparison.developmentScore)) < 1e-12
    "GT mask unchanged",                         isequal(gtMask, gtCopy)
    }];

disp(summary);
disp(comparison);
fprintf('DevelopmentScore EXP-026 - EXP-024 = %.10f\n', score026 - score024);
for n = 1:2
    r57 = phase57ByCondition(phase57ByCondition.experiment == "EXP-024" & phase57ByCondition.condition == noiseLevels(n), :);
    fprintf('%s: candidates EXP-026 / EXP-024 = %d / %d; GT captured EXP-026 / EXP-024 = %d / %d\n', ...
        noiseLevels(n), summary.candidateVoxels(n), r57.predictedVoxels, summary.intersectionVoxels(n), ...
        r57.intersectionVoxels);
end
fprintf('DECISION: %s EXP-026\n\n', decision);


%% 4. Figura diagnostica GT (dopo la valutazione; non influisce sulla decisione)
% k = 102: slice diagnostica già nota dalla fase 57.

fig = figure('Color', 'w');
layout = tiledlayout(fig, 2, 4, 'TileSpacing', 'tight', 'Padding', 'tight');
title(layout, sprintf(['EXP-026 diagnostic (after scoring), k = %d: T2 / Class 3 / GT / ' ...
    'yellow = Class 3 & GT, red = Class 3 only, green = GT only'], diagnosticSlice), 'Interpreter', 'none');
k = diagnosticSlice;
for n = 1:2
    panels = {candidateOverlay(volumes{n}(:, :, k), candidates{n}(:, :, k), false), ...
        candidateOverlay(volumes{n}(:, :, k), candidates{n}(:, :, k), true), ...
        candidateOverlay(volumes{n}(:, :, k), gtMask(:, :, k), true), ...
        errorOverlay(volumes{n}(:, :, k), candidates{n}(:, :, k), gtMask(:, :, k))};
    names = ["T2", "Class 3", "GT", "overlay"];
    for p = 1:4
        ax = nexttile(layout);
        image(ax, panels{p});
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, noiseLevels(n) + " " + names(p), 'FontSize', 9);
    end
end
fig.Position(3:4) = [1500 800];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp026_t2_gt_diagnostic_k102.png'), 'Resolution', 150);


%% Esito dei controlli

scriptText = fileread([mfilename('fullpath') '.m']);
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['gray' 'thresh('], ['imerode' '('], ['imdilate' '('], ['imopen' '('], ['imclose' '('], ...
    ['imfill' '('], ['bwconn' 'comp('], ['region' 'props('], ['bwarea' 'open(']};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};
checks(end+1, :) = {"no Otsu-binary/morphology/components called", ~any(cellfun(@(f) contains(scriptText, f), forbidden))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-48s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp026:checksFailed', 'EXP-026 technical checks failed.');
end
fprintf('\nEXP-026 CHECKS: PASS (%d)\n', size(checks, 1));


function dice = diceCoefficient(prediction, reference)
%DICECOEFFICIENT Dice 3D sul volume completo: 2|P & G| / (|P| + |G|).
    denominator = nnz(prediction) + nnz(reference);
    if denominator == 0
        error('exp026:emptyDice', 'Dice undefined for two empty masks.');
    end
    dice = 2 * nnz(prediction & reference) / denominator;
end

function rgb = candidateOverlay(sliceImage, maskSlice, showMask)
%CANDIDATEOVERLAY T2 in scala di grigi con la maschera in rosso (solo visualizzazione).
    gray = sliceImage.';
    red = gray; green = gray; blue = gray;
    if showMask
        m = maskSlice.';
        red(m) = 1;
        green(m) = 0;
        blue(m) = 0;
    end
    rgb = cat(3, red, green, blue);
end

function rgb = classMapRgb(classSlice)
%CLASSMAPRGB Mappa delle 3 classi (0 fuori dal cervello = nero).
    palette = [0 0 0; 0.20 0.35 0.85; 0.30 0.70 0.30; 1.00 0.90 0.10];
    idx = double(classSlice.') + 1;
    rgb = reshape(palette(idx, :), [size(idx) 3]);
end

function rgb = errorOverlay(sliceImage, predictionSlice, gtSlice)
%ERROROVERLAY T2 con previsione e GT a colori (solo visualizzazione diagnostica).
    gray = sliceImage.';
    p = predictionSlice.';
    g = gtSlice.';
    red = gray; green = gray; blue = gray;
    both = p & g; onlyP = p & ~g; onlyG = ~p & g;
    red(both) = 1; green(both) = 1; blue(both) = 0;
    red(onlyP) = 1; green(onlyP) = 0; blue(onlyP) = 0;
    red(onlyG) = 0; green(onlyG) = 1; blue(onlyG) = 0;
    rgb = cat(3, red, green, blue);
end
