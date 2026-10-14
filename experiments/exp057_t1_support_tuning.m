%% EXP-057 (fase 95, esperimento supplementare FINALE): supporto anatomico da T1
% Griglia preregistrata di 36 configurazioni (S x T x M x G), pn0 e pn3:
%   S0 EXP-021 | S1 EXP-021 AND NOT T1-low | S2 EXP-021 AND imfill(T1-high) AND NOT T1-low
%     (T1: multithresh(T1(EXP-021), 2); classe 1 = T1-low, classe 3 = T1-high)
%   TA multithresh(T2(S), 2) classe più alta | TB graythresh(T2(S)), voxel > soglia
%   M0 nessuna | M1 apertura diamond 1 | M2 apertura square 3 (2D per slice)
%   G0 nessuna | G1 rimozione delle componenti 3D (26) su una sola slice
% SEZIONE 1: supporti e 72 predizioni SENZA GT (salvate). SEZIONE 2: verifica e
% baseline S0_TA_M2_G1 = vincitore EXP-056 voxel per voxel. SEZIONE 3: GT.
% SEZIONE 4: Dice a volume completo, DevelopmentScore, classifica (fase 37).
% SEZIONI 5-6: vincitore e diagnostiche post-selezione (non cambiano la scelta).
% Ultimo esperimento di sviluppo: dopo segue la fase 96. Nessun dato held-out.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
fixedSlices = [46 91 102 136];
candidateDir = fullfile(cfg.paths.processedData, 'phase95_exp057_candidates');
candidateFile = @(id, noise) fullfile(candidateDir, sprintf('exp057_%s_%s.mat', id, noise));
selectedFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase95_exp057_t2_%s_selected_prediction.mat', noise));
exp056WinnerFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase95_t2_%s_selected_prediction.mat', noise));
maskFile = @(noise) fullfile(cfg.paths.processedData, sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));
exp056Selected = fullfile(cfg.paths.metrics, 'exp056_selected_configuration.csv');
phase94File = fullfile(cfg.paths.metrics, 'exp055_gt_lesion_size_analysis.csv');
priorArtifacts = [string(exp056Selected), fullfile(cfg.paths.metrics, ["exp056_tuning_ranking.csv" ...
    "exp052_complete_3d_metrics.csv" "exp055_gt_lesion_size_analysis.csv"]), string(exp056WinnerFile("pn0")), ...
    string(exp056WinnerFile("pn3"))];
mriT2 = [string(cfg.dataset.mriFiles.T2), string(cfg.dataset.noisyMriFiles.pn3.T2)];
mriT1 = [string(cfg.dataset.mriFiles.T1), string(cfg.dataset.noisyMriFiles.pn3.T1)];
prepare = @(raw) normalizeFixedRange(convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, cfg.preprocessing.normalization.outputRange);
checks = cell(0, 2);
gtLoaded = false;


%% 0. Ingressi

helperFiles = fullfile(cfg.paths.segmentation, ["computeT1AnatomicalSupport.m" "generateExp057Prediction.m" ...
    "generateLesionCandidateMask.m" "removeSingleSliceComponents3D.m"]);
for f = [priorArtifacts, string(maskFile("pn0")), string(maskFile("pn3")), helperFiles, mriT2, mriT1]
    if ~isfile(f)
        error('exp057:technicallyBlocked', 'EXP-057 TECHNICALLY BLOCKED: missing %s', f);
    end
end
priorBefore = arrayfun(@fileState, priorArtifacts, 'UniformOutput', false);
sel56 = readtable(exp056Selected, 'TextType', 'string');
checks = [checks; {
    "required T1 / T2 MRI, brain masks, EXP-056 artifacts and helpers exist", true
    "EXP-056 winner on record is P0_T2_M2_G1",       height(sel56) == 1 && sel56.configId == "P0_T2_M2_G1"
    }];


%% 1. Supporti e 72 predizioni (NESSUN GT)

configs = struct([]);
for s = ["S0" "S1" "S2"]
    for t = ["TA" "TB"]
        for m = struct('code', {"M0", "M1", "M2"}, 'type', {"none", "diamond", "square"}, 'param', {0, 1, 3})
            for g = struct('code', {"G0", "G1"}, 'filter', {"none", "minOccupiedSlices"})
                configs = [configs; struct('id', s + "_" + t + "_" + m.code + "_" + g.code, 'supportLevel', s, ...
                    'thresholdRule', t, 'openingType', m.type, 'openingParameter', m.param, 'componentFilter', g.filter, ...
                    'componentConnectivity', 26, 'minimumOccupiedSlices', 2)]; %#ok<AGROW>
            end
        end
    end
