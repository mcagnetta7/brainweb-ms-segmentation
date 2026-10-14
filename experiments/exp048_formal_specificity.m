%% EXP-048 (fase 87): Specificity formale
% Catena: M_pred (fase 71, T2) + M_GT (label 10, volume completo)
%   -> computeVoxelConfusion (fase 82) -> computeSpecificityFromConfusion
%   Specificity = TN / (TN + FP); convenzione 0/0 -> 1. TP e FN non entrano.
% La classe non-lesione domina il volume: la Specificity non va letta da sola
% né come accuratezza. I CSV formali delle fasi 83-86 sono letti solo per un
% riepilogo descrittivo (nessun ricalcolo, nessun punteggio combinato).
% Un valore per volume (pn0, pn3). Nessuna metrica di volume, nessun
% aggregato, nessuna analisi per slice o per lesione, nessuna modifica della
% segmentazione.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
confusionFile = fullfile(cfg.paths.metrics, 'exp043_voxel_confusion_matrix.csv');
decisionFile = fullfile(cfg.paths.metrics, 'phase81_multimodal_decision.csv');
earlierFiles = struct( ...
    'dice', fullfile(cfg.paths.metrics, 'exp044_formal_dice.csv'), ...
    'iou', fullfile(cfg.paths.metrics, 'exp045_formal_iou.csv'), ...
    'precision', fullfile(cfg.paths.metrics, 'exp046_formal_precision.csv'), ...
    'recall', fullfile(cfg.paths.metrics, 'exp047_formal_recall.csv'));
phase71File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));
confusionFunction = fullfile(cfg.paths.evaluation, 'computeVoxelConfusion.m');
specificityFunction = fullfile(cfg.paths.evaluation, 'computeSpecificityFromConfusion.m');
checks = cell(0, 2);


%% 1. Artefatti e predizioni

