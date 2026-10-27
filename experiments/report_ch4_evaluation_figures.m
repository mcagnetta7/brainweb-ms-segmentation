%% Figure del Capitolo 4 della relazione (Metodologia di valutazione) - casi artificiali, nessun dato BrainWeb
% Figura 4.1: matrice di confusione sul caso artificiale 3 x 3 della fase 111 (GT, predizione, categorie).
% Figura 4.2: criterio lesion-wise (componenti 26-connesse, almeno un voxel in comune) su un caso
%   artificiale con una lesione toccata da un solo voxel, una ben coperta, una mancata e una componente falsa.
% Tutti i valori mostrati sono calcolati con le funzioni di valutazione del progetto e confrontati con i
% valori attesi scritti a mano; nessuna segmentazione, nessun dato BrainWeb, nessun risultato modificato.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);
M = cfg.paths.metrics; F = cfg.paths.figures;
rel = @(p) strrep(erase(string(p), string(projectRoot) + filesep), '\', '/');
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));
cTP = [0 0.8 0]; cFP = [0.9 0 0]; cFN = [0 0.35 1]; cTN = [0.88 0.88 0.88];   % colori delle figure dei risultati
cGT = [0 0.9 0.9]; cPred = [1 0.85 0];
checks = cell(0, 2);
figs = struct('f41', fullfile(F, 'report_ch4_confusion_example.png'), 'f42', fullfile(F, 'report_ch4_lesionwise_example.png'));


%% Figura 4.1 - matrice di confusione sul caso 3 x 3

gt = logical([1 1 0; 1 0 0; 0 0 0]);
pr = logical([1 0 1; 1 0 0; 0 0 0]);
c = computeVoxelConfusion(pr, gt);
m = [computeDiceFromConfusion(c), computeIoUFromConfusion(c), computePrecisionFromConfusion(c), ...
    computeRecallFromConfusion(c), computeSpecificityFromConfusion(c)];
checks = [checks; {"3x3 case: TP 2, FP 1, FN 1, TN 5; Dice 2/3, IoU 1/2, Precision 2/3, Recall 2/3, Specificity 5/6", ...
    isequal([c.TP c.FP c.FN c.TN], [2 1 1 5]) && max(abs(m - [2/3 1/2 2/3 2/3 5/6])) < 1e-12}];

fig = figure('Color', 'w', 'Position', [100 100 1300 560]);
layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'loose', 'Padding', 'compact');
drawGrid(nexttile(layout), paintMask(gt, cGT, [1 1 1]), string(double(gt)), '(a) ground truth M_{GT}');
drawGrid(nexttile(layout), paintMask(pr, cPred, [1 1 1]), string(double(pr)), '(b) predizione M_{pred}');
catLabels = strings(3); rgb = zeros(3, 3, 3);
for i = 1:3
    for j = 1:3
        [catLabels(i, j), col] = category(pr(i, j), gt(i, j), cTP, cFP, cFN, cTN);
        rgb(i, j, :) = reshape(col, 1, 1, 3);
    end
end
drawGrid(nexttile(layout), rgb, catLabels, '(c) categorie voxel per voxel');
title(layout, 'Esempio di matrice di confusione voxel-wise su un caso artificiale 3 \times 3');
subtitle(layout, sprintf(['TP = %d,  FP = %d,  FN = %d,  TN = %d     |     Dice = 2/3 = %.3f,  IoU = 1/2 = %.3f,  ' ...
    'Precision = 2/3 = %.3f,  Recall = 2/3 = %.3f,  Specificity = 5/6 = %.3f'], c.TP, c.FP, c.FN, c.TN, m));
exportgraphics(fig, figs.f41, 'Resolution', 250);
close(fig);


%% Figura 4.2 - criterio lesion-wise

