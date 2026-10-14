%% EXP-054 (fase 93): analisi per lesione con componenti connesse 3D
% M_pred della fase 71 (T2), pn0 e pn3; GT completo (label 10). Oggetti =
% componenti 3D con connettività 26 (come nella fase 72). Regola fissata
% prima dei risultati: GT e predetta corrispondono se e solo se condividono
% >= 1 voxel; relazioni molti-a-molti, nessuna soglia di sovrapposizione,
% distanza o dimensione. Diagnostica a livello di oggetto: la tabella della
% fase 91 resta il risultato principale. Nessun filtro, nessuna analisi per
% dimensione (fase 94), nessun tuning.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
connectivity = 26;                               % definizione degli oggetti della fase 72
phase91File = fullfile(cfg.paths.metrics, 'exp052_complete_3d_metrics.csv');
phase92Files = fullfile(cfg.paths.metrics, ["exp053_slice_wise_metrics.csv" "exp053_slice_diagnostic_summary.csv"]);
phase72Summary = fullfile(cfg.paths.metrics, 'exp039_components3d_summary.csv');
phase71File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));
phase72File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase72_t2_%s_components3d.mat', noise));
matchFunction = fullfile(cfg.paths.evaluation, 'computeLesionWiseMatches.m');
checks = cell(0, 2);


%% 1. Ingressi

required = [string(phase91File), phase92Files, string(phase71File("pn0")), string(phase71File("pn3")), ...
    string(phase72File("pn0")), string(phase72File("pn3")), string(phase72Summary), string(matchFunction)];
for f = required
    if ~isfile(f)
        error('exp054:technicallyBlocked', 'PHASE 93 TECHNICALLY BLOCKED: missing %s', f);
    end
end
checks = [checks; {
    "Phase-91 consolidated CSV exists",              isfile(phase91File)
    "Phase-92 diagnostic artifacts exist",           all(arrayfun(@isfile, phase92Files))
    "Phase-71 pn0 M_pred exists",                    isfile(phase71File("pn0"))
    "Phase-71 pn3 M_pred exists",                    isfile(phase71File("pn3"))
    "Phase-72 pn0 3D-component artifact exists",     isfile(phase72File("pn0"))
    "Phase-72 pn3 3D-component artifact exists",     isfile(phase72File("pn3"))
    "Phase-72 3D-component summary exists",          isfile(phase72Summary)
    "computeLesionWiseMatches exists",               isfile(matchFunction)
    }];
frozenFiles = [string(phase91File), phase92Files];
frozenBefore = arrayfun(@fileState, frozenFiles, 'UniformOutput', false);
phase91 = readtable(phase91File, 'TextType', 'string');
p72summary = readtable(phase72Summary, 'TextType', 'string');

predMasks = cell(1, 2); predStateBefore = cell(1, 2);
for n = 1:2
    predStateBefore{n} = fileState(phase71File(noiseLevels(n)));
    s = load(phase71File(noiseLevels(n)), 'M_pred');
    predMasks{n} = s.M_pred;
end
predCopies = predMasks;
labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;                           % GT completo, nessuna restrizione
gtCopy = gtMask;
checks = [checks; {
    "pn0 prediction logical",                        islogical(predMasks{1})
    "pn3 prediction logical",                        islogical(predMasks{2})
    "GT logical",                                    islogical(gtMask)
    "all masks 181x217x181",                         isequal(size(predMasks{1}), expectedSize) && ...
        isequal(size(predMasks{2}), expectedSize) && isequal(size(gtMask), expectedSize)
    "GT exactly labels == 10",                       isequal(gtMask, labels == 10)
    "connectivity = 26",                             connectivity == 26
    }];


%% 2. Corrispondenze per lesione

results = cell(1, 2);
for n = 1:2
    results{n} = computeLesionWiseMatches(predMasks{n}, gtMask, connectivity);
end
checks = [checks; {
    "same connectivity for GT / pn0 / pn3",          results{1}.connectivity == 26 && results{2}.connectivity == 26
    "GT component set identical across pn0 / pn3",   isequal(results{1}.gtComponents, results{2}.gtComponents)
    "GT component count same for pn0 and pn3",      results{1}.gtComponentCount == results{2}.gtComponentCount
    }];

