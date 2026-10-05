%% Smoothing gaussiano: confronto filtrato / non filtrato (fase 45)
% Modalità iniziale T2, msles2, 1 mm, rf0. Condizioni di sviluppo:
%   pn0  riferimento senza rumore (non filtrato)
%   pn3  condizione rumorosa, non filtrata e filtrata
% Stessa preparazione per tutti: loader -> conversione double (fase 43)
% -> normalizzazione fissa /4095 (fase 44). L'unica differenza tra i due
% rami pn3 è il filtro gaussiano 2D slice per slice.
%
% Parametri ESPLORATIVI della fase 45 (non scelti dai dati, non finali):
%   sigma = 0.5 pixel (valore predefinito di imgaussfilt)
%   filterSize = 2*ceil(2*sigma)+1 = 3 (dimensione automatica di MATLAB)
%   padding = "replicate" (valore predefinito di imgaussfilt)
%
% Nessun ground truth, nessun dato di test, nessuna soglia. Se un
% controllo fallisce lo script si interrompe con un errore.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing);

modality = cfg.dataset.modality;
sigma = 0.5;                                % riferimento esplorativo della fase 45
filterSize = 2 * ceil(2 * sigma) + 1;
padding = "replicate";

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);


%% Caricamento e verifica di pn3

rawPn0 = loadBrainwebMri(cfg, modality);
rawPn3 = loadBrainwebMri(cfg, modality, "pn3");

pn3Checks = {
    'pn3 size as configured',   isequal(size(rawPn3), cfg.dataset.volumeSize)
    'pn3 same size as pn0',     isequal(size(rawPn3), size(rawPn0))
    'pn3 class uint16',         isa(rawPn3, 'uint16')
    'pn3 values in 0...4095',   max(rawPn3(:)) <= 4095
};


%% Preparazione identica e filtro

pn0 = prepare(rawPn0);
pn3 = prepare(rawPn3);
pn3Copy = pn3;

pn3Gaussian = gaussianFilterSlices(pn3, sigma, filterSize, padding);
pn0Gaussian = gaussianFilterSlices(pn0, sigma, filterSize, padding);    % solo diagnostica


%% Confronto quantitativo (riferimento: pn0 normalizzato, non filtrato)

mse = @(a, b) mean((a - b).^2, 'all');

mseUnfiltered = mse(pn3, pn0);
mseGaussian = mse(pn3Gaussian, pn0);
relativeChange = 100 * (mseGaussian - mseUnfiltered) / mseUnfiltered;
cleanDistortion = mse(pn0Gaussian, pn0);

% Diagnostica della scala: BrainWeb scala ogni volume raw a 0...4095,
% quindi pn3 e pn0 possono differire anche per guadagno e offset.
meanDifference = mean(pn3 - pn0, 'all');
fit = polyfit(pn0(:), pn3(:), 1);           % pn3 ~ fit(1)*pn0 + fit(2)
scaledReference = fit(1) * pn0 + fit(2);
mseUnfilteredScaled = mse(pn3, scaledReference);
mseGaussianScaled = mse(pn3Gaussian, scaledReference);
relativeChangeScaled = 100 * (mseGaussianScaled - mseUnfilteredScaled) / mseUnfilteredScaled;


%% Verifica del filtraggio slice per slice

% Se il filtro fosse 3D, modificare una slice cambierebbe anche le vicine
probe = pn3;
probe(:, :, 50) = 0;
probeFiltered = gaussianFilterSlices(probe, sigma, filterSize, padding);
otherSlices = setdiff(1:size(pn3, 3), 50);
sliceIndependent = isequal(probeFiltered(:, :, otherSlices), pn3Gaussian(:, :, otherSlices));


%% Controlli

checks = [pn3Checks; {
    'inputs double in [0,1]',        isa(pn0, 'double') && isa(pn3, 'double') ...
                                     && min([pn0(:); pn3(:)]) >= 0 && max([pn0(:); pn3(:)]) <= 1
    'output size unchanged',         isequal(size(pn3Gaussian), size(pn3))
    'output class double',           isa(pn3Gaussian, 'double')
    'output finite',                 all(isfinite(pn3Gaussian(:)))
    'filter is 2D slice by slice',   sliceIndependent
    'normalized pn3 unchanged',      isequal(pn3, pn3Copy)
    'raw pn3 unchanged on reload',   isequal(rawPn3, loadBrainwebMri(cfg, modality, "pn3"))
}];

