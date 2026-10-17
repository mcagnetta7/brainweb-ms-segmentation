%% Fase 97: test finale held-out della pipeline congelata v3 (D3_M1_G0)
% Valutazione FINALE, non un esperimento di tuning: nessun parametro, nessuna
% scelta, nessuna modifica del codice congelato (tag v3-final-frozen).
% Ordine rigido:
%   0. verifica del congelamento della fase 96 (hash, tag) e dei file held-out
%   1. quattro predizioni v3 (pn1, pn5, pn7, pn9) con generateFinalPrediction,
%      salvate PRIMA di qualsiasi GT
%   2. predizioni secondarie v1 / v2 (versioni congelate), salvate, ancora senza GT
%   3. GT (label 10, volume completo) -> metriche primarie e confronto secondario
%   4. diagnostiche (lesion-wise fase 93, SMALL / LARGE fase 94, copertura di S2)
%   5. figure, manifest dei risultati, verifica finale degli hash congelati
% La versione principale è v3, fissata prima dell'accesso agli held-out: nessun
% risultato di questo script la può cambiare.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));
rel = @(p) strrep(erase(string(p), string(projectRoot) + filesep), '\', '/');

heldOut = ["pn1" "pn5" "pn7" "pn9"];
noisePercent = [1 5 7 9];
expectedSize = [181 217 181];
freezeCommit = "96b16124999a0d40f8df2c66b072fb3a38f10322";
freezeTag = "v3-final-frozen";
phase96Manifest = fullfile(cfg.paths.metrics, 'phase96_final_freeze_manifest.csv');
mriDir = fileparts(cfg.dataset.mriFiles.T1);
rawFile = @(m, n) fullfile(mriDir, sprintf('%s_ai_msles2_1mm_%s_rf0.raws', lower(m), n));
% SHA-256 registrati al download (DOWNLOAD_INFO.txt, 2026-10-16)
rawHashes = struct( ...
    'pn1', {{'A9EDEFBB50E9C8430081ACEB104FCFDC83F41F7A7D51BA9F1A5F2E1563D51562', 'DFA804EC972FC2A3C90F5A364E672F59500AFFE13BED62A0311A1A20B88B82BF'}}, ...
    'pn5', {{'ACEEF2CE6C2CD408519D45BCEA76336A42808E7CC993B562D1702C7AEF372DD9', '520489DD991B57B7F4FCF9F0F45C1B7BBF115CC6A09F1A31F356D57DC8DF85FA'}}, ...
    'pn7', {{'22DF705214F894B103B0BDC0AA46310AD99BE5D329A59DF24789C66A9C3780AF', '611D4E64FB49670475BD0B48D41CEEE830CCFEEB0BA5E9337CC93D813B5353F4'}}, ...
    'pn9', {{'F3B76893FE2EB45F4D06991F8234785BA9F2C801F3CE783EA0980DE0636F9F08', '81E733F93D9E0C08D892422099A380EE8FD987D8C480F48E84FFE93C1F9C51BC'}});
predFile = @(v, n) fullfile(cfg.paths.processedData, sprintf('phase97_%s_%s_prediction.mat', v, n));
v1File = @(n) fullfile(cfg.paths.processedData, sprintf('phase95_exp057_t2_%s_selected_prediction.mat', n));
v2File = @(n) fullfile(cfg.paths.processedData, sprintf('phase95_exp058_v2_%s_selected_prediction.mat', n));
v1Config = struct('id', "S2_TA_M2_G1", 'supportLevel', "S2", 'thresholdRule', "TA", 'openingType', "square", ...
    'openingParameter', 3, 'componentFilter', "minOccupiedSlices", 'componentConnectivity', 26, 'minimumOccupiedSlices', 2);
v2Config = struct('id', "F5_R0", 'filterType', "anisotropic", 'filterT1', false, 'filterT2', true, 'recovery', "R0");
checks = cell(0, 2);


%% 0. Precondizioni: congelamento della fase 96 e file held-out

manifest96 = readtable(phase96Manifest, 'TextType', 'string', 'Delimiter', ',');
manifest96Hash = sha256File(phase96Manifest);
frozenOk = height(manifest96) == 26 && all(arrayfun(@(i) strcmp(sha256File(fullfile(projectRoot, manifest96.path(i))), ...
    manifest96.sha256(i)), 1:height(manifest96)));
[gitStatus, gitOut] = system(sprintf('git -C "%s" rev-list -n 1 %s', projectRoot, freezeTag));
tagOk = gitStatus == 0 && strtrim(string(gitOut)) == freezeCommit;
finalConfig = finalSegmentationConfig();
rawOk = true;
for n = heldOut
    rawOk = rawOk && strcmp(sha256File(rawFile("T1", n)), rawHashes.(n){1}) && strcmp(sha256File(rawFile("T2", n)), rawHashes.(n){2});
end
checks = [checks; {
    "1-3 tag v3-final-frozen resolves to the Phase-96 freeze commit 96b1612", tagOk
    "4-5 Phase-96 manifest exists, 26 frozen source hashes match BEFORE the test", frozenOk
    "6-7 primary = v3, configuration D3_M1_G0, selected before held-out access", finalConfig.version == "v3" && ...
        finalConfig.sourceConfiguration == "D3_M1_G0" && ~finalConfig.heldOutUsedForSelection
    "8-10, 14-15 held-out T1 / T2 pn1, pn5, pn7, pn9 present with the SHA-256 recorded at download", rawOk
    }];
mustPass(checks);

% Configurazione in memoria per il loader validato (config.m NON modificato)
cfgHeld = cfg;
for n = heldOut
    cfgHeld.dataset.noisyMriFiles.(n).T1 = rawFile("T1", n);
    cfgHeld.dataset.noisyMriFiles.(n).T2 = rawFile("T2", n);
end


%% 1. Predizioni primarie v3 (NESSUN GT)

assert(~exist('gtMask', 'var'), 'GT must not be loaded before the predictions.');
v3Pred = cell(1, 4); s2Held = cell(1, 4); v3Details = cell(1, 4); rawT1 = cell(1, 4); rawT2 = cell(1, 4);
for c = 1:4
    n = heldOut(c);
    rawT1{c} = loadBrainwebMri(cfgHeld, "T1", n);
    rawT2{c} = loadBrainwebMri(cfgHeld, "T2", n);
    [M_pred, det] = generateFinalPrediction(rawT1{c}, rawT2{c});
    t1Norm = normalizeFixedRange(convertToWorkingClass(rawT1{c}, "double"), [0 4095], [0 1]);
    sup = computeT1AnatomicalSupport(t1Norm, det.brainMask);
    v3Pred{c} = M_pred; s2Held{c} = sup.S2; v3Details{c} = det;
    checks = [checks; {
        "16-18 " + n + " T1 / T2 uint16 181x217x181, identical grid, values 0..4095", isa(rawT1{c}, 'uint16') && ...
            isequal(size(rawT1{c}), size(rawT2{c}), expectedSize) && max([rawT1{c}(:); rawT2{c}(:)]) <= 4095
        "23-25 " + n + " v3 prediction logical, 181x217x181, contained in the automatic S2", islogical(M_pred) && ...
            isequal(size(M_pred), expectedSize) && ~any(M_pred & ~sup.S2, 'all')
        }]; %#ok<AGROW>
    condition = n; version = "v3"; configId = "D3_M1_G0";
    metadata = struct('phase', 97, 'role', "HELD-OUT PRIMARY TEST", 'sourceFreezeTag', freezeTag, ...
        'sourceFreezeCommit', freezeCommit, 'phase96Manifest', rel(phase96Manifest), 'modalities', "T1 + T2", ...
        'brainMaskThreshold', det.brainMaskThreshold, 't1ThresholdsNormalized', det.t1ThresholdsNormalized, ...
        'taThresholdsNormalized', det.t2ThresholdsNormalized, 'predictedVoxels', nnz(M_pred), ...
        'gtUsedForGeneration', false, 'heldOutCondition', true);
    save(predFile("v3", n), 'M_pred', 'condition', 'version', 'configId', 'metadata');
    fprintf('%s v3: %d voxels; brain-mask threshold %.6f; T1 levels [%s]; TA levels [%s]\n', n, nnz(M_pred), ...
        det.brainMaskThreshold, strjoin(compose('%.6f', det.t1ThresholdsNormalized), ' '), ...
        strjoin(compose('%.6f', det.t2ThresholdsNormalized), ' '));
end
v3Saved = arrayfun(@(c) loadPrediction(predFile("v3", heldOut(c))), 1:4, 'UniformOutput', false);
checks(end+1, :) = {"22 all four v3 predictions saved and re-read identical BEFORE the GT is loaded", ...
    isequal(v3Saved, v3Pred) && ~exist('gtMask', 'var')};
mustPass(checks);


%% 2. Versioni secondarie congelate v1 / v2 (ancora senza GT)

% Verifica che i generatori secondari, con la maschera EXP-021 rigenerata dal T1,
% riproducano esattamente le predizioni congelate di v1 e v2 su pn0 / pn3.
secondaryReproduced = true;
for n = ["pn0" "pn3"]
    [r1, r2] = deal(loadBrainwebMri(cfg, "T1", n), loadBrainwebMri(cfg, "T2", n));
    [p1, p2] = secondaryPredictions(r1, r2, v1Config, v2Config);
    secondaryReproduced = secondaryReproduced && isequal(p1, loadPrediction(v1File(n))) && isequal(p2, loadPrediction(v2File(n)));
end
checks(end+1, :) = {"43-44 frozen v1 / v2 generators reproduce the frozen v1 / v2 pn0 / pn3 predictions exactly", ...
    secondaryReproduced};
mustPass(checks);
v1Pred = cell(1, 4); v2Pred = cell(1, 4);
for c = 1:4
    n = heldOut(c);
    [v1Pred{c}, v2Pred{c}] = secondaryPredictions(rawT1{c}, rawT2{c}, v1Config, v2Config);
    for pair = {{"v1", v1Pred{c}, "S2_TA_M2_G1"}, {"v2", v2Pred{c}, "F5_R0"}}
        M_pred = pair{1}{2}; condition = n; version = pair{1}{1}; configId = pair{1}{3};
        metadata = struct('phase', 97, 'role', "SECONDARY LOCKED COMPARISON", 'gtUsedForGeneration', false, ...
            'heldOutCondition', true, 'predictedVoxels', nnz(M_pred));
        save(predFile(version, n), 'M_pred', 'condition', 'version', 'configId', 'metadata');
    end
end
fprintf('\nAll 12 held-out predictions (v3 primary, v1 / v2 secondary) saved before the GT.\n\n');


%% 3. GT (caricato SOLO ora) e metriche a volume completo

labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
gtCopy = gtMask;
gtVoxels = nnz(gtMask);
versions = {"v3", "D3_M1_G0", v3Pred; "v1", "S2_TA_M2_G1", v1Pred; "v2", "F5_R0", v2Pred};
cmpRows = cell(0, 16);
primaryRows = cell(4, 23);
for c = 1:4
    for v = 1:3
        cnt = computeVoxelConfusion(versions{v, 3}{c}, gtMask);
        volErr = computeVolumeErrorPercent(gtVoxels, cnt.TP + cnt.FP);
        m = [computeDiceFromConfusion(cnt), computeIoUFromConfusion(cnt), computePrecisionFromConfusion(cnt), ...
            computeRecallFromConfusion(cnt), computeSpecificityFromConfusion(cnt)];
        role = ternary(v == 1, "PRIMARY HELD-OUT", "SECONDARY LOCKED COMPARISON");
        cmpRows(end+1, :) = {heldOut(c), role, versions{v, 1}, versions{v, 2}, m(1), m(2), m(3), m(4), m(5), ...
            cnt.TP, cnt.FP, cnt.FN, cnt.TN, cnt.TP + cnt.FP, volErr.volumeErrorPercent, volErr.signedDifference}; %#ok<SAGROW>
        if v == 1
            d = v3Details{c};
            primaryRows(c, :) = {heldOut(c), "HELD-OUT PRIMARY TEST", "v3", "D3_M1_G0", noisePercent(c), ...
                d.brainMaskThreshold, d.t1ThresholdsNormalized(1), d.t1ThresholdsNormalized(2), ...
                d.t2ThresholdsNormalized(1), d.t2ThresholdsNormalized(2), cnt.TP + cnt.FP, cnt.TP, cnt.FP, cnt.FN, ...
                cnt.TN, m(1), m(2), m(3), m(4), m(5), volErr.volumeErrorPercent, volErr.signedDifference, ...
                nnz(gtMask & s2Held{c})};
        end
    end
end
primaryTable = cell2table(primaryRows, 'VariableNames', {'condition', 'role', 'version', 'configId', 'noisePercent', ...
    'brainMaskThreshold', 't1Threshold1', 't1Threshold2', 'taThreshold1', 'taThreshold2', 'predictedVoxels', ...
    'tpVoxels', 'fpVoxels', 'fnVoxels', 'tnVoxels', 'dice', 'iou', 'precision', 'recall', 'specificity', ...
    'volumeErrorPercent', 'signedVolumeDifferenceMm3', 'gtVoxelsInsideS2'});
comparison = cell2table(cmpRows, 'VariableNames', {'condition', 'role', 'version', 'configId', 'dice', 'iou', ...
    'precision', 'recall', 'specificity', 'tpVoxels', 'fpVoxels', 'fnVoxels', 'tnVoxels', 'predictedVoxels', ...
    'volumeErrorPercent', 'signedVolumeDifferenceMm3'});
writetable(primaryTable, fullfile(cfg.paths.metrics, 'phase97_v3_heldout_metrics.csv'));
writetable(comparison, fullfile(cfg.paths.metrics, 'phase97_frozen_versions_comparison.csv'));
disp(primaryTable(:, {'condition', 'predictedVoxels', 'tpVoxels', 'fpVoxels', 'fnVoxels', 'dice', 'iou', ...
    'precision', 'recall', 'specificity', 'volumeErrorPercent'}));
fprintf('v3 held-out Dice: mean %.6f, min %.6f, max %.6f (descriptive only; no selection)\n\n', ...
    mean(primaryTable.dice), min(primaryTable.dice), max(primaryTable.dice));
summary = groupsummary(comparison, 'version', {'mean', 'min', 'max'}, 'dice');
disp(summary);
checks = [checks; {
    "31-32 full-volume GT label 10, no restriction to S2 / brain mask (TP+FP+FN+TN = all voxels)", ...
        all(primaryTable.tpVoxels + primaryTable.fpVoxels + primaryTable.fnVoxels + primaryTable.tnVoxels == prod(expectedSize))
    "33-39 Dice, IoU, Precision, Recall, Specificity, volume error, confusion counts for all 4", ...
        height(primaryTable) == 4 && all(isfinite([primaryTable.dice; primaryTable.iou; primaryTable.precision; ...
        primaryTable.recall; primaryTable.specificity; primaryTable.volumeErrorPercent]))
    "40 primary table has exactly the four held-out rows", isequal(primaryTable.condition.', heldOut)
    "46 frozen-version comparison has 12 rows (4 conditions x 3 versions)", height(comparison) == 12
    }];


%% 4. Diagnostiche (dopo le metriche primarie; regole congelate)

sizeTable = readtable(fullfile(cfg.paths.metrics, 'exp055_gt_lesion_size_analysis.csv'), 'TextType', 'string');
sizeOfLesion = sortrows(sizeTable(sizeTable.condition == "pn0", {'gtLesionId', 'gtLesionVoxels', 'sizeClass', ...
    'sizeThresholdVoxels'}), 'gtLesionId');
lesionRows = cell(4, 17);
for c = 1:4
    lw = computeLesionWiseMatches(v3Pred{c}, gtMask, 26);
    g = lw.gtComponentTable;
    small = sizeOfLesion.sizeClass(g.gtLesionId) == "SMALL";
    lesionRows(c, :) = {heldOut(c), "v3", lw.gtComponentCount, lw.detectedGtLesionCount, lw.missedGtLesionCount, ...
        lw.predictedComponentCount, lw.falsePredictedComponentCount, height(lw.matchTable), sum(lw.matchTable.overlapVoxels), ...
        nnz(g.isDetected & small), nnz(~g.isDetected & small), nnz(g.isDetected & ~small), nnz(~g.isDetected & ~small), ...
        sum(g.totalOverlapVoxels(small)), sum(g.totalOverlapVoxels(~small)), nnz(gtMask & s2Held{c}), ...
        nnz(gtMask & s2Held{c}) / gtVoxels};
end
lesionTable = cell2table(lesionRows, 'VariableNames', {'condition', 'version', 'gtLesionCount', 'detectedGtLesions', ...
    'missedGtLesions', 'predictedComponents', 'falsePredictedComponents', 'overlapRelations', 'overlapVoxels', ...
    'smallDetected', 'smallMissed', 'largeDetected', 'largeMissed', 'smallLesionVoxelsRecovered', ...
    'largeLesionVoxelsRecovered', 'gtVoxelsInsideS2', 'recallCeilingS2'});
writetable(lesionTable, fullfile(cfg.paths.metrics, 'phase97_v3_lesionwise_diagnostics.csv'));
disp(lesionTable);
checks = [checks; {
    "47 lesion-wise rule unchanged: 26-connected 3D, detected iff >= 1 shared voxel", all(lesionTable.gtLesionCount == 59)
    "48 SMALL / LARGE grouping read from the frozen Phase-94 artifact (threshold 7 voxels)", ...
        all(sizeOfLesion.sizeThresholdVoxels == 7) && height(sizeOfLesion) == 59 && nnz(sizeOfLesion.sizeClass == "SMALL") == 31
    }];


%% 5. Figure (dopo predizioni e metriche; non cambiano nulla)

devRef = readtable(fullfile(projectRoot, 'docs', 'phase96_final_development_reference.csv'), 'TextType', 'string');
devNoise = [0 3];
fig = figure('Color', 'w');
layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact');
ax = nexttile(layout);
plot(ax, noisePercent, primaryTable.dice, 'ko-', 'MarkerFaceColor', 'k', 'LineWidth', 1.5); hold(ax, 'on');
plot(ax, devNoise, devRef.dice, 'ks', 'MarkerSize', 9, 'LineWidth', 1.2); hold(ax, 'off');
legend(ax, 'HELD-OUT (pn1, pn5, pn7, pn9)', 'DEVELOPMENT (pn0, pn3)', 'Location', 'southwest');
xlabel(ax, 'BrainWeb noise level (%)'); ylabel(ax, 'complete-volume Dice'); title(ax, 'v3 Dice vs noise');
ylim(ax, [0 1]); grid(ax, 'on'); xticks(ax, 0:9);
ax = nexttile(layout);
plot(ax, noisePercent, primaryTable.precision, 'bo-', noisePercent, primaryTable.recall, 'r^-', 'LineWidth', 1.5);
hold(ax, 'on'); plot(ax, devNoise, devRef.precision, 'bs', devNoise, devRef.recall, 'rs', 'MarkerSize', 9); hold(ax, 'off');
legend(ax, 'Precision (held-out)', 'Recall (held-out)', 'Precision (development)', 'Recall (development)', 'Location', 'southwest');
xlabel(ax, 'BrainWeb noise level (%)'); title(ax, 'v3 Precision / Recall vs noise'); ylim(ax, [0 1]); grid(ax, 'on'); xticks(ax, 0:9);
ax = nexttile(layout);
plot(ax, noisePercent, primaryTable.predictedVoxels, 'mo-', 'MarkerFaceColor', 'm', 'LineWidth', 1.5); hold(ax, 'on');
plot(ax, devNoise, devRef.predictedVoxels, 'ms', 'MarkerSize', 9); yline(ax, gtVoxels, 'k--', 'GT volume 3512 mm^3'); hold(ax, 'off');
legend(ax, 'held-out', 'development', 'Location', 'northwest');
xlabel(ax, 'BrainWeb noise level (%)'); ylabel(ax, 'predicted lesion volume (mm^3)'); title(ax, 'v3 predicted volume vs noise');
grid(ax, 'on'); xticks(ax, 0:9);
title(layout, 'Phase 97 - frozen v3 (D3\_M1\_G0): held-out vs development (development values are in-sample)');
fig.Position(3:4) = [1500 460];
exportgraphics(fig, fullfile(cfg.paths.figures, 'phase97_v3_noise_curves.png'));

fig = figure('Color', 'w');
ax = axes(fig);
diceMatrix = reshape(comparison.dice, 3, 4).';
bar(ax, categorical(heldOut, heldOut), diceMatrix);
legend(ax, 'v3 PRIMARY', 'v1 secondary', 'v2 secondary', 'Location', 'southwest');
ylabel(ax, 'complete-volume Dice'); ylim(ax, [0 1]); grid(ax, 'on');
title(ax, 'Phase 97 - frozen versions on held-out noise levels (primary fixed before the test)');
exportgraphics(fig, fullfile(cfg.paths.figures, 'phase97_frozen_versions_dice.png'));

% Sovrapposizioni: slice fissa k = 91 e slice con più voxel GT (SOLO per la visualizzazione)
[~, kMax] = max(squeeze(sum(gtMask, [1 2])));
displaySlices = unique([91 kMax]);
fig = figure('Color', 'w');
layout = tiledlayout(fig, numel(displaySlices), 4, 'TileSpacing', 'tight', 'Padding', 'tight');
for k = displaySlices
    for c = 1:4
        ax = nexttile(layout);
        t2s = double(rawT2{c}(:, :, k)).' / 4095;
        p = v3Pred{c}(:, :, k).'; g = gtMask(:, :, k).';
        rgb = repmat(t2s, 1, 1, 3);
        rgb(:, :, 1) = rgb(:, :, 1) .* ~(p | g) + (p & ~g);
        rgb(:, :, 2) = rgb(:, :, 2) .* ~(p | g) + (p & g);
        rgb(:, :, 3) = rgb(:, :, 3) .* ~(p | g) + (~p & g);
        image(ax, rgb); axis(ax, 'image'); set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('%s, k = %d', heldOut(c), k), 'FontSize', 8);
    end
end
title(layout, {'Phase 97 - v3 on held-out T2: green = TP, red = FP, blue = FN', ...
    sprintf('slices: fixed k = 91 and k = %d (max GT lesion voxels; GT used for DISPLAY selection only)', kMax)});
fig.Position(3:4) = [1300 700];
exportgraphics(fig, fullfile(cfg.paths.figures, 'phase97_v3_heldout_overlays.png'));


%% 6. Manifest dei risultati e verifica finale del codice congelato

perCondition = strings(1, 0);
for n = heldOut
    perCondition = [perCondition, string(rawFile("T1", n)), string(rawFile("T2", n)), string(predFile("v3", n)), ...
        string(predFile("v1", n)), string(predFile("v2", n))]; %#ok<AGROW>
end
resultFiles = [perCondition, ...
    fullfile(cfg.paths.metrics, ["phase97_v3_heldout_metrics.csv" "phase97_frozen_versions_comparison.csv" ...
    "phase97_v3_lesionwise_diagnostics.csv"]), ...
    fullfile(cfg.paths.figures, ["phase97_v3_noise_curves.png" "phase97_frozen_versions_dice.png" ...
    "phase97_v3_heldout_overlays.png"]), string([mfilename('fullpath') '.m'])];
resultManifest = table(rel(resultFiles.'), string(cellfun(@sha256File, cellstr(resultFiles.'), 'UniformOutput', false)), ...
    'VariableNames', {'path', 'sha256'});
