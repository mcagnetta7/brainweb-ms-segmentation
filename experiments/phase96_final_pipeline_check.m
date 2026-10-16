%% Fase 96: controllo di regressione della pipeline finale congelata v3 (D3_M1_G0)
% NON è un esperimento di tuning: nessuna griglia, nessuna selezione, nessun
% parametro modificato. Verifica che il punto d'ingresso finale
% generateFinalPrediction, partendo dai volumi MRI grezzi e generando da sé la
% maschera EXP-021, riproduca voxel per voxel le predizioni salvate di EXP-059
% (pn0, pn3). Poi (solo dopo) ricalcola le metriche di sviluppo come
% regressione e scrive il manifest SHA-256 degli artefatti congelati.
% Nessun dato held-out.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));
rel = @(p) strrep(erase(string(p), string(projectRoot) + filesep), '\', '/');

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
v3File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase95_exp059_v3_%s_selected_prediction.mat', noise));
v2File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase95_exp058_v2_%s_selected_prediction.mat', noise));
v1File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase95_exp057_t2_%s_selected_prediction.mat', noise));
maskFile = @(noise) fullfile(cfg.paths.processedData, sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));
selectedCsv = fullfile(cfg.paths.metrics, 'exp059_selected_configuration.csv');
rankingCsv = fullfile(cfg.paths.metrics, 'exp059_tuning_ranking.csv');
manifestCsv = fullfile(cfg.paths.metrics, 'phase96_final_freeze_manifest.csv');
referenceCsv = fullfile(cfg.paths.metrics, 'phase96_final_development_reference.csv');
% SHA-256 registrati nel log al congelamento di v1 (fase 96a) e v2 (fase 96b)
historicalHashes = {v1File("pn0"), '12147984BACB7F94BAC288F89109BF605877AEFE8611C02115BECE81E44FEB9D'
                    v1File("pn3"), 'AFDE41B5EC35B89ED25ED9E95D53560021D27E19F5335FDDBAFE58B887603B57'
                    v2File("pn0"), 'D0BD81358D9AD8070C923F9DFDF4A505D0E5EFD75AC6AB9EDEC58C5107AC291D'
                    v2File("pn3"), '31F1E459F42ADA11204B4B342DE3E50125C08420523BF0C5F8C06D8337073BA7'};
closeTo = @(a, b) abs(a - b) <= 1e-12 * max(1, abs(b));
checks = cell(0, 2);


%% 0. Artefatti autorevoli di EXP-059 e versioni storiche

