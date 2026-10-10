%% EXP-029 (fase 62): sonda di erosione / dilatazione sulla maschera dei candidati
% Esperimento di morfologia: misura l'effetto elementare di UNA erosione e
% di UNA dilatazione sulla candidateMask canonica della fase 60 (= EXP-026),
% che NON viene modificata né sostituita.
%   - elemento strutturante: strel('square', 3), una sola applicazione;
%     sonda esplorativa minima, NON la scelta della fase 65
%   - 2D, slice assiale per slice assiale (applySliceMorphology2D);
%     risultato sempre intersecato con la maschera cerebrale EXP-021
%   - le quattro uscite (erosione / dilatazione x pn0 / pn3) sono salvate
%     PRIMA di caricare il GT
%   - punteggi: Dice sul volume completo, DevelopmentScore, delta rispetto
%     alla baseline; nessuna tolleranza, nessuna scelta di pipeline
%   - nessuna apertura, chiusura, componente connessa, riempimento;
%     solo pn0 + pn3.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

se = strel('square', 3);                         % preregistrato, unico
operations = ["erosion" "dilation"];
opCodes = ["erode" "dilate"];
variants = ["baseline" "erosion" "dilation"];
noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
nSlices = expectedSize(3);
fixedSlices = [46 91 102 136];
candidateFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase60_t2_%s_candidate_mask.mat', noise));
maskFile = @(noise) fullfile(cfg.paths.processedData, ...
    sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));
outputFile = @(noise, op) fullfile(cfg.paths.processedData, ...
    sprintf('exp029_t2_%s_%s_square3_candidate.mat', noise, op));
outputTag = ["eroded" "dilated"];

checks = {"SE is square 3x3", isequal(se.Neighborhood, true(3))};
phase60Summary = readtable(fullfile(cfg.paths.metrics, 'phase60_candidate_mask_summary.csv'), 'TextType', 'string');
neighborKernel = [1 1 1; 1 0 1; 1 1 1];

masks = cell(2, 3);                              % condizione x variante
brainMasks = cell(1, 2);
volumes = cell(1, 2);
gtLoaded = false;


%% 1. Morfologia (senza GT)

