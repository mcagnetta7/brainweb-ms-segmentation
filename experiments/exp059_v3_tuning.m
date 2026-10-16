%% EXP-059 (emendamento A2): v3 = base v2 + diffusione 3D (D) x apertura (M) x componenti (G)
% Griglia preregistrata di 12 configurazioni (2 D x 3 M x 2 G), pn0 e pn3:
%   D2 diffusione anisotropa per slice (= v2) | D3 diffusione anisotropa sull'intero volume
%   M0 nessuna apertura | M1 diamond 1 | M2 square 3 (= v2)
%   G0 nessuna | G1 rimozione delle componenti 3D (26) su una sola slice (= v2)
% SEZIONE 1: 24 predizioni SENZA GT (salvate). SEZIONE 2: D2_M2_G1 = v2 congelata.
% SEZIONE 3: GT. SEZIONE 4: Dice, DevelopmentScore, classifica (fase 37).
% SEZIONE 5: vincitore e versione principale (regola A2, prima di ogni held-out).
% SEZIONE 6: diagnostiche post-selezione. Ultimo esperimento di sviluppo prima del test.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
v2RecordedScore = 0.66116938387951;
candidateDir = fullfile(cfg.paths.processedData, 'phase95_exp059_candidates');
candidateFile = @(id, noise) fullfile(candidateDir, sprintf('exp059_%s_%s.mat', id, noise));
v3File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase95_exp059_v3_%s_selected_prediction.mat', noise));
v2File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase95_exp058_v2_%s_selected_prediction.mat', noise));
v1File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase95_exp057_t2_%s_selected_prediction.mat', noise));
maskFile = @(noise) fullfile(cfg.paths.processedData, sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));
v2Selected = fullfile(cfg.paths.metrics, 'exp058_selected_configuration.csv');
phase94File = fullfile(cfg.paths.metrics, 'exp055_gt_lesion_size_analysis.csv');
priorArtifacts = [string(v2Selected), fullfile(cfg.paths.metrics, ["exp058_tuning_ranking.csv" ...
    "exp058_tuning_grid_results.csv" "exp057_selected_configuration.csv" "exp055_gt_lesion_size_analysis.csv"]), ...
    string(v2File("pn0")), string(v2File("pn3")), string(v1File("pn0")), string(v1File("pn3"))];
mriT2 = [string(cfg.dataset.mriFiles.T2), string(cfg.dataset.noisyMriFiles.pn3.T2)];
mriT1 = [string(cfg.dataset.mriFiles.T1), string(cfg.dataset.noisyMriFiles.pn3.T1)];
prepare = @(raw) normalizeFixedRange(convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, cfg.preprocessing.normalization.outputRange);
closeTo = @(a, b) abs(a - b) <= 1e-12 * max(1, abs(b));
checks = cell(0, 2);
gtLoaded = false;


%% 0. Ingressi e riferimento v2 congelato

helperFiles = [fullfile(cfg.paths.segmentation, ["generateExp059Prediction.m" "computeT1AnatomicalSupport.m" ...
    "generateExp057Prediction.m" "generateLesionCandidateMask.m" "removeSingleSliceComponents3D.m"]), ...
    fullfile(cfg.paths.preprocessing, ["anisotropicDiffusionSlices.m" "anisotropicDiffusionVolume3D.m"])];
for f = [priorArtifacts, string(maskFile("pn0")), string(maskFile("pn3")), helperFiles, mriT2, mriT1]
    if ~isfile(f)
        error('exp059:technicallyBlocked', 'EXP-059 TECHNICALLY BLOCKED: missing %s', f);
    end
end
priorBefore = arrayfun(@fileState, priorArtifacts, 'UniformOutput', false);
sel58 = readtable(v2Selected, 'TextType', 'string');
v2Score = sel58.developmentScore;
checks = [checks; {
    "required T1 / T2 MRI, brain masks, frozen v1 / v2 artifacts and helpers exist", true
    "frozen v2 on record is F5_R0",                  height(sel58) == 1 && sel58.configId == "F5_R0"
    "v2 DevelopmentScore read from artifact = recorded 0.66116938387951", closeTo(v2Score, v2RecordedScore)
    }];


