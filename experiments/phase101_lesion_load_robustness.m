%% Fase 101: robustezza della pipeline congelata v3 al carico lesionale (msles1 / msles2 / msles3)
% Estensione di robustezza DOPO il congelamento: nessun tuning, nessuna selezione.
% Dati: tre simulazioni BrainWeb CUSTOM con impostazioni identiche (template AI,
% 1 mm, rumore 0 %, INU 0 %, magnitude, seme 1); cambia solo il fantoccio
% (lieve / moderato / grave). Solo v3 tramite generateFinalPrediction.
% Ordine rigido: integrità -> tre predizioni salvate e rilette -> solo dopo i GT.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));
rel = @(p) strrep(erase(string(p), string(projectRoot) + filesep), '\', '/');
M = cfg.paths.metrics;

phantoms = ["msles1" "msles2" "msles3"];
loadNames = ["mild" "moderate" "severe"];
officialLesionMm3 = [422 3512 10104];          % pagine anatomiche ufficiali (note §3.1)
expectedSize = [181 217 181];
freezeCommit = "96b16124999a0d40f8df2c66b072fb3a38f10322";
customDir = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'phase101');
mriFiles = struct( ...
    'msles1', {{'custom_msles1_t1_ai_1mm_n0_inu0_job1261017-050735s-2817767.raws', ...
                'custom_msles1_t2_ai_1mm_n0_inu0_job1261017-050750s-2817854.raws'}}, ...
    'msles2', {{'custom_msles2_t1_ai_1mm_n0_inu0_job1261017-050846s-2818122.raws', ...
                'custom_msles2_t2_ai_1mm_n0_inu0_job1261017-050720s-2817689.raws'}}, ...
    'msles3', {{'custom_msles3_t1_ai_1mm_n0_inu0_job1261017-050805s-2817935.raws', ...
                'custom_msles3_t2_ai_1mm_n0_inu0_job1261017-050820s-2818018.raws'}});
mriHashes = struct( ...
    'msles1', {{'68DBB8937CE93F296CA18730D36151E2EF6ADD368783AA60DDB5FC54B92959C4', 'AD894B4F3705BC07969C52B3DC5635C24F9CC0786736131DC3A3826F8B9A9135'}}, ...
    'msles2', {{'952899077340EA64E74EA4C8984A6801C4399AA2F154E9AB2B47D500D5359ECE', 'DB84A85BD78B5AB3684277BB715B921762EC12B5EC6268805326D4C96558DF69'}}, ...
    'msles3', {{'ADF63BEC3138E3264E53AC05F456A0A22335871BD1ECDC46DBECF0F16286EC36', '7F7EEF1FDAF305B2C4CC9F3197F3BF90343EE785E51E99B6D51B7EEFE5CA08BC'}});
gtFiles = struct('msles1', fullfile(customDir, 'ground_truth', 'phantom_1.0mm_msles1_crisp.rawb'), ...
    'msles2', cfg.dataset.groundTruthFile, ...
    'msles3', fullfile(customDir, 'ground_truth', 'phantom_1.0mm_msles3_crisp.rawb'));
gtHashes = struct('msles1', '3F0DA14AE35395978F921C52174538D050239EE1549C5F636C47E775749EA1CA', ...
    'msles2', 'D1C0270A8FB27A5BA8364A885FE83F701441171F0B3474FDD0FC0EC8AE6AE06B', ...
    'msles3', '4928F1EC24D46104B95EB3D3D82E8A0D025D82145A711B17A3E07DA366346D47');
mriPath = @(p, m) fullfile(customDir, 'mri', mriFiles.(p){m});
predFile = @(p) fullfile(cfg.paths.processedData, sprintf('phase101_v3_%s_prediction.mat', p));
checks = cell(0, 2);


%% 0. Integrità del codice congelato e dei risultati precedenti; file di input

[gitStatus, gitOut] = system(sprintf('git -C "%s" rev-list -n 1 v3-final-frozen', projectRoot));
integrityBefore = integrityState(projectRoot, M);
finalConfig = finalSegmentationConfig();
inputsOk = true;
for p = phantoms
    inputsOk = inputsOk && strcmp(sha256File(mriPath(p, 1)), mriHashes.(p){1}) && ...
        strcmp(sha256File(mriPath(p, 2)), mriHashes.(p){2}) && strcmp(sha256File(gtFiles.(p)), gtHashes.(p));
