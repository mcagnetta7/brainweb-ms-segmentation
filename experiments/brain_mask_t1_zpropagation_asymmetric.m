%% T1: propagazione asimmetrica della maschera lungo z (fase 50, EXP-019)
% EXP-018 (propagazione con erosione e dilatazione di raggio 3) ha dato un
% supporto a scala cerebrale al centro e in alto, ma sotto k ~ 45 la
% maschera è scivolata in orbita, seni, faccia e collo senza fermarsi.
% EXP-019 cambia SOLO i due raggi, dichiarati prima dei risultati:
%   il seme è la slice con la sezione più grande, quindi allontanandosi dal
%   seme il cervello si restringe:
%   - sfondo = NOT imdilate(M, disk 1): crescita al più ~1 px per slice
%   - primo piano = imerode(M, disk 5): la maschera può arretrare più in
%     fretta della variazione massima osservata del raggio equivalente dei
%     candidati EXP-012 (~3.6 px per slice a k = 46-133)
% Tutto il resto è come EXP-018 (stesso seme, gradiente morfologico 3x3
% della T1, imimposemin + watershed, bacini toccati dal primo piano AND NOT
% sfondo, imfill, arresto con primo piano vuoto). Propagazione tra slice
% autorizzata dall'utente; solo operazioni 2D; nessuno sweep, nessun
% vincolo da Otsu, nessun GT. T2 resta la modalità delle lesioni.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

maskModality = "T1";
assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'EXP-019 requires no filter.');

connectivity = 8;
erosionElement = strel('disk', 5, 0);
dilationElement = strel('disk', 1, 0);
gradientNeighborhood = ones(3);
expectedThresholds = [66 64] / 255;         % EXP-010, solo controllo
expectedRawVoxels = [2771291 2727314];      % EXP-010, solo controllo

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
nSlices = cfg.dataset.volumeSize(3);
% Slice diagnostiche già dichiarate nella fase 50 (solo diagnostica)
diagnosticSlices = sort([round(linspace(1, nSlices, 5)), 40, 43, 44, 139, 143]);

volumes = cell(1, 2);
rawMasks = cell(1, 2);
candidates = cell(1, 2);
fgMarkers = cell(1, 2);
bgMarkers = cell(1, 2);
ridges = cell(1, 2);
seeds = zeros(1, 2);
exp012Areas = cell(1, 2);
exp018Areas = cell(1, 2);
otsuFraction = cell(1, 2);
outsideFill = cell(1, 2);
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
    if ~checks{end, 2} || ~checks{end-1, 2}
        error('exp019:inputNotReproduced', 'EXP-010 raw T1 masks not reproduced: EXP-019 TECHNICALLY BLOCKED.');
    end

    % Ancora EXP-012 (funzione validata in EXP-015) e accordo con EXP-011
    [~, ~, anchorMask] = internalDarkSkeletonMarkersSlices(rawMask, connectivity);
    exp012 = load(fullfile(cfg.paths.processedData, sprintf('exp012_t1_%s_nested_support_mask_candidate.mat', noise)), ...
        'selectedMask', 'candidate');
    exp018 = load(fullfile(cfg.paths.processedData, sprintf('exp018_t1_%s_zpropagation_candidate.mat', noise)), ...
        'candidate');
    if ~isequal(anchorMask, exp012.selectedMask)
        error('exp019:anchorNotReproduced', 'EXP-012 anchor not reproduced: EXP-019 TECHNICALLY BLOCKED.');
    end
    agreement = false(nSlices, 1);
    anchorArea = squeeze(sum(anchorMask, [1 2]));
    for k = 1:nSlices
        if anchorArea(k) == 0
            continue
        end
        components = bwconncomp(rawMask(:, :, k), connectivity);
        [~, index] = max(cellfun(@numel, components.PixelIdxList));
        largest = false(size(rawMask, [1 2]));
        largest(components.PixelIdxList{index}) = true;
        agreement(k) = isequal(largest, anchorMask(:, :, k));
    end
    agreementArea = anchorArea .* agreement;
    [~, seedSlice] = max(agreementArea);
    seedMask = imfill(anchorMask(:, :, seedSlice), 'holes');

    [candidate, fg, bg, ridgeMask, d] = propagateBrainMaskSlices(volume, seedMask, seedSlice, ...
        erosionElement, dilationElement, gradientNeighborhood);

    % Verifiche indipendenti: il bacino sta dentro la maschera vicina
    % dilatata; l'imfill finale può aggiungere fuori da essa solo buchi
    % racchiusi (es. concavità della maschera vicina chiuse dalla dilatazione)
    insideDilatedNeighbor = true;
    outsideDilatedByFilling = zeros(nSlices, 1);
    for k = [seedSlice + 1:nSlices, seedSlice - 1:-1:1]
        neighbor = candidate(:, :, k + (k < seedSlice) - (k > seedSlice));
        dilated = imdilate(neighbor, dilationElement);
        insideDilatedNeighbor = insideDilatedNeighbor && ...
            isequal(candidate(:, :, k), imfill(candidate(:, :, k) & dilated, 'holes'));
        outsideDilatedByFilling(k) = nnz(candidate(:, :, k) & ~dilated);
    end
    recomputed = true;
    for k = setdiff(diagnosticSlices, seedSlice)
        neighbor = candidate(:, :, k + (k < seedSlice) - (k > seedSlice));
        f = imerode(neighbor, erosionElement);
        if ~any(f(:))
            recomputed = recomputed && ~any(candidate(:, :, k), 'all');
            continue
        end
        b = ~imdilate(neighbor, dilationElement);
        I = volume(:, :, k);
        L = watershed(imimposemin(imdilate(I, ones(3)) - imerode(I, ones(3)), f | b));
        t = unique(L(f));
        t = t(t > 0);
        recomputed = recomputed && isequal(imfill(ismember(L, t) & ~b, 'holes'), candidate(:, :, k));
    end

    checks(end+1, :) = {noise + " anchor = EXP-012 selected component", isequal(anchorMask, exp012.selectedMask)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " seed is an EXP-011/EXP-012 agreement slice", agreement(seedSlice)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " seed mask = EXP-012 candidate at seed", ...
        isequal(candidate(:, :, seedSlice), exp012.candidate(:, :, seedSlice))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " fg/bg markers disjoint", ~any(fg & bg, 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " outside dilated neighbor only by filling", insideDilatedNeighbor}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " propagation recomputed on diag. slices", recomputed}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " stopped slices empty", ~any(candidate(:, :, d.stopped), 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate logical, same size", islogical(candidate) && isequal(size(candidate), size(volume))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " normalized volume unchanged", isequal(volume, volumeCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw MRI unchanged on reload", isequal(raw, loadBrainwebMri(cfg, maskModality, noise))}; %#ok<SAGROW>

    save(fullfile(cfg.paths.processedData, sprintf('exp019_t1_%s_zpropagation_candidate.mat', noise)), ...
        'candidate', 'seedSlice', 'threshold');

    candidateArea = squeeze(sum(candidate, [1 2]));
    fraction = squeeze(sum(candidate & rawMask, [1 2])) ./ max(candidateArea, 1);
    fraction(candidateArea == 0) = NaN;

    volumes{n} = volume;
    rawMasks{n} = rawMask;
    candidates{n} = candidate;
    fgMarkers{n} = fg;
    bgMarkers{n} = bg;
    ridges{n} = ridgeMask;
    seeds(n) = seedSlice;
    exp012Areas{n} = squeeze(sum(exp012.candidate, [1 2]));
    exp018Areas{n} = squeeze(sum(exp018.candidate, [1 2]));
    otsuFraction{n} = fraction;
    outsideFill{n} = outsideDilatedByFilling;
    diags{n} = d;
