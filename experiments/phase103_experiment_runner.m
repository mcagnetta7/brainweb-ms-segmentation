%% Fase 103: runner unico della suite di valutazione (v3 di riferimento + v4 finale congelate)
% Automazione, NON un esperimento: nessun tuning, nessuna selezione, nessuna nuova evidenza.
% Un registro esplicito di 13 casi x 2 versioni congelate = 26 combinazioni, eseguite da UN
% ciclo generico. Ogni predizione è confrontata voxel per voxel con quella già salvata e i
% conteggi di confusione con i CSV autorevoli: la fase 103 RIPRODUCE l'evidenza esistente.
% Le predizioni restano in memoria (nessun file storico sovrascritto).
% Uso:  cd('C:\brainweb-ms-segmentation'); clear; close all;
%       run(fullfile('experiments', 'phase103_experiment_runner.m'))

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.evaluation);
M = cfg.paths.metrics;
P = cfg.paths.processedData;
rel = @(p) strrep(erase(string(p), string(projectRoot) + filesep), '\', '/');
logFile = fullfile(M, 'phase103_runner_verification.txt');
if isfile(logFile)
    delete(logFile);
end
diary(logFile);
cleanupDiary = onCleanup(@() diary('off'));
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));
expectedSize = [181 217 181];
checks = cell(0, 2);


%% 0. Registri delle versioni e dei casi (dichiarati prima di qualsiasi esecuzione)

versions = struct( ...
    'name',         {"v3", "v4"}, ...
    'configId',     {"D3_M1_G0", "V4_K5"}, ...
    'freezeTag',    {"v3-final-frozen", "v4-frozen"}, ...
    'freezeCommit', {"96b16124999a0d40f8df2c66b072fb3a38f10322", "2525ddefacb21d58150db5a4b986e36919e8de3b"}, ...
    'generator',    {@(t1, t2) generateFinalPrediction(t1, t2), @(t1, t2) generateV4Prediction(t1, t2, 5)});

