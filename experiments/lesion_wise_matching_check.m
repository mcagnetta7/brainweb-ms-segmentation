%% Controllo sintetico di computeLesionWiseMatches (volumi artificiali, nessun dato reale)
% Regola fissa: corrispondenza se e solo se le componenti condividono >= 1 voxel;
% connettività 26; relazioni molti-a-molti.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);

sz = [12 12 6];
conn = 26;
matchOf = @(p, g) computeLesionWiseMatches(p, g, conn);

% 1. Corrispondenza perfetta di una lesione
g1 = false(sz); g1(2:3, 2:3, 2) = true; p1 = g1;
r1 = matchOf(p1, g1);
% 2. Sovrapposizione parziale (intersezione nota: 2 voxel)
g2 = false(sz); g2(2:3, 2:3, 2) = true;
p2 = false(sz); p2(3:4, 2:3, 2) = true;
r2 = matchOf(p2, g2);
% 3. Sovrapposizione di un solo voxel
g3 = false(sz); g3(2:3, 2:3, 2) = true;
p3 = false(sz); p3(3:5, 3, 2) = true;                     % condivide solo (3,3,2)
r3 = matchOf(p3, g3);
% 4. Lesione mancata / 5. componente predetta falsa
g4 = false(sz); g4(2:3, 2:3, 2) = true;
p4 = false(sz); p4(9:10, 9:10, 5) = true;
r4 = matchOf(p4, g4);
% 6. Una predetta tocca due lesioni GT distinte (fusione)
g6 = false(sz); g6(2, 2, 2) = true; g6(2, 6, 2) = true;   % separate di 3 voxel
p6 = false(sz); p6(2, 2:6, 2) = true;
r6 = matchOf(p6, g6);
% 7. Due predette toccano una lesione GT (frammentazione)
g7 = false(sz); g7(2, 2:6, 2) = true;
p7 = false(sz); p7(2, 2, 2) = true; p7(2, 6, 2) = true;
r7 = matchOf(p7, g7);
% 8. Caso misto: una rilevata, una mancata, una predetta corrispondente, una falsa
g8 = false(sz); g8(2:3, 2:3, 2) = true; g8(8:9, 2:3, 2) = true;
p8 = false(sz); p8(2:3, 2:3, 2) = true; p8(9:10, 9:10, 5) = true;
p8Copy = p8; g8Copy = g8;
r8 = matchOf(p8, g8);
% 9. Adiacenza diagonale 3D: un solo oggetto con connettività 26
g9 = false(sz); g9(2, 2, 2) = true; g9(3, 3, 3) = true;
r9 = matchOf(g9, g9);
% 14. Nessuna sovrapposizione -> nessuna relazione
r14 = matchOf(p4, g4);

all8 = {r1, r2, r3, r4, r6, r7, r8, r9};
partitionsOk = all(cellfun(@(r) r.detectedGtLesionCount + r.missedGtLesionCount == r.gtComponentCount && ...
    r.matchedPredictedComponentCount + r.falsePredictedComponentCount == r.predictedComponentCount, all8));
uniquePairsOk = all(cellfun(@(r) height(unique(r.matchTable(:, 1:2))) == height(r.matchTable), all8));
positiveOk = all(cellfun(@(r) all(r.matchTable.overlapVoxels > 0), all8));
masks = {p1 g1; p2 g2; p3 g3; p4 g4; p6 g6; p7 g7; p8 g8; g9 g9};
tpOk = true;
for i = 1:size(masks, 1)
    c = computeVoxelConfusion(masks{i, 1}, masks{i, 2});
    tpOk = tpOk && sum(all8{i}.matchTable.overlapVoxels) == c.TP;
end

checks = {
    "1 perfect single-lesion match: 1 GT detected, 1 pred matched, 1 relation", r1.gtComponentCount == 1 && ...
        r1.detectedGtLesionCount == 1 && r1.missedGtLesionCount == 0 && r1.predictedComponentCount == 1 && ...
        r1.matchedPredictedComponentCount == 1 && r1.falsePredictedComponentCount == 0 && height(r1.matchTable) == 1
    "2 partial overlap: detected, matched, overlap = 2 voxels", r2.detectedGtLesionCount == 1 && ...
        r2.matchedPredictedComponentCount == 1 && r2.matchTable.overlapVoxels == 2
    "3 one-voxel overlap counts as a match (> 0 rule)",       r3.detectedGtLesionCount == 1 && r3.matchTable.overlapVoxels == 1
    "4 missed GT lesion",                                     r4.missedGtLesionCount == 1 && r4.detectedGtLesionCount == 0
    "5 false predicted lesion",                               r4.falsePredictedComponentCount == 1 && r4.matchedPredictedComponentCount == 0
    "6 one prediction over two GT lesions: 2 detected, 1 matched, matchedGtCount 2", r6.gtComponentCount == 2 && ...
        r6.detectedGtLesionCount == 2 && r6.predictedComponentCount == 1 && r6.predictedComponentTable.matchedGtCount == 2
    "7 two predictions over one GT lesion: 1 detected, 2 matched, matchedPredictionCount 2", r7.gtComponentCount == 1 && ...
        r7.predictedComponentCount == 2 && r7.matchedPredictedComponentCount == 2 && r7.gtComponentTable.matchedPredictionCount == 2
    "8 mixed case: 1 detected, 1 missed, 1 matched, 1 false", r8.detectedGtLesionCount == 1 && r8.missedGtLesionCount == 1 && ...
        r8.matchedPredictedComponentCount == 1 && r8.falsePredictedComponentCount == 1
    "9 diagonal 3D adjacency = one component under 26-connectivity", r9.gtComponentCount == 1
    "10 component partitions (detected + missed, matched + false)", partitionsOk
    "11 match relations unique",                              uniquePairsOk
    "12 all relation overlaps positive",                      positiveOk
    "13 sum of relation overlaps = whole-volume TP (computeVoxelConfusion)", tpOk
    "14 no overlap -> no relation",                           height(r14.matchTable) == 0
    "15 deterministic",                                       isequal(matchOf(p8, g8), r8)
    "16 input masks unchanged",                               isequal(p8, p8Copy) && isequal(g8, g8Copy)
    "invalid input rejected (non-logical, size mismatch, connectivity 4)", ...
        throwsError(@() computeLesionWiseMatches(double(p1), g1, conn)) && ...
        throwsError(@() computeLesionWiseMatches(p1, false(12, 12, 5), conn)) && ...
        throwsError(@() computeLesionWiseMatches(p1, g1, 4))
    };

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-90s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('lesionWiseCheck:failed', 'Synthetic lesion-wise check failed.');
end
fprintf('\nSYNTHETIC LESION-WISE CHECK: PASS (%d)\n', size(checks, 1));

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
