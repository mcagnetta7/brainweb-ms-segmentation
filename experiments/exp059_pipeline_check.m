%% Controllo sintetico di anisotropicDiffusionVolume3D e generateExp059Prediction
% Fantoccio deterministico (nessun dato reale, nessun GT), come in EXP-057/058, con
% una lesione piccola 2x2 racchiusa nella WM: l'apertura (diamond 1 o square 3) la
% cancella, senza apertura resta.

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
t1(lesionIn) = 0.45; t2(lesionIn) = 0.75;                 % lesione racchiusa 3x3
smallLesion = false(sz); smallLesion(21:22, 21:22, :) = true;
t1(smallLesion) = 0.45; t2(smallLesion) = 0.75;           % lesione piccola 2x2
sulcus = false(sz); sulcus(3:4, 12:14, :) = true;
t1(sulcus) = 0.1; t2(sulcus) = 0.95;                      % solco

rng(59);
t2n = min(max(t2 + 0.02 * randn(sz), 0), 1);
t1Copy = t1; t2Copy = t2; brainCopy = brain;

cfgOf = @(d, m, mp, g) struct('id', d + "_" + m + mp + "_" + g, 'diffusion', d, 'openingType', m, ...
    'openingParameter', mp, 'componentFilter', g, 'componentConnectivity', 26, 'minimumOccupiedSlices', 2);

% Filtro 3D: accoppia le slice (D2 no)
coupling = 0.5 * ones(20, 20, 5);
coupling(:, :, 3) = 0.5 + 0.01 * randn(20, 20);
coupling(10, 10, 3) = 1;
d2c = anisotropicDiffusionSlices(coupling);
[d3c, g3c] = anisotropicDiffusionVolume3D(coupling);
[d3n, g3n] = anisotropicDiffusionVolume3D(t2n);
[constOut, constThr] = anisotropicDiffusionVolume3D(0.3 * ones(8, 8, 3));

% D2_M2_G1 = v2 (generateExp058Prediction F5_R0)
v2 = generateExp058Prediction(t1, t2n, brain, struct('id', "F5_R0", 'filterType', "anisotropic", ...
    'filterT1', false, 'filterT2', true, 'recovery', "R0"));
[pBase, dBase] = generateExp059Prediction(t1, t2n, brain, cfgOf("D2", "square", 3, "minOccupiedSlices"));

% Griglia sul fantoccio rumoroso: M e G riducono soltanto, tutto dentro S2
sup = computeT1AnatomicalSupport(t1, brain);
gridOk = true; s2Ok = true;
for d = ["D2" "D3"]
    m0 = generateExp059Prediction(t1, t2n, brain, cfgOf(d, "none", 0, "none"));
    for mg = {"diamond", 1; "square", 3}.'
        mOnly = generateExp059Prediction(t1, t2n, brain, cfgOf(d, mg{1}, mg{2}, "none"));
        [mG, dd] = generateExp059Prediction(t1, t2n, brain, cfgOf(d, mg{1}, mg{2}, "minOccupiedSlices"));
        gridOk = gridOk && ~any(mOnly & ~m0, 'all') && ~any(mG & ~mOnly, 'all') && islogical(mG) && isequal(size(mG), sz);
        s2Ok = s2Ok && ~any((m0 | mOnly | mG) & ~sup.S2, 'all') && dd.S2Voxels == nnz(sup.S2);
    end
end
[~, dD3] = generateExp059Prediction(t1, t2n, brain, cfgOf("D3", "none", 0, "none"));

% Lesione piccola sul fantoccio senza rumore
pM0 = generateExp059Prediction(t1, t2, brain, cfgOf("D2", "none", 0, "minOccupiedSlices"));
pM1 = generateExp059Prediction(t1, t2, brain, cfgOf("D2", "diamond", 1, "minOccupiedSlices"));
pM2 = generateExp059Prediction(t1, t2, brain, cfgOf("D2", "square", 3, "minOccupiedSlices"));

