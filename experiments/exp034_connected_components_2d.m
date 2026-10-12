%% EXP-034 (fase 67): identificazione delle componenti connesse 2D
% Scompone le maschere selezionate della fase 65 (EXP-026 + apertura
% standard square3, mantenuta nella fase 66) in componenti connesse 2D,
% slice assiale per slice, con bwconncomp e connettività 8 esplicita.
%   - nessuna modifica della maschera, nessun filtraggio, nessuna proprietà
%     (nessun regionprops, nessuna dimensione dei componenti): fase 68
%   - nessun ground truth, nessun Dice
%   - componenti 2D indipendenti per slice: il loro totale NON è il numero
%     di lesioni 3D uniche (componenti 3D: fase 72)
%   - solo pn0 + pn3.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

connectivity = 8;                                % scelta di progetto fissata a priori
noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
nSlices = expectedSize(3);
fixedSlices = [46 91 102 136];
sourceFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase65_t2_%s_selected_opening_candidate.mat', noise));
outputFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase67_t2_%s_components2d.mat', noise));

checks = {"connectivity fixed to 8", connectivity == 8};
masks = cell(1, 2);
components = cell(1, 2);
counts = cell(1, 2);
volumes = cell(1, 2);
sliceRows = cell(1, 2);
summaryRows = cell(2, 1);


%% 1. Componenti 2D per ogni condizione

