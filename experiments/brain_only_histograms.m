%% Fase 40: istogrammi delle sole intensità cerebrali (ripresa dopo la fase 52)
% Roadmap: "dopo la brain mask, analizzare solo i tessuti cerebrali".
% Ripresa come dichiarato nella §13.17 (rinviata il 2026-10-04):
%   - maschera = EXP-021 congelata e validata (fasi 50-52), stessa
%     condizione del volume (pn0 -> pn0, pn3 -> pn3);
%   - valori = volume grezzo(brainMask) (MAI il volume con zeri fuori
%     maschera: gli zeri inseriti sarebbero artificiali);
%   - binning della fase 39: un bin per valore grezzo 0...4095
%     (bordi -0.5:1:4095.5), identico per tutte le modalità;
%   - pn0: T1, T2, PD (stessa configurazione delle fasi 38-39);
%     pn3: T1, T2 (la PD pn3 non è stata scaricata e non serve);
%   - confronto qualitativo con gli istogrammi globali della fase 39.
% Circolarità dichiarata: la maschera deriva dalla soglia Otsu della T1,
% quindi l'istogramma T1 nella maschera è troncato sotto quella soglia
% (tranne i buchi riempiti) e T2/PD sono selezionati indirettamente da T1.
% Nessun GT, nessuna etichetta, nessuna soglia, nessuna attribuzione di
% tessuti ai picchi, nessun dato held-out.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io);

edges = -0.5:1:4095.5;
values = 0:4095;
cases = {
    "pn0", "T1"
    "pn0", "T2"
    "pn0", "PD"
    "pn3", "T1"
    "pn3", "T2"
    };
nCases = size(cases, 1);

maskFile = @(noise) fullfile(cfg.paths.processedData, ...
    sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));

masks = struct();
for noise = ["pn0" "pn3"]
    saved = load(maskFile(noise), 'candidate', 'radius');
    assert(islogical(saved.candidate) && saved.radius == 3, 'Unexpected EXP-021 mask for %s.', noise);
    masks.(noise) = saved.candidate;
end

brainCounts = zeros(numel(values), nCases);
globalCounts = zeros(numel(values), nCases);
rows = cell(nCases, 1);
checks = cell(0, 2);

for c = 1:nCases
    noise = cases{c, 1};
    modality = cases{c, 2};
    volume = loadBrainwebMri(cfg, modality, noise);
    volumeCopy = volume;
    mask = masks.(noise);
    label = noise + " " + modality;

    checks(end+1, :) = {label + " volume size = mask size", isequal(size(volume), size(mask))}; %#ok<SAGROW>
    if ~checks{end, 2}
        error('phase40:sizeMismatch', 'Volume and mask sizes differ for %s.', label);
    end

    brainValues = double(volume(mask));             % popolazione cerebrale (nessuno zero artificiale)
    brainCounts(:, c) = histcounts(brainValues, edges).';
    globalCounts(:, c) = histcounts(double(volume(:)), edges).';
    [~, modeIndex] = max(brainCounts(:, c));

    checks(end+1, :) = {label + " histogram total = nnz(mask)", sum(brainCounts(:, c)) == nnz(mask)}; %#ok<SAGROW>
    checks(end+1, :) = {label + " histogram mean = mean(brainValues)", ...
        abs(sum(values(:) .* brainCounts(:, c)) / nnz(mask) - mean(brainValues)) < 1e-9}; %#ok<SAGROW>
    checks(end+1, :) = {label + " global total = all voxels", sum(globalCounts(:, c)) == numel(volume)}; %#ok<SAGROW>
    checks(end+1, :) = {label + " volume unchanged", isequal(volume, volumeCopy)}; %#ok<SAGROW>

    rows{c} = {noise, modality, nnz(mask), min(brainValues), max(brainValues), mean(brainValues), ...
        median(brainValues), std(brainValues), values(modeIndex), nnz(brainValues == 0), ...
        mean(double(volume(:))), median(double(volume(:)))};
end

if any(~[checks{:, 2}])
    error('phase40:checksFailed', 'Phase 40 technical checks failed.');
end


%% Tabella riassuntiva (descrittiva)

summary = cell2table(vertcat(rows{:}), 'VariableNames', {'Condition', 'Modality', 'BrainVoxels', ...
    'BrainMin', 'BrainMax', 'BrainMean', 'BrainMedian', 'BrainStd', 'BrainMode', 'BrainZeroVoxels', ...
    'GlobalMean', 'GlobalMedian'});
disp(summary);
writetable(summary, fullfile(cfg.paths.metrics, 'phase40_brain_only_histogram_summary.csv'));

countsTable = array2table([values(:), brainCounts], 'VariableNames', ...
    ['RawValue', cellstr(strrep(strcat([cases{:, 1}], "_", [cases{:, 2}]), " ", ""))]);
writetable(countsTable, fullfile(cfg.paths.metrics, 'phase40_brain_only_histogram_counts.csv'));


%% Figure: per modalità, istogramma nel cervello (lineare e log) e confronto con la fase 39

for c = 1:nCases
    noise = cases{c, 1};
    modality = cases{c, 2};
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact');
    title(layout, sprintf(['Phase 40 - %s %s: brain-only histogram (raw values inside EXP-021 mask, one bin per ' ...
        'raw value; no GT, no thresholds)'], modality, noise), 'Interpreter', 'none');

    ax = nexttile(layout);
    bar(ax, values, brainCounts(:, c), 1, 'EdgeColor', 'none');
    xlim(ax, [-20 4115]);
    ylabel(ax, 'count (linear)');
    title(ax, 'brain-only, linear y');

    ax = nexttile(layout);
    semilogy(ax, values, max(brainCounts(:, c), 0.5), '-');
    xlim(ax, [-20 4115]);
    ylabel(ax, 'count (log, display only)');
    title(ax, 'brain-only, log y');

    ax = nexttile(layout);
    globalFraction = globalCounts(:, c) / sum(globalCounts(:, c));
    brainFraction = brainCounts(:, c) / sum(brainCounts(:, c));
    semilogy(ax, values, max(globalFraction, 1e-8), '-', values, max(brainFraction, 1e-8), '-');
    xlim(ax, [-20 4115]);
    ylabel(ax, 'fraction (log)');
    xlabel(ax, 'raw value');
    legend(ax, 'global (Phase 39, all voxels)', 'brain-only (Phase 40)', 'Location', 'best');
    title(ax, 'shape comparison (each normalized to its own total)');

    fig.Position(3:4) = [1000 900];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('phase40_%s_%s_brain_only_histogram.png', ...
        lower(modality), noise)));
end


%% Esito dei controlli

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-44s %s\n', checks{c, 1}, result);
end
fprintf('\nPHASE 40 CHECKS: PASS\n');
