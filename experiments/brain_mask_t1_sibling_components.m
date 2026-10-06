%% T1: unione dei figli diretti del genitore immediato (fase 50, EXP-013)
% EXP-012 ha risolto l'identità della componente (nessuno scalpo, faccia/
% collo o artefatto), ma tenendo UNA sola componente annidata per slice il
% supporto è incompleto (es. un solo emisfero a k = 136). EXP-013 cambia
% SOLO la regola di selezione:
%   ancora = selezione di EXP-012 (annidata di area massima)
%   -> genitore immediato dell'ancora (racchiudente con la regione racchiusa
%      più piccola)
%   -> TUTTI i figli diretti di quel genitore (ancora compresa)
%   -> ogni figlio riempito singolarmente -> unione (l'unione NON è riempita)
% Nessuna ancora -> slice VUOTA (nessun ripiego).
%
% Regola automatica di selezione basata sulla topologia, costruita con
% operazioni consentite (componenti connesse, riempimento dei buchi,
% logica); non una nuova tecnica. "Genitore" e "figli" sono termini
% topologici, non anatomici. Nessuna altra morfologia, nessuna soglia di
% area, nessuna regola di posizione o di z, nessun 3D, nessun ground truth.
% T1 serve solo per la maschera; T2 resta la modalità delle lesioni.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

maskModality = "T1";
assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'EXP-013 requires no filter.');

connectivity = 8;
expectedThresholds = [66 64] / 255;         % EXP-010, solo controllo
expectedRawVoxels = [2771291 2727314];      % EXP-010, solo controllo

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
nSlices = cfg.dataset.volumeSize(3);
% Slice deterministiche + slice di transizione dichiarate da EXP-012 (solo diagnostica)
diagnosticSlices = sort([round(linspace(1, nSlices, 5)), 40, 43, 44, 139, 143]);

volumes = cell(1, 2);
rawMasks = cell(1, 2);
candidates = cell(1, 2);
exp012Candidates = cell(1, 2);
anchorMasks = cell(1, 2);
parentMasks = cell(1, 2);
childrenMasks = cell(1, 2);
diags = cell(1, 2);
unionFillWouldAdd = zeros(nSlices, 2);
checks = cell(0, 2);

