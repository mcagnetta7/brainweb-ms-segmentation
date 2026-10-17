%% Fase 99: studio di ablazione retrospettivo della pipeline finale (solo sviluppo)
% Sintesi di risultati di sviluppo GIÀ salvati (EXP-026/030/033, EXP-042,
% EXP-056, EXP-057, EXP-058, EXP-059, fase 73): nessuna predizione, nessun
% MRI, nessun GT, nessuna funzione di segmentazione, nessun dato held-out.
% Ogni configurazione è descritta da sette blocchi (supporto, soglia, filtro,
% dimensionalità del filtro, morfologia, regola sulle componenti, recupero),
% letti dalle colonne dei grid salvati o, dove un esperimento li teneva fissi,
% dalla sua preregistrazione. Una coppia è "controllata" solo se i descrittori
% differiscono esattamente nel blocco dichiarato.
% DevelopmentScore = (Dice_pn0 + Dice_pn3) / 2 (fase 37), letto dai CSV.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
M = cfg.paths.metrics;
abs_ = @(p) fullfile(projectRoot, p);
closeTo = @(a, b) abs(a - b) <= 1e-12 * max(1, abs(b));
checks = cell(0, 2);


%% 0. Precondizioni e integrità prima dell'analisi

statusText = fileread(fullfile(projectRoot, 'docs', 'PROJECT_STATUS.md'));
finalConfig = finalSegmentationConfig();
integrityBefore = integrityState(projectRoot, M);
checks = [checks; {
    "1 Phase 98 recorded COMPLETE",                   contains(statusText, 'final raw result archive: COMPLETE')
    "2 primary remains v3 / D3_M1_G0",               finalConfig.version == "v3" && finalConfig.sourceConfiguration == "D3_M1_G0"
    "3-5 Phase-96 (26), Phase-97 (27), Phase-98 inventory (32) hashes match BEFORE the analysis", integrityBefore.ok
    }];


%% 1. Fonti autorevoli (solo lettura)

src = struct();
for e = ["056" "057" "058" "059"]
    f = "exp" + e;
    src.(f).ranking = readtable(fullfile(M, f + "_tuning_ranking.csv"), 'TextType', 'string');
    src.(f).grid = readtable(fullfile(M, f + "_tuning_grid_results.csv"), 'TextType', 'string');
end
exp026 = readtable(fullfile(M, 'exp026_multithresh_summary.csv'), 'TextType', 'string');
exp030 = readtable(fullfile(M, 'exp030_opening_score_comparison.csv'), 'TextType', 'string');
exp033 = readtable(fullfile(M, 'exp033_before_after_development_summary.csv'), 'TextType', 'string');
exp042 = readtable(fullfile(M, 'exp042_mono_vs_multimodal_summary.csv'), 'TextType', 'string');
phase73 = readtable(fullfile(M, 'phase73_region_growing_decision.csv'), 'TextType', 'string');
checks(end+1, :) = {"6-11 EXP-026, opening (EXP-030 / 033), EXP-056, EXP-057, EXP-058, EXP-059 artifacts read", ...
    height(exp026) == 2 && height(exp030) == 3 && all(arrayfun(@(e) height(src.("exp" + e).ranking) > 0, ["056" "057" "058" "059"]))};

% Righe usate (esperimento, configurazione)
keys = {"056", "P0_T2_M0_G0"; "056", "P0_T2_M2_G0"; "056", "P0_T2_M2_G1"; ...
        "057", "S0_TA_M2_G1"; "057", "S1_TA_M2_G1"; "057", "S2_TA_M2_G1"; ...
        "058", "F0_R0"; "058", "F5_R0"; "058", "F5_R1"; "058", "F5_R2"; ...
        "059", "D2_M2_G1"; "059", "D3_M2_G1"; "059", "D3_M0_G0"; "059", "D3_M1_G0"; "059", "D3_M2_G0"; "059", "D3_M1_G1"};
rows = struct([]);
for i = 1:size(keys, 1)
    rows = [rows; rowOf(src.("exp" + keys{i, 1}), keys{i, 1}, keys{i, 2})]; %#ok<AGROW>
end
key = @(e, c) find(arrayfun(@(r) r.experiment == "EXP-" + e && r.config == c, rows));
R = @(e, c) rows(key(e, c));

