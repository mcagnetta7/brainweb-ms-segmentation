%% EXP-022 (fase 54): soglia globale T2 definita manualmente
% Primo esperimento di segmentazione delle lesioni: riferimento iniziale,
% NON il metodo finale.
%   - modalità T2; dati di sviluppo msles2 1 mm rf0, pn0 + pn3
%   - supporto cerebrale: EXP-021 (pn0 -> pn0, pn3 -> pn3, mai incrociate)
%   - T2 -> double -> /4095; preprocessing NONE
%   - candidati = thresholdLesionCandidates(T2norm, brainMask, T)
%     cioè brainMask AND (T2norm > T), confronto STRETTO ">"
%   - soglia scelta A MANO solo dagli istogrammi T2 solo-cervello della
%     fase 40 (pn0 e pn3), congelata PRIMA di generare i candidati
%     (preregistrata in BRAINWEB_DATASET_NOTES.md §13.33):
%       T_raw        = 3400   (compromesso tra la valle di pn3 ~3250 e il
%                             minimo di pn0 ~3550, quasi al gradino di
%                             pn0 ~3430)
%       T_normalized = 3400 / 4095
%     stessa soglia per pn0 e pn3
%   - nessun GT, nessuna metrica sulle lesioni, nessuno sweep, nessuna
%     morfologia, nessuna analisi delle componenti, nessun dato held-out.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'EXP-022 requires no filter.');


%% 1. Soglia congelata (prima di qualsiasi candidato)

T_raw = 3400;                                   % FROZEN FOR EXP-022
T_normalized = T_raw / 4095;                    % equivalente esatto, nessun arrotondamento
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
    sprintf('exp022_t2_%s_manual_global_threshold_candidate.mat', noise));

checks = cell(0, 2);
checks(end+1, :) = {"T_raw inside [0, 4095]", T_raw >= 0 && T_raw <= 4095};
checks(end+1, :) = {"T_normalized inside [0, 1]", T_normalized >= 0 && T_normalized <= 1};
checks(end+1, :) = {"T_normalized == T_raw / 4095 exactly", T_normalized == T_raw / 4095};


%% 2. Figura della scelta della soglia (dagli istogrammi salvati della fase 40)

histogram40 = readtable(fullfile(cfg.paths.metrics, 'phase40_brain_only_histogram_counts.csv'));
rawValues = histogram40.RawValue;
fig = figure('Color', 'w');
layout = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact');
title(layout, sprintf(['EXP-022 manual threshold selection - Phase-40 brain-only T2 histograms ' ...
    '(normalized frequency, one bin per raw value, no smoothing); T_raw = %d'], T_raw), 'Interpreter', 'none');
scales = ["linear" "log"];
for p = 1:2
    ax = nexttile(layout);
    plot(ax, rawValues, histogram40.pn0_T2 / sum(histogram40.pn0_T2), '-', ...
        rawValues, histogram40.pn3_T2 / sum(histogram40.pn3_T2), '-');
    xline(ax, T_raw, 'k--', sprintf('T_{raw} = %d', T_raw), 'LineWidth', 1.2);
    set(ax, 'YScale', scales(p));
    xlim(ax, [1000 4095]);
    ylabel(ax, sprintf('fraction (%s)', scales(p)));
    legend(ax, 'pn0 T2 brain-only', 'pn3 T2 brain-only', 'Location', 'northeast');
end
xlabel(ax, 'raw T2 value');
fig.Position(3:4) = [1000 750];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp022_manual_threshold_selection.png'));


%% 3. Candidati (stessa soglia congelata per pn0 e pn3)

