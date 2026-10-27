%% Figure del Capitolo 5 della relazione (Protocollo sperimentale) - solo visualizzazione
% Figura 5.1: cronologia dello sviluppo e dei dati (schema; nessun dato).
% Figura 5.2: diagnostica del caso lieve - istogrammi della T2 filtrata dentro S2 per tessuto della ground
%   truth, sui cinque casi di sviluppo della v4, con i due livelli di multithresh (come la diagnostica di
%   sviluppo che ha preceduto la v4). Passi ricalcolati con gli helper congelati; i valori devono coincidere
%   con la tabella della diagnostica salvata (livelli TA, voxel per tessuto, frazioni sopra TA2).
% Figura 5.3: scelta di k - Dice dei cinque casi di sviluppo e Dice medio in funzione di k, letti dai
%   risultati salvati dell'esperimento di scelta (nessun ricalcolo).
% Nessuna segmentazione nuova, nessun risultato modificato o salvato oltre a figure e manifest.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.visualization);
M = cfg.paths.metrics; F = cfg.paths.figures;
rel = @(p) strrep(erase(string(p), string(projectRoot) + filesep), '\', '/');
readCsv = @(f) readtable(fullfile(M, f), 'TextType', 'string', 'Delimiter', ',');
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));
rawDir = fileparts(cfg.dataset.mriFiles.T1);
c101 = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'phase101');
pre = @(n, m) fullfile(rawDir, sprintf('%s_ai_msles2_1mm_%s_rf0.raws', m, n));
checks = cell(0, 2);
figs = struct('f51', fullfile(F, 'report_ch5_timeline.png'), 'f52', fullfile(F, 'report_ch5_mild_load_diagnostic.png'), ...
    'f53', fullfile(F, 'report_ch5_k_selection.png'));


%% Figura 5.1 - cronologia dello sviluppo e dei dati

steps = {
 % testo del passo                                                   dati usati / stato                                          tipo
 "Sviluppo della pipeline: prima pipeline, v1, v2, v3",              "pn0, pn3 (sviluppo)",                                       "dev"
 "Congelamento della v3",                                            "codice e risultati di sviluppo registrati con SHA-256",     "freeze"
 "Test prospettico originale della v3",                              "pn1, pn5, pn7, pn9: primo accesso, valutazione unica",      "test3"
 "Studio del carico lesionale (v3 congelata)",                       "msles1, msles2, msles3, seme 1: primo accesso",             "study"
 "Analisi del fallimento e sviluppo della v4 (scelta di k)",         "pn0, pn3, msles1-3 seme 1 (sviluppo); test riservato dichiarato", "dev"
 "Congelamento della v4",                                            "prima che esistano i dati del test riservato",              "freeze"
 "Studio dell'isteresi (non mantenuto); chiusura dello sviluppo",    "tutti i 9 casi già visti (in-sample)",                      "dev"
 "Protocollo del test riservato scritto e fissato",                  "nessun dato ancora richiesto",                              "freeze"
 "Test riservato finale della v4 (v3 come riferimento)",             "normale 0 % e 3 %, msles1 3 %, msles3 3 %, seme 2: primo accesso, valutazione unica", "test4"
 };
style = struct('dev', [0.80 0.89 1.00], 'freeze', [0.88 0.88 0.88], 'test3', [0.78 0.93 0.78], ...
    'study', [0.93 0.90 0.78], 'test4', [1.00 0.85 0.70]);
