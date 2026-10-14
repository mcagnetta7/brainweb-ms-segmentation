%% EXP-058 (emendamento A1): v2 = v1 congelata + filtro del rumore F x recupero dell'estensione R
% Griglia preregistrata di 21 configurazioni (7 F x 3 R), pn0 e pn3:
%   F0 nessuno | F1/F2/F3 gaussiano 0.5 su T1 / T2 / entrambi
%   F4/F5/F6 diffusione anisotropa (parametri espliciti) su T1 / T2 / entrambi
%   R0 nessuno | R1 imreconstruct(v1, S2 & T2f > TA_S2, 26) | R2 imreconstruct(v1, S1 & T2f > TA_S2, 26)
% SEZIONE 1: 42 predizioni SENZA GT (salvate) + invarianti. SEZIONE 2: F0_R0 = v1 congelata.
% SEZIONE 3: GT. SEZIONE 4: Dice, DevelopmentScore, classifica (fase 37).
% SEZIONE 5: vincitore e versione principale per il test (regola A1, prima di ogni held-out).
% SEZIONE 6: diagnostiche post-selezione. Unico esperimento ammesso da A1: niente EXP-059.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
v1RecordedScore = 0.600033865204608;
candidateDir = fullfile(cfg.paths.processedData, 'phase95_exp058_candidates');
candidateFile = @(id, noise) fullfile(candidateDir, sprintf('exp058_%s_%s.mat', id, noise));
v2File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase95_exp058_v2_%s_selected_prediction.mat', noise));
v1File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase95_exp057_t2_%s_selected_prediction.mat', noise));
maskFile = @(noise) fullfile(cfg.paths.processedData, sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));
v1Selected = fullfile(cfg.paths.metrics, 'exp057_selected_configuration.csv');
phase94File = fullfile(cfg.paths.metrics, 'exp055_gt_lesion_size_analysis.csv');
priorArtifacts = [string(v1Selected), fullfile(cfg.paths.metrics, ["exp057_tuning_ranking.csv" ...
    "exp057_tuning_grid_results.csv" "exp055_gt_lesion_size_analysis.csv"]), string(v1File("pn0")), string(v1File("pn3"))];
mriT2 = [string(cfg.dataset.mriFiles.T2), string(cfg.dataset.noisyMriFiles.pn3.T2)];
mriT1 = [string(cfg.dataset.mriFiles.T1), string(cfg.dataset.noisyMriFiles.pn3.T1)];
prepare = @(raw) normalizeFixedRange(convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, cfg.preprocessing.normalization.outputRange);
closeTo = @(a, b) abs(a - b) <= 1e-12 * max(1, abs(b));
checks = cell(0, 2);
gtLoaded = false;


%% 0. Ingressi e riferimento v1 congelato

helperFiles = [fullfile(cfg.paths.segmentation, ["generateExp058Prediction.m" "computeT1AnatomicalSupport.m" ...
    "generateExp057Prediction.m" "generateLesionCandidateMask.m" "removeSingleSliceComponents3D.m"]), ...
    fullfile(cfg.paths.preprocessing, ["anisotropicDiffusionSlices.m" "gaussianFilterSlices.m"])];
for f = [priorArtifacts, string(maskFile("pn0")), string(maskFile("pn3")), helperFiles, mriT2, mriT1]
    if ~isfile(f)
        error('exp058:technicallyBlocked', 'EXP-058 TECHNICALLY BLOCKED: missing %s', f);
    end
end
priorBefore = arrayfun(@fileState, priorArtifacts, 'UniformOutput', false);
sel57 = readtable(v1Selected, 'TextType', 'string');
v1Score = sel57.developmentScore;
checks = [checks; {
    "required T1 / T2 MRI, brain masks, frozen v1 artifacts and helpers exist", true
    "frozen v1 on record is S2_TA_M2_G1",            height(sel57) == 1 && sel57.configId == "S2_TA_M2_G1"
    "v1 DevelopmentScore read from artifact = recorded 0.600033865204608", closeTo(v1Score, v1RecordedScore)
    }];


%% 1. 42 predizioni (NESSUN GT) e invarianti di R

fDefs = struct('code', {"F0", "F1", "F2", "F3", "F4", "F5", "F6"}, ...
    'type', {"none", "gaussian", "gaussian", "gaussian", "anisotropic", "anisotropic", "anisotropic"}, ...
    't1', {false, true, false, true, true, false, true}, 't2', {false, false, true, true, false, true, true});
