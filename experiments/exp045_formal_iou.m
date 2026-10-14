%% EXP-045 (fase 84): IoU / indice di Jaccard formale
% Catena: M_pred (fase 71, T2) + M_GT (label 10, volume completo)
%   -> computeVoxelConfusion (fase 82) -> computeIoUFromConfusion
%   IoU = TP / (TP + FP + FN) (= indice di Jaccard); convenzione 0/0 -> 1.
% Il Dice della fase 83 è letto solo come regressione: IoU = Dice / (2 - Dice).
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
overlapFile = fullfile(cfg.paths.metrics, 'exp044_formal_dice.csv');
phase71File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));
confusionFunction = fullfile(cfg.paths.evaluation, 'computeVoxelConfusion.m');
iouFunction = fullfile(cfg.paths.evaluation, 'computeIoUFromConfusion.m');
regressionTolerance = 1e-12;                     % solo confronto numerico con il CSV della fase 83
checks = cell(0, 2);


%% 1. Artefatti e predizioni

checks = [checks; {
    "EXP-043 confusion CSV exists",                   isfile(confusionFile)
    "EXP-044 formal Dice CSV exists",                 isfile(overlapFile)
    "computeVoxelConfusion exists",                   isfile(confusionFunction)
    "computeIoUFromConfusion exists",                 isfile(iouFunction)
    }];
predMasks = cell(1, 2);
fileInfoBefore = cell(1, 2);
for n = 1:2
    noise = noiseLevels(n);
    checks(end+1, :) = {"Phase-71 " + noise + " M_pred exists", isfile(phase71File(noise))}; %#ok<SAGROW>
    if ~isfile(phase71File(noise))
        error('exp045:technicallyBlocked', 'PHASE 84 TECHNICALLY BLOCKED: missing %s', phase71File(noise));
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


%% 2. Conteggi (fase 82) e IoU

functionCode = strjoin(regexprep(splitlines(string(fileread(iouFunction))), '%.*$', ''), newline);
checks(end+1, :) = {"IoU function uses TP / FP / FN only (no TN, no voxel counting, no file access, no Dice conversion)", ...
    ~contains(functionCode, 'TN') && ~contains(functionCode, ['nn' 'z(']) && ~contains(functionCode, ['lo' 'ad(']) && ...
    ~contains(lower(functionCode), ['di' 'ce'])};

phase82 = readtable(confusionFile, 'TextType', 'string');
phase83 = readtable(overlapFile, 'TextType', 'string');
rows = cell(2, 10);
for n = 1:2
    noise = noiseLevels(n);
    counts = computeVoxelConfusion(predMasks{n}, gtMask);
    iouValue = computeIoUFromConfusion(counts);
    iouNumerator = counts.TP;
    iouDenominator = counts.TP + counts.FP + counts.FN;
    intersectionVoxels = counts.TP;
    unionVoxels = counts.TP + counts.FP + counts.FN;

    ref = phase82(phase82.condition == noise, :);
    ref83 = phase83(phase83.condition == noise, :);
    tnChanged = counts; tnChanged.TN = 0;
    checks = [checks; {
        noise + " confusion counts reproduce EXP-043 exactly (TP, FP, FN, TN)", height(ref) == 1 && ...
            ref.tpVoxels == counts.TP && ref.fpVoxels == counts.FP && ref.fnVoxels == counts.FN && ref.tnVoxels == counts.TN
        noise + " TN does not affect IoU",             computeIoUFromConfusion(tnChanged) == iouValue
        noise + " numerator = TP = intersection",      iouNumerator == counts.TP && intersectionVoxels == counts.TP
        noise + " denominator = TP + FP + FN = intersection + FP + FN = union", iouDenominator == counts.TP + counts.FP + counts.FN && ...
            iouDenominator == intersectionVoxels + counts.FP + counts.FN && unionVoxels == iouDenominator && iouDenominator > 0
        noise + " IoU = numerator / denominator = intersection / union", iouValue == iouNumerator / iouDenominator && ...
            iouValue == intersectionVoxels / unionVoxels
        noise + " IoU in [0, 1]",                      iouValue >= 0 && iouValue <= 1
        noise + " IoU = D / (2 - D) with Phase-83 value (regression, 1e-12)", ...
            height(ref83) == 1 && abs(iouValue - ref83.dice / (2 - ref83.dice)) < regressionTolerance
        }]; %#ok<AGROW>
    rows(n, :) = {noise, "Phase-71 T2 M_pred", counts.TP, counts.FP, counts.FN, intersectionVoxels, unionVoxels, ...
        iouNumerator, iouDenominator, iouValue};
end
iouTable = cell2table(rows, 'VariableNames', {'condition', 'predictionSource', 'tpVoxels', 'fpVoxels', 'fnVoxels', ...
    'intersectionVoxels', 'unionVoxels', 'iouNumerator', 'iouDenominator', 'iou'});
writetable(iouTable, fullfile(cfg.paths.metrics, 'exp045_formal_iou.csv'));
disp(iouTable);
for n = 1:2
    fprintf('%s formal IoU (= Jaccard index) = %.15g  (%d / %d)\n', noiseLevels(n), iouTable.iou(n), ...
        iouTable.iouNumerator(n), iouTable.iouDenominator(n));
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
laterMetrics = {['preci' 'sion'], ['Preci' 'sion'], ['reca' 'll'], ['Reca' 'll'], ['sensi' 'tivity'], ...
    ['Sensi' 'tivity'], ['specif' 'icity'], ['Specif' 'icity'], ['accu' 'racy'], ['Accu' 'racy'], ['F' '1'], ...
    ['volume' 'Error'], ['computeDice' 'FromConfusion(']};
aggregates = {['Development' 'Score'], ['development' 'Score'], ['mea' 'n(']};
granularity = {['bwconn' 'comp('], ['region' 'props('], ['for k' ' = 1:'], ['perSl' 'ice'], ['lesion' 'Wise']};
segmentation = {['loadBrainweb' 'Mri('], ['multi' 'thresh('], ['imquan' 'tize('], ['imo' 'pen('], ['imc' 'lose('], ...
    ['ime' 'rode('], ['imdi' 'late('], ['save' '(']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "no metric assigned to a later roadmap phase, no new overlap-metric table", ~any(cellfun(@(f) contains(codeText, f), laterMetrics))
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
    fprintf('%-100s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp045:checksFailed', 'EXP-045 checks failed.');
end
fprintf('\nEXP-045 CHECKS: PASS (%d)\n', size(checks, 1));