end
ids = [configs.id].';
nConfigs = numel(configs);
checks(end+1, :) = {"exactly 36 unique configurations, baseline S0_TA_M2_G1 included", ...
    nConfigs == 36 && numel(unique(ids)) == 36 && any(ids == "S0_TA_M2_G1")};

if ~isfolder(candidateDir)
    mkdir(candidateDir);
end
predictions = cell(nConfigs, 2);
thresholds = cell(nConfigs, 2);
supportsByCondition = cell(1, 2); supportDetails = cell(1, 2); brainMasks = cell(1, 2);
rawT2 = cell(1, 2); rawT1 = cell(1, 2); t1NormByCondition = cell(1, 2);
for n = 1:2
    noise = noiseLevels(n);
    rawT2{n} = loadBrainwebMri(cfg, "T2", noise);
    rawT1{n} = loadBrainwebMri(cfg, "T1", noise);
    t2Norm = prepare(rawT2{n});
    t1Norm = prepare(rawT1{n});
    t1NormByCondition{n} = t1Norm;
    s = load(maskFile(noise), 'candidate');
    brainMasks{n} = s.candidate;
    [supports, sd] = computeT1AnatomicalSupport(t1Norm, brainMasks{n});
    supportsByCondition{n} = supports; supportDetails{n} = sd;
    checks = [checks; {
        noise + " T1 / T2 normalized in [0,1], brain mask logical 181x217x181", all(isfinite([t1Norm(:); t2Norm(:)])) && ...
            min([t1Norm(:); t2Norm(:)]) >= 0 && max([t1Norm(:); t2Norm(:)]) <= 1 && islogical(brainMasks{n}) && ...
            isequal(size(brainMasks{n}), expectedSize)
        noise + " supports nested S2 <= S1 <= S0 = EXP-021, non-empty", isequal(supports.S0, brainMasks{n}) && ...
            ~any(supports.S1 & ~supports.S0, 'all') && ~any(supports.S2 & ~supports.S1, 'all') && nnz(supports.S2) > 0
        }]; %#ok<AGROW>
    for i = 1:nConfigs
        support = supports.(char(configs(i).supportLevel));
        [M_pred, details] = generateExp057Prediction(t2Norm, support, configs(i));
        predictions{i, n} = M_pred;
        thresholds{i, n} = details.thresholdsNormalized;
        configuration = configs(i);
        condition = noise;
        thresholdsNormalized = details.thresholdsNormalized;
        t1ThresholdsNormalized = sd.t1ThresholdsNormalized;
        metadata = struct('phase', 95, 'experiment', "EXP-057", 'condition', noise, 'configId', configs(i).id, ...
            'modalities', "T2 lesion signal, T1 anatomical support", 'normalization', "/4095", 'brainSupport', "EXP-021", ...
            'supportVoxels', details.supportVoxels, 'candidateVoxels', details.candidateVoxels, ...
            'afterMorphologyVoxels', details.afterMorphologyVoxels, 'finalVoxels', details.finalVoxels, ...
            'removedComponents', details.removedComponents, 'gtUsedForGeneration', false, 'heldOutUsed', false);
        save(candidateFile(configs(i).id, noise), 'M_pred', 'configuration', 'condition', 'thresholdsNormalized', ...
            't1ThresholdsNormalized', 'metadata');
    end
end
supportTable = table(noiseLevels.', cellfun(@(d) d.t1ThresholdsNormalized(1), supportDetails).', ...
    cellfun(@(d) d.t1ThresholdsNormalized(2), supportDetails).', cellfun(@(d) d.t1LowVoxels, supportDetails).', ...
    cellfun(@(d) d.t1HighVoxels, supportDetails).', cellfun(@(d) d.S0Voxels, supportDetails).', ...
    cellfun(@(d) d.S1Voxels, supportDetails).', cellfun(@(d) d.S2Voxels, supportDetails).', ...
    'VariableNames', {'condition', 't1Threshold1', 't1Threshold2', 't1LowVoxels', 't1HighVoxels', 'S0Voxels', ...
    'S1Voxels', 'S2Voxels'});
writetable(supportTable, fullfile(cfg.paths.metrics, 'exp057_support_summary.csv'));
disp(supportTable);

