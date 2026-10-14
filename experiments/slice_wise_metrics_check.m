%% Controllo sintetico di computeSliceWiseMetrics (volume artificiale, nessun dato reale)
% Slice: 1 sovrapposizione perfetta, 2 parziale, 3 solo GT, 4 solo predizione,
% 5 entrambe vuote.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);

sz = [3 4 5];
pred = false(sz); gt = false(sz);
gt(1, 1:2, 1) = true; pred(1, 1:2, 1) = true;                  % 1: perfetta
gt(1:2, 1, 2) = true; pred(1, 1:3, 2) = true;                  % 2: parziale (TP 1, FP 2, FN 1)
gt(2, 2:3, 3) = true;                                          % 3: solo GT
pred(3, 4, 4) = true;                                          % 4: solo predizione
predCopy = pred; gtCopy = gt;

s = computeSliceWiseMetrics(pred, gt);
whole = computeVoxelConfusion(pred, gt);
n = prod(sz(1:2));
flagsOk = isequal(s.hasGtLesion, s.gtPositiveVoxels > 0) && isequal(s.hasPrediction, s.predictedPositiveVoxels > 0) && ...
    isequal(s.hasOverlap, s.tpVoxels > 0) && ...
    isequal(s.diceIouInformative, s.tpVoxels + s.fpVoxels + s.fnVoxels > 0) && ...
    isequal(s.precisionInformative, s.tpVoxels + s.fpVoxels > 0) && isequal(s.recallInformative, s.tpVoxels + s.fnVoxels > 0);

checks = {
    "1 perfect positive overlap slice: Dice 1, IoU 1",          s.dice(1) == 1 && s.iou(1) == 1 && s.tpVoxels(1) == 2
    "2 partial overlap slice: TP 1, FP 2, FN 1, Dice 2/5",      s.tpVoxels(2) == 1 && s.fpVoxels(2) == 2 && s.fnVoxels(2) == 1 && abs(s.dice(2) - 0.4) < 1e-15
    "3 GT positive, prediction empty: Recall 0",                s.predictedPositiveVoxels(3) == 0 && s.fnVoxels(3) == 2 && s.recall(3) == 0
    "4 prediction positive, GT empty: Precision 0",             s.gtPositiveVoxels(4) == 0 && s.fpVoxels(4) == 1 && s.precision(4) == 0
    "5 both empty: formal conventions kept (Dice = IoU = Precision = Recall = 1)", ...
        s.dice(5) == 1 && s.iou(5) == 1 && s.precision(5) == 1 && s.recall(5) == 1 && s.specificity(5) == 1
    "5 both empty: hasGtLesion = hasPrediction = hasOverlap = false", ~s.hasGtLesion(5) && ~s.hasPrediction(5) && ~s.hasOverlap(5) && ...
        ~s.diceIouInformative(5) && ~s.precisionInformative(5) && ~s.recallInformative(5)
    "6 dimensions preserved: slice size 3x4 = 12 voxels",        all(s.totalSliceVoxels == n)
    "7 one row per input slice",                                height(s) == sz(3) && isequal(s.sliceIndex, (1:sz(3)).')
    "8 TP + FP + FN + TN = slice voxels in every slice",        all(s.tpVoxels + s.fpVoxels + s.fnVoxels + s.tnVoxels == n)
    "9 sum of slice TP = whole-volume TP",                      sum(s.tpVoxels) == whole.TP
    "10 sum of slice FP = whole-volume FP",                     sum(s.fpVoxels) == whole.FP
    "11 sum of slice FN = whole-volume FN",                     sum(s.fnVoxels) == whole.FN
    "12 sum of slice TN = whole-volume TN",                     sum(s.tnVoxels) == whole.TN
    "flags agree with counts",                                  flagsOk
    "18 no metric average produced (only per-slice rows)",      height(s) == sz(3) && ~any(contains(s.Properties.VariableNames, ["mean" "avg" "median"]))
    "19 deterministic",                                         isequal(computeSliceWiseMetrics(pred, gt), s)
    "20 inputs unchanged",                                      isequal(pred, predCopy) && isequal(gt, gtCopy)
    "non-3D / size mismatch / non-logical rejected",            throwsError(@() computeSliceWiseMetrics(false(3, 4), false(3, 4))) && ...
        throwsError(@() computeSliceWiseMetrics(pred, false(3, 4, 4))) && throwsError(@() computeSliceWiseMetrics(double(pred), gt))
    };

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-80s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('sliceWiseCheck:failed', 'Synthetic slice-wise check failed.');
end
fprintf('\nSYNTHETIC SLICE-WISE CHECK: PASS (%d)\n', size(checks, 1));

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
