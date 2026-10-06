%% T1: fattibilità del bordo esterno del cervello con Canny (fase 50, EXP-016)
% EXP-011..015 hanno mostrato che soglia, topologia e marker scuri non
% bastano a identificare il confine cervello/periferia. EXP-016 verifica
% SOLO se Canny automatico 2D sulla T1 normalizzata contiene un confine
% esterno utile:
%   T1 -> double -> /4095 -> nessun filtro -> edge(I, 'Canny') per slice
% Una sola configurazione (soglie automatiche di MATLAB), nessuno sweep,
% nessun'altra tecnica di bordo. La mappa resta grezza. Ancora EXP-012 e
% genitore immediato servono SOLO per la diagnostica (dominio locale e test
% di barriera), mai per generare i bordi. Nessuna maschera cerebrale,
% nessun watershed, nessuna informazione da altre slice, nessun GT.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

maskModality = "T1";
assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'EXP-016 requires no filter.');

connectivity = 8;                   % componenti di primo piano (EXP-012)
barrierConnectivity = 4;            % complemento di linee a 8-connettività (come EXP-015)
expectedThresholds = [66 64] / 255;         % EXP-010, solo controllo
expectedRawVoxels = [2771291 2727314];      % EXP-010, solo controllo

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
nSlices = cfg.dataset.volumeSize(3);
% Slice diagnostiche dichiarate prima di EXP-016 (solo diagnostica)
diagnosticSlices = sort([round(linspace(1, nSlices, 5)), 40, 43, 44, 139, 143]);

volumes = cell(1, 2);
edgeVolumes = cell(1, 2);
anchors = cell(1, 2);
parents = cell(1, 2);
filledParents = cell(1, 2);
anchorRegions = cell(1, 2);
parentRegions = cell(1, 2);
cannyThresholds = cell(1, 2);
stats = cell(1, 2);
checks = cell(0, 2);