for n = 1:2
    noise = noiseLevels(n);
    checks(end+1, :) = {noise + " Phase-65 source exists", isfile(sourceFile(noise))}; %#ok<SAGROW>
    if ~isfile(sourceFile(noise))
        error('exp034:technicallyBlocked', 'EXP-034 TECHNICALLY BLOCKED: missing %s.', sourceFile(noise));
    end
    contents = whos('-file', sourceFile(noise));
    saved = load(sourceFile(noise), 'candidateMask', 'metadata');
    candidateMask = saved.candidateMask;
    md = saved.metadata;
    maskCopy = candidateMask;

    inputChecks = {
        noise + " candidateMask present, logical, 181x217x181", any(strcmp({contents.name}, 'candidateMask')) && ...
                                                               islogical(candidateMask) && isequal(size(candidateMask), expectedSize)
        noise + " metadata Phase 65 / EXP-032 / EXP-026",      md.phase == 65 && md.sourceExperiment == "EXP-032" && ...
                                                               md.candidateGenerationSource == "EXP-026"
        noise + " opening square3 / square / 3, 2D, not frozen", md.operation == "opening" && ...
                                                               md.selectedStructuringElementCandidate == "square3" && ...
                                                               md.structuringElementShape == "square" && ...
                                                               md.structuringElementParameter == 3 && ...
                                                               md.processingDimensionality == "2D axial slice-wise" && ...
                                                               ~md.finalPipelineFrozen
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('exp034:technicallyBlocked', 'EXP-034 TECHNICALLY BLOCKED: invalid source for %s.', noise);
    end

    [ccBySlice, numComponentsPerSlice] = extractConnectedComponents2D(candidateMask, connectivity);

    % Integrità: struttura, ricostruzione esatta, disgiunzione
    structureOk = numel(ccBySlice) == nSlices;
    reconstructOk = true;
    disjointOk = true;
    for k = 1:nSlices
        cc = ccBySlice{k};
        sliceMask = candidateMask(:, :, k);
        structureOk = structureOk && cc.Connectivity == 8 && isequal(cc.ImageSize, expectedSize(1:2)) && ...
            cc.NumObjects == numel(cc.PixelIdxList) && numComponentsPerSlice(k) == cc.NumObjects && ...
            (cc.NumObjects >= 1) == any(sliceMask(:));
        rebuilt = false(expectedSize(1:2));
        for i = 1:cc.NumObjects
            rebuilt(cc.PixelIdxList{i}) = true;
        end
        allIdx = vertcat(cc.PixelIdxList{:});
        reconstructOk = reconstructOk && isequal(rebuilt, sliceMask);
        disjointOk = disjointOk && numel(allIdx) == numel(unique(allIdx)) && numel(allIdx) == nnz(sliceMask);
    end
    total2DComponents = sum(numComponentsPerSlice);
    checks = [checks; {
        noise + " 181 CC structures, conn. 8, ImageSize 181x217",  structureOk
        noise + " PixelIdxList union reconstructs every slice",   reconstructOk
        noise + " components disjoint, cover all candidate pixels", disjointOk
        noise + " total2DComponents = sum(numComponentsPerSlice)", total2DComponents == sum(cellfun(@(c) c.NumObjects, ccBySlice))
        noise + " source mask unchanged",                          isequal(candidateMask, maskCopy)
        }]; %#ok<AGROW>

    metadata = struct('phase', 67, 'experiment', "EXP-034", 'condition', noise, ...
        'source', "Phase-65 selected opening candidate", 'sourceFile', string(sourceFile(noise)), ...
        'sourceExperiment', "EXP-032", 'candidateGenerationSource', "EXP-026", ...
        'morphology', "standard opening", 'selectedStructuringElement', "square3", ...
        'connectivity', connectivity, 'componentDimensionality', "2D axial slice-wise", ...
        'numberOfSlices', nSlices, 'gtUsed', false, 'componentFilteringApplied', false, ...
        'componentPropertiesComputed', false, 'unique3DLesionsEstimated', false, 'finalPipelineFrozen', false, ...
        'note', "Components are independent 2D slice-wise candidate regions. Their total count must not be interpreted as the number of unique 3D lesions.");
    save(outputFile(noise), 'ccBySlice', 'numComponentsPerSlice', 'metadata');
    reloaded = load(outputFile(noise), 'ccBySlice', 'numComponentsPerSlice');
    checks(end+1, :) = {noise + " saved components reload identically", ...
        isequal(reloaded.ccBySlice, ccBySlice) && isequal(reloaded.numComponentsPerSlice, numComponentsPerSlice)}; %#ok<SAGROW>

    candidateVoxels = squeeze(sum(candidateMask, [1 2]));
    sliceRows{n} = table(repmat(noise, nSlices, 1), (1:nSlices).', candidateVoxels, numComponentsPerSlice, ...
        candidateVoxels > 0, 'VariableNames', {'condition', 'slice', 'candidateVoxels', 'numComponents', ...
        'hasCandidateVoxels'});
    withComponents = find(numComponentsPerSlice > 0);
    summaryRows{n} = {noise, nSlices, numel(withComponents), nSlices - numel(withComponents), total2DComponents, ...
        min(numComponentsPerSlice), max(numComponentsPerSlice), mean(numComponentsPerSlice), ...
        median(numComponentsPerSlice), withComponents(1), withComponents(end)};

    masks{n} = candidateMask;
    components{n} = ccBySlice;
    counts{n} = numComponentsPerSlice;
    volumes{n} = prepare(loadBrainwebMri(cfg, "T2", noise));      % solo per le figure
end
checks(end+1, :) = {"same connectivity for pn0 and pn3", ...
    all(cellfun(@(c) c.Connectivity, components{1}) == 8) && all(cellfun(@(c) c.Connectivity, components{2}) == 8)};

bySlice = [sliceRows{1}; sliceRows{2}];
summary = cell2table(vertcat(summaryRows{:}), 'VariableNames', {'condition', 'numberOfSlices', ...
    'slicesWithCandidates', 'slicesWithoutCandidates', 'total2DComponents', 'minComponentsPerSlice', ...
    'maxComponentsPerSlice', 'meanComponentsPerSlice', 'medianComponentsPerSlice', 'firstComponentSlice', ...
    'lastComponentSlice'});
checks(end+1, :) = {"per-slice CSV has 362 rows", height(bySlice) == 2 * nSlices};
writetable(bySlice, fullfile(cfg.paths.metrics, 'exp034_components_by_slice.csv'));
writetable(summary, fullfile(cfg.paths.metrics, 'exp034_component_summary.csv'));
disp(summary);
fprintf(['NOTE: total2DComponents counts slice-wise component instances; it is NOT the number of unique ' ...
    'MS lesions.\n\n']);


%% 2. Figure

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 3, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, {sprintf('EXP-034 T2 %s - T2 / Phase-65 candidate mask / 2D 8-connected component labels', ...
        noiseLevels(n)), 'label colours are for display only (no identity across slices)'}, 'Interpreter', 'none');
    for k = fixedSlices
        labelMap = zeros(expectedSize(1:2));
        cc = components{n}{k};
        for i = 1:cc.NumObjects
            labelMap(cc.PixelIdxList{i}) = i;
        end
        panels = {grayOverlay(volumes{n}(:, :, k), false(expectedSize(1:2))), ...
            grayOverlay(volumes{n}(:, :, k), masks{n}(:, :, k)), labelRgb(labelMap)};
        names = ["T2", "candidates", sprintf("%d components", cc.NumObjects)];
        for p = 1:3
            ax = nexttile(layout);
            image(ax, panels{p});
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('k=%d %s', k, names(p)), 'FontSize', 8);
        end
    end
    fig.Position(3:4) = [1000 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp034_components2d_%s.png', noiseLevels(n))), ...
        'Resolution', 150);
