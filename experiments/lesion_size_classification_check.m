%% Controllo sintetico di classifyGtLesionSizes (valori artificiali, nessun dato reale)

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);

[t1, c1] = classifyGtLesionSizes([1 2 3 4 5]);
perm = [4 1 5 3 2];
[t2, c2] = classifyGtLesionSizes(perm);
[t3, c3] = classifyGtLesionSizes([1 3 3 3 10]);
[t4, c4] = classifyGtLesionSizes(7);
[t5, c5] = classifyGtLesionSizes([6 6 6 6]);
sizesIn = [9 2 5]; sizesCopy = sizesIn;
[t6, c6] = classifyGtLesionSizes(sizesIn);
[t6b, c6b] = classifyGtLesionSizes(sizesIn);

checks = {
    "1 sizes [1 2 3 4 5]: median 3, 1-3 SMALL, 4-5 LARGE", t1 == 3 && isequal(c1, ["SMALL" "SMALL" "SMALL" "LARGE" "LARGE"])
    "2 permutation: same threshold, same class per size",  t2 == t1 && isequal(c2, ["LARGE" "SMALL" "LARGE" "SMALL" "SMALL"])
    "3 ties at the median stay SMALL ([1 3 3 3 10]: 4 SMALL, 1 LARGE)", t3 == 3 && nnz(c3 == "SMALL") == 4 && c3(5) == "LARGE"
    "4 single lesion: valid threshold, SMALL",         t4 == 7 && c4 == "SMALL"
    "5 all equal sizes: all SMALL, no artificial split", t5 == 6 && all(c5 == "SMALL")
    "6 zero size rejected",                            throwsError(@() classifyGtLesionSizes([0 3]))
    "7 negative size rejected",                        throwsError(@() classifyGtLesionSizes([-1 3]))
    "8 non-integer size rejected",                     throwsError(@() classifyGtLesionSizes([1.5 3]))
    "9 NaN rejected",                                  throwsError(@() classifyGtLesionSizes([NaN 3]))
    "10 Inf rejected",                                 throwsError(@() classifyGtLesionSizes([Inf 3]))
    "11 empty vector rejected",                        throwsError(@() classifyGtLesionSizes([]))
    "12 deterministic",                                t6 == t6b && isequal(c6, c6b) && t6 == 5
    "13 sizesIn unchanged",                              isequal(sizesIn, sizesCopy)
    };

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-68s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('lesionSizeCheck:failed', 'Synthetic lesion-size classification check failed.');
end
fprintf('\nSYNTHETIC LESION-SIZE CHECK: PASS (%d)\n', size(checks, 1));

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
