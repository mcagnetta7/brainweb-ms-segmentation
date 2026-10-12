%% Fase 70: controllo di auditSmallLesionProtection2D (solo dati sintetici)
% Verifica della classificazione per sovrapposizione delle componenti GT 2D
% prima/dopo un filtro che rimuove soltanto. Solo volumi artificiali:
% nessun dato BrainWeb, nessuna logica di segmentazione o filtraggio.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);

checks = cell(0, 2);
sz = [12 12 2];
gt = false(sz); before = false(sz); after = false(sz);
% Slice 1: GT A senza supporto; GT B supporto invariato; GT C ridotto ma
% non nullo; GT D supporto totalmente rimosso
gt(1:2, 1:2, 1) = true;                              % A (4 px)
gt(1:3, 6:8, 1) = true; before(1:3, 6:8, 1) = true;   % B (9 px, 9 sovrapposti)
gt(6:7, 1:4, 1) = true; before(6:7, 1:4, 1) = true;   % C (8 px)
gt(10:11, 10:11, 1) = true; before(10:11, 10:11, 1) = true;   % D (4 px)
after = before;
after(6:7, 3:4, 1) = false;                          % C ridotto a 4 px
after(10:11, 10:11, 1) = false;                      % D perso
% Slice 2: GT nella stessa posizione di D, supporto invariato (indipendenza)
gt(10:11, 10:11, 2) = true; before(10:11, 10:11, 2) = true; after(10:11, 10:11, 2) = true;
copies = {gt, before, after};

t = auditSmallLesionProtection2D(gt, before, after, 8, "synthetic");
s1 = t(t.slice == 1, :);
getRow = @(area, ob) s1(s1.gtAreaPixels == area & s1.overlapBefore == ob, :);
A = getRow(4, 0); B = getRow(9, 9); C = getRow(8, 8); D = getRow(4, 4);

checks(end+1, :) = {"after must be subset of before", ...
    rejects(@() auditSmallLesionProtection2D(gt, after, before, 8, "x"))};
checks(end+1, :) = {"no support before -> not newly lost", ~A.newlyCompletelyLost && ~A.hadSupportBefore};
checks(end+1, :) = {"same overlap after -> unaffected", ~B.affectedByFilter && B.overlapAfter == 9};
checks(end+1, :) = {"reduced but non-zero -> partial reduction", C.affectedByFilter && C.hasSupportAfter && C.overlapAfter == 4};
checks(end+1, :) = {"support before, zero after -> newly lost", D.newlyCompletelyLost && D.overlapAfter == 0};
checks(end+1, :) = {"Area from GT PixelIdxList", isequal(sort(s1.gtAreaPixels).', [4 4 8 9])};
checks(end+1, :) = {"coverageBefore correct", abs(C.coverageBefore - 1) < 1e-12 && A.coverageBefore == 0};
checks(end+1, :) = {"coverageAfter correct", abs(C.coverageAfter - 0.5) < 1e-12};
checks(end+1, :) = {"coverageChange correct", abs(C.coverageChange + 0.5) < 1e-12 && abs(D.coverageChange + 1) < 1e-12};
checks(end+1, :) = {"sum removedOverlap = removed GT voxels", sum(t.removedOverlap) == nnz(before & ~after & gt)};
checks(end+1, :) = {"no component with before 0 and after > 0", ~any(t.overlapBefore == 0 & t.overlapAfter > 0)};
s2 = t(t.slice == 2, :);
checks(end+1, :) = {"adjacent slices independent", height(s2) == 1 && ~s2.affectedByFilter};
diagGt = false(5, 5, 2); diagGt(2, 2, 1) = true; diagGt(3, 3, 1) = true;   % 2 slice: volume 3D
tDiag = auditSmallLesionProtection2D(diagGt, diagGt, diagGt, 8, "diag");
checks(end+1, :) = {"explicit 8-connectivity (diagonal = one component)", height(tDiag) == 1};
checks(end+1, :) = {"input masks unchanged", isequal({gt, before, after}, copies)};
checks(end+1, :) = {"repeated execution deterministic", isequal(t, auditSmallLesionProtection2D(gt, before, after, 8, "synthetic"))};
functionText = fileread(fullfile(cfg.paths.evaluation, 'auditSmallLesionProtection2D.m'));
checks(end+1, :) = {"no segmentation / filtering logic in the function", ...
    ~contains(functionText, ['filterComponents' 'ByArea2D(']) && ~contains(functionText, ['imopen' '(']) && ...
    ~contains(functionText, ['multi' 'thresh('])};

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-52s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('phase70:checksFailed', 'Small-lesion protection audit sanity checks failed.');
end
fprintf('\nSMALL-LESION PROTECTION 2D CHECKS: PASS (synthetic data only)\n');


function tf = rejects(call)
%REJECTS true se la chiamata genera un errore.
    try
        call();
        tf = false;
    catch
        tf = true;
    end
end
