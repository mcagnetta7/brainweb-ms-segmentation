%% Fase 52: applicazione della maschera cerebrale EXP-021 alla T2
% Implementazione della roadmap, NON un esperimento (non è EXP-022).
% La maschera EXP-021 (T1, congelata e validata nella fase 51) viene
% caricata dal file salvato e applicata alla T2 della STESSA condizione
% (pn0 -> pn0, pn3 -> pn3), senza ricalcolarla né modificarla:
%   analysisDomain = brainMask
%   maskedT2       = T2 con 0 fuori dalla maschera (solo visualizzazione/
%                    memorizzazione; zeri artificiali)
%   brainValues    = T2(brainMask) (popolazione per le statistiche future)
% T2: loader validato -> double -> /4095, nessun filtro. Nessuna
% registrazione, nessun ricampionamento. Nessun GT, nessuna etichetta,
% nessuna segmentazione delle lesioni, nessun istogramma della fase 40.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.visualization);

assert(cfg.dataset.modality == "T2", 'The lesion modality must remain T2.');
assert(cfg.preprocessing.filter.method == "none", 'Phase 52 requires no filter.');

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);

noiseLevels = ["pn0" "pn3"];
t2Files = {cfg.dataset.mriFiles.T2, cfg.dataset.noisyMriFiles.pn3.T2};
expectedSize = [181 217 181];
assert(isequal(cfg.dataset.volumeSize, expectedSize), 'Unexpected configured volume size.');
displaySlices = [1 40 46 91 136 143 160];

maskFile = @(noise) fullfile(cfg.paths.processedData, ...
    sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));
outputFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase52_t2_%s_brain_masked.mat', noise));

volumes = cell(1, 2);
maskedVolumes = cell(1, 2);
masks = cell(1, 2);
rows = cell(2, 1);
checks = cell(0, 2);

for n = 1:2
    noise = noiseLevels(n);

    % Ingressi e controlli di geometria PRIMA dell'applicazione
    raw = loadBrainwebMri(cfg, "T2", noise);
    t2 = prepare(raw);
    saved = load(maskFile(noise), 'candidate', 'radius');
    brainMask = saved.candidate;

    geometry = {
        noise + " T2 size 181x217x181",            isequal(size(t2), expectedSize)
        noise + " mask size 181x217x181",          isequal(size(brainMask), expectedSize)
        noise + " T2 size = mask size",            isequal(size(t2), size(brainMask))
        noise + " mask logical",                   islogical(brainMask)
        noise + " T2 finite after conversion",     all(isfinite(t2(:)))
        noise + " frozen EXP-021 (radius 3)",      saved.radius == 3
        };
    checks = [checks; geometry]; %#ok<AGROW>
    if any(~[geometry{:, 2}])
        error('phase52:technicallyBlocked', 'PHASE 52 TECHNICALLY BLOCKED: geometry checks failed for %s.', noise);
    end

    t2Copy = t2;
    maskCopy = brainMask;
    [maskedT2, brainValues] = applyBrainMask(t2, brainMask);

    checks = [checks; {
        noise + " output size = T2 size",              isequal(size(maskedT2), size(t2))
        noise + " T2 unchanged by application",        isequal(t2, t2Copy)
        noise + " mask unchanged by application",      isequal(brainMask, maskCopy)
        noise + " in-mask values identical to T2",     isequal(maskedT2(brainMask), t2(brainMask))
        noise + " outside-mask values exactly 0",      ~any(maskedT2(~brainMask))
        noise + " numel(brainValues) = nnz(mask)",     numel(brainValues) == nnz(brainMask)
        noise + " brainValues = T2(brainMask)",        isequal(brainValues, t2(brainMask))
        noise + " no NaN/Inf introduced",              all(isfinite(maskedT2(:))) && all(isfinite(brainValues))
        noise + " raw T2 unchanged on reload",         isequal(raw, loadBrainwebMri(cfg, "T2", noise))
        }]; %#ok<AGROW>

    % Salvataggio e rilettura
    metadata = struct( ...
        'condition', noise, ...
        'sourceMri', string(t2Files{n}), ...
        'sourceBrainMask', string(maskFile(noise)), ...
        'brainMaskMethod', "EXP-021 (T1, 3D erode sphere 3 -> largest 26-conn component -> dilate AND raw -> 2D fill), frozen, Phase-51 validated", ...
        'normalization', "uint16 -> double -> /4095 (fixed [0 4095] -> [0 1]), no filter", ...
        'note', "Zeros outside brainMask are artificial; brain-only statistics must use T2(brainMask).");
    save(outputFile(noise), 'maskedT2', 'brainMask', 'metadata');
    reloaded = load(outputFile(noise), 'maskedT2', 'brainMask');
    checks(end+1, :) = {noise + " saved output reloads identically", ...
        isequal(reloaded.maskedT2, maskedT2) && isequal(reloaded.brainMask, brainMask)}; %#ok<SAGROW>

    total = numel(brainMask);
    inside = nnz(brainMask);
    rows{n} = {noise, total, inside, total - inside, inside / total, (total - inside) / total, ...
        min(brainValues), max(brainValues), mean(brainValues), std(brainValues), ...
        nnz(maskedT2(brainMask) ~= t2(brainMask)), nnz(maskedT2(~brainMask) ~= 0)};

    volumes{n} = t2;
    maskedVolumes{n} = maskedT2;
    masks{n} = brainMask;
