%% EXP-027 (fase 59): soglia variabile / locale sulla T2 (media e deviazione standard locali)
% Formula del corso: T(x,y) = a * m(x,y) + b * s(x,y); candidato se
% I(x,y) > T(x,y) (confronto STRETTO).
%   - modalità T2; sviluppo msles2 1 mm rf0, pn0 + pn3; nessun dato held-out
%   - supporto: EXP-021 (pn0 -> pn0, pn3 -> pn3); preprocessing NONE
%   - elaborazione 2D, slice assiale per slice assiale (nessuna finestra 3D);
%     le 181 slice binarie formano il volume 3D dei candidati
%   - statistiche MASCHERATE: nella finestra quadrata contano solo i pixel
%     di brainMask; finestra troncata al bordo dell'immagine; deviazione
%     standard di POPOLAZIONE sqrt(E[x^2] - E[x]^2) (scelte di progetto)
%   - statistiche calcolate sui livelli grezzi interi (somme esatte), poi
%     T diviso per 4095; candidato = brainMask & (T2norm > T), T non limitata
%   - griglia preregistrata (log, prima dell'esecuzione): a = 1,
%     windowSize in {9, 21, 41}, b in {0.5, 1.0, 1.5} -> 9 configurazioni,
%     uguali per pn0 e pn3
%   - il GT viene caricato SOLO dopo che tutte le 18 previsioni sono salvate
%   - selezione: DevelopmentScore della fase 37 (nessuna tolleranza), poi
%     confronto con EXP-026 (valori dal CSV salvato)
%   - nessuna combinazione con soglie globali, nessuna morfologia, nessuna
%     analisi delle componenti, nessun filtro, nessuna armonizzazione.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'EXP-027 requires no filter.');

% Griglia preregistrata (NON modificare dopo i risultati)
a = 1.0;
windowSizes = [9 21 41];
bValues = [0.5 1.0 1.5];
[bGrid, wGrid] = meshgrid(bValues, windowSizes);
grid = table(compose("W%02d_B%02d", wGrid(:), round(10 * bGrid(:))), wGrid(:), repmat(a, numel(wGrid), 1), ...
    bGrid(:), 'VariableNames', {'configuration', 'windowSize', 'a', 'b'});
grid = sortrows(grid, {'windowSize', 'b'});
nConfigs = height(grid);

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);
rawScale = cfg.preprocessing.normalization.inputRange(2);   % 4095

noiseLevels = ["pn0" "pn3"];
t2Files = {cfg.dataset.mriFiles.T2, cfg.dataset.noisyMriFiles.pn3.T2};
expectedSize = [181 217 181];
nSlices = expectedSize(3);
overlaySlices = [46 91 136];
diagnosticSlice = 102;
maskFile = @(noise) fullfile(cfg.paths.processedData, ...
    sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));
outputFile = @(noise, configuration) fullfile(cfg.paths.processedData, ...
    sprintf('exp027_t2_%s_local_%s_candidate.mat', noise, configuration));

