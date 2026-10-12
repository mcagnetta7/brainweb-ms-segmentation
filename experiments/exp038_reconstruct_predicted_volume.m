%% EXP-038 (fase 71): ricomposizione del volume predetto completo M_pred
% Fase di rappresentazione: le 181 slice assiali della previsione mantenuta
% (maschere della fase 65: EXP-026 + apertura 2D square3, NESSUN filtro
% sulle componenti, perché EXP-036 è stato respinto nella fase 70) vengono
% ricomposte esplicitamente nel volume logico M_pred(x,y,z).
%   - M_pred deve coincidere voxel per voxel e slice per slice con la fonte
%   - nessuna segmentazione nuova, nessun GT, nessuna metrica, nessuna
%     componente connessa (2D o 3D), nessuna morfologia o soglia
%   - solo pn0 + pn3.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
nSlices = expectedSize(3);
displaySlices = [1 46 91 136 181];
sourceFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase65_t2_%s_selected_opening_candidate.mat', noise));
outputFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));

% Decisione della fase 70: EXP-036 respinto, pipeline senza filtro
decisionFile = fullfile(cfg.paths.metrics, 'exp037_phase70_decision.csv');
checks = {"Phase-70 decision CSV exists", isfile(decisionFile)};
if ~isfile(decisionFile)
    error('exp038:technicallyBlocked', 'EXP-038 TECHNICALLY BLOCKED: missing Phase-70 decision.');
end
phase70 = readtable(decisionFile, 'TextType', 'string');
phase70Ok = phase70.phase70Decision == "REJECT_AREA9_FILTER" && ~phase70.smallLesionProtectionPassed;
checks(end+1, :) = {"Phase 70: REJECT_AREA9_FILTER, protection not passed", phase70Ok};
if ~phase70Ok
    error('exp038:technicallyBlocked', 'EXP-038 TECHNICALLY BLOCKED: Phase-70 decision not reproduced.');
end

sources = cell(1, 2);
volumes = cell(1, 2);
summaryRows = cell(2, 1);
sliceTables = cell(1, 2);


%% 1. Ricomposizione per condizione

