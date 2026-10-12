%% Fase 79: scelta della combinazione di modalità (decisione, nessun ID esperimento)
% Legge SOLO i risultati salvati di EXP-040 (fase 78) e applica la regola
% predichiarata in EXPERIMENT_LOG (Phase 79):
%   primaria   = modalità di rango 1;
%   secondaria = modalità di rango 2, se ha anche più TP della candidata
%                rimanente sia in pn0 sia in pn3; altrimenti nessuna scelta
%                automatica (decisione dell'utente).
% Nessuna MRI, nessun GT, nessuna soglia, nessuna morfologia, nessuna
% fusione, nessun Dice multimodale. Le maschere T2 classe 3 / M_pred sono
% caricate solo per verificarne l'identità (fase 78).

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
noiseLevels = ["pn0" "pn3"];
metricsDir = cfg.paths.metrics;
candidateFile = fullfile(metricsDir, 'exp040_single_modality_candidate_metrics.csv');
developmentFile = fullfile(metricsDir, 'exp040_single_modality_development_summary.csv');
modalityFile = fullfile(metricsDir, 'exp040_modality_summary.csv');
phase71File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));
exp040T2File = @(noise) fullfile(cfg.paths.processedData, sprintf('exp040_t2_%s_class3_opened_candidate.mat', noise));
checks = cell(0, 2);


%% 1. Evidenza della fase 78

checks = [checks; {
    "EXP-040 candidate metrics CSV exists",   isfile(candidateFile)
    "EXP-040 development summary CSV exists", isfile(developmentFile)
    "EXP-040 modality summary CSV exists",    isfile(modalityFile)
    }];
candidates = readtable(candidateFile, 'TextType', 'string');
development = readtable(developmentFile, 'TextType', 'string');
modSummary = readtable(modalityFile, 'TextType', 'string');

