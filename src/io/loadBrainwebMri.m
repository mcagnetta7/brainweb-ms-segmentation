function volume = loadBrainwebMri(cfg, modality)
%LOADBRAINWEBMRI Carica un volume MRI BrainWeb del progetto.
%
%   volume = LOADBRAINWEBMRI(cfg, modality) restituisce il volume MRI
%   della modalità richiesta ("T1", "T2" o "PD"), usando file, dimensioni
%   e formato definiti in cfg.dataset.
%
%   Output: array uint16 di dimensioni cfg.dataset.volumeSize, con i
%   valori originali del file (0...4095) e la convenzione V(i,j,k),
%   i = X, j = Y, k = Z.

    arguments
        cfg (1,1) struct
        modality {mustBeTextScalar}
    end

    modality = upper(char(modality));

    if ~isfield(cfg.dataset.mriFiles, modality)
        error('brainweb:unsupportedModality', ...
            'Unsupported MRI modality "%s". Available: %s.', ...
            modality, strjoin(fieldnames(cfg.dataset.mriFiles), ', '));
    end

    volume = readBrainwebRaw( ...
        cfg.dataset.mriFiles.(modality), ...
        cfg.dataset.volumeSize, ...
        cfg.dataset.mriFormat.precision, ...
        cfg.dataset.mriFormat.byteOrder);

end
