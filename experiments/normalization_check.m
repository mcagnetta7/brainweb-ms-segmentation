%% Validazione della normalizzazione (fase 44)
% Carica la MRI della modalità iniziale (T2, msles2, 1 mm, pn0, rf0),
% applica la conversione della fase 43 e la normalizzazione fissa della
% fase 44, e verifica che il risultato corrisponda esattamente alla
% formula documentata.
%
% Mostra anche, su pochi valori scalari, perché serve [0,1]: im2uint8,
% usato internamente dalle funzioni MATLAB per immagini double, satura
% ogni valore sopra 1. Nessun ground truth, nessun filtro, nessuna soglia.
% Se un controllo fallisce lo script si interrompe con un errore.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing);

normalization = cfg.preprocessing.normalization;
assert(normalization.method == "fixed-12bit", 'Unexpected normalization method.');

rawVolume = loadBrainwebMri(cfg, cfg.dataset.modality);
workingVolume = convertToWorkingClass(rawVolume, cfg.preprocessing.workingClass);
workingCopy = workingVolume;

normalizedVolume = normalizeFixedRange(workingVolume, ...
    normalization.inputRange, normalization.outputRange);


%% Controlli

expected = workingVolume / 4095;                    % formula documentata

rawEdges = -0.5:1:4095.5;
uniqueIn = unique(workingVolume(:));
uniqueOut = unique(normalizedVolume(:));

checks = {
    'size unchanged',                 isequal(size(normalizedVolume), size(workingVolume))
    'class double',                   isa(normalizedVolume, 'double')
    'all values finite',              all(isfinite(normalizedVolume(:)))
    'values within [0,1]',            min(normalizedVolume(:)) >= 0 && max(normalizedVolume(:)) <= 1
    '0 maps to 0',                    all(normalizedVolume(workingVolume == 0) == 0)
    '4095 maps to 1',                 all(normalizedVolume(workingVolume == 4095) == 1)
    'exactly I / 4095',               isequal(normalizedVolume, expected)
    'ordering preserved',             numel(uniqueOut) == numel(uniqueIn) && all(diff(uniqueOut) > 0)
    'histogram shape preserved',      isequal(histcounts(workingVolume(:), rawEdges), ...
                                              histcounts(normalizedVolume(:), rawEdges / 4095))
    'working volume unchanged',       isequal(workingVolume, workingCopy)
    'raw data unchanged',             isequal(rawVolume, loadBrainwebMri(cfg, cfg.dataset.modality))
};


%% Test negativi: valori fuori intervallo devono essere rifiutati, non tagliati

invalidInputs = {[0 -1], [0 4096], [0 NaN], [0 Inf]};
for n = 1:numel(invalidInputs)
    value = invalidInputs{n};
    try
        normalizeFixedRange(value, normalization.inputRange, normalization.outputRange);
        rejected = false;
    catch err
        rejected = strcmp(err.identifier, 'preprocessing:valueOutOfRange');
    end
    checks(end+1, :) = {sprintf('reject %s', mat2str(value)), rejected}; %#ok<SAGROW>
end

fprintf('\n%s  -  %s 1mm %s %s\n', cfg.dataset.modality, cfg.dataset.case, ...
    cfg.dataset.noiseLevel, cfg.dataset.rfInhomogeneity);
fprintf('working:    class=%s  range=[%g %g]\n', class(workingVolume), ...
    min(workingVolume(:)), max(workingVolume(:)));
fprintf('normalized: class=%s  range=[%g %g]\n', class(normalizedVolume), ...
    min(normalizedVolume(:)), max(normalizedVolume(:)));

% Dimostrazione su valori scalari (nessun volume): im2uint8 assume [0,1]
demo = [0 0.5 1 2 4095];
fprintf('im2uint8([%s]) = [%s]\n\n', num2str(demo), num2str(im2uint8(demo)));

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-28s %s\n', checks{c, 1}, result);
end

if ~all([checks{:, 2}])
    error('phase44:validationFailed', 'PHASE 44 CHECKS: FAIL');
end
fprintf('\nPHASE 44 CHECKS: PASS\n');
