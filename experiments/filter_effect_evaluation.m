%% Valutazione dell'effetto del filtro (fase 47, EXP-004)
% Confronto attivo: NON FILTRATO contro GAUSSIANO sigma 0.5, 3x3,
% "replicate" (unico candidato rimasto dopo EXP-001...EXP-003).
% Nessuno sweep: i parametri sono quelli dichiarati nella fase 45.
%
% Dati di sviluppo: T2, msles2, 1 mm, rf0, pn0 e pn3. Preparazione
% identica: loader -> double (fase 43) -> /4095 (fase 44).
%
% Ordine obbligato:
%   Parte A (solo MRI): filtro, MSE, diagnostica di scala, distorsione su
%           pn0, energia del dettaglio, figura della slice centrale.
%   Parte B (dopo): caricamento del ground truth SOLO per la figura con i
%           contorni delle lesioni. Il GT non influenza nessun parametro.
%
% Energia del dettaglio (solo pn0, solo direzioni X e Y dentro ogni
% slice, nessuna differenza lungo Z):
%   E = sum( diff(V,1,1).^2 ) + sum( diff(V,1,2).^2 )
%   retention = 100 * E_gaussian / E_unfiltered
%
% Nessuna soglia, maschera cerebrale, morfologia o metrica di
% segmentazione. Se un controllo fallisce lo script si interrompe.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing);

modality = cfg.dataset.modality;
sigma = 0.5;                                % parametri della fase 45, non tarati
filterSize = 3;
padding = "replicate";

% Valori di EXP-001 da riprodurre
expectedExp001 = [0.00265251 0.00288098 0.000597665 0.000426673];

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);


%% PARTE A - solo MRI

rawPn0 = loadBrainwebMri(cfg, modality);
rawPn3 = loadBrainwebMri(cfg, modality, "pn3");
pn0 = prepare(rawPn0);
pn3 = prepare(rawPn3);
pn0Copy = pn0;
pn3Copy = pn3;

pn0Gaussian = gaussianFilterSlices(pn0, sigma, filterSize, padding);
pn3Gaussian = gaussianFilterSlices(pn3, sigma, filterSize, padding);

mse = @(a, b) mean((a - b).^2, 'all');

% 1. Riproduzione di EXP-001
mseUnfiltered = mse(pn3, pn0);
mseGaussian = mse(pn3Gaussian, pn0);
fit = polyfit(pn0(:), pn3(:), 1);           % una sola volta, su pn3 non filtrato
scaledReference = fit(1) * pn0 + fit(2);
mseUnfilteredScaled = mse(pn3, scaledReference);
mseGaussianScaled = mse(pn3Gaussian, scaledReference);
relativeChangeScaled = 100 * (mseGaussianScaled - mseUnfilteredScaled) / mseUnfilteredScaled;
reproduced = [mseUnfiltered mseGaussian mseUnfilteredScaled mseGaussianScaled];

% 2. Distorsione dell'immagine pulita (misura separata)
cleanDistortion = mse(pn0Gaussian, pn0);

% 3. Energia del dettaglio 2D su pn0 (differenze solo lungo X e Y)
detailEnergy = @(v) sum(diff(v, 1, 1).^2, 'all') + sum(diff(v, 1, 2).^2, 'all');
energyUnfiltered = detailEnergy(pn0);
energyGaussian = detailEnergy(pn0Gaussian);
detailRetention = 100 * energyGaussian / energyUnfiltered;

% Controlli della parte A
checks = {
    'output size unchanged',         isequal(size(pn3Gaussian), size(pn3)) && isequal(size(pn0Gaussian), size(pn0))
    'output class double',           isa(pn3Gaussian, 'double') && isa(pn0Gaussian, 'double')
    'output finite',                 all(isfinite(pn3Gaussian(:))) && all(isfinite(pn0Gaussian(:)))
    'normalized volumes unchanged',  isequal(pn0, pn0Copy) && isequal(pn3, pn3Copy)
    'raw pn3 unchanged on reload',   isequal(rawPn3, loadBrainwebMri(cfg, modality, "pn3"))
    'EXP-001 reproduced',            all(abs(reproduced - expectedExp001) ./ expectedExp001 < 1e-4)
};


%% Figura 1 - slice centrale k = 91 (scelta senza GT)

k = ceil(size(pn0, 3) / 2);
rows = {pn0, pn0Gaussian, "pn0"; pn3, pn3Gaussian, "pn3"};

fig1 = figure('Color', 'w');
layout = tiledlayout(fig1, 2, 3, 'TileSpacing', 'compact');
title(layout, sprintf('Phase 47 - %s %s 1mm %s - k = %d - Gaussian sigma %g, %dx%d, %s', ...
    modality, cfg.dataset.case, cfg.dataset.rfInhomogeneity, k, sigma, ...
    filterSize, filterSize, padding), 'Interpreter', 'none');
for r = 1:2
    unfilteredSlice = rows{r, 1}(:, :, k);
    filteredSlice = rows{r, 2}(:, :, k);
    panels = {unfilteredSlice, filteredSlice, abs(filteredSlice - unfilteredSlice)};
    titles = [rows{r, 3} + " unfiltered", rows{r, 3} + " Gaussian", ...
              "|" + rows{r, 3} + " Gaussian - unfiltered|"];
    for p = 1:3
        ax = nexttile(layout);
        imagesc(ax, panels{p}.');
        colormap(ax, gray);
        if p <= 2
            clim(ax, [0 1]);                % stessa scala per le immagini
        else
            colorbar(ax);                   % scala propria, mostrata
        end
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, titles(p));
    end
