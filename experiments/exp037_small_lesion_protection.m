%% EXP-037 (fase 70): audit di protezione delle piccole lesioni del filtro Area-9
% Confronta due previsioni GIÀ congelate: PRIMA = maschere della fase 65
% (apertura square3), DOPO = maschere filtrate EXP-036 (rimozione Area == 9).
%   - nessuna nuova previsione, nessun filtro, nessuna soglia nuova
%   - GT (label 10) scomposto in componenti 2D con connettività 8 SOLO per
%     la valutazione (src/evaluation/auditSmallLesionProtection2D.m)
%   - vincolo preregistrato: nessuna componente GT 2D con supporto prima e
%     supporto nullo dopo, in pn0 E pn3; altrimenti il filtro è respinto
%   - nessuna soglia di "piccola lesione": l'area GT è descrittiva
%   - componente GT 2D != lesione 3D; non è la valutazione finale per lesione.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

connectivity = 8;
noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
fixedSlices = [46 91 102 136];
beforeFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase65_t2_%s_selected_opening_candidate.mat', noise));
afterFile = @(noise) fullfile(cfg.paths.processedData, sprintf('exp036_t2_%s_area9_filtered_candidate.mat', noise));

checks = {"GT evaluation connectivity fixed to 8", connectivity == 8};
befores = cell(1, 2); afters = cell(1, 2); volumes = cell(1, 2);


%% 1. Previsioni congelate

