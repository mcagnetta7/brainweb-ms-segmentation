%% Fase 60: generazione della maschera dei candidati (metodo selezionato EXP-026)
% NON è un nuovo esperimento (nessun EXP-028). Formalizza l'uscita del
% metodo di soglia selezionato come artefatto canonico candidateMask:
%   T2 -> double -> /4095 -> maschera EXP-021 ->
%   multithresh(T2norm(brainMask), 2) -> imquantize -> classe 3
%   - parametri del metodo da config.m (cfg.segmentation); nessuna soglia
%     numerica fissata: le soglie sono ristimate per ogni volume
%   - verifica di identità esatta con le previsioni congelate di EXP-026
%     (che NON vengono modificate)
%   - solo pn0 + pn3; preprocessing NONE; nessun GT, nessuna metrica,
%     nessuna morfologia, nessuna analisi delle componenti.
% candidateMask è una maschera di CANDIDATI, non la segmentazione finale.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation);

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);
rawScale = cfg.preprocessing.normalization.inputRange(2);   % 4095

noiseLevels = ["pn0" "pn3"];
t2Files = {cfg.dataset.mriFiles.T2, cfg.dataset.noisyMriFiles.pn3.T2};
expectedSize = [181 217 181];
maskFile = @(noise) fullfile(cfg.paths.processedData, ...
    sprintf('exp021_t1_%s_3d_erode_select_dilate_candidate.mat', noise));
exp026File = @(noise) fullfile(cfg.paths.processedData, sprintf('exp026_t2_%s_multithresh_candidate.mat', noise));
outputFile = @(noise) fullfile(cfg.paths.processedData, sprintf('phase60_t2_%s_candidate_mask.mat', noise));

% Stato del metodo selezionato (dai CSV salvati delle fasi 58-59)
exp026Comparison = readtable(fullfile(cfg.paths.metrics, 'exp026_vs_otsu_comparison.csv'), 'TextType', 'string');
exp027Comparison = readtable(fullfile(cfg.paths.metrics, 'exp027_vs_exp026_comparison.csv'), 'TextType', 'string');
exp026Summary = readtable(fullfile(cfg.paths.metrics, 'exp026_multithresh_summary.csv'), 'TextType', 'string');

checks = {
    "selected method is EXP-026",       exp026Comparison.selectedCurrentBaseline(exp026Comparison.experiment == "EXP-026") == 1 && ...
                                        exp027Comparison.selectedCurrentBaseline(exp027Comparison.experiment == "EXP-026") == 1
    "EXP-027 remains rejected",         exp027Comparison.selectedCurrentBaseline(exp027Comparison.experiment == "EXP-027") == 0
    "config: multithresh, N = 2, class 3", cfg.segmentation.thresholdMethod == "multithresh" && ...
                                        cfg.segmentation.multithresh.numberOfThresholds == 2 && ...
                                        cfg.segmentation.multithresh.candidateClass == 3
    "modality is T2",                   cfg.dataset.modality == "T2"
    "preprocessing is NONE",            cfg.preprocessing.filter.method == "none"
    "only pn0/pn3 development data",    isequal(noiseLevels, ["pn0" "pn3"])
    };

