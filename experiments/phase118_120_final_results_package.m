%% Fasi 118-120: congelamento dei risultati, tabelle finali e insieme definitivo delle figure
% Nessun esperimento nuovo: nessuna segmentazione, nessuna metrica ricalcolata dal GT, nessuna media
% globale. Le tabelle copiano, selezionano, uniscono e rinominano valori dei CSV autorevoli; ogni valore
% copiato è verificato contro la sorgente e, dove disponibile, contro la fase 103 e i risultati originali.
% Gerarchia delle evidenze (mai mescolate senza etichetta):
%   A. FINAL_V4_RESERVED_TEST          v4 sui quattro casi riservati seed 2 (evidenza primaria);
%   B. SEEN DURING v4 DEVELOPMENT       v4 su pn0-pn9 e custom seed 1 (non indipendente);
%   C. HISTORICAL_V3_PROSPECTIVE_TEST   v3 su pn1 / pn5 / pn7 / pn9 (fase 97).
% Figura 2D finale: stessi casi e stesse slice dell'indice delle fasi 105-107 (nessuna nuova scelta).

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.visualization);
M = cfg.paths.metrics; F = cfg.paths.figures; P = cfg.paths.processedData;
D = fullfile(projectRoot, 'docs');
rel = @(p) strrep(erase(string(p), string(projectRoot) + filesep), '\', '/');
abspath = @(r) fullfile(projectRoot, char(r));
readCsv = @(f) readtable(f, 'TextType', 'string', 'Delimiter', ',');
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));
c101 = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'phase101');
cRes = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'v4_reserved_test');
checks = cell(0, 2);


%% 0. Stato del progetto e integrità delle sorgenti prima di tutto

statusText = fileread(fullfile(D, 'PROJECT_STATUS.md'));
statusOk = contains(statusText, 'automated experiment runner: COMPLETE') && ...
    contains(statusText, 'FULFILLED BY PHASE 103') && contains(statusText, 'final 2D visualization: COMPLETE') && ...
    contains(statusText, 'final 3D visualization: COMPLETE') && contains(statusText, 'DEFERRED TO PRE-DELIVERY QA') && ...
    contains(statusText, 'DEFERRED UNTIL FINAL REPOSITORY PREPARATION');
[s4, o4] = system(sprintf('git -C "%s" rev-list -n 1 v4-frozen', projectRoot));
[s3, o3] = system(sprintf('git -C "%s" rev-list -n 1 v3-final-frozen', projectRoot));
manifestOk = @(t) all(arrayfun(@(i) isfile(abspath(t.path(i))) && strcmp(sha256File(abspath(t.path(i))), t.sha256(i)), 1:height(t)));
mf = struct('v4', readCsv(fullfile(D, 'v4_freeze_manifest.csv')), 'v3', readCsv(fullfile(D, 'phase96_final_freeze_manifest.csv')), ...
    'p97', readCsv(fullfile(M, 'phase97_result_manifest.csv')), 'p98', readCsv(fullfile(M, 'phase98_final_results_inventory.csv')), ...
    'p101', readCsv(fullfile(M, 'phase101_result_manifest.csv')), 'res', readCsv(fullfile(M, 'v4_reserved_test_manifest.csv')), ...
    'p103', readCsv(fullfile(M, 'phase103_runner_manifest.csv')), 'p105', readCsv(fullfile(M, 'phase105_107_figure_manifest.csv')), ...
    'p108', readCsv(fullfile(M, 'phase108_109_figure_manifest.csv')), 'ctx', readCsv(fullfile(M, 'phase108_109_brain_context_manifest.csv')));
mfOk = structfun(manifestOk, mf);
% Fase 99: nessun manifest precedente; verifica di contenuto (ultimo passo = riferimento v3 della fase 96)
traj = readCsv(fullfile(M, 'phase99_development_trajectory.csv'));
ref96 = readCsv(fullfile(M, 'phase96_final_development_reference.csv'));
p99Ok = traj.sourceConfiguration(end) == "D3_M1_G0" && traj.dicePn0(end) == ref96.dice(ref96.condition == "pn0") && ...
    traj.dicePn3(end) == ref96.dice(ref96.condition == "pn3") && ...
    isfile(fullfile(M, 'phase99_ablation_summary.csv')) && isfile(fullfile(M, 'phase99_ablation_pairwise.csv'));
checks = [checks; {
    "1-6 Phases 103 / 104 / 105-107 / 108-109 complete; 110-115 and 116-117 recorded as deferred", statusOk
    "7-9 final v4 / V4_K5: v4-frozen -> 2525dde; v3 reference: v3-final-frozen -> 96b1612", s4 == 0 && s3 == 0 && ...
        startsWith(strtrim(string(o4)), "2525ddefacb21d58150db5a4b986e36919e8de3b") && ...
        startsWith(strtrim(string(o3)), "96b16124999a0d40f8df2c66b072fb3a38f10322")
    "10-11 v4 14 frozen hashes and v3 26 frozen hashes valid BEFORE", height(mf.v4) == 14 && height(mf.v3) == 26 && mfOk(1) && mfOk(2)
    "12-18 Phase-97 / 98 / 101 / reserved-test / 103 / 105-107 / 108-109 (+ brain context) manifests valid; Phase-99 content check", ...
        all(mfOk(3:end)) && p99Ok
    }];
if any(~[checks{:, 2}])
    error('phase118:blocked', 'PHASES 118-120 TECHNICALLY BLOCKED - AUTHORITATIVE SOURCE INTEGRITY FAILURE.');