for n = 1:2
    noise = noiseLevels(n);
    exists = isfile(beforeFile(noise)) && isfile(afterFile(noise));
    checks(end+1, :) = {noise + " Phase-65 and EXP-036 masks exist", exists}; %#ok<SAGROW>
    if ~exists
        error('exp037:technicallyBlocked', 'EXP-037 TECHNICALLY BLOCKED: missing input for %s.', noise);
    end
    b = load(beforeFile(noise), 'candidateMask', 'metadata');
    a = load(afterFile(noise), 'candidateMask', 'metadata');
    mb = b.metadata; ma = a.metadata;
    inputChecks = {
        noise + " BEFORE logical 181x217x181, Phase 65 / EXP-032 / EXP-026 / square3", islogical(b.candidateMask) && ...
            isequal(size(b.candidateMask), expectedSize) && mb.phase == 65 && mb.sourceExperiment == "EXP-032" && ...
            mb.candidateGenerationSource == "EXP-026" && mb.selectedStructuringElementCandidate == "square3"
        noise + " AFTER logical 181x217x181, EXP-036 Area == 9 rule",  islogical(a.candidateMask) && ...
            isequal(size(a.candidateMask), expectedSize) && ma.phase == 69 && ma.experiment == "EXP-036" && ...
            ma.filterRule == "remove Area == 9" && ma.retentionRule == "Area > 9" && ma.areaThresholdPixels == 9 && ...
            ma.connectivity == 8 && ~ma.gtUsedForGeneration && ma.componentFilteringApplied && ~ma.finalPipelineFrozen
        noise + " AFTER subset of BEFORE (no added voxel)",   ~any(a.candidateMask & ~b.candidateMask, 'all')
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('exp037:technicallyBlocked', 'EXP-037 TECHNICALLY BLOCKED: invalid frozen masks for %s.', noise);
    end
    befores{n} = b.candidateMask;
    afters{n} = a.candidateMask;
    volumes{n} = prepare(loadBrainwebMri(cfg, "T2", noise));      % solo per le figure
end
beforeCopies = befores; afterCopies = afters;


%% 2. GT e audit (solo valutazione)

labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
gtVoxels = nnz(gtMask);
gtCopy = gtMask;
checks(end+1, :) = {"GT = label 10, logical, 181x217x181, non-empty", islogical(gtMask) && ...
    isequal(size(gtMask), expectedSize) && isequal(gtMask, labels == 10) && gtVoxels > 0};

exp036 = readtable(fullfile(cfg.paths.metrics, 'exp036_area9_filter_change_summary.csv'), 'TextType', 'string');
exp036dev = readtable(fullfile(cfg.paths.metrics, 'exp036_area9_filter_development_summary.csv'), 'TextType', 'string');

audits = cell(1, 2);
summaryRows = cell(2, 1);
dice = zeros(2, 2);
statsOf = @(v) ifEmpty(v);
for n = 1:2
    noise = noiseLevels(n);
    b = befores{n}; a = afters{n};
    t = auditSmallLesionProtection2D(gtMask, b, a, connectivity, noise);
    tpBefore = nnz(b & gtMask); tpAfter = nnz(a & gtMask);
    removedTP = nnz(b & ~a & gtMask);
    dice(n, :) = [2 * tpBefore / (nnz(b) + gtVoxels), 2 * tpAfter / (nnz(a) + gtVoxels)];
    ref = exp036(exp036.condition == noise, :);

    partial = t.affectedByFilter & t.hasSupportAfter;
    lost = t.newlyCompletelyLost;
    catA = ~t.hadSupportBefore & ~t.hasSupportAfter;
    catB = t.hadSupportBefore & ~t.affectedByFilter;
    catE = ~t.hadSupportBefore & t.hasSupportAfter;
    checks = [checks; {
        noise + " one row per GT 2D component, Area = PixelIdxList",  height(t) >= 1 && sum(t.gtAreaPixels) == gtVoxels
        noise + " overlapAfter <= overlapBefore everywhere",          all(t.overlapAfter <= t.overlapBefore)
        noise + " removed / coverage / change formulas",              all(t.removedOverlap == t.overlapBefore - t.overlapAfter) && ...
            all(abs(t.coverageBefore - t.overlapBefore ./ t.gtAreaPixels) < 1e-12) && ...
            all(abs(t.coverageAfter - t.overlapAfter ./ t.gtAreaPixels) < 1e-12) && ...
            all(abs(t.coverageChange - (t.coverageAfter - t.coverageBefore)) < 1e-12)
        noise + " newlyCompletelyLost iff before > 0 and after == 0", isequal(lost, t.overlapBefore > 0 & t.overlapAfter == 0)
        noise + " category E (before 0, after > 0) = 0",              nnz(catE) == 0
        noise + " categories A+B+C+D cover all components",           nnz(catA) + nnz(catB) + nnz(partial) + nnz(lost) == height(t)
        noise + " sum overlapBefore = TP before",                     sum(t.overlapBefore) == tpBefore
        noise + " sum overlapAfter = TP after",                       sum(t.overlapAfter) == tpAfter
        noise + " sum removedOverlap = removedTP = EXP-036",          sum(t.removedOverlap) == removedTP && removedTP == ref.removedTP
        noise + " TP before/after reproduce EXP-036",                 tpBefore == ref.unfilteredTP && tpAfter == ref.filteredTP
        }]; %#ok<AGROW>

    affectedArea = statsOf(t.gtAreaPixels(t.affectedByFilter));
    lostArea = statsOf(t.gtAreaPixels(lost));
    summaryRows{n} = [{noise, height(t), nnz(t.hadSupportBefore), nnz(t.hasSupportAfter), nnz(t.affectedByFilter), ...
        nnz(partial), nnz(lost), gtVoxels, tpBefore, tpAfter, removedTP, tpAfter / tpBefore}, ...
        num2cell(affectedArea), num2cell(lostArea)];
    audits{n} = t;

    groups = {t.gtAreaPixels, t.gtAreaPixels(t.hadSupportBefore), t.gtAreaPixels(t.affectedByFilter), ...
        t.gtAreaPixels(partial), t.gtAreaPixels(lost)};
    groupNames = ["all", "support before", "affected", "partially reduced", "completely lost"];
    for g = 1:5
        s = statsOf(groups{g});
        fprintf('%s GT Area [%s]: n = %d, min / median / mean / max = %g / %g / %.2f / %g\n', noise, ...
            groupNames(g), numel(groups{g}), s(1), s(2), s(3), s(4));
    end
end
fprintf('\n');
summary = cell2table(vertcat(summaryRows{:}), 'VariableNames', {'condition', 'totalGT2DComponents', ...
    'gtComponentsWithSupportBefore', 'gtComponentsWithSupportAfter', 'gtComponentsAffectedByFilter', ...
    'gtComponentsPartiallyReduced', 'gtComponentsNewlyCompletelyLost', 'gtVoxels', 'tpBefore', 'tpAfter', ...
    'removedTP', 'fractionBeforeTPRetained', 'minAffectedGTArea', 'medianAffectedGTArea', 'meanAffectedGTArea', ...
    'maxAffectedGTArea', 'minCompletelyLostGTArea', 'medianCompletelyLostGTArea', 'meanCompletelyLostGTArea', ...
    'maxCompletelyLostGTArea'});
allAudits = [audits{1}; audits{2}];
writetable(allAudits, fullfile(cfg.paths.metrics, 'exp037_small_lesion_component_audit.csv'));
writetable(summary, fullfile(cfg.paths.metrics, 'exp037_small_lesion_protection_summary.csv'));

% Riproduzione del punteggio e decisione preregistrata
scoreBefore = (dice(1, 1) + dice(2, 1)) / 2;
scoreAfter = (dice(1, 2) + dice(2, 2)) / 2;
refBefore = exp036dev(exp036dev.stage == "unfiltered", :);
refAfter = exp036dev(exp036dev.stage == "area9_filtered", :);
checks = [checks; {
    "unfiltered Dice reproduces EXP-036",   abs(dice(1, 1) - refBefore.dicePn0) < 1e-12 && abs(dice(2, 1) - refBefore.dicePn3) < 1e-12
    "filtered Dice reproduces EXP-036",     abs(dice(1, 2) - refAfter.dicePn0) < 1e-12 && abs(dice(2, 2) - refAfter.dicePn3) < 1e-12
    "DevelopmentScores reproduce EXP-036",  abs(scoreBefore - refBefore.developmentScore) < 1e-12 && ...
                                            abs(scoreAfter - refAfter.developmentScore) < 1e-12
    }];
developmentImproved = scoreAfter > scoreBefore;
lostPn0 = summary.gtComponentsNewlyCompletelyLost(1);
lostPn3 = summary.gtComponentsNewlyCompletelyLost(2);
protectionPassed = lostPn0 == 0 && lostPn3 == 0;
if developmentImproved && protectionPassed
    phase70Decision = "RETAIN_AREA9_FILTER";
else
    phase70Decision = "REJECT_AREA9_FILTER";
end
decision = table(scoreBefore, scoreAfter, scoreAfter - scoreBefore, lostPn0, lostPn3, developmentImproved, ...
    protectionPassed, phase70Decision, 'VariableNames', {'unfilteredDevelopmentScore', 'filteredDevelopmentScore', ...
    'deltaDevelopmentScore', 'newlyCompletelyLostPn0', 'newlyCompletelyLostPn3', 'developmentImproved', ...
    'smallLesionProtectionPassed', 'phase70Decision'});
writetable(decision, fullfile(cfg.paths.metrics, 'exp037_phase70_decision.csv'));
disp(summary(:, 1:12));
disp(decision);
fprintf('PHASE-70 DECISION: %s\n\n', phase70Decision);


%% 3. Figure

for n = 1:2
    t = audits{n};
    supported = t(t.hadSupportBefore, :);
    fig = figure('Color', 'w');
    ax = axes(fig);
    hold(ax, 'on');
    plot(ax, supported.gtAreaPixels(~supported.affectedByFilter), supported.coverageChange(~supported.affectedByFilter), ...
        'k.', 'MarkerSize', 6);
    p = supported.affectedByFilter & supported.hasSupportAfter;
    plot(ax, supported.gtAreaPixels(p), supported.coverageChange(p), 'bo', 'MarkerSize', 5);
    l = supported.newlyCompletelyLost;
    plot(ax, supported.gtAreaPixels(l), supported.coverageChange(l), 'rx', 'MarkerSize', 8, 'LineWidth', 1.2);
    hold(ax, 'off');
    set(ax, 'XScale', 'log');
    xlabel(ax, 'GT 2D component Area (pixels, log scale)');
    ylabel(ax, 'coverage change (after - before)');
    legend(ax, 'unaffected', 'partially reduced', 'completely lost', 'Location', 'southeast');
    title(ax, sprintf('EXP-037 %s - GT 2D components with support before filtering (descriptive)', noiseLevels(n)));
    grid(ax, 'on');
    fig.Position(3:4) = [900 500];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp037_gt_area_vs_coverage_change_%s.png', noiseLevels(n))));
end

fig = figure('Color', 'w');
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact');
title(layout, 'EXP-037 - Area of affected GT 2D components, sorted (descriptive, no cutoff)');
for n = 1:2
    t = audits{n};
    affected = sortrows(t(t.affectedByFilter, :), 'gtAreaPixels');
    ax = nexttile(layout);
    hold(ax, 'on');
    r = (1:height(affected)).';
    plot(ax, r(~affected.newlyCompletelyLost), affected.gtAreaPixels(~affected.newlyCompletelyLost), 'bo');
    plot(ax, r(affected.newlyCompletelyLost), affected.gtAreaPixels(affected.newlyCompletelyLost), 'rx', ...
        'MarkerSize', 8, 'LineWidth', 1.2);
    hold(ax, 'off');
    set(ax, 'YScale', 'log');
    xlabel(ax, 'rank'); ylabel(ax, 'GT Area (pixels)');
    legend(ax, 'partially reduced', 'completely lost', 'Location', 'northwest');
    title(ax, noiseLevels(n)); grid(ax, 'on');
end
fig.Position(3:4) = [1100 450];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp037_affected_gt_area_rank.png'));

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 5, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, {sprintf('EXP-037 T2 %s - T2 / GT / unfiltered / Area-9 filtered / removed lesion voxels (orange)', ...
        noiseLevels(n)), 'fixed slices only; complete-loss cases elsewhere are listed in the audit table'}, ...
        'Interpreter', 'none');
    for k = fixedSlices
        v = volumes{n}(:, :, k);
        panels = {overlay(v, false(expectedSize(1:2)), [1 0 0]), overlay(v, gtMask(:, :, k), [0 1 0]), ...
            overlay(v, befores{n}(:, :, k), [1 0 0]), overlay(v, afters{n}(:, :, k), [1 0 0]), ...
            overlay(v, befores{n}(:, :, k) & ~afters{n}(:, :, k) & gtMask(:, :, k), [1 0.6 0])};
        names = ["T2", "GT", "unfiltered", "filtered", "removed TP"];
        for p = 1:5
            ax = nexttile(layout);
            image(ax, panels{p});
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('k=%d %s', k, names(p)), 'FontSize', 7);
        end
    end
    fig.Position(3:4) = [1500 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp037_fixed_slice_audit_%s.png', noiseLevels(n))), ...
        'Resolution', 130);