configs = struct([]);
for f = fDefs
    for r = ["R0" "R1" "R2"]
        configs = [configs; struct('id', f.code + "_" + r, 'filterType', f.type, 'filterT1', f.t1, ...
            'filterT2', f.t2, 'recovery', r)]; %#ok<AGROW>
    end
end
ids = [configs.id].';
nConfigs = numel(configs);
checks(end+1, :) = {"exactly 21 unique configurations, base F0_R0 included", ...
    nConfigs == 21 && numel(unique(ids)) == 21 && any(ids == "F0_R0")};

if ~isfolder(candidateDir)
    mkdir(candidateDir);
end
predictions = cell(nConfigs, 2);
detailsAll = cell(nConfigs, 2);
invariantsOk = true;
rawT2 = cell(1, 2); rawT1 = cell(1, 2); brainMasks = cell(1, 2); t2NormByCondition = cell(1, 2);
for n = 1:2
    noise = noiseLevels(n);
    rawT2{n} = loadBrainwebMri(cfg, "T2", noise);
    rawT1{n} = loadBrainwebMri(cfg, "T1", noise);
    t2Norm = prepare(rawT2{n});
    t1Norm = prepare(rawT1{n});
    t2NormByCondition{n} = t2Norm;
    s = load(maskFile(noise), 'candidate');
    brainMasks{n} = s.candidate;
    checks(end+1, :) = {noise + " T1 / T2 normalized in [0,1], brain mask logical 181x217x181", ...
        all(isfinite([t1Norm(:); t2Norm(:)])) && min([t1Norm(:); t2Norm(:)]) >= 0 && ...
        max([t1Norm(:); t2Norm(:)]) <= 1 && islogical(brainMasks{n}) && isequal(size(brainMasks{n}), expectedSize)}; %#ok<SAGROW>
    for i = 1:nConfigs
        [M_pred, details, inter] = generateExp058Prediction(t1Norm, t2Norm, brainMasks{n}, configs(i));
        predictions{i, n} = M_pred;
        detailsAll{i, n} = details;
        % Invarianti preregistrati: v1 (R0) <= R1 <= maskR1, R2 <= maskR2, maskR1 <= maskR2
        invariantsOk = invariantsOk && ~any(inter.v1Prediction & ~inter.maskR1, 'all') && ...
            ~any(inter.maskR1 & ~inter.maskR2, 'all') && ~any(inter.v1Prediction & ~M_pred, 'all') && ...
            ~any(M_pred & ~inter.maskR2, 'all') && ...
            (configs(i).recovery ~= "R0" || isequal(M_pred, inter.v1Prediction)) && ...
            (configs(i).recovery ~= "R1" || ~any(M_pred & ~inter.maskR1, 'all'));
        configuration = configs(i);
        condition = noise;
        metadata = struct('phase', 95, 'experiment', "EXP-058", 'condition', noise, 'configId', configs(i).id, ...
            'details', details, 'gtUsedForGeneration', false, 'heldOutUsed', false);
        save(candidateFile(configs(i).id, noise), 'M_pred', 'configuration', 'condition', 'metadata');
    end
    % R0 <= R1 <= R2 a parità di filtro (stesso marker, maschere annidate)
    for f = 1:numel(fDefs)
        p = arrayfun(@(id) predictions{ids == id, n}, fDefs(f).code + "_" + ["R0" "R1" "R2"], 'UniformOutput', false);
        invariantsOk = invariantsOk && ~any(p{1} & ~p{2}, 'all') && ~any(p{2} & ~p{3}, 'all');
    end
    fprintf('%s: 21 predictions generated\n', noise);
end


%% 2. Verifica e riproduzione della v1 (ancora senza GT)

allSaved = all(arrayfun(@(i) isfile(candidateFile(ids(i), "pn0")) && isfile(candidateFile(ids(i), "pn3")), 1:nConfigs));
baseIdx = find(ids == "F0_R0");
v1Pred = cell(1, 2);
for n = 1:2
    s = load(v1File(noiseLevels(n)), 'M_pred');
    v1Pred{n} = s.M_pred;
