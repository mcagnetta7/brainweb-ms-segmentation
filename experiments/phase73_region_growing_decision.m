%% Fase 73: decisione sull'introduzione del region growing (nessun esperimento)
% Sintesi riproducibile di risultati GIÀ salvati per decidere se il region
% growing è giustificato nella pipeline attuale. Nessuna elaborazione
% d'immagine, nessun GT caricato, nessuna previsione nuova, nessun seme,
% nessun predicato di similarità, nessun nuovo ID di esperimento.
%
% Criterio della roadmap: il region growing è giustificato solo se
%   A) la maschera candidata fornisce nuclei di lesione affidabili (semi
%      specifici, non dominati da strutture chiare non lesionali), e
%   B) il limite principale residuo è l'estensione incompleta delle lesioni.
% I soli falsi negativi NON bastano.
%
% Indicatori (tutti da CSV salvati, nessuna nuova metrica):
%   - carico di FP: FP > TP nella previsione mantenuta (EXP-033, dopo morfologia)
%   - candidati ambigui grandi: la componente 3D più grande (EXP-039) supera
%     il volume TOTALE delle lesioni GT (un singolo oggetto più grande di
%     tutte le lesioni insieme non può essere un nucleo di lesione)
%   - estensione incompleta: FN > 0 nella previsione mantenuta
%   - protezione delle piccole lesioni: esito della fase 70 (EXP-037)

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));
noiseLevels = ["pn0" "pn3"];

required = {
    fullfile(cfg.paths.processedData, 'phase71_t2_pn0_predicted_volume.mat')
    fullfile(cfg.paths.processedData, 'phase71_t2_pn3_predicted_volume.mat')
    fullfile(cfg.paths.metrics, 'exp033_before_after_metrics.csv')
    fullfile(cfg.paths.metrics, 'exp037_phase70_decision.csv')
    fullfile(cfg.paths.metrics, 'exp039_components3d_summary.csv')
    };
checks = {"required prior artifacts exist", all(cellfun(@isfile, required))};
if ~checks{1, 2}
    error('phase73:technicallyBlocked', 'PHASE 73 TECHNICALLY BLOCKED: missing prior results.');
end
m033 = readtable(required{3}, 'TextType', 'string');
d037 = readtable(required{4}, 'TextType', 'string');
s039 = readtable(required{5}, 'TextType', 'string');

rows = cell(2, 1);
fpBurden = false(1, 2); largeAmbiguous = false(1, 2); incompleteExtent = false(1, 2);
for n = 1:2
    noise = noiseLevels(n);
    r = m033(m033.condition == noise & m033.stage == "after_morphology", :);
    c = s039(s039.condition == noise, :);
    md = load(required{n}, 'metadata');
    checks = [checks; {
        noise + " retained M_pred: no component filtering, EXP-036 rejected", ...
            md.metadata.componentFiltering == "none" && md.metadata.phase70Decision == "REJECT_AREA9_FILTER"
        noise + " retained-prediction metrics available (EXP-033)", height(r) == 1
        noise + " 3D structural results available (EXP-039)",      height(c) == 1 && c.predictedVoxels == r.candidateVoxels
        }]; %#ok<AGROW>
    fpBurden(n) = r.fpVoxels > r.tpVoxels;
    largeAmbiguous(n) = c.maxVoxelCount > r.gtVoxels;
    incompleteExtent(n) = r.fnVoxels > 0;
    rows{n} = {noise, r.candidateVoxels, r.tpVoxels, r.fpVoxels, r.fnVoxels, r.gtVoxels, c.total3DComponents, ...
        c.maxVoxelCount, c.maxOccupiedSliceCount};
end
evidence = cell2table(vertcat(rows{:}), 'VariableNames', {'condition', 'retainedCandidateVoxels', 'tpVoxels', ...
    'fpVoxels', 'fnVoxels', 'gtVoxels', 'total3DComponents', 'largest3DComponentVoxels', 'maxOccupiedSliceCount'});

smallLesionConcern = ~d037.smallLesionProtectionPassed;
coreReliable = ~any(fpBurden) && ~any(largeAmbiguous);
extentObserved = all(incompleteExtent);
prerequisite = coreReliable && extentObserved;
if prerequisite
    decisionValue = "INTRODUCE_REGION_GROWING";
    reason = "High-confidence lesion cores with incomplete extent.";
else
    decisionValue = "DO_NOT_INTRODUCE_REGION_GROWING";
    reason = "Incomplete lesion extent exists, but the candidate mask is not a specific high-confidence " + ...
        "lesion-core seed set (FP > TP and 3D candidate objects larger than the total GT lesion volume); " + ...
        "growth would propagate from non-specific seeds.";
end
coreCriterion = "FAIL";
if coreReliable
    coreCriterion = "PASS";
end
decision = table(decisionValue, coreCriterion, extentObserved, all(fpBurden), all(largeAmbiguous), ...
    smallLesionConcern, prerequisite, reason, 'VariableNames', {'decision', 'coreReliabilityCriterion', ...
    'extentLimitationObserved', 'falsePositiveBurdenObserved', 'largeAmbiguousCandidatesObserved', ...
    'smallLesionProtectionConcern', 'regionGrowingPrerequisiteSatisfied', 'reason'});
writetable(evidence, fullfile(cfg.paths.metrics, 'phase73_region_growing_evidence.csv'));
writetable(decision, fullfile(cfg.paths.metrics, 'phase73_region_growing_decision.csv'));
disp(evidence);
disp(decision(:, 1:7));
fprintf('PHASE-73 DECISION: %s\n\n', decisionValue);

checks(end+1, :) = {"config.m unchanged", isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)};
scriptText = fileread([mfilename('fullpath') '.m']);
forbidden = {['loadBrainweb' 'GroundTruth('], ['loadBrainweb' 'Mri('], ['bwconn' 'comp('], ['imopen' '('], ...
    ['imdilate' '('], ['imfill' '('], ['region' 'Growing('], ['regionGrow' 'Lesions('], ['grow' 'Lesions'], ['save' '('], ['pn' '1'], ['pn' '5'], ...
    ['pn' '7'], ['pn' '9']};
checks(end+1, :) = {"no image processing, GT, growth, save or held-out data", ...
    ~any(cellfun(@(f) contains(scriptText, f), forbidden))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-66s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase73:checksFailed', 'Phase-73 checks failed.');
end
fprintf('\nPHASE-73 CHECKS: PASS (%d)\n', size(checks, 1));