% Figura dei supporti (senza GT): slice fisse, T1 con S1 / S2
fig = figure('Color', 'w');
layout = tiledlayout(fig, 2, numel(fixedSlices), 'TileSpacing', 'tight', 'Padding', 'tight');
for n = 1:2
    for k = fixedSlices
        ax = nexttile(layout);
        g = t1NormByCondition{n}(:, :, k).';
        s1 = supportsByCondition{n}.S1(:, :, k).'; s2 = supportsByCondition{n}.S2(:, :, k).';
        rgb = cat(3, g, g, g);
        rgb(:, :, 1) = g .* ~s1 + 0.9 * (s1 & ~s2);          % arancio: S1 non in S2
        rgb(:, :, 2) = g .* ~s1 + 0.5 * (s1 & ~s2) + 0.8 * s2; % verde: S2
        rgb(:, :, 3) = g .* ~s1;
        image(ax, min(rgb, 1)); axis(ax, 'image'); set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('%s k=%d', noiseLevels(n), k), 'FontSize', 8);
    end
end
title(layout, {'EXP-057 supports on T1 (no GT): green = S2 (filled T1-high, minus T1-low)', ...
    'orange = in S1 but not S2; gray = excluded from S1 (T1-low) or outside the brain mask'});
fig.Position(3:4) = [1200 650];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp057_supports.png'));


%% 2. Verifica e riproduzione della baseline (ancora senza GT)

allSaved = all(arrayfun(@(i) isfile(candidateFile(ids(i), "pn0")) && isfile(candidateFile(ids(i), "pn3")), 1:nConfigs));
insideSupport = true;
for n = 1:2
    for i = 1:nConfigs
        support = supportsByCondition{n}.(char(configs(i).supportLevel));
        insideSupport = insideSupport && ~any(predictions{i, n} & ~support, 'all');
    end
end
baseIdx = find(ids == "S0_TA_M2_G1");
winner56 = cell(1, 2);
for n = 1:2
    s = load(exp056WinnerFile(noiseLevels(n)), 'M_pred');
    winner56{n} = s.M_pred;
end
checks = [checks; {
    "exactly 72 predictions generated and saved before GT", allSaved && numel(predictions) == 72 && ~gtLoaded
    "all predictions logical 181x217x181, inside their support", ...
        all(cellfun(@(m) islogical(m) && isequal(size(m), expectedSize), predictions(:))) && insideSupport
    "baseline S0_TA_M2_G1 = EXP-056 winner pn0 voxel by voxel", isequal(predictions{baseIdx, 1}, winner56{1})
    "baseline S0_TA_M2_G1 = EXP-056 winner pn3 voxel by voxel", isequal(predictions{baseIdx, 2}, winner56{2})
    }];
if ~isequal(predictions{baseIdx, 1}, winner56{1}) || ~isequal(predictions{baseIdx, 2}, winner56{2})
    error('exp057:technicallyBlocked', 'EXP-057 TECHNICALLY BLOCKED: baseline does not reproduce the EXP-056 winner.');
end


%% 3. Ground truth (caricato SOLO ora)

gtLoaded = true;
labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
gtCopy = gtMask;
gtVoxels = nnz(gtMask);
checks(end+1, :) = {"GT = complete label 10, 181x217x181", isequal(gtMask, labels == 10) && isequal(size(gtMask), expectedSize)};


%% 4. Valutazione a volume completo e classifica

gridRows = cell(nConfigs * 2, 22);
dice = zeros(nConfigs, 2);
r = 0;
for i = 1:nConfigs
    c = configs(i);
    for n = 1:2
        cnt = computeVoxelConfusion(predictions{i, n}, gtMask);
        dice(i, n) = computeDiceFromConfusion(cnt);
        predVox = cnt.TP + cnt.FP;
        volErr = computeVolumeErrorPercent(gtVoxels, predVox);
        thr = [thresholds{i, n}, NaN(1, 2 - numel(thresholds{i, n}))];
        r = r + 1;
        gridRows(r, :) = {c.id, noiseLevels(n), c.supportLevel, c.thresholdRule, ...
            c.openingType + ternary(c.openingType == "none", "", string(c.openingParameter)), c.componentFilter, ...
            thr(1), thr(2), nnz(supportsByCondition{n}.(char(c.supportLevel))), predVox, cnt.TP, cnt.FP, cnt.FN, ...
            cnt.TN, dice(i, n), computeIoUFromConfusion(cnt), computePrecisionFromConfusion(cnt), ...
            computeRecallFromConfusion(cnt), computeSpecificityFromConfusion(cnt), predVox * 1, ...
            volErr.volumeErrorPercent, nnz(gtMask & supportsByCondition{n}.(char(c.supportLevel)))};
    end