for n = 1:2
    noise = noiseLevels(n);
    raw = loadBrainwebMri(cfg, maskModality, noise);
    volume = prepare(raw);
    volumeCopy = volume;

    checks(end+1, :) = {noise + " normalized input double in [0,1]", isa(volume, 'double') ...
        && min(volume(:)) >= 0 && max(volume(:)) <= 1}; %#ok<SAGROW>

    [rawMask, threshold] = initialSupportMask(volume);
    checks(end+1, :) = {noise + " EXP-010 threshold reproduced", abs(threshold - expectedThresholds(n)) < 1e-9}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " EXP-010 raw foreground reproduced", nnz(rawMask) == expectedRawVoxels(n)}; %#ok<SAGROW>
    if any(~[checks{:, 2}])
        error('exp013:inputNotReproduced', 'EXP-010 raw T1 masks not reproduced: EXP-013 TECHNICALLY BLOCKED.');
    end

    rawMaskCopy = rawMask;
    [candidate, d, anchorMask, parentMask, childrenMask] = selectSiblingSupportComponentsSlices(rawMask, connectivity);

    % Riferimento EXP-012 (file salvati, non modificati)
    exp012 = load(fullfile(cfg.paths.processedData, sprintf('exp012_t1_%s_nested_support_mask_candidate.mat', noise)), ...
        'candidate', 'selectedMask');

    % Verifiche per slice indipendenti dalla funzione
    individuallyFilled = true;
    directChildrenOnly = true;
    for k = 1:nSlices
        children = bwconncomp(childrenMask(:, :, k), connectivity);
        filledUnion = false(size(rawMask, [1 2]));
        for c = 1:children.NumObjects
            childMask = false(size(filledUnion));
            childMask(children.PixelIdxList{c}) = true;
            filledUnion = filledUnion | imfill(childMask, 'holes');
        end
        individuallyFilled = individuallyFilled && isequal(candidate(:, :, k), filledUnion);
        unionFillWouldAdd(k, n) = nnz(imfill(childrenMask(:, :, k), 'holes')) - nnz(candidate(:, :, k));

        if d.hasAnchor(k)
            % Figli scelti: dentro la regione racchiusa dal genitore e non
            % racchiusi da nessun'altra componente che stia in quella regione
            parentSlice = parentMask(:, :, k);
            parentHole = imfill(parentSlice, 'holes') & ~parentSlice;
            others = bwconncomp(rawMask(:, :, k) & ~parentSlice, connectivity);
            insideOther = false(size(parentSlice));
            for c = 1:others.NumObjects
                if all(parentHole(others.PixelIdxList{c}))
                    otherMask = false(size(parentSlice));
                    otherMask(others.PixelIdxList{c}) = true;
                    insideOther = insideOther | (imfill(otherMask, 'holes') & ~otherMask);
                end
            end
            selected = childrenMask(:, :, k);
            directChildrenOnly = directChildrenOnly && ~any(selected & ~parentHole, 'all') ...
                && ~any(selected & insideOther, 'all');
        end
    end

    checks(end+1, :) = {noise + " 8-connectivity used", d.connectivity == 8}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw mask unchanged", isequal(rawMask, rawMaskCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " anchor identical to EXP-012", isequal(anchorMask, exp012.selectedMask)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " anchor filled = EXP-012 candidate", ...
        isequal(d.anchorFilledArea, squeeze(sum(exp012.candidate, [1 2]))) && ~any(exp012.candidate & ~candidate, 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " anchor among selected children", ~any(anchorMask & ~childrenMask, 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " only direct children of parent", directChildrenOnly}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " parent never in candidate", ~any(parentMask & candidate, 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " children filled individually, no union fill", individuallyFilled}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " no fallback (empty if no anchor)", ...
        ~any(candidate(:, :, ~d.hasAnchor), 'all') && ~any(childrenMask(:, :, ~d.hasAnchor), 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate logical, same size", islogical(candidate) && isequal(size(candidate), size(volume))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " selected children subset of raw", ~any(childrenMask & ~rawMask, 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " normalized volume unchanged", isequal(volume, volumeCopy)}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " raw MRI unchanged on reload", isequal(raw, loadBrainwebMri(cfg, maskModality, noise))}; %#ok<SAGROW>

    selectedChildrenMask = childrenMask;
    save(fullfile(cfg.paths.processedData, sprintf('exp013_t1_%s_siblings_support_mask_candidate.mat', noise)), ...
        'candidate', 'anchorMask', 'parentMask', 'selectedChildrenMask', 'threshold');

    volumes{n} = volume;
    rawMasks{n} = rawMask;
    candidates{n} = candidate;
    exp012Candidates{n} = exp012.candidate;
    anchorMasks{n} = anchorMask;
    parentMasks{n} = parentMask;
    childrenMasks{n} = childrenMask;
    diags{n} = d;
end

if any(~[checks{:, 2}])
    error('exp013:checksFailed', 'EXP-013 technical checks failed.');
end


%% Diagnostica

exp012Area = [squeeze(sum(exp012Candidates{1}, [1 2])), squeeze(sum(exp012Candidates{2}, [1 2]))];
rows = cell(2, 1);
for n = 1:2
    d = diags{n};
    c = candidates{n};
    a = d.hasAnchor;
    nonEmpty = find(squeeze(any(c, [1 2])));
    rows{n} = {maskModality, noiseLevels(n), nnz(rawMasks{n}), nnz(a), nnz(~a), nnz(d.parentTie), ...
        median(d.nAnchorParents(a)), max(d.nAnchorParents(a)), ...
        median(d.nDirectChildren(a)), max(d.nDirectChildren(a)), nnz(d.nDirectChildren > 1), ...
        sum(d.childrenRawArea - d.anchorArea), sum(d.finalArea - exp012Area(:, n)), ...
        sum(unionFillWouldAdd(:, n)), nnz(c), nnz(c) / numel(c), nonEmpty(1), nonEmpty(end)};
end
summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'MaskModality', 'Noise', 'RawVoxels', 'SlicesWithAnchor', 'SlicesWithoutAnchor', 'ParentTies', ...
     'MedianAnchorParents', 'MaxAnchorParents', 'MedianDirectChildren', 'MaxDirectChildren', ...
     'SlicesWithAddedSiblings', 'AddedSiblingRawArea', 'AddedFinalAreaOverExp012', ...
     'UnionFillWouldAddNotUsed', 'CandidateVoxels', 'CandidateFraction', 'FirstNonEmpty', 'LastNonEmpty'});