for n = 1:2
    noise = noiseLevels(n);
    raw = loadBrainwebMri(cfg, maskModality, noise);
    volume = prepare(raw);
    volumeCopy = volume;

    checks(end+1, :) = {noise + " normalized input double in [0,1]", isa(volume, 'double') ...
        && min(volume(:)) >= 0 && max(volume(:)) <= 1}; %#ok<SAGROW>

    % Bordi: solo dalla T1 normalizzata
    [edges, thresholds] = detectT1CannyEdgesSlices(volume);

    % Topologia solo per la diagnostica (EXP-010 -> EXP-012/013, funzione EXP-015)
    [rawMask, threshold] = initialSupportMask(volume);
    checks(end+1, :) = {noise + " EXP-010 threshold reproduced", abs(threshold - expectedThresholds(n)) < 1e-9}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " EXP-010 raw foreground reproduced", nnz(rawMask) == expectedRawVoxels(n)}; %#ok<SAGROW>
    if any(~[checks{:, 2}])
        error('exp016:inputNotReproduced', 'EXP-010 raw T1 masks not reproduced: EXP-016 TECHNICALLY BLOCKED.');
    end
    [~, ~, anchorMask, parentMask, topology] = internalDarkSkeletonMarkersSlices(rawMask, connectivity);
    exp012 = load(fullfile(cfg.paths.processedData, sprintf('exp012_t1_%s_nested_support_mask_candidate.mat', noise)), ...
        'selectedMask');
    exp013 = load(fullfile(cfg.paths.processedData, sprintf('exp013_t1_%s_siblings_support_mask_candidate.mat', noise)), ...
        'parentMask');

    % Diagnostica per slice
    s = struct();
    names = ["edgePixels", "nEdgeComponents", "largestEdgeComponent", "medianEdgeComponent", ...
        "edgesInsideFilledParent", "edgesOutsideFilledParent", "edgesOnAnchor", "edgesOnParent", ...
        "edgesOtherInsideParent"];
    for f = names
        s.(f) = zeros(nSlices, 1);
    end
    s.hasAnchor = topology.hasAnchor;
    s.barrier = false(nSlices, 1);
    filledParent = false(size(volume));
    anchorRegion = false(size(volume));
    parentRegion = false(size(volume));
    edgesRecomputed = true;
    for k = 1:nSlices
        e = edges(:, :, k);
        components = bwconncomp(e, 8);
        sizes = cellfun(@numel, components.PixelIdxList);
        s.edgePixels(k) = nnz(e);
        s.nEdgeComponents(k) = components.NumObjects;
        if ~isempty(sizes)
            s.largestEdgeComponent(k) = max(sizes);
            s.medianEdgeComponent(k) = median(sizes);
        end
        if ismember(k, diagnosticSlices)
            edgesRecomputed = edgesRecomputed && isequal(e, edge(volume(:, :, k), 'Canny'));
        end
        if ~s.hasAnchor(k)
            s.edgesOutsideFilledParent(k) = nnz(e);
            continue
        end
        a = anchorMask(:, :, k);
        p = parentMask(:, :, k);
        fp = imfill(p, 'holes');
        filledParent(:, :, k) = fp;
        s.edgesInsideFilledParent(k) = nnz(e & fp);
        s.edgesOutsideFilledParent(k) = nnz(e & ~fp);
        s.edgesOnAnchor(k) = nnz(e & a);
        s.edgesOnParent(k) = nnz(e & p);
        s.edgesOtherInsideParent(k) = nnz(e & fp & ~a & ~p);

        % Test di barriera: regioni 4-connesse di filledParent AND NOT bordi
        domain = bwconncomp(fp & ~e, barrierConnectivity);
        labels = labelmatrix(domain);
        anchorLabels = unique(labels(a & labels > 0));
        parentLabels = unique(labels(p & labels > 0));
        s.barrier(k) = isempty(intersect(anchorLabels, parentLabels));
        anchorRegion(:, :, k) = ismember(labels, anchorLabels) & labels > 0;
        parentRegion(:, :, k) = ismember(labels, parentLabels) & labels > 0;
    end

    checks(end+1, :) = {noise + " anchor = EXP-012 selected component", isequal(anchorMask, exp012.selectedMask)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " immediate parent = EXP-013 parent", isequal(parentMask, exp013.parentMask)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " edges logical, same size", islogical(edges) && isequal(size(edges), size(volume))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " edges = edge(T1 slice,'Canny') (diag.)", edgesRecomputed}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " normalized volume unchanged", isequal(volume, volumeCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw MRI unchanged on reload", isequal(raw, loadBrainwebMri(cfg, maskModality, noise))}; %#ok<SAGROW>

    cannyEdges = edges;
    save(fullfile(cfg.paths.processedData, sprintf('exp016_t1_%s_canny_edges.mat', noise)), ...
        'cannyEdges', 'thresholds');

    volumes{n} = volume;
    edgeVolumes{n} = edges;
    anchors{n} = anchorMask;
    parents{n} = parentMask;
    filledParents{n} = filledParent;
    anchorRegions{n} = anchorRegion;
    parentRegions{n} = parentRegion;
    cannyThresholds{n} = thresholds;
    stats{n} = s;
end

if any(~[checks{:, 2}])
    error('exp016:checksFailed', 'EXP-016 technical checks failed.');
end


%% Diagnostica

rows = cell(2, 1);
for n = 1:2
    s = stats{n};
    a = s.hasAnchor;
    t = cannyThresholds{n};
    rows{n} = {maskModality, noiseLevels(n), sum(s.edgePixels), median(s.edgePixels), max(s.edgePixels), ...
        median(s.nEdgeComponents), max(s.nEdgeComponents), median(s.largestEdgeComponent), max(s.largestEdgeComponent), ...
        median(t(:, 1), 'omitnan'), min(t(:, 1)), max(t(:, 1)), median(t(:, 2), 'omitnan'), min(t(:, 2)), max(t(:, 2)), ...
        nnz(a), nnz(a & s.barrier), sum(s.edgesInsideFilledParent), sum(s.edgesOnAnchor), sum(s.edgesOnParent), ...
        sum(s.edgesOtherInsideParent)};
end
summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'MaskModality', 'Noise', 'EdgePixels', 'MedianEdgePixelsPerSlice', 'MaxEdgePixelsPerSlice', ...
     'MedianEdgeComponents', 'MaxEdgeComponents', 'MedianLargestComponent', 'MaxLargestComponent', ...
     'MedianLowThreshold', 'MinLowThreshold', 'MaxLowThreshold', ...
     'MedianHighThreshold', 'MinHighThreshold', 'MaxHighThreshold', ...
     'SlicesWithAnchor', 'BarrierSlices', 'EdgesInsideFilledParent', 'EdgesOnAnchor', 'EdgesOnParent', ...
     'EdgesOtherInsideFilledParent'});
disp(summary);

b0 = stats{1}.barrier;
b3 = stats{2}.barrier;
bothAnchor = stats{1}.hasAnchor & stats{2}.hasAnchor;
intersectionOverUnion = nnz(edgeVolumes{1} & edgeVolumes{2}) / nnz(edgeVolumes{1} | edgeVolumes{2});
fprintf(['EXP-016 edge consistency (pn0 vs pn3): IoU = %.4f, differing voxels = %.4f %%\n' ...
         'Barrier (slices with anchor in both): both %d, only pn0 %d, only pn3 %d, neither %d\n' ...
         'Barrier slices pn0: %s\nBarrier slices pn3: %s\n\n'], ...
    intersectionOverUnion, 100 * nnz(xor(edgeVolumes{1}, edgeVolumes{2})) / numel(edgeVolumes{1}), ...
    nnz(bothAnchor & b0 & b3), nnz(bothAnchor & b0 & ~b3), nnz(bothAnchor & ~b0 & b3), ...
    nnz(bothAnchor & ~b0 & ~b3), slicesAsRanges(find(b0)), slicesAsRanges(find(b3)));

