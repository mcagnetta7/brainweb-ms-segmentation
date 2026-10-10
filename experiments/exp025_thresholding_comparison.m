%% EXP-025 (fase 57): confronto quantitativo dei metodi di soglia di base
% Primo confronto con il ground truth. Valuta le maschere candidate SALVATE
% (congelate) di EXP-022 (manuale), EXP-023 (iterativa) ed EXP-024 (Otsu):
% non rigenera nulla e non stima soglie.
%   - GT: crisp msles2 (loadBrainwebGroundTruth), M_GT = (labels == 10),
%     lo stesso per pn0 e pn3, NON intersecato con la maschera cerebrale
%   - metrica: Dice 3D sul volume completo 181x217x181 (nessuna media per
%     slice)
%   - punteggio (fase 37): DevelopmentScore = (Dice_pn0 + Dice_pn3) / 2
%   - nessuna tolleranza di quasi-parità (preregistrata nel log): vince il
%     DevelopmentScore numericamente più alto; spareggi solo in caso di
%     parità esatta: min(Dice_pn0, Dice_pn3), poi semplicità
%   - nessun'altra metrica formale (IoU, precision, recall, ... nelle fasi
%     di valutazione successive); nessun dato held-out
% Il risultato sceglie il metodo di soglia INIZIALE, non la pipeline finale.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io);

expectedSize = [181 217 181];
conditions = ["pn0" "pn3"];
methods = {
    "Manual global threshold",    "EXP-022", "exp022_t2_%s_manual_global_threshold_candidate.mat"
    "Iterative global threshold", "EXP-023", "exp023_t2_%s_iterative_threshold_candidate.mat"
    "Otsu global threshold",      "EXP-024", "exp024_t2_%s_otsu_threshold_candidate.mat"
    };
nMethods = size(methods, 1);
checks = cell(0, 2);


%% 0. Controllo sintetico del calcolo del Dice (prima di qualsiasi dato reale)

A = false(4, 4); A(1:2, 1:2) = true;            % 4 voxel
B = false(4, 4); B(1:2, 2:3) = true;            % 4 voxel, 2 in comune con A
C = false(4, 4); C(3:4, 3:4) = true;            % disgiunto da A
checks(end+1, :) = {"synthetic: identical masks -> Dice 1", diceCoefficient(A, A) == 1};
checks(end+1, :) = {"synthetic: disjoint masks -> Dice 0", diceCoefficient(A, C) == 0};
checks(end+1, :) = {"synthetic: partial overlap -> 2*2/(4+4)", diceCoefficient(A, B) == 0.5};
checks(end+1, :) = {"synthetic: symmetry Dice(A,B) = Dice(B,A)", diceCoefficient(A, B) == diceCoefficient(B, A)};
checks(end+1, :) = {"synthetic: Dice inside [0,1]", all([diceCoefficient(A, B) diceCoefficient(A, C)] >= 0 & ...
    [diceCoefficient(A, B) diceCoefficient(A, C)] <= 1)};
if any(~[checks{:, 2}])
    error('exp025:diceCheckFailed', 'Synthetic Dice sanity checks failed.');
end


%% 1. Ground truth (solo valutazione)

labels = loadBrainwebGroundTruth(cfg);
gtMask = labels == 10;
checks(end+1, :) = {"GT size 181x217x181", isequal(size(labels), expectedSize)};
checks(end+1, :) = {"GT labels inside 0...10", all(labels(:) <= 10)};
checks(end+1, :) = {"GT lesion mask logical", islogical(gtMask)};
checks(end+1, :) = {"GT lesion voxels > 0", nnz(gtMask) > 0};
gtVoxels = nnz(gtMask);
gtCopy = gtMask;


%% 2. Dice per metodo e condizione sulle maschere salvate

