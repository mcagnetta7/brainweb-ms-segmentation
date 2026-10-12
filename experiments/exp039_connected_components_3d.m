%% EXP-039 (fase 72): componenti connesse 3D del volume predetto completo
% Rappresenta i voxel di M_pred (fase 71: EXP-026 + apertura 2D square3,
% nessun filtro sulle componenti) come componenti 3D 26-connesse, con UNA
% chiamata bwconncomp sull'intero volume. M_pred non viene modificato.
%   - connettività 26 fissata a priori senza GT (analogo volumetrico
%     dell'intorno 2D a 8; voxel isotropi da 1 mm)
%   - estensione volumetrica, specifica del progetto, del concetto di
%     componenti connesse del corso (mostrato in 2D)
%   - descrittori minimi da PixelIdxList + ind2sub (nessun regionprops3)
%   - nessun GT, nessuna metrica, nessun filtraggio, nessuna morfologia o
%     soglia; le componenti sono CANDIDATI, non lesioni confermate
%   - solo pn0 + pn3.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

connectivity = 26;                               % preregistrata
noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
nSlices = expectedSize(3);
fixedSlices = [46 91 102 136];
sourceFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));
outputFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase72_t2_%s_components3d.mat', noise));
summary034 = readtable(fullfile(cfg.paths.metrics, 'exp034_component_summary.csv'), 'TextType', 'string');

checks = {"connectivity fixed to 26 before analysis", connectivity == 26};
volumes = cell(1, 2);
components = cell(1, 2);
tables = cell(1, 2);
summaryRows = cell(2, 1);
sliceTables = cell(1, 2);
bwCalls = 0;


%% 1. Componenti 3D per condizione

