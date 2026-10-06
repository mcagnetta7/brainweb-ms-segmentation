%% T1: candidato dal contorno di Canny più piccolo che racchiude l'ancora (fase 50, EXP-017)
% EXP-016 ha mostrato che Canny automatico contiene un confine esterno del
% cervello utile ma immerso in molti contorni. EXP-017 prova UNA
% conversione minima da bordi a regione:
%   T1 -> double -> /4095 -> edge(I,'Canny') (EXP-016, invariato)
%   -> UNA chiusura imclose(bordi, strel('square',3))
%   -> componenti dei bordi a 8-connettività, ognuna riempita DA SOLA
%   -> regioni che contengono TUTTA l'ancora EXP-012
%   -> la più piccola (parità: indice più basso) = candidato
% Nessuna ancora o nessuna regione racchiudente -> slice VUOTA. Nessun
% vincolo da Otsu o dal genitore, nessuna morfologia dopo la scelta, nessuno
% sweep, nessuna informazione da altre slice, nessun GT.
% T1 serve solo per la maschera; T2 resta la modalità delle lesioni.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

maskModality = "T1";
assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'EXP-017 requires no filter.');

connectivity = 8;
closingElement = strel('square', 3);
expectedThresholds = [66 64] / 255;         % EXP-010, solo controllo
expectedRawVoxels = [2771291 2727314];      % EXP-010, solo controllo

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
nSlices = cfg.dataset.volumeSize(3);
% Slice diagnostiche dichiarate prima di EXP-017 (solo diagnostica)
diagnosticSlices = sort([round(linspace(1, nSlices, 5)), 40, 43, 44, 139, 143]);

volumes = cell(1, 2);
edgeVolumes = cell(1, 2);
closedVolumes = cell(1, 2);
anchors = cell(1, 2);
candidates = cell(1, 2);
counts = cell(1, 2);
exp012Areas = cell(1, 2);
coverage = cell(1, 2);
diags = cell(1, 2);
checks = cell(0, 2);

