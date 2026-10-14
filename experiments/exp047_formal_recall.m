%% EXP-047 (fase 86): Recall / Sensitivity formale
% Catena: M_pred (fase 71, T2) + M_GT (label 10, volume completo)
%   -> computeVoxelConfusion (fase 82) -> computeRecallFromConfusion
%   Recall = TP / (TP + FN) (= Sensitivity); convenzione 0/0 -> 1 (non
%   indica una buona predizione). FP e TN non entrano nella formula.
% Misura per voxel, non per lesione. La Precision della fase 85 è letta solo
% per una descrizione affiancata (nessun punteggio combinato).
% Un valore per volume (pn0, pn3). Nessun'altra metrica, nessun aggregato,
% nessuna analisi per slice o per lesione, nessuna modifica della segmentazione.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
confusionFile = fullfile(cfg.paths.metrics, 'exp043_voxel_confusion_matrix.csv');
decisionFile = fullfile(cfg.paths.metrics, 'phase81_multimodal_decision.csv');
precisionFile = fullfile(cfg.paths.metrics, 'exp046_formal_precision.csv');
phase71File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));
confusionFunction = fullfile(cfg.paths.evaluation, 'computeVoxelConfusion.m');
recallFunction = fullfile(cfg.paths.evaluation, 'computeRecallFromConfusion.m');
checks = cell(0, 2);


%% 1. Artefatti e predizioni

for f = string({confusionFile, decisionFile, precisionFile})
    if ~isfile(f)
        error('exp047:technicallyBlocked', 'PHASE 86 TECHNICALLY BLOCKED: missing %s', f);
    end
end
decision = readtable(decisionFile, 'TextType', 'string');
checks = [checks; {
    "EXP-043 confusion CSV exists",                   isfile(confusionFile)
    "computeVoxelConfusion exists",                   isfile(confusionFunction)
    "computeRecallFromConfusion exists",              isfile(recallFunction)
    "Phase-81 retained method = Phase-71 T2 M_pred",  decision.decision == "REJECT_MULTIMODAL_FUSION" && ...
        decision.canonicalMethodAfterPhase81 == "Phase-71 T2 M_pred"
    }];
predMasks = cell(1, 2);
fileInfoBefore = cell(1, 2);
for n = 1:2
    noise = noiseLevels(n);
    checks(end+1, :) = {"Phase-71 " + noise + " M_pred exists", isfile(phase71File(noise))}; %#ok<SAGROW>
    if ~isfile(phase71File(noise))
        error('exp047:technicallyBlocked', 'PHASE 86 TECHNICALLY BLOCKED: missing %s', phase71File(noise));
    end
    fileInfoBefore{n} = dir(phase71File(noise));
    s = load(phase71File(noise), 'M_pred');
    predMasks{n} = s.M_pred;
    checks(end+1, :) = {noise + " prediction logical 181x217x181", ...
        islogical(predMasks{n}) && isequal(size(predMasks{n}), expectedSize)}; %#ok<SAGROW>
end
predCopies = predMasks;

labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;                           % GT completo, nessuna maschera / ROI
gtCopy = gtMask;
checks = [checks; {
    "GT logical 181x217x181",                         islogical(gtMask) && isequal(size(gtMask), expectedSize)
    "complete GT = label 10 (all label-10 voxels kept)", isequal(gtMask, labels == 10) && nnz(gtMask) == nnz(labels == 10)
    "prediction and GT dimensions match",             isequal(size(predMasks{1}), size(gtMask)) && isequal(size(predMasks{2}), size(gtMask))
    }];


%% 2. Conteggi (fase 82) e Recall

functionCode = strjoin(regexprep(splitlines(string(fileread(recallFunction))), '%.*$', ''), newline);
checks(end+1, :) = {"Recall function uses TP / FN only (no FP, no TN, no voxel counting, no file access)", ...
    ~contains(functionCode, 'FP') && ~contains(functionCode, 'TN') && ~contains(functionCode, ['nn' 'z(']) && ...
    ~contains(functionCode, ['lo' 'ad('])};

