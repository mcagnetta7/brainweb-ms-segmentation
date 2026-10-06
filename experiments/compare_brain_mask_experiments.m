%% Confronto di tutti gli esperimenti sulla maschera cerebrale (EXP-005 ... EXP-020)
% Script di sola lettura: carica gli output già salvati in data/processed/
% e li confronta numericamente e visivamente. Non ricalcola nessun metodo,
% non modifica nessun file di esperimento, non usa ground truth né
% etichette anatomiche (nessuna Dice). Non è un esperimento: non va
% registrato in EXPERIMENT_LOG.md.
%
% Metriche descrittive (nessuna è una misura di correttezza anatomica):
%   - voxel del candidato e frazione del volume
%   - slice non vuote, prima/ultima
%   - frazione di primo piano Otsu T1 grezzo (EXP-010) dentro il candidato:
%     alta = soprattutto tessuto; bassa = include molto tessuto scuro
%     (banda cranio/liquor, cavità)
%   - area relativa al supporto della testa T2 (candidato A di EXP-006)
%   - IoU pn0 vs pn3 (stabilità al rumore)
%   - IoU con EXP-018 (miglior risultato della fase 50 finora)
% EXP-015 (marker scheletrico) ed EXP-016 (bordi di Canny) non sono
% maschere: sono mostrati solo nelle figure e con le metriche applicabili.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing);

% Registro: ID, etichetta, file (%s = rumore), variabile, modalità, tipo, esito
registry = {
    "EXP-005", "T2 raw global Otsu",              "phase49_t2_%s_initial_support_mask.mat",       "mask",                     "T2", "mask",   "head-support raw mask"
    "EXP-006", "T2 largest comp + fill (A)",      "phase50_t2_%s_support_mask_candidate.mat",     "mask",                     "T2", "mask",   "head-support fallback"
    "EXP-007", "T2 erode-select-dilate",          "exp007_t2_%s_support_mask.mat",                "mask",                     "T2", "mask",   "REJECTED"
    "EXP-008", "T2 watershed (5x5 marker)",       "exp008_watershed_t2_%s_support_mask.mat",      "mask",                     "T2", "mask",   "REJECTED"
    "EXP-009", "T2 reconstruction markers",       "exp009_reconstruction_t2_%s_support_mask.mat", "mask",                     "T2", "mask",   "REJECTED"
    "EXP-010", "T1 raw global Otsu",              "exp010_t1_%s_raw_support_mask.mat",            "t1Mask",                   "T1", "mask",   "PROMISING (raw)"
    "EXP-011", "T1 largest comp + fill",          "exp011_t1_%s_support_mask_candidate.mat",      "candidate",                "T1", "mask",   "REJECTED"
    "EXP-012", "T1 nested component",             "exp012_t1_%s_nested_support_mask_candidate.mat", "candidate",              "T1", "mask",   "PROMISING BUT INCOMPLETE"
    "EXP-013", "T1 sibling union",                "exp013_t1_%s_siblings_support_mask_candidate.mat", "candidate",            "T1", "mask",   "REJECTED"
    "EXP-014", "T1 watershed, topology markers",  "exp014_t1_%s_watershed_support_mask_candidate.mat", "candidate",           "T1", "mask",   "REJECTED"
    "EXP-015", "T1 dark skeleton (marker)",       "exp015_t1_%s_dark_background_marker.mat",      "internalBackgroundMarker", "T1", "marker", "REJECTED (marker)"
    "EXP-016", "T1 raw Canny (edges)",            "exp016_t1_%s_canny_edges.mat",                 "cannyEdges",               "T1", "edges",  "PROMISING BUT PROBLEMATIC (edges)"
    "EXP-017", "T1 Canny smallest enclosure",     "exp017_t1_%s_canny_enclosing_candidate.mat",   "candidate",                "T1", "mask",   "REJECTED"
    "EXP-018", "T1 z-propagation r3/r3",          "exp018_t1_%s_zpropagation_candidate.mat",      "candidate",                "T1", "mask",   "PROMISING BUT PROBLEMATIC"
    "EXP-019", "T1 z-propagation r5/r1",          "exp019_t1_%s_zpropagation_candidate.mat",      "candidate",                "T1", "mask",   "REJECTED"
    "EXP-020", "T1 z-prop. r5/r1, ridge to fg",   "exp020_t1_%s_zpropagation_candidate.mat",      "candidate",                "T1", "mask",   "REJECTED"
    };
nExp = size(registry, 1);
referenceId = "EXP-018";
headId = "EXP-006";
otsuId = "EXP-010";

noiseLevels = ["pn0" "pn3"];
nSlices = cfg.dataset.volumeSize(3);
displaySlices = sort([round(linspace(1, nSlices, 5)), 40, 43, 44, 139, 143]);

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);


