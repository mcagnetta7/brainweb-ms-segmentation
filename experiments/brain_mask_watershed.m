%% Watershed a marker per separare cervello e periferia (fase 50, EXP-008)
% Esperimento supplementare dentro la fase 50, dopo EXP-006 (A tenuto
% come supporto della testa, B respinto) ed EXP-007 (respinto).
%
% Configurazione UNICA, dichiarata prima dei risultati (nessuno sweep):
%   erosione per i marker:   strel('square', 5)  (solo per i marker)
%   gradiente morfologico:   imdilate - imerode con ones(3)
%   connettività:            8 (componenti 2D)
%   elaborazione:            2D slice per slice, stessa regola pn0 e pn3
%   dettagli: vedi src/segmentation/watershedBrainMaskSlices.m
%
% Accettazione (qualitativa, nessun punteggio): le slice centrali non
% sono più dischi della testa; la periferia è separata; il candidato è
% coerente e non frammentato; pn0 e pn3 si comportano in modo coerente;
% non ricompare il bordo mancante di EXP-007; i marker sono validi su una
% parte significativa del volume. Altrimenti EXP-008 è respinto e resta
% il candidato A.
%
% Nessun ground truth, nessuna etichetta anatomica, nessun intervallo di
% slice, nessuna scelta manuale di bacini, nessuna sovrapposizione alla
% MRI (fase 51). Se un controllo tecnico fallisce lo script si ferma.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

modality = cfg.dataset.modality;
assert(cfg.preprocessing.filter.method == "none", 'EXP-008 requires no filter.');

connectivity = 8;
markerElement = strel('square', 5);
gradientNeighborhood = ones(3);
expectedThresholds = [78 75] / 255;         % EXP-005, solo controllo di riproducibilità
expectedCandidateA = [4165201 4160417];     % EXP-006, solo controllo di riproducibilità

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
nSlices = cfg.dataset.volumeSize(3);
displaySlices = round(linspace(1, nSlices, 5));

volumes = cell(1, 2);
headMasks = cell(1, 2);
candidates = cell(1, 2);
brainMarkers = cell(1, 2);
nonBrainMarkers = cell(1, 2);
diags = cell(1, 2);
checks = cell(0, 2);

for n = 1:2
    noise = noiseLevels(n);
    raw = loadBrainwebMri(cfg, modality, noise);
    volume = prepare(raw);
    volumeCopy = volume;

    [rawMask, threshold] = initialSupportMask(volume);
    headSupport = cleanSupportMaskSlices(rawMask, connectivity, []);

    checks(end+1, :) = {noise + " EXP-005 threshold reproduced", abs(threshold - expectedThresholds(n)) < 1e-9}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate A reproduced", nnz(headSupport) == expectedCandidateA(n)}; %#ok<SAGROW>
    if any(~[checks{:, 2}])
        error('exp008:inputNotReproduced', 'EXP-005 / EXP-006 inputs not reproduced.');
    end

    [candidate, brainMarker, nonBrainMarker, d] = watershedBrainMaskSlices( ...
        volume, rawMask, headSupport, markerElement, gradientNeighborhood, connectivity);

    valid = ~d.markerEmpty;
    checks(end+1, :) = {noise + " input double in [0,1]", isa(volume, 'double') && min(volume(:)) >= 0 && max(volume(:)) <= 1}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " brain marker within raw mask", ~any(brainMarker(:) & ~rawMask(:))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " markers disjoint (all slices)", all(d.markerOverlap == 0)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate logical, same size", islogical(candidate) && isequal(size(candidate), size(volume))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate within head support", ~any(candidate(:) & ~headSupport(:))}; %#ok<SAGROW>
    markerInside = true;
    for k = find(valid)'
        markerInside = markerInside && ~any(any(brainMarker(:, :, k) & ~candidate(:, :, k)));
    end
    checks(end+1, :) = {noise + " brain marker inside candidate", markerInside}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " normalized volume unchanged", isequal(volume, volumeCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw MRI unchanged on reload", isequal(raw, loadBrainwebMri(cfg, modality, noise))}; %#ok<SAGROW>

    volumes{n} = volume;
    headMasks{n} = headSupport;
    candidates{n} = candidate;
    brainMarkers{n} = brainMarker;
    nonBrainMarkers{n} = nonBrainMarker;
    diags{n} = d;
end


%% Diagnostica

rows = cell(2, 1);
for n = 1:2
    d = diags{n};
    c = candidates{n};
    nonEmpty = find(squeeze(any(c, [1 2])));
    if isempty(nonEmpty)
        firstSlice = NaN; lastSlice = NaN;
    else
        firstSlice = nonEmpty(1); lastSlice = nonEmpty(end);
    end
    rows{n} = {string(modality), noiseLevels(n), nnz(headMasks{n}), ...
        nnz(~d.markerEmpty), nnz(d.markerEmpty), nnz(d.markerOverlap > 0), nnz(d.labelsUnderMarker > 1), ...
        nnz(c), nnz(c) / numel(c), numel(nonEmpty), nSlices - numel(nonEmpty), firstSlice, lastSlice, ...
        nnz(headMasks{n}) - nnz(c), sum(d.addedByFilling)};
end
summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'Modality', 'Noise', 'CandidateAVoxels', 'ValidMarkerSlices', 'EmptyMarkerSlices', ...
     'OverlapSlices', 'MultiLabelMarkerSlices', 'Exp008Voxels', 'Exp008Fraction', ...
     'NonEmptySlices', 'EmptySlices', 'FirstNonEmpty', 'LastNonEmpty', ...
     'RemovedVsCandidateA', 'AddedByFilling'});