phase82 = readtable(confusionFile, 'TextType', 'string');
phase85 = readtable(precisionFile, 'TextType', 'string');
rows = cell(2, 8);
for n = 1:2
    noise = noiseLevels(n);
    counts = computeVoxelConfusion(predMasks{n}, gtMask);
    recallValue = computeRecallFromConfusion(counts);
    recallNumerator = counts.TP;
    recallDenominator = counts.TP + counts.FN;
    gtPositiveVoxels = nnz(gtMask);

    ref = phase82(phase82.condition == noise, :);
    fpChanged = counts; fpChanged.FP = 0;
    tnChanged = counts; tnChanged.TN = 0;
    checks = [checks; {
        noise + " confusion counts reproduce EXP-043 exactly (TP, FP, FN, TN)", height(ref) == 1 && ...
            ref.tpVoxels == counts.TP && ref.fpVoxels == counts.FP && ref.fnVoxels == counts.FN && ref.tnVoxels == counts.TN
        noise + " FP does not affect Recall",          computeRecallFromConfusion(fpChanged) == recallValue
        noise + " TN does not affect Recall",          computeRecallFromConfusion(tnChanged) == recallValue
        noise + " numerator = TP",                     recallNumerator == counts.TP
        noise + " denominator = TP + FN = GT-positive voxels", recallDenominator == counts.TP + counts.FN && ...
            recallDenominator == gtPositiveVoxels && recallDenominator > 0
        noise + " Recall = numerator / denominator",   recallValue == recallNumerator / recallDenominator
        noise + " Recall in [0, 1]",                   recallValue >= 0 && recallValue <= 1
        }]; %#ok<AGROW>
    rows(n, :) = {noise, "Phase-71 T2 M_pred", counts.TP, counts.FN, gtPositiveVoxels, ...
        recallNumerator, recallDenominator, recallValue};
end
recallTable = cell2table(rows, 'VariableNames', {'condition', 'predictionSource', 'tpVoxels', 'fnVoxels', ...
    'gtPositiveVoxels', 'recallNumerator', 'recallDenominator', 'recall'});
writetable(recallTable, fullfile(cfg.paths.metrics, 'exp047_formal_recall.csv'));
disp(recallTable);
for n = 1:2
    fprintf(['%s formal Recall (= Sensitivity) = %.15g  (%d / %d): %.4f %% of GT lesion VOXELS detected, ' ...
        '%.4f %% missed\n'], noiseLevels(n), recallTable.recall(n), recallTable.recallNumerator(n), ...
        recallTable.recallDenominator(n), 100 * recallTable.recall(n), ...
        100 * recallTable.fnVoxels(n) / recallTable.recallDenominator(n));
end
fprintf('\nSide by side (descriptive only, no combined score):\n');
for n = 1:2
    p = phase85(phase85.condition == noiseLevels(n), :);
    fprintf('  %s  Precision (Phase 85) = %.15g   Recall (Phase 86) = %.15g\n', noiseLevels(n), ...
        p.precision, recallTable.recall(n));
end
fprintf('\n');


%% 3. Controlli finali

sourcesUnchanged = true;
for n = 1:2
    after = dir(phase71File(noiseLevels(n)));
    s = load(phase71File(noiseLevels(n)), 'M_pred');
    sourcesUnchanged = sourcesUnchanged && after.datenum == fileInfoBefore{n}.datenum && ...
        after.bytes == fileInfoBefore{n}.bytes && isequal(s.M_pred, predCopies{n});
end
scriptText = fileread([mfilename('fullpath') '.m']);
codeText = strjoin(regexprep(splitlines(string(scriptText)), '%.*$', ''), newline);
laterMetrics = {['specif' 'icity'], ['Specif' 'icity'], ['accu' 'racy'], ['Accu' 'racy'], ['F' '1'], ...
    ['Fbe' 'ta'], ['F_be' 'ta'], ['bal' 'anced'], ['volume' 'Error'], ['computeDice' 'FromConfusion('], ...
    ['computeIoU' 'FromConfusion('], ['computePrecision' 'FromConfusion(']};
aggregates = {['Development' 'Score'], ['development' 'Score'], ['mea' 'n(']};
granularity = {['bwconn' 'comp('], ['region' 'props('], ['for k' ' = 1:'], ['perSl' 'ice'], ['lesion' 'Wise']};
segmentation = {['loadBrainweb' 'Mri('], ['multi' 'thresh('], ['imquan' 'tize('], ['imo' 'pen('], ['imc' 'lose('], ...
    ['ime' 'rode('], ['imdi' 'late('], ['save' '(']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "no later-phase or combined metric, no earlier-metric recomputation", ~any(cellfun(@(f) contains(codeText, f), laterMetrics))
    "no development aggregate computed",             ~any(cellfun(@(f) contains(codeText, f), aggregates))
    "no slice-wise / lesion-wise evaluation",        ~any(cellfun(@(f) contains(codeText, f), granularity))
    "no segmentation operation / no mask saved",     ~any(cellfun(@(f) contains(codeText, f), segmentation))
    "no held-out condition referenced",              ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "source M_pred files unchanged",                 sourcesUnchanged && isequal(predMasks, predCopies)
    "GT unchanged",                                  isequal(gtMask, gtCopy)
    "config.m unchanged",                            isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-90s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp047:checksFailed', 'EXP-047 checks failed.');
end
fprintf('\nEXP-047 CHECKS: PASS (%d)\n', size(checks, 1));
