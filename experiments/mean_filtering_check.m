%% Filtro di media: confronto filtrato / non filtrato (EXP-003)
% Esperimento supplementare prima della fase 47 (non è una fase della
% roadmap). Filtro di media (moving average), ammesso dal progetto
% (ALLOWED_TECHNIQUES.md, sezione 4.1), testato con lo stesso protocollo
% delle fasi 45-46.
%
% Modalità iniziale T2, msles2, 1 mm, rf0. Condizioni di sviluppo:
%   pn0  riferimento senza rumore (non filtrato)
%   pn3  condizione rumorosa, non filtrata e filtrata con media
% Stessa preparazione per tutti: loader -> double (fase 43) -> /4095
% (fase 44). L'unica differenza tra i due rami pn3 è il filtro di media
% 2D slice per slice.
%
% Parametri ESPLORATIVI (non scelti dai dati, non finali):
%   finestra 3x3 (pesi uguali 1/9), bordi "replicate" (come il gaussiano
%   della fase 45)
% Nota: a parità di finestra 3x3 la media smussa molto più del gaussiano
% con sigma 0.5, il cui peso centrale è molto maggiore. Lo script stampa
% i pesi centrali dei due kernel solo come documentazione.
%
% Diagnostica di scala come nelle fasi 45-46: retta pn3 ~ a*pn0 + b
% stimata UNA volta su pn3 NON filtrato e riusata per entrambi i rami.
% Solo diagnostica: non entra nella pipeline (domanda aperta 17).
%
% Regola di decisione dichiarata prima dei risultati:
%   candidato per la fase 47 = SI solo se l'MSE corretto per la scala
%   diminuisce (variazione relativa < 0) e la figura non mostra artefatti
%   evidenti; altrimenti NO.
%
% Nessun ground truth, nessun dato di test, nessuna soglia. Se un
% controllo fallisce lo script si interrompe con un errore.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing);

modality = cfg.dataset.modality;
windowSize = [3 3];                         % finestra esplorativa
padding = "replicate";

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);


%% Caricamento, preparazione identica e filtro

rawPn0 = loadBrainwebMri(cfg, modality);
rawPn3 = loadBrainwebMri(cfg, modality, "pn3");

pn0 = prepare(rawPn0);
pn3 = prepare(rawPn3);
pn3Copy = pn3;

pn3Mean = meanFilterSlices(pn3, windowSize, padding);
pn0Mean = meanFilterSlices(pn0, windowSize, padding);   % solo diagnostica


%% Confronto quantitativo

mse = @(a, b) mean((a - b).^2, 'all');

% MSE grezzo: influenzato dalla differenza di scala tra i volumi salvati
mseUnfiltered = mse(pn3, pn0);
mseMean = mse(pn3Mean, pn0);
relativeChange = 100 * (mseMean - mseUnfiltered) / mseUnfiltered;

% Diagnostica di scala: retta stimata solo su pn3 non filtrato
fit = polyfit(pn0(:), pn3(:), 1);
scaledReference = fit(1) * pn0 + fit(2);
mseUnfilteredScaled = mse(pn3, scaledReference);
mseMeanScaled = mse(pn3Mean, scaledReference);
relativeChangeScaled = 100 * (mseMeanScaled - mseUnfilteredScaled) / mseUnfilteredScaled;

cleanDistortion = mse(pn0Mean, pn0);