%% 1. 24 predizioni (NESSUN GT)

mDefs = struct('code', {"M0", "M1", "M2"}, 'type', {"none", "diamond", "square"}, 'param', {0, 1, 3});
gDefs = struct('code', {"G0", "G1"}, 'filter', {"none", "minOccupiedSlices"});
configs = struct([]);
for d = ["D2" "D3"]
    for m = mDefs
        for g = gDefs
            configs = [configs; struct('id', d + "_" + m.code + "_" + g.code, 'diffusion', d, 'openingType', m.type, ...
                'openingParameter', m.param, 'componentFilter', g.filter, 'componentConnectivity', 26, ...
                'minimumOccupiedSlices', 2)]; %#ok<AGROW>
        end
    end
end
ids = [configs.id].';
nConfigs = numel(configs);
checks(end+1, :) = {"exactly 12 unique configurations, base D2_M2_G1 included", ...
    nConfigs == 12 && numel(unique(ids)) == 12 && any(ids == "D2_M2_G1")};

if ~isfolder(candidateDir)
    mkdir(candidateDir);
end
predictions = cell(nConfigs, 2);
detailsAll = cell(nConfigs, 2);
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
        [M_pred, details] = generateExp059Prediction(t1Norm, t2Norm, brainMasks{n}, configs(i));
        predictions{i, n} = M_pred;
        detailsAll{i, n} = details;
        configuration = configs(i);
        condition = noise;
        metadata = struct('phase', 95, 'experiment', "EXP-059", 'condition', noise, 'configId', configs(i).id, ...
            'details', details, 'gtUsedForGeneration', false, 'heldOutUsed', false);
        save(candidateFile(configs(i).id, noise), 'M_pred', 'configuration', 'condition', 'metadata');
    end
    fprintf('%s: 12 predictions generated\n', noise);
end


%% 2. Verifica e riproduzione della v2 (ancora senza GT)

allSaved = all(arrayfun(@(i) isfile(candidateFile(ids(i), "pn0")) && isfile(candidateFile(ids(i), "pn3")), 1:nConfigs));
baseIdx = find(ids == "D2_M2_G1");
v2Pred = cell(1, 2);
for n = 1:2
    s = load(v2File(noiseLevels(n)), 'M_pred');
    v2Pred{n} = s.M_pred;
end
reducesOnly = true;
for n = 1:2
    for d = ["D2" "D3"]
        p = @(m, g) predictions{ids == d + "_" + m + "_" + g, n};
        for g = ["G0" "G1"]
            reducesOnly = reducesOnly && ~any(p("M1", g) & ~p("M0", g), 'all') && ~any(p("M2", g) & ~p("M0", g), 'all');
        end
        for m = ["M0" "M1" "M2"]
            reducesOnly = reducesOnly && ~any(p(m, "G1") & ~p(m, "G0"), 'all');
        end
    end
end
checks = [checks; {
    "exactly 24 predictions generated and saved before GT", allSaved && numel(predictions) == 24 && ~gtLoaded
    "all predictions logical 181x217x181",           all(cellfun(@(m) islogical(m) && isequal(size(m), expectedSize), predictions(:)))
    "opening and G only remove voxels (M1, M2 <= M0; G1 <= G0)", reducesOnly
    "D2_M2_G1 = frozen v2 pn0 voxel by voxel",       isequal(predictions{baseIdx, 1}, v2Pred{1})
    "D2_M2_G1 = frozen v2 pn3 voxel by voxel",       isequal(predictions{baseIdx, 2}, v2Pred{2})
    }];
if ~isequal(predictions{baseIdx, 1}, v2Pred{1}) || ~isequal(predictions{baseIdx, 2}, v2Pred{2})
    error('exp059:technicallyBlocked', 'EXP-059 TECHNICALLY BLOCKED: D2_M2_G1 does not reproduce the frozen v2.');
end