writetable(resultManifest, fullfile(cfg.paths.metrics, 'phase97_result_manifest.csv'));

frozenAfterOk = all(arrayfun(@(i) strcmp(sha256File(fullfile(projectRoot, manifest96.path(i))), manifest96.sha256(i)), ...
    1:height(manifest96)));
rawAfterOk = true;
for n = heldOut
    rawAfterOk = rawAfterOk && strcmp(sha256File(rawFile("T1", n)), rawHashes.(n){1}) && ...
        strcmp(sha256File(rawFile("T2", n)), rawHashes.(n){2});
end
finalConfigAfter = finalSegmentationConfig();
scriptText = fileread([mfilename('fullpath') '.m']);
codeText = strjoin(regexprep(splitlines(string(scriptText)), '%.*$', ''), newline);
forbiddenHere = {['multithresh(' 't2'], ['imdiffuse' 'filt('], ['imo' 'pen('], ['str' 'el('], ['gaussianFilter' 'Slices('], ...
    ['imrecon' 'struct('], ['regionGrow' 'ing('], ['"P' 'D"'], ['rf' '20'], ['rf' '40'], ['msles' '1'], ['msles' '3']};
checks = [checks; {
    "11-13 no proton density, no INU 20 / 40 %, no other phantom, no segmentation step re-implemented here", ...
        ~any(cellfun(@(f) contains(codeText, f), forbiddenHere))
    "19-21, 26 v3 generated only by the frozen generateFinalPrediction(rawT1, rawT2), no GT argument", ...
        contains(codeText, 'generateFinalPrediction(rawT1{c}, rawT2{c})') && nargin('generateFinalPrediction') == 2
    "27-29 automatic thresholds recorded for every held-out condition", all(isfinite([primaryTable.brainMaskThreshold; ...
        primaryTable.t1Threshold1; primaryTable.t1Threshold2; primaryTable.taThreshold1; primaryTable.taThreshold2]))
    "52 Phase-96 manifest file not modified",         strcmp(sha256File(phase96Manifest), manifest96Hash)
    "53 frozen source hashes (Phase-96 manifest, 26) match AFTER the test", frozenAfterOk
    "54 held-out raw files unchanged after use (SHA-256)", rawAfterOk
    "GT unchanged; config.m unchanged",               isequal(gtMask, gtCopy) && ...
        isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    "55 primary remains v3 / D3_M1_G0 after all results", finalConfigAfter.version == "v3" && ...
        finalConfigAfter.sourceConfiguration == "D3_M1_G0"
    }];

