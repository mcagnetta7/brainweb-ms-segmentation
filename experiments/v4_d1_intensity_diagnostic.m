%% v4 / D1: diagnostica delle intensità del T2 filtrato dentro S2, per tessuto (solo sviluppo)
% Emendamento A3, passo D1. Nessuna predizione, nessuna scelta di parametri: ricalcola
% soltanto le grandezze intermedie della pipeline congelata v3 (maschera EXP-021, S2,
% T2 filtrato D3, livelli TA = multithresh(T2f(S2), 2)) con gli stessi helper e le
% confronta con i tessuti del GT discreto. Il GT è usato perché sono dati di SVILUPPO
% (pn0, pn3, custom msles1 / msles2 / msles3); serve a orientare il disegno di EXP-060.
% Il test riservato della v4 (fantoccio normal, msles1 / msles3 con rumore 3 %) non esiste ancora.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);
M = cfg.paths.metrics;
manifest96 = readtable(fullfile(M, 'phase96_final_freeze_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
frozenOk = @() all(arrayfun(@(i) strcmp(sha256File(fullfile(projectRoot, manifest96.path(i))), manifest96.sha256(i)), ...
    1:height(manifest96)));
frozenBefore = frozenOk();

customDir = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'phase101');
cfgDev = cfg;
custom = struct('msles1', {{'custom_msles1_t1_ai_1mm_n0_inu0_job1261017-050735s-2817767.raws', ...
    'custom_msles1_t2_ai_1mm_n0_inu0_job1261017-050750s-2817854.raws'}}, ...
    'msles2', {{'custom_msles2_t1_ai_1mm_n0_inu0_job1261017-050846s-2818122.raws', ...
    'custom_msles2_t2_ai_1mm_n0_inu0_job1261017-050720s-2817689.raws'}}, ...
    'msles3', {{'custom_msles3_t1_ai_1mm_n0_inu0_job1261017-050805s-2817935.raws', ...
    'custom_msles3_t2_ai_1mm_n0_inu0_job1261017-050820s-2818018.raws'}});
for p = ["msles1" "msles2" "msles3"]
    cfgDev.dataset.noisyMriFiles.(p).T1 = fullfile(customDir, 'mri', custom.(p){1});
    cfgDev.dataset.noisyMriFiles.(p).T2 = fullfile(customDir, 'mri', custom.(p){2});
end
conditions = ["pn0" "pn3" "msles1" "msles2" "msles3"];
gtFile = struct('pn0', cfg.dataset.groundTruthFile, 'pn3', cfg.dataset.groundTruthFile, ...
    'msles1', fullfile(customDir, 'ground_truth', 'phantom_1.0mm_msles1_crisp.rawb'), ...
    'msles2', cfg.dataset.groundTruthFile, ...
    'msles3', fullfile(customDir, 'ground_truth', 'phantom_1.0mm_msles3_crisp.rawb'));
tissues = struct('label', {1, 2, 3, 10}, 'name', {"CSF", "GM", "WM", "lesion"});

tissueRows = cell(0, 13);
condRows = cell(0, 16);
t2fKeep = struct();
for c = conditions
    rawT1 = loadBrainwebMri(cfgDev, "T1", c);
    rawT2 = loadBrainwebMri(cfgDev, "T2", c);
    t1n = normalizeFixedRange(convertToWorkingClass(rawT1, "double"), [0 4095], [0 1]);
    t2n = normalizeFixedRange(convertToWorkingClass(rawT2, "double"), [0 4095], [0 1]);
    brainMask = brainMask3DErodeSelectDilate(initialSupportMask(t1n), 3, 26);
    [sup, sd] = computeT1AnatomicalSupport(t1n, brainMask);
    t2f = min(max(anisotropicDiffusionVolume3D(t2n), 0), 1);
    [levels, sep] = multithresh(t2f(sup.S2), 2);
    t1Classes = imquantize(t1n, sd.t1ThresholdsNormalized);
    cfgGt = cfg; cfgGt.dataset.groundTruthFile = gtFile.(c);
    labels = loadBrainwebGroundTruth(cfgGt);
    inS2 = sup.S2;
    for t = tissues
        v = t2f(inS2 & labels == t.label);
        tissueRows(end+1, :) = {c, t.name, numel(v), mean(v), std(v), pct(v, 5), pct(v, 25), median(v), ...
            pct(v, 75), pct(v, 95), mean(v > levels(1)), mean(v > levels(2)), nnz(inS2 & labels ~= 10 & t2f > levels(2))}; %#ok<SAGROW>
    end
    % Riferimenti ricavabili SENZA GT: T1-alto (sostanza bianca candidata) e T1-medio dentro S2
    wmRef = t2f(inS2 & t1Classes == 3);
    midRef = t2f(inS2 & t1Classes == 2);
    condRows(end+1, :) = {c, nnz(inS2), levels(1), levels(2), levels(2) - levels(1), sep, ...
        mean(wmRef), std(wmRef), numel(wmRef), mean(midRef), std(midRef), numel(midRef), ...
        nnz(inS2 & t2f > levels(2)), nnz(inS2 & labels == 10), nnz(labels == 10), ...
        nnz(inS2 & labels == 10 & t2f > levels(2))}; %#ok<SAGROW>
    t2fKeep.(c) = struct('t2f', t2f(inS2), 'labels', labels(inS2), 'levels', levels);
    fprintf('%s: TA levels [%.4f %.4f], gap %.4f, separability %.4f\n', c, levels(1), levels(2), levels(2) - levels(1), sep);
end
byTissue = cell2table(tissueRows, 'VariableNames', {'condition', 'tissue', 'voxelsInS2', 'meanT2f', 'stdT2f', ...
    'p05', 'p25', 'median', 'p75', 'p95', 'fractionAboveTA1', 'fractionAboveTA2', 'nonLesionAboveTA2'});
summary = cell2table(condRows, 'VariableNames', {'condition', 'S2Voxels', 'taLevel1', 'taLevel2', 'taGap', ...
    'multithreshSeparability', 'meanT2fT1High', 'stdT2fT1High', 'voxelsT1High', 'meanT2fT1Mid', 'stdT2fT1Mid', ...
    'voxelsT1Mid', 'voxelsAboveTA2', 'lesionVoxelsInS2', 'lesionVoxelsTotal', 'lesionVoxelsAboveTA2'});
writetable(byTissue, fullfile(M, 'v4_d1_intensity_by_tissue.csv'));
writetable(summary, fullfile(M, 'v4_d1_condition_summary.csv'));
disp(summary);
disp(byTissue(:, {'condition', 'tissue', 'voxelsInS2', 'meanT2f', 'stdT2f', 'p05', 'median', 'p95', 'fractionAboveTA2'}));

% Figura: istogrammi del T2 filtrato dentro S2 per tessuto, con le due soglie TA
fig = figure('Color', 'w');
layout = tiledlayout(fig, 1, numel(conditions), 'TileSpacing', 'compact');
edges = linspace(0, 1, 101);
colors = struct('CSF', [0.2 0.6 1], 'GM', [0.4 0.7 0.3], 'WM', [0.6 0.6 0.6], 'lesion', [0.9 0.2 0.2]);
for c = conditions
    ax = nexttile(layout); hold(ax, 'on');
    k = t2fKeep.(c);
    for t = tissues
        v = k.t2f(k.labels == t.label);
        if ~isempty(v)
            h = histcounts(v, edges, 'Normalization', 'probability');
            plot(ax, edges(1:end-1) + 0.005, h, 'Color', colors.(t.name), 'LineWidth', 1.4);
        end
    end
    xline(ax, k.levels(1), 'k--'); xline(ax, k.levels(2), 'k-', 'LineWidth', 1.5);
    hold(ax, 'off'); xlim(ax, [0.2 1]); grid(ax, 'on'); title(ax, c); xlabel(ax, 'filtered T2 (normalized)');
end
legend(ax, [cellstr([tissues.name]), {'TA level 1', 'TA level 2'}], 'Location', 'northeast');
title(layout, {'v4 / D1 - filtered T2 inside S2 by GT tissue (DEVELOPMENT data only; per-tissue normalized histograms)', ...
    'dashed = TA level 1, solid = TA level 2 (v3 threshold)'});
fig.Position(3:4) = [1600 400];
exportgraphics(fig, fullfile(cfg.paths.figures, 'v4_d1_t2_by_tissue.png'));

frozenAfter = frozenOk();
fprintf('\nfrozen v3 sources unchanged (26 hashes, before / after): %d / %d\n', frozenBefore, frozenAfter);
if ~(frozenBefore && frozenAfter)
    error('v4d1:frozenChanged', 'Frozen v3 sources changed.');
end
fprintf('v4 / D1 DIAGNOSTIC: DONE (no prediction generated)\n');


function q = pct(v, p)
%PCT Percentile p (0..100) per rango più vicino, senza toolbox statistici.
    if isempty(v)
        q = NaN;
        return
    end
    s = sort(v(:));
    q = s(max(1, min(numel(s), ceil(p / 100 * numel(s)))));
end

function h = sha256File(f)
%SHA256FILE Impronta SHA-256 (esadecimale maiuscolo) tramite certutil di Windows.
    [status, out] = system(sprintf('certutil -hashfile "%s" SHA256', f));
    lines = erase(strtrim(splitlines(string(out))), " ");
    match = lines(strlength(lines) == 64 & ~cellfun(@isempty, regexp(cellstr(lines), '^[0-9a-fA-F]{64}$')));
    if status ~= 0 || numel(match) ~= 1
        error('v4d1:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