end

fig = figure('Color', 'w');
ax = axes(fig);
plot(ax, 1:nSlices, counts{1}, 'b-', 1:nSlices, counts{2}, 'r-');
xlabel(ax, 'axial slice k');
ylabel(ax, 'number of 2D components (NumObjects)');
legend(ax, 'pn0', 'pn3', 'Location', 'northwest');
title(ax, 'EXP-034 - 2D 8-connected candidate components per axial slice (descriptive)');
xlim(ax, [1 nSlices]);
grid(ax, 'on');
fig.Position(3:4) = [1000 450];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp034_component_count_by_slice.png'));


%% Esito dei controlli

checks(end+1, :) = {"config.m unchanged", isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)};
scriptText = fileread([mfilename('fullpath') '.m']);
functionText = fileread(fullfile(cfg.paths.segmentation, 'extractConnectedComponents2D.m'));
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['region' 'props('], ['region' 'props3('],['bwarea' 'open('], ['loadBrainweb' 'GroundTruth('], ['imopen' '('], ...
    ['imclose' '('], ['imerode' '('], ['imdilate' '('], ['imfill' '('], ['imreconstruct' '('], ['bwmorph' '('], ...
    ['multi' 'thresh('], ['imquantize' '('], ['gray' 'thresh('], ['imbinarize' '('], ['bwconn' 'comp(candidate' 'Mask']};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};
checks(end+1, :) = {"no GT/regionprops/filter/morphology/threshold/3D CC", ...
    ~any(cellfun(@(f) contains(scriptText, f) || contains(functionText, f), forbidden))};
checks(end+1, :) = {"bwconncomp receives single 2D slices only", ...
    contains(functionText, ['bwconn' 'comp(slice' 'Mask, connectivity)']) && ~contains(scriptText, ['bwconn' 'comp('])};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-58s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp034:checksFailed', 'EXP-034 checks failed.');
end
fprintf('\nEXP-034 CHECKS: PASS (%d)\n', size(checks, 1));


function rgb = grayOverlay(sliceImage, maskSlice)
%GRAYOVERLAY T2 in scala di grigi con la maschera in rosso (solo visualizzazione).
    gray = sliceImage.';
    m = maskSlice.';
    red = gray; green = gray; blue = gray;
    red(m) = 1; green(m) = 0; blue(m) = 0;
    rgb = cat(3, red, green, blue);
end

function rgb = labelRgb(labelMap)
%LABELRGB Etichette 2D a colori ciclici su fondo nero (solo visualizzazione).
    palette = [0 0 0; lines(7)];
    idx = labelMap.';
    idx(idx > 0) = mod(idx(idx > 0) - 1, 7) + 1;
    rgb = reshape(palette(idx + 1, :), [size(idx) 3]);
end
