%% Fase 63: controllo dell'apertura 2D slice per slice (solo dati sintetici)
% Verifica di buon senso di imopen con strel('square', 3), applicato slice
% per slice e vincolato alla maschera cerebrale, come in EXP-030. Solo
% piccoli volumi artificiali: nessun dato BrainWeb, nessun ground truth.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);

checks = cell(0, 2);
se = strel('square', 3);
openSlices = @(mask, brainMask) openSliceWise(mask, brainMask, se);

% Slice 1: pixel isolato; slice 2: blocco 3x3; slice 3: blocco 5x5 con
% sporgenza larga 1 pixel; slice 4: vuota
mask = false(15, 15, 4);
mask(3, 3, 1) = true;
mask(6:8, 6:8, 2) = true;
mask(5:9, 5:9, 3) = true;
mask(7, 10:13, 3) = true;                        % sporgenza larga 1 pixel
brainMask = true(15, 15, 4);
maskCopy = mask;
brainCopy = brainMask;

opened = openSlices(mask, brainMask);
block5 = false(15, 15); block5(5:9, 5:9) = true;

checks(end+1, :) = {"SE is exactly square 3x3", isequal(se.Neighborhood, true(3))};
checks(end+1, :) = {"opened output logical", islogical(opened)};
checks(end+1, :) = {"isolated pixel disappears", ~any(opened(:, :, 1), 'all')};
checks(end+1, :) = {"solid 3x3 block survives unchanged", isequal(opened(:, :, 2), mask(:, :, 2))};
checks(end+1, :) = {"5x5 square kept, 1-px protrusion removed", isequal(opened(:, :, 3), block5)};

manual = false(size(mask));
for k = 1:size(mask, 3)
    manual(:, :, k) = imdilate(imerode(mask(:, :, k), se), se);
end
eroded = applySliceMorphology2D(mask, brainMask, "erode", se);
checks(end+1, :) = {"imopen = imdilate(imerode(mask))", isequal(opened, manual)};
checks(end+1, :) = {"imopen = helper erode -> dilate", ...
    isequal(opened, applySliceMorphology2D(eroded, brainMask, "dilate", se))};
checks(end+1, :) = {"opened subset of input", ~any(opened & ~mask, 'all')};
checks(end+1, :) = {"eroded subset of opened", ~any(eroded & ~opened, 'all')};
checks(end+1, :) = {"no propagation between slices", ~any(opened(:, :, 4), 'all')};

restricted = brainMask;
restricted(:, 1:7, 3) = false;
openedRestricted = openSlices(mask, restricted);
checks(end+1, :) = {"brain-mask restriction respected", ~any(openedRestricted & ~restricted, 'all')};
checks(end+1, :) = {"input mask unchanged", isequal(mask, maskCopy)};
checks(end+1, :) = {"input brainMask unchanged", isequal(brainMask, brainCopy)};
checks(end+1, :) = {"repeated execution deterministic", isequal(opened, openSlices(mask, brainMask))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-46s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase63:checksFailed', 'Opening sanity checks failed.');
end
fprintf('\nOPENING SANITY CHECKS: PASS (synthetic data only)\n');


function opened = openSliceWise(mask, brainMask, se)
%OPENSLICEWISE imopen per slice assiale, poi AND con la maschera cerebrale (come in EXP-030).
    opened = false(size(mask));
    for k = 1:size(mask, 3)
        opened(:, :, k) = imopen(mask(:, :, k), se);
    end
    opened = opened & brainMask;
end
