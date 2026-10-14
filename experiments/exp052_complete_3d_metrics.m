%% EXP-052 (fase 91): tabella consolidata delle metriche 3D a volume completo
% Raccoglie i risultati formali già salvati delle fasi 82-90 (EXP-043..051)
% per M_pred della fase 71 (T2), pn0 e pn3 separati, sull'intero volume
% 181x217x181. Nessuna metrica nuova, nessuna funzione di metrica chiamata,
% nessuna maschera o MRI caricata, nessuna media tra condizioni o slice.
% I controlli incrociati sono solo verifiche di coerenza (non salvati).

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
totalVoxels = prod(expectedSize);
predictionSource = "Phase-71 T2 M_pred";
sourceNames = ["exp043_voxel_confusion_matrix", "exp044_formal_dice", "exp045_formal_iou", ...
    "exp046_formal_precision", "exp047_formal_recall", "exp048_formal_specificity", ...
    "exp049_gt_lesion_volume", "exp050_predicted_lesion_volume", "exp051_formal_volume_error"];
sourceFiles = fullfile(cfg.paths.metrics, sourceNames + ".csv");
closeTo = @(a, b) abs(a - b) <= 1e-12 * max(1, abs(b));   % solo rappresentazione dei valori salvati
checks = cell(0, 2);


%% 1. Artefatti formali (sola lettura)

for i = 1:numel(sourceFiles)
    exists = isfile(sourceFiles(i));
    checks(end+1, :) = {upper(extractBefore(sourceNames(i), 7)) + " artifact exists (" + sourceNames(i) + ")", exists}; %#ok<SAGROW>
    if ~exists
        error('exp052:technicallyBlocked', 'PHASE 91 TECHNICALLY BLOCKED: missing %s', sourceFiles(i));
    end
end
stateBefore = arrayfun(@fileState, sourceFiles, 'UniformOutput', false);
t = struct();
for i = 1:numel(sourceFiles)
    t.(char(extractBefore(sourceNames(i), 7))) = readtable(sourceFiles(i), 'TextType', 'string');
end

