%% Controllo sintetico di computeSpecificityFromConfusion (maschere artificiali, nessun dato reale)
% Catena: maschere sintetiche -> computeVoxelConfusion -> computeSpecificityFromConfusion.
% I valori attesi sono calcolati a mano solo come riferimento. Nessun test di
% simmetria: la Specificity riguarda i negativi reali del GT.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);

sz = [2 2 2];                                    % 8 voxel: fetta 1 = lesione, fetta 2 = non-lesione
gt = false(sz); gt(:, :, 1) = true;

% 1. Classificazione negativa perfetta (FP = 0, TN > 0)
c1 = computeVoxelConfusion(gt, gt);
% 2. Tutti i negativi classificati positivi (TN = 0, FP > 0)
c2 = computeVoxelConfusion(true(sz), gt);
% 3. TN 3, FP 1 -> 0.75
p3 = gt; p3(1, 1, 2) = true;
c3 = computeVoxelConfusion(p3, gt);
% 4. TN 2, FP 2 -> 0.5
p4 = gt; p4(1, 1:2, 2) = true;
c4 = computeVoxelConfusion(p4, gt);
% 5. Nessun negativo nel GT (convenzione)
c5 = computeVoxelConfusion(p3, true(sz));
% 6. Corrispondenza perfetta tutta negativa
c6 = computeVoxelConfusion(false(sz), false(sz));

% 7. Indipendenza da TP: stessi TN / FP di c3, più TP
sz3 = [2 2 3];
g7 = false(sz3); g7(:, :, [1 3]) = true;
p7 = g7; p7(1, 1, 2) = true;
c7 = computeVoxelConfusion(p7, g7);
% 8. Indipendenza da FN: stessi TN / FP di c3, FN aggiunti
p8 = false(sz3); p8(:, :, 1) = true; p8(1, 1, 2) = true;
c8 = computeVoxelConfusion(p8, g7);

spec = @(c) computeSpecificityFromConfusion(c);
valid = [spec(c1) spec(c2) spec(c3) spec(c4) spec(c5) spec(c6) spec(c7) spec(c8)];
base = struct('TP', 4, 'FP', 1, 'FN', 0, 'TN', 3);
withField = @(name, value) setfield(base, name, value); %#ok<SFLD>

checks = {
    "1 perfect negative classification (FP = 0, TN > 0) -> 1", c1.FP == 0 && c1.TN > 0 && spec(c1) == 1
    "2 all negative voxels misclassified (TN = 0, FP > 0) -> 0", c2.TN == 0 && c2.FP > 0 && spec(c2) == 0
    "3 TN 3 / FP 1 -> 0.75",                          c3.TN == 3 && c3.FP == 1 && spec(c3) == 0.75
    "4 TN 2 / FP 2 -> 0.5",                           c4.TN == 2 && c4.FP == 2 && spec(c4) == 0.5
    "5 no negative GT voxels -> 1 (project convention)", c5.TN == 0 && c5.FP == 0 && spec(c5) == 1
    "6 all-negative perfect match -> 1",              c6.TN == prod(sz) && spec(c6) == 1
    "7 TP independence (same TN / FP, more TP)",      c7.TN == c3.TN && c7.FP == c3.FP && c7.TP > c3.TP && spec(c7) == spec(c3)
    "8 FN independence (same TN / FP, more FN)",      c8.TN == c3.TN && c8.FP == c3.FP && c8.FN > c3.FN && spec(c8) == spec(c3)
    "9 all valid outputs in [0, 1]",                  all(valid >= 0 & valid <= 1)
    "10 negative count rejected",                     throwsError(@() spec(withField('TN', -3)))
    "11 non-integer count rejected",                  throwsError(@() spec(withField('FP', 0.5)))
    "12 NaN count rejected",                          throwsError(@() spec(withField('TN', NaN)))
    "13 Inf count rejected",                          throwsError(@() spec(withField('FP', Inf)))
    "14 missing TN field rejected",                   throwsError(@() spec(rmfield(base, 'TN')))
    "15 missing FP field rejected",                   throwsError(@() spec(rmfield(base, 'FP')))
    "16 deterministic",                               spec(c3) == spec(c3) && spec(base) == 0.75
    };

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-62s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('specificityMetricCheck:failed', 'Synthetic Specificity check failed.');
end
fprintf('\nSYNTHETIC SPECIFICITY CHECK: PASS (%d)\n', size(checks, 1));

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