volumes = cell(1, 2);
candidates = cell(1, 2);
rows = cell(2, 1);
usedThresholds = zeros(1, 2);
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
        error('exp022:technicallyBlocked', 'EXP-022 TECHNICALLY BLOCKED: input checks failed for %s.', noise);
    end

    usedThresholds(n) = T_normalized;
    lesionCandidateMask = thresholdLesionCandidates(t2, brainMask, T_normalized);

    checks = [checks; {
        noise + " output size = T2 size",                 isequal(size(lesionCandidateMask), size(t2))
        noise + " output logical",                        islogical(lesionCandidateMask)
        noise + " output = brainMask & (T2norm > T)",     isequal(lesionCandidateMask, brainMask & (t2 > T_normalized))
        noise + " no candidate outside brainMask",        ~any(lesionCandidateMask & ~brainMask, 'all')
        noise + " source T2 unchanged",                   isequal(t2, t2Copy) && isequal(raw, loadBrainwebMri(cfg, "T2", noise))
        noise + " brainMask unchanged",                   isequal(brainMask, maskCopy)
        }]; %#ok<AGROW>

    metadata = struct('experiment', "EXP-022", 'phase', 54, 'condition', noise, ...
        'sourceT2', string(t2Files{n}), 'sourceBrainMask', string(maskFile(noise)), ...
        'thresholdRaw', T_raw, 'thresholdNormalized', T_normalized, 'comparator', comparator, ...
        'normalization', "uint16 -> double -> /4095", 'preprocessing', "none", ...
        'note', "Manual global threshold from Phase-40 histograms, frozen before candidates; candidate mask, not a final lesion mask; no GT.");
    save(outputFile(noise), 'lesionCandidateMask', 'metadata');
    reloaded = load(outputFile(noise), 'lesionCandidateMask');
    checks(end+1, :) = {noise + " saved candidate reloads identically", ...
        isequal(reloaded.lesionCandidateMask, lesionCandidateMask)}; %#ok<SAGROW>

    candidateRaw = double(raw(lesionCandidateMask));
    sliceHasCandidate = squeeze(any(lesionCandidateMask, [1 2]));
    candidateSlices = find(sliceHasCandidate);
    if isempty(candidateSlices)
        candidateSlices = 0;
        candidateRaw = NaN;
    end
    rows{n} = {noise, T_raw, T_normalized, numel(t2), nnz(brainMask), nnz(lesionCandidateMask), ...
        nnz(lesionCandidateMask) / nnz(brainMask), nnz(lesionCandidateMask) / numel(t2), ...
        nnz(sliceHasCandidate), candidateSlices(1), candidateSlices(end), ...
        min(candidateRaw), max(candidateRaw), mean(candidateRaw), median(candidateRaw)};
    checks(end+1, :) = {noise + " candidate count = nnz(output)", rows{n}{6} == nnz(lesionCandidateMask)}; %#ok<SAGROW>

    volumes{n} = t2;
    candidates{n} = lesionCandidateMask;
end

checks(end+1, :) = {"same threshold used for pn0 and pn3", usedThresholds(1) == usedThresholds(2)};
scriptText = fileread([mfilename('fullpath') '.m']);
checks(end+1, :) = {"no GT loader referenced in this script", ...
    ~contains(scriptText, ['loadBrainweb' 'GroundTruth']) && ~contains(scriptText, ['groundTruth' 'File'])};

if any(~[checks{:, 2}])
    for c = 1:size(checks, 1)
        fprintf('%-46s %d\n', checks{c, 1}, checks{c, 2});
    end
    error('exp022:checksFailed', 'EXP-022 technical checks failed.');
end


%% 4. Statistiche descrittive (nessuna metrica di qualità)

summary = cell2table(vertcat(rows{:}), 'VariableNames', {'condition', 'thresholdRaw', 'thresholdNormalized', ...
    'totalVoxels', 'brainMaskVoxels', 'candidateVoxels', 'candidateFractionBrain', 'candidateFractionWholeVolume', ...
    'nonEmptySlices', 'firstCandidateSlice', 'lastCandidateSlice', 'candidateMinIntensityRaw', ...
    'candidateMaxIntensityRaw', 'candidateMeanIntensityRaw', 'candidateMedianIntensityRaw'});
disp(summary);
fractionDifference = summary.candidateFractionBrain(2) - summary.candidateFractionBrain(1);
fprintf('candidateFractionBrain: pn0 = %.6f, pn3 = %.6f, pn3 - pn0 = %.6f, pn3 / pn0 = %.4f\n\n', ...
    summary.candidateFractionBrain(1), summary.candidateFractionBrain(2), fractionDifference, ...
    summary.candidateFractionBrain(2) / summary.candidateFractionBrain(1));
writetable(summary, fullfile(cfg.paths.metrics, 'exp022_manual_global_threshold_summary.csv'));


%% 5. Figure: candidati sovrapposti alla T2 (nessun GT, nessun TP/FP/FN)

for n = 1:2
    % Slice fisse 46 / 91 / 136: T2 e T2 + candidati
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 2, numel(overlaySlices), 'TileSpacing', 'compact', 'Padding', 'compact');
    title(layout, sprintf('EXP-022 T2 %s - manual global threshold T_raw = %d (">"): T2 / T2 + candidates (red)', ...
        noiseLevels(n), T_raw), 'Interpreter', 'none');
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
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp022_t2_%s_candidate_overlay.png', noiseLevels(n))), ...
        'Resolution', 150);

    % Foglio di contatto a passo fisso (1:10:181)
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 3, 7, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf('EXP-022 T2 %s - candidates (red), axial contact sheet every 10 slices', noiseLevels(n)), ...
        'Interpreter', 'none');
    for k = contactSlices
        ax = nexttile(layout);
        image(ax, candidateOverlay(volumes{n}(:, :, k), candidates{n}(:, :, k), true));
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('k=%d', k), 'FontSize', 7);
    end
    fig.Position(3:4) = [1600 900];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp022_t2_candidate_contact_sheet_%s.png', ...
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
fprintf('\nEXP-022 CHECKS: PASS\n');


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
