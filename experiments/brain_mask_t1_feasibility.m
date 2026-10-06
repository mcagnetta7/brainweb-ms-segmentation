%% Fattibilità di una maschera cerebrale su T1 (fase 50, EXP-010)
% Esperimento strategico dentro la fase 50, dopo il fallimento del ramo T2
% (EXP-005...EXP-009). Cambia UN solo fattore: la modalità usata per la
% maschera, T2 -> T1. T1 serve SOLO come supporto anatomico per la
% maschera; T2 resta la modalità provvisoria per le lesioni
% (cfg.dataset.modality non viene toccato). Non è una fusione multimodale.
%
% Baseline più semplice, come nella fase 49:
%   T1 -> double -> /4095 -> nessun filtro -> UNA soglia di Otsu sul volume
%   intero (graythresh su tutti i voxel) -> stessa soglia su ogni slice
%   -> maschera GREZZA
% Nessuna pulizia: niente morfologia, riempimento, selezione di componenti,
% watershed o ricostruzione. Le componenti connesse sono contate solo come
% diagnostica e non modificano la maschera.
%
% Confronto strutturale con la maschera grezza T2 di EXP-005 (rigenerata
% con lo stesso metodo, senza ritarature) sulle slice deterministiche.
% Nessun ground truth, nessuna etichetta anatomica, nessun dato di test.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

maskModality = "T1";                        % solo per questo esperimento
lesionModality = cfg.dataset.modality;      % resta T2
assert(lesionModality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'EXP-010 requires no filter.');

connectivity = 8;                           % solo per la diagnostica delle componenti
expectedT2Thresholds = [78 75] / 255;       % EXP-005, solo controllo

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
nSlices = cfg.dataset.volumeSize(3);
displaySlices = round(linspace(1, nSlices, 5));

t1Volumes = cell(1, 2);
t1Masks = cell(1, 2);
t2Masks = cell(1, 2);
t1Thresholds = zeros(1, 2);
componentStats = cell(1, 2);
checks = cell(0, 2);

for n = 1:2
    noise = noiseLevels(n);
    rawT1 = loadBrainwebMri(cfg, maskModality, noise);
    rawT2 = loadBrainwebMri(cfg, lesionModality, noise);

    % Compatibilità geometrica T1/T2 (stesso loader, stessa convenzione)
    checks(end+1, :) = {noise + " T1 size = T2 size = configured", ...
        isequal(size(rawT1), size(rawT2), cfg.dataset.volumeSize)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " T1 class uint16, values 0...4095", ...
        isa(rawT1, 'uint16') && max(rawT1(:)) <= 4095}; %#ok<SAGROW>

    t1 = prepare(rawT1);
    t1Copy = t1;
    [t1Mask, t1Threshold] = initialSupportMask(t1);

    [t2Mask, t2Threshold] = initialSupportMask(prepare(rawT2));     % riferimento EXP-005
    checks(end+1, :) = {noise + " T2 EXP-005 threshold reproduced", ...
        abs(t2Threshold - expectedT2Thresholds(n)) < 1e-9}; %#ok<SAGROW>

    checks(end+1, :) = {noise + " T1 input double in [0,1]", isa(t1, 'double') && min(t1(:)) >= 0 && max(t1(:)) <= 1}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " T1 one finite threshold in (0,1)", isscalar(t1Threshold) && t1Threshold > 0 && t1Threshold < 1}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " T1 mask logical, = volume > T", islogical(t1Mask) && isequal(t1Mask, t1 > t1Threshold)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " T1 normalized volume unchanged", isequal(t1, t1Copy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " T1 raw unchanged on reload", isequal(rawT1, loadBrainwebMri(cfg, maskModality, noise))}; %#ok<SAGROW>

    % Diagnostica delle componenti (non modifica la maschera)
    stats = zeros(nSlices, 3);              % [nComponents largest secondLargest]
    for k = 1:nSlices
        components = bwconncomp(t1Mask(:, :, k), connectivity);
        areas = sort(cellfun(@numel, components.PixelIdxList), 'descend');
        stats(k, 1) = components.NumObjects;
        if ~isempty(areas), stats(k, 2) = areas(1); end
        if numel(areas) > 1, stats(k, 3) = areas(2); end
    end

    save(fullfile(cfg.paths.processedData, sprintf('exp010_t1_%s_raw_support_mask.mat', noise)), ...
        't1Mask', 't1Threshold');

    t1Volumes{n} = t1;
    t1Masks{n} = t1Mask;
    t2Masks{n} = t2Mask;
    t1Thresholds(n) = t1Threshold;
    componentStats{n} = stats;