n = size(steps, 1);
fig = figure('Color', 'w', 'Position', [80 40 1300 1150]);
ax = axes(fig, 'Position', [0.02 0.09 0.96 0.86]);
hold(ax, 'on'); axis(ax, [0 100 0.3 n + 0.7]); axis(ax, 'off'); set(ax, 'YDir', 'reverse');
for i = 1:n
    rectangle(ax, 'Position', [2 i - 0.36 44 0.72], 'Curvature', 0.15, 'FaceColor', style.(steps{i, 3}), ...
        'EdgeColor', [0.35 0.35 0.35], 'LineWidth', 1);
    text(ax, 3.2, i, sprintf('%d.  %s', i, steps{i, 1}), 'FontSize', 11, 'FontWeight', 'bold', 'VerticalAlignment', 'middle');
    text(ax, 50, i, steps{i, 2}, 'FontSize', 10.5, 'VerticalAlignment', 'middle', 'Color', [0.15 0.15 0.15]);
    plot(ax, [46.5 49], [i i], ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
    if i < n                                      % freccia verso il passo successivo (asse Y invertito)
        plot(ax, [24 24], [i + 0.37 i + 0.6], '-', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.2);
        plot(ax, 24, i + 0.6, 'v', 'MarkerSize', 6, 'MarkerFaceColor', [0.35 0.35 0.35], 'MarkerEdgeColor', 'none');
    end
end
hold(ax, 'off');
title(ax, 'Cronologia dello sviluppo e uso dei dati', 'FontSize', 13);
legAx = axes(fig, 'Position', [0.02 0.01 0.96 0.06]); axis(legAx, 'off'); hold(legAx, 'on');
labels = {'sviluppo (dati visti)', 'congelamento / protocollo', 'test prospettico originale della v3', ...
    'studio di robustezza della v3', 'test riservato finale della v4'};
keys = ["dev" "freeze" "test3" "study" "test4"];
for i = 1:5
    x0 = (i - 1) * 19.5;
    rectangle(legAx, 'Position', [x0 0.3 2.6 0.4], 'FaceColor', style.(keys(i)), 'EdgeColor', [0.35 0.35 0.35]);
    text(legAx, x0 + 3.1, 0.5, labels{i}, 'FontSize', 9, 'VerticalAlignment', 'middle');
end
axis(legAx, [0 100 0 1]); hold(legAx, 'off');
exportgraphics(fig, figs.f51, 'Resolution', 250);
close(fig);


%% Figura 5.2 - diagnostica del caso lieve (istogrammi per tessuto)

known = containers.Map('KeyType', 'char', 'ValueType', 'any');
t = readCsv("phase101_result_manifest.csv");
for r = 1:height(t)
    known(char(t.path(r))) = upper(t.sha256(r));
end
known(char(rel(pre("pn0", "t1")))) = "C94E3BB8D0DF62C4D52B5A7EAFF0673F73E828A345D2FF8EE3FEEE8BD3A91FD0";
known(char(rel(pre("pn0", "t2")))) = "113EBC5E1BA1E57FE4B5F6FD2686F1B869023615B54191DD31F4EEE6A1362071";
known(char(rel(pre("pn3", "t1")))) = "AC7C6136D99F83FC6BCBF44111D2541996A146E946433F8AF2F39E95A9D8B8FE";
known(char(rel(pre("pn3", "t2")))) = "52AF70628F1211CCEF850F61E715D4D743102EAF29AD1337CDEB61BBCCFE0F7E";
dev = struct( ...
    'id',    {"pn0", "pn3", "msles1", "msles2", "msles3"}, ...
    'label', {"pn0 - moderato, rumore 0 %", "pn3 - moderato, rumore 3 %", "msles1 seme 1 - lieve", ...
              "msles2 seme 1 - moderato", "msles3 seme 1 - grave"}, ...
    't1',    {pre("pn0", "t1"), pre("pn3", "t1"), fullfile(c101, 'mri', 'custom_msles1_t1_ai_1mm_n0_inu0_job1261017-050735s-2817767.raws'), ...
              fullfile(c101, 'mri', 'custom_msles2_t1_ai_1mm_n0_inu0_job1261017-050846s-2818122.raws'), ...
              fullfile(c101, 'mri', 'custom_msles3_t1_ai_1mm_n0_inu0_job1261017-050805s-2817935.raws')}, ...
    't2',    {pre("pn0", "t2"), pre("pn3", "t2"), fullfile(c101, 'mri', 'custom_msles1_t2_ai_1mm_n0_inu0_job1261017-050750s-2817854.raws'), ...
              fullfile(c101, 'mri', 'custom_msles2_t2_ai_1mm_n0_inu0_job1261017-050720s-2817689.raws'), ...
              fullfile(c101, 'mri', 'custom_msles3_t2_ai_1mm_n0_inu0_job1261017-050820s-2818018.raws')}, ...
    'gt',    {cfg.dataset.groundTruthFile, cfg.dataset.groundTruthFile, fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles1_crisp.rawb'), ...
              cfg.dataset.groundTruthFile, fullfile(c101, 'ground_truth', 'phantom_1.0mm_msles3_crisp.rawb')});
inputs = unique([string({dev.t1}), string({dev.t2}), string({dev.gt})]);
inputsOk = all(arrayfun(@(f) isKey(known, char(rel(f))) && strcmp(sha256File(f), char(known(char(rel(f))))), inputs));
checks = [checks; {"MRI / GT inputs match their recorded SHA-256", inputsOk}];
if ~inputsOk
    error('reportCh5:blocked', 'Report Chapter-5 figures BLOCKED: input integrity check failed.');
end

d1 = readCsv("v4_d1_intensity_by_tissue.csv");
d1c = readCsv("v4_d1_condition_summary.csv");
tissues = struct('name', {"CSF", "GM", "WM", "lesion"}, 'label', {"liquor", "sostanza grigia", "sostanza bianca", "lesione"}, ...
    'code', {1, 2, 3, 10}, 'color', {[0.15 0.45 1], [0.2 0.65 0.2], [0.45 0.45 0.45], [0.9 0 0]});
edges = 0.2:0.005:1; centers = edges(1:end-1) + 0.0025;
minVoxels = 100;                                  % regola di visualizzazione: tessuti con meno voxel in S2 non disegnati
diagOk = true;
fig = figure('Color', 'w', 'Position', [40 100 1900 560]);
layout = tiledlayout(fig, 1, numel(dev), 'TileSpacing', 'compact', 'Padding', 'compact');
for i = 1:numel(dev)
    s = supportAndFilteredT2(cfg, dev(i).t1, dev(i).t2);
    labels = loadLabels(cfg, dev(i).gt);
    ta = double(multithresh(s.t2f(s.S2), 2));
    rowC = d1c(d1c.condition == dev(i).id, :);
    diagOk = diagOk && height(rowC) == 1 && max(abs(ta - [rowC.taLevel1 rowC.taLevel2])) < 1e-9 && nnz(s.S2) == rowC.S2Voxels;
    ax = nexttile(layout); hold(ax, 'on'); h = gobjects(0); names = {};
    for tt = tissues
        v = s.t2f(s.S2 & labels == tt.code);
        rowT = d1(d1.condition == dev(i).id & d1.tissue == tt.name, :);
        diagOk = diagOk && height(rowT) == 1 && numel(v) == rowT.voxelsInS2 && ...
            abs(mean(v > ta(2)) - rowT.fractionAboveTA2) < 1e-12;
        if numel(v) >= minVoxels
            counts = histcounts(v, edges, 'Normalization', 'probability');
            h(end+1) = plot(ax, centers, counts, '-', 'Color', tt.color, 'LineWidth', 1.4); %#ok<SAGROW>
            names{end+1} = sprintf('%s (%d)', tt.label, numel(v)); %#ok<SAGROW>
        end
    end
    yl = ylim(ax);
    h(end+1) = plot(ax, ta([1 1]), yl, 'k--', 'LineWidth', 1); names{end+1} = sprintf('livello 1 = %.3f', ta(1));
    h(end+1) = plot(ax, ta([2 2]), yl, 'k-', 'LineWidth', 1.8); names{end+1} = sprintf('livello TA = %.3f', ta(2));
    hold(ax, 'off'); grid(ax, 'on'); xlim(ax, [0.35 0.95]);
    xlabel(ax, 'T2 filtrata (normalizzata)');
    if i == 1, ylabel(ax, 'frazione dei voxel del tessuto'); end
    title(ax, dev(i).label, 'FontSize', 10);
    legend(ax, h, names, 'Location', 'northeast', 'FontSize', 7.5);
end
title(layout, ['T2 filtrata dentro S2 per tessuto della ground truth (istogrammi normalizzati per tessuto) e livelli di ' ...
    'multithresh - casi di sviluppo della v4']);
exportgraphics(fig, figs.f52, 'Resolution', 250);
close(fig);
checks = [checks; {"recomputed TA levels, |S2|, voxels per tissue and fractions above TA2 equal the saved diagnostic table", diagOk}];


%% Figura 5.3 - scelta di k (risultati salvati dell'esperimento di scelta)

g = readCsv("exp060_grid_results.csv");
rk = readCsv("exp060_ranking.csv");
configs = ["none" "k3" "k4" "k5" "k6"]; xl = {'nessuna', 'k = 3', 'k = 4', 'k = 5', 'k = 6'};
conds = ["pn0" "pn3" "msles1" "msles2" "msles3"];
condLabels = {'pn0', 'pn3', 'msles1 seme 1 (lieve)', 'msles2 seme 1', 'msles3 seme 1 (grave)'};
colors = lines(5);
D = zeros(numel(conds), numel(configs));
for a = 1:numel(conds)
    for b = 1:numel(configs)
        D(a, b) = g.dice(g.condition == conds(a) & g.configId == configs(b));
    end
end
meanDice = arrayfun(@(c) rk.meanDevelopmentDice(rk.configId == c), configs);
admissible = arrayfun(@(c) rk.admissible(rk.configId == c), configs);
selected = arrayfun(@(c) rk.selected(rk.configId == c), configs);
checks = [checks; {"k selection read from saved results: k5 selected, k6 not admissible, mean Dice 0.631 vs 0.569", ...
    isequal(configs(selected == 1), "k5") && admissible(5) == 0 && abs(meanDice(4) - 0.630759) < 1e-6 && ...
    abs(meanDice(1) - 0.568614) < 1e-6 && max(abs(mean(D, 1) - meanDice)) < 1e-12}];

fig = figure('Color', 'w', 'Position', [80 100 1500 600]);
layout = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile(layout); hold(ax, 'on');
for a = 1:numel(conds)
    plot(ax, 1:5, D(a, :), '-o', 'Color', colors(a, :), 'LineWidth', 1.5, 'MarkerFaceColor', colors(a, :));
end
plot(ax, [4 4], [0 0.83], '-', 'Color', [0.4 0.4 0.4], 'LineWidth', 1);
plot(ax, [5 5], [0 0.83], ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 1);
text(ax, 4, 0.835, 'k scelto', 'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold');
text(ax, 5, 0.835, 'escluso', 'HorizontalAlignment', 'center', 'FontSize', 9);
hold(ax, 'off'); grid(ax, 'on'); xlim(ax, [0.7 5.3]); ylim(ax, [0 0.87]);
set(ax, 'XTick', 1:5, 'XTickLabel', xl); ylabel(ax, 'Dice (volume completo)');
legend(ax, condLabels, 'Location', 'southeast');
title(ax, '(a) Dice dei cinque casi di sviluppo in funzione della soglia minima');
ax = nexttile(layout); hold(ax, 'on');
b = bar(ax, 1:5, meanDice, 0.6, 'FaceColor', 'flat');
for c = 1:5
    if selected(c) == 1
        b.CData(c, :) = [0.2 0.65 0.2];
    elseif admissible(c) == 1
        b.CData(c, :) = [0.6 0.75 0.9];
    else
        b.CData(c, :) = [0.9 0.55 0.55];
    end
    text(ax, c, meanDice(c) + 0.01, sprintf('%.3f', meanDice(c)), 'HorizontalAlignment', 'center', 'FontSize', 10);
end
hold(ax, 'off'); grid(ax, 'on'); ylim(ax, [0.5 0.66]); set(ax, 'XTick', 1:5, 'XTickLabel', xl);
ylabel(ax, 'Dice medio sui cinque casi di sviluppo');
title(ax, '(b) Dice medio sui cinque casi (obiettivo della scelta)');
hold(ax, 'on');
hb = [patch(ax, NaN, NaN, [0.2 0.65 0.2]), patch(ax, NaN, NaN, [0.6 0.75 0.9]), patch(ax, NaN, NaN, [0.9 0.55 0.55])];
hold(ax, 'off');
legend(ax, hb, {'scelto', 'ammissibile', 'escluso dal vincolo di non inferiorità'}, 'Location', 'northwest');
title(layout, 'Scelta del coefficiente k della soglia minima \mu_{ref} + k\sigma_{ref} (valori in-sample)');
exportgraphics(fig, figs.f53, 'Resolution', 250);
close(fig);


%% Verifiche e manifest

code = char(strjoin(regexprep(splitlines(string(fileread([mfilename('fullpath') '.m']))), '%.*$', ''), newline));
forbidden = {['generateV4' 'Prediction('], ['generateFinal' 'Prediction('], ['computeDice' 'FromConfusion('], ['sa' 've(']};
inputsAfter = all(arrayfun(@(f) strcmp(sha256File(f), char(known(char(rel(f))))), inputs));
checks = [checks; {"no prediction generated, no metric computed, no MAT saving; inputs and config.m unchanged AFTER", ...
    ~any(cellfun(@(f) contains(code, f), forbidden)) && inputsAfter && isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)}];
for i = 1:size(checks, 1)
    fprintf('%-115s %s\n', checks{i, 1}, ternary(checks{i, 2}, 'ok', 'FAILED'));
end
if any(~[checks{:, 2}])
    error('reportCh5:checksFailed', 'Report Chapter-5 figure checks failed.');
end
outputs = [string(figs.f51); string(figs.f52); string(figs.f53); string([mfilename('fullpath') '.m'])];
writetable(table(rel(outputs), string(cellfun(@sha256File, cellstr(outputs), 'UniformOutput', false)), ...
    'VariableNames', {'path', 'sha256'}), fullfile(M, 'report_ch5_figure_manifest.csv'));
fprintf('\nREPORT CHAPTER 5 FIGURES: PASS (%d)\n', size(checks, 1));


function s = supportAndFilteredT2(cfg, t1Path, t2Path)
%SUPPORTANDFILTEREDT2 S2 e T2 filtrata con gli stessi helper congelati della pipeline (solo visualizzazione).
    cfg.dataset.noisyMriFiles.vis.T1 = char(t1Path);
    cfg.dataset.noisyMriFiles.vis.T2 = char(t2Path);
    normalize = @(raw) normalizeFixedRange(convertToWorkingClass(raw, "double"), [0 4095], [0 1]);
    t1n = normalize(loadBrainwebMri(cfg, "T1", "vis"));
    t2n = normalize(loadBrainwebMri(cfg, "T2", "vis"));
    B = brainMask3DErodeSelectDilate(initialSupportMask(t1n), 3, 26);
    supports = computeT1AnatomicalSupport(t1n, B);
    s.S2 = supports.S2;
    s.t2f = min(max(anisotropicDiffusionVolume3D(t2n), 0), 1);
end

function labels = loadLabels(cfg, path)
%LOADLABELS Etichette della ground truth crisp (usate solo per separare i tessuti nella figura diagnostica).
    cfg.dataset.groundTruthFile = char(path);
    labels = loadBrainwebGroundTruth(cfg);
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
        error('reportCh5:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
