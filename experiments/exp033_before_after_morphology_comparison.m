%% EXP-033 (fase 66): confronto formale prima / dopo la morfologia
% Confronto sul development set tra due artefatti GIÀ congelati:
%   PRIMA = candidateMask canonica della fase 60 (EXP-026)
%   DOPO  = maschere selezionate della fase 65 (apertura standard,
%           strel('square', 3), 2D slice per slice; vincitore di EXP-032)
%   - nessuna maschera viene rigenerata o salvata; nessuna morfologia,
%     componente connessa o soglia viene chiamata
%   - il GT (label 10) serve solo a valutare le due maschere congelate
%   - regola (preregistrata, senza tolleranza): se il DevelopmentScore DOPO
%     supera quello PRIMA, il blocco morfologico è mantenuto per lo sviluppo
%     successivo (non è un congelamento della pipeline)
%   - pn0 e pn3 hanno già scelto l'SE nella fase 65: NON è una validazione
%     indipendente; solo pn0 + pn3.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
stages = ["before_morphology" "after_morphology"];
expectedSize = [181 217 181];
nSlices = expectedSize(3);
fixedSlices = [46 91 102 136];
beforeFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase60_t2_%s_candidate_mask.mat', noise));
afterFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase65_t2_%s_selected_opening_candidate.mat', noise));
winnerFile = @(noise) fullfile(cfg.paths.processedData, sprintf('exp032_t2_%s_opening_square3_candidate.mat', noise));
exp030File = @(noise) fullfile(cfg.paths.processedData, sprintf('exp030_t2_%s_opened_square3_candidate.mat', noise));
phase60Summary = readtable(fullfile(cfg.paths.metrics, 'phase60_candidate_mask_summary.csv'), 'TextType', 'string');

checks = cell(0, 2);
masks = cell(2, 2);                              % condizione x (prima, dopo)
copies = cell(2, 2);
volumes = cell(1, 2);
afterSE = strings(1, 2);


%% 1. Maschere congelate (prima del GT)

