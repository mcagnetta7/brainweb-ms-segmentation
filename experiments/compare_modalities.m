%% Confronto T1 / T2 / PD per la modalità iniziale (fase 41)
% Confronta le tre modalità della configurazione di sviluppo (msles2,
% 1 mm, pn0, rf0) sui valori grezzi: statistiche per classe, separabilità
% lesione-sostanza bianca, distribuzioni e slice affiancate.
%
% Il ground truth crisp è usato SOLO come riferimento analitico offline,
% per estrarre statistiche aggregate per classe. Queste statistiche non
% devono diventare soglie, ROI o regole della segmentazione.
%
% Misure (per ogni modalità, valori grezzi):
%   differenza assoluta delle medie   |muL - muWM|   (unità grezze, non
%                                     confrontabile tra modalità)
%   separazione standardizzata        d = |muL - muWM| / sqrt((sL^2 + sWM^2) / 2)
%   coefficiente di sovrapposizione   OVL = sum(min(pL, pWM)) su bin comuni
% dove pL e pWM sono le frequenze normalizzate con bin di 32 valori grezzi
% (0...4095, 128 bin), uguali per tutte le modalità.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io);

modalities = ["T1" "T2" "PD"];
classLabels = [10 3 2 1];
classNames = ["Lesion" "WM" "GM" "CSF"];
lesionLabel = 10;
wmLabel = 3;
distributionEdges = -0.5:32:4095.5;         % 128 bin da 32 valori grezzi

labels = loadBrainwebGroundTruth(cfg);      % solo riferimento analitico
labelsCopy = labels;

nModalities = numel(modalities);
nClasses = numel(classLabels);
volumes = cell(nModalities, 1);
classMean = zeros(nModalities, nClasses);
classMedian = zeros(nModalities, nClasses);
classStd = zeros(nModalities, nClasses);
classCount = zeros(1, nClasses);
distributions = zeros(nModalities, nClasses, numel(distributionEdges) - 1);
unchanged = false(nModalities, 1);

for c = 1:nClasses
    classCount(c) = nnz(labels == classLabels(c));
end


%% Statistiche per classe

for m = 1:nModalities
    volume = loadBrainwebMri(cfg, modalities(m));
    volumeCopy = volume;
    assert(isequal(size(volume), size(labels)), 'MRI/GT size mismatch.');

    for c = 1:nClasses
        values = double(volume(labels == classLabels(c)));
        classMean(m, c) = mean(values);
        classMedian(m, c) = median(values);
        classStd(m, c) = std(values);
        counts = histcounts(values, distributionEdges);
        distributions(m, c, :) = counts / sum(counts);
    end

    unchanged(m) = isequal(volume, volumeCopy);
    volumes{m} = volume;
end


%% Separabilità rispetto alla lesione

iL = find(classLabels == lesionLabel);
separation = @(m, c) abs(classMean(m, iL) - classMean(m, c)) ...
    / sqrt((classStd(m, iL)^2 + classStd(m, c)^2) / 2);
overlap = @(m, c) sum(min(squeeze(distributions(m, iL, :)), ...
                          squeeze(distributions(m, c, :))));

rows = cell(nModalities * (nClasses - 1), 1);
r = 0;
for m = 1:nModalities
    for c = 1:nClasses
        if c == iL
            continue
        end
        r = r + 1;
        rows{r} = {modalities(m), classNames(c), ...
            classMean(m, iL), classMedian(m, iL), classStd(m, iL), ...
            classMean(m, c), classMedian(m, c), classStd(m, c), ...
            abs(classMean(m, iL) - classMean(m, c)), separation(m, c), overlap(m, c)};
    end
end
comparison = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'Modality', 'VersusClass', 'LesionMean', 'LesionMedian', 'LesionStd', ...
     'ClassMean', 'ClassMedian', 'ClassStd', 'AbsMeanDiff', 'StdSeparation', 'Overlap'});

fprintf('\nVoxels per class: Lesion %d, WM %d, GM %d, CSF %d\n', classCount);
disp(comparison);

tableFile = fullfile(cfg.paths.metrics, 'phase41_modality_comparison.csv');
writetable(comparison, tableFile);


%% Distribuzioni (analisi offline basata sul GT)

binCenters = distributionEdges(1:end-1) + 16;
classColors = [1 0 0; 0.2 0.2 0.2; 0.2 0.6 0.2; 0.2 0.4 0.9];

fig = figure('Color', 'w');
layout = tiledlayout(fig, nModalities, 1, 'TileSpacing', 'compact');
title(layout, 'OFFLINE GT-BASED ANALYSIS - class intensity distributions (msles2 1mm pn0 rf0)', ...
    'Interpreter', 'none');
for m = 1:nModalities
    ax = nexttile(layout);
    hold(ax, 'on');
    for c = 1:nClasses
        lineWidth = 1 + (c <= 2);           % lesione e WM in evidenza
        stairs(ax, binCenters, squeeze(distributions(m, c, :)), ...
            'Color', classColors(c, :), 'LineWidth', lineWidth, ...
            'DisplayName', classNames(c));
    end
    hold(ax, 'off');
    xlim(ax, [0 4095]);
    ylabel(ax, 'fraction of class');
    title(ax, modalities(m));
    if m == 1
        legend(ax, 'Location', 'northeast');
    end
end
xlabel(ax, 'raw MRI intensity (bins of 32 values)');
fig.Position(3:4) = [800 750];
distributionFile = fullfile(cfg.paths.figures, 'phase41_class_distributions_offline_gt.png');
exportgraphics(fig, distributionFile);


%% Slice affiancate, stessi indici per tutte le modalità

% Slice scelte dal GT solo per questa visualizzazione (come nella fase 35):
% quella con più voxel di lesione e la mediana tra quelle con lesioni.
lesionPerSlice = squeeze(sum(labels == lesionLabel, [1 2]));
[~, mainSlice] = max(lesionPerSlice);
lesionSlices = find(lesionPerSlice > 0);
checkSlice = lesionSlices(ceil(numel(lesionSlices) / 2));
slices = [mainSlice checkSlice];

fig = figure('Color', 'w');
layout = tiledlayout(fig, numel(slices), nModalities, 'TileSpacing', 'compact');
title(layout, 'Matched axial slices, raw values, display range per volume (display only)', ...
    'Interpreter', 'none');
for s = 1:numel(slices)
    for m = 1:nModalities
        ax = nexttile(layout);
        volume = volumes{m};
        imagesc(ax, volume(:, :, slices(s)).');
        colormap(ax, gray);
        clim(ax, double([min(volume(:)) max(volume(:))]));
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('%s  k = %d', modalities(m), slices(s)));
    end
end
fig.Position(3:4) = [1100 800];
slicesFile = fullfile(cfg.paths.figures, 'phase41_matched_slices.png');
exportgraphics(fig, slicesFile);


%% Controlli

checks = {
    'MRI volumes unchanged',   all(unchanged)
    'GT unchanged',            isequal(labels, labelsCopy)
    'lesion voxels 3512',      classCount(iL) == 3512
    'distributions sum to 1',  all(abs(sum(distributions, 3) - 1) < 1e-9, 'all')
};

fprintf('\nSlices used: %d and %d\n', slices);
for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-26s %s\n', checks{c, 1}, result);
end
if all([checks{:, 2}])
    fprintf('\nPHASE 41 CHECKS: PASS\n');
else
    fprintf('\nPHASE 41 CHECKS: FAIL\n');
end
fprintf('Table: %s\nFigures: %s\n         %s\n', tableFile, distributionFile, slicesFile);
