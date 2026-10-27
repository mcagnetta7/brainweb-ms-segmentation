%% Fasi 108-109, variante facoltativa: figure 3D con contesto cerebrale trasparente (solo visualizzazione)
% Aggiunge alle figure canoniche 108 / 109 (che restano invariate) una superficie grigia molto trasparente
% della maschera cerebrale automatica EXP-021, ricalcolata dalla T1 con gli stessi helper congelati della v4
% (initialSupportMask + brainMask3DErodeSelectDilate sfera 3, 26). Solo il primo passo della pipeline:
% nessuna segmentazione delle lesioni, nessun GT nel calcolo della maschera cerebrale. La maschera è
% verificata contro brainMaskVoxels della fase 103 e non viene salvata.
% Stessi casi, predizioni, GT, colori, vista (az -37.5, el 30), limiti e helper (renderMask3DSurface)
% dello script canonico phase108_109_final_3d_visualization.m.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.visualization);
M = cfg.paths.metrics; F = cfg.paths.figures;
rel = @(p) strrep(erase(string(p), string(projectRoot) + filesep), '\', '/');
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));
cRes = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'v4_reserved_test');
checks = cell(0, 2);

idx108 = readtable(fullfile(M, 'phase108_109_visualization_index.csv'), 'TextType', 'string', 'Delimiter', ',');
cases = struct( ...
    'caseId', {"pn3", "reserved_msles1_n3", "reserved_msles3_n3"}, ...
    'label',  {"Moderate MS - development reference - 3% noise", "Mild MS - reserved seed 2 - 3% noise", ...
               "Severe MS - reserved seed 2 - 3% noise"}, ...
    't1',     {cfg.dataset.noisyMriFiles.pn3.T1, ...
               fullfile(cRes, 'mri', 'custom_msles1_t1_ai_1mm_n3_inu0_seed2_job1261017-094208s-2845311.raws'), ...
               fullfile(cRes, 'mri', 'custom_msles3_t1_ai_1mm_n3_inu0_seed2_job1261017-094301s-2845466.raws')});
expectedSize = [181 217 181];
cameraAz = -37.5; cameraEl = 30;
predColor = [1 0.85 0]; gtColor = [0 0.9 0.9];
brainColor = [0.55 0.55 0.55]; brainAlpha = 0.07;
alphaPred108 = 0.9; alphaCompare = 0.45;


%% 0. Integrità prima della visualizzazione

