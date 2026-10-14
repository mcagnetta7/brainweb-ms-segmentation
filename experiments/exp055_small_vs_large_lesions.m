%% EXP-055 (fase 94): lesioni GT piccole contro grandi (diagnostica)
% LA SOGLIA DI DIMENSIONE È CALCOLATA DALLE DIMENSIONI DELLE COMPONENTI GT
% PRIMA CHE GLI ESITI DI RILEVAZIONE DELLA FASE 93 VENGANO USATI.
%   Sezione 1: GT -> componenti 3D (26) -> dimensioni -> mediana -> classi (congelate)
%   Sezione 2: lettura degli esiti della fase 93 (exp054_gt_lesion_status.csv)
%   Sezione 3: unione e analisi descrittiva
% SMALL = dimensione <= mediana, LARGE = > mediana (parità -> SMALL). Classi
% relative a questo dataset, non cliniche. La mediana è solo per la
% valutazione: non è mai una soglia di segmentazione o di filtro. Nessuna
% nuova corrispondenza, nessun filtro, nessun tuning.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
connectivity = 26;                               % definizione delle lesioni della fase 93
voxelVolumeMm3 = 1;                              % 1 x 1 x 1 mm (fase 26)
statusFile = fullfile(cfg.paths.metrics, 'exp054_gt_lesion_status.csv');
summary93File = fullfile(cfg.paths.metrics, 'exp054_lesion_wise_summary.csv');
phase91File = fullfile(cfg.paths.metrics, 'exp052_complete_3d_metrics.csv');
priorFiles = fullfile(cfg.paths.metrics, ["exp052_complete_3d_metrics.csv" "exp053_slice_wise_metrics.csv" ...
    "exp053_slice_diagnostic_summary.csv" "exp054_lesion_wise_summary.csv" "exp054_gt_lesion_status.csv" ...
    "exp054_predicted_component_status.csv" "exp054_lesion_matches.csv"]);
checks = cell(0, 2);

for f = priorFiles
    if ~isfile(f)
        error('exp055:technicallyBlocked', 'PHASE 94 TECHNICALLY BLOCKED: missing %s', f);
    end
end
priorBefore = arrayfun(@fileState, priorFiles, 'UniformOutput', false);
checks = [checks; {
    "EXP-054 GT-lesion-status artifact exists",      isfile(statusFile)
    "EXP-054 lesion-wise summary exists",            isfile(summary93File)
    "EXP-052 complete-volume artifact exists",       isfile(phase91File)
    }];


%% 1. Dimensioni delle lesioni GT e soglia (SENZA esiti di rilevazione)

labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
gtCopy = gtMask;
ccGt = bwconncomp(gtMask, connectivity);
gtLesionVoxels = cellfun(@numel, ccGt.PixelIdxList).';
gtUnion = false(expectedSize); gtUnion(vertcat(ccGt.PixelIdxList{:})) = true;

[sizeThresholdVoxels, sizeClass] = classifyGtLesionSizes(gtLesionVoxels);   % solo dimensioni GT
nLesions = numel(gtLesionVoxels);
sizeTable = table((1:nLesions).', gtLesionVoxels, gtLesionVoxels * voxelVolumeMm3, sizeClass, ...
    'VariableNames', {'gtLesionId', 'gtLesionVoxels', 'gtLesionVolumeMm3', 'sizeClass'});