for n = 1:2
    s = stats{n};
    t = cannyThresholds{n};
    ks = diagnosticSlices(:);
    disp(table(ks, s.edgePixels(ks), s.nEdgeComponents(ks), s.largestEdgeComponent(ks), ...
        s.edgesInsideFilledParent(ks), s.edgesOnAnchor(ks), s.edgesOnParent(ks), s.edgesOtherInsideParent(ks), ...
        s.barrier(ks), t(ks, 1), t(ks, 2), ...
        'VariableNames', {char("k_" + noiseLevels(n)), 'edgePx', 'comps', 'largest', 'inFilledParent', ...
        'onAnchor', 'onParent', 'otherInside', 'barrier', 'lowT', 'highT'}));
end

writetable(summary, fullfile(cfg.paths.metrics, 'exp016_t1_canny_summary.csv'));
perSliceColumns = {};
perSliceNames = {'k'};
fields = ["hasAnchor", "edgePixels", "nEdgeComponents", "largestEdgeComponent", "medianEdgeComponent", ...
    "edgesInsideFilledParent", "edgesOutsideFilledParent", "edgesOnAnchor", "edgesOnParent", ...
    "edgesOtherInsideParent", "barrier"];
for n = 1:2
    for f = fields
        perSliceColumns{end+1} = stats{n}.(f); %#ok<SAGROW>
    end
    perSliceColumns{end+1} = cannyThresholds{n}(:, 1); %#ok<SAGROW>
    perSliceColumns{end+1} = cannyThresholds{n}(:, 2); %#ok<SAGROW>
    perSliceNames = [perSliceNames, cellstr(noiseLevels(n) + "_" + [fields, "lowThreshold", "highThreshold"])]; %#ok<AGROW>
end
perSlice = table((1:nSlices)', perSliceColumns{:}, 'VariableNames', perSliceNames);
writetable(perSlice, fullfile(cfg.paths.metrics, 'exp016_t1_canny_per_slice.csv'));


%% Figure (diagnostica dei bordi, NON validazione del contorno della fase 51)

% 1. Curve per slice
fig1 = figure('Color', 'w');
layout = tiledlayout(fig1, 5, 1, 'TileSpacing', 'compact');
title(layout, 'EXP-016 - per-slice Canny diagnostics (pn0 blue, pn3 red dashed)', 'Interpreter', 'none');
plotFields = ["edgePixels", "nEdgeComponents", "largestEdgeComponent", "edgesInsideFilledParent", "barrier"];
plotLabels = ["edge px", "edge comps", "largest comp", "edges in filledParent", "barrier (1 = yes)"];
for p = 1:5
    ax = nexttile(layout);
    plot(ax, 1:nSlices, double(stats{1}.(plotFields(p))), 'b-', 1:nSlices, double(stats{2}.(plotFields(p))), 'r--');
    ylabel(ax, plotLabels(p));
    xlim(ax, [1 nSlices]);
end
legend(ax, 'pn0', 'pn3', 'Location', 'northeast');
xlabel(ax, 'axial slice k');
fig1.Position(3:4) = [950 1050];
exportgraphics(fig1, fullfile(cfg.paths.figures, 'exp016_t1_canny_per_slice.png'));

% 2. Passi per le slice diagnostiche
for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 6, numel(diagnosticSlices), 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf(['EXP-016 T1 %s edge diagnostic (NOT Phase-51 validation) - T1 / raw Canny / ' ...
        'Canny on T1 (red) / EXP-012 anchor / Canny in filledParent / barrier (green: anchor region, ' ...
        'red: parent region, white: edges)'], noiseLevels(n)), 'Interpreter', 'none');
    for r = 1:6
        for c = 1:numel(diagnosticSlices)
            k = diagnosticSlices(c);
            I = volumes{n}(:, :, k).';
            e = edgeVolumes{n}(:, :, k).';
            switch r
                case 1, rgb = repmat(I, 1, 1, 3);
                case 2, rgb = repmat(double(e), 1, 1, 3);
                case 3
                    red = I; green = I; blue = I;
                    red(e) = 1; green(e) = 0; blue(e) = 0;
                    rgb = cat(3, red, green, blue);
                case 4, rgb = repmat(double(anchors{n}(:, :, k).'), 1, 1, 3);
                case 5, rgb = repmat(double(e & filledParents{n}(:, :, k).'), 1, 1, 3);
                case 6
                    ar = anchorRegions{n}(:, :, k).';
                    pr = parentRegions{n}(:, :, k).';
                    local = e & filledParents{n}(:, :, k).';
                    red = 0.8 * double(pr) + double(local);
                    green = 0.8 * double(ar) + double(local);
                    blue = double(local);
                    rgb = min(cat(3, red, green, blue), 1);
            end
            ax = nexttile(layout);
            image(ax, rgb);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('k=%d', k), 'FontSize', 7);
        end
    end
    fig.Position(3:4) = [1700 1100];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp016_t1_%s_canny_steps.png', noiseLevels(n))), ...
        'Resolution', 150);
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
fprintf('\nEXP-016 CHECKS: PASS\n');


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
