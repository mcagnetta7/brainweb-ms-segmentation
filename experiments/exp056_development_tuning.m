%% EXP-056 (fase 95): tuning finale solo su dati di sviluppo
% Griglia preregistrata di 24 configurazioni (P x T x M x G) su T2, pn0 e pn3:
%   P0 nessun filtro | P1 gaussiano sigma 0.5, 3x3, replicate
%   T2 multithresh N=2, classe 3 | T3 multithresh N=3, classe 4
%   M0 nessuna | M1 apertura diamond 1 | M2 apertura square 3 (2D per slice)
%   G0 nessuna | G1 rimozione delle componenti 3D (26) su una sola slice
% SEZIONE 1: tutte le 48 predizioni generate e salvate SENZA GT.
% SEZIONE 2: verifica dei file e riproduzione esatta della baseline (fase 71).
% SEZIONE 3: GT caricato solo ora.  SEZIONE 4: Dice a volume completo,
% DevelopmentScore = (Dice_pn0 + Dice_pn3)/2, classifica (fase 37, nessuna
% tolleranza).  SEZIONI 5-6: vincitore e diagnostiche post-selezione (non
% cambiano la scelta).  Nessun dato held-out; config.m invariato.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
fixedSlices = [46 91 102 136];
candidateDir = fullfile(cfg.paths.processedData, 'phase95_candidates');
candidateFile = @(id, noise) fullfile(candidateDir, sprintf('exp056_%s_%s.mat', id, noise));
selectedFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase95_t2_%s_selected_prediction.mat', noise));
maskFile = @(noise) fullfile(cfg.paths.processedData, sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));
phase71File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));
phase91File = fullfile(cfg.paths.metrics, 'exp052_complete_3d_metrics.csv');
phase94File = fullfile(cfg.paths.metrics, 'exp055_gt_lesion_size_analysis.csv');
priorArtifacts = [string(phase91File), fullfile(cfg.paths.metrics, ["exp053_slice_wise_metrics.csv" ...
    "exp054_lesion_wise_summary.csv" "exp054_gt_lesion_status.csv" "exp055_size_class_summary.csv" ...
    "exp055_gt_lesion_size_analysis.csv"]), string(phase71File("pn0")), string(phase71File("pn3"))];
prepare = @(raw) normalizeFixedRange(convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, cfg.preprocessing.normalization.outputRange);
checks = cell(0, 2);
gtLoaded = false;


%% 0. Ingressi

helperFiles = [fullfile(cfg.paths.preprocessing, "gaussianFilterSlices.m"), ...
    fullfile(cfg.paths.segmentation, ["generateLesionCandidateMask.m" "generatePhase95Prediction.m" ...
    "removeSingleSliceComponents3D.m"]), fullfile(cfg.paths.evaluation, ["computeVoxelConfusion.m" ...
    "computeLesionWiseMatches.m"])];
required = [priorArtifacts, string(maskFile("pn0")), string(maskFile("pn3")), helperFiles, ...
    string(cfg.dataset.mriFiles.T2), string(cfg.dataset.noisyMriFiles.pn3.T2)];
for f = required
    if ~isfile(f)
        error('exp056:technicallyBlocked', 'PHASE 95 TECHNICALLY BLOCKED: missing %s', f);
    end
end
priorBefore = arrayfun(@fileState, priorArtifacts, 'UniformOutput', false);
checks(end+1, :) = {"required MRI, brain masks, Phase-71 / 91-94 artifacts and helpers exist", true};


%% 1. Generazione delle 48 predizioni (NESSUN GT)