% Ogni punteggio = fonte autorevole; collegamenti tra esperimenti (stessa configurazione riprodotta)
scoresFromSource = all(arrayfun(@(r) r.sourceConsistent, rows));
links = [
    closeTo(R("056", "P0_T2_M0_G0").score, mean(exp026.dice))                         % fase 60 / EXP-026
    closeTo(R("056", "P0_T2_M0_G0").score, exp030.developmentScore(exp030.variant == "baseline"))
    closeTo(R("056", "P0_T2_M2_G0").score, exp030.developmentScore(exp030.variant == "opening"))
    closeTo(R("056", "P0_T2_M2_G0").score, exp033.developmentScore(exp033.stage == "after_morphology"))
    closeTo(R("056", "P0_T2_M2_G1").score, R("057", "S0_TA_M2_G1").score)          % EXP-056 vincitore = base EXP-057
    closeTo(R("057", "S2_TA_M2_G1").score, R("058", "F0_R0").score)                % v1 = base EXP-058
    closeTo(R("058", "F5_R0").score, R("059", "D2_M2_G1").score)                   % v2 = base EXP-059
    ];
checks = [checks; {
    "16-18 every score / Dice / count equals its source row (ranking = grid), DevelopmentScore = mean of the two Dice", scoresFromSource
    "cross-experiment links: EXP-026 = 056 M0; EXP-030/033 opening = 056 M2_G0; 056 winner = 057 S0; v1 = 058 F0_R0; v2 = 059 D2", all(links)
    }];


%% 2. Coppie controllate (un solo blocco cambiato, verificato sui descrittori)

pairDefs = {
    "P01", "opening introduction (none -> square 3)", "056", "P0_T2_M0_G0", "056", "P0_T2_M2_G0", "morphology"
    "P02", "G1 introduction (pre-S2)",                "056", "P0_T2_M2_G0", "056", "P0_T2_M2_G1", "componentRule"
    "P03", "anatomical support S0 -> S1",             "057", "S0_TA_M2_G1", "057", "S1_TA_M2_G1", "support"
    "P04", "anatomical support S1 -> S2",             "057", "S1_TA_M2_G1", "057", "S2_TA_M2_G1", "support"
    "P05", "anatomical support S0 -> S2",             "057", "S0_TA_M2_G1", "057", "S2_TA_M2_G1", "support"
    "P06", "T2 anisotropic filtering (none -> 2D, T2 only)", "058", "F0_R0", "058", "F5_R0", "filter"
    "P07", "diffusion D2 -> D3",                      "059", "D2_M2_G1", "059", "D3_M2_G1", "filterDim"
    "P08", "morphology M0 -> M1 (after D3)",          "059", "D3_M0_G0", "059", "D3_M1_G0", "morphology"
    "P09", "morphology M2 -> M1 (after D3)",          "059", "D3_M2_G0", "059", "D3_M1_G0", "morphology"
    "P10", "component rule G1 -> G0 (after D3 + M1)", "059", "D3_M1_G1", "059", "D3_M1_G0", "componentRule"
    "P11", "recovery R0 -> R1 (filtered v2 branch)",  "058", "F5_R0", "058", "F5_R1", "recovery"
    "P12", "recovery R0 -> R2 (filtered v2 branch)",  "058", "F5_R0", "058", "F5_R2", "recovery"
    };
pairRows = cell(size(pairDefs, 1), 15);
allControlled = true;
for p = 1:size(pairDefs, 1)
    a = R(pairDefs{p, 3}, pairDefs{p, 4}); b = R(pairDefs{p, 5}, pairDefs{p, 6});
    changed = differingBlocks(a, b);
    controlled = isequal(changed, string(pairDefs{p, 7}));
    allControlled = allControlled && controlled;
    delta = b.score - a.score;
    pairRows(p, :) = {pairDefs{p, 1}, pairDefs{p, 2}, a.experiment, a.config, b.experiment, b.config, controlled, ...
        a.dice(1), b.dice(1), a.dice(2), b.dice(2), a.score, b.score, delta, ...
        ternary(delta > 0, "candidate higher", ternary(delta < 0, "candidate lower", "equal"))};
