%% T1: maschera cerebrale con erosione 3D -> componente 3D più grande -> dilatazione 3D (fase 50, EXP-021)
% Eccezione esplorativa autorizzata dall'utente (2026-10-06): estensione
% volumetrica della ricetta del corso per la rimozione del cranio
% (t1.nii: binarizza -> rimuovi il "ponte" cranio/cervello -> regione più
% grande -> riempi i buchi), che nel corso è mostrata su una sola layer.
% L'elaborazione 3D NON è trattata nel PDF del corso.
%   maschera T1 Otsu grezza (EXP-010)
%   -> imerode 3D con strel('sphere', 3)
%   -> bwconncomp 3D a 26-connettività -> componente più grande
%   -> imdilate 3D con la stessa sfera AND maschera grezza
%   -> imfill 'holes' slice per slice (2D)
% Raggio 3 dichiarato prima dei risultati: spezza collegamenti fino a ~7
% voxel (ponti T2 osservati: >= 3 px in EXP-007, ~5 px in EXP-008; in T1 la
% banda scura è più larga) e preserva il nucleo di sostanza bianca. Una sola
% configurazione, nessuno sweep, nessuna regola di posizione, nessun GT.
% Rischio dichiarato: la componente più grande potrebbe essere collo/faccia;
% la componente che contiene l'ancora EXP-012 del seme è registrata SOLO
% come diagnostica. T1 serve solo per la maschera; T2 resta la modalità
% delle lesioni.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

maskModality = "T1";
assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'EXP-021 requires no filter.');

radius = 3;
connectivity3D = 26;
expectedThresholds = [66 64] / 255;         % EXP-010, solo controllo
expectedRawVoxels = [2771291 2727314];      % EXP-010, solo controllo

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
volumeSize = cfg.dataset.volumeSize;
nSlices = volumeSize(3);
diagnosticSlices = sort([round(linspace(1, nSlices, 5)), 40, 43, 44, 139, 143]);

volumes = cell(1, 2);
rawMasks = cell(1, 2);
erodedMasks = cell(1, 2);
cores = cell(1, 2);
candidates = cell(1, 2);
references = cell(1, 2);
diags = cell(1, 2);
seedInfo = zeros(2, 3);             % seme, componente col seme (rango), scelta = seme?
checks = cell(0, 2);

for n = 1:2
    noise = noiseLevels(n);
    raw = loadBrainwebMri(cfg, maskModality, noise);
    volume = prepare(raw);
    volumeCopy = volume;

    checks(end+1, :) = {noise + " normalized input double in [0,1]", isa(volume, 'double') ...
        && min(volume(:)) >= 0 && max(volume(:)) <= 1}; %#ok<SAGROW>

    [rawMask, threshold] = initialSupportMask(volume);
    checks(end+1, :) = {noise + " EXP-010 threshold reproduced", abs(threshold - expectedThresholds(n)) < 1e-9}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " EXP-010 raw foreground reproduced", nnz(rawMask) == expectedRawVoxels(n)}; %#ok<SAGROW>
    if ~checks{end, 2} || ~checks{end-1, 2}
        error('exp021:inputNotReproduced', 'EXP-010 raw T1 masks not reproduced: EXP-021 TECHNICALLY BLOCKED.');
    end

    rawMaskCopy = rawMask;
    [candidate, core, d] = brainMask3DErodeSelectDilate(rawMask, radius, connectivity3D);

    % Verifiche indipendenti
    eroded = imerode(rawMask, strel('sphere', radius));
    components = bwconncomp(eroded, 26);
    sizes = cellfun(@numel, components.PixelIdxList);
    restored = imdilate(core, strel('sphere', radius)) & rawMask;
    fillRecomputed = true;
    for k = 1:nSlices
        fillRecomputed = fillRecomputed && isequal(candidate(:, :, k), imfill(restored(:, :, k), 'holes'));
    end

    % Diagnostica: quale componente 3D contiene l'ancora EXP-012 del seme
    exp012 = load(fullfile(cfg.paths.processedData, sprintf('exp012_t1_%s_nested_support_mask_candidate.mat', noise)), ...
        'selectedMask', 'candidate');
    exp018 = load(fullfile(cfg.paths.processedData, sprintf('exp018_t1_%s_zpropagation_candidate.mat', noise)), ...
        'candidate', 'seedSlice');
    exp020 = load(fullfile(cfg.paths.processedData, sprintf('exp020_t1_%s_zpropagation_candidate.mat', noise)), ...
        'candidate');
    head = load(fullfile(cfg.paths.processedData, sprintf('phase50_t2_%s_support_mask_candidate.mat', noise)), 'mask');
    labels = labelmatrix(components);
    seedSlice = exp018.seedSlice;
    seedLabels = labels(:, :, seedSlice);
    seedLabels = seedLabels(exp012.selectedMask(:, :, seedSlice) & seedLabels > 0);
    [~, rankOrder] = sort(sizes, 'descend');
    seedComponent = mode(double(seedLabels));
    seedRank = find(rankOrder == seedComponent, 1);
    if isempty(seedRank)
        seedRank = 0;
    end
    seedInfo(n, :) = [seedSlice, seedRank, double(seedComponent == d.selectedIndex)];

    checks(end+1, :) = {noise + " raw mask unchanged", isequal(rawMask, rawMaskCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " 3D erosion + 26-conn recomputed", nnz(eroded) == d.erodedVoxels ...
        && components.NumObjects == d.nComponents}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " selected core = largest 3D component", ~isempty(sizes) && nnz(core) == max(sizes) ...
        && ~any(core & ~eroded, 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " dilated core AND raw, then 2D fill", fillRecomputed && nnz(restored) == d.restoredVoxels}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate logical, same size", islogical(candidate) && isequal(size(candidate), size(volume))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " normalized volume unchanged", isequal(volume, volumeCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw MRI unchanged on reload", isequal(raw, loadBrainwebMri(cfg, maskModality, noise))}; %#ok<SAGROW>

    save(fullfile(cfg.paths.processedData, sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise)), ...
        'candidate', 'core', 'radius', 'threshold');

    volumes{n} = volume;
    rawMasks{n} = rawMask;
    erodedMasks{n} = eroded;
    cores{n} = core;
    candidates{n} = candidate;
    references{n} = struct('exp012', exp012.candidate, 'exp018', exp018.candidate, 'exp020', exp020.candidate, ...
        'head', head.mask);
    diags{n} = d;