pChoices = struct('code', {"P0", "P1"}, 'enabled', {false, true});
tChoices = struct('code', {"T2", "T3"}, 'n', {2, 3});
mChoices = struct('code', {"M0", "M1", "M2"}, 'type', {"none", "diamond", "square"}, 'param', {0, 1, 3});
gChoices = struct('code', {"G0", "G1"}, 'filter', {"none", "minOccupiedSlices"});
configs = struct([]);
for p = pChoices
    for t = tChoices
        for m = mChoices
            for g = gChoices
                c = struct('id', p.code + "_" + t.code + "_" + m.code + "_" + g.code, 'gaussianEnabled', p.enabled, ...
                    'gaussianSigma', 0.5, 'gaussianFilterSize', 3, 'gaussianPadding', "replicate", ...
                    'numberOfThresholds', t.n, 'selectedHighestClass', t.n + 1, 'openingType', m.type, ...
                    'openingParameter', m.param, 'componentFilter', g.filter, 'componentConnectivity', 26, ...
                    'minimumOccupiedSlices', 2);
                configs = [configs; c]; %#ok<AGROW>
            end
        end
    end
end
ids = [configs.id].';
nConfigs = numel(configs);
checks = [checks; {
    "exactly 24 unique configurations",             nConfigs == 24 && numel(unique(ids)) == 24
    "baseline P0_T2_M2_G0 in the grid",             any(ids == "P0_T2_M2_G0")
    }];

if ~isfolder(candidateDir)
    mkdir(candidateDir);
end
predictions = cell(nConfigs, 2);
thresholds = cell(nConfigs, 2);
brainMasks = cell(1, 2); rawVolumes = cell(1, 2);
for n = 1:2
    noise = noiseLevels(n);
    raw = loadBrainwebMri(cfg, "T2", noise);
    rawVolumes{n} = raw;
    t2Norm = prepare(raw);
    s = load(maskFile(noise), 'candidate');
    brainMasks{n} = s.candidate;
    checks(end+1, :) = {noise + " T2 normalized /4095 in [0,1], brain mask logical 181x217x181", ...
        all(isfinite(t2Norm(:))) && min(t2Norm(:)) >= 0 && max(t2Norm(:)) <= 1 && islogical(brainMasks{n}) && ...
        isequal(size(brainMasks{n}), expectedSize)}; %#ok<SAGROW>
    for i = 1:nConfigs
        [M_pred, details] = generatePhase95Prediction(t2Norm, brainMasks{n}, configs(i));
        predictions{i, n} = M_pred;
        thresholds{i, n} = details.thresholdsNormalized;
        configuration = configs(i);
        condition = noise;
        metadata = struct('phase', 95, 'experiment', "EXP-056", 'condition', noise, 'configId', configs(i).id, ...
            'modality', "T2", 'normalization', "/4095", 'brainSupport', "EXP-021", 'gtUsedForGeneration', false, ...
            'candidateVoxels', details.candidateVoxels, 'afterMorphologyVoxels', details.afterMorphologyVoxels, ...
            'finalVoxels', details.finalVoxels, 'removedComponents', details.componentDetails.removedComponentCount, ...
            'heldOutUsed', false);
        thresholdsNormalized = details.thresholdsNormalized;
        save(candidateFile(configs(i).id, noise), 'M_pred', 'configuration', 'condition', 'thresholdsNormalized', 'metadata');
    end
end


%% 2. Verifica dei file e riproduzione della baseline (ancora senza GT)

allSaved = all(arrayfun(@(i) isfile(candidateFile(ids(i), "pn0")) && isfile(candidateFile(ids(i), "pn3")), 1:nConfigs));
validMasks = all(cellfun(@(m) islogical(m) && isequal(size(m), expectedSize), predictions(:)));
insideBrain = true;
for n = 1:2
    insideBrain = insideBrain && all(cellfun(@(m) ~any(m & ~brainMasks{n}, 'all'), predictions(:, n)));
end
baseIdx = find(ids == "P0_T2_M2_G0");
baseline71 = cell(1, 2);
for n = 1:2
    s = load(phase71File(noiseLevels(n)), 'M_pred');
    baseline71{n} = s.M_pred;
end
checks = [checks; {
    "exactly 48 predictions generated and saved before GT", allSaved && numel(predictions) == 48 && ~gtLoaded
    "all predictions logical 181x217x181",           validMasks
    "all predictions inside the corresponding brain mask", insideBrain
    "baseline P0_T2_M2_G0 reproduces Phase-71 pn0 exactly", isequal(predictions{baseIdx, 1}, baseline71{1})
    "baseline P0_T2_M2_G0 reproduces Phase-71 pn3 exactly", isequal(predictions{baseIdx, 2}, baseline71{2})
    }];