sz = [16 24 3]; z = 2;
gtL = false(sz); prL = false(sz);
gtL(3:8, 3:8, z) = true;                          % L1: 36 voxel, toccata da un solo voxel
prL(8:9, 8:9, z) = true;                          % P1: blocco 2 x 2 che condivide solo (8,8)
gtL(3:6, 14:17, z) = true;                        % L2: 16 voxel, coperta interamente
prL(3:7, 14:17, z) = true;                        % P2: copre L2 e una riga in più
gtL(12:13, 4:5, z) = true;                        % L3: 4 voxel, mancata
prL(12:13, 19:20, z) = true;                      % P3: componente falsa
lw = computeLesionWiseMatches(prL, gtL, 26);
cL = computeVoxelConfusion(prL, gtL);
cover1 = nnz(gtL(3:8, 3:8, z) & prL(3:8, 3:8, z));
checks = [checks; {"lesion-wise case: 3 GT lesions, 2 detected, 1 missed, 3 predicted components, 2 matched, 1 false", ...
    isequal([lw.gtComponentCount lw.detectedGtLesionCount lw.missedGtLesionCount lw.predictedComponentCount ...
    lw.matchedPredictedComponentCount lw.falsePredictedComponentCount], [3 2 1 3 2 1])}];
checks = [checks; {"voxel counts of the lesion-wise case: TP 17, FP 11, FN 39; lesion 1 covered by 1 of 36 voxels", ...
    isequal([cL.TP cL.FP cL.FN], [17 11 39]) && cover1 == 1}];

