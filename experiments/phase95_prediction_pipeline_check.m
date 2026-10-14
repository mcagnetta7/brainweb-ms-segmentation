%% Controllo sintetico della pipeline della fase 95 (correttezza software, non scelta di parametri)
% Volume sintetico strutturato e deterministico; nessun GT, nessun dato reale.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.preprocessing, cfg.paths.segmentation);

sz = [24 24 6];
vol = 0.1 * ones(sz);
brain = false(sz); brain(3:22, 3:22, :) = true;
vol(brain) = 0.4;
vol(5:12, 5:12, :) = 0.7;                        % regione intermedia
vol(6:9, 6:9, 2:4) = 0.95;                       % blocco luminoso su 3 slice
vol(15:17, 15:17, 3) = 0.95;                     % quadrato 3x3 su una sola slice
vol(20, 20, 5) = 0.95;                           % voxel isolato
vol(14:18, 6:7, 1:6) = 0.85;                     % struttura sottile su tutte le slice
volCopy = vol; brainCopy = brain;

base = struct('id', "P0_T2_M0_G0", 'gaussianEnabled', false, 'gaussianSigma', 0.5, 'gaussianFilterSize', 3, ...
    'gaussianPadding', "replicate", 'numberOfThresholds', 2, 'selectedHighestClass', 3, 'openingType', "none", ...
    'openingParameter', 0, 'componentFilter', "none", 'componentConnectivity', 26, 'minimumOccupiedSlices', 2);
with = @(c, varargin) setfields(c, varargin{:});

[m0, d0] = generatePhase95Prediction(vol, brain, base);
[m0b, d0b] = generatePhase95Prediction(vol, brain, base);
segT2 = struct('thresholdMethod', "multithresh", 'multithresh', struct('numberOfThresholds', 2, 'candidateClass', 3));
segT3 = struct('thresholdMethod', "multithresh", 'multithresh', struct('numberOfThresholds', 3, 'candidateClass', 4));
refT2 = generateLesionCandidateMask(vol, brain, segT2);
refT3 = generateLesionCandidateMask(vol, brain, segT3);
[mT3, dT3] = generatePhase95Prediction(vol, brain, with(base, 'numberOfThresholds', 3, 'selectedHighestClass', 4));
gauss = gaussianFilterSlices(vol, 0.5, 3, "replicate");
refP1 = generateLesionCandidateMask(min(max(gauss, 0), 1), brain, segT2);
mP1 = generatePhase95Prediction(vol, brain, with(base, 'gaussianEnabled', true));
mM1 = generatePhase95Prediction(vol, brain, with(base, 'openingType', "diamond", 'openingParameter', 1));
mM2 = generatePhase95Prediction(vol, brain, with(base, 'openingType', "square", 'openingParameter', 3));
refM1 = false(sz); refM2 = false(sz);
for k = 1:sz(3)
    refM1(:, :, k) = imopen(refT2(:, :, k), strel('diamond', 1));
    refM2(:, :, k) = imopen(refT2(:, :, k), strel('square', 3));
end
refM1 = refM1 & brain; refM2 = refM2 & brain;
mG1 = generatePhase95Prediction(vol, brain, with(base, 'componentFilter', "minOccupiedSlices"));

% Regola G1 isolata su maschere costruite
g = false([10 10 8]);
g(2:3, 2:3, 4) = true;                           % una sola slice -> rimossa
g(6:7, 6:7, 2:3) = true;                         % due slice -> mantenuta
g(2, 8, 6) = true; g(3, 9, 7) = true;            % diagonale 3D (26-connessa) su 2 slice -> mantenuta
[kept, kd] = removeSingleSliceComponents3D(g, 26, 2);
gShift = circshift(g, 1, 3);                     % stessi oggetti, altra posizione assoluta in z
keptShift = removeSingleSliceComponents3D(gShift, 26, 2);
helperCode = strjoin(regexprep(splitlines(string(fileread(fullfile(cfg.paths.segmentation, 'generatePhase95Prediction.m')))), '%.*$', ''), newline);
ruleCode = strjoin(regexprep(splitlines(string(fileread(fullfile(cfg.paths.segmentation, 'removeSingleSliceComponents3D.m')))), '%.*$', ''), newline);