if ~isequal(predictions{baseIdx, 1}, baseline71{1}) || ~isequal(predictions{baseIdx, 2}, baseline71{2})
    error('exp056:technicallyBlocked', 'PHASE 95 TECHNICALLY BLOCKED: baseline does not reproduce Phase 71.');
end


%% 3. Ground truth (caricato SOLO ora)

gtLoaded = true;
labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;                           % GT completo, nessuna maschera
gtCopy = gtMask;
gtVoxels = nnz(gtMask);
checks(end+1, :) = {"GT = complete label 10, 181x217x181", isequal(gtMask, labels == 10) && isequal(size(gtMask), expectedSize)};


%% 4. Valutazione a volume completo e classifica

gridRows = cell(nConfigs * 2, 24);
dice = zeros(nConfigs, 2);
r = 0;
for i = 1:nConfigs
    c = configs(i);
    for n = 1:2
        cnt = computeVoxelConfusion(predictions{i, n}, gtMask);
        dice(i, n) = computeDiceFromConfusion(cnt);
        predVox = cnt.TP + cnt.FP;
        volErr = computeVolumeErrorPercent(gtVoxels, predVox);
        thr = [thresholds{i, n}, NaN(1, 3 - numel(thresholds{i, n}))];
        r = r + 1;
        gridRows(r, :) = {c.id, noiseLevels(n), ternary(c.gaussianEnabled, "gaussian", "none"), ...
            ternary(c.gaussianEnabled, 0.5, NaN), c.numberOfThresholds, c.selectedHighestClass, ...
            c.openingType + ternary(c.openingType == "none", "", string(c.openingParameter)), c.componentFilter, ...
            26, thr(1), thr(2), thr(3), predVox, cnt.TP, cnt.FP, cnt.FN, cnt.TN, dice(i, n), ...
            computeIoUFromConfusion(cnt), computePrecisionFromConfusion(cnt), computeRecallFromConfusion(cnt), ...
            computeSpecificityFromConfusion(cnt), predVox * 1, volErr.volumeErrorPercent};
    end
end
gridTable = cell2table(gridRows, 'VariableNames', {'configId', 'condition', 'preprocessing', 'gaussianSigma', ...
    'numberOfThresholds', 'selectedClass', 'morphology', 'componentRule', 'connectivity', 'threshold1Normalized', ...
    'threshold2Normalized', 'threshold3Normalized', 'predictedVoxels', 'tpVoxels', 'fpVoxels', 'fnVoxels', ...
    'tnVoxels', 'dice', 'iou', 'precision', 'recall', 'specificity', 'predictedVolumeMm3', 'volumeErrorPercent'});
writetable(gridTable, fullfile(cfg.paths.metrics, 'exp056_tuning_grid_results.csv'));

developmentScore = (dice(:, 1) + dice(:, 2)) / 2;
weaker = min(dice, [], 2);
blocks = arrayfun(@(c) double(c.gaussianEnabled) + double(c.numberOfThresholds == 3) + ...
    double(c.openingType ~= "none") + double(c.componentFilter ~= "none"), configs);
morphologyOrder = arrayfun(@(c) find(["none" "diamond" "square"] == c.openingType), configs);   % M0 < M1 < M2
[~, idOrder] = sort(ids);
idRank = zeros(nConfigs, 1); idRank(idOrder) = 1:nConfigs;
[~, order] = sortrows([-developmentScore, -weaker, blocks, morphologyOrder, idRank]);
rankOf = zeros(nConfigs, 1); rankOf(order) = 1:nConfigs;
winnerIdx = order(1);
baseScore = developmentScore(baseIdx);
p91 = readtable(phase91File, 'TextType', 'string');
closeTo = @(a, b) abs(a - b) <= 1e-12 * max(1, abs(b));