for n = 1:2
    noise = noiseLevels(n);
    if ~isfile(candidateFile(noise)) || ~isfile(maskFile(noise))
        error('exp029:technicallyBlocked', 'EXP-029 TECHNICALLY BLOCKED: missing input for %s.', noise);
    end
    contents = whos('-file', candidateFile(noise));
    saved = load(candidateFile(noise), 'candidateMask', 'metadata');
    baseline = saved.candidateMask;
    savedMask = load(maskFile(noise), 'candidate');
    brainMask = savedMask.candidate;
    baselineCopy = baseline;

    inputChecks = {
        noise + " candidateMask variable present",    any(strcmp({contents.name}, 'candidateMask'))
        noise + " candidateMask logical",             islogical(baseline)
        noise + " candidateMask 181x217x181",         isequal(size(baseline), expectedSize)
        noise + " metadata source = EXP-026",         saved.metadata.sourceExperiment == "EXP-026"
        noise + " brainMask same size, logical",      isequal(size(brainMask), expectedSize) && islogical(brainMask)
        noise + " baseline inside brainMask",         ~any(baseline & ~brainMask, 'all')
        noise + " count = Phase-60 summary CSV",      nnz(baseline) == ...
                                                      phase60Summary.candidateVoxels(phase60Summary.condition == noise)
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('exp029:technicallyBlocked', 'EXP-029 TECHNICALLY BLOCKED: invalid input for %s.', noise);
    end

    % Riferimento indipendente: vicini candidati 2D a 8 (come in EXP-028)
    neighborCount = zeros(size(baseline));
    for k = 1:nSlices
        neighborCount(:, :, k) = conv2(double(baseline(:, :, k)), neighborKernel, 'same');
    end

    masks{n, 1} = baseline;
    for o = 1:2
        result = applySliceMorphology2D(baseline, brainMask, opCodes(o), se);
        masks{n, o + 1} = result;
        metadata = struct('experiment', "EXP-029", 'phase', 62, 'condition', noise, ...
            'source', "Phase-60 canonical candidate mask", 'sourceFile', string(candidateFile(noise)), ...
            'sourceExperiment', "EXP-026", 'operation', operations(o), ...
            'processingDimensionality', "2D axial slice-wise", 'structuringElementShape', "square", ...
            'structuringElementSize', 3, 'iterations', 1, 'brainMaskConstrained', true, ...
            'sourceBrainMask', string(maskFile(noise)), 'provisionalStructuringElement', true, ...
            'gtUsedForGeneration', false, 'finalMorphology', false, ...
            'note', "SE square 3x3 is a Phase-62 probe, not the final Phase-65 structuring-element selection.");
        candidateMask = result;
        save(outputFile(noise, outputTag(o)), 'candidateMask', 'metadata');
        reloaded = load(outputFile(noise, outputTag(o)), 'candidateMask');
        checks(end+1, :) = {noise + " " + operations(o) + " saved mask reloads identically", ...
            isequal(reloaded.candidateMask, result)}; %#ok<SAGROW>
    end
    eroded = masks{n, 2};
    dilated = masks{n, 3};

    checks = [checks; {
        noise + " outputs logical, 181x217x181",         islogical(eroded) && islogical(dilated) && ...
                                                         isequal(size(eroded), expectedSize) && isequal(size(dilated), expectedSize)
        noise + " erosion adds no voxel",                ~any(eroded & ~baseline, 'all')
        noise + " baseline subset of dilation",          ~any(baseline & ~dilated, 'all')
        noise + " outputs inside brainMask",             ~any((eroded | dilated) & ~brainMask, 'all')
        noise + " erosion = candidates with 8 neighbours (slice-wise)", isequal(eroded, baseline & neighborCount == 8)
        noise + " dilation = (cand | >=1 neighbour) & brain (slice-wise)", ...
                                                         isequal(dilated, (baseline | neighborCount >= 1) & brainMask)
        noise + " baseline unchanged",                   isequal(baseline, baselineCopy)
        }]; %#ok<AGROW>
    brainMasks{n} = brainMask;
    volumes{n} = prepare(loadBrainwebMri(cfg, "T2", noise));      % solo per le figure
end
outputsFrozen = all(arrayfun(@(noise) isfile(outputFile(noise, "eroded")) && isfile(outputFile(noise, "dilated")), ...
    noiseLevels));
checks(end+1, :) = {"all 4 outputs saved before GT loading", outputsFrozen && ~gtLoaded};


%% 2. Valutazione (GT caricato SOLO ora)

gtLoaded = true;
labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
gtVoxels = nnz(gtMask);
gtCopy = gtMask;
checks(end+1, :) = {"GT = label 10, 181x217x181, non-empty", isequal(size(labels), expectedSize) && ...
    isequal(gtMask, labels == 10) && gtVoxels > 0};

summaryRows = cell(0, 8);
dice = zeros(2, 3);
for n = 1:2
    for v = 1:3
        m = masks{n, v};
        tp = nnz(m & gtMask);
        fp = nnz(m & ~gtMask);
        fn = nnz(~m & gtMask);
        dice(n, v) = 2 * tp / (nnz(m) + gtVoxels);
        checks(end+1, :) = {noiseLevels(n) + " " + variants(v) + " Dice finite in [0,1], full volume", ...
            isfinite(dice(n, v)) && dice(n, v) >= 0 && dice(n, v) <= 1 && numel(m) == prod(expectedSize)}; %#ok<SAGROW>
        summaryRows(end+1, :) = {noiseLevels(n), variants(v), nnz(m), gtVoxels, tp, fp, fn, dice(n, v)}; %#ok<SAGROW>
    end
end
summary = cell2table(summaryRows, 'VariableNames', {'condition', 'variant', 'candidateVoxels', 'gtVoxels', ...
    'tpVoxels', 'fpVoxels', 'fnVoxels', 'dice'});
writetable(summary, fullfile(cfg.paths.metrics, 'exp029_erosion_dilation_summary.csv'));

developmentScore = mean(dice, 1).';
weakerConditionDice = min(dice, [], 1).';
deltaVsBaseline = developmentScore - developmentScore(1);
effect = table(variants.', dice(1, :).', dice(2, :).', weakerConditionDice, developmentScore, deltaVsBaseline, ...
    'VariableNames', {'variant', 'dicePn0', 'dicePn3', 'weakerConditionDice', 'developmentScore', 'deltaVsBaseline'});
writetable(effect, fullfile(cfg.paths.metrics, 'exp029_morphology_effect_comparison.csv'));

% Riferimento: baseline = EXP-026
exp026 = readtable(fullfile(cfg.paths.metrics, 'exp026_vs_otsu_comparison.csv'), 'TextType', 'string');
ref = exp026(exp026.experiment == "EXP-026", :);
checks = [checks; {
    "baseline Dice reproduces EXP-026",          abs(dice(1, 1) - ref.dicePn0) < 1e-12 && abs(dice(2, 1) - ref.dicePn3) < 1e-12
    "DevelopmentScore = (pn0 + pn3)/2 exactly",  all(developmentScore == ((dice(1, :) + dice(2, :)) / 2).')
    "deltas = score - baseline score",           all(deltaVsBaseline == developmentScore - developmentScore(1))
    }];

% Conteggi delle variazioni
changeRows = cell(0, 15);
for n = 1:2
    baseline = masks{n, 1};
    baseTP = nnz(baseline & gtMask);
    baseFP = nnz(baseline & ~gtMask);
    baseFN = nnz(~baseline & gtMask);

    eroded = masks{n, 2};
    removed = baseline & ~eroded;
    removedTP = nnz(removed & gtMask);
    removedFP = nnz(removed & ~gtMask);
    dilated = masks{n, 3};
    added = dilated & ~baseline;
    addedTP = nnz(added & gtMask);
    addedFP = nnz(added & ~gtMask);
    checks = [checks; {
        noiseLevels(n) + " eroded = baseline & eroded",        isequal(eroded, baseline & eroded)
        noiseLevels(n) + " |baseline| = |eroded| + |removed|", nnz(baseline) == nnz(eroded) + nnz(removed)
        noiseLevels(n) + " removedTP + removedFP = removed",   removedTP + removedFP == nnz(removed)
        noiseLevels(n) + " |dilated| = |baseline| + |added|",  nnz(dilated) == nnz(baseline) + nnz(added)
        noiseLevels(n) + " addedTP + addedFP = added",         addedTP + addedFP == nnz(added)
        noiseLevels(n) + " FN recovered = added & GT",         addedTP == baseFN - nnz(~dilated & gtMask)
        }]; %#ok<AGROW>
    changeRows(end+1, :) = {noiseLevels(n), "erosion", nnz(baseline), nnz(eroded), nnz(removed), removedTP, ...
        removedFP, baseTP, baseFP, baseFN, removedTP, removedFP, 0, 0, 0}; %#ok<SAGROW>
    changeRows(end+1, :) = {noiseLevels(n), "dilation", nnz(baseline), nnz(dilated), nnz(added), addedTP, ...
        addedFP, baseTP, baseFP, baseFN, 0, 0, addedTP, addedFP, addedTP}; %#ok<SAGROW>
    fprintf(['%s erosion: removed %d (TP %d, FP %d); FP share of removed %.4f; baseline TP lost %.4f; ' ...
        'baseline FP removed %.4f\n'], noiseLevels(n), nnz(removed), removedTP, removedFP, ...
        removedFP / nnz(removed), removedTP / baseTP, removedFP / baseFP);
    fprintf(['%s dilation: added %d (TP %d, FP %d); FN recovered %.4f of %d; TP share of added %.4f; ' ...
        'FP share of added %.4f\n'], noiseLevels(n), nnz(added), addedTP, addedFP, addedTP / baseFN, baseFN, ...
        addedTP / nnz(added), addedFP / nnz(added));
end
changes = cell2table(changeRows, 'VariableNames', {'condition', 'operation', 'baselineVoxels', 'resultVoxels', ...
    'changedVoxels', 'tpChanged', 'fpChanged', 'baselineTP', 'baselineFP', 'baselineFN', 'tpLostByErosion', ...
    'fpRemovedByErosion', 'tpAddedByDilation', 'fpAddedByDilation', 'fnRecoveredByDilation'});
writetable(changes, fullfile(cfg.paths.metrics, 'exp029_morphology_change_counts.csv'));
disp(summary);
disp(effect);
for v = 2:3
    if deltaVsBaseline(v) > 0
        verdict = "IMPROVES";
    elseif deltaVsBaseline(v) < 0
        verdict = "WORSENS";
    else
        verdict = "LEAVES UNCHANGED";
    end
    fprintf('%s %s the baseline DevelopmentScore (delta %.10f)\n', variants(v), verdict, deltaVsBaseline(v));
end
fprintf('\n');


%% 3. Figure (slice fisse; dopo i punteggi per gli overlay d'errore)

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 4, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf('EXP-029 T2 %s - T2 / baseline / erosion / dilation (square 3x3, 2D, red = candidate)', ...
        noiseLevels(n)), 'Interpreter', 'none');
    for k = fixedSlices
        panels = {maskOverlay(volumes{n}(:, :, k), false(expectedSize(1:2))), ...
            maskOverlay(volumes{n}(:, :, k), masks{n, 1}(:, :, k)), ...
            maskOverlay(volumes{n}(:, :, k), masks{n, 2}(:, :, k)), ...
            maskOverlay(volumes{n}(:, :, k), masks{n, 3}(:, :, k))};
        names = ["T2", "baseline", "erosion", "dilation"];
        showPanels(layout, panels, names, k);
    end
    fig.Position(3:4) = [1300 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp029_morphology_probe_%s.png', noiseLevels(n))), ...
        'Resolution', 150);

    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 3, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf('EXP-029 T2 %s - errors (after scoring): yellow = TP, red = FP, green = FN', ...
        noiseLevels(n)), 'Interpreter', 'none');
    for k = fixedSlices
        panels = arrayfun(@(v) errorOverlay(volumes{n}(:, :, k), masks{n, v}(:, :, k), gtMask(:, :, k)), 1:3, ...
            'UniformOutput', false);
        showPanels(layout, panels, variants, k);
    end
    fig.Position(3:4) = [1000 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp029_morphology_errors_%s.png', noiseLevels(n))), ...
        'Resolution', 150);

    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 2, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, {sprintf('EXP-029 T2 %s - changes vs baseline', noiseLevels(n)), ...
        'orange = lesion GT voxel, red = non-lesion'}, 'Interpreter', 'none');
    for k = fixedSlices
        removedSlice = masks{n, 1}(:, :, k) & ~masks{n, 2}(:, :, k);
        addedSlice = masks{n, 3}(:, :, k) & ~masks{n, 1}(:, :, k);
        panels = {changeOverlay(volumes{n}(:, :, k), removedSlice, gtMask(:, :, k)), ...
            changeOverlay(volumes{n}(:, :, k), addedSlice, gtMask(:, :, k))};
        showPanels(layout, panels, ["removed by erosion", "added by dilation"], k);
    end
    fig.Position(3:4) = [700 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp029_morphology_changes_%s.png', noiseLevels(n))), ...
        'Resolution', 150);
end


%% Esito dei controlli

checks(end+1, :) = {"GT unchanged, same for pn0 and pn3", isequal(gtMask, gtCopy)};
scriptText = fileread([mfilename('fullpath') '.m']);
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['imopen' '('], ['imclose' '('], ['imfill' '('], ['imreconstruct' '('], ['bwmorph' '('], ...
    ['bwconn' 'comp('], ['bwlabel' '('], ['region' 'props('], ['bwarea' 'open('], ['multi' 'thresh('], ...
    ['imquantize' '('], ['generateLesion' 'CandidateMask(']};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};
checks(end+1, :) = {"no opening/closing/components/thresholding", ~any(cellfun(@(f) contains(scriptText, f), forbidden))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-62s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp029:checksFailed', 'EXP-029 checks failed.');
end
fprintf('\nEXP-029 CHECKS: PASS (%d)\n', size(checks, 1));


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
