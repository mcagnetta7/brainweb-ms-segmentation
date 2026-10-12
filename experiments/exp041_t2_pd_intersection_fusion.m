%% EXP-041 (fase 80): fusione T2 + PD per intersezione
% Una sola regola predichiarata (EXPERIMENT_LOG, EXP-041), uguale per pn0 e pn3:
%   fusedCandidateMask = M_T2 AND M_PD   (fusione binaria a livello di decisione)
% Ingressi: maschere selezionate e congelate della fase 78 (T2 classe 3,
% PD classe 3). Nessuna MRI ricaricata, nessuna soglia, nessuna morfologia,
% nessun filtro, nessun region growing, nessun GT. Solo statistiche
% strutturali di sovrapposizione tra maschere (non metriche di prestazione).
% Il risultato è sperimentale: M_pred della fase 71 resta canonico.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

noiseLevels = ["pn0" "pn3"];
expectedSize = [181 217 181];
fixedSlices = [46 91 102 136];
fusionRule = "intersection";
fusionExpression = "T2 AND PD";
decisionFile = fullfile(cfg.paths.metrics, 'phase79_selected_combination.csv');
selectedFile = @(mod, noise) fullfile(cfg.paths.processedData, ...
    sprintf('phase78_%s_%s_selected_single_modality.mat', mod, noise));
phase71File = @(noise) fullfile(cfg.paths.processedData, sprintf('phase71_t2_%s_predicted_volume.mat', noise));
outputFile = @(noise) fullfile(cfg.paths.processedData, sprintf('exp041_t2_pd_%s_intersection_candidate.mat', noise));
checks = cell(0, 2);


%% 1. Decisione della fase 79

checks(end+1, :) = {"Phase-79 selected-combination CSV exists", isfile(decisionFile)};
decision = readtable(decisionFile, 'TextType', 'string');
decisionOk = height(decision) == 1 && decision.primaryModality == "T2" && decision.secondaryModality == "PD" && ...
    decision.selectedCombination == "T2+PD" && decision.decisionStatus == "SELECTED" && ...
    ~decision.fusionRuleDefined && ~decision.multimodalPredictionGenerated;
checks = [checks; {
    "Phase-79 primary = T2",                         decision.primaryModality == "T2"
    "Phase-79 secondary = PD",                       decision.secondaryModality == "PD"
    "Phase-79 selected combination = T2+PD (SELECTED)", decision.selectedCombination == "T2+PD" && decision.decisionStatus == "SELECTED"
    "Phase-79 fusionRuleDefined = false",            ~decision.fusionRuleDefined
    "Phase-79 multimodalPredictionGenerated = false", ~decision.multimodalPredictionGenerated
    }];
if ~decisionOk
    error('exp041:technicallyBlocked', 'PHASE 80 TECHNICALLY BLOCKED: Phase-79 decision not as expected.');
end


%% 2. Ingressi della fase 78 e provenienza

