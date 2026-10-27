%% Figure del Capitolo 6 della relazione (Risultati) - versioni in italiano, solo visualizzazione
% 6.1 traiettoria dello sviluppo (ablazione); 6.2 robustezza al rumore; 6.3 carico lesionale;
% 6.4 test riservato v3 / v4; 6.5 panoramica 2D finale; 6.6-6.8 viste 3D (predizione, GT vs predizione,
% TP / FP / FN). Grafici: valori letti dalle tabelle congelate (fasi 99 e 119). Figure di immagini: stesse
% predizioni salvate, ground truth, casi, slice, colori e vista delle figure finali (fasi 105-120).
% Nessuna segmentazione, nessuna metrica ricalcolata per i risultati: i conteggi mostrati sono confrontati
% con la fase 103 e con l'indice delle slice; le figure congelate originali non vengono toccate.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.visualization);
M = cfg.paths.metrics; F = cfg.paths.figures; P = cfg.paths.processedData;
rel = @(p) strrep(erase(string(p), string(projectRoot) + filesep), '\', '/');
readCsv = @(f) readtable(fullfile(M, f), 'TextType', 'string', 'Delimiter', ',');
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));
c101 = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'phase101');
cRes = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'v4_reserved_test');
checks = cell(0, 2);
cV3 = [0.85 0.33 0.10]; cV4 = [0.00 0.45 0.74];          % colori delle due versioni nei grafici
cTP = [0 1 0]; cFP = [1 0 0]; cFN = [0 0.35 1]; cGT = [0 0.9 0.9]; cPred = [1 0.85 0];
figs = struct('f1', 'report_ch6_ablation_trajectory.png', 'f2', 'report_ch6_noise.png', 'f3', 'report_ch6_lesion_load.png', ...
    'f4', 'report_ch6_reserved_v3_v4.png', 'f5', 'report_ch6_2d_overview.png', 'f6', 'report_ch6_3d_prediction.png', ...
    'f7', 'report_ch6_3d_gt_prediction.png', 'f8', 'report_ch6_3d_tp_fp_fn.png');
figs = structfun(@(f) fullfile(F, f), figs, 'UniformOutput', false);

% Integrità del pacchetto congelato (prima)
pkA = readCsv("phase118_final_results_source_manifest.csv"); pkB = readCsv("phase118_120_final_report_package_manifest.csv");
pk = [pkA(:, {'path', 'sha256'}); pkB(:, {'path', 'sha256'})];
manifestOk = @(t) all(arrayfun(@(i) strcmp(sha256File(fullfile(projectRoot, t.path(i))), t.sha256(i)), 1:height(t)));
frozenBefore = manifestOk(pk);
checks = [checks; {"frozen Phase-118/120 result package valid BEFORE", frozenBefore}];
if ~frozenBefore
    error('reportCh6:blocked', 'Report Chapter-6 figures BLOCKED: frozen package integrity failed.');
end
audit = readCsv("phase119_full_results_audit.csv");
row = @(id, v) audit(audit.caseId == id & audit.version == v, :);
val = @(id, v, name) auditValue(audit, id, v, name);


%% Figura 6.1 - traiettoria dello sviluppo (ablazione, fase 99)

traj = readCsv("phase99_development_trajectory.csv");
stepLabels = {'soglia multi-livello', '+ apertura quadrata', '+ filtro componenti', '+ supporto S2 (v1)', ...
    '+ filtro anisotropo 2D (v2)', 'filtro 2D \rightarrow 3D', 'quadrato \rightarrow diamante', '- filtro componenti (v3)'};
checks = [checks; {"trajectory: 8 steps, last = v3 development score 0.690", height(traj) == 8 && ...
    abs(traj.developmentScore(end) - 0.689891619845975) < 1e-12}];