summaryRows = cell(2, 13);
gtStatus = table(); predStatus = table(); matches = table();
for n = 1:2
    noise = noiseLevels(n);
    r = results{n};
    gtT = r.gtComponentTable; prT = r.predictedComponentTable; mT = r.matchTable;
    p91 = phase91(phase91.condition == noise, :);
    s72 = load(phase72File(noise), 'CC3D');
    row72 = p72summary(p72summary.condition == noise, :);

    gtUnion = false(expectedSize); gtUnion(vertcat(r.gtComponents{:})) = true;
    prUnion = false(expectedSize); prUnion(vertcat(r.predictedComponents{:})) = true;
    gtSizes = cellfun(@numel, r.gtComponents); prSizes = cellfun(@numel, r.predictedComponents);
    merged = prT.matchedGtCount > 1; split = gtT.matchedPredictionCount > 1;
    checks = [checks; {
        noise + " every GT component has >= 1 voxel",  all(gtSizes >= 1)
        noise + " every predicted component has >= 1 voxel", all(prSizes >= 1)
        noise + " GT component union reconstructs M_GT exactly", isequal(gtUnion, gtMask)
        noise + " predicted component union reconstructs M_pred exactly", isequal(prUnion, predMasks{n})
        noise + " GT components mutually disjoint",    sum(gtSizes) == nnz(gtMask)
        noise + " predicted components mutually disjoint", sum(prSizes) == nnz(predMasks{n})
        noise + " every match overlap > 0",            all(mT.overlapVoxels > 0)
        noise + " no duplicate GT / predicted pairs",  height(unique(mT(:, 1:2))) == height(mT)
        noise + " detected GT >= 1 match, missed GT 0 matches", all(gtT.matchedPredictionCount(gtT.isDetected) >= 1) && ...
            all(gtT.matchedPredictionCount(gtT.isMissed) == 0) && isequal(gtT.isDetected, ~gtT.isMissed)
        noise + " matched pred >= 1 GT match, false pred 0 matches", all(prT.matchedGtCount(prT.isMatched) >= 1) && ...
            all(prT.matchedGtCount(prT.isFalseLesion) == 0) && isequal(prT.isMatched, ~prT.isFalseLesion)
        noise + " detected + missed = GT components",  r.detectedGtLesionCount + r.missedGtLesionCount == r.gtComponentCount
        noise + " matched + false = predicted components", r.matchedPredictedComponentCount + r.falsePredictedComponentCount == r.predictedComponentCount
        noise + " predicted components = Phase-72 (count and voxel lists)", r.predictedComponentCount == s72.CC3D.NumObjects && ...
            r.predictedComponentCount == row72.total3DComponents && isequal(r.predictedComponents, s72.CC3D.PixelIdxList)
        noise + " sum of relation overlaps = Phase-91 TP", sum(mT.overlapVoxels) == p91.tpVoxels
        noise + " status tables: one row per component", height(gtT) == r.gtComponentCount && height(prT) == r.predictedComponentCount
        noise + " relation counts consistent with the match table", ...
            sum(gtT.matchedPredictionCount) == height(mT) && sum(prT.matchedGtCount) == height(mT)
        noise + " merge / split diagnostics agree with relation counts", ...
            nnz(merged) == nnz(prT.matchedGtCount > 1) && nnz(split) == nnz(gtT.matchedPredictionCount > 1)
        }]; %#ok<AGROW>

    summaryRows(n, :) = {noise, "Phase-71 T2 M_pred", connectivity, r.gtComponentCount, r.predictedComponentCount, ...
        r.detectedGtLesionCount, r.missedGtLesionCount, r.matchedPredictedComponentCount, ...
        r.falsePredictedComponentCount, nnz(split), nnz(merged), height(mT), sum(mT.overlapVoxels)};
    gtStatus = [gtStatus; addvars(gtT, repmat(noise, height(gtT), 1), 'Before', 1, 'NewVariableNames', 'condition')]; %#ok<AGROW>
    predStatus = [predStatus; addvars(prT, repmat(noise, height(prT), 1), 'Before', 1, 'NewVariableNames', 'condition')]; %#ok<AGROW>
    matches = [matches; addvars(mT, repmat(noise, height(mT), 1), 'Before', 1, 'NewVariableNames', 'condition')]; %#ok<AGROW>
end
summary = cell2table(summaryRows, 'VariableNames', {'condition', 'predictionSource', 'connectivity', 'gtLesions', ...
    'predictedComponents', 'detectedGtLesions', 'missedGtLesions', 'matchedPredictedComponents', ...
    'falsePredictedComponents', 'gtLesionsMatchedByMultiplePredictions', ...
    'predictedComponentsMatchingMultipleGtLesions', 'matchRelations', 'overlapVoxelsAcrossRelations'});