helperCode = strjoin(regexprep(splitlines(string([fileread(fullfile(cfg.paths.segmentation, 'generateExp059Prediction.m')), ...
    newline, fileread(fullfile(cfg.paths.preprocessing, 'anisotropicDiffusionVolume3D.m'))])), '%.*$', ''), newline);

checks = {
    "1 D3: same size, finite, inside [0,1], threshold = 0.10 x volume range", isequal(size(d3n), sz) && ...
        all(isfinite(d3n(:))) && min(d3n(:)) >= 0 && max(d3n(:)) <= 1 && abs(g3n - 0.1 * (max(t2n(:)) - min(t2n(:)))) < 1e-15
    "2 D3: constant volume returned unchanged (threshold NaN)", isequal(constOut, 0.3 * ones(8, 8, 3)) && isnan(constThr)
    "3 D2 leaves constant neighbour slices unchanged; D3 couples them", isequal(d2c(:, :, 2), coupling(:, :, 2)) && ...
        ~isequal(d3c(:, :, 2), coupling(:, :, 2)) && abs(g3c - 0.1 * (max(coupling(:)) - min(coupling(:)))) < 1e-15
    "4 D2_M2_G1 = v2 (generateExp058Prediction F5_R0)", isequal(pBase, v2)
    "5 D3: TA re-estimated on the 3D-filtered T2 inside S2", ...
        isequal(dD3.t2ThresholdsNormalized, double(multithresh(min(max(d3n(sup.S2), 0), 1), 2)))
    "6 opening and G only remove voxels (M1, M2 <= M0; G1 <= G0), D2 and D3", gridOk
    "7 all outputs logical, inside S2; S2 from the unfiltered T1", s2Ok && dBase.S2Voxels == nnz(sup.S2)
    "8 small 2x2 lesion kept without opening, erased by diamond 1 and square 3", all(pM0(smallLesion)) && ...
        ~any(pM1 & smallLesion, 'all') && ~any(pM2 & smallLesion, 'all')
    "9 CSF (ventricle, sulcus) never predicted without opening", ~any(pM0 & (vent | sulcus), 'all')
    "10 deterministic",                                   isequal(generateExp059Prediction(t1, t2n, brain, ...
        cfgOf("D3", "diamond", 1, "none")), generateExp059Prediction(t1, t2n, brain, cfgOf("D3", "diamond", 1, "none")))
    "11 inputs unchanged",                                isequal(t1, t1Copy) && isequal(t2, t2Copy) && isequal(brain, brainCopy)
    "12 no GT argument / no file access / no T1 filtering in helpers", nargin('generateExp059Prediction') == 4 && ...
        nargin('anisotropicDiffusionVolume3D') == 1 && ~contains(helperCode, ['Ground' 'Truth']) && ...
        ~contains(helperCode, ['lo' 'ad(']) && ~contains(helperCode, ['Slices(' 't1']) && ~contains(helperCode, ['Volume3D(' 't1'])
    "13 invalid configurations rejected (D4, square 5, minSlices 3, missing field)", ...
        throwsError(@() generateExp059Prediction(t1, t2, brain, cfgOf("D4", "none", 0, "none"))) && ...
        throwsError(@() generateExp059Prediction(t1, t2, brain, cfgOf("D2", "square", 5, "none"))) && ...
        throwsError(@() generateExp059Prediction(t1, t2, brain, setfield(cfgOf("D2", "none", 0, "minOccupiedSlices"), ...
            'minimumOccupiedSlices', 3))) && ... %#ok<SFLD>
        throwsError(@() generateExp059Prediction(t1, t2, brain, rmfield(cfgOf("D2", "none", 0, "none"), 'diffusion')))
    };

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-100s %s\n', checks{c, 1}, result);
end
fprintf('\nINFO: voxels without opening / diamond 1 / square 3 (clean phantom, G1) = %d / %d / %d\n', ...
    nnz(pM0), nnz(pM1), nnz(pM2));
if any(~[checks{:, 2}])
    error('exp059Check:failed', 'Synthetic EXP-059 pipeline check failed.');
end
fprintf('\nSYNTHETIC EXP-059 CHECK: PASS (%d)\n', size(checks, 1));

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