rankingTable = table(rankOf(order), ids(order), [configs(order).gaussianEnabled].', [configs(order).numberOfThresholds].', ...
    [configs(order).openingType].', [configs(order).componentFilter].', dice(order, 1), dice(order, 2), weaker(order), ...
    developmentScore(order), developmentScore(order) - baseScore, blocks(order), order == winnerIdx, ...
    'VariableNames', {'rank', 'configId', 'gaussian', 'numberOfThresholds', 'opening', 'componentRule', 'dicePn0', ...
    'dicePn3', 'weakerConditionDice', 'developmentScore', 'deltaDevelopmentScoreVsPhase71', 'activeBlocks', 'selected'});
writetable(rankingTable, fullfile(cfg.paths.metrics, 'exp056_tuning_ranking.csv'));
disp(rankingTable);

winner = configs(winnerIdx);
checks = [checks; {
    "baseline Dice reproduces Phase 91 (pn0, pn3)", closeTo(dice(baseIdx, 1), p91.dice(p91.condition == "pn0")) && ...
        closeTo(dice(baseIdx, 2), p91.dice(p91.condition == "pn3"))
    "Dice pn0 / pn3 recorded for all 24, finite",  all(isfinite(dice(:))) && height(gridTable) == 48
    "DevelopmentScore = exact equal-weight mean",  all(developmentScore == (dice(:, 1) + dice(:, 2)) / 2)
    "ranking first by DevelopmentScore (descending), no tolerance", all(diff(developmentScore(order)) <= 0)
    "exactly one selected winner = rank 1",         nnz(rankingTable.selected) == 1 && rankingTable.selected(1)
    "selected DevelopmentScore >= baseline",        developmentScore(winnerIdx) >= baseScore
    "exact ties at the top resolved only by the declared order", ...
        nnz(developmentScore == developmentScore(winnerIdx)) == 1 || weaker(winnerIdx) >= max(weaker(developmentScore == developmentScore(winnerIdx)))
    }];


%% 5. Vincitore: file selezionati

for n = 1:2
    M_pred = predictions{winnerIdx, n};
    configuration = winner;
    metadata = struct('phase', 95, 'experiment', "EXP-056", 'condition', noiseLevels(n), 'configId', winner.id, ...
        'selectionCriterion', "Phase-37 DevelopmentScore", 'developmentOnly', true, 'heldOutUsed', false, ...
        'notYetFrozen', true, 'sourceCandidateFile', string(candidateFile(winner.id, noiseLevels(n))));
    save(selectedFile(noiseLevels(n)), 'M_pred', 'configuration', 'metadata');
end
selectedTable = table(winner.id, ternary(winner.gaussianEnabled, "Gaussian sigma 0.5, 3x3, replicate", "none"), ...
    "multithresh N=" + winner.numberOfThresholds + ", Class " + winner.selectedHighestClass, ...
    ternary(winner.openingType == "none", "none", "opening " + winner.openingType + " " + winner.openingParameter), ...
    ternary(winner.componentFilter == "none", "none", "remove single-slice 3D components (26)"), ...
    dice(winnerIdx, 1), dice(winnerIdx, 2), weaker(winnerIdx), developmentScore(winnerIdx), ...
    developmentScore(winnerIdx) - baseScore, 'VariableNames', {'configId', 'preprocessing', 'thresholdRule', ...
    'morphology', 'componentRule', 'dicePn0', 'dicePn3', 'weakerConditionDice', 'developmentScore', 'deltaVsBaseline'});
writetable(selectedTable, fullfile(cfg.paths.metrics, 'exp056_selected_configuration.csv'));
fprintf('\nSELECTED (development, not yet frozen): %s  DevelopmentScore %.15g (baseline %.15g, delta %+.6g)\n\n', ...
    winner.id, developmentScore(winnerIdx), baseScore, developmentScore(winnerIdx) - baseScore);


%% 6. Diagnostiche post-selezione (NON cambiano il vincitore)

