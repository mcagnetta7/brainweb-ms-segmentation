%% Fase 62: controllo di applySliceMorphology2D (solo dati sintetici)
% Verifica di buon senso di erosione / dilatazione 2D slice per slice con
% strel('square', 3) e vincolo alla maschera cerebrale. Solo piccoli
% volumi artificiali: nessun dato BrainWeb, nessun ground truth.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.segmentation);

checks = cell(0, 2);
se = strel('square', 3);
allowed = true(9, 9, 3);

% Volume sintetico: slice 1 pixel isolato al centro, slice 2 blocco 3x3,
% slice 3 vuota (nessuna propagazione tra slice deve comparire)
mask = false(9, 9, 3);
mask(5, 5, 1) = true;
mask(4:6, 4:6, 2) = true;
maskCopy = mask;

eroded = applySliceMorphology2D(mask, allowed, "erode", se);
dilated = applySliceMorphology2D(mask, allowed, "dilate", se);

expectedDilatedPixel = false(9, 9); expectedDilatedPixel(4:6, 4:6) = true;
expectedErodedBlock = false(9, 9); expectedErodedBlock(5, 5) = true;

checks(end+1, :) = {"SE is exactly square 3x3", isequal(se.Neighborhood, true(3))};
checks(end+1, :) = {"erosion output logical", islogical(eroded)};
checks(end+1, :) = {"dilation output logical", islogical(dilated)};
checks(end+1, :) = {"erosion never adds foreground", ~any(eroded & ~mask, 'all')};
checks(end+1, :) = {"dilation never removes foreground", ~any(mask & ~dilated, 'all')};
checks(end+1, :) = {"isolated pixel disappears after erosion", ~any(eroded(:, :, 1), 'all')};
checks(end+1, :) = {"single pixel dilates to 3x3 block", isequal(dilated(:, :, 1), expectedDilatedPixel)};
checks(end+1, :) = {"3x3 block erodes to its centre", isequal(eroded(:, :, 2), expectedErodedBlock)};
checks(end+1, :) = {"no propagation into the empty slice", ~any(dilated(:, :, 3), 'all')};

% Vincolo alla maschera cerebrale
brainMask = true(9, 9, 3);
brainMask(:, 6:9, 1) = false;                    % metà destra della slice 1 non ammessa
dilatedConstrained = applySliceMorphology2D(mask, brainMask, "dilate", se);
checks(end+1, :) = {"brain mask prevents dilation outside support", ~any(dilatedConstrained & ~brainMask, 'all') && ...
    isequal(dilatedConstrained(:, :, 1), expectedDilatedPixel & brainMask(:, :, 1))};

checks(end+1, :) = {"inputs unchanged", isequal(mask, maskCopy)};
checks(end+1, :) = {"repeated calls deterministic", ...
    isequal(eroded, applySliceMorphology2D(mask, allowed, "erode", se)) && ...
    isequal(dilated, applySliceMorphology2D(mask, allowed, "dilate", se))};
checks(end+1, :) = {"unsupported operation rejected", rejects(@() applySliceMorphology2D(mask, allowed, "open", se))};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-46s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase62:checksFailed', 'Morphology sanity checks failed.');
end
fprintf('\nMORPHOLOGY SANITY CHECKS: PASS (synthetic data only)\n');


function tf = rejects(call)
%REJECTS true se la chiamata genera un errore.
    try
        call();
        tf = false;
    catch
        tf = true;
    end
end
