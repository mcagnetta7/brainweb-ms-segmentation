%% EXP-043 (fase 82): matrice di confusione formale voxel per voxel
% Predizione mantenuta: M_pred della fase 71 (T2), verificata dalla
% decisione della fase 81. GT: label 10 sull'intero volume 181x217x181.
% Conteggi TP / FP / FN / TN con computeVoxelConfusion; convenzione
%   righe = GT [0, 1], colonne = predizione [0, 1]  ->  [TN FP; FN TP].
% Solo conteggi: nessuna metrica derivata, nessuna analisi per slice o per
% lesione, nessuna modifica della segmentazione, solo pn0 / pn3.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
decisionFile = fullfile(cfg.paths.metrics, 'phase81_multimodal_decision.csv');
regressionFile = fullfile(cfg.paths.metrics, 'exp042_mono_vs_multimodal_metrics.csv');
phase71File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));
functionFile = fullfile(cfg.paths.evaluation, 'computeVoxelConfusion.m');
checks = cell(0, 2);


%% 1. Decisione della fase 81 e predizione mantenuta

checks(end+1, :) = {"Phase-81 decision artifact exists", isfile(decisionFile)};
decision = readtable(decisionFile, 'TextType', 'string');
checks = [checks; {
    "Phase-81 decision = REJECT_MULTIMODAL_FUSION",      height(decision) == 1 && decision.decision == "REJECT_MULTIMODAL_FUSION"
    "canonical retained method = Phase-71 T2 M_pred",    decision.canonicalMethodAfterPhase81 == "Phase-71 T2 M_pred"
    }];
if decision.decision ~= "REJECT_MULTIMODAL_FUSION" || decision.canonicalMethodAfterPhase81 ~= "Phase-71 T2 M_pred"
    error('exp043:technicallyBlocked', 'PHASE 82 TECHNICALLY BLOCKED: Phase-81 decision does not support T2 M_pred.');
end

predMasks = cell(1, 2);
fileInfoBefore = cell(1, 2);
for n = 1:2
    noise = noiseLevels(n);
    checks(end+1, :) = {noise + " M_pred exists", isfile(phase71File(noise))}; %#ok<SAGROW>
    if ~isfile(phase71File(noise))
        error('exp043:technicallyBlocked', 'PHASE 82 TECHNICALLY BLOCKED: missing %s', phase71File(noise));
    end
    fileInfoBefore{n} = dir(phase71File(noise));
    s = load(phase71File(noise), 'M_pred');
    predMasks{n} = s.M_pred;
    checks = [checks; {
        noise + " M_pred logical / binary",         islogical(predMasks{n})
        noise + " M_pred size 181x217x181, non-empty array, contains candidates", ...
            isequal(size(predMasks{n}), expectedSize) && nnz(predMasks{n}) > 0
        }]; %#ok<AGROW>
end
predCopies = predMasks;


%% 2. Ground truth (volume completo)

labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;                           % GT completo, nessuna maschera / ROI
gtCopy = gtMask;
checks = [checks; {
    "GT loads correctly (181x217x181)",              isequal(size(labels), expectedSize)
    "M_GT = label 10, logical, contains lesion voxels", islogical(gtMask) && isequal(gtMask, labels == 10) && nnz(gtMask) > 0
    "M_GT size 181x217x181, matches both predictions", isequal(size(gtMask), expectedSize) && ...
        isequal(size(predMasks{1}), size(gtMask)) && isequal(size(predMasks{2}), size(gtMask))
    "GT keeps every label-10 voxel of the volume",    nnz(gtMask) == nnz(labels == 10)
    }];


%% 3. Conteggi formali

functionText = fileread(functionFile);
functionCode = strjoin(regexprep(splitlines(string(functionText)), '%.*$', ''), newline);
segmentationOps = {['lo' 'ad('], ['fre' 'ad('], ['multi' 'thresh('], ['imquan' 'tize('], ['imo' 'pen('], ...
    ['imc' 'lose('], ['ime' 'rode('], ['imdi' 'late('], ['bwconn' 'comp('], ['region' 'props('], ['rawb'], ['.raws']};
checks = [checks; {
    "reusable confusion function exists",             isfile(functionFile)
    "function contains no file access / segmentation logic", ~any(cellfun(@(f) contains(functionCode, f), segmentationOps))
    }];

