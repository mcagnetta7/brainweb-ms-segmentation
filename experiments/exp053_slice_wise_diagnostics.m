%% EXP-053 (fase 92): valutazione diagnostica per slice
% M_pred della fase 71 (T2), pn0 e pn3; GT completo (label 10). Asse assiale
% (dimensione 3), tutte le 181 slice. Conteggi e metriche per slice con le
% funzioni formali esistenti (computeSliceWiseMetrics). SOLO DIAGNOSTICA: la
% tabella a volume completo della fase 91 resta il risultato principale;
% nessuna metrica per slice viene mediata. Le figure nascondono (NaN) le
% metriche con denominatore non informativo; il CSV conserva i valori formali.
% Nessuna regola di posizione (soglia in z, ROI, soglie per slice), nessuna
% analisi per lesione, nessun tuning.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
sliceVoxels = expectedSize(1) * expectedSize(2);
phase91File = fullfile(cfg.paths.metrics, 'exp052_complete_3d_metrics.csv');
phase71File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));
functionNames = ["computeVoxelConfusion" "computeDiceFromConfusion" "computeIoUFromConfusion" ...
    "computePrecisionFromConfusion" "computeRecallFromConfusion" "computeSpecificityFromConfusion" ...
    "computeSliceWiseMetrics"];
checks = cell(0, 2);


%% 1. Ingressi

requiredFiles = [string(phase91File), string(phase71File("pn0")), string(phase71File("pn3")), ...
    fullfile(cfg.paths.evaluation, functionNames + ".m")];
for f = requiredFiles
    if ~isfile(f)
        error('exp053:technicallyBlocked', 'PHASE 92 TECHNICALLY BLOCKED: missing %s', f);
    end
end
checks(end+1, :) = {"Phase-91 consolidated CSV exists", isfile(phase91File)};
for n = 1:2
    checks(end+1, :) = {"Phase-71 " + noiseLevels(n) + " M_pred exists", isfile(phase71File(noiseLevels(n)))}; %#ok<SAGROW>
end
for name = functionNames
    checks(end+1, :) = {name + " exists", isfile(fullfile(cfg.paths.evaluation, name + ".m"))}; %#ok<SAGROW>
end
phase91Before = fileState(phase91File);
phase91 = readtable(phase91File, 'TextType', 'string');

predMasks = cell(1, 2);
predStateBefore = cell(1, 2);
for n = 1:2
    predStateBefore{n} = fileState(phase71File(noiseLevels(n)));
    s = load(phase71File(noiseLevels(n)), 'M_pred');
    predMasks{n} = s.M_pred;
end
predCopies = predMasks;
labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;                           % GT completo, nessuna maschera / selezione di slice
gtCopy = gtMask;
checks = [checks; {
    "pn0 M_pred logical",                            islogical(predMasks{1})
    "pn3 M_pred logical",                            islogical(predMasks{2})
    "GT logical (label 10)",                         islogical(gtMask) && isequal(gtMask, labels == 10)
    "all masks 181x217x181",                         isequal(size(predMasks{1}), expectedSize) && ...
        isequal(size(predMasks{2}), expectedSize) && isequal(size(gtMask), expectedSize)
    "prediction and GT dimensions match",            isequal(size(predMasks{1}), size(gtMask)) && isequal(size(predMasks{2}), size(gtMask))
    "axial dimension fixed to dimension 3 (181 slices)", size(gtMask, 3) == 181
    }];


%% 2. Metriche per slice e regressione con la fase 91