disp(summary);

has0 = diags{1}.hasAnchor;
has3 = diags{2}.hasAnchor;
added0 = diags{1}.nAddedSiblings > 0;
added3 = diags{2}.nAddedSiblings > 0;
intersectionOverUnion = nnz(candidates{1} & candidates{2}) / nnz(candidates{1} | candidates{2});
fprintf(['EXP-013 consistency (pn0 vs pn3): IoU = %.4f, differing voxels = %.4f %%\n' ...
         'Slices with candidate: both %d, only pn0 %d, only pn3 %d, neither %d\n'], ...
    intersectionOverUnion, 100 * nnz(xor(candidates{1}, candidates{2})) / numel(candidates{1}), ...
    nnz(has0 & has3), nnz(has0 & ~has3), nnz(~has0 & has3), nnz(~has0 & ~has3));
fprintf('Direct-child count differs (pn0 vs pn3): %d slices: %s\n', ...
    nnz(diags{1}.nDirectChildren ~= diags{2}.nDirectChildren), ...
    slicesAsRanges(find(diags{1}.nDirectChildren ~= diags{2}.nDirectChildren)));
fprintf('Siblings added in both: %s\nSiblings added only pn0: %s\nSiblings added only pn3: %s\n\n', ...
    slicesAsRanges(find(added0 & added3)), slicesAsRanges(find(added0 & ~added3)), ...
    slicesAsRanges(find(~added0 & added3)));

% Tabella delle slice diagnostiche
for n = 1:2
    d = diags{n};
    ks = diagnosticSlices(:);
    disp(table(ks, d.nComponents(ks), d.nNested(ks), d.anchorArea(ks), d.nAnchorParents(ks), ...
        d.parentArea(ks), d.parentEnclosedArea(ks), d.nDirectChildren(ks), d.childrenRawArea(ks), ...
        exp012Area(ks, n), d.finalArea(ks), ...
        'VariableNames', {char("k_" + noiseLevels(n)), 'nComp', 'nNested', 'anchorArea', 'nParents', ...
        'parentArea', 'parentEnclosed', 'nChildren', 'childrenRaw', 'exp012Area', 'exp013Area'}));
end

writetable(summary, fullfile(cfg.paths.metrics, 'exp013_t1_siblings_summary.csv'));
perSliceColumns = {};
perSliceNames = {'k'};
for n = 1:2
    d = diags{n};
    perSliceColumns = [perSliceColumns, {d.nComponents, d.nRelations, d.nNested, d.hasAnchor, ...
        d.anchorIndex, d.anchorArea, d.nAnchorParents, d.parentIndex, d.parentArea, d.parentEnclosedArea, ...
        d.parentTie, d.nDirectChildren, d.nAddedSiblings, d.childrenRawArea, d.finalArea, ...
        exp012Area(:, n), d.finalArea - exp012Area(:, n), unionFillWouldAdd(:, n)}]; %#ok<AGROW>
    perSliceNames = [perSliceNames, cellstr(noiseLevels(n) + "_" + ["nComponents", "nRelations", "nNested", ...
        "hasAnchor", "anchorIndex", "anchorArea", "nAnchorParents", "parentIndex", "parentArea", ...
        "parentEnclosedArea", "parentTie", "nDirectChildren", "nAddedSiblings", "childrenRawArea", ...
        "exp013Area", "exp012Area", "areaGainOverExp012", "unionFillWouldAddNotUsed"])]; %#ok<AGROW>
