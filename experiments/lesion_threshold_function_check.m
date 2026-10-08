%% Fase 53: controllo software di thresholdLesionCandidates (solo dati sintetici)
% Verifica la funzione che applica la baseline
%   lesionCandidateMask = brainMask AND (volume > threshold)
% usando SOLO array artificiali e soglie artificiali. Non carica dati
% BrainWeb, non usa ground truth, non sceglie nessuna soglia reale: non è
% un esperimento di soglia (quello è la fase 54). Si ferma con un errore se
% un controllo fallisce.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);

checks = cell(0, 2);

% Volume sintetico 3x3x2 con valori noti, maschera che esclude alcuni voxel
volume = reshape([0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 0.5 0.5 0.49 0.51 0.95 0.05 0.75], 3, 3, 2);
brainMask = true(size(volume));
brainMask([2 9 16]) = false;                    % 0.1, 0.8 e 0.95 fuori dalla maschera
artificialThreshold = 0.5;
volumeCopy = volume;
maskCopy = brainMask;

result = thresholdLesionCandidates(volume, brainMask, artificialThreshold);
expected = brainMask & (volume > artificialThreshold);

checks(end+1, :) = {"output same size as input", isequal(size(result), size(volume))};
checks(end+1, :) = {"output logical", islogical(result)};
checks(end+1, :) = {"output equals brainMask AND volume > T", isequal(result, expected)};
checks(end+1, :) = {"never true outside brainMask", ~any(result(~brainMask))};
checks(end+1, :) = {"above-T voxels outside mask stay false", ~result(9) && ~result(16)};
checks(end+1, :) = {"above-T voxels inside mask become true", result(11) && result(15) && result(18)};
checks(end+1, :) = {"voxels equal to T are false (strict >)", ~any(result(volume == artificialThreshold))};
checks(end+1, :) = {"voxels below T are false", ~any(result(volume < artificialThreshold))};
checks(end+1, :) = {"input volume unchanged", isequal(volume, volumeCopy)};
checks(end+1, :) = {"input mask unchanged", isequal(brainMask, maskCopy)};
checks(end+1, :) = {"T = 1 gives no candidates", ~any(thresholdLesionCandidates(volume, brainMask, 1), 'all')};
checks(end+1, :) = {"T = 0 keeps in-mask values > 0 only", ...
    isequal(thresholdLesionCandidates(volume, brainMask, 0), brainMask & volume > 0)};
checks(end+1, :) = {"empty mask gives empty output", ...
    ~any(thresholdLesionCandidates(volume, false(size(volume)), artificialThreshold), 'all')};

% Test negativi: deve uscire l'identificatore d'errore esatto
negativeCases = {
    "size mismatch",            @() thresholdLesionCandidates(volume, true(3, 3, 1), 0.5),        'segmentation:sizeMismatch'
    "non-logical mask",         @() thresholdLesionCandidates(volume, double(brainMask), 0.5),    'segmentation:invalidMask'
    "threshold below 0",        @() thresholdLesionCandidates(volume, brainMask, -0.1),           'segmentation:invalidThreshold'
    "threshold above 1",        @() thresholdLesionCandidates(volume, brainMask, 1.1),            'segmentation:invalidThreshold'
    "threshold NaN",            @() thresholdLesionCandidates(volume, brainMask, NaN),            'segmentation:invalidThreshold'
    "threshold Inf",            @() thresholdLesionCandidates(volume, brainMask, Inf),            'segmentation:invalidThreshold'
    "non-scalar threshold",     @() thresholdLesionCandidates(volume, brainMask, [0.4 0.6]),      'segmentation:invalidThreshold'
    "volume with NaN",          @() thresholdLesionCandidates(setNaN(volume), brainMask, 0.5),    'segmentation:invalidVolume'
    "volume above 1 (raw)",     @() thresholdLesionCandidates(volume * 4095, brainMask, 0.5),     'segmentation:invalidVolume'
    "volume below 0",           @() thresholdLesionCandidates(volume - 0.1, brainMask, 0.5),      'segmentation:invalidVolume'
    };
for c = 1:size(negativeCases, 1)
    raised = '';
    try
        negativeCases{c, 2}();
    catch exception
        raised = exception.identifier;
    end
    checks(end+1, :) = {"rejects " + negativeCases{c, 1}, strcmp(raised, negativeCases{c, 3})}; %#ok<SAGROW>
end

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-46s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase53:checksFailed', 'thresholdLesionCandidates checks failed.');
end
fprintf('\nTHRESHOLD FUNCTION CHECKS: PASS (synthetic data only)\n');


function volume = setNaN(volume)
%SETNAN Copia del volume sintetico con un NaN (solo per il test negativo).
    volume(1) = NaN;
end
