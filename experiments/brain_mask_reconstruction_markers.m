%% Marker da ricostruzione e massimi regionali per il watershed (fase 50, EXP-009)
% Ultimo tentativo controllato dentro la fase 50. Rispetto a EXP-008
% cambia SOLO il generatore del marker del primo piano:
%   EXP-008: componente più grande dopo erosione binaria 5x5
%   EXP-009: apertura per ricostruzione -> chiusura per ricostruzione
%            (strel('square', 3), connettività 8) -> imregionalmax (8);
%            si tengono TUTTE le componenti dei massimi che non toccano il
%            marker non-cervello di EXP-008
%
% Invariati rispetto a EXP-008: T2, pn0 + pn3, 2D, nessun filtro, Otsu
% globale, candidato A, marker non-cervello (sfondo + guscio 5x5 di A),
% gradiente morfologico 3x3 dell'immagine ORIGINALE, watershed con
% imimposemin. Selezione: unione dei bacini toccati da qualsiasi marker
% del primo piano, intersecata con A, poi imfill.
%
% Nessuno sweep, nessun ricorso al marker di EXP-008 dove manca il marker,
% nessuna propagazione tra slice, nessun ground truth, nessuna etichetta
% anatomica, nessun intervallo di slice, nessuna sovrapposizione alla MRI.
% Criteri di accettazione e rifiuto come da prompt di EXP-009; in caso
% di rifiuto non si avvia EXP-010.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

modality = cfg.dataset.modality;
assert(cfg.preprocessing.filter.method == "none", 'EXP-009 requires no filter.');

connectivity = 8;
shellElement = strel('square', 5);          % invariato da EXP-008 (marker non-cervello)
reconstructionElement = strel('square', 3); % EXP-009, solo per i marker
gradientNeighborhood = ones(3);             % invariato da EXP-008
expectedThresholds = [78 75] / 255;
expectedCandidateA = [4165201 4160417];

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
nSlices = cfg.dataset.volumeSize(3);
displaySlices = round(linspace(1, nSlices, 5));

volumes = cell(1, 2);
headMasks = cell(1, 2);
nonBrainMarkers = cell(1, 2);
foregroundMarkers = cell(1, 2);
candidates = cell(1, 2);
exp008Candidates = cell(1, 2);
markerDiags = cell(1, 2);
watershedDiags = cell(1, 2);
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
        error('exp009:inputNotReproduced', 'EXP-005 / EXP-006 inputs not reproduced.');
    end

    % Backbone di EXP-008 rieseguito: marker non-cervello identico
    [exp008Candidate, ~, nonBrainMarker] = watershedBrainMaskSlices( ...
        volume, rawMask, headSupport, shellElement, gradientNeighborhood, connectivity);

    % Nuovo generatore del marker del primo piano
    [foregroundMarker, md] = reconstructionRegionalMaxMarkers( ...
        volume, nonBrainMarker, reconstructionElement, connectivity);

    % Watershed invariato, unione dei bacini del primo piano
    [candidate, wd] = markerWatershedUnionSlices( ...
        volume, foregroundMarker, nonBrainMarker, headSupport, gradientNeighborhood);

    checks(end+1, :) = {noise + " markers disjoint (all slices)", all(md.overlap == 0)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate logical, same size", islogical(candidate) && isequal(size(candidate), size(volume))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate within head support", ~any(candidate(:) & ~headSupport(:))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " normalized volume unchanged", isequal(volume, volumeCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw MRI unchanged on reload", isequal(raw, loadBrainwebMri(cfg, modality, noise))}; %#ok<SAGROW>

    volumes{n} = volume;
    headMasks{n} = headSupport;
    nonBrainMarkers{n} = nonBrainMarker;
    foregroundMarkers{n} = foregroundMarker;
    candidates{n} = candidate;
    exp008Candidates{n} = exp008Candidate;
    markerDiags{n} = md;
    watershedDiags{n} = wd;
end

if any(~[checks{:, 2}])
    error('exp009:checksFailed', 'EXP-009 technical checks failed.');
end


%% Diagnostica

rows = cell(2, 1);
areaRatio = zeros(nSlices, 2);
for n = 1:2
    md = markerDiags{n};
    wd = watershedDiags{n};
    c = candidates{n};
    nonEmpty = find(squeeze(any(c, [1 2])));
    if isempty(nonEmpty)
        firstSlice = NaN; lastSlice = NaN;
    else
        firstSlice = nonEmpty(1); lastSlice = nonEmpty(end);
    end
    areaRatio(:, n) = squeeze(sum(c, [1 2])) ./ max(squeeze(sum(headMasks{n}, [1 2])), 1);
    rows{n} = {string(modality), noiseLevels(n), nnz(headMasks{n}), ...
        sum(md.nMaxima), sum(md.nRetained), sum(md.nRejected), ...
        nnz(md.nRetained == 0), nnz(md.nRetained == 1), nnz(md.nRetained > 1), ...
        nnz(md.overlap > 0), nnz(wd.conflictBasins > 0), ...
        nnz(c), nnz(c) / numel(c), numel(nonEmpty), nSlices - numel(nonEmpty), firstSlice, lastSlice, ...
        nnz(headMasks{n}) - nnz(c), sum(wd.addedByFilling), nnz(areaRatio(:, n) < 0.95)};
end
summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'Modality', 'Noise', 'CandidateAVoxels', 'TotalMaxima', 'RetainedMaxima', 'RejectedMaxima', ...
     'SlicesZeroMarkers', 'SlicesOneMarker', 'SlicesMultipleMarkers', 'OverlapSlices', 'ConflictSlices', ...
     'Exp009Voxels', 'Exp009Fraction', 'NonEmptySlices', 'EmptySlices', 'FirstNonEmpty', 'LastNonEmpty', ...
     'RemovedVsCandidateA', 'AddedByFilling', 'SlicesRatioBelow095'});
