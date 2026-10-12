%% EXP-042 (fase 81): T2 mono-modale contro fusione T2 AND PD (EXP-041)
% Valutazione / selezione predichiarata (EXPERIMENT_LOG, EXP-042):
%   MONO  = M_pred della fase 71 (T2)
%   MULTI = EXP-041 (T2 AND PD), congelata nella fase 80 senza GT
%   Dice sull'intero volume, DevelopmentScore = media pn0/pn3, nessuna
%   tolleranza; MULTI > MONO -> trattenuta, altrimenti (anche pareggio
%   esatto) rifiutata. Diagnostica: TP/FP/FN e voxel rimossi dalla fusione.
% Nessun metodo viene rigenerato o modificato; GT caricato solo dopo i
% controlli di provenienza. Nessun dato held-out, config.m invariato.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
methods = ["T2" "T2+PD"];
expectedSize = [181 217 181];
fixedSlices = [46 91 102 136];
phase71File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));
phase78T2File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase78_t2_%s_selected_single_modality.mat', noise));
exp041File = @(noise) fullfile(cfg.paths.processedData, sprintf('exp041_t2_pd_%s_intersection_candidate.mat', noise));
aliasFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase81_%s_retained_prediction.mat', noise));
fusionSummaryFile = fullfile(cfg.paths.metrics, 'exp041_t2_pd_fusion_summary.csv');
checks = cell(0, 2);
gtLoaded = false;


%% 1. Provenienza e integrità (senza GT)

monoMasks = cell(1, 2); multiMasks = cell(1, 2);
fileInfoBefore = struct();
checks(end+1, :) = {"EXP-041 fusion summary exists", isfile(fusionSummaryFile)};
fusionSummary = readtable(fusionSummaryFile, 'TextType', 'string');
for n = 1:2
    noise = noiseLevels(n);
    checks = [checks; {
        "Phase-71 T2 " + noise + " M_pred exists",   isfile(phase71File(noise))
        "EXP-041 " + noise + " fused mask exists",   isfile(exp041File(noise))
        }]; %#ok<AGROW>
    if ~isfile(phase71File(noise)) || ~isfile(exp041File(noise))
        error('exp042:technicallyBlocked', 'PHASE 81 TECHNICALLY BLOCKED: missing source for %s.', noise);
    end
    m = load(phase71File(noise), 'M_pred');
    a = load(phase78T2File(noise), 'candidateMask');
    f = load(exp041File(noise), 'fusedCandidateMask', 'metadata');
    md = f.metadata;
    provenance = md.phase == 80 && md.experiment == "EXP-041" && md.condition == noise && ...
        md.primaryModality == "T2" && md.secondaryModality == "PD" && md.selectedCombination == "T2+PD" && ...
        md.fusionLevel == "binary decision-level" && md.fusionRule == "intersection" && ...
        md.fusionExpression == "T2 AND PD" && md.primarySelectedClass == 3 && md.secondarySelectedClass == 3 && ...
        ~md.gtUsed && ~md.performanceEvaluated && ~md.canonicalPipelineModified;
    monoMasks{n} = m.M_pred;
    multiMasks{n} = f.fusedCandidateMask;
    row = fusionSummary(fusionSummary.condition == noise, :);
    checks = [checks; {
        "EXP-041 " + noise + " metadata: phase 80, intersection, T2 AND PD, Class 3/3, gtUsed=false, not evaluated", provenance
        "masks " + noise + " logical 181x217x181",   islogical(monoMasks{n}) && islogical(multiMasks{n}) && ...
            isequal(size(monoMasks{n}), expectedSize) && isequal(size(multiMasks{n}), expectedSize)
        "Phase-78 T2 alias " + noise + " = Phase-71 M_pred", isequal(a.candidateMask, monoMasks{n})
        "fused " + noise + " subset of T2",          ~any(multiMasks{n} & ~monoMasks{n}, 'all')
        "structural counts " + noise + " = Phase-80 summary", height(row) == 1 && row.t2Voxels == nnz(monoMasks{n}) && ...
            row.fusedVoxels == nnz(multiMasks{n}) && row.t2OnlyVoxels == nnz(monoMasks{n} & ~multiMasks{n})
        }]; %#ok<AGROW>
    if ~provenance || ~isequal(a.candidateMask, monoMasks{n})
        error('exp042:technicallyBlocked', 'PHASE 81 TECHNICALLY BLOCKED: provenance mismatch for %s.', noise);
    end
    fileInfoBefore.(char("mono" + noise)) = dir(phase71File(noise));
    fileInfoBefore.(char("multi" + noise)) = dir(exp041File(noise));