rows = cell(2, 1);
for n = 1:2
    noise = noiseLevels(n);
    raw = loadBrainwebMri(cfg, "T2", noise);
    t2 = prepare(raw);
    saved = load(maskFile(noise), 'candidate');
    brainMask = saved.candidate;
    if ~isfile(exp026File(noise))
        error('phase60:technicallyBlocked', 'PHASE 60 TECHNICALLY BLOCKED: missing %s.', exp026File(noise));
    end
    reference = load(exp026File(noise), 'lesionCandidateMask', 'metadata');
    t2Copy = t2;
    maskCopy = brainMask;

    inputChecks = {
        noise + " T2 source file",               contains(string(t2Files{n}), "t2_ai_msles2_1mm_" + noise + "_rf0")
        noise + " EXP-021 mask for " + noise,    contains(string(maskFile(noise)), "exp021_t1_" + noise)
        noise + " T2 size 181x217x181",          isequal(size(t2), expectedSize)
        noise + " mask size = T2 size",          isequal(size(brainMask), size(t2))
        noise + " mask logical",                 islogical(brainMask)
        noise + " normalized T2 finite",         all(isfinite(t2(:)))
        noise + " normalized T2 in [0,1]",       min(t2(:)) >= 0 && max(t2(:)) <= 1
        };
    checks = [checks; inputChecks]; %#ok<AGROW>
    if any(~[inputChecks{:, 2}])
        error('phase60:technicallyBlocked', 'PHASE 60 TECHNICALLY BLOCKED: input checks failed for %s.', noise);
    end

    % Generatore riutilizzabile (metodo selezionato)
    [candidateMask, details] = generateLesionCandidateMask(t2, brainMask, cfg.segmentation);
    levels = details.thresholdsNormalized;
    classVolume = imquantize(t2, levels);
    identicalToExp026 = isequal(candidateMask, reference.lesionCandidateMask);

    checks = [checks; {
        noise + " multithresh input = T2norm(brainMask)", isequal(levels, double(multithresh(t2(brainMask), 2)))
        noise + " exactly two thresholds",               numel(levels) == 2
        noise + " threshold 1 < threshold 2",            levels(1) < levels(2)
        noise + " selected class = 3",                   details.selectedClass == 3
        noise + " candidateMask logical",                islogical(candidateMask)
        noise + " candidateMask size 181x217x181",       isequal(size(candidateMask), expectedSize)
        noise + " candidateMask inside brainMask",       ~any(candidateMask & ~brainMask, 'all')
        noise + " = highest imquantize class in mask",   isequal(candidateMask, brainMask & (classVolume == 3))
        noise + " = T2norm > upper threshold in mask",   isequal(candidateMask, brainMask & (t2 > levels(2)))
        noise + " identical to frozen EXP-026 mask",     identicalToExp026
        noise + " thresholds identical to EXP-026",      isequal(levels, reference.metadata.thresholdsNormalized)
        noise + " source T2 unchanged",                  isequal(t2, t2Copy)
        noise + " brainMask unchanged",                  isequal(brainMask, maskCopy)
        }]; %#ok<AGROW>
    if ~identicalToExp026
        error('phase60:technicallyBlocked', 'PHASE 60 TECHNICALLY BLOCKED: %s differs from EXP-026.', noise);
    end

    metadata = struct('phase', 60, 'sourceExperiment', "EXP-026", ...
        'status', "current development candidate mask", 'modality', "T2", 'condition', noise, ...
        'sourceT2', string(t2Files{n}), 'sourceBrainMask', string(maskFile(noise)), ...
        'method', "multithresh / multi-level Otsu", 'numberOfThresholds', details.numberOfThresholds, ...
        'numberOfClasses', details.numberOfClasses, 'selectedClass', details.selectedClass, ...
        'thresholdsNormalized', levels, 'thresholdsRawEquivalent', rawScale * levels, ...
        'normalization', "uint16 -> double -> /4095", 'preprocessing', "none", ...
        'gtUsedForGeneration', false, 'finalSegmentation', false, ...
        'note', "This is a lesion candidate mask, not the final lesion segmentation.");
    save(outputFile(noise), 'candidateMask', 'metadata');
    reloaded = load(outputFile(noise), 'candidateMask', 'metadata');
    checks = [checks; {
        noise + " canonical MAT reloads identically",   isequal(reloaded.candidateMask, candidateMask) && ...
                                                       isequal(reloaded.metadata, metadata)
        noise + " metadata source = EXP-026, no GT",    reloaded.metadata.sourceExperiment == "EXP-026" && ...
                                                       ~reloaded.metadata.gtUsedForGeneration
        }]; %#ok<AGROW>

    slices = find(squeeze(any(candidateMask, [1 2])));
    rows{n} = {noise, "EXP-026", "multithresh / multi-level Otsu", details.numberOfThresholds, ...
        details.selectedClass, levels(1), rawScale * levels(1), levels(2), rawScale * levels(2), ...
        nnz(brainMask), nnz(candidateMask), nnz(candidateMask) / nnz(brainMask), slices(1), slices(end), ...
        identicalToExp026};
    checks(end+1, :) = {noise + " candidate count = EXP-026 summary CSV", ...
        nnz(candidateMask) == exp026Summary.candidateVoxels(exp026Summary.condition == noise)}; %#ok<SAGROW>
end

summary = cell2table(vertcat(rows{:}), 'VariableNames', {'condition', 'sourceExperiment', 'method', ...
    'numberOfThresholds', 'selectedClass', 'threshold1Normalized', 'threshold1RawEquivalent', ...
    'threshold2Normalized', 'threshold2RawEquivalent', 'brainMaskVoxels', 'candidateVoxels', ...
    'candidateFractionBrain', 'firstCandidateSlice', 'lastCandidateSlice', 'identicalToExp026'});
writetable(summary, fullfile(cfg.paths.metrics, 'phase60_candidate_mask_summary.csv'));
disp(summary);

scriptText = fileread([mfilename('fullpath') '.m']);
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
forbidden = {['imerode' '('], ['imdilate' '('], ['imopen' '('], ['imclose' '('], ['imfill' '('], ...
    ['imreconstruct' '('], ['bwconn' 'comp('], ['region' 'props('], ['bwarea' 'open(']};
checks(end+1, :) = {"no GT loader called", ~contains(scriptText, ['loadBrainweb' 'GroundTruth'])};
checks(end+1, :) = {"no morphology/components called", ~any(cellfun(@(f) contains(scriptText, f), forbidden))};
checks(end+1, :) = {"no held-out condition referenced", ~any(cellfun(@(h) contains(scriptText, h), heldOut))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-48s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase60:checksFailed', 'Phase 60 checks failed.');
end
fprintf('\nPHASE 60 CHECKS: PASS (%d)\n', size(checks, 1));