checks = cell(0, 2);
checks = [checks; {
    "exactly 9 configurations",              nConfigs == 9
    "a = 1 for all configurations",          all(grid.a == 1)
    "window sizes exactly {9, 21, 41}",      isequal(unique(grid.windowSize).', [9 21 41])
    "b exactly {0.5, 1.0, 1.5}",             isequal(unique(grid.b).', [0.5 1.0 1.5])
    "all windows odd",                       all(mod(grid.windowSize, 2) == 1)
    "configuration IDs unique",              numel(unique(grid.configuration)) == nConfigs
    }];
disp(grid);

volumes = cell(1, 2);
rawVolumes = cell(1, 2);
brainMasks = cell(1, 2);
candidates = cell(nConfigs, 2);
mapStats = zeros(nConfigs, 2, 8);    % min, max, mean, median, std di T; min, max, mediana di N
gtLoaded = false;                    % diventa true solo nella sezione 2


%% 1. Previsioni per tutte le 9 configurazioni e le 2 condizioni (senza GT)

for n = 1:2
    noise = noiseLevels(n);
    raw = loadBrainwebMri(cfg, "T2", noise);
    t2 = prepare(raw);
    rawLevels = double(raw);
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
        noise + " raw levels integer, T2norm = raw/4095", all(rawLevels(:) == round(rawLevels(:))) && ...
                                                       isequal(t2, rawLevels / rawScale)
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('exp027:technicallyBlocked', 'EXP-027 TECHNICALLY BLOCKED: input checks failed for %s.', noise);
    end

    % Volume di controllo: valori fuori maschera alterati (devono essere ininfluenti)
    rawAltered = rawLevels;
    rawAltered(~brainMask) = rawScale;

    for g = 1:nConfigs
        w = grid.windowSize(g);
        b = grid.b(g);
        thresholdNorm = NaN(size(t2));
        functionCandidate = false(size(t2));
        localCount = zeros(size(t2));
        localMean = NaN(size(t2));
        localStd = NaN(size(t2));
        outsideInvariant = true;
        for k = 1:nSlices
            [cand, T, m, s, N] = localMeanStdThreshold2D(rawLevels(:, :, k), brainMask(:, :, k), w, a, b);
            [candAlt, TAlt] = localMeanStdThreshold2D(rawAltered(:, :, k), brainMask(:, :, k), w, a, b);
            outsideInvariant = outsideInvariant && isequaln(T, TAlt) && isequal(cand, candAlt);
            thresholdNorm(:, :, k) = T / rawScale;
            functionCandidate(:, :, k) = cand;
            localCount(:, :, k) = N;
            localMean(:, :, k) = m;
            localStd(:, :, k) = s;
        end
        % Regola autorevole nella scala normalizzata
        lesionCandidateMask = brainMask & (t2 > thresholdNorm);

        label = noise + " " + grid.configuration(g);
        tIn = thresholdNorm(brainMask);
        nIn = localCount(brainMask);
        checks = [checks; {
            label + " outside-mask values do not contribute", outsideInvariant
            label + " in-mask local counts >= 1",              all(nIn >= 1)
            label + " local means finite",                     all(isfinite(localMean(brainMask)))
            label + " local std finite and >= 0",              all(isfinite(localStd(brainMask)) & localStd(brainMask) >= 0)
            label + " threshold map finite inside mask",       all(isfinite(tIn))
            label + " candidate = mask & (T2norm > Tlocal)",   isequal(lesionCandidateMask, brainMask & (t2 > thresholdNorm))
            label + " normalized rule = raw-level rule",       isequal(lesionCandidateMask, functionCandidate)
            label + " output logical",                         islogical(lesionCandidateMask)
            label + " output size 181x217x181",                isequal(size(lesionCandidateMask), expectedSize)
            label + " no candidate outside brainMask",         ~any(lesionCandidateMask & ~brainMask, 'all')
            }]; %#ok<AGROW>
        mapStats(g, n, :) = [min(tIn), max(tIn), mean(tIn), median(tIn), std(tIn, 1), ...
            min(nIn), max(nIn), median(nIn)];

        metadata = struct('experiment', "EXP-027", 'phase', 59, 'configuration', grid.configuration(g), ...
            'condition', noise, 'windowSize', w, 'a', a, 'b', b, ...
            'formula', "T = a*m + b*s (masked local mean, population std); candidate = brainMask & (T2norm > T)", ...
            'processingDimensionality', "2D axial slice-wise", ...
            'normalization', "uint16 -> double -> /4095 (statistics on integer raw levels, T / 4095)", ...
            'preprocessing', "none", 'sourceT2', string(t2Files{n}), 'sourceBrainMask', string(maskFile(noise)), ...
            'gtUsedForGeneration', false);
        save(outputFile(noise, grid.configuration(g)), 'lesionCandidateMask', 'metadata');
        reloaded = load(outputFile(noise, grid.configuration(g)), 'lesionCandidateMask');
        checks(end+1, :) = {label + " saved prediction reloads identically", ...
            isequal(reloaded.lesionCandidateMask, lesionCandidateMask)}; %#ok<SAGROW>
        candidates{g, n} = lesionCandidateMask;
        fprintf('%s: %d candidate voxels (%.4f of brain mask)\n', label, nnz(lesionCandidateMask), ...
            nnz(lesionCandidateMask) / nnz(brainMask));
    end

    checks = [checks; {
        noise + " source T2 unchanged",   isequal(t2, t2Copy) && isequal(raw, loadBrainwebMri(cfg, "T2", noise))
        noise + " brainMask unchanged",   isequal(brainMask, maskCopy)
        }]; %#ok<AGROW>
    volumes{n} = t2;
    rawVolumes{n} = rawLevels;
    brainMasks{n} = brainMask;
end

allSaved = true;
for g = 1:nConfigs
    for n = 1:2
        allSaved = allSaved && isfile(outputFile(noiseLevels(n), grid.configuration(g)));
    end
end
checks(end+1, :) = {"all 18 predictions saved before GT loading", allSaved && ~gtLoaded};
checks(end+1, :) = {"same 9-configuration grid for pn0 and pn3", all(~cellfun(@isempty, candidates(:)))};


%% 2. Valutazione (GT caricato SOLO ora)

gtLoaded = true;
labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
gtVoxels = nnz(gtMask);
gtCopy = gtMask;
checks = [checks; {
    "GT size = prediction size",                 isequal(size(labels), expectedSize)
    "GT lesion mask = label 10, non-empty",      isequal(gtMask, labels == 10) && gtVoxels > 0
    "GT not intersected with brainMask",         gtVoxels == nnz(labels == 10)
    }];

gridRows = cell(nConfigs * 2, 1);
dice = zeros(nConfigs, 2);
r = 0;
for g = 1:nConfigs
    for n = 1:2
        prediction = candidates{g, n};
        intersection = nnz(prediction & gtMask);
        dice(g, n) = diceCoefficient(prediction, gtMask);
        checks(end+1, :) = {noiseLevels(n) + " " + grid.configuration(g) + " Dice full-volume formula", ...
            isfinite(dice(g, n)) && dice(g, n) >= 0 && dice(g, n) <= 1 && ...
            numel(prediction) == prod(expectedSize) && ...
            dice(g, n) == 2 * intersection / (nnz(prediction) + gtVoxels)}; %#ok<SAGROW>
        r = r + 1;
        st = squeeze(mapStats(g, n, :)).';
        gridRows{r} = {grid.configuration(g), grid.windowSize(g), a, grid.b(g), noiseLevels(n), ...
            nnz(prediction), gtVoxels, intersection, gtVoxels - intersection, nnz(prediction) / gtVoxels, ...
            dice(g, n), st(1), st(2), st(3), st(4), st(5), st(6), st(7), st(8)};
    end
end
gridTable = cell2table(vertcat(gridRows{:}), 'VariableNames', {'configuration', 'windowSize', 'a', 'b', ...
    'condition', 'candidateVoxels', 'gtVoxels', 'intersectionVoxels', 'missedGtVoxels', 'candidateToGtRatio', ...
    'dice', 'thresholdMin', 'thresholdMax', 'thresholdMean', 'thresholdMedian', 'thresholdStd', ...
    'neighborCountMin', 'neighborCountMax', 'neighborCountMedian'});
writetable(gridTable, fullfile(cfg.paths.metrics, 'exp027_local_threshold_grid.csv'));

% Decisione A: migliore configurazione locale (fase 37, nessuna tolleranza)
developmentScore = (dice(:, 1) + dice(:, 2)) / 2;
weakerConditionDice = min(dice, [], 2);
[~, order] = sortrows([-developmentScore, -weakerConditionDice]);
rank = zeros(nConfigs, 1);
rank(order) = 1:nConfigs;
top = order(1);
unresolvedTie = any(developmentScore == developmentScore(top) & weakerConditionDice == weakerConditionDice(top) ...
    & (1:nConfigs).' ~= top);
selectedBestLocal = false(nConfigs, 1);
selectedBestLocal(top) = ~unresolvedTie;
configComparison = [grid, table(dice(:, 1), dice(:, 2), weakerConditionDice, developmentScore, rank, ...
    selectedBestLocal, 'VariableNames', {'dicePn0', 'dicePn3', 'weakerConditionDice', 'developmentScore', ...
    'rank', 'selectedBestLocal'})];
configComparison = sortrows(configComparison, 'rank');
writetable(configComparison, fullfile(cfg.paths.metrics, 'exp027_local_threshold_config_comparison.csv'));
disp(configComparison);
if unresolvedTie
    error('exp027:unresolvedTie', ['Exact tie for the best local configuration after the ' ...
        'weaker-condition Dice: reported as UNRESOLVED (no further criterion was declared).']);
end
best = top;
bestId = grid.configuration(best);

% Decisione B: migliore locale contro EXP-026 (valori esatti dal CSV)
exp026 = readtable(fullfile(cfg.paths.metrics, 'exp026_vs_otsu_comparison.csv'), 'TextType', 'string');
ref = exp026(exp026.experiment == "EXP-026", :);
checks(end+1, :) = {"EXP-026 reference loaded from saved CSV", height(ref) == 1};
scoreBest = developmentScore(best);
if scoreBest > ref.developmentScore
    decision = "KEEP";
elseif scoreBest < ref.developmentScore
    decision = "REJECT";
elseif weakerConditionDice(best) > ref.weakerConditionDice
    decision = "KEEP";                           % parità esatta: condizione più debole
else
    decision = "REJECT";                         % parità esatta: EXP-026 più semplice
end
baseline = table(["Multi-threshold (multithresh N=2, Class 3)"; "Best local threshold (T = a*m + b*s)"], ...
    ["EXP-026"; "EXP-027"], ["N=2, Class 3"; bestId], [ref.dicePn0; dice(best, 1)], [ref.dicePn3; dice(best, 2)], ...
    [ref.weakerConditionDice; weakerConditionDice(best)], [ref.developmentScore; scoreBest], ...
    [decision == "REJECT"; decision == "KEEP"], 'VariableNames', {'method', 'experiment', 'configuration', ...
    'dicePn0', 'dicePn3', 'weakerConditionDice', 'developmentScore', 'selectedCurrentBaseline'});
writetable(baseline, fullfile(cfg.paths.metrics, 'exp027_vs_exp026_comparison.csv'));
reloadedBaseline = readtable(fullfile(cfg.paths.metrics, 'exp027_vs_exp026_comparison.csv'), 'TextType', 'string');

checks = [checks; {
    "DevelopmentScore = (pn0 + pn3)/2 exactly",     all(developmentScore == (dice(:, 1) + dice(:, 2)) / 2)
    "exactly one best-local configuration",          nnz(selectedBestLocal) == 1
    "best local has max DevelopmentScore",           scoreBest == max(developmentScore)
    "KEEP/REJECT follows score rule",                (decision == "KEEP") == (scoreBest > ref.developmentScore) || ...
                                                     scoreBest == ref.developmentScore
    "exactly one current baseline",                  nnz(baseline.selectedCurrentBaseline) == 1
    "saved comparison CSV reproduces scores",        max(abs(reloadedBaseline.developmentScore - baseline.developmentScore)) < 1e-12
    "GT mask unchanged",                             isequal(gtMask, gtCopy)
    }];

disp(baseline);
fprintf('Best local configuration: %s; DevelopmentScore best local - EXP-026 = %.10f\n', ...
    bestId, scoreBest - ref.developmentScore);
exp026Summary = readtable(fullfile(cfg.paths.metrics, 'exp026_multithresh_summary.csv'), 'TextType', 'string');
for n = 1:2
    exp026Mask = load(fullfile(cfg.paths.processedData, ...
        sprintf('exp026_t2_%s_multithresh_candidate.mat', noiseLevels(n))), 'lesionCandidateMask');
    bestMask = candidates{best, n};
    fprintf(['%s: candidates best local / EXP-026 = %d / %d; GT captured = %d / %d; ' ...
        'EXP-026 candidates also selected by best local = %d; best-local-only voxels = %d\n'], noiseLevels(n), ...
        nnz(bestMask), exp026Summary.candidateVoxels(n), nnz(bestMask & gtMask), ...
        exp026Summary.intersectionVoxels(n), nnz(bestMask & exp026Mask.lesionCandidateMask), ...
        nnz(bestMask & ~exp026Mask.lesionCandidateMask));
end
fprintf('DECISION: %s EXP-027\n\n', decision);


%% 3. Figure (dopo la selezione numerica; non la modificano)

% Griglia dei DevelopmentScore
fig = figure('Color', 'w');
scoreGrid = reshape(developmentScore, numel(bValues), numel(windowSizes)).';   % righe = finestre
hm = heatmap(fig, string(bValues), string(windowSizes), scoreGrid);
hm.XLabel = 'b';
hm.YLabel = 'windowSize';
hm.Title = sprintf('EXP-027 DevelopmentScore (a = 1); best %s = %.6f, EXP-026 = %.6f', ...
    bestId, scoreBest, ref.developmentScore);
hm.CellLabelFormat = '%.4f';
fig.Position(3:4) = [700 450];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp027_local_threshold_grid_scores.png'));

% Configurazione migliore: T2 / mappa di soglia / candidati
wBest = grid.windowSize(best);
bBest = grid.b(best);
for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 3, numel(overlaySlices), 'TileSpacing', 'compact', 'Padding', 'compact');
    title(layout, sprintf(['EXP-027 best local %s (w = %d, a = 1, b = %.1f), T2 %s: T2 / ' ...
        'threshold map (normalized, [0 1]) / T2 + candidates (red)'], bestId, wBest, bBest, noiseLevels(n)), ...
        'Interpreter', 'none');
    for row = 1:3
        for k = overlaySlices
            ax = nexttile(layout);
            switch row
                case 1
                    image(ax, candidateOverlay(volumes{n}(:, :, k), candidates{best, n}(:, :, k), false));
                case 2
                    [~, T] = localMeanStdThreshold2D(rawVolumes{n}(:, :, k), brainMasks{n}(:, :, k), wBest, a, bBest);
                    map = (T / rawScale).';
                    imagesc(ax, map, 'AlphaData', ~isnan(map));
                    set(ax, 'Color', 'k', 'CLim', [0 1]);
                    colormap(ax, parula);
                    if k == overlaySlices(end)
                        colorbar(ax);
                    end
                case 3
                    image(ax, candidateOverlay(volumes{n}(:, :, k), candidates{best, n}(:, :, k), true));
            end
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('k=%d', k), 'FontSize', 9);
        end
    end
    fig.Position(3:4) = [1300 1250];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp027_best_local_%s.png', noiseLevels(n))), ...
        'Resolution', 150);