end
monoCopies = monoMasks; multiCopies = multiMasks;
checks(end+1, :) = {"all prediction masks frozen before GT loading", ~gtLoaded};


%% 2. Valutazione (GT caricato SOLO ora)

gtLoaded = true;
labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;                           % GT completo, non intersecato con alcuna maschera
gtVoxels = nnz(gtMask);
gtCopy = gtMask;
checks(end+1, :) = {"GT = label 10, complete 181x217x181 volume, non-empty", ...
    isequal(size(gtMask), expectedSize) && isequal(gtMask, labels == 10) && gtVoxels > 0};

metricRows = cell(0, 8);
dice = zeros(2, 2);                              % metodo x condizione
counts = zeros(2, 2, 4);                         % metodo x condizione x (voxel, TP, FP, FN)
for mi = 1:2
    for n = 1:2
        if mi == 1
            mask = monoMasks{n};
        else
            mask = multiMasks{n};
        end
        tp = nnz(mask & gtMask); fp = nnz(mask & ~gtMask); fn = nnz(~mask & gtMask);
        dice(mi, n) = 2 * tp / (nnz(mask) + gtVoxels);
        counts(mi, n, :) = [nnz(mask) tp fp fn];
        checks(end+1, :) = {methods(mi) + " " + noiseLevels(n) + " TP+FN = GT voxels, full-volume Dice in [0,1]", ...
            tp + fn == gtVoxels && tp + fp == nnz(mask) && numel(mask) == prod(expectedSize) && ...
            dice(mi, n) >= 0 && dice(mi, n) <= 1}; %#ok<SAGROW>
        metricRows(end+1, :) = {methods(mi), noiseLevels(n), nnz(mask), gtVoxels, tp, fp, fn, dice(mi, n)}; %#ok<SAGROW>
    end
end
metrics = cell2table(metricRows, 'VariableNames', {'method', 'condition', 'predictedVoxels', 'gtVoxels', ...
    'tpVoxels', 'fpVoxels', 'fnVoxels', 'dice'});
writetable(metrics, fullfile(cfg.paths.metrics, 'exp042_mono_vs_multimodal_metrics.csv'));

% Voxel rimossi dalla fusione (solo diagnostica, nessuna modifica della regola)
removedRows = cell(2, 8);
for n = 1:2
    removedByFusion = monoMasks{n} & ~multiMasks{n};
    removedVoxels = nnz(removedByFusion);
    removedTP = nnz(removedByFusion & gtMask);
    removedFP = nnz(removedByFusion & ~gtMask);
    mono = squeeze(counts(1, n, :)); multi = squeeze(counts(2, n, :));
    checks = [checks; {
        noiseLevels(n) + ": removed = T2 AND NOT multimodal; removed = removedTP + removedFP", ...
            removedVoxels == mono(1) - multi(1) && removedVoxels == removedTP + removedFP
        noiseLevels(n) + ": multi TP = T2 TP - removedTP",   multi(2) == mono(2) - removedTP
        noiseLevels(n) + ": multi FP = T2 FP - removedFP",   multi(3) == mono(3) - removedFP
        noiseLevels(n) + ": multi FN = T2 FN + removedTP",   multi(4) == mono(4) + removedTP
        }]; %#ok<AGROW>
    if removedVoxels > 0
        tpFraction = removedTP / removedVoxels; fpFraction = removedFP / removedVoxels;
    else
        tpFraction = NaN; fpFraction = NaN;
    end
    removedRows(n, :) = {noiseLevels(n), mono(1), multi(1), removedVoxels, removedTP, removedFP, tpFraction, fpFraction};
end
removedTable = cell2table(removedRows, 'VariableNames', {'condition', 't2Voxels', 'multimodalVoxels', ...
    'removedVoxels', 'removedTP', 'removedFP', 'removedTPFraction', 'removedFPFraction'});
writetable(removedTable, fullfile(cfg.paths.metrics, 'exp042_fusion_removed_voxels.csv'));
if any(~[checks{:, 2}])
    error('exp042:inconsistent', 'EXP-042: confusion-count identities failed; investigate before any decision.');
end

% DevelopmentScore e regola predichiarata
developmentScore = (dice(:, 1) + dice(:, 2)) / 2;
weaker = min(dice, [], 2);
baselineScore = developmentScore(1);
candidateScore = developmentScore(2);
if candidateScore > baselineScore
    comparison = "GREATER";
    decision = "RETAIN_MULTIMODAL_FUSION";
    reason = "Candidate DevelopmentScore greater than baseline (predefined rule, no tolerance).";
    canonicalAfter = "EXP-041 T2 AND PD (development level, not frozen)";