end
statusText = fileread(fullfile(projectRoot, 'docs', 'PROJECT_STATUS.md'));
checks = [checks; {
    "1 Phase 99 recorded COMPLETE",                   contains(statusText, 'retrospective ablation study: COMPLETE')
    "2-3 primary v3 / D3_M1_G0; tag v3-final-frozen -> 96b1612", finalConfig.version == "v3" && ...
        finalConfig.sourceConfiguration == "D3_M1_G0" && gitStatus == 0 && strtrim(string(gitOut)) == freezeCommit
    "4-5 Phase-96 (26), Phase-97 (27), Phase-98 (32), Phase-99 outputs: hashes valid BEFORE", integrityBefore.ok
    "6-17 6 custom AI MRI (msles1/2/3 x T1/T2) + 3 crisp GT present with recorded SHA-256", inputsOk
    }];
mustPass(checks);

cfgCustom = cfg;
for p = phantoms
    cfgCustom.dataset.noisyMriFiles.(p).T1 = mriPath(p, 1);
    cfgCustom.dataset.noisyMriFiles.(p).T2 = mriPath(p, 2);
end


%% 1. Tre predizioni v3 (NESSUN GT)

assert(~exist('labels', 'var'), 'GT must not be loaded before the predictions.');
pred = cell(1, 3); det = cell(1, 3); s2 = cell(1, 3); supportInfo = zeros(3, 3); rawT2 = cell(1, 3);
for i = 1:3
    p = phantoms(i);
    rawT1 = loadBrainwebMri(cfgCustom, "T1", p);
    rawT2{i} = loadBrainwebMri(cfgCustom, "T2", p);
    [M_pred, d] = generateFinalPrediction(rawT1, rawT2{i});
    t1Norm = normalizeFixedRange(convertToWorkingClass(rawT1, "double"), [0 4095], [0 1]);
    [sup, supDetails] = computeT1AnatomicalSupport(t1Norm, d.brainMask);
    pred{i} = M_pred; det{i} = d; s2{i} = sup.S2;
    supportInfo(i, :) = [nnz(d.brainMask), supDetails.S1Voxels, supDetails.S2Voxels];
    checks = [checks; {
        "19-20 " + p + " T1 / T2 uint16 181x217x181, identical grid, 0..4095 (frozen normalization)", ...
            isa(rawT1, 'uint16') && isequal(size(rawT1), size(rawT2{i}), expectedSize) && max([rawT1(:); rawT2{i}(:)]) <= 4095
        "25-27 " + p + " prediction logical, 181x217x181, inside the automatic S2", islogical(M_pred) && ...
            isequal(size(M_pred), expectedSize) && ~any(M_pred & ~sup.S2, 'all')
        }]; %#ok<AGROW>
    phantom = p; officialLesionLoadName = loadNames(i); version = "v3"; configId = "D3_M1_G0";
    metadata = struct('phase', 101, 'simulationType', "BrainWeb custom simulation", 'protocol', "AI", ...
        'resolution', "1 mm isotropic", 'noise', "0 %", 'rfOrInu', "0 % (field A)", 'randomSeed', 1, ...
        'brainMaskThreshold', d.brainMaskThreshold, 't1ThresholdsNormalized', d.t1ThresholdsNormalized, ...
        't2ThresholdsNormalized', d.t2ThresholdsNormalized, 'predictedVoxels', nnz(M_pred), ...
        'gtUsedForGeneration', false, 'sourceFreezeTag', "v3-final-frozen", 'sourceFreezeCommit', freezeCommit);
    save(predFile(p), 'M_pred', 'phantom', 'officialLesionLoadName', 'version', 'configId', 'metadata');
    fprintf('%s (%s): %d voxels; brain-mask thr %.6f; T1 levels [%s]; TA levels [%s]\n', p, loadNames(i), nnz(M_pred), ...
        d.brainMaskThreshold, strjoin(compose('%.6f', d.t1ThresholdsNormalized), ' '), ...
        strjoin(compose('%.6f', d.t2ThresholdsNormalized), ' '));
end
reloaded = arrayfun(@(p) loadPrediction(predFile(p)), phantoms, 'UniformOutput', false);
checks(end+1, :) = {"23-24 all three predictions saved and re-read identical BEFORE any GT is loaded", ...
    isequal(reloaded, pred) && ~exist('labels', 'var')};
mustPass(checks);


%% 2. GT (solo ora) e metriche a volume completo