end

if any(~[checks{:, 2}])
    error('exp021:checksFailed', 'EXP-021 technical checks failed.');
end


%% Diagnostica

iou = @(a, b) nnz(a & b) / max(nnz(a | b), 1);
sliceArea = @(m) squeeze(sum(m, [1 2]));
rows = cell(2, 1);
for n = 1:2
    d = diags{n};
    c = candidates{n};
    r = references{n};
    nonEmpty = find(sliceArea(c) > 0);
    if isempty(nonEmpty)
        nonEmpty = 0;
    end
    topSizes = [d.componentSizes, zeros(1, 3)];
    rows{n} = {maskModality, noiseLevels(n), radius, d.erodedVoxels, d.nComponents, topSizes(1), topSizes(2), ...
        topSizes(3), seedInfo(n, 2), logical(seedInfo(n, 3)), d.restoredVoxels, d.addedByFilling, nnz(c), ...
        nnz(c) / numel(c), numel(nonEmpty), nonEmpty(1), nonEmpty(end), nnz(c) / nnz(r.head), ...
        iou(c, r.exp012), iou(c, r.exp018), iou(c, r.exp020)};
end
summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'MaskModality', 'Noise', 'Radius', 'ErodedVoxels', 'Components3D', 'Largest', 'Second', 'Third', ...
     'SeedAnchorComponentRank', 'SelectedContainsSeedAnchor', 'RestoredVoxels', 'AddedByFilling', ...
     'CandidateVoxels', 'CandidateFraction', 'NonEmptySlices', 'FirstNonEmpty', 'LastNonEmpty', ...
     'RelativeToT2Head', 'IoU_EXP012', 'IoU_EXP018', 'IoU_EXP020'});
disp(summary);

fprintf('EXP-021 consistency (pn0 vs pn3): IoU = %.4f, differing voxels = %.4f %%\n\n', ...
    iou(candidates{1}, candidates{2}), 100 * nnz(xor(candidates{1}, candidates{2})) / numel(candidates{1}));

for n = 1:2
    r = references{n};
    ks = diagnosticSlices(:);
    area021 = sliceArea(candidates{n});
    area012 = sliceArea(r.exp012);
    area018 = sliceArea(r.exp018);
    area020 = sliceArea(r.exp020);
    disp(table(ks, area021(ks), area012(ks), area018(ks), area020(ks), ...
        'VariableNames', {char("k_" + noiseLevels(n)), 'exp021', 'exp012', 'exp018', 'exp020'}));
end

writetable(summary, fullfile(cfg.paths.metrics, 'exp021_t1_3d_summary.csv'));
perSliceColumns = {};
perSliceNames = {'k'};
for n = 1:2
    r = references{n};
    perSliceColumns = [perSliceColumns, {sliceArea(candidates{n}), sliceArea(cores{n}), sliceArea(r.exp012), ...
        sliceArea(r.exp018), sliceArea(r.exp020)}]; %#ok<AGROW>
    perSliceNames = [perSliceNames, cellstr(noiseLevels(n) + "_" + ["exp021Area", "coreArea", "exp012Area", ...
        "exp018Area", "exp020Area"])]; %#ok<AGROW>
