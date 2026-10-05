%% Baseline di preprocessing senza filtro (fase 42)
% Definisce il riferimento "nessun preprocessing" per la modalità iniziale
% (cfg.dataset.modality, T2 dalla fase 41) della configurazione di
% sviluppo msles2, 1 mm, pn0, rf0:
%
%   input:          volume restituito dal loader validato
%   trasformazione: identità (nessun filtro, nessuna conversione,
%                   nessuna normalizzazione)
%   output:         stessi valori, stesso tipo, stesse dimensioni
%
% Questo riferimento serve a confrontare i filtri delle fasi 45-47. Non
% viene salvata nessuna copia del volume: il riferimento si ricostruisce
% da file raw + loader + regola di identità. Nessun ground truth.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.visualization);

modality = cfg.dataset.modality;
assert(strlength(modality) > 0, 'No modality set in cfg.dataset.modality.');

inputVolume = loadBrainwebMri(cfg, modality);

% Fase 42: nessun preprocessing
baselineVolume = inputVolume;


%% Controlli

reloadedVolume = loadBrainwebMri(cfg, modality);    % seconda lettura indipendente

checks = {
    'identical values (isequal)',  isequal(baselineVolume, inputVolume)
    'same class',                  strcmp(class(baselineVolume), class(inputVolume))
    'same size',                   isequal(size(baselineVolume), size(inputVolume))
    'size as configured',          isequal(size(baselineVolume), cfg.dataset.volumeSize)
    'class as configured',         strcmp(class(baselineVolume), cfg.dataset.mriFormat.precision)
    'no NaN/Inf',                  ~any(isnan(baselineVolume(:)) | isinf(baselineVolume(:)))
    'equal to a fresh reload',     isequal(baselineVolume, reloadedVolume)
};

fprintf('\n%s  -  %s 1mm %s %s\n', modality, cfg.dataset.case, ...
    cfg.dataset.noiseLevel, cfg.dataset.rfInhomogeneity);
fprintf('size=[%s]  class=%s  min=%d  max=%d\n\n', ...
    num2str(size(baselineVolume)), class(baselineVolume), ...
    min(baselineVolume(:)), max(baselineVolume(:)));

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-28s %s\n', checks{c, 1}, result);
end


%% Figura di riferimento (slice assiale centrale, scelta senza GT)

k = ceil(size(baselineVolume, 3) / 2);
titleText = sprintf('Unfiltered preprocessing baseline  -  %s %s 1mm %s %s  -  k = %d', ...
    modality, cfg.dataset.case, cfg.dataset.noiseLevel, cfg.dataset.rfInhomogeneity, k);
fig = showAxialSlice(baselineVolume, k, titleText);
figureFile = fullfile(cfg.paths.figures, ...
    sprintf('phase42_%s_unfiltered_baseline_k%03d.png', lower(modality), k));
exportgraphics(fig, figureFile);

if all([checks{:, 2}])
    fprintf('\nPHASE 42 CHECKS: PASS\n');
else
    fprintf('\nPHASE 42 CHECKS: FAIL\n');
end
fprintf('Figure saved: %s\n', figureFile);
