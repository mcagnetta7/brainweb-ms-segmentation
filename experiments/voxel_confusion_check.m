%% Controllo sintetico di computeVoxelConfusion (nessun dato reale, nessun GT)

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);

sz = [4 5 3];
n = prod(sz);

% 1. Negativo perfetto
c1 = computeVoxelConfusion(false(sz), false(sz));

% 2. Corrispondenza perfetta su un GT non banale
gt2 = false(sz); gt2(2:3, 2:4, 2) = true;
c2 = computeVoxelConfusion(gt2, gt2);

% 3. Tutte e quattro le categorie, conteggi noti a mano
pred3 = false(sz); gt3 = false(sz);
pred3(1, 1, 1) = true; gt3(1, 1, 1) = true;          % TP
pred3(2, 2, 2) = true; gt3(2, 3, 2) = true;          % FP in (2,2,2), FN in (2,3,2)
pred3(4, 5, 3) = true;                               % FP
gt3(3, 1, 1) = true; gt3(3, 2, 1) = true;            % FN
pred3Copy = pred3; gt3Copy = gt3;
c3 = computeVoxelConfusion(pred3, gt3);
% atteso: TP 1, FP 2, FN 3, TN n - 6

% 4. Predizione tutta positiva
c4 = computeVoxelConfusion(true(sz), gt3);

% 5. Predizione tutta negativa
c5 = computeVoxelConfusion(false(sz), gt3);

identities = @(c, p, g) c.TP + c.FP == nnz(p) && c.TP + c.FN == nnz(g) && c.TN + c.FN == nnz(~p) && ...
    c.TN + c.FP == nnz(~g) && c.TP + c.FP + c.FN + c.TN == numel(p) && c.totalVoxels == numel(p) && ...
    isequal(c.confusionMatrix, [c.TN c.FP; c.FN c.TP]);

checks = {
    "1 perfect negative: TP=FP=FN=0, TN=total",       c1.TP == 0 && c1.FP == 0 && c1.FN == 0 && c1.TN == n && identities(c1, false(sz), false(sz))
    "2 perfect match: FP=FN=0, TP=GT positives",      c2.FP == 0 && c2.FN == 0 && c2.TP == nnz(gt2) && c2.TN == n - nnz(gt2) && identities(c2, gt2, gt2)
    "3 all four categories: TP 1, FP 2, FN 3, TN n-6", c3.TP == 1 && c3.FP == 2 && c3.FN == 3 && c3.TN == n - 6 && identities(c3, pred3, gt3)
    "4 all-positive prediction: FN=0, TN=0, consistent", c4.FN == 0 && c4.TN == 0 && c4.TP == nnz(gt3) && identities(c4, true(sz), gt3)
    "5 all-negative prediction: TP=FP=0, FN=GT positives", c5.TP == 0 && c5.FP == 0 && c5.FN == nnz(gt3) && identities(c5, false(sz), gt3)
    "6 size mismatch rejected",                       throwsError(@() computeVoxelConfusion(false(sz), false([4 5 2])))
    "7a non-logical prediction rejected",             throwsError(@() computeVoxelConfusion(double(pred3), gt3))
    "7b non-logical GT rejected",                     throwsError(@() computeVoxelConfusion(pred3, uint8(gt3)))
    "7c empty input rejected",                        throwsError(@() computeVoxelConfusion(false(0, 3), false(0, 3)))
    "8 inputs unchanged",                             isequal(pred3, pred3Copy) && isequal(gt3, gt3Copy)
    "9 deterministic",                                isequal(computeVoxelConfusion(pred3, gt3), c3)
    "matrix orientation [TN FP; FN TP]",              isequal(c3.confusionMatrix, [n - 6 2; 3 1])
    };

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-55s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('voxelConfusionCheck:failed', 'Synthetic confusion check failed.');
end
fprintf('\nSYNTHETIC CONFUSION CHECK: PASS (%d)\n', size(checks, 1));

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