for n = 1:2
    noise = noiseLevels(n);
    files = {beforeFile(noise), afterFile(noise), winnerFile(noise), exp030File(noise)};
    exists = cellfun(@isfile, files);
    checks(end+1, :) = {noise + " BEFORE / AFTER / EXP-032 / EXP-030 files exist", all(exists)}; %#ok<SAGROW>
    if ~all(exists)
        error('exp033:technicallyBlocked', 'EXP-033 TECHNICALLY BLOCKED: missing input for %s.', noise);
    end
    beforeVars = whos('-file', beforeFile(noise));
    afterVars = whos('-file', afterFile(noise));
    before = load(beforeFile(noise), 'candidateMask', 'metadata');
    after = load(afterFile(noise), 'candidateMask', 'metadata');
    winner = load(winnerFile(noise), 'candidateMask');
    exp030 = load(exp030File(noise), 'candidateMask');
    b = before.candidateMask;
    a = after.candidateMask;
    md = after.metadata;

    inputChecks = {
        noise + " BEFORE candidateMask logical 181x217x181",  any(strcmp({beforeVars.name}, 'candidateMask')) && ...
                                                             islogical(b) && isequal(size(b), expectedSize)
        noise + " BEFORE metadata Phase 60 / EXP-026",       before.metadata.phase == 60 && before.metadata.sourceExperiment == "EXP-026"
        noise + " BEFORE count = Phase-60 summary CSV",      nnz(b) == phase60Summary.candidateVoxels(phase60Summary.condition == noise)
        noise + " AFTER candidateMask logical 181x217x181",   any(strcmp({afterVars.name}, 'candidateMask')) && ...
                                                             islogical(a) && isequal(size(a), expectedSize)
        noise + " AFTER metadata Phase 65 / EXP-032 / EXP-026", md.phase == 65 && md.sourceExperiment == "EXP-032" && ...
                                                             md.candidateGenerationSource == "EXP-026" && md.operation == "opening"
        noise + " AFTER SE square3 / square / 3 / 3x3 / 9",   md.selectedStructuringElementCandidate == "square3" && ...
                                                             md.structuringElementShape == "square" && ...
                                                             md.structuringElementParameter == 3 && ...
                                                             md.structuringElementBoundingSize == 3 && ...
                                                             md.structuringElementForegroundElements == 9
        noise + " AFTER 2D slice-wise, not frozen",           md.processingDimensionality == "2D axial slice-wise" && ~md.finalPipelineFrozen
        noise + " AFTER = frozen EXP-032 square3 winner",     isequal(a, winner.candidateMask)
        noise + " AFTER = EXP-030 square3 opening",           isequal(a, exp030.candidateMask)
        noise + " AFTER subset of BEFORE (no added voxel)",   ~any(a & ~b, 'all')
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('exp033:technicallyBlocked', 'EXP-033 TECHNICALLY BLOCKED: invalid frozen masks for %s.', noise);
    end
    masks(n, :) = {b, a};
    copies(n, :) = {b, a};
    afterSE(n) = string(md.selectedStructuringElementCandidate); %#ok<SAGROW>
    volumes{n} = prepare(loadBrainwebMri(cfg, "T2", noise));      % solo per le figure
end
checks(end+1, :) = {"same selected SE for pn0 and pn3", afterSE(1) == afterSE(2)};


%% 2. Valutazione (GT)

labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
gtVoxels = nnz(gtMask);
gtCopy = gtMask;
checks(end+1, :) = {"GT = label 10, 181x217x181, non-empty", isequal(size(labels), expectedSize) && ...
    isequal(gtMask, labels == 10) && gtVoxels > 0};

metricRows = cell(0, 8);
dice = zeros(2, 2);                              % condizione x (prima, dopo)
counts = zeros(2, 2, 3);                         % condizione x stadio x (TP, FP, FN)
sliceTables = cell(1, 2);
for n = 1:2
    for s = 1:2
        m = masks{n, s};
        tp = nnz(m & gtMask); fp = nnz(m & ~gtMask); fn = nnz(~m & gtMask);
        counts(n, s, :) = [tp fp fn];
        dice(n, s) = 2 * tp / (nnz(m) + gtVoxels);
        checks(end+1, :) = {noiseLevels(n) + " " + stages(s) + " Dice finite in [0,1], TP+FP, TP+FN", ...
            isfinite(dice(n, s)) && dice(n, s) >= 0 && dice(n, s) <= 1 && numel(m) == prod(expectedSize) && ...
            tp + fp == nnz(m) && tp + fn == gtVoxels}; %#ok<SAGROW>
        metricRows(end+1, :) = {noiseLevels(n), stages(s), nnz(m), gtVoxels, tp, fp, fn, dice(n, s)}; %#ok<SAGROW>
    end
    b = masks{n, 1}; a = masks{n, 2};
    perSlice = @(m) squeeze(sum(m, [1 2]));
    sliceTables{n} = table(repmat(noiseLevels(n), nSlices, 1), (1:nSlices).', perSlice(b), perSlice(a), ...
        perSlice(b & gtMask), perSlice(a & gtMask), perSlice(b & ~gtMask), perSlice(a & ~gtMask), ...
        perSlice(~b & gtMask), perSlice(~a & gtMask), perSlice(b & ~a & gtMask), perSlice(b & ~a & ~gtMask), ...
        'VariableNames', {'condition', 'slice', 'beforeCandidateVoxels', 'afterCandidateVoxels', 'beforeTP', ...
        'afterTP', 'beforeFP', 'afterFP', 'beforeFN', 'afterFN', 'removedTP', 'removedFP'});
    t = sliceTables{n};
    checks(end+1, :) = {noiseLevels(n) + " slice totals reproduce volume TP/FP/FN", ...
        sum(t.beforeTP) == counts(n, 1, 1) && sum(t.afterTP) == counts(n, 2, 1) && ...
        sum(t.beforeFP) == counts(n, 1, 2) && sum(t.afterFP) == counts(n, 2, 2) && ...
        sum(t.beforeFN) == counts(n, 1, 3) && sum(t.afterFN) == counts(n, 2, 3)}; %#ok<SAGROW>
end
metrics = cell2table(metricRows, 'VariableNames', {'condition', 'stage', 'candidateVoxels', 'gtVoxels', ...
    'tpVoxels', 'fpVoxels', 'fnVoxels', 'dice'});
bySlice = [sliceTables{1}; sliceTables{2}];
writetable(metrics, fullfile(cfg.paths.metrics, 'exp033_before_after_metrics.csv'));
writetable(bySlice, fullfile(cfg.paths.metrics, 'exp033_before_after_by_slice.csv'));

developmentScore = ((dice(1, :) + dice(2, :)) / 2).';
weakerConditionDice = min(dice, [], 1).';
deltaVsBefore = developmentScore - developmentScore(1);
development = table(stages.', dice(1, :).', dice(2, :).', weakerConditionDice, developmentScore, deltaVsBefore, ...
    'VariableNames', {'stage', 'dicePn0', 'dicePn3', 'weakerConditionDice', 'developmentScore', 'deltaVsBefore'});
writetable(development, fullfile(cfg.paths.metrics, 'exp033_before_after_development_summary.csv'));

changeRows = cell(2, 1);
for n = 1:2
    b = masks{n, 1}; a = masks{n, 2};
    removed = b & ~a;
    removedTP = nnz(removed & gtMask);
    removedFP = nnz(removed & ~gtMask);
    c = squeeze(counts(n, :, :));                % righe: prima, dopo; colonne: TP FP FN
    checks = [checks; {
        noiseLevels(n) + " removedTP + removedFP = removed",  removedTP + removedFP == nnz(removed)
        noiseLevels(n) + " before = after + removed",         nnz(b) == nnz(a) + nnz(removed)
        noiseLevels(n) + " no added voxel",                   nnz(a & ~b) == 0
        }]; %#ok<AGROW>
    changeRows{n} = {noiseLevels(n), nnz(b), nnz(a), c(1, 1), c(2, 1), c(1, 2), c(2, 2), c(1, 3), c(2, 3), ...
        nnz(removed), removedTP, removedFP, nnz(removed) / nnz(b), c(2, 1) / c(1, 1), removedTP / c(1, 1), ...
        removedFP / c(1, 2), removedFP / nnz(removed), removedFP / removedTP, dice(n, 2) - dice(n, 1)};
end
changes = cell2table(vertcat(changeRows{:}), 'VariableNames', {'condition', 'beforeCandidateVoxels', ...
    'afterCandidateVoxels', 'beforeTP', 'afterTP', 'beforeFP', 'afterFP', 'beforeFN', 'afterFN', 'removedVoxels', ...
    'removedTP', 'removedFP', 'fractionCandidatesRemoved', 'fractionTPPreserved', 'fractionTPLost', ...
    'fractionFPRemoved', 'fractionRemovedThatIsFP', 'fpRemovedPerTpLost', 'deltaDice'});
writetable(changes, fullfile(cfg.paths.metrics, 'exp033_morphology_change_summary.csv'));

% Riferimenti salvati
exp026 = readtable(fullfile(cfg.paths.metrics, 'exp026_vs_otsu_comparison.csv'), 'TextType', 'string');
ref026 = exp026(exp026.experiment == "EXP-026", :);
exp032 = readtable(fullfile(cfg.paths.metrics, 'exp032_selected_structuring_element.csv'), 'TextType', 'string');
exp030 = readtable(fullfile(cfg.paths.metrics, 'exp030_opening_score_comparison.csv'), 'TextType', 'string');
ref030 = exp030(exp030.variant == "opening", :);
checks = [checks; {
    "BEFORE Dice reproduces EXP-026",             abs(dice(1, 1) - ref026.dicePn0) < 1e-12 && abs(dice(2, 1) - ref026.dicePn3) < 1e-12
    "AFTER Dice reproduces EXP-032 selected",     abs(dice(1, 2) - exp032.dicePn0) < 1e-12 && abs(dice(2, 2) - exp032.dicePn3) < 1e-12
    "AFTER Dice reproduces EXP-030 square3",      abs(dice(1, 2) - ref030.dicePn0) < 1e-12 && abs(dice(2, 2) - ref030.dicePn3) < 1e-12
    "DevelopmentScores = (pn0 + pn3)/2 exactly",  all(developmentScore == ((dice(1, :) + dice(2, :)) / 2).')
    "DeltaDevelopmentScore correct",              deltaVsBefore(2) == developmentScore(2) - developmentScore(1)
    "deltaDice pn0 / pn3 correct",                changes.deltaDice(1) == dice(1, 2) - dice(1, 1) && ...
                                                  changes.deltaDice(2) == dice(2, 2) - dice(2, 1)
    }];

disp(metrics);
disp(development);
disp(changes);
fprintf('FN increase: pn0 %d, pn3 %d\n', changes.afterFN(1) - changes.beforeFN(1), ...
    changes.afterFN(2) - changes.beforeFN(2));
if developmentScore(2) > developmentScore(1)
    fprintf(['THE SELECTED MORPHOLOGY BLOCK IMPROVES THE DEVELOPMENT-SET RESULT AND IS RETAINED FOR ' ...
        'SUBSEQUENT DEVELOPMENT PHASES. (delta %.10f)\n\n'], deltaVsBefore(2));
elseif developmentScore(2) < developmentScore(1)
    fprintf(['THE SELECTED MORPHOLOGY BLOCK DOES NOT IMPROVE THE DEVELOPMENT-SET RESULT AND SHOULD NOT BE ' ...
        'RETAINED IN ITS CURRENT FORM. (delta %.10f)\n\n'], deltaVsBefore(2));
else
    fprintf('THE SELECTED MORPHOLOGY BLOCK DOES NOT PROVIDE A MEASURABLE DEVELOPMENT-SCORE IMPROVEMENT.\n\n');
end


%% 3. Figure (slice fisse)

for n = 1:2
    b = masks{n, 1}; a = masks{n, 2};
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 4, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf('EXP-033 T2 %s - T2 / BEFORE morphology / AFTER morphology (opening square 3x3) / GT', ...
        noiseLevels(n)), 'Interpreter', 'none');
    for k = fixedSlices
        panels = {maskOverlay(volumes{n}(:, :, k), false(expectedSize(1:2))), maskOverlay(volumes{n}(:, :, k), b(:, :, k)), ...
            maskOverlay(volumes{n}(:, :, k), a(:, :, k)), maskOverlay(volumes{n}(:, :, k), gtMask(:, :, k))};
        showPanels(layout, panels, ["T2", "before", "after", "GT"], k);
    end
    fig.Position(3:4) = [1300 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp033_before_after_masks_%s.png', noiseLevels(n))), ...
        'Resolution', 150);

    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 2, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, {sprintf('EXP-033 T2 %s - errors before / after morphology', noiseLevels(n)), ...
        'yellow = TP, red = FP, green = FN'}, 'Interpreter', 'none');
    for k = fixedSlices
        panels = {errorOverlay(volumes{n}(:, :, k), b(:, :, k), gtMask(:, :, k)), ...
            errorOverlay(volumes{n}(:, :, k), a(:, :, k), gtMask(:, :, k))};
        showPanels(layout, panels, ["before", "after"], k);
    end
    fig.Position(3:4) = [750 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp033_before_after_errors_%s.png', noiseLevels(n))), ...
        'Resolution', 150);

    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, {sprintf('EXP-033 T2 %s - voxels removed by morphology', noiseLevels(n)), ...
        'orange = lesion GT voxel, red = non-lesion'}, 'Interpreter', 'none');
    for k = fixedSlices
        ax = nexttile(layout);
        image(ax, changeOverlay(volumes{n}(:, :, k), b(:, :, k) & ~a(:, :, k), gtMask(:, :, k)));
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('k=%d removed', k), 'FontSize', 8);
    end
    fig.Position(3:4) = [900 1000];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp033_removed_by_morphology_%s.png', noiseLevels(n))), ...
        'Resolution', 150);

    t = sliceTables{n};
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact');
    title(layout, sprintf('EXP-033 %s - FP and FN per axial slice, before vs after morphology (diagnostic only)', ...
        noiseLevels(n)), 'Interpreter', 'none');
    ax = nexttile(layout);
    plot(ax, t.slice, t.beforeFP, 'r-', t.slice, t.afterFP, 'k-');
    ylabel(ax, 'FP voxels'); legend(ax, 'before', 'after'); xlim(ax, [1 nSlices]);
    ax = nexttile(layout);
    plot(ax, t.slice, t.beforeFN, 'g-', t.slice, t.afterFN, 'k-');
    ylabel(ax, 'FN voxels'); legend(ax, 'before', 'after'); xlim(ax, [1 nSlices]);
    xlabel(ax, 'axial slice k');
    fig.Position(3:4) = [1000 650];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp033_before_after_slice_profile_%s.png', noiseLevels(n))));