fprintf('\n%s %s 1mm %s: pn0 (reference) vs pn3\n', modality, cfg.dataset.case, ...
    cfg.dataset.rfInhomogeneity);
fprintf('Gaussian: sigma=%g, filterSize=%dx%d, padding=%s (exploratory)\n\n', ...
    sigma, filterSize, filterSize, padding);
fprintf('MSE pn3 unfiltered vs pn0:   %.6g\n', mseUnfiltered);
fprintf('MSE pn3 Gaussian   vs pn0:   %.6g\n', mseGaussian);
fprintf('Relative MSE change:         %+.2f %%\n', relativeChange);
fprintf('Clean-reference distortion:  %.6g  (MSE pn0 Gaussian vs pn0)\n\n', cleanDistortion);
fprintf('Scale diagnostic: mean(pn3 - pn0) = %.4f, fit pn3 = %.4f*pn0 + %.4f\n', ...
    meanDifference, fit(1), fit(2));
fprintf('Scale-matched MSE unfiltered: %.6g\n', mseUnfilteredScaled);
fprintf('Scale-matched MSE Gaussian:   %.6g\n', mseGaussianScaled);
fprintf('Scale-matched relative change: %+.2f %%\n\n', relativeChangeScaled);

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-30s %s\n', checks{c, 1}, result);
end
if ~all([checks{:, 2}])
    error('phase45:validationFailed', 'PHASE 45 CHECKS: FAIL');
end


%% Risultati salvati

metrics = table(string(modality), "pn3", sigma, filterSize, string(padding), ...
    mseUnfiltered, mseGaussian, relativeChange, cleanDistortion, ...
    fit(1), fit(2), mseUnfilteredScaled, mseGaussianScaled, relativeChangeScaled, ...
    'VariableNames', {'Modality', 'Noise', 'Sigma', 'FilterSize', 'Padding', ...
    'MSE_unfiltered', 'MSE_gaussian', 'RelChangePercent', 'CleanDistortion', ...
    'ScaleSlope', 'ScaleOffset', 'MSE_unfiltered_scaled', 'MSE_gaussian_scaled', ...
    'RelChangeScaledPercent'});
metricsFile = fullfile(cfg.paths.metrics, 'phase45_gaussian_pn3_sigma0p5.csv');
writetable(metrics, metricsFile);

k = ceil(size(pn3, 3) / 2);                 % slice centrale, scelta senza GT
panels = {pn0(:, :, k), pn3(:, :, k), pn3Gaussian(:, :, k), ...
          abs(pn3Gaussian(:, :, k) - pn3(:, :, k))};
titles = ["pn0 reference (unfiltered)", "pn3 unfiltered", ...
          sprintf("pn3 Gaussian (sigma %g, %dx%d)", sigma, filterSize, filterSize), ...
          "|pn3 Gaussian - pn3| (where the filter changed the image)"];

fig = figure('Color', 'w');
layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact');
title(layout, sprintf('Phase 45 exploratory Gaussian smoothing  -  %s %s 1mm %s  -  k = %d', ...
    modality, cfg.dataset.case, cfg.dataset.rfInhomogeneity, k), 'Interpreter', 'none');
for p = 1:4
    ax = nexttile(layout);
    imagesc(ax, panels{p}.');
    colormap(ax, gray);
    if p <= 3
        clim(ax, [0 1]);                    % stessa scala per i tre pannelli
    end
    axis(ax, 'image');
    set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
    title(ax, titles(p));
end
fig.Position(3:4) = [900 900];
figureFile = fullfile(cfg.paths.figures, sprintf('phase45_gaussian_pn0_pn3_k%03d.png', k));
exportgraphics(fig, figureFile);

fprintf('\nPHASE 45 CHECKS: PASS\n');
fprintf('Metrics: %s\nFigure:  %s\n', metricsFile, figureFile);
