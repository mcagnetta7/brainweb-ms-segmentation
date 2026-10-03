%% Prima visualizzazione di una slice MRI (fase 31)
% Carica un volume con il loader di src/io e ne mostra una slice assiale
% centrale, per verificare che l'anatomia sia riconoscibile e
% l'orientamento coerente con la convenzione della fase 27.
%
% La modalità T1 è usata solo per questo test di visualizzazione: non è
% la scelta della modalità baseline. Il ground truth non viene usato.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.visualization);

modality = "T1";
volume = loadBrainwebMri(cfg, modality);
assert(isequal(size(volume), cfg.dataset.volumeSize), ...
    'Unexpected volume size.');

% Slice assiale centrale, scelta solo per la verifica visiva
k = ceil(size(volume, 3) / 2);

titleText = sprintf('%s  -  %s %s %s  -  axial slice k = %d', ...
    modality, cfg.dataset.case, cfg.dataset.noiseLevel, ...
    cfg.dataset.rfInhomogeneity, k);
fig = showAxialSlice(volume, k, titleText);

outputFile = fullfile(cfg.paths.figures, ...
    sprintf('phase31_%s_axial_k%03d.png', lower(modality), k));
exportgraphics(fig, outputFile);
fprintf('Figure saved: %s\n', outputFile);
