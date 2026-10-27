%% Fase 111: validazione delle metriche di valutazione su casi artificiali con risultato noto
% Validazione SOFTWARE, non un esperimento: nessun dato BrainWeb, nessuna segmentazione, nessuna modifica
% di funzioni, parametri o risultati. Si chiamano le funzioni di valutazione REALI del progetto
% (src/evaluation) su piccole maschere artificiali e si confrontano con valori attesi scritti a mano
% (non calcolati con le funzioni sotto test).
%
% Funzioni testate: computeVoxelConfusion, computeDiceFromConfusion, computeIoUFromConfusion,
% computePrecisionFromConfusion, computeRecallFromConfusion, computeSpecificityFromConfusion,
% computeBinaryMaskVolume, computeVolumeErrorPercent, computeLesionWiseMatches.
%
% Convenzioni esistenti (lette dal codice, non modificate):
%   - Dice / IoU / Precision / Recall / Specificity con denominatore nullo restituiscono 1 (convenzione
%     documentata nelle funzioni e nelle note del dataset, fase 92);
%   - computeVolumeErrorPercent rifiuta V_GT = 0 con un errore (metrica non definita);
%   - politica di reporting per |GT| = 0 (test riservato, runner fase 103): Dice / IoU / Precision /
%     Recall / errore volumetrico = NaN (non riportati), Specificity = TN / (TN + FP).

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);
M = cfg.paths.metrics;
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));
tol = 1e-12;
rows = cell(0, 7);       % testId, quantity, expected, actual, tolerance, mandatory, notes


%% 0. Integrità del pacchetto scientifico congelato (prima)

manifests = ["phase118_final_results_source_manifest.csv" "phase118_120_final_report_package_manifest.csv" ...
    "phase103_runner_manifest.csv"];
manifestOk = @(t) all(arrayfun(@(i) strcmp(sha256File(fullfile(projectRoot, t.path(i))), t.sha256(i)), 1:height(t)));
mfTables = arrayfun(@(f) readtable(fullfile(M, f), 'TextType', 'string', 'Delimiter', ','), manifests, 'UniformOutput', false);
frozenBefore = all(cellfun(manifestOk, mfTables));
if ~frozenBefore
    error('phase111:blocked', 'PHASE 111 TECHNICALLY BLOCKED: frozen result package integrity check failed.');
end


%% 1. Caso principale 3 x 3 con TP, FP, FN e TN presenti

gtP = logical([1 1 0; 1 0 0; 0 0 0]);
prP = logical([1 0 1; 1 0 0; 0 0 0]);
% valori attesi scritti a mano
exp1 = struct('TP', 2, 'FP', 1, 'FN', 1, 'TN', 5, 'total', 9, 'Dice', 2/3, 'IoU', 1/2, 'Precision', 2/3, ...
    'Recall', 2/3, 'Specificity', 5/6, 'Vgt', 3, 'Vpred', 3, 'VolErr', 0);
c = computeVoxelConfusion(prP, gtP);
for q = ["TP" "FP" "FN" "TN"]
    rows(end+1, :) = {"P1", q, exp1.(q), c.(q), 0, true, "primary 3x3 case"}; %#ok<SAGROW>
end
rows(end+1, :) = {"P1", "TP+FP+FN+TN", exp1.total, c.TP + c.FP + c.FN + c.TN, 0, true, "counts sum to 9 elements"};
rows(end+1, :) = {"P1", "Dice", exp1.Dice, computeDiceFromConfusion(c), tol, true, "2TP/(2TP+FP+FN) = 4/6"};
rows(end+1, :) = {"P1", "IoU", exp1.IoU, computeIoUFromConfusion(c), tol, true, "TP/(TP+FP+FN) = 2/4"};
rows(end+1, :) = {"P1", "Precision", exp1.Precision, computePrecisionFromConfusion(c), tol, true, "TP/(TP+FP) = 2/3"};
rows(end+1, :) = {"P1", "Recall", exp1.Recall, computeRecallFromConfusion(c), tol, true, "TP/(TP+FN) = 2/3"};
rows(end+1, :) = {"P1", "Specificity", exp1.Specificity, computeSpecificityFromConfusion(c), tol, true, "TN/(TN+FP) = 5/6"};
vg = computeBinaryMaskVolume(gtP, [1 1 1]); vp = computeBinaryMaskVolume(prP, [1 1 1]);
ve = computeVolumeErrorPercent(vg.volumeMm3, vp.volumeMm3);
rows(end+1, :) = {"P1", "GT volume (mm3)", exp1.Vgt, vg.volumeMm3, 0, true, "3 voxels x 1 mm3"};
rows(end+1, :) = {"P1", "predicted volume (mm3)", exp1.Vpred, vp.volumeMm3, 0, true, "3 voxels x 1 mm3"};
rows(end+1, :) = {"P1", "VolumeErrorPercent", exp1.VolErr, ve.volumeErrorPercent, tol, true, "|3-3|/3*100"};