end

if any(~[checks{:, 2}])
    error('exp019:checksFailed', 'EXP-019 technical checks failed.');
end


%% Diagnostica

rows = cell(2, 1);
for n = 1:2
    d = diags{n};
    c = candidates{n};
    nonEmpty = find(squeeze(any(c, [1 2])));
    propagated = d.candidateArea > 0;
    propagated(seeds(n)) = false;
    rows{n} = {maskModality, noiseLevels(n), seeds(n), nnz(c), nnz(c) / numel(c), numel(nonEmpty), ...
        nSlices - numel(nonEmpty), nonEmpty(1), nonEmpty(end), nnz(d.stopped), ...
        median(d.labelsTouched(propagated)), max(d.labelsTouched(propagated)), sum(d.addedByFilling), ...
        sum(outsideFill{n}), nnz(outsideFill{n}), ...
        median(otsuFraction{n}, 'omitnan'), sum(exp012Areas{n}), sum(exp018Areas{n})};
end
summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'MaskModality', 'Noise', 'SeedSlice', 'CandidateVoxels', 'CandidateFraction', 'NonEmptySlices', ...
     'EmptySlices', 'FirstNonEmpty', 'LastNonEmpty', 'StoppedSlices', 'MedianLabelsTouched', ...
     'MaxLabelsTouched', 'AddedByFilling', 'FilledOutsideDilatedNeighbor', 'SlicesFilledOutsideDilated', ...
     'MedianOtsuFractionInCandidate', 'Exp012Voxels', 'Exp018Voxels'});
disp(summary);

h0 = squeeze(any(candidates{1}, [1 2]));
h3 = squeeze(any(candidates{2}, [1 2]));
intersectionOverUnion = nnz(candidates{1} & candidates{2}) / nnz(candidates{1} | candidates{2});
fprintf(['EXP-019 consistency (pn0 vs pn3): IoU = %.4f, differing voxels = %.4f %%\n' ...
         'Slices with candidate: both %d, only pn0 %d, only pn3 %d, neither %d\n\n'], ...
    intersectionOverUnion, 100 * nnz(xor(candidates{1}, candidates{2})) / numel(candidates{1}), ...
    nnz(h0 & h3), nnz(h0 & ~h3), nnz(~h0 & h3), nnz(~h0 & ~h3));

