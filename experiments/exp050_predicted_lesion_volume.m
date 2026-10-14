%% EXP-050 (fase 89): volume fisico delle lesioni predette
% M_pred della fase 71 (T2), pn0 e pn3 separati (maschere diverse).
%   V_pred = N_pred * V_voxel   con computeBinaryMaskVolume (fase 88, invariata)
% Spaziatura 1 x 1 x 1 mm (fase 26, come nella fase 88). Il volume predetto
% comprende tutti i voxel predetti positivi (TP + FP): non è il volume reale
% delle lesioni. Nessun GT caricato, nessun confronto con il volume del GT,
% nessun errore di volume (fase 90).

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
voxelSpacingMm = [1 1 1];                        % fase 26 (note 13.7.2), come in EXP-049
phase71File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));
volumeFunction = fullfile(cfg.paths.evaluation, 'computeBinaryMaskVolume.m');
phase88File = fullfile(cfg.paths.metrics, 'exp049_gt_lesion_volume.csv');
confusionFile = fullfile(cfg.paths.metrics, 'exp043_voxel_confusion_matrix.csv');
checks = cell(0, 2);


%% 1. Artefatti e predizioni

for f = string({volumeFunction, phase88File, confusionFile})
    if ~isfile(f)
        error('exp050:technicallyBlocked', 'PHASE 89 TECHNICALLY BLOCKED: missing %s', f);
    end
end
functionInfoBefore = dir(volumeFunction);
functionTextBefore = fileread(volumeFunction);
phase88 = readtable(phase88File, 'TextType', 'string');  % solo provenienza della spaziatura
checks = [checks; {
    "computeBinaryMaskVolume exists",                 isfile(volumeFunction)
    "Phase-88 artifact exists, same spacing provenance", height(phase88) == 1 && ...
        isequal([phase88.spacingXmm phase88.spacingYmm phase88.spacingZmm], voxelSpacingMm)
    }];

predMasks = cell(1, 2);
fileInfoBefore = cell(1, 2);
for n = 1:2
    noise = noiseLevels(n);
    checks(end+1, :) = {"Phase-71 " + noise + " M_pred file exists", isfile(phase71File(noise))}; %#ok<SAGROW>
    if ~isfile(phase71File(noise))
        error('exp050:technicallyBlocked', 'PHASE 89 TECHNICALLY BLOCKED: missing %s', phase71File(noise));
    end
    fileInfoBefore{n} = dir(phase71File(noise));
    s = load(phase71File(noise));
    hasVariable = isfield(s, 'M_pred');
    checks(end+1, :) = {noise + " M_pred variable exists", hasVariable}; %#ok<SAGROW>
    if ~hasVariable || ~islogical(s.M_pred) || ~isequal(size(s.M_pred), expectedSize)
        error('exp050:technicallyBlocked', 'PHASE 89 TECHNICALLY BLOCKED: invalid M_pred for %s.', noise);
    end
    predMasks{n} = s.M_pred;
    checks = [checks; {
        noise + " M_pred logical",                    islogical(predMasks{n})
        noise + " size = 181x217x181",                isequal(size(predMasks{n}), expectedSize)
        noise + " total voxels = 7,109,137",          numel(predMasks{n}) == 7109137
        }]; %#ok<AGROW>
end
predCopies = predMasks;


%% 2. Geometria e volume predetto

checks = [checks; {
    "spacing has exactly 3 elements",                 numel(voxelSpacingMm) == 3
    "spacing = [1 1 1] mm (validated geometry, Phase 26)", isequal(voxelSpacingMm, [1 1 1])
    "all spacing values finite",                      all(isfinite(voxelSpacingMm))
    "all spacing values positive",                    all(voxelSpacingMm > 0)
    }];