end
gridTable = cell2table(gridRows, 'VariableNames', {'configId', 'condition', 'support', 'thresholdRule', ...
    'morphology', 'componentRule', 't2Threshold1Normalized', 't2Threshold2Normalized', 'supportVoxels', ...
    'predictedVoxels', 'tpVoxels', 'fpVoxels', 'fnVoxels', 'tnVoxels', 'dice', 'iou', 'precision', 'recall', ...
    'specificity', 'predictedVolumeMm3', 'volumeErrorPercent', 'gtVoxelsInsideSupport'});
writetable(gridTable, fullfile(cfg.paths.metrics, 'exp057_tuning_grid_results.csv'));

developmentScore = (dice(:, 1) + dice(:, 2)) / 2;
weaker = min(dice, [], 2);
blocks = arrayfun(@(c) double(c.supportLevel == "S1") + 2 * double(c.supportLevel == "S2") + ...
    double(c.openingType ~= "none") + double(c.componentFilter ~= "none"), configs);
[~, idOrder] = sort(ids);
idRank = zeros(nConfigs, 1); idRank(idOrder) = 1:nConfigs;
[~, order] = sortrows([-developmentScore, -weaker, blocks, idRank]);
rankOf = zeros(nConfigs, 1); rankOf(order) = 1:nConfigs;
winnerIdx = order(1);
baseScore = developmentScore(baseIdx);
rank56 = readtable(fullfile(cfg.paths.metrics, 'exp056_tuning_ranking.csv'), 'TextType', 'string');
closeTo = @(a, b) abs(a - b) <= 1e-12 * max(1, abs(b));

rankingTable = table(rankOf(order), ids(order), [configs(order).supportLevel].', [configs(order).thresholdRule].', ...
    [configs(order).openingType].', [configs(order).componentFilter].', dice(order, 1), dice(order, 2), weaker(order), ...
    developmentScore(order), developmentScore(order) - baseScore, blocks(order), order == winnerIdx, ...
    'VariableNames', {'rank', 'configId', 'support', 'thresholdRule', 'opening', 'componentRule', 'dicePn0', ...
    'dicePn3', 'weakerConditionDice', 'developmentScore', 'deltaVsExp056Winner', 'activeBlocks', 'selected'});
writetable(rankingTable, fullfile(cfg.paths.metrics, 'exp057_tuning_ranking.csv'));
disp(rankingTable);

winner = configs(winnerIdx);
checks = [checks; {
    "baseline score reproduces the EXP-056 winner (0.058158...)", ...
        closeTo(baseScore, rank56.developmentScore(rank56.configId == "P0_T2_M2_G1"))
    "Dice pn0 / pn3 recorded for all 36, finite",   all(isfinite(dice(:))) && height(gridTable) == 72
    "DevelopmentScore = exact equal-weight mean",   all(developmentScore == (dice(:, 1) + dice(:, 2)) / 2)
    "ranking first by DevelopmentScore, no tolerance", all(diff(developmentScore(order)) <= 0)
    "exactly one selected winner = rank 1, score >= baseline", nnz(rankingTable.selected) == 1 && ...
        rankingTable.selected(1) && developmentScore(winnerIdx) >= baseScore
    }];


%% 5. Vincitore: file selezionati

for n = 1:2
    M_pred = predictions{winnerIdx, n};
    configuration = winner;
    metadata = struct('phase', 95, 'experiment', "EXP-057", 'condition', noiseLevels(n), 'configId', winner.id, ...
        'selectionCriterion', "Phase-37 DevelopmentScore", 'developmentOnly', true, 'heldOutUsed', false, ...
        'notYetFrozen', true, 'sourceCandidateFile', string(candidateFile(winner.id, noiseLevels(n))));
    save(selectedFile(noiseLevels(n)), 'M_pred', 'configuration', 'metadata');