for n = 1:2
    noise = noiseLevels(n);
    raw = loadBrainwebMri(cfg, maskModality, noise);
    volume = prepare(raw);
    volumeCopy = volume;

    checks(end+1, :) = {noise + " normalized input double in [0,1]", isa(volume, 'double') ...
        && min(volume(:)) >= 0 && max(volume(:)) <= 1}; %#ok<SAGROW>

    % Canny di EXP-016, riprodotto
    edges = detectT1CannyEdgesSlices(volume);
    exp016 = load(fullfile(cfg.paths.processedData, sprintf('exp016_t1_%s_canny_edges.mat', noise)), 'cannyEdges');
    if ~isequal(edges, exp016.cannyEdges)
        error('exp017:cannyNotReproduced', 'EXP-016 Canny not reproduced: EXP-017 TECHNICALLY BLOCKED.');
    end

    % Ancora di EXP-012, riprodotta (funzione validata in EXP-015)
    [rawMask, threshold] = initialSupportMask(volume);
    checks(end+1, :) = {noise + " EXP-010 threshold reproduced", abs(threshold - expectedThresholds(n)) < 1e-9}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " EXP-010 raw foreground reproduced", nnz(rawMask) == expectedRawVoxels(n)}; %#ok<SAGROW>
    [~, ~, anchorMask] = internalDarkSkeletonMarkersSlices(rawMask, connectivity);
    exp012 = load(fullfile(cfg.paths.processedData, sprintf('exp012_t1_%s_nested_support_mask_candidate.mat', noise)), ...
        'selectedMask', 'candidate');
    if ~isequal(anchorMask, exp012.selectedMask)
        error('exp017:anchorNotReproduced', 'EXP-012 anchor not reproduced: EXP-017 TECHNICALLY BLOCKED.');
    end

    [candidate, closedEdges, enclosingCount, d] = ...
        selectCannyEnclosingBrainCandidateSlices(edges, anchorMask, closingElement, connectivity);

    % Verifiche indipendenti
    closingRecomputed = true;
    candidateRecomputed = true;
    for k = 1:nSlices
        closingRecomputed = closingRecomputed && isequal(closedEdges(:, :, k), ...
            imclose(edges(:, :, k), strel('square', 3)));
    end
    for k = diagnosticSlices
        expected = false(size(rawMask, [1 2]));
        a = anchorMask(:, :, k);
        if any(a(:))
            comps = bwconncomp(closedEdges(:, :, k), 8);
            best = inf;
            for i = 1:comps.NumObjects
                m = false(size(a));
                m(comps.PixelIdxList{i}) = true;
                f = imfill(m, 'holes');
                if all(f(a)) && nnz(f) < best
                    best = nnz(f);
                    expected = f;
                end
            end
        end
        candidateRecomputed = candidateRecomputed && isequal(expected, candidate(:, :, k));
    end

    % Copertura delle componenti Otsu grezze (solo descrittiva)
    cov = struct('nComponentsIntersected', zeros(nSlices, 1), 'rawInside', zeros(nSlices, 1), ...
        'rawOutside', zeros(nSlices, 1));
    for k = find(d.hasCandidate).'
        c = candidate(:, :, k);
        r = rawMask(:, :, k);
        comps = bwconncomp(r, connectivity);
        cov.nComponentsIntersected(k) = nnz(cellfun(@(p) any(c(p)), comps.PixelIdxList));
        cov.rawInside(k) = nnz(r & c);
        cov.rawOutside(k) = nnz(r & ~c);
    end

    checks(end+1, :) = {noise + " EXP-016 Canny reproduced exactly", isequal(edges, exp016.cannyEdges)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " anchor = EXP-012 selected component", isequal(anchorMask, exp012.selectedMask)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " closing = one imclose square(3)", closingRecomputed}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate recomputed on diag. slices", candidateRecomputed}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate contains whole anchor", ~any(anchorMask & ~candidate & ...
        reshape(repelem(d.hasCandidate, numel(rawMask(:, :, 1))), size(rawMask)), 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " empty where no anchor / no enclosure", ~any(candidate(:, :, ~d.hasCandidate), 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate logical, same size", islogical(candidate) && isequal(size(candidate), size(volume))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " normalized volume unchanged", isequal(volume, volumeCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw MRI unchanged on reload", isequal(raw, loadBrainwebMri(cfg, maskModality, noise))}; %#ok<SAGROW>

    selection = rmfield(d, 'enclosingAreas');
    enclosingAreas = d.enclosingAreas;
    save(fullfile(cfg.paths.processedData, sprintf('exp017_t1_%s_canny_enclosing_candidate.mat', noise)), ...
        'candidate', 'closedEdges', 'selection', 'enclosingAreas', 'threshold');

    volumes{n} = volume;
    edgeVolumes{n} = edges;
    closedVolumes{n} = closedEdges;
    anchors{n} = anchorMask;
    candidates{n} = candidate;
    counts{n} = enclosingCount;
    exp012Areas{n} = squeeze(sum(exp012.candidate, [1 2]));
    coverage{n} = cov;
    diags{n} = d;
end

if any(~[checks{:, 2}])
    error('exp017:checksFailed', 'EXP-017 technical checks failed.');
end


%% Diagnostica

rows = cell(2, 1);
for n = 1:2
    d = diags{n};
    a = d.hasAnchor;
    c = d.hasCandidate;
    ratio = d.candidateArea(c) ./ d.anchorArea(c);
    nonEmpty = find(squeeze(any(candidates{n}, [1 2])));
    if isempty(nonEmpty)
        nonEmpty = 0;
    end
    rows{n} = {maskModality, noiseLevels(n), sum(d.rawEdgePixels), sum(d.closedEdgePixels), ...
        sum(d.addedByClosing), sum(d.removedByClosing), median(d.nRawComponents), max(d.nRawComponents), ...
        median(d.nClosedComponents), max(d.nClosedComponents), nnz(a), nnz(c), nnz(a & ~c), ...
        median(d.nEnclosing(a)), max(d.nEnclosing(a)), sum(d.tieCount), ...
        nnz(candidates{n}), nnz(candidates{n}) / numel(candidates{n}), median(ratio), max(ratio), ...
        median(d.bestCoverage(a & ~c)), nonEmpty(1), nonEmpty(end)};
end
summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'MaskModality', 'Noise', 'RawEdgePixels', 'ClosedEdgePixels', 'AddedByClosing', 'RemovedByClosing', ...
     'MedianRawComponents', 'MaxRawComponents', 'MedianClosedComponents', 'MaxClosedComponents', ...
     'SlicesWithAnchor', 'SlicesWithCandidate', 'AnchorSlicesWithoutEnclosure', ...
     'MedianEnclosing', 'MaxEnclosing', 'Ties', 'CandidateVoxels', 'CandidateFraction', ...
     'MedianCandidateToAnchor', 'MaxCandidateToAnchor', 'MedianBestCoverageWhenNoEnclosure', ...
     'FirstNonEmpty', 'LastNonEmpty'});