statusReadBeforeThreshold = exist('status93', 'var') == 1;   % nessun esito letto finora
checks = [checks; {
    "GT loads successfully",                         ~isempty(labels)
    "GT = labels == 10, logical, 181x217x181",       isequal(gtMask, labels == 10) && islogical(gtMask) && isequal(size(gtMask), expectedSize)
    "connectivity fixed to 26",                      connectivity == 26 && ccGt.Connectivity == 26
    "every GT component contains >= 1 voxel",        all(gtLesionVoxels >= 1)
    "sum of GT component sizes = 3,512",             sum(gtLesionVoxels) == 3512 && sum(gtLesionVoxels) == nnz(gtMask)
    "GT component union reconstructs M_GT",          isequal(gtUnion, gtMask)
    "GT components mutually disjoint",               sum(gtLesionVoxels) == nnz(gtUnion)
    "median threshold computed only from GT component sizes", sizeThresholdVoxels == median(gtLesionVoxels)
    "threshold computed before detection status is used", ~statusReadBeforeThreshold
    "every lesion receives exactly one size class",  all(sizeClass == "SMALL" | sizeClass == "LARGE") && numel(sizeClass) == nLesions
    "SMALL iff voxels <= threshold, LARGE iff > threshold", isequal(sizeClass == "SMALL", gtLesionVoxels <= sizeThresholdVoxels) && ...
        isequal(sizeClass == "LARGE", gtLesionVoxels > sizeThresholdVoxels)
    "lesions equal to the threshold stay SMALL (no artificial split)", all(sizeClass(gtLesionVoxels == sizeThresholdVoxels) == "SMALL")
    }];
nSmall = nnz(sizeClass == "SMALL"); nLarge = nnz(sizeClass == "LARGE");
fprintf('GT lesions: %d; median size threshold = %g voxels = %g mm^3; SMALL (<= median) %d, LARGE (> median) %d\n', ...
    nLesions, sizeThresholdVoxels, sizeThresholdVoxels * voxelVolumeMm3, nSmall, nLarge);
for cls = ["SMALL" "LARGE"]
    v = gtLesionVoxels(sizeClass == cls);
    if ~isempty(v)
        fprintf('  %s: min %d, median %g, max %d voxels, total %d voxels\n', cls, min(v), median(v), max(v), sum(v));
    end
end
if nSmall == 0 || nLarge == 0
    error('exp055:technicallyBlocked', 'TECHNICALLY BLOCKED BY SIZE DISTRIBUTION: one size class is empty.');
end


%% 2. Esiti della fase 93 (letti SOLO ora, dopo il congelamento delle classi)

