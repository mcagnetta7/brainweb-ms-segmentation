%% Validazione del loader BrainWeb (fase 30)
% Esegue il loader reale di src/io sui quattro file del dataset iniziale
% e controlla dimensioni, numero di voxel, tipo, intervallo dei valori,
% NaN/Inf ed etichette del ground truth.
%
% Solo lettura: nessuna figura, nessun file scritto, nessuna elaborazione.
% I valori attesi sono invarianti verificati nelle fasi 22-28
% (docs/BRAINWEB_DATASET_NOTES.md, sezioni 13.5-13.7).

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io);

expectedSize = cfg.dataset.volumeSize;
expectedNumel = prod(expectedSize);
expectedMriMax = 4095;              % raw short a 12 bit (fase 24)
expectedLabels = 0:10;              % etichette del modello crisp (fase 24)
expectedLesionVoxels = 3512;        % voxel con etichetta 10 (fasi 22-24)

checks = {};    % {descrizione, esito}


%% Caricamento con il loader reale

volumes = struct();                 % evita conflitti con variabili già nel workspace
volumes.T1 = loadBrainwebMri(cfg, "T1");
volumes.T2 = loadBrainwebMri(cfg, "T2");
volumes.PD = loadBrainwebMri(cfg, "PD");
volumes.GT = loadBrainwebGroundTruth(cfg);


%% Controlli per volume

names = fieldnames(volumes);
for n = 1:numel(names)
    name = names{n};
    V = volumes.(name);
    isGt = strcmp(name, 'GT');

    if isGt
        expectedClass = char(cfg.dataset.groundTruthFormat.precision);
    else
        expectedClass = char(cfg.dataset.mriFormat.precision);
    end

    hasNanInf = any(isnan(V(:))) || any(isinf(V(:)));
    vMin = min(V(:));
    vMax = max(V(:));

    fprintf('%-2s  size=[%s]  numel=%d  class=%s  min=%d  max=%d  NaN/Inf=%s\n', ...
        name, num2str(size(V)), numel(V), class(V), vMin, vMax, mat2str(hasNanInf));

    checks(end+1, :) = {[name ' size'], isequal(size(V), expectedSize)};
    checks(end+1, :) = {[name ' numel'], numel(V) == expectedNumel};
    checks(end+1, :) = {[name ' class'], strcmp(class(V), expectedClass)};
    checks(end+1, :) = {[name ' no NaN/Inf'], ~hasNanInf};

    if isGt
        labels = unique(V(:))';
        lesionVoxels = nnz(V == 10);
        fprintf('    labels=%s  label10 voxels=%d\n', mat2str(labels), lesionVoxels);
        checks(end+1, :) = {'GT labels 0...10', isequal(double(labels), expectedLabels)};
        checks(end+1, :) = {'GT label10 count', lesionVoxels == expectedLesionVoxels};
    else
        checks(end+1, :) = {[name ' range 0...4095'], vMin >= 0 && vMax <= expectedMriMax};
    end
end


%% Coerenza strutturale tra volumi

sizeT1 = size(volumes.T1);
checks(end+1, :) = {'size T1 == T2', isequal(sizeT1, size(volumes.T2))};
checks(end+1, :) = {'size T1 == PD', isequal(sizeT1, size(volumes.PD))};
checks(end+1, :) = {'size T1 == GT', isequal(sizeT1, size(volumes.GT))};


%% Gestione degli errori del loader

try
    readBrainwebRaw(fullfile(cfg.paths.rawData, 'missing_file.raws'), ...
        expectedSize, "uint16", "ieee-le");
    missingFileOk = false;
catch err
    missingFileOk = strcmp(err.identifier, 'brainweb:fileNotFound');
end
checks(end+1, :) = {'error: missing file', missingFileOk};

try
    readBrainwebRaw(cfg.dataset.mriFiles.T1, [181 217 180], "uint16", "ieee-le");
    wrongSizeOk = false;
catch err
    wrongSizeOk = strcmp(err.identifier, 'brainweb:wrongFileSize');
end
checks(end+1, :) = {'error: wrong dimensions', wrongSizeOk};

try
    loadBrainwebMri(cfg, "FLAIR");
    wrongModalityOk = false;
catch err
    wrongModalityOk = strcmp(err.identifier, 'brainweb:unsupportedModality');
end
checks(end+1, :) = {'error: unsupported modality', wrongModalityOk};


%% Esito

fprintf('\n');
for c = 1:size(checks, 1)
    fprintf('%-28s %s\n', checks{c, 1}, ternary(checks{c, 2}));
end

if all([checks{:, 2}])
    fprintf('\nLOADER VALIDATION: PASS\n');
else
    fprintf('\nLOADER VALIDATION: FAIL\n');
end


function text = ternary(passed)
    if passed
        text = 'ok';
    else
        text = 'FAILED';
    end
end