for n = 1:2
    d = diags{n};
    ks = unique([diagnosticSlices, seeds(n)]).';
    disp(table(ks, d.foregroundArea(ks), d.bandArea(ks), d.labelsTouched(ks), d.addedByFilling(ks), ...
        d.candidateArea(ks), exp012Areas{n}(ks), exp018Areas{n}(ks), round(otsuFraction{n}(ks), 3), d.stopped(ks), ...
        'VariableNames', {char("k_" + noiseLevels(n)), 'fgMarker', 'band', 'labels', 'fillAdded', 'exp019', ...
        'exp012', 'exp018', 'otsuFraction', 'stopped'}));
end

writetable(summary, fullfile(cfg.paths.metrics, 'exp019_t1_zpropagation_summary.csv'));
perSliceColumns = {};
perSliceNames = {'k'};
fields = ["foregroundArea", "backgroundArea", "bandArea", "labelsTouched", "basinArea", "addedByFilling", ...
    "candidateArea", "stopped"];
for n = 1:2
    for f = fields
        perSliceColumns{end+1} = diags{n}.(f); %#ok<SAGROW>
    end
    perSliceColumns = [perSliceColumns, {exp012Areas{n}, exp018Areas{n}, otsuFraction{n}, outsideFill{n}}]; %#ok<AGROW>
    perSliceNames = [perSliceNames, cellstr(noiseLevels(n) + "_" + [fields, "exp012Area", "exp018Area", ...
        "otsuFraction", "filledOutsideDilatedNeighbor"])]; %#ok<AGROW>
end
perSlice = table((1:nSlices)', perSliceColumns{:}, 'VariableNames', perSliceNames);
writetable(perSlice, fullfile(cfg.paths.metrics, 'exp019_t1_zpropagation_per_slice.csv'));


%% Figure (diagnostica di sviluppo, NON validazione della fase 51)

% 1. Aree per slice e frazione Otsu
fig1 = figure('Color', 'w');
layout = tiledlayout(fig1, 3, 1, 'TileSpacing', 'compact');
title(layout, 'EXP-019 - per-slice areas (EXP-012 / EXP-018 / EXP-019) and raw-Otsu fraction inside EXP-019', ...
    'Interpreter', 'none');
for n = 1:2
    ax = nexttile(layout);
    plot(ax, 1:nSlices, exp012Areas{n}, 'b-', 1:nSlices, exp018Areas{n}, 'g-', 1:nSlices, diags{n}.candidateArea, 'r--');
    xline(ax, seeds(n), 'k:');
    legend(ax, 'EXP-012', 'EXP-018', 'EXP-019', 'seed', 'Location', 'north');
    ylabel(ax, 'pixels');
    title(ax, sprintf('T1 %s (seed k = %d)', noiseLevels(n), seeds(n)));
    xlim(ax, [1 nSlices]);
end
ax = nexttile(layout);
plot(ax, 1:nSlices, otsuFraction{1}, 'b-', 1:nSlices, otsuFraction{2}, 'r--');
ylabel(ax, 'Otsu fraction in EXP-019');
legend(ax, 'pn0', 'pn3', 'Location', 'south');
xlim(ax, [1 nSlices]);
xlabel(ax, 'axial slice k');
fig1.Position(3:4) = [950 900];
exportgraphics(fig1, fullfile(cfg.paths.figures, 'exp019_t1_zpropagation_per_slice.png'));

% 2. Passi per le slice diagnostiche
for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 7, numel(diagnosticSlices), 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf(['EXP-019 T1 %s development diagnostic (NOT Phase-51 validation) - T1 / neighbor mask ' ...
        '(k-1 above seed, k+1 below) / fg marker / bg marker / watershed ridges / EXP-019 candidate / ' ...
        'candidate on T1 (seed k = %d)'], noiseLevels(n), seeds(n)), 'Interpreter', 'none');
    for r = 1:7
        for c = 1:numel(diagnosticSlices)
            k = diagnosticSlices(c);
            I = volumes{n}(:, :, k).';
            neighborIndex = k + (k < seeds(n)) - (k > seeds(n));
            switch r
                case 1, rgb = repmat(I, 1, 1, 3);
                case 2, rgb = repmat(double(candidates{n}(:, :, neighborIndex).'), 1, 1, 3);
                case 3, rgb = repmat(double(fgMarkers{n}(:, :, k).'), 1, 1, 3);
                case 4, rgb = repmat(double(bgMarkers{n}(:, :, k).'), 1, 1, 3);
                case 5, rgb = repmat(double(ridges{n}(:, :, k).'), 1, 1, 3);
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
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp019_t1_%s_zpropagation_steps.png', noiseLevels(n))), ...
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
fprintf('\nEXP-019 CHECKS: PASS\n');
