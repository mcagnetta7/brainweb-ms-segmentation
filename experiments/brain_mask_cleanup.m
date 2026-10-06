%% Pulizia della maschera di supporto (fase 50, EXP-006)
% Input: maschere grezze della fase 49 (EXP-005), rigenerate da T2 pn0 e
% pn3 (double, /4095, nessun filtro, Otsu globale per volume).
%
% Candidato A (predefinito), per ogni slice assiale:
%   componenti connesse 2D a 8-connettività -> tieni la più grande ->
%   riempi i buchi SOLO nella componente tenuta.
% imfill NON viene mai applicato alla maschera grezza: riempirebbe il
% vuoto del cranio tra scalpo e cervello.
%
% Candidato B (escalation controllata): apertura 2D con elemento
% quadrato 3x3, poi come A. Si esegue SOLO se le figure di A mostrano
% scalpo o strutture esterne attaccati alla componente scelta tramite
% ponti sottili. Interruttore runCandidateB, spento di default.
%
% Nessuna chiusura, erosione o dilatazione isolata, nessuna soglia di
% area, nessun intervallo di slice, nessuna regola di posizione, nessun
% 3D, nessun ground truth, nessuna sovrapposizione alla MRI (fase 51).
% Se un controllo fallisce lo script si interrompe con un errore.

% Trigger di B soddisfatto (documentato dopo il primo run con solo A):
% nelle slice centrali A tiene un disco della testa perché lo scalpo è
% collegato al cervello attraverso le interruzioni dell'anello scuro del
% cranio (ponti sottili).
runCandidateB = true;
selectCandidateB = false;                   % deciso solo dopo aver ispezionato B

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

modality = cfg.dataset.modality;
assert(cfg.preprocessing.filter.method == "none", 'Phase 50 requires no filter.');

connectivity = 8;
openingElement = strel('square', 3);        % solo per il candidato B
expectedThresholds = [78 75] / 255;         % EXP-005, solo controllo di riproducibilità

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
nSlices = cfg.dataset.volumeSize(3);
displaySlices = round(linspace(1, nSlices, 5));    % stesse slice della fase 49

rawMasks = cell(1, 2);
masksA = cell(1, 2);
masksB = cell(1, 2);
diagA = cell(1, 2);
diagB = cell(1, 2);
checks = cell(0, 2);

for n = 1:2
    noise = noiseLevels(n);
    volume = prepare(loadBrainwebMri(cfg, modality, noise));
    [rawMask, threshold] = initialSupportMask(volume);

    checks(end+1, :) = {noise + " EXP-005 threshold reproduced", ...
        abs(threshold - expectedThresholds(n)) < 1e-9}; %#ok<SAGROW>

    [masksA{n}, diagA{n}] = cleanSupportMaskSlices(rawMask, connectivity, []);
    if runCandidateB
        [masksB{n}, diagB{n}] = cleanSupportMaskSlices(rawMask, connectivity, openingElement);
        fprintf('%s candidate B: foreground %d voxels (%.2f %%), opening changed %d voxels in %d slices\n', ...
            noise, nnz(masksB{n}), 100 * nnz(masksB{n}) / numel(masksB{n}), ...
            sum(diagB{n}.openingChanged), nnz(diagB{n}.openingChanged));
    end
    rawMasks{n} = rawMask;

    checks(end+1, :) = {noise + " candidate A logical, same size", ...
        islogical(masksA{n}) && isequal(size(masksA{n}), size(rawMask))}; %#ok<SAGROW>
    checks(end+1, :) = {noise + " candidate A voxel accounting", ...
        nnz(masksA{n}) == nnz(rawMask) - sum(diagA{n}.removedByComponent) ...
        + sum(diagA{n}.addedByFilling)}; %#ok<SAGROW>
end

if any(~[checks{:, 2}])
    error('exp006:inputNotReproduced', 'Phase 49 input or candidate A checks failed.');
end


%% Scelta del candidato: A, salvo trigger documentato per B

% Stessa scelta per pn0 e pn3
if selectCandidateB
    finalMasks = masksB;
    finalDiag = diagB;
    finalName = "B";
else
    finalMasks = masksA;
    finalDiag = diagA;
    finalName = "A";
end


%% Diagnostica

rows = cell(2, 1);
for n = 1:2
    d = finalDiag{n};
    rawMask = rawMasks{n};
    finalMask = finalMasks{n};
    rows{n} = {string(modality), noiseLevels(n), finalName, ...
        nnz(rawMask), nnz(rawMask) / numel(rawMask), ...
        nnz(finalMask), nnz(finalMask) / numel(finalMask), ...
        nnz(squeeze(any(finalMask, [1 2]))), nnz(~squeeze(any(finalMask, [1 2]))), ...
        sum(d.removedByComponent), sum(d.addedByFilling), ...
        median(d.nComponents), max(d.nComponents), nnz(d.nComponents > 1)};
end
summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'Modality', 'Noise', 'Candidate', 'RawVoxels', 'RawFraction', ...
     'CleanVoxels', 'CleanFraction', 'NonEmptySlices', 'EmptySlices', ...
     'RemovedByComponent', 'AddedByFilling', ...
     'MedianComponentsPerSlice', 'MaxComponentsPerSlice', 'SlicesWithMultipleComponents'});
disp(summary);