end

if any(~[checks{:, 2}])
    for c = 1:size(checks, 1)
        fprintf('%-46s %d\n', checks{c, 1}, checks{c, 2});
    end
    error('phase52:checksFailed', 'Phase 52 technical checks failed.');
end


%% Statistiche descrittive (nessuna interpretazione, nessuna soglia)

statistics = cell2table(vertcat(rows{:}), 'VariableNames', {'Condition', 'TotalVoxels', 'MaskVoxels', ...
    'ExcludedVoxels', 'RetainedFraction', 'ExcludedFraction', 'BrainT2Min', 'BrainT2Max', 'BrainT2Mean', ...
    'BrainT2Std', 'InMaskVoxelsModified', 'NonZeroOutsideMask'});
disp(statistics);
writetable(statistics, fullfile(cfg.paths.metrics, 'phase52_t2_brain_mask_application.csv'));


%% Verifica visiva dell'applicazione (non è una nuova validazione della maschera)

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 4, numel(displaySlices), 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf(['Phase 52 - EXP-021 (T1) brain mask applied to T2 %s: T2 / brain mask / ' ...
        'masked T2 (zeros outside are artificial) / mask boundary on T2 (alignment check)'], noiseLevels(n)), ...
        'Interpreter', 'none');
    for row = 1:4
        for c = 1:numel(displaySlices)
            k = displaySlices(c);
            ax = nexttile(layout);
            switch row
                case 1, panel = volumes{n}(:, :, k);
                case 2, panel = double(masks{n}(:, :, k));
                case 3, panel = maskedVolumes{n}(:, :, k);
                case 4
                    overlayMaskBoundaryOnMRI(ax, volumes{n}(:, :, k), masks{n}(:, :, k), ...
                        'BoundaryColor', [1 1 0], 'Title', sprintf('boundary k=%d', k));
                    continue
            end
            imagesc(ax, panel.');
            colormap(ax, gray);
            clim(ax, [0 1]);
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('k=%d', k), 'FontSize', 8);
        end
    end
    fig.Position(3:4) = [1700 1050];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('phase52_t2_%s_brain_mask_application.png', ...
        noiseLevels(n))), 'Resolution', 150);
end


%% Esito dei controlli

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-46s %s\n', checks{c, 1}, result);
end
fprintf('\nPHASE 52 CHECKS: PASS\n');