gt = cell(1, 3);
rows = cell(3, 35);
labelsOk = true;
for i = 1:3
    p = phantoms(i);
    cfgGt = cfg; cfgGt.dataset.groundTruthFile = gtFiles.(p);
    labels = loadBrainwebGroundTruth(cfgGt);
    gt{i} = labels == 10;
    % Semantica dell'etichetta 10 = lesione MS: volume ufficiale della pagina anatomica (voxel da 1 mm^3)
    labelsOk = labelsOk && isequal(size(labels), expectedSize) && min(labels(:)) == 0 && max(labels(:)) == 10 && ...
        nnz(gt{i}) == officialLesionMm3(i);
    cnt = computeVoxelConfusion(pred{i}, gt{i});
    gtVox = nnz(gt{i}); predVox = cnt.TP + cnt.FP;
    v = computeVolumeErrorPercent(gtVox, predVox);
    d = det{i};
    rows(i, :) = {p, loadNames(i), "BrainWeb custom simulation (AI template)", 1, 0, 0, gtVox, gtVox, predVox, predVox, ...
        cnt.TP, cnt.FP, cnt.FN, cnt.TN, computeDiceFromConfusion(cnt), computeIoUFromConfusion(cnt), ...
        computePrecisionFromConfusion(cnt), computeRecallFromConfusion(cnt), computeSpecificityFromConfusion(cnt), ...
        v.absoluteDifference, v.signedDifference, v.volumeErrorPercent, cnt.FP / gtVox, predVox / gtVox, ...
        d.brainMaskThreshold, d.t1ThresholdsNormalized(1), d.t1ThresholdsNormalized(2), d.t2ThresholdsNormalized(1), ...
        d.t2ThresholdsNormalized(2), "v3", "D3_M1_G0", "POST-FREEZE LESION-LOAD ROBUSTNESS", ...
        supportInfo(i, 1), supportInfo(i, 2), supportInfo(i, 3)};
end
primary = cell2table(rows, 'VariableNames', {'phantom', 'officialLesionLoadName', 'simulationType', 'resolutionMm', ...
    'noisePercent', 'rfOrInuPercent', 'gtLesionVoxels', 'gtLesionVolumeMm3', 'predictedVoxels', 'predictedVolumeMm3', ...
    'tpVoxels', 'fpVoxels', 'fnVoxels', 'tnVoxels', 'dice', 'iou', 'precision', 'recall', 'specificity', ...
    'absoluteVolumeDifferenceMm3', 'signedVolumeDifferenceMm3', 'volumeErrorPercent', 'fpToGtVoxelRatio', ...
    'predictedToGtVolumeRatio', 'brainMaskThreshold', 't1Threshold1', 't1Threshold2', 'taThreshold1', 'taThreshold2', ...
    'version', 'configId', 'role', 'brainMaskVoxels', 'S1Voxels', 'S2Voxels'});
writetable(primary, fullfile(M, 'phase101_lesion_load_robustness.csv'));
disp(primary(:, {'phantom', 'officialLesionLoadName', 'gtLesionVoxels', 'predictedVoxels', 'tpVoxels', 'fpVoxels', ...
    'fnVoxels', 'dice', 'precision', 'recall', 'volumeErrorPercent', 'fpToGtVoxelRatio', 'predictedToGtVolumeRatio'}));
fprintf('Descriptive only (no selection): Dice mean %.6f, min %.6f, max %.6f\n\n', mean(primary.dice), ...
    min(primary.dice), max(primary.dice));
checks = [checks; {
    "30 GT label range 0..10; label-10 voxels = official lesion volume (422 / 3512 / 10104 mm^3)", labelsOk
    "31-41 complete-volume metrics, counts, volumes and ratios for all three (TP+FP+FN+TN = all voxels)", ...
        height(primary) == 3 && all(primary.tpVoxels + primary.fpVoxels + primary.fnVoxels + primary.tnVoxels == ...
        prod(expectedSize)) && all(isfinite([primary.dice; primary.iou; primary.precision; primary.recall; primary.specificity]))
    }];


%% 3. Diagnostica per lesione e copertura di S2 (dopo le metriche principali)

