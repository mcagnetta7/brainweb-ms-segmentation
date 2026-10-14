%% EXP-051 (fase 90): errore percentuale di volume delle lesioni
% Ingressi congelati: V_GT da EXP-049 (fase 88), V_pred da EXP-050 (fase 89),
% in mm^3. Nessuna maschera caricata, nessun volume ricalcolato.
%   VolumeErrorPercent = |V_pred - V_GT| / V_GT * 100   (PROJECT_SPEC 17)
% La metrica formale è assoluta; direzione (sovra/sottostima) solo
% descrittiva. Valori sopra 100 % validi, non limitati. pn0 e pn3 separati.
% Non misura la sovrapposizione spaziale.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
gtVolumeFile = fullfile(cfg.paths.metrics, 'exp049_gt_lesion_volume.csv');
predVolumeFile = fullfile(cfg.paths.metrics, 'exp050_predicted_lesion_volume.csv');
errorFunction = fullfile(cfg.paths.evaluation, 'computeVolumeErrorPercent.m');
checks = cell(0, 2);


%% 1. Artefatti delle fasi 88 e 89

for f = string({gtVolumeFile, predVolumeFile, errorFunction})
    if ~isfile(f)
        error('exp051:technicallyBlocked', 'PHASE 90 TECHNICALLY BLOCKED: missing %s', f);
    end