disp(summary);

h0 = diags{1}.hasCandidate;
h3 = diags{2}.hasCandidate;
intersectionOverUnion = nnz(candidates{1} & candidates{2}) / nnz(candidates{1} | candidates{2});
fprintf(['EXP-017 consistency (pn0 vs pn3): IoU = %.4f, differing voxels = %.4f %%\n' ...
         'Slices with candidate: both %d, only pn0 %d, only pn3 %d, neither %d\n'], ...
    intersectionOverUnion, 100 * nnz(xor(candidates{1}, candidates{2})) / numel(candidates{1}), ...
    nnz(h0 & h3), nnz(h0 & ~h3), nnz(~h0 & h3), nnz(~h0 & ~h3));
for n = 1:2
    fprintf('%s anchor slices without enclosing region: %s\n', noiseLevels(n), ...
        slicesAsRanges(find(diags{n}.hasAnchor & ~diags{n}.hasCandidate)));
end
fprintf('\n');

for n = 1:2
    d = diags{n};
    cov = coverage{n};
    ks = diagnosticSlices(:);
    areasText = strings(numel(ks), 1);
    for i = 1:numel(ks)
        areasText(i) = areasAsText(d.enclosingAreas{ks(i)});
    end
    disp(table(ks, d.anchorArea(ks), d.nClosedComponents(ks), d.nEnclosing(ks), d.candidateArea(ks), ...
        exp012Areas{n}(ks), round(d.bestCoverage(ks), 4), cov.nComponentsIntersected(ks), cov.rawInside(ks), ...
        cov.rawOutside(ks), areasText, ...
        'VariableNames', {char("k_" + noiseLevels(n)), 'anchor', 'closedComps', 'nEnclosing', 'candidate', ...
        'exp012', 'bestCoverage', 'otsuComps', 'otsuInside', 'otsuOutside', 'enclosingAreas'}));
end

writetable(summary, fullfile(cfg.paths.metrics, 'exp017_t1_canny_enclosing_summary.csv'));
perSliceColumns = {};
perSliceNames = {'k'};
fields = ["hasAnchor", "hasCandidate", "rawEdgePixels", "closedEdgePixels", "addedByClosing", ...
    "removedByClosing", "nRawComponents", "nClosedComponents", "anchorArea", "nEnclosing", "selectedIndex", ...
    "selectedFilledArea", "selectedEdgeArea", "candidateArea", "tieCount", "bestCoverage"];
for n = 1:2
    for f = fields
        perSliceColumns{end+1} = diags{n}.(f); %#ok<SAGROW>
    end
    perSliceColumns{end+1} = exp012Areas{n}; %#ok<SAGROW>
    perSliceColumns{end+1} = coverage{n}.nComponentsIntersected; %#ok<SAGROW>
    perSliceColumns{end+1} = coverage{n}.rawInside; %#ok<SAGROW>
    perSliceColumns{end+1} = coverage{n}.rawOutside; %#ok<SAGROW>
    areasText = strings(nSlices, 1);
    for k = 1:nSlices
        areasText(k) = areasAsText(diags{n}.enclosingAreas{k});
    end
    perSliceColumns{end+1} = areasText; %#ok<SAGROW>
    perSliceNames = [perSliceNames, cellstr(noiseLevels(n) + "_" + [fields, "exp012Area", ...
        "otsuComponentsIntersected", "otsuInside", "otsuOutside", "enclosingAreas"])]; %#ok<AGROW>