lesRows = cell(3, 21);
for i = 1:3
    lw = computeLesionWiseMatches(pred{i}, gt{i}, 26);
    sizes = cellfun(@numel, lw.gtComponents(:));
    detected = lw.gtComponentTable.isDetected;
    inS2 = nnz(gt{i} & s2{i});
    lesRows(i, :) = {phantoms(i), loadNames(i), lw.gtComponentCount, lw.detectedGtLesionCount, lw.missedGtLesionCount, ...
        lw.predictedComponentCount, lw.matchedPredictedComponentCount, lw.falsePredictedComponentCount, ...
        height(lw.matchTable), sum(lw.matchTable.overlapVoxels), min(sizes), median(sizes), mean(sizes), max(sizes), ...
        sum(sizes), medianOrNaN(sizes(detected)), medianOrNaN(sizes(~detected)), inS2, nnz(gt{i}) - inS2, ...
        inS2 / nnz(gt{i}), inS2 / nnz(gt{i})};
end
lesion = cell2table(lesRows, 'VariableNames', {'phantom', 'officialLesionLoadName', 'gtComponentCount', ...
    'detectedGtLesions', 'missedGtLesions', 'predictedComponents', 'matchedPredictedComponents', ...
    'falsePredictedComponents', 'overlapRelations', 'overlapVoxels', 'gtLesionSizeMin', 'gtLesionSizeMedian', ...
    'gtLesionSizeMean', 'gtLesionSizeMax', 'gtLesionVoxelsTotal', 'detectedLesionSizeMedian', 'missedLesionSizeMedian', ...
    'gtVoxelsInsideS2', 'gtVoxelsOutsideS2', 'fractionGtInsideS2', 'recallCeilingS2'});
writetable(lesion, fullfile(M, 'phase101_lesionwise_diagnostics.csv'));
disp(lesion);
checks = [checks; {
    "42 lesion-wise rule: 26-connected 3D, detected iff >= 1 shared voxel; overlap voxels = TP", ...
        isequal(lesion.overlapVoxels, primary.tpVoxels) && all(lesion.detectedGtLesions + lesion.missedGtLesions == lesion.gtComponentCount)
    "43 continuous size statistics only (no cross-phantom size threshold)", all(isfinite(lesion.gtLesionSizeMedian))
    "44 S2 coverage / recall ceiling saved; total GT voxels consistent", isequal(lesion.gtLesionVoxelsTotal, primary.gtLesionVoxels) && ...
        all(lesion.gtVoxelsInsideS2 + lesion.gtVoxelsOutsideS2 == primary.gtLesionVoxels)
    }];


%% 4. Provenienza dei dati

prov = cell(0, 13);
jobOf = @(f) string(regexp(f, 'job([0-9a-z-]+)\.raws', 'tokens', 'once'));
for p = phantoms
    for m = 1:2
        f = mriPath(p, m);
        prov(end+1, :) = {p, loadNames(phantoms == p), ternary(m == 1, "T1", "T2"), "BrainWeb custom simulation", 0, 0, ...
            "1 mm, AI template, magnitude, seed 1", rel(f), fileBytes(f), sha256File(f), "2026-10-17", ...
            "cgi/bw/submit_request job " + jobOf(mriFiles.(p){m}), "PRIMARY input; served as brainweb.raws"}; %#ok<SAGROW>
    end
    f = gtFiles.(p);
    prov(end+1, :) = {p, loadNames(phantoms == p), "crisp GT", "BrainWeb anatomical model", NaN, NaN, "1 mm", rel(f), ...
        fileBytes(f), sha256File(f), ternary(p == "msles2", "2026-10-03", "2026-10-17"), ...
        "cgi/brainweb2 alias phantom_1.0mm_" + p + "_crisp", "label 10 = MS lesion (verified by volume)"}; %#ok<SAGROW>
end
icbm = dir(fullfile(customDir, 'mri', '*_icbm_*.raws'));
for k = 1:numel(icbm)
    f = fullfile(icbm(k).folder, icbm(k).name);
    tok = regexp(icbm(k).name, 'custom_(msles\d)_(t\d)_', 'tokens', 'once');
    prov(end+1, :) = {string(tok{1}), loadNames(phantoms == string(tok{1})), upper(string(tok{2})), ...
        "BrainWeb custom simulation", 0, 0, "1 mm, ICBM template, magnitude, seed 1", rel(f), icbm(k).bytes, sha256File(f), ...
        "2026-10-17", "cgi/bw/submit_request job " + jobOf(icbm(k).name), "obtained, NOT used (T2 contrast differs from the development domain)"}; %#ok<SAGROW>
end
provenance = cell2table(prov, 'VariableNames', {'phantom', 'officialLesionLoadName', 'modalityOrGt', 'simulationType', ...
    'noisePercent', 'rfOrInuPercent', 'resolution', 'filename', 'fileSizeBytes', 'sha256', 'downloadDate', ...
    'sourceReference', 'notes'});