% Figura GT-free: D2 vs D3 su T2 pn3, slice 91
fig = figure('Color', 'w');
layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'tight', 'Padding', 'tight');
k = 91;
d2Vol = anisotropicDiffusionSlices(t2NormByCondition{2}(:, :, k));
d3Vol = anisotropicDiffusionVolume3D(t2NormByCondition{2});
views = {t2NormByCondition{2}(:, :, k), d2Vol, d3Vol(:, :, k)};
names = ["T2 pn3, no filter" "D2 slice-wise diffusion (v2)" "D3 whole-volume diffusion"];
for v = 1:3
    ax = nexttile(layout);
    imagesc(ax, views{v}.', [0 1]); colormap(ax, gray); axis(ax, 'image');
    set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []); title(ax, names(v) + " (k = 91)");
end
title(layout, 'EXP-059 - 2D vs 3D anisotropic diffusion on T2 pn3 (no GT)');
fig.Position(3:4) = [1200 450];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp059_diffusion_2d_vs_3d.png'));
clear d3Vol


%% 3. Ground truth (caricato SOLO ora)

gtLoaded = true;
labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
gtCopy = gtMask;
gtVoxels = nnz(gtMask);
checks(end+1, :) = {"GT = complete label 10, 181x217x181", isequal(gtMask, labels == 10) && isequal(size(gtMask), expectedSize)};


%% 4. Valutazione a volume completo e classifica

gridRows = cell(nConfigs * 2, 19);
dice = zeros(nConfigs, 2);
r = 0;
for i = 1:nConfigs
    c = configs(i);
    for n = 1:2
        dt = detailsAll{i, n};
        cnt = computeVoxelConfusion(predictions{i, n}, gtMask);
        dice(i, n) = computeDiceFromConfusion(cnt);
        predVox = cnt.TP + cnt.FP;
        volErr = computeVolumeErrorPercent(gtVoxels, predVox);
        r = r + 1;
        gridRows(r, :) = {c.id, noiseLevels(n), c.diffusion, ...
            c.openingType + ternary(c.openingType == "none", "", string(c.openingParameter)), c.componentFilter, ...
            dt.t2ThresholdsNormalized(end), dt.candidateVoxels, predVox, cnt.TP, cnt.FP, cnt.FN, dice(i, n), ...
            computeIoUFromConfusion(cnt), computePrecisionFromConfusion(cnt), computeRecallFromConfusion(cnt), ...
            computeSpecificityFromConfusion(cnt), volErr.volumeErrorPercent, dt.S2Voxels, dt.removedComponents};
    end
end
gridTable = cell2table(gridRows, 'VariableNames', {'configId', 'condition', 'diffusion', 'morphology', ...
    'componentRule', 'taS2Normalized', 'candidateVoxels', 'predictedVoxels', 'tpVoxels', 'fpVoxels', 'fnVoxels', ...
    'dice', 'iou', 'precision', 'recall', 'specificity', 'volumeErrorPercent', 'S2Voxels', 'removedComponents'});
writetable(gridTable, fullfile(cfg.paths.metrics, 'exp059_tuning_grid_results.csv'));

developmentScore = (dice(:, 1) + dice(:, 2)) / 2;
weaker = min(dice, [], 2);
complexityPenalty = arrayfun(@(c) double(c.diffusion == "D3") + double(c.openingType ~= "none") + ...
    double(c.componentFilter ~= "none"), configs);
[~, idOrder] = sort(ids);
idRank = zeros(nConfigs, 1); idRank(idOrder) = 1:nConfigs;
[~, order] = sortrows([-developmentScore, -weaker, complexityPenalty, idRank]);
rankOf = zeros(nConfigs, 1); rankOf(order) = 1:nConfigs;
winnerIdx = order(1);
baseScore = developmentScore(baseIdx);

rankingTable = table(rankOf(order), ids(order), [configs(order).diffusion].', [configs(order).openingType].', ...
    [configs(order).componentFilter].', dice(order, 1), dice(order, 2), weaker(order), developmentScore(order), ...
    developmentScore(order) - v2Score, complexityPenalty(order), order == winnerIdx, ...
    'VariableNames', {'rank', 'configId', 'diffusion', 'opening', 'componentRule', 'dicePn0', 'dicePn3', ...
    'weakerConditionDice', 'developmentScore', 'deltaVsV2', 'complexityPenalty', 'selected'});
