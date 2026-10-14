%% Controllo sintetico di computeDiceFromConfusion (maschere artificiali, nessun dato reale)
% Catena: maschere sintetiche -> computeVoxelConfusion -> computeDiceFromConfusion.
% I valori attesi sono calcolati a mano solo come riferimento.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);

sz = [4 5 3];
diceOf = @(p, g) computeDiceFromConfusion(computeVoxelConfusion(p, g));

% 1. Corrispondenza perfetta con positivi
gt1 = false(sz); gt1(2:3, 2:4, 2) = true;
d1 = diceOf(gt1, gt1);

% 2. Disaccordo completo (insiemi disgiunti)
p2 = false(sz); p2(1, 1, 1) = true;
g2 = false(sz); g2(4, 5, 3) = true;
d2 = diceOf(p2, g2);

% 3. Sovrapposizione parziale nota: TP 2, FP 1, FN 3 -> 4 / 8 = 0.5
p3 = false(sz); g3 = false(sz);
p3(1, 1, 1) = true; g3(1, 1, 1) = true;          % TP
p3(1, 2, 1) = true; g3(1, 2, 1) = true;          % TP
p3(2, 2, 2) = true;                              % FP
g3(3, 3, 3) = true; g3(3, 4, 3) = true; g3(4, 4, 3) = true;   % FN
c3 = computeVoxelConfusion(p3, g3);
d3 = computeDiceFromConfusion(c3);

% 4. Predizione vuota, GT non vuoto
d4 = diceOf(false(sz), g3);
% 5. Predizione non vuota, GT vuoto
d5 = diceOf(p3, false(sz));
% 6. Entrambi vuoti (convenzione di progetto)
d6 = diceOf(false(sz), false(sz));
% 7. Corrispondenza perfetta tutta positiva
d7 = diceOf(true(sz), true(sz));
% 8. Simmetria (FP e FN si scambiano)
c8 = computeVoxelConfusion(g3, p3);
d8 = computeDiceFromConfusion(c8);

valid = [d1 d2 d3 d4 d5 d6 d7 d8];
base = struct('TP', 2, 'FP', 1, 'FN', 3, 'TN', 54);
withField = @(name, value) setfield(base, name, value); %#ok<SFLD>
withoutFN = rmfield(base, 'FN');
withTN = base; withTN.TN = 1e6;

checks = {
    "1 perfect match with positives -> 1",            d1 == 1
    "2 complete disagreement -> 0",                   d2 == 0
    "3 known partial overlap TP 2 / FP 1 / FN 3 -> 0.5", c3.TP == 2 && c3.FP == 1 && c3.FN == 3 && abs(d3 - 0.5) < 1e-15
    "4 empty prediction, non-empty GT -> 0",          d4 == 0
    "5 non-empty prediction, empty GT -> 0",          d5 == 0
    "6 both empty -> 1 (project convention)",         d6 == 1
    "7 full-positive perfect match -> 1",             d7 == 1
    "8 symmetry (FP <-> FN swapped, same Dice)",      c8.FP == c3.FN && c8.FN == c3.FP && d8 == d3
    "9 all valid outputs in [0, 1]",                  all(valid >= 0 & valid <= 1)
    "TN does not affect Dice",                        computeDiceFromConfusion(withTN) == computeDiceFromConfusion(base)
    "10 negative count rejected",                     throwsError(@() computeDiceFromConfusion(withField('FP', -1)))
    "11 non-integer count rejected",                  throwsError(@() computeDiceFromConfusion(withField('TP', 1.5)))
    "12a NaN count rejected",                         throwsError(@() computeDiceFromConfusion(withField('FN', NaN)))
    "12b Inf count rejected",                         throwsError(@() computeDiceFromConfusion(withField('TP', Inf)))
    "13 missing required field rejected",             throwsError(@() computeDiceFromConfusion(withoutFN))
    "14 deterministic",                               computeDiceFromConfusion(c3) == d3
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
    error('diceMetricCheck:failed', 'Synthetic Dice check failed.');
end
fprintf('\nSYNTHETIC DICE CHECK: PASS (%d)\n', size(checks, 1));

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
