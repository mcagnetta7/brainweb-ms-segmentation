%% EXP-023 (fase 55): soglia globale iterativa sulla T2 solo-cervello
% Esperimento di stima AUTOMATICA della soglia (metodo iterativo del corso).
%   - modalità T2; sviluppo msles2 1 mm rf0, pn0 + pn3; nessun dato held-out
%   - supporto: EXP-021 (pn0 -> pn0, pn3 -> pn3); preprocessing NONE
%   - valori analizzati: brainValues = T2norm(brainMask) (mai zeri artificiali)
%   - stessa REGOLA per pn0 e pn3 (le soglie numeriche possono differire):
%       T0 = mean(brainValues)   (descrizione scritta del corso; l'esempio
%                                 MATLAB delle slide usa 0.5*mean)
%       partizione: R_high = >= T, R_low = < T
%       T_next = (mu_low + mu_high) / 2
%       convergenza: abs(T_next - T) < epsilon, epsilon = 0.5/4095 (scelta di
%       progetto: mezzo livello grezzo; il PDF usa 0.5 su dati im2double)
%       maxIterations = 1000 (solo limite di sicurezza)
%   - candidati: thresholdLesionCandidates(T2norm, brainMask, T_iter), cioè
%     confronto STRETTO ">" (contratto della fase 53, invariato)
%   - nessun GT, nessuna metrica sulle lesioni, nessuna regolazione, nessuna
%     morfologia, nessuna analisi delle componenti.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'EXP-023 requires no filter.');


%% Regola fissata prima dell'esecuzione (identica per pn0 e pn3)

epsilon = 0.5 / 4095;
maxIterations = 1000;
initializationRule = "T0 = mean(T2norm(brainMask))";
partitionRule = "R_high = values >= T; R_low = values < T";
updateRule = "T_next = (mean(R_low) + mean(R_high)) / 2";
convergenceRule = "abs(T_next - T) < 0.5/4095";
comparator = ">";
manualReferenceRaw = 3400;                       % EXP-022, solo confronto descrittivo

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
    sprintf('exp023_t2_%s_iterative_threshold_candidate.mat', noise));
historyFile = @(noise) fullfile(cfg.paths.metrics, sprintf('exp023_iterative_threshold_history_%s.csv', noise));

checks = cell(0, 2);
checks(end+1, :) = {"epsilon = 0.5/4095", epsilon == 0.5 / 4095};

