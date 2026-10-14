%% Controllo sintetico di anisotropicDiffusionSlices e generateExp058Prediction
% Fantoccio deterministico (nessun dato reale, nessun GT), come in EXP-057, con:
% - una lesione racchiusa nella WM con una "coda" larga 1 pixel (tolta dall'apertura,
%   da recuperare con R1);
% - una lesione a cavallo del bordo di S2: parte con T1 di tipo WM (in S2), parte
%   con T1 di tipo GM fuori dall'involucro (solo in S1; da recuperare solo con R2);
% - una lesione iuxtacorticale senza alcun nucleo in S2 (non recuperabile).

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
t1(rim) = 0.6; t2(rim) = 0.6;                             % bordo di volume parziale
vent = false(sz); vent(13:17, 13:17, :) = true;
t1(vent) = 0.1; t2(vent) = 0.95;                          % ventricolo
lesionIn = false(sz); lesionIn(8:10, 8:10, :) = true;
t1(lesionIn) = 0.45; t2(lesionIn) = 0.75;                 % lesione racchiusa
tail = false(sz); tail(11:12, 9, :) = true;
t1(tail) = 0.45; t2(tail) = 0.75;                         % coda sottile della lesione
crossIn = false(sz); crossIn(6:9, 18:20, :) = true;
t1(crossIn) = 0.85; t2(crossIn) = 0.75;                   % parte della lesione dentro S2
crossOut = false(sz); crossOut(4:5, 18:20, :) = true;
t1(crossOut) = 0.45; t2(crossOut) = 0.75;                 % parte della lesione fuori da S2
sulcus = false(sz); sulcus(3:4, 12:14, :) = true;
t1(sulcus) = 0.1; t2(sulcus) = 0.95;                      % solco
lesionOut = false(sz); lesionOut(3:5, 24:26, :) = true;
t1(lesionOut) = 0.45; t2(lesionOut) = 0.75;               % iuxtacorticale, nessun nucleo in S2

rng(58);
noisy = @(v) min(max(v + 0.02 * randn(size(v)), 0), 1);
t1n = noisy(t1); t2n = noisy(t2);
t1Copy = t1; t2Copy = t2; brainCopy = brain;

cfgOf = @(f, a, b, r) struct('id', f + "_" + r, 'filterType', f, 'filterT1', a, 'filterT2', b, 'recovery', r);
v1cfg = struct('id', "S2_TA_M2_G1", 'supportLevel', "S2", 'thresholdRule', "TA", 'openingType', "square", ...
    'openingParameter', 3, 'componentFilter', "minOccupiedSlices", 'componentConnectivity', 26, 'minimumOccupiedSlices', 2);

% Filtro anisotropo
slice = t2n(:, :, 3);
[aOut, gThr] = anisotropicDiffusionSlices(t2n);
defaultEqual = isequal(aOut(:, :, 3), imdiffusefilt(slice));
constantVol = cat(3, zeros(30), 0.3 * ones(30), slice);
[cOut, cThr] = anisotropicDiffusionSlices(constantVol);
wmCore = false(sz); wmCore(20:24, 6:10, :) = true;        % regione uniforme di WM
sdBefore = std(t2n(wmCore)); sdAfter = std(aOut(wmCore));

% Pipeline senza rumore: F0
[p0, d0, i0] = generateExp058Prediction(t1, t2, brain, cfgOf("none", false, false, "R0"));
[p1, ~, i1] = generateExp058Prediction(t1, t2, brain, cfgOf("none", false, false, "R1"));
[p2, ~, i2] = generateExp058Prediction(t1, t2, brain, cfgOf("none", false, false, "R2"));
[sup, ~] = computeT1AnatomicalSupport(t1, brain);
v1Direct = generateExp057Prediction(t2, sup.S2, v1cfg);
segCfg = struct('thresholdMethod', "multithresh", 'multithresh', struct('numberOfThresholds', 2, 'candidateClass', 3));
taCandidate = generateLesionCandidateMask(t2, sup.S2, segCfg);

% Tutte le 21 configurazioni sul fantoccio rumoroso: invarianti
fDefs = {"none", false, false; "gaussian", true, false; "gaussian", false, true; "gaussian", true, true; ...
    "anisotropic", true, false; "anisotropic", false, true; "anisotropic", true, true};
invariantsOk = true; supportsFollowT1 = true; rangeOk = true;
[~, ~, iBase] = generateExp058Prediction(t1n, t2n, brain, cfgOf("none", false, false, "R0"));
for f = 1:size(fDefs, 1)
    out = cell(1, 3);
    for r = 0:2
        [out{r+1}, ~, it] = generateExp058Prediction(t1n, t2n, brain, cfgOf(fDefs{f, 1}, fDefs{f, 2}, fDefs{f, 3}, "R" + r));
        rangeOk = rangeOk && islogical(out{r+1}) && isequal(size(out{r+1}), sz);
    end
    invariantsOk = invariantsOk && ~any(out{1} & ~out{2}, 'all') && ~any(out{2} & ~out{3}, 'all') && ...
        ~any(out{2} & ~it.maskR1, 'all') && ~any(out{3} & ~it.maskR2, 'all') && isequal(out{1}, it.v1Prediction) && ...
        ~any(it.v1Prediction & ~it.maskR1, 'all');
    if ~fDefs{f, 2}
        supportsFollowT1 = supportsFollowT1 && isequal(it.S2, iBase.S2) && isequal(it.S1, iBase.S1);
    end