end
perSlice = table((1:nSlices)', perSliceColumns{:}, 'VariableNames', perSliceNames);
writetable(perSlice, fullfile(cfg.paths.metrics, 'exp021_t1_3d_per_slice.csv'));


%% Figure (diagnostica di sviluppo, NON validazione della fase 51)

% 1. Aree per slice
fig1 = figure('Color', 'w');
layout = tiledlayout(fig1, 2, 1, 'TileSpacing', 'compact');
title(layout, 'EXP-021 (3D erode-select-dilate) - per-slice areas vs EXP-012 / EXP-018 / EXP-020', ...
    'Interpreter', 'none');
for n = 1:2
    r = references{n};
    ax = nexttile(layout);
    plot(ax, 1:nSlices, sliceArea(r.exp012), 'b-', 1:nSlices, sliceArea(r.exp018), 'g-', ...
        1:nSlices, sliceArea(r.exp020), 'm-', 1:nSlices, sliceArea(candidates{n}), 'r--', 'LineWidth', 1);
    legend(ax, 'EXP-012', 'EXP-018', 'EXP-020', 'EXP-021 (3D)', 'Location', 'north');
    ylabel(ax, 'pixels');
    title(ax, noiseLevels(n));
    xlim(ax, [1 nSlices]);
end
xlabel(ax, 'axial slice k');
fig1.Position(3:4) = [950 650];
exportgraphics(fig1, fullfile(cfg.paths.figures, 'exp021_t1_3d_area_per_slice.png'));

% 2. Passi per le slice diagnostiche
for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 6, numel(diagnosticSlices), 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf(['EXP-021 T1 %s development diagnostic (NOT Phase-51 validation) - T1 / raw Otsu / ' ...
        '3D-eroded / selected 3D core / EXP-021 candidate / candidate on T1'], noiseLevels(n)), 'Interpreter', 'none');
    for row = 1:6
        for c = 1:numel(diagnosticSlices)
            k = diagnosticSlices(c);
            I = volumes{n}(:, :, k).';
            switch row
                case 1, rgb = repmat(I, 1, 1, 3);
                case 2, rgb = repmat(double(rawMasks{n}(:, :, k).'), 1, 1, 3);
                case 3, rgb = repmat(double(erodedMasks{n}(:, :, k).'), 1, 1, 3);
                case 4, rgb = repmat(double(cores{n}(:, :, k).'), 1, 1, 3);
                case 5, rgb = repmat(double(candidates{n}(:, :, k).'), 1, 1, 3);
                case 6, rgb = tintRed(I, candidates{n}(:, :, k).');
            end
            ax = nexttile(layout);
            image(ax, rgb);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('k=%d', k), 'FontSize', 7);
        end
    end
    fig.Position(3:4) = [1700 1100];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp021_t1_%s_3d_steps.png', noiseLevels(n))), ...
        'Resolution', 150);
end

% 3. Viste ortogonali centrali (sagittale e coronale): EXP-018 vs EXP-021
mid = round(volumeSize / 2);
fig3 = figure('Color', 'w');
layout = tiledlayout(fig3, 2, 4, 'TileSpacing', 'compact');
title(layout, 'EXP-018 vs EXP-021 - central sagittal (i = 91) and coronal (j = 109) views, pn0 / pn3', ...
    'Interpreter', 'none');
for n = 1:2
    r = references{n};
    sagittalI = squeeze(volumes{n}(mid(1), :, :)).';
    coronalI = squeeze(volumes{n}(:, mid(2), :)).';
    views = {tintRed(sagittalI, squeeze(r.exp018(mid(1), :, :)).'), 'EXP-018 sagittal'
             tintRed(sagittalI, squeeze(candidates{n}(mid(1), :, :)).'), 'EXP-021 sagittal'
             tintRed(coronalI, squeeze(r.exp018(:, mid(2), :)).'), 'EXP-018 coronal'
             tintRed(coronalI, squeeze(candidates{n}(:, mid(2), :)).'), 'EXP-021 coronal'};
    for v = 1:4
        ax = nexttile(layout);
        image(ax, views{v, 1});
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('%s %s', noiseLevels(n), views{v, 2}), 'FontSize', 8);
    end
end
fig3.Position(3:4) = [1400 750];
exportgraphics(fig3, fullfile(cfg.paths.figures, 'exp021_t1_3d_orthogonal_views.png'), 'Resolution', 150);


%% Esito dei controlli

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-48s %s\n', checks{c, 1}, result);
end
fprintf('\nEXP-021 CHECKS: PASS\n');


function rgb = tintRed(I, mask)
%TINTRED Immagine in scala di grigi con la maschera in rosso semitrasparente.
    red = I; green = I; blue = I;
    red(mask) = 0.5 + 0.5 * red(mask);
    green(mask) = 0.55 * green(mask);
    blue(mask) = 0.55 * blue(mask);
    rgb = cat(3, red, green, blue);
end
