%% EXP-028 (fase 61): analisi diagnostica degli errori della maschera dei candidati
% Esperimento DIAGNOSTICO: nessun nuovo metodo, nessuna decisione KEEP /
% REJECT, nessuna modifica di candidateMask.
%   - ingresso: maschere canoniche della fase 60 (= EXP-026), NON rigenerate
%   - GT (label 10) caricato dopo le maschere, solo per la diagnostica;
%     maschere TP / FP / FN solo in memoria (non salvate)
%   - topologia locale: numero di vicini candidati nell'intorno 2D a 8
%     (slice per slice, conv2 con kernel 3x3 a centro nullo, padding 0):
%     NON è analisi delle componenti (nessuna etichettatura, nessun oggetto)
%   - nessuna morfologia, nessuna componente connessa, nessun filtraggio;
%     solo pn0 + pn3; le slice fisse sono 46 / 91 / 102 / 136 e il foglio di
%     contatto usa una slice ogni 10 (nessuna slice scelta dai risultati).

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing);

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
nSlices = expectedSize(3);
fixedSlices = [46 91 102 136];
contactSlices = 1:10:nSlices;
candidateFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase60_t2_%s_candidate_mask.mat', noise));
neighborKernel = [1 1 1; 1 0 1; 1 1 1];

checks = cell(0, 2);
phase60Summary = readtable(fullfile(cfg.paths.metrics, 'phase60_candidate_mask_summary.csv'), 'TextType', 'string');


%% 1. Maschere canoniche della fase 60 (prima del GT)