writetable(summary, fullfile(cfg.paths.metrics, 'exp054_lesion_wise_summary.csv'));
writetable(gtStatus, fullfile(cfg.paths.metrics, 'exp054_gt_lesion_status.csv'));
writetable(predStatus, fullfile(cfg.paths.metrics, 'exp054_predicted_component_status.csv'));
writetable(matches, fullfile(cfg.paths.metrics, 'exp054_lesion_matches.csv'));
disp(summary);

% Descrizione delle relazioni (solo conteggi; nessuna classificazione per dimensione)
for n = 1:2
    r = results{n};
    fprintf('%s: matched predicted components overlapping 1 / 2 / >=3 GT lesions: %d / %d / %d\n', noiseLevels(n), ...
        nnz(r.predictedComponentTable.matchedGtCount == 1), nnz(r.predictedComponentTable.matchedGtCount == 2), ...
        nnz(r.predictedComponentTable.matchedGtCount >= 3));
    fprintf('    detected GT lesions matched by 1 / 2 / >=3 predicted components: %d / %d / %d\n', ...
        nnz(r.gtComponentTable.matchedPredictionCount == 1), nnz(r.gtComponentTable.matchedPredictionCount == 2), ...
        nnz(r.gtComponentTable.matchedPredictionCount >= 3));
end
detectedBoth = nnz(results{1}.gtComponentTable.isDetected & results{2}.gtComponentTable.isDetected);
fprintf('GT lesions detected in both conditions: %d; only pn0: %d; only pn3: %d\n\n', detectedBoth, ...
    nnz(results{1}.gtComponentTable.isDetected & ~results{2}.gtComponentTable.isDetected), ...
    nnz(~results{1}.gtComponentTable.isDetected & results{2}.gtComponentTable.isDetected));


%% 3. Controlli finali

predUnchanged = true;
for n = 1:2
    s = load(phase71File(noiseLevels(n)), 'M_pred');
    predUnchanged = predUnchanged && isequal(fileState(phase71File(noiseLevels(n))), predStateBefore{n}) && ...
        isequal(s.M_pred, predCopies{n});
end
frozenAfter = arrayfun(@fileState, frozenFiles, 'UniformOutput', false);
scriptText = fileread([mfilename('fullpath') '.m']);
codeText = strjoin(regexprep(splitlines(string(scriptText)), '%.*$', ''), newline);
functionCode = strjoin(regexprep(splitlines(string(fileread(matchFunction))), '%.*$', ''), newline);
bothCode = codeText + newline + functionCode;
forbiddenMatching = {['match' 'pairs('], ['hung' 'arian'], ['munk' 'res'], ['centr' 'oid'], ['Centr' 'oid'], ...
    ['pdi' 'st2('], ['overlap' 'Fraction'], ['min' 'Overlap'], ['region' 'props']};
forbiddenSize = {['min' 'Size'], ['minLesion' 'Size'], ['size' 'Threshold'], ['sm' 'all'], ['la' 'rge'], ...
    ['bwarea' 'open('], ['filterComponents' 'ByArea']};
forbiddenOther = {['loadBrainweb' 'Mri('], ['multi' 'thresh('], ['imquan' 'tize('], ['imo' 'pen('], ['imc' 'lose('], ...
    ['ime' 'rode('], ['imdi' 'late('], ['save' '('], ['mea' 'n('], ['F' '1'], ['zCut' 'off']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "no one-to-one assignment, overlap-fraction threshold or distance-based matching", ~any(cellfun(@(f) contains(bothCode, f), forbiddenMatching))
    "no size threshold, size categorization or component filtering", ~any(cellfun(@(f) contains(bothCode, f), forbiddenSize))
    "no segmentation operation, tuning, combined score or location rule", ~any(cellfun(@(f) contains(codeText, f), forbiddenOther))
    "no held-out condition referenced",              ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "Phase-71 masks unchanged",                      predUnchanged && isequal(predMasks, predCopies)
    "Phase-91 and Phase-92 artifacts unchanged",     isequal(frozenBefore, frozenAfter)
    "GT unchanged",                                  isequal(gtMask, gtCopy)
    "config.m unchanged",                            isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];

for c = 1:size(checks, 1)
    if checks{c, 2}
        status = 'ok';
    else
        status = 'FAILED';
    end
    fprintf('%-90s %s\n', checks{c, 1}, status);
end
if any(~[checks{:, 2}])
    error('exp054:checksFailed', 'EXP-054 checks failed.');
end
fprintf('\nEXP-054 CHECKS: PASS (%d)\n', size(checks, 1));


function state = fileState(f)
%FILESTATE Data, dimensione e contenuto di un file (verifica di immutabilità).
    info = dir(f);
    state = {info.datenum, info.bytes, fileread(f)};
end
