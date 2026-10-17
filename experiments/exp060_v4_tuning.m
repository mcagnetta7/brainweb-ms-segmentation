%% EXP-060 (emendamento A3): v4 = v3 con soglia minima riferita alla sostanza bianca
% Griglia preregistrata: k in {nessuno (= v3), 3, 4, 5, 6} x 5 condizioni di sviluppo
% (pn0, pn3 precalcolati; msles1 / msles2 / msles3 custom AI, rumore 0).
% Soglia T2 = max(TA livello 2, muWM + k * sigmaWM), riferimento S2 AND T1-alto (senza GT).
% Ordine: integrità -> 25 predizioni salvate senza GT -> base = v3 voxel per voxel ->
% GT -> Dice -> regola di adozione preregistrata. Nessun held-out, nessun test riservato.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing, cfg.paths.segmentation, cfg.paths.evaluation);
configTextAtStart = fileread(fullfile(projectRoot, 'config.m'));
M = cfg.paths.metrics;

conditions = ["pn0" "pn3" "msles1" "msles2" "msles3"];
goodCases = ["pn0" "pn3" "msles2" "msles3"];
kGrid = [NaN 3 4 5 6];
kId = @(k) ternary(isnan(k), "none", "k" + k);
customDir = fullfile(projectRoot, 'data', 'raw', 'brainweb_custom', 'phase101');
custom = struct('msles1', {{'custom_msles1_t1_ai_1mm_n0_inu0_job1261017-050735s-2817767.raws', ...
    'custom_msles1_t2_ai_1mm_n0_inu0_job1261017-050750s-2817854.raws'}}, ...
    'msles2', {{'custom_msles2_t1_ai_1mm_n0_inu0_job1261017-050846s-2818122.raws', ...
    'custom_msles2_t2_ai_1mm_n0_inu0_job1261017-050720s-2817689.raws'}}, ...
    'msles3', {{'custom_msles3_t1_ai_1mm_n0_inu0_job1261017-050805s-2817935.raws', ...
    'custom_msles3_t2_ai_1mm_n0_inu0_job1261017-050820s-2818018.raws'}});
cfgDev = cfg;
for p = ["msles1" "msles2" "msles3"]
    cfgDev.dataset.noisyMriFiles.(p).T1 = fullfile(customDir, 'mri', custom.(p){1});
    cfgDev.dataset.noisyMriFiles.(p).T2 = fullfile(customDir, 'mri', custom.(p){2});
end
gtFile = struct('pn0', cfg.dataset.groundTruthFile, 'pn3', cfg.dataset.groundTruthFile, ...
    'msles1', fullfile(customDir, 'ground_truth', 'phantom_1.0mm_msles1_crisp.rawb'), ...
    'msles2', cfg.dataset.groundTruthFile, ...
    'msles3', fullfile(customDir, 'ground_truth', 'phantom_1.0mm_msles3_crisp.rawb'));
v3File = struct('pn0', fullfile(cfg.paths.processedData, 'phase95_exp059_v3_pn0_selected_prediction.mat'), ...
    'pn3', fullfile(cfg.paths.processedData, 'phase95_exp059_v3_pn3_selected_prediction.mat'), ...
    'msles1', fullfile(cfg.paths.processedData, 'phase101_v3_msles1_prediction.mat'), ...
    'msles2', fullfile(cfg.paths.processedData, 'phase101_v3_msles2_prediction.mat'), ...
    'msles3', fullfile(cfg.paths.processedData, 'phase101_v3_msles3_prediction.mat'));
candDir = fullfile(cfg.paths.processedData, 'exp060_candidates');
candFile = @(k, c) fullfile(candDir, sprintf('exp060_%s_%s.mat', kId(k), c));
checks = cell(0, 2);


%% 0. Integrità

manifest96 = readtable(fullfile(M, 'phase96_final_freeze_manifest.csv'), 'TextType', 'string', 'Delimiter', ',');
frozenOk = @() all(arrayfun(@(i) strcmp(sha256File(fullfile(projectRoot, manifest96.path(i))), manifest96.sha256(i)), ...
    1:height(manifest96)));
checks(end+1, :) = {"Phase-96 frozen v3 sources (26 hashes) unchanged BEFORE", frozenOk()};
mustPass(checks);


%% 1. 25 predizioni (NESSUN GT)

