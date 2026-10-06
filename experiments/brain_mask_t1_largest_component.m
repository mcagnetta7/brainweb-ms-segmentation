%% T1: componente più grande + riempimento dei buchi (fase 50, EXP-011)
% Dopo EXP-010 (T1 promettente), si riapplica SENZA MODIFICHE la regola del
% candidato A di EXP-006 alla maschera grezza T1:
%   T1 -> double -> /4095 -> nessun filtro -> Otsu globale per volume
%   -> per ogni slice: componente più grande a 8-connettività -> imfill
% Funzioni riusate senza modifiche: initialSupportMask, cleanSupportMaskSlices.
%
% "La componente più grande" è il candidato automatico di supporto
% cerebrale testato qui, non un fatto anatomico. Nessuna altra morfologia,
% nessuna soglia di area, nessuna regola di posizione o di continuità tra
% slice, nessun 3D, nessun ground truth. T1 serve solo per la maschera;
% T2 resta la modalità delle lesioni.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

maskModality = "T1";
assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'EXP-011 requires no filter.');

connectivity = 8;
expectedThresholds = [66 64] / 255;         % EXP-010, solo controllo
expectedRawVoxels = [2771291 2727314];      % EXP-010, solo controllo

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
nSlices = cfg.dataset.volumeSize(3);
displaySlices = round(linspace(1, nSlices, 5));

volumes = cell(1, 2);
rawMasks = cell(1, 2);
candidates = cell(1, 2);
diags = cell(1, 2);
secondArea = zeros(nSlices, 2);
checks = cell(0, 2);

for n = 1:2
    noise = noiseLevels(n);
    raw = loadBrainwebMri(cfg, maskModality, noise);
    volume = prepare(raw);
    volumeCopy = volume;

    [rawMask, threshold] = initialSupportMask(volume);
    checks(end+1, :) = {noise + " EXP-010 threshold reproduced", abs(threshold - expectedThresholds(n)) < 1e-9}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " EXP-010 raw foreground reproduced", nnz(rawMask) == expectedRawVoxels(n)}; %#ok<SAGROW>
    if any(~[checks{:, 2}])
        error('exp011:inputNotReproduced', 'EXP-010 raw T1 masks not reproduced.');
    end

    [candidate, d] = cleanSupportMaskSlices(rawMask, connectivity, []);

    % Diagnostica: seconda componente per slice (non modifica nulla)
    for k = 1:nSlices
        components = bwconncomp(rawMask(:, :, k), connectivity);
        areas = sort(cellfun(@numel, components.PixelIdxList), 'descend');
        if numel(areas) > 1
            secondArea(k, n) = areas(2);
        end
    end

    checks(end+1, :) = {noise + " candidate logical, same size", islogical(candidate) && isequal(size(candidate), size(volume))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " voxel accounting", nnz(candidate) == nnz(rawMask) ...
        - sum(d.removedByComponent) + sum(d.addedByFilling)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " normalized volume unchanged", isequal(volume, volumeCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw MRI unchanged on reload", isequal(raw, loadBrainwebMri(cfg, maskModality, noise))}; %#ok<SAGROW>

    save(fullfile(cfg.paths.processedData, sprintf('exp011_t1_%s_support_mask_candidate.mat', noise)), ...
        'candidate', 'threshold');

    volumes{n} = volume;
    rawMasks{n} = rawMask;
    candidates{n} = candidate;
    diags{n} = d;
end

if any(~[checks{:, 2}])
    error('exp011:checksFailed', 'EXP-011 technical checks failed.');
end


%% Diagnostica

rows = cell(2, 1);
for n = 1:2
    d = diags{n};
    c = candidates{n};
    nonEmpty = find(squeeze(any(c, [1 2])));
    hasSecond = secondArea(:, n) > 0;
    ratio = d.largestArea(hasSecond) ./ secondArea(hasSecond, n);
    rows{n} = {maskModality, noiseLevels(n), nnz(rawMasks{n}), ...
        median(d.nComponents), max(d.nComponents), nnz(d.nComponents > 1), ...
        median(d.largestArea), median(secondArea(hasSecond, n)), median(ratio), min(ratio), ...
        sum(d.removedByComponent), sum(d.addedByFilling), nnz(c), nnz(c) / numel(c), ...
        numel(nonEmpty), nSlices - numel(nonEmpty), nonEmpty(1), nonEmpty(end)};
end
summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'MaskModality', 'Noise', 'RawVoxels', 'MedianComponents', 'MaxComponents', 'SlicesMultipleComponents', ...
     'MedianLargestArea', 'MedianSecondArea', 'MedianLargestToSecondRatio', 'MinLargestToSecondRatio', ...
     'RemovedByComponent', 'AddedByFilling', 'CandidateVoxels', 'CandidateFraction', ...
     'NonEmptySlices', 'EmptySlices', 'FirstNonEmpty', 'LastNonEmpty'});