for c = 1:size(checks, 1)
    if checks{c, 2}
        status = 'ok';
    else
        status = 'FAILED';
    end
    fprintf('%-100s %s\n', checks{c, 1}, status);
end
if any(~[checks{:, 2}])
    error('phase97:checksFailed', 'PHASE 97 TECHNICALLY BLOCKED: checks failed.');
end
fprintf('\nResult manifest: %d artifacts hashed -> %s\n', height(resultManifest), ...
    rel(fullfile(cfg.paths.metrics, 'phase97_result_manifest.csv')));
fprintf('\nPHASE 97 CHECKS: PASS (%d)\n', size(checks, 1));


function [p1, p2] = secondaryPredictions(rawT1, rawT2, v1Config, v2Config)
%SECONDARYPREDICTIONS Predizioni delle versioni congelate v1 e v2 (solo confronto).
%   Stessa normalizzazione e stessa maschera EXP-021 rigenerata dal T1 della
%   condizione; v1 = generateExp057Prediction S2_TA_M2_G1 su T2 non filtrato;
%   v2 = generateExp058Prediction F5_R0. Nessun parametro nuovo.
    t1Norm = normalizeFixedRange(convertToWorkingClass(rawT1, "double"), [0 4095], [0 1]);
    t2Norm = normalizeFixedRange(convertToWorkingClass(rawT2, "double"), [0 4095], [0 1]);
    brainMask = brainMask3DErodeSelectDilate(initialSupportMask(t1Norm), 3, 26);
    supports = computeT1AnatomicalSupport(t1Norm, brainMask);
    p1 = generateExp057Prediction(t2Norm, supports.S2, v1Config);
    p2 = generateExp058Prediction(t1Norm, t2Norm, brainMask, v2Config);