t2Masks = cell(1, 2); pdMasks = cell(1, 2); mPred = cell(1, 2);
fileInfoBefore = struct();
for n = 1:2
    noise = noiseLevels(n);
    for mod = ["t2" "pd"]
        f = selectedFile(mod, noise);
        checks(end+1, :) = {"selected Phase-78 " + upper(mod) + " " + noise + " artifact exists", isfile(f)}; %#ok<SAGROW>
        if ~isfile(f)
            error('exp041:technicallyBlocked', 'PHASE 80 TECHNICALLY BLOCKED: missing %s', f);
        end
        s = load(f, 'candidateMask', 'metadata');
        md = s.metadata;
        provenance = md.phase == 78 && md.experiment == "EXP-040" && md.modality == upper(mod) && ...
            md.condition == noise && md.candidateClass == 3 && md.brainSupport == "EXP-021" && ...
            md.normalization == "/4095" && md.preprocessing == "none" && md.thresholdMethod == "multithresh" && ...
            md.numberOfThresholds == 2 && md.morphology == "standard 2D opening" && ...
            md.structuringElement == "square3" && md.componentFiltering == "none" && ...
            md.regionGrowing == "none" && md.multimodalFusion == "none" && ~md.gtUsedForGeneration;
        checks = [checks; {
            upper(mod) + " " + noise + " mask logical 181x217x181", islogical(s.candidateMask) && isequal(size(s.candidateMask), expectedSize)
            upper(mod) + " " + noise + " provenance (EXP-040, Class 3, EXP-021, /4095, multithresh 2, square3)", provenance
            }]; %#ok<AGROW>
        if mod == "t2"
            t2Masks{n} = s.candidateMask;
        else
            pdMasks{n} = s.candidateMask;
        end
        fileInfoBefore.(char(mod + noise)) = dir(f);
    end
    p = load(phase71File(noise), 'M_pred');
    mPred{n} = p.M_pred;
    fileInfoBefore.(char("mpred" + noise)) = dir(phase71File(noise));
    checks(end+1, :) = {"T2 " + noise + " selected mask = Phase-71 M_pred exactly", isequal(t2Masks{n}, mPred{n})}; %#ok<SAGROW>
    if ~isequal(t2Masks{n}, mPred{n})
        error('exp041:technicallyBlocked', 'PHASE 80 TECHNICALLY BLOCKED: T2 %s != Phase-71 M_pred.', noise);
    end
end
t2Copies = t2Masks; pdCopies = pdMasks; mPredCopies = mPred;


%% 3. Fusione (regola unica, uguale per pn0 e pn3)

fusedMasks = cell(1, 2);
rows = cell(2, 13);
for n = 1:2
    noise = noiseLevels(n);
    t2Mask = t2Masks{n};
    pdMask = pdMasks{n};
    fusedCandidateMask = fuseCandidateMasksIntersection(t2Mask, pdMask);
    fusedMasks{n} = fusedCandidateMask;

    t2Voxels = nnz(t2Mask);
    pdVoxels = nnz(pdMask);
    fusedVoxels = nnz(fusedCandidateMask);
    overlapVoxels = nnz(t2Mask & pdMask);
    t2OnlyVoxels = nnz(t2Mask & ~pdMask);
    pdOnlyVoxels = nnz(pdMask & ~t2Mask);
    exactIntersection = isequal(fusedCandidateMask, t2Mask & pdMask);
    subsetOfT2 = ~any(fusedCandidateMask & ~t2Mask, 'all');
    subsetOfPD = ~any(fusedCandidateMask & ~pdMask, 'all');
    checks = [checks; {
        "fused " + noise + " logical and 181x217x181",      islogical(fusedCandidateMask) && isequal(size(fusedCandidateMask), expectedSize)
        "fused " + noise + " = T2 AND PD exactly",          exactIntersection
        "fused " + noise + " subset of T2 (no voxel added)", subsetOfT2 && fusedVoxels <= t2Voxels
        "fused " + noise + " subset of PD",                 subsetOfPD && fusedVoxels <= pdVoxels
        "structural counts consistent " + noise,            overlapVoxels == fusedVoxels && ...
            t2Voxels == fusedVoxels + t2OnlyVoxels && pdVoxels == fusedVoxels + pdOnlyVoxels
        }]; %#ok<AGROW>

    metadata = struct('phase', 80, 'experiment', "EXP-041", 'condition', noise, ...
        'primaryModality', "T2", 'secondaryModality', "PD", 'selectedCombination', "T2+PD", ...
        'fusionLevel', "binary decision-level", 'fusionRule', fusionRule, 'fusionExpression', fusionExpression, ...
        'primarySourcePhase', 78, 'primarySourceExperiment', "EXP-040", 'primarySelectedClass', 3, ...
        'secondarySourcePhase', 78, 'secondarySourceExperiment', "EXP-040", 'secondarySelectedClass', 3, ...
        'primarySourceFile', string(selectedFile("t2", noise)), 'secondarySourceFile', string(selectedFile("pd", noise)), ...
        'brainSupport', "EXP-021", 'primaryNormalization', "/4095", 'secondaryNormalization', "/4095", ...
        'preprocessing', "none", 'morphologyBeforeFusion', "Phase-78 square3 opening already frozen", ...
        'morphologyAfterFusion', "none", 'componentFiltering', "none", 'regionGrowing', "none", ...
        'gtUsed', false, 'performanceEvaluated', false, 'canonicalPipelineModified', false, ...
        'finalPipelineFrozen', false);
    save(outputFile(noise), 'fusedCandidateMask', 'metadata');

    rows(n, :) = {noise, fusionRule, t2Voxels, pdVoxels, fusedVoxels, t2OnlyVoxels, pdOnlyVoxels, ...
        fusedVoxels / t2Voxels, t2OnlyVoxels / t2Voxels, fusedVoxels / pdVoxels, ...
        exactIntersection, subsetOfT2, subsetOfPD};
