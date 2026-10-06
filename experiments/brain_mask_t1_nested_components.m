%% T1: selezione topologica della componente annidata (fase 50, EXP-012)
% EXP-011 ha mostrato che in T1 cervello e scalpo sono già componenti
% separate nelle slice centrali, ma "componente più grande = cervello"
% sbaglia agli estremi del volume. EXP-012 cambia SOLO la regola di
% selezione:
%   T1 -> double -> /4095 -> nessun filtro -> Otsu globale per volume
%   -> per ogni slice: componenti a 8-connettività
%   -> regione racchiusa da ogni componente (imfill della sola componente)
%   -> componenti COMPLETAMENTE contenute nella regione racchiusa da
%      un'altra componente = annidate
%   -> la più grande tra le annidate -> imfill finale
% Nessuna componente annidata -> slice VUOTA (nessun ripiego su EXP-011).
%
% È una regola automatica di selezione basata sulla topologia, costruita con
% operazioni consentite (componenti connesse, riempimento dei buchi, logica);
% non una nuova tecnica. "Componente racchiudente" e "annidata" sono termini
% topologici, non anatomici. Nessuna altra morfologia, nessuna soglia di
% area, nessuna regola di posizione o di z, nessun 3D, nessun ground truth.
% T1 serve solo per la maschera; T2 resta la modalità delle lesioni.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

maskModality = "T1";
assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'EXP-012 requires no filter.');

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
selectedMasks = cell(1, 2);
enclosedMasks = cell(1, 2);
diags = cell(1, 2);
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
        error('exp012:inputNotReproduced', 'EXP-010 raw T1 masks not reproduced: EXP-012 TECHNICALLY BLOCKED.');
    end

    rawMaskCopy = rawMask;
    [candidate, d, selectedMask, enclosedMask] = selectNestedSupportComponentSlices(rawMask, connectivity);

    % Il candidato deriva solo dalla componente scelta + il suo riempimento
    fromSelectionOnly = true;
    for k = 1:nSlices
        fromSelectionOnly = fromSelectionOnly && ...
            isequal(candidate(:, :, k), imfill(selectedMask(:, :, k), 'holes'));
    end
    emptyWhereNoNested = ~any(candidate(:, :, d.noNestedCandidate), 'all') ...
        && ~any(selectedMask(:, :, d.noNestedCandidate), 'all');

    checks(end+1, :) = {noise + " 8-connectivity used", d.connectivity == 8}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw mask unchanged", isequal(rawMask, rawMaskCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate logical, same size", islogical(candidate) && isequal(size(candidate), size(volume))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " selected component subset of raw", ~any(selectedMask & ~rawMask, 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate = fill(selected) per slice", fromSelectionOnly}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " no fallback (empty if no nested)", emptyWhereNoNested}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " normalized volume unchanged", isequal(volume, volumeCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw MRI unchanged on reload", isequal(raw, loadBrainwebMri(cfg, maskModality, noise))}; %#ok<SAGROW>

    save(fullfile(cfg.paths.processedData, sprintf('exp012_t1_%s_nested_support_mask_candidate.mat', noise)), ...
        'candidate', 'selectedMask', 'threshold');

    volumes{n} = volume;
    rawMasks{n} = rawMask;
    candidates{n} = candidate;
    selectedMasks{n} = selectedMask;
    enclosedMasks{n} = enclosedMask;
    diags{n} = d;
end

if any(~[checks{:, 2}])
    error('exp012:checksFailed', 'EXP-012 technical checks failed.');
end


%% Diagnostica