end
selectedTable = table(winner.id, winner.supportLevel, winner.thresholdRule, ...
    ternary(winner.openingType == "none", "none", "opening " + winner.openingType + " " + winner.openingParameter), ...
    ternary(winner.componentFilter == "none", "none", "remove single-slice 3D components (26)"), ...
    dice(winnerIdx, 1), dice(winnerIdx, 2), weaker(winnerIdx), developmentScore(winnerIdx), ...
    developmentScore(winnerIdx) - baseScore, 'VariableNames', {'configId', 'support', 'thresholdRule', 'morphology', ...
    'componentRule', 'dicePn0', 'dicePn3', 'weakerConditionDice', 'developmentScore', 'deltaVsExp056Winner'});
writetable(selectedTable, fullfile(cfg.paths.metrics, 'exp057_selected_configuration.csv'));
fprintf('\nSELECTED (development, not yet frozen): %s  DevelopmentScore %.15g (EXP-056 winner %.15g, delta %+.6g)\n\n', ...
    winner.id, developmentScore(winnerIdx), baseScore, developmentScore(winnerIdx) - baseScore);


%% 6. Diagnostiche post-selezione (NON cambiano il vincitore)

winnerBefore = winner.id;
cmpRows = cell(0, 13);
lesionRows = cell(0, 9);
sizeTable = readtable(phase94File, 'TextType', 'string');
sizeOfLesion = sortrows(sizeTable(sizeTable.condition == "pn0", {'gtLesionId', 'sizeClass'}), 'gtLesionId');
detectedSets = struct();
for n = 1:2
    for which = ["EXP-056 winner" "EXP-057 selected"]
        idx = ternary(which == "EXP-056 winner", baseIdx, winnerIdx);
        g = gridTable(gridTable.configId == ids(idx) & gridTable.condition == noiseLevels(n), :);
        cmpRows(end+1, :) = {noiseLevels(n), which, ids(idx), g.dice, g.iou, g.precision, g.recall, g.specificity, ...
            g.tpVoxels, g.fpVoxels, g.fnVoxels, g.predictedVoxels, g.volumeErrorPercent}; %#ok<SAGROW>
        lw = computeLesionWiseMatches(predictions{idx, n}, gtMask, 26);
        det = lw.gtComponentTable.isDetected;
        small = sizeOfLesion.sizeClass(lw.gtComponentTable.gtLesionId) == "SMALL";
        lesionRows(end+1, :) = {noiseLevels(n), which, ids(idx), lw.detectedGtLesionCount, lw.missedGtLesionCount, ...
            lw.falsePredictedComponentCount, lw.predictedComponentCount, nnz(det & small), nnz(det & ~small)}; %#ok<SAGROW>
        detectedSets.(matlab.lang.makeValidName(noiseLevels(n) + which)) = det;
    end
end
comparison = cell2table(cmpRows, 'VariableNames', {'condition', 'role', 'configId', 'dice', 'iou', 'precision', ...
    'recall', 'specificity', 'tpVoxels', 'fpVoxels', 'fnVoxels', 'predictedVoxels', 'volumeErrorPercent'});
lesionDiag = cell2table(lesionRows, 'VariableNames', {'condition', 'role', 'configId', 'detectedGtLesions', ...
    'missedGtLesions', 'falsePredictedComponents', 'predictedComponents', 'detectedSmall', 'detectedLarge'});
writetable(comparison, fullfile(cfg.paths.metrics, 'exp057_exp056winner_vs_selected.csv'));
writetable(lesionDiag, fullfile(cfg.paths.metrics, 'exp057_selected_lesion_diagnostics.csv'));
disp(comparison); disp(lesionDiag);
for n = 1:2
    before = detectedSets.(matlab.lang.makeValidName(noiseLevels(n) + "EXP-056 winner"));
    after = detectedSets.(matlab.lang.makeValidName(noiseLevels(n) + "EXP-057 selected"));
    fprintf('%s: GT lesions lost vs EXP-056 winner: [%s]; newly detected: [%s]\n', noiseLevels(n), ...
        strjoin(string(find(before & ~after).'), ' '), strjoin(string(find(~before & after).'), ' '));
    for sLevel = ["S0" "S1" "S2"]
        fprintf('    GT lesion voxels inside %s: %d of %d\n', sLevel, ...
            nnz(gtMask & supportsByCondition{n}.(char(sLevel))), gtVoxels);
    end
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
xtickangle(ax, 70);
ylabel(ax, 'complete-volume Dice'); grid(ax, 'on');
legend(ax, 'DevelopmentScore', 'Dice pn0', 'Dice pn3', 'EXP-056 winner (S0\_TA\_M2\_G1)', 'Location', 'northeast');
title(ax, sprintf('EXP-057 - 36 configurations ranked by DevelopmentScore (selected: %s)', winner.id), 'Interpreter', 'none');
fig.Position(3:4) = [1400 540];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp057_tuning_ranking.png'));