end

% Diagnostica GT (dopo il punteggio), k = 102
fig = figure('Color', 'w');
layout = tiledlayout(fig, 2, 4, 'TileSpacing', 'tight', 'Padding', 'tight');
title(layout, sprintf(['EXP-027 diagnostic (after scoring), %s, k = %d: T2 / candidates / GT / ' ...
    'yellow = both, red = candidate only, green = GT only'], bestId, diagnosticSlice), 'Interpreter', 'none');
k = diagnosticSlice;
names = ["T2", "best local", "GT", "overlay"];
for n = 1:2
    panels = {candidateOverlay(volumes{n}(:, :, k), candidates{best, n}(:, :, k), false), ...
        candidateOverlay(volumes{n}(:, :, k), candidates{best, n}(:, :, k), true), ...
        candidateOverlay(volumes{n}(:, :, k), gtMask(:, :, k), true), ...
        errorOverlay(volumes{n}(:, :, k), candidates{best, n}(:, :, k), gtMask(:, :, k))};
    for p = 1:4
        ax = nexttile(layout);
        image(ax, panels{p});
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, noiseLevels(n) + " " + names(p), 'FontSize', 9);
    end
end
fig.Position(3:4) = [1500 800];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp027_t2_gt_diagnostic_k102.png'), 'Resolution', 150);