end


%% 1. Fase 118: manifest delle sorgenti scientifiche (solo riferimenti, nessuna copia)

src = {
 % category                role                                          phase                  path
 "algorithm_freeze",      "v4 frozen source manifest (14 files)",        "v4 freeze",           "docs/v4_freeze_manifest.csv"
 "algorithm_freeze",      "v3 frozen source manifest (26 files)",        "Phase 96",            "docs/phase96_final_freeze_manifest.csv"
 "algorithm_freeze",      "v3 freeze record",                            "Phase 96",            "docs/PHASE96_FINAL_FREEZE.md"
 "metrics",               "v3 development reference (pn0, pn3)",         "Phase 96",            "results/metrics/phase96_final_development_reference.csv"
 "metrics",               "ORIGINAL v3 PROSPECTIVE TEST metrics",        "Phase 97",            "results/metrics/phase97_v3_heldout_metrics.csv"
 "metrics",               "v1 / v2 / v3 locked comparison on pn1-pn9",   "Phase 97",            "results/metrics/phase97_frozen_versions_comparison.csv"
 "metrics",               "v3 prospective lesion-wise diagnostics",      "Phase 97",            "results/metrics/phase97_v3_lesionwise_diagnostics.csv"
 "metrics",               "noise robustness table (Phase-97 artifacts)", "Phase 100",           "results/metrics/phase100_noise_robustness_table.csv"
 "ablation",              "retrospective ablation summary",              "Phase 99",            "results/metrics/phase99_ablation_summary.csv"
 "ablation",              "retrospective ablation pairwise",             "Phase 99",            "results/metrics/phase99_ablation_pairwise.csv"
 "ablation",              "development trajectory",                      "Phase 99",            "results/metrics/phase99_development_trajectory.csv"
 "ablation",              "ablation figure",                             "Phase 99",            "results/figures/phase99_ablation_development_score.png"
 "robustness",            "v3 lesion-load robustness",                   "Phase 101",           "results/metrics/phase101_lesion_load_robustness.csv"
 "robustness",            "v3 lesion-load lesion-wise diagnostics",      "Phase 101",           "results/metrics/phase101_lesionwise_diagnostics.csv"
 "robustness",            "custom simulation provenance",                "Phase 101",           "results/metrics/phase101_dataset_provenance.csv"
 "v4_development",        "v4 intensity diagnostic (condition summary)", "v4 D1",               "results/metrics/v4_d1_condition_summary.csv"
 "v4_development",        "v4 intensity diagnostic (by tissue)",         "v4 D1",               "results/metrics/v4_d1_intensity_by_tissue.csv"
 "v4_development",        "EXP-060 grid (k selection, seen data)",       "EXP-060",             "results/metrics/exp060_grid_results.csv"
 "v4_development",        "EXP-060 ranking",                             "EXP-060",             "results/metrics/exp060_ranking.csv"
 "v4_development",        "EXP-060 v3 vs v4 diagnostics",                "EXP-060",             "results/metrics/exp060_v3_vs_v4_diagnostics.csv"
 "v4_development",        "v4 secondary comparison on pn1-pn9 (seen)",   "v4 secondary",        "results/metrics/v4_secondary_heldout_comparison.csv"
 "v4_development",        "EXP-061 grid (negative result)",              "EXP-061",             "results/metrics/exp061_grid_results.csv"
 "v4_development",        "EXP-061 ranking (negative result)",           "EXP-061",             "results/metrics/exp061_ranking.csv"
 "reserved_test",         "FINAL v4 RESERVED TEST results",              "v4 reserved test",    "results/metrics/v4_reserved_test_results.csv"
 "prediction_provenance", "reserved v4 prediction normal_n0",            "v4 reserved test",    "data/processed/v4test_v4_normal_n0_prediction.mat"
 "prediction_provenance", "reserved v4 prediction normal_n3",            "v4 reserved test",    "data/processed/v4test_v4_normal_n3_prediction.mat"
 "prediction_provenance", "reserved v4 prediction msles1_n3",            "v4 reserved test",    "data/processed/v4test_v4_msles1_n3_prediction.mat"
 "prediction_provenance", "reserved v4 prediction msles3_n3",            "v4 reserved test",    "data/processed/v4test_v4_msles3_n3_prediction.mat"
 "prediction_provenance", "v4 k = 5 prediction pn3 (figures)",           "EXP-060",             "data/processed/exp060_candidates/exp060_k5_pn3.mat"
 "automation",            "13 cases x 2 versions consolidated metrics",  "Phase 103",           "results/metrics/phase103_runner_metrics.csv"
 "automation",            "per-case v3 / v4 summary",                    "Phase 103",           "results/metrics/phase103_case_summary.csv"
 "automation",            "runner verification log",                     "Phase 103",           "results/metrics/phase103_runner_verification.txt"
 "visualization",         "2D v4 prediction figure",                     "Phase 105",           "results/figures/phase105_v4_mri_prediction.png"
 "visualization",         "2D GT figure",                                "Phase 106",           "results/figures/phase106_v4_mri_ground_truth.png"
 "visualization",         "2D TP / FP / FN figure",                      "Phase 107",           "results/figures/phase107_v4_tp_fp_fn.png"
 "visualization",         "2D normal-phantom FP diagnostic",             "Phase 107",           "results/figures/phase107_v4_normal_false_positive_diagnostic.png"
 "visualization",         "2D display-slice index",                      "Phases 105-107",      "results/metrics/phase105_107_visualization_index.csv"
 "visualization",         "3D v4 prediction (canonical)",                "Phase 108",           "results/figures/phase108_v4_3d_prediction.png"
 "visualization",         "3D GT vs v4 prediction (canonical)",          "Phase 109",           "results/figures/phase109_v4_3d_gt_prediction_comparison.png"
 "visualization",         "3D TP / FP / FN",                             "Phase 109",           "results/figures/phase109_v4_3d_tp_fp_fn.png"
 "visualization",         "3D visualization index",                      "Phases 108-109",      "results/metrics/phase108_109_visualization_index.csv"
 "visualization",         "3D v4 prediction with brain context",         "Phases 108-109",      "results/figures/phase108_v4_3d_prediction_brain_context.png"
 "visualization",         "3D GT vs v4 prediction with brain context",   "Phases 108-109",      "results/figures/phase109_v4_3d_gt_prediction_brain_context.png"
 "visualization",         "brain-context index",                         "Phases 108-109",      "results/metrics/phase108_109_brain_context_index.csv"
 "manifest",              "Phase-97 result manifest",                    "Phase 97",            "results/metrics/phase97_result_manifest.csv"
 "manifest",              "Phase-98 final results inventory",            "Phase 98",            "results/metrics/phase98_final_results_inventory.csv"
 "manifest",              "Phase-101 result manifest",                   "Phase 101",           "results/metrics/phase101_result_manifest.csv"
 "manifest",              "reserved-test manifest",                      "v4 reserved test",    "results/metrics/v4_reserved_test_manifest.csv"
 "manifest",              "Phase-103 runner manifest",                   "Phase 103",           "results/metrics/phase103_runner_manifest.csv"
 "manifest",              "Phase-105/107 figure manifest",               "Phases 105-107",      "results/metrics/phase105_107_figure_manifest.csv"
 "manifest",              "Phase-108/109 figure manifest",               "Phases 108-109",      "results/metrics/phase108_109_figure_manifest.csv"
 "manifest",              "Phase-108/109 brain-context manifest",        "Phases 108-109",      "results/metrics/phase108_109_brain_context_manifest.csv"
 };