rows = cell(0, 8);
predictions = cell(nMethods, 2);
thresholdContext = strings(nMethods, 2);
for m = 1:nMethods
    for n = 1:2
        condition = conditions(n);
        file = fullfile(cfg.paths.processedData, sprintf(methods{m, 3}, condition));
        label = methods{m, 2} + " " + condition;
        checks(end+1, :) = {label + " file exists", isfile(file)}; %#ok<SAGROW>
        if ~isfile(file)
            error('exp025:technicallyBlocked', 'EXP-025 TECHNICALLY BLOCKED: missing %s.', file);
        end
        saved = load(file, 'lesionCandidateMask', 'metadata');
        prediction = saved.lesionCandidateMask;
        predictionCopy = prediction;

        inputChecks = {
            label + " prediction size = GT size",   isequal(size(prediction), size(gtMask))
            label + " prediction logical",          islogical(prediction)
            label + " metadata experiment matches", string(saved.metadata.experiment) == methods{m, 2}
            label + " metadata condition matches",  string(saved.metadata.condition) == condition
            };
        checks = [checks; inputChecks]; %#ok<AGROW>
        if any(~[inputChecks{:, 2}])
            error('exp025:technicallyBlocked', 'EXP-025 TECHNICALLY BLOCKED: invalid prediction %s.', label);
        end

        intersection = nnz(prediction & gtMask);
        denominator = nnz(prediction) + gtVoxels;
        dice = diceCoefficient(prediction, gtMask);
        checks = [checks; {
            label + " Dice denominator > 0",        denominator > 0
            label + " Dice finite in [0,1]",        isfinite(dice) && dice >= 0 && dice <= 1
            label + " Dice = 2*|P&G|/(|P|+|G|)",    dice == 2 * intersection / denominator
            label + " prediction unchanged",        isequal(prediction, predictionCopy)
            }]; %#ok<AGROW>

        % Contesto (non entra nella selezione): soglia salvata nei metadati
        md = saved.metadata;
        if isfield(md, 'thresholdRaw')
            thresholdContext(m, n) = sprintf('%.4f', md.thresholdRaw);
        elseif isfield(md, 'finalThresholdRawEquivalent')
            thresholdContext(m, n) = sprintf('%.4f', md.finalThresholdRawEquivalent);
        else
            thresholdContext(m, n) = sprintf('%.4f', md.thresholdRawEquivalent);
        end

        rows(end+1, :) = {methods{m, 1}, methods{m, 2}, condition, nnz(prediction), gtVoxels, ...
            intersection, dice, thresholdContext(m, n)}; %#ok<SAGROW>
        predictions{m, n} = prediction;
    end
end
byCondition = cell2table(rows, 'VariableNames', {'method', 'experiment', 'condition', 'predictedVoxels', ...
    'gtVoxels', 'intersectionVoxels', 'dice', 'thresholdRawEquivalentContext'});


%% 3. DevelopmentScore, classifica e selezione (regola preregistrata)

dicePn0 = zeros(nMethods, 1);
dicePn3 = zeros(nMethods, 1);
for m = 1:nMethods
    dicePn0(m) = byCondition.dice(byCondition.experiment == methods{m, 2} & byCondition.condition == "pn0");
    dicePn3(m) = byCondition.dice(byCondition.experiment == methods{m, 2} & byCondition.condition == "pn3");
end
developmentScore = (dicePn0 + dicePn3) / 2;
weakerConditionDice = min(dicePn0, dicePn3);

