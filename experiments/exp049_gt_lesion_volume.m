%% EXP-049 (fase 88): volume fisico delle lesioni nel GT
% M_GT = labels == 10 sull'intero volume 181x217x181 (stessa anatomia crisp
% per pn0 e pn3: un solo valore). Spaziatura 1 x 1 x 1 mm verificata nella
% fase 26 (note 13.7.2); config.m non ha un campo spaziatura, quindi è
% passata qui in modo esplicito.
%   V_GT = N_GT * V_voxel,  V_voxel = prod(spaziatura)
% Nessuna predizione caricata, nessun volume predetto, nessun errore di
% volume, nessuna metrica di confusione, nessuna componente connessa.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

expectedSize = [181 217 181];
lesionLabel = 10;
voxelSpacingMm = [1 1 1];                        % fase 26 (note 13.7.2): passo 1 mm su x, y, z
establishedGtVoxels = 3512;                      % invariante già verificata (fase 22, note 13.5.3): solo regressione
volumeFunction = fullfile(cfg.paths.evaluation, 'computeBinaryMaskVolume.m');
checks = cell(0, 2);


%% 1. Ground truth

checks(end+1, :) = {"computeBinaryMaskVolume exists", isfile(volumeFunction)};
labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == lesionLabel;                  % GT completo, nessuna maschera / ROI / selezione di slice
gtCopy = gtMask;
spacingCopy = voxelSpacingMm;
checks = [checks; {
    "GT loads successfully",                          ~isempty(labels)
    "GT dimensions = 181x217x181",                    isequal(size(labels), expectedSize) && isequal(cfg.dataset.volumeSize, expectedSize)
    "GT total voxels = 7,109,137",                    numel(labels) == 7109137 && numel(gtMask) == 7109137
    "M_GT logical",                                   islogical(gtMask)
    "M_GT = labels == 10 exactly",                    isequal(gtMask, labels == 10)
    "M_GT non-empty array with positive lesion voxels", ~isempty(gtMask) && any(gtMask(:))
    }];


%% 2. Geometria e volume

checks = [checks; {
    "spacing has exactly 3 elements",                 numel(voxelSpacingMm) == 3
    "spacing = [1 1 1] mm (validated geometry, Phase 26)", isequal(voxelSpacingMm, [1 1 1])
    "every spacing value finite",                     all(isfinite(voxelSpacingMm))
    "every spacing value positive",                   all(voxelSpacingMm > 0)
    }];

volumeInfo = computeBinaryMaskVolume(gtMask, voxelSpacingMm);
gtLesionVoxels = nnz(gtMask);                    % conteggio indipendente
checks = [checks; {
    "voxel volume = product of spacing",              volumeInfo.voxelVolumeMm3 == prod(voxelSpacingMm)
    "voxel volume = 1 mm^3 for this dataset",         volumeInfo.voxelVolumeMm3 == 1
    "GT lesion voxel count = nnz(M_GT)",              volumeInfo.voxelCount == gtLesionVoxels
    "GT lesion voxel count reproduces the established 3,512-voxel invariant", volumeInfo.voxelCount == establishedGtVoxels
    "GT volume = voxel count * voxel volume",         volumeInfo.volumeMm3 == volumeInfo.voxelCount * volumeInfo.voxelVolumeMm3
    "GT volume finite and non-negative",              isfinite(volumeInfo.volumeMm3) && volumeInfo.volumeMm3 >= 0
    "volumeCm3 = volumeMm3 / 1000",                   volumeInfo.volumeCm3 == volumeInfo.volumeMm3 / 1000
    "volumeMl = volumeMm3 / 1000 = volumeCm3",        volumeInfo.volumeMl == volumeInfo.volumeMm3 / 1000 && volumeInfo.volumeMl == volumeInfo.volumeCm3
    }];

result = table("BrainWeb msles2 crisp phantom (phantom_1.0mm_msles2_crisp.rawb)", lesionLabel, ...
    expectedSize(1), expectedSize(2), expectedSize(3), voxelSpacingMm(1), voxelSpacingMm(2), voxelSpacingMm(3), ...
    volumeInfo.voxelVolumeMm3, volumeInfo.voxelCount, volumeInfo.volumeMm3, volumeInfo.volumeCm3, volumeInfo.volumeMl, ...
    "pn0 and pn3 (shared crisp GT)", 'VariableNames', {'gtSource', 'lesionLabel', 'sizeX', 'sizeY', 'sizeZ', ...
    'spacingXmm', 'spacingYmm', 'spacingZmm', 'voxelVolumeMm3', 'gtLesionVoxels', 'gtLesionVolumeMm3', ...
    'gtLesionVolumeCm3', 'gtLesionVolumeMl', 'appliesTo'});
writetable(result, fullfile(cfg.paths.metrics, 'exp049_gt_lesion_volume.csv'));
disp(result);
fprintf(['GT lesion voxels = %d; each voxel occupies %g mm^3 (spacing %g x %g x %g mm);\n' ...
    'GT lesion volume = %g mm^3 = %g cm^3 = %g mL (same for pn0 and pn3)\n\n'], volumeInfo.voxelCount, ...
    volumeInfo.voxelVolumeMm3, voxelSpacingMm, volumeInfo.volumeMm3, volumeInfo.volumeCm3, volumeInfo.volumeMl);


%% 3. Controlli finali

scriptText = fileread([mfilename('fullpath') '.m']);
codeText = strjoin(regexprep(splitlines(string(scriptText)), '%.*$', ''), newline);
predictionUse = {['M_' 'pred'], ['phase71' '_t2'], ['predicted' 'Volume'], ['pred' 'Mask']};
errorPatterns = {['volume' 'Error'], ['abs' '('], ['relative' 'Difference'], ['ratio' ' =']};
otherMetrics = {['computeVoxel' 'Confusion('], ['FromConf' 'usion(']};
granularity = {['bwconn' 'comp('], ['region' 'props('], ['bwla' 'bel('], ['for k' ' = 1:'], ['perSl' 'ice'], ...
    ['lesion' 'Wise']};
segmentation = {['loadBrainweb' 'Mri('], ['multi' 'thresh('], ['imquan' 'tize('], ['imo' 'pen('], ['imc' 'lose('], ...
    ['ime' 'rode('], ['imdi' 'late('], ['save' '(']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "no prediction loaded, no predicted volume",     ~any(cellfun(@(f) contains(codeText, f), predictionUse))
    "no volume error / ratio computed",              ~any(cellfun(@(f) contains(codeText, f), errorPatterns))
    "no confusion-based metric recomputed",          ~any(cellfun(@(f) contains(codeText, f), otherMetrics))
    "no connected components / slice-wise / lesion-wise volume", ~any(cellfun(@(f) contains(codeText, f), granularity))
    "no segmentation operation / no mask saved",     ~any(cellfun(@(f) contains(codeText, f), segmentation))
    "no held-out condition referenced",              ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "GT and spacing unchanged",                      isequal(gtMask, gtCopy) && isequal(voxelSpacingMm, spacingCopy)
    "config.m unchanged",                            isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];

for c = 1:size(checks, 1)
    if checks{c, 2}
        status = 'ok';
    else
        status = 'FAILED';
    end
    fprintf('%-75s %s\n', checks{c, 1}, status);
end
if any(~[checks{:, 2}])
    error('exp049:checksFailed', 'EXP-049 checks failed.');
end
fprintf('\nEXP-049 CHECKS: PASS (%d)\n', size(checks, 1));
