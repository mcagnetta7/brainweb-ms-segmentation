%% EXP-024 (fase 56): soglia globale di Otsu sulla T2 solo-cervello
% Stima AUTOMATICA della soglia con il built-in del corso graythresh (Otsu).
%   - modalità T2; sviluppo msles2 1 mm rf0, pn0 + pn3; nessun dato held-out
%   - supporto: EXP-021 (pn0 -> pn0, pn3 -> pn3); preprocessing NONE
%   - ingresso a graythresh: brainValues = T2norm(brainMask) (mai zeri
%     artificiali, mai il volume intero)
%   - T_otsu = graythresh(brainValues), una sola chiamata per condizione,
%     nessuna modifica; stesso algoritmo per pn0 e pn3 (soglie diverse
%     ammesse). Nota: su dati double graythresh usa un istogramma interno a
%     256 bin su [0,1], quindi T_otsu è un multiplo di 1/255 (comportamento
%     del built-in, non una regolazione)
%   - candidati: thresholdLesionCandidates(T2norm, brainMask, T_otsu), cioè
%     confronto STRETTO ">" (contratto della fase 53, invariato)
%   - nessun GT, nessuna metrica sulle lesioni, nessuna regolazione, nessuna
%     morfologia, nessuna analisi delle componenti.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'EXP-024 requires no filter.');

comparator = ">";
prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
t2Files = {cfg.dataset.mriFiles.T2, cfg.dataset.noisyMriFiles.pn3.T2};
expectedSize = [181 217 181];
nSlices = expectedSize(3);
overlaySlices = [46 91 136];
contactSlices = 1:10:nSlices;
maskFile = @(noise) fullfile(cfg.paths.processedData, ...
    sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));
outputFile = @(noise) fullfile(cfg.paths.processedData, ...
    sprintf('exp024_t2_%s_otsu_threshold_candidate.mat', noise));

checks = cell(0, 2);
volumes = cell(1, 2);
candidates = cell(1, 2);
otsuThresholds = zeros(1, 2);
rows = cell(2, 1);

