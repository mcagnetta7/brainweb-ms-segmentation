%% T1: watershed a marker con marker topologici (fase 50, EXP-014)
% Dopo EXP-013 la selezione tra componenti già separate è esaurita: nelle
% slice inferiori il tessuto simile a cervello è 8-connesso al componente
% periferico. EXP-014 prova UNA configurazione dichiarata prima:
%   T1 -> double -> /4095 -> nessun filtro -> Otsu globale (EXP-010)
%   -> per slice: ancora EXP-012 (marker del primo piano, invariata)
%   -> genitore immediato P (regola EXP-013), filledParent = imfill(P)
%   -> marker non-cervello = NOT filledParent OR bordo ESTERNO 3x3 di P
%      (chiarimento della specifica: i bordi attorno ai buchi interni di P
%      restano liberi)
%   -> gradiente morfologico 3x3 della T1 originale
%   -> imimposemin + watershed
%   -> bacini toccati dall'ancora AND filledParent AND NOT marker
%      non-cervello -> imfill
% Nessuna ancora -> slice VUOTA. Nessuna variante, nessuno sweep, nessun
% fratello di EXP-013 aggiunto. Diverso da EXP-008 (T2, marker da erosione
% 5x5): qui modalità T1 e marker del primo piano topologico.
% T1 serve solo per la maschera; T2 resta la modalità delle lesioni.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

maskModality = "T1";
assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'EXP-014 requires no filter.');

connectivity = 8;
gradientNeighborhood = ones(3);
boundaryElement = strel('square', 3);
expectedThresholds = [66 64] / 255;         % EXP-010, solo controllo
expectedRawVoxels = [2771291 2727314];      % EXP-010, solo controllo

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
nSlices = cfg.dataset.volumeSize(3);
% Slice deterministiche + slice di transizione dichiarate prima di EXP-014 (solo diagnostica)
diagnosticSlices = sort([round(linspace(1, nSlices, 5)), 40, 43, 44, 139, 143]);

