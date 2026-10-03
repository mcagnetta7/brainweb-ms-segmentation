%% Visualizzazione ortogonale di un volume MRI (fase 32)
% Carica un volume con il loader di src/io e ne mostra le viste assiale,
% coronale e sagittale passanti per lo stesso voxel centrale.
%
% La modalità T1 è la stessa della fase 31 ed è usata solo per la
% verifica visiva: non è la scelta della modalità baseline. Il ground
% truth non viene usato.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.visualization);

modality = "T1";
volume = loadBrainwebMri(cfg, modality);
assert(isequal(size(volume), cfg.dataset.volumeSize), ...
    'Unexpected volume size.');

% Voxel centrale del volume, scelto solo per la verifica visiva
center = ceil(size(volume) / 2);

titleText = sprintf('%s  -  %s %s %s  -  orthogonal views at (i, j, k) = (%d, %d, %d)', ...
    modality, cfg.dataset.case, cfg.dataset.noiseLevel, ...
    cfg.dataset.rfInhomogeneity, center);
fig = showOrthogonalSlices(volume, center, titleText);
fig.Position(3:4) = [1200 480];

outputFile = fullfile(cfg.paths.figures, ...
    sprintf('phase32_%s_orthogonal_i%03d_j%03d_k%03d.png', lower(modality), center));
exportgraphics(fig, outputFile);
fprintf('Center (i0, j0, k0) = (%d, %d, %d)\n', center);
fprintf('Figure saved: %s\n', outputFile);
