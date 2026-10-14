%% Controllo sintetico di computeT1AnatomicalSupport e generateExp057Prediction
% Fantoccio deterministico (nessun dato reale, nessun GT): anello di WM (T1 alto)
% che racchiude un ventricolo (T1 basso, T2 molto alto) e una lesione (T1 come la
% GM, T2 alto); corteccia esterna (GM), un solco (T1 basso, T2 molto alto) e una
% lesione iuxtacorticale fuori dall'anello.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.preprocessing, cfg.paths.segmentation);

sz = [30 30 5];
brain = false(sz); brain(2:29, 2:29, :) = true;
t1 = zeros(sz); t2 = zeros(sz);
t1(brain) = 0.45; t2(brain) = 0.5;                       % GM / corteccia
wm = false(sz); wm(6:25, 6:25, :) = true;
t1(wm) = 0.85; t2(wm) = 0.3;                              % WM
rim = false(sz); rim(12:18, 12:18, :) = true;
t1(rim) = 0.6; t2(rim) = 0.6;                             % bordo di volume parziale del ventricolo
vent = false(sz); vent(13:17, 13:17, :) = true;
rim = rim & ~vent;
t1(vent) = 0.1; t2(vent) = 0.95;                          % ventricolo
lesionIn = false(sz); lesionIn(8:10, 8:10, :) = true;
t1(lesionIn) = 0.45; t2(lesionIn) = 0.75;                 % lesione racchiusa nella WM
sulcus = false(sz); sulcus(3:4, 14:16, :) = true;
t1(sulcus) = 0.1; t2(sulcus) = 0.95;                      % solco
lesionOut = false(sz); lesionOut(3:5, 22:24, :) = true;
t1(lesionOut) = 0.45; t2(lesionOut) = 0.75;               % lesione iuxtacorticale (non racchiusa)
t1Copy = t1; t2Copy = t2; brainCopy = brain;

[sup, sd] = computeT1AnatomicalSupport(t1, brain);
[sup2, sd2] = computeT1AnatomicalSupport(t1, brain);
cfgOf = @(s, t, m, mp, g) struct('id', s + "_" + t, 'supportLevel', s, 'thresholdRule', t, 'openingType', m, ...
    'openingParameter', mp, 'componentFilter', g, 'componentConnectivity', 26, 'minimumOccupiedSlices', 2);

[pS0, dS0] = generateExp057Prediction(t2, sup.S0, cfgOf("S0", "TA", "none", 0, "none"));
[pS2, dS2] = generateExp057Prediction(t2, sup.S2, cfgOf("S2", "TA", "none", 0, "none"));
[pTB, dTB] = generateExp057Prediction(t2, sup.S1, cfgOf("S1", "TB", "none", 0, "none"));
baseCfg = cfgOf("S0", "TA", "square", 3, "minOccupiedSlices");
pBase = generateExp057Prediction(t2, sup.S0, baseCfg);
p95cfg = struct('id', "P0_T2_M2_G1", 'gaussianEnabled', false, 'gaussianSigma', 0.5, 'gaussianFilterSize', 3, ...
    'gaussianPadding', "replicate", 'numberOfThresholds', 2, 'selectedHighestClass', 3, 'openingType', "square", ...
    'openingParameter', 3, 'componentFilter', "minOccupiedSlices", 'componentConnectivity', 26, 'minimumOccupiedSlices', 2);
p95 = generatePhase95Prediction(t2, brain, p95cfg);
pM2 = generateExp057Prediction(t2, sup.S2, cfgOf("S2", "TA", "square", 3, "none"));
helperCode = strjoin(regexprep(splitlines(string(fileread(fullfile(cfg.paths.segmentation, 'generateExp057Prediction.m')))), '%.*$', ''), newline);
supportCode = strjoin(regexprep(splitlines(string(fileread(fullfile(cfg.paths.segmentation, 'computeT1AnatomicalSupport.m')))), '%.*$', ''), newline);

