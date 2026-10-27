%% Figure del Capitolo 2 della relazione (Dataset BrainWeb) - solo visualizzazione dei dati
% Figura 2.1: stessa slice assiale di pn0 in T1, T2 e T2 + ground truth (label 10, ciano).
% Figura 2.2: stessa slice T2 per pn0, pn1, pn3, pn5, pn7, pn9 con la stessa scala di grigi.
% Figura 2.3: lesioni della ground truth di msles1 / msles2 / msles3 in 3D (stessa vista e limiti delle
%   figure finali), dentro la maschera cerebrale automatica ricavata dalla T1 delle simulazioni seme 1
%   (stesso passo congelato delle figure 108-109, solo contesto).
% Nessuna segmentazione delle lesioni, nessuna metrica, nessun dato nuovo: solo file già scaricati e
% verificati con le impronte registrate. Slice: k con il massimo numero di voxel di lesione della GT msles2
% (primo massimo), la stessa regola e la stessa slice (k = 102) delle figure finali di pn3.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.visualization);
M = cfg.paths.metrics; F = cfg.paths.figures;
rel = @(p) strrep(erase(string(p), string(projectRoot) + filesep), '\', '/');
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));
rawDir = fileparts(cfg.dataset.mriFiles.T1);
c101 = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'phase101');
pre = @(n, m) fullfile(rawDir, sprintf('%s_ai_msles2_1mm_%s_rf0.raws', m, n));
checks = cell(0, 2);
expectedSize = [181 217 181];

% Impronte registrate: inventario fase 98 (pn1-pn9), manifest fase 101 (seme 1, GT), registro di download (pn0, pn3)
known = containers.Map('KeyType', 'char', 'ValueType', 'any');
for mf = ["phase98_final_results_inventory.csv" "phase101_result_manifest.csv"]
    t = readtable(fullfile(M, mf), 'TextType', 'string', 'Delimiter', ',');
    for r = 1:height(t)
        known(char(t.path(r))) = upper(t.sha256(r));
    end
end
known(char(rel(pre("pn0", "t1")))) = "C94E3BB8D0DF62C4D52B5A7EAFF0673F73E828A345D2FF8EE3FEEE8BD3A91FD0";
known(char(rel(pre("pn0", "t2")))) = "113EBC5E1BA1E57FE4B5F6FD2686F1B869023615B54191DD31F4EEE6A1362071";
known(char(rel(pre("pn3", "t2")))) = "52AF70628F1211CCEF850F61E715D4D743102EAF29AD1337CDEB61BBCCFE0F7E";