for f = [string(selectedCsv), string(rankingCsv), string(v3File("pn0")), string(v3File("pn3")), ...
        string(maskFile("pn0")), string(maskFile("pn3")), string(historicalHashes(:, 1)).']
    if ~isfile(f)
        error('phase96:technicallyBlocked', 'PHASE 96 TECHNICALLY BLOCKED: missing %s', f);
    end
end
sel = readtable(selectedCsv, 'TextType', 'string');
ranking = readtable(rankingCsv, 'TextType', 'string');
v3Saved = cell(1, 2);
for n = 1:2
    s = load(v3File(noiseLevels(n)), 'M_pred', 'configuration');
    v3Saved{n} = s.M_pred;
    savedConfig(n) = s.configuration; %#ok<SAGROW>
end
historicalOk = all(cellfun(@(f, h) strcmp(sha256File(f), h), historicalHashes(:, 1), historicalHashes(:, 2)));
finalConfig = finalSegmentationConfig();
checks = [checks; {
    "1 EXP-059 selected-configuration artifact exists (one row)", height(sel) == 1
    "2 EXP-059 selected configuration is D3_M1_G0, ranked first", sel.configId == "D3_M1_G0" && ...
        ranking.configId(1) == "D3_M1_G0" && ranking.selected(1) == 1
    "3-4 EXP-059 v3 pn0 / pn3 predictions exist, saved config D3_M1_G0", ...
        all([savedConfig.id] == "D3_M1_G0") && all([savedConfig.diffusion] == "D3")
    "5-7 authoritative Dice pn0 / pn3 / DevelopmentScore loaded", all(isfinite([sel.dicePn0 sel.dicePn3 sel.developmentScore]))
    "8 DevelopmentScore = equal-weight mean (Phase 37)", closeTo(sel.developmentScore, (sel.dicePn0 + sel.dicePn3) / 2)
    "9 primary version is v3 (selected before held-out access)", sel.primaryVersion == "v3" && sel.v3Exists == 1 && ...
        finalConfig.version == "v3" && ~finalConfig.heldOutUsedForSelection
    "10-11 v1 / v2 frozen predictions match their recorded SHA-256", historicalOk
    "45 final configuration artifact describes the frozen pipeline", finalConfig.sourceConfiguration == "D3_M1_G0" && ...
        finalConfig.t2FilterId == "D3" && finalConfig.structuringElement == "diamond" && ...
        finalConfig.structuringElementParameter == 1 && finalConfig.componentFilter == "none" && finalConfig.recovery == "none"
    }];
mustPass(checks);


%% 1. Rigenerazione dai volumi grezzi (NESSUN GT)

finalPred = cell(1, 2);
rawT1 = cell(1, 2); rawT2 = cell(1, 2);
for n = 1:2
    noise = noiseLevels(n);
    rawT1{n} = loadBrainwebMri(cfg, "T1", noise);
    rawT2{n} = loadBrainwebMri(cfg, "T2", noise);
    [M_pred, det] = generateFinalPrediction(rawT1{n}, rawT2{n});
    finalPred{n} = M_pred;

    % Ricostruzione indipendente passo per passo (stessi helper di base, nessun wrapper)
    t1Norm = normalizeFixedRange(convertToWorkingClass(rawT1{n}, "double"), [0 4095], [0 1]);
    t2Norm = normalizeFixedRange(convertToWorkingClass(rawT2{n}, "double"), [0 4095], [0 1]);
    s = load(maskFile(noise), 'candidate');
    sup = computeT1AnatomicalSupport(t1Norm, s.candidate);
    t2f = min(max(anisotropicDiffusionVolume3D(t2Norm), 0), 1);
    levels = multithresh(t2f(sup.S2), 2);
    candidate = sup.S2 & t2f > levels(2);
    opened = false(size(candidate));
    for k = 1:size(candidate, 3)
        opened(:, :, k) = imopen(candidate(:, :, k), strel('diamond', 1));
    end
    independent = opened & sup.S2;

    checks = [checks; {
        "13 " + noise + " normalization: fixed 0..4095 -> 0..1, double", isa(t1Norm, 'double') && ...
            min([t1Norm(:); t2Norm(:)]) >= 0 && max([t1Norm(:); t2Norm(:)]) <= 1
        "14 " + noise + " EXP-021 brain mask regenerated from T1 = saved EXP-021 mask", isequal(det.brainMask, s.candidate)
        "15-26 " + noise + " independent step-by-step rebuild (S2, D3, TA in S2, class 3, diamond-1 opening) = final", ...
            isequal(independent, M_pred)
        "37-39 " + noise + " final output logical, 181x217x181, contained in S2", islogical(M_pred) && ...
            isequal(size(M_pred), expectedSize) && ~any(M_pred & ~sup.S2, 'all')
        "40-41 " + noise + " FINAL prediction = saved EXP-059 D3_M1_G0 prediction voxel by voxel", isequal(M_pred, v3Saved{n})
        }]; %#ok<AGROW>
    fprintf('%s: final prediction %d voxels, brain-mask threshold %.6f, T2 levels [%s]\n', noise, nnz(M_pred), ...
        det.brainMaskThreshold, strjoin(compose('%.6f', det.t2ThresholdsNormalized), ' '));
end
mustPass(checks);


%% 2. Regressione delle metriche (GT caricato SOLO ora, nessuna selezione)

labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
gtCopy = gtMask;
refRows = cell(2, 18);
dice = zeros(1, 2);
for n = 1:2
    cnt = computeVoxelConfusion(finalPred{n}, gtMask);
    cntSaved = computeVoxelConfusion(v3Saved{n}, gtMask);
    dice(n) = computeDiceFromConfusion(cnt);
    volErr = computeVolumeErrorPercent(nnz(gtMask), cnt.TP + cnt.FP);
    refRows(n, :) = {noiseLevels(n), "v3", "D3_M1_G0", "DEVELOPMENT REFERENCE (in-sample, not a test result)", ...
        dice(n), computeIoUFromConfusion(cnt), computePrecisionFromConfusion(cnt), computeRecallFromConfusion(cnt), ...
        computeSpecificityFromConfusion(cnt), cnt.TP, cnt.FP, cnt.FN, cnt.TN, cnt.TP + cnt.FP, ...
        volErr.volumeErrorPercent, "EXP-059", "phase96_final_pipeline_check", isequal(cnt, cntSaved)};
end
developmentScore = (dice(1) + dice(2)) / 2;
referenceTable = cell2table(refRows, 'VariableNames', {'condition', 'version', 'configId', 'role', 'dice', 'iou', ...
    'precision', 'recall', 'specificity', 'tpVoxels', 'fpVoxels', 'fnVoxels', 'tnVoxels', 'predictedVoxels', ...
    'volumeErrorPercent', 'sourceExperiment', 'producedBy', 'countsEqualSavedPrediction'});
writetable(referenceTable, referenceCsv);
disp(referenceTable);
fprintf('Development Dice pn0 %.15g / pn3 %.15g, DevelopmentScore %.15g (EXP-059 artifact: %.15g)\n\n', ...
    dice(1), dice(2), developmentScore, sel.developmentScore);
checks = [checks; {
    "42 final pn0 Dice reproduces EXP-059 (CSV, 1e-12 for text rounding)", closeTo(dice(1), sel.dicePn0)
    "43 final pn3 Dice reproduces EXP-059 (CSV, 1e-12 for text rounding)", closeTo(dice(2), sel.dicePn3)
    "44 DevelopmentScore reproduces EXP-059",        closeTo(developmentScore, sel.developmentScore)
    "confusion counts of final = saved EXP-059 predictions (exact)", all(referenceTable.countsEqualSavedPrediction)
    "GT = complete label 10",                        isequal(gtMask, labels == 10) && isequal(size(gtMask), expectedSize)
    }];


%% 3. Controlli statici sul codice finale

entryCode = stripComments(fileread(fullfile(cfg.paths.segmentation, 'generateFinalPrediction.m')));
configCode = stripComments(fileread(fullfile(cfg.paths.segmentation, 'finalSegmentationConfig.m')));
d3Code = stripComments(fileread(fullfile(cfg.paths.preprocessing, 'anisotropicDiffusionVolume3D.m')));
scriptText = fileread([mfilename('fullpath') '.m']);
entryForbidden = {['Ground' 'Truth'], ['lo' 'ad('], ['"P' 'D"'], ['"squ' 'are"'], ['minOccupied' 'Slices'], ...
    ['imrecon' 'struct('], ['regionGrow' 'ing('], ['gaussianFilter' 'Slices('], ['anisotropicDiffusion' 'Slices('], ...
    ['"D' '2"'], ['multithresh(' 't2'], ['k >' '= 70'], ['sizeThreshold' 'Voxels'], ['min' 'Size']};
checks = [checks; {
    "16 T1 not filtered (no diffusion call on T1 in the final chain)", ~contains(entryCode, ['Volume3D(' 't1']) && ...
        ~finalConfig.t1Filtered
    "18-22 D3 helper: whole volume, 0.10 x volume range, 5 iterations, exponential, maximal", ...
        contains(d3Code, '0.10 * dynamicRange') && contains(d3Code, '''NumberOfIterations'', 5') && ...
        contains(d3Code, '''ConductionMethod'', ''exponential''') && contains(d3Code, '''Connectivity'', ''maximal''') && ...
        contains(d3Code, 'max(volume(:)) - min(volume(:))')
    "27-33 final entry point: no square 3, G1, recovery, region growing, PD, Gaussian or D2", ...
        ~any(cellfun(@(f) contains(entryCode, f), entryForbidden(3:11)))
    "34 no GT argument and no file access in the final entry point", nargin('generateFinalPrediction') == 2 && ...
        ~any(cellfun(@(f) contains(entryCode, f), entryForbidden(1:2)))
    "35-36 no position rule or GT-derived size threshold", ~any(cellfun(@(f) contains(entryCode, f) || ...
        contains(configCode, f), entryForbidden(12:14)))
    "no condition-specific measured threshold in the final configuration", ~contains(configCode, '0.6') && ...
        ~contains(configCode, '0.5')
    }];


%% 4. Protezione degli held-out e immutabilità

heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
rawNames = string({dir(fullfile(projectRoot, 'data', 'raw', '**', '*')).name});
outNames = [string({dir(fullfile(cfg.paths.metrics, '*')).name}), string({dir(fullfile(cfg.paths.processedData, '*')).name})];
rawUnchanged = true;
for n = 1:2
    rawUnchanged = rawUnchanged && isequal(rawT1{n}, loadBrainwebMri(cfg, "T1", noiseLevels(n))) && ...
        isequal(rawT2{n}, loadBrainwebMri(cfg, "T2", noiseLevels(n)));
end
checks = [checks; {
    "54-57 no held-out file in data/raw, no held-out path in config.m", ...
        ~any(cellfun(@(h) any(contains(rawNames, h)), heldOut)) && ~any(cellfun(@(h) contains(configTextAtStart, h), heldOut))
    "58 no held-out metric or prediction file exists",  ~any(cellfun(@(h) any(contains(outNames, h)), heldOut))
    "no held-out reference in this script",           ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "59-62 no new experiment id, no new candidate, no grid in this script", ~contains(scriptText, ['EXP-0' '60']) && ...
        ~contains(scriptText, ['sortr' 'ows(']) && ~contains(scriptText, ['candidate' 'Dir'])
    "51 raw pn0 / pn3 MRI unchanged",                 rawUnchanged
    "52 GT unchanged",                                isequal(gtMask, gtCopy)
    "53 config.m unchanged",                          isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];


%% 5. Manifest SHA-256 degli artefatti congelati

manifestRows = {
    "final configuration",            fullfile(cfg.paths.segmentation, 'finalSegmentationConfig.m'),        "v3", "frozen parameter record"
    "final prediction entry point",   fullfile(cfg.paths.segmentation, 'generateFinalPrediction.m'),        "v3", "composes the helpers below"
    "D3 anisotropic diffusion",       fullfile(cfg.paths.preprocessing, 'anisotropicDiffusionVolume3D.m'),  "v3", "whole-volume diffusion of T2"
    "T1 anatomical support S2",       fullfile(cfg.paths.segmentation, 'computeT1AnatomicalSupport.m'),     "v1-v3", "T1 partition, imfill, S2"
    "v3 pipeline composition",        fullfile(cfg.paths.segmentation, 'generateExp059Prediction.m'),       "v3", "D3 + S2 + TA/M/G"
    "TA threshold and opening",       fullfile(cfg.paths.segmentation, 'generateExp057Prediction.m'),       "v1-v3", "TA inside S2, one 2D opening AND S2"
    "TA candidate (multithresh)",     fullfile(cfg.paths.segmentation, 'generateLesionCandidateMask.m'),    "v1-v3", "multithresh N=2, class 3"
    "G1 helper (not executed, G0)",   fullfile(cfg.paths.segmentation, 'removeSingleSliceComponents3D.m'),  "v1-v2", "code dependency only"
    "EXP-021 Otsu foreground",        fullfile(cfg.paths.segmentation, 'initialSupportMask.m'),             "all", "brain mask step 1"
    "EXP-021 3D erode-select-dilate", fullfile(cfg.paths.segmentation, 'brainMask3DErodeSelectDilate.m'),   "all", "brain mask steps 2-5"
    "fixed normalization",            fullfile(cfg.paths.preprocessing, 'normalizeFixedRange.m'),           "all", "0..4095 -> 0..1"
    "working class conversion",       fullfile(cfg.paths.preprocessing, 'convertToWorkingClass.m'),         "all", "double"
    "MRI loader",                     fullfile(cfg.paths.io, 'loadBrainwebMri.m'),                          "all", "uint16 little-endian"
    "raw reader",                     fullfile(cfg.paths.io, 'readBrainwebRaw.m'),                          "all", ""
    "project configuration",          fullfile(projectRoot, 'config.m'),                                    "all", "unchanged; data paths and format"
    "EXP-059 selected configuration", selectedCsv,                                                          "v3", "authoritative development result"
    "EXP-059 ranking",                rankingCsv,                                                           "v3", ""
    "EXP-059 v3 pn0 prediction",      v3File("pn0"),                                                        "v3", "development reference prediction"
    "EXP-059 v3 pn3 prediction",      v3File("pn3"),                                                        "v3", "development reference prediction"
    "EXP-059 experiment script",      fullfile(projectRoot, 'experiments', 'exp059_v3_tuning.m'),          "v3", "regenerates the EXP-059 predictions"
    "Phase-96 regression check",      [mfilename('fullpath') '.m'],                                         "v3", "this script"
    "Phase-96 development reference", referenceCsv,                                                         "v3", "written by this script"
    "v1 pn0 prediction (historical)", v1File("pn0"),                                                        "v1", "secondary locked version"
    "v1 pn3 prediction (historical)", v1File("pn3"),                                                        "v1", "secondary locked version"
    "v2 pn0 prediction (historical)", v2File("pn0"),                                                        "v2", "secondary locked version"
    "v2 pn3 prediction (historical)", v2File("pn3"),                                                        "v2", "secondary locked version"
    };
hashes = cellfun(@sha256File, manifestRows(:, 2), 'UniformOutput', false);
manifest = table(string(manifestRows(:, 1)), rel(string(manifestRows(:, 2))), string(hashes), ...
    string(manifestRows(:, 3)), repmat("EXP-059 / Phase 96", size(manifestRows, 1), 1), string(manifestRows(:, 4)), ...
    'VariableNames', {'role', 'path', 'sha256', 'version', 'sourceExperiment', 'notes'});
writetable(manifest, manifestCsv);
reread = readtable(manifestCsv, 'TextType', 'string', 'Delimiter', ',');
verified = height(reread) == height(manifest) && all(arrayfun(@(i) strcmp(sha256File(fullfile(projectRoot, ...
    reread.path(i))), reread.sha256(i)), 1:height(reread)));
checks = [checks; {
    "47-48 SHA-256 manifest written, one entry per frozen artifact", isfile(manifestCsv) && height(manifest) == 26 && ...
        all(strlength(manifest.sha256) == 64)
    "49 manifest hashes match the current files (re-read and recomputed)", verified
    "50 EXP-059 and historical v1 / v2 artifacts unchanged", historicalOk && ...
        isequal(loadPrediction(v3File("pn0")), v3Saved{1}) && isequal(loadPrediction(v3File("pn3")), v3Saved{2})
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
    error('phase96:checksFailed', 'PHASE 96 TECHNICALLY BLOCKED: checks failed.');
end
fprintf('\nManifest: %d artifacts hashed -> %s\n', height(manifest), rel(manifestCsv));
fprintf('\nPHASE 96 REGRESSION CHECKS: PASS (%d)\n', size(checks, 1));


function h = sha256File(f)
%SHA256FILE Impronta SHA-256 (esadecimale maiuscolo) del contenuto di un file.
%   Usa certutil di Windows (MATLAB senza Java in questa installazione).
    if ~isfile(f)
        error('phase96:fileNotReadable', 'Cannot read %s', f);
    end
    [status, out] = system(sprintf('certutil -hashfile "%s" SHA256', f));
    lines = erase(strtrim(splitlines(string(out))), " ");
    match = lines(strlength(lines) == 64 & ~cellfun(@isempty, regexp(cellstr(lines), '^[0-9a-fA-F]{64}$')));
    if status ~= 0 || numel(match) ~= 1
        error('phase96:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end

function M_pred = loadPrediction(f)
%LOADPREDICTION Ricarica M_pred da un file di predizione salvato.
    s = load(f, 'M_pred');
    M_pred = s.M_pred;
end

function code = stripComments(text)
%STRIPCOMMENTS Testo del codice senza commenti (% fino a fine riga).
    code = strjoin(regexprep(splitlines(string(text)), '%.*$', ''), newline);
end

function mustPass(checks)
%MUSTPASS Interrompe la fase 96 se un controllo preliminare fallisce.
    failed = find(~[checks{:, 2}]);
    for c = failed
        fprintf('%-100s FAILED\n', checks{c, 1});
    end
    if ~isempty(failed)
        error('phase96:technicallyBlocked', 'PHASE 96 TECHNICALLY BLOCKED: preliminary checks failed.');
    end
end