end
checks = [checks; {
    "exactly 42 predictions generated and saved before GT", allSaved && numel(predictions) == 42 && ~gtLoaded
    "all predictions logical 181x217x181",           all(cellfun(@(m) islogical(m) && isequal(size(m), expectedSize), predictions(:)))
    "invariants: R0 <= R1 <= R2, R1 <= S2 & T2f > TA_S2, R2 <= S1 & T2f > TA_S2", invariantsOk
    "F0_R0 = frozen v1 pn0 voxel by voxel",          isequal(predictions{baseIdx, 1}, v1Pred{1})
    "F0_R0 = frozen v1 pn3 voxel by voxel",          isequal(predictions{baseIdx, 2}, v1Pred{2})
    }];
if ~isequal(predictions{baseIdx, 1}, v1Pred{1}) || ~isequal(predictions{baseIdx, 2}, v1Pred{2})
    error('exp058:technicallyBlocked', 'EXP-058 TECHNICALLY BLOCKED: F0_R0 does not reproduce the frozen v1.');
end

% Figura GT-free: effetto dei filtri su T2 pn3, slice 91
fig = figure('Color', 'w');
layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'tight', 'Padding', 'tight');
k = 91;
t2s = t2NormByCondition{2}(:, :, k);
views = {t2s, min(max(gaussianFilterSlices(t2s, 0.5, 3, "replicate"), 0), 1), anisotropicDiffusionSlices(t2s)};
names = ["T2 pn3, no filter" "Gaussian sigma 0.5" "anisotropic diffusion (fixed)"];
for v = 1:3
    ax = nexttile(layout);
    imagesc(ax, views{v}.', [0 1]); colormap(ax, gray); axis(ax, 'image');
    set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []); title(ax, names(v) + " (k = 91)");
end
title(layout, 'EXP-058 - noise filters on T2 pn3 (no GT)');
fig.Position(3:4) = [1200 450];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp058_filters_t2_pn3.png'));


%% 3. Ground truth (caricato SOLO ora)

gtLoaded = true;
labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
gtCopy = gtMask;
gtVoxels = nnz(gtMask);
checks(end+1, :) = {"GT = complete label 10, 181x217x181", isequal(gtMask, labels == 10) && isequal(size(gtMask), expectedSize)};


%% 4. Valutazione a volume completo e classifica

gridRows = cell(nConfigs * 2, 23);
dice = zeros(nConfigs, 2);
r = 0;
for i = 1:nConfigs
    c = configs(i);
    for n = 1:2
        d = detailsAll{i, n};
        cnt = computeVoxelConfusion(predictions{i, n}, gtMask);
        dice(i, n) = computeDiceFromConfusion(cnt);
        predVox = cnt.TP + cnt.FP;
        volErr = computeVolumeErrorPercent(gtVoxels, predVox);
        r = r + 1;
        gridRows(r, :) = {c.id, noiseLevels(n), c.filterType, c.filterT1, c.filterT2, c.recovery, ...
            d.t1ThresholdsNormalized(1), d.t1ThresholdsNormalized(2), d.t2ThresholdsNormalized(end), d.S2Voxels, ...
            d.v1Voxels, d.maskR2Voxels, predVox, cnt.TP, cnt.FP, cnt.FN, dice(i, n), computeIoUFromConfusion(cnt), ...
            computePrecisionFromConfusion(cnt), computeRecallFromConfusion(cnt), computeSpecificityFromConfusion(cnt), ...
            volErr.volumeErrorPercent, d.S1Voxels};
    end
end
gridTable = cell2table(gridRows, 'VariableNames', {'configId', 'condition', 'filterType', 'filterT1', 'filterT2', ...
    'recovery', 't1Threshold1', 't1Threshold2', 'taS2Normalized', 'S2Voxels', 'v1SeedVoxels', 'maskR2Voxels', ...
    'predictedVoxels', 'tpVoxels', 'fpVoxels', 'fnVoxels', 'dice', 'iou', 'precision', 'recall', 'specificity', ...
    'volumeErrorPercent', 'S1Voxels'});
writetable(gridTable, fullfile(cfg.paths.metrics, 'exp058_tuning_grid_results.csv'));

developmentScore = (dice(:, 1) + dice(:, 2)) / 2;
weaker = min(dice, [], 2);
filterWeight = arrayfun(@(c) ternary(c.filterType == "anisotropic", 2, 1), configs);
blocks = arrayfun(@(c) double(c.filterT1) + double(c.filterT2), configs) .* filterWeight + ...
    arrayfun(@(c) double(c.recovery == "R1") + 2 * double(c.recovery == "R2"), configs);