% Pesi centrali dei kernel 3x3 (solo documentazione dell'intensità dello smoothing)
meanKernel = fspecial('average', windowSize);
gaussianKernel = fspecial('gaussian', 3, 0.5);   % kernel esplorativo della fase 45


%% Verifica del filtraggio slice per slice

probe = pn3;
probe(:, :, 50) = 0;
probeFiltered = meanFilterSlices(probe, windowSize, padding);
otherSlices = setdiff(1:size(pn3, 3), 50);
sliceIndependent = isequal(probeFiltered(:, :, otherSlices), pn3Mean(:, :, otherSlices));


%% Controlli

checks = {
    'pn3 same size as pn0',          isequal(size(rawPn3), size(rawPn0))
    'inputs double in [0,1]',        isa(pn0, 'double') && isa(pn3, 'double') ...
                                     && min([pn0(:); pn3(:)]) >= 0 && max([pn0(:); pn3(:)]) <= 1
    'kernel weights sum to 1',       abs(sum(meanKernel(:)) - 1) < 1e-12
    'output size unchanged',         isequal(size(pn3Mean), size(pn3))
    'output class double',           isa(pn3Mean, 'double')
    'output finite',                 all(isfinite(pn3Mean(:)))
    'output within [0,1]',           min(pn3Mean(:)) >= -1e-12 && max(pn3Mean(:)) <= 1 + 1e-12
    'filter is 2D slice by slice',   sliceIndependent
    'normalized pn3 unchanged',      isequal(pn3, pn3Copy)
    'raw pn3 unchanged on reload',   isequal(rawPn3, loadBrainwebMri(cfg, modality, "pn3"))
};

fprintf('\n%s %s 1mm %s: pn0 (reference) vs pn3\n', modality, cfg.dataset.case, ...
    cfg.dataset.rfInhomogeneity);
fprintf('Mean filter: window=%dx%d, padding=%s (exploratory)\n', ...
    windowSize(1), windowSize(2), padding);
fprintf('Kernel centre weight: mean 3x3 = %.4f, Gaussian sigma 0.5 3x3 = %.4f (documentation only)\n\n', ...
    meanKernel(2, 2), gaussianKernel(2, 2));
fprintf('Raw MSE (affected by scale mismatch):\n');
fprintf('  pn3 unfiltered vs pn0:  %.6g\n', mseUnfiltered);
fprintf('  pn3 mean       vs pn0:  %.6g\n', mseMean);
fprintf('  relative change:        %+.2f %%\n\n', relativeChange);
fprintf('Affine diagnostic (from unfiltered pn3): pn3 = %.4f*pn0 + %.4f\n', fit(1), fit(2));
fprintf('Scale-matched MSE:\n');
fprintf('  unfiltered:             %.6g\n', mseUnfilteredScaled);
fprintf('  mean:                   %.6g\n', mseMeanScaled);
fprintf('  relative change:        %+.2f %%\n\n', relativeChangeScaled);
fprintf('Clean-reference distortion (MSE pn0 mean vs pn0): %.6g\n\n', cleanDistortion);

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-30s %s\n', checks{c, 1}, result);
end
if ~all([checks{:, 2}])
    error('exp003:validationFailed', 'EXP-003 CHECKS: FAIL');
end


%% Risultati salvati

metrics = table(string(modality), "pn3", sprintf("%dx%d", windowSize), string(padding), ...
    mseUnfiltered, mseMean, relativeChange, fit(1), fit(2), ...
    mseUnfilteredScaled, mseMeanScaled, relativeChangeScaled, cleanDistortion, ...
    'VariableNames', {'Modality', 'Noise', 'Window', 'Padding', ...
    'MSE_unfiltered', 'MSE_mean', 'RelChangePercent', 'ScaleSlope', 'ScaleOffset', ...
    'MSE_unfiltered_scaled', 'MSE_mean_scaled', 'RelChangeScaledPercent', 'CleanDistortion'});
metricsFile = fullfile(cfg.paths.metrics, 'exp003_mean_pn3_3x3.csv');
writetable(metrics, metricsFile);

k = ceil(size(pn3, 3) / 2);                 % slice centrale, scelta senza GT
panels = {pn0(:, :, k), pn3(:, :, k), pn3Mean(:, :, k), ...
          abs(pn3Mean(:, :, k) - pn3(:, :, k))};
titles = ["pn0 reference (unfiltered)", "pn3 unfiltered", ...
          sprintf("pn3 mean (%dx%d, %s)", windowSize(1), windowSize(2), padding), ...
          "|pn3 mean - pn3| (where the filter changed the image)"];

fig = figure('Color', 'w');
layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact');
title(layout, sprintf('EXP-003 exploratory mean filtering  -  %s %s 1mm %s  -  k = %d', ...
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
figureFile = fullfile(cfg.paths.figures, sprintf('exp003_mean_pn0_pn3_k%03d.png', k));
exportgraphics(fig, figureFile);

fprintf('\nEXP-003 CHECKS: PASS\n');
fprintf('Metrics: %s\nFigure:  %s\n', metricsFile, figureFile);