%% Esito dei controlli

scriptText = fileread([mfilename('fullpath') '.m']);
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['imerode' '('], ['imdilate' '('], ['imopen' '('], ['imclose' '('], ['imfill' '('], ...
    ['imreconstruct' '('], ['bwconn' 'comp('], ['region' 'props('], ['bwarea' 'open('], ...
    ['multi' 'thresh('], ['gray' 'thresh(']};
checks(end+1, :) = {"only development conditions used", isequal(noiseLevels, ["pn0" "pn3"])};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};
checks(end+1, :) = {"no morphology/components/global threshold called", ~any(cellfun(@(f) contains(scriptText, f), forbidden))};

% I controlli per singola configurazione (etichetta "pnX Wxx_Byy ...") si
% stampano solo se falliti; tutti gli altri sempre.
failed = ~[checks{:, 2}];
perConfiguration = ~cellfun(@isempty, regexp(string(checks(:, 1)), '^pn[03] W\d\d_B\d\d', 'once'));
for c = 1:size(checks, 1)
    if failed(c)
        fprintf('%-58s FAILED\n', checks{c, 1});
    elseif ~perConfiguration(c)
        fprintf('%-58s ok\n', checks{c, 1});
    end
end
fprintf('Per-configuration checks: %d, failed: %d\n', nnz(perConfiguration), nnz(perConfiguration(:) & failed(:)));
if any(failed)
    error('exp027:checksFailed', 'EXP-027 technical checks failed.');
end
fprintf('\nEXP-027 CHECKS: PASS (%d)\n', size(checks, 1));

function dice = diceCoefficient(prediction, reference)
%DICECOEFFICIENT Dice 3D sul volume completo: 2|P & G| / (|P| + |G|).
    denominator = nnz(prediction) + nnz(reference);
    if denominator == 0
        error('exp027:emptyDice', 'Dice undefined for two empty masks.');
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
