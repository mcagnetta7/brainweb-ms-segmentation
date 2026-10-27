%% Figure del Capitolo 3 della relazione (Metodologia) - solo visualizzazione dei passi della pipeline v4
% Figura 3.2: maschera cerebrale e costruzione di S2 su una slice di pn3.
% Figura 3.3: effetto della diffusione anisotropa 3D sulla T2 di pn3 (ingrandimento e profilo).
% Figura 3.4: istogramma della T2 filtrata dentro S2 con livelli TA e soglia minima (pn3; msles1 seme 1),
%   senza ground truth.
% Figura 3.5: effetto dell'apertura 2D (candidati, maschera aperta, voxel rimossi) su pn3.
% I passi intermedi sono ricalcolati con gli helper congelati della v4 SOLO per la visualizzazione; la
% maschera finale ricalcolata deve coincidere voxel per voxel con la predizione v4 salvata e le soglie con i
% valori della fase 103, altrimenti lo script si ferma. Nessun risultato viene modificato o salvato.
% Regole di visualizzazione (fissate prima di produrre le figure):
%   slice k = 102 (massimo dei voxel di lesione della GT msles2, la stessa delle figure finali di pn3);
%   finestra di ingrandimento 3.3 = 61 x 61 pixel centrata sul baricentro della lesione GT più grande della
%   slice (GT usata solo per posizionare la finestra); profilo = riga orizzontale per lo stesso baricentro;
%   finestra 3.5 = 61 x 61 pixel con il maggior numero di voxel rimossi dall'apertura nella slice.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.visualization);
M = cfg.paths.metrics; F = cfg.paths.figures; P = cfg.paths.processedData;
rel = @(p) strrep(erase(string(p), string(projectRoot) + filesep), '\', '/');
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));
c101 = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'phase101');
checks = cell(0, 2);
k = 102; win = 30;

cases = struct( ...
    'caseId', {"pn3", "custom_s1_msles1"}, ...
    'label',  {"pn3 (msles2, rumore 3 %)", "msles1 seme 1 (carico lieve, rumore 0 %)"}, ...
    't1',     {cfg.dataset.noisyMriFiles.pn3.T1, fullfile(c101, 'mri', 'custom_msles1_t1_ai_1mm_n0_inu0_job1261017-050735s-2817767.raws')}, ...
    't2',     {cfg.dataset.noisyMriFiles.pn3.T2, fullfile(c101, 'mri', 'custom_msles1_t2_ai_1mm_n0_inu0_job1261017-050750s-2817854.raws')}, ...
    'pred',   {fullfile(P, 'exp060_candidates', 'exp060_k5_pn3.mat'), fullfile(P, 'exp060_candidates', 'exp060_k5_msles1.mat')});