writetable(provenance, fullfile(M, 'phase101_dataset_provenance.csv'));


%% 5. Figure

x = categorical(loadNames, loadNames);
fig = figure('Color', 'w');
layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact');
ax = nexttile(layout);
bar(ax, x, [primary.dice primary.precision primary.recall]); ylim(ax, [0 1]); grid(ax, 'on');
legend(ax, 'Dice', 'Precision', 'Recall', 'Location', 'southoutside', 'Orientation', 'horizontal');
title(ax, 'v3 overlap metrics');
ax = nexttile(layout);
bar(ax, x, [primary.gtLesionVoxels primary.predictedVoxels]); grid(ax, 'on'); ylabel(ax, 'voxels (mm^3)');
legend(ax, 'GT lesion volume', 'predicted volume', 'Location', 'southoutside', 'Orientation', 'horizontal');
title(ax, 'GT vs predicted lesion volume');
ax = nexttile(layout);
bar(ax, x, [primary.fpVoxels primary.fnVoxels]); grid(ax, 'on'); ylabel(ax, 'voxels');
legend(ax, 'FP', 'FN', 'Location', 'southoutside', 'Orientation', 'horizontal');
title(ax, 'FP and FN');
title(layout, {'Phase 101 - frozen v3 vs simulated lesion load (BrainWeb custom, AI, 1 mm, 0 % noise, 0 % INU)', ...
    'mild = msles1, moderate = msles2, severe = msles3; not independent patients'});
fig.Position(3:4) = [1400 460];
exportgraphics(fig, fullfile(cfg.paths.figures, 'phase101_lesion_load_metrics.png'));

fig = figure('Color', 'w');
layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'tight', 'Padding', 'tight');
for i = 1:3
    [~, k] = max(squeeze(sum(gt{i}, [1 2])));
    ax = nexttile(layout);
    t2s = double(rawT2{i}(:, :, k)).' / 4095;
    pr = pred{i}(:, :, k).'; g = gt{i}(:, :, k).';
    rgb = repmat(t2s, 1, 1, 3);
    rgb(:, :, 1) = rgb(:, :, 1) .* ~(pr | g) + (pr & ~g);
    rgb(:, :, 2) = rgb(:, :, 2) .* ~(pr | g) + (pr & g);
    rgb(:, :, 3) = rgb(:, :, 3) .* ~(pr | g) + (~pr & g);
    image(ax, rgb); axis(ax, 'image'); set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
    title(ax, sprintf('%s (%s), k = %d', phantoms(i), loadNames(i), k));
end
title(layout, {'Phase 101 - v3 on custom T2: green = TP, red = FP, blue = FN', ...
    'slice = max GT lesion voxels of each phantom (GT USED FOR VISUALIZATION SELECTION ONLY)'});
fig.Position(3:4) = [1300 480];
exportgraphics(fig, fullfile(cfg.paths.figures, 'phase101_lesion_load_overlays.png'));


%% 6. Manifest dei risultati e integrità finale

perPhantom = strings(1, 0);
for p = phantoms
    perPhantom = [perPhantom, string(mriPath(p, 1)), string(mriPath(p, 2)), string(gtFiles.(p)), string(predFile(p))]; %#ok<AGROW>
end
resultFiles = [perPhantom, ...
    fullfile(M, ["phase101_lesion_load_robustness.csv" "phase101_lesionwise_diagnostics.csv" ...
    "phase101_dataset_provenance.csv"]), fullfile(cfg.paths.figures, ["phase101_lesion_load_metrics.png" ...
    "phase101_lesion_load_overlays.png"]), string(fullfile(customDir, 'REQUESTS.txt')), string([mfilename('fullpath') '.m'])];
manifest = table(rel(resultFiles.'), string(cellfun(@sha256File, cellstr(resultFiles.'), 'UniformOutput', false)), ...
    'VariableNames', {'path', 'sha256'});
manifestFile = fullfile(M, 'phase101_result_manifest.csv');
writetable(manifest, manifestFile);
reread = readtable(manifestFile, 'TextType', 'string', 'Delimiter', ',');
manifestOk = all(arrayfun(@(i) strcmp(sha256File(fullfile(projectRoot, reread.path(i))), reread.sha256(i)), 1:height(reread)));
integrityAfter = integrityState(projectRoot, M);
inputsAfter = true;
for p = phantoms
    inputsAfter = inputsAfter && strcmp(sha256File(mriPath(p, 1)), mriHashes.(p){1}) && ...
        strcmp(sha256File(mriPath(p, 2)), mriHashes.(p){2}) && strcmp(sha256File(gtFiles.(p)), gtHashes.(p));
