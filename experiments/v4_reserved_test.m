%% Test riservato della v4 (emendamento A3; protocollo registrato prima di generare i dati)
% Esecuzione UNICA. Versioni congelate: v4 = generateV4Prediction(rawT1, rawT2, 5) (PRINCIPALE,
% tag v4-frozen) e v3 = generateFinalPrediction(rawT1, rawT2) (riferimento, tag v3-final-frozen).
% Dati: simulazioni custom AI, 1 mm, INU 0 %, seme 2: normal 0 % / 3 %, msles1 3 %, msles3 3 %.
% Ordine: integrità -> 8 predizioni salvate e rilette -> GT -> metriche del protocollo.
% Fantoccio normal (|GT| = 0): niente Dice / Recall / Precision; si riportano voxel e volume FP,
% frazione FP della maschera cerebrale e di S2, componenti false, Specificity.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.evaluation);
M = cfg.paths.metrics;
rel = @(p) strrep(erase(string(p), string(projectRoot) + filesep), '\', '/');
testDir = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'v4_reserved_test');
oldGt = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'phase101', 'ground_truth');

conds = struct( ...
    'id',  {"normal_n0", "normal_n3", "msles1_n3", "msles3_n3"}, ...
    't1',  {'custom_normal_t1_ai_1mm_n0_inu0_seed2_job1261017-094107s-2844999.raws', ...
            'custom_normal_t1_ai_1mm_n3_inu0_seed2_job1261017-094138s-2845156.raws', ...
            'custom_msles1_t1_ai_1mm_n3_inu0_seed2_job1261017-094208s-2845311.raws', ...
            'custom_msles3_t1_ai_1mm_n3_inu0_seed2_job1261017-094301s-2845466.raws'}, ...
    't2',  {'custom_normal_t2_ai_1mm_n0_inu0_seed2_job1261017-094123s-2845078.raws', ...
            'custom_normal_t2_ai_1mm_n3_inu0_seed2_job1261017-094153s-2845233.raws', ...
            'custom_msles1_t2_ai_1mm_n3_inu0_seed2_job1261017-094235s-2845389.raws', ...
            'custom_msles3_t2_ai_1mm_n3_inu0_seed2_job1261017-094329s-2845552.raws'}, ...
    'h1',  {'8047C03F7E65036589CC867BB0616D651C4BF01BF0DFD6A225A642CBAF0AD33E', ...
            'D43D19C2DB6844F3AABD3B7EB622CF35B28BC34627D9BE191A93373099346934', ...
            '69DB250D99B4382FD884DA3884A56878935B5DC7CEA9EA03D71A2CCE6E9E643E', ...
            'B4D02188F51911495682C40871722114D4341E7EE764A2F1EF8BF5DE6715A660'}, ...
    'h2',  {'63E169D7F8CAC80A767E00229B6B4F699A6098FE03765E11627B9B36CE82C120', ...
            'C793B4A82EBC1D1612FF5CABA1AFF247C1DB8A190F50C3A3CBE13B092C16161B', ...
            '95F55879579AD3DBE5EA58A98ABB2EFE32B4FE03A4D66F75342C3FA479A4B956', ...
            'A561C64310510C8A83B9E91B96DFFC80F3D961C86F8981FF0FF74A66B963DA47'}, ...
    'gt',  {fullfile(testDir, 'ground_truth', 'phantom_1.0mm_normal_crisp.rawb'), ...
            fullfile(testDir, 'ground_truth', 'phantom_1.0mm_normal_crisp.rawb'), ...
            fullfile(oldGt, 'phantom_1.0mm_msles1_crisp.rawb'), fullfile(oldGt, 'phantom_1.0mm_msles3_crisp.rawb')}, ...
    'hgt', {'8693F9FDE4F2B233237F2C5D0C4E4E2AAC705BB08EFD1E13AE70079AB7456C54', ...
            '8693F9FDE4F2B233237F2C5D0C4E4E2AAC705BB08EFD1E13AE70079AB7456C54', ...
            '3F0DA14AE35395978F921C52174538D050239EE1549C5F636C47E775749EA1CA', ...
            '4928F1EC24D46104B95EB3D3D82E8A0D025D82145A711B17A3E07DA366346D47'});
predFile = @(v, c) fullfile(cfg.paths.processedData, sprintf('v4test_%s_%s_prediction.mat', v, c));
checks = cell(0, 2);