volumes = cell(1, 2);
rawMasks = cell(1, 2);
candidates = cell(1, 2);
foregroundMarkers = cell(1, 2);
nonBrainMarkers = cell(1, 2);
parentMasks = cell(1, 2);
ridgeMasks = cell(1, 2);
exp012Candidates = cell(1, 2);
exp013Candidates = cell(1, 2);
diags = cell(1, 2);
postFillNonBrain = zeros(1, 2);
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
    if any(~[checks{:, 2}])
        error('exp014:inputNotReproduced', 'EXP-010 raw T1 masks not reproduced: EXP-014 TECHNICALLY BLOCKED.');
    end

    [candidate, foregroundMarker, nonBrainMarker, parentMask, ridgeMask, d] = ...
        watershedFromTopologyMarkersSlices(volume, rawMask, connectivity, gradientNeighborhood, boundaryElement);

    % Riferimenti salvati (non modificati)
    exp012 = load(fullfile(cfg.paths.processedData, sprintf('exp012_t1_%s_nested_support_mask_candidate.mat', noise)), ...
        'candidate', 'selectedMask');
    exp013 = load(fullfile(cfg.paths.processedData, sprintf('exp013_t1_%s_siblings_support_mask_candidate.mat', noise)), ...
        'candidate', 'parentMask');

    % Marker non-cervello ricalcolato in modo indipendente
    expectedNonBrain = false(size(rawMask));
    filledParents = false(size(rawMask));
    for k = find(d.hasAnchor).'
        filledParent = imfill(parentMask(:, :, k), 'holes');     % 2D, slice per slice
        filledParents(:, :, k) = filledParent;
        expectedNonBrain(:, :, k) = ~filledParent | (parentMask(:, :, k) & filledParent ...
            & ~imerode(filledParent, strel('square', 3)));
    end

    % Watershed ricalcolato in modo indipendente sulle slice diagnostiche
    recomputedEqual = true;
    for k = diagnosticSlices
        if ~d.hasAnchor(k)
            recomputedEqual = recomputedEqual && ~any(candidate(:, :, k), 'all');
            continue
        end
        I = volume(:, :, k);
        g = imdilate(I, ones(3)) - imerode(I, ones(3));
        L = watershed(imimposemin(g, foregroundMarker(:, :, k) | nonBrainMarker(:, :, k)));
        touched = unique(L(foregroundMarker(:, :, k)));
        touched = touched(touched > 0);
        basin = ismember(L, touched) & imfill(parentMask(:, :, k), 'holes') & ~nonBrainMarker(:, :, k);
        recomputedEqual = recomputedEqual && isequal(imfill(basin, 'holes'), candidate(:, :, k)) ...
            && isequal(L == 0, ridgeMask(:, :, k));
    end

    postFillNonBrain(n) = nnz(candidate & nonBrainMarker);

    checks(end+1, :) = {noise + " 8-connectivity, 3x3 gradient, 3x3 band", connectivity == 8 ...
        && isequal(gradientNeighborhood, ones(3)) && isequal(boundaryElement.Neighborhood, true(3))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " anchor = EXP-012 selected component", isequal(foregroundMarker, exp012.selectedMask)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " immediate parent = EXP-013 parent", isequal(parentMask, exp013.parentMask)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " non-brain = outside + outer 3x3 band", isequal(nonBrainMarker, expectedNonBrain)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " marker overlap zero", ~any(d.markerOverlap)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " watershed recomputed on diag. slices", recomputedEqual}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate inside filled parent", ~any(candidate & ~filledParents, 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " no fallback (empty if no anchor)", ~any(candidate(:, :, ~d.hasAnchor), 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate logical, same size", islogical(candidate) && isequal(size(candidate), size(volume))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " normalized volume unchanged", isequal(volume, volumeCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw MRI unchanged on reload", isequal(raw, loadBrainwebMri(cfg, maskModality, noise))}; %#ok<SAGROW>

    save(fullfile(cfg.paths.processedData, sprintf('exp014_t1_%s_watershed_support_mask_candidate.mat', noise)), ...
        'candidate', 'foregroundMarker', 'nonBrainMarker', 'parentMask', 'threshold');

    volumes{n} = volume;
    rawMasks{n} = rawMask;
    candidates{n} = candidate;
    foregroundMarkers{n} = foregroundMarker;
    nonBrainMarkers{n} = nonBrainMarker;
    parentMasks{n} = parentMask;
    ridgeMasks{n} = ridgeMask;
    exp012Candidates{n} = exp012.candidate;
    exp013Candidates{n} = exp013.candidate;
    diags{n} = d;
end

if any(~[checks{:, 2}])
    error('exp014:checksFailed', 'EXP-014 technical checks failed.');
end


%% Diagnostica

sliceArea = @(mask) squeeze(sum(mask, [1 2]));
rows = cell(2, 1);
for n = 1:2
    d = diags{n};
    c = candidates{n};
    a = d.hasAnchor;
    area012 = sliceArea(exp012Candidates{n});
    area013 = sliceArea(exp013Candidates{n});
    nonEmpty = find(squeeze(any(c, [1 2])));
    rows{n} = {maskModality, noiseLevels(n), nnz(a), nnz(~a), nnz(d.parentTie), sum(d.markerOverlap > 0), ...
        median(d.labelsUnderAnchor(a)), max(d.labelsUnderAnchor(a)), nnz(d.labelsUnderAnchor > 1), ...
        sum(d.addedByFilling), postFillNonBrain(n), nnz(c), nnz(c) / numel(c), ...
        nnz(d.finalArea > area012), nnz(d.finalArea < area012), sum(d.finalArea - area012), ...
        sum(area012), sum(area013), numel(nonEmpty), nonEmpty(1), nonEmpty(end)};
end
summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'MaskModality', 'Noise', 'SlicesWithAnchor', 'SlicesWithoutAnchor', 'ParentTies', 'MarkerOverlapSlices', ...
     'MedianLabelsUnderAnchor', 'MaxLabelsUnderAnchor', 'SlicesMultipleLabels', ...
     'AddedByFilling', 'NonBrainPixelsAfterFill', 'CandidateVoxels', 'CandidateFraction', ...
     'SlicesExpandedVsExp012', 'SlicesShrunkVsExp012', 'NetGainVsExp012', ...
     'Exp012Voxels', 'Exp013Voxels', 'NonEmptySlices', 'FirstNonEmpty', 'LastNonEmpty'});
