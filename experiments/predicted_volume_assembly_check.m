%% Fase 71: controllo di assemblePredictedVolume (solo dati sintetici)
% Verifica della ricomposizione delle maschere 2D in un volume 3D. Solo
% piccole maschere artificiali: nessun dato BrainWeb, nessun ground truth,
% nessuna componente connessa.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);

checks = cell(0, 2);
a = false(4, 5); a(2, 3) = true;
b = false(4, 5);                                 % slice vuota
c = false(4, 5); c(1, 1) = true; c(4, 5) = true;
slices = {a; b; c};
slicesCopy = slices;

one = assemblePredictedVolume({a});
v = assemblePredictedVolume(slices);

checks(end+1, :) = {"one slice -> volume with depth 1", isequal(size(one, 3), 1) && isequal(one, a)};
checks(end+1, :) = {"slices concatenated along dimension 3", isequal(size(v), [4 5 3])};
checks(end+1, :) = {"slice order preserved", isequal(v(:, :, 1), a) && isequal(v(:, :, 2), b) && isequal(v(:, :, 3), c)};
checks(end+1, :) = {"logical class preserved", islogical(v)};
checks(end+1, :) = {"empty slice preserved", ~any(v(:, :, 2), 'all')};
checks(end+1, :) = {"non-empty slice preserved", isequal(v(:, :, 3), c)};
checks(end+1, :) = {"no voxel added / removed", nnz(v) == nnz(a) + nnz(b) + nnz(c) && ...
    all(cellfun(@(s, k) isequal(v(:, :, k), s), slices.', {1 2 3}))};
checks(end+1, :) = {"inconsistent slice sizes rejected", rejects(@() assemblePredictedVolume({a; false(3, 5)}))};
checks(end+1, :) = {"non-logical slice rejected", rejects(@() assemblePredictedVolume({a; double(b)}))};
checks(end+1, :) = {"empty input rejected", rejects(@() assemblePredictedVolume({}))};
checks(end+1, :) = {"input slices unchanged", isequal(slices, slicesCopy)};
checks(end+1, :) = {"repeated execution deterministic", isequal(v, assemblePredictedVolume(slices))};

for k = 1:size(checks, 1)
    if checks{k, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-44s %s\n', checks{k, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase71:checksFailed', 'Predicted-volume assembly sanity checks failed.');
end
fprintf('\nPREDICTED VOLUME ASSEMBLY CHECKS: PASS (synthetic data only)\n');


function tf = rejects(call)
%REJECTS true se la chiamata genera un errore.
    try
        call();
        tf = false;
    catch
        tf = true;
    end
end