fig = figure('Color', 'w');
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact');
for n = 1:2
    ax = nexttile(layout);
    b = comparison(comparison.condition == noiseLevels(n), :);
    bar(ax, categorical(["Dice" "IoU" "Precision" "Recall"], ["Dice" "IoU" "Precision" "Recall"]), ...
        [b.dice b.iou b.precision b.recall].');
    legend(ax, "EXP-056 winner " + b.configId(1), "EXP-057 selected " + b.configId(2), 'Interpreter', 'none', ...
        'Location', 'northwest');
    ylim(ax, [0 1]); grid(ax, 'on'); title(ax, noiseLevels(n));
end
title(layout, 'EXP-057 - EXP-056 winner vs EXP-057 selected configuration (complete volume)');
fig.Position(3:4) = [1000 420];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp057_exp056winner_vs_selected.png'));


%% 8. Controlli finali

rawUnchanged = isequal(rawT2{1}, loadBrainwebMri(cfg, "T2", "pn0")) && isequal(rawT2{2}, loadBrainwebMri(cfg, "T2", "pn3")) && ...
    isequal(rawT1{1}, loadBrainwebMri(cfg, "T1", "pn0")) && isequal(rawT1{2}, loadBrainwebMri(cfg, "T1", "pn3"));
masksUnchanged = true;
for n = 1:2
    s = load(maskFile(noiseLevels(n)), 'candidate');
    masksUnchanged = masksUnchanged && isequal(s.candidate, brainMasks{n});
end
priorAfter = arrayfun(@fileState, priorArtifacts, 'UniformOutput', false);
scriptText = fileread([mfilename('fullpath') '.m']);
codeText = strjoin(regexprep(splitlines(string(scriptText)), '%.*$', ''), newline);
helperCode = strjoin(regexprep(splitlines(string(strjoin(arrayfun(@(f) string(fileread(f)), helperFiles(1:2)), newline))), ...
    '%.*$', ''), newline);
forbidden = {['regionGrow' 'ing('], ['fuseCandidate' 'Masks'], ['localMeanStd' 'Threshold2D('], ['loadBrainweb' 'Mri(cfg, "PD"'], ...
    ['weight' 'ed'], ['F' '1'], ['computeSlice' 'WiseMetrics('], ['gaussianFilter' 'Slices(']};
supportForbidden = {['imc' 'lose('], ['ime' 'rode('], ['imdi' 'late('], ['bwconn' 'comp('], ['bwarea' 'open('], ...
    ['multithresh(t1Norm(brainMask), ' '3'], ['classVolume == ' '2']};
positionRules = {['k >' '= 70'], ['70:' '104'], ['first' 'GtSlice'], ['sizeThreshold' 'Voxels'], ['7 ' 'voxels'], ['min' 'Size']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "only T1 / T2 pn0 / pn3 accessed, no held-out filename", ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "no region growing, PD fusion, local threshold, Gaussian or combined score", ~any(cellfun(@(f) contains(codeText, f), forbidden))
    "supports built only from the pre-registered steps (no closing / erosion / components / other classes)", ...
        ~any(cellfun(@(f) contains(helperCode, f), supportForbidden))
    "no position rule or GT-size threshold in generation, no GT in helpers", ...
        ~any(cellfun(@(f) contains(codeText, f) || contains(helperCode, f), positionRules)) && ~contains(helperCode, ['Ground' 'Truth'])
    "raw T1 / T2 MRI unchanged",                     rawUnchanged
    "brain masks unchanged",                         masksUnchanged
    "EXP-056 / Phase-91 / Phase-94 artifacts unchanged", isequal(priorBefore, priorAfter)
    "GT unchanged",                                  isequal(gtMask, gtCopy)
    "config.m unchanged",                            isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];

for c = 1:size(checks, 1)
    if checks{c, 2}
        status = 'ok';
    else
        status = 'FAILED';
    end
    fprintf('%-100s %s\n', checks{c, 1}, status);
end
if any(~[checks{:, 2}])
    error('exp057:checksFailed', 'EXP-057 checks failed.');
end
fprintf('\nEXP-057 CHECKS: PASS (%d)\n', size(checks, 1));


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