end


%% Esito dei controlli

for n = 1:2
    checks(end+1, :) = {noiseLevels(n) + " source BEFORE / AFTER masks unchanged", ...
        isequal(masks{n, 1}, copies{n, 1}) && isequal(masks{n, 2}, copies{n, 2})}; %#ok<SAGROW>
end
checks(end+1, :) = {"GT unchanged, same for pn0 and pn3", isequal(gtMask, gtCopy)};
checks(end+1, :) = {"config.m unchanged", isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)};
scriptText = fileread([mfilename('fullpath') '.m']);
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['imopen' '('], ['imclose' '('], ['imerode' '('], ['imdilate' '('], ['imfill' '('], ...
    ['imreconstruct' '('], ['bwmorph' '('], ['bwconn' 'comp('], ['bwlabel' '('], ['region' 'props('], ...
    ['bwarea' 'open('], ['multi' 'thresh('], ['imquantize' '('], ['gray' 'thresh('], ['imbinarize' '('], ...
    ['thresholdLesion' 'Candidates('], ['generateLesion' 'CandidateMask('], ['save' '(']};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};
checks(end+1, :) = {"no morphology/components/thresholding/save called", ...
    ~any(cellfun(@(f) contains(scriptText, f), forbidden))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-58s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp033:checksFailed', 'EXP-033 checks failed.');
end
fprintf('\nEXP-033 CHECKS: PASS (%d)\n', size(checks, 1));


function showPanels(layout, panels, names, k)
%SHOWPANELS Disegna una riga di pannelli RGB con titolo slice/nome.
    for p = 1:numel(panels)
        ax = nexttile(layout);
        image(ax, panels{p});
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('k=%d %s', k, names(p)), 'FontSize', 8);
    end