end
finalConfigAfter = finalSegmentationConfig();
scriptCode = strjoin(regexprep(splitlines(string(fileread([mfilename('fullpath') '.m']))), '%.*$', ''), newline);
forbidden = {['generateExp05' '7Prediction('], ['generateExp05' '8Prediction('], ['generateExp05' '9Prediction('], ...
    ['multithresh' '('], ['imdiffuse' 'filt('], ['imo' 'pen('], ['"P' 'D"'], ['Development' 'Score'], ['p' 'n1'], ...
    ['p' 'n5'], ['p' 'n7'], ['p' 'n9'], ['EXP-0' '60']};
checks = [checks; {
    "13, 21-22, 28, 45-48 only generateFinalPrediction(rawT1, rawT2); no other generator, step, PD, score or held-out", ...
        ~any(cellfun(@(f) contains(scriptCode, f), forbidden)) && contains(scriptCode, 'generateFinalPrediction(rawT1, rawT2{i})')
    "51-52 Phase-101 result manifest written (12 per-phantom + 3 CSV + 2 figures + requests + script = 19); hashes match", ...
        manifestOk && height(manifest) == 19
    "18 custom MRI and GT files unchanged after use",  inputsAfter
    "53-54 Phase-96 / 97 / 98 / 99 hashes unchanged AFTER", integrityAfter.ok && isequal(integrityBefore.hashes, integrityAfter.hashes)
    "49 primary remains v3 / D3_M1_G0; config.m unchanged", finalConfigAfter.version == "v3" && ...
        finalConfigAfter.sourceConfiguration == "D3_M1_G0" && isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
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
    error('phase101:checksFailed', 'PHASE 101 TECHNICALLY BLOCKED: checks failed.');
end
fprintf('\nResult manifest: %d artifacts -> %s\n', height(manifest), rel(manifestFile));
fprintf('\nPHASE 101 CHECKS: PASS (%d)\n', size(checks, 1));


function s = integrityState(root, M)
%INTEGRITYSTATE Hash dei manifest delle fasi 96 / 97, dell'inventario 98 e degli output della fase 99.
    files = {fullfile(M, 'phase96_final_freeze_manifest.csv'), 26; fullfile(M, 'phase97_result_manifest.csv'), 27; ...
        fullfile(M, 'phase98_final_results_inventory.csv'), 32};
    s.ok = true; s.hashes = strings(0, 1);
    for i = 1:size(files, 1)
        t = readtable(files{i, 1}, 'TextType', 'string', 'Delimiter', ',');
        h = string(arrayfun(@(p) sha256File(fullfile(root, p)), t.path, 'UniformOutput', false));
        s.ok = s.ok && height(t) == files{i, 2} && all(h == t.sha256);
        s.hashes = [s.hashes; h; string(sha256File(files{i, 1}))];
    end
    for f = ["phase99_ablation_summary.csv" "phase99_ablation_pairwise.csv" "phase99_development_trajectory.csv"]
        s.hashes = [s.hashes; string(sha256File(fullfile(M, f)))];
    end
end

function b = fileBytes(f)
%FILEBYTES Dimensione del file in byte.
    info = dir(f);
    b = info.bytes;
end

function m = medianOrNaN(x)
%MEDIANORNAN Mediana, NaN se il vettore è vuoto.
    if isempty(x)
        m = NaN;
    else
        m = median(x);
    end
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
        error('phase101:fileNotReadable', 'Cannot read %s', f);
    end
    [status, out] = system(sprintf('certutil -hashfile "%s" SHA256', f));
    lines = erase(strtrim(splitlines(string(out))), " ");
    match = lines(strlength(lines) == 64 & ~cellfun(@isempty, regexp(cellstr(lines), '^[0-9a-fA-F]{64}$')));
    if status ~= 0 || numel(match) ~= 1
        error('phase101:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end

function mustPass(checks)
%MUSTPASS Interrompe la fase 101 se un controllo preliminare fallisce.
    failed = find(~[checks{:, 2}]);
    for c = failed
        fprintf('%-100s FAILED\n', checks{c, 1});
    end
    if ~isempty(failed)
        error('phase101:technicallyBlocked', 'PHASE 101 TECHNICALLY BLOCKED: preliminary checks failed.');
    end
end
