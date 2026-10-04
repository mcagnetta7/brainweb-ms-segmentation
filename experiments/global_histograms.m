%% Istogrammi globali delle intensità MRI (fase 39)
% Per T1, T2 e PD della configurazione di sviluppo iniziale (msles2,
% 1 mm, pn0, rf0) calcola l'istogramma dell'intero volume 3D, sfondo
% compreso, e descrive la distribuzione globale: voxel a zero, valore più
% frequente (moda) e mediana. Salva una figura per modalità, con scala
% lineare e logaritmica.
%
% Stesso binning della fase 38: un bin per ogni valore intero grezzo
% 0...4095 (bordi -0.5:1:4095.5), uguale per tutte le modalità.
%
% Analisi solo descrittiva: nessun ground truth, nessuna maschera,
% nessuna soglia, nessuna scelta di modalità. I volumi non vengono
% modificati.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io);

modalities = ["T1" "T2" "PD"];
histogramEdges = -0.5:1:4095.5;             % come nella fase 38
binCenters = histogramEdges(1:end-1) + 0.5;

nModalities = numel(modalities);
totalVoxels = zeros(nModalities, 1);
zeroVoxels = zeros(nModalities, 1);
zeroPercent = zeros(nModalities, 1);
modeValue = zeros(nModalities, 1);
modeVoxels = zeros(nModalities, 1);
modePercent = zeros(nModalities, 1);
medianValue = zeros(nModalities, 1);
volumeSizes = zeros(nModalities, 3);
unchanged = false(nModalities, 1);
histogramsOk = false(nModalities, 1);
figureFiles = strings(nModalities, 1);


for m = 1:nModalities
    volume = loadBrainwebMri(cfg, modalities(m));
    volumeCopy = volume;
    volumeSizes(m, :) = size(volume);

    counts = histcounts(double(volume(:)), histogramEdges);

    totalVoxels(m) = numel(volume);
    zeroVoxels(m) = nnz(volume == 0);
    zeroPercent(m) = 100 * zeroVoxels(m) / totalVoxels(m);
    [modeVoxels(m), modeIndex] = max(counts);
    modeValue(m) = binCenters(modeIndex);
    modePercent(m) = 100 * modeVoxels(m) / totalVoxels(m);
    medianValue(m) = median(double(volume(:)));

    histogramsOk(m) = sum(counts) == totalVoxels(m) && counts(1) == zeroVoxels(m);

    % Figura: stesso istogramma in scala lineare e logaritmica
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact');
    title(layout, sprintf('%s  -  global (complete-volume) histogram  -  %s 1mm %s %s', ...
        modalities(m), cfg.dataset.case, cfg.dataset.noiseLevel, ...
        cfg.dataset.rfInhomogeneity), 'Interpreter', 'none');

    axLinear = nexttile(layout);
    stairs(axLinear, binCenters, counts);
    xlim(axLinear, [histogramEdges(1) histogramEdges(end)]);
    ylabel(axLinear, 'voxel count');
    title(axLinear, 'linear y axis');

    axLog = nexttile(layout);
    stairs(axLog, binCenters, counts);
    set(axLog, 'YScale', 'log');
    xlim(axLog, [histogramEdges(1) histogramEdges(end)]);
    ylabel(axLog, 'voxel count (log)');
    xlabel(axLog, 'raw MRI intensity (1 bin per value, all voxels)');
    title(axLog, 'logarithmic y axis (display only, same counts)');

    fig.Position(3:4) = [800 600];
    figureFiles(m) = fullfile(cfg.paths.figures, ...
        sprintf('phase39_%s_global_histogram.png', lower(modalities(m))));
    exportgraphics(fig, figureFiles(m));

    unchanged(m) = isequal(volume, volumeCopy);
end


%% Riepilogo

summary = table(modalities', totalVoxels, zeroVoxels, zeroPercent, ...
    modeValue, modeVoxels, modePercent, medianValue, ...
    'VariableNames', {'Modality', 'TotalVoxels', 'ZeroVoxels', 'ZeroPercent', ...
                      'ModeValue', 'ModeVoxels', 'ModePercent', 'Median'});
disp(summary);

summaryFile = fullfile(cfg.paths.metrics, 'phase39_global_histogram_summary.csv');
writetable(summary, summaryFile);


%% Controlli

checks = {
    'same size for all',         all(volumeSizes == cfg.dataset.volumeSize, 'all')
    'histograms use all voxels', all(histogramsOk)
    'figures saved',             all(arrayfun(@isfile, figureFiles))
    'volumes unchanged',         all(unchanged)
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
    fprintf('\nPHASE 39 CHECKS: PASS\n');
else
    fprintf('\nPHASE 39 CHECKS: FAIL\n');
end
fprintf('Summary saved: %s\n', summaryFile);