end

function M_pred = loadPrediction(f)
%LOADPREDICTION Ricarica M_pred da un file di predizione salvato.
    s = load(f, 'M_pred');
    M_pred = s.M_pred;
end

function out = ternary(condition, a, b)
%TERNARY a se condition è vero, altrimenti b.
    if condition
        out = a;
    else
        out = b;
    end
end

function h = sha256File(f)
%SHA256FILE Impronta SHA-256 (esadecimale maiuscolo) tramite certutil di Windows.
    if ~isfile(f)
        error('phase97:fileNotReadable', 'Cannot read %s', f);
    end
    [status, out] = system(sprintf('certutil -hashfile "%s" SHA256', f));
    lines = erase(strtrim(splitlines(string(out))), " ");
    match = lines(strlength(lines) == 64 & ~cellfun(@isempty, regexp(cellstr(lines), '^[0-9a-fA-F]{64}$')));
    if status ~= 0 || numel(match) ~= 1
        error('phase97:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end

function mustPass(checks)
%MUSTPASS Interrompe la fase 97 se un controllo preliminare fallisce.
    failed = find(~[checks{:, 2}]);
    for c = failed
        fprintf('%-100s FAILED\n', checks{c, 1});
    end
    if ~isempty(failed)
        error('phase97:technicallyBlocked', 'PHASE 97 TECHNICALLY BLOCKED: preliminary checks failed.');
    end
end