volumes = cell(1, 2);
candidates = cell(1, 2);
histories = cell(1, 2);
finalThresholds = zeros(1, 2);
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
        error('exp023:technicallyBlocked', 'EXP-023 TECHNICALLY BLOCKED: input checks failed for %s.', noise);
    end

    % Stima automatica (nessun intervento manuale tra stima e candidati)
    brainValues = t2(brainMask);
    [T_iter, history] = estimateIterativeThreshold(brainValues, epsilon, maxIterations);
    lesionCandidateMask = thresholdLesionCandidates(t2, brainMask, T_iter);

    % Verifica indipendente della storia
    historyConsistent = true;
    for i = 1:numel(history.iteration)
        T = history.thresholdCurrent(i);
        high = brainValues >= T;
        low = brainValues < T;
        historyConsistent = historyConsistent && any(high) && any(low) && ...
            abs(history.meanLow(i) - mean(brainValues(low))) < 1e-12 && ...
            abs(history.meanHigh(i) - mean(brainValues(high))) < 1e-12 && ...
            history.thresholdNext(i) == (history.meanLow(i) + history.meanHigh(i)) / 2 && ...
            history.delta(i) == abs(history.thresholdNext(i) - T);
        if i > 1
            historyConsistent = historyConsistent && T == history.thresholdNext(i - 1);
        end
    end

    checks = [checks; {
        noise + " brainValues count = nnz(mask)",       numel(brainValues) == nnz(brainMask)
        noise + " T0 = mean(brainValues)",              history.initialThreshold == mean(brainValues)
        noise + " history follows partition/update",   historyConsistent
        noise + " final delta < epsilon",               history.delta(end) < epsilon
        noise + " converged before guard",              numel(history.iteration) < maxIterations
        noise + " final threshold = last T_next",       T_iter == history.thresholdNext(end)
        noise + " final threshold finite in [0,1]",     isfinite(T_iter) && T_iter >= 0 && T_iter <= 1
        noise + " output size = T2 size",               isequal(size(lesionCandidateMask), size(t2))
        noise + " output logical",                      islogical(lesionCandidateMask)
        noise + " output = brainMask & (T2norm > T)",   isequal(lesionCandidateMask, brainMask & (t2 > T_iter))
        noise + " no candidate outside brainMask",      ~any(lesionCandidateMask & ~brainMask, 'all')
        noise + " source T2 unchanged",                 isequal(t2, t2Copy) && isequal(raw, loadBrainwebMri(cfg, "T2", noise))
        noise + " brainMask unchanged",                 isequal(brainMask, maskCopy)
        }]; %#ok<AGROW>

    % Storia salvata in CSV (normalizzata ed equivalente grezzo)
    historyTable = table(history.iteration, history.thresholdCurrent, 4095 * history.thresholdCurrent, ...
        history.meanLow, 4095 * history.meanLow, history.meanHigh, 4095 * history.meanHigh, ...
        history.thresholdNext, 4095 * history.thresholdNext, history.delta, 4095 * history.delta, ...
        history.countLow, history.countHigh, ...
        'VariableNames', {'iteration', 'thresholdCurrent', 'thresholdCurrentRawEquivalent', 'meanLow', ...
        'meanLowRawEquivalent', 'meanHigh', 'meanHighRawEquivalent', 'thresholdNext', ...
        'thresholdNextRawEquivalent', 'delta', 'deltaRawEquivalent', 'countLow', 'countHigh'});
    writetable(historyTable, historyFile(noise));
    reloadedHistory = readtable(historyFile(noise));
    checks(end+1, :) = {noise + " saved history reloads consistently", ...
        isequal(reloadedHistory.iteration, history.iteration) && ...
        max(abs(reloadedHistory.thresholdNext - history.thresholdNext)) < 1e-12}; %#ok<SAGROW>

    metadata = struct('experiment', "EXP-023", 'phase', 55, 'condition', noise, ...
        'sourceT2', string(t2Files{n}), 'sourceBrainMask', string(maskFile(noise)), ...
        'initializationRule', initializationRule, 'initialThreshold', history.initialThreshold, ...
        'finalThreshold', T_iter, 'finalThresholdRawEquivalent', 4095 * T_iter, ...
        'partitionRule', partitionRule, 'updateRule', updateRule, 'convergenceRule', convergenceRule, ...
        'epsilon', epsilon, 'maxIterations', maxIterations, 'iterations', numel(history.iteration), ...
        'comparator', comparator, 'normalization', "uint16 -> double -> /4095", 'preprocessing', "none", ...
        'note', "Automatic iterative threshold on T2(brainMask); candidate mask, not a final lesion mask; no GT.");
    save(outputFile(noise), 'lesionCandidateMask', 'metadata', 'history');
    reloaded = load(outputFile(noise), 'lesionCandidateMask', 'history');
    checks(end+1, :) = {noise + " saved candidate reloads identically", ...
        isequal(reloaded.lesionCandidateMask, lesionCandidateMask) && isequal(reloaded.history, history)}; %#ok<SAGROW>

    % Statistiche descrittive
    candidateRaw = double(raw(lesionCandidateMask));
    sliceHasCandidate = squeeze(any(lesionCandidateMask, [1 2]));
    candidateSlices = find(sliceHasCandidate);
    if isempty(candidateSlices)
        candidateSlices = 0;
        candidateRaw = NaN;
        warning('exp023:noCandidates', 'No candidates for %s.', noise);
    end
    rows{n} = {noise, history.initialThreshold, 4095 * history.initialThreshold, T_iter, 4095 * T_iter, ...
        epsilon, 4095 * epsilon, numel(history.iteration), history.delta(end), ...
        history.meanLow(end), 4095 * history.meanLow(end), history.meanHigh(end), 4095 * history.meanHigh(end), ...
        numel(t2), nnz(brainMask), nnz(lesionCandidateMask), nnz(lesionCandidateMask) / nnz(brainMask), ...
        nnz(lesionCandidateMask) / numel(t2), nnz(sliceHasCandidate), candidateSlices(1), candidateSlices(end), ...
        min(candidateRaw), max(candidateRaw), mean(candidateRaw), median(candidateRaw)};

    volumes{n} = t2;
    candidates{n} = lesionCandidateMask;
    histories{n} = history;
    finalThresholds(n) = T_iter;
end

scriptText = fileread([mfilename('fullpath') '.m']);
% Stessa regola per pn0 e pn3: epsilon, maxIterations e regole sono definiti
% una sola volta prima del ciclo (per costruzione; nessun controllo fittizio)
checks(end+1, :) = {"no GT loader referenced in this script", ...
    ~contains(scriptText, ['loadBrainweb' 'GroundTruth']) && ~contains(scriptText, ['groundTruth' 'File'])};

if any(~[checks{:, 2}])
    for c = 1:size(checks, 1)
        fprintf('%-48s %d\n', checks{c, 1}, checks{c, 2});
    end
    error('exp023:checksFailed', 'EXP-023 technical checks failed.');
end


%% Tabella riassuntiva e confronto descrittivo con EXP-022

summary = cell2table(vertcat(rows{:}), 'VariableNames', {'condition', 'initialThreshold', ...
    'initialThresholdRawEquivalent', 'finalThreshold', 'finalThresholdRawEquivalent', 'epsilon', ...
    'epsilonRawEquivalent', 'iterations', 'finalDelta', 'finalMeanLow', 'finalMeanLowRawEquivalent', ...
    'finalMeanHigh', 'finalMeanHighRawEquivalent', 'totalVoxels', 'brainMaskVoxels', 'candidateVoxels', ...
    'candidateFractionBrain', 'candidateFractionWholeVolume', 'nonEmptySlices', 'firstCandidateSlice', ...
    'lastCandidateSlice', 'candidateMinIntensityRaw', 'candidateMaxIntensityRaw', 'candidateMeanIntensityRaw', ...
    'candidateMedianIntensityRaw'});