winnerBefore = winner.id;
cmpRows = cell(0, 13);
lesionRows = cell(0, 9);
sizeTable = readtable(phase94File, 'TextType', 'string');
sizeOfLesion = sortrows(sizeTable(sizeTable.condition == "pn0", {'gtLesionId', 'sizeClass'}), 'gtLesionId');
for n = 1:2
    for which = ["baseline" "selected"]
        idx = ternary(which == "baseline", baseIdx, winnerIdx);
        g = gridTable(gridTable.configId == ids(idx) & gridTable.condition == noiseLevels(n), :);
        cmpRows(end+1, :) = {noiseLevels(n), which, ids(idx), g.dice, g.iou, g.precision, g.recall, g.specificity, ...
            g.tpVoxels, g.fpVoxels, g.fnVoxels, g.predictedVoxels, g.volumeErrorPercent}; %#ok<SAGROW>
        lw = computeLesionWiseMatches(predictions{idx, n}, gtMask, 26);
        det = lw.gtComponentTable.isDetected;
        small = sizeOfLesion.sizeClass(lw.gtComponentTable.gtLesionId) == "SMALL";
        lesionRows(end+1, :) = {noiseLevels(n), which, ids(idx), lw.detectedGtLesionCount, lw.missedGtLesionCount, ...
            lw.falsePredictedComponentCount, lw.predictedComponentCount, nnz(det & small), nnz(det & ~small)}; %#ok<SAGROW>
        detectedSets.(char(noiseLevels(n) + which)) = det;
    end
end
comparison = cell2table(cmpRows, 'VariableNames', {'condition', 'role', 'configId', 'dice', 'iou', 'precision', ...
    'recall', 'specificity', 'tpVoxels', 'fpVoxels', 'fnVoxels', 'predictedVoxels', 'volumeErrorPercent'});
lesionDiag = cell2table(lesionRows, 'VariableNames', {'condition', 'role', 'configId', 'detectedGtLesions', ...
    'missedGtLesions', 'falsePredictedComponents', 'predictedComponents', 'detectedSmall', 'detectedLarge'});
writetable(comparison, fullfile(cfg.paths.metrics, 'exp056_baseline_vs_selected.csv'));
writetable(lesionDiag, fullfile(cfg.paths.metrics, 'exp056_selected_lesion_diagnostics.csv'));
disp(comparison); disp(lesionDiag);
for n = 1:2
    lost = find(detectedSets.(char(noiseLevels(n) + "baseline")) & ~detectedSets.(char(noiseLevels(n) + "selected")));
    gained = find(~detectedSets.(char(noiseLevels(n) + "baseline")) & detectedSets.(char(noiseLevels(n) + "selected")));
    fprintf('%s: GT lesions detected by baseline but missed by selected: [%s]; newly detected: [%s]\n', noiseLevels(n), ...
        strjoin(string(lost.'), ' '), strjoin(string(gained.'), ' '));
end
checks(end+1, :) = {"post-selection diagnostics did not change the winner", winner.id == winnerBefore && ...
    rankingTable.configId(1) == winnerBefore};


%% 7. Figure

fig = figure('Color', 'w');
ax = axes(fig);
bar(ax, developmentScore(order), 'FaceColor', [0.7 0.8 1]);
hold(ax, 'on');
plot(ax, 1:nConfigs, dice(order, 1), 'b^', 1:nConfigs, dice(order, 2), 'rv');
plot(ax, find(order == baseIdx), developmentScore(baseIdx), 'ks', 'MarkerSize', 12, 'LineWidth', 1.5);
hold(ax, 'off');
set(ax, 'XTick', 1:nConfigs, 'XTickLabel', ids(order), 'TickLabelInterpreter', 'none');
xtickangle(ax, 60);
ylabel(ax, 'complete-volume Dice'); grid(ax, 'on');
legend(ax, 'DevelopmentScore', 'Dice pn0', 'Dice pn3', 'baseline P0\_T2\_M2\_G0', 'Location', 'northeast');
title(ax, sprintf('EXP-056 - 24 configurations ranked by DevelopmentScore (selected: %s)', winner.id), 'Interpreter', 'none');
fig.Position(3:4) = [1200 520];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp056_tuning_ranking.png'));