rawDir = fileparts(cfg.dataset.mriFiles.T1);
c101 = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'phase101');
cRes = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'v4_reserved_test');
gt2 = cfg.dataset.groundTruthFile;
pre = @(n, m) fullfile(rawDir, sprintf('%s_ai_msles2_1mm_%s_rf0.raws', m, n));
caseList = {
 % caseId                  phantom   sourceType                 protocol          noise seed role                              sourcePhase  T1  T2  GT
  "pn0",                   "msles2", "BrainWeb pre-computed",   "SBD (AI)",        0,  NaN, "DEVELOPMENT_REFERENCE",          "Phase 96",  pre("pn0", "t1"), pre("pn0", "t2"), gt2
  "pn1",                   "msles2", "BrainWeb pre-computed",   "SBD (AI)",        1,  NaN, "PHASE97_HELDOUT_THEN_SEEN_V4",   "Phase 97",  pre("pn1", "t1"), pre("pn1", "t2"), gt2
  "pn3",                   "msles2", "BrainWeb pre-computed",   "SBD (AI)",        3,  NaN, "DEVELOPMENT_REFERENCE",          "Phase 96",  pre("pn3", "t1"), pre("pn3", "t2"), gt2
  "pn5",                   "msles2", "BrainWeb pre-computed",   "SBD (AI)",        5,  NaN, "PHASE97_HELDOUT_THEN_SEEN_V4",   "Phase 97",  pre("pn5", "t1"), pre("pn5", "t2"), gt2
  "pn7",                   "msles2", "BrainWeb pre-computed",   "SBD (AI)",        7,  NaN, "PHASE97_HELDOUT_THEN_SEEN_V4",   "Phase 97",  pre("pn7", "t1"), pre("pn7", "t2"), gt2
  "pn9",                   "msles2", "BrainWeb pre-computed",   "SBD (AI)",        9,  NaN, "PHASE97_HELDOUT_THEN_SEEN_V4",   "Phase 97",  pre("pn9", "t1"), pre("pn9", "t2"), gt2
  "custom_s1_msles1",      "msles1", "BrainWeb custom",         "AI, 0 % INU",     0,   1,  "SEEN_V4_DEVELOPMENT",            "Phase 101", fullfile(c101, 'mri', 'custom_msles1_t1_ai_1mm_n0_inu0_job1261017-050735s-2817767.raws'), fullfile(c101, 'mri', 'custom_msles1_t2_ai_1mm_n0_inu0_job1261017-050750s-2817854.raws'), fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles1_crisp.rawb')
  "custom_s1_msles2",      "msles2", "BrainWeb custom",         "AI, 0 % INU",     0,   1,  "SEEN_V4_DEVELOPMENT",            "Phase 101", fullfile(c101, 'mri', 'custom_msles2_t1_ai_1mm_n0_inu0_job1261017-050846s-2818122.raws'), fullfile(c101, 'mri', 'custom_msles2_t2_ai_1mm_n0_inu0_job1261017-050720s-2817689.raws'), gt2
  "custom_s1_msles3",      "msles3", "BrainWeb custom",         "AI, 0 % INU",     0,   1,  "SEEN_V4_DEVELOPMENT",            "Phase 101", fullfile(c101, 'mri', 'custom_msles3_t1_ai_1mm_n0_inu0_job1261017-050805s-2817935.raws'), fullfile(c101, 'mri', 'custom_msles3_t2_ai_1mm_n0_inu0_job1261017-050820s-2818018.raws'), fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles3_crisp.rawb')
  "reserved_normal_n0",    "normal", "BrainWeb custom",         "AI, 0 % INU",     0,   2,  "RESERVED_TEST_REPLAY",           "v4 reserved test", fullfile(cRes, 'mri', 'custom_normal_t1_ai_1mm_n0_inu0_seed2_job1261017-094107s-2844999.raws'), fullfile(cRes, 'mri', 'custom_normal_t2_ai_1mm_n0_inu0_seed2_job1261017-094123s-2845078.raws'), fullfile(cRes, 'ground_truth', 'phantom_1.0mm_normal_crisp.rawb')
  "reserved_normal_n3",    "normal", "BrainWeb custom",         "AI, 0 % INU",     3,   2,  "RESERVED_TEST_REPLAY",           "v4 reserved test", fullfile(cRes, 'mri', 'custom_normal_t1_ai_1mm_n3_inu0_seed2_job1261017-094138s-2845156.raws'), fullfile(cRes, 'mri', 'custom_normal_t2_ai_1mm_n3_inu0_seed2_job1261017-094153s-2845233.raws'), fullfile(cRes, 'ground_truth', 'phantom_1.0mm_normal_crisp.rawb')
  "reserved_msles1_n3",    "msles1", "BrainWeb custom",         "AI, 0 % INU",     3,   2,  "RESERVED_TEST_REPLAY",           "v4 reserved test", fullfile(cRes, 'mri', 'custom_msles1_t1_ai_1mm_n3_inu0_seed2_job1261017-094208s-2845311.raws'), fullfile(cRes, 'mri', 'custom_msles1_t2_ai_1mm_n3_inu0_seed2_job1261017-094235s-2845389.raws'), fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles1_crisp.rawb')
  "reserved_msles3_n3",    "msles3", "BrainWeb custom",         "AI, 0 % INU",     3,   2,  "RESERVED_TEST_REPLAY",           "v4 reserved test", fullfile(cRes, 'mri', 'custom_msles3_t1_ai_1mm_n3_inu0_seed2_job1261017-094301s-2845466.raws'), fullfile(cRes, 'mri', 'custom_msles3_t2_ai_1mm_n3_inu0_seed2_job1261017-094329s-2845552.raws'), fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles3_crisp.rawb')
  };
cases = cell2struct(caseList, {'caseId', 'phantom', 'sourceType', 'protocol', 'noise', 'seed', 'role', 'sourcePhase', ...
    't1', 't2', 'gt'}, 2);

% Riferimenti storici: predizioni salvate e conteggi autorevoli (solo per la verifica di riproduzione)
legacy = struct('custom_s1_msles1', "msles1", 'custom_s1_msles2', "msles2", 'custom_s1_msles3', "msles3", ...
    'reserved_normal_n0', "normal_n0", 'reserved_normal_n3', "normal_n3", 'reserved_msles1_n3', "msles1_n3", ...
    'reserved_msles3_n3', "msles3_n3");