candidates = cell(1, 2);
candidateCopies = cell(1, 2);
volumes = cell(1, 2);
for n = 1:2
    noise = noiseLevels(n);
    file = candidateFile(noise);
    checks(end+1, :) = {noise + " Phase-60 MAT exists", isfile(file)}; %#ok<SAGROW>
    if ~isfile(file)
        error('exp028:technicallyBlocked', 'EXP-028 TECHNICALLY BLOCKED: missing %s.', file);
    end
    contents = whos('-file', file);
    saved = load(file, 'candidateMask', 'metadata');
    candidateMask = saved.candidateMask;
    inputChecks = {
        noise + " variable candidateMask present",      any(strcmp({contents.name}, 'candidateMask'))
        noise + " candidateMask logical",               islogical(candidateMask)
        noise + " candidateMask 181x217x181",           isequal(size(candidateMask), expectedSize)
        noise + " metadata source = EXP-026",           saved.metadata.sourceExperiment == "EXP-026"
        noise + " metadata finalSegmentation = false",  ~saved.metadata.finalSegmentation
        noise + " count = Phase-60 summary CSV",        nnz(candidateMask) == ...
                                                        phase60Summary.candidateVoxels(phase60Summary.condition == noise)
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('exp028:technicallyBlocked', 'EXP-028 TECHNICALLY BLOCKED: invalid candidate mask %s.', noise);
    end
    candidates{n} = candidateMask;
    candidateCopies{n} = candidateMask;
    volumes{n} = prepare(loadBrainwebMri(cfg, "T2", noise));      % solo per le figure
end


%% 2. Ground truth (solo diagnostica)

labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
gtVoxels = nnz(gtMask);
gtCopy = gtMask;
checks = [checks; {
    "GT size 181x217x181",           isequal(size(labels), expectedSize)
    "GT labels inside 0...10",       all(labels(:) >= 0 & labels(:) <= 10)
    "gtMask = labels == 10, logical", islogical(gtMask) && isequal(gtMask, labels == 10)
    "GT lesion voxels > 0",          gtVoxels > 0
    }];


%% 3. Conteggi d'errore e topologia locale

summaryRows = cell(2, 1);
sliceRows = cell(2, 1);
distributionRows = cell(0, 5);
neighborVolumes = cell(1, 2);
errorClasses = ["TP" "FP" "FN"];
distributions = zeros(2, 3, 9);                  % condizione x classe x (0...8)
for n = 1:2
    noise = noiseLevels(n);
    candidateMask = candidates{n};
    tpMask = candidateMask & gtMask;
    fpMask = candidateMask & ~gtMask;
    fnMask = ~candidateMask & gtMask;

    % Vicini candidati nell'intorno 2D a 8, slice per slice
    neighborCount = zeros(size(candidateMask));
    for k = 1:nSlices
        neighborCount(:, :, k) = conv2(double(candidateMask(:, :, k)), neighborKernel, 'same');
    end
    % Implementazione indipendente: somma degli 8 spostamenti nel piano con padding a zero
    padded = false(size(candidateMask) + [2 2 0]);
    padded(2:end-1, 2:end-1, :) = candidateMask;
    shiftedSum = zeros(size(candidateMask));
    for di = -1:1
        for dj = -1:1
            if di ~= 0 || dj ~= 0
                shiftedSum = shiftedSum + double(padded((2:end-1) + di, (2:end-1) + dj, :));
            end
        end
    end

    nbTP = neighborCount(tpMask);
    nbFP = neighborCount(fpMask);
    nbFN = neighborCount(fnMask);
    values = {nbTP, nbFP, nbFN};
    for e = 1:3
        distributions(n, e, :) = histcounts(values{e}, -0.5:1:8.5);
        for v = 0:8
            distributionRows(end+1, :) = {noise, errorClasses(e), v, distributions(n, e, v + 1), ...
                distributions(n, e, v + 1) / max(numel(values{e}), 1)}; %#ok<SAGROW>
        end
    end

    candidateBySlice = squeeze(sum(candidateMask, [1 2]));
    tpBySlice = squeeze(sum(tpMask, [1 2]));
    fpBySlice = squeeze(sum(fpMask, [1 2]));
    fnBySlice = squeeze(sum(fnMask, [1 2]));
    sliceRows{n} = table(repmat(noise, nSlices, 1), (1:nSlices).', candidateBySlice, tpBySlice, fpBySlice, ...
        fnBySlice, 'VariableNames', {'condition', 'slice', 'candidateVoxels', 'tpVoxels', 'fpVoxels', 'fnVoxels'});

    isolatedTP = nnz(nbTP == 0);
    isolatedFP = nnz(nbFP == 0);
    fnDist = squeeze(distributions(n, 3, :)).';
    summaryRows{n} = [{noise, nnz(candidateMask), gtVoxels, nnz(tpMask), nnz(fpMask), nnz(fnMask), ...
        isolatedTP + isolatedFP, isolatedTP, isolatedFP}, num2cell(fnDist)];

    allNb = neighborCount(candidateMask);
    checks = [checks; {
        noise + " TP + FP = candidate voxels",          nnz(tpMask) + nnz(fpMask) == nnz(candidateMask)
        noise + " TP + FN = GT voxels",                 nnz(tpMask) + nnz(fnMask) == gtVoxels
        noise + " TP/FP/FN disjoint",                   ~any((tpMask & fpMask) | (tpMask & fnMask) | (fpMask & fnMask), 'all')
        noise + " neighbor counts integer",             all(neighborCount(:) == round(neighborCount(:)))
        noise + " neighbor counts in 0...8",            all(neighborCount(:) >= 0 & neighborCount(:) <= 8)
        noise + " slice-wise, no wrap, zero border",    isequal(neighborCount, shiftedSum)
        noise + " isolated = neighborCount == 0",       isolatedTP + isolatedFP == nnz(allNb == 0)
        noise + " TP distribution sums to TP",          sum(distributions(n, 1, :)) == nnz(tpMask)
        noise + " FP distribution sums to FP",          sum(distributions(n, 2, :)) == nnz(fpMask)
        noise + " FN distribution sums to FN",          sum(distributions(n, 3, :)) == nnz(fnMask)
        noise + " per-slice TP sums to volume TP",      sum(tpBySlice) == nnz(tpMask)
        noise + " per-slice FP sums to volume FP",      sum(fpBySlice) == nnz(fpMask)
        noise + " per-slice FN sums to volume FN",      sum(fnBySlice) == nnz(fnMask)
        noise + " candidateMask unchanged",             isequal(candidateMask, candidateCopies{n})
        }]; %#ok<AGROW>
    neighborVolumes{n} = neighborCount;
end
checks(end+1, :) = {"same GT for pn0 and pn3, unchanged", isequal(gtMask, gtCopy)};

fnNames = compose("fnWith%dCandidateNeighbors", 0:8);
summary = cell2table(vertcat(summaryRows{:}), 'VariableNames', [{'condition', 'candidateVoxels', 'gtVoxels', ...
    'tpVoxels', 'fpVoxels', 'fnVoxels', 'isolatedCandidateVoxels', 'isolatedTP', 'isolatedFP'}, cellstr(fnNames)]);
bySlice = [sliceRows{1}; sliceRows{2}];
distribution = cell2table(distributionRows, 'VariableNames', {'condition', 'errorClass', 'neighborCount', ...
    'voxelCount', 'fractionWithinClass'});
writetable(summary, fullfile(cfg.paths.metrics, 'exp028_candidate_error_summary.csv'));
writetable(bySlice, fullfile(cfg.paths.metrics, 'exp028_error_counts_by_slice.csv'));
writetable(distribution, fullfile(cfg.paths.metrics, 'exp028_neighbor_distribution.csv'));
disp(summary);
for n = 1:2
    for e = 1:3
        fprintf('%s %s neighbor distribution 0..8: %s\n', noiseLevels(n), errorClasses(e), ...
            strjoin(string(squeeze(distributions(n, e, :)).'), ' / '));
    end
end
fprintf('\n');


%% 4. Figure diagnostiche (giallo = TP, rosso = FP, verde = FN)

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 4, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf(['EXP-028 T2 %s - Phase-60 candidateMask errors: T2 / candidates / GT / ' ...
        'yellow = TP, red = FP, green = FN'], noiseLevels(n)), 'Interpreter', 'none');
    for k = fixedSlices
        panels = {maskOverlay(volumes{n}(:, :, k), false(expectedSize(1:2))), ...
            maskOverlay(volumes{n}(:, :, k), candidates{n}(:, :, k)), ...
            maskOverlay(volumes{n}(:, :, k), gtMask(:, :, k)), ...
            errorOverlay(volumes{n}(:, :, k), candidates{n}(:, :, k), gtMask(:, :, k))};
        names = ["T2", "candidates", "GT", "errors"];
        for p = 1:4
            ax = nexttile(layout);
            image(ax, panels{p});
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('k=%d %s', k, names(p)), 'FontSize', 8);
        end
    end
    fig.Position(3:4) = [1300 1300];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp028_candidate_errors_%s.png', noiseLevels(n))), ...
        'Resolution', 150);

    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 3, 7, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf(['EXP-028 T2 %s - error overlay every 10 axial slices ' ...
        '(yellow = TP, red = FP, green = FN)'], noiseLevels(n)), 'Interpreter', 'none');
    for k = contactSlices
        ax = nexttile(layout);
        image(ax, errorOverlay(volumes{n}(:, :, k), candidates{n}(:, :, k), gtMask(:, :, k)));
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('k=%d', k), 'FontSize', 7);
    end
    fig.Position(3:4) = [1600 900];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp028_error_contact_sheet_%s.png', noiseLevels(n))), ...
        'Resolution', 150);
