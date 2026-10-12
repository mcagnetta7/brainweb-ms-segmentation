%% Controllo sintetico di fuseCandidateMasksIntersection (nessun GT, nessun dato reale)

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);

primaryMask = false(6, 7, 3);
primaryMask(2:4, 2:4, 1:2) = true;
secondaryMask = false(6, 7, 3);
secondaryMask(3:5, 3:6, 2:3) = true;
primaryCopy = primaryMask;
secondaryCopy = secondaryMask;

fused = fuseCandidateMasksIntersection(primaryMask, secondaryMask);
expected = false(6, 7, 3);
expected(3:4, 3:4, 2) = true;
disjointSecondary = false(6, 7, 3);
disjointSecondary(6, 7, 3) = true;

checks = {
    "logical inputs accepted",                      islogical(fused)
    "identical masks -> same mask",                 isequal(fuseCandidateMasksIntersection(primaryMask, primaryMask), primaryMask)
    "disjoint masks -> empty output",               ~any(fuseCandidateMasksIntersection(primaryMask, disjointSecondary), 'all')
    "partial overlap -> exactly the intersection",  isequal(fused, expected)
    "output is logical",                            islogical(fused)
    "output has the same dimensions",               isequal(size(fused), size(primaryMask))
    "output subset of primary",                     ~any(fused & ~primaryMask, 'all')
    "output subset of secondary",                   ~any(fused & ~secondaryMask, 'all')
    "no new voxel introduced",                      nnz(fused) <= min(nnz(primaryMask), nnz(secondaryMask))
    "different dimensions rejected",                throwsError(@() fuseCandidateMasksIntersection(primaryMask, false(6, 7, 2)))
    "non-logical primary rejected",                 throwsError(@() fuseCandidateMasksIntersection(double(primaryMask), secondaryMask))
    "non-logical secondary rejected",               throwsError(@() fuseCandidateMasksIntersection(primaryMask, double(secondaryMask)))
    "inputs unchanged",                             isequal(primaryMask, primaryCopy) && isequal(secondaryMask, secondaryCopy)
    "repeated execution deterministic",             isequal(fuseCandidateMasksIntersection(primaryMask, secondaryMask), fused)
    };

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-50s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('fusionCheck:failed', 'Synthetic fusion check failed.');
end
fprintf('\nSYNTHETIC FUSION CHECK: PASS (%d)\n', size(checks, 1));

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