refPred = @(v, c) referencePredictionFile(P, v, c, legacy);
refCounts = loadReferenceCounts(M, projectRoot, legacy);


%% 1. Integrità PRIMA di caricare qualsiasi MRI

manifestFiles = {fullfile(M, 'phase96_final_freeze_manifest.csv'), 26; fullfile(projectRoot, 'docs', 'v4_freeze_manifest.csv'), 14; ...
    fullfile(M, 'phase97_result_manifest.csv'), 27; fullfile(M, 'phase98_final_results_inventory.csv'), 32; ...
    fullfile(M, 'phase101_result_manifest.csv'), 19; fullfile(M, 'v4_reserved_test_manifest.csv'), 20};
[before, knownHashes] = integrityState(projectRoot, M, manifestFiles);
tagOk = true;
for v = versions
    [s, o] = system(sprintf('git -C "%s" rev-list -n 1 %s', projectRoot, v.freezeTag));
    tagOk = tagOk && s == 0 && strtrim(string(o)) == v.freezeCommit;
end
% hash dei dati grezzi pn0 / pn3 (DOWNLOAD_INFO.txt); gli altri sono nei manifest delle fasi 97 / 101 / test riservato
knownHashes(char(rel(pre("pn0", "t1")))) = "C94E3BB8D0DF62C4D52B5A7EAFF0673F73E828A345D2FF8EE3FEEE8BD3A91FD0";
knownHashes(char(rel(pre("pn0", "t2")))) = "113EBC5E1BA1E57FE4B5F6FD2686F1B869023615B54191DD31F4EEE6A1362071";
knownHashes(char(rel(pre("pn3", "t1")))) = "AC7C6136D99F83FC6BCBF44111D2541996A146E946433F8AF2F39E95A9D8B8FE";
knownHashes(char(rel(pre("pn3", "t2")))) = "52AF70628F1211CCEF850F61E715D4D743102EAF29AD1337CDEB61BBCCFE0F7E";
statusText = fileread(fullfile(projectRoot, 'docs', 'PROJECT_STATUS.md'));
checks = [checks; {
    "1-2 Phase 101 COMPLETE; Phase 102 recorded skipped", contains(statusText, 'lesion-load robustness: COMPLETE') && ...
        contains(statusText, 'Phase 102') && contains(statusText, 'SKIPPED')
    "5-6 tags v3-final-frozen -> 96b1612 and v4-frozen -> 2525dde", tagOk
    "7-8, 10-14 frozen v3 (26) / v4 (14) hashes and Phase-97 / 98 / 101 / reserved manifests valid BEFORE", before.ok
    "9-12 registry: 13 unique cases (6 pre-computed, 3 custom seed 1, 4 reserved seed 2), explicit roles", ...
        numel(cases) == 13 && numel(unique([cases.caseId])) == 13 && nnz([cases.sourceType] == "BrainWeb pre-computed") == 6 && ...
        nnz([cases.role] == "SEEN_V4_DEVELOPMENT") == 3 && nnz([cases.role] == "RESERVED_TEST_REPLAY") == 4 && all(strlength([cases.role]) > 0)
    "18-20 versions registry: exactly v3 (D3_M1_G0) and v4 (k = 5 fixed in the generator handle)", numel(versions) == 2 && ...
        isequal([versions.name], ["v3" "v4"]) && versions(1).configId == "D3_M1_G0"
    }];
inputOk = true;
for c = cases.'
    for f = {c.t1, c.t2, c.gt}
        key = char(rel(f{1}));
        inputOk = inputOk && isfile(f{1}) && isKey(knownHashes, key) && strcmp(sha256File(f{1}), char(knownHashes(key)));
    end
end
checks(end+1, :) = {"13-16 all 39 input files exist and match recorded SHA-256 (no download, no new simulation)", inputOk};
mustPass(checks, 'PHASE 103 TECHNICALLY BLOCKED — FROZEN SOURCE OR INPUT INTEGRITY FAILURE');


%% 2. Ciclo generico: 13 casi x 2 versioni