rows = cell(2, 1);
for n = 1:2
    d = diags{n};
    c = candidates{n};
    hasCandidate = ~d.noNestedCandidate;
    sameAsExp011 = hasCandidate & d.selectedIndex == d.largestIndex;
    nonEmpty = find(squeeze(any(c, [1 2])));
    if isempty(nonEmpty)
        nonEmpty = 0;
    end
    rows{n} = {maskModality, noiseLevels(n), nnz(rawMasks{n}), ...
        nnz(hasCandidate), nnz(~hasCandidate), ...
        median(d.nComponents), median(d.nEnclosing), max(d.nEnclosing), median(d.nNested), max(d.nNested), ...
        nnz(hasCandidate & ~sameAsExp011), nnz(~sameAsExp011), ...
        median(d.selectedArea(hasCandidate)), sum(d.addedByFilling), nnz(c), nnz(c) / numel(c), ...
        nonEmpty(1), nonEmpty(end)};
end
summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'MaskModality', 'Noise', 'RawVoxels', 'SlicesWithCandidate', 'SlicesWithoutCandidate', ...
     'MedianComponents', 'MedianEnclosing', 'MaxEnclosing', 'MedianNested', 'MaxNested', ...
     'SlicesDifferentFromExp011NonEmpty', 'SlicesDifferentFromExp011All', ...
     'MedianSelectedArea', 'AddedByFilling', 'CandidateVoxels', 'CandidateFraction', ...
     'FirstNonEmpty', 'LastNonEmpty'});
disp(summary);

for n = 1:2
    fprintf('%s slices without nested candidate: %s\n', noiseLevels(n), ...
        slicesAsRanges(find(diags{n}.noNestedCandidate)));
    fprintf('%s slices with a different component from EXP-011 (non-empty): %s\n', noiseLevels(n), ...
        slicesAsRanges(find(~diags{n}.noNestedCandidate & diags{n}.selectedIndex ~= diags{n}.largestIndex)));
end

has0 = ~diags{1}.noNestedCandidate;
has3 = ~diags{2}.noNestedCandidate;
intersectionOverUnion = nnz(candidates{1} & candidates{2}) / nnz(candidates{1} | candidates{2});
fprintf(['\nEXP-012 consistency (pn0 vs pn3): IoU = %.4f, differing voxels = %.4f %%\n' ...
         'Slices with candidate: both %d, only pn0 %d, only pn3 %d, neither %d\n'], ...
    intersectionOverUnion, 100 * nnz(xor(candidates{1}, candidates{2})) / numel(candidates{1}), ...
    nnz(has0 & has3), nnz(has0 & ~has3), nnz(~has0 & has3), nnz(~has0 & ~has3));
fprintf('Only pn0: %s\nOnly pn3: %s\n\n', slicesAsRanges(find(has0 & ~has3)), slicesAsRanges(find(~has0 & has3)));

writetable(summary, fullfile(cfg.paths.metrics, 'exp012_t1_nested_summary.csv'));
perSliceColumns = {};
perSliceNames = {'k'};
for n = 1:2
    d = diags{n};
    perSliceColumns = [perSliceColumns, {d.nComponents, d.nEnclosing, d.nNested, d.selectedArea, ...
        d.nParentsOfSelected, d.noNestedCandidate, d.addedByFilling, d.finalArea, d.largestArea, ...
        ~d.noNestedCandidate & d.selectedIndex == d.largestIndex}]; %#ok<AGROW>
    perSliceNames = [perSliceNames, cellstr(noiseLevels(n) + "_" + ["nComponents", "nEnclosing", "nNested", ...
        "selectedArea", "nParentsOfSelected", "noNestedCandidate", "addedByFilling", "finalArea", ...
        "exp011LargestArea", "sameSelectionAsExp011"])]; %#ok<AGROW>
