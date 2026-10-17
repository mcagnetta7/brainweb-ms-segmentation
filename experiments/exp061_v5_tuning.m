%% EXP-061 (emendamento A4): v5 = crescita a isteresi dai nuclei della v4
% 10 configurazioni x 9 condizioni viste (pn0 pn1 pn3 pn5 pn7 pn9, msles1 msles2 msles3 custom).
% Ordine: integrità v4 -> 90 predizioni salvate senza GT -> base L0_M1 = v4 voxel per voxel ->
% GT -> Dice medio sulle 9 condizioni (valori IN-SAMPLE) -> scelta preregistrata.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.evaluation);
M = cfg.paths.metrics;
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));

pre = ["pn0" "pn1" "pn3" "pn5" "pn7" "pn9"];
cus = ["msles1" "msles2" "msles3"];
conditions = [pre cus];
labelOf = @(c) ternary(any(cus == c), c + " (custom)", "msles2 " + c);
mriDir = fileparts(cfg.dataset.mriFiles.T1);
customDir = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'phase101');
custom = struct('msles1', {{'custom_msles1_t1_ai_1mm_n0_inu0_job1261017-050735s-2817767.raws', ...
    'custom_msles1_t2_ai_1mm_n0_inu0_job1261017-050750s-2817854.raws'}}, ...
    'msles2', {{'custom_msles2_t1_ai_1mm_n0_inu0_job1261017-050846s-2818122.raws', ...
    'custom_msles2_t2_ai_1mm_n0_inu0_job1261017-050720s-2817689.raws'}}, ...
    'msles3', {{'custom_msles3_t1_ai_1mm_n0_inu0_job1261017-050805s-2817935.raws', ...
    'custom_msles3_t2_ai_1mm_n0_inu0_job1261017-050820s-2818018.raws'}});
cfgAll = cfg;
for n = ["pn1" "pn5" "pn7" "pn9"]
    cfgAll.dataset.noisyMriFiles.(n).T1 = fullfile(mriDir, sprintf('t1_ai_msles2_1mm_%s_rf0.raws', n));
    cfgAll.dataset.noisyMriFiles.(n).T2 = fullfile(mriDir, sprintf('t2_ai_msles2_1mm_%s_rf0.raws', n));
end
for p = cus
    cfgAll.dataset.noisyMriFiles.(p).T1 = fullfile(customDir, 'mri', custom.(p){1});
    cfgAll.dataset.noisyMriFiles.(p).T2 = fullfile(customDir, 'mri', custom.(p){2});
end
gtFile = @(c) ternary(c == "msles1" || c == "msles3", ...
    fullfile(customDir, 'ground_truth', sprintf('phantom_1.0mm_%s_crisp.rawb', c)), cfg.dataset.groundTruthFile);
v4File = @(c) ternary(any(c == ["pn1" "pn5" "pn7" "pn9"]), ...
    fullfile(cfg.paths.processedData, sprintf('v4_secondary_%s_prediction.mat', c)), ...
    fullfile(cfg.paths.processedData, 'exp060_candidates', sprintf('exp060_k5_%s.mat', c)));

ids = ["L0_M1" "L0_M0" "L4_Z2_M1" "L4_Z1_M1" "L3_Z2_M1" "L3_Z1_M1" "L4_Z2_M0" "L4_Z1_M0" "L3_Z2_M0" "L3_Z1_M0"];
configs = struct([]);
for id = ids
    parts = split(id, "_");
    configs = [configs; struct('id', id, 'growth', parts(1), 'zone', ternary(numel(parts) == 3, ...
        ternary(numel(parts) == 3 && parts(2) == "Z1", "S1", "S2"), "S2"), 'opening', parts(end))]; %#ok<AGROW>
end
complexity = arrayfun(@(c) double(c.growth ~= "L0") + double(c.growth ~= "L0" && c.zone == "S1"), configs);
candDir = fullfile(cfg.paths.processedData, 'exp061_candidates');
checks = cell(0, 2);


%% 0. Integrità della v4 congelata