perCondition = cell(1, 2);
for n = 1:2
    noise = noiseLevels(n);
    s = computeSliceWiseMetrics(predMasks{n}, gtMask);
    s = addvars(s, repmat(noise, height(s), 1), 'Before', 1, 'NewVariableNames', 'condition');
    perCondition{n} = s;
    p91 = phase91(phase91.condition == noise, :);
    counts = [s.tpVoxels s.fpVoxels s.fnVoxels s.tnVoxels];
    checks = [checks; {
        "exactly 181 " + noise + " slices analyzed",  height(s) == 181 && isequal(s.sliceIndex, (1:181).')
        noise + " each slice contains 39,277 voxels",  all(s.totalSliceVoxels == sliceVoxels) && sliceVoxels == 39277
        noise + " every slice TP/FP/FN/TN non-negative integers", all(counts(:) >= 0) && all(counts(:) == fix(counts(:)))
        noise + " every slice TP+FP+FN+TN = 39,277",    all(sum(counts, 2) == sliceVoxels)
        noise + " sum TP = Phase-91 TP",                sum(s.tpVoxels) == p91.tpVoxels
        noise + " sum FP = Phase-91 FP",                sum(s.fpVoxels) == p91.fpVoxels
        noise + " sum FN = Phase-91 FN",                sum(s.fnVoxels) == p91.fnVoxels
        noise + " sum TN = Phase-91 TN",                sum(s.tnVoxels) == p91.tnVoxels
        noise + " sum GT-positive voxels = 3,512",      sum(s.gtPositiveVoxels) == 3512
        noise + " sum predicted-positive voxels = Phase-91 TP + FP", sum(s.predictedPositiveVoxels) == p91.tpVoxels + p91.fpVoxels
        noise + " all Dice / IoU / Precision / Recall / Specificity finite in [0,1]", ...
            all(isfinite([s.dice; s.iou; s.precision; s.recall; s.specificity])) && ...
            all([s.dice; s.iou; s.precision; s.recall; s.specificity] >= 0) && ...
            all([s.dice; s.iou; s.precision; s.recall; s.specificity] <= 1)
        noise + " hasGtLesion / hasPrediction / hasOverlap agree with counts", ...
            isequal(s.hasGtLesion, s.gtPositiveVoxels > 0) && isequal(s.hasPrediction, s.predictedPositiveVoxels > 0) && ...
            isequal(s.hasOverlap, s.tpVoxels > 0)
        noise + " informative flags agree with denominators", ...
            isequal(s.diceIouInformative, s.tpVoxels + s.fpVoxels + s.fnVoxels > 0) && ...
            isequal(s.precisionInformative, s.tpVoxels + s.fpVoxels > 0) && isequal(s.recallInformative, s.tpVoxels + s.fnVoxels > 0)
        noise + " both-empty slices keep formal conventions (Dice = IoU = Precision = Recall = 1)", ...
            all(s.dice(~s.diceIouInformative) == 1) && all(s.iou(~s.diceIouInformative) == 1) && ...
            all(s.precision(~s.precisionInformative) == 1) && all(s.recall(~s.recallInformative) == 1)
        }]; %#ok<AGROW>
end
sliceTable = [perCondition{1}; perCondition{2}];
checks(end+1, :) = {"exactly 362 CSV rows overall", height(sliceTable) == 362};
writetable(sliceTable, fullfile(cfg.paths.metrics, 'exp053_slice_wise_metrics.csv'));


%% 3. Riepiloghi diagnostici (descrittivi, non punteggi)

summaryRows = cell(2, 11);
rankingRows = cell(0, 5);
for n = 1:2
    s = perCondition{n};
    g = s.gtPositiveVoxels > 0; p = s.predictedPositiveVoxels > 0;
    summaryRows(n, :) = {noiseLevels(n), height(s), nnz(g), nnz(p), nnz(g & p), nnz(g & ~p), nnz(~g & p), ...
        nnz(~g & ~p), nnz(s.tpVoxels > 0), nnz(s.fpVoxels > 0), nnz(s.fnVoxels > 0)};
    checks(end+1, :) = {noiseLevels(n) + " slice categories internally consistent", ...
        nnz(g & p) + nnz(g & ~p) + nnz(~g & p) + nnz(~g & ~p) == 181 && nnz(g) == nnz(g & p) + nnz(g & ~p) && ...
        nnz(p) == nnz(g & p) + nnz(~g & p)}; %#ok<SAGROW>
    for kind = ["FP" "FN" "TP"]
        values = s.(char(lower(kind) + "Voxels"));
        ranked = sortrows([-values, s.sliceIndex]);             % conteggio decrescente, poi slice crescente
        top = ranked(1:5, :);
        for r = 1:5
            rankingRows(end+1, :) = {noiseLevels(n), kind, r, top(r, 2), -top(r, 1)}; %#ok<SAGROW>
        end
    end
end
summary = cell2table(summaryRows, 'VariableNames', {'condition', 'totalSlices', 'gtPositiveSlices', ...
    'predictionPositiveSlices', 'bothPositiveSlices', 'gtOnlyPositiveSlices', 'predictionOnlyPositiveSlices', ...
    'bothEmptySlices', 'slicesWithTP', 'slicesWithFP', 'slicesWithFN'});
writetable(summary, fullfile(cfg.paths.metrics, 'exp053_slice_diagnostic_summary.csv'));
rankings = cell2table(rankingRows, 'VariableNames', {'condition', 'count', 'rank', 'sliceIndex', 'voxels'});
writetable(rankings, fullfile(cfg.paths.metrics, 'exp053_slice_top5_rankings.csv'));
rankAgain = sortrows([-perCondition{1}.fpVoxels, perCondition{1}.sliceIndex]);
checks(end+1, :) = {"top-5 FP / FN rankings deterministic (count desc, then slice index)", ...
    isequal(rankAgain(1:5, 2).', rankings.sliceIndex(rankings.condition == "pn0" & rankings.count == "FP").')};

% Confronto descrittivo pn0 / pn3 (stesse slice)
fp0 = perCondition{1}.fpVoxels > 0; fp3 = perCondition{2}.fpVoxels > 0;
fn0 = perCondition{1}.fnVoxels > 0; fn3 = perCondition{2}.fnVoxels > 0;
cross = table(nnz(fp0 & fp3), nnz(fp0 & ~fp3), nnz(~fp0 & fp3), nnz(fn0 & fn3), nnz(fn0 & ~fn3), nnz(~fn0 & fn3), ...
    'VariableNames', {'slicesFPBoth', 'slicesFPOnlyPn0', 'slicesFPOnlyPn3', 'slicesFNBoth', 'slicesFNOnlyPn0', ...
    'slicesFNOnlyPn3'});
writetable(cross, fullfile(cfg.paths.metrics, 'exp053_slice_cross_condition.csv'));

disp(summary);
for n = 1:2
    s = perCondition{n};
    nonEmptyGt = s.sliceIndex(s.gtPositiveVoxels > 0); nonEmptyPred = s.sliceIndex(s.predictedPositiveVoxels > 0);
    fprintf('%s: GT-positive slices k %d-%d, prediction-positive slices k %d-%d\n', noiseLevels(n), ...
        min(nonEmptyGt), max(nonEmptyGt), min(nonEmptyPred), max(nonEmptyPred));
    for kind = ["FP" "FN" "TP"]
        r = rankings(rankings.condition == noiseLevels(n) & rankings.count == kind, :);
        fprintf('  top-5 %s slices (k:voxels): %s\n', kind, strjoin(compose('%d:%d', r.sliceIndex, r.voxels).', ', '));
    end
end
disp(cross);


%% 4. Figure diagnostiche (le metriche non informative sono nascoste solo nel grafico)

tableBeforePlots = sliceTable;
for n = 1:2
    s = perCondition{n};
    k = s.sliceIndex;

    fig = figure('Color', 'w');
    ax = axes(fig);
    plot(ax, k, s.gtPositiveVoxels, 'k-', k, s.predictedPositiveVoxels, 'b-', k, s.tpVoxels, 'g-', ...
        k, s.fpVoxels, 'r-', k, s.fnVoxels, 'm-', 'LineWidth', 1.1);
    legend(ax, 'GT-positive', 'predicted-positive', 'TP', 'FP', 'FN', 'Location', 'northwest');
    xlabel(ax, 'Axial slice index k'); ylabel(ax, 'Voxel count');
    xlim(ax, [1 181]); grid(ax, 'on');
    title(ax, sprintf('EXP-053 %s - voxel counts per axial slice (diagnostic only)', noiseLevels(n)));
    fig.Position(3:4) = [1000 450];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp053_%s_slice_counts.png', noiseLevels(n))));

    diceShown = s.dice; diceShown(~s.diceIouInformative) = NaN;
    iouShown = s.iou; iouShown(~s.diceIouInformative) = NaN;
    precisionShown = s.precision; precisionShown(~s.precisionInformative) = NaN;
    recallShown = s.recall; recallShown(~s.recallInformative) = NaN;
    fig = figure('Color', 'w');
    ax = axes(fig);
    plot(ax, k, diceShown, 'b.-', k, iouShown, 'c.-', k, precisionShown, 'r.-', k, recallShown, 'g.-');
    legend(ax, 'Dice', 'IoU', 'Precision', 'Recall', 'Location', 'northwest');
    xlabel(ax, 'Axial slice index k'); ylabel(ax, 'Metric value');
    xlim(ax, [1 181]); ylim(ax, [0 1]); grid(ax, 'on');
    title(ax, {sprintf('EXP-053 %s - metrics per axial slice (diagnostic only)', noiseLevels(n)), ...
        'missing points = metric hidden for an uninformative denominator (CSV keeps the formal value)'});
    fig.Position(3:4) = [1000 450];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp053_%s_slice_metrics.png', noiseLevels(n))));
end
checks(end+1, :) = {"plotting masks do not modify the saved values", isequal(sliceTable, tableBeforePlots)};


%% 5. Controlli finali

predUnchanged = true;
for n = 1:2
    s = load(phase71File(noiseLevels(n)), 'M_pred');
    predUnchanged = predUnchanged && isequal(fileState(phase71File(noiseLevels(n))), predStateBefore{n}) && ...
        isequal(s.M_pred, predCopies{n});
end
scriptText = fileread([mfilename('fullpath') '.m']);
codeText = strjoin(regexprep(splitlines(string(scriptText)), '%.*$', ''), newline);
aggregates = {['mea' 'n('], ['med' 'ian('], ['Development' 'Score'], ['development' 'Score'], ['nanm' 'ean(']};
forbiddenAnalysis = {['volume' 'Error'], ['computeVolume' 'ErrorPercent('], ['bwconn' 'comp('], ['region' 'props'], ...
    ['bwla' 'bel('], ['lesion' 'Wise'], ['small' 'Lesion'], ['large' 'Lesion']};
segmentation = {['loadBrainweb' 'Mri('], ['multi' 'thresh('], ['imquan' 'tize('], ['imo' 'pen('], ['imc' 'lose('], ...
    ['ime' 'rode('], ['imdi' 'late('], ['save' '(']};
locationRules = {['zCut' 'off'], ['slice' 'Threshold'], ['exclude' 'Slices'], ['roi' 'Mask']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "no slice-wise mean / median metric, no aggregate score", ~any(cellfun(@(f) contains(codeText, f), aggregates))
    "no slice-wise volume error, no components, no lesion-wise / size analysis", ~any(cellfun(@(f) contains(codeText, f), forbiddenAnalysis))
    "no segmentation operation / no mask saved",     ~any(cellfun(@(f) contains(codeText, f), segmentation))
    "no location-specific rule created",             ~any(cellfun(@(f) contains(codeText, f), locationRules))
    "no held-out condition referenced",              ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "Phase-71 source masks unchanged",               predUnchanged && isequal(predMasks, predCopies)
    "Phase-91 consolidated CSV unchanged",           isequal(fileState(phase91File), phase91Before)
    "GT unchanged",                                  isequal(gtMask, gtCopy)
    "config.m unchanged",                            isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];

for c = 1:size(checks, 1)
    if checks{c, 2}
        status = 'ok';
    else
        status = 'FAILED';
    end
    fprintf('%-90s %s\n', checks{c, 1}, status);
end
if any(~[checks{:, 2}])
    error('exp053:checksFailed', 'EXP-053 checks failed.');
end
fprintf('\nEXP-053 CHECKS: PASS (%d)\n', size(checks, 1));


function state = fileState(f)
%FILESTATE Data, dimensione e contenuto di un file (verifica di immutabilità).
    info = dir(f);
    state = {info.datenum, info.bytes, fileread(f)};
end
