%% Separazione per erosione-selezione-dilatazione (fase 50, EXP-007)
% Esperimento supplementare dentro la fase 50, dopo il fallimento del
% candidato B (EXP-006). Unica differenza rispetto a B: la componente più
% grande viene scelta TRA erosione e dilatazione, invece che dopo
% un'apertura completa.
%
%   raw Otsu -> imerode 3x3 -> componente più grande (8-conn)
%            -> imdilate 3x3 -> AND raw -> imfill holes
%
% Stesso elemento strutturante di B (strel('square', 3)): nessun nuovo
% parametro. Stessa regola per pn0 e pn3.
%
% Regola di decisione dichiarata prima dei risultati: EXP-007 sostituisce
% il candidato A solo se, nelle viste delle sole maschere, sulle slice
% deterministiche centrali lo scalpo è separato e resta una regione
% intracranica, in modo coerente tra pn0 e pn3, senza frammentazione
% evidente. Altrimenti resta A (e si valuta EXP-008, watershed con marker).
%
% Nessuna soglia di area, intervallo di slice, regola di posizione, 3D,
% ground truth o sovrapposizione alla MRI. Se un controllo fallisce lo
% script si interrompe con un errore.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

modality = cfg.dataset.modality;
assert(cfg.preprocessing.filter.method == "none", 'Phase 50 requires no filter.');

connectivity = 8;
element = strel('square', 3);
expectedThresholds = [78 75] / 255;         % EXP-005, solo controllo di riproducibilità

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
nSlices = cfg.dataset.volumeSize(3);
displaySlices = round(linspace(1, nSlices, 5));

rawMasks = cell(1, 2);
masksA = cell(1, 2);
masks7 = cell(1, 2);
diag7 = cell(1, 2);
checks = cell(0, 2);

for n = 1:2
    noise = noiseLevels(n);
    volume = prepare(loadBrainwebMri(cfg, modality, noise));
    [rawMask, threshold] = initialSupportMask(volume);
    checks(end+1, :) = {noise + " EXP-005 threshold reproduced", ...
        abs(threshold - expectedThresholds(n)) < 1e-9}; %#ok<SAGROW>

    masksA{n} = cleanSupportMaskSlices(rawMask, connectivity, []);
    [masks7{n}, diag7{n}] = erodeSelectDilateSlices(rawMask, connectivity, element);
    rawMasks{n} = rawMask;

    checks(end+1, :) = {noise + " EXP-007 logical, same size", ...
        islogical(masks7{n}) && isequal(size(masks7{n}), size(rawMask))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " EXP-007 restored part within raw", ...
        sum(diag7{n}.restoredArea) <= nnz(rawMask)}; %#ok<SAGROW>
end

if any(~[checks{:, 2}])
    error('exp007:checksFailed', 'EXP-007 checks failed.');
end


%% Diagnostica

rows = cell(2, 1);
for n = 1:2
    d = diag7{n};
    rows{n} = {string(modality), noiseLevels(n), ...
        nnz(rawMasks{n}) / numel(rawMasks{n}), ...
        nnz(masksA{n}) / numel(masksA{n}), ...
        nnz(masks7{n}), nnz(masks7{n}) / numel(masks7{n}), ...
        sum(d.removedBySelection), sum(d.addedByFilling), ...
        nnz(squeeze(any(masks7{n}, [1 2])))};
end
summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'Modality', 'Noise', 'RawFraction', 'CandidateAFraction', ...
     'Exp007Voxels', 'Exp007Fraction', 'RemovedBySelection', 'AddedByFilling', 'NonEmptySlices'});
disp(summary);

intersectionOverUnion = nnz(masks7{1} & masks7{2}) / nnz(masks7{1} | masks7{2});
fprintf('EXP-007 consistency (pn0 vs pn3): IoU = %.4f, differing voxels = %.4f %%\n\n', ...
    intersectionOverUnion, 100 * nnz(xor(masks7{1}, masks7{2})) / numel(masks7{1}));

writetable(summary, fullfile(cfg.paths.metrics, 'exp007_erode_select_dilate_summary.csv'));
areaPerSlice = table((1:nSlices)', ...
    squeeze(sum(masksA{1}, [1 2])), squeeze(sum(masks7{1}, [1 2])), ...
    squeeze(sum(masksA{2}, [1 2])), squeeze(sum(masks7{2}, [1 2])), ...
    'VariableNames', {'k', 'pn0_areaA', 'pn0_areaExp007', 'pn3_areaA', 'pn3_areaExp007'});
writetable(areaPerSlice, fullfile(cfg.paths.metrics, 'exp007_area_per_slice.csv'));


%% Figure (solo maschere)

fig1 = figure('Color', 'w');
ax = axes('Parent', fig1);
plot(ax, 1:nSlices, areaPerSlice.pn0_areaA, 'b-', 1:nSlices, areaPerSlice.pn0_areaExp007, 'b--', ...
    1:nSlices, areaPerSlice.pn3_areaA, 'r-', 1:nSlices, areaPerSlice.pn3_areaExp007, 'r--');
legend(ax, 'pn0 candidate A', 'pn0 EXP-007', 'pn3 candidate A', 'pn3 EXP-007', 'Location', 'north');
xlabel(ax, 'axial slice k'); ylabel(ax, 'foreground pixels per slice');
title(ax, 'EXP-007 vs candidate A - mask area per slice (all slices)');
xlim(ax, [1 nSlices]);
fig1.Position(3:4) = [900 450];
exportgraphics(fig1, fullfile(cfg.paths.figures, 'exp007_area_per_slice.png'));

fig2 = figure('Color', 'w');
layout = tiledlayout(fig2, 6, numel(displaySlices), 'TileSpacing', 'compact');
title(layout, 'EXP-007 - raw / candidate A / EXP-007 (erode 3x3 -> largest -> dilate 3x3 -> AND raw -> fill), mask only', ...
    'Interpreter', 'none');
for n = 1:2
    versions = {rawMasks{n}, masksA{n}, masks7{n}};
    labels = ["raw", "A", "EXP-007"];
    for v = 1:3
        for s = 1:numel(displaySlices)
            ax = nexttile(layout);
            imagesc(ax, versions{v}(:, :, displaySlices(s)).');
            colormap(ax, gray);
            clim(ax, [0 1]);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('%s %s  k = %d', noiseLevels(n), labels(v), displaySlices(s)));
        end
    end
end
fig2.Position(3:4) = [1300 1600];
exportgraphics(fig2, fullfile(cfg.paths.figures, 'exp007_raw_A_exp007_masks.png'));


%% Salvataggio (non sovrascrive il candidato A della fase 50)

for n = 1:2
    mask = masks7{n};
    cleanupRule = 'EXP-007: imerode square 3x3 -> largest 8-conn 2D component -> imdilate square 3x3 -> AND raw -> imfill holes';
    save(fullfile(cfg.paths.processedData, ...
        sprintf('exp007_%s_%s_support_mask.mat', lower(modality), noiseLevels(n))), 'mask', 'cleanupRule');
end

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-42s %s\n', checks{c, 1}, result);
end
fprintf('\nEXP-007 CHECKS: PASS\n');
