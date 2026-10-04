%% Statistiche di base delle intensità MRI (fase 38)
% Calcola minimo, massimo, media, deviazione standard e un istogramma di
% base per T1, T2 e PD della configurazione di sviluppo iniziale
% (msles2, 1 mm, pn0, rf0), sull'intero volume 3D, sfondo compreso.
%
% Analisi solo descrittiva: nessun ground truth, nessuna maschera,
% nessuna soglia, nessuna scelta di modalità. I valori originali non
% vengono modificati; la conversione a double serve solo al calcolo di
% media e deviazione standard.
%
% Istogramma: un bin per ogni valore intero grezzo 0...4095 (bordi
% -0.5:1:4095.5), uguale per tutte le modalità.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io);

modalities = ["T1" "T2" "PD"];
histogramEdges = -0.5:1:4095.5;             % un bin per valore grezzo

nModalities = numel(modalities);
minimum = zeros(nModalities, 1);
maximum = zeros(nModalities, 1);
meanValue = zeros(nModalities, 1);
standardDeviation = zeros(nModalities, 1);
voxelCount = zeros(nModalities, 1);
dataClass = strings(nModalities, 1);
histogramCounts = zeros(nModalities, numel(histogramEdges) - 1);
unchanged = false(nModalities, 1);


%% Statistiche per modalità

for m = 1:nModalities
    volume = loadBrainwebMri(cfg, modalities(m));
    volumeCopy = volume;

    values = double(volume(:));             % solo per il calcolo

    minimum(m) = min(values);
    maximum(m) = max(values);
    meanValue(m) = mean(values);
    standardDeviation(m) = std(values);     % normalizzazione N-1
    voxelCount(m) = numel(values);
    dataClass(m) = class(volume);
    histogramCounts(m, :) = histcounts(values, histogramEdges);

    unchanged(m) = isequal(volume, volumeCopy);
end


%% Tabella riassuntiva

summary = table(modalities', dataClass, voxelCount, minimum, maximum, ...
    meanValue, standardDeviation, ...
    'VariableNames', {'Modality', 'Class', 'Voxels', 'Min', 'Max', 'Mean', 'Std'});
disp(summary);

summaryFile = fullfile(cfg.paths.metrics, 'phase38_basic_intensity_statistics.csv');
writetable(summary, summaryFile);


%% Istogrammi di base (profilo descrittivo, non analisi globale della fase 39)

binCenters = histogramEdges(1:end-1) + 0.5;
fig = figure('Color', 'w');
layout = tiledlayout(fig, nModalities, 1, 'TileSpacing', 'compact');
title(layout, 'Basic descriptive intensity profile  -  msles2 1mm pn0 rf0  -  complete volume', ...
    'Interpreter', 'none');
for m = 1:nModalities
    ax = nexttile(layout);
    stairs(ax, binCenters, histogramCounts(m, :));
    set(ax, 'YScale', 'log');
    xlim(ax, [histogramEdges(1) histogramEdges(end)]);
    ylabel(ax, 'voxels (log)');
    title(ax, modalities(m));
end
xlabel(ax, 'raw intensity (1 bin per value)');
fig.Position(3:4) = [800 700];

figureFile = fullfile(cfg.paths.figures, 'phase38_basic_intensity_profile.png');
exportgraphics(fig, figureFile);


%% Controlli

checks = {
    'sizes as configured',      all(voxelCount == prod(cfg.dataset.volumeSize))
    'histograms use all voxels', all(sum(histogramCounts, 2) == voxelCount)
    'mean matches histogram',   all(abs(histogramCounts * binCenters' ./ voxelCount - meanValue) < 1e-6)
    'values within 0...4095',   all(minimum >= 0 & maximum <= 4095)
    'volumes unchanged',        all(unchanged)
};

fprintf('\n');
for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-28s %s\n', checks{c, 1}, result);
end

if all([checks{:, 2}])
    fprintf('\nPHASE 38 CHECKS: PASS\n');
else
    fprintf('\nPHASE 38 CHECKS: FAIL\n');
end
fprintf('Table saved:  %s\nFigure saved: %s\n', summaryFile, figureFile);
