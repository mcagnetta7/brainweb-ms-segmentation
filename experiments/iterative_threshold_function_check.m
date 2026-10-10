%% Fase 55: controllo software di estimateIterativeThreshold (solo dati sintetici)
% Verifica lo stimatore iterativo del corso con array artificiali. Non
% carica dati BrainWeb, non usa ground truth: non è un esperimento.
% Si ferma con un errore se un controllo fallisce.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);

checks = cell(0, 2);

% Dati sintetici bimodali noti
values = [0.10 0.12 0.11 0.13 0.09 0.80 0.82 0.79 0.81 0.83 0.50];
valuesCopy = values;
epsilon = 0.5 / 4095;
[threshold, history] = estimateIterativeThreshold(values, epsilon, 1000);

nIter = numel(history.iteration);
consistent = true;
for i = 1:nIter
    T = history.thresholdCurrent(i);
    high = values >= T;
    low = values < T;
    consistent = consistent && ...
        abs(history.meanLow(i) - mean(values(low))) < 1e-15 && ...
        abs(history.meanHigh(i) - mean(values(high))) < 1e-15 && ...
        history.countLow(i) == nnz(low) && history.countHigh(i) == nnz(high) && ...
        history.thresholdNext(i) == (history.meanLow(i) + history.meanHigh(i)) / 2 && ...
        history.delta(i) == abs(history.thresholdNext(i) - T);
    if i > 1
        consistent = consistent && history.thresholdCurrent(i) == history.thresholdNext(i - 1);
    end
end

checks(end+1, :) = {"T0 = mean(values)", history.initialThreshold == mean(values) ...
    && history.thresholdCurrent(1) == mean(values)};
checks(end+1, :) = {"partition >= T / < T and group means", consistent};
checks(end+1, :) = {"converged: last delta < epsilon", history.delta(end) < epsilon};
checks(end+1, :) = {"earlier deltas >= epsilon", all(history.delta(1:end-1) >= epsilon)};
checks(end+1, :) = {"final threshold = last T_next", threshold == history.thresholdNext(end)};
checks(end+1, :) = {"threshold finite and inside data range", isfinite(threshold) ...
    && threshold >= min(values) && threshold <= max(values)};
checks(end+1, :) = {"bimodal case separates the two groups", threshold > 0.13 && threshold < 0.79};
[threshold2, history2] = estimateIterativeThreshold(values, epsilon, 1000);
checks(end+1, :) = {"deterministic output", threshold2 == threshold && isequal(history2, history)};
checks(end+1, :) = {"input values unchanged", isequal(values, valuesCopy)};
checks(end+1, :) = {"column and row input give same result", ...
    estimateIterativeThreshold(values(:), epsilon, 1000) == threshold};

% Test negativi: deve uscire l'identificatore d'errore esatto
negativeCases = {
    "empty input",              @() estimateIterativeThreshold([], epsilon, 1000),               'segmentation:invalidValues'
    "NaN input",                @() estimateIterativeThreshold([0.1 NaN 0.9], epsilon, 1000),    'segmentation:invalidValues'
    "Inf input",                @() estimateIterativeThreshold([0.1 Inf 0.9], epsilon, 1000),    'segmentation:invalidValues'
    "epsilon = 0",              @() estimateIterativeThreshold(values, 0, 1000),                 'segmentation:invalidEpsilon'
    "negative epsilon",         @() estimateIterativeThreshold(values, -1e-3, 1000),             'segmentation:invalidEpsilon'
    "non-integer maxIterations", @() estimateIterativeThreshold(values, epsilon, 2.5),           'segmentation:invalidMaxIterations'
    "maxIterations = 0",        @() estimateIterativeThreshold(values, epsilon, 0),              'segmentation:invalidMaxIterations'
    "constant values (empty low group)", @() estimateIterativeThreshold([0.4 0.4 0.4], epsilon, 1000), 'segmentation:emptyPartition'
    "guard reached (no convergence)", @() estimateIterativeThreshold(values, epsilon, 1),        'segmentation:notConverged'
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
    error('phase55:checksFailed', 'estimateIterativeThreshold checks failed.');
end
fprintf('\nITERATIVE THRESHOLD FUNCTION CHECKS: PASS (synthetic data only)\n');
