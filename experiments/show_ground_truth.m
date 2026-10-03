%% Visualizzazione separata del ground truth (fase 34)
% Carica il modello discreto BrainWeb con il loader di src/io e ne mostra
% una slice assiale con le etichette originali, senza MRI e senza
% sovrapposizioni.
%
% La slice è scelta automaticamente come quella con più voxel di
% etichetta 10, solo per rendere interpretabile il ground truth. Questa
% scelta non deve essere usata nella segmentazione.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.visualization);

labels = loadBrainwebGroundTruth(cfg);
labelsCopy = labels;                        % riferimento per il confronto finale

% Etichette del modello discreto BrainWeb (anatomic_ms.html)
labelNames = ["Background", "CSF", "Grey Matter", "White Matter", "Fat", ...
    "Muscle/Skin", "Skin", "Skull", "Glial Matter", "Connective", "MS Lesion"];

% Colori a categorie; la lesione (10) è in rosso acceso per evidenziarla,
% solo nella visualizzazione
labelColors = [
    0.00 0.00 0.00      % 0  Background
    0.25 0.45 0.85      % 1  CSF
    0.55 0.55 0.55      % 2  Grey Matter
    0.88 0.88 0.82      % 3  White Matter
    0.95 0.85 0.35      % 4  Fat
    0.60 0.40 0.30      % 5  Muscle/Skin
    0.95 0.70 0.65      % 6  Skin
    0.75 0.75 0.95      % 7  Skull
    0.60 0.35 0.75      % 8  Glial Matter
    0.45 0.60 0.35      % 9  Connective
    1.00 0.00 0.00      % 10 MS Lesion
];

% Slice assiale con più voxel di etichetta 10
lesionLabel = 10;
lesionPerSlice = squeeze(sum(labels == lesionLabel, [1 2]));
[~, k] = max(lesionPerSlice);

titleText = sprintf('Ground truth (crisp %s)  -  axial slice k = %d / %d', ...
    cfg.dataset.case, k, size(labels, 3));
fig = showLabelSlice(labels, k, labelNames, labelColors, titleText);
fig.Position(3:4) = [700 560];

outputFile = fullfile(cfg.paths.figures, sprintf('phase34_gt_axial_k%03d.png', k));
exportgraphics(fig, outputFile);


%% Controlli

checks = {
    'size [181 217 181]',   isequal(size(labels), cfg.dataset.volumeSize)
    'class uint8',          isa(labels, 'uint8')
    'labels 0...10',        isequal(double(unique(labels(:)))', 0:10)
    'label 10 count 3512',  nnz(labels == lesionLabel) == 3512
    'slice has label 10',   lesionPerSlice(k) > 0
    'GT unchanged',         isequal(labels, labelsCopy)
};

fprintf('\nAxial slice k = %d (label-10 voxels in slice: %d)\n', k, lesionPerSlice(k));
for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-24s %s\n', checks{c, 1}, result);
end

if all([checks{:, 2}])
    fprintf('\nGT VISUALIZATION CHECKS: PASS\n');
else
    fprintf('\nGT VISUALIZATION CHECKS: FAIL\n');
end
fprintf('Figure saved: %s\n', outputFile);