%% 2. Errore volumetrico non nullo (volumi noti)

g4 = false(3, 3); g4(1:4) = true;                % 4 voxel
p5 = false(3, 3); p5(1:5) = true;                % 5 voxel
vg4 = computeBinaryMaskVolume(g4, [1 1 1]); vp5 = computeBinaryMaskVolume(p5, [1 1 1]);
ve2 = computeVolumeErrorPercent(vg4.volumeMm3, vp5.volumeMm3);
rows(end+1, :) = {"V2", "VolumeErrorPercent", 25, ve2.volumeErrorPercent, tol, true, "|5-4|/4*100 = 25 % (overestimation)"};
rows(end+1, :) = {"V2", "signed difference (mm3)", 1, ve2.signedDifference, 0, true, "5-4 = +1"};
ve3 = computeVolumeErrorPercent(4, 3);
rows(end+1, :) = {"V3", "VolumeErrorPercent", 25, ve3.volumeErrorPercent, tol, true, "|3-4|/4*100 = 25 % (absolute, underestimation)"};
rows(end+1, :) = {"V3", "signed difference (mm3)", -1, ve3.signedDifference, 0, true, "3-4 = -1"};
vg4s = computeBinaryMaskVolume(g4, [2 1 1]);
rows(end+1, :) = {"V4", "voxel volume with 2x1x1 mm spacing (mm3)", 8, vg4s.volumeMm3, 0, true, ...
    "4 voxels x 2 mm3 (spacing is multiplied, not assumed 1)"};


%% 3. Casi limite (convenzioni esistenti, verificate senza modificarle)

% Caso A - corrispondenza perfetta non vuota
gA = logical([1 1 0; 0 1 0; 0 0 0]); cA = computeVoxelConfusion(gA, gA);
rows = [rows; caseRows("A", cA, [3 0 0 6], [1 1 1 1 1], tol, "prediction = GT (3 positives, 6 negatives)")];
veA = computeVolumeErrorPercent(3, 3);
rows(end+1, :) = {"A", "VolumeErrorPercent", 0, veA.volumeErrorPercent, tol, true, "equal volumes"};

% Caso B - GT non vuota, predizione vuota (Precision: denominatore TP+FP = 0 -> convenzione 1)
gB = logical([1 1 0; 1 0 0; 0 0 0]); pB = false(3, 3); cB = computeVoxelConfusion(pB, gB);
rows = [rows; caseRows("B", cB, [0 0 3 6], [0 0 1 0 1], tol, ...
    "empty prediction; Precision 0/0 -> 1 by project convention")];
veB = computeVolumeErrorPercent(3, 0);
rows(end+1, :) = {"B", "VolumeErrorPercent", 100, veB.volumeErrorPercent, tol, true, "|0-3|/3*100 (allowed: V_pred = 0)"};

% Caso C - GT vuota, predizione non vuota (struttura del phantom normale)
gC = false(3, 3); pC = logical([0 1 0; 0 1 0; 0 0 0]); cC = computeVoxelConfusion(pC, gC);
rows = [rows; caseRows("C", cC, [0 2 0 7], [0 0 0 1 7/9], tol, ...
    "empty GT; Dice/IoU/Precision = 0 (denominators > 0); Recall 0/0 -> 1 by convention; Specificity 7/9")];
rows(end+1, :) = {"C", "VolumeErrorPercent rejects V_GT = 0", 1, double(throwsWithId(@() computeVolumeErrorPercent(0, 2), ...
    'computeVolumeErrorPercent:zeroGtVolume')), 0, true, "undefined: function raises an error, no convention"};

% Caso D - GT e predizione entrambe vuote (tutti i denominatori positivi nulli -> convenzione 1)
gD = false(3, 3); cD = computeVoxelConfusion(gD, gD);
rows = [rows; caseRows("D", cD, [0 0 0 9], [1 1 1 1 1], tol, "both empty; Dice/IoU/Precision/Recall 0/0 -> 1 by convention")];
rows(end+1, :) = {"D", "VolumeErrorPercent rejects V_GT = 0", 1, double(throwsWithId(@() computeVolumeErrorPercent(0, 0), ...
    'computeVolumeErrorPercent:zeroGtVolume')), 0, true, "undefined: function raises an error, no convention"};