[~, idOrder] = sort(ids);
idRank = zeros(nConfigs, 1); idRank(idOrder) = 1:nConfigs;
[~, order] = sortrows([-developmentScore, -weaker, blocks, idRank]);
rankOf = zeros(nConfigs, 1); rankOf(order) = 1:nConfigs;
winnerIdx = order(1);
baseScore = developmentScore(baseIdx);

rankingTable = table(rankOf(order), ids(order), [configs(order).filterType].', [configs(order).filterT1].', ...
    [configs(order).filterT2].', [configs(order).recovery].', dice(order, 1), dice(order, 2), weaker(order), ...
    developmentScore(order), developmentScore(order) - v1Score, blocks(order), order == winnerIdx, ...
    'VariableNames', {'rank', 'configId', 'filterType', 'filterT1', 'filterT2', 'recovery', 'dicePn0', 'dicePn3', ...
    'weakerConditionDice', 'developmentScore', 'deltaVsV1', 'activeBlocks', 'selected'});
writetable(rankingTable, fullfile(cfg.paths.metrics, 'exp058_tuning_ranking.csv'));
disp(rankingTable);

winner = configs(winnerIdx);
checks = [checks; {
    "F0_R0 score reproduces the frozen v1 score",    closeTo(baseScore, v1Score)
    "Dice pn0 / pn3 recorded for all 21, finite",    all(isfinite(dice(:))) && height(gridTable) == 42
    "DevelopmentScore = exact equal-weight mean",    all(developmentScore == (dice(:, 1) + dice(:, 2)) / 2)
    "ranking first by DevelopmentScore, no tolerance", all(diff(developmentScore(order)) <= 0)
    "exactly one selected winner = rank 1, score >= v1", nnz(rankingTable.selected) == 1 && ...
        rankingTable.selected(1) && developmentScore(winnerIdx) >= baseScore
    }];


%% 5. Vincitore e versione principale (regola A1, prima di qualsiasi held-out)

v2Exists = winner.id ~= "F0_R0" && developmentScore(winnerIdx) > v1Score;
if v2Exists
    primary = "v2"; secondary = "v1";
    for n = 1:2
        M_pred = predictions{winnerIdx, n};
        configuration = winner;
        metadata = struct('phase', 95, 'experiment', "EXP-058", 'condition', noiseLevels(n), 'configId', winner.id, ...
            'version', "v2", 'selectionCriterion', "Phase-37 DevelopmentScore, amendment A1", 'developmentOnly', true, ...
            'heldOutUsed', false, 'notYetFrozen', true, 'sourceCandidateFile', string(candidateFile(winner.id, noiseLevels(n))));
        save(v2File(noiseLevels(n)), 'M_pred', 'configuration', 'metadata');
    end
else
    primary = "v1"; secondary = "none";
end
selectedTable = table(winner.id, winner.filterType, winner.filterT1, winner.filterT2, winner.recovery, ...
    dice(winnerIdx, 1), dice(winnerIdx, 2), weaker(winnerIdx), developmentScore(winnerIdx), v1Score, ...
    developmentScore(winnerIdx) - v1Score, v2Exists, primary, secondary, 'VariableNames', {'configId', 'filterType', ...
    'filterT1', 'filterT2', 'recovery', 'dicePn0', 'dicePn3', 'weakerConditionDice', 'developmentScore', ...
    'v1DevelopmentScore', 'deltaVsV1', 'v2Exists', 'primaryVersion', 'secondaryVersion'});
writetable(selectedTable, fullfile(cfg.paths.metrics, 'exp058_selected_configuration.csv'));
fprintf('\nEXP-058 WINNER: %s  DevelopmentScore %.15g (v1 %.15g, delta %+.6g)\n', winner.id, ...
    developmentScore(winnerIdx), v1Score, developmentScore(winnerIdx) - v1Score);
fprintf('PRIMARY VERSION FOR THE FINAL TEST (amendment A1): %s; secondary: %s (not yet frozen)\n\n', primary, secondary);


%% 6. Diagnostiche post-selezione (NON cambiano il vincitore né la versione principale)

