%% Fasi 105-107: visualizzazione 2D finale della pipeline v4 (MRI + predizione, MRI + GT, TP / FP / FN)
% Solo visualizzazione: nessuna segmentazione rieseguita (si caricano le predizioni v4 già salvate),
% nessuna metrica nuova, nessuna modifica di maschere, MRI o GT.
% Casi predefiniti: pn3 (moderato, sviluppo), reserved_msles1_n3 (lieve), reserved_msles3_n3 (grave);
% diagnostica opzionale: reserved_normal_n3 (nessuna lesione).
% Slice: argmax_k dei voxel GT di lesione (parità -> k più piccolo), scelta SOLO per la visualizzazione,
% identica nelle tre figure. Normal: argmax_k dei voxel predetti dalla v4 (solo visualizzazione).
% Convenzione del progetto: sezione trasposta solo per la visualizzazione, YDir normal, nessun flip;
% grigi della T2 grezza con intervallo [min max] del volume (solo visualizzazione).

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.visualization);
M = cfg.paths.metrics; F = cfg.paths.figures; P = cfg.paths.processedData;
rel = @(p) strrep(erase(string(p), string(projectRoot) + filesep), '\', '/');
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));
c101 = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'phase101');
cRes = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'v4_reserved_test');
checks = cell(0, 2);

cases = struct( ...
    'caseId',   {"pn3", "reserved_msles1_n3", "reserved_msles3_n3", "reserved_normal_n3"}, ...
    'phantom',  {"msles2", "msles1", "msles3", "normal"}, ...
    'load',     {"moderate", "mild", "severe", "none"}, ...
    'role',     {"DEVELOPMENT_REFERENCE", "RESERVED_TEST_REPLAY", "RESERVED_TEST_REPLAY", "RESERVED_TEST_REPLAY"}, ...
    'noise',    {3, 3, 3, 3}, ...
    'label',    {"Moderate MS - development reference - 3% noise", "Mild MS - reserved seed 2 - 3% noise", ...
                 "Severe MS - reserved seed 2 - 3% noise", "Normal phantom - reserved seed 2 - 3% noise"}, ...
    't2',       {cfg.dataset.noisyMriFiles.pn3.T2, ...
                 fullfile(cRes, 'mri', 'custom_msles1_t2_ai_1mm_n3_inu0_seed2_job1261017-094235s-2845389.raws'), ...
                 fullfile(cRes, 'mri', 'custom_msles3_t2_ai_1mm_n3_inu0_seed2_job1261017-094329s-2845552.raws'), ...
                 fullfile(cRes, 'mri', 'custom_normal_t2_ai_1mm_n3_inu0_seed2_job1261017-094153s-2845233.raws')}, ...
    'gt',       {cfg.dataset.groundTruthFile, fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles1_crisp.rawb'), ...
                 fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles3_crisp.rawb'), ...
                 fullfile(cRes, 'ground_truth', 'phantom_1.0mm_normal_crisp.rawb')}, ...
    'pred',     {fullfile(P, 'exp060_candidates', 'exp060_k5_pn3.mat'), fullfile(P, 'v4test_v4_msles1_n3_prediction.mat'), ...
                 fullfile(P, 'v4test_v4_msles3_n3_prediction.mat'), fullfile(P, 'v4test_v4_normal_n3_prediction.mat')});
core = 1:3; normalIdx = 4;


%% 0. Integrità prima della visualizzazione