end
fig1.Position(3:4) = [1200 800];
figure1File = fullfile(cfg.paths.figures, sprintf('phase47_unfiltered_vs_gaussian_k%03d.png', k));
exportgraphics(fig1, figure1File);


%% PARTE B - ground truth solo come riferimento visivo (dopo la parte A)

labels = loadBrainwebGroundTruth(cfg);
lesionMask = labels == 10;                  % solo per disegnare i contorni

% Slice scelte dal GT solo per la figura, con la stessa regola delle
% fasi 35 e 41: quella con più lesioni e la mediana tra quelle con lesioni.
lesionPerSlice = squeeze(sum(lesionMask, [1 2]));
[~, mainSlice] = max(lesionPerSlice);
lesionSlices = find(lesionPerSlice > 0);
checkSlice = lesionSlices(ceil(numel(lesionSlices) / 2));
diagnosticSlices = [mainSlice checkSlice];

volumes = {pn0, pn0Gaussian, pn3, pn3Gaussian};
volumeNames = ["pn0 unfiltered", "pn0 Gaussian", "pn3 unfiltered", "pn3 Gaussian"];

fig2 = figure('Color', 'w');
layout = tiledlayout(fig2, numel(diagnosticSlices), numel(volumes), 'TileSpacing', 'compact');
title(layout, 'Phase 47 diagnostic only - GT lesion contour (label 10) on full slices', ...
    'Interpreter', 'none');
for s = 1:numel(diagnosticSlices)
    ks = diagnosticSlices(s);
    for v = 1:numel(volumes)
        ax = nexttile(layout);
        imagesc(ax, volumes{v}(:, :, ks).');
        colormap(ax, gray);
        clim(ax, [0 1]);
        hold(ax, 'on');
        contour(ax, double(lesionMask(:, :, ks).'), [0.5 0.5], 'r', 'LineWidth', 0.5);
        hold(ax, 'off');
        axis(ax, 'image');
        set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('%s  k = %d', volumeNames(v), ks));
    end
end
fig2.Position(3:4) = [1400 750];
figure2File = fullfile(cfg.paths.figures, 'phase47_gt_contour_unfiltered_vs_gaussian.png');
exportgraphics(fig2, figure2File);


%% Risultati

fprintf('\n%s %s 1mm %s: unfiltered vs Gaussian (sigma=%g, %dx%d, %s)\n\n', ...
    modality, cfg.dataset.case, cfg.dataset.rfInhomogeneity, sigma, filterSize, filterSize, padding);
fprintf('Raw MSE pn3 unfiltered vs pn0:   %.6g\n', mseUnfiltered);
fprintf('Raw MSE pn3 Gaussian   vs pn0:   %.6g\n', mseGaussian);
fprintf('Affine diagnostic: pn3 = %.4f*pn0 + %.4f\n', fit(1), fit(2));
fprintf('Scale-matched MSE unfiltered:    %.6g\n', mseUnfilteredScaled);
fprintf('Scale-matched MSE Gaussian:      %.6g\n', mseGaussianScaled);
fprintf('Scale-matched relative change:   %+.2f %%\n', relativeChangeScaled);
fprintf('Clean-reference distortion:      %.6g\n', cleanDistortion);
fprintf('Detail energy pn0 unfiltered:    %.6g\n', energyUnfiltered);
fprintf('Detail energy pn0 Gaussian:      %.6g\n', energyGaussian);
fprintf('Detail retention:                %.2f %%\n', detailRetention);
fprintf('GT diagnostic slices (figure only): %d (%d lesion px), %d (%d lesion px)\n\n', ...
    mainSlice, lesionPerSlice(mainSlice), checkSlice, lesionPerSlice(checkSlice));

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-30s %s\n', checks{c, 1}, result);
end
if ~all([checks{:, 2}])
    error('exp004:validationFailed', 'PHASE 47 CHECKS: FAIL');
end

metrics = table(string(modality), "pn0+pn3", sigma, filterSize, string(padding), ...
    mseUnfiltered, mseGaussian, fit(1), fit(2), mseUnfilteredScaled, mseGaussianScaled, ...
    relativeChangeScaled, cleanDistortion, energyUnfiltered, energyGaussian, detailRetention, ...
    'VariableNames', {'Modality', 'Noise', 'Sigma', 'FilterSize', 'Padding', ...
    'MSE_unfiltered', 'MSE_gaussian', 'ScaleSlope', 'ScaleOffset', ...
    'MSE_unfiltered_scaled', 'MSE_gaussian_scaled', 'RelChangeScaledPercent', ...
    'CleanDistortion', 'DetailEnergyUnfiltered', 'DetailEnergyGaussian', 'DetailRetentionPercent'});
metricsFile = fullfile(cfg.paths.metrics, 'phase47_filter_effect_evaluation.csv');
writetable(metrics, metricsFile);

fprintf('\nPHASE 47 CHECKS: PASS\n');
fprintf('Metrics: %s\nFigures: %s\n         %s\n', metricsFile, figure1File, figure2File);