status93 = readtable(statusFile, 'TextType', 'string');
summary93 = readtable(summary93File, 'TextType', 'string');
phase91 = readtable(phase91File, 'TextType', 'string');
checks(end+1, :) = {"GT component count reproduces Phase 93", all(summary93.gtLesions == nLesions)};
rowsOk = true; idsOk = true;
for noise = noiseLevels
    s = status93(status93.condition == noise, :);
    rowsOk = rowsOk && height(s) == nLesions;
    idsOk = idsOk && isequal(sort(s.gtLesionId), (1:nLesions).');
end
checks = [checks; {
    "Phase-93 status: one row per GT lesion per condition", rowsOk
    "every gtLesionId maps to exactly one Phase-94 component", idsOk
    }];


%% 3. Unione e analisi

perLesion = table();
classRows = cell(0, 13);
for n = 1:2
    noise = noiseLevels(n);
    s = sortrows(status93(status93.condition == noise, :), 'gtLesionId');
    t = [sizeTable(:, {'gtLesionId', 'gtLesionVoxels', 'gtLesionVolumeMm3'}), ...
        table(repmat(sizeThresholdVoxels, nLesions, 1), sizeClass, 'VariableNames', {'sizeThresholdVoxels', 'sizeClass'}), ...
        s(:, {'isDetected', 'isMissed', 'matchedPredictionCount', 'totalOverlapVoxels'})];
    t.gtVoxelCoverageFraction = t.totalOverlapVoxels ./ t.gtLesionVoxels;
    t = addvars(t, repmat(noise, nLesions, 1), 'Before', 1, 'NewVariableNames', 'condition');
    perLesion = [perLesion; t]; %#ok<AGROW>
    p91 = phase91(phase91.condition == noise, :);
    checks = [checks; {
        noise + " isDetected / isMissed reproduce Phase 93", isequal(t.isDetected, s.isDetected) && isequal(t.isMissed, s.isMissed) && ...
            all(t.isDetected ~= t.isMissed)
        noise + " 0 <= totalOverlapVoxels <= GT lesion voxels", all(t.totalOverlapVoxels >= 0) && all(t.totalOverlapVoxels <= t.gtLesionVoxels)
        noise + " per-lesion GT voxel coverage in [0,1]", all(t.gtVoxelCoverageFraction >= 0 & t.gtVoxelCoverageFraction <= 1)
        noise + " missed lesions have zero coverage, detected lesions positive coverage", ...
            all(t.gtVoxelCoverageFraction(logical(t.isMissed)) == 0) && all(t.gtVoxelCoverageFraction(logical(t.isDetected)) > 0)
        noise + " summed lesion overlap = Phase-91 TP", sum(t.totalOverlapVoxels) == p91.tpVoxels
        }]; %#ok<AGROW>
    for cls = ["SMALL" "LARGE"]
        c = t(t.sizeClass == cls, :);
        detected = nnz(c.isDetected); missed = nnz(c.isMissed);
        totalGt = sum(c.gtLesionVoxels); recovered = sum(c.totalOverlapVoxels);
        classRows(end+1, :) = {noise, cls, sizeThresholdVoxels, height(c), detected, missed, detected / height(c), ...
            totalGt, recovered, recovered / totalGt, min(c.gtLesionVoxels), median(c.gtLesionVoxels), ...
            max(c.gtLesionVoxels)}; %#ok<AGROW>
        checks(end+1, :) = {noise + " " + cls + ": detected + missed = lesions, class coverage in [0,1]", ...
            detected + missed == height(c) && recovered / totalGt >= 0 && recovered / totalGt <= 1}; %#ok<AGROW>
    end
end
classSummary = cell2table(classRows, 'VariableNames', {'condition', 'sizeClass', 'sizeThresholdVoxels', 'lesionCount', ...
    'detectedLesions', 'missedLesions', 'detectionFraction', 'totalGtVoxels', 'recoveredGtVoxels', ...
    'gtVoxelCoverageFraction', 'minGtLesionVoxels', 'medianGtLesionVoxels', 'maxGtLesionVoxels'});
lesion0 = perLesion(perLesion.condition == "pn0", :); lesion3 = perLesion(perLesion.condition == "pn3", :);
checks(end+1, :) = {"pn0 and pn3 share identical lesion sizes and classes", ...
    isequal(lesion0.gtLesionVoxels, lesion3.gtLesionVoxels) && isequal(lesion0.sizeClass, lesion3.sizeClass) && ...
    isequal(lesion0.sizeThresholdVoxels, lesion3.sizeThresholdVoxels)};

crossRows = cell(2, 5);
for i = 1:2
    cls = ["SMALL" "LARGE"]; cls = cls(i);
    sel = lesion0.sizeClass == cls;
    d0 = logical(lesion0.isDetected(sel)); d3 = logical(lesion3.isDetected(sel));
    crossRows(i, :) = {cls, nnz(d0 & d3), nnz(d0 & ~d3), nnz(~d0 & d3), nnz(~d0 & ~d3)};
end
cross = cell2table(crossRows, 'VariableNames', {'sizeClass', 'detectedBoth', 'detectedOnlyPn0', 'detectedOnlyPn3', 'missedBoth'});

writetable(perLesion, fullfile(cfg.paths.metrics, 'exp055_gt_lesion_size_analysis.csv'));
writetable(classSummary, fullfile(cfg.paths.metrics, 'exp055_size_class_summary.csv'));
writetable(cross, fullfile(cfg.paths.metrics, 'exp055_size_cross_condition.csv'));
disp(classSummary);
disp(cross);


%% 4. Figure diagnostiche

fig = figure('Color', 'w');
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact');
for n = 1:2
    ax = nexttile(layout);
    c = classSummary(classSummary.condition == noiseLevels(n), :);
    bar(ax, categorical(c.sizeClass, ["SMALL" "LARGE"]), [c.detectedLesions c.missedLesions], 'stacked');
    legend(ax, 'detected (any overlap)', 'missed', 'Location', 'northeast');
    ylabel(ax, 'GT lesion count'); grid(ax, 'on');
    title(ax, sprintf('%s (SMALL <= %g voxels < LARGE)', noiseLevels(n), sizeThresholdVoxels));
end
title(layout, 'EXP-055 - GT lesions detected / missed by size class (diagnostic, dataset-relative classes)');
fig.Position(3:4) = [1000 420];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp055_small_large_detection_counts.png'));

fig = figure('Color', 'w');
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact');
for n = 1:2
    ax = nexttile(layout);
    t = perLesion(perLesion.condition == noiseLevels(n), :);
    det = logical(t.isDetected);
    semilogx(ax, t.gtLesionVoxels(det), t.gtVoxelCoverageFraction(det), 'bo', 'MarkerFaceColor', 'b');
    hold(ax, 'on');
    semilogx(ax, t.gtLesionVoxels(~det), t.gtVoxelCoverageFraction(~det), 'rx', 'LineWidth', 1.2);
    xline(ax, sizeThresholdVoxels, 'k--', 'median');
    hold(ax, 'off');
    ylim(ax, [-0.05 1.05]); grid(ax, 'on');
    xlabel(ax, 'GT lesion size (voxels = mm^3), log scale'); ylabel(ax, 'GT voxel coverage fraction');
    legend(ax, 'detected', 'missed', 'Location', 'northwest');
    title(ax, noiseLevels(n));
end
title(layout, 'EXP-055 - GT lesion size vs GT voxel coverage (diagnostic)');
fig.Position(3:4) = [1100 450];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp055_lesion_size_vs_gt_coverage.png'));


%% 5. Controlli finali

priorAfter = arrayfun(@fileState, priorFiles, 'UniformOutput', false);
scriptText = fileread([mfilename('fullpath') '.m']);
codeText = strjoin(regexprep(splitlines(string(scriptText)), '%.*$', ''), newline);
forbidden = {['computeLesion' 'WiseMatches('], ['M_' 'pred'], ['phase71' '_t2'], ['predicted' 'Volume'], ...
    ['bwarea' 'open('], ['filterComponents' 'ByArea'], ['region' 'props'], ['Dice' 'From'], ['IoU' 'From'], ...
    ['Precision' 'From'], ['Recall' 'From'], ['F' '1'], ['fit' 'lm('], ['poly' 'fit('], ['cor' 'r('], ...
    ['cor' 'rcoef('], ['tt' 'est'], ['multi' 'thresh('], ['imquan' 'tize('], ['imo' 'pen('], ['imc' 'lose('], ...
    ['ime' 'rode('], ['imdi' 'late('], ['save' '('], ['zCut' 'off']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
checks = [checks; {
    "no prediction loaded, no rematching, no predicted-component sizes or filtering, no lesion-wise metric, no model fitting, no segmentation", ...
        ~any(cellfun(@(f) contains(codeText, f), forbidden))
    "no held-out condition referenced",              ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "prior Phase-91 / 92 / 93 artifacts unchanged",  isequal(priorBefore, priorAfter)
    "GT unchanged",                                  isequal(gtMask, gtCopy)
    "config.m unchanged",                            isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
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
    error('exp055:checksFailed', 'EXP-055 checks failed.');
end
fprintf('\nEXP-055 CHECKS: PASS (%d)\n', size(checks, 1));


function state = fileState(f)
%FILESTATE Data, dimensione e contenuto di un file (verifica di immutabilità).
    info = dir(f);
    state = {info.datenum, info.bytes, fileread(f)};
end