end
pairwise = cell2table(pairRows, 'VariableNames', {'comparisonId', 'factor', 'referenceExperiment', 'referenceConfig', ...
    'candidateExperiment', 'candidateConfig', 'allOtherBlocksFixed', 'referenceDicePn0', 'candidateDicePn0', ...
    'referenceDicePn3', 'candidateDicePn3', 'referenceDevelopmentScore', 'candidateDevelopmentScore', ...
    'deltaDevelopmentScore', 'result'});
writetable(pairwise, fullfile(M, 'phase99_ablation_pairwise.csv'));
disp(pairwise(:, {'comparisonId', 'factor', 'referenceConfig', 'candidateConfig', 'allOtherBlocksFixed', ...
    'referenceDevelopmentScore', 'candidateDevelopmentScore', 'deltaDevelopmentScore'}));
checks = [checks; {
    "19-24 every pair differs ONLY in its declared block (support, filter, D, M, G, R verified)", allControlled
    "25 no uncontrolled pair labelled as a one-factor ablation", all(pairwise.allOtherBlocksFixed)
    }];


%% 3. Tabella riassuntiva per gruppo di ablazione

groups = {
    "A opening", {"056", "P0_T2_M0_G0"; "056", "P0_T2_M2_G0"}
    "B G1 (pre-S2)", {"056", "P0_T2_M2_G0"; "056", "P0_T2_M2_G1"}
    "C anatomical support", {"057", "S0_TA_M2_G1"; "057", "S1_TA_M2_G1"; "057", "S2_TA_M2_G1"}
    "D T2 filtering", {"058", "F0_R0"; "058", "F5_R0"}
    "E D2 vs D3", {"059", "D2_M2_G1"; "059", "D3_M2_G1"}
    "F morphology after D3", {"059", "D3_M0_G0"; "059", "D3_M1_G0"; "059", "D3_M2_G0"}
    "G G1 vs G0 after D3 + M1", {"059", "D3_M1_G1"; "059", "D3_M1_G0"}
    "H recovery (rejected)", {"058", "F5_R0"; "058", "F5_R1"; "058", "F5_R2"}
    };
retained = ["P0_T2_M2_G0", "S2_TA_M2_G1", "F5_R0", "D3_M2_G1", "D3_M1_G0"];
sumRows = cell(0, 31);
for g = 1:size(groups, 1)
    members = groups{g, 2};
    ref = R(members{1, 1}, members{1, 2});
    for s = 1:size(members, 1)
        r = R(members{s, 1}, members{s, 2});
        changed = strjoin(differingBlocks(ref, r), ", ");
        role = ternary(s == 1, "reference", ternary(r.config == "D3_M1_G0", "FINAL v3", ...
            ternary(any(r.config == retained), "retained at that stage", "evaluated, not retained")));
        sumRows(end+1, :) = {groups{g, 1}, s - 1, r.experiment, r.config, ternary(changed == "", "-", changed), ...
            r.blocks.support, r.blocks.filter, r.blocks.filterDim, r.blocks.morphology, r.blocks.componentRule, ...
            r.blocks.recovery, r.dice(1), r.dice(2), r.weaker, r.score, r.score - ref.score, ...
            (r.score - ref.score) / ref.score * 100, r.tp(1), r.fp(1), r.fn(1), r.tp(2), r.fp(2), r.fn(2), ...
            r.predicted(1), r.predicted(2), r.precision(1), r.precision(2), r.recall(1), r.recall(2), role, ...
            "development only (pn0 + pn3)"}; %#ok<SAGROW>
    end
end
% Appendice: blocchi valutati ma non mantenuti senza una riga nei grid sopra
t2 = exp042(exp042.method == "T2", :); fused = exp042(exp042.method == "T2+PD", :);
sumRows(end+1, :) = {"NR multimodal fusion", 0, "EXP-042", "T2 (opening)", "-", "S0", "none", "none", "square3", ...
    "none", "none", t2.dicePn0, t2.dicePn3, t2.weakerConditionDice, t2.developmentScore, 0, 0, NaN, NaN, NaN, NaN, ...
    NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, "reference", "development only (pn0 + pn3)"};
sumRows(end+1, :) = {"NR multimodal fusion", 1, "EXP-042", "T2 AND PD", "fusion", "S0", "none", "none", "square3", ...
    "none", "none", fused.dicePn0, fused.dicePn3, fused.weakerConditionDice, fused.developmentScore, ...
    fused.developmentScore - t2.developmentScore, (fused.developmentScore - t2.developmentScore) / t2.developmentScore * 100, ...
    NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, "rejected (EXP-042)", "development only (pn0 + pn3)"};
