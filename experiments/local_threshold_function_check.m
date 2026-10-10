%% Fase 59: controllo di localMeanStdThreshold2D (solo dati sintetici)
% Verifica di buon senso delle statistiche locali mascherate usate in
% EXP-027. Solo piccoli array artificiali: nessun dato BrainWeb, nessun
% ground truth. Non è un esperimento. Le statistiche di riferimento sono
% calcolate qui con cicli espliciti, indipendenti dall'implementazione.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);

checks = cell(0, 2);
tol = 1e-12;

% 1-2. Immagine costante dentro la maschera
constantImage = 7 * ones(6, 5);
constantMask = true(6, 5);
[~, T, ~, s] = localMeanStdThreshold2D(constantImage, constantMask, 3, 1.0, 1.5);
checks(end+1, :) = {"constant image: localStd = 0 exactly", all(s(:) == 0)};
checks(end+1, :) = {"constant image: T = a * constant", all(T(:) == 7)};

% Immagine intera nota con maschera irregolare
testImage = [ 3  8  1  9  4  6
          5  2  7  3  8  1
          9  4  6  2  5  7
          1  7  3  8  2  9
          6  5  9  1  7  3 ];
mask = logical([1 1 1 0 0 1
                1 1 1 1 0 1
                0 1 1 1 1 1
                1 1 0 1 1 1
                1 1 1 1 0 0]);
testImageCopy = testImage;
maskCopy = mask;
w = 3; a = 1; b = 0.5;
[candidate, T, m, s, n] = localMeanStdThreshold2D(testImage, mask, w, a, b);

% Riferimento con cicli espliciti (finestra troncata, solo pixel della maschera)
[rows, cols] = size(testImage);
refMean = NaN(rows, cols); refStd = NaN(rows, cols); refCount = zeros(rows, cols);
h = (w - 1) / 2;
for r = 1:rows
    for c = 1:cols
        if mask(r, c)
            rr = max(1, r - h):min(rows, r + h);
            cc = max(1, c - h):min(cols, c + h);
            block = testImage(rr, cc);
            valid = block(mask(rr, cc));
            refCount(r, c) = numel(valid);
            refMean(r, c) = mean(valid);
            refStd(r, c) = std(valid, 1);           % popolazione
        end
    end
end

% 3-4. Valori noti
checks(end+1, :) = {"localMean = manual mean", max(abs(m(mask) - refMean(mask))) < tol};
checks(end+1, :) = {"localStd = manual population std", max(abs(s(mask) - refStd(mask))) < tol};
% esempio scritto a mano: pixel (1,1), finestra troncata 2x2 -> {3,8,5,2}
checks(end+1, :) = {"pixel (1,1): mean 4.5, std sqrt(5.25)", ...
    abs(m(1, 1) - 4.5) < tol && abs(s(1, 1) - sqrt(5.25)) < tol && n(1, 1) == 4};

% 5-6. I valori fuori maschera non influenzano le statistiche
altered = testImage;
altered(~mask) = 1000;
[candidateAlt, TAlt, mAlt, sAlt] = localMeanStdThreshold2D(altered, mask, w, a, b);
checks(end+1, :) = {"outside-mask values do not change mean/std", ...
    isequal(m(mask), mAlt(mask)) && isequal(s(mask), sAlt(mask))};
checks(end+1, :) = {"outside-mask values do not change in-mask T", isequal(T(mask), TAlt(mask)) && ...
    isequal(candidate, candidateAlt)};

% 7-8. Finestre troncate al bordo e conteggi
checks(end+1, :) = {"border windows truncated (count = manual)", isequal(n, refCount)};
checks(end+1, :) = {"all mask pixels have localCount >= 1", all(n(mask) >= 1)};

% 9-10. Regola dei candidati e tipo
checks(end+1, :) = {"candidate = mask & (image > T)", isequal(candidate, mask & (testImage > T))};
checks(end+1, :) = {"candidate logical", islogical(candidate)};
checks(end+1, :) = {"T = a*m + b*s inside mask", max(abs(T(mask) - (a * refMean(mask) + b * refStd(mask)))) < tol};

% 11-12. Ingressi invariati
checks(end+1, :) = {"input image unchanged", isequal(testImage, testImageCopy)};
checks(end+1, :) = {"input mask unchanged", isequal(mask, maskCopy)};

% 13-17. Ingressi non validi rifiutati
checks(end+1, :) = {"even windowSize rejected", rejects(@() localMeanStdThreshold2D(testImage, mask, 4, a, b))};
checks(end+1, :) = {"windowSize < 1 rejected", rejects(@() localMeanStdThreshold2D(testImage, mask, -1, a, b))};
checks(end+1, :) = {"negative a rejected", rejects(@() localMeanStdThreshold2D(testImage, mask, w, -1, b))};
checks(end+1, :) = {"negative b rejected", rejects(@() localMeanStdThreshold2D(testImage, mask, w, a, -0.5))};
checks(end+1, :) = {"size mismatch rejected", rejects(@() localMeanStdThreshold2D(testImage, mask(:, 1:5), w, a, b))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-46s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase59:checksFailed', 'Local threshold sanity checks failed.');
end
fprintf('\nLOCAL THRESHOLD SANITY CHECKS: PASS (synthetic data only)\n');


function tf = rejects(call)
%REJECTS true se la chiamata genera un errore.
    try
        call();
        tf = false;
    catch
        tf = true;
    end
end