% Errori di ingresso: dimensioni diverse e maschere non logiche sono rifiutate
rows(end+1, :) = {"E", "size mismatch rejected", 1, double(throwsWithId(@() computeVoxelConfusion(false(3, 3), false(3, 4)), ...
    'computeVoxelConfusion:sizeMismatch')), 0, true, "input validation"};
rows(end+1, :) = {"E", "non-logical mask rejected", 1, double(throwsAny(@() computeVoxelConfusion(double(gB), gB))), 0, true, ...
    "input validation (mustBeA logical)"};


%% 4. Politica di reporting per |GT| = 0 (livello di reporting, dai risultati congelati)

runnerCode = fileread(fullfile(projectRoot, 'experiments', 'phase103_experiment_runner.m'));
audit = readtable(fullfile(M, 'phase119_full_results_audit.csv'), 'TextType', 'string', 'Delimiter', ',');
normalRows = audit(startsWith(audit.caseId, "reserved_normal"), :);
policyNaN = all(isnan([normalRows.dice normalRows.iou normalRows.precision normalRows.recall normalRows.volumeErrorPercent]), 'all');
countsOk = all(normalRows.gtLesionVoxels == 0 & normalRows.TP == 0 & normalRows.FN == 0 & normalRows.FP == normalRows.predictedVoxels);
specOk = max(abs(normalRows.specificity - normalRows.TN ./ (normalRows.TN + normalRows.FP))) < tol;
rows(end+1, :) = {"R", "lesion-free rows found (2 cases x 2 versions)", 4, height(normalRows), 0, true, "phase119_full_results_audit.csv"};
rows(end+1, :) = {"R", "Dice/IoU/Precision/Recall/VolumeError reported as NaN", 1, double(policyNaN), 0, true, ...
    "reporting layer; low-level functions unchanged"};
rows(end+1, :) = {"R", "TP = FN = 0 and FP = predicted voxels", 1, double(countsOk), 0, true, "lesion-free counts"};
rows(end+1, :) = {"R", "Specificity = TN/(TN+FP)", 1, double(specOk), 0, true, sprintf("max abs diff < %g", tol)};
rows(end+1, :) = {"R", "runner applies NaN only when |GT| = 0", 1, ...
    double(contains(runnerCode, 'm = NaN(1, 4); ve = NaN;') && contains(runnerCode, 'protocollo preregistrato')), 0, true, ...
    "reporting branch in phase103_experiment_runner.m"};


%% 5. Analisi lesion-wise (componenti 26-connesse, corrispondenza = almeno un voxel in comune)

% Volume 9 x 9 x 3; tutte le componenti sono sul piano z = 2 e distano almeno 2 voxel tra loro.
gtL = false(9, 9, 3); prL = false(9, 9, 3);
gtL(2, 2, 2) = true; gtL(2, 3, 2) = true;        % G1: rilevata (P1 condivide (2,3,2))
gtL(6, 6, 2) = true;                             % G2: mancata
gtL(2, 7, 2) = true; gtL(3, 7, 2) = true;        % G3: rilevata (P2 condivide (3,7,2))
prL(2, 3, 2) = true; prL(2, 4, 2) = true;        % P1: corrisponde a G1
prL(3, 7, 2) = true;                             % P2: corrisponde a G3
prL(8, 2, 2) = true;                             % P3: componente falsa
expL = struct('gt', 3, 'detected', 2, 'missed', 1, 'pred', 3, 'matched', 2, 'false', 1);
lw = computeLesionWiseMatches(prL, gtL, 26);
rows(end+1, :) = {"L", "GT lesion count", expL.gt, lw.gtComponentCount, 0, true, "26-connected GT components"};
rows(end+1, :) = {"L", "detected GT lesions", expL.detected, lw.detectedGtLesionCount, 0, true, ">= 1 shared voxel"};
rows(end+1, :) = {"L", "missed GT lesions", expL.missed, lw.missedGtLesionCount, 0, true, "no shared voxel"};
rows(end+1, :) = {"L", "predicted components", expL.pred, lw.predictedComponentCount, 0, true, "26-connected"};
rows(end+1, :) = {"L", "matched predicted components", expL.matched, lw.matchedPredictedComponentCount, 0, true, ""};
rows(end+1, :) = {"L", "false predicted components", expL.false, lw.falsePredictedComponentCount, 0, true, "no GT overlap"};
% 26-connettività: due voxel che si toccano solo in un vertice formano UNA componente
gtV = false(4, 4, 4); gtV(1, 1, 1) = true; gtV(2, 2, 2) = true;
lwV = computeLesionWiseMatches(false(4, 4, 4), gtV, 26);
rows(end+1, :) = {"L26", "vertex-touching voxels = 1 component", 1, lwV.gtComponentCount, 0, true, "26-connectivity"};
rows(end+1, :) = {"L26", "missed lesions with empty prediction", 1, lwV.missedGtLesionCount, 0, true, ""};