rows = cell(0, 41);
reproduced = 0; references = 0; discrepancies = strings(0, 1); sameByVersion = struct();
for c = cases.'
    cfgCase = cfg;
    cfgCase.dataset.noisyMriFiles.case103.T1 = c.t1;
    cfgCase.dataset.noisyMriFiles.case103.T2 = c.t2;
    rawT1 = loadBrainwebMri(cfgCase, "T1", "case103");
    rawT2 = loadBrainwebMri(cfgCase, "T2", "case103");
    if ~isequal(size(rawT1), size(rawT2), expectedSize) || max([rawT1(:); rawT2(:)]) > 4095
        error('phase103:input', 'PHASE 103 TECHNICALLY BLOCKED: invalid input geometry / range for %s.', c.caseId);
    end
    out = struct();
    for v = versions
        [Mp, d] = v.generator(rawT1, rawT2);          % nessun GT passato al generatore
        if ~islogical(Mp) || ~isequal(size(Mp), expectedSize)
            error('phase103:output', 'PHASE 103 TECHNICALLY BLOCKED: invalid %s output for %s.', v.name, c.caseId);
        end
        out.(v.name) = struct('M', Mp, 'd', d);
    end
    S2 = out.v4.d.S2;                                % supporto restituito dal generatore congelato (identico per v3 e v4)
    brainMask = out.v3.d.brainMask;

    % GT (solo valutazione, dopo le predizioni del caso)
    cfgGt = cfg; cfgGt.dataset.groundTruthFile = c.gt;
    labels = loadBrainwebGroundTruth(cfgGt);
    gt = labels == 10;
    if c.phantom == "normal"
        if any(gt(:)) || max(labels(:)) > 9
            error('phase103:gt', 'PHASE 103 TECHNICALLY BLOCKED: normal phantom GT contains label 10.');
        end
    elseif ~any(gt(:))
        error('phase103:gt', 'PHASE 103 TECHNICALLY BLOCKED: empty lesion GT for %s.', c.caseId);
    end

    for v = versions
        Mp = out.(v.name).M; d = out.(v.name).d;
        insideS2 = ~any(Mp & ~S2, 'all');
        cnt = computeVoxelConfusion(Mp, gt);
        comps = bwconncomp(Mp, 26);
        if any(gt(:))
            lw = computeLesionWiseMatches(Mp, gt, 26);
            m = [computeDiceFromConfusion(cnt), computeIoUFromConfusion(cnt), computePrecisionFromConfusion(cnt), ...
                computeRecallFromConfusion(cnt)];
            volErr = computeVolumeErrorPercent(nnz(gt), nnz(Mp));
            ve = volErr.volumeErrorPercent;
            lesionInfo = [lw.gtComponentCount, lw.detectedGtLesionCount, lw.missedGtLesionCount, ...
                lw.matchedPredictedComponentCount, lw.falsePredictedComponentCount];
        else
            m = NaN(1, 4); ve = NaN;                   % |GT| = 0: protocollo preregistrato del test riservato
            lesionInfo = [0, NaN, NaN, 0, comps.NumObjects];
        end
        if v.name == "v4"
            thr = [d.taLevels(2), d.muWM, d.sigmaWM, d.floorValue, d.threshold, double(d.floorActive)];
        else
            thr = [d.t2ThresholdsNormalized(2), NaN, NaN, NaN, d.t2ThresholdsNormalized(2), 0];
        end
        rows(end+1, :) = {c.caseId, c.phantom, c.role, c.sourceType, c.protocol, c.noise, c.seed, c.sourcePhase, ...
            v.name, v.configId, v.freezeTag, nnz(gt), nnz(Mp), cnt.TP, cnt.FP, cnt.FN, cnt.TN, m(1), m(2), m(3), m(4), ...
            computeSpecificityFromConfusion(cnt), ve, comps.NumObjects, lesionInfo(5), lesionInfo(1), lesionInfo(2), ...
            lesionInfo(3), nnz(brainMask), nnz(S2), nnz(gt & S2), ternary(any(gt(:)), nnz(gt & S2) / max(nnz(gt), 1), NaN), ...
            cnt.FP / nnz(brainMask), nnz(Mp & ~gt & S2) / nnz(S2), thr(1), thr(2), thr(3), thr(4), ...
            thr(5), logical(thr(6)), insideS2}; %#ok<SAGROW>

        % Riproduzione dell'evidenza esistente: predizione salvata (voxel) e conteggi autorevoli
        saved = load(refPred(v.name, c.caseId), 'M_pred');
        ref = refCounts.(v.name + "_" + c.caseId);
        same = isequal(saved.M_pred, Mp) && cnt.TP == ref(1) && cnt.FP == ref(2) && cnt.FN == ref(3);
        references = references + 1; reproduced = reproduced + same;
        sameByVersion.(v.name) = same;
        if ~same
            discrepancies(end+1) = v.name + " " + c.caseId; %#ok<SAGROW>
        end
    end
    fprintf('%-20s v3 %6d voxels | v4 %6d voxels | reproduced v3 %d, v4 %d\n', c.caseId, nnz(out.v3.M), nnz(out.v4.M), ...
        sameByVersion.v3, sameByVersion.v4);
    if ~isempty(discrepancies)
        error('phase103:reproduction', 'PHASE 103 TECHNICALLY BLOCKED: not reproduced: %s', strjoin(discrepancies, ', '));
    end