%% 0. Integrità: entrambe le versioni congelate e i file del test

v4Manifest = readtable(fullfile(projectRoot, 'docs', 'v4_freeze_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
v3Manifest = readtable(fullfile(M, 'phase96_final_freeze_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
manifestOk = @(t) all(arrayfun(@(i) strcmp(sha256File(fullfile(projectRoot, t.path(i))), t.sha256(i)), 1:height(t)));
[s4, o4] = system(sprintf('git -C "%s" rev-list -n 1 v4-frozen', projectRoot));
[s3, o3] = system(sprintf('git -C "%s" rev-list -n 1 v3-final-frozen', projectRoot));
filesOk = true;
for c = conds
    filesOk = filesOk && strcmp(sha256File(fullfile(testDir, 'mri', c.t1)), c.h1) && ...
        strcmp(sha256File(fullfile(testDir, 'mri', c.t2)), c.h2) && strcmp(sha256File(c.gt), c.hgt);
end
checks = [checks; {
    "tags: v4-frozen -> 2525dde, v3-final-frozen -> 96b1612", s4 == 0 && s3 == 0 && ...
        startsWith(strtrim(string(o4)), "2525dde") && startsWith(strtrim(string(o3)), "96b1612")
    "v4 (14) and v3 (26) frozen hashes unchanged BEFORE", manifestOk(v4Manifest) && manifestOk(v3Manifest)
    "8 reserved MRI + GT files match the hashes recorded at download", filesOk
    }];
if any(~[checks{:, 2}])
    error('v4test:blocked', 'RESERVED TEST BLOCKED: integrity checks failed.');
end


%% 1. Predizioni v4 e v3 (NESSUN GT)

assert(~exist('labels', 'var'), 'GT must not be loaded before the predictions.');
cfgT = cfg;
pred = struct(); info = struct();
for c = conds
    cfgT.dataset.noisyMriFiles.(c.id).T1 = fullfile(testDir, 'mri', c.t1);
    cfgT.dataset.noisyMriFiles.(c.id).T2 = fullfile(testDir, 'mri', c.t2);
    rawT1 = loadBrainwebMri(cfgT, "T1", c.id);
    rawT2 = loadBrainwebMri(cfgT, "T2", c.id);
    [p4, d4] = generateV4Prediction(rawT1, rawT2, 5);
    [p3, d3] = generateFinalPrediction(rawT1, rawT2);
    pred.(c.id) = struct('v4', p4, 'v3', p3);
    info.(c.id) = struct('brainMask', d3.brainMask, 'S2', d4.S2, 'taLevel2', d4.taLevels(2), 'floor', d4.floorValue, ...
        'threshold', d4.threshold, 'muRef', d4.muWM, 'sigmaRef', d4.sigmaWM);
    for v = ["v4" "v3"]
        M_pred = pred.(c.id).(v); metadata = struct('test', "v4 reserved test", 'condition', c.id, 'version', v, ...
            'gtUsedForGeneration', false);
        save(predFile(v, c.id), 'M_pred', 'metadata');
    end
    fprintf('%s: TA2 %.4f, v4 floor %.4f (muRef %.4f, sigmaRef %.4f); voxels v4 %d, v3 %d\n', c.id, d4.taLevels(2), ...
        d4.floorValue, d4.muWM, d4.sigmaWM, nnz(p4), nnz(p3));
end
reloadOk = true;
for c = conds
    for v = ["v4" "v3"]
        s = load(predFile(v, c.id), 'M_pred');
        reloadOk = reloadOk && isequal(s.M_pred, pred.(c.id).(v));
    end
end
checks(end+1, :) = {"8 predictions (v4, v3 x 4 conditions) saved and re-read identical BEFORE any GT", ...
    reloadOk && ~exist('labels', 'var')};


%% 2. GT e metriche del protocollo

rows = cell(0, 21);
gtOk = true;
for c = conds
    cfgGt = cfg; cfgGt.dataset.groundTruthFile = c.gt;
    labels = loadBrainwebGroundTruth(cfgGt);
    gt = labels == 10;
    isNormal = startsWith(c.id, "normal");
    gtOk = gtOk && ternary(isNormal, max(labels(:)) <= 9 && nnz(gt) == 0, nnz(gt) > 0);
    for v = ["v4" "v3"]
        P = pred.(c.id).(v);
        cnt = computeVoxelConfusion(P, gt);
        comps = bwconncomp(P, 26);
        bm = info.(c.id).brainMask; s2 = info.(c.id).S2;
        if isNormal
            dice = NaN; iou = NaN; prec = NaN; rec = NaN; detected = NaN; falseComp = comps.NumObjects; gtLes = 0;
        else
            lw = computeLesionWiseMatches(P, gt, 26);
            dice = computeDiceFromConfusion(cnt); iou = computeIoUFromConfusion(cnt);
            prec = computePrecisionFromConfusion(cnt); rec = computeRecallFromConfusion(cnt);
            detected = lw.detectedGtLesionCount; falseComp = lw.falsePredictedComponentCount; gtLes = lw.gtComponentCount;
        end
        rows(end+1, :) = {c.id, v, ternary(v == "v4", "PRIMARY", "REFERENCE"), nnz(gt), nnz(P), cnt.TP, cnt.FP, cnt.FN, ...
            cnt.TN, dice, iou, prec, rec, computeSpecificityFromConfusion(cnt), cnt.FP, cnt.FP / nnz(bm), ...
            nnz(P & ~gt & s2) / nnz(s2), comps.NumObjects, falseComp, gtLes, detected}; %#ok<SAGROW>
    end
end
results = cell2table(rows, 'VariableNames', {'condition', 'version', 'role', 'gtLesionVoxels', 'predictedVoxels', ...
    'tpVoxels', 'fpVoxels', 'fnVoxels', 'tnVoxels', 'dice', 'iou', 'precision', 'recall', 'specificity', ...
    'fpVolumeMm3', 'fpFractionBrainMask', 'fpFractionS2', 'predictedComponents', 'falsePredictedComponents', ...
    'gtLesions', 'detectedGtLesions'});
writetable(results, fullfile(M, 'v4_reserved_test_results.csv'));
disp(results);
fprintf('Normal phantom (|GT| = 0): Dice / IoU / Precision / Recall are NaN by protocol (not reported).\n\n');
checks(end+1, :) = {"GT verified: normal phantom has no label 10 (max label <= 9); msles1 / msles3 lesion GT non-empty", gtOk};


%% 3. Manifest e integrità finale

files = strings(0, 1);
for c = conds
    files = [files; string(fullfile(testDir, 'mri', c.t1)); string(fullfile(testDir, 'mri', c.t2)); ...
        string(predFile("v4", c.id)); string(predFile("v3", c.id))]; %#ok<AGROW>
end
files = [files; string(fullfile(testDir, 'ground_truth', 'phantom_1.0mm_normal_crisp.rawb')); ...
    string(fullfile(testDir, 'REQUESTS.txt')); string(fullfile(M, 'v4_reserved_test_results.csv')); ...
    string([mfilename('fullpath') '.m'])];
manifest = table(rel(files), string(cellfun(@sha256File, cellstr(files), 'UniformOutput', false)), ...
    'VariableNames', {'path', 'sha256'});
writetable(manifest, fullfile(M, 'v4_reserved_test_manifest.csv'));
checks(end+1, :) = {"v4 / v3 frozen hashes unchanged AFTER; test manifest written (" + height(manifest) + " entries)", ...
    manifestOk(v4Manifest) && manifestOk(v3Manifest)};

for k = 1:size(checks, 1)
    fprintf('%-100s %s\n', checks{k, 1}, ternary(checks{k, 2}, 'ok', 'FAILED'));
end
if any(~[checks{:, 2}])
    error('v4test:checksFailed', 'Reserved test checks failed.');
end
fprintf('\nv4 RESERVED TEST: PASS (%d) - one-shot evaluation, no change to v4 or v3 allowed.\n', size(checks, 1));


function out = ternary(condition, a, b)
%TERNARY a se condition è vero, altrimenti b.
    if condition
        out = a;
    else
        out = b;
    end
end

function h = sha256File(f)
%SHA256FILE Impronta SHA-256 (esadecimale maiuscolo) tramite certutil di Windows.
    [status, out] = system(sprintf('certutil -hashfile "%s" SHA256', f));
    lines = erase(strtrim(splitlines(string(out))), " ");
    match = lines(strlength(lines) == 64 & ~cellfun(@isempty, regexp(cellstr(lines), '^[0-9a-fA-F]{64}$')));
    if status ~= 0 || numel(match) ~= 1
        error('v4test:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