writetable(rankingTable, fullfile(cfg.paths.metrics, 'exp059_tuning_ranking.csv'));
disp(rankingTable);

winner = configs(winnerIdx);
checks = [checks; {
    "D2_M2_G1 score reproduces the frozen v2 score", closeTo(baseScore, v2Score)
    "Dice pn0 / pn3 recorded for all 12, finite",    all(isfinite(dice(:))) && height(gridTable) == 24
    "DevelopmentScore = exact equal-weight mean",    all(developmentScore == (dice(:, 1) + dice(:, 2)) / 2)
    "ranking first by DevelopmentScore, no tolerance", all(diff(developmentScore(order)) <= 0)
    "exactly one selected winner = rank 1, score >= v2 base", nnz(rankingTable.selected) == 1 && ...
        rankingTable.selected(1) && developmentScore(winnerIdx) >= baseScore
    }];


%% 5. Vincitore e versione principale (regola A2, prima di qualsiasi held-out)

v3Exists = winner.id ~= "D2_M2_G1" && developmentScore(winnerIdx) > v2Score;
if v3Exists
    primary = "v3";
    for n = 1:2
        M_pred = predictions{winnerIdx, n};
        configuration = winner;
        metadata = struct('phase', 95, 'experiment', "EXP-059", 'condition', noiseLevels(n), 'configId', winner.id, ...
            'version', "v3", 'selectionCriterion', "Phase-37 DevelopmentScore, amendment A2", 'developmentOnly', true, ...
            'heldOutUsed', false, 'notYetFrozen', true, 'sourceCandidateFile', string(candidateFile(winner.id, noiseLevels(n))));
        save(v3File(noiseLevels(n)), 'M_pred', 'configuration', 'metadata');
    end
else
    primary = "v2";
end
selectedTable = table(winner.id, winner.diffusion, winner.openingType, winner.openingParameter, winner.componentFilter, ...
    dice(winnerIdx, 1), dice(winnerIdx, 2), weaker(winnerIdx), developmentScore(winnerIdx), v2Score, ...
    developmentScore(winnerIdx) - v2Score, v3Exists, primary, 'VariableNames', {'configId', 'diffusion', ...
    'openingType', 'openingParameter', 'componentRule', 'dicePn0', 'dicePn3', 'weakerConditionDice', ...
    'developmentScore', 'v2DevelopmentScore', 'deltaVsV2', 'v3Exists', 'primaryVersion'});
writetable(selectedTable, fullfile(cfg.paths.metrics, 'exp059_selected_configuration.csv'));
fprintf('\nEXP-059 WINNER: %s  DevelopmentScore %.15g (v2 %.15g, delta %+.6g)\n', winner.id, ...
    developmentScore(winnerIdx), v2Score, developmentScore(winnerIdx) - v2Score);
fprintf('PRIMARY VERSION FOR THE FINAL TEST (amendment A2): %s; secondary locked versions: the other frozen versions (not yet frozen)\n\n', primary);


%% 6. Diagnostiche post-selezione (NON cambiano il vincitore né la versione principale)

