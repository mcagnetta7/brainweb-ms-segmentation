%% T1: fattibilità di un marker di sfondo interno scheletrizzato (fase 50, EXP-015)
% EXP-014 ha mostrato che il marker del primo piano (ancora EXP-012) era
% affidabile, ma mancava un marker di sfondo nella banda scura interna tra
% cervello e periferia, e il bacino si espandeva in tutta la cavità.
% EXP-015 verifica SOLO se si può costruire automaticamente un marker di
% sfondo interno, come nel flusso del watershed a marker del corso (pixel
% scuri = sfondo, assottigliati con lo scheletro):
%   T1 -> double -> /4095 -> nessun filtro -> Otsu globale (EXP-010)
%   -> ancora EXP-012, genitore immediato P (EXP-013/014)
%   -> internalDark = imfill(P) AND NOT rawMask AND NOT imfill(ancora)
%   -> bwmorph(internalDark, 'skel', Inf), senza potatura né selezione
% NESSUN watershed, nessun imimposemin, nessuna seconda soglia. L'uscita è
% un candidato marker di sfondo, NON una maschera cerebrale.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

maskModality = "T1";
assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'EXP-015 requires no filter.');

connectivity = 8;
expectedThresholds = [66 64] / 255;         % EXP-010, solo controllo
expectedRawVoxels = [2771291 2727314];      % EXP-010, solo controllo

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
nSlices = cfg.dataset.volumeSize(3);
% Slice diagnostiche dichiarate prima di EXP-015 (solo diagnostica)
diagnosticSlices = sort([round(linspace(1, nSlices, 5)), 40, 43, 44, 139, 143]);

volumes = cell(1, 2);
rawMasks = cell(1, 2);
darks = cell(1, 2);
markers = cell(1, 2);
anchors = cell(1, 2);
parents = cell(1, 2);
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
        error('exp015:inputNotReproduced', 'EXP-010 raw T1 masks not reproduced: EXP-015 TECHNICALLY BLOCKED.');
    end

    rawMaskCopy = rawMask;
    [internalDark, marker, anchorMask, parentMask, d] = internalDarkSkeletonMarkersSlices(rawMask, connectivity);

    % Riferimenti salvati (non modificati)
    exp012 = load(fullfile(cfg.paths.processedData, sprintf('exp012_t1_%s_nested_support_mask_candidate.mat', noise)), ...
        'selectedMask');
    exp013 = load(fullfile(cfg.paths.processedData, sprintf('exp013_t1_%s_siblings_support_mask_candidate.mat', noise)), ...
        'parentMask');
    if ~isequal(anchorMask, exp012.selectedMask)
        error('exp015:anchorNotReproduced', 'EXP-012 anchor not reproduced: EXP-015 STOPPED.');
    end

    % Regione scura e scheletro ricalcolati in modo indipendente
    darkRecomputed = true;
    skeletonRecomputed = true;
    for k = 1:nSlices
        expectedDark = imfill(parentMask(:, :, k), 'holes') & ~rawMask(:, :, k) ...
            & ~imfill(anchorMask(:, :, k), 'holes');
        darkRecomputed = darkRecomputed && isequal(internalDark(:, :, k), expectedDark);
        skeletonRecomputed = skeletonRecomputed && isequal(marker(:, :, k), bwmorph(expectedDark, 'skel', Inf));
    end

    checks(end+1, :) = {noise + " 8-connectivity for foreground", d.connectivity == 8}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw mask unchanged", isequal(rawMask, rawMaskCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " anchor = EXP-012 selected component", isequal(anchorMask, exp012.selectedMask)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " immediate parent = EXP-013 parent", isequal(parentMask, exp013.parentMask)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " internalDark = filledP & ~raw & ~filledA", darkRecomputed}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " marker = bwmorph(dark,'skel',Inf)", skeletonRecomputed}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " marker subset of internalDark", ~any(marker & ~internalDark, 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " marker/anchor overlap zero", ~any(marker & anchorMask, 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " marker/parent overlap zero", ~any(marker & parentMask, 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " empty marker where no anchor", ~any(marker(:, :, ~d.hasAnchor), 'all') ...
        && ~any(internalDark(:, :, ~d.hasAnchor), 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " marker logical, same size", islogical(marker) && isequal(size(marker), size(volume))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " normalized volume unchanged", isequal(volume, volumeCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw MRI unchanged on reload", isequal(raw, loadBrainwebMri(cfg, maskModality, noise))}; %#ok<SAGROW>

    internalBackgroundMarker = marker;
    save(fullfile(cfg.paths.processedData, sprintf('exp015_t1_%s_dark_background_marker.mat', noise)), ...
        'internalDark', 'internalBackgroundMarker', 'anchorMask', 'parentMask', 'threshold');

    volumes{n} = volume;
    rawMasks{n} = rawMask;
    darks{n} = internalDark;
    markers{n} = marker;
    anchors{n} = anchorMask;
    parents{n} = parentMask;
    diags{n} = d;
end

if any(~[checks{:, 2}])
    error('exp015:checksFailed', 'EXP-015 technical checks failed.');
end


%% Diagnostica

rows = cell(2, 1);
for n = 1:2
    d = diags{n};
    a = d.hasAnchor;
    rows{n} = {maskModality, noiseLevels(n), nnz(a), nnz(~a), sum(d.internalDarkArea), sum(d.skeletonArea), ...
        median(d.skeletonArea(a)), max(d.skeletonArea(a)), ...
        median(d.nSkeletonComponents(a)), max(d.nSkeletonComponents(a)), ...
        nnz(a & d.skeletonEmpty), nnz(d.anchorOverlap), nnz(d.parentOverlap), nnz(a & d.barrier), ...
        sum(d.siblingArea), sum(d.siblingAreaSeparated), nnz(a & d.siblingAreaSeparated > 0)};
end
summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'MaskModality', 'Noise', 'SlicesWithAnchor', 'SlicesWithoutAnchor', 'InternalDarkPixels', 'SkeletonPixels', ...
     'MedianSkeletonPerSlice', 'MaxSkeletonPerSlice', 'MedianSkeletonComponents', 'MaxSkeletonComponents', ...
     'AnchorSlicesEmptySkeleton', 'AnchorOverlapSlices', 'ParentOverlapSlices', 'BarrierSlices', ...
     'SiblingArea', 'SiblingAreaSeparatedBySkeleton', 'SlicesWithSiblingSeparated'});
