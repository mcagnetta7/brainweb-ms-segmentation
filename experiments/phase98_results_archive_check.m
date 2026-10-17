%% Fase 98: archivio e verifica dei risultati grezzi del test finale (fase 97)
% Solo verifica e indicizzazione degli artefatti GIÀ salvati nella fase 97:
% nessuna segmentazione, nessun caricamento di MRI o GT, nessuna metrica
% ricalcolata sul GT, nessun file autorevole modificato. Controlli:
%   0. congelamento della fase 96 (tag, manifest) e stato della fase 97
%   1. manifest dei risultati della fase 97 (percorsi, unicità, SHA-256)
%   2. hash dei file MRI held-out contro DOWNLOAD_INFO.txt
%   3. le 12 predizioni (M_pred, tipo, dimensioni, metadati)
%   4. coerenza algebrica delle tabelle (conteggi -> metriche) e tra tabelle e maschere
%   5. inventario della fase 98 (indice dei file esistenti, non una copia)
% Il tempo di esecuzione non è misurato qui: rimandato alla fase 102.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
rel = @(p) strrep(erase(string(p), string(projectRoot) + filesep), '\', '/');
abs_ = @(p) fullfile(projectRoot, p);
consoleLog = fullfile(cfg.paths.metrics, 'phase98_verification_console.txt');
if isfile(consoleLog)
    delete(consoleLog);
end
diary(consoleLog);
cleanupDiary = onCleanup(@() diary('off'));

heldOut = ["pn1" "pn5" "pn7" "pn9"];
versionsAll = ["v3" "v1" "v2"];
configOf = struct('v3', "D3_M1_G0", 'v1', "S2_TA_M2_G1", 'v2', "F5_R0");
expectedSize = [181 217 181];
totalVoxels = prod(expectedSize);
gtVoxels = 3512;
freezeCommit = "96b16124999a0d40f8df2c66b072fb3a38f10322";
manifest96File = fullfile(cfg.paths.metrics, 'phase96_final_freeze_manifest.csv');
manifest97File = fullfile(cfg.paths.metrics, 'phase97_result_manifest.csv');
primaryCsv = fullfile(cfg.paths.metrics, 'phase97_v3_heldout_metrics.csv');
comparisonCsv = fullfile(cfg.paths.metrics, 'phase97_frozen_versions_comparison.csv');
lesionCsv = fullfile(cfg.paths.metrics, 'phase97_v3_lesionwise_diagnostics.csv');
inventoryCsv = fullfile(cfg.paths.metrics, 'phase98_final_results_inventory.csv');
downloadInfo = fullfile(fileparts(fileparts(cfg.dataset.mriFiles.T1)), 'DOWNLOAD_INFO.txt');
predFile = @(v, n) fullfile(cfg.paths.processedData, sprintf('phase97_%s_%s_prediction.mat', v, n));
rawFile = @(m, n) fullfile(fileparts(cfg.dataset.mriFiles.T1), sprintf('%s_ai_msles2_1mm_%s_rf0.raws', m, n));
closeTo = @(a, b) abs(a - b) <= 1e-12 * max(1, abs(b));
checks = cell(0, 2);


%% 0. Congelamento della fase 96 e stato della fase 97

[gitStatus, gitOut] = system(sprintf('git -C "%s" rev-list -n 1 v3-final-frozen', projectRoot));
manifest96HashAtStart = sha256File(manifest96File);
manifest96 = readtable(manifest96File, 'TextType', 'string', 'Delimiter', ',');
manifest96Ok = height(manifest96) == 26 && all(arrayfun(@(i) strcmp(sha256File(abs_(manifest96.path(i))), ...
    manifest96.sha256(i)), 1:height(manifest96)));
statusText = fileread(fullfile(projectRoot, 'docs', 'PROJECT_STATUS.md'));
finalConfig = finalSegmentationConfig();
checks = [checks; {
    "1 Phase 97 recorded COMPLETE in PROJECT_STATUS", contains(statusText, 'held-out final test: COMPLETE')
    "2 primary remains v3 / D3_M1_G0",               finalConfig.version == "v3" && finalConfig.sourceConfiguration == "D3_M1_G0"
    "3 tag v3-final-frozen still resolves to 96b1612", gitStatus == 0 && strtrim(string(gitOut)) == freezeCommit
    "4-5 Phase-96 manifest exists, 26 frozen hashes still match", manifest96Ok
    }];


%% 1. Manifest dei risultati della fase 97

manifest97 = readtable(manifest97File, 'TextType', 'string', 'Delimiter', ',');
paths97 = manifest97.path;
exists97 = arrayfun(@(p) isfile(abs_(p)), paths97);
hashes97 = strings(height(manifest97), 1);
hashes97(exists97) = string(arrayfun(@(p) sha256File(abs_(p)), paths97(exists97), 'UniformOutput', false));
isPrediction = contains(paths97, "data/processed/phase97_") & endsWith(paths97, "_prediction.mat");
checks = [checks; {
    "6-7 Phase-97 manifest exists, every listed path exists", all(exists97)
    "8 every Phase-97 SHA-256 is valid hex and matches the current file", ...
        all(~cellfun(@isempty, regexp(cellstr(manifest97.sha256), '^[0-9A-F]{64}$'))) && all(hashes97 == manifest97.sha256)
    "9 manifest paths are unique",                    numel(unique(paths97)) == numel(paths97)
    "10 manifest = 8 raw MRI + 12 predictions + 3 CSV + 3 figures + 1 script = 27 artifacts", height(manifest97) == 27 && ...
        nnz(endsWith(paths97, ".raws")) == 8 && nnz(isPrediction) == 12 && nnz(endsWith(paths97, ".csv")) == 3 && ...
        nnz(endsWith(paths97, ".png")) == 3 && nnz(endsWith(paths97, ".m")) == 1
    }];


%% 2. MRI held-out: hash contro il registro del download

infoText = fileread(downloadInfo);
rawOk = true;
for n = heldOut
    for m = ["t1" "t2"]
        name = sprintf('%s_ai_msles2_1mm_%s_rf0.raws', m, n);
        token = regexp(infoText, [regexptranslate('escape', name) '\s+\d+%\s+14218274\s+([0-9a-f]{64})'], 'tokens', 'once');
        info = dir(rawFile(m, n));
        rawOk = rawOk && ~isempty(token) && strcmpi(sha256File(rawFile(m, n)), token{1}) && info.bytes == 14218274;
    end
end
checks(end+1, :) = {"43-44 8 held-out raw MRI: SHA-256 = download record, 14,218,274 bytes, unchanged", rawOk};


%% 3. Le 12 predizioni (solo lettura)

predRows = cell(0, 6);
predOk = true;
for v = versionsAll
    for n = heldOut
        f = predFile(v, n);
        s = load(f);
        ok = isfield(s, 'M_pred') && islogical(s.M_pred) && isequal(size(s.M_pred), expectedSize) && ...
            s.condition == n && s.version == v && s.configId == configOf.(v) && ...
            s.metadata.heldOutCondition && ~s.metadata.gtUsedForGeneration && s.metadata.predictedVoxels == nnz(s.M_pred);
        predOk = predOk && ok;
        predRows(end+1, :) = {v, n, string(s.configId), nnz(s.M_pred), ok, rel(f)}; %#ok<SAGROW>
    end
end
predTable = cell2table(predRows, 'VariableNames', {'version', 'condition', 'configId', 'voxels', 'valid', 'path'});
disp(predTable(:, 1:5));
checks = [checks; {
    "11-14 exactly 12 held-out predictions: 4 v3, 4 v1, 4 v2", height(predTable) == 12 && ...
        all(arrayfun(@(v) nnz(predTable.version == v), versionsAll) == 4)
    "15-21 every M_pred logical 181x217x181; condition / version / configId / metadata consistent", predOk
    }];


%% 4. Coerenza delle tabelle (conteggi salvati -> metriche salvate; tabelle <-> maschere)

primary = readtable(primaryCsv, 'TextType', 'string');
comparison = readtable(comparisonCsv, 'TextType', 'string');
lesion = readtable(lesionCsv, 'TextType', 'string');
needed = ["dice" "iou" "precision" "recall" "specificity" "tpVoxels" "fpVoxels" "fnVoxels" "tnVoxels" ...
    "predictedVoxels" "volumeErrorPercent"];
algebra = @(t) all(t.tpVoxels + t.fpVoxels == t.predictedVoxels) && all(t.tpVoxels + t.fnVoxels == gtVoxels) && ...
    all(t.tpVoxels + t.fpVoxels + t.fnVoxels + t.tnVoxels == totalVoxels) && ...
    all(closeTo(t.dice, 2 * t.tpVoxels ./ (2 * t.tpVoxels + t.fpVoxels + t.fnVoxels))) && ...
    all(closeTo(t.iou, t.tpVoxels ./ (t.tpVoxels + t.fpVoxels + t.fnVoxels))) && ...
    all(closeTo(t.precision, t.tpVoxels ./ (t.tpVoxels + t.fpVoxels))) && ...
    all(closeTo(t.recall, t.tpVoxels ./ (t.tpVoxels + t.fnVoxels))) && ...
    all(closeTo(t.specificity, t.tnVoxels ./ (t.tnVoxels + t.fpVoxels))) && ...
    all(closeTo(t.volumeErrorPercent, abs(t.predictedVoxels - gtVoxels) / gtVoxels * 100));
maskVoxels = @(v, n) predTable.voxels(predTable.version == v & predTable.condition == n);
comparisonMasksOk = all(arrayfun(@(i) comparison.predictedVoxels(i) == maskVoxels(comparison.version(i), ...
    comparison.condition(i)), 1:height(comparison)));
expectedRoles = (comparison.version == "v3" & comparison.role == "PRIMARY HELD-OUT") | ...
    (comparison.version ~= "v3" & comparison.role == "SECONDARY LOCKED COMPARISON");
checks = [checks; {
    "22-24 primary CSV: 4 rows pn1 / pn5 / pn7 / pn9, HELD-OUT PRIMARY TEST, v3, D3_M1_G0", height(primary) == 4 && ...
        isequal(primary.condition.', heldOut) && all(primary.role == "HELD-OUT PRIMARY TEST") && ...
        all(primary.version == "v3") && all(primary.configId == "D3_M1_G0")
    "25 required voxel-wise metric columns present", all(ismember(needed, string(primary.Properties.VariableNames)))
    "26-33 primary: TP+FP = predicted, TP+FN = 3512, total = 181*217*181, stored metrics consistent", algebra(primary)
    "primary predicted voxels = voxels of the saved v3 masks", all(arrayfun(@(i) primary.predictedVoxels(i) == ...
        maskVoxels("v3", primary.condition(i)), 1:4))
    "34-35 comparison CSV: 12 rows = 4 conditions x {v1, v2, v3}", height(comparison) == 12 && ...
        all(arrayfun(@(n) isequal(sort(comparison.version(comparison.condition == n)).', ["v1" "v2" "v3"]), heldOut))
    "36-37 v3 marked PRIMARY HELD-OUT, v1 / v2 SECONDARY LOCKED COMPARISON", all(expectedRoles)
    "comparison: stored metrics consistent with counts; counts = saved masks", algebra(comparison) && comparisonMasksOk
    "comparison v3 rows identical to the primary table", isequal(comparison.dice(comparison.version == "v3"), primary.dice) && ...
        isequal(comparison.tpVoxels(comparison.version == "v3"), primary.tpVoxels)
    "38-39 lesion-wise CSV: 4 rows pn1 / pn5 / pn7 / pn9, required columns", height(lesion) == 4 && ...
        isequal(lesion.condition.', heldOut) && all(ismember(["gtLesionCount" "detectedGtLesions" "missedGtLesions" ...
        "predictedComponents" "falsePredictedComponents" "overlapRelations" "overlapVoxels" "smallDetected" "smallMissed" ...
        "largeDetected" "largeMissed" "gtVoxelsInsideS2" "recallCeilingS2"], string(lesion.Properties.VariableNames)))
    "40-42 detected + missed = 59; SMALL = 31; LARGE = 28 (Phase-94 grouping)", ...
        all(lesion.detectedGtLesions + lesion.missedGtLesions == 59) && all(lesion.gtLesionCount == 59) && ...
        all(lesion.smallDetected + lesion.smallMissed == 31) && all(lesion.largeDetected + lesion.largeMissed == 28)
    "lesion-wise: overlap voxels = primary TP; recall ceiling = GT voxels in S2 / 3512", ...
        isequal(lesion.overlapVoxels, primary.tpVoxels) && all(closeTo(lesion.recallCeilingS2, lesion.gtVoxelsInsideS2 / gtVoxels)) && ...
        isequal(lesion.gtVoxelsInsideS2, primary.gtVoxelsInsideS2)
    }];


%% 5. Inventario della fase 98 (indice dei file esistenti)

roleOf = @(v) ternary(v == "v3", "PRIMARY HELD-OUT PREDICTION", "SECONDARY LOCKED PREDICTION");
inv = cell(0, 8);
for n = heldOut
    for m = ["t1" "t2"]
        inv(end+1, :) = {"raw_input", "held-out MRI input (immutable)", n, upper(m), rel(rawFile(m, n)), "97", ...
            "", "official BrainWeb msles2 1 mm rf0; hash = DOWNLOAD_INFO.txt"}; %#ok<SAGROW>
    end
end
for v = versionsAll
    for n = heldOut
        inv(end+1, :) = {"prediction", roleOf(v), n, v, rel(predFile(v, n)), "97", ...
            ternary(v == "v3", "PRIMARY HELD-OUT PREDICTIONS", ""), configOf.(v)}; %#ok<SAGROW>
    end
end
inv = [inv; {
    "metrics", "primary held-out metrics", "pn1;pn5;pn7;pn9", "v3", rel(primaryCsv), "97", "PRIMARY FINAL TEST METRICS", "full precision"
    "metrics", "frozen-version comparison", "pn1;pn5;pn7;pn9", "v1;v2;v3", rel(comparisonCsv), "97", "SECONDARY VERSION COMPARISON", "not a selection"
    "diagnostics", "lesion-wise diagnostics", "pn1;pn5;pn7;pn9", "v3", rel(lesionCsv), "97", "LESION-WISE DIAGNOSTICS", "detected = at least one shared voxel"
    "figure", "noise curves", "pn0;pn1;pn3;pn5;pn7;pn9", "v3", "results/figures/phase97_v3_noise_curves.png", "97", "", "pn0 / pn3 marked DEVELOPMENT"
    "figure", "frozen versions Dice", "pn1;pn5;pn7;pn9", "v1;v2;v3", "results/figures/phase97_frozen_versions_dice.png", "97", "", ""
    "figure", "overlays TP / FP / FN", "pn1;pn5;pn7;pn9", "v3", "results/figures/phase97_v3_heldout_overlays.png", "97", "", "GT used for display slice only"
    "script", "held-out test script", "", "v1;v2;v3", "experiments/phase97_heldout_test.m", "97", "", "generated all Phase-97 results"
    "script", "archive verification script", "", "", rel([mfilename('fullpath') '.m']), "98", "", "read-only checks; builds this inventory"
    "manifest", "Phase-97 result manifest", "", "", rel(manifest97File), "97", "PROVENANCE", "27 SHA-256 entries"
    "manifest", "Phase-96 frozen source manifest", "", "v3", rel(manifest96File), "96", "FROZEN ALGORITHM PROVENANCE", "with tag v3-final-frozen (96b1612)"
    "documentation", "Phase-96 freeze record", "", "v3", "docs/PHASE96_FINAL_FREEZE.md", "96", "", "frozen pipeline definition"
    "documentation", "raw data download record", "", "", rel(downloadInfo), "97", "", "held-out download metadata and SHA-256"
    }];
inventory = cell2table(inv, 'VariableNames', {'category', 'role', 'condition', 'version', 'path', 'sourcePhase', ...
    'authoritativeFor', 'notes'});
inventory.sha256 = string(arrayfun(@(p) sha256File(abs_(p)), inventory.path, 'UniformOutput', false));
writetable(inventory, inventoryCsv);
reread = readtable(inventoryCsv, 'TextType', 'string', 'Delimiter', ',');
inventoryOk = all(arrayfun(@(i) isfile(abs_(reread.path(i))) && strcmp(sha256File(abs_(reread.path(i))), reread.sha256(i)), ...
    1:height(reread)));
authoritative = reread.authoritativeFor(~ismissing(reread.authoritativeFor) & reread.authoritativeFor ~= "");
checks = [checks; {
    "56-58 Phase-98 inventory written; every path exists; hashes match the referenced files", inventoryOk
    "59 authoritative roles unambiguous (each designation used once; 4 primary predictions)", ...
        numel(unique(authoritative(authoritative ~= "PRIMARY HELD-OUT PREDICTIONS"))) == ...
        nnz(authoritative ~= "PRIMARY HELD-OUT PREDICTIONS") && nnz(authoritative == "PRIMARY HELD-OUT PREDICTIONS") == 4
    "inventory hashes of Phase-97 artifacts = Phase-97 manifest hashes", all(arrayfun(@(i) ...
        ~any(paths97 == reread.path(i)) || manifest97.sha256(paths97 == reread.path(i)) == reread.sha256(i), 1:height(reread)))
    }];


%% 6. Integrità finale e assenza di nuovi risultati

scriptCode = strjoin(regexprep(splitlines(string(fileread([mfilename('fullpath') '.m']))), '%.*$', ''), newline);
noRun = {['generateFinal' 'Prediction('], ['generateExp05' '7Prediction('], ['generateExp05' '8Prediction('], ...
    ['generateExp05' '9Prediction('], ['loadBrainweb' 'Mri('], ['loadBrainweb' 'GroundTruth('], ['computeVoxel' 'Confusion('], ...
    ['tic' ';'], ['time' 'it(']};
after97 = string(arrayfun(@(p) sha256File(abs_(p)), paths97, 'UniformOutput', false));
checks = [checks; {
    "45-47 Phase-96 manifest, Phase-97 CSVs, predictions and figures unchanged (re-hashed at the end)", ...
        all(after97 == manifest97.sha256) && strcmp(sha256File(manifest96File), manifest96HashAtStart)
    "48-55 no segmentation, MRI / GT loading, metric recomputation or timing in this script", ...
        ~any(cellfun(@(f) contains(scriptCode, f), noRun))
    }];

for c = 1:size(checks, 1)
    if checks{c, 2}
        status = 'ok';
    else
        status = 'FAILED';
    end
    fprintf('%-100s %s\n', checks{c, 1}, status);
end
fprintf('\nInventory: %d rows -> %s\n', height(inventory), rel(inventoryCsv));
fprintf('Runtime: not measured (deferred to Phase 102).\n');
if any(~[checks{:, 2}])
    error('phase98:checksFailed', 'PHASE 98 TECHNICALLY BLOCKED: checks failed.');
end
fprintf('\nPHASE 98 ARCHIVE CHECKS: PASS (%d)\n', size(checks, 1));
diary('off');


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
    if ~isfile(f)
        error('phase98:fileNotReadable', 'Cannot read %s', f);
    end
    [status, out] = system(sprintf('certutil -hashfile "%s" SHA256', f));
    lines = erase(strtrim(splitlines(string(out))), " ");
    match = lines(strlength(lines) == 64 & ~cellfun(@isempty, regexp(cellstr(lines), '^[0-9a-fA-F]{64}$')));
    if status ~= 0 || numel(match) ~= 1
        error('phase98:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