disp(summary);

has0 = diags{1}.hasAnchor;
has3 = diags{2}.hasAnchor;
expanded0 = diags{1}.finalArea > sliceArea(exp012Candidates{1});
expanded3 = diags{2}.finalArea > sliceArea(exp012Candidates{2});
intersectionOverUnion = nnz(candidates{1} & candidates{2}) / nnz(candidates{1} | candidates{2});
fprintf(['EXP-014 consistency (pn0 vs pn3): IoU = %.4f, differing voxels = %.4f %%\n' ...
         'Slices with candidate: both %d, only pn0 %d, only pn3 %d, neither %d\n'], ...
    intersectionOverUnion, 100 * nnz(xor(candidates{1}, candidates{2})) / numel(candidates{1}), ...
    nnz(has0 & has3), nnz(has0 & ~has3), nnz(~has0 & has3), nnz(~has0 & ~has3));
fprintf('Expanded vs EXP-012: both %d slices, only pn0 %d (%s), only pn3 %d (%s)\n\n', ...
    nnz(expanded0 & expanded3), nnz(expanded0 & ~expanded3), slicesAsRanges(find(expanded0 & ~expanded3)), ...
    nnz(~expanded0 & expanded3), slicesAsRanges(find(~expanded0 & expanded3)));

for n = 1:2
    d = diags{n};
    ks = diagnosticSlices(:);
    area012 = sliceArea(exp012Candidates{n});
    area013 = sliceArea(exp013Candidates{n});
    disp(table(ks, d.anchorArea(ks), d.parentArea(ks), d.filledParentArea(ks), d.boundaryBandArea(ks), ...
        d.labelsUnderAnchor(ks), d.basinRawArea(ks), d.constrainedArea(ks), d.addedByFilling(ks), ...
        area012(ks), area013(ks), d.finalArea(ks), ...
        'VariableNames', {char("k_" + noiseLevels(n)), 'anchor', 'parent', 'filledParent', 'band', ...
        'labels', 'basinRaw', 'constrained', 'fillAdded', 'exp012', 'exp013', 'exp014'}));
end

writetable(summary, fullfile(cfg.paths.metrics, 'exp014_t1_watershed_summary.csv'));
perSliceColumns = {};
perSliceNames = {'k'};
for n = 1:2
    d = diags{n};
    area012 = sliceArea(exp012Candidates{n});
    area013 = sliceArea(exp013Candidates{n});
    ratio012 = d.finalArea ./ area012;
    ratioParent = d.finalArea ./ d.filledParentArea;
    perSliceColumns = [perSliceColumns, {d.hasAnchor, d.anchorArea, d.parentArea, d.filledParentArea, ...
        d.boundaryBandArea, d.markerOverlap, d.labelsUnderAnchor, d.basinRawArea, d.constrainedArea, ...
        d.addedByFilling, d.finalArea, area012, area013, d.finalArea - area012, d.finalArea - area013, ...
        ratio012, ratioParent}]; %#ok<AGROW>
    perSliceNames = [perSliceNames, cellstr(noiseLevels(n) + "_" + ["hasAnchor", "anchorArea", "parentArea", ...
        "filledParentArea", "boundaryBandArea", "markerOverlap", "labelsUnderAnchor", "basinRawArea", ...
        "constrainedArea", "addedByFilling", "exp014Area", "exp012Area", "exp013Area", ...
        "gainVsExp012", "diffVsExp013", "ratioExp014Exp012", "ratioExp014FilledParent"])]; %#ok<AGROW>