winnerBefore = winner.id; primaryBefore = primary;
cmpRows = cell(0, 13);
lesionRows = cell(0, 9);
sizeTable = readtable(phase94File, 'TextType', 'string');
sizeOfLesion = sortrows(sizeTable(sizeTable.condition == "pn0", {'gtLesionId', 'sizeClass'}), 'gtLesionId');
detectedSets = struct();
for n = 1:2
    for which = ["v2" "EXP-059 winner"]
        idx = ternary(which == "v2", baseIdx, winnerIdx);
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
writetable(comparison, fullfile(cfg.paths.metrics, 'exp059_v2_vs_winner.csv'));
writetable(lesionDiag, fullfile(cfg.paths.metrics, 'exp059_winner_lesion_diagnostics.csv'));
disp(comparison); disp(lesionDiag);
for n = 1:2
    before = detectedSets.(matlab.lang.makeValidName(noiseLevels(n) + "v2"));
    after = detectedSets.(matlab.lang.makeValidName(noiseLevels(n) + "EXP-059 winner"));
    fprintf('%s: GT lesions lost vs v2: [%s]; newly detected: [%s]\n', noiseLevels(n), ...
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
xtickangle(ax, 45);
ylabel(ax, 'complete-volume Dice'); grid(ax, 'on');
legend(ax, 'DevelopmentScore', 'Dice pn0', 'Dice pn3', 'frozen v2 (D2\_M2\_G1)', 'Location', 'southwest');
title(ax, sprintf('EXP-059 - 12 configurations ranked by DevelopmentScore (winner: %s)', winner.id), 'Interpreter', 'none');
fig.Position(3:4) = [1000 500];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp059_tuning_ranking.png'));

fig = figure('Color', 'w');
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact');
for n = 1:2
    ax = nexttile(layout);
    b = comparison(comparison.condition == noiseLevels(n), :);
    bar(ax, categorical(["Dice" "IoU" "Precision" "Recall"], ["Dice" "IoU" "Precision" "Recall"]), ...
        [b.dice b.iou b.precision b.recall].');
    legend(ax, "v2 " + b.configId(1), "EXP-059 winner " + b.configId(2), 'Interpreter', 'none', 'Location', 'northwest');
    ylim(ax, [0 1]); grid(ax, 'on'); title(ax, noiseLevels(n));
end
title(layout, 'EXP-059 - frozen v2 vs EXP-059 winner (complete volume)');
fig.Position(3:4) = [1000 420];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp059_v2_vs_winner.png'));


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
helperCode = strjoin(regexprep(splitlines(string(strjoin(arrayfun(@(f) string(fileread(f)), helperFiles), newline))), ...
    '%.*$', ''), newline);
forbidden = {['regionGrow' 'ing('], ['fuseCandidate' 'Masks'], ['localMeanStd' 'Threshold2D('], ['loadBrainweb' 'Mri(cfg, "PD"'], ...
    ['weight' 'ed'], ['computeSlice' 'WiseMetrics('], ['medfilt' '2('], ['imbilat' 'filt('], ['imnlm' 'filt('], ...
    ['gaussianFilter' 'Slices('], ['imrecon' 'struct('], ['generateExp058' 'Prediction(']};
helperForbidden = {['imc' 'lose('], ['ime' 'rode('], ['imdi' 'late('], ['bwarea' 'open('], ['imrecon' 'struct('], ...
    ['multithresh(t1Norm(brainMask), ' '3'], ['Slices(' 't1'], ['Volume3D(' 't1']};
positionRules = {['k >' '= 70'], ['70:' '104'], ['first' 'GtSlice'], ['sizeThreshold' 'Voxels'], ['7 ' 'voxels'], ['min' 'Size']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "only T1 / T2 pn0 / pn3 accessed, no held-out filename", ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "no region growing, PD, local threshold, recovery, Gaussian or other filter family", ~any(cellfun(@(f) contains(codeText, f), forbidden))
    "helpers: no support change, no T1 filtering, no recovery or extra morphology", ...
        ~any(cellfun(@(f) contains(helperCode, f), helperForbidden))
    "no position rule or GT-size threshold in generation, no GT in helpers", ...
        ~any(cellfun(@(f) contains(codeText, f) || contains(helperCode, f), positionRules)) && ~contains(helperCode, ['Ground' 'Truth'])
    "raw T1 / T2 MRI unchanged",                     rawUnchanged
    "brain masks unchanged",                         masksUnchanged
    "frozen v1 / v2 / EXP-057 / EXP-058 / Phase-94 artifacts unchanged", isequal(priorBefore, priorAfter)
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
    error('exp059:checksFailed', 'EXP-059 checks failed.');
end
fprintf('\nEXP-059 CHECKS: PASS (%d)\n', size(checks, 1));


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