sumRows(end+1, :) = {"NR region growing", 0, "Phase 73", string(phase73.decision), "-", "", "", "", "", "", "", ...
    NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, ...
    "NOT RETAINED / NOT NUMERICALLY ABLATED", "prerequisite not satisfied (Phase 73): " + string(phase73.reason)};
summary = cell2table(sumRows, 'VariableNames', {'ablationGroup', 'step', 'sourceExperiment', 'sourceConfiguration', ...
    'changeFromReference', 'support', 'filter', 'filterDimensionality', 'morphology', 'componentRule', 'recovery', ...
    'dicePn0', 'dicePn3', 'weakerConditionDice', 'developmentScore', 'deltaVsReference', 'relativeDeltaPercent', ...
    'tpPn0', 'fpPn0', 'fnPn0', 'tpPn3', 'fpPn3', 'fnPn3', 'predictedVoxelsPn0', 'predictedVoxelsPn3', ...
    'precisionPn0', 'precisionPn3', 'recallPn0', 'recallPn3', 'role', 'interpretation'});
writetable(summary, fullfile(M, 'phase99_ablation_summary.csv'));


%% 4. Traiettoria storica di sviluppo (pietre miliari)

milestones = {
    "Phase 60 / EXP-026 candidate (multithresh N=2, class 3)", "056", "P0_T2_M0_G0"
    "+ square-3 opening (EXP-030, Phase 63-65)",               "056", "P0_T2_M2_G0"
    "+ single-slice component filter G1 (EXP-056 winner)",     "056", "P0_T2_M2_G1"
    "+ T1-derived support S2 = v1 (EXP-057)",                  "057", "S2_TA_M2_G1"
    "+ T2 anisotropic diffusion 2D = v2 (EXP-058)",            "058", "F5_R0"
    "diffusion 2D -> 3D (EXP-059)",                            "059", "D3_M2_G1"
    "opening square 3 -> diamond 1 (EXP-059)",                 "059", "D3_M1_G1"
    "G1 removed = v3 FINAL (EXP-059)",                         "059", "D3_M1_G0"
    };
trajRows = cell(size(milestones, 1), 11);
previous = [];
for t = 1:size(milestones, 1)
    r = R(milestones{t, 2}, milestones{t, 3});
    if isempty(previous)
        changed = ""; controlled = false; delta = NaN;
    else
        changed = strjoin(differingBlocks(previous, r), ", ");
        controlled = numel(differingBlocks(previous, r)) == 1;
        delta = r.score - previous.score;
    end
    trajRows(t, :) = {t, milestones{t, 1}, r.experiment, r.config, ternary(changed == "", "-", changed), controlled, ...
        r.dice(1), r.dice(2), r.score, delta, "DEVELOPMENT ONLY (pn0 + pn3)"};
    previous = r;
end
selected059 = readtable(fullfile(M, 'exp059_selected_configuration.csv'), 'TextType', 'string');
trajectory = cell2table(trajRows, 'VariableNames', {'step', 'milestone', 'sourceExperiment', 'sourceConfiguration', ...
    'changedBlocks', 'controlledSingleFactorChange', 'dicePn0', 'dicePn3', 'developmentScore', 'deltaVsPrevious', 'role'});
writetable(trajectory, fullfile(M, 'phase99_development_trajectory.csv'));
disp(trajectory(:, {'step', 'sourceConfiguration', 'changedBlocks', 'controlledSingleFactorChange', 'developmentScore', ...
    'deltaVsPrevious'}));
checks = [checks; {
    "26 trajectory records controlled vs non-controlled transitions explicitly", ...
        all(ismember(trajectory.controlledSingleFactorChange(2:end), [true false])) && ~trajectory.controlledSingleFactorChange(1)
    "final milestone = frozen v3 D3_M1_G0, score = EXP-059 selected", trajectory.sourceConfiguration(end) == "D3_M1_G0" && ...
        closeTo(trajectory.developmentScore(end), selected059.developmentScore)
    }];


%% 5. Figura (solo sviluppo)

