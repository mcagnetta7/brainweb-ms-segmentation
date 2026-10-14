%% Controllo sintetico di computeIoUFromConfusion (maschere artificiali, nessun dato reale)
% Catena: maschere sintetiche -> computeVoxelConfusion -> computeIoUFromConfusion.
% I valori attesi sono calcolati a mano solo come riferimento.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);

sz = [4 5 3];
iouOf = @(p, g) computeIoUFromConfusion(computeVoxelConfusion(p, g));

% 1. Corrispondenza perfetta con positivi
gt1 = false(sz); gt1(2:3, 2:4, 2) = true;
v1 = iouOf(gt1, gt1);

% 2. Insiemi disgiunti
p2 = false(sz); p2(1, 1, 1) = true;
g2 = false(sz); g2(4, 5, 3) = true;
v2 = iouOf(p2, g2);

% 3. Sovrapposizione parziale nota: TP 2, FP 1, FN 3 -> 2 / 6 = 1/3
p3 = false(sz); g3 = false(sz);
p3(1, 1, 1) = true; g3(1, 1, 1) = true;          % TP
p3(1, 2, 1) = true; g3(1, 2, 1) = true;          % TP
p3(2, 2, 2) = true;                              % FP
g3(3, 3, 3) = true; g3(3, 4, 3) = true; g3(4, 4, 3) = true;   % FN
c3 = computeVoxelConfusion(p3, g3);
v3 = computeIoUFromConfusion(c3);

v4 = iouOf(false(sz), g3);                       % 4. predizione vuota, GT non vuoto
v5 = iouOf(p3, false(sz));                       % 5. predizione non vuota, GT vuoto
v6 = iouOf(false(sz), false(sz));                % 6. entrambi vuoti (convenzione)
v7 = iouOf(true(sz), true(sz));                  % 7. corrispondenza perfetta tutta positiva
c8 = computeVoxelConfusion(g3, p3);              % 8. simmetria
v8 = computeIoUFromConfusion(c8);

valid = [v1 v2 v3 v4 v5 v6 v7 v8];
base = struct('TP', 2, 'FP', 1, 'FN', 3, 'TN', 54);
withField = @(name, value) setfield(base, name, value); %#ok<SFLD>
withoutTP = rmfield(base, 'TP');
withTN = base; withTN.TN = 1e6;

checks = {
    "1 perfect match with positives -> 1",            v1 == 1
    "2 complete disagreement -> 0",                   v2 == 0
    "3 known partial overlap TP 2 / FP 1 / FN 3 -> 1/3", c3.TP == 2 && c3.FP == 1 && c3.FN == 3 && abs(v3 - 1/3) < 1e-15
    "4 empty prediction, non-empty GT -> 0",          v4 == 0
    "5 non-empty prediction, empty GT -> 0",          v5 == 0
    "6 both empty -> 1 (project convention)",         v6 == 1
    "7 full-positive perfect match -> 1",             v7 == 1
    "8 symmetry (FP <-> FN swapped, same IoU)",       c8.FP == c3.FN && c8.FN == c3.FP && v8 == v3
    "9 all valid outputs in [0, 1]",                  all(valid >= 0 & valid <= 1)
    "10 TN independence",                             computeIoUFromConfusion(withTN) == computeIoUFromConfusion(base)
    "11 negative count rejected",                     throwsError(@() computeIoUFromConfusion(withField('FN', -2)))
    "12 non-integer count rejected",                  throwsError(@() computeIoUFromConfusion(withField('FP', 0.5)))
    "13 NaN count rejected",                          throwsError(@() computeIoUFromConfusion(withField('TP', NaN)))
    "14 Inf count rejected",                          throwsError(@() computeIoUFromConfusion(withField('FP', Inf)))
    "15 missing required field rejected",             throwsError(@() computeIoUFromConfusion(withoutTP))
    "16 deterministic",                               computeIoUFromConfusion(c3) == v3
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
    error('iouMetricCheck:failed', 'Synthetic IoU check failed.');
end
fprintf('\nSYNTHETIC IoU CHECK: PASS (%d)\n', size(checks, 1));

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