%% 6. Tabella dei risultati, integrità dopo, riepilogo

t = cell2table(rows, 'VariableNames', {'testId', 'quantity', 'expected', 'actual', 'tolerance', 'mandatory', 'notes'});
t.expected = double(t.expected); t.actual = double(t.actual);
t.absoluteDifference = abs(t.actual - t.expected);
t.passed = t.absoluteDifference <= t.tolerance;
t = t(:, {'testId', 'quantity', 'expected', 'actual', 'absoluteDifference', 'tolerance', 'passed', 'mandatory', 'notes'});

code = char(strjoin(regexprep(splitlines(string(fileread([mfilename('fullpath') '.m']))), '%.*$', ''), newline));
forbidden = {['loadBrainweb' 'Mri('], ['loadBrainweb' 'GroundTruth('], ['generateV4' 'Prediction('], ...
    ['generateFinal' 'Prediction('], ['multi' 'thresh('], ['imop' 'en('], ['sa' 've(']};
noForbidden = ~any(cellfun(@(f) contains(code, f), forbidden));
frozenAfter = all(cellfun(manifestOk, mfTables)) && isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart);
extra = table(["S"; "S"], ["no BrainWeb data, segmentation or MAT saving in this script"; ...
    "frozen result package, Phase-103 outputs and config.m unchanged AFTER"], [1; 1], ...
    [double(noForbidden); double(frozenAfter)], [double(~noForbidden); double(~frozenAfter)], [0; 0], ...
    [noForbidden; frozenAfter], [true; true], ["scope"; "integrity"], ...
    'VariableNames', t.Properties.VariableNames);
t = [t; extra];
writetable(t, fullfile(M, 'phase111_artificial_metric_validation.csv'));

nChecks = height(t); nPassed = nnz(t.passed); nFailed = nChecks - nPassed;
status = ternary(nFailed == 0, "PASS", "FAIL");
summary = sprintf(['Phase 111 - artificial-case validation of the evaluation metrics\n' ...
    'checks: %d\npassed: %d\nfailed: %d\ntolerance (floating metrics): %g\noverall status: %s\n'], ...
    nChecks, nPassed, nFailed, tol, status);
fid = fopen(fullfile(M, 'phase111_validation_summary.txt'), 'w'); fprintf(fid, '%s', summary); fclose(fid);

disp(t(:, {'testId', 'quantity', 'expected', 'actual', 'passed'}));
if nFailed > 0
    disp(t(~t.passed, :));
    error('phase111:failed', 'PHASE 111 FAILED - EVALUATION IMPLEMENTATION DISAGREES WITH KNOWN ARTIFICIAL CASE.');
end
fprintf('\nPHASE 111 ARTIFICIAL METRIC VALIDATION: PASS (%d / %d checks)\n', nPassed, nChecks);


function r = caseRows(id, c, counts, metrics, tol, note)
%CASEROWS Righe di confronto per un caso limite: conteggi [TP FP FN TN] e metriche
%   [Dice IoU Precision Recall Specificity] attese, contro le funzioni del progetto.
    names = ["TP" "FP" "FN" "TN"];
    r = cell(0, 7);
    for i = 1:4
        r(end+1, :) = {id, names(i), counts(i), c.(names(i)), 0, true, note}; %#ok<AGROW>
    end
    actual = [computeDiceFromConfusion(c), computeIoUFromConfusion(c), computePrecisionFromConfusion(c), ...
        computeRecallFromConfusion(c), computeSpecificityFromConfusion(c)];
    mnames = ["Dice" "IoU" "Precision" "Recall" "Specificity"];
    for i = 1:5
        r(end+1, :) = {id, mnames(i), metrics(i), actual(i), tol, true, note}; %#ok<AGROW>
    end
end

function tf = throwsWithId(f, id)
%THROWSWITHID Vero se f lancia un errore con l'identificativo indicato.
    tf = false;
    try
        f();
    catch err
        tf = strcmp(err.identifier, id);
    end
end

function tf = throwsAny(f)
%THROWSANY Vero se f lancia un qualsiasi errore.
    tf = false;
    try
        f();
    catch
        tf = true;
    end
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
    [status, out] = system(sprintf('certutil -hashfile "%s" SHA256', f));
    lines = erase(strtrim(splitlines(string(out))), " ");
    match = lines(strlength(lines) == 64 & ~cellfun(@isempty, regexp(cellstr(lines), '^[0-9a-fA-F]{64}$')));
    if status ~= 0 || numel(match) ~= 1
        error('phase111:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
