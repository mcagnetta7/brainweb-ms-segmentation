%% Fase 58: controllo minimo di multithresh + imquantize (solo dati sintetici)
% Verifica di buon senso dei built-in MATLAB multithresh (Otsu multi-livello)
% e imquantize usati in EXP-026. Solo array artificiali normalizzati: nessun
% dato BrainWeb, nessun ground truth. Non è un esperimento e non reimplementa
% Otsu multi-livello.

checks = cell(0, 2);

% Valori sintetici con tre gruppi ben separati, in [0,1]
values = [0.10 0.12 0.11 0.13 0.09 0.45 0.47 0.46 0.44 0.48 0.80 0.82 0.79 0.81 0.83].';
valuesCopy = values;
levels = multithresh(values, 2);
fprintf('class(levels) = %s\n', class(levels));
levels = double(levels);                         % conversione esatta (single -> double)

checks(end+1, :) = {"multithresh returns exactly two thresholds", numel(levels) == 2};
checks(end+1, :) = {"thresholds finite", all(isfinite(levels))};
checks(end+1, :) = {"thresholds inside [0,1]", all(levels >= 0 & levels <= 1)};
checks(end+1, :) = {"threshold 1 < threshold 2", levels(1) < levels(2)};
checks(end+1, :) = {"repeated call gives identical thresholds", isequal(double(multithresh(values, 2)), levels)};
checks(end+1, :) = {"thresholds separate the three groups", ...
    levels(1) > 0.13 && levels(1) < 0.44 && levels(2) > 0.48 && levels(2) < 0.79};

classes = imquantize(values, levels);
checks(end+1, :) = {"imquantize labels are 1..3", isequal(unique(classes(:)).', 1:3)};
checks(end+1, :) = {"highest class = values > upper threshold", isequal(classes == 3, values > levels(2))};
checks(end+1, :) = {"class counts sum to number of elements", ...
    sum(histcounts(classes, 0.5:1:3.5)) == numel(values)};
checks(end+1, :) = {"source values unchanged", isequal(values, valuesCopy)};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-46s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase58:checksFailed', 'multithresh sanity checks failed.');
end
fprintf('\nMULTITHRESH SANITY CHECKS: PASS (synthetic data only)\n');