end

function rgb = maskOverlay(sliceImage, maskSlice)
%MASKOVERLAY T2 in scala di grigi con la maschera in rosso (solo visualizzazione).
    gray = sliceImage.';
    m = maskSlice.';
    red = gray; green = gray; blue = gray;
    red(m) = 1; green(m) = 0; blue(m) = 0;
    rgb = cat(3, red, green, blue);
end

function rgb = errorOverlay(sliceImage, candidateSlice, gtSlice)
%ERROROVERLAY TP giallo, FP rosso, FN verde (solo visualizzazione diagnostica).
    gray = sliceImage.';
    p = candidateSlice.';
    g = gtSlice.';
    red = gray; green = gray; blue = gray;
    tp = p & g; fp = p & ~g; fn = ~p & g;
    red(tp) = 1; green(tp) = 1; blue(tp) = 0;
    red(fp) = 1; green(fp) = 0; blue(fp) = 0;
    red(fn) = 0; green(fn) = 1; blue(fn) = 0;
    rgb = cat(3, red, green, blue);
end

function rgb = changeOverlay(sliceImage, changedSlice, gtSlice)
%CHANGEOVERLAY Voxel cambiati: arancione se lesione GT, rosso altrimenti.
    gray = sliceImage.';
    c = changedSlice.';
    g = gtSlice.';
    red = gray; green = gray; blue = gray;
    lesion = c & g; other = c & ~g;
    red(lesion) = 1; green(lesion) = 0.6; blue(lesion) = 0;
    red(other) = 1; green(other) = 0; blue(other) = 0;
    rgb = cat(3, red, green, blue);
end