if ~isfolder(candDir)
    mkdir(candDir);
end
pred = cell(numel(kGrid), numel(conditions));
det = cell(numel(kGrid), numel(conditions));
for c = 1:numel(conditions)
    cond = conditions(c);
    rawT1 = loadBrainwebMri(cfgDev, "T1", cond);
    rawT2 = loadBrainwebMri(cfgDev, "T2", cond);
    for j = 1:numel(kGrid)
        [M_pred, d] = generateV4Prediction(rawT1, rawT2, kGrid(j));
        pred{j, c} = M_pred;
        d = rmfield(d, 'S2');
        det{j, c} = d;
        metadata = struct('experiment', "EXP-060", 'condition', cond, 'k', kGrid(j), 'details', d, ...
            'gtUsedForGeneration', false);
        save(candFile(kGrid(j), cond), 'M_pred', 'metadata');
    end
    fprintf('%s: TA2 %.4f, muWM %.4f, sigmaWM %.4f -> floors k3..6 [%s]\n', cond, det{1, c}.taLevels(2), ...
        det{1, c}.muWM, det{1, c}.sigmaWM, strjoin(compose('%.4f', cellfun(@(x) x.floorValue, det(2:end, c)).'), ' '));
end


%% 2. Base = v3 voxel per voxel; predizioni annidate al crescere di k (ancora senza GT)

baseOk = true; nestedOk = true;
for c = 1:numel(conditions)
    s = load(v3File.(conditions(c)), 'M_pred');
    baseOk = baseOk && isequal(pred{1, c}, s.M_pred);
    for j = 2:numel(kGrid)
        nestedOk = nestedOk && ~any(pred{j, c} & ~pred{j - 1, c}, 'all');
    end
end
checks = [checks; {
    "25 predictions generated and saved before any GT", all(cellfun(@(f) isfile(f), ...
        arrayfun(@(i) candFile(kGrid(1 + mod(i - 1, 5)), conditions(1 + floor((i - 1) / 5))), 1:25, 'UniformOutput', false)))
    "base k = none reproduces the saved v3 predictions voxel by voxel (5 conditions)", baseOk
    "predictions nested: larger k -> subset (threshold non-decreasing, opening increasing)", nestedOk
    }];
if ~baseOk
    error('exp060:technicallyBlocked', 'EXP-060 TECHNICALLY BLOCKED: base does not reproduce v3.');
end


%% 3. GT (solo ora), Dice e regola di adozione preregistrata

gridRows = cell(0, 15);
dice = zeros(numel(kGrid), numel(conditions));
for c = 1:numel(conditions)
    cfgGt = cfg; cfgGt.dataset.groundTruthFile = gtFile.(conditions(c));
    gt = loadBrainwebGroundTruth(cfgGt) == 10;
    for j = 1:numel(kGrid)
        cnt = computeVoxelConfusion(pred{j, c}, gt);
        dice(j, c) = computeDiceFromConfusion(cnt);
        d = det{j, c};
        gridRows(end+1, :) = {kId(kGrid(j)), kGrid(j), conditions(c), d.taLevels(2), d.muWM, d.sigmaWM, d.floorValue, ...
            d.threshold, d.floorActive, cnt.TP + cnt.FP, cnt.TP, cnt.FP, cnt.FN, dice(j, c), ...
            computePrecisionFromConfusion(cnt)}; %#ok<SAGROW>
    end
end
gridTable = cell2table(gridRows, 'VariableNames', {'configId', 'k', 'condition', 'taLevel2', 'muWM', 'sigmaWM', ...
    'floorValue', 'threshold', 'floorActive', 'predictedVoxels', 'tpVoxels', 'fpVoxels', 'fnVoxels', 'dice', 'precision'});
writetable(gridTable, fullfile(M, 'exp060_grid_results.csv'));

objective = mean(dice, 2);
goodIdx = ismember(conditions, goodCases);
worstDrop = max(dice(1, goodIdx) - dice(:, goodIdx), [], 2);
admissible = worstDrop <= 0.01;
ranking = table(string(arrayfun(kId, kGrid, 'UniformOutput', false)).', kGrid.', dice(:, 1), dice(:, 2), dice(:, 3), dice(:, 4), dice(:, 5), ...
    objective, objective - objective(1), worstDrop, admissible, 'VariableNames', {'configId', 'k', 'dicePn0', ...
    'dicePn3', 'diceMsles1', 'diceMsles2', 'diceMsles3', 'meanDevelopmentDice', 'deltaVsV3', ...
    'worstDropOnGoodCases', 'admissible'});
candidates = find(admissible & (1:numel(kGrid)).' > 1 & objective > objective(1));
if isempty(candidates)
    winnerIdx = 1; v4Exists = false;
else
    best = max(objective(candidates));
    tied = candidates(objective(candidates) == best);
    [~, pick] = max(kGrid(tied));            % parità esatta -> k più grande
    winnerIdx = tied(pick); v4Exists = true;
end
ranking.selected = (1:numel(kGrid)).' == winnerIdx & v4Exists;
writetable(ranking, fullfile(M, 'exp060_ranking.csv'));
disp(ranking);
fprintf('\nEXP-060 RESULT: %s\n\n', ternary(v4Exists, "v4 = " + kId(kGrid(winnerIdx)) + ...
    sprintf(' (mean development Dice %.6f vs v3 %.6f)', objective(winnerIdx), objective(1)), ...
    "no admissible improvement -> no v4, v3 stays"));
checks = [checks; {
    "objective = mean Dice over 5 development conditions; non-inferiority 0.01 on pn0 / pn3 / msles2 / msles3", ...
        height(ranking) == 5 && all(isfinite(dice(:)))
    "selection follows the pre-registered rule (admissible, strictly better than v3, tie -> larger k)", ...
        ~v4Exists || (admissible(winnerIdx) && objective(winnerIdx) > objective(1))
    }];


%% 4. Diagnostiche post-selezione (non cambiano la scelta)

if v4Exists
    diagRows = cell(0, 9);
    for c = 1:numel(conditions)
        cfgGt = cfg; cfgGt.dataset.groundTruthFile = gtFile.(conditions(c));
        gt = loadBrainwebGroundTruth(cfgGt) == 10;
        for j = [1 winnerIdx]
            lw = computeLesionWiseMatches(pred{j, c}, gt, 26);
            diagRows(end+1, :) = {conditions(c), kId(kGrid(j)), nnz(pred{j, c}), nnz(pred{j, c} & ~gt), ...
                lw.gtComponentCount, lw.detectedGtLesionCount, lw.predictedComponentCount, ...
                lw.falsePredictedComponentCount, dice(j, c)}; %#ok<SAGROW>
        end
    end
    diagTable = cell2table(diagRows, 'VariableNames', {'condition', 'configId', 'predictedVoxels', 'fpVoxels', ...
        'gtLesions', 'detectedGtLesions', 'predictedComponents', 'falsePredictedComponents', 'dice'});
    writetable(diagTable, fullfile(M, 'exp060_v3_vs_v4_diagnostics.csv'));
    disp(diagTable);
end


%% 5. Controlli finali

scriptCode = strjoin(regexprep(splitlines(string(fileread([mfilename('fullpath') '.m']))), '%.*$', ''), newline);
forbidden = {['p' 'n1'], ['p' 'n5'], ['p' 'n7'], ['p' 'n9'], ['seed' '2'], ['nor' 'mal_'], ['"P' 'D"']};
checks = [checks; {
    "no held-out condition, no reserved-test data, no PD in this script", ~any(cellfun(@(f) contains(scriptCode, f), forbidden))
    "Phase-96 frozen v3 sources unchanged AFTER; config.m unchanged", frozenOk() && ...
        isequal(fileread(fullfile(projectRoot, 'config.m')), configTextAtStart)
    }];
for c = 1:size(checks, 1)
    fprintf('%-100s %s\n', checks{c, 1}, ternary(checks{c, 2}, 'ok', 'FAILED'));
end
if any(~[checks{:, 2}])
    error('exp060:checksFailed', 'EXP-060 checks failed.');
end
fprintf('\nEXP-060 CHECKS: PASS (%d)\n', size(checks, 1));


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
        error('exp060:hashFailed', 'SHA-256 computation failed for %s', f);
    end
    h = upper(char(match));
end

function mustPass(checks)
%MUSTPASS Interrompe EXP-060 se un controllo preliminare fallisce.
    failed = find(~[checks{:, 2}]);
    if ~isempty(failed)
        error('exp060:technicallyBlocked', 'EXP-060 TECHNICALLY BLOCKED: %s', checks{failed(1), 1});
    end
end