fig = figure('Color', 'w');
ax = axes(fig);
bar(ax, trajectory.developmentScore, 'FaceColor', [0.55 0.7 0.9]);
hold(ax, 'on');
plot(ax, 1:height(trajectory), trajectory.dicePn0, 'b^', 1:height(trajectory), trajectory.dicePn3, 'rv', 'MarkerSize', 7);
hold(ax, 'off');
labels = ["EXP-026", "+opening", "+G1", "+S2 (v1)", "+aniso T2 (v2)", "2D->3D", "sq3->diamond1", "-G1 (v3)"];
set(ax, 'XTick', 1:height(trajectory), 'XTickLabel', labels);
xtickangle(ax, 30); ylim(ax, [0 1]); grid(ax, 'on');
ylabel(ax, 'complete-volume Dice / DevelopmentScore');
legend(ax, 'DevelopmentScore', 'Dice pn0', 'Dice pn3', 'Location', 'northwest');
title(ax, {'Phase 99 - retrospective ablation: development trajectory', ...
    'DEVELOPMENT ONLY (pn0 + pn3), each step a controlled single-block change; held-out not shown'});
fig.Position(3:4) = [1000 480];
exportgraphics(fig, fullfile(cfg.paths.figures, 'phase99_ablation_development_score.png'));


%% 6. Controlli finali

scriptCode = strjoin(regexprep(splitlines(string(fileread([mfilename('fullpath') '.m']))), '%.*$', ''), newline);
forbidden = {['loadBrainweb' 'Mri('], ['loadBrainweb' 'GroundTruth('], ['generateFinal' 'Prediction('], ...
    ['generateExp05' '7Prediction('], ['generateExp05' '8Prediction('], ['generateExp05' '9Prediction('], ...
    ['sa' 've('], ['p' 'n1'], ['p' 'n5'], ['p' 'n7'], ['p' 'n9'], ['EXP-0' '60']};
integrityAfter = integrityState(projectRoot, M);
finalConfigAfter = finalSegmentationConfig();
checks = [checks; {
    "12-15, 27, 33-34 no MRI / GT loading, no segmentation call, no MAT written, no held-out, no new experiment id", ...
        ~any(cellfun(@(f) contains(scriptCode, f), forbidden))
    "28-29, 45 primary still v3 / D3_M1_G0 (no new primary)", finalConfigAfter.version == "v3" && ...
        finalConfigAfter.sourceConfiguration == "D3_M1_G0"
    "30-32 summary, pairwise and trajectory CSVs written", isfile(fullfile(M, 'phase99_ablation_summary.csv')) && ...
        isfile(fullfile(M, 'phase99_ablation_pairwise.csv')) && isfile(fullfile(M, 'phase99_development_trajectory.csv'))
    "36-37 Phase-96 / 97 / 98 hashes still match AFTER the analysis", integrityAfter.ok && ...
        isequal(integrityBefore.hashes, integrityAfter.hashes)
    }];

for c = 1:size(checks, 1)
    if checks{c, 2}
        status = 'ok';
    else
        status = 'FAILED';
    end
    fprintf('%-100s %s\n', checks{c, 1}, status);
end
if any(~[checks{:, 2}])
    error('phase99:checksFailed', 'PHASE 99 TECHNICALLY BLOCKED: checks failed.');
end
fprintf('\nControlled one-factor comparisons: %d; trajectory transitions: %d (controlled %d)\n', height(pairwise), ...
    height(trajectory) - 1, nnz(trajectory.controlledSingleFactorChange));
fprintf('\nPHASE 99 CHECKS: PASS (%d)\n', size(checks, 1));


