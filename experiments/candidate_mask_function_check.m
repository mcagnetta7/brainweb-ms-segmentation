%% Fase 60: controllo di generateLesionCandidateMask (solo dati sintetici)
% Verifica di buon senso del generatore riutilizzabile dei candidati. Solo
% un piccolo volume artificiale: nessun dato BrainWeb, nessun ground truth.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);
segCfg = cfg.segmentation;

checks = cell(0, 2);

% Volume 4x4x2 con tre gruppi di intensità dentro la maschera
volume = reshape([0.10 0.12 0.11 0.13 0.45 0.47 0.46 0.44 0.80 0.82 0.79 0.81 0.09 0.48 0.83 0.95 ...
                  0.11 0.10 0.46 0.45 0.81 0.80 0.12 0.47 0.83 0.13 0.44 0.82 0.99 0.98 0.97 0.96], 4, 4, 2);
mask = true(size(volume));
mask(:, :, 2) = false;
mask(1:3, 1:2, 2) = true;                        % i valori alti di slice 2 fuori maschera
volumeCopy = volume;
maskCopy = mask;

[candidate, details] = generateLesionCandidateMask(volume, mask, segCfg);
levels = details.thresholdsNormalized;
classVolume = imquantize(volume, levels);

checks(end+1, :) = {"exactly two thresholds", numel(levels) == 2};
checks(end+1, :) = {"thresholds finite", all(isfinite(levels))};
checks(end+1, :) = {"threshold 1 < threshold 2", levels(1) < levels(2)};
checks(end+1, :) = {"classes 1,2,3 inside mask", isequal(unique(classVolume(mask)).', 1:3)};
checks(end+1, :) = {"class counts sum to nnz(mask)", sum(details.classCounts) == nnz(mask)};
checks(end+1, :) = {"candidate logical", islogical(candidate)};
checks(end+1, :) = {"candidate = mask & (class == 3)", isequal(candidate, mask & (classVolume == 3))};
checks(end+1, :) = {"candidate = mask & (volume > upper)", isequal(candidate, mask & (volume > levels(2)))};
checks(end+1, :) = {"no candidate outside mask", ~any(candidate(~mask))};
checks(end+1, :) = {"input volume unchanged", isequal(volume, volumeCopy)};
checks(end+1, :) = {"input mask unchanged", isequal(mask, maskCopy)};
[candidateAgain, detailsAgain] = generateLesionCandidateMask(volume, mask, segCfg);
checks(end+1, :) = {"repeated execution deterministic", isequal(candidate, candidateAgain) && ...
    isequal(details, detailsAgain)};

% Ingressi non validi rifiutati
checks(end+1, :) = {"non-numeric volume rejected", rejects(@() generateLesionCandidateMask(string(volume), mask, segCfg))};
checks(end+1, :) = {"complex volume rejected", rejects(@() generateLesionCandidateMask(complex(volume, 1), mask, segCfg))};
nonFinite = volume; nonFinite(1) = NaN;
checks(end+1, :) = {"non-finite volume rejected", rejects(@() generateLesionCandidateMask(nonFinite, mask, segCfg))};
checks(end+1, :) = {"volume outside [0,1] rejected", rejects(@() generateLesionCandidateMask(volume * 4095, mask, segCfg))};
checks(end+1, :) = {"non-logical mask rejected", rejects(@() generateLesionCandidateMask(volume, double(mask), segCfg))};
checks(end+1, :) = {"size mismatch rejected", rejects(@() generateLesionCandidateMask(volume, mask(:, :, 1), segCfg))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-46s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase60:checksFailed', 'Candidate-mask generator sanity checks failed.');
end
fprintf('\nCANDIDATE MASK GENERATOR CHECKS: PASS (synthetic data only)\n');


function tf = rejects(call)
%REJECTS true se la chiamata genera un errore.
    try
        call();
        tf = false;
    catch
        tf = true;
    end
end