plane = struct('gt', gtL(:, :, z), 'pr', prL(:, :, z));
rgb = ones([sz(1:2) 3]);
rgb = paint(rgb, plane.pr & plane.gt, cTP);
rgb = paint(rgb, plane.pr & ~plane.gt, cFP);
rgb = paint(rgb, ~plane.pr & plane.gt, cFN);
fig = figure('Color', 'w', 'Position', [100 100 1250 820]);
ax = axes(fig);
drawGrid(ax, rgb, strings(sz(1:2)), '');
outline(ax, plane.gt, [0 0 0], 2);
hold(ax, 'on');
text(ax, 5.5, 1.6, sprintf('lesione 1: RILEVATA\n(1 voxel coperto su 36)'), 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
text(ax, 15.5, 1.6, sprintf('lesione 2: RILEVATA\n(16 voxel coperti su 16)'), 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
text(ax, 4.5, 15.2, 'lesione 3: MANCATA', 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
text(ax, 19.5, 15.2, 'COMPONENTE FALSA', 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
h = [patch(ax, NaN, NaN, cTP), patch(ax, NaN, NaN, cFP), patch(ax, NaN, NaN, cFN), plot(ax, NaN, NaN, 'k-', 'LineWidth', 2)];
hold(ax, 'off');
legend(ax, h, {'TP', 'FP', 'FN', 'contorno delle lesioni della ground truth'}, 'Location', 'southoutside', 'Orientation', 'horizontal');
title(ax, {'Analisi lesion-wise su un caso artificiale (componenti 26-connesse, corrispondenza = almeno un voxel in comune)', ...
    sprintf(['lesioni GT = %d,  rilevate = %d,  mancate = %d,  componenti predette = %d,  componenti false = %d', ...
    '     |     voxel: TP = %d,  FP = %d,  FN = %d'], lw.gtComponentCount, lw.detectedGtLesionCount, ...
    lw.missedGtLesionCount, lw.predictedComponentCount, lw.falsePredictedComponentCount, cL.TP, cL.FP, cL.FN)}, ...
    'FontWeight', 'normal', 'FontSize', 10);
exportgraphics(fig, figs.f42, 'Resolution', 250);
close(fig);


%% Verifiche e manifest

code = char(strjoin(regexprep(splitlines(string(fileread([mfilename('fullpath') '.m']))), '%.*$', ''), newline));
forbidden = {['loadBrainweb' 'Mri('], ['loadBrainweb' 'GroundTruth('], ['generateV4' 'Prediction('], ['sa' 've(']};
checks = [checks; {"no BrainWeb data, segmentation or MAT saving; config.m unchanged", ...
    ~any(cellfun(@(f) contains(code, f), forbidden)) && isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)}];
for i = 1:size(checks, 1)
    fprintf('%-115s %s\n', checks{i, 1}, ternary(checks{i, 2}, 'ok', 'FAILED'));
end
if any(~[checks{:, 2}])
    error('reportCh4:checksFailed', 'Report Chapter-4 figure checks failed.');
end
outputs = [string(figs.f41); string(figs.f42); string([mfilename('fullpath') '.m'])];
writetable(table(rel(outputs), string(cellfun(@sha256File, cellstr(outputs), 'UniformOutput', false)), ...
    'VariableNames', {'path', 'sha256'}), fullfile(M, 'report_ch4_figure_manifest.csv'));
fprintf('\nREPORT CHAPTER 4 FIGURES: PASS (%d)\n', size(checks, 1));


function drawGrid(ax, rgb, labels, ttl)
%DRAWGRID Griglia di celle colorate (una cella = un voxel) con etichette di testo opzionali.
    image(ax, rgb); axis(ax, 'image'); hold(ax, 'on');
    [nr, nc, ~] = size(rgb);
    for r = 0.5:1:nr + 0.5
        plot(ax, [0.5 nc + 0.5], [r r], '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.5);
    end
    for q = 0.5:1:nc + 0.5
        plot(ax, [q q], [0.5 nr + 0.5], '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.5);
    end
    for r = 1:nr
        for q = 1:nc
            if strlength(labels(r, q)) > 0
                text(ax, q, r, labels(r, q), 'HorizontalAlignment', 'center', 'FontSize', 16, 'FontWeight', 'bold');
            end
        end
    end
    hold(ax, 'off');
    set(ax, 'XTick', [], 'YTick', [], 'Box', 'on');
    if strlength(string(ttl)) > 0
        title(ax, ttl, 'FontSize', 12);
    end
end

function rgb = paintMask(mask, onColor, offColor)
%PAINTMASK Immagine RGB: onColor dove la maschera è vera, offColor altrove.
    rgb = zeros([size(mask) 3]);
    for ch = 1:3
        rgb(:, :, ch) = mask * onColor(ch) + ~mask * offColor(ch);
    end
end

function rgb = paint(rgb, mask, color)
%PAINT Colora (opaco) i pixel della maschera.
    for ch = 1:3
        layer = rgb(:, :, ch);
        layer(mask) = color(ch);
        rgb(:, :, ch) = layer;
    end
end

function outline(ax, mask, color, width)
%OUTLINE Contorno a gradini delle celle della maschera (bordi tra cella interna e cella esterna).
    hold(ax, 'on');
    [nr, nc] = size(mask);
    padded = false(nr + 2, nc + 2); padded(2:end-1, 2:end-1) = mask;
    for r = 1:nr
        for q = 1:nc
            if ~mask(r, q), continue; end
            if ~padded(r, q + 1), plot(ax, [q - 0.5 q + 0.5], [r - 0.5 r - 0.5], '-', 'Color', color, 'LineWidth', width); end
            if ~padded(r + 2, q + 1), plot(ax, [q - 0.5 q + 0.5], [r + 0.5 r + 0.5], '-', 'Color', color, 'LineWidth', width); end
            if ~padded(r + 1, q), plot(ax, [q - 0.5 q - 0.5], [r - 0.5 r + 0.5], '-', 'Color', color, 'LineWidth', width); end
            if ~padded(r + 1, q + 2), plot(ax, [q + 0.5 q + 0.5], [r - 0.5 r + 0.5], '-', 'Color', color, 'LineWidth', width); end
        end
    end
    hold(ax, 'off');
end

function [name, color] = category(p, g, cTP, cFP, cFN, cTN)
%CATEGORY Categoria di confusione di un voxel e colore corrispondente.
    if p && g
        name = "TP"; color = cTP;
    elseif p
        name = "FP"; color = cFP;
    elseif g
        name = "FN"; color = cFN;
    else
        name = "TN"; color = cTN;
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
        error('reportCh4:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
