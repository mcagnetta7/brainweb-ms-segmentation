%% Fase 51: validazione visiva della maschera cerebrale EXP-021
% Validazione della roadmap, NON un esperimento: non è EXP-022 e non
% modifica EXP-021. Carica le maschere EXP-021 salvate (congelate, raggio
% 3) e la T1 di sviluppo (pn0, pn3), e mostra il CONTORNO della maschera
% sopra la MRI:
%   - foglio di contatto assiale su tutto il volume (una slice ogni 5)
%   - viste assiali ingrandite alle slice diagnostiche già dichiarate
%   - viste coronali e sagittali a 1/4, 1/2, 3/4 del volume
%   - viste della sola maschera (assiale, coronale, sagittale centrali e
%     proiezioni lungo i tre assi)
% Il contorno è estratto solo per la visualizzazione (mask AND NOT
% imerode(mask, 3x3)), slice per slice, senza toccare la maschera.
% Nessun ground truth, nessuna etichetta anatomica, nessun dato held-out.
% Il giudizio qualitativo è dato dopo l'ispezione delle figure.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.visualization);

assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
volumeSize = cfg.dataset.volumeSize;
nSlices = volumeSize(3);

% Scelte di sola visualizzazione (non influenzano nessun algoritmo)
contactStep = 5;
contactSlices = 1:contactStep:nSlices;
if contactSlices(end) ~= nSlices
    contactSlices(end+1) = nSlices;
end
diagnosticSlices = [1 40 43 44 46 91 136 139 143 160 181];
coronalPlanes = round([0.25 0.5 0.75] * volumeSize(2));      % indici j
sagittalPlanes = round([0.25 0.5 0.75] * volumeSize(1));     % indici i
boundaryColor = [1 1 0];

maskFile = @(noise) fullfile(cfg.paths.processedData, ...
    sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));


%% Caricamento e controlli tecnici

volumes = cell(1, 2);
masks = cell(1, 2);
rawCopies = cell(1, 2);
maskCopies = cell(1, 2);
checks = cell(0, 2);
for n = 1:2
    noise = noiseLevels(n);
    raw = loadBrainwebMri(cfg, "T1", noise);
    volume = prepare(raw);
    saved = load(maskFile(noise), 'candidate', 'radius');
    mask = saved.candidate;
    maskCopy = mask;

    checks(end+1, :) = {noise + " T1 size = volumeSize", isequal(size(volume), volumeSize)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " mask size = T1 size", isequal(size(mask), size(volume))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " mask logical", islogical(mask)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " T1 finite (no NaN/Inf)", all(isfinite(volume(:)))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " frozen EXP-021 radius = 3", saved.radius == 3}; %#ok<SAGROW>

    volumes{n} = volume;
    masks{n} = mask;
    rawCopies{n} = raw;
    maskCopies{n} = maskCopy;
end
if any(~[checks{:, 2}])
    error('phase51:technicallyBlocked', 'Phase 51 TECHNICALLY BLOCKED: input checks failed.');
end


%% Statistiche descrittive (non sostituiscono la validazione visiva)

rows = cell(2, 1);
for n = 1:2
    m = masks{n};
    areas = squeeze(sum(m, [1 2]));
    nonEmpty = find(areas > 0);
    rows{n} = {noiseLevels(n), nnz(m), nnz(m) / numel(m), numel(nonEmpty), nonEmpty(1), nonEmpty(end), ...
        areas(150), areas(155), areas(160)};
end
statistics = cell2table(vertcat(rows{:}), 'VariableNames', {'Condition', 'MaskVoxels', 'MaskFraction', ...
    'NonEmptySlices', 'FirstNonEmpty', 'LastNonEmpty', 'Area_k150', 'Area_k155', 'Area_k160'});
disp(statistics);
iou = nnz(masks{1} & masks{2}) / nnz(masks{1} | masks{2});
fprintf('pn0 vs pn3 mask IoU = %.4f\n\n', iou);
statistics.IoU_pn0_pn3 = [iou; iou];
writetable(statistics, fullfile(cfg.paths.metrics, 'phase51_exp021_descriptive_statistics.csv'));


%% Figura 1-2: foglio di contatto assiale (contorno)

for n = 1:2
    fig = figure('Color', 'w');
    nCols = 8;
    layout = tiledlayout(fig, ceil(numel(contactSlices) / nCols), nCols, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf(['Phase 51 - EXP-021 boundary on T1 %s, axial contact sheet (every %d slices + last); ' ...
        'yellow = mask boundary'], noiseLevels(n), contactStep), 'Interpreter', 'none');
    for k = contactSlices
        overlayMaskBoundaryOnMRI(nexttile(layout), volumes{n}(:, :, k), masks{n}(:, :, k), ...
            'BoundaryColor', boundaryColor, 'Title', sprintf('k=%d', k));
    end
    fig.Position(3:4) = [1600 1500];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('phase51_exp021_axial_contact_sheet_%s.png', ...
        noiseLevels(n))), 'Resolution', 150);
end