end
perSlice = table((1:nSlices)', perSliceColumns{:}, 'VariableNames', perSliceNames);
writetable(perSlice, fullfile(cfg.paths.metrics, 'exp012_t1_nested_per_slice.csv'));


%% Figure (solo maschere e MRI affiancate, nessuna sovrapposizione di contorni)

% 1. Aree per slice su tutto il volume (0 = nessun candidato annidato)
fig1 = figure('Color', 'w');
layout = tiledlayout(fig1, 2, 1, 'TileSpacing', 'compact');
title(layout, 'EXP-012 - per-slice areas: EXP-011 largest component vs EXP-012 nested selection (0 = no nested candidate)', ...
    'Interpreter', 'none');
for n = 1:2
    ax = nexttile(layout);
    plot(ax, 1:nSlices, diags{n}.largestArea, 'b-', 1:nSlices, diags{n}.selectedArea, 'r-', ...
        1:nSlices, diags{n}.finalArea, 'k--');
    legend(ax, 'EXP-011 selected (largest)', 'EXP-012 nested selected (before filling)', ...
        'EXP-012 final (after filling)', 'Location', 'north');
    ylabel(ax, 'pixels');
    title(ax, sprintf('T1 %s', noiseLevels(n)));
    xlim(ax, [1 nSlices]);
end
xlabel(ax, 'axial slice k');
fig1.Position(3:4) = [950 650];
exportgraphics(fig1, fullfile(cfg.paths.figures, 'exp012_t1_area_per_slice.png'));

% 2. T1 / grezza / EXP-011 / EXP-012 prima del riempimento / EXP-012 finale
for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 5, numel(displaySlices), 'TileSpacing', 'compact');
    title(layout, sprintf('EXP-012 T1 %s - T1 / raw Otsu / EXP-011 largest / EXP-012 nested (before filling) / EXP-012 candidate', ...
        noiseLevels(n)), 'Interpreter', 'none');
    rowNames = ["T1", "raw mask", "EXP-011 largest", "EXP-012 nested", "EXP-012 candidate"];
    for r = 1:5
        for s = 1:numel(displaySlices)
            k = displaySlices(s);
            switch r
                case 1, panel = volumes{n}(:, :, k);
                case 2, panel = rawMasks{n}(:, :, k);
                case 3, panel = largestComponent(rawMasks{n}(:, :, k), connectivity);
                case 4, panel = selectedMasks{n}(:, :, k);
                case 5, panel = candidates{n}(:, :, k);
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
    fig.Position(3:4) = [1300 1350];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp012_t1_%s_nested_steps.png', noiseLevels(n))));
end

% 3. Relazione di racchiudimento: grigio = primo piano grezzo,
%    blu = regioni racchiuse dalle componenti, rosso = componente annidata scelta
fig3 = figure('Color', 'w');
layout = tiledlayout(fig3, 2, numel(displaySlices), 'TileSpacing', 'compact');
title(layout, 'EXP-012 enclosure - gray: raw foreground, blue: regions enclosed by a component, red: selected nested component', ...
    'Interpreter', 'none');
for n = 1:2
    for s = 1:numel(displaySlices)
        k = displaySlices(s);
        foreground = rawMasks{n}(:, :, k).';
        enclosed = enclosedMasks{n}(:, :, k).';
        selected = selectedMasks{n}(:, :, k).';
        red = 0.5 * foreground;
        green = 0.5 * foreground;
        blue = 0.5 * foreground;
        red(enclosed & ~foreground) = 0.2;
        green(enclosed & ~foreground) = 0.4;
        blue(enclosed & ~foreground) = 1;
        red(selected) = 1;
        green(selected) = 0;
        blue(selected) = 0;
        ax = nexttile(layout);
        image(ax, cat(3, red, green, blue));
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('%s  k = %d', noiseLevels(n), k));
    end
end
fig3.Position(3:4) = [1300 600];
exportgraphics(fig3, fullfile(cfg.paths.figures, 'exp012_t1_enclosure_relation.png'));


%% Esito dei controlli

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-42s %s\n', checks{c, 1}, result);
end
fprintf('\nEXP-012 CHECKS: PASS\n');


function selected = largestComponent(slice, connectivity)
%LARGESTCOMPONENT Componente più grande di una slice (solo per le figure, come EXP-011).
    selected = false(size(slice));
    components = bwconncomp(slice, connectivity);
    if components.NumObjects > 0
        [~, index] = max(cellfun(@numel, components.PixelIdxList));
        selected(components.PixelIdxList{index}) = true;
    end
end

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