end

fig = figure('Color', 'w');
layout = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact');
title(layout, 'EXP-028 - FP and FN voxels per axial slice (diagnostic only)');
for n = 1:2
    ax = nexttile(layout);
    rowsN = bySlice.condition == noiseLevels(n);
    yyaxis(ax, 'left');
    plot(ax, bySlice.slice(rowsN), bySlice.fpVoxels(rowsN), 'r-');
    ylabel(ax, 'FP voxels');
    yyaxis(ax, 'right');
    plot(ax, bySlice.slice(rowsN), bySlice.fnVoxels(rowsN), 'g-');
    ylabel(ax, 'FN voxels');
    title(ax, noiseLevels(n));
    xlim(ax, [1 nSlices]);
end
xlabel(ax, 'axial slice k');
fig.Position(3:4) = [1000 650];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp028_fp_fn_by_slice.png'));

fig = figure('Color', 'w');
layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact');
title(layout, 'EXP-028 - candidate-neighbor count in the 2D 8-neighborhood (fraction within class)');
for e = 1:3
    ax = nexttile(layout);
    fractions = squeeze(distributions(:, e, :)) ./ sum(distributions(:, e, :), 3);
    bar(ax, 0:8, fractions.');
    xlabel(ax, 'candidate neighbors');
    ylabel(ax, 'fraction');
    title(ax, errorClasses(e) + " voxels");
    legend(ax, noiseLevels, 'Location', 'northwest');
end
fig.Position(3:4) = [1400 450];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp028_neighbor_topology.png'));


%% Esito dei controlli

for n = 1:2
    checks(end+1, :) = {noiseLevels(n) + " candidateMask unchanged at end", ...
        isequal(candidates{n}, candidateCopies{n})}; %#ok<SAGROW>
end
scriptText = fileread([mfilename('fullpath') '.m']);
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['imerode' '('], ['imdilate' '('], ['imopen' '('], ['imclose' '('], ['imfill' '('], ...
    ['imreconstruct' '('], ['bwmorph' '('], ['bwconn' 'comp('], ['bwlabel' '('], ['region' 'props('], ...
    ['bwarea' 'open('], ['multi' 'thresh('], ['save' '(']};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};
checks(end+1, :) = {"no morphology/components/threshold/save called", ~any(cellfun(@(f) contains(scriptText, f), forbidden))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-48s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp028:checksFailed', 'EXP-028 checks failed.');
end
fprintf('\nEXP-028 CHECKS: PASS (%d)\n', size(checks, 1));


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