disp(summary);

intersectionOverUnion = nnz(candidates{1} & candidates{2}) / nnz(candidates{1} | candidates{2});
fprintf('EXP-009 consistency (pn0 vs pn3): IoU = %.4f, differing voxels = %.4f %%\n\n', ...
    intersectionOverUnion, 100 * nnz(xor(candidates{1}, candidates{2})) / numel(candidates{1}));

writetable(summary, fullfile(cfg.paths.metrics, 'exp009_reconstruction_markers_summary.csv'));
perSlice = table((1:nSlices)', ...
    markerDiags{1}.nMaxima, markerDiags{1}.nRetained, markerDiags{1}.nRejected, areaRatio(:, 1), ...
    markerDiags{2}.nMaxima, markerDiags{2}.nRetained, markerDiags{2}.nRejected, areaRatio(:, 2), ...
    'VariableNames', {'k', 'pn0_nMaxima', 'pn0_nRetained', 'pn0_nRejected', 'pn0_areaRatioToA', ...
                      'pn3_nMaxima', 'pn3_nRetained', 'pn3_nRejected', 'pn3_areaRatioToA'});
writetable(perSlice, fullfile(cfg.paths.metrics, 'exp009_reconstruction_markers_per_slice.csv'));


%% Figure (diagnostica dell'algoritmo, nessuna sovrapposizione finale alla MRI)

% 1. Rapporto d'area rispetto ad A, EXP-009 contro EXP-008, su tutte le slice
fig1 = figure('Color', 'w');
ax = axes('Parent', fig1);
ratio008 = zeros(nSlices, 2);
for n = 1:2
    ratio008(:, n) = squeeze(sum(exp008Candidates{n}, [1 2])) ./ max(squeeze(sum(headMasks{n}, [1 2])), 1);
end
plot(ax, 1:nSlices, ratio008(:, 1), 'Color', [0.6 0.6 1], 'LineStyle', '-');
hold(ax, 'on');
plot(ax, 1:nSlices, areaRatio(:, 1), 'b-', 1:nSlices, areaRatio(:, 2), 'r--');
hold(ax, 'off');
legend(ax, 'pn0 EXP-008', 'pn0 EXP-009', 'pn3 EXP-009', 'Location', 'south');
xlabel(ax, 'axial slice k'); ylabel(ax, 'candidate area / candidate A area');
title(ax, 'EXP-009 vs EXP-008 - area ratio to head support per slice (all slices)');
xlim(ax, [1 nSlices]); ylim(ax, [0 1.05]);
fig1.Position(3:4) = [900 420];
exportgraphics(fig1, fullfile(cfg.paths.figures, 'exp009_area_ratio_per_slice.png'));

% 2. Per pn0 e pn3: A / immagine preparata / massimi / marker accettati /
%    marker non-cervello / candidato
for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 6, numel(displaySlices), 'TileSpacing', 'compact');
    title(layout, sprintf('EXP-009 %s - A / marker preparation / regional maxima / accepted markers / non-brain marker / EXP-009', ...
        noiseLevels(n)), 'Interpreter', 'none');
    rowNames = ["A", "prepared", "maxima", "accepted", "non-brain", "EXP-009"];
    for r = 1:6
        for s = 1:numel(displaySlices)
            k = displaySlices(s);
            sliceImage = volumes{n}(:, :, k);
            switch r
                case 1, panel = headMasks{n}(:, :, k); limits = [0 1];
                case 2, panel = preparedSlice(sliceImage, reconstructionElement, connectivity); limits = [0 1];
                case 3, panel = imregionalmax(preparedSlice(sliceImage, reconstructionElement, connectivity), connectivity); limits = [0 1];
                case 4, panel = foregroundMarkers{n}(:, :, k); limits = [0 1];
                case 5, panel = nonBrainMarkers{n}(:, :, k); limits = [0 1];
                case 6, panel = candidates{n}(:, :, k); limits = [0 1];
            end
            ax = nexttile(layout);
            imagesc(ax, double(panel).');
            colormap(ax, gray);
            clim(ax, limits);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('%s  k = %d', rowNames(r), k));
        end
    end
    fig.Position(3:4) = [1300 1600];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp009_%s_markers_and_candidate.png', noiseLevels(n))));
end


%% Salvataggio ed esito dei controlli

for n = 1:2
    mask = candidates{n};
    foregroundMarker = foregroundMarkers{n};
    method = 'EXP-009: foreground markers = imregionalmax(closing-by-reconstruction(opening-by-reconstruction(I, square 3), square 3), 8) components not touching the EXP-008 non-brain marker; watershed on 3x3 morphological gradient of I with imimposemin; union of foreground-touched basins AND candidate A; imfill holes';
    save(fullfile(cfg.paths.processedData, ...
        sprintf('exp009_reconstruction_%s_%s_support_mask.mat', lower(modality), noiseLevels(n))), ...
        'mask', 'foregroundMarker', 'method');
end

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-42s %s\n', checks{c, 1}, result);
end
fprintf('\nEXP-009 CHECKS: PASS\n');


function prepared = preparedSlice(sliceImage, element, connectivity)
%PREPAREDSLICE Stessa preparazione di reconstructionRegionalMaxMarkers (solo per le figure).
    opened = imreconstruct(imerode(sliceImage, element), sliceImage, connectivity);
    prepared = imcomplement(imreconstruct( ...
        imcomplement(imdilate(opened, element)), imcomplement(opened), connectivity));
end
