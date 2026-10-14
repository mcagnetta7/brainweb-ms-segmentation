%% Controllo sintetico di computeRecallFromConfusion (maschere artificiali, nessun dato reale)
% Catena: maschere sintetiche -> computeVoxelConfusion -> computeRecallFromConfusion.
% I valori attesi sono calcolati a mano solo come riferimento. Nessun test di
% simmetria: il Recall non è simmetrico rispetto a predizione e GT.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);

sz = [4 5 3];

% 1. Recupero perfetto (FN = 0, TP > 0), con FP presenti
p1 = false(sz); g1 = false(sz);
p1(1, 1:3, 1) = true; g1(1, 1:2, 1) = true;
c1 = computeVoxelConfusion(p1, g1);

% 2. Mancato completo (TP = 0, FN > 0)
p2 = false(sz); p2(4, 5, 3) = true;
g2 = false(sz); g2(1, 1:2, 1) = true;
c2 = computeVoxelConfusion(p2, g2);

% 3. TP 3, FN 1 -> 0.75
p3 = false(sz); g3 = false(sz);
p3(2, 1:3, 2) = true; g3(2, 1:4, 2) = true;
c3 = computeVoxelConfusion(p3, g3);

% 4. TP 2, FN 2 -> 0.5
p4 = false(sz); g4 = false(sz);
p4(1, 1:2, 3) = true; g4(1, 1:4, 3) = true;
c4 = computeVoxelConfusion(p4, g4);

% 5. GT vuoto (convenzione), con FP nella predizione
c5 = computeVoxelConfusion(p3, false(sz));
% 6. Corrispondenza perfetta tutta positiva
c6 = computeVoxelConfusion(true(sz), true(sz));

% 7. Indipendenza da FP: stessi TP / FN di c3, FP aggiunti nella predizione
p7 = p3; p7(4, 3:5, 3) = true;
c7 = computeVoxelConfusion(p7, g3);
% 8. Indipendenza da TN: stessi TP / FP / FN, volume più grande (più TN)
pBig = false([6 7 4]); gBig = false([6 7 4]);
pBig(2, 1:3, 2) = true; gBig(2, 1:4, 2) = true;
c8 = computeVoxelConfusion(pBig, gBig);

rec = @(c) computeRecallFromConfusion(c);
valid = [rec(c1) rec(c2) rec(c3) rec(c4) rec(c5) rec(c6) rec(c7) rec(c8)];
base = struct('TP', 3, 'FP', 2, 'FN', 1, 'TN', 50);
withField = @(name, value) setfield(base, name, value); %#ok<SFLD>

checks = {
    "1 perfect lesion recovery (FN = 0, TP > 0) -> 1", c1.FN == 0 && c1.TP > 0 && c1.FP > 0 && rec(c1) == 1
    "2 complete miss (TP = 0, FN > 0) -> 0",          c2.TP == 0 && c2.FN > 0 && rec(c2) == 0
    "3 TP 3 / FN 1 -> 0.75",                          c3.TP == 3 && c3.FN == 1 && rec(c3) == 0.75
    "4 TP 2 / FN 2 -> 0.5",                           c4.TP == 2 && c4.FN == 2 && rec(c4) == 0.5
    "5 empty GT -> 1 (project convention)",           c5.TP == 0 && c5.FN == 0 && c5.FP > 0 && rec(c5) == 1
    "6 full-positive perfect match -> 1",             rec(c6) == 1
    "7 FP independence (same TP / FN, more FP)",      c7.TP == c3.TP && c7.FN == c3.FN && c7.FP > c3.FP && rec(c7) == rec(c3)
    "8 TN independence (same TP / FP / FN, more TN)", c8.TP == c3.TP && c8.FP == c3.FP && c8.FN == c3.FN && c8.TN > c3.TN && rec(c8) == rec(c3)
    "9 all valid outputs in [0, 1]",                  all(valid >= 0 & valid <= 1)
    "10 negative count rejected",                     throwsError(@() rec(withField('FN', -1)))
    "11 non-integer count rejected",                  throwsError(@() rec(withField('TP', 1.25)))
    "12 NaN count rejected",                          throwsError(@() rec(withField('TP', NaN)))
    "13 Inf count rejected",                          throwsError(@() rec(withField('FN', Inf)))
    "14 missing TP field rejected",                   throwsError(@() rec(rmfield(base, 'TP')))
    "15 missing FN field rejected",                   throwsError(@() rec(rmfield(base, 'FN')))
    "16 deterministic",                               rec(c3) == rec(c3) && rec(base) == 0.75
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
    error('recallMetricCheck:failed', 'Synthetic Recall check failed.');
end
fprintf('\nSYNTHETIC RECALL CHECK: PASS (%d)\n', size(checks, 1));

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
