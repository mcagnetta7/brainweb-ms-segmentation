%% Fase 65: controllo della griglia di elementi strutturanti (solo dati sintetici)
% Verifica le quattro definizioni preregistrate di EXP-032 e il
% comportamento di imopen slice per slice. Solo piccoli volumi artificiali:
% nessun dato BrainWeb, nessun ground truth.

checks = cell(0, 2);
names = ["square3" "diamond1" "square5" "diamond2"];
ses = {strel('square', 3), strel('diamond', 1), strel('square', 5), strel('diamond', 2)};
expectedSize = {[3 3], [3 3], [5 5], [5 5]};
expectedCount = [9 5 25 13];

for s = 1:4
    nh = ses{s}.Neighborhood;
    checks(end+1, :) = {names(s) + " bounding size and element count", ...
        isequal(size(nh), expectedSize{s}) && nnz(nh) == expectedCount(s)}; %#ok<SAGROW>
    checks(end+1, :) = {names(s) + " is 2D", ismatrix(nh)}; %#ok<SAGROW>
end
distinct = true;
for a = 1:4
    for b = a + 1:4
        distinct = distinct && ~isequal(ses{a}.Neighborhood, ses{b}.Neighborhood);
    end
end
checks(end+1, :) = {"all four neighbourhoods distinct", distinct};

% Volume sintetico: slice 1 croce larga 1 pixel, slice 2 quadrato 7x7 con
% sporgenza larga 1 pixel, slice 3 vuota
mask = false(21, 21, 3);
mask(11, 6:16, 1) = true; mask(6:16, 11, 1) = true;
mask(8:14, 8:14, 2) = true; mask(11, 15:18, 2) = true;
maskCopy = mask;
for s = 1:4
    opened = false(size(mask));
    for k = 1:size(mask, 3)
        opened(:, :, k) = imopen(mask(:, :, k), ses{s});
    end
    again = false(size(mask));
    for k = 1:size(mask, 3)
        again(:, :, k) = imopen(mask(:, :, k), ses{s});
    end
    checks(end+1, :) = {names(s) + " opening logical", islogical(opened)}; %#ok<SAGROW>
    checks(end+1, :) = {names(s) + " opening anti-extensive", ~any(opened & ~mask, 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {names(s) + " no propagation across slices", ~any(opened(:, :, 3), 'all')}; %#ok<SAGROW>
    checks(end+1, :) = {names(s) + " deterministic", isequal(opened, again)}; %#ok<SAGROW>
    checks(end+1, :) = {names(s) + " 1-px protrusion removed, 7x7 body kept", ...
        ~any(opened(11, 16:18, 2)) && all(opened(9:13, 9:13, 2), 'all')}; %#ok<SAGROW>
end
% La croce larga 1 pixel è rimossa dai quadrati e da diamond2; diamond1 (a
% sua volta una croce a 5 pixel) conserva solo il "+" nel punto d'incrocio
plus = false(21, 21); plus(11, 10:12) = true; plus(10:12, 11) = true;
for s = [1 3 4]
    checks(end+1, :) = {names(s) + " removes the 1-px-wide cross", ...
        ~any(imopen(mask(:, :, 1), ses{s}), 'all')}; %#ok<SAGROW>
end
checks(end+1, :) = {"diamond1 keeps only the 5-px plus at the crossing", ...
    isequal(imopen(mask(:, :, 1), ses{2}), plus)};
checks(end+1, :) = {"source mask unchanged", isequal(mask, maskCopy)};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-50s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase65:checksFailed', 'Structuring-element grid checks failed.');
end
fprintf('\nSTRUCTURING-ELEMENT GRID CHECKS: PASS (synthetic data only)\n');
