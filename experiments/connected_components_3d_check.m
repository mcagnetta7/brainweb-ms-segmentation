%% Fase 72: controllo di extractConnectedComponents3D (solo dati sintetici)
% Verifica della scomposizione in componenti connesse 3D con connettività
% 26. Solo piccoli volumi artificiali: nessun dato BrainWeb, nessun ground
% truth, nessun regionprops3, nessun filtraggio.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);

checks = cell(0, 2);
sz = [10 10 6];

empty = false(sz);
oneVoxel = false(sz); oneVoxel(5, 5, 3) = true;
twoGroups = false(sz); twoGroups(1:2, 1:2, 1) = true; twoGroups(8:9, 8:9, 5) = true;
face = false(sz); face(5, 5, 3) = true; face(5, 5, 4) = true;
edgePair = false(sz); edgePair(5, 5, 3) = true; edgePair(6, 5, 4) = true;
corner = false(sz); corner(5, 5, 3) = true; corner(6, 6, 4) = true;
diagSlices = false(sz); diagSlices(3, 3, 2) = true; diagSlices(4, 4, 3) = true;
separated = false(sz); separated(2, 2, 2) = true; separated(2, 4, 2) = true;   % distanza 2: non adiacenti

cc = extractConnectedComponents3D(twoGroups, 26);
ccEmpty = extractConnectedComponents3D(empty, 26);
checks(end+1, :) = {"logical 3D input accepted", isstruct(cc)};
checks(end+1, :) = {"explicit connectivity 26 stored", cc.Connectivity == 26};
checks(end+1, :) = {"empty volume -> NumObjects 0", ccEmpty.NumObjects == 0};
checks(end+1, :) = {"isolated voxel -> one component", countOf(oneVoxel) == 1};
checks(end+1, :) = {"two separated groups -> two components", cc.NumObjects == 2};
checks(end+1, :) = {"face-sharing voxels connected", countOf(face) == 1};
checks(end+1, :) = {"edge-sharing voxels connected (26)", countOf(edgePair) == 1};
checks(end+1, :) = {"corner-touching voxels connected (26)", countOf(corner) == 1};
checks(end+1, :) = {"diagonal x/y offset across slices connected", countOf(diagSlices) == 1};
checks(end+1, :) = {"sufficiently separated voxels stay separate", countOf(separated) == 2};

rebuilt = false(sz);
for i = 1:cc.NumObjects
    rebuilt(cc.PixelIdxList{i}) = true;
end
allIdx = vertcat(cc.PixelIdxList{:});
checks(end+1, :) = {"PixelIdxList union reconstructs the input", isequal(rebuilt, twoGroups)};
checks(end+1, :) = {"PixelIdxList entries disjoint", numel(allIdx) == numel(unique(allIdx))};
checks(end+1, :) = {"NumObjects = numel(PixelIdxList)", cc.NumObjects == numel(cc.PixelIdxList)};
checks(end+1, :) = {"sum of component voxels = nnz(input)", sum(cellfun(@numel, cc.PixelIdxList)) == nnz(twoGroups)};
copyIn = twoGroups;
again = extractConnectedComponents3D(twoGroups, 26);
checks(end+1, :) = {"input volume unchanged", isequal(twoGroups, copyIn)};
checks(end+1, :) = {"repeated execution deterministic", isequal(cc, again)};
checks(end+1, :) = {"non-logical input rejected", rejects(@() extractConnectedComponents3D(double(twoGroups), 26))};
checks(end+1, :) = {"invalid connectivity rejected", rejects(@() extractConnectedComponents3D(twoGroups, 8))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-48s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase72:checksFailed', 'Connected-component 3D sanity checks failed.');
end
fprintf('\nCONNECTED COMPONENTS 3D CHECKS: PASS (synthetic data only)\n');


function n = countOf(v)
%COUNTOF Numero di componenti 26-connesse del volume v.
    cc = extractConnectedComponents3D(v, 26);
    n = cc.NumObjects;
end

function tf = rejects(call)
%REJECTS true se la chiamata genera un errore.
    try
        call();
        tf = false;
    catch
        tf = true;
    end
end