elseif candidateScore < baselineScore
    comparison = "LOWER";
    decision = "REJECT_MULTIMODAL_FUSION";
    reason = "Candidate DevelopmentScore lower than baseline (predefined rule, no tolerance).";
    canonicalAfter = "Phase-71 T2 M_pred";
else
    comparison = "EXACTLY EQUAL";
    decision = "REJECT_MULTIMODAL_FUSION";
    reason = "Exact tie: the simpler single-modality T2 method is retained (predefined rule).";
    canonicalAfter = "Phase-71 T2 M_pred";
end
retain = decision == "RETAIN_MULTIMODAL_FUSION";

summary = table(methods.', dice(:, 1), dice(:, 2), weaker, developmentScore, ...
    ["single modality"; "two-modality decision-level fusion"], [~retain; retain], ...
    'VariableNames', {'method', 'dicePn0', 'dicePn3', 'weakerConditionDice', 'developmentScore', ...
    'complexityLevel', 'selected'});
writetable(summary, fullfile(cfg.paths.metrics, 'exp042_mono_vs_multimodal_summary.csv'));

deltaDicePn0 = dice(2, 1) - dice(1, 1);
deltaDicePn3 = dice(2, 2) - dice(1, 2);
deltaScore = candidateScore - baselineScore;
decisionTable = table("Phase-71 T2 M_pred", "EXP-041 T2 AND PD", baselineScore, candidateScore, ...
    deltaScore, deltaDicePn0, deltaDicePn3, comparison, decision, reason, canonicalAfter, ...
    'VariableNames', {'baselineMethod', 'candidateMethod', 'baselineDevelopmentScore', ...
    'candidateDevelopmentScore', 'deltaDevelopmentScore', 'deltaDicePn0', 'deltaDicePn3', ...
    'scoreComparison', 'decision', 'reason', 'canonicalMethodAfterPhase81'});
writetable(decisionTable, fullfile(cfg.paths.metrics, 'phase81_multimodal_decision.csv'));
checks = [checks; {
    "T2 DevelopmentScore = (pn0 + pn3)/2 exactly",          developmentScore(1) == (dice(1, 1) + dice(1, 2)) / 2
    "multimodal DevelopmentScore = (pn0 + pn3)/2 exactly",  developmentScore(2) == (dice(2, 1) + dice(2, 2)) / 2
    "decision from DevelopmentScore only; exact tie -> T2; no tolerance", ...
        retain == (candidateScore > baselineScore)
    }];

% Alias solo se la fusione vince (copie esatte di EXP-041)
if retain
    for n = 1:2
        frozen = load(exp041File(noiseLevels(n)), 'fusedCandidateMask', 'metadata');
        retainedPrediction = frozen.fusedCandidateMask;
        metadata = frozen.metadata;
        metadata.selectedBy = "Phase-81 DevelopmentScore comparison";
        metadata.finalPipelineFrozen = false;
        save(aliasFile(noiseLevels(n)), 'retainedPrediction', 'metadata');
        checks(end+1, :) = {noiseLevels(n) + " retained alias = EXP-041 exactly", ...
            isequal(retainedPrediction, multiMasks{n})}; %#ok<SAGROW>
    end
end

disp(metrics);
disp(removedTable);
disp(summary);
fprintf('deltaDice pn0 = %.6g, deltaDice pn3 = %.6g, deltaDevelopmentScore = %.6g (%s)\n', ...
    deltaDicePn0, deltaDicePn3, deltaScore, comparison);
fprintf('DECISION: %s  -> canonical development prediction: %s\n\n', decision, canonicalAfter);


%% 3. Figure (generate DOPO la valutazione della regola congelata; non la influenzano)

fig = figure('Color', 'w');
ax = axes(fig);
bar(ax, categorical(["Dice pn0" "Dice pn3" "DevelopmentScore"], ["Dice pn0" "Dice pn3" "DevelopmentScore"]), ...
    [dice(1, 1) dice(2, 1); dice(1, 2) dice(2, 2); developmentScore(1) developmentScore(2)]);