v4Manifest = readtable(fullfile(projectRoot, 'docs', 'v4_freeze_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
v4Ok = @() all(arrayfun(@(i) strcmp(sha256File(fullfile(projectRoot, v4Manifest.path(i))), v4Manifest.sha256(i)), ...
    1:height(v4Manifest)));
checks(end+1, :) = {"v4 frozen files (14 hashes) unchanged BEFORE", v4Ok()};
if ~checks{end, 2}
    error('exp061:blocked', 'v4 freeze not verified.');
end


%% 1. 90 predizioni (NESSUN GT)

if ~isfolder(candDir)
    mkdir(candDir);
end
pred = cell(numel(ids), numel(conditions));
det = cell(1, numel(conditions));
for c = 1:numel(conditions)
    [p, d] = generateV5Predictions(loadBrainwebMri(cfgAll, "T1", conditions(c)), ...
        loadBrainwebMri(cfgAll, "T2", conditions(c)), configs);
    pred(:, c) = p; det{c} = d;
    for j = 1:numel(ids)
        M_pred = p{j}; metadata = struct('experiment', "EXP-061", 'condition', conditions(c), 'config', configs(j), ...
            'details', d, 'gtUsedForGeneration', false);
        save(fullfile(candDir, sprintf('exp061_%s_%s.mat', ids(j), conditions(c))), 'M_pred', 'metadata');
    end
    fprintf('%s: high %.4f, low4 %.4f, low3 %.4f; voxels L0_M1 %d, L3_Z1_M0 %d\n', labelOf(conditions(c)), d.high, ...
        d.low4, d.low3, nnz(p{1}), nnz(p{end}));
end


%% 2. Base = v4 voxel per voxel; annidamento (ancora senza GT)

baseOk = true; nestedOk = true;
for c = 1:numel(conditions)
    s = load(v4File(conditions(c)), 'M_pred');
    baseOk = baseOk && isequal(pred{1, c}, s.M_pred);
    P = @(id) pred{ids == id, c};
    nestedOk = nestedOk && ~any(P("L0_M1") & ~P("L0_M0"), 'all') && ~any(P("L4_Z2_M1") & ~P("L3_Z2_M1"), 'all') && ...
        ~any(P("L3_Z2_M1") & ~P("L3_Z1_M1"), 'all') && ~any(P("L0_M1") & ~P("L4_Z2_M1"), 'all');
end
checks = [checks; {
    "base L0_M1 reproduces the saved v4 predictions voxel by voxel (9 conditions)", baseOk
    "nesting: v4 <= growth; L4 <= L3; zone S2 <= S1; opened cores <= unopened", nestedOk
    }];
if ~baseOk
    error('exp061:technicallyBlocked', 'EXP-061 TECHNICALLY BLOCKED: base does not reproduce v4.');
end


%% 3. GT, metriche, scelta preregistrata

dice = zeros(numel(ids), numel(conditions));
rows = cell(0, 11);
for c = 1:numel(conditions)
    cfgGt = cfg; cfgGt.dataset.groundTruthFile = gtFile(conditions(c));
    gt = loadBrainwebGroundTruth(cfgGt) == 10;
    for j = 1:numel(ids)
        cnt = computeVoxelConfusion(pred{j, c}, gt);
        lw = computeLesionWiseMatches(pred{j, c}, gt, 26);
        dice(j, c) = computeDiceFromConfusion(cnt);
        rows(end+1, :) = {ids(j), conditions(c), dice(j, c), computePrecisionFromConfusion(cnt), ...
            computeRecallFromConfusion(cnt), cnt.TP + cnt.FP, cnt.FP, cnt.FN, lw.gtComponentCount, ...
            lw.detectedGtLesionCount, lw.falsePredictedComponentCount}; %#ok<SAGROW>
    end
end
grid = cell2table(rows, 'VariableNames', {'configId', 'condition', 'dice', 'precision', 'recall', 'predictedVoxels', ...
    'fpVoxels', 'fnVoxels', 'gtLesions', 'detectedGtLesions', 'falsePredictedComponents'});
writetable(grid, fullfile(M, 'exp061_grid_results.csv'));

objective = mean(dice, 2);
[~, idOrder] = sort(ids); idRank = zeros(numel(ids), 1); idRank(idOrder) = 1:numel(ids);
[~, order] = sortrows([-objective, complexity, idRank]);
winnerIdx = order(1);
v5Exists = winnerIdx ~= 1 && objective(winnerIdx) > objective(1);
detectedTotal = arrayfun(@(j) sum(grid.detectedGtLesions(grid.configId == ids(j))), 1:numel(ids)).';
falseTotal = arrayfun(@(j) sum(grid.falsePredictedComponents(grid.configId == ids(j))), 1:numel(ids)).';
ranking = array2table(dice(order, :), 'VariableNames', cellstr(conditions));
ranking = [table((1:numel(ids)).', ids(order).', 'VariableNames', {'rank', 'configId'}), ranking, ...
    table(objective(order), objective(order) - objective(1), detectedTotal(order), falseTotal(order), ...
    complexity(order), order == winnerIdx & v5Exists, 'VariableNames', {'meanDiceInSample', 'deltaVsV4', ...
    'detectedLesionsSum', 'falseComponentsSum', 'complexity', 'selected'})];
writetable(ranking, fullfile(M, 'exp061_ranking.csv'));
disp(ranking);
fprintf('\nEXP-061 RESULT: %s\n', ternary(v5Exists, "v5 = " + ids(winnerIdx) + sprintf(' (mean in-sample Dice %.6f vs v4 %.6f)', ...
    objective(winnerIdx), objective(1)), "no improvement over v4 -> v4 stays"));
fprintf('Detected GT lesions summed over the 9 conditions: v4 %d, winner %d; false components v4 %d, winner %d\n\n', ...
    detectedTotal(1), detectedTotal(winnerIdx), falseTotal(1), falseTotal(winnerIdx));


%% 4. Controlli finali

checks = [checks; {
    "all 90 predictions finite metrics; objective = mean Dice over 9 conditions", all(isfinite(dice(:))) && height(grid) == 90
    "selection follows the pre-registered rule (strictly better than v4, tie -> lower complexity, ID)", ...
        ~v5Exists || objective(winnerIdx) > objective(1)
    "v4 frozen files unchanged AFTER; config.m unchanged", v4Ok() && isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];
for c = 1:size(checks, 1)
    fprintf('%-100s %s\n', checks{c, 1}, ternary(checks{c, 2}, 'ok', 'FAILED'));
end
if any(~[checks{:, 2}])
    error('exp061:checksFailed', 'EXP-061 checks failed.');
end
fprintf('\nEXP-061 CHECKS: PASS (%d)\n', size(checks, 1));


function out = ternary(condition, a, b)
%TERNARY a se condition è vero, altrimenti b.
    if condition
        out = a;
    else
        out = b;
    end
end

function h = sha256File(f)
%SHA256FILE Impronta SHA-256 (esadecimale maiuscolo) tramite certutil di Windows.
    [status, out] = system(sprintf('certutil -hashfile "%s" SHA256', f));
    lines = erase(strtrim(splitlines(string(out))), " ");
    match = lines(strlength(lines) == 64 & ~cellfun(@isempty, regexp(cellstr(lines), '^[0-9a-fA-F]{64}$')));
    if status ~= 0 || numel(match) ~= 1
        error('exp061:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end