% Ordine: DevelopmentScore decrescente; a parità esatta, Dice della
% condizione più debole decrescente (poi semplicità: ordine del registro
% manuale -> iterativa -> Otsu non usato salvo parità totale)
[~, order] = sortrows([-developmentScore, -weakerConditionDice, (1:nMethods)']);
rank = zeros(nMethods, 1);
rank(order) = 1:nMethods;
selected = rank == 1;
exactTieAtTop = nnz(developmentScore == max(developmentScore)) > 1;

comparison = table(string(methods(:, 1)), string(methods(:, 2)), dicePn0, dicePn3, weakerConditionDice, ...
    developmentScore, rank, selected, 'VariableNames', {'method', 'experiment', 'dicePn0', 'dicePn3', ...
    'weakerConditionDice', 'developmentScore', 'rank', 'selected'});
comparison = sortrows(comparison, 'rank');

checks(end+1, :) = {"exactly three methods compared", height(comparison) == 3};
checks(end+1, :) = {"each method has pn0 and pn3", height(byCondition) == 6 && ...
    all(groupcounts(byCondition.experiment) == 2)};
checks(end+1, :) = {"only development conditions present", all(ismember(byCondition.condition, ["pn0" "pn3"]))};
checks(end+1, :) = {"DevelopmentScore = (pn0 + pn3)/2 exactly", ...
    all(comparison.developmentScore == (comparison.dicePn0 + comparison.dicePn3) / 2)};
checks(end+1, :) = {"weakerConditionDice = min(pn0, pn3)", ...
    all(comparison.weakerConditionDice == min(comparison.dicePn0, comparison.dicePn3))};
checks(end+1, :) = {"selected method has max DevelopmentScore", ...
    comparison.developmentScore(comparison.selected) == max(comparison.developmentScore)};
checks(end+1, :) = {"GT mask unchanged", isequal(gtMask, gtCopy)};

writetable(byCondition, fullfile(cfg.paths.metrics, 'exp025_thresholding_dice_by_condition.csv'));
writetable(comparison, fullfile(cfg.paths.metrics, 'exp025_thresholding_method_comparison.csv'));
reloaded = readtable(fullfile(cfg.paths.metrics, 'exp025_thresholding_method_comparison.csv'), 'TextType', 'string');
checks(end+1, :) = {"saved comparison CSV reproduces scores", ...
    max(abs(reloaded.developmentScore - comparison.developmentScore)) < 1e-12 && ...
    isequal(reloaded.experiment, comparison.experiment)};

scriptText = fileread([mfilename('fullpath') '.m']);
forbidden = {['gray' 'thresh('], ['estimateIterative' 'Threshold('], ['thresholdLesion' 'Candidates('], ...
    ['imerode' '('], ['imdilate' '('], ['bwconn' 'comp('], ['bwarea' 'open(']};
checks(end+1, :) = {"no estimator/generator/morphology called", ~any(cellfun(@(f) contains(scriptText, f), forbidden))};

disp(byCondition);
disp(comparison);
fprintf('GT lesion voxels (label 10): %d; exact tie at the top: %d\n', gtVoxels, exactTieAtTop);
fprintf('SELECTED INITIAL THRESHOLDING METHOD: %s (%s), DevelopmentScore = %.6f\n\n', ...
    comparison.method(1), comparison.experiment(1), comparison.developmentScore(1));


%% 4. Figura quantitativa

fig = figure('Color', 'w');
ax = axes(fig);
values = [dicePn0, dicePn3, developmentScore];          % ordine del registro: manuale, iterativa, Otsu
bar(ax, categorical(string(methods(:, 1)), string(methods(:, 1))), values);
ylabel(ax, '3D Dice (full volume)');
legend(ax, 'Dice pn0', 'Dice pn3', 'DevelopmentScore', 'Location', 'northeast');
title(ax, 'EXP-025 - thresholding methods, development Dice (pn0, pn3) and DevelopmentScore');
grid(ax, 'on');
fig.Position(3:4) = [850 500];
exportgraphics(fig, fullfile(cfg.paths.figures, 'exp025_thresholding_dice_comparison.png'));


%% 5. Figura diagnostica (dopo il calcolo di tutti i Dice; non influisce sulla selezione)
% giallo = previsione e GT, rosso = solo previsione, verde = solo GT.
% k = 46 / 91 / 136 fisse; k = 102 è una slice diagnostica già nota da
% ispezioni precedenti del GT e non entra nella selezione.

prepare = @(raw) normalizeFixedRange( ...
    convertToWorkingClass(raw, cfg.preprocessing.workingClass), ...
    cfg.preprocessing.normalization.inputRange, ...
    cfg.preprocessing.normalization.outputRange);
addpath(cfg.paths.preprocessing);
diagnosticSlices = [46 91 102 136];
for n = 1:2
    t2 = prepare(loadBrainwebMri(cfg, "T2", conditions(n)));
    fig = figure('Color', 'w');
    layout = tiledlayout(fig, nMethods, numel(diagnosticSlices), 'TileSpacing', 'tight', 'Padding', 'tight');
    title(layout, sprintf(['EXP-025 diagnostic (after scoring) - T2 %s: yellow = prediction & GT, ' ...
        'red = prediction only, green = GT only'], conditions(n)), 'Interpreter', 'none');
    for m = 1:nMethods
        for k = diagnosticSlices
            ax = nexttile(layout);
            image(ax, errorOverlay(t2(:, :, k), predictions{m, n}(:, :, k), gtMask(:, :, k)));
            axis(ax, 'image');
            set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
            title(ax, sprintf('%s k=%d', methods{m, 2}, k), 'FontSize', 8);
        end
    end
    fig.Position(3:4) = [1500 1150];
    exportgraphics(fig, fullfile(cfg.paths.figures, sprintf('exp025_t2_%s_error_overlay.png', conditions(n))), ...
        'Resolution', 150);
end


%% Esito dei controlli

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-48s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('exp025:checksFailed', 'EXP-025 technical checks failed.');
end
fprintf('\nEXP-025 CHECKS: PASS\n');


function dice = diceCoefficient(prediction, reference)
%DICECOEFFICIENT Dice 3D sul volume completo: 2|P & G| / (|P| + |G|).
    denominator = nnz(prediction) + nnz(reference);
    if denominator == 0
        error('exp025:emptyDice', 'Dice undefined for two empty masks.');
    end
    dice = 2 * nnz(prediction & reference) / denominator;
end

function rgb = errorOverlay(sliceImage, predictionSlice, gtSlice)
%ERROROVERLAY T2 con previsione e GT a colori (solo visualizzazione diagnostica).
    gray = sliceImage.';
    p = predictionSlice.';
    g = gtSlice.';
    red = gray; green = gray; blue = gray;
    both = p & g; onlyP = p & ~g; onlyG = ~p & g;
    red(both) = 1; green(both) = 1; blue(both) = 0;
    red(onlyP) = 1; green(onlyP) = 0; blue(onlyP) = 0;
    red(onlyG) = 0; green(onlyG) = 1; blue(onlyG) = 0;
    rgb = cat(3, red, green, blue);
end