%% Figura 3-4: slice assiali diagnostiche ingrandite (contorno + riempimento)

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 4, 6, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf(['Phase 51 - EXP-021 on T1 %s, enlarged diagnostic slices: boundary (primary) and ' ...
        'semi-transparent fill'], noiseLevels(n)), 'Interpreter', 'none');
    for s = 1:numel(diagnosticSlices)
        k = diagnosticSlices(s);
        overlayMaskBoundaryOnMRI(nexttile(layout), volumes{n}(:, :, k), masks{n}(:, :, k), ...
            'BoundaryColor', boundaryColor, 'Title', sprintf('k=%d boundary', k));
        overlayMaskBoundaryOnMRI(nexttile(layout), volumes{n}(:, :, k), masks{n}(:, :, k), ...
            'BoundaryColor', [1 0 0], 'ShowFill', true, 'Title', sprintf('k=%d fill', k));
    end
    fig.Position(3:4) = [1700 1250];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('phase51_exp021_axial_diagnostic_%s.png', ...
        noiseLevels(n))), 'Resolution', 150);
end


%% Figura 5: coronali (righe pn0 / pn3, colonne j = 1/4, 1/2, 3/4)

fig = figure('Color', 'w');
layout = tiledlayout(fig, 2, numel(coronalPlanes), 'TileSpacing', 'compact', 'Padding', 'compact');
title(layout, sprintf('Phase 51 - EXP-021 boundary, coronal planes j = %s (rows: pn0, pn3)', ...
    mat2str(coronalPlanes)), 'Interpreter', 'none');
for n = 1:2
    for j = coronalPlanes
        overlayMaskBoundaryOnMRI(nexttile(layout), squeeze(volumes{n}(:, j, :)), squeeze(masks{n}(:, j, :)), ...
            'BoundaryColor', boundaryColor, 'Title', sprintf('%s coronal j=%d', noiseLevels(n), j));
    end
end
fig.Position(3:4) = [1500 1000];
exportgraphics(fig, fullfile(cfg.paths.figures, 'phase51_exp021_coronal_validation.png'), 'Resolution', 150);


%% Figura 6: sagittali (righe pn0 / pn3, colonne i = 1/4, 1/2, 3/4)

fig = figure('Color', 'w');
layout = tiledlayout(fig, 2, numel(sagittalPlanes), 'TileSpacing', 'compact', 'Padding', 'compact');
title(layout, sprintf('Phase 51 - EXP-021 boundary, sagittal planes i = %s (rows: pn0, pn3)', ...
    mat2str(sagittalPlanes)), 'Interpreter', 'none');
for n = 1:2
    for i = sagittalPlanes
        overlayMaskBoundaryOnMRI(nexttile(layout), squeeze(volumes{n}(i, :, :)), squeeze(masks{n}(i, :, :)), ...
            'BoundaryColor', boundaryColor, 'Title', sprintf('%s sagittal i=%d', noiseLevels(n), i));
    end
end
fig.Position(3:4) = [1500 950];
exportgraphics(fig, fullfile(cfg.paths.figures, 'phase51_exp021_sagittal_validation.png'), 'Resolution', 150);


%% Figura 7: sola maschera (piani centrali + proiezioni lungo i tre assi)

center = round(volumeSize / 2);
fig = figure('Color', 'w');
layout = tiledlayout(fig, 2, 6, 'TileSpacing', 'compact', 'Padding', 'compact');
title(layout, sprintf(['Phase 51 - EXP-021 mask only: central axial k=%d, coronal j=%d, sagittal i=%d, ' ...
    'and projections (any voxel along the axis); rows: pn0, pn3'], center(3), center(2), center(1)), ...
    'Interpreter', 'none');
for n = 1:2
    m = masks{n};
    panels = {m(:, :, center(3)), sprintf('axial k=%d', center(3))
              squeeze(m(:, center(2), :)), sprintf('coronal j=%d', center(2))
              squeeze(m(center(1), :, :)), sprintf('sagittal i=%d', center(1))
              squeeze(any(m, 3)), 'axial projection'
              squeeze(any(m, 2)), 'coronal projection'
              squeeze(any(m, 1)), 'sagittal projection'};
    for p = 1:size(panels, 1)
        ax = nexttile(layout);
        imagesc(ax, double(panels{p, 1}).');
        colormap(ax, gray);
        clim(ax, [0 1]);
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('%s %s', noiseLevels(n), panels{p, 2}), 'FontSize', 8);
    end
end
fig.Position(3:4) = [1700 700];
exportgraphics(fig, fullfile(cfg.paths.figures, 'phase51_exp021_orthogonal_mask_validation.png'), 'Resolution', 150);


%% Controlli finali: dati invariati

for n = 1:2
    noise = noiseLevels(n);
    checks(end+1, :) = {noise + " mask unchanged after display", isequal(masks{n}, maskCopies{n})}; %#ok<SAGROW>
    reloaded = load(maskFile(noise), 'candidate');
    checks(end+1, :) = {noise + " saved EXP-021 file unchanged", isequal(reloaded.candidate, masks{n})}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw MRI unchanged on reload", isequal(rawCopies{n}, loadBrainwebMri(cfg, "T1", noise))}; %#ok<SAGROW>
end

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-44s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase51:checksFailed', 'Phase 51 technical checks failed.');
end
fprintf('\nPHASE 51 FIGURES READY (qualitative judgement follows inspection)\n');
