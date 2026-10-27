%% Fasi 108-109: visualizzazione 3D finale della pipeline v4 (predizione 3D; confronto 3D GT / predizione)
% Solo visualizzazione: nessuna segmentazione rieseguita (si caricano le predizioni v4 già salvate),
% nessuna metrica nuova, nessuna modifica delle maschere. Stessi tre casi delle fasi 105-107:
% pn3 (moderato, sviluppo), reserved_msles1_n3 (lieve), reserved_msles3_n3 (grave).
% Convenzione 3D: X = dimensione 1 dell'array, Y = dimensione 2, Z = dimensione 3, 1 mm isotropo;
% lo scambio delle prime due dimensioni richiesto da isosurface avviene solo nella copia di
% visualizzazione (renderMask3DSurface). Nessuna etichetta anatomica sinistra / destra.
% Vista fissa per tutti i casi e tutte le figure: view(3) di MATLAB (azimut -37.5, elevazione 30),
% proiezione ortografica, limiti dell'intero volume, una sola camlight.

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
    'caseId',   {"pn3", "reserved_msles1_n3", "reserved_msles3_n3"}, ...
    'phantom',  {"msles2", "msles1", "msles3"}, ...
    'load',     {"moderate", "mild", "severe"}, ...
    'role',     {"DEVELOPMENT_REFERENCE", "RESERVED_TEST_REPLAY", "RESERVED_TEST_REPLAY"}, ...
    'noise',    {3, 3, 3}, ...
    'label',    {"Moderate MS - development reference - 3% noise", "Mild MS - reserved seed 2 - 3% noise", ...
                 "Severe MS - reserved seed 2 - 3% noise"}, ...
    'gt',       {cfg.dataset.groundTruthFile, fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles1_crisp.rawb'), ...
                 fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles3_crisp.rawb')}, ...
    'pred',     {fullfile(P, 'exp060_candidates', 'exp060_k5_pn3.mat'), fullfile(P, 'v4test_v4_msles1_n3_prediction.mat'), ...
                 fullfile(P, 'v4test_v4_msles3_n3_prediction.mat')});
expectedSize = [181 217 181];
cameraAz = -37.5; cameraEl = 30;                       % = view(3), fissata prima di vedere le figure
predColor = [1 0.85 0]; gtColor = [0 0.9 0.9];         % stessi colori delle fasi 105 / 106
errColors = {[0 1 0], [1 0 0], [0 0.35 1]};            % TP / FP / FN, stessi colori della fase 107
alphaPred108 = 0.9; alphaCompare = 0.45; alphaError = 0.6;


%% 0. Integrità prima della visualizzazione