rows = cell(2, 11);
for n = 1:2
    noise = noiseLevels(n);
    pred = predMasks{n};
    c = computeVoxelConfusion(pred, gtMask);

    % Controllo indipendente dei quattro conteggi (conteggio diretto)
    directTP = sum(pred(:) & gtMask(:));
    directFP = sum(pred(:) & ~gtMask(:));
    directFN = sum(~pred(:) & gtMask(:));
    directTN = sum(~pred(:) & ~gtMask(:));
    predictedPositive = nnz(pred); predictedNegative = nnz(~pred);
    gtPositive = nnz(gtMask); gtNegative = nnz(~gtMask);
    checks = [checks; {
        noise + " TP computed correctly",            c.TP == directTP
        noise + " FP computed correctly",            c.FP == directFP
        noise + " FN computed correctly",            c.FN == directFN
        noise + " TN computed correctly",            c.TN == directTN
        noise + " TP + FP = predicted positives",    c.TP + c.FP == predictedPositive
        noise + " TP + FN = GT positives",           c.TP + c.FN == gtPositive
        noise + " TN + FN = predicted negatives",    c.TN + c.FN == predictedNegative
        noise + " TN + FP = GT negatives",           c.TN + c.FP == gtNegative
        noise + " TP + FP + FN + TN = total voxels", c.TP + c.FP + c.FN + c.TN == c.totalVoxels
        noise + " total voxels = numel(M_pred) = numel(M_GT)", c.totalVoxels == numel(pred) && numel(pred) == numel(gtMask)
        noise + " matrix = [TN FP; FN TP]",          isequal(c.confusionMatrix, [c.TN c.FP; c.FN c.TP])
        }]; %#ok<AGROW>

    rows(n, :) = {noise, "Phase-71 T2 M_pred", c.totalVoxels, predictedPositive, predictedNegative, ...
        gtPositive, gtNegative, c.TP, c.FP, c.FN, c.TN};

    % Matrice 2x2 esplicita: righe = GT [0,1], colonne = predizione [0,1]
    matrixTable = array2table(c.confusionMatrix, 'VariableNames', {'pred0', 'pred1'}, 'RowNames', {'gt0', 'gt1'});
    writetable(matrixTable, fullfile(cfg.paths.metrics, sprintf('exp043_confusion_matrix_%s.csv', noise)), ...
        'WriteRowNames', true);
    fprintf('%s confusion matrix (rows = GT [0,1], columns = prediction [0,1]) = [TN FP; FN TP]:\n', noise);
    disp(matrixTable);
end
countsTable = cell2table(rows, 'VariableNames', {'condition', 'predictionSource', 'totalVoxels', ...
    'predictedPositive', 'predictedNegative', 'gtPositive', 'gtNegative', 'tpVoxels', 'fpVoxels', ...
    'fnVoxels', 'tnVoxels'});
writetable(countsTable, fullfile(cfg.paths.metrics, 'exp043_voxel_confusion_matrix.csv'));
disp(countsTable);


%% 4. Controllo di regressione con la fase 81 (solo validazione)

regression = readtable(regressionFile, 'TextType', 'string');
for n = 1:2
    old = regression(all([regression.method == "T2", regression.condition == noiseLevels(n)], 2), :);
    checks(end+1, :) = {noiseLevels(n) + " TP / FP / FN reproduce Phase-81 T2 diagnostic counts", ...
        height(old) == 1 && old.tpVoxels == countsTable.tpVoxels(n) && old.fpVoxels == countsTable.fpVoxels(n) && ...
        old.fnVoxels == countsTable.fnVoxels(n)}; %#ok<SAGROW>
end


%% 5. Controlli finali

sourcesUnchanged = true;
for n = 1:2
    after = dir(phase71File(noiseLevels(n)));
    s = load(phase71File(noiseLevels(n)), 'M_pred');
    sourcesUnchanged = sourcesUnchanged && after.datenum == fileInfoBefore{n}.datenum && ...
        after.bytes == fileInfoBefore{n}.bytes && isequal(s.M_pred, predCopies{n});
end
scriptText = fileread([mfilename('fullpath') '.m']);
codeText = strjoin(regexprep(splitlines(string(scriptText)), '%.*$', ''), newline);
derivedMetrics = {['di' 'ce'], ['Di' 'ce'], ['jacc' 'ard'], ['Jacc' 'ard'], ['Io' 'U'], ['preci' 'sion'], ...
    ['Preci' 'sion'], ['reca' 'll'], ['Reca' 'll'], ['sensi' 'tivity'], ['Sensi' 'tivity'], ['specif' 'icity'], ...
    ['Specif' 'icity'], ['accu' 'racy'], ['Accu' 'racy'], ['F' '1'], ['volume' 'Error']};
granularity = {['bwconn' 'comp('], ['region' 'props('], ['for k' ' = 1:'], ['perSl' 'ice'], ['lesion' 'Wise']};
segmentation = {['loadBrainweb' 'Mri('], ['multi' 'thresh('], ['imquan' 'tize('], ['imo' 'pen('], ['imc' 'lose('], ...
    ['ime' 'rode('], ['imdi' 'late('], ['save' '(']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "no derived metric computed",                    ~any(cellfun(@(f) contains(codeText, f), derivedMetrics))
    "no slice-wise / lesion-wise evaluation",        ~any(cellfun(@(f) contains(codeText, f), granularity))
    "no segmentation operation / no mask saved",     ~any(cellfun(@(f) contains(codeText, f), segmentation))
    "no held-out condition referenced",              ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "M_pred source files unchanged",                 sourcesUnchanged && isequal(predMasks, predCopies)
    "GT unchanged",                                  isequal(gtMask, gtCopy)
    "config.m unchanged",                            isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-75s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp043:checksFailed', 'EXP-043 checks failed.');
end
fprintf('\nEXP-043 CHECKS: PASS (%d)\n', size(checks, 1));