end
gaussT2 = min(max(gaussianFilterSlices(t2n, 0.5, 3, "replicate"), 0), 1);
[~, dG] = generateExp058Prediction(t1n, t2n, brain, cfgOf("gaussian", false, true, "R0"));
[sG, ~] = computeT1AnatomicalSupport(t1n, brain);
gaussPathOk = isequal(dG.t2ThresholdsNormalized, double(multithresh(gaussT2(sG.S2), 2)));

helperCode = strjoin(regexprep(splitlines(string([fileread(fullfile(cfg.paths.segmentation, 'generateExp058Prediction.m')), ...
    newline, fileread(fullfile(cfg.paths.preprocessing, 'anisotropicDiffusionSlices.m'))])), '%.*$', ''), newline);

checks = {
    "1 anisotropic: same size, finite, inside [0,1], thresholds = 0.10 x slice range", isequal(size(aOut), sz) && ...
        all(isfinite(aOut(:))) && min(aOut(:)) >= 0 && max(aOut(:)) <= 1 && abs(gThr(3) - 0.1 * (max(slice(:)) - min(slice(:)))) < 1e-15
    "2 anisotropic: constant slices returned unchanged (threshold NaN), others filtered", ...
        isequal(cOut(:, :, 1:2), constantVol(:, :, 1:2)) && all(isnan(cThr(1:2))) && ~isequal(cOut(:, :, 3), slice)
    "3 anisotropic reduces noise in a uniform WM region",  sdAfter < sdBefore
    "4 F0_R0 = v1 (generateExp057Prediction S2_TA_M2_G1) on the S2 from T1", isequal(p0, v1Direct) && isequal(i0.S2, sup.S2)
    "5 R1 mask = TA candidate inside S2 before the opening", isequal(i0.maskR1, taCandidate)
    "6 opening removes the thin tail; R1 restores it (connected to the seed)", ~any(p0 & tail, 'all') && all(p1(tail))
    "7 R1 stays inside S2: lesion part outside S2 recovered only by R2", ~any(p1 & crossOut, 'all') && all(p2(crossOut)) && ...
        all(p0(crossIn))
    "8 lesion with no seed in S2 is not recovered (R0, R1, R2)", ~any((p0 | p1 | p2) & lesionOut, 'all')
    "9 CSF (ventricle, sulcus) never predicted (R0, R1, R2)", ~any((p0 | p1 | p2) & (vent | sulcus), 'all')
    "10 noisy phantom, all 21 configs: R0 <= R1 <= R2, R1 <= maskR1, R2 <= maskR2, seeds <= maskR1", invariantsOk && rangeOk
    "11 filtering only T2 leaves S1 / S2 unchanged (supports depend on T1 only)", supportsFollowT1
    "12 Gaussian path: TA re-estimated on the filtered T2 inside S2",  gaussPathOk
    "13 deterministic",                                   isequal(generateExp058Prediction(t1n, t2n, brain, ...
        cfgOf("anisotropic", true, true, "R2")), generateExp058Prediction(t1n, t2n, brain, cfgOf("anisotropic", true, true, "R2")))
    "14 inputs unchanged",                                isequal(t1, t1Copy) && isequal(t2, t2Copy) && isequal(brain, brainCopy)
    "15 no GT argument / no file access in helpers",      nargin('generateExp058Prediction') == 4 && ...
        nargin('anisotropicDiffusionSlices') == 1 && ~contains(helperCode, ['Ground' 'Truth']) && ~contains(helperCode, ['lo' 'ad('])
    "16 invalid configurations rejected (median, none+flag, gaussian without flag, R3, missing field)", ...
        throwsError(@() generateExp058Prediction(t1, t2, brain, cfgOf("median", true, false, "R0"))) && ...
        throwsError(@() generateExp058Prediction(t1, t2, brain, cfgOf("none", true, false, "R0"))) && ...
        throwsError(@() generateExp058Prediction(t1, t2, brain, cfgOf("gaussian", false, false, "R0"))) && ...
        throwsError(@() generateExp058Prediction(t1, t2, brain, cfgOf("none", false, false, "R3"))) && ...
        throwsError(@() generateExp058Prediction(t1, t2, brain, rmfield(cfgOf("none", false, false, "R0"), 'recovery')))
    };

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-100s %s\n', checks{c, 1}, result);
end
fprintf('\nINFO (recorded, not a pass condition): explicit anisotropic call equals imdiffusefilt(slice) defaults: %s\n', ...
    string(defaultEqual));
fprintf('INFO: noise std in uniform WM region before / after anisotropic diffusion: %.5f / %.5f\n', sdBefore, sdAfter);
fprintf('INFO: F0 voxels R0 / R1 / R2 = %d / %d / %d\n', nnz(p0), nnz(p1), nnz(p2));
if any(~[checks{:, 2}])
    error('exp058Check:failed', 'Synthetic EXP-058 filter / recovery check failed.');
end
fprintf('\nSYNTHETIC EXP-058 CHECK: PASS (%d)\n', size(checks, 1));

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
