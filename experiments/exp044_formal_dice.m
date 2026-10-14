%% EXP-044 (fase 83): coefficiente di Dice formale
% Catena: M_pred (fase 71, T2) + M_GT (label 10, volume completo)
%   -> computeVoxelConfusion (fase 82) -> computeDiceFromConfusion
%   Dice = 2TP / (2TP + FP + FN); convenzione 0/0 -> 1.
% Un Dice per volume (pn0, pn3). Nessun'altra metrica, nessun
% DevelopmentScore, nessuna analisi per slice o per lesione, nessuna
% modifica della segmentazione.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
confusionFile = fullfile(cfg.paths.metrics, 'exp043_voxel_confusion_matrix.csv');
decisionFile = fullfile(cfg.paths.metrics, 'phase81_multimodal_decision.csv');
previousDiceFile = fullfile(cfg.paths.metrics, 'exp042_mono_vs_multimodal_metrics.csv');
phase71File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));
confusionFunction = fullfile(cfg.paths.evaluation, 'computeVoxelConfusion.m');
diceFunction = fullfile(cfg.paths.evaluation, 'computeDiceFromConfusion.m');
csvTolerance = 1e-12;                            % solo per la rappresentazione testuale del CSV di EXP-042
checks = cell(0, 2);


%% 1. Artefatti e predizioni

decision = readtable(decisionFile, 'TextType', 'string');
checks = [checks; {
    "Phase-82 confusion CSV exists",                  isfile(confusionFile)
    "computeVoxelConfusion exists",                   isfile(confusionFunction)
    "computeDiceFromConfusion exists",                isfile(diceFunction)
    "Phase-81 retained method = Phase-71 T2 M_pred",  decision.decision == "REJECT_MULTIMODAL_FUSION" && ...
        decision.canonicalMethodAfterPhase81 == "Phase-71 T2 M_pred"
    }];
predMasks = cell(1, 2);
fileInfoBefore = cell(1, 2);
for n = 1:2
    noise = noiseLevels(n);
    checks(end+1, :) = {"Phase-71 " + noise + " M_pred exists", isfile(phase71File(noise))}; %#ok<SAGROW>
    if ~isfile(phase71File(noise))
        error('exp044:technicallyBlocked', 'PHASE 83 TECHNICALLY BLOCKED: missing %s', phase71File(noise));
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


%% 2. Conteggi (fase 82) e Dice

functionCode = strjoin(regexprep(splitlines(string(fileread(diceFunction))), '%.*$', ''), newline);
checks(end+1, :) = {"Dice function uses TP / FP / FN only (no TN, no voxel counting, no file access)", ...
    ~contains(functionCode, 'TN') && ~contains(functionCode, ['nn' 'z(']) && ~contains(functionCode, ['lo' 'ad('])};

phase82 = readtable(confusionFile, 'TextType', 'string');
previous = readtable(previousDiceFile, 'TextType', 'string');
rows = cell(2, 8);
for n = 1:2
    noise = noiseLevels(n);
    counts = computeVoxelConfusion(predMasks{n}, gtMask);
    diceValue = computeDiceFromConfusion(counts);
    numerator = 2 * counts.TP;
    denominator = 2 * counts.TP + counts.FP + counts.FN;
    predictedPositive = counts.TP + counts.FP;
    gtPositive = counts.TP + counts.FN;

    ref = phase82(phase82.condition == noise, :);
    old = previous(all([previous.method == "T2", previous.condition == noise], 2), :);
    tnChanged = counts; tnChanged.TN = 0;
    checks = [checks; {
        noise + " confusion counts reproduce EXP-043 exactly (TP, FP, FN, TN)", height(ref) == 1 && ...
            ref.tpVoxels == counts.TP && ref.fpVoxels == counts.FP && ref.fnVoxels == counts.FN && ref.tnVoxels == counts.TN
        noise + " TN does not affect Dice",            computeDiceFromConfusion(tnChanged) == diceValue
        noise + " numerator = 2*TP",                   numerator == 2 * counts.TP
        noise + " denominator = 2*TP + FP + FN",       denominator == 2 * counts.TP + counts.FP + counts.FN && denominator > 0
        noise + " Dice = numerator / denominator",     diceValue == numerator / denominator
        noise + " Dice in [0, 1]",                     diceValue >= 0 && diceValue <= 1
        noise + " equivalent denominator = predicted positives + GT positives", ...
            denominator == predictedPositive + gtPositive && predictedPositive == nnz(predMasks{n}) && gtPositive == nnz(gtMask)
        noise + " formal Dice reproduces previous T2 Dice (EXP-042 CSV, 1e-12)", ...
            height(old) == 1 && abs(old.dice - diceValue) < csvTolerance
        }]; %#ok<AGROW>
    rows(n, :) = {noise, "Phase-71 T2 M_pred", counts.TP, counts.FP, counts.FN, numerator, denominator, diceValue};
end
diceTable = cell2table(rows, 'VariableNames', {'condition', 'predictionSource', 'tpVoxels', 'fpVoxels', ...
    'fnVoxels', 'diceNumerator', 'diceDenominator', 'dice'});
writetable(diceTable, fullfile(cfg.paths.metrics, 'exp044_formal_dice.csv'));
disp(diceTable);
for n = 1:2
    fprintf('%s formal Dice = %.15g  (%d / %d)\n', noiseLevels(n), diceTable.dice(n), ...
        diceTable.diceNumerator(n), diceTable.diceDenominator(n));
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
laterMetrics = {['jacc' 'ard'], ['Jacc' 'ard'], ['Io' 'U'], ['preci' 'sion'], ['Preci' 'sion'], ['reca' 'll'], ...
    ['Reca' 'll'], ['sensi' 'tivity'], ['Sensi' 'tivity'], ['specif' 'icity'], ['Specif' 'icity'], ...
    ['accu' 'racy'], ['Accu' 'racy'], ['F' '1'], ['volume' 'Error']};
aggregates = {['Development' 'Score'], ['development' 'Score'], ['mea' 'n(']};
granularity = {['bwconn' 'comp('], ['region' 'props('], ['for k' ' = 1:'], ['perSl' 'ice'], ['lesion' 'Wise']};
segmentation = {['loadBrainweb' 'Mri('], ['multi' 'thresh('], ['imquan' 'tize('], ['imo' 'pen('], ['imc' 'lose('], ...
    ['ime' 'rode('], ['imdi' 'late('], ['save' '(']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "no metric assigned to a later roadmap phase",   ~any(cellfun(@(f) contains(codeText, f), laterMetrics))
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
    fprintf('%-82s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp044:checksFailed', 'EXP-044 checks failed.');
end
fprintf('\nEXP-044 CHECKS: PASS (%d)\n', size(checks, 1));
