%% v4 congelata sui held-out già visti pn1 / pn5 / pn7 / pn9 (analisi SECONDARIA, emendamento A3)
% La v4 (tag v4-frozen, generateV4Prediction(rawT1, rawT2, 5)) è congelata: questa valutazione
% non può modificarla. I livelli pn1-pn9 sono già stati usati per il test della v3, quindi non
% sono un test indipendente per la v4: risultato descrittivo, confrontato con la v3 della fase 97.
% Ordine: integrità -> 4 predizioni v4 salvate -> GT -> metriche e diagnostica per lesione.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.evaluation);
M = cfg.paths.metrics;
heldOut = ["pn1" "pn5" "pn7" "pn9"];
mriDir = fileparts(cfg.dataset.mriFiles.T1);
cfgHeld = cfg;
for n = heldOut
    cfgHeld.dataset.noisyMriFiles.(n).T1 = fullfile(mriDir, sprintf('t1_ai_msles2_1mm_%s_rf0.raws', n));
    cfgHeld.dataset.noisyMriFiles.(n).T2 = fullfile(mriDir, sprintf('t2_ai_msles2_1mm_%s_rf0.raws', n));
end
v4Manifest = readtable(fullfile(projectRoot, 'docs', 'v4_freeze_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
v4Ok = @() all(arrayfun(@(i) strcmp(sha256File(fullfile(projectRoot, v4Manifest.path(i))), v4Manifest.sha256(i)), ...
    1:height(v4Manifest)));
[gitStatus, gitOut] = system(sprintf('git -C "%s" rev-list -n 1 v4-frozen', projectRoot));
if ~(v4Ok() && gitStatus == 0 && startsWith(strtrim(string(gitOut)), "2525dde"))
    error('v4heldout:notFrozen', 'v4 freeze could not be verified.');
end

% 1. Predizioni v4 (nessun GT)
pred = cell(1, 4); det = cell(1, 4);
for i = 1:4
    [pred{i}, d] = generateV4Prediction(loadBrainwebMri(cfgHeld, "T1", heldOut(i)), ...
        loadBrainwebMri(cfgHeld, "T2", heldOut(i)), 5);
    det{i} = rmfield(d, 'S2');
    M_pred = pred{i}; metadata = struct('version', "v4", 'k', 5, 'condition', heldOut(i), ...
        'role', "SECONDARY (held-out already seen by v3)", 'details', det{i}, 'gtUsedForGeneration', false);
    save(fullfile(cfg.paths.processedData, sprintf('v4_secondary_%s_prediction.mat', heldOut(i))), 'M_pred', 'metadata');
    fprintf('%s: TA2 %.4f, floor muWM+5sigmaWM %.4f (muWM %.4f, sigmaWM %.4f), floor active %d, %d voxels\n', ...
        heldOut(i), d.taLevels(2), d.floorValue, d.muWM, d.sigmaWM, d.floorActive, nnz(pred{i}));
end

% 2. GT e metriche, confronto con la v3 (fase 97, valori letti dai CSV)
gt = loadBrainwebGroundTruth(cfg) == 10;
sizeTable = readtable(fullfile(M, 'exp055_gt_lesion_size_analysis.csv'), 'TextType', 'string');
sizeOfLesion = sortrows(sizeTable(sizeTable.condition == "pn0", {'gtLesionId', 'sizeClass'}), 'gtLesionId');
small = sizeOfLesion.sizeClass == "SMALL";
v3 = readtable(fullfile(M, 'phase97_v3_heldout_metrics.csv'), 'TextType', 'string');
v3les = readtable(fullfile(M, 'phase97_v3_lesionwise_diagnostics.csv'), 'TextType', 'string');
rows = cell(4, 21);
for i = 1:4
    cnt = computeVoxelConfusion(pred{i}, gt);
    lw = computeLesionWiseMatches(pred{i}, gt, 26);
    det4 = lw.gtComponentTable.isDetected;
    r3 = v3(v3.condition == heldOut(i), :); l3 = v3les(v3les.condition == heldOut(i), :);
    rows(i, :) = {heldOut(i), r3.dice, computeDiceFromConfusion(cnt), r3.precision, computePrecisionFromConfusion(cnt), ...
        r3.recall, computeRecallFromConfusion(cnt), r3.predictedVoxels, cnt.TP + cnt.FP, r3.fpVoxels, cnt.FP, ...
        l3.detectedGtLesions, lw.detectedGtLesionCount, l3.falsePredictedComponents, lw.falsePredictedComponentCount, ...
        l3.smallDetected, nnz(det4 & small), l3.largeDetected, nnz(det4 & ~small), det{i}.taLevels(2), det{i}.threshold};
end
cmp = cell2table(rows, 'VariableNames', {'condition', 'diceV3', 'diceV4', 'precisionV3', 'precisionV4', 'recallV3', ...
    'recallV4', 'predictedV3', 'predictedV4', 'fpV3', 'fpV4', 'detectedV3', 'detectedV4', 'falseCompV3', 'falseCompV4', ...
    'smallDetectedV3', 'smallDetectedV4', 'largeDetectedV3', 'largeDetectedV4', 'taLevel2', 'thresholdV4'});
writetable(cmp, fullfile(M, 'v4_secondary_heldout_comparison.csv'));
disp(cmp);
fprintf('Mean Dice over pn1/5/7/9 (descriptive): v3 %.4f, v4 %.4f\n', mean(cmp.diceV3), mean(cmp.diceV4));
fprintf('GT lesions: 59 (SMALL 31, LARGE 28); "detected" = at least one shared voxel.\n');
if ~v4Ok()
    error('v4heldout:changed', 'v4 frozen files changed during the analysis.');
end
fprintf('\nv4 SECONDARY HELD-OUT CHECK: DONE (v4 frozen files unchanged)\n');


function h = sha256File(f)
%SHA256FILE Impronta SHA-256 (esadecimale maiuscolo) tramite certutil di Windows.
    [status, out] = system(sprintf('certutil -hashfile "%s" SHA256', f));
    lines = erase(strtrim(splitlines(string(out))), " ");
    match = lines(strlength(lines) == 64 & ~cellfun(@isempty, regexp(cellstr(lines), '^[0-9a-fA-F]{64}$')));
    if status ~= 0 || numel(match) ~= 1
        error('v4heldout:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