disp(summary);

intersectionOverUnion = nnz(candidates{1} & candidates{2}) / nnz(candidates{1} | candidates{2});
differing = nnz(xor(candidates{1}, candidates{2})) / numel(candidates{1});
fprintf('EXP-008 consistency (pn0 vs pn3): IoU = %.4f, differing voxels = %.4f %%\n\n', ...
    intersectionOverUnion, 100 * differing);

writetable(summary, fullfile(cfg.paths.metrics, 'exp008_watershed_summary.csv'));

areaRatio = zeros(nSlices, 2);
for n = 1:2
    areaA = squeeze(sum(headMasks{n}, [1 2]));
    areaC = squeeze(sum(candidates{n}, [1 2]));
    areaRatio(:, n) = areaC ./ max(areaA, 1);
end
perSlice = table((1:nSlices)', diags{1}.nComponentsEroded, diags{1}.markerArea, areaRatio(:, 1), ...
    diags{2}.nComponentsEroded, diags{2}.markerArea, areaRatio(:, 2), ...
    'VariableNames', {'k', 'pn0_nComponentsEroded', 'pn0_markerArea', 'pn0_areaRatioToA', ...
                      'pn3_nComponentsEroded', 'pn3_markerArea', 'pn3_areaRatioToA'});
writetable(perSlice, fullfile(cfg.paths.metrics, 'exp008_watershed_per_slice.csv'));


%% Figure (diagnostica dell'algoritmo, nessuna sovrapposizione finale alla MRI)

% 1. Rapporto area candidato / area A per ogni slice (circa 1 = disco della testa)
fig1 = figure('Color', 'w');
ax = axes('Parent', fig1);
plot(ax, 1:nSlices, areaRatio(:, 1), 'b-', 1:nSlices, areaRatio(:, 2), 'r--');
legend(ax, 'pn0', 'pn3', 'Location', 'south');
xlabel(ax, 'axial slice k'); ylabel(ax, 'EXP-008 area / candidate A area');
title(ax, 'EXP-008 - area ratio to head support per slice (all slices)');
xlim(ax, [1 nSlices]); ylim(ax, [0 1.05]);
fig1.Position(3:4) = [900 400];
exportgraphics(fig1, fullfile(cfg.paths.figures, 'exp008_area_ratio_per_slice.png'));

% 2. A / marker cervello / marker non-cervello / candidato, per pn0 e pn3
for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 4, numel(displaySlices), 'TileSpacing', 'compact');
    title(layout, sprintf('EXP-008 %s - candidate A / brain marker / non-brain marker / EXP-008 candidate', ...
        noiseLevels(n)), 'Interpreter', 'none');
    versions = {headMasks{n}, brainMarkers{n}, nonBrainMarkers{n}, candidates{n}};
    labels = ["A (head support)", "brain marker", "non-brain marker", "EXP-008"];
    for v = 1:4
        for s = 1:numel(displaySlices)
            ax = nexttile(layout);
            imagesc(ax, versions{v}(:, :, displaySlices(s)).');
            colormap(ax, gray);
            clim(ax, [0 1]);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('%s  k = %d', labels(v), displaySlices(s)));
        end
    end
    fig.Position(3:4) = [1300 1100];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp008_%s_markers_and_candidate.png', noiseLevels(n))));
end

% 3. Gradiente morfologico e linee del watershed (rosso) sulle slice deterministiche
fig3 = figure('Color', 'w');
layout = tiledlayout(fig3, 2, numel(displaySlices), 'TileSpacing', 'compact');
title(layout, 'EXP-008 - morphological gradient (3x3) with watershed ridge lines (red)', 'Interpreter', 'none');
for n = 1:2
    for s = 1:numel(displaySlices)
        k = displaySlices(s);
        sliceImage = volumes{n}(:, :, k);
        gradientImage = imdilate(sliceImage, gradientNeighborhood) - imerode(sliceImage, gradientNeighborhood);
        markers = brainMarkers{n}(:, :, k) | nonBrainMarkers{n}(:, :, k);
        ridges = false(size(sliceImage));
        if any(brainMarkers{n}(:, :, k), 'all')
            ridges = watershed(imimposemin(gradientImage, markers)) == 0;
        end
        ax = nexttile(layout);
        imagesc(ax, gradientImage.');
        colormap(ax, gray);
        hold(ax, 'on');
        [rows, cols] = find(ridges);
        plot(ax, rows, cols, 'r.', 'MarkerSize', 2);
        hold(ax, 'off');
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('%s  k = %d', noiseLevels(n), k));
    end
end
fig3.Position(3:4) = [1400 650];
exportgraphics(fig3, fullfile(cfg.paths.figures, 'exp008_gradient_watershed_lines.png'));


%% Salvataggio e controlli

for n = 1:2
    mask = candidates{n};
    brainMarker = brainMarkers{n};
    method = 'EXP-008: marker-controlled watershed on 3x3 morphological gradient; brain marker = largest 8-conn component of imerode(raw AND candidateA, square 5); non-brain marker = outside candidateA plus candidateA minus imerode(candidateA, square 5); basin AND candidateA; imfill holes';
    save(fullfile(cfg.paths.processedData, ...
        sprintf('exp008_watershed_%s_%s_support_mask.mat', lower(modality), noiseLevels(n))), ...
        'mask', 'brainMarker', 'method');
end

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-42s %s\n', checks{c, 1}, result);
end
if ~all([checks{:, 2}])
    error('exp008:validationFailed', 'EXP-008 CHECKS: FAIL');
end
fprintf('\nEXP-008 CHECKS: PASS\n');