srcPaths = string(src(:, 4));
sourcesExist = all(arrayfun(@(p) isfile(abspath(p)), srcPaths));
if ~sourcesExist
    error('phase118:blocked', 'PHASES 118-120 TECHNICALLY BLOCKED - AUTHORITATIVE SOURCE MISSING.');
end
srcHashBefore = string(arrayfun(@(p) sha256File(abspath(p)), srcPaths, 'UniformOutput', false));
authoritativeFor = repmat("", size(srcPaths));
authoritativeFor(srcPaths == "results/metrics/v4_reserved_test_results.csv") = "Table 1 (primary): FINAL v4 RESERVED TEST";
authoritativeFor(srcPaths == "results/metrics/phase103_runner_metrics.csv") = ...
    "Table 2 (seen v4 context), Table 4 (audit); volumeErrorPercent of Table 1; cross-checks";
authoritativeFor(srcPaths == "results/metrics/phase97_v3_heldout_metrics.csv") = "Table 3: ORIGINAL v3 PROSPECTIVE TEST";
authoritativeFor(srcPaths == "results/metrics/phase105_107_visualization_index.csv") = "Phase-120 2D overview cases and slices";
notes = repmat("", size(srcPaths));
notes(startsWith(srcPaths, "results/metrics/phase99_") | srcPaths == "results/figures/phase99_ablation_development_score.png") = ...
    "no earlier hash record; first hashed here (content checked against Phase-96 reference)";
notes(startsWith(srcPaths, "results/metrics/exp06") | startsWith(srcPaths, "results/metrics/v4_d1") | ...
    srcPaths == "results/metrics/v4_secondary_heldout_comparison.csv" | srcPaths == "results/metrics/phase100_noise_robustness_table.csv" | ...
    srcPaths == "results/metrics/phase96_final_development_reference.csv") = "first hashed here (no earlier manifest lists it)";
notes(srcPaths == "data/processed/exp060_candidates/exp060_k5_pn3.mat") = ...
    "first hashed here; reproduced voxel by voxel in Phase 103";
sourceManifest = table(string(src(:, 1)), string(src(:, 2)), string(src(:, 3)), srcPaths, srcHashBefore, ...
    authoritativeFor, notes, 'VariableNames', {'category', 'role', 'sourcePhase', 'path', 'sha256', 'authoritativeFor', 'notes'});
sourceManifestFile = fullfile(M, 'phase118_final_results_source_manifest.csv');
writetable(sourceManifest, sourceManifestFile);


%% 2. Fase 119: tabelle (copiate dalle sorgenti autorevoli, nessuna metrica ricalcolata)

t103 = readCsv(fullfile(M, 'phase103_runner_metrics.csv'));
res = readCsv(fullfile(M, 'v4_reserved_test_results.csv'));
p97 = readCsv(fullfile(M, 'phase97_v3_heldout_metrics.csv'));
e60 = readCsv(fullfile(M, 'exp060_grid_results.csv'));
sec = readCsv(fullfile(M, 'v4_secondary_heldout_comparison.csv'));
loadOf = containers.Map({'normal', 'msles1', 'msles2', 'msles3'}, {'none', 'mild', 'moderate', 'severe'});
lesionLoad = @(ph) string(arrayfun(@(p) loadOf(char(p)), ph, 'UniformOutput', false));
row103 = @(caseId, v) t103(t103.caseId == caseId & t103.version == v, :);