%% Caricamento

masks = cell(nExp, 2);
backgrounds = struct();
for n = 1:2
    noise = noiseLevels(n);
    backgrounds.(noise).T1 = prepare(loadBrainwebMri(cfg, "T1", noise));
    backgrounds.(noise).T2 = prepare(loadBrainwebMri(cfg, "T2", noise));
    for e = 1:nExp
        file = fullfile(cfg.paths.processedData, sprintf(registry{e, 3}, noise));
        if ~isfile(file)
            warning('compare:missingFile', 'Missing output: %s', file);
            continue
        end
        data = load(file, registry{e, 4});
        masks{e, n} = logical(data.(registry{e, 4}));
    end
end

indexOf = @(id) find([registry{:, 1}] == id);
reference = indexOf(referenceId);
head = indexOf(headId);
otsu = indexOf(otsuId);


%% Metriche

rows = {};
areas = cell(1, 2);
for n = 1:2
    areas{n} = nan(nSlices, nExp);
end
for e = 1:nExp
    values = struct();
    for n = 1:2
        m = masks{e, n};
        if isempty(m)
            continue
        end
        areas{n}(:, e) = squeeze(sum(m, [1 2]));
        nonEmpty = find(areas{n}(:, e) > 0);
        if isempty(nonEmpty)
            nonEmpty = 0;
        end
        values.(noiseLevels(n)) = {nnz(m), nnz(m) / numel(m), nnz(areas{n}(:, e) > 0), nonEmpty(1), nonEmpty(end)};
        isMask = registry{e, 6} == "mask";
        values.([char(noiseLevels(n)) '_otsu']) = NaN;
        values.([char(noiseLevels(n)) '_head']) = NaN;
        values.([char(noiseLevels(n)) '_ref']) = NaN;
        if isMask
            values.([char(noiseLevels(n)) '_otsu']) = nnz(m & masks{otsu, n}) / max(nnz(m), 1);
            values.([char(noiseLevels(n)) '_head']) = nnz(m) / nnz(masks{head, n});
            r = masks{reference, n};
            values.([char(noiseLevels(n)) '_ref']) = nnz(m & r) / max(nnz(m | r), 1);
        end
    end
    if isempty(masks{e, 1}) || isempty(masks{e, 2})
        continue
    end
    iouNoise = nnz(masks{e, 1} & masks{e, 2}) / max(nnz(masks{e, 1} | masks{e, 2}), 1);
    rows(end+1, :) = [registry(e, [1 2 5 6 7]), values.pn0, values.pn3, ...
        {values.pn0_otsu, values.pn3_otsu, values.pn0_head, values.pn3_head, iouNoise, ...
         values.pn0_ref, values.pn3_ref}]; %#ok<SAGROW>
end
comparison = cell2table(rows, 'VariableNames', ...
    {'ID', 'Method', 'Modality', 'Type', 'Decision', ...
     'Voxels_pn0', 'Fraction_pn0', 'NonEmptySlices_pn0', 'First_pn0', 'Last_pn0', ...
     'Voxels_pn3', 'Fraction_pn3', 'NonEmptySlices_pn3', 'First_pn3', 'Last_pn3', ...
     'OtsuT1Fraction_pn0', 'OtsuT1Fraction_pn3', 'RelativeToHead_pn0', 'RelativeToHead_pn3', ...
     'IoU_pn0_pn3', 'IoU_vsEXP018_pn0', 'IoU_vsEXP018_pn3'});

disp(comparison(:, {'ID', 'Method', 'Decision', 'Voxels_pn0', 'NonEmptySlices_pn0', ...
    'OtsuT1Fraction_pn0', 'RelativeToHead_pn0', 'IoU_pn0_pn3', 'IoU_vsEXP018_pn0'}));