for f = [string(confusionFile), string(decisionFile), string(struct2cell(earlierFiles)).']
    if ~isfile(f)
        error('exp048:technicallyBlocked', 'PHASE 87 TECHNICALLY BLOCKED: missing %s', f);
    end
end
decision = readtable(decisionFile, 'TextType', 'string');
checks = [checks; {
    "EXP-043 confusion CSV exists",                   isfile(confusionFile)
    "computeVoxelConfusion exists",                   isfile(confusionFunction)
    "computeSpecificityFromConfusion exists",         isfile(specificityFunction)
    "Phase-81 retained method = Phase-71 T2 M_pred",  decision.decision == "REJECT_MULTIMODAL_FUSION" && ...
        decision.canonicalMethodAfterPhase81 == "Phase-71 T2 M_pred"
    }];
predMasks = cell(1, 2);
fileInfoBefore = cell(1, 2);
for n = 1:2
    noise = noiseLevels(n);
    checks(end+1, :) = {"Phase-71 " + noise + " M_pred exists", isfile(phase71File(noise))}; %#ok<SAGROW>
    if ~isfile(phase71File(noise))
        error('exp048:technicallyBlocked', 'PHASE 87 TECHNICALLY BLOCKED: missing %s', phase71File(noise));
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


%% 2. Conteggi (fase 82) e Specificity

functionCode = strjoin(regexprep(splitlines(string(fileread(specificityFunction))), '%.*$', ''), newline);
checks(end+1, :) = {"Specificity function uses TN / FP only (no TP, no FN, no voxel counting, no file access)", ...
    ~contains(functionCode, 'TP') && ~contains(functionCode, 'FN') && ~contains(functionCode, ['nn' 'z(']) && ...
    ~contains(functionCode, ['lo' 'ad('])};

phase82 = readtable(confusionFile, 'TextType', 'string');
rows = cell(2, 8);
for n = 1:2
    noise = noiseLevels(n);
    counts = computeVoxelConfusion(predMasks{n}, gtMask);
    specificityValue = computeSpecificityFromConfusion(counts);
    specificityNumerator = counts.TN;
    specificityDenominator = counts.TN + counts.FP;
    gtNegativeVoxels = nnz(~gtMask);

    ref = phase82(phase82.condition == noise, :);
    tpChanged = counts; tpChanged.TP = 0;
    fnChanged = counts; fnChanged.FN = 0;
    checks = [checks; {
        noise + " confusion counts reproduce EXP-043 exactly (TP, FP, FN, TN)", height(ref) == 1 && ...
            ref.tpVoxels == counts.TP && ref.fpVoxels == counts.FP && ref.fnVoxels == counts.FN && ref.tnVoxels == counts.TN
        noise + " TP does not affect Specificity",     computeSpecificityFromConfusion(tpChanged) == specificityValue
        noise + " FN does not affect Specificity",     computeSpecificityFromConfusion(fnChanged) == specificityValue
        noise + " numerator = TN",                     specificityNumerator == counts.TN
        noise + " denominator = TN + FP = GT-negative voxels", specificityDenominator == counts.TN + counts.FP && ...
            specificityDenominator == gtNegativeVoxels && specificityDenominator > 0
        noise + " Specificity = numerator / denominator", specificityValue == specificityNumerator / specificityDenominator
        noise + " Specificity in [0, 1]",              specificityValue >= 0 && specificityValue <= 1
        }]; %#ok<AGROW>
    rows(n, :) = {noise, "Phase-71 T2 M_pred", counts.TN, counts.FP, gtNegativeVoxels, ...
        specificityNumerator, specificityDenominator, specificityValue};
end
specificityTable = cell2table(rows, 'VariableNames', {'condition', 'predictionSource', 'tnVoxels', 'fpVoxels', ...
    'gtNegativeVoxels', 'specificityNumerator', 'specificityDenominator', 'specificity'});
writetable(specificityTable, fullfile(cfg.paths.metrics, 'exp048_formal_specificity.csv'));
disp(specificityTable);
for n = 1:2
    fprintf(['%s formal Specificity = %.15g  (%d / %d): %.4f %% of GT non-lesion voxels correctly rejected, ' ...
        '%.4f %% (= %d voxels) labelled as lesion\n'], noiseLevels(n), specificityTable.specificity(n), ...
        specificityTable.specificityNumerator(n), specificityTable.specificityDenominator(n), ...
        100 * specificityTable.specificity(n), ...
        100 * specificityTable.fpVoxels(n) / specificityTable.specificityDenominator(n), specificityTable.fpVoxels(n));
end

% Riepilogo descrittivo con le metriche già formalizzate (solo lettura)
earlier = structfun(@(f) readtable(f, 'TextType', 'string'), earlierFiles, 'UniformOutput', false);
fprintf('\nFormal development metrics (read from EXP-044..047 CSVs; no recomputation, no combined score):\n');
for n = 1:2
    pick = @(t, col) t.(col)(t.condition == noiseLevels(n));
    fprintf(['  %s  Dice %.6f | IoU %.6f | Precision %.6f | Recall %.6f | Specificity %.6f\n'], ...
        noiseLevels(n), pick(earlier.dice, 'dice'), pick(earlier.iou, 'iou'), ...
        pick(earlier.precision, 'precision'), pick(earlier.recall, 'recall'), specificityTable.specificity(n));
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
laterMetrics = {['accu' 'racy'], ['Accu' 'racy'], ['bal' 'anced'], ['Bal' 'anced'], ['F' '1'], ['Fbe' 'ta'], ...
    ['F_be' 'ta'], ['MC' 'C'], ['Mat' 'thews'], ['RO' 'C'], ['AU' 'C'], ['Youd' 'en'], ['volume' 'Error'], ...
    ['gt' 'Volume'], ['predicted' 'Volume'], ['mm' '3'], ['computeDice' 'FromConfusion('], ...
    ['computeIoU' 'FromConfusion('], ['computePrecision' 'FromConfusion('], ['computeRecall' 'FromConfusion(']};
aggregates = {['Development' 'Score'], ['development' 'Score'], ['mea' 'n(']};
granularity = {['bwconn' 'comp('], ['region' 'props('], ['for k' ' = 1:'], ['perSl' 'ice'], ['lesion' 'Wise']};
segmentation = {['loadBrainweb' 'Mri('], ['multi' 'thresh('], ['imquan' 'tize('], ['imo' 'pen('], ['imc' 'lose('], ...
    ['ime' 'rode('], ['imdi' 'late('], ['save' '(']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "no combined / volume / later-phase metric, no earlier-metric recomputation", ~any(cellfun(@(f) contains(codeText, f), laterMetrics))
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
    fprintf('%-96s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp048:checksFailed', 'EXP-048 checks failed.');
end
fprintf('\nEXP-048 CHECKS: PASS (%d)\n', size(checks, 1));