conditionTables = ["exp043" "exp044" "exp045" "exp046" "exp047" "exp048" "exp050" "exp051"];
oneRowEach = true; sourceOk = true;
for name = conditionTables
    tbl = t.(char(name));
    oneRowEach = oneRowEach && height(tbl) == 2 && isequal(sort(tbl.condition).', noiseLevels);
    sourceOk = sourceOk && all(startsWith(tbl.predictionSource, predictionSource));
end
gt = t.exp049;
checks = [checks; {
    "each condition-specific artifact contains exactly pn0 and pn3 (one row each)", oneRowEach
    "EXP-049 contains exactly one shared GT row (label 10)", height(gt) == 1 && gt.lesionLabel == 10
    "prediction source is consistently Phase-71 T2 M_pred", sourceOk
    "dimensions 181x217x181 in the available metadata", isequal([gt.sizeX gt.sizeY gt.sizeZ], expectedSize) && ...
        all(t.exp050.sizeX == 181 & t.exp050.sizeY == 217 & t.exp050.sizeZ == 181)
    "total whole-volume voxel count = 7,109,137",     totalVoxels == 7109137 && all(t.exp043.totalVoxels == totalVoxels)
    }];
if ~oneRowEach || ~sourceOk || height(gt) ~= 1
    error('exp052:technicallyBlocked', 'PHASE 91 TECHNICALLY BLOCKED: inconsistent source artifacts.');
end


%% 2. Assemblaggio e controlli di coerenza per condizione

rows = cell(2, 20);
for n = 1:2
    noise = noiseLevels(n);
    pick = @(name) t.(name)(t.(name).condition == noise, :);
    c43 = pick('exp043'); c44 = pick('exp044'); c45 = pick('exp045'); c46 = pick('exp046');
    c47 = pick('exp047'); c48 = pick('exp048'); c50 = pick('exp050'); c51 = pick('exp051');
    tp = c43.tpVoxels; fp = c43.fpVoxels; fn = c43.fnVoxels; tn = c43.tnVoxels;
    counts = [tp fp fn tn];
    metrics = [c44.dice c45.iou c46.precision c47.recall c48.specificity];

    checks = [checks; {
        noise + " TP/FP/FN/TN non-negative integer counts", all(isfinite(counts)) && all(counts >= 0) && all(counts == fix(counts))
        noise + " TP + FP + FN + TN = 7,109,137",        sum(counts) == totalVoxels
        noise + " TP + FN = GT lesion voxels (EXP-049)",  tp + fn == gt.gtLesionVoxels
        noise + " TP + FP = predicted-positive voxels (EXP-050)", tp + fp == c50.predictedLesionVoxels
        noise + " confusion counts identical across EXP-043..048", ...
            isequal([c44.tpVoxels c44.fpVoxels c44.fnVoxels], [tp fp fn]) && isequal([c45.tpVoxels c45.fpVoxels c45.fnVoxels], [tp fp fn]) && ...
            isequal([c46.tpVoxels c46.fpVoxels], [tp fp]) && isequal([c47.tpVoxels c47.fnVoxels], [tp fn]) && ...
            isequal([c48.tnVoxels c48.fpVoxels], [tn fp])
        noise + " Dice finite in [0,1]",                 isfinite(c44.dice) && c44.dice >= 0 && c44.dice <= 1
        noise + " IoU finite in [0,1]",                  isfinite(c45.iou) && c45.iou >= 0 && c45.iou <= 1
        noise + " Precision finite in [0,1]",            isfinite(c46.precision) && c46.precision >= 0 && c46.precision <= 1
        noise + " Recall finite in [0,1]",               isfinite(c47.recall) && c47.recall >= 0 && c47.recall <= 1
        noise + " Specificity finite in [0,1]",          isfinite(c48.specificity) && c48.specificity >= 0 && c48.specificity <= 1
        noise + " GT volume = shared EXP-049 value (3,512 voxels x 1 mm^3)", c51.gtLesionVolumeMm3 == gt.gtLesionVolumeMm3 && ...
            gt.gtLesionVolumeMm3 == gt.gtLesionVoxels * gt.voxelVolumeMm3 && gt.voxelVolumeMm3 == 1
        noise + " predicted volume = EXP-050 (count x 1 mm^3)", c51.predictedLesionVolumeMm3 == c50.predictedLesionVolumeMm3 && ...
            c50.predictedLesionVolumeMm3 == c50.predictedLesionVoxels * c50.voxelVolumeMm3 && c50.voxelVolumeMm3 == 1
        noise + " volume error = EXP-051, finite and >= 0", isfinite(c51.volumeErrorPercent) && c51.volumeErrorPercent >= 0
        noise + " volume direction = EXP-051 and agrees with sign", ...
            c51.volumeDirection == "overestimation" == (c51.signedVolumeDifferenceMm3 > 0) && ...
            c51.volumeDirection == "underestimation" == (c51.signedVolumeDifferenceMm3 < 0)
        noise + " regression: IoU vs Dice / (2 - Dice)", closeTo(c45.iou, c44.dice / (2 - c44.dice))
        noise + " regression: Precision vs TP / (TP + FP)", closeTo(c46.precision, tp / (tp + fp))
        noise + " regression: Recall vs TP / (TP + FN)", closeTo(c47.recall, tp / (tp + fn))
        noise + " regression: Specificity vs TN / (TN + FP)", closeTo(c48.specificity, tn / (tn + fp))
        noise + " regression: volume error vs |V_pred - V_GT| / V_GT * 100", ...
            closeTo(c51.volumeErrorPercent, abs(c50.predictedLesionVolumeMm3 - gt.gtLesionVolumeMm3) / gt.gtLesionVolumeMm3 * 100)
        }]; %#ok<AGROW>

    rows(n, :) = {noise, predictionSource, "complete 181x217x181 volume", expectedSize(1), expectedSize(2), ...
        expectedSize(3), totalVoxels, tp, fp, fn, tn, metrics(1), metrics(2), metrics(3), metrics(4), metrics(5), ...
        gt.gtLesionVolumeMm3, c50.predictedLesionVolumeMm3, c51.volumeErrorPercent, c51.volumeDirection};
end
complete3d = cell2table(rows, 'VariableNames', {'condition', 'predictionSource', 'evaluationScope', ...
    'sizeX', 'sizeY', 'sizeZ', 'totalVoxels', 'tpVoxels', 'fpVoxels', 'fnVoxels', 'tnVoxels', 'dice', 'iou', ...
    'precision', 'recall', 'specificity', 'gtLesionVolumeMm3', 'predictedLesionVolumeMm3', ...
    'volumeErrorPercent', 'volumeDirection'});
writetable(complete3d, fullfile(cfg.paths.metrics, 'exp052_complete_3d_metrics.csv'));

fprintf('PRIMARY complete-volume 3D development results (recall = sensitivity):\n');
disp(complete3d(:, {'condition', 'dice', 'iou', 'precision', 'recall', 'specificity', 'gtLesionVolumeMm3', ...
    'predictedLesionVolumeMm3', 'volumeErrorPercent', 'volumeDirection'}));
fprintf('Supporting confusion counts (EXP-043):\n');
disp(complete3d(:, {'condition', 'tpVoxels', 'fpVoxels', 'fnVoxels', 'tnVoxels', 'totalVoxels'}));


%% 3. Controlli finali

stateAfter = arrayfun(@fileState, sourceFiles, 'UniformOutput', false);
scriptText = fileread([mfilename('fullpath') '.m']);
codeText = strjoin(regexprep(splitlines(string(scriptText)), '%.*$', ''), newline);
metricCalls = {['computeVoxel' 'Confusion('], ['FromConf' 'usion('], ['computeBinary' 'MaskVolume('], ...
    ['computeVolume' 'ErrorPercent(']};
newMetrics = {['accu' 'racy'], ['Accu' 'racy'], ['F' '1'], ['Fbe' 'ta'], ['MC' 'C'], ['RO' 'C'], ['AU' 'C'], ...
    ['Youd' 'en'], ['Haus' 'dorff'], ['bound' 'ary']};
aggregates = {['Development' 'Score'], ['development' 'Score'], ['mea' 'n('], ['med' 'ian(']};
granularity = {['for k' ' = 1:'], ['numberOf' 'Slices'], ['bwconn' 'comp('], ['region' 'props'], ['bwla' 'bel('], ...
    ['lesion' 'Wise'], ['perSl' 'ice']};
pipelineAccess = {['lo' 'ad('], ['loadBrainweb' 'Mri('], ['loadBrainweb' 'GroundTruth('], ['multi' 'thresh('], ...
    ['imquan' 'tize('], ['imo' 'pen('], ['imc' 'lose('], ['ime' 'rode('], ['imdi' 'late('], ['save' '(']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "no metric function called, no new metric",     ~any(cellfun(@(f) contains(codeText, f), [metricCalls newMetrics]))
    "no aggregate score / pn0-pn3 average",          ~any(cellfun(@(f) contains(codeText, f), aggregates))
    "no per-slice metrics, slice averaging, components or lesion-wise matching", ~any(cellfun(@(f) contains(codeText, f), granularity))
    "no MRI / mask loaded, no segmentation operation", ~any(cellfun(@(f) contains(codeText, f), pipelineAccess))
    "no held-out condition referenced",              ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "source EXP-043..051 artifacts unchanged (timestamp, size, content)", isequal(stateBefore, stateAfter)
    "config.m unchanged",                            isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];

for c = 1:size(checks, 1)
    if checks{c, 2}
        status = 'ok';
    else
        status = 'FAILED';
    end
    fprintf('%-85s %s\n', checks{c, 1}, status);
end
if any(~[checks{:, 2}])
    error('exp052:checksFailed', 'EXP-052 checks failed.');
end
fprintf('\nEXP-052 CHECKS: PASS (%d)\n', size(checks, 1));


function state = fileState(f)
%FILESTATE Data, dimensione e contenuto di un file (verifica di immutabilità).
    info = dir(f);
    state = {info.datenum, info.bytes, fileread(f)};
end