phase82 = readtable(confusionFile, 'TextType', 'string');
rows = cell(2, 13);
for n = 1:2
    noise = noiseLevels(n);
    predictedPositiveVoxels = nnz(predMasks{n});           % conteggio indipendente
    volumeInfo = computeBinaryMaskVolume(predMasks{n}, voxelSpacingMm);
    ref = phase82(phase82.condition == noise, :);
    if n == 1
        checks = [checks; {
            "voxel volume = product of spacing",      volumeInfo.voxelVolumeMm3 == prod(voxelSpacingMm)
            "voxel volume = 1 mm^3",                  volumeInfo.voxelVolumeMm3 == 1
            }]; %#ok<AGROW>
    end
    checks = [checks; {
        noise + " predicted-positive count = nnz(M_pred) = function voxelCount", ...
            volumeInfo.voxelCount == predictedPositiveVoxels
        noise + " predicted volume = voxelCount * voxelVolume", volumeInfo.volumeMm3 == volumeInfo.voxelCount * volumeInfo.voxelVolumeMm3
        noise + " predicted volume finite and non-negative", isfinite(volumeInfo.volumeMm3) && volumeInfo.volumeMm3 >= 0
        noise + " cm^3 = mL = mm^3 / 1000",           volumeInfo.volumeCm3 == volumeInfo.volumeMm3 / 1000 && ...
            volumeInfo.volumeMl == volumeInfo.volumeMm3 / 1000 && volumeInfo.volumeCm3 == volumeInfo.volumeMl
        noise + " predicted count = TP + FP of EXP-043 (regression)", height(ref) == 1 && ...
            predictedPositiveVoxels == ref.tpVoxels + ref.fpVoxels
        }]; %#ok<AGROW>
    rows(n, :) = {noise, "Phase-71 T2 M_pred", expectedSize(1), expectedSize(2), expectedSize(3), ...
        voxelSpacingMm(1), voxelSpacingMm(2), voxelSpacingMm(3), volumeInfo.voxelVolumeMm3, volumeInfo.voxelCount, ...
        volumeInfo.volumeMm3, volumeInfo.volumeCm3, volumeInfo.volumeMl};
end
resultTable = cell2table(rows, 'VariableNames', {'condition', 'predictionSource', 'sizeX', 'sizeY', 'sizeZ', ...
    'spacingXmm', 'spacingYmm', 'spacingZmm', 'voxelVolumeMm3', 'predictedLesionVoxels', ...
    'predictedLesionVolumeMm3', 'predictedLesionVolumeCm3', 'predictedLesionVolumeMl'});
writetable(resultTable, fullfile(cfg.paths.metrics, 'exp050_predicted_lesion_volume.csv'));
disp(resultTable);
for n = 1:2
    fprintf('%s: %d predicted-positive voxels x %g mm^3 = %g mm^3 = %g cm^3 = %g mL (segmented volume, TP + FP)\n', ...
        noiseLevels(n), resultTable.predictedLesionVoxels(n), resultTable.voxelVolumeMm3(n), ...
        resultTable.predictedLesionVolumeMm3(n), resultTable.predictedLesionVolumeCm3(n), ...
        resultTable.predictedLesionVolumeMl(n));
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
functionInfoAfter = dir(volumeFunction);
scriptText = fileread([mfilename('fullpath') '.m']);
codeText = strjoin(regexprep(splitlines(string(scriptText)), '%.*$', ''), newline);
gtArithmetic = {['loadBrainweb' 'GroundTruth('], ['gtLesion' 'Volume'], ['phase88.gt' 'Lesion'], ['V_' 'GT'], ...
    ['volume' 'Error'], ['abs' '('], ['Differ' 'ence'], ['Rat' 'io'], ['Perc' 'ent'], ['* 1' '00']};
otherMetrics = {['computeVoxel' 'Confusion('], ['FromConf' 'usion(']};
granularity = {['bwconn' 'comp('], ['region' 'props('], ['bwla' 'bel('], ['for k' ' = 1:'], ['perSl' 'ice'], ...
    ['lesion' 'Wise']};
segmentation = {['loadBrainweb' 'Mri('], ['multi' 'thresh('], ['imquan' 'tize('], ['imo' 'pen('], ['imc' 'lose('], ...
    ['ime' 'rode('], ['imdi' 'late('], ['save' '(']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "Phase-71 source files unchanged",               sourcesUnchanged && isequal(predMasks, predCopies)
    "computeBinaryMaskVolume unchanged",             functionInfoAfter.datenum == functionInfoBefore.datenum && ...
        isequal(fileread(volumeFunction), functionTextBefore)
    "no GT loaded, no arithmetic with the GT volume",  ~any(cellfun(@(f) contains(codeText, f), gtArithmetic))
    "no confusion-based metric recomputed",          ~any(cellfun(@(f) contains(codeText, f), otherMetrics))
    "no connected components / slice-wise / lesion-wise volume", ~any(cellfun(@(f) contains(codeText, f), granularity))
    "no segmentation operation / no mask saved",     ~any(cellfun(@(f) contains(codeText, f), segmentation))
    "no held-out condition referenced",              ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "config.m unchanged",                            isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];

for c = 1:size(checks, 1)
    if checks{c, 2}
        status = 'ok';
    else
        status = 'FAILED';
    end
    fprintf('%-78s %s\n', checks{c, 1}, status);
end
if any(~[checks{:, 2}])
    error('exp050:checksFailed', 'EXP-050 checks failed.');
end
fprintf('\nEXP-050 CHECKS: PASS (%d)\n', size(checks, 1));