% Tabella 1 (primaria): v4, quattro casi riservati seed 2
rv = res(res.version == "v4", :);
reservedOrder = ["normal_n0" "normal_n3" "msles1_n3" "msles3_n3"];
r1 = vertcat(arrayfun(@(c) row103("reserved_" + c, "v4"), reservedOrder, 'UniformOutput', false));
r1 = vertcat(r1{:});
ph1 = extractBefore(rv.condition, "_");
main = table(rv.condition, "reserved_" + rv.condition, ph1, lesionLoad(ph1), repmat("T1 + T2", 4, 1), r1.noiseLevel, r1.seed, ...
    rv.version, r1.configId, repmat("FINAL_V4_RESERVED_TEST", 4, 1), repmat("FINAL RESERVED TEST", 4, 1), ...
    rv.gtLesionVoxels, rv.predictedVoxels, rv.dice, rv.iou, rv.precision, rv.recall, rv.specificity, r1.volumeErrorPercent, ...
    rv.tpVoxels, rv.fpVoxels, rv.fnVoxels, rv.gtLesions, rv.detectedGtLesions, rv.falsePredictedComponents, rv.predictedComponents, ...
    repmat("results/metrics/v4_reserved_test_results.csv", 4, 1), ...
    repmat("results/metrics/phase103_runner_metrics.csv (replay of the same saved predictions; not reported in the reserved-test CSV)", 4, 1), ...
    'VariableNames', {'case', 'caseIdPhase103', 'phantom', 'lesionLoad', 'modality', 'noisePercent', 'seed', 'version', 'configId', ...
    'evidenceRole', 'evidenceLabel', 'gtLesionVoxels', 'predictedVoxels', 'dice', 'iou', 'precision', 'recall', 'specificity', ...
    'volumeErrorPercent', 'TP', 'FP', 'FN', 'gtLesions', 'detectedGtLesions', 'falsePredictedComponents', 'predictedComponents', ...
    'metricSource', 'volumeErrorPercentSource'});