end
summary = cell2table(rows, 'VariableNames', {'condition', 'fusionRule', 't2Voxels', 'pdVoxels', 'fusedVoxels', ...
    't2OnlyVoxels', 'pdOnlyVoxels', 'fractionT2Retained', 'fractionT2Removed', 'fractionPDOverlappingT2', ...
    'exactIntersection', 'subsetOfT2', 'subsetOfPD'});
writetable(summary, fullfile(cfg.paths.metrics, 'exp041_t2_pd_fusion_summary.csv'));
disp(summary);

% Descrittori strutturali per slice (solo maschere): slice non vuote
for n = 1:2
    occupied = @(m) find(squeeze(any(m, [1 2])));
    kT2 = occupied(t2Masks{n}); kF = occupied(fusedMasks{n});
    fprintf('%s: non-empty slices T2 %d (k %d-%d), fused %d (k %d-%d)\n', noiseLevels(n), ...
        numel(kT2), min(kT2), max(kT2), numel(kF), min(kF), max(kF));
end
fprintf('\n');


%% 4. Figure descrittive (nessun GT): T2, PD, fusa, mappa di accordo

for n = 1:2
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, numel(fixedSlices), 4, 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, {sprintf('EXP-041 %s - T2 Class 3, PD Class 3, fused T2 AND PD (no GT)', noiseLevels(n)), ...
        'agreement map: cyan = T2 only, magenta = PD only, white = both (modality agreement, not TP/FP/FN)'}, ...
        'Interpreter', 'none');
    for k = fixedSlices
        t2Slice = t2Masks{n}(:, :, k).';
        pdSlice = pdMasks{n}(:, :, k).';
        fusedSlice = fusedMasks{n}(:, :, k).';
        panels = {t2Slice, pdSlice, fusedSlice};
        names = ["T2 Class 3", "PD Class 3", "fused T2 AND PD"];
        for p = 1:3
            ax = nexttile(layout);
            imagesc(ax, double(panels{p}));
            colormap(ax, gray(2)); set(ax, 'CLim', [0 1]);
            axis(ax, 'image'); set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('k=%d %s (%d px)', k, names(p), nnz(panels{p})), 'FontSize', 8);
        end
        ax = nexttile(layout);
        both = double(fusedSlice); t2Only = onlyIn(t2Slice, pdSlice); pdOnly = onlyIn(pdSlice, t2Slice);
        rgb = zeros([size(t2Slice) 3]);
        rgb(:, :, 1) = pdOnly + both;
        rgb(:, :, 2) = t2Only + both;
        rgb(:, :, 3) = t2Only + pdOnly + both;
        image(ax, min(rgb, 1));
        axis(ax, 'image'); set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
        title(ax, sprintf('k=%d agreement', k), 'FontSize', 8);
    end
    fig.Position(3:4) = [1200 1250];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp041_t2_pd_fusion_%s.png', noiseLevels(n))), ...
        'Resolution', 130);
end


%% 5. Controlli finali

