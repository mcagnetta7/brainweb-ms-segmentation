%% EXP-021: controllo di robustezza al raggio (solo descrittivo, nessuna selezione)
% EXP-021 è congelato con raggio 3 (decisione utente 2026-10-06, dichiarata
% prima di questo controllo). Qui lo stesso metodo viene rilanciato con
% raggio 2 e 4 SOLO per riportare quanto il risultato dipende dal raggio.
% Il raggio resta 3 qualunque sia l'esito: questo script non sceglie nulla
% e non salva maschere candidate. Nessun GT, nessuna etichetta anatomica.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

frozenRadius = 3;
radii = [2 3 4];
connectivity3D = 26;
expectedRawVoxels = [2771291 2727314];      % EXP-010, solo controllo

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
nSlices = cfg.dataset.volumeSize(3);
mid = round(cfg.dataset.volumeSize / 2);
diagnosticSlices = sort([round(linspace(1, nSlices, 5)), 40, 43, 44, 139, 143]);
iou = @(a, b) nnz(a & b) / max(nnz(a | b), 1);
sliceArea = @(m) squeeze(sum(m, [1 2]));

volumes = cell(1, 2);
results = cell(numel(radii), 2);
diags = cell(numel(radii), 2);
seedOk = false(numel(radii), 2);
checks = cell(0, 2);

for n = 1:2
    noise = noiseLevels(n);
    volume = prepare(loadBrainwebMri(cfg, "T1", noise));
    rawMask = initialSupportMask(volume);
    checks(end+1, :) = {noise + " EXP-010 raw foreground reproduced", nnz(rawMask) == expectedRawVoxels(n)}; %#ok<SAGROW>

    exp012 = load(fullfile(cfg.paths.processedData, sprintf('exp012_t1_%s_nested_support_mask_candidate.mat', noise)), ...
        'selectedMask');
    exp018 = load(fullfile(cfg.paths.processedData, sprintf('exp018_t1_%s_zpropagation_candidate.mat', noise)), ...
        'seedSlice');
    frozen = load(fullfile(cfg.paths.processedData, sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise)), ...
        'candidate');
    seedAnchor = false(size(rawMask));
    seedAnchor(:, :, exp018.seedSlice) = exp012.selectedMask(:, :, exp018.seedSlice);

    for r = 1:numel(radii)
        [candidate, core, d] = brainMask3DErodeSelectDilate(rawMask, radii(r), connectivity3D);
        results{r, n} = candidate;
        diags{r, n} = d;
        seedOk(r, n) = any(core & seedAnchor, 'all');
        if radii(r) == frozenRadius
            checks(end+1, :) = {noise + " radius 3 reproduces frozen EXP-021", isequal(candidate, frozen.candidate)}; %#ok<SAGROW>
        end
    end
    volumes{n} = volume;
end

if any(~[checks{:, 2}])
    error('exp021sens:checksFailed', 'Sensitivity check could not reproduce EXP-021.');
end


%% Tabella

rows = {};
reference = find(radii == frozenRadius);
for r = 1:numel(radii)
    for n = 1:2
        d = diags{r, n};
        c = results{r, n};
        areas = sliceArea(c);
        nonEmpty = find(areas > 0);
        sizes = [d.componentSizes, 0, 0];
        rows(end+1, :) = {radii(r), noiseLevels(n), d.nComponents, sizes(1), sizes(2), seedOk(r, n), ...
            nnz(c), numel(nonEmpty), nonEmpty(1), nonEmpty(end), iou(c, results{reference, n}), ...
            areas(40), areas(44), areas(91), areas(136), areas(150)}; %#ok<SAGROW>
    end
end
summary = cell2table(rows, 'VariableNames', {'Radius', 'Noise', 'Components3D', 'Largest', 'Second', ...
    'LargestHoldsSeedAnchor', 'CandidateVoxels', 'NonEmptySlices', 'FirstNonEmpty', 'LastNonEmpty', ...
    'IoU_vsRadius3', 'Area_k40', 'Area_k44', 'Area_k91', 'Area_k136', 'Area_k150'});
disp(summary);
for r = 1:numel(radii)
    fprintf('radius %d: IoU pn0 vs pn3 = %.4f\n', radii(r), iou(results{r, 1}, results{r, 2}));
end
writetable(summary, fullfile(cfg.paths.metrics, 'exp021_t1_3d_radius_sensitivity.csv'));


%% Figure (solo descrittive)

% 1. Aree per slice
fig1 = figure('Color', 'w');
layout = tiledlayout(fig1, 2, 1, 'TileSpacing', 'compact');
title(layout, 'EXP-021 radius sensitivity (descriptive only; frozen radius = 3)', 'Interpreter', 'none');
styles = {'b-', 'r--', 'g-'};
for n = 1:2
    ax = nexttile(layout);
    hold(ax, 'on');
    for r = 1:numel(radii)
        plot(ax, 1:nSlices, sliceArea(results{r, n}), styles{r}, 'LineWidth', 1);
    end
    hold(ax, 'off');
    legend(ax, compose('radius %d', radii), 'Location', 'north');
    ylabel(ax, 'pixels');
    title(ax, noiseLevels(n));
    xlim(ax, [1 nSlices]);
end
xlabel(ax, 'axial slice k');
fig1.Position(3:4) = [950 650];
exportgraphics(fig1, fullfile(cfg.paths.figures, 'exp021_t1_3d_radius_sensitivity_area.png'));

% 2. Mosaico pn0: righe = raggi, colonne = slice diagnostiche + coronale centrale
fig2 = figure('Color', 'w');
nCols = numel(diagnosticSlices) + 1;
layout = tiledlayout(fig2, numel(radii), nCols, 'TileSpacing', 'tight', 'Padding', 'tight');
title(layout, 'EXP-021 radius sensitivity, pn0 (descriptive only; NOT Phase-51 validation)', 'Interpreter', 'none');
for r = 1:numel(radii)
    for c = 1:nCols
        if c <= numel(diagnosticSlices)
            k = diagnosticSlices(c);
            I = volumes{1}(:, :, k).';
            m = results{r, 1}(:, :, k).';
            label = sprintf('r=%d k=%d', radii(r), k);
        else
            I = squeeze(volumes{1}(:, mid(2), :)).';
            m = squeeze(results{r, 1}(:, mid(2), :)).';
            label = sprintf('r=%d coronal', radii(r));
        end
        red = I; green = I; blue = I;
        red(m) = 0.5 + 0.5 * red(m);
        green(m) = 0.55 * green(m);
        blue(m) = 0.55 * blue(m);
        ax = nexttile(layout);
        image(ax, cat(3, red, green, blue));
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, label, 'FontSize', 7);
    end
end
fig2.Position(3:4) = [1800 560];
exportgraphics(fig2, fullfile(cfg.paths.figures, 'exp021_t1_3d_radius_sensitivity_mosaic.png'), 'Resolution', 150);

for c = 1:size(checks, 1)
    fprintf('%-48s %s\n', checks{c, 1}, string(checks{c, 2}));
end
fprintf('\nEXP-021 RADIUS SENSITIVITY: DONE (radius stays 3)\n');
