%% Fase 69: controllo di filterComponentsByArea2D (solo dati sintetici)
% Verifica della regola "tieni Area > 9" su strutture tipo fase 67 e una
% tabella tipo fase 68. Solo volumi artificiali: nessun dato BrainWeb,
% nessun ground truth. Nessun'altra soglia viene provata.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);

checks = cell(0, 2);
imageSize = [12 12 3];

% Slice 1: blocco 3x3 (area 9) e blocco 2x5 (area 10); slice 2: blocco 4x4
% (area 16); slice 3: blocco 3x3 nella stessa posizione della slice 1
mask = false(imageSize);
mask(2:4, 2:4, 1) = true; mask(7:8, 3:7, 1) = true;
mask(5:8, 5:8, 2) = true;
mask(2:4, 2:4, 3) = true;
cc = cell(3, 1);
rows = cell(0, 3);
for k = 1:3
    cc{k} = bwconncomp(mask(:, :, k), 8);
    for i = 1:cc{k}.NumObjects
        rows(end+1, :) = {k, i, numel(cc{k}.PixelIdxList{i})}; %#ok<SAGROW>
    end
end
t = cell2table(rows, 'VariableNames', {'slice', 'componentIndexInSlice', 'areaPixels'});
ccCopy = cc;
tCopy = t;

[filtered, keep, removed] = filterComponentsByArea2D(cc, t, imageSize, 9);
area9 = false(imageSize(1:2)); area9(2:4, 2:4) = true;
area10 = false(imageSize(1:2)); area10(7:8, 3:7) = true;

checks(end+1, :) = {"Area-9 component removed", ~any(filtered(:, :, 1) & area9, 'all')};
checks(end+1, :) = {"Area-10 component retained", all(filtered(:, :, 1) == area10, 'all')};
checks(end+1, :) = {"Area-16 component retained", isequal(filtered(:, :, 2), mask(:, :, 2))};
checks(end+1, :) = {"whole PixelIdxList sets kept or removed", isequal(filtered(:, :, 1), area10)};
checks(end+1, :) = {"retained pixels unchanged, nothing added", ~any(filtered & ~mask, 'all') && ...
    all(mask(filtered))};
checks(end+1, :) = {"output logical, correct size", islogical(filtered) && isequal(size(filtered), imageSize)};
checks(end+1, :) = {"same rule on every slice (slice 3 Area 9 removed)", ~any(filtered(:, :, 3), 'all')};
checks(end+1, :) = {"adjacent slices independent", isequal(filtered(:, :, 2), mask(:, :, 2))};
checks(end+1, :) = {"keep/removed vectors follow componentIndexInSlice", ...
    isequal(keep{1}.', [false true]) && isequal(removed{1}.', [true false]) && keep{2} && removed{3}};

missing = t(1:end-1, :);
duplicate = [t; t(1, :)];
wrongArea = t; wrongArea.areaPixels(2) = 99;
checks(end+1, :) = {"missing property row rejected", rejects(@() filterComponentsByArea2D(cc, missing, imageSize, 9))};
checks(end+1, :) = {"duplicate property row rejected", rejects(@() filterComponentsByArea2D(cc, duplicate, imageSize, 9))};
checks(end+1, :) = {"Area vs PixelIdxList mismatch rejected", rejects(@() filterComponentsByArea2D(cc, wrongArea, imageSize, 9))};
checks(end+1, :) = {"source ccBySlice unchanged", isequal(cc, ccCopy)};
checks(end+1, :) = {"source property table unchanged", isequal(t, tCopy)};
checks(end+1, :) = {"repeated execution deterministic", isequal(filtered, filterComponentsByArea2D(cc, t, imageSize, 9))};
functionText = fileread(fullfile(cfg.paths.segmentation, 'filterComponentsByArea2D.m'));
checks(end+1, :) = {"no GT / recomputation in the function", ~contains(functionText, ['loadBrainweb' 'GroundTruth']) && ...
    ~contains(functionText, ['bwconn' 'comp(']) && ~contains(functionText, ['region' 'props('])};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-52s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase69:checksFailed', 'Component-area filter sanity checks failed.');
end
fprintf('\nCOMPONENT AREA FILTER CHECKS: PASS (synthetic data only)\n');


function tf = rejects(call)
%REJECTS true se la chiamata genera un errore.
    try
        call();
        tf = false;
    catch
        tf = true;
    end
end