known = containers.Map('KeyType', 'char', 'ValueType', 'any');
t = readtable(fullfile(M, 'phase101_result_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
for r = 1:height(t)
    known(char(t.path(r))) = upper(t.sha256(r));
end
known(char(rel(cfg.dataset.noisyMriFiles.pn3.T1))) = "AC7C6136D99F83FC6BCBF44111D2541996A146E946433F8AF2F39E95A9D8B8FE";
known(char(rel(cfg.dataset.noisyMriFiles.pn3.T2))) = "52AF70628F1211CCEF850F61E715D4D743102EAF29AD1337CDEB61BBCCFE0F7E";
inputs = [string({cases.t1}), string({cases.t2}), string(cfg.dataset.groundTruthFile)];
inputsOk = all(arrayfun(@(f) isKey(known, char(rel(f))) && strcmp(sha256File(f), char(known(char(rel(f))))), inputs));
predHashBefore = string(arrayfun(@(c) sha256File(c.pred), cases, 'UniformOutput', false));
checks = [checks; {"MRI / GT inputs match their recorded SHA-256", inputsOk}];
if ~inputsOk
    error('reportCh3:blocked', 'Report Chapter-3 figures BLOCKED: input integrity check failed.');
end


%% Ricalcolo dei passi della pipeline v4 (helper congelati) e verifica contro i risultati salvati

r103 = readtable(fullfile(M, 'phase103_runner_metrics.csv'), 'TextType', 'string', 'Delimiter', ',');
st = struct([]);
reproOk = true;
for i = 1:numel(cases)
    s = pipelineSteps(cfg, cases(i).t1, cases(i).t2, 5);
    saved = load(cases(i).pred, 'M_pred');
    row = r103(r103.caseId == cases(i).caseId & r103.version == "v4", :);
    reproOk = reproOk && isequal(s.Mpred, saved.M_pred) && height(row) == 1 && ...
        abs(s.ta(2) - row.TA2) < 1e-9 && abs(s.floorValue - row.floorValue) < 1e-9 && ...
        nnz(s.B) == row.brainMaskVoxels && nnz(s.S2) == row.S2Voxels;
    st = [st s]; %#ok<AGROW>
end
checks = [checks; {"recomputed steps reproduce the saved v4 predictions voxel by voxel; TA2, floor, |B|, |S2| equal Phase 103", reproOk}];
if ~reproOk
    error('reportCh3:blocked', 'Report Chapter-3 figures BLOCKED: recomputed pipeline differs from the saved v4 result.');
end
p = st(1);                                      % pn3
gt = loadGtLabel10(cfg, cfg.dataset.groundTruthFile);
figs = struct('f32', fullfile(F, 'report_ch3_brain_mask_s2.png'), 'f33', fullfile(F, 'report_ch3_anisotropic_diffusion.png'), ...
    'f34', fullfile(F, 'report_ch3_threshold_histograms.png'), 'f35', fullfile(F, 'report_ch3_opening.png'));
show = @(ax, img, range) showSlice(ax, img, range);


%% Figura 3.2 - maschera cerebrale e supporto S2 (pn3, slice k)

t1s = p.t1n(:, :, k);
classes = p.classes(:, :, k);
classes(~p.B(:, :, k)) = 0;
cavities = p.filledHigh(:, :, k) & ~p.high(:, :, k) & p.B(:, :, k);
fig = figure('Color', 'w', 'Position', [60 100 1700 470]);
layout = tiledlayout(fig, 1, 5, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile(layout); show(ax, t1s, [0 max(p.t1n(:))]); title(ax, '(a) T1 normalizzata');
ax = nexttile(layout); overlayMaskBoundaryOnMRI(ax, t1s, p.B(:, :, k), 'BoundaryColor', [1 0.2 0.2], 'ShowFill', true, ...
    'FillAlpha', 0.35, 'DisplayRange', [0 max(p.t1n(:))], 'Title', "(b) maschera cerebrale B");
ax = nexttile(layout);
rgb = labelRgb(classes, [0 0 0; 0.15 0.35 0.9; 0.55 0.55 0.55; 0.95 0.95 0.95]);
image(ax, permute(rgb, [2 1 3])); axis(ax, 'image'); set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
title(ax, '(c) partizione T1 in B: Low / media / High');
ax = nexttile(layout);
rgb = labelRgb(uint8(p.high(:, :, k)) + 2 * uint8(cavities), [0 0 0; 0.95 0.95 0.95; 1 0.2 0.2]);
image(ax, permute(rgb, [2 1 3])); axis(ax, 'image'); set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
title(ax, '(d) High (bianco) + cavità riempite (rosso)');
ax = nexttile(layout); overlayMaskBoundaryOnMRI(ax, t1s, p.S2(:, :, k), 'BoundaryColor', [0 0.8 0.3], 'ShowFill', true, ...
    'FillAlpha', 0.4, 'DisplayRange', [0 max(p.t1n(:))], 'Title', "(e) supporto S2");
set(findall(fig, 'Type', 'axes'), 'FontSize', 9);
title(layout, sprintf('Maschera cerebrale e supporto anatomico S2 dalla sola T1 - pn3, slice assiale k = %d', k));
exportgraphics(fig, figs.f32, 'Resolution', 250);
close(fig);


%% Figura 3.3 - diffusione anisotropa 3D (pn3, slice k)

cc = bwconncomp(gt(:, :, k), 8);
[~, big] = max(cellfun(@numel, cc.PixelIdxList));
[ii, jj] = ind2sub(size(gt, [1 2]), cc.PixelIdxList{big});
ci = round(mean(ii)); cj = round(mean(jj));
ri = max(1, ci - win):min(size(gt, 1), ci + win); rj = max(1, cj - win):min(size(gt, 2), cj + win);
orig = p.t2n(:, :, k); filt = p.t2f(:, :, k);
range = [0 max(p.t2n(:))];
fig = figure('Color', 'w', 'Position', [60 60 1500 900]);
layout = tiledlayout(fig, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile(layout, 1); show(ax, orig, range); hold(ax, 'on');
rectangle(ax, 'Position', [ri(1) rj(1) numel(ri) numel(rj)], 'EdgeColor', [1 0.85 0], 'LineWidth', 1.2);
plot(ax, [ri(1) ri(end)], [cj cj], 'r-', 'LineWidth', 1); hold(ax, 'off'); title(ax, '(a) T2 normalizzata');
ax = nexttile(layout, 2); show(ax, filt, range); title(ax, '(b) T2 dopo diffusione anisotropa 3D');
ax = nexttile(layout, 4); show(ax, orig(ri, rj), range); title(ax, '(c) ingrandimento, T2 normalizzata');
ax = nexttile(layout, 5); show(ax, filt(ri, rj), range); title(ax, '(d) ingrandimento, T2 filtrata');
ax = nexttile(layout, 3, [2 1]);
plot(ax, ri, orig(ri, cj), '-', 'Color', [0.55 0.55 0.55], 'LineWidth', 1); hold(ax, 'on');
plot(ax, ri, filt(ri, cj), 'k-', 'LineWidth', 1.6);
inLesion = gt(ri, cj, k);
plot(ax, ri(inLesion), 0.02 + 0 * ri(inLesion), 's', 'MarkerSize', 4, 'MarkerFaceColor', [0 0.9 0.9], 'MarkerEdgeColor', 'none');
hold(ax, 'off'); grid(ax, 'on'); ylim(ax, [0 max(orig(ri, cj)) * 1.05]);
xlabel(ax, 'posizione lungo la riga (indice X)'); ylabel(ax, 'intensità normalizzata');
legend(ax, {'T2 normalizzata', 'T2 filtrata', 'voxel di lesione (GT, riferimento)'}, 'Location', 'southoutside');
title(ax, '(e) profilo lungo la riga rossa');
set(findall(fig, 'Type', 'axes'), 'FontSize', 9);
title(layout, sprintf('Effetto della diffusione anisotropa 3D sulla T2 - pn3, slice assiale k = %d', k));
exportgraphics(fig, figs.f33, 'Resolution', 250);
close(fig);


%% Figura 3.4 - istogrammi della T2 filtrata dentro S2 con TA e soglia minima (senza GT)

fig = figure('Color', 'w', 'Position', [60 100 1500 560]);
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
edges = 0:0.005:1;
for i = 1:numel(st)
    ax = nexttile(layout);
    values = st(i).t2f(st(i).S2);
    histogram(ax, values, edges, 'FaceColor', [0.6 0.6 0.6], 'EdgeColor', 'none');
    set(ax, 'YScale', 'log'); hold(ax, 'on');
    yl = ylim(ax);
    h = [plot(ax, st(i).ta([1 1]), yl, 'b--', 'LineWidth', 1.2), plot(ax, st(i).ta([2 2]), yl, 'b-', 'LineWidth', 1.6), ...
        plot(ax, st(i).floorValue([1 1]), yl, 'r-', 'LineWidth', 1.6)];
    hold(ax, 'off'); xlim(ax, [0.3 0.95]); grid(ax, 'on');
    xlabel(ax, 'intensità T2 filtrata (normalizzata)'); ylabel(ax, 'numero di voxel in S2 (scala log)');
    legend(ax, h, {sprintf('T_{TA1} = %.3f', st(i).ta(1)), sprintf('T_{TA2} = %.3f', st(i).ta(2)), ...
        sprintf('\\mu_{ref} + 5\\sigma_{ref} = %.3f', st(i).floorValue)}, 'Location', 'northeast');
    title(ax, sprintf('%s\nsoglia finale = %.3f', cases(i).label, max(st(i).ta(2), st(i).floorValue)), 'Interpreter', 'tex');
end
title(layout, 'Istogramma della T2 filtrata dentro S2: livelli TA (blu) e soglia minima WM-like (rosso)');
exportgraphics(fig, figs.f34, 'Resolution', 250);
close(fig);


%% Figura 3.5 - effetto dell'apertura 2D (pn3, slice k)

cand = p.cand(:, :, k); opened = p.opened(:, :, k); removed = cand & ~opened;
score = conv2(double(removed), ones(2 * win + 1), 'same');
[~, best] = max(score(:));
[bi, bj] = ind2sub(size(score), best);
qi = max(1, bi - win):min(size(cand, 1), bi + win); qj = max(1, bj - win):min(size(cand, 2), bj + win);
zoomT2 = p.t2f(qi, qj, k);
fig = figure('Color', 'w', 'Position', [60 100 1500 560]);
layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
overlayMaskBoundaryOnMRI(nexttile(layout), zoomT2, cand(qi, qj), 'BoundaryColor', [1 0.85 0], 'ShowFill', true, ...
    'FillAlpha', 0.5, 'DisplayRange', range, 'Title', "(a) candidati prima dell'apertura");
overlayMaskBoundaryOnMRI(nexttile(layout), zoomT2, opened(qi, qj), 'BoundaryColor', [1 0.85 0], 'ShowFill', true, ...
    'FillAlpha', 0.5, 'DisplayRange', range, 'Title', "(b) dopo l'apertura (diamante, raggio 1)");
ax = nexttile(layout);
rgb = repmat(min(max(zoomT2.' / range(2), 0), 1), 1, 1, 3);
rgb = paint(rgb, opened(qi, qj).', [1 0.85 0], 0.5);
rgb = paint(rgb, removed(qi, qj).', [1 0 0], 0.85);
image(ax, rgb); axis(ax, 'image'); set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
title(ax, '(c) mantenuti (giallo) e rimossi (rosso)');
set(findall(fig, 'Type', 'axes'), 'FontSize', 9);
title(layout, sprintf(['Effetto dell''apertura morfologica 2D - pn3, slice k = %d, ingrandimento %d x %d pixel ' ...
    '(voxel rimossi nell''intero volume: %d su %d candidati)'], k, numel(qi), numel(qj), nnz(p.cand) - nnz(p.opened), nnz(p.cand)));
exportgraphics(fig, figs.f35, 'Resolution', 250);
close(fig);


%% Verifiche e manifest

code = char(strjoin(regexprep(splitlines(string(fileread([mfilename('fullpath') '.m']))), '%.*$', ''), newline));
forbidden = {['computeDice' 'FromConfusion('], ['smo' 'oth3('], ['sa' 've('], ['generateV5' 'Predictions(']};
inputsAfter = all(arrayfun(@(f) strcmp(sha256File(f), char(known(char(rel(f))))), inputs));
predHashAfter = string(arrayfun(@(c) sha256File(c.pred), cases, 'UniformOutput', false));
checks = [checks; {
    "display slice k = 102 is the first maximum of msles2 GT lesion voxels", ...
        find(squeeze(sum(gt, [1 2])) == max(squeeze(sum(gt, [1 2]))), 1) == k
    "no metric computation, smoothing or MAT saving; saved predictions, inputs and config.m unchanged AFTER", ...
        ~any(cellfun(@(f) contains(code, f), forbidden)) && isequal(predHashBefore, predHashAfter) && inputsAfter && ...
        isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];
for i = 1:size(checks, 1)
    fprintf('%-115s %s\n', checks{i, 1}, ternary(checks{i, 2}, 'ok', 'FAILED'));
end
if any(~[checks{:, 2}])
    error('reportCh3:checksFailed', 'Report Chapter-3 figure checks failed.');
end
outputs = [string(figs.f32); string(figs.f33); string(figs.f34); string(figs.f35); string([mfilename('fullpath') '.m'])];
writetable(table(rel(outputs), string(cellfun(@sha256File, cellstr(outputs), 'UniformOutput', false)), ...
    'VariableNames', {'path', 'sha256'}), fullfile(M, 'report_ch3_figure_manifest.csv'));
fprintf(['\nREPORT CHAPTER 3 FIGURES: PASS (%d); pn3 TA2 %.4f floor %.4f; msles1 TA2 %.4f floor %.4f; ' ...
    'opening removed %d of %d candidate voxels (pn3)\n'], size(checks, 1), st(1).ta(2), st(1).floorValue, ...
    st(2).ta(2), st(2).floorValue, nnz(p.cand) - nnz(p.opened), nnz(p.cand));


function s = pipelineSteps(cfg, t1Path, t2Path, kFloor)
%PIPELINESTEPS Passi intermedi della pipeline v4, con gli stessi helper congelati di generateV4Prediction.
    cfg.dataset.noisyMriFiles.vis.T1 = char(t1Path);
    cfg.dataset.noisyMriFiles.vis.T2 = char(t2Path);
    normalize = @(raw) normalizeFixedRange(convertToWorkingClass(raw, "double"), [0 4095], [0 1]);
    s.t1n = normalize(loadBrainwebMri(cfg, "T1", "vis"));
    s.t2n = normalize(loadBrainwebMri(cfg, "T2", "vis"));
    s.B = brainMask3DErodeSelectDilate(initialSupportMask(s.t1n), 3, 26);
    [supports, details] = computeT1AnatomicalSupport(s.t1n, s.B);
    s.S2 = supports.S2;
    s.classes = imquantize(s.t1n, details.t1ThresholdsNormalized);
    s.high = s.B & s.classes == 3;
    s.filledHigh = false(size(s.high));
    for z = 1:size(s.high, 3)
        s.filledHigh(:, :, z) = imfill(s.high(:, :, z), 'holes');
    end
    t2f = anisotropicDiffusionVolume3D(s.t2n);
    s.t2f = min(max(t2f, 0), 1);
    s.ta = double(multithresh(s.t2f(s.S2), 2));
    reference = s.t2f(s.S2 & s.high);
    s.floorValue = mean(reference) + kFloor * std(reference);
    s.cand = s.S2 & s.t2f > max(s.ta(2), s.floorValue);
    s.opened = false(size(s.cand));
    se = strel('diamond', 1);
    for z = 1:size(s.cand, 3)
        s.opened(:, :, z) = imopen(s.cand(:, :, z), se);
    end
    s.Mpred = s.opened & s.S2;
end

function m = loadGtLabel10(cfg, path)
%LOADGTLABEL10 Maschera della ground truth (label 10), usata solo per posizionare finestre e marcatori.
    cfg.dataset.groundTruthFile = char(path);
    m = loadBrainwebGroundTruth(cfg) == 10;
end

function showSlice(ax, img, range)
%SHOWSLICE Sezione in scala di grigi con la convenzione del progetto (trasposta, YDir normal).
    imagesc(ax, img.', range); colormap(ax, gray); axis(ax, 'image');
    set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
end

function rgb = labelRgb(labels, palette)
%LABELRGB Immagine RGB da una mappa di etichette 0..n con la palette indicata (righe = etichette).
    rgb = reshape(palette(double(labels) + 1, :), [size(labels) 3]);
end

function rgb = paint(rgb, mask, color, alpha)
%PAINT Colora con trasparenza i pixel della maschera.
    for c = 1:3
        ch = rgb(:, :, c);
        ch(mask) = (1 - alpha) * ch(mask) + alpha * color(c);
        rgb(:, :, c) = ch;
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
        error('reportCh3:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