end
gtTable = readtable(gtVolumeFile, 'TextType', 'string');
predTable = readtable(predVolumeFile, 'TextType', 'string');
checks = [checks; {
    "EXP-049 GT-volume CSV exists",                   isfile(gtVolumeFile)
    "EXP-050 predicted-volume CSV exists",            isfile(predVolumeFile)
    "computeVolumeErrorPercent exists",               isfile(errorFunction)
    "EXP-049 contains exactly one row",               height(gtTable) == 1
    "EXP-050 contains exactly two rows",              height(predTable) == 2
    "EXP-050 conditions are exactly pn0 and pn3",     isequal(sort(predTable.condition).', noiseLevels)
    "EXP-050 prediction source = Phase-71 T2 M_pred", all(predTable.predictionSource == "Phase-71 T2 M_pred")
    "GT provenance: label 10, 3,512 voxels, 3,512 mm^3 (regression)", gtTable.lesionLabel == 10 && ...
        gtTable.gtLesionVoxels == 3512 && gtTable.gtLesionVolumeMm3 == 3512
    "GT and predicted volumes in compatible mm^3 geometry (same spacing, voxel 1 mm^3)", ...
        all(predTable.voxelVolumeMm3 == gtTable.voxelVolumeMm3) && gtTable.voxelVolumeMm3 == 1 && ...
        all(predTable.spacingXmm == gtTable.spacingXmm) && all(predTable.spacingYmm == gtTable.spacingYmm) && ...
        all(predTable.spacingZmm == gtTable.spacingZmm)
    }];

gtVolumeMm3 = gtTable.gtLesionVolumeMm3;          % valore salvato, non arrotondato
checks = [checks; {
    "GT volume finite",                               isfinite(gtVolumeMm3)
    "GT volume > 0",                                  gtVolumeMm3 > 0
    }];


%% 2. Errore di volume

rows = cell(2, 9);
for n = 1:2
    noise = noiseLevels(n);
    predVolumeMm3 = predTable.predictedLesionVolumeMm3(predTable.condition == noise);
    checks = [checks; {
        noise + " predicted volume finite",           isfinite(predVolumeMm3)
        noise + " predicted volume >= 0",             predVolumeMm3 >= 0
        }]; %#ok<AGROW>

    e = computeVolumeErrorPercent(gtVolumeMm3, predVolumeMm3);
    if e.signedDifference > 0
        direction = "overestimation";
    elseif e.signedDifference < 0
        direction = "underestimation";
    else
        direction = "exact match";
    end
    signedReference = predVolumeMm3 - gtVolumeMm3;
    checks = [checks; {
        noise + " signed difference = V_pred - V_GT", e.signedDifference == signedReference
        noise + " absolute difference = |signed difference|", e.absoluteDifference == abs(signedReference)
        noise + " error = |V_pred - V_GT| / V_GT * 100 (PROJECT_SPEC)", e.volumeErrorPercent == abs(signedReference) / gtVolumeMm3 * 100
        noise + " error finite and >= 0",             isfinite(e.volumeErrorPercent) && e.volumeErrorPercent >= 0
        noise + " error not clamped to 100 %",        e.volumeErrorPercent == e.absoluteDifference / gtVolumeMm3 * 100 && ...
            (e.absoluteDifference <= gtVolumeMm3 || e.volumeErrorPercent > 100)
        noise + " direction agrees with sign of signed difference", ...
            (direction == "overestimation") == (e.signedDifference > 0) && ...
            (direction == "underestimation") == (e.signedDifference < 0)
        }]; %#ok<AGROW>
    rows(n, :) = {noise, "Phase-71 T2 M_pred (EXP-050)", "BrainWeb crisp label 10 (EXP-049)", gtVolumeMm3, ...
        predVolumeMm3, e.signedDifference, e.absoluteDifference, e.volumeErrorPercent, direction};
end
resultTable = cell2table(rows, 'VariableNames', {'condition', 'predictionSource', 'gtVolumeSource', ...
    'gtLesionVolumeMm3', 'predictedLesionVolumeMm3', 'signedVolumeDifferenceMm3', ...
    'absoluteVolumeDifferenceMm3', 'volumeErrorPercent', 'volumeDirection'});
writetable(resultTable, fullfile(cfg.paths.metrics, 'exp051_formal_volume_error.csv'));
disp(resultTable);
for n = 1:2
    fprintf('%s: V_pred %g mm^3 vs V_GT %g mm^3 -> signed %+g mm^3, |diff| %g mm^3, VolumeError = %.10g %% (%s)\n', ...
        noiseLevels(n), resultTable.predictedLesionVolumeMm3(n), resultTable.gtLesionVolumeMm3(n), ...
        resultTable.signedVolumeDifferenceMm3(n), resultTable.absoluteVolumeDifferenceMm3(n), ...
        resultTable.volumeErrorPercent(n), resultTable.volumeDirection(n));
end
fprintf('\n');


%% 3. Controlli finali

scriptText = fileread([mfilename('fullpath') '.m']);
codeText = strjoin(regexprep(splitlines(string(scriptText)), '%.*$', ''), newline);
maskAccess = {['lo' 'ad('], ['loadBrainweb' 'GroundTruth('], ['loadBrainweb' 'Mri('], ['computeBinary' 'MaskVolume('], ...
    ['nn' 'z(']};
otherMetrics = {['computeVoxel' 'Confusion('], ['FromConf' 'usion('], ['Development' 'Score'], ['mea' 'n(']};
granularity = {['bwconn' 'comp('], ['region' 'props('], ['bwla' 'bel('], ['for k' ' = 1:'], ['perSl' 'ice'], ...
    ['lesion' 'Wise']};
segmentation = {['multi' 'thresh('], ['imquan' 'tize('], ['imo' 'pen('], ['imc' 'lose('], ['ime' 'rode('], ...
    ['imdi' 'late('], ['save' '(']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "no GT or prediction mask loaded, no physical volume recomputed", ~any(cellfun(@(f) contains(codeText, f), maskAccess))
    "no confusion-based metric, no aggregate score", ~any(cellfun(@(f) contains(codeText, f), otherMetrics))
    "no slice-wise / lesion-wise analysis",         ~any(cellfun(@(f) contains(codeText, f), granularity))
    "no segmentation operation / no mask saved",    ~any(cellfun(@(f) contains(codeText, f), segmentation))
    "no held-out condition referenced",             ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "config.m unchanged",                           isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
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
    error('exp051:checksFailed', 'EXP-051 checks failed.');
end
fprintf('\nEXP-051 CHECKS: PASS (%d)\n', size(checks, 1));