disp(summary);

intersectionOverUnion = nnz(candidates{1} & candidates{2}) / nnz(candidates{1} | candidates{2});
fprintf('EXP-011 consistency (pn0 vs pn3): IoU = %.4f, differing voxels = %.4f %%\n\n', ...
    intersectionOverUnion, 100 * nnz(xor(candidates{1}, candidates{2})) / numel(candidates{1}));

writetable(summary, fullfile(cfg.paths.metrics, 'exp011_t1_largest_component_summary.csv'));
finalArea = [squeeze(sum(candidates{1}, [1 2])), squeeze(sum(candidates{2}, [1 2]))];
perSlice = table((1:nSlices)', diags{1}.nComponents, diags{1}.largestArea, secondArea(:, 1), finalArea(:, 1), ...
    diags{2}.nComponents, diags{2}.largestArea, secondArea(:, 2), finalArea(:, 2), ...
    'VariableNames', {'k', 'pn0_nComponents', 'pn0_largest', 'pn0_second', 'pn0_final', ...
                      'pn3_nComponents', 'pn3_largest', 'pn3_second', 'pn3_final'});
writetable(perSlice, fullfile(cfg.paths.metrics, 'exp011_t1_largest_component_per_slice.csv'));


%% Figure (solo maschere e MRI affiancate, nessuna sovrapposizione)

% 1. Aree per slice su tutto il volume
fig1 = figure('Color', 'w');
layout = tiledlayout(fig1, 2, 1, 'TileSpacing', 'compact');
title(layout, 'EXP-011 - per-slice areas: largest component, second component, final candidate (all slices)', ...
    'Interpreter', 'none');
for n = 1:2
    ax = nexttile(layout);
    plot(ax, 1:nSlices, diags{n}.largestArea, 'b-', 1:nSlices, secondArea(:, n), 'r-', ...
        1:nSlices, finalArea(:, n), 'k--');
    legend(ax, 'largest component', 'second component', 'final (after filling)', 'Location', 'north');
    ylabel(ax, 'pixels');
    title(ax, sprintf('T1 %s', noiseLevels(n)));
    xlim(ax, [1 nSlices]);
end
xlabel(ax, 'axial slice k');
fig1.Position(3:4) = [950 650];
exportgraphics(fig1, fullfile(cfg.paths.figures, 'exp011_t1_area_per_slice.png'));

% 2. T1 / maschera grezza / componente scelta prima del riempimento / candidato
for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 4, numel(displaySlices), 'TileSpacing', 'compact');
    title(layout, sprintf('EXP-011 T1 %s - T1 / raw Otsu mask / largest component (before filling) / candidate', ...
        noiseLevels(n)), 'Interpreter', 'none');
    rowNames = ["T1", "raw mask", "largest component", "EXP-011 candidate"];
    for r = 1:4
        for s = 1:numel(displaySlices)
            k = displaySlices(s);
            switch r
                case 1, panel = volumes{n}(:, :, k);
                case 2, panel = rawMasks{n}(:, :, k);
                case 3, panel = largestComponent(rawMasks{n}(:, :, k), connectivity);
                case 4, panel = candidates{n}(:, :, k);
            end
            ax = nexttile(layout);
            imagesc(ax, double(panel).');
            colormap(ax, gray);
            clim(ax, [0 1]);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('%s  k = %d', rowNames(r), k));
        end
    end
    fig.Position(3:4) = [1300 1100];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp011_t1_%s_cleanup_steps.png', noiseLevels(n))));
end


%% Esito dei controlli

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-42s %s\n', checks{c, 1}, result);
end
fprintf('\nEXP-011 CHECKS: PASS\n');


function selected = largestComponent(slice, connectivity)
%LARGESTCOMPONENT Componente più grande di una slice (solo per le figure).
    selected = false(size(slice));
    components = bwconncomp(slice, connectivity);
    if components.NumObjects > 0
        [~, index] = max(cellfun(@numel, components.PixelIdxList));
        selected(components.PixelIdxList{index}) = true;
    end
end