end
metrics = cell2table(rows, 'VariableNames', {'caseId', 'phantom', 'caseRole', 'sourceType', 'simulationProtocol', ...
    'noiseLevel', 'seed', 'historicalSourcePhase', 'version', 'configId', 'freezeTag', 'gtLesionVoxels', 'predictedVoxels', ...
    'TP', 'FP', 'FN', 'TN', 'dice', 'iou', 'precision', 'recall', 'specificity', 'volumeErrorPercent', ...
    'predictedComponents', 'falsePredictedComponents', 'gtLesions', 'detectedGtLesions', 'missedGtLesions', ...
    'brainMaskVoxels', 'S2Voxels', 'gtVoxelsInsideS2', 'fractionGtInsideS2', 'fpFractionBrainMask', 'fpFractionS2', ...
    'TA2', 'muRef', 'sigmaRef', 'floorValue', 'effectiveThreshold', 'floorActive', 'predictionInsideS2'});
writetable(metrics, fullfile(M, 'phase103_runner_metrics.csv'));


%% 3. Riepilogo per caso (descrittivo, nessuna classifica)

summaryRows = cell(numel(cases), 16);
for i = 1:numel(cases)
    a = metrics(metrics.caseId == cases(i).caseId & metrics.version == "v3", :);
    b = metrics(metrics.caseId == cases(i).caseId & metrics.version == "v4", :);
    summaryRows(i, :) = {cases(i).caseId, cases(i).role, a.gtLesionVoxels, a.dice, b.dice, b.dice - a.dice, ...
        a.precision, b.precision, a.recall, b.recall, a.FP, b.FP, a.FP - b.FP, a.predictedVoxels, b.predictedVoxels, ...
        b.detectedGtLesions - a.detectedGtLesions};
end
summary = cell2table(summaryRows, 'VariableNames', {'caseId', 'role', 'gtLesionVoxels', 'diceV3', 'diceV4', ...
    'deltaDiceV4minusV3', 'precisionV3', 'precisionV4', 'recallV3', 'recallV4', 'fpV3', 'fpV4', 'fpReductionV3minusV4', ...
    'predictedVoxelsV3', 'predictedVoxelsV4', 'deltaDetectedLesionsV4minusV3'});
writetable(summary, fullfile(M, 'phase103_case_summary.csv'));
disp(summary);


%% 4. Controlli finali, manifest

after = integrityState(projectRoot, M, manifestFiles);
code = strjoin(regexprep(splitlines(string(fileread([mfilename('fullpath') '.m']))), '%.*$', ''), newline);
forbidden = {['ti' 'c;'], ['to' 'c;'], ['time' 'it('], ['figu' 're('], ['exportgra' 'phics('], ['sa' 've('], ...
    ['generateV5' 'Predictions('], ['generateExp05' '9Prediction('], ['generateV4Prediction(t1, t2, ' '4'], ['EXP-0' '62']};