end
perSlice = table((1:nSlices)', perSliceColumns{:}, 'VariableNames', perSliceNames);
writetable(perSlice, fullfile(cfg.paths.metrics, 'exp013_t1_siblings_per_slice.csv'));


%% Figure (solo maschere e MRI affiancate, nessuna sovrapposizione di contorni)

% 1. Aree e numero di figli diretti per slice
fig1 = figure('Color', 'w');
layout = tiledlayout(fig1, 2, 1, 'TileSpacing', 'compact');
title(layout, 'EXP-013 - per-slice areas: EXP-012 vs EXP-013 candidate, and number of selected direct children', ...
    'Interpreter', 'none');
for n = 1:2
    ax = nexttile(layout);
    yyaxis(ax, 'left');
    plot(ax, 1:nSlices, exp012Area(:, n), 'b-', 1:nSlices, diags{n}.finalArea, 'r--');
    ylabel(ax, 'pixels');
    yyaxis(ax, 'right');
    stairs(ax, 1:nSlices, diags{n}.nDirectChildren, 'k-');
    ylabel(ax, 'direct children');
    legend(ax, 'EXP-012 candidate', 'EXP-013 candidate', 'selected direct children', 'Location', 'north');
    title(ax, sprintf('T1 %s', noiseLevels(n)));
    xlim(ax, [1 nSlices]);
end
xlabel(ax, 'axial slice k');
fig1.Position(3:4) = [950 650];
exportgraphics(fig1, fullfile(cfg.paths.figures, 'exp013_t1_area_per_slice.png'));

% 2. T1 / grezza / ancora / genitore / figli diretti / EXP-012 / EXP-013
for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 7, numel(diagnosticSlices), 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf(['EXP-013 T1 %s - T1 / raw Otsu / EXP-012 anchor / immediate parent (topology only) / ' ...
        'direct children / EXP-012 candidate / EXP-013 candidate'], noiseLevels(n)), 'Interpreter', 'none');
    rowNames = ["T1", "raw", "anchor", "parent", "children", "EXP-012", "EXP-013"];
    for r = 1:7
        for s = 1:numel(diagnosticSlices)
            k = diagnosticSlices(s);
            switch r
                case 1, panel = volumes{n}(:, :, k);
                case 2, panel = rawMasks{n}(:, :, k);
                case 3, panel = anchorMasks{n}(:, :, k);
                case 4, panel = parentMasks{n}(:, :, k);
                case 5, panel = childrenMasks{n}(:, :, k);
                case 6, panel = exp012Candidates{n}(:, :, k);
                case 7, panel = candidates{n}(:, :, k);
            end
            ax = nexttile(layout);
            imagesc(ax, double(panel).');
            colormap(ax, gray);
            clim(ax, [0 1]);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('%s k=%d', rowNames(r), k), 'FontSize', 8);
        end
    end
    fig.Position(3:4) = [1700 1250];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp013_t1_%s_siblings_steps.png', noiseLevels(n))));
end


%% Esito dei controlli

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-48s %s\n', checks{c, 1}, result);
end
fprintf('\nEXP-013 CHECKS: PASS\n');


function text = slicesAsRanges(slices)
%SLICESASRANGES Elenco di slice come intervalli compatti, es. "1-15, 37".
    if isempty(slices)
        text = 'none';
        return
    end
    slices = slices(:).';
    breaks = [0, find(diff(slices) > 1), numel(slices)];
    parts = strings(1, numel(breaks) - 1);
    for b = 1:numel(breaks) - 1
        first = slices(breaks(b) + 1);
        last = slices(breaks(b + 1));
        if first == last
            parts(b) = sprintf('%d', first);
        else
            parts(b) = sprintf('%d-%d', first, last);
        end
    end
    text = char(strjoin(parts, ', '));
end
