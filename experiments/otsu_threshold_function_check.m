%% Fase 56: controllo minimo di graythresh + thresholdLesionCandidates (solo dati sintetici)
% Verifica di buon senso del built-in MATLAB graythresh (Otsu) usato in
% EXP-024 e della sua combinazione con thresholdLesionCandidates. Solo
% array artificiali normalizzati: nessun dato BrainWeb, nessun ground truth.
% Non è un esperimento e non reimplementa Otsu.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);

checks = cell(0, 2);

% Valori sintetici con due gruppi ben separati, in [0,1]
values = [0.10 0.12 0.11 0.13 0.09 0.80 0.82 0.79 0.81 0.83].';
valuesCopy = values;
T = graythresh(values);

checks(end+1, :) = {"graythresh returns one numeric scalar", isnumeric(T) && isscalar(T) && isreal(T)};
checks(end+1, :) = {"threshold finite", isfinite(T)};
checks(end+1, :) = {"threshold inside [0,1]", T >= 0 && T <= 1};
checks(end+1, :) = {"repeated call gives identical threshold", graythresh(values) == T};
checks(end+1, :) = {"threshold separates the two synthetic groups", T > 0.13 && T < 0.79};
checks(end+1, :) = {"synthetic values unchanged", isequal(values, valuesCopy)};

% Combinazione con thresholdLesionCandidates su un volume sintetico 2x5
volume = reshape(values, 2, 5);
brainMask = true(size(volume));
brainMask(1, 5) = false;                         % un valore alto escluso dalla maschera
volumeCopy = volume;
candidate = thresholdLesionCandidates(volume, brainMask, T);
checks(end+1, :) = {"candidate = brainMask & (volume > T)", isequal(candidate, brainMask & (volume > T))};
checks(end+1, :) = {"no candidate outside the synthetic mask", ~any(candidate(~brainMask))};
checks(end+1, :) = {"synthetic volume unchanged", isequal(volume, volumeCopy)};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-46s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase56:checksFailed', 'Otsu sanity checks failed.');
end
fprintf('\nOTSU SANITY CHECKS: PASS (synthetic data only)\n');
