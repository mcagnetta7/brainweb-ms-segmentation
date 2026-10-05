function volume = loadBrainwebMri(cfg, modality, noiseLevel)
%LOADBRAINWEBMRI Carica un volume MRI BrainWeb del progetto.
%
%   volume = LOADBRAINWEBMRI(cfg, modality) restituisce il volume MRI
%   della modalità richiesta ("T1", "T2" o "PD") nella configurazione
%   principale (cfg.dataset.noiseLevel, pn0), usando file, dimensioni e
%   formato definiti in cfg.dataset.
%
%   volume = LOADBRAINWEBMRI(cfg, modality, noiseLevel) carica invece la
%   configurazione con rumore indicata (es. "pn3"), se presente in
%   cfg.dataset.noisyMriFiles.
%
%   Output: array uint16 di dimensioni cfg.dataset.volumeSize, con i
%   valori originali del file (0...4095) e la convenzione V(i,j,k),
%   i = X, j = Y, k = Z.

    arguments
        cfg (1,1) struct
        modality {mustBeTextScalar}
        noiseLevel {mustBeTextScalar} = cfg.dataset.noiseLevel
    end

    modality = upper(char(modality));
    noiseLevel = char(noiseLevel);

    if strcmp(noiseLevel, cfg.dataset.noiseLevel)
        files = cfg.dataset.mriFiles;
    elseif isfield(cfg.dataset, 'noisyMriFiles') && isfield(cfg.dataset.noisyMriFiles, noiseLevel)
        files = cfg.dataset.noisyMriFiles.(noiseLevel);
    else
        error('brainweb:unsupportedNoiseLevel', ...
            'No MRI files configured for noise level "%s".', noiseLevel);
    end

    if ~isfield(files, modality)
        error('brainweb:unsupportedModality', ...
            'Unsupported MRI modality "%s" for noise level "%s". Available: %s.', ...
            modality, noiseLevel, strjoin(fieldnames(files), ', '));
    end

    volume = readBrainwebRaw( ...
        files.(modality), ...
        cfg.dataset.volumeSize, ...
        cfg.dataset.mriFormat.precision, ...
        cfg.dataset.mriFormat.byteOrder);

end