winnerBefore = winner.id; primaryBefore = primary;
cmpRows = cell(0, 13);
lesionRows = cell(0, 9);
sizeTable = readtable(phase94File, 'TextType', 'string');
sizeOfLesion = sortrows(sizeTable(sizeTable.condition == "pn0", {'gtLesionId', 'sizeClass'}), 'gtLesionId');
detectedSets = struct();
for n = 1:2
    for which = ["v1" "EXP-058 winner"]
        idx = ternary(which == "v1", baseIdx, winnerIdx);
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
writetable(comparison, fullfile(cfg.paths.metrics, 'exp058_v1_vs_winner.csv'));
writetable(lesionDiag, fullfile(cfg.paths.metrics, 'exp058_winner_lesion_diagnostics.csv'));
disp(comparison); disp(lesionDiag);
for n = 1:2
    before = detectedSets.(matlab.lang.makeValidName(noiseLevels(n) + "v1"));
    after = detectedSets.(matlab.lang.makeValidName(noiseLevels(n) + "EXP-058 winner"));
    fprintf('%s: GT lesions lost vs v1: [%s]; newly detected: [%s]\n', noiseLevels(n), ...
        strjoin(string(find(before & ~after).'), ' '), strjoin(string(find(~before & after).'), ' '));
end
checks(end+1, :) = {"post-selection diagnostics did not change the winner or the primary version", ...
    winner.id == winnerBefore && primary == primaryBefore && rankingTable.configId(1) == winnerBefore};


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
legend(ax, 'DevelopmentScore', 'Dice pn0', 'Dice pn3', 'frozen v1 (F0\_R0)', 'Location', 'southwest');
title(ax, sprintf('EXP-058 - 21 configurations ranked by DevelopmentScore (winner: %s)', winner.id), 'Interpreter', 'none');
fig.Position(3:4) = [1200 520];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp058_tuning_ranking.png'));

fig = figure('Color', 'w');
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact');
for n = 1:2
    ax = nexttile(layout);
    b = comparison(comparison.condition == noiseLevels(n), :);
    bar(ax, categorical(["Dice" "IoU" "Precision" "Recall"], ["Dice" "IoU" "Precision" "Recall"]), ...
        [b.dice b.iou b.precision b.recall].');
    legend(ax, "v1 " + b.configId(1), "EXP-058 winner " + b.configId(2), 'Interpreter', 'none', 'Location', 'northwest');
    ylim(ax, [0 1]); grid(ax, 'on'); title(ax, noiseLevels(n));
end
title(layout, 'EXP-058 - frozen v1 vs EXP-058 winner (complete volume)');
fig.Position(3:4) = [1000 420];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp058_v1_vs_winner.png'));


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
helperCode = strjoin(regexprep(splitlines(string(strjoin(arrayfun(@(f) string(fileread(f)), helperFiles(1:6)), newline))), ...
    '%.*$', ''), newline);
forbidden = {['regionGrow' 'ing('], ['fuseCandidate' 'Masks'], ['localMeanStd' 'Threshold2D('], ['loadBrainweb' 'Mri(cfg, "PD"'], ...
    ['weight' 'ed'], ['computeSlice' 'WiseMetrics('], ['medfilt' '2('], ['imbilat' 'filt('], ['imnlm' 'filt('], ...
    ['imgaussfilt' '3('], ['meanFilter' 'Slices('], ['medianFilter' 'Slices(']};
helperForbidden = {['imc' 'lose('], ['ime' 'rode('], ['imdi' 'late('], ['bwarea' 'open('], ['multithresh(t1Norm(brainMask), ' '3'], ...
    ['multithresh(t2f(supports.S' '1']};
positionRules = {['k >' '= 70'], ['70:' '104'], ['first' 'GtSlice'], ['sizeThreshold' 'Voxels'], ['7 ' 'voxels'], ['min' 'Size']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "only T1 / T2 pn0 / pn3 accessed, no held-out filename", ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "no region growing, PD fusion, local threshold or other filter family", ~any(cellfun(@(f) contains(codeText, f), forbidden))
    "helpers: no extra morphology, other T1 classes or threshold estimated in S1", ...
        ~any(cellfun(@(f) contains(helperCode, f), helperForbidden))
    "no position rule or GT-size threshold in generation, no GT in helpers", ...
        ~any(cellfun(@(f) contains(codeText, f) || contains(helperCode, f), positionRules)) && ~contains(helperCode, ['Ground' 'Truth'])
    "raw T1 / T2 MRI unchanged",                     rawUnchanged
    "brain masks unchanged",                         masksUnchanged
    "frozen v1 / EXP-057 / Phase-94 artifacts unchanged", isequal(priorBefore, priorAfter)
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
    error('exp058:checksFailed', 'EXP-058 checks failed.');
end
fprintf('\nEXP-058 CHECKS: PASS (%d)\n', size(checks, 1));


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
