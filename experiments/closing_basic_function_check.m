%% Fase 64: controllo della chiusura 2D slice per slice (solo dati sintetici)
% Verifica di buon senso di imclose con strel('square', 3), applicato slice
% per slice e intersecato con la maschera cerebrale SOLO dopo la chiusura
% completa, come in EXP-031. Solo piccoli volumi artificiali, lontani dal
% bordo dell'immagine: nessun dato BrainWeb, nessun ground truth.

checks = cell(0, 2);
se = strel('square', 3);

% Slice 1: pixel isolato; slice 2: quadrato 5x5 pieno; slice 3: quadrato
% 5x5 con buco centrale di un pixel; slice 4: due blocchi 3x3 separati da
% una fessura larga un pixel; slice 5: vuota
mask = false(15, 15, 5);
mask(7, 7, 1) = true;
mask(5:9, 5:9, 2) = true;
mask(5:9, 5:9, 3) = true; mask(7, 7, 3) = false;
mask(6:8, 4:6, 4) = true; mask(6:8, 8:10, 4) = true;
brainMask = true(15, 15, 5);
maskCopy = mask;
brainCopy = brainMask;

closed = closeSliceWise(mask, brainMask, se);
square5 = false(15, 15); square5(5:9, 5:9) = true;
bridged = false(15, 15); bridged(6:8, 4:10) = true;

checks(end+1, :) = {"SE is exactly square 3x3", isequal(se.Neighborhood, true(3))};
checks(end+1, :) = {"output logical", islogical(closed)};
manual = false(size(mask));
for k = 1:size(mask, 3)
    manual(:, :, k) = imerode(imdilate(mask(:, :, k), se), se);
end
checks(end+1, :) = {"imclose = imerode(imdilate(mask))", isequal(closed, manual & brainMask)};
checks(end+1, :) = {"isolated pixel preserved", isequal(closed(:, :, 1), mask(:, :, 1))};
checks(end+1, :) = {"solid square unchanged", isequal(closed(:, :, 2), square5)};
checks(end+1, :) = {"single-pixel internal hole filled", isequal(closed(:, :, 3), square5)};
checks(end+1, :) = {"one-pixel gap between blocks closed", isequal(closed(:, :, 4), bridged)};
checks(end+1, :) = {"input subset of closed result", ~any(mask & ~closed, 'all')};
checks(end+1, :) = {"no cross-slice propagation", ~any(closed(:, :, 5), 'all')};

% Maschera cerebrale applicata solo alla fine: esclusa la colonna accanto al
% quadrato 5x5. La chiusura completa conserva il quadrato; ritagliare la
% dilatazione intermedia lo eroderebbe (operazione diversa).
restricted = brainMask;
restricted(:, 10, 2) = false;
closedRestricted = closeSliceWise(mask, restricted, se);
clippedVariant = imerode(imdilate(mask(:, :, 2), se) & restricted(:, :, 2), se) & restricted(:, :, 2);
checks(end+1, :) = {"final brain-mask restriction respected", ~any(closedRestricted & ~restricted, 'all')};
checks(end+1, :) = {"no intermediate clipping (clipped would differ)", ...
    isequal(closedRestricted(:, :, 2), square5) && ~isequal(clippedVariant, square5)};
checks(end+1, :) = {"input mask unchanged", isequal(mask, maskCopy)};
checks(end+1, :) = {"input brainMask unchanged", isequal(brainMask, brainCopy)};
checks(end+1, :) = {"repeated execution deterministic", isequal(closed, closeSliceWise(mask, brainMask, se))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-48s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase64:checksFailed', 'Closing sanity checks failed.');
end
fprintf('\nCLOSING SANITY CHECKS: PASS (synthetic data only)\n');


function closed = closeSliceWise(mask, brainMask, se)
%CLOSESLICEWISE imclose per slice assiale, poi AND con la maschera cerebrale (come in EXP-031).
    closed = false(size(mask));
    for k = 1:size(mask, 3)
        closed(:, :, k) = imclose(mask(:, :, k), se);
    end
    closed = closed & brainMask;
end