writetable(comparison, fullfile(cfg.paths.metrics, 'brain_mask_experiments_comparison.csv'));
for n = 1:2
    perSlice = array2table([(1:nSlices)', areas{n}], 'VariableNames', ...
        ['k', cellstr(strrep([registry{:, 1}], "-", "_"))]);
    writetable(perSlice, fullfile(cfg.paths.metrics, ...
        sprintf('brain_mask_experiments_area_per_slice_%s.csv', noiseLevels(n))));
end

% Aree alle slice diagnostiche (pn0)
diagnosticAreas = array2table(areas{1}(displaySlices, :), 'VariableNames', ...
    cellstr(strrep([registry{:, 1}], "-", "_")), 'RowNames', compose('k=%d', displaySlices));
disp(diagnosticAreas);


%% Figura 1: aree per slice di tutte le maschere

maskRows = find([registry{:, 6}] == "mask");
colors = lines(numel(maskRows));
fig1 = figure('Color', 'w');
layout = tiledlayout(fig1, 2, 1, 'TileSpacing', 'compact');
title(layout, 'Brain-mask experiments - per-slice area (T2 dashed, T1 solid; descriptive, no GT)', ...
    'Interpreter', 'none');
for n = 1:2
    ax = nexttile(layout);
    hold(ax, 'on');
    for i = 1:numel(maskRows)
        e = maskRows(i);
        style = '-';
        if registry{e, 5} == "T2"
            style = '--';
        end
        width = 1;
        if e == reference
            width = 2.5;
        end
        plot(ax, 1:nSlices, areas{n}(:, e), style, 'Color', colors(i, :), 'LineWidth', width);
    end
    hold(ax, 'off');
    ylabel(ax, 'pixels');
    title(ax, sprintf('%s', noiseLevels(n)));
    xlim(ax, [1 nSlices]);
end
legend(ax, strcat([registry{maskRows, 1}], " ", [registry{maskRows, 2}]), 'Location', 'eastoutside', ...
    'Interpreter', 'none', 'FontSize', 7);
xlabel(ax, 'axial slice k');
fig1.Position(3:4) = [1400 900];
exportgraphics(fig1, fullfile(cfg.paths.figures, 'brain_mask_experiments_area_per_slice.png'));


%% Figura 2: riepilogo a barre

fig2 = figure('Color', 'w');
layout = tiledlayout(fig2, 2, 2, 'TileSpacing', 'compact');
title(layout, 'Brain-mask experiments - descriptive summary (pn0 / pn3; no GT)', 'Interpreter', 'none');
labels = categorical(comparison.ID);
labels = reordercats(labels, cellstr(comparison.ID));
panels = {
    [comparison.Voxels_pn0, comparison.Voxels_pn3], 'candidate voxels'
    [comparison.OtsuT1Fraction_pn0, comparison.OtsuT1Fraction_pn3], 'raw T1 Otsu fraction inside (masks)'
    [comparison.RelativeToHead_pn0, comparison.RelativeToHead_pn3], 'area / T2 head support (masks)'
    [comparison.IoU_pn0_pn3, comparison.IoU_vsEXP018_pn0], 'IoU pn0-pn3 / IoU vs EXP-018 (pn0)'
    };
for p = 1:4
    ax = nexttile(layout);
    bar(ax, labels, panels{p, 1});
    title(ax, panels{p, 2});
    if p == 4
        legend(ax, 'IoU pn0-pn3', 'IoU vs EXP-018', 'Location', 'southoutside', 'Orientation', 'horizontal');
    else
        legend(ax, 'pn0', 'pn3', 'Location', 'southoutside', 'Orientation', 'horizontal');
    end
    ax.XTickLabelRotation = 60;
end
fig2.Position(3:4) = [1400 900];
exportgraphics(fig2, fullfile(cfg.paths.figures, 'brain_mask_experiments_summary_bars.png'));


%% Figure 3-4: mosaico visivo (righe = esperimenti, colonne = slice diagnostiche)
% Sfondo: la modalità usata dall'esperimento; rosso = maschera (tinta) o
% marker/bordi (pixel). Diagnostica di sviluppo, NON validazione fase 51.

for n = 1:2
    noise = noiseLevels(n);
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, nExp, numel(displaySlices), 'TileSpacing', 'none', 'Padding', 'compact');
    title(layout, sprintf(['Brain-mask experiments %s - development comparison (NOT Phase-51 validation); ' ...
        'red = mask (tint) or marker/edges (pixels)'], noise), 'Interpreter', 'none');
    for e = 1:nExp
        for c = 1:numel(displaySlices)
            k = displaySlices(c);
            I = backgrounds.(noise).(registry{e, 5})(:, :, k).';
            red = I; green = I; blue = I;
            if ~isempty(masks{e, n})
                m = masks{e, n}(:, :, k).';
                if registry{e, 6} == "mask"
                    red(m) = 0.5 + 0.5 * red(m);
                    green(m) = 0.55 * green(m);
                    blue(m) = 0.55 * blue(m);
                else
                    red(m) = 1;
                    green(m) = 0;
                    blue(m) = 0;
                end
            end
            ax = nexttile(layout);
            image(ax, cat(3, red, green, blue));
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            if e == 1
                title(ax, sprintf('k=%d', k), 'FontSize', 8);
            end
            if c == 1
                ylabel(ax, sprintf('%s\n%s', registry{e, 1}, registry{e, 2}), 'FontSize', 6, ...
                    'Interpreter', 'none');
            end
        end
    end
    fig.Position(3:4) = [1500 2300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('brain_mask_experiments_mosaic_%s.png', noise)), ...
        'Resolution', 150);
end

fprintf('\nComparison written to results/metrics and results/figures (brain_mask_experiments_*).\n');