checks = [checks; {
    "22-26, 33-34 generic loop over the registry; frozen entry points only; automatic voxel and lesion-wise metrics", height(metrics) == 26
    "27-28 all 26 predictions logical, 181x217x181, inside the generator's S2", all(metrics.predictionInsideS2)
    "29-32 GT handling: normal phantoms empty (overlap metrics NaN by protocol), lesion GT non-empty", ...
        all(isnan(metrics.dice(metrics.phantom == "normal"))) && all(~isnan(metrics.dice(metrics.phantom ~= "normal")))
    "36-38 master table 26 rows (13 x 2); case summary 13 rows", height(metrics) == 26 && height(summary) == 13
    "41-45 all 26 combinations reproduce the saved prediction voxel by voxel and the authoritative TP / FP / FN", ...
        reproduced == 26 && references == 26
    "21, 24, 46-50 no tunable k, no performance branch, no timing, no figure, no file saved besides tables, no new EXP", ...
        ~any(cellfun(@(f) contains(code, f), forbidden))
    "39-40, 54-57 frozen hashes and historical artifacts unchanged AFTER; config.m unchanged", after.ok && ...
        isequal(before.hashes, after.hashes) && isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];
for k = 1:size(checks, 1)
    fprintf('%-100s %s\n', checks{k, 1}, ternary(checks{k, 2}, 'ok', 'FAILED'));
end
fprintf('\nCases %d, versions %d, combinations %d; reproduced exactly %d / %d.\n', numel(cases), numel(versions), ...
    height(metrics), reproduced, references);
fprintf('Outputs: %s, %s, %s\n', rel(fullfile(M, 'phase103_runner_metrics.csv')), rel(fullfile(M, 'phase103_case_summary.csv')), rel(logFile));
if any(~[checks{:, 2}])
    error('phase103:checksFailed', 'PHASE 103 TECHNICALLY BLOCKED: checks failed.');
end
fprintf('\nPHASE 103 RUNNER: PASS (%d)\n', size(checks, 1));
diary('off');
outputs = [string(fullfile(projectRoot, 'experiments', 'phase103_experiment_runner.m')); ...
    string(fullfile(M, 'phase103_runner_metrics.csv')); string(fullfile(M, 'phase103_case_summary.csv')); string(logFile)];
writetable(table(rel(outputs), string(cellfun(@sha256File, cellstr(outputs), 'UniformOutput', false)), ...
    'VariableNames', {'path', 'sha256'}), fullfile(M, 'phase103_runner_manifest.csv'));


function f = referencePredictionFile(P, v, caseId, legacy)
%REFERENCEPREDICTIONFILE Predizione già salvata dalla fase che ha prodotto quel risultato.
    c = string(caseId);
    if isfield(legacy, c)
        old = legacy.(c);
    else
        old = c;
    end
    if startsWith(c, "reserved_")
        f = fullfile(P, sprintf('v4test_%s_%s_prediction.mat', v, old));
    elseif v == "v3" && any(c == ["pn0" "pn3"])
        f = fullfile(P, sprintf('phase95_exp059_v3_%s_selected_prediction.mat', c));
    elseif v == "v3" && startsWith(c, "pn")
        f = fullfile(P, sprintf('phase97_v3_%s_prediction.mat', c));
    elseif v == "v3"
        f = fullfile(P, sprintf('phase101_v3_%s_prediction.mat', old));
    elseif any(c == ["pn1" "pn5" "pn7" "pn9"])
        f = fullfile(P, sprintf('v4_secondary_%s_prediction.mat', c));
    else
        f = fullfile(P, 'exp060_candidates', sprintf('exp060_k5_%s.mat', old));
    end
end

function refs = loadReferenceCounts(M, root, legacy)
%LOADREFERENCECOUNTS TP / FP / FN autorevoli dai CSV delle fasi che hanno prodotto ogni risultato.
    refs = struct();
    dev = readtable(fullfile(root, 'docs', 'phase96_final_development_reference.csv'), 'TextType', 'string');
    for r = 1:height(dev)
        refs.("v3_" + dev.condition(r)) = [dev.tpVoxels(r), dev.fpVoxels(r), dev.fnVoxels(r)];
    end
    t97 = readtable(fullfile(M, 'phase97_v3_heldout_metrics.csv'), 'TextType', 'string');
    for r = 1:height(t97)
        refs.("v3_" + t97.condition(r)) = [t97.tpVoxels(r), t97.fpVoxels(r), t97.fnVoxels(r)];
    end
    t101 = readtable(fullfile(M, 'phase101_lesion_load_robustness.csv'), 'TextType', 'string');
    g60 = readtable(fullfile(M, 'exp060_grid_results.csv'), 'TextType', 'string');
    g60 = g60(g60.configId == "k5", :);
    sec = readtable(fullfile(M, 'v4_secondary_heldout_comparison.csv'), 'TextType', 'string');
    res = readtable(fullfile(M, 'v4_reserved_test_results.csv'), 'TextType', 'string');
    for c = string(fieldnames(legacy)).'
        old = legacy.(c);
        if startsWith(c, "reserved_")
            for v = ["v3" "v4"]
                x = res(res.condition == old & res.version == v, :);
                refs.(v + "_" + c) = [x.tpVoxels, x.fpVoxels, x.fnVoxels];
            end
        else
            x = t101(t101.phantom == old, :);
            refs.("v3_" + c) = [x.tpVoxels, x.fpVoxels, x.fnVoxels];
            x = g60(g60.condition == old, :);
            refs.("v4_" + c) = [x.tpVoxels, x.fpVoxels, x.fnVoxels];
        end
    end
    for n = ["pn0" "pn3"]
        x = g60(g60.condition == n, :);
        refs.("v4_" + n) = [x.tpVoxels, x.fpVoxels, x.fnVoxels];
    end
    for n = ["pn1" "pn5" "pn7" "pn9"]
        x = sec(sec.condition == n, :);
        tp = x.predictedV4 - x.fpV4;
        refs.("v4_" + n) = [tp, x.fpV4, 3512 - tp];
    end
end

function [s, known] = integrityState(root, M, manifestFiles)
%INTEGRITYSTATE Verifica tutti i manifest; restituisce anche la mappa percorso -> SHA-256 nota.
    s.ok = true; s.hashes = strings(0, 1);
    known = containers.Map('KeyType', 'char', 'ValueType', 'any');
    for i = 1:size(manifestFiles, 1)
        t = readtable(manifestFiles{i, 1}, 'TextType', 'string', 'Delimiter', ',');
        h = string(arrayfun(@(p) sha256File(fullfile(root, p)), t.path, 'UniformOutput', false));
        s.ok = s.ok && height(t) == manifestFiles{i, 2} && all(h == t.sha256);
        s.hashes = [s.hashes; h; string(sha256File(manifestFiles{i, 1}))];
        for r = 1:height(t)
            known(char(t.path(r))) = upper(t.sha256(r));
        end
    end
    for f = ["phase99_ablation_summary.csv" "phase99_ablation_pairwise.csv" "phase99_development_trajectory.csv"]
        s.hashes = [s.hashes; string(sha256File(fullfile(M, f)))];
    end
end

function out = ternary(condition, a, b)
%TERNARY a se condition è vero, altrimenti b.
    if condition
        out = a;
    else
        out = b;
    end
end

function mustPass(checks, message)
%MUSTPASS Interrompe il runner se un controllo preliminare fallisce.
    failed = find(~[checks{:, 2}]);
    for k = failed
        fprintf('%-100s FAILED\n', checks{k, 1});
    end
    if ~isempty(failed)
        error('phase103:technicallyBlocked', '%s', message);
    end
end

function h = sha256File(f)
%SHA256FILE Impronta SHA-256 (esadecimale maiuscolo) tramite certutil di Windows.
    [status, out] = system(sprintf('certutil -hashfile "%s" SHA256', f));
    lines = erase(strtrim(splitlines(string(out))), " ");
    match = lines(strlength(lines) == 64 & ~cellfun(@isempty, regexp(cellstr(lines), '^[0-9a-fA-F]{64}$')));
    if status ~= 0 || numel(match) ~= 1
        error('phase103:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