mainOk = height(rv) == 4 && isequal(rv.condition.', reservedOrder) && all(rv.role == "PRIMARY") && ...
    isequaln([rv.gtLesionVoxels rv.predictedVoxels rv.tpVoxels rv.fpVoxels rv.fnVoxels rv.dice rv.iou rv.precision rv.recall ...
        rv.specificity rv.predictedComponents rv.falsePredictedComponents rv.gtLesions rv.detectedGtLesions], ...
        [r1.gtLesionVoxels r1.predictedVoxels r1.TP r1.FP r1.FN r1.dice r1.iou r1.precision r1.recall ...
        r1.specificity r1.predictedComponents r1.falsePredictedComponents r1.gtLesions r1.detectedGtLesions]) && ...
    all(r1.version == "v4" & r1.configId == "V4_K5" & r1.caseRole == "RESERVED_TEST_REPLAY" & r1.seed == 2);
isNormal = main.phantom == "normal";
normalOk = sum(isNormal) == 2 && all(main.gtLesionVoxels(isNormal) == 0) && ...
    all(isnan([main.dice(isNormal) main.iou(isNormal) main.precision(isNormal) main.recall(isNormal) main.volumeErrorPercent(isNormal)]), 'all') && ...
    all(main.FP(isNormal) == main.predictedVoxels(isNormal)) && all(main.FP(isNormal) > 0) && ~any(isnan(main.specificity));

% Tabella 2: contesto v4 su dati visti durante lo sviluppo (non indipendente)
seenIds = ["pn0" "pn1" "pn3" "pn5" "pn7" "pn9" "custom_s1_msles1" "custom_s1_msles2" "custom_s1_msles3"];
s2 = arrayfun(@(c) row103(c, "v4"), seenIds, 'UniformOutput', false);
s2 = vertcat(s2{:});
seen = table(s2.caseId, s2.phantom, lesionLoad(s2.phantom), repmat("T1 + T2", 9, 1), s2.noiseLevel, s2.seed, s2.version, ...
    s2.configId, s2.caseRole, repmat("SEEN DURING v4 DEVELOPMENT", 9, 1), repmat("NO", 9, 1), s2.historicalSourcePhase, ...
    s2.gtLesionVoxels, s2.predictedVoxels, s2.dice, s2.iou, s2.precision, s2.recall, s2.specificity, s2.volumeErrorPercent, ...
    s2.TP, s2.FP, s2.FN, s2.gtLesions, s2.detectedGtLesions, s2.falsePredictedComponents, s2.predictedComponents, ...
    repmat("results/metrics/phase103_runner_metrics.csv", 9, 1), ...
    'VariableNames', {'case', 'phantom', 'lesionLoad', 'modality', 'noisePercent', 'seed', 'version', 'configId', 'evidenceRole', ...
    'evidenceLabel', 'independentEvidence', 'historicalSourcePhase', 'gtLesionVoxels', 'predictedVoxels', 'dice', 'iou', 'precision', ...
    'recall', 'specificity', 'volumeErrorPercent', 'TP', 'FP', 'FN', 'gtLesions', 'detectedGtLesions', 'falsePredictedComponents', ...
    'predictedComponents', 'metricSource'});
% Controllo incrociato con le sorgenti originali della v4 (EXP-060 k = 5; confronto secondario pn1-pn9)
seenOk = height(s2) == 9 && all(s2.version == "v4" & s2.configId == "V4_K5") && ...
    all(ismember(s2.caseRole, ["DEVELOPMENT_REFERENCE" "SEEN_V4_DEVELOPMENT" "PHASE97_HELDOUT_THEN_SEEN_V4"])) && ...
    ~any(contains(seen.evidenceLabel, "TEST"));
e60Map = ["pn0" "pn0"; "pn3" "pn3"; "custom_s1_msles1" "msles1"; "custom_s1_msles2" "msles2"; "custom_s1_msles3" "msles3"];
for r = 1:size(e60Map, 1)
    a = s2(s2.caseId == e60Map(r, 1), :); b = e60(e60.configId == "k5" & e60.condition == e60Map(r, 2), :);
    seenOk = seenOk && height(b) == 1 && isequal([a.predictedVoxels a.TP a.FP a.FN a.dice a.precision], ...
        [b.predictedVoxels b.tpVoxels b.fpVoxels b.fnVoxels b.dice b.precision]);
end
for c = ["pn1" "pn5" "pn7" "pn9"]
    a = s2(s2.caseId == c, :); b = sec(sec.condition == c, :);
    seenOk = seenOk && height(b) == 1 && a.caseRole == "PHASE97_HELDOUT_THEN_SEEN_V4" && ...
        isequal([a.dice a.precision a.recall a.predictedVoxels a.FP a.detectedGtLesions a.falsePredictedComponents], ...
        [b.diceV4 b.precisionV4 b.recallV4 b.predictedV4 b.fpV4 b.detectedV4 b.falseCompV4]);
end

% Tabella 3: test prospettico originale della v3 (fase 97, valori storici invariati)
g3 = arrayfun(@(c) row103(c, "v3"), p97.condition.', 'UniformOutput', false);
g3 = vertcat(g3{:});
v3t = table(p97.condition, repmat("msles2", 4, 1), repmat("moderate", 4, 1), repmat("T1 + T2", 4, 1), p97.noisePercent, ...
    p97.version, p97.configId, repmat("HISTORICAL_V3_PROSPECTIVE_TEST", 4, 1), repmat("ORIGINAL v3 PROSPECTIVE TEST", 4, 1), ...
    p97.role, g3.gtLesionVoxels, p97.predictedVoxels, p97.dice, p97.iou, p97.precision, p97.recall, p97.specificity, ...
    p97.volumeErrorPercent, p97.tpVoxels, p97.fpVoxels, p97.fnVoxels, repmat("results/metrics/phase97_v3_heldout_metrics.csv", 4, 1), ...
    repmat("gtLesionVoxels from phase103_runner_metrics.csv (same GT file)", 4, 1), ...
    'VariableNames', {'case', 'phantom', 'lesionLoad', 'modality', 'noisePercent', 'version', 'configId', 'evidenceRole', ...
    'evidenceLabel', 'originalPhase97Role', 'gtLesionVoxels', 'predictedVoxels', 'dice', 'iou', 'precision', 'recall', ...
    'specificity', 'volumeErrorPercent', 'TP', 'FP', 'FN', 'metricSource', 'notes'});
v3Ok = height(p97) == 4 && isequal(p97.condition.', ["pn1" "pn5" "pn7" "pn9"]) && all(p97.version == "v3" & p97.configId == "D3_M1_G0") && ...
    all(g3.caseRole == "PHASE97_HELDOUT_THEN_SEEN_V4") && ...
    isequal([p97.predictedVoxels p97.tpVoxels p97.fpVoxels p97.fnVoxels p97.tnVoxels p97.dice p97.iou p97.precision p97.recall ...
        p97.specificity p97.volumeErrorPercent], [g3.predictedVoxels g3.TP g3.FP g3.FN g3.TN g3.dice g3.iou g3.precision g3.recall ...
        g3.specificity g3.volumeErrorPercent]);

% Tabella 4: audit completo (tutte le 26 righe della fase 103 + stato dell'evidenza)
status = strings(height(t103), 1);
for r = 1:height(t103)
    status(r) = evidenceStatus(t103.caseId(r), t103.caseRole(r), t103.version(r));
end
audit = [t103 table(status, 'VariableNames', {'evidenceStatus'})];
auditOk = height(audit) == 26 && sum(status == "FINAL_V4_RESERVED_TEST") == 4 && sum(status == "HISTORICAL_V3_PROSPECTIVE_TEST") == 4 && ...
    sum(startsWith(status, "SEEN_DURING_V4_DEVELOPMENT")) == 9 && all(status ~= "");

tableFiles = struct('main', fullfile(M, 'phase119_main_results_v4_reserved.csv'), 'seen', fullfile(M, 'phase119_v4_seen_context.csv'), ...
    'v3', fullfile(M, 'phase119_v3_original_prospective_test.csv'), 'audit', fullfile(M, 'phase119_full_results_audit.csv'), ...
    'report', fullfile(M, 'phase119_main_results_v4_reserved_report.csv'));
writetable(main, tableFiles.main);
writetable(seen, tableFiles.seen);
writetable(v3t, tableFiles.v3);
writetable(audit, tableFiles.audit);
% Tabella di presentazione (solo arrotondamento; la tabella a piena precisione resta invariata)
report = main(:, {'case', 'phantom', 'lesionLoad', 'modality', 'noisePercent', 'seed', 'version', 'evidenceLabel', ...
    'gtLesionVoxels', 'predictedVoxels', 'dice', 'iou', 'precision', 'recall', 'specificity', 'volumeErrorPercent', ...
    'TP', 'FP', 'FN', 'gtLesions', 'detectedGtLesions', 'falsePredictedComponents'});
for v = ["dice" "iou" "precision" "recall"]
    report.(v) = round(report.(v), 3);
end
report.specificity = round(report.specificity, 5);
report.volumeErrorPercent = round(report.volumeErrorPercent, 1);
writetable(report, tableFiles.report);

% Rilettura: i valori scritti coincidono con le sorgenti (piena precisione)
numCols = @(t) t{:, varfun(@isnumeric, t, 'OutputFormat', 'uniform')};
readBackOk = isequaln(numCols(readCsv(tableFiles.main)), numCols(main)) && isequaln(numCols(readCsv(tableFiles.seen)), numCols(seen)) && ...
    isequaln(numCols(readCsv(tableFiles.v3)), numCols(v3t)) && isequaln(numCols(readCsv(tableFiles.audit)), numCols(t103));
checks = [checks; {
    "19-21 Phase-118 source manifest created; every source exists; hashes recorded", sourcesExist && isfile(sourceManifestFile)
    "22-25 Table 1 = 4 reserved seed-2 rows, v4 only, FINAL_V4_RESERVED_TEST; values equal reserved-test CSV and Phase 103", ...
        mainOk && all(main.evidenceRole == "FINAL_V4_RESERVED_TEST") && all(main.version == "v4")
    "26-31 normal_n0 / normal_n3 / msles1_n3 / msles3_n3 included; normal overlap metrics NaN; normal FP retained", normalOk
    "32-33 seen-context table: 9 v4 rows with exact Phase-103 roles, labelled non-independent; equal EXP-060 / secondary sources", seenOk
    "34-35 v3 original prospective table: 4 rows exactly equal Phase 97 (and Phase-103 v3 replay)", v3Ok
    "36 full audit table: 26 rows with evidence status", auditOk
    "37-39 values copied exactly (read-back equal); no global mean, no metric recomputed from GT", readBackOk
    }];


%% 3. Fase 120: panoramica 2D finale (stessi casi e slice delle fasi 105-107)

idx105 = readCsv(fullfile(M, 'phase105_107_visualization_index.csv'));
known = containers.Map('KeyType', 'char', 'ValueType', 'any');
for f = ["phase101_result_manifest.csv" "v4_reserved_test_manifest.csv"]
    t = readCsv(fullfile(M, f));
    for r = 1:height(t)
        known(char(t.path(r))) = t.sha256(r);
    end
end
known(char(rel(cfg.dataset.noisyMriFiles.pn3.T2))) = "52AF70628F1211CCEF850F61E715D4D743102EAF29AD1337CDEB61BBCCFE0F7E";
vis = struct( ...
    'caseId', {"pn3", "reserved_msles1_n3", "reserved_msles3_n3"}, ...
    'label',  {"Moderate MS - development reference", "Mild MS - final reserved test", "Severe MS - final reserved test"}, ...
    't2',     {cfg.dataset.noisyMriFiles.pn3.T2, ...
               fullfile(cRes, 'mri', 'custom_msles1_t2_ai_1mm_n3_inu0_seed2_job1261017-094235s-2845389.raws'), ...
               fullfile(cRes, 'mri', 'custom_msles3_t2_ai_1mm_n3_inu0_seed2_job1261017-094329s-2845552.raws')}, ...
    'gt',     {cfg.dataset.groundTruthFile, fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles1_crisp.rawb'), ...
               fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles3_crisp.rawb')}, ...
    'pred',   {fullfile(P, 'exp060_candidates', 'exp060_k5_pn3.mat'), fullfile(P, 'v4test_v4_msles1_n3_prediction.mat'), ...
               fullfile(P, 'v4test_v4_msles3_n3_prediction.mat')});
visInputsOk = isequal(idx105.caseId(1:3).', [vis.caseId]) && isequal(idx105.predictionSource(1:3).', rel(string({vis.pred}))) && ...
    all(arrayfun(@(v) isKey(known, char(rel(v.t2))) && strcmp(sha256File(v.t2), char(known(char(rel(v.t2))))) && ...
        isKey(known, char(rel(v.gt))) && strcmp(sha256File(v.gt), char(known(char(rel(v.gt))))), vis));
if ~visInputsOk
    error('phase120:blocked', 'PHASES 118-120 TECHNICALLY BLOCKED - Phase-120 inputs differ from the frozen display selection.');
end

predColor = [1 0.85 0]; gtColor = [0 0.9 0.9]; fillAlpha = 0.45;      % come fasi 105 / 106
colTitles = ["Original T2" "T2 + ground truth" "T2 + final v4 prediction" "T2 + TP / FP / FN"];
overviewFile = fullfile(F, 'phase120_final_2d_overview.png');
fig = figure('Color', 'w', 'Position', [60 60 1500 1200]);
layout = tiledlayout(fig, 3, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
sliceOk = true; slicesUsed = zeros(1, 3);
for i = 1:3
    k = idx105.sliceIndex(i);
    slicesUsed(i) = k;
    cfgC = cfg; cfgC.dataset.noisyMriFiles.vis.T2 = vis(i).t2;
    t2 = loadBrainwebMri(cfgC, "T2", "vis");
    cfgG = cfg; cfgG.dataset.groundTruthFile = vis(i).gt;
    gt = loadBrainwebGroundTruth(cfgG) == 10;
    s = load(vis(i).pred, 'M_pred');
    pred = s.M_pred;
    if ~islogical(pred) || ~isequal(size(pred), size(gt), size(t2))
        error('phase120:blocked', 'PHASES 118-120 TECHNICALLY BLOCKED - dimension / type mismatch for %s.', vis(i).caseId);
    end
    range = double([min(t2(:)) max(t2(:))]);
    mriSlice = double(t2(:, :, k));
    titles = repmat("", 1, 4);
    if i == 1
        titles = colTitles;
    end
    ax = nexttile(layout);
    overlayMaskBoundaryOnMRI(ax, mriSlice, false(size(mriSlice)), 'DisplayRange', range, 'Title', titles(1));
    ylabel(ax, sprintf('%s\n%s\nslice k = %d', vis(i).caseId, vis(i).label, k), 'Interpreter', 'none', 'FontSize', 9);
    ax = nexttile(layout);
    overlayMaskBoundaryOnMRI(ax, mriSlice, gt(:, :, k), 'BoundaryColor', gtColor, 'ShowFill', true, 'FillAlpha', fillAlpha, ...
        'DisplayRange', range, 'Title', titles(2));
    ax = nexttile(layout);
    overlayMaskBoundaryOnMRI(ax, mriSlice, pred(:, :, k), 'BoundaryColor', predColor, 'ShowFill', true, 'FillAlpha', fillAlpha, ...
        'DisplayRange', range, 'Title', titles(3));
    ax = nexttile(layout);
    cnt = overlayErrorMapOnMRI(ax, mriSlice, pred(:, :, k), gt(:, :, k), 'Alpha', 0.6, 'DisplayRange', range, 'Title', titles(4));
    sliceOk = sliceOk && nnz(gt(:, :, k)) == idx105.gtLesionVoxelsInSlice(i) && nnz(pred(:, :, k)) == idx105.predictedVoxelsInSlice(i) && ...
        cnt.TP == idx105.tpVoxelsInSlice(i) && cnt.FP == idx105.fpVoxelsInSlice(i) && cnt.FN == idx105.fnVoxelsInSlice(i);
end
ax = nexttile(layout, 12);
hold(ax, 'on');
h = [patch(ax, NaN, NaN, gtColor), patch(ax, NaN, NaN, predColor), patch(ax, NaN, NaN, [0 1 0]), ...
    patch(ax, NaN, NaN, [1 0 0]), patch(ax, NaN, NaN, [0 0.35 1])];
hold(ax, 'off');
legend(ax, h, {'GT (label 10)', 'v4 prediction', 'TP', 'FP', 'FN'}, 'Location', 'southoutside', 'Orientation', 'horizontal');
title(layout, 'Final v4 (V4\_K5) segmentation - T2, 3% noise');
exportgraphics(fig, overviewFile, 'Resolution', 250);
close(fig);
checks = [checks; {
    "40-47 2D overview: same 3 cases and Phase-105 slices; T2 / GT / v4 / TP-FP-FN columns; slice counts equal Phase-105 index", ...
        sliceOk && isequal(slicesUsed, idx105.sliceIndex(1:3).') && isfile(overviewFile)
    }];


%% 4. Fase 120: selezione delle figure 3D definitive, indice e didascalie

figIndex = table(["F1"; "F2"; "F3"; "F4"], ...
    ["main 2D result figure"; "3D localization of the final prediction"; "3D GT / prediction comparison"; "optional 3D error geometry"], ...
    [rel(overviewFile); "results/figures/phase108_v4_3d_prediction_brain_context.png"; ...
     "results/figures/phase109_v4_3d_gt_prediction_brain_context.png"; "results/figures/phase109_v4_3d_tp_fp_fn.png"], ...
    ["Phase 120 (slices from Phases 105-107)"; "Phases 108-109 (brain-context variant)"; "Phases 108-109 (brain-context variant)"; "Phase 109"], ...
    repmat("pn3; reserved_msles1_n3; reserved_msles3_n3", 4, 1), repmat("v4 / V4_K5", 4, 1), ...
    ["original T2, T2 + GT, T2 + v4 prediction, T2 + TP / FP / FN on the frozen display slices"; ...
     "complete 3D v4 lesion mask inside the transparent automatic EXP-021 T1-derived brain mask (display context only)"; ...
     "complete 3D GT (cyan) and v4 prediction (yellow), semi-transparent, inside the EXP-021 brain mask (display context only)"; ...
     "complete 3D TP (green), FP (red), FN (blue) surfaces, no brain context"], ...
    ["roadmap set original / GT / prediction / error map in one figure; cases and slices fixed before Phase 120"; ...
     "brain context gives spatial localization; lesion mask unchanged"; ...
     "brain-context variant remains readable; canonical phase109_v4_3d_gt_prediction_comparison.png kept as alternative"; ...
     "shows where FP and FN lie in 3D; optional for Results / Discussion"], ...
    false(4, 1), 'VariableNames', {'figureId', 'reportRole', 'path', 'sourcePhase', 'cases', 'version', 'description', ...
    'selectionReason', 'scientificDataModified'});
figureIndexFile = fullfile(M, 'phase120_final_figure_index.csv');
writetable(figIndex, figureIndexFile);
captionsFile = fullfile(D, 'FINAL_FIGURE_CAPTIONS.md');
freezeDocFile = fullfile(D, 'FINAL_RESULTS_FREEZE.md');
captionText = fileread(captionsFile);
selectedOk = all(arrayfun(@(p) isfile(abspath(p)), figIndex.path)) && ...
    all(ismember(figIndex.path(2:4), [mf.p108.path; mf.ctx.path])) && ~any(figIndex.scientificDataModified);
checks = [checks; {
    "49-53 definitive 3D figures selected from validated manifests; figure index and captions exist; grey surface described as EXP-021 mask", ...
        selectedOk && isfile(figureIndexFile) && isfile(freezeDocFile) && contains(captionText, 'EXP-021') && ...
        contains(captionText, 'not an anatomical') && all(arrayfun(@(f) contains(captionText, f), ["F1" "F2" "F3" "F4"]))
    }];


%% 5. Manifest del pacchetto e integrità dopo

packageFiles = [string(freezeDocFile); string(sourceManifestFile); string(tableFiles.main); string(tableFiles.seen); ...
    string(tableFiles.v3); string(tableFiles.audit); string(tableFiles.report); string(overviewFile); string(figureIndexFile); ...
    string(captionsFile); string([mfilename('fullpath') '.m'])];
packageHashes = string(cellfun(@sha256File, cellstr(packageFiles), 'UniformOutput', false));
packageManifestFile = fullfile(M, 'phase118_120_final_report_package_manifest.csv');
writetable(table(rel(packageFiles), packageHashes, 'VariableNames', {'path', 'sha256'}), packageManifestFile);

code = char(strjoin(regexprep(splitlines(string(fileread([mfilename('fullpath') '.m']))), '%.*$', ''), newline));
forbidden = {['generateFinal' 'Prediction('], ['generateV4' 'Prediction('], ['generate' 'Exp'], ['generateV5' 'Predictions('], ...
    ['multi' 'thresh('], ['anisotropic' 'Diffusion'], ['imop' 'en('], ['imcl' 'ose('], ['imdi' 'late('], ['region' 'Grow'], ...
    ['computeDice' 'FromConfusion('], ['computeIoU' 'FromConfusion('], ['computePrecision' 'FromConfusion('], ...
    ['computeRecall' 'FromConfusion('], ['computeSpecificity' 'FromConfusion('], ['computeVolume' 'ErrorPercent('], ...
    ['computeVoxel' 'Confusion('], ['me' 'an('], ['sa' 've('], ['EXP-0' '62'], ['git ' 'tag'], ['git ' 'commit']};
srcHashAfter = string(arrayfun(@(p) sha256File(abspath(p)), srcPaths, 'UniformOutput', false));
checks = [checks; {
    "54-55 package manifest created; every package artifact hash matches", isfile(packageManifestFile) && ...
        isequal(packageHashes, string(cellfun(@sha256File, cellstr(packageFiles), 'UniformOutput', false)))
    "48, 56-61 no segmentation, candidate generation, morphology, metric recomputation, mean, MAT saving, tag / commit", ...
        ~any(cellfun(@(f) contains(code, f), forbidden))
    "62 Phase-118 scientific source hashes unchanged AFTER", isequal(srcHashBefore, srcHashAfter)
    "63-65 v4 / v3 frozen hashes, all source manifests and config.m unchanged AFTER", all(structfun(manifestOk, mf)) && ...
        isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];
for i = 1:size(checks, 1)
    fprintf('%-130s %s\n', checks{i, 1}, ternary(checks{i, 2}, 'ok', 'FAILED'));
end
if any(~[checks{:, 2}])
    error('phase118:checksFailed', 'PHASES 118-120 checks failed.');
end
disp(main(:, {'case', 'gtLesionVoxels', 'predictedVoxels', 'dice', 'precision', 'recall', 'specificity', 'FP', 'falsePredictedComponents'}));
fprintf('Sources frozen: %d; package artifacts: %d; slices reused: %s\n', numel(srcPaths), numel(packageFiles), mat2str(slicesUsed));
fprintf('\nPHASES 118-120 FINAL RESULTS PACKAGE: PASS (%d)\n', size(checks, 1));


function s = evidenceStatus(caseId, caseRole, version)
%EVIDENCESTATUS Stato dell'evidenza di una riga della fase 103 (solo etichetta, nessun valore modificato).
    if version == "v4" && caseRole == "RESERVED_TEST_REPLAY"
        s = "FINAL_V4_RESERVED_TEST";
    elseif version == "v4"
        s = "SEEN_DURING_V4_DEVELOPMENT (" + caseRole + ")";
    elseif ismember(caseId, ["pn1" "pn5" "pn7" "pn9"])
        s = "HISTORICAL_V3_PROSPECTIVE_TEST";
    elseif caseRole == "DEVELOPMENT_REFERENCE"
        s = "V3_DEVELOPMENT_REFERENCE";
    elseif caseRole == "SEEN_V4_DEVELOPMENT"
        s = "V3_POST_FREEZE_LESION_LOAD_ROBUSTNESS (Phase 101)";
    elseif caseRole == "RESERVED_TEST_REPLAY"
        s = "V3_REFERENCE_ARM_OF_V4_RESERVED_TEST";
    else
        s = "";
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

function h = sha256File(f)
%SHA256FILE Impronta SHA-256 (esadecimale maiuscolo) tramite certutil di Windows.
    [status, out] = system(sprintf('certutil -hashfile "%s" SHA256', f));
    lines = erase(strtrim(splitlines(string(out))), " ");
    match = lines(strlength(lines) == 64 & ~cellfun(@isempty, regexp(cellstr(lines), '^[0-9a-fA-F]{64}$')));
    if status ~= 0 || numel(match) ~= 1
        error('phase118:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
