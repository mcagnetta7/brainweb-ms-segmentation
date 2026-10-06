%% Maschera di supporto iniziale con soglia globale (fase 49, EXP-005)
% T2, msles2, 1 mm, rf0, condizioni di sviluppo pn0 e pn3. Preparazione:
% loader -> double (fase 43) -> /4095 (fase 44) -> nessun filtro (fase 47).
%
% Metodo: UNA soglia di Otsu per volume (graythresh su tutti i voxel),
% applicata identica a ogni slice assiale. Stessa regola per pn0 e pn3;
% le soglie numeriche possono differire perché stimate dai dati.
%
% Uscita GREZZA: nessuna morfologia, nessun riempimento, nessuna
% componente connessa, nessun ground truth, nessuna sovrapposizione alla
% MRI (fase 51). Le imperfezioni vengono registrate, non corrette.
% Se un controllo fallisce lo script si interrompe con un errore.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

modality = cfg.dataset.modality;
assert(cfg.preprocessing.filter.method == "none", 'Phase 49 requires no filter.');

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
nSlices = cfg.dataset.volumeSize(3);
displaySlices = round(linspace(1, nSlices, 5));    % prima, 1/4, centro, 3/4, ultima

volumes = cell(1, 2);
masks = cell(1, 2);
thresholds = zeros(1, 2);
checks = cell(0, 2);
summaryRows = cell(2, 1);

for n = 1:2
    noise = noiseLevels(n);
    raw = loadBrainwebMri(cfg, modality, noise);
    volume = prepare(raw);
    volumeCopy = volume;

    [mask, threshold] = initialSupportMask(volume);

    perSlice = squeeze(sum(mask, [1 2]));
    foreground = nnz(mask);
    fraction = foreground / numel(mask);
    nonEmpty = nnz(perSlice > 0);
    empty = nSlices - nonEmpty;

    checks(end+1, :) = {noise + " input double in [0,1]", isa(volume, 'double') ...
        && min(volume(:)) >= 0 && max(volume(:)) <= 1}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " one finite threshold in (0,1)", isscalar(threshold) ...
        && isfinite(threshold) && threshold > 0 && threshold < 1}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " mask size = volume size", isequal(size(mask), size(volume))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " mask is logical", islogical(mask)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " mask not all false/true", foreground > 0 && foreground < numel(mask)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " mask = volume > T", isequal(mask, volume > threshold)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " normalized volume unchanged", isequal(volume, volumeCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw MRI unchanged on reload", isequal(raw, loadBrainwebMri(cfg, modality, noise))}; %#ok<SAGROW>

    summaryRows{n} = {string(modality), noise, threshold, foreground, fraction, nonEmpty, empty, ...
        perSlice(1), perSlice(end)};

    % Maschera grezza salvata come dato derivato (escluso da Git)
    maskFile = fullfile(cfg.paths.processedData, ...
        sprintf('phase49_%s_%s_initial_support_mask.mat', lower(modality), noise));
    save(maskFile, 'mask', 'threshold');

    volumes{n} = volume;
    masks{n} = mask;
    thresholds(n) = threshold;
end


%% Diagnostica tra condizioni (solo descrittiva, nessuna soglia di qualità)

intersectionOverUnion = nnz(masks{1} & masks{2}) / nnz(masks{1} | masks{2});
differingFraction = nnz(xor(masks{1}, masks{2})) / numel(masks{1});

summary = cell2table(vertcat(summaryRows{:}), 'VariableNames', ...
    {'Modality', 'Noise', 'OtsuThreshold', 'ForegroundVoxels', 'ForegroundFraction', ...
     'NonEmptySlices', 'EmptySlices', 'ForegroundFirstSlice', 'ForegroundLastSlice'});
disp(summary);
fprintf('Cross-condition mask consistency (pn0 vs pn3): IoU = %.4f, differing voxels = %.4f %%\n\n', ...
    intersectionOverUnion, 100 * differingFraction);

metricsFile = fullfile(cfg.paths.metrics, 'phase49_initial_support_mask.csv');
writetable(summary, metricsFile);


%% Figure: istogrammi con soglia e maschere grezze (nessuna sovrapposizione)

edges = linspace(0, 1, 257);
fig1 = figure('Color', 'w');
layout = tiledlayout(fig1, 2, 1, 'TileSpacing', 'compact');
title(layout, 'Phase 49 - complete-volume histograms (log) with global Otsu threshold', ...
    'Interpreter', 'none');
for n = 1:2
    ax = nexttile(layout);
    counts = histcounts(volumes{n}(:), edges);
    stairs(ax, edges(1:end-1), counts);
    set(ax, 'YScale', 'log');
    xline(ax, thresholds(n), 'r', sprintf('T = %.4f', thresholds(n)), 'LineWidth', 1);
    xlim(ax, [0 1]);
    ylabel(ax, 'voxels (log)');
    title(ax, sprintf('%s %s', modality, noiseLevels(n)));
end
xlabel(ax, 'normalized intensity (256 bins)');
fig1.Position(3:4) = [800 600];
histogramFile = fullfile(cfg.paths.figures, 'phase49_histograms_otsu_threshold.png');
exportgraphics(fig1, histogramFile);

fig2 = figure('Color', 'w');
layout = tiledlayout(fig2, 2, numel(displaySlices), 'TileSpacing', 'compact');
title(layout, 'Phase 49 - RAW initial support masks (white = foreground), deterministic slices', ...
    'Interpreter', 'none');
for n = 1:2
    for s = 1:numel(displaySlices)
        ax = nexttile(layout);
        imagesc(ax, masks{n}(:, :, displaySlices(s)).');
        colormap(ax, gray);
        clim(ax, [0 1]);
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('%s  k = %d', noiseLevels(n), displaySlices(s)));
    end
end
fig2.Position(3:4) = [1400 650];
maskFigureFile = fullfile(cfg.paths.figures, 'phase49_raw_masks_deterministic_slices.png');
exportgraphics(fig2, maskFigureFile);


%% Esito

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-40s %s\n', checks{c, 1}, result);
end
if ~all([checks{:, 2}])
    error('exp005:validationFailed', 'PHASE 49 CHECKS: FAIL');
end

fprintf('\nPHASE 49 CHECKS: PASS\n');
fprintf('Masks:   %s\nMetrics: %s\nFigures: %s\n         %s\n', cfg.paths.processedData, ...
    metricsFile, histogramFile, maskFigureFile);
