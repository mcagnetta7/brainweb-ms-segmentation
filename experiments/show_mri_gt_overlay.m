%% Sovrapposizione MRI + ground truth (fase 35)
% Carica la MRI e il ground truth con il loader di src/io e sovrappone le
% lesioni (etichetta 10) a una slice assiale della MRI, per verificare
% visivamente l'integrità spaziale tra MRI e GT.
%
% La modalità T1 è la stessa delle fasi 31-33 ed è usata solo per questa
% verifica: non è la scelta della modalità baseline. Le slice sono scelte
% automaticamente dal GT solo per la visualizzazione: non sono parametri
% della segmentazione.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.visualization);

modality = "T1";
lesionLabel = 10;                           % BrainWeb: MS Lesion

mri = loadBrainwebMri(cfg, modality);
labels = loadBrainwebGroundTruth(cfg);
mriCopy = mri;                              % riferimenti per il confronto finale
labelsCopy = labels;

% Slice principale: quella con più voxel di etichetta 10.
% Slice di controllo: la slice mediana tra quelle che contengono lesioni.
lesionPerSlice = squeeze(sum(labels == lesionLabel, [1 2]));
[~, mainSlice] = max(lesionPerSlice);
lesionSlices = find(lesionPerSlice > 0);
checkSlice = lesionSlices(ceil(numel(lesionSlices) / 2));

slices = [mainSlice checkSlice];
suffixes = ["", "_check"];
overlayCounts = zeros(size(slices));

for s = 1:numel(slices)
    k = slices(s);
    titleText = sprintf('%s + GT lesions (label %d)  -  axial slice k = %d / %d', ...
        modality, lesionLabel, k, size(mri, 3));
    [fig, overlayCounts(s)] = showLesionOverlay(mri, labels, k, lesionLabel, titleText);
    fig.Position(3:4) = [620 640];
    exportgraphics(fig, fullfile(cfg.paths.figures, ...
        sprintf('phase35_%s_gt_overlay_k%03d%s.png', lower(modality), k, suffixes(s))));
end


%% Controlli

checks = {
    'MRI size [181 217 181]',  isequal(size(mri), cfg.dataset.volumeSize)
    'GT size [181 217 181]',   isequal(size(labels), cfg.dataset.volumeSize)
    'overlay count main',      overlayCounts(1) == lesionPerSlice(mainSlice) && overlayCounts(1) > 0
    'overlay count check',     overlayCounts(2) == lesionPerSlice(checkSlice) && overlayCounts(2) > 0
    'MRI unchanged',           isequal(mri, mriCopy)
    'GT unchanged',            isequal(labels, labelsCopy)
};

fprintf('\nMain slice k = %d (label-10 pixels: %d)\n', mainSlice, overlayCounts(1));
fprintf('Check slice k = %d (label-10 pixels: %d)\n', checkSlice, overlayCounts(2));
for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-26s %s\n', checks{c, 1}, result);
end

if all([checks{:, 2}])
    fprintf('\nOVERLAY CHECKS: PASS\n');
else
    fprintf('\nOVERLAY CHECKS: FAIL\n');
end
fprintf('Figures saved in: %s\n', cfg.paths.figures);
