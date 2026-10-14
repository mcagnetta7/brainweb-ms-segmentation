%% EXP-046 (fase 85): Precision formale
% Catena: M_pred (fase 71, T2) + M_GT (label 10, volume completo)
%   -> computeVoxelConfusion (fase 82) -> computePrecisionFromConfusion
%   Precision = TP / (TP + FP); convenzione 0/0 -> 1 (non indica una
%   rilevazione riuscita). FN e TN non entrano nella formula.
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
phase71File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));
confusionFunction = fullfile(cfg.paths.evaluation, 'computeVoxelConfusion.m');
precisionFunction = fullfile(cfg.paths.evaluation, 'computePrecisionFromConfusion.m');
checks = cell(0, 2);


%% 1. Artefatti e predizioni

if ~isfile(decisionFile)
    error('exp046:technicallyBlocked', 'PHASE 85 TECHNICALLY BLOCKED: missing %s', decisionFile);
end
decision = readtable(decisionFile, 'TextType', 'string');
checks = [checks; {
    "EXP-043 confusion CSV exists",                   isfile(confusionFile)
    "computeVoxelConfusion exists",                   isfile(confusionFunction)
    "computePrecisionFromConfusion exists",           isfile(precisionFunction)
    "Phase-81 retained method = Phase-71 T2 M_pred",  decision.decision == "REJECT_MULTIMODAL_FUSION" && ...
        decision.canonicalMethodAfterPhase81 == "Phase-71 T2 M_pred"
    }];
predMasks = cell(1, 2);
fileInfoBefore = cell(1, 2);
for n = 1:2
    noise = noiseLevels(n);
    checks(end+1, :) = {"Phase-71 " + noise + " M_pred exists", isfile(phase71File(noise))}; %#ok<SAGROW>
    if ~isfile(phase71File(noise))
        error('exp046:technicallyBlocked', 'PHASE 85 TECHNICALLY BLOCKED: missing %s', phase71File(noise));
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


%% 2. Conteggi (fase 82) e Precision

functionCode = strjoin(regexprep(splitlines(string(fileread(precisionFunction))), '%.*$', ''), newline);
checks(end+1, :) = {"Precision function uses TP / FP only (no FN, no TN, no voxel counting, no file access)", ...
    ~contains(functionCode, 'FN') && ~contains(functionCode, 'TN') && ~contains(functionCode, ['nn' 'z(']) && ...
    ~contains(functionCode, ['lo' 'ad('])};

phase82 = readtable(confusionFile, 'TextType', 'string');
rows = cell(2, 8);
for n = 1:2
    noise = noiseLevels(n);
    counts = computeVoxelConfusion(predMasks{n}, gtMask);
    precisionValue = computePrecisionFromConfusion(counts);
    precisionNumerator = counts.TP;
    precisionDenominator = counts.TP + counts.FP;
    predictedPositiveVoxels = nnz(predMasks{n});

    ref = phase82(phase82.condition == noise, :);
    fnChanged = counts; fnChanged.FN = 0;
    tnChanged = counts; tnChanged.TN = 0;
    checks = [checks; {
        noise + " confusion counts reproduce EXP-043 exactly (TP, FP, FN, TN)", height(ref) == 1 && ...
            ref.tpVoxels == counts.TP && ref.fpVoxels == counts.FP && ref.fnVoxels == counts.FN && ref.tnVoxels == counts.TN
        noise + " FN does not affect Precision",       computePrecisionFromConfusion(fnChanged) == precisionValue
        noise + " TN does not affect Precision",       computePrecisionFromConfusion(tnChanged) == precisionValue
        noise + " numerator = TP",                     precisionNumerator == counts.TP
        noise + " denominator = TP + FP = predicted-positive voxels", precisionDenominator == counts.TP + counts.FP && ...
            precisionDenominator == predictedPositiveVoxels && precisionDenominator > 0
        noise + " Precision = numerator / denominator", precisionValue == precisionNumerator / precisionDenominator
        noise + " Precision in [0, 1]",                precisionValue >= 0 && precisionValue <= 1
        }]; %#ok<AGROW>
    rows(n, :) = {noise, "Phase-71 T2 M_pred", counts.TP, counts.FP, predictedPositiveVoxels, ...
        precisionNumerator, precisionDenominator, precisionValue};
end
precisionTable = cell2table(rows, 'VariableNames', {'condition', 'predictionSource', 'tpVoxels', 'fpVoxels', ...
    'predictedPositiveVoxels', 'precisionNumerator', 'precisionDenominator', 'precision'});
writetable(precisionTable, fullfile(cfg.paths.metrics, 'exp046_formal_precision.csv'));
disp(precisionTable);
for n = 1:2
    fprintf('%s formal Precision = %.15g  (%d / %d): %.4f %% of predicted-positive voxels are TP, %.4f %% are FP\n', ...
        noiseLevels(n), precisionTable.precision(n), precisionTable.precisionNumerator(n), ...
        precisionTable.precisionDenominator(n), 100 * precisionTable.precision(n), ...
        100 * precisionTable.fpVoxels(n) / precisionTable.precisionDenominator(n));
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
laterMetrics = {['reca' 'll'], ['Reca' 'll'], ['sensi' 'tivity'], ['Sensi' 'tivity'], ['specif' 'icity'], ...
    ['Specif' 'icity'], ['accu' 'racy'], ['Accu' 'racy'], ['F' '1'], ['volume' 'Error'], ...
    ['computeDice' 'FromConfusion('], ['computeIoU' 'FromConfusion(']};
aggregates = {['Development' 'Score'], ['development' 'Score'], ['mea' 'n(']};
granularity = {['bwconn' 'comp('], ['region' 'props('], ['for k' ' = 1:'], ['perSl' 'ice'], ['lesion' 'Wise']};
segmentation = {['loadBrainweb' 'Mri('], ['multi' 'thresh('], ['imquan' 'tize('], ['imo' 'pen('], ['imc' 'lose('], ...
    ['ime' 'rode('], ['imdi' 'late('], ['save' '(']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "no metric assigned to a later roadmap phase, no Dice / IoU recomputation", ~any(cellfun(@(f) contains(codeText, f), laterMetrics))
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
    fprintf('%-92s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp046:checksFailed', 'EXP-046 checks failed.');
end
fprintf('\nEXP-046 CHECKS: PASS (%d)\n', size(checks, 1));