function r = rowOf(s, e, configId)
%ROWOF Metriche e descrittori di una configurazione salvata (ranking + grid).
    rk = s.ranking(s.ranking.configId == configId, :);
    g = s.grid(s.grid.configId == configId, :);
    g = [g(g.condition == "pn0", :); g(g.condition == "pn3", :)];
    if height(rk) ~= 1 || height(g) ~= 2
        error('phase99:missingSource', 'PHASE 99 TECHNICALLY BLOCKED: EXP-%s %s not found.', e, configId);
    end
    r = struct('experiment', "EXP-" + e, 'config', configId, 'dice', [rk.dicePn0 rk.dicePn3], ...
        'weaker', rk.weakerConditionDice, 'score', rk.developmentScore, 'tp', g.tpVoxels.', 'fp', g.fpVoxels.', ...
        'fn', g.fnVoxels.', 'predicted', g.predictedVoxels.', 'precision', g.precision.', 'recall', g.recall.', ...
        'blocks', blocksOf(e, g(1, :)));
    r.sourceConsistent = isequal(r.dice, g.dice.') && abs(r.score - (r.dice(1) + r.dice(2)) / 2) <= 1e-12 && ...
        r.weaker == min(r.dice) && all(r.tp + r.fp == r.predicted);
end

function b = blocksOf(e, g)
%BLOCKSOF Sette blocchi della configurazione: colonne del grid o valori fissati dalla preregistrazione.
    switch e
        case "056"   % EXP-056: supporto EXP-021 (S0), nessun recupero
            b = struct('support', "S0", 'threshold', "multithresh N=" + g.numberOfThresholds + " highest class", ...
                'filter', ternary(g.preprocessing == "none", "none", "gaussian T2"), ...
                'filterDim', ternary(g.preprocessing == "none", "none", "2D"), 'morphology', g.morphology, ...
                'componentRule', g.componentRule, 'recovery', "none");
        case "057"   % EXP-057: nessun filtro, nessun recupero
            b = struct('support', g.support, 'threshold', ternary(g.thresholdRule == "TA", ...
                "multithresh N=2 highest class", "graythresh"), 'filter', "none", 'filterDim', "none", ...
                'morphology', g.morphology, 'componentRule', g.componentRule, 'recovery', "none");
        case "058"   % EXP-058: pipeline v1 fissa (S2, TA, square 3, G1); variano filtro e recupero
            modalities = ["T1" "T2"];
            volumes = strjoin(modalities([g.filterT1 g.filterT2] == 1), "+");
            b = struct('support', "S2", 'threshold', "multithresh N=2 highest class", ...
                'filter', ternary(g.filterType == "none", "none", g.filterType + " " + volumes), ...
                'filterDim', ternary(g.filterType == "none", "none", "2D"), 'morphology', "square3", ...
                'componentRule', "minOccupiedSlices", 'recovery', ternary(g.recovery == "R0", "none", g.recovery));
        case "059"   % EXP-059: base v2 (S2, TA, diffusione anisotropa del T2); variano D, M, G
            b = struct('support', "S2", 'threshold', "multithresh N=2 highest class", 'filter', "anisotropic T2", ...
                'filterDim', ternary(g.diffusion == "D2", "2D", "3D"), 'morphology', g.morphology, ...
                'componentRule', g.componentRule, 'recovery', "none");
    end
end

function d = differingBlocks(a, b)
%DIFFERINGBLOCKS Nomi dei blocchi che differiscono tra due configurazioni.
%   La dimensionalità è un attributo del filtro: se cambia il filtro stesso
%   (per esempio nessuno -> anisotropo 2D) conta come un solo blocco, "filter".
    names = string(fieldnames(a.blocks)).';
    d = names(arrayfun(@(n) a.blocks.(n) ~= b.blocks.(n), names));
    if any(d == "filter")
        d(d == "filterDim") = [];
    end
end

function s = integrityState(root, M)
%INTEGRITYSTATE Verifica gli hash dei manifest delle fasi 96 e 97 e dell'inventario della fase 98.
    files = {fullfile(M, 'phase96_final_freeze_manifest.csv'), 26; fullfile(M, 'phase97_result_manifest.csv'), 27; ...
        fullfile(M, 'phase98_final_results_inventory.csv'), 32};
    s.ok = true; s.hashes = strings(0, 1);
    for i = 1:size(files, 1)
        t = readtable(files{i, 1}, 'TextType', 'string', 'Delimiter', ',');
        h = string(arrayfun(@(p) sha256File(fullfile(root, p)), t.path, 'UniformOutput', false));
        s.ok = s.ok && height(t) == files{i, 2} && all(h == t.sha256);
        s.hashes = [s.hashes; h; string(sha256File(files{i, 1}))];
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
    if ~isfile(f)
        error('phase99:fileNotReadable', 'Cannot read %s', f);
    end
    [status, out] = system(sprintf('certutil -hashfile "%s" SHA256', f));
    lines = erase(strtrim(splitlines(string(out))), " ");
    match = lines(strlength(lines) == 64 & ~cellfun(@isempty, regexp(cellstr(lines), '^[0-9a-fA-F]{64}$')));
    if status ~= 0 || numel(match) ~= 1
        error('phase99:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