for n = 1:2
    noise = noiseLevels(n);
    raw = loadBrainwebMri(cfg, "T2", noise);
    t2 = prepare(raw);
    saved = load(maskFile(noise), 'candidate');
    brainMask = saved.candidate;
    t2Copy = t2;
    maskCopy = brainMask;

    inputChecks = {
        noise + " T2 size 181x217x181",        isequal(size(t2), expectedSize)
        noise + " mask size = T2 size",        isequal(size(brainMask), size(t2))
        noise + " mask logical",               islogical(brainMask)
        noise + " normalized T2 finite",       all(isfinite(t2(:)))
        noise + " normalized T2 in [0,1]",     min(t2(:)) >= 0 && max(t2(:)) <= 1
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('exp024:technicallyBlocked', 'EXP-024 TECHNICALLY BLOCKED: input checks failed for %s.', noise);
    end

    % Stima automatica e candidati (nessun intervento manuale)
    brainValues = t2(brainMask);
    T_otsu = graythresh(brainValues);
    lesionCandidateMask = thresholdLesionCandidates(t2, brainMask, T_otsu);

    checks = [checks; {
        noise + " brainValues finite",                   all(isfinite(brainValues))
        noise + " brainValues count = nnz(mask)",        numel(brainValues) == nnz(brainMask)
        noise + " T_otsu numeric real scalar",           isnumeric(T_otsu) && isreal(T_otsu) && isscalar(T_otsu)
        noise + " T_otsu finite in [0,1]",               isfinite(T_otsu) && T_otsu >= 0 && T_otsu <= 1
        noise + " repeated graythresh identical",        graythresh(brainValues) == T_otsu
        noise + " output size = T2 size",                isequal(size(lesionCandidateMask), size(t2))
        noise + " output logical",                       islogical(lesionCandidateMask)
        noise + " output = brainMask & (T2norm > T)",    isequal(lesionCandidateMask, brainMask & (t2 > T_otsu))
        noise + " no candidate outside brainMask",       ~any(lesionCandidateMask & ~brainMask, 'all')
        noise + " source T2 unchanged",                  isequal(t2, t2Copy) && isequal(raw, loadBrainwebMri(cfg, "T2", noise))
        noise + " brainMask unchanged",                  isequal(brainMask, maskCopy)
        }]; %#ok<AGROW>

    metadata = struct('experiment', "EXP-024", 'phase', 56, 'condition', noise, ...
        'sourceT2', string(t2Files{n}), 'sourceBrainMask', string(maskFile(noise)), ...
        'estimator', "graythresh (Otsu) on T2norm(brainMask)", ...
        'thresholdNormalized', T_otsu, 'thresholdRawEquivalent', 4095 * T_otsu, ...
        'comparator', comparator, 'normalization', "uint16 -> double -> /4095", 'preprocessing', "none", ...
        'gtUsed', false, ...
        'note', "Automatic Otsu threshold (graythresh, built-in 256-bin histogram); candidate mask, not a final lesion mask.");
    save(outputFile(noise), 'lesionCandidateMask', 'metadata');
    reloaded = load(outputFile(noise), 'lesionCandidateMask', 'metadata');
    checks(end+1, :) = {noise + " saved candidate reloads identically", ...
        isequal(reloaded.lesionCandidateMask, lesionCandidateMask) && ...
        reloaded.metadata.thresholdNormalized == T_otsu}; %#ok<SAGROW>

    candidateRaw = double(raw(lesionCandidateMask));
    sliceHasCandidate = squeeze(any(lesionCandidateMask, [1 2]));
    candidateSlices = find(sliceHasCandidate);
    if isempty(candidateSlices)
        candidateSlices = 0;
        candidateRaw = NaN;
        warning('exp024:noCandidates', 'No candidates for %s.', noise);
    end
    rows{n} = {noise, T_otsu, 4095 * T_otsu, numel(t2), nnz(brainMask), nnz(lesionCandidateMask), ...
        nnz(lesionCandidateMask) / nnz(brainMask), nnz(lesionCandidateMask) / numel(t2), ...
        nnz(sliceHasCandidate), candidateSlices(1), candidateSlices(end), ...
        min(candidateRaw), max(candidateRaw), mean(candidateRaw), median(candidateRaw)};
    checks(end+1, :) = {noise + " candidate count = nnz(output)", rows{n}{6} == nnz(lesionCandidateMask)}; %#ok<SAGROW>

    volumes{n} = t2;
    candidates{n} = lesionCandidateMask;
    otsuThresholds(n) = T_otsu;
end

scriptText = fileread([mfilename('fullpath') '.m']);
checks(end+1, :) = {"no GT loader referenced in this script", ...
    ~contains(scriptText, ['loadBrainweb' 'GroundTruth']) && ~contains(scriptText, ['groundTruth' 'File'])};

if any(~[checks{:, 2}])
    for c = 1:size(checks, 1)
        fprintf('%-46s %d\n', checks{c, 1}, checks{c, 2});
    end
    error('exp024:checksFailed', 'EXP-024 technical checks failed.');
end


%% Tabella riassuntiva e confronto descrittivo con EXP-022 / EXP-023 (dai CSV salvati)

summary = cell2table(vertcat(rows{:}), 'VariableNames', {'condition', 'thresholdNormalized', ...
    'thresholdRawEquivalent', 'totalVoxels', 'brainMaskVoxels', 'candidateVoxels', 'candidateFractionBrain', ...
    'candidateFractionWholeVolume', 'nonEmptySlices', 'firstCandidateSlice', 'lastCandidateSlice', ...
    'candidateMinIntensityRaw', 'candidateMaxIntensityRaw', 'candidateMeanIntensityRaw', ...
    'candidateMedianIntensityRaw'});
disp(summary);
writetable(summary, fullfile(cfg.paths.metrics, 'exp024_otsu_threshold_summary.csv'));

exp022 = readtable(fullfile(cfg.paths.metrics, 'exp022_manual_global_threshold_summary.csv'), 'TextType', 'string');
exp023 = readtable(fullfile(cfg.paths.metrics, 'exp023_iterative_threshold_summary.csv'), 'TextType', 'string');
for n = 1:2
    r22 = exp022(exp022.condition == noiseLevels(n), :);
    r23 = exp023(exp023.condition == noiseLevels(n), :);
    fprintf(['%s: T_otsu = %.6f (%.4f raw-eq.); T_otsu - EXP-022 = %.4f; T_otsu - EXP-023 = %.4f; ' ...
        'candidate fraction EXP-024 / EXP-022 / EXP-023 = %.6f / %.6f / %.6f\n'], noiseLevels(n), ...
        otsuThresholds(n), 4095 * otsuThresholds(n), 4095 * otsuThresholds(n) - r22.thresholdRaw, ...
        4095 * otsuThresholds(n) - r23.finalThresholdRawEquivalent, summary.candidateFractionBrain(n), ...
        r22.candidateFractionBrain, r23.candidateFractionBrain);
end
fprintf('T_otsu pn3 - pn0 = %.4f raw-equivalent; T_otsu * 255 = %.6f (pn0), %.6f (pn3)\n\n', ...
    4095 * (otsuThresholds(2) - otsuThresholds(1)), 255 * otsuThresholds(1), 255 * otsuThresholds(2));


%% Figure

% 1. Istogrammi della fase 40 con le soglie (solo visualizzazione)
histogram40 = readtable(fullfile(cfg.paths.metrics, 'phase40_brain_only_histogram_counts.csv'));
fig = figure('Color', 'w');
layout = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact');
title(layout, 'EXP-024 - Phase-40 brain-only T2 histograms with Otsu thresholds (references: EXP-022, EXP-023)', ...
    'Interpreter', 'none');
scales = ["linear" "log"];
for p = 1:2
    ax = nexttile(layout);
    plot(ax, histogram40.RawValue, histogram40.pn0_T2 / sum(histogram40.pn0_T2), '-', ...
        histogram40.RawValue, histogram40.pn3_T2 / sum(histogram40.pn3_T2), '-');
    xline(ax, 4095 * otsuThresholds(1), 'b-', sprintf('Otsu pn0 = %.1f', 4095 * otsuThresholds(1)), 'LineWidth', 1.3);
    xline(ax, 4095 * otsuThresholds(2), 'r-', sprintf('Otsu pn3 = %.1f', 4095 * otsuThresholds(2)), 'LineWidth', 1.3);
    xline(ax, exp023.finalThresholdRawEquivalent(1), 'b:', 'EXP-023 pn0');
    xline(ax, exp023.finalThresholdRawEquivalent(2), 'r:', 'EXP-023 pn3');
    xline(ax, exp022.thresholdRaw(1), 'k:', 'EXP-022 3400');
    set(ax, 'YScale', scales(p));
    xlim(ax, [1000 4095]);
    ylabel(ax, sprintf('fraction (%s)', scales(p)));
    legend(ax, 'pn0 T2 brain-only', 'pn3 T2 brain-only', 'Location', 'northeast');
end
xlabel(ax, 'raw T2 value');
fig.Position(3:4) = [1000 750];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp024_otsu_threshold_histograms.png'));

% 2. Candidati (stesse slice e stesso foglio di contatto di EXP-022/023)
for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 2, numel(overlaySlices), 'TileSpacing', 'compact', 'Padding', 'compact');
    title(layout, sprintf('EXP-024 T2 %s - Otsu threshold %.2f raw-equivalent (">"): T2 / T2 + candidates (red)', ...
        noiseLevels(n), 4095 * otsuThresholds(n)), 'Interpreter', 'none');
    for row = 1:2
        for k = overlaySlices
            ax = nexttile(layout);
            image(ax, candidateOverlay(volumes{n}(:, :, k), candidates{n}(:, :, k), row == 2));
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('k=%d', k), 'FontSize', 9);
        end
    end
    fig.Position(3:4) = [1300 900];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp024_t2_%s_candidate_overlay.png', noiseLevels(n))), ...
        'Resolution', 150);

    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 3, 7, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf('EXP-024 T2 %s - candidates (red), axial contact sheet every 10 slices', noiseLevels(n)), ...
        'Interpreter', 'none');
    for k = contactSlices
        ax = nexttile(layout);
        image(ax, candidateOverlay(volumes{n}(:, :, k), candidates{n}(:, :, k), true));
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('k=%d', k), 'FontSize', 7);
    end
    fig.Position(3:4) = [1600 900];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp024_t2_candidate_contact_sheet_%s.png', ...
        noiseLevels(n))), 'Resolution', 150);
end


%% Esito dei controlli

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-46s %s\n', checks{c, 1}, result);
end
fprintf('\nEXP-024 CHECKS: PASS\n');


function rgb = candidateOverlay(sliceImage, candidateSlice, showCandidates)
%CANDIDATEOVERLAY T2 in scala di grigi con i candidati in rosso (solo visualizzazione).
    gray = sliceImage.';
    red = gray; green = gray; blue = gray;
    if showCandidates
        m = candidateSlice.';
        red(m) = 1;
        green(m) = 0;
        blue(m) = 0;
    end
    rgb = cat(3, red, green, blue);
end