checks = {
    "1 S0 = brain mask",                                  isequal(sup.S0, brain)
    "2 S1 excludes ventricle and sulcus (T1-low), keeps WM, GM and both lesions", ...
        ~any(sup.S1 & (vent | sulcus), 'all') && all(sup.S1(wm & ~vent)) && all(sup.S1(lesionIn | lesionOut))
    "3 S2 keeps WM and the enclosed lesion (imfill per slice)", all(sup.S2(wm & ~vent)) && all(sup.S2(lesionIn))
    "4 S2 excludes the filled ventricle (T1-low subtracted after filling)", ~any(sup.S2 & vent, 'all')
    "5 S2 excludes cortex, sulcus and the non-enclosed lesion", ~any(sup.S2 & (~wm & brain), 'all') && ~any(sup.S2 & lesionOut, 'all')
    "6 S2 subset of S1 subset of S0",                     ~any(sup.S2 & ~sup.S1, 'all') && ~any(sup.S1 & ~sup.S0, 'all')
    "7 T1 partition: 2 thresholds, class counts reported", numel(sd.t1ThresholdsNormalized) == 2 && sd.t1LowVoxels == nnz(vent | sulcus)
    "8 TA threshold re-estimated inside the support (S0 vs S2 differ)", ...
        isequal(dS2.thresholdsNormalized, double(multithresh(t2(sup.S2), 2))) && ~isequal(dS0.thresholdsNormalized, dS2.thresholdsNormalized)
    "9 TB = graythresh inside the support, voxels > threshold", dTB.thresholdsNormalized == graythresh(t2(sup.S1)) && ...
        isequal(pTB, sup.S1 & t2 > graythresh(t2(sup.S1)))
    "10 outputs logical, same size, inside their support", islogical(pS2) && isequal(size(pS2), sz) && ...
        ~any(pS2 & ~sup.S2, 'all') && ~any(pTB & ~sup.S1, 'all') && ~any(pM2 & ~sup.S2, 'all')
    "11 S2 + TA finds the enclosed lesion and not the CSF",  all(pS2(lesionIn)) && ~any(pS2 & (vent | sulcus), 'all')
    "12 S0 + TA selects CSF (the current failure mode)",   any(pS0 & vent, 'all')
    "partial-volume rim stays inside S2 (declared failure mode, not removed by T1-low)", all(sup.S2(rim))
    "13 baseline S0_TA_M2_G1 = EXP-056 generator P0_T2_M2_G1", isequal(pBase, p95)
    "14 deterministic",                                   isequal(sup, sup2) && isequal(sd, sd2) && ...
        isequal(generateExp057Prediction(t2, sup.S2, cfgOf("S2", "TA", "none", 0, "none")), pS2)
    "15 inputs unchanged",                                isequal(t1, t1Copy) && isequal(t2, t2Copy) && isequal(brain, brainCopy)
    "16 no GT argument / no file access in helpers",      nargin('generateExp057Prediction') == 3 && nargin('computeT1AnatomicalSupport') == 2 && ...
        ~contains(helperCode + supportCode, ['Ground' 'Truth']) && ~contains(helperCode + supportCode, ['lo' 'ad('])
    "17 invalid configurations rejected (S3, TC, square 5, minSlices 3, missing field)", ...
        throwsError(@() generateExp057Prediction(t2, sup.S0, cfgOf("S3", "TA", "none", 0, "none"))) && ...
        throwsError(@() generateExp057Prediction(t2, sup.S0, cfgOf("S0", "TC", "none", 0, "none"))) && ...
        throwsError(@() generateExp057Prediction(t2, sup.S0, cfgOf("S0", "TA", "square", 5, "none"))) && ...
        throwsError(@() generateExp057Prediction(t2, sup.S0, setfield(baseCfg, 'minimumOccupiedSlices', 3))) && ... %#ok<SFLD>
        throwsError(@() generateExp057Prediction(t2, sup.S0, rmfield(baseCfg, 'thresholdRule')))
    "18 non-normalized T1 rejected",                      throwsError(@() computeT1AnatomicalSupport(t1 * 2, brain))
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
    error('exp057Check:failed', 'Synthetic EXP-057 support / pipeline check failed.');
end
fprintf('\nSYNTHETIC EXP-057 CHECK: PASS (%d)\n', size(checks, 1));

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