reloadOk = true;
for n = 1:2
    r = load(outputFile(noiseLevels(n)), 'fusedCandidateMask', 'metadata');
    reloadOk = reloadOk && isequal(r.fusedCandidateMask, fusedMasks{n}) && r.metadata.fusionRule == "intersection" && ...
        ~r.metadata.gtUsed && ~r.metadata.performanceEvaluated;
end
sourcesUnchanged = true;
for name = string(fieldnames(fileInfoBefore)).'
    before = fileInfoBefore.(char(name));
    after = dir(fullfile(before.folder, before.name));
    sourcesUnchanged = sourcesUnchanged && after.datenum == before.datenum && after.bytes == before.bytes;
end
for n = 1:2
    s2 = load(selectedFile("t2", noiseLevels(n)), 'candidateMask');
    sp = load(selectedFile("pd", noiseLevels(n)), 'candidateMask');
    sm = load(phase71File(noiseLevels(n)), 'M_pred');
    sourcesUnchanged = sourcesUnchanged && isequal(s2.candidateMask, t2Copies{n}) && ...
        isequal(sp.candidateMask, pdCopies{n}) && isequal(sm.M_pred, mPredCopies{n});
end

scriptText = fileread([mfilename('fullpath') '.m']);
codeText = strjoin(regexprep(splitlines(string(scriptText)), '%.*$', ''), newline);
forbidden = {['loadBrainweb' 'GroundTruth('], ['loadBrainweb' 'Mri('], ['ground' 'Truth'], ['phan' 'tom_'], ...
    ['multi' 'thresh('], ['imquan' 'tize('], ['graythr' 'esh('], ['imbina' 'rize('], ['imo' 'pen('], ...
    ['imc' 'lose('], ['ime' 'rode('], ['imdi' 'late('], ['imf' 'ill('], ['imrecon' 'struct('], ...
    ['bwconn' 'comp('], ['bwarea' 'open('], ['filterComponents' 'ByArea2D('], ['regionGrow' 'ing(']};
metricWords = {['di' 'ce'], ['Di' 'ce'], ['tp' 'Voxels'], ['fp' 'Voxels'], ['fn' 'Voxels'], ['gt' 'Mask']};
altRules = {[' ' '| '], ['xo' 'r('], ['fusedCandidateMask = t2' 'Mask'], ['fusedCandidateMask = pd' 'Mask']};
heldOut = {['pn' '1'], ['pn' '5'], ['pn' '7'], ['pn' '9']};
fusionCalls = numel(strfind(codeText, ['fuseCandidateMasks' 'Intersection(']));
checks = [checks; {
    "fusion rule fixed to intersection; one fusion call, same for pn0/pn3", fusionRule == "intersection" && fusionCalls == 1
    "source T2 / PD masks and Phase-71 M_pred unchanged",   sourcesUnchanged && isequal(t2Masks, t2Copies) && isequal(pdMasks, pdCopies) && isequal(mPred, mPredCopies)
    "fused MAT files reload identically",                   reloadOk
    "no GT / MRI loaded, no threshold, morphology, components, region growing", ~any(cellfun(@(f) contains(codeText, f), forbidden))
    "no performance metric or confusion count computed",    ~any(cellfun(@(f) contains(codeText, f), metricWords))
    "no alternative fusion rule (OR / XOR / other)",        ~any(cellfun(@(f) contains(codeText, f), altRules))
    "no held-out condition referenced",                     ~any(cellfun(@(h) contains(scriptText, h), heldOut))
    "config.m unchanged, no fusion field",                  isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart) && ...
                                                             ~isfield(cfg, 'fusion') && ~isfield(cfg, 'multimodal')
    }];

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-90s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp041:checksFailed', 'EXP-041 checks failed.');
end
fprintf('\nEXP-041 CHECKS: PASS (%d)\n', size(checks, 1));


function out = onlyIn(a, b)
%ONLYIN Pixel di a non presenti in b (solo per la mappa di accordo).
    out = double(a) .* double(~b);
end
