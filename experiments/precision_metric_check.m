%% Controllo sintetico di computePrecisionFromConfusion (maschere artificiali, nessun dato reale)
% Catena: maschere sintetiche -> computeVoxelConfusion -> computePrecisionFromConfusion.
% I valori attesi sono calcolati a mano solo come riferimento. Nessun test di
% simmetria: la Precision non è simmetrica rispetto a predizione e GT.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);

sz = [4 5 3];

% 1. Tutti i positivi predetti sono corretti (FP = 0, TP > 0), con FN presenti
p1 = false(sz); g1 = false(sz);
p1(1, 1:2, 1) = true; g1(1, 1:3, 1) = true;
c1 = computeVoxelConfusion(p1, g1);

% 2. Tutti i positivi predetti sono sbagliati (TP = 0, FP > 0)
p2 = false(sz); p2(4, 4:5, 3) = true;
g2 = false(sz); g2(1, 1, 1) = true;
c2 = computeVoxelConfusion(p2, g2);

% 3. TP 3, FP 1 -> 0.75
p3 = false(sz); g3 = false(sz);
p3(2, 1:3, 2) = true; g3(2, 1:3, 2) = true;      % TP 3
p3(4, 5, 1) = true;                              % FP 1
c3 = computeVoxelConfusion(p3, g3);

% 4. TP 2, FP 2 -> 0.5
p4 = false(sz); g4 = false(sz);
p4(1, 1:4, 3) = true; g4(1, 1:2, 3) = true;
c4 = computeVoxelConfusion(p4, g4);

% 5. Predizione vuota (convenzione), con lesioni nel GT
c5 = computeVoxelConfusion(false(sz), g3);
% 6. Corrispondenza perfetta tutta positiva
c6 = computeVoxelConfusion(true(sz), true(sz));

% 7. Indipendenza da FN: stessi TP / FP di c3, FN aggiunti nel GT
g7 = g3; g7(3, 3:5, 3) = true;
c7 = computeVoxelConfusion(p3, g7);
% 8. Indipendenza da TN: stessi TP / FP / FN, volume più grande (più TN)
pBig = false([6 7 4]); gBig = false([6 7 4]);
pBig(2, 1:3, 2) = true; gBig(2, 1:3, 2) = true; pBig(4, 5, 1) = true;
c8 = computeVoxelConfusion(pBig, gBig);

prec = @(c) computePrecisionFromConfusion(c);
valid = [prec(c1) prec(c2) prec(c3) prec(c4) prec(c5) prec(c6) prec(c7) prec(c8)];
base = struct('TP', 3, 'FP', 1, 'FN', 2, 'TN', 50);
withField = @(name, value) setfield(base, name, value); %#ok<SFLD>

checks = {
    "1 perfect positive prediction (FP = 0, TP > 0) -> 1", c1.FP == 0 && c1.TP > 0 && c1.FN > 0 && prec(c1) == 1
    "2 all predicted positives wrong (TP = 0, FP > 0) -> 0", c2.TP == 0 && c2.FP > 0 && prec(c2) == 0
    "3 TP 3 / FP 1 -> 0.75",                          c3.TP == 3 && c3.FP == 1 && prec(c3) == 0.75
    "4 TP 2 / FP 2 -> 0.5",                           c4.TP == 2 && c4.FP == 2 && prec(c4) == 0.5
    "5 empty prediction -> 1 (project convention)",   c5.TP == 0 && c5.FP == 0 && c5.FN > 0 && prec(c5) == 1
    "6 full-positive perfect match -> 1",             prec(c6) == 1
    "7 FN independence (same TP / FP, more FN)",      c7.TP == c3.TP && c7.FP == c3.FP && c7.FN > c3.FN && prec(c7) == prec(c3)
    "8 TN independence (same TP / FP / FN, more TN)", c8.TP == c3.TP && c8.FP == c3.FP && c8.FN == c3.FN && c8.TN > c3.TN && prec(c8) == prec(c3)
    "9 all valid outputs in [0, 1]",                  all(valid >= 0 & valid <= 1)
    "10 negative count rejected",                     throwsError(@() prec(withField('TP', -1)))
    "11 non-integer count rejected",                  throwsError(@() prec(withField('FP', 2.5)))
    "12 NaN count rejected",                          throwsError(@() prec(withField('FP', NaN)))
    "13 Inf count rejected",                          throwsError(@() prec(withField('TP', Inf)))
    "14 missing TP field rejected",                   throwsError(@() prec(rmfield(base, 'TP')))
    "15 missing FP field rejected",                   throwsError(@() prec(rmfield(base, 'FP')))
    "16 deterministic",                               prec(c3) == prec(c3) && prec(base) == 0.75
    };

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-58s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('precisionMetricCheck:failed', 'Synthetic Precision check failed.');
end
fprintf('\nSYNTHETIC PRECISION CHECK: PASS (%d)\n', size(checks, 1));

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