[s4, o4] = system(sprintf('git -C "%s" rev-list -n 1 v4-frozen', projectRoot));
v4Manifest = readtable(fullfile(projectRoot, 'docs', 'v4_freeze_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
p103 = readtable(fullfile(M, 'phase103_runner_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
manifestOk = @(t) all(arrayfun(@(i) strcmp(sha256File(fullfile(projectRoot, t.path(i))), t.sha256(i)), 1:height(t)));
known = containers.Map('KeyType', 'char', 'ValueType', 'any');
for mf = ["phase101_result_manifest.csv" "v4_reserved_test_manifest.csv"]
    t = readtable(fullfile(M, mf), 'TextType', 'string', 'Delimiter', ',');
    for r = 1:height(t)
        known(char(t.path(r))) = t.sha256(r);
    end
end
known(char(rel(cfg.dataset.noisyMriFiles.pn3.T2))) = "52AF70628F1211CCEF850F61E715D4D743102EAF29AD1337CDEB61BBCCFE0F7E";
inputsKnown = true;
for c = cases
    for f = [string(c.t2), string(c.gt)]
        inputsKnown = inputsKnown && isKey(known, char(rel(f))) && strcmp(sha256File(f), char(known(char(rel(f)))));
    end
end
hashesBefore = string(arrayfun(@(c) sha256File(c.pred), cases, 'UniformOutput', false));
reservedPredsKnown = all(arrayfun(@(i) strcmp(hashesBefore(i), char(known(char(rel(cases(i).pred))))), 2:4));
statusText = fileread(fullfile(projectRoot, 'docs', 'PROJECT_STATUS.md'));
checks = [checks; {
    "1-2 Phase 103 COMPLETE (Phase 104 fulfilled by Phase 103)", contains(statusText, 'automated experiment runner: COMPLETE')
    "3-5 final pipeline v4 / V4_K5: tag v4-frozen -> 2525dde; 14 frozen hashes valid BEFORE", s4 == 0 && ...
        startsWith(strtrim(string(o4)), "2525dde") && manifestOk(v4Manifest)
    "Phase-103 outputs exist and match their manifest", manifestOk(p103)
    "T2 and GT inputs match recorded SHA-256; reserved v4 predictions match the reserved-test manifest", ...
        inputsKnown && reservedPredsKnown
    }];
if any(~[checks{:, 2}])
    error('phase105:blocked', 'PHASES 105-107 TECHNICALLY BLOCKED: integrity checks failed.');
end


%% 1. Caricamento (nessuna segmentazione) e scelta deterministica delle slice

data = struct([]);
for i = 1:numel(cases)
    c = cases(i);
    cfgC = cfg;
    cfgC.dataset.noisyMriFiles.vis.T2 = c.t2;
    t2 = loadBrainwebMri(cfgC, "T2", "vis");
    cfgG = cfg; cfgG.dataset.groundTruthFile = c.gt;
    labels = loadBrainwebGroundTruth(cfgG);
    s = load(c.pred, 'M_pred');
    pred = s.M_pred;
    gt = labels == 10;
    if ~isequal(size(t2), size(labels), size(pred)) || ~islogical(pred)
        error('phase105:blocked', 'PHASES 105-107 TECHNICALLY BLOCKED: dimension / type mismatch for %s.', c.caseId);
    end
    if c.phantom == "normal"
        [~, k] = max(squeeze(sum(pred, [1 2])));      % solo visualizzazione; parità -> primo k
        rule = "MAX_V4_PREDICTED_VOXELS_FOR_DISPLAY_ONLY";
    else
        [~, k] = max(squeeze(sum(gt, [1 2])));        % max restituisce il primo massimo = k più piccolo
        rule = "MAX_GT_LESION_VOXELS_FOR_DISPLAY_ONLY";
    end
    data(i).t2 = t2; data(i).pred = pred; data(i).gt = gt; data(i).k = k; data(i).rule = rule; %#ok<SAGROW>
    data(i).range = double([min(t2(:)) max(t2(:))]);
    data(i).labelMax = max(labels(:));
end


%% 2. Fase 105 (MRI + predizione), fase 106 (MRI + GT), fase 107 (TP / FP / FN)

figs = struct('p105', fullfile(F, 'phase105_v4_mri_prediction.png'), 'p106', fullfile(F, 'phase106_v4_mri_ground_truth.png'), ...
    'p107', fullfile(F, 'phase107_v4_tp_fp_fn.png'), 'normal', fullfile(F, 'phase107_v4_normal_false_positive_diagnostic.png'));
predColor = [1 0.85 0]; gtColor = [0 0.9 0.9]; fillAlpha = 0.45;
panelTitle = @(i) sprintf('%s\n%s, k = %d', cases(i).caseId, cases(i).label, data(i).k);

for which = ["p105" "p106" "p107"]
    fig = figure('Color', 'w', 'Position', [100 100 1500 560]);
    layout = tiledlayout(fig, 1, numel(core), 'TileSpacing', 'compact', 'Padding', 'compact');
    for i = core
        ax = nexttile(layout);
        k = data(i).k;
        mriSlice = double(data(i).t2(:, :, k));
        switch which
            case "p105"
                overlayMaskBoundaryOnMRI(ax, mriSlice, data(i).pred(:, :, k), 'BoundaryColor', predColor, ...
                    'ShowFill', true, 'FillAlpha', fillAlpha, 'DisplayRange', data(i).range, 'Title', panelTitle(i));
            case "p106"
                overlayMaskBoundaryOnMRI(ax, mriSlice, data(i).gt(:, :, k), 'BoundaryColor', gtColor, ...
                    'ShowFill', true, 'FillAlpha', fillAlpha, 'DisplayRange', data(i).range, 'Title', panelTitle(i));
            case "p107"
                cnt = overlayErrorMapOnMRI(ax, mriSlice, data(i).pred(:, :, k), data(i).gt(:, :, k), 'Alpha', 0.6, ...
                    'DisplayRange', data(i).range, 'Title', panelTitle(i));
                data(i).sliceCounts = cnt;
        end
        set(ax, 'FontSize', 9);
    end
    switch which
        case "p105"
            title(layout, 'Phase 105 - final v4 (V4\_K5) prediction on T2 (yellow fill + boundary)');
        case "p106"
            title(layout, 'Phase 106 - ground truth, label 10 = MS lesion, on T2 (cyan fill + boundary)');
        case "p107"
            title(layout, 'Phase 107 - v4 errors on T2: green = TP, red = FP, blue = FN (TN not shown)');
            ax = nexttile(layout, numel(core));
            hold(ax, 'on');
            h = [patch(ax, NaN, NaN, [0 1 0]), patch(ax, NaN, NaN, [1 0 0]), patch(ax, NaN, NaN, [0 0.35 1])];
            hold(ax, 'off');
            legend(ax, h, {'TP', 'FP', 'FN'}, 'Location', 'southoutside', 'Orientation', 'horizontal');
    end
    subtitle(layout, 'Display slice = axial slice with most GT lesion voxels (chosen after segmentation, for display only)');
    exportgraphics(fig, figs.(which), 'Resolution', 200);
    close(fig);
end

% Diagnostica opzionale: fantoccio normal (GT vuoto: ogni voxel predetto è FP)
n = normalIdx; k = data(n).k;
fig = figure('Color', 'w', 'Position', [100 100 1000 520]);
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile(layout);
overlayMaskBoundaryOnMRI(ax, double(data(n).t2(:, :, k)), false(size(data(n).pred(:, :, k))), ...
    'DisplayRange', data(n).range, 'Title', sprintf('T2, k = %d', k));
ax = nexttile(layout);
cntNormal = overlayErrorMapOnMRI(ax, double(data(n).t2(:, :, k)), data(n).pred(:, :, k), data(n).gt(:, :, k), ...
    'Alpha', 0.75, 'DisplayRange', data(n).range, 'Title', sprintf('v4 prediction = false positives (red), k = %d', k));
data(n).sliceCounts = cntNormal;
title(layout, {'BrainWeb normal phantom - 0 GT lesion voxels - reserved seed-2 replay - 3% noise', ...
    'display slice selected by maximum v4 prediction only (worst residual FP slice)'});
exportgraphics(fig, figs.normal, 'Resolution', 200);
close(fig);


%% 3. Verifiche della visualizzazione e indice

indexRows = cell(0, 17);
masksOk = true;
for i = 1:numel(cases)
    k = data(i).k; p = data(i).pred; g = data(i).gt;
    tp = p & g; fp = p & ~g; fn = ~p & g;
    masksOk = masksOk && ~any(tp & fp, 'all') && ~any(tp & fn, 'all') && ~any(fp & fn, 'all') && ...
        isequal(tp | fp, p) && isequal(tp | fn, g) && ...
        data(i).sliceCounts.TP + data(i).sliceCounts.FP == nnz(p(:, :, k)) && ...
        data(i).sliceCounts.TP + data(i).sliceCounts.FN == nnz(g(:, :, k));
    isNormal = i == normalIdx;
    indexRows(end+1, :) = {cases(i).caseId, cases(i).phantom, cases(i).load, cases(i).role, cases(i).noise, "v4", ...
        rel(cases(i).pred), k, data(i).rule, nnz(g(:, :, k)), nnz(p(:, :, k)), data(i).sliceCounts.TP, ...
        data(i).sliceCounts.FP, data(i).sliceCounts.FN, ternary(isNormal, "", rel(figs.p105)), ...
        ternary(isNormal, "", rel(figs.p106)), ternary(isNormal, rel(figs.normal), rel(figs.p107))}; %#ok<SAGROW>
end
index = cell2table(indexRows, 'VariableNames', {'caseId', 'phantom', 'lesionLoad', 'role', 'noisePercent', 'version', ...
    'predictionSource', 'sliceIndex', 'sliceSelectionRule', 'gtLesionVoxelsInSlice', 'predictedVoxelsInSlice', ...
    'tpVoxelsInSlice', 'fpVoxelsInSlice', 'fnVoxelsInSlice', 'phase105Figure', 'phase106Figure', 'phase107Figure'});
writetable(index, fullfile(M, 'phase105_107_visualization_index.csv'));
disp(index(:, {'caseId', 'sliceIndex', 'sliceSelectionRule', 'gtLesionVoxelsInSlice', 'predictedVoxelsInSlice', ...
    'tpVoxelsInSlice', 'fpVoxelsInSlice', 'fnVoxelsInSlice'}));

hashesAfter = string(arrayfun(@(c) sha256File(c.pred), cases, 'UniformOutput', false));
inputsAfter = true;
for c = cases
    for f = [string(c.t2), string(c.gt)]
        inputsAfter = inputsAfter && strcmp(sha256File(f), char(known(char(rel(f)))));
    end
end
code = strjoin(regexprep(splitlines(string(fileread([mfilename('fullpath') '.m']))), '%.*$', ''), newline);
forbidden = {['generateV4' 'Prediction('], ['generateFinal' 'Prediction('], ['imdi' 'late('], ['imcl' 'ose('], ...
    ['bwarea' 'open('], ['computeDice' 'FromConfusion('], ['sa' 've('], ['EXP-0' '62']};
checks = [checks; {
    "6-10 three predefined lesion cases (+ optional normal); saved v4 predictions loaded; T2 background; no segmentation rerun", ...
        numel(core) == 3 && ~any(cellfun(@(f) contains(code, f), forbidden(1:2)))
    "11-12 GT = label 10; MRI / GT / prediction dimensions identical; normal phantom has no label 10", ...
        all(arrayfun(@(i) isequal(size(data(i).t2), size(data(i).gt)), 1:4)) && ~any(data(normalIdx).gt(:)) && data(normalIdx).labelMax <= 9
    "15-18 one deterministic slice per case (max GT voxels, first maximum); same slice in figures 105-107", ...
        all(arrayfun(@(i) data(i).k == find(squeeze(sum(data(i).gt, [1 2])) == max(squeeze(sum(data(i).gt, [1 2]))), 1), core))
    "27-32 TP / FP / FN pairwise disjoint; TP|FP = prediction; TP|FN = GT; slice counts consistent", masksOk
    "19-21, 38, 42-47 masks / MRI / GT unaltered (no morphology, no metric recomputation, nothing saved but figures / index)", ...
        ~any(cellfun(@(f) contains(code, f), forbidden(3:end)))
    "49-52 v4 frozen hashes, prediction files, MRI / GT, Phase-103 outputs and config.m unchanged AFTER", ...
        manifestOk(v4Manifest) && manifestOk(p103) && isequal(hashesBefore, hashesAfter) && inputsAfter && ...
        isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];
for i = 1:size(checks, 1)
    fprintf('%-100s %s\n', checks{i, 1}, ternary(checks{i, 2}, 'ok', 'FAILED'));
end
if any(~[checks{:, 2}])
    error('phase105:checksFailed', 'PHASES 105-107 checks failed.');
end

outputs = [string(figs.p105); string(figs.p106); string(figs.p107); string(figs.normal); ...
    string(fullfile(M, 'phase105_107_visualization_index.csv')); string([mfilename('fullpath') '.m'])];
writetable(table(rel(outputs), string(cellfun(@sha256File, cellstr(outputs), 'UniformOutput', false)), ...
    'VariableNames', {'path', 'sha256'}), fullfile(M, 'phase105_107_figure_manifest.csv'));
fprintf('\nPHASES 105-107 VISUALIZATION: PASS (%d)\n', size(checks, 1));


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
        error('phase105:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