fig = figure('Color', 'w');
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact');
for n = 1:2
    ax = nexttile(layout);
    b = comparison(comparison.condition == noiseLevels(n), :);
    bar(ax, categorical(["Dice" "IoU" "Precision" "Recall"], ["Dice" "IoU" "Precision" "Recall"]), ...
        [b.dice b.iou b.precision b.recall].');
    legend(ax, "baseline " + b.configId(1), "selected " + b.configId(2), 'Interpreter', 'none', 'Location', 'northwest');
    ylim(ax, [0 1]); grid(ax, 'on'); title(ax, noiseLevels(n));
end
title(layout, 'EXP-056 - Phase-71 baseline vs selected configuration (complete volume)');
fig.Position(3:4) = [1000 420];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp056_baseline_vs_selected_metrics.png'));


%% 8. Controlli finali

rawUnchanged = isequal(rawVolumes{1}, loadBrainwebMri(cfg, "T2", "pn0")) && isequal(rawVolumes{2}, loadBrainwebMri(cfg, "T2", "pn3"));
masksUnchanged = true;
for n = 1:2
    s = load(maskFile(noiseLevels(n)), 'candidate');
    masksUnchanged = masksUnchanged && isequal(s.candidate, brainMasks{n});
end
priorAfter = arrayfun(@fileState, priorArtifacts, 'UniformOutput', false);
scriptText = fileread([mfilename('fullpath') '.m']);
codeText = strjoin(regexprep(splitlines(string(scriptText)), '%.*$', ''), newline);
helperText = strjoin(cellfun(@(f) fileread(f), cellstr(helperFiles(3:4)), 'UniformOutput', false), newline);
helperCode = strjoin(regexprep(splitlines(string(helperText)), '%.*$', ''), newline);
forbidden = {['regionGrow' 'ing('], ['fuseCandidate' 'Masks'], ['localMeanStd' 'Threshold2D('], ['loadBrainweb' 'Mri(cfg, "PD"'], ...
    ['loadBrainweb' 'Mri(cfg, "T1"'], ['weight' 'ed'], ['F' '1'], ['nanm' 'ean('], ['computeSlice' 'WiseMetrics(']};
positionRules = {['k >' '= 70'], ['70:' '104'], ['first' 'GtSlice'], ['sizeThreshold' 'Voxels'], ['7 ' 'voxels'], ['min' 'Size']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "only T2 pn0 / pn3 accessed, no held-out filename", ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "no region growing, multimodal fusion, local threshold, combined score or slice-wise ranking", ~any(cellfun(@(f) contains(codeText, f), forbidden))
    "no position rule or GT-size threshold in generation (script and helpers)", ...
        ~any(cellfun(@(f) contains(codeText, f) || contains(helperCode, f), positionRules)) && ~contains(helperCode, ['Ground' 'Truth'])
    "raw MRI unchanged",                             rawUnchanged
    "brain masks unchanged",                         masksUnchanged
    "Phase-71 sources and Phase-91..94 artifacts unchanged", isequal(priorBefore, priorAfter)
    "GT unchanged",                                  isequal(gtMask, gtCopy)
    "config.m unchanged",                            isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];

for c = 1:size(checks, 1)
    if checks{c, 2}
        status = 'ok';
    else
        status = 'FAILED';
    end
    fprintf('%-95s %s\n', checks{c, 1}, status);
end
if any(~[checks{:, 2}])
    error('exp056:checksFailed', 'EXP-056 checks failed.');
end
fprintf('\nEXP-056 CHECKS: PASS (%d)\n', size(checks, 1));


function out = ternary(condition, a, b)
%TERNARY a se condition è vero, altrimenti b.
    if condition
        out = a;
    else
        out = b;
    end
end

function state = fileState(f)
%FILESTATE Data, dimensione e contenuto di un file (verifica di immutabilità).
    info = dir(f);
    state = {info.datenum, info.bytes, fileread(f)};
end