checks(end+1, :) = {"all three modalities present (T1, T2, PD)", ...
    isequal(sort(modSummary.modality).', sort(["T1" "T2" "PD"])) && height(modSummary) == 3};
for m = ["T1" "T2" "PD"]
    row = modSummary(modSummary.modality == m, :);
    selectedInDev = development(all([development.modality == m, development.selectedWithinModality == 1], 2), :);
    checks(end+1, :) = {"selected class exists for " + m, height(row) == 1 && ...
        height(selectedInDev) == 1 && selectedInDev.candidateClass == row.selectedClass}; %#ok<SAGROW>
end
checks(end+1, :) = {"no unresolved exact tie", ~any(modSummary.unresolvedExactTie)};

% Ricalcolo dai valori per classe (riproduzione del riepilogo)
reproduced = true;
for r = 1:height(modSummary)
    m = modSummary.modality(r);
    c = modSummary.selectedClass(r);
    rowsPn0 = candidates(all([candidates.modality == m, candidates.candidateClass == c, candidates.condition == "pn0"], 2), :);
    rowsPn3 = candidates(all([candidates.modality == m, candidates.candidateClass == c, candidates.condition == "pn3"], 2), :);
    reproduced = reproduced && height(rowsPn0) == 1 && height(rowsPn3) == 1 && ...
        rowsPn0.dice == modSummary.dicePn0(r) && rowsPn3.dice == modSummary.dicePn3(r) && ...
        abs((rowsPn0.dice + rowsPn3.dice) / 2 - modSummary.developmentScore(r)) < 1e-15 && ...
        rowsPn0.tpVoxels == modSummary.tpPn0(r) && rowsPn3.tpVoxels == modSummary.tpPn3(r) && ...
        rowsPn0.fpVoxels == modSummary.fpPn0(r) && rowsPn3.fpVoxels == modSummary.fpPn3(r) && ...
        rowsPn0.fnVoxels == modSummary.fnPn0(r) && rowsPn3.fnVoxels == modSummary.fnPn3(r);
end
checks(end+1, :) = {"modality summary reproduced from the candidate metrics CSV", reproduced};

rowOf = @(m) modSummary(modSummary.modality == m, :);
t1 = rowOf("T1"); t2 = rowOf("T2"); pd = rowOf("PD");
checks = [checks; {
    "T2 individual rank = 1",                   t2.individualModalityRank == 1
    "PD individual rank = 2",                   pd.individualModalityRank == 2
    "T1 individual rank = 3",                   t1.individualModalityRank == 3
    "T2 has the highest DevelopmentScore",      t2.developmentScore > max(pd.developmentScore, t1.developmentScore)
    "PD DevelopmentScore > T1 DevelopmentScore", pd.developmentScore > t1.developmentScore
    }];

% Identità T2 classe 3 = M_pred (fase 71), solo verifica
identical = true;
mpredInfoBefore = cell(1, 2);
for n = 1:2
    mpredInfoBefore{n} = dir(phase71File(noiseLevels(n)));
    a = load(exp040T2File(noiseLevels(n)), 'candidateMask');
    b = load(phase71File(noiseLevels(n)), 'M_pred');
    identical = identical && isequal(a.candidateMask, b.M_pred);
end
checks(end+1, :) = {"Phase-78 T2 Class 3 reproduces Phase-71 M_pred (pn0, pn3)", identical};


%% 2. Regola predichiarata

primary = modSummary.modality(modSummary.individualModalityRank == 1);
second = modSummary(modSummary.individualModalityRank == 2, :);
third = modSummary(modSummary.individualModalityRank == 3, :);
tpSupport = second.tpPn0 > third.tpPn0 && second.tpPn3 > third.tpPn3;
if tpSupport
    secondary = second.modality;
    decisionStatus = "SELECTED";
else
    secondary = "";
    decisionStatus = "UNRESOLVED_USER_DECISION_REQUIRED";
end

role = strings(3, 1);
reason = strings(3, 1);
selectedFlag = false(3, 1);
order = sortrows(modSummary, 'individualModalityRank');
for r = 1:3
    m = order.modality(r);
    if m == primary
        role(r) = "primary";
        selectedFlag(r) = true;
        reason(r) = "Primary/anchor: individual rank 1, highest DevelopmentScore by a large margin; " + ...
            "current retained segmentation modality (Phase-71 M_pred).";
    elseif m == secondary
        role(r) = "secondary";
        selectedFlag(r) = true;
        reason(r) = "Secondary (rank 2): higher DevelopmentScore than " + third.modality + " and more TP in " + ...
            "both conditions; poor standalone specificity (very large FP burden) and large pn0/pn3 variation.";
    elseif m == second.modality
        role(r) = "unresolved";
        reason(r) = "Rank 2, but the TP-support condition fails: user decision required.";
    else
        role(r) = "not selected for first multimodal pair";
        reason(r) = "Rank 3: lowest DevelopmentScore and fewer TP than " + second.modality + " in both " + ...
            "conditions; very broad candidates. Not discarded from the project.";
    end
end
decision = table(repmat(primary, 3, 1), order.modality, role, order.individualModalityRank, order.selectedClass, ...
    order.developmentScore, order.dicePn0, order.dicePn3, order.tpPn0, order.fpPn0, order.fnPn0, ...
    order.tpPn3, order.fpPn3, order.fnPn3, selectedFlag, reason, ...
    'VariableNames', {'primaryModality', 'modality', 'role', 'individualRank', 'selectedClass', ...
    'developmentScore', 'dicePn0', 'dicePn3', 'tpPn0', 'fpPn0', 'fnPn0', 'tpPn3', 'fpPn3', 'fnPn3', ...
    'selectedForMultimodalPair', 'reason'});
writetable(decision, fullfile(metricsDir, 'phase79_modality_combination_decision.csv'));

if tpSupport
    combination = primary + "+" + secondary;
else
    combination = "";
end
selectedCombination = table(primary, secondary, combination, decisionStatus, ...
    "Primary = individual rank 1; secondary = rank 2 with more TP than the rank-3 modality in pn0 and pn3 (pre-registered Phase-79 rule). Complementarity not yet tested.", ...
    false, false, 'VariableNames', {'primaryModality', 'secondaryModality', 'selectedCombination', ...
    'decisionStatus', 'decisionReason', 'fusionRuleDefined', 'multimodalPredictionGenerated'});
writetable(selectedCombination, fullfile(metricsDir, 'phase79_selected_combination.csv'));

disp(decision(:, 1:15));
disp(selectedCombination);
fprintf('SELECTED PAIR: %s  (status %s)\n\n', combination, decisionStatus);


%% 3. Controlli

mpredUnchanged = true;
for n = 1:2
    after = dir(phase71File(noiseLevels(n)));
    mpredUnchanged = mpredUnchanged && after.datenum == mpredInfoBefore{n}.datenum && after.bytes == mpredInfoBefore{n}.bytes;
end
scriptText = fileread([mfilename('fullpath') '.m']);
codeText = strjoin(regexprep(splitlines(string(scriptText)), '%.*$', ''), newline);
forbidden = {['multi' 'thresh('], ['imquan' 'tize('], ['imo' 'pen('], ['imc' 'lose('], ['ime' 'rode('], ...
    ['imdi' 'late('], ['bwconn' 'comp('], ['filterComponents' 'ByArea2D('], ['regionGrow' 'ing('], ...
    ['loadBrainweb' 'Mri('], ['loadBrainweb' 'GroundTruth('], ['graythr' 'esh('], ['save' '(']};
fusionOps = {[' ' '& '], [' ' '| '], ['an' 'd('], [' o' 'r('], ['xo' 'r(']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
segFields = isfield(cfg, 'segmentation') && cfg.segmentation.thresholdMethod == "multithresh" && ...
    cfg.segmentation.multithresh.numberOfThresholds == 2 && cfg.segmentation.multithresh.candidateClass == 3 && ...
    isequal(sort(string(fieldnames(cfg.segmentation))).', ["multithresh" "thresholdMethod"]);
checks = [checks; {
    "no MRI / GT loaded, no threshold, morphology, components, region growing, mask saved", ...
        ~any(cellfun(@(f) contains(codeText, f), forbidden))
    "no logical AND / OR / XOR between masks (no fusion mask)", ~any(cellfun(@(f) contains(codeText, f), fusionOps))
    "no multimodal score with coefficients (rank + TP comparison only)", ~contains(codeText, ['wei' 'ght'])
    "no multimodal Dice computed",               ~contains(codeText, ['2 *' ' tp'])
    "no held-out condition referenced",          ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "Phase-71 M_pred files unchanged",           mpredUnchanged
    "config.m: no fusion field, segmentation parameters unchanged", ~isfield(cfg, 'fusion') && ~isfield(cfg, 'multimodal') && segFields
    "selected pair explicitly recorded",         isfile(fullfile(metricsDir, 'phase79_selected_combination.csv')) && strlength(combination) > 0
    "fusion rule remains undefined, no multimodal prediction", ~selectedCombination.fusionRuleDefined && ~selectedCombination.multimodalPredictionGenerated
    }];

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-74s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase79:checksFailed', 'Phase-79 checks failed.');
end
fprintf('\nPHASE-79 CHECKS: PASS (%d)\n', size(checks, 1));