intersectionOverUnion = nnz(finalMasks{1} & finalMasks{2}) / nnz(finalMasks{1} | finalMasks{2});
differingFraction = nnz(xor(finalMasks{1}, finalMasks{2})) / numel(finalMasks{1});
fprintf('Cleaned-mask consistency (pn0 vs pn3): IoU = %.4f, differing voxels = %.4f %%\n\n', ...
    intersectionOverUnion, 100 * differingFraction);

writetable(summary, fullfile(cfg.paths.metrics, 'phase50_support_mask_cleanup_summary.csv'));

perSlice = table((1:nSlices)', ...
    diagA{1}.nComponents, diagA{1}.largestArea, diagA{1}.removedByComponent, diagA{1}.addedByFilling, ...
    diagA{2}.nComponents, diagA{2}.largestArea, diagA{2}.removedByComponent, diagA{2}.addedByFilling, ...
    'VariableNames', {'k', 'pn0_nComponents', 'pn0_largestArea', 'pn0_removed', 'pn0_filled', ...
                      'pn3_nComponents', 'pn3_largestArea', 'pn3_removed', 'pn3_filled'});
writetable(perSlice, fullfile(cfg.paths.metrics, 'phase50_support_mask_cleanup_per_slice.csv'));


%% Figure (solo maschere, nessuna MRI)

% 1. Diagnostica per slice su tutto il volume (nessuna slice scelta a mano)
fig1 = figure('Color', 'w');
layout = tiledlayout(fig1, 3, 1, 'TileSpacing', 'compact');
title(layout, 'Phase 50 candidate A - per-slice diagnostics (all slices)', 'Interpreter', 'none');
ax = nexttile(layout);
plot(ax, 1:nSlices, diagA{1}.nComponents, 1:nSlices, diagA{2}.nComponents);
ylabel(ax, 'components (8-conn)'); legend(ax, 'pn0', 'pn3'); xlim(ax, [1 nSlices]);
ax = nexttile(layout);
plot(ax, 1:nSlices, diagA{1}.removedByComponent, 1:nSlices, diagA{2}.removedByComponent);
ylabel(ax, 'voxels removed'); xlim(ax, [1 nSlices]);
ax = nexttile(layout);
plot(ax, 1:nSlices, diagA{1}.addedByFilling, 1:nSlices, diagA{2}.addedByFilling);
ylabel(ax, 'voxels added by filling'); xlabel(ax, 'axial slice k'); xlim(ax, [1 nSlices]);
fig1.Position(3:4) = [900 750];
exportgraphics(fig1, fullfile(cfg.paths.figures, 'phase50_candidateA_per_slice_diagnostics.png'));

% 2. Maschera grezza contro candidato finale sulle slice deterministiche
fig2 = figure('Color', 'w');
layout = tiledlayout(fig2, 4, numel(displaySlices), 'TileSpacing', 'compact');
title(layout, sprintf('Phase 50 - RAW (Phase 49) vs cleaned candidate %s, mask only', finalName), ...
    'Interpreter', 'none');
for n = 1:2
    for version = 1:2
        if version == 1
            volumeMask = rawMasks{n};
            label = "raw";
        else
            volumeMask = finalMasks{n};
            label = "clean " + finalName;
        end
        for s = 1:numel(displaySlices)
            ax = nexttile(layout);
            imagesc(ax, volumeMask(:, :, displaySlices(s)).');
            colormap(ax, gray);
            clim(ax, [0 1]);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('%s %s  k = %d', noiseLevels(n), label, displaySlices(s)));
        end
    end
end
fig2.Position(3:4) = [1400 1150];
exportgraphics(fig2, fullfile(cfg.paths.figures, 'phase50_raw_vs_clean_masks.png'));

if runCandidateB
    fig3 = figure('Color', 'w');
    layout = tiledlayout(fig3, 2, numel(displaySlices), 'TileSpacing', 'compact');
    title(layout, 'Phase 50 candidate B (3x3 square opening + largest component + filling)', ...
        'Interpreter', 'none');
    for n = 1:2
        for s = 1:numel(displaySlices)
            ax = nexttile(layout);
            imagesc(ax, masksB{n}(:, :, displaySlices(s)).');
            colormap(ax, gray);
            clim(ax, [0 1]);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('%s B  k = %d', noiseLevels(n), displaySlices(s)));
        end
    end
    fig3.Position(3:4) = [1400 650];
    exportgraphics(fig3, fullfile(cfg.paths.figures, 'phase50_candidateB_masks.png'));
    for n = 1:2
        fprintf('%s candidate B: voxels changed by opening = %d, slices affected = %d\n', ...
            noiseLevels(n), sum(diagB{n}.openingChanged), nnz(diagB{n}.openingChanged));
    end
end


%% Salvataggio e esito

for n = 1:2
    mask = finalMasks{n};
    cleanupRule = sprintf('candidate %s: %d-connected largest 2D component per slice, then imfill holes', ...
        finalName, connectivity);
    save(fullfile(cfg.paths.processedData, ...
        sprintf('phase50_%s_%s_support_mask_candidate.mat', lower(modality), noiseLevels(n))), ...
        'mask', 'cleanupRule');
end

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-40s %s\n', checks{c, 1}, result);
end
fprintf('\nPHASE 50 CHECKS: PASS (candidate B run: %s)\n', mat2str(runCandidateB));