[s4, o4] = system(sprintf('git -C "%s" rev-list -n 1 v4-frozen', projectRoot));
v4Manifest = readtable(fullfile(projectRoot, 'docs', 'v4_freeze_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
p103 = readtable(fullfile(M, 'phase103_runner_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
p105 = readtable(fullfile(M, 'phase105_107_figure_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
manifestOk = @(t) all(arrayfun(@(i) strcmp(sha256File(fullfile(projectRoot, t.path(i))), t.sha256(i)), 1:height(t)));
known = containers.Map('KeyType', 'char', 'ValueType', 'any');
for mf = ["phase101_result_manifest.csv" "v4_reserved_test_manifest.csv"]
    t = readtable(fullfile(M, mf), 'TextType', 'string', 'Delimiter', ',');
    for r = 1:height(t)
        known(char(t.path(r))) = t.sha256(r);
    end
end
gtKnown = all(arrayfun(@(c) isKey(known, char(rel(c.gt))) && strcmp(sha256File(c.gt), char(known(char(rel(c.gt))))), cases));
hashesBefore = string(arrayfun(@(c) sha256File(c.pred), cases, 'UniformOutput', false));
reservedPredsKnown = all(arrayfun(@(i) strcmp(hashesBefore(i), char(known(char(rel(cases(i).pred))))), 2:3));
idx105 = readtable(fullfile(M, 'phase105_107_visualization_index.csv'), 'TextType', 'string', 'Delimiter', ',');
sameAs105 = isequal(idx105.caseId(1:3).', [cases.caseId]) && isequal(idx105.predictionSource(1:3).', rel(string({cases.pred})));
statusText = fileread(fullfile(projectRoot, 'docs', 'PROJECT_STATUS.md'));
checks = [checks; {
    "1-3 Phases 105-107 COMPLETE; Phase-105/107 figure manifest valid", ...
        contains(statusText, 'final 2D visualization: COMPLETE') && manifestOk(p105)
    "4-6 final pipeline v4 / V4_K5: tag v4-frozen -> 2525dde; 14 frozen hashes valid BEFORE", s4 == 0 && ...
        startsWith(strtrim(string(o4)), "2525dde") && height(v4Manifest) == 14 && manifestOk(v4Manifest)
    "Phase-103 outputs exist and match their manifest", manifestOk(p103)
    "7-8 same three cases and prediction files as Phases 105-107; GT matches recorded SHA-256; reserved v4 predictions match the reserved-test manifest", ...
        sameAs105 && gtKnown && reservedPredsKnown
    }];
if any(~[checks{:, 2}])
    error('phase108:blocked', 'PHASES 108-109 TECHNICALLY BLOCKED: integrity checks failed.');
end


%% 1. Caricamento (nessuna segmentazione) e verifica contro la fase 103

r103 = readtable(fullfile(M, 'phase103_runner_metrics.csv'), 'TextType', 'string', 'Delimiter', ',');
data = struct([]);
countsOk = true;
for i = 1:numel(cases)
    c = cases(i);
    cfgG = cfg; cfgG.dataset.groundTruthFile = c.gt;
    labels = loadBrainwebGroundTruth(cfgG);
    s = load(c.pred, 'M_pred');
    pred = s.M_pred;
    gt = labels == 10;
    if ~islogical(pred) || ~isequal(size(pred), size(gt), expectedSize)
        error('phase108:blocked', 'PHASES 108-109 TECHNICALLY BLOCKED: dimension / type mismatch for %s.', c.caseId);
    end
    tp = pred & gt; fp = pred & ~gt; fn = ~pred & gt;
    ccP = bwconncomp(pred, 26); ccG = bwconncomp(gt, 26);
    row = r103(r103.caseId == c.caseId & r103.version == "v4", :);
    countsOk = countsOk && height(row) == 1 && row.configId == "V4_K5" && row.predictedVoxels == nnz(pred) && ...
        row.TP == nnz(tp) && row.FP == nnz(fp) && row.FN == nnz(fn) && row.gtLesionVoxels == nnz(gt) && ...
        row.predictedComponents == ccP.NumObjects && row.gtLesions == ccG.NumObjects;
    data(i).pred = pred; data(i).gt = gt; data(i).tp = tp; data(i).fp = fp; data(i).fn = fn; %#ok<SAGROW>
    data(i).nCompPred = ccP.NumObjects; data(i).nCompGt = ccG.NumObjects;
end
if ~countsOk
    error('phase108:blocked', ['PHASES 108-109 TECHNICALLY BLOCKED - VISUALIZATION INPUT DOES NOT MATCH ' ...
        'AUTHORITATIVE PHASE-103 RESULTS.']);
end


%% 2. Fase 108 (predizione 3D), fase 109 (GT + predizione; TP / FP / FN)

figs = struct('p108', fullfile(F, 'phase108_v4_3d_prediction.png'), ...
    'p109', fullfile(F, 'phase109_v4_3d_gt_prediction_comparison.png'), 'p109err', fullfile(F, 'phase109_v4_3d_tp_fp_fn.png'));
panelTitle = @(i) sprintf('%s\n%s', cases(i).caseId, cases(i).label);
render = struct([]);
cameraUsed = zeros(0, 2);

for figKey = ["p108" "p109" "p109err"]
    fig = figure('Color', 'w', 'Position', [100 100 1650 620]);
    layout = tiledlayout(fig, 1, numel(cases), 'TileSpacing', 'compact', 'Padding', 'compact');
    for i = 1:numel(cases)
        ax = nexttile(layout);
        hold(ax, 'on');
        switch figKey
            case "p108"
                [~, info] = renderMask3DSurface(ax, data(i).pred, predColor, alphaPred108);
                render(i).p108 = info;
            case "p109"
                [~, infoG] = renderMask3DSurface(ax, data(i).gt, gtColor, alphaCompare);
                [~, infoP] = renderMask3DSurface(ax, data(i).pred, predColor, alphaCompare);
                render(i).p109gt = infoG; render(i).p109pred = infoP;
            case "p109err"
                sets = {data(i).tp, data(i).fp, data(i).fn};
                for e = 1:3
                    [~, infoE] = renderMask3DSurface(ax, sets{e}, errColors{e}, alphaError);
                    render(i).err(e) = infoE;
                end
        end
        hold(ax, 'off');
        daspect(ax, [1 1 1]);
        xlim(ax, [0.5 expectedSize(1) + 0.5]); ylim(ax, [0.5 expectedSize(2) + 0.5]); zlim(ax, [0.5 expectedSize(3) + 0.5]);
        view(ax, cameraAz, cameraEl);
        set(ax, 'Projection', 'orthographic', 'Box', 'on', 'FontSize', 8, 'XGrid', 'off', 'YGrid', 'off', 'ZGrid', 'off');
        camlight(ax, 'headlight');
        lighting(ax, 'gouraud');
        material(ax, 'dull');
        xlabel(ax, 'X (dim 1, voxel)'); ylabel(ax, 'Y (dim 2, voxel)'); zlabel(ax, 'Z (dim 3, slice)');
        title(ax, panelTitle(i), 'FontSize', 9, 'Interpreter', 'none');
        [az, el] = view(ax);
        cameraUsed(end+1, :) = [az el]; %#ok<SAGROW>
    end
    ax = nexttile(layout, numel(cases));
    hold(ax, 'on');
    switch figKey
        case "p108"
            title(layout, 'Phase 108 - final v4 (V4\_K5) predicted lesion mask, complete 3D volume (yellow surface)');
            h = patch(ax, NaN, NaN, predColor); names = {'v4 prediction'};
        case "p109"
            title(layout, 'Phase 109 - ground truth (cyan, label 10) vs final v4 prediction (yellow), semi-transparent');
            h = [patch(ax, NaN, NaN, gtColor, 'FaceAlpha', alphaCompare), patch(ax, NaN, NaN, predColor, 'FaceAlpha', alphaCompare)];
            names = {'GT', 'v4 prediction'};
        case "p109err"
            title(layout, 'Phase 109 - v4 errors in 3D: green = TP, red = FP, blue = FN (TN not shown)');
            h = [patch(ax, NaN, NaN, errColors{1}), patch(ax, NaN, NaN, errColors{2}), patch(ax, NaN, NaN, errColors{3})];
            names = {'TP', 'FP', 'FN'};
    end
    hold(ax, 'off');
    legend(ax, h, names, 'Location', 'southoutside', 'Orientation', 'horizontal');
    subtitle(layout, ['Full volume 181 x 217 x 181, 1 mm isotropic, same fixed view (az -37.5, el 30) for every case; ' ...
        'isosurface at 0.5 of the unchanged binary mask; no smoothing, no component removal']);
    exportgraphics(fig, figs.(figKey), 'Resolution', 250);
    close(fig);
end


%% 3. Verifiche della visualizzazione e indice

% Riquadro dei vertici = riquadro dei voxel ± 0.5 lungo (dim 1, dim 2, dim 3): conferma X / Y / Z
boxOk = @(mask, info) max(abs(double(info.vertexRange) - (voxelBox(mask) + [-0.5 0.5])), [], 'all') < 1e-6;
emptySafe = @(mask, info) (nnz(mask) == 0 && info.vertexCount == 0) || (nnz(mask) > 0 && info.faceCount > 0 && boxOk(mask, info));
masksOk = true; geometryOk = true;
indexRows = cell(0, 23);
for i = 1:numel(cases)
    d = data(i);
    masksOk = masksOk && ~any(d.tp & d.fp, 'all') && ~any(d.tp & d.fn, 'all') && ~any(d.fp & d.fn, 'all') && ...
        isequal(d.tp | d.fp, d.pred) && isequal(d.tp | d.fn, d.gt);
    geometryOk = geometryOk && emptySafe(d.pred, render(i).p108) && emptySafe(d.gt, render(i).p109gt) && ...
        emptySafe(d.pred, render(i).p109pred) && isequaln(render(i).p108, render(i).p109pred) && ...
        emptySafe(d.tp, render(i).err(1)) && emptySafe(d.fp, render(i).err(2)) && emptySafe(d.fn, render(i).err(3));
    indexRows(end+1, :) = {cases(i).caseId, cases(i).phantom, cases(i).load, cases(i).role, cases(i).noise, "v4", ...
        rel(cases(i).pred), rel(cases(i).gt), nnz(d.pred), nnz(d.gt), nnz(d.tp), nnz(d.fp), nnz(d.fn), ...
        d.nCompPred, d.nCompGt, "X=dim1;Y=dim2;Z=dim3", "display-only permute([2 1 3]) for isosurface", ...
        "1x1x1", cameraAz, cameraEl, rel(figs.p108), rel(figs.p109), rel(figs.p109err)}; %#ok<SAGROW>
end
index = cell2table(indexRows, 'VariableNames', {'caseId', 'phantom', 'lesionLoad', 'role', 'noisePercent', 'version', ...
    'predictionSource', 'gtSource', 'predictionVoxels', 'gtVoxels', 'tpVoxels', 'fpVoxels', 'fnVoxels', ...
    'predictionComponents', 'gtComponents', 'coordinateConvention', 'displayPermutation', 'voxelSpacingMm', ...
    'cameraAzimuth', 'cameraElevation', 'phase108Figure', 'phase109ComparisonFigure', 'phase109ErrorFigure'});
writetable(index, fullfile(M, 'phase108_109_visualization_index.csv'));
disp(index(:, {'caseId', 'predictionVoxels', 'gtVoxels', 'tpVoxels', 'fpVoxels', 'fnVoxels', ...
    'predictionComponents', 'gtComponents'}));

hashesAfter = string(arrayfun(@(c) sha256File(c.pred), cases, 'UniformOutput', false));
gtAfter = all(arrayfun(@(c) strcmp(sha256File(c.gt), char(known(char(rel(c.gt))))), cases));
helperFile = fullfile(cfg.paths.visualization, 'renderMask3DSurface.m');
code = '';
for f = {[mfilename('fullpath') '.m'], helperFile}
    code = [code newline char(strjoin(regexprep(splitlines(string(fileread(f{1}))), '%.*$', ''), newline))]; %#ok<AGROW>
end
forbidden = {['generateV4' 'Prediction('], ['generateFinal' 'Prediction('], ['smo' 'oth3('], ['reduce' 'patch('], ...
    ['reduce' 'volume('], ['imres' 'ize3('], ['imdi' 'late('], ['imcl' 'ose('], ['bwarea' 'open('], ['vol' 'show('], ...
    ['computeDice' 'FromConfusion('], ['sa' 've('], ['EXP-0' '62']};
checks = [checks; {
    "9-15 saved v4 predictions + GT label 10 loaded; logical 181x217x181; complete 3D masks; no segmentation rerun", ...
        all(arrayfun(@(d) islogical(d.pred) && islogical(d.gt) && isequal(size(d.pred), expectedSize), data)) && ...
        ~any(cellfun(@(f) contains(code, f), forbidden(1:2)))
    "16-20, 33 X = dim 1, Y = dim 2, Z = dim 3 (vertex box = voxel box +/- 0.5 for every surface); empty masks skipped safely", ...
        geometryOk
    "22-25 isotropic aspect; same camera (az -37.5, el 30) and same full-volume limits for every panel", ...
        all(abs(cameraUsed(:, 1) - cameraAz) < 1e-9 & abs(cameraUsed(:, 2) - cameraEl) < 1e-9) && size(cameraUsed, 1) == 9
    "34-40 TP = P&GT, FP = P&~GT, FN = ~P&GT; pairwise disjoint; TP|FP = prediction; TP|FN = GT", masksOk
    "41-44 prediction / GT / TP / FP / FN voxels and 26-connected component counts equal Phase 103 (v4)", countsOk
    "28-30, 48 no smoothing, downsampling, component filtering, volume rendering, metric recomputation or MAT saving", ...
        ~any(cellfun(@(f) contains(code, f), forbidden(3:end)))
    "53-58 v4 frozen hashes, predictions, GT, Phase-103 and Phase-105/107 outputs, config.m unchanged AFTER", ...
        manifestOk(v4Manifest) && manifestOk(p103) && manifestOk(p105) && isequal(hashesBefore, hashesAfter) && ...
        gtAfter && isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];
for i = 1:size(checks, 1)
    fprintf('%-120s %s\n', checks{i, 1}, ternary(checks{i, 2}, 'ok', 'FAILED'));
end
if any(~[checks{:, 2}])
    error('phase108:checksFailed', 'PHASES 108-109 checks failed.');
end

outputs = [string(figs.p108); string(figs.p109); string(figs.p109err); ...
    string(fullfile(M, 'phase108_109_visualization_index.csv')); string([mfilename('fullpath') '.m']); string(helperFile)];
writetable(table(rel(outputs), string(cellfun(@sha256File, cellstr(outputs), 'UniformOutput', false)), ...
    'VariableNames', {'path', 'sha256'}), fullfile(M, 'phase108_109_figure_manifest.csv'));
fprintf('\nPHASES 108-109 VISUALIZATION: PASS (%d)\n', size(checks, 1));


function box = voxelBox(mask)
%VOXELBOX Riquadro [min max] degli indici dei voxel attivi lungo le dimensioni 1, 2, 3.
    [i, j, k] = ind2sub(size(mask), find(mask));
    box = [min(i) max(i); min(j) max(j); min(k) max(k)];
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
    [status, out] = system(sprintf('certutil -hashfile "%s" SHA256', f));
    lines = erase(strtrim(splitlines(string(out))), " ");
    match = lines(strlength(lines) == 64 & ~cellfun(@isempty, regexp(cellstr(lines), '^[0-9a-fA-F]{64}$')));
    if status ~= 0 || numel(match) ~= 1
        error('phase108:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