end
perSlice = table((1:nSlices)', perSliceColumns{:}, 'VariableNames', perSliceNames);
writetable(perSlice, fullfile(cfg.paths.metrics, 'exp017_t1_canny_enclosing_per_slice.csv'));


%% Figure (diagnostica di sviluppo, NON validazione della fase 51)

% 1. Curve per slice
fig1 = figure('Color', 'w');
layout = tiledlayout(fig1, 6, 1, 'TileSpacing', 'compact');
title(layout, 'EXP-017 - per-slice diagnostics (pn0 blue, pn3 red dashed)', 'Interpreter', 'none');
series = {@(n) diags{n}.nEnclosing, @(n) diags{n}.candidateArea, @(n) exp012Areas{n}, ...
    @(n) diags{n}.candidateArea ./ max(exp012Areas{n}, 1), @(n) diags{n}.addedByClosing, ...
    @(n) diags{n}.nClosedComponents};
labels = ["enclosing regions", "EXP-017 area", "EXP-012 area", "EXP-017 / EXP-012", ...
    "px added by closing", "closed-edge comps"];
for p = 1:6
    ax = nexttile(layout);
    plot(ax, 1:nSlices, double(series{p}(1)), 'b-', 1:nSlices, double(series{p}(2)), 'r--');
    ylabel(ax, labels(p));
    xlim(ax, [1 nSlices]);
end
legend(ax, 'pn0', 'pn3', 'Location', 'northeast');
xlabel(ax, 'axial slice k');
fig1.Position(3:4) = [950 1150];
exportgraphics(fig1, fullfile(cfg.paths.figures, 'exp017_t1_canny_enclosing_per_slice.png'));

% 2. Passi per le slice diagnostiche
for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 7, numel(diagnosticSlices), 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf(['EXP-017 T1 %s development diagnostic (NOT Phase-51 validation) - T1 / raw Canny / ' ...
        'closed edges / EXP-012 anchor / anchor-enclosing filled regions (brighter = more nested) / ' ...
        'selected candidate / candidate on T1'], noiseLevels(n)), 'Interpreter', 'none');
    for r = 1:7
        for c = 1:numel(diagnosticSlices)
            k = diagnosticSlices(c);
            I = volumes{n}(:, :, k).';
            switch r
                case 1, rgb = repmat(I, 1, 1, 3);
                case 2, rgb = repmat(double(edgeVolumes{n}(:, :, k).'), 1, 1, 3);
                case 3, rgb = repmat(double(closedVolumes{n}(:, :, k).'), 1, 1, 3);
                case 4, rgb = repmat(double(anchors{n}(:, :, k).'), 1, 1, 3);
                case 5
                    count = double(counts{n}(:, :, k).');
                    rgb = repmat(count / max(max(count(:)), 1), 1, 1, 3);
                case 6, rgb = repmat(double(candidates{n}(:, :, k).'), 1, 1, 3);
                case 7
                    m = candidates{n}(:, :, k).';
                    red = I; green = I; blue = I;
                    red(m) = 0.5 + 0.5 * red(m);
                    green(m) = 0.6 * green(m);
                    blue(m) = 0.6 * blue(m);
                    rgb = cat(3, red, green, blue);
            end
            ax = nexttile(layout);
            image(ax, rgb);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('k=%d', k), 'FontSize', 7);
        end
    end
    fig.Position(3:4) = [1700 1250];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp017_t1_%s_canny_enclosing_steps.png', noiseLevels(n))), ...
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
fprintf('\nEXP-017 CHECKS: PASS\n');


function text = areasAsText(areas)
%AREASASTEXT Aree delle regioni racchiudenti come testo, es. "18912 24705".
    if isempty(areas)
        text = "";
    else
        text = strjoin(string(areas(:).'), ' ');
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
