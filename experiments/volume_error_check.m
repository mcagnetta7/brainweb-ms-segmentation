%% Controllo sintetico di computeVolumeErrorPercent (valori artificiali, nessun dato reale)

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);

e1 = computeVolumeErrorPercent(100, 100);
e2 = computeVolumeErrorPercent(100, 125);
e3 = computeVolumeErrorPercent(100, 75);
e4 = computeVolumeErrorPercent(100, 0);
e5 = computeVolumeErrorPercent(10, 210);
eMm3 = computeVolumeErrorPercent(1000, 1250);
eCm3 = computeVolumeErrorPercent(1, 1.25);
gtIn = 100; predIn = 125;
eRepeat = computeVolumeErrorPercent(gtIn, predIn);

checks = {
    "1 perfect match: signed 0, absolute 0, error 0 %",       e1.signedDifference == 0 && e1.absoluteDifference == 0 && e1.volumeErrorPercent == 0
    "2 overestimate 125 vs 100: signed +25, abs 25, 25 %",    e2.signedDifference == 25 && e2.absoluteDifference == 25 && e2.volumeErrorPercent == 25
    "3 underestimate 75 vs 100: signed -25, abs 25, 25 % (absolute)", e3.signedDifference == -25 && e3.absoluteDifference == 25 && e3.volumeErrorPercent == 25
    "4 zero prediction, GT 100: signed -100, abs 100, 100 %", e4.signedDifference == -100 && e4.absoluteDifference == 100 && e4.volumeErrorPercent == 100
    "5 large over-segmentation 210 vs 10: abs 200, 2000 % (not capped)", e5.absoluteDifference == 200 && e5.volumeErrorPercent == 2000
    "6 unit-scale invariance (mm^3 vs cm^3): both 25 %",      abs(eMm3.volumeErrorPercent - 25) < 1e-12 && abs(eCm3.volumeErrorPercent - 25) < 1e-12
    "7 negative GT rejected",                                 throwsError(@() computeVolumeErrorPercent(-1, 10))
    "8 zero GT rejected",                                     throwsError(@() computeVolumeErrorPercent(0, 10))
    "9 NaN GT rejected",                                      throwsError(@() computeVolumeErrorPercent(NaN, 10))
    "10 Inf GT rejected",                                     throwsError(@() computeVolumeErrorPercent(Inf, 10))
    "11 negative prediction rejected",                        throwsError(@() computeVolumeErrorPercent(10, -1))
    "12 NaN prediction rejected",                             throwsError(@() computeVolumeErrorPercent(10, NaN))
    "13 Inf prediction rejected",                             throwsError(@() computeVolumeErrorPercent(10, Inf))
    "14 non-scalar input rejected",                           throwsError(@() computeVolumeErrorPercent([10 20], 10)) && ...
                                                               throwsError(@() computeVolumeErrorPercent(10, [1 2]))
    "15 deterministic",                                       isequal(computeVolumeErrorPercent(100, 125), e2) && isequal(eRepeat, e2)
    "16 inputs unchanged",                                    gtIn == 100 && predIn == 125
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
    error('volumeErrorCheck:failed', 'Synthetic volume-error check failed.');
end
fprintf('\nSYNTHETIC VOLUME-ERROR CHECK: PASS (%d)\n', size(checks, 1));

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