end
perSlice = table((1:nSlices)', perSliceColumns{:}, 'VariableNames', perSliceNames);
writetable(perSlice, fullfile(cfg.paths.metrics, 'exp014_t1_watershed_per_slice.csv'));


%% Figure (solo maschere e MRI affiancate, nessuna sovrapposizione di contorni)

% 1. Aree per slice: EXP-012 / EXP-013 / EXP-014
fig1 = figure('Color', 'w');
layout = tiledlayout(fig1, 2, 1, 'TileSpacing', 'compact');
title(layout, 'EXP-014 - per-slice candidate areas: EXP-012 vs EXP-013 vs EXP-014 (0 = no anchor)', ...
    'Interpreter', 'none');
for n = 1:2
    ax = nexttile(layout);
    plot(ax, 1:nSlices, sliceArea(exp012Candidates{n}), 'b-', 1:nSlices, sliceArea(exp013Candidates{n}), 'g-', ...
        1:nSlices, diags{n}.finalArea, 'r--');
    legend(ax, 'EXP-012', 'EXP-013', 'EXP-014', 'Location', 'north');
    ylabel(ax, 'pixels');
    title(ax, sprintf('T1 %s', noiseLevels(n)));
    xlim(ax, [1 nSlices]);
end
xlabel(ax, 'axial slice k');
fig1.Position(3:4) = [950 650];
exportgraphics(fig1, fullfile(cfg.paths.figures, 'exp014_t1_area_per_slice.png'));

% 2. Passi per le slice diagnostiche
for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 9, numel(diagnosticSlices), 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf(['EXP-014 T1 %s - T1 / raw / anchor (fg marker) / immediate parent / non-brain marker / ' ...
        '3x3 gradient / watershed ridges / EXP-012 / EXP-014'], noiseLevels(n)), 'Interpreter', 'none');
    rowNames = ["T1", "raw", "anchor", "parent", "non-brain", "gradient", "ridges", "EXP-012", "EXP-014"];
    for r = 1:9
        for s = 1:numel(diagnosticSlices)
            k = diagnosticSlices(s);
            I = volumes{n}(:, :, k);
            limits = [0 1];
            switch r
                case 1, panel = I;
                case 2, panel = rawMasks{n}(:, :, k);
                case 3, panel = foregroundMarkers{n}(:, :, k);
                case 4, panel = parentMasks{n}(:, :, k);
                case 5, panel = nonBrainMarkers{n}(:, :, k);
                case 6
                    panel = imdilate(I, gradientNeighborhood) - imerode(I, gradientNeighborhood);
                    limits = [0 max(max(panel(:)), eps)];
                case 7, panel = ridgeMasks{n}(:, :, k);
                case 8, panel = exp012Candidates{n}(:, :, k);
                case 9, panel = candidates{n}(:, :, k);
            end
            ax = nexttile(layout);
            imagesc(ax, double(panel).');
            colormap(ax, gray);
            clim(ax, limits);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('%s k=%d', rowNames(r), k), 'FontSize', 7);
        end
    end
    fig.Position(3:4) = [1700 1550];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp014_t1_%s_watershed_steps.png', noiseLevels(n))));
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
fprintf('\nEXP-014 CHECKS: PASS\n');


function text = slicesAsRanges(slices)
%SLICESASRANGES Elenco di slice come intervalli compatti, es. "1-15, 37".
    if isempty(slices)
        text = 'none';
        return
    end
    slices = slices(:).';
    breaks = [0, find(diff(slices) > 1), numel(slices)];
    parts = strings(1, numel(breaks) - 1);
    for b = 1:numel(breaks) - 1
        first = slices(breaks(b) + 1);
        last = slices(breaks(b + 1));
        if first == last
            parts(b) = sprintf('%d', first);
        else
            parts(b) = sprintf('%d-%d', first, last);
        end
    end
    text = char(strjoin(parts, ', '));
end
