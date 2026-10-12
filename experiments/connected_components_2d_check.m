%% Fase 67: controllo di extractConnectedComponents2D (solo dati sintetici)
% Verifica di buon senso della scomposizione in componenti connesse 2D
% slice per slice con connettività 8. Solo piccoli volumi artificiali:
% nessun dato BrainWeb, nessun ground truth, nessun regionprops.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);

checks = cell(0, 2);

% Slice 1 vuota; slice 2 un pixel isolato; slice 3 due gruppi separati;
% slice 4 due pixel che si toccano solo in diagonale; slice 5 un pixel
% nella stessa posizione della slice 2 (adiacenza solo tra slice)
mask = false(9, 9, 5);
mask(5, 5, 2) = true;
mask(2:3, 2:3, 3) = true; mask(7:8, 7:8, 3) = true;
mask(4, 4, 4) = true; mask(5, 5, 4) = true;
mask(5, 5, 5) = true;
maskCopy = mask;

[cc, nPerSlice] = extractConnectedComponents2D(mask, 8);

checks(end+1, :) = {"logical input accepted, one CC per slice", iscell(cc) && numel(cc) == size(mask, 3)};
checks(end+1, :) = {"explicit connectivity 8 stored", all(cellfun(@(c) c.Connectivity == 8, cc))};
checks(end+1, :) = {"empty slice -> NumObjects 0", cc{1}.NumObjects == 0 && isempty(cc{1}.PixelIdxList)};
checks(end+1, :) = {"isolated pixel -> one component", cc{2}.NumObjects == 1};
checks(end+1, :) = {"two separated groups -> two components", cc{3}.NumObjects == 2};
checks(end+1, :) = {"diagonal pixels -> one component (8-conn.)", cc{4}.NumObjects == 1};
checks(end+1, :) = {"adjacent slices not connected", cc{2}.NumObjects == 1 && cc{5}.NumObjects == 1};

reconstructOk = true;
disjointOk = true;
countOk = true;
for k = 1:size(mask, 3)
    rebuilt = false(size(mask, 1), size(mask, 2));
    for i = 1:cc{k}.NumObjects
        rebuilt(cc{k}.PixelIdxList{i}) = true;
    end
    allIdx = vertcat(cc{k}.PixelIdxList{:});
    reconstructOk = reconstructOk && isequal(rebuilt, mask(:, :, k));
    disjointOk = disjointOk && numel(allIdx) == numel(unique(allIdx));
    countOk = countOk && cc{k}.NumObjects == numel(cc{k}.PixelIdxList) && nPerSlice(k) == cc{k}.NumObjects;
end
checks(end+1, :) = {"PixelIdxList union reconstructs each slice", reconstructOk};
checks(end+1, :) = {"PixelIdxList entries disjoint", disjointOk};
checks(end+1, :) = {"NumObjects = numel(PixelIdxList) = count vector", countOk};
checks(end+1, :) = {"input mask unchanged", isequal(mask, maskCopy)};
[ccAgain, nAgain] = extractConnectedComponents2D(mask, 8);
checks(end+1, :) = {"repeated execution deterministic", isequal(cc, ccAgain) && isequal(nPerSlice, nAgain)};
checks(end+1, :) = {"non-logical mask rejected", rejects(@() extractConnectedComponents2D(double(mask), 8))};
checks(end+1, :) = {"invalid connectivity rejected", rejects(@() extractConnectedComponents2D(mask, 26))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-50s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase67:checksFailed', 'Connected-component sanity checks failed.');
end
fprintf('\nCONNECTED COMPONENTS 2D CHECKS: PASS (synthetic data only)\n');


function tf = rejects(call)
%REJECTS true se la chiamata genera un errore.
    try
        call();
        tf = false;
    catch
        tf = true;
    end
end