for n = 1:2
    noise = noiseLevels(n);
    checks(end+1, :) = {noise + " Phase-71 artifact exists", isfile(sourceFile(noise))}; %#ok<SAGROW>
    if ~isfile(sourceFile(noise))
        error('exp039:technicallyBlocked', 'EXP-039 TECHNICALLY BLOCKED: missing %s.', sourceFile(noise));
    end
    vars = whos('-file', sourceFile(noise));
    saved = load(sourceFile(noise), 'M_pred', 'metadata');
    M_pred = saved.M_pred;
    md = saved.metadata;
    predCopy = M_pred;
    inputChecks = {
        noise + " M_pred present, logical, 181x217x181",        any(strcmp({vars.name}, 'M_pred')) && islogical(M_pred) && ...
                                                                isequal(size(M_pred), expectedSize)
        noise + " metadata Phase 71 / EXP-038 / source 65 EXP-032", md.phase == 71 && md.experiment == "EXP-038" && ...
                                                                md.sourcePhase == 65 && md.sourceExperiment == "EXP-032"
        noise + " EXP-026 + square3, no component filtering",   md.candidateGenerationSource == "EXP-026" && ...
                                                                md.selectedStructuringElement == "square3" && md.componentFiltering == "none"
        noise + " EXP-036 rejected (REJECT_AREA9_FILTER)",       md.rejectedComponentFilterExperiment == "EXP-036" && ...
                                                                md.phase70Decision == "REJECT_AREA9_FILTER"
        noise + " no GT, no prior 3D connectivity, not frozen",  ~md.gtUsed && ~md.threeDimensionalConnectivityApplied && ...
                                                                ~md.unique3DLesionsEstimated && ~md.finalPipelineFrozen
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('exp039:technicallyBlocked', 'EXP-039 TECHNICALLY BLOCKED: invalid M_pred for %s.', noise);
    end

    CC3D = extractConnectedComponents3D(M_pred, connectivity);   % una sola chiamata sul volume intero
    bwCalls = bwCalls + 1;

    % Tabella minima da PixelIdxList + ind2sub; ricostruzione e disgiunzione
    nObj = CC3D.NumObjects;
    voxelCount = zeros(nObj, 1); firstSlice = zeros(nObj, 1); lastSlice = zeros(nObj, 1); occupied = zeros(nObj, 1);
    rebuilt = false(expectedSize);
    componentsPerSlice = zeros(nSlices, 1);
    validIdx = true;
    for i = 1:nObj
        idx = CC3D.PixelIdxList{i};
        validIdx = validIdx && ~isempty(idx) && all(idx >= 1 & idx <= prod(expectedSize));
        [~, ~, z] = ind2sub(expectedSize, idx);
        zs = unique(z);
        voxelCount(i) = numel(idx);
        firstSlice(i) = min(z); lastSlice(i) = max(z); occupied(i) = numel(zs);
        componentsPerSlice(zs) = componentsPerSlice(zs) + 1;
        rebuilt(idx) = true;
    end
    allIdx = vertcat(CC3D.PixelIdxList{:});
    sliceSpan = lastSlice - firstSlice + 1;
    componentTable = table(repmat(noise, nObj, 1), (1:nObj).', voxelCount, firstSlice, lastSlice, sliceSpan, occupied, ...
        'VariableNames', {'condition', 'component3DIndex', 'voxelCount', 'firstSlice', 'lastSlice', 'sliceSpan', ...
        'occupiedSliceCount'});
    checks = [checks; {
        noise + " CC3D connectivity 26, ImageSize 181x217x181",    CC3D.Connectivity == 26 && isequal(CC3D.ImageSize, expectedSize)
        noise + " NumObjects = numel(PixelIdxList) >= 1",          nObj == numel(CC3D.PixelIdxList) && nObj >= 1
        noise + " every PixelIdxList non-empty with valid indices", validIdx
        noise + " PixelIdxList sets mutually disjoint",            numel(allIdx) == numel(unique(allIdx))
        noise + " union of PixelIdxList reconstructs M_pred exactly", isequal(rebuilt, M_pred)
        noise + " sum voxelCount = nnz(M_pred)",                   sum(voxelCount) == nnz(M_pred)
        noise + " slice descriptors consistent",                   all(firstSlice >= 1 & lastSlice <= nSlices & ...
                                                                   firstSlice <= lastSlice & occupied >= 1 & occupied <= sliceSpan)
        noise + " occupiedSliceCount == sliceSpan (no z gaps)",    all(occupied == sliceSpan)   % una componente connessa non salta slice
        noise + " M_pred unchanged",                               isequal(M_pred, predCopy)
        }]; %#ok<AGROW>

    metadata = struct('phase', 72, 'experiment', "EXP-039", 'condition', noise, ...
        'source', "Phase-71 canonical M_pred", 'sourceFile', string(sourceFile(noise)), 'sourcePhase', 71, ...
        'sourceExperiment', "EXP-038", 'candidateGenerationSource', "EXP-026", ...
        'morphology', "standard 2D opening square3", 'componentFiltering', "none", ...
        'analysisType', "3D connected components", 'connectivity', connectivity, 'dimensionality', "3D volumetric", ...
        'gtUsed', false, 'predictionModified', false, 'componentFilteringApplied', false, 'regionprops3Used', false, ...
        'courseTechnique', "connected components / bwconncomp", 'course3DExtension', true, ...
        'courseExplicitlyCovers26Connectivity', false, 'unique3DLesionsConfirmed', false, 'finalPipelineFrozen', false, ...
        'note', "26-connected 3D candidate components of M_pred; candidate objects, not confirmed MS lesions.");
    save(outputFile(noise), 'CC3D', 'componentTable', 'metadata');
    reloaded = load(outputFile(noise), 'CC3D', 'componentTable');
    checks(end+1, :) = {noise + " saved CC3D and component table reload identically", ...
        isequal(reloaded.CC3D, CC3D) && isequal(reloaded.componentTable, componentTable) && height(componentTable) == nObj}; %#ok<SAGROW>

    oneSlice = occupied == 1;
    summaryRows{n} = {noise, connectivity, nnz(M_pred), summary034.total2DComponents(summary034.condition == noise), nObj, ...
        nnz(oneSlice), nnz(~oneSlice), nnz(oneSlice) / nObj, nnz(~oneSlice) / nObj, min(voxelCount), median(voxelCount), ...
        mean(voxelCount), max(voxelCount), min(occupied), median(occupied), mean(occupied), max(occupied), ...
        max(sliceSpan), isequal(rebuilt, M_pred)};
    sliceTables{n} = table(repmat(noise, nSlices, 1), (1:nSlices).', squeeze(sum(M_pred, [1 2])), componentsPerSlice, ...
        'VariableNames', {'condition', 'slice', 'foregroundVoxels', 'numberOf3DComponentsPresent'});
    volumes{n} = M_pred;
    components{n} = CC3D;
    tables{n} = componentTable;
end
checks(end+1, :) = {"bwconncomp called once per complete volume, same conn. pn0/pn3", bwCalls == 2 && ...
    components{1}.Connectivity == components{2}.Connectivity};

summary = cell2table(vertcat(summaryRows{:}), 'VariableNames', {'condition', 'connectivity', 'predictedVoxels', ...
    'phase67Total2DComponents', 'total3DComponents', 'singleSliceComponents', 'multiSliceComponents', ...
    'fractionSingleSliceComponents', 'fractionMultiSliceComponents', 'minVoxelCount', 'medianVoxelCount', ...
    'meanVoxelCount', 'maxVoxelCount', 'minOccupiedSliceCount', 'medianOccupiedSliceCount', ...
    'meanOccupiedSliceCount', 'maxOccupiedSliceCount', 'maxSliceSpan', 'exactReconstruction'});
writetable([tables{1}; tables{2}], fullfile(cfg.paths.metrics, 'exp039_components3d.csv'));
writetable(summary, fullfile(cfg.paths.metrics, 'exp039_components3d_summary.csv'));
writetable([sliceTables{1}; sliceTables{2}], fullfile(cfg.paths.metrics, 'exp039_components3d_by_slice.csv'));
disp(summary);
fprintf(['NOTE: the reported 3D components are predicted candidate objects. Their count must not be ' ...
    'interpreted as the number of confirmed MS lesions.\n\n']);


%% 2. Figure

for n = 1:2
    labelVolume = zeros(expectedSize, 'uint16');           % solo visualizzazione (transitorio)
    for i = 1:components{n}.NumObjects
        labelVolume(components{n}.PixelIdxList{i}) = i;
    end

    % Proiezioni ortogonali delle etichette (massimo lungo ciascun asse)
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact');
    title(layout, {sprintf('EXP-039 %s - 26-connected 3D candidate components (maximum-label projections)', ...
        noiseLevels(n)), 'colours for display only; component indices carry no lesion identity'}, 'Interpreter', 'none');
    projections = {squeeze(max(labelVolume, [], 3)), squeeze(max(labelVolume, [], 2)), squeeze(max(labelVolume, [], 1))};
    names = ["axial (max over z)", "projection over y", "projection over x"];
    for p = 1:3
        ax = nexttile(layout);
        image(ax, labelRgb(double(projections{p}).'));
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, names(p), 'FontSize', 9);
    end
    fig.Position(3:4) = [1400 500];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp039_components3d_%s.png', noiseLevels(n))), 'Resolution', 130);

    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 2, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf('EXP-039 %s - M_pred / 3D component labels intersecting the slice', noiseLevels(n)), ...
        'Interpreter', 'none');
    for k = fixedSlices
        ax = nexttile(layout);
        imagesc(ax, volumes{n}(:, :, k).', [0 1]); colormap(ax, gray);
        axis(ax, 'image'); set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('k=%d M_pred', k), 'FontSize', 8, 'Interpreter', 'none');
        ax = nexttile(layout);
        labelsHere = double(labelVolume(:, :, k));
        image(ax, labelRgb(labelsHere.'));
        axis(ax, 'image'); set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('k=%d %d 3D components', k, numel(unique(labelsHere(labelsHere > 0)))), 'FontSize', 8);
    end
    fig.Position(3:4) = [700 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp039_components3d_slices_%s.png', noiseLevels(n))), ...
        'Resolution', 130);
end

fig = figure('Color', 'w');
ax = axes(fig);
semilogy(ax, sort(tables{1}.voxelCount), 'b-'); hold(ax, 'on');
semilogy(ax, sort(tables{2}.voxelCount), 'r-'); hold(ax, 'off');
xlabel(ax, 'component rank (ascending voxel count)'); ylabel(ax, 'voxel count (log scale)');
legend(ax, 'pn0', 'pn3', 'Location', 'northwest'); grid(ax, 'on');
title(ax, 'EXP-039 - sorted voxel count of 3D candidate components (descriptive, no cutoff)');
fig.Position(3:4) = [900 450];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp039_component3d_voxelcount_rank.png'));

fig = figure('Color', 'w');
ax = axes(fig);
plot(ax, sort(tables{1}.occupiedSliceCount), 'b-'); hold(ax, 'on');
plot(ax, sort(tables{2}.occupiedSliceCount), 'r-'); hold(ax, 'off');
xlabel(ax, 'component rank'); ylabel(ax, 'occupied slices');
legend(ax, 'pn0', 'pn3', 'Location', 'northwest'); grid(ax, 'on');
title(ax, 'EXP-039 - sorted occupied-slice count of 3D candidate components (descriptive)');
fig.Position(3:4) = [900 450];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp039_component3d_slice_span_rank.png'));


%% Esito dei controlli

checks(end+1, :) = {"config.m unchanged", isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)};
scriptText = fileread([mfilename('fullpath') '.m']);
functionText = fileread(fullfile(cfg.paths.segmentation, 'extractConnectedComponents3D.m'));
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['loadBrainweb' 'GroundTruth('], ['region' 'props3('], ['region' 'props('], ['filterComponents' 'ByArea2D('], ...
    ['bwarea' 'open('], ['imopen' '('], ['imclose' '('], ['imerode' '('], ['imdilate' '('], ['imfill' '('], ...
    ['imreconstruct' '('], ['bwmorph' '('], ['multi' 'thresh('], ['imquantize' '('], ['gray' 'thresh('], ...
    ['imbinarize' '('], ['dice' 'Coefficient'], ['bwconn' 'comp(']};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};
checks(end+1, :) = {"no GT/regionprops3/filter/morphology/threshold/metric in script", ...
    ~any(cellfun(@(f) contains(scriptText, f), forbidden))};
checks(end+1, :) = {"function: bwconncomp on the whole volume only, no regionprops3", ...
    contains(functionText, ['bwconn' 'comp(M_pred, connectivity)']) && ~contains(functionText, ['region' 'props3('])};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-66s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp039:checksFailed', 'EXP-039 checks failed.');
end
fprintf('\nEXP-039 CHECKS: PASS (%d)\n', size(checks, 1));


function rgb = labelRgb(labelMap)
%LABELRGB Etichette a colori ciclici su fondo nero (solo visualizzazione).
    palette = [0 0 0; lines(7)];
    idx = labelMap;
    idx(idx > 0) = mod(idx(idx > 0) - 1, 7) + 1;
    rgb = reshape(palette(idx + 1, :), [size(idx) 3]);
end