end


%% Diagnostica

rows = cell(2, 1);
for n = 1:2
    m = t1Masks{n};
    perSlice = squeeze(sum(m, [1 2]));
    s = componentStats{n};
    rows{n} = {maskModality, noiseLevels(n), t1Thresholds(n), nnz(m), nnz(m) / numel(m), ...
        nnz(perSlice > 0), nnz(perSlice == 0), perSlice(1), perSlice(end), ...
        median(s(:, 1)), max(s(:, 1)), nnz(s(:, 1) > 1), median(s(:, 2)), median(s(:, 3))};
end
summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'MaskModality', 'Noise', 'OtsuThreshold', 'ForegroundVoxels', 'ForegroundFraction', ...
     'NonEmptySlices', 'EmptySlices', 'ForegroundFirstSlice', 'ForegroundLastSlice', ...
     'MedianComponents', 'MaxComponents', 'SlicesMultipleComponents', ...
     'MedianLargestArea', 'MedianSecondLargestArea'});
disp(summary);

intersectionOverUnion = nnz(t1Masks{1} & t1Masks{2}) / nnz(t1Masks{1} | t1Masks{2});
fprintf('T1 raw-mask consistency (pn0 vs pn3): IoU = %.4f, differing voxels = %.4f %%\n\n', ...
    intersectionOverUnion, 100 * nnz(xor(t1Masks{1}, t1Masks{2})) / numel(t1Masks{1}));

writetable(summary, fullfile(cfg.paths.metrics, 'exp010_t1_raw_mask_summary.csv'));
perSliceTable = table((1:nSlices)', componentStats{1}(:, 1), componentStats{1}(:, 2), componentStats{1}(:, 3), ...
    componentStats{2}(:, 1), componentStats{2}(:, 2), componentStats{2}(:, 3), ...
    'VariableNames', {'k', 'pn0_nComponents', 'pn0_largest', 'pn0_second', ...
                      'pn3_nComponents', 'pn3_largest', 'pn3_second'});
writetable(perSliceTable, fullfile(cfg.paths.metrics, 'exp010_t1_component_diagnostics.csv'));


%% Figure (diagnostica di fattibilità, nessuna sovrapposizione finale)

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 3, numel(displaySlices), 'TileSpacing', 'compact');
    title(layout, sprintf('EXP-010 %s - normalized T1 / raw T1 Otsu mask (T = %.4f) / raw T2 EXP-005 mask', ...
        noiseLevels(n), t1Thresholds(n)), 'Interpreter', 'none');
    versions = {t1Volumes{n}, t1Masks{n}, t2Masks{n}};
    labels = ["T1", "T1 raw mask", "T2 raw mask"];
    for v = 1:3
        for s = 1:numel(displaySlices)
            ax = nexttile(layout);
            imagesc(ax, double(versions{v}(:, :, displaySlices(s))).');
            colormap(ax, gray);
            clim(ax, [0 1]);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('%s  k = %d', labels(v), displaySlices(s)));
        end
    end
    fig.Position(3:4) = [1300 850];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp010_%s_t1_vs_t2_raw_masks.png', noiseLevels(n))));
end

edges = linspace(0, 1, 257);
fig3 = figure('Color', 'w');
layout = tiledlayout(fig3, 2, 1, 'TileSpacing', 'compact');
title(layout, 'EXP-010 - complete-volume T1 histograms (log) with global Otsu threshold', 'Interpreter', 'none');
for n = 1:2
    ax = nexttile(layout);
    counts = histcounts(t1Volumes{n}(:), edges);
    stairs(ax, edges(1:end-1), counts);
    set(ax, 'YScale', 'log');
    xline(ax, t1Thresholds(n), 'r', sprintf('T = %.4f', t1Thresholds(n)), 'LineWidth', 1);
    xlim(ax, [0 1]);
    ylabel(ax, 'voxels (log)');
    title(ax, sprintf('T1 %s', noiseLevels(n)));
end
xlabel(ax, 'normalized intensity (256 bins)');
fig3.Position(3:4) = [800 600];
exportgraphics(fig3, fullfile(cfg.paths.figures, 'exp010_t1_histograms_otsu.png'));


%% Esito dei controlli

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-42s %s\n', checks{c, 1}, result);
end
if ~all([checks{:, 2}])
    error('exp010:checksFailed', 'EXP-010 CHECKS: FAIL');
end
fprintf('\nEXP-010 CHECKS: PASS\n');