checks = {
    "1 output logical",                               islogical(m0) && islogical(mG1) && islogical(mP1)
    "2 output same size as input",                    isequal(size(m0), sz) && isequal(size(mG1), sz)
    "3 no output outside brainMask",                  ~any(m0 & ~brain, 'all') && ~any(mM2 & ~brain, 'all') && ~any(mP1 & ~brain, 'all')
    "4 deterministic repeated execution",             isequal(m0, m0b) && isequaln(d0, d0b)
    "5 inputs unchanged",                             isequal(vol, volCopy) && isequal(brain, brainCopy)
    "6 P0 thresholds the unfiltered normalized volume", isequal(m0, refT2)
    "7 P1 = Gaussian sigma 0.5, 3x3, replicate before thresholding", isequal(mP1, refP1)
    "8 T2 = 2 thresholds, highest Class 3",           numel(d0.thresholdsNormalized) == 2 && isequal(m0, refT2)
    "9 T3 = 3 thresholds, highest Class 4",           numel(dT3.thresholdsNormalized) == 3 && isequal(mT3, refT3)
    "10 M0 applies no morphology",                    isequal(m0, refT2) && d0.candidateVoxels == d0.afterMorphologyVoxels
    "11 M1 = one diamond-1 2D opening",               isequal(mM1, refM1)
    "12 M2 = one square-3 2D opening",                isequal(mM2, refM2)
    "13 G0 removes no component",                     d0.componentDetails.removedComponentCount == 0 && d0.finalVoxels == d0.afterMorphologyVoxels
    "14 G1 uses 26-connectivity (3D diagonal = one object)", kd.componentCount == 3 && kept(2, 8, 6) && kept(3, 9, 7)
    "15 G1 removes every single-slice component",     ~any(kept(:, :, 4), 'all') && kd.removedComponentCount == 1
    "16 G1 keeps every component spanning >= 2 slices", all(kept(6:7, 6:7, 2:3), 'all') && kd.keptComponentCount == 2
    "G1 inside the pipeline: subset of M0, single-slice objects removed", ~any(mG1 & ~m0, 'all')
    "17 no absolute slice-index rule (shifted volume -> shifted result)", isequal(keptShift, circshift(kept, 1, 3)) && ...
        ~contains(ruleCode, ['firstSl' 'ice']) && ~contains(ruleCode, ['slice' 'Range'])
    "18 no GT argument in the segmentation helper",   nargin('generatePhase95Prediction') == 3 && ~contains(helperCode, ['Ground' 'Truth'])
    "19 configuration alone determines behaviour",    ~isequal(m0, mM2) && isequal(generatePhase95Prediction(vol, brain, base), m0)
    "20 invalid configurations rejected (sigma 0.6, N 4, square 5, minSlices 3, missing field)", ...
        throwsError(@() generatePhase95Prediction(vol, brain, with(base, 'gaussianEnabled', true, 'gaussianSigma', 0.6))) && ...
        throwsError(@() generatePhase95Prediction(vol, brain, with(base, 'numberOfThresholds', 4, 'selectedHighestClass', 5))) && ...
        throwsError(@() generatePhase95Prediction(vol, brain, with(base, 'openingType', "square", 'openingParameter', 5))) && ...
        throwsError(@() generatePhase95Prediction(vol, brain, with(base, 'componentFilter', "minOccupiedSlices", 'minimumOccupiedSlices', 3))) && ...
        throwsError(@() generatePhase95Prediction(vol, brain, rmfield(base, 'openingType')))
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
    error('phase95Check:failed', 'Synthetic Phase-95 pipeline check failed.');
end
fprintf('\nSYNTHETIC PHASE-95 PIPELINE CHECK: PASS (%d)\n', size(checks, 1));

function s = setfields(s, varargin)
%SETFIELDS Copia di s con i campi indicati sostituiti.
    for i = 1:2:numel(varargin)
        s.(varargin{i}) = varargin{i + 1};
    end
end

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