[s4, o4] = system(sprintf('git -C "%s" rev-list -n 1 v4-frozen', projectRoot));
v4Manifest = readtable(fullfile(projectRoot, 'docs', 'v4_freeze_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
p103 = readtable(fullfile(M, 'phase103_runner_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
p105 = readtable(fullfile(M, 'phase105_107_figure_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
p108 = readtable(fullfile(M, 'phase108_109_figure_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
manifestOk = @(t) all(arrayfun(@(i) strcmp(sha256File(fullfile(projectRoot, t.path(i))), t.sha256(i)), 1:height(t)));
known = containers.Map('KeyType', 'char', 'ValueType', 'any');
for mf = ["phase101_result_manifest.csv" "v4_reserved_test_manifest.csv"]
    t = readtable(fullfile(M, mf), 'TextType', 'string', 'Delimiter', ',');
    for r = 1:height(t)
        known(char(t.path(r))) = t.sha256(r);
    end
end
% T1 pn3: impronta registrata in questa fase (nessun manifest precedente la elenca); la verifica
% sostanziale è il confronto della maschera cerebrale con la fase 103.
known(char(rel(cfg.dataset.noisyMriFiles.pn3.T1))) = "AC7C6136D99F83FC6BCBF44111D2541996A146E946433F8AF2F39E95A9D8B8FE";
inputs = [string({cases.t1}), idx108.predictionSource.', idx108.gtSource.'];
inputs(4:end) = string(fullfile(projectRoot, inputs(4:end)));
inputHash = @(f) knownHash(known, char(rel(f)));
predHashesBefore = string(arrayfun(@(f) sha256File(f), inputs(4:6), 'UniformOutput', false));
inputsKnown = all(arrayfun(@(f) inputHash(f) == "" || strcmp(sha256File(f), inputHash(f)), inputs)) && ...
    all(arrayfun(@(f) inputHash(f) ~= "", inputs([1:3 5:9])));
checks = [checks; {
    "Phases 108-109 canonical figures and index match their manifest; Phase-105/107 and Phase-103 manifests valid", ...
        manifestOk(p108) && manifestOk(p105) && manifestOk(p103)
    "v4-frozen -> 2525dde; 14 frozen hashes valid BEFORE", s4 == 0 && startsWith(strtrim(string(o4)), "2525dde") && ...
        height(v4Manifest) == 14 && manifestOk(v4Manifest)
    "same three cases as the canonical figures; T1, GT and reserved predictions match recorded SHA-256", ...
        isequal(idx108.caseId.', [cases.caseId]) && inputsKnown
    }];
if any(~[checks{:, 2}])
    error('phase108ctx:blocked', 'BRAIN-CONTEXT VARIANT BLOCKED: integrity checks failed.');
end


%% 1. Caricamento; maschera cerebrale EXP-021 dalla sola T1 (primo passo congelato, nessuna lesione)

r103 = readtable(fullfile(M, 'phase103_runner_metrics.csv'), 'TextType', 'string', 'Delimiter', ',');
data = struct([]);
brainOk = true; lesionOk = true;
for i = 1:numel(cases)
    cfgC = cfg; cfgC.dataset.noisyMriFiles.vis.T1 = cases(i).t1;
    rawT1 = loadBrainwebMri(cfgC, "T1", "vis");
    t1Norm = normalizeFixedRange(convertToWorkingClass(rawT1, "double"), [0 4095], [0 1]);
    brainMask = brainMask3DErodeSelectDilate(initialSupportMask(t1Norm), 3, 26);
    cfgG = cfg; cfgG.dataset.groundTruthFile = char(inputs(6 + i));
    gt = loadBrainwebGroundTruth(cfgG) == 10;
    s = load(inputs(3 + i), 'M_pred');
    pred = s.M_pred;
    row = r103(r103.caseId == cases(i).caseId & r103.version == "v4", :);
    brainOk = brainOk && islogical(brainMask) && isequal(size(brainMask), expectedSize) && ...
        height(row) == 1 && row.brainMaskVoxels == nnz(brainMask);
    lesionOk = lesionOk && islogical(pred) && isequal(size(pred), size(gt), expectedSize) && ...
        idx108.predictionVoxels(i) == nnz(pred) && idx108.gtVoxels(i) == nnz(gt) && ...
        row.predictedVoxels == nnz(pred) && row.gtLesionVoxels == nnz(gt);
    data(i).brain = brainMask; data(i).pred = pred; data(i).gt = gt; %#ok<SAGROW>
end
if ~(brainOk && lesionOk)
    error('phase108ctx:blocked', 'BRAIN-CONTEXT VARIANT BLOCKED: brain mask or lesion masks do not match Phase 103.');
end


%% 2. Figure con contesto cerebrale (stessa vista, limiti, colori delle figure canoniche)

figs = struct('p108', fullfile(F, 'phase108_v4_3d_prediction_brain_context.png'), ...
    'p109', fullfile(F, 'phase109_v4_3d_gt_prediction_brain_context.png'));
cameraUsed = zeros(0, 2);
for figKey = ["p108" "p109"]
    fig = figure('Color', 'w', 'Position', [100 100 1650 620]);
    layout = tiledlayout(fig, 1, numel(cases), 'TileSpacing', 'compact', 'Padding', 'compact');
    for i = 1:numel(cases)
        ax = nexttile(layout);
        hold(ax, 'on');
        renderMask3DSurface(ax, data(i).brain, brainColor, brainAlpha);
        if figKey == "p108"
            renderMask3DSurface(ax, data(i).pred, predColor, alphaPred108);
        else
            renderMask3DSurface(ax, data(i).gt, gtColor, alphaCompare);
            renderMask3DSurface(ax, data(i).pred, predColor, alphaCompare);
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
        title(ax, sprintf('%s\n%s', cases(i).caseId, cases(i).label), 'FontSize', 9, 'Interpreter', 'none');
        [az, el] = view(ax);
        cameraUsed(end+1, :) = [az el]; %#ok<SAGROW>
    end
    ax = nexttile(layout, numel(cases));
    hold(ax, 'on');
    if figKey == "p108"
        title(layout, 'Phase 108 (brain context) - final v4 (V4\_K5) predicted lesion mask (yellow) inside the automatic brain mask (grey)');
        h = [patch(ax, NaN, NaN, brainColor, 'FaceAlpha', 0.3), patch(ax, NaN, NaN, predColor)];
        names = {'brain mask (EXP-021, context only)', 'v4 prediction'};
    else
        title(layout, 'Phase 109 (brain context) - ground truth (cyan) vs final v4 prediction (yellow) inside the automatic brain mask (grey)');
        h = [patch(ax, NaN, NaN, brainColor, 'FaceAlpha', 0.3), patch(ax, NaN, NaN, gtColor, 'FaceAlpha', alphaCompare), ...
            patch(ax, NaN, NaN, predColor, 'FaceAlpha', alphaCompare)];
        names = {'brain mask (EXP-021, context only)', 'GT', 'v4 prediction'};
    end
    hold(ax, 'off');
    legend(ax, h, names, 'Location', 'southoutside', 'Orientation', 'horizontal');
    subtitle(layout, ['Same view, limits and lesion surfaces as the canonical Phase-108/109 figures; brain surface = ' ...
        'automatic T1 brain mask (first frozen v4 step), alpha 0.07, display only']);
    exportgraphics(fig, figs.(figKey), 'Resolution', 250);
    close(fig);
end


%% 3. Verifiche, indice e manifest

index = table([cases.caseId].', rel(string({cases.t1})).', arrayfun(@(d) nnz(d.brain), data).', ...
    arrayfun(@(c) r103.brainMaskVoxels(r103.caseId == c.caseId & r103.version == "v4"), cases).', ...
    repmat(brainAlpha, 3, 1), repmat(rel(figs.p108), 3, 1), repmat(rel(figs.p109), 3, 1), ...
    'VariableNames', {'caseId', 't1Source', 'brainMaskVoxels', 'phase103BrainMaskVoxels', 'brainAlpha', ...
    'phase108BrainContextFigure', 'phase109BrainContextFigure'});
writetable(index, fullfile(M, 'phase108_109_brain_context_index.csv'));
disp(index(:, {'caseId', 'brainMaskVoxels', 'phase103BrainMaskVoxels'}));

code = char(strjoin(regexprep(splitlines(string(fileread([mfilename('fullpath') '.m']))), '%.*$', ''), newline));
forbidden = {['generateV4' 'Prediction('], ['generateFinal' 'Prediction('], ['computeT1Anatomical' 'Support('], ...
    ['anisotropicDiffusion' 'Volume3D('], ['multi' 'thresh('], ['smo' 'oth3('], ['reduce' 'patch('], ['imres' 'ize3('], ...
    ['bwarea' 'open('], ['vol' 'show('], ['computeDice' 'FromConfusion('], ['sa' 've('], ['EXP-0' '62']};
predHashesAfter = string(arrayfun(@(f) sha256File(f), inputs(4:6), 'UniformOutput', false));
inputsAfter = all(arrayfun(@(f) inputHash(f) == "" || strcmp(sha256File(f), inputHash(f)), inputs));
checks = [checks; {
    "brain mask = EXP-021 step only, from T1 (no GT, no lesion segmentation); voxel counts equal Phase-103 brainMaskVoxels", ...
        brainOk && ~any(cellfun(@(f) contains(code, f), forbidden(1:5)))
    "lesion masks = the canonical saved v4 predictions and GT label 10 (counts equal Phase 103 and the Phase-108/109 index)", lesionOk
    "same camera (az -37.5, el 30) and full-volume limits in every panel", ...
        size(cameraUsed, 1) == 6 && all(abs(cameraUsed(:, 1) - cameraAz) < 1e-9 & abs(cameraUsed(:, 2) - cameraEl) < 1e-9)
    "no smoothing, downsampling, component filtering, volume rendering, metric recomputation or MAT saving", ...
        ~any(cellfun(@(f) contains(code, f), forbidden(6:end)))
    "v4 frozen hashes, predictions, T1 / GT inputs, Phase-103 / 105-107 / 108-109 outputs, config.m unchanged AFTER", ...
        manifestOk(v4Manifest) && manifestOk(p103) && manifestOk(p105) && manifestOk(p108) && ...
        isequal(predHashesBefore, predHashesAfter) && inputsAfter && isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];
for i = 1:size(checks, 1)
    fprintf('%-120s %s\n', checks{i, 1}, ternary(checks{i, 2}, 'ok', 'FAILED'));
end
if any(~[checks{:, 2}])
    error('phase108ctx:checksFailed', 'Brain-context variant checks failed.');
end

outputs = [string(figs.p108); string(figs.p109); string(fullfile(M, 'phase108_109_brain_context_index.csv')); ...
    string([mfilename('fullpath') '.m'])];
writetable(table(rel(outputs), string(cellfun(@sha256File, cellstr(outputs), 'UniformOutput', false)), ...
    'VariableNames', {'path', 'sha256'}), fullfile(M, 'phase108_109_brain_context_manifest.csv'));
fprintf('\nPHASES 108-109 BRAIN-CONTEXT VARIANT: PASS (%d)\n', size(checks, 1));


function h = knownHash(known, key)
%KNOWNHASH Impronta registrata per key, oppure "" se nessun manifest la elenca.
    h = "";
    if isKey(known, key)
        h = string(known(key));
    end
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
        error('phase108ctx:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