disp(summary);

m0 = squeeze(any(markers{1}, [1 2]));
m3 = squeeze(any(markers{2}, [1 2]));
b0 = diags{1}.barrier;
b3 = diags{2}.barrier;
bothAnchor = diags{1}.hasAnchor & diags{2}.hasAnchor;
intersectionOverUnion = nnz(markers{1} & markers{2}) / nnz(markers{1} | markers{2});
fprintf(['EXP-015 marker consistency (pn0 vs pn3): IoU = %.4f, differing voxels = %.4f %%\n' ...
         'Slices with marker: both %d, only pn0 %d, only pn3 %d, neither %d\n' ...
         'Barrier (slices with anchor in both): both %d, neither %d, disagree %d (%s)\n' ...
         'Barrier slices pn0: %s\nBarrier slices pn3: %s\n\n'], ...
    intersectionOverUnion, 100 * nnz(xor(markers{1}, markers{2})) / numel(markers{1}), ...
    nnz(m0 & m3), nnz(m0 & ~m3), nnz(~m0 & m3), nnz(~m0 & ~m3), ...
    nnz(bothAnchor & b0 & b3), nnz(bothAnchor & ~b0 & ~b3), nnz(bothAnchor & xor(b0, b3)), ...
    slicesAsRanges(find(bothAnchor & xor(b0, b3))), slicesAsRanges(find(b0)), slicesAsRanges(find(b3)));

for n = 1:2
    d = diags{n};
    ks = diagnosticSlices(:);
    disp(table(ks, d.anchorArea(ks), d.filledParentArea(ks), d.internalDarkArea(ks), d.skeletonArea(ks), ...
        d.nSkeletonComponents(ks), d.largestSkeletonComponent(ks), d.barrier(ks), d.siblingArea(ks), ...
        d.siblingAreaSeparated(ks), ...
        'VariableNames', {char("k_" + noiseLevels(n)), 'anchor', 'filledParent', 'internalDark', 'skeleton', ...
        'skelComps', 'largestComp', 'barrier', 'siblingArea', 'siblingSeparated'}));
end

writetable(summary, fullfile(cfg.paths.metrics, 'exp015_t1_dark_background_marker_summary.csv'));
perSliceColumns = {};
perSliceNames = {'k'};
fields = ["hasAnchor", "anchorArea", "parentArea", "filledParentArea", "filledAnchorArea", "internalDarkArea", ...
    "skeletonArea", "nSkeletonComponents", "largestSkeletonComponent", "skeletonEmpty", "anchorOverlap", ...
    "parentOverlap", "barrier", "siblingArea", "siblingAreaSeparated"];
