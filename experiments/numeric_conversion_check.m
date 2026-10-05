%% Validazione della conversione numerica (fase 43)
% Carica la MRI della modalità iniziale (T2, msles2, 1 mm, pn0, rf0), la
% converte nel tipo di lavoro configurato (cfg.preprocessing.workingClass)
% e verifica che ogni voxel conservi esattamente il proprio valore.
%
% Verifica anche, solo come documentazione, che single rappresenti
% esattamente i valori 0...4095 e che uint8 non possa contenerli. Nessuna
% copia del volume viene salvata; nessun ground truth. Se un controllo
% fallisce lo script si interrompe con un errore.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.preprocessing);

modality = cfg.dataset.modality;
workingClass = char(cfg.preprocessing.workingClass);

inputVolume = loadBrainwebMri(cfg, modality);
inputCopy = inputVolume;
workingVolume = convertToWorkingClass(inputVolume, workingClass);

inputValues = double(inputVolume);          % confronto in un tipo comune

% Verifiche documentali su single e uint8 (nessun volume salvato o usato)
singleExact = isequal(double(single(inputVolume)), inputValues);
voxelsAbove255 = nnz(inputVolume > intmax('uint8'));


%% Controlli

checks = {
    'input class uint16',            isa(inputVolume, 'uint16')
    'output class = working class',  isa(workingVolume, workingClass)
    'size unchanged',                isequal(size(workingVolume), size(inputVolume))
    'every voxel value preserved',   isequal(double(workingVolume), inputValues)
    'zero differing voxels',         nnz(double(workingVolume) ~= inputValues) == 0
    'min unchanged',                 double(min(workingVolume(:))) == double(min(inputVolume(:)))
    'max unchanged',                 double(max(workingVolume(:))) == double(max(inputVolume(:)))
    'no NaN/Inf',                    ~any(isnan(workingVolume(:)) | isinf(workingVolume(:)))
    'loader output untouched',       isequal(inputVolume, inputCopy)
    'single also exact (doc only)',  singleExact
    'uint8 unsuitable (max > 255)',  voxelsAbove255 > 0
};

fprintf('\n%s  -  %s 1mm %s %s\n', modality, cfg.dataset.case, ...
    cfg.dataset.noiseLevel, cfg.dataset.rfInhomogeneity);
fprintf('input:  class=%s  size=[%s]  min=%d  max=%d\n', class(inputVolume), ...
    num2str(size(inputVolume)), min(inputVolume(:)), max(inputVolume(:)));
fprintf('output: class=%s  size=[%s]  min=%g  max=%g\n', class(workingVolume), ...
    num2str(size(workingVolume)), min(workingVolume(:)), max(workingVolume(:)));
fprintf('voxels above 255 (cannot fit uint8): %d of %d\n\n', voxelsAbove255, numel(inputVolume));

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-32s %s\n', checks{c, 1}, result);
end

if ~all([checks{:, 2}])
    error('phase43:validationFailed', 'PHASE 43 CHECKS: FAIL');
end
fprintf('\nPHASE 43 CHECKS: PASS\n');