fig = figure('Color', 'w', 'Position', [80 100 1500 620]);
ax = axes(fig); hold(ax, 'on');
b = bar(ax, 1:8, traj.developmentScore, 0.6, 'FaceColor', 'flat');
for i = 1:8
    b.CData(i, :) = ternary(any(i == [4 5 8]), [0.20 0.55 0.80], [0.70 0.80 0.90]);
    text(ax, i, traj.developmentScore(i) + 0.015, sprintf('%.3f', traj.developmentScore(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10);
end
hold(ax, 'off'); grid(ax, 'on'); ylim(ax, [0 0.78]);
set(ax, 'XTick', 1:8, 'XTickLabel', stepLabels, 'XTickLabelRotation', 20, 'FontSize', 10);
ylabel(ax, 'punteggio di sviluppo (media del Dice su pn0 e pn3)');
title(ax, {'Percorso di sviluppo come catena di modifiche di un solo blocco (valori in-sample)', ...
    'in blu scuro le versioni congelate v1, v2 e v3'}, 'FontWeight', 'normal');
exportgraphics(fig, figs.f1, 'Resolution', 250);
close(fig);


%% Figura 6.2 - robustezza al rumore (v3: sviluppo / test prospettico; v4: dati visti)

ids = ["pn0" "pn1" "pn3" "pn5" "pn7" "pn9"]; noise = [0 1 3 5 7 9]; isDev = [1 0 1 0 0 0] == 1;
metricsNames = ["dice" "precision" "recall"]; metricLabels = {'Dice', 'Precision', 'Recall'};
V3 = zeros(3, 6); V4 = zeros(3, 6);
for j = 1:6
    for m = 1:3
        V3(m, j) = val(ids(j), "v3", metricsNames(m)); V4(m, j) = val(ids(j), "v4", metricsNames(m));
    end
end
fig = figure('Color', 'w', 'Position', [60 100 1700 560]);
layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
for m = 1:3
    ax = nexttile(layout); hold(ax, 'on');
    plot(ax, noise, V3(m, :), '-', 'Color', cV3, 'LineWidth', 1.6);
    h2 = plot(ax, noise(isDev), V3(m, isDev), 'o', 'Color', cV3, 'MarkerSize', 8, 'LineWidth', 1.5, 'MarkerFaceColor', 'w');
    h3 = plot(ax, noise(~isDev), V3(m, ~isDev), 'o', 'Color', cV3, 'MarkerSize', 8, 'MarkerFaceColor', cV3);
    h4 = plot(ax, noise, V4(m, :), '--s', 'Color', cV4, 'LineWidth', 1.4, 'MarkerSize', 7, 'MarkerFaceColor', cV4);
    hold(ax, 'off'); grid(ax, 'on'); ylim(ax, [0 1]); xlim(ax, [-0.5 9.5]);
    set(ax, 'XTick', noise); xlabel(ax, 'rumore (%)'); ylabel(ax, metricLabels{m});
    title(ax, metricLabels{m});
    if m == 3
        legend(ax, [h2 h3 h4], {'v3 - sviluppo (pn0, pn3)', 'v3 - test prospettico originale', ...
            'v4 - dati visti (non test indipendente)'}, 'Location', 'southwest');
    end
end
title(layout, 'Robustezza al rumore sul phantom msles2 (database pre-calcolato)');
exportgraphics(fig, figs.f2, 'Resolution', 250);
close(fig);


%% Figura 6.3 - carico lesionale (seme 1, rumore 0 %)

lids = ["custom_s1_msles1" "custom_s1_msles2" "custom_s1_msles3"];
lLabels = {'msles1 (lieve)', 'msles2 (moderato)', 'msles3 (grave)'};
fig = figure('Color', 'w', 'Position', [60 100 1700 560]);
layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
L = zeros(3, 3, 2);
for m = 1:3
    for j = 1:3
        L(m, j, 1) = val(lids(j), "v3", metricsNames(m)); L(m, j, 2) = val(lids(j), "v4", metricsNames(m));
    end
    ax = nexttile(layout);
    bb = bar(ax, 1:3, squeeze(L(m, :, :)), 0.8);
    bb(1).FaceColor = cV3; bb(2).FaceColor = cV4;
    for s = 1:2
        text(ax, bb(s).XEndPoints, bb(s).YEndPoints + 0.02, compose('%.3f', bb(s).YData), ...
            'HorizontalAlignment', 'center', 'FontSize', 8.5);
    end
    grid(ax, 'on'); ylim(ax, [0 1]); set(ax, 'XTick', 1:3, 'XTickLabel', lLabels);
    ylabel(ax, metricLabels{m}); title(ax, metricLabels{m});
    if m == 1
        legend(ax, {'v3', 'v4 (dati visti)'}, 'Location', 'northwest');
    end
end
title(layout, 'Robustezza al carico lesionale - simulazioni con seme 1, rumore 0 %');
exportgraphics(fig, figs.f3, 'Resolution', 250);
close(fig);


%% Figura 6.4 - test riservato: v3 (riferimento) e v4 (versione finale)

main = readCsv("phase119_main_results_v4_reserved.csv");
nIds = ["reserved_normal_n0" "reserved_normal_n3"];
FPn = [arrayfun(@(i) val(i, "v3", "FP"), nIds); arrayfun(@(i) val(i, "v4", "FP"), nIds)].';
lesIds = ["reserved_msles1_n3" "reserved_msles3_n3"];
R = zeros(6, 2); rLabels = cell(1, 6); k = 0;
for j = 1:2
    for m = 1:3
        k = k + 1;
        R(k, :) = [val(lesIds(j), "v3", metricsNames(m)), val(lesIds(j), "v4", metricsNames(m))];
        rLabels{k} = sprintf('%s - %s', ternary(j == 1, 'msles1 3 %', 'msles3 3 %'), metricLabels{m});
    end
end
mainOk = isequal(FPn(:, 2).', main.FP(1:2).') && ...
    max(abs([R(1:3, 2).' R(4:6, 2).'] - [main.dice(3) main.precision(3) main.recall(3) main.dice(4) main.precision(4) main.recall(4)])) < 1e-12;
checks = [checks; {"reserved-test values in Figure 6.4 equal the primary table (v4) and the audit table (v3)", mainOk && ...
    isequal(FPn(:, 1).', [31917 17486])}];
fig = figure('Color', 'w', 'Position', [60 100 1750 600]);
layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile(layout);
bb = bar(ax, 1:2, FPn, 0.8); bb(1).FaceColor = cV3; bb(2).FaceColor = cV4;
set(ax, 'YScale', 'log'); ylim(ax, [1 1e5]); grid(ax, 'on');
for s = 1:2
    text(ax, bb(s).XEndPoints, bb(s).YEndPoints * 1.4, compose('%d', bb(s).YData), 'HorizontalAlignment', 'center', 'FontSize', 10);
end
set(ax, 'XTick', 1:2, 'XTickLabel', {'normale, rumore 0 %', 'normale, rumore 3 %'});
ylabel(ax, 'voxel falsi positivi (scala log)'); title(ax, '(a) phantom normale senza lesioni');
legend(ax, {'v3 (riferimento)', 'v4 (versione finale)'}, 'Location', 'northeast');
ax = nexttile(layout, [1 2]);
bb = bar(ax, 1:6, R, 0.8); bb(1).FaceColor = cV3; bb(2).FaceColor = cV4;
for s = 1:2
    text(ax, bb(s).XEndPoints, bb(s).YEndPoints + 0.02, compose('%.3f', bb(s).YData), 'HorizontalAlignment', 'center', 'FontSize', 9);
end
grid(ax, 'on'); ylim(ax, [0 1]); set(ax, 'XTick', 1:6, 'XTickLabel', rLabels);
title(ax, '(b) phantom con lesioni: Dice, Precision e Recall');
title(layout, 'Test riservato finale (seme 2): v3 come riferimento e v4 come versione finale, entrambe congelate');
exportgraphics(fig, figs.f4, 'Resolution', 250);
close(fig);


%% Dati delle figure di immagini (stessi casi e predizioni delle figure finali)

known = containers.Map('KeyType', 'char', 'ValueType', 'any');
for mf = ["phase101_result_manifest.csv" "v4_reserved_test_manifest.csv" "phase118_final_results_source_manifest.csv"]
    t = readCsv(mf);
    for r = 1:height(t)
        known(char(t.path(r))) = upper(t.sha256(r));
    end
end
known(char(rel(cfg.dataset.noisyMriFiles.pn3.T1))) = "AC7C6136D99F83FC6BCBF44111D2541996A146E946433F8AF2F39E95A9D8B8FE";
known(char(rel(cfg.dataset.noisyMriFiles.pn3.T2))) = "52AF70628F1211CCEF850F61E715D4D743102EAF29AD1337CDEB61BBCCFE0F7E";
cs = struct( ...
    'caseId', {"pn3", "reserved_msles1_n3", "reserved_msles3_n3"}, ...
    'label',  {"pn3 - carico moderato (sviluppo)", "msles1 3 % - carico lieve (test riservato)", "msles3 3 % - carico grave (test riservato)"}, ...
    't1',     {cfg.dataset.noisyMriFiles.pn3.T1, fullfile(cRes, 'mri', 'custom_msles1_t1_ai_1mm_n3_inu0_seed2_job1261017-094208s-2845311.raws'), ...
               fullfile(cRes, 'mri', 'custom_msles3_t1_ai_1mm_n3_inu0_seed2_job1261017-094301s-2845466.raws')}, ...
    't2',     {cfg.dataset.noisyMriFiles.pn3.T2, fullfile(cRes, 'mri', 'custom_msles1_t2_ai_1mm_n3_inu0_seed2_job1261017-094235s-2845389.raws'), ...
               fullfile(cRes, 'mri', 'custom_msles3_t2_ai_1mm_n3_inu0_seed2_job1261017-094329s-2845552.raws')}, ...
    'gt',     {cfg.dataset.groundTruthFile, fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles1_crisp.rawb'), ...
               fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles3_crisp.rawb')}, ...
    'pred',   {fullfile(P, 'exp060_candidates', 'exp060_k5_pn3.mat'), fullfile(P, 'v4test_v4_msles1_n3_prediction.mat'), ...
               fullfile(P, 'v4test_v4_msles3_n3_prediction.mat')});
inputs = [string({cs.t1}), string({cs.t2}), string({cs.gt}), string({cs.pred})];
inputsOk = all(arrayfun(@(f) isKey(known, char(rel(f))) && strcmp(sha256File(f), char(known(char(rel(f))))), inputs));
checks = [checks; {"T1 / T2 / GT / saved v4 predictions match their recorded SHA-256", inputsOk}];
if ~inputsOk
    error('reportCh6:blocked', 'Report Chapter-6 figures BLOCKED: input integrity check failed.');
end
idx105 = readCsv("phase105_107_visualization_index.csv");
data = struct([]); dataOk = isequal(idx105.caseId(1:3).', [cs.caseId]);
for i = 1:3
    v = struct();
    v.t2 = double(readVolume(cfg, cs(i).t2, "T2"));
    t1n = normalizeFixedRange(convertToWorkingClass(readVolume(cfg, cs(i).t1, "T1"), "double"), [0 4095], [0 1]);
    v.brain = brainMask3DErodeSelectDilate(initialSupportMask(t1n), 3, 26);
    v.gt = readGt(cfg, cs(i).gt);
    s = load(cs(i).pred, 'M_pred'); v.pred = s.M_pred;
    r4 = row(cs(i).caseId, "v4");
    dataOk = dataOk && islogical(v.pred) && isequal(size(v.pred), size(v.gt), [181 217 181]) && ...
        r4.predictedVoxels == nnz(v.pred) && r4.TP == nnz(v.pred & v.gt) && r4.FP == nnz(v.pred & ~v.gt) && ...
        r4.FN == nnz(~v.pred & v.gt) && r4.brainMaskVoxels == nnz(v.brain);
    v.k = idx105.sliceIndex(i);
    data = [data v]; %#ok<AGROW>
end
checks = [checks; {"same cases and saved predictions as the final figures; voxel counts and brain masks equal Phase 103", dataOk}];
if ~dataOk
    error('reportCh6:blocked', 'Report Chapter-6 figures BLOCKED: image inputs differ from the frozen results.');
end


%% Figura 6.5 - panoramica 2D finale (in italiano)

rowNames = {'pn3 - moderato (sviluppo)', 'msles1 3 % - lieve (test riservato)', 'msles3 3 % - grave (test riservato)'};
colTitles = ["T2 originale" "T2 + ground truth" "T2 + predizione v4" "T2 + TP / FP / FN"];
fig = figure('Color', 'w', 'Position', [60 60 1500 1200]);
layout = tiledlayout(fig, 3, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
sliceOk = true;
for i = 1:3
    k = data(i).k; range = [min(data(i).t2(:)) max(data(i).t2(:))];
    mri = data(i).t2(:, :, k); g = data(i).gt(:, :, k); p = data(i).pred(:, :, k);
    tt = repmat("", 1, 4); if i == 1, tt = colTitles; end
    ax = nexttile(layout);
    overlayMaskBoundaryOnMRI(ax, mri, false(size(g)), 'DisplayRange', range, 'Title', tt(1));
    ylabel(ax, sprintf('%s\nslice k = %d', rowNames{i}, k), 'FontSize', 9);
    overlayMaskBoundaryOnMRI(nexttile(layout), mri, g, 'BoundaryColor', cGT, 'ShowFill', true, 'FillAlpha', 0.45, ...
        'DisplayRange', range, 'Title', tt(2));
    overlayMaskBoundaryOnMRI(nexttile(layout), mri, p, 'BoundaryColor', cPred, 'ShowFill', true, 'FillAlpha', 0.45, ...
        'DisplayRange', range, 'Title', tt(3));
    cnt = overlayErrorMapOnMRI(nexttile(layout), mri, p, g, 'Alpha', 0.6, 'DisplayRange', range, 'Title', tt(4));
    sliceOk = sliceOk && cnt.TP == idx105.tpVoxelsInSlice(i) && cnt.FP == idx105.fpVoxelsInSlice(i) && cnt.FN == idx105.fnVoxelsInSlice(i);
end
ax = nexttile(layout, 12); hold(ax, 'on');
h = [patch(ax, NaN, NaN, cGT), patch(ax, NaN, NaN, cPred), patch(ax, NaN, NaN, cTP), patch(ax, NaN, NaN, cFP), patch(ax, NaN, NaN, cFN)];
hold(ax, 'off');
legend(ax, h, {'ground truth', 'predizione v4', 'TP', 'FP', 'FN'}, 'Location', 'southoutside', 'Orientation', 'horizontal');
title(layout, 'Segmentazione finale della v4 su T2 (rumore 3 %)');
exportgraphics(fig, figs.f5, 'Resolution', 250);
close(fig);
checks = [checks; {"2D overview: same slices as the frozen index; slice TP / FP / FN equal the index", sliceOk}];


%% Figure 6.6-6.8 - viste 3D (stessa vista, limiti e colori delle figure finali)

for which = ["f6" "f7" "f8"]
    fig = figure('Color', 'w', 'Position', [60 100 1650 620]);
    layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    for i = 1:3
        ax = nexttile(layout); hold(ax, 'on');
        d = data(i);
        switch which
            case "f6"
                renderMask3DSurface(ax, d.brain, [0.55 0.55 0.55], 0.07);
                renderMask3DSurface(ax, d.pred, cPred, 0.9);
            case "f7"
                renderMask3DSurface(ax, d.brain, [0.55 0.55 0.55], 0.07);
                renderMask3DSurface(ax, d.gt, cGT, 0.45);
                renderMask3DSurface(ax, d.pred, cPred, 0.45);
            case "f8"
                renderMask3DSurface(ax, d.pred & d.gt, cTP, 0.6);
                renderMask3DSurface(ax, d.pred & ~d.gt, cFP, 0.6);
                renderMask3DSurface(ax, ~d.pred & d.gt, cFN, 0.6);
        end
        hold(ax, 'off'); daspect(ax, [1 1 1]);
        xlim(ax, [0.5 181.5]); ylim(ax, [0.5 217.5]); zlim(ax, [0.5 181.5]);
        view(ax, -37.5, 30);
        set(ax, 'Projection', 'orthographic', 'Box', 'on', 'FontSize', 8);
        camlight(ax, 'headlight'); lighting(ax, 'gouraud'); material(ax, 'dull');
        xlabel(ax, 'X (dim 1, voxel)'); ylabel(ax, 'Y (dim 2, voxel)'); zlabel(ax, 'Z (dim 3, slice)');
        title(ax, cs(i).label, 'FontSize', 10, 'Interpreter', 'none');
    end
    ax = nexttile(layout, 3); hold(ax, 'on');
    switch which
        case "f6"
            h = [patch(ax, NaN, NaN, [0.55 0.55 0.55], 'FaceAlpha', 0.3), patch(ax, NaN, NaN, cPred)];
            names = {'maschera cerebrale automatica (solo contesto)', 'predizione v4'};
            ttl = 'Maschera completa della v4 in 3D';
        case "f7"
            h = [patch(ax, NaN, NaN, [0.55 0.55 0.55], 'FaceAlpha', 0.3), patch(ax, NaN, NaN, cGT, 'FaceAlpha', 0.45), ...
                patch(ax, NaN, NaN, cPred, 'FaceAlpha', 0.45)];
            names = {'maschera cerebrale automatica (solo contesto)', 'ground truth', 'predizione v4'};
            ttl = 'Ground truth e predizione della v4 in 3D';
        case "f8"
            h = [patch(ax, NaN, NaN, cTP), patch(ax, NaN, NaN, cFP), patch(ax, NaN, NaN, cFN)];
            names = {'TP', 'FP', 'FN'};
            ttl = 'Errori della v4 in 3D (TN non mostrati)';
    end
    hold(ax, 'off');
    legend(ax, h, names, 'Location', 'southoutside', 'Orientation', 'horizontal');
    title(layout, ttl);
    subtitle(layout, 'volume completo 181 \times 217 \times 181, voxel isotropi da 1 mm, stessa vista per tutti i casi; maschere non modificate');
    exportgraphics(fig, figs.(which), 'Resolution', 250);
    close(fig);
end


%% Verifiche e manifest

code = char(strjoin(regexprep(splitlines(string(fileread([mfilename('fullpath') '.m']))), '%.*$', ''), newline));
forbidden = {['generateV4' 'Prediction('], ['generateFinal' 'Prediction('], ['multi' 'thresh('], ['computeDice' 'FromConfusion('], ...
    ['smo' 'oth3('], ['sa' 've(']};
checks = [checks; {"no segmentation, metric recomputation, smoothing or MAT saving; frozen package, inputs and config.m unchanged AFTER", ...
    ~any(cellfun(@(f) contains(code, f), forbidden)) && manifestOk(pk) && ...
    all(arrayfun(@(f) strcmp(sha256File(f), char(known(char(rel(f))))), inputs)) && ...
    isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)}];
for i = 1:size(checks, 1)
    fprintf('%-120s %s\n', checks{i, 1}, ternary(checks{i, 2}, 'ok', 'FAILED'));
end
if any(~[checks{:, 2}])
    error('reportCh6:checksFailed', 'Report Chapter-6 figure checks failed.');
end
outputs = [string(struct2cell(figs)); string([mfilename('fullpath') '.m'])];
writetable(table(rel(outputs), string(cellfun(@sha256File, cellstr(outputs), 'UniformOutput', false)), ...
    'VariableNames', {'path', 'sha256'}), fullfile(M, 'report_ch6_figure_manifest.csv'));
fprintf('\nREPORT CHAPTER 6 FIGURES: PASS (%d)\n', size(checks, 1));


function x = auditValue(audit, id, version, name)
%AUDITVALUE Valore di una colonna della tabella di audit congelata per un caso e una versione.
    r = audit(audit.caseId == id & audit.version == version, :);
    if height(r) ~= 1
        error('reportCh6:auditRow', 'Expected one audit row for %s / %s.', id, version);
    end
    x = r.(char(name));
end

function v = readVolume(cfg, path, modality)
%READVOLUME Volume MRI raw tramite il loader del progetto (copia locale di cfg).
    cfg.dataset.noisyMriFiles.vis.(char(modality)) = char(path);
    v = loadBrainwebMri(cfg, char(modality), "vis");
end

function m = readGt(cfg, path)
%READGT Maschera della ground truth (label 10).
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
        error('reportCh6:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