end


%% Esito dei controlli

checks = [checks; {
    "BEFORE / AFTER masks unchanged",   isequal(befores, beforeCopies) && isequal(afters, afterCopies)
    "GT unchanged, same for pn0 and pn3", isequal(gtMask, gtCopy)
    "config.m unchanged",              isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];
scriptText = fileread([mfilename('fullpath') '.m']);
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['filterComponents' 'ByArea2D('], ['bwconn' 'comp('], ['region' 'props'], ['bwarea' 'open('], ...
    ['imopen' '('], ['imclose' '('], ['imerode' '('], ['imdilate' '('], ['multi' 'thresh('], ['imquantize' '('], ...
    ['save' '(']};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};
checks(end+1, :) = {"no new prediction / filter / CC / morphology / threshold / save", ...
    ~any(cellfun(@(f) contains(scriptText, f), forbidden))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-72s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp037:checksFailed', 'EXP-037 checks failed.');
end
fprintf('\nEXP-037 CHECKS: PASS (%d)\n', size(checks, 1));


function s = ifEmpty(v)
%IFEMPTY [min mediana media max] di un vettore; NaN se vuoto.
    if isempty(v)
        s = [NaN NaN NaN NaN];
    else
        s = [min(v) median(v) mean(v) max(v)];
    end
end

function rgb = overlay(sliceImage, maskSlice, colour)
%OVERLAY T2 in scala di grigi con la maschera nel colore indicato (solo visualizzazione).
    gray = sliceImage.';
    m = maskSlice.';
    red = gray; green = gray; blue = gray;
    red(m) = colour(1); green(m) = colour(2); blue(m) = colour(3);
    rgb = cat(3, red, green, blue);
end