noiseIds = ["pn0" "pn1" "pn3" "pn5" "pn7" "pn9"];
s1 = struct( ...
    'phantom', {"msles1", "msles2", "msles3"}, ...
    'label',   {"msles1 - carico lieve", "msles2 - carico moderato", "msles3 - carico grave"}, ...
    'caseId',  {"custom_s1_msles1", "custom_s1_msles2", "custom_s1_msles3"}, ...
    't1',      {fullfile(c101, 'mri', 'custom_msles1_t1_ai_1mm_n0_inu0_job1261017-050735s-2817767.raws'), ...
                fullfile(c101, 'mri', 'custom_msles2_t1_ai_1mm_n0_inu0_job1261017-050846s-2818122.raws'), ...
                fullfile(c101, 'mri', 'custom_msles3_t1_ai_1mm_n0_inu0_job1261017-050805s-2817935.raws')}, ...
    'gt',      {fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles1_crisp.rawb'), cfg.dataset.groundTruthFile, ...
                fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles3_crisp.rawb')});
inputs = [string(pre("pn0", "t1")), arrayfun(@(n) string(pre(n, "t2")), noiseIds), string({s1.t1}), string({s1.gt})];
inputsOk = all(arrayfun(@(f) isKey(known, char(rel(f))) && strcmp(sha256File(f), char(known(char(rel(f))))), inputs));
checks = [checks; {"all MRI / GT inputs match their recorded SHA-256 (download record, Phase-98 inventory, Phase-101 manifest)", inputsOk}];
if ~inputsOk
    error('reportCh2:blocked', 'Report Chapter-2 figures BLOCKED: input integrity check failed.');
end

readMri = @(path, modality) readMriVolume(cfg, path, modality);
readGt = @(path) readLesionGt(cfg, path);


%% Figura 2.1 - modalità e ground truth (pn0)

t1 = double(readMri(pre("pn0", "t1"), "T1"));
t2 = double(readMri(pre("pn0", "t2"), "T2"));
gt2 = readGt(cfg.dataset.groundTruthFile);
[~, k] = max(squeeze(sum(gt2, [1 2])));          % primo massimo = k più piccolo
gtColor = [0 0.9 0.9];
figs = struct('f21', fullfile(F, 'report_ch2_modalities_gt.png'), 'f22', fullfile(F, 'report_ch2_noise_levels.png'), ...
    'f23', fullfile(F, 'report_ch2_lesion_load_3d.png'));

fig = figure('Color', 'w', 'Position', [100 100 1350 560]);
layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
overlayMaskBoundaryOnMRI(nexttile(layout), t1(:, :, k), false(size(gt2, 1, 2)), ...
    'DisplayRange', [min(t1(:)) max(t1(:))], 'Title', "T1");
overlayMaskBoundaryOnMRI(nexttile(layout), t2(:, :, k), false(size(gt2, 1, 2)), ...
    'DisplayRange', [min(t2(:)) max(t2(:))], 'Title', "T2");
overlayMaskBoundaryOnMRI(nexttile(layout), t2(:, :, k), gt2(:, :, k), 'BoundaryColor', gtColor, 'ShowFill', true, ...
    'FillAlpha', 0.45, 'DisplayRange', [min(t2(:)) max(t2(:))], 'Title', "T2 + ground truth (label 10)");
title(layout, sprintf('BrainWeb msles2, pn0 (rumore 0 %%), slice assiale k = %d', k));
exportgraphics(fig, figs.f21, 'Resolution', 250);
close(fig);


%% Figura 2.2 - livelli di rumore (stessa slice, stessa scala di grigi)

t2n = cell(1, numel(noiseIds));
for i = 1:numel(noiseIds)
    v = readMri(pre(noiseIds(i), "t2"), "T2");
    t2n{i} = double(v(:, :, k));
    ranges(i, :) = double([min(v(:)) max(v(:))]); %#ok<SAGROW>
end
commonRange = [min(ranges(:, 1)) max(ranges(:, 2))];
noisePct = [0 1 3 5 7 9];
fig = figure('Color', 'w', 'Position', [100 100 1350 1000]);
layout = tiledlayout(fig, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
for i = 1:numel(noiseIds)
    overlayMaskBoundaryOnMRI(nexttile(layout), t2n{i}, false(size(t2n{i})), 'DisplayRange', commonRange, ...
        'Title', sprintf('%s - rumore %d %%', noiseIds(i), noisePct(i)));
end
title(layout, sprintf('T2 BrainWeb msles2, slice assiale k = %d, stessa scala di grigi [%d %d]', k, commonRange));
exportgraphics(fig, figs.f22, 'Resolution', 250);
close(fig);


%% Figura 2.3 - carico lesionale in 3D (GT label 10 dentro la maschera cerebrale automatica)

r103 = readtable(fullfile(M, 'phase103_runner_metrics.csv'), 'TextType', 'string', 'Delimiter', ',');
cameraAz = -37.5; cameraEl = 30;                 % stessa vista delle figure finali 108-109
gtCounts = zeros(1, 3); brainOk = true;
fig = figure('Color', 'w', 'Position', [100 100 1650 620]);
layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
for i = 1:3
    gt = readGt(s1(i).gt);
    t1n = normalizeFixedRange(convertToWorkingClass(readMri(s1(i).t1, "T1"), "double"), [0 4095], [0 1]);
    brainMask = brainMask3DErodeSelectDilate(initialSupportMask(t1n), 3, 26);
    row = r103(r103.caseId == s1(i).caseId & r103.version == "v4", :);
    brainOk = brainOk && height(row) == 1 && row.brainMaskVoxels == nnz(brainMask) && row.gtLesionVoxels == nnz(gt);
    gtCounts(i) = nnz(gt);
    ax = nexttile(layout);
    hold(ax, 'on');
    renderMask3DSurface(ax, brainMask, [0.55 0.55 0.55], 0.07);
    renderMask3DSurface(ax, gt, gtColor, 0.9);
    hold(ax, 'off');
    daspect(ax, [1 1 1]);
    xlim(ax, [0.5 expectedSize(1) + 0.5]); ylim(ax, [0.5 expectedSize(2) + 0.5]); zlim(ax, [0.5 expectedSize(3) + 0.5]);
    view(ax, cameraAz, cameraEl);
    set(ax, 'Projection', 'orthographic', 'Box', 'on', 'FontSize', 8);
    camlight(ax, 'headlight'); lighting(ax, 'gouraud'); material(ax, 'dull');
    xlabel(ax, 'X (dim 1, voxel)'); ylabel(ax, 'Y (dim 2, voxel)'); zlabel(ax, 'Z (dim 3, slice)');
    title(ax, sprintf('%s\n%d voxel di lesione', s1(i).label, gtCounts(i)), 'FontSize', 9, 'Interpreter', 'none');
end
ax = nexttile(layout, 3);
hold(ax, 'on');
h = [patch(ax, NaN, NaN, [0.55 0.55 0.55], 'FaceAlpha', 0.3), patch(ax, NaN, NaN, gtColor)];
hold(ax, 'off');
legend(ax, h, {'maschera cerebrale automatica (solo contesto)', 'lesioni della ground truth (label 10)'}, ...
    'Location', 'southoutside', 'Orientation', 'horizontal');
title(layout, 'Carico lesionale dei tre phantom SM BrainWeb - ground truth in 3D, stessa vista e stessi limiti');
exportgraphics(fig, figs.f23, 'Resolution', 250);
close(fig);


%% Verifiche e manifest

code = char(strjoin(regexprep(splitlines(string(fileread([mfilename('fullpath') '.m']))), '%.*$', ''), newline));
forbidden = {['generateV4' 'Prediction('], ['generateFinal' 'Prediction('], ['multi' 'thresh('], ['computeDice' 'FromConfusion('], ...
    ['smo' 'oth3('], ['sa' 've(']};
inputsAfter = all(arrayfun(@(f) strcmp(sha256File(f), char(known(char(rel(f))))), inputs));
checks = [checks; {
    "display slice k = 102 (first maximum of msles2 GT lesion voxels; same slice as the final pn3 figures)", k == 102
    "msles1 / msles2 / msles3 GT = 422 / 3512 / 10104 voxels; brain masks equal Phase-103 brainMaskVoxels (seed 1)", ...
        isequal(gtCounts, [422 3512 10104]) && brainOk
    "no lesion segmentation, metric, smoothing or MAT saving", ~any(cellfun(@(f) contains(code, f), forbidden))
    "inputs and config.m unchanged AFTER", inputsAfter && isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];
for i = 1:size(checks, 1)
    fprintf('%-115s %s\n', checks{i, 1}, ternary(checks{i, 2}, 'ok', 'FAILED'));
end
if any(~[checks{:, 2}])
    error('reportCh2:checksFailed', 'Report Chapter-2 figure checks failed.');
end
outputs = [string(figs.f21); string(figs.f22); string(figs.f23); string([mfilename('fullpath') '.m'])];
writetable(table(rel(outputs), string(cellfun(@sha256File, cellstr(outputs), 'UniformOutput', false)), ...
    'VariableNames', {'path', 'sha256'}), fullfile(M, 'report_ch2_figure_manifest.csv'));
fprintf('\nREPORT CHAPTER 2 FIGURES: PASS (%d); slice k = %d; common T2 range [%d %d]\n', size(checks, 1), k, commonRange);


function v = readMriVolume(cfg, path, modality)
%READMRIVOLUME Carica un volume MRI raw tramite il loader del progetto (copia locale di cfg, config.m invariato).
    cfg.dataset.noisyMriFiles.vis.(char(modality)) = char(path);
    v = loadBrainwebMri(cfg, char(modality), "vis");
end

function m = readLesionGt(cfg, path)
%READLESIONGT Maschera logica della ground truth: label 10 = lesione SM.
    cfg.dataset.groundTruthFile = char(path);
    m = loadBrainwebGroundTruth(cfg) == 10;
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
        error('reportCh2:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