for n = 1:2
    noise = noiseLevels(n);
    checks(end+1, :) = {noise + " Phase-65 source exists", isfile(sourceFile(noise))}; %#ok<SAGROW>
    if ~isfile(sourceFile(noise))
        error('exp038:technicallyBlocked', 'EXP-038 TECHNICALLY BLOCKED: missing %s (no fallback).', sourceFile(noise));
    end
    vars = whos('-file', sourceFile(noise));
    saved = load(sourceFile(noise), 'candidateMask', 'metadata');
    sourceMask = saved.candidateMask;
    md = saved.metadata;
    sourceCopy = sourceMask;
    inputChecks = {
        noise + " candidateMask present, logical, 181x217x181", any(strcmp({vars.name}, 'candidateMask')) && ...
                                                               islogical(sourceMask) && isequal(size(sourceMask), expectedSize)
        noise + " Phase 65 / EXP-032 / EXP-026",               md.phase == 65 && md.sourceExperiment == "EXP-032" && ...
                                                               md.candidateGenerationSource == "EXP-026"
        noise + " opening square3 / square / 3, 2D, not frozen", md.operation == "opening" && ...
                                                               md.selectedStructuringElementCandidate == "square3" && ...
                                                               md.structuringElementShape == "square" && ...
                                                               md.structuringElementParameter == 3 && ...
                                                               md.processingDimensionality == "2D axial slice-wise" && ...
                                                               ~md.finalPipelineFrozen
        noise + " source is not the rejected EXP-036 file",    ~contains(string(sourceFile(noise)), "exp036")
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('exp038:technicallyBlocked', 'EXP-038 TECHNICALLY BLOCKED: invalid source for %s.', noise);
    end

    % Slice assiali esplicite -> volume
    sliceMasks = cell(nSlices, 1);
    for k = 1:nSlices
        sliceMasks{k} = sourceMask(:, :, k);
    end
    M_pred = assemblePredictedVolume(sliceMasks);

    sliceOk = false(nSlices, 1);
    sourceVoxels = zeros(nSlices, 1);
    reconstructedVoxels = zeros(nSlices, 1);
    for k = 1:nSlices
        sliceOk(k) = isequal(M_pred(:, :, k), sourceMask(:, :, k)) && isequal(sliceMasks{k}, M_pred(:, :, k));
        sourceVoxels(k) = nnz(sourceMask(:, :, k));
        reconstructedVoxels(k) = nnz(M_pred(:, :, k));
    end
    nonEmpty = find(sourceVoxels > 0);
    nonEmptyRec = find(reconstructedVoxels > 0);
    checks = [checks; {
        noise + " exactly 181 logical 181x217 slice masks",  numel(sliceMasks) == nSlices && ...
                                                             all(cellfun(@(s) islogical(s) && isequal(size(s), expectedSize(1:2)), sliceMasks))
        noise + " M_pred logical 181x217x181",               islogical(M_pred) && isequal(size(M_pred), expectedSize)
        noise + " M_pred exactly equals Phase-65 source",    isequal(M_pred, sourceMask)
        noise + " every slice identical, order preserved",   all(sliceOk)
        noise + " voxel count preserved (none added/removed)", nnz(M_pred) == nnz(sourceMask) && ...
                                                             ~any(xor(M_pred, sourceMask), 'all')
        noise + " empty / non-empty slices and range preserved", isequal(nonEmpty, nonEmptyRec)
        noise + " source mask unchanged",                    isequal(sourceMask, sourceCopy)
        }]; %#ok<AGROW>

    metadata = struct('phase', 71, 'experiment', "EXP-038", 'condition', noise, ...
        'source', "Phase-65 selected opening candidate", 'sourceFile', string(sourceFile(noise)), 'sourcePhase', 65, ...
        'sourceExperiment', "EXP-032", 'candidateGenerationSource', "EXP-026", 'morphology', "standard 2D opening", ...
        'selectedStructuringElement', "square3", 'componentFiltering', "none", ...
        'rejectedComponentFilterExperiment', "EXP-036", 'phase70DecisionExperiment', "EXP-037", ...
        'phase70Decision', "REJECT_AREA9_FILTER", 'assembly', "axial slice-wise concatenation", ...
        'numberOfSlices', nSlices, 'volumeSize', expectedSize, 'outputVariable', "M_pred", 'outputClass', "logical", ...
        'gtUsed', false, 'threeDimensionalConnectivityApplied', false, 'unique3DLesionsEstimated', false, ...
        'finalPipelineFrozen', false, ...
        'note', "Phase 71 assembles the currently retained Phase-65 slice-wise prediction into the complete 3D M_pred representation. No segmentation voxel is added, removed or modified.");
    save(outputFile(noise), 'M_pred', 'metadata');
    reloaded = load(outputFile(noise), 'M_pred', 'metadata');
    checks(end+1, :) = {noise + " saved M_pred reloads identically, Phase 71 / EXP-038 metadata", ...
        isequal(reloaded.M_pred, M_pred) && reloaded.metadata.phase == 71 && reloaded.metadata.experiment == "EXP-038" && ...
        reloaded.metadata.componentFiltering == "none" && reloaded.metadata.rejectedComponentFilterExperiment == "EXP-036"}; %#ok<SAGROW>

    summaryRows{n} = {noise, 65, "EXP-032", nSlices, size(M_pred, 1), size(M_pred, 2), size(M_pred, 3), nnz(M_pred), ...
        numel(nonEmpty), nSlices - numel(nonEmpty), nonEmpty(1), nonEmpty(end), isequal(M_pred, sourceMask)};
    sliceTables{n} = table(repmat(noise, nSlices, 1), (1:nSlices).', sourceVoxels, reconstructedVoxels, sliceOk, ...
        'VariableNames', {'condition', 'slice', 'sourceVoxels', 'reconstructedVoxels', 'exactSliceIdentity'});
    sources{n} = sourceMask;
    volumes{n} = M_pred;
end

summary = cell2table(vertcat(summaryRows{:}), 'VariableNames', {'condition', 'sourcePhase', 'sourceExperiment', ...
    'numberOfSlices', 'rows', 'columns', 'depth', 'predictedVoxels', 'nonEmptySlices', 'emptySlices', ...
    'firstNonEmptySlice', 'lastNonEmptySlice', 'exactIdentityWithSource'});
bySlice = [sliceTables{1}; sliceTables{2}];
checks(end+1, :) = {"per-slice table: 362 rows, all identical", height(bySlice) == 2 * nSlices && all(bySlice.exactSliceIdentity)};
writetable(summary, fullfile(cfg.paths.metrics, 'exp038_predicted_volume_summary.csv'));
writetable(bySlice, fullfile(cfg.paths.metrics, 'exp038_predicted_volume_by_slice.csv'));
disp(summary);


%% 2. Figura di integrità (sorgente / M_pred / differenza)

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 3, numel(displaySlices), 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf('EXP-038 %s - Phase-65 source / reconstructed M_pred / xor difference (must be empty)', ...
        noiseLevels(n)), 'Interpreter', 'none');
    rowsToShow = {sources{n}, volumes{n}, xor(sources{n}, volumes{n})};
    rowNames = ["source", "M_pred", "xor"];
    for r = 1:3
        for k = displaySlices
            ax = nexttile(layout);
            imagesc(ax, rowsToShow{r}(:, :, k).', [0 1]);
            colormap(ax, gray);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('k=%d %s (%d)', k, rowNames(r), nnz(rowsToShow{r}(:, :, k))), 'FontSize', 7);
        end
    end
    fig.Position(3:4) = [1400 800];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp038_predicted_volume_identity_%s.png', noiseLevels(n))), ...
        'Resolution', 130);
end


%% Esito dei controlli

checks = [checks; {
    "source masks unchanged at the end", isequal(sources{1}, volumes{1}) && isequal(sources{2}, volumes{2})
    "config.m unchanged",                isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];
scriptText = fileread([mfilename('fullpath') '.m']);
functionText = fileread(fullfile(cfg.paths.segmentation, 'assemblePredictedVolume.m'));
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['loadBrainweb' 'GroundTruth('], ['bwconn' 'comp('], ['bwlabel' '('], ['region' 'props'], ...
    ['filterComponents' 'ByArea2D('], ['bwarea' 'open('], ['imopen' '('], ['imclose' '('], ['imerode' '('], ...
    ['imdilate' '('], ['imfill' '('], ['imreconstruct' '('], ['bwmorph' '('], ['multi' 'thresh('], ...
    ['imquantize' '('], ['gray' 'thresh('], ['imbinarize' '('], ['dice' 'Coefficient'], ['Development' 'Score =']};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};
checks(end+1, :) = {"no GT/metric/components/filter/morphology/threshold", ...
    ~any(cellfun(@(f) contains(scriptText, f) || contains(functionText, f), forbidden))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-66s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp038:checksFailed', 'EXP-038 checks failed.');
end
fprintf('\nEXP-038 CHECKS: PASS (%d)\n', size(checks, 1));