for n = 1:2
    for f = fields
        perSliceColumns{end+1} = diags{n}.(f); %#ok<SAGROW>
    end
    perSliceNames = [perSliceNames, cellstr(noiseLevels(n) + "_" + fields)]; %#ok<AGROW>
end
perSlice = table((1:nSlices)', perSliceColumns{:}, 'VariableNames', perSliceNames);
writetable(perSlice, fullfile(cfg.paths.metrics, 'exp015_t1_dark_background_marker_per_slice.csv'));


%% Figure (diagnostica dei marker, NON validazione del contorno della fase 51)

% 1. Curve per slice
fig1 = figure('Color', 'w');
layout = tiledlayout(fig1, 4, 1, 'TileSpacing', 'compact');
title(layout, 'EXP-015 - per-slice marker diagnostics (pn0 blue, pn3 red dashed; 0 = no anchor)', ...
    'Interpreter', 'none');
plotFields = ["internalDarkArea", "skeletonArea", "nSkeletonComponents", "barrier"];
plotLabels = ["internalDark px", "skeleton px", "skeleton comps", "barrier (1 = yes)"];
for p = 1:4
    ax = nexttile(layout);
    plot(ax, 1:nSlices, double(diags{1}.(plotFields(p))), 'b-', 1:nSlices, double(diags{2}.(plotFields(p))), 'r--');
    ylabel(ax, plotLabels(p));
    xlim(ax, [1 nSlices]);
end
legend(ax, 'pn0', 'pn3', 'Location', 'northeast');
xlabel(ax, 'axial slice k');
fig1.Position(3:4) = [950 900];
exportgraphics(fig1, fullfile(cfg.paths.figures, 'exp015_t1_marker_per_slice.png'));

% 2. Passi per le slice diagnostiche
for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 7, numel(diagnosticSlices), 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf(['EXP-015 T1 %s - T1 / raw Otsu / EXP-012 anchor / immediate parent / filled parent / ' ...
        'internalDark / skeleton marker'], noiseLevels(n)), 'Interpreter', 'none');
    rowNames = ["T1", "raw", "anchor", "parent", "filledParent", "internalDark", "skeleton"];
    for r = 1:7
        for s = 1:numel(diagnosticSlices)
            k = diagnosticSlices(s);
            switch r
                case 1, panel = volumes{n}(:, :, k);
                case 2, panel = rawMasks{n}(:, :, k);
                case 3, panel = anchors{n}(:, :, k);
                case 4, panel = parents{n}(:, :, k);
                case 5, panel = imfill(parents{n}(:, :, k), 'holes');
                case 6, panel = darks{n}(:, :, k);
                case 7, panel = markers{n}(:, :, k);
            end
            ax = nexttile(layout);
            imagesc(ax, double(panel).');
            colormap(ax, gray);
            clim(ax, [0 1]);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('%s k=%d', rowNames(r), k), 'FontSize', 7);
        end
    end
    fig.Position(3:4) = [1700 1250];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp015_t1_%s_marker_steps.png', noiseLevels(n))));
end

% 3. Marker sovrapposto alla T1 (rosso = scheletro, blu = internalDark, verde = ancora)
fig3 = figure('Color', 'w');
layout = tiledlayout(fig3, 2, numel(diagnosticSlices), 'TileSpacing', 'tight', 'Padding', 'tight');
title(layout, ['EXP-015 marker diagnostic visualization (NOT Phase-51 brain-mask boundary validation) - ' ...
    'red: skeleton marker, blue tint: internalDark, green tint: EXP-012 anchor'], 'Interpreter', 'none');
for n = 1:2
    for s = 1:numel(diagnosticSlices)
        k = diagnosticSlices(s);
        I = volumes{n}(:, :, k).';
        dark = darks{n}(:, :, k).';
        anchor = anchors{n}(:, :, k).';
        skeleton = markers{n}(:, :, k).';
        red = I;
        green = I;
        blue = I;
        blue(dark) = 0.5 + 0.5 * blue(dark);
        green(anchor) = 0.5 + 0.5 * green(anchor);
        red(skeleton) = 1;
        green(skeleton) = 0;
        blue(skeleton) = 0;
        ax = nexttile(layout);
        image(ax, cat(3, red, green, blue));
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('%s k=%d', noiseLevels(n), k), 'FontSize', 8);
    end
end
fig3.Position(3:4) = [1900 520];
exportgraphics(fig3, fullfile(cfg.paths.figures, 'exp015_t1_marker_on_t1.png'), 'Resolution', 200);


%% Esito dei controlli

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-48s %s\n', checks{c, 1}, result);
end
fprintf('\nEXP-015 CHECKS: PASS\n');


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