legend(ax, "T2 (Phase-71 M_pred)", "T2 AND PD (EXP-041)", 'Location', 'northwest', 'Interpreter', 'none');
ylabel(ax, 'full-volume Dice');
title(ax, sprintf('EXP-042 - mono vs multimodal (decision: %s)', decision), 'Interpreter', 'none');
grid(ax, 'on');
fig.Position(3:4) = [800 450];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp042_dice_comparison.png'));

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 3, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, {sprintf('EXP-042 %s - generated AFTER evaluating the frozen fusion rule (not used to change it)', ...
        noiseLevels(n)), 'cols 1-2: yellow TP, red FP, green FN', 'col 3: orange removed TP, blue removed FP, gray kept'}, ...
        'Interpreter', 'none');
    for k = fixedSlices
        monoSlice = monoMasks{n}(:, :, k).';
        multiSlice = multiMasks{n}(:, :, k).';
        gtSlice = gtMask(:, :, k).';
        ax = nexttile(layout);
        image(ax, errorRgb(monoSlice, gtSlice)); styleAxis(ax, sprintf('k=%d T2 (%d px)', k, nnz(monoSlice)));
        ax = nexttile(layout);
        image(ax, errorRgb(multiSlice, gtSlice)); styleAxis(ax, sprintf('k=%d T2 AND PD (%d px)', k, nnz(multiSlice)));
        ax = nexttile(layout);
        removedSlice = monoSlice & ~multiSlice;
        rgb = zeros([size(monoSlice) 3]);
        for c = 1:3
            channel = 0.5 * double(multiSlice);
            orange = [1 0.6 0]; blue = [0.2 0.4 1];
            channel(removedSlice & gtSlice) = orange(c);
            channel(removedSlice & ~gtSlice) = blue(c);
            rgb(:, :, c) = channel;
        end
        image(ax, rgb);
        styleAxis(ax, sprintf('k=%d removed: %d TP / %d FP', k, nnz(removedSlice & gtSlice), nnz(removedSlice & ~gtSlice)));
    end
    fig.Position(3:4) = [1000 1250];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp042_removed_voxels_%s.png', noiseLevels(n))), ...
        'Resolution', 130);
end


%% 4. Controlli finali

sourcesUnchanged = true;
for name = string(fieldnames(fileInfoBefore)).'
    before = fileInfoBefore.(char(name));
    after = dir(fullfile(before.folder, before.name));
    sourcesUnchanged = sourcesUnchanged && after.datenum == before.datenum && after.bytes == before.bytes;
end
scriptText = fileread([mfilename('fullpath') '.m']);
codeText = strjoin(regexprep(splitlines(string(scriptText)), '%.*$', ''), newline);
forbidden = {['loadBrainweb' 'Mri('], ['multi' 'thresh('], ['imquan' 'tize('], ['graythr' 'esh('], ...
    ['imbina' 'rize('], ['imo' 'pen('], ['imc' 'lose('], ['ime' 'rode('], ['imdi' 'late('], ['imf' 'ill('], ...
    ['bwconn' 'comp('], ['bwarea' 'open('], ['filterComponents' 'ByArea2D('], ['regionGrow' 'ing('], ...
    ['fuseCandidateMasks' 'Intersection(']};
laterMetrics = {['jacc' 'ard'], ['Jacc' 'ard'], ['IoU' ' ='], ['preci' 'sion'], ['Preci' 'sion'], ...
    ['reca' 'll'], ['Reca' 'll'], ['specif' 'icity'], ['Specif' 'icity'], ['tn' ' ='], ['volume' 'Error']};
altRules = {[' ' '| '], ['xo' 'r('], ['tole' 'rance =']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "GT unchanged",                                           isequal(gtMask, gtCopy)
    "Phase-71 and EXP-041 source masks unchanged",            sourcesUnchanged && isequal(monoMasks, monoCopies) && isequal(multiMasks, multiCopies)
    "no regeneration / alternative fusion / threshold / morphology / filtering / region growing", ...
        ~any(cellfun(@(f) contains(codeText, f), forbidden)) && ~any(cellfun(@(f) contains(codeText, f), altRules))
    "no later-phase metric (TN, overlap ratios, volume error)", ~any(cellfun(@(f) contains(codeText, f), laterMetrics))
    "no held-out condition referenced",                       ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "config.m unchanged",                                     isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-100s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp042:checksFailed', 'EXP-042 checks failed.');
end
fprintf('\nEXP-042 CHECKS: PASS (%d)\n', size(checks, 1));


function rgb = errorRgb(predSlice, gtSlice)
%ERRORRGB TP giallo, FP rosso, FN verde su sfondo nero (solo visualizzazione).
    tp = predSlice & gtSlice; fp = predSlice & ~gtSlice; fn = ~predSlice & gtSlice;
    rgb = cat(3, double(tp) + double(fp), double(tp) + double(fn), zeros(size(predSlice)));
end

function styleAxis(ax, label)
%STYLEAXIS Formato comune dei pannelli.
    axis(ax, 'image');
    set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
    title(ax, label, 'FontSize', 8);
end