disp(summary);
writetable(summary, fullfile(cfg.paths.metrics, 'exp023_iterative_threshold_summary.csv'));

exp022 = readtable(fullfile(cfg.paths.metrics, 'exp022_manual_global_threshold_summary.csv'));
fprintf('T_iter raw-equivalent: pn0 = %.4f, pn3 = %.4f, pn3 - pn0 = %.4f\n', ...
    4095 * finalThresholds(1), 4095 * finalThresholds(2), 4095 * (finalThresholds(2) - finalThresholds(1)));
fprintf('T_iter - EXP-022 (3400): pn0 = %.4f, pn3 = %.4f (raw-equivalent)\n', ...
    4095 * finalThresholds(1) - manualReferenceRaw, 4095 * finalThresholds(2) - manualReferenceRaw);
fprintf('candidateFractionBrain EXP-023 / EXP-022: pn0 = %.6f / %.6f, pn3 = %.6f / %.6f\n\n', ...
    summary.candidateFractionBrain(1), exp022.candidateFractionBrain(1), ...
    summary.candidateFractionBrain(2), exp022.candidateFractionBrain(2));


%% Figure

% 1. Convergenza
fig = figure('Color', 'w');
ax = axes(fig);
hold(ax, 'on');
markers = {'o-', 's-'};
for n = 1:2
    trajectory = 4095 * [histories{n}.initialThreshold; histories{n}.thresholdNext];
    plot(ax, 0:numel(trajectory) - 1, trajectory, markers{n}, 'DisplayName', ...
        sprintf('%s (final %.2f, %d updates)', noiseLevels(n), trajectory(end), numel(trajectory) - 1));
end
hold(ax, 'off');
xlabel(ax, 'iteration (0 = T0 = mean of brain-only T2)');
ylabel(ax, 'threshold (raw-equivalent)');
legend(ax, 'Location', 'best');
title(ax, 'EXP-023 iterative threshold convergence (epsilon = 0.5 raw levels)');
grid(ax, 'on');
fig.Position(3:4) = [800 500];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp023_iterative_threshold_convergence.png'));

% 2. Istogrammi della fase 40 con le soglie (solo interpretazione)
histogram40 = readtable(fullfile(cfg.paths.metrics, 'phase40_brain_only_histogram_counts.csv'));
fig = figure('Color', 'w');
layout = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact');
title(layout, 'EXP-023 - Phase-40 brain-only T2 histograms with iterative thresholds (EXP-022 3400 = reference)', ...
    'Interpreter', 'none');
scales = ["linear" "log"];
for p = 1:2
    ax = nexttile(layout);
    plot(ax, histogram40.RawValue, histogram40.pn0_T2 / sum(histogram40.pn0_T2), '-', ...
        histogram40.RawValue, histogram40.pn3_T2 / sum(histogram40.pn3_T2), '-');
    xline(ax, 4095 * finalThresholds(1), 'b--', sprintf('T_{iter} pn0 = %.1f', 4095 * finalThresholds(1)));
    xline(ax, 4095 * finalThresholds(2), 'r--', sprintf('T_{iter} pn3 = %.1f', 4095 * finalThresholds(2)));
    xline(ax, manualReferenceRaw, 'k:', 'EXP-022 reference 3400');
    set(ax, 'YScale', scales(p));
    xlim(ax, [1000 4095]);
    ylabel(ax, sprintf('fraction (%s)', scales(p)));
    legend(ax, 'pn0 T2 brain-only', 'pn3 T2 brain-only', 'Location', 'northeast');
end
xlabel(ax, 'raw T2 value');
fig.Position(3:4) = [1000 750];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp023_iterative_threshold_histograms.png'));

% 3. Candidati (stesse slice e stesso foglio di contatto di EXP-022)
for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 2, numel(overlaySlices), 'TileSpacing', 'compact', 'Padding', 'compact');
    title(layout, sprintf('EXP-023 T2 %s - iterative threshold %.2f raw-equivalent (">"): T2 / T2 + candidates (red)', ...
        noiseLevels(n), 4095 * finalThresholds(n)), 'Interpreter', 'none');
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
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp023_t2_%s_candidate_overlay.png', noiseLevels(n))), ...
        'Resolution', 150);

    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 3, 7, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf('EXP-023 T2 %s - candidates (red), axial contact sheet every 10 slices', noiseLevels(n)), ...
        'Interpreter', 'none');
    for k = contactSlices
        ax = nexttile(layout);
        image(ax, candidateOverlay(volumes{n}(:, :, k), candidates{n}(:, :, k), true));
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('k=%d', k), 'FontSize', 7);
    end
    fig.Position(3:4) = [1600 900];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp023_t2_candidate_contact_sheet_%s.png', ...
        noiseLevels(n))), 'Resolution', 150);
end


%% Esito dei controlli

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-48s %s\n', checks{c, 1}, result);
end
fprintf('\nEXP-023 CHECKS: PASS\n');


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
