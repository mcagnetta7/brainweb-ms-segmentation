function labels = loadBrainwebGroundTruth(cfg)
%LOADBRAINWEBGROUNDTRUTH Carica il modello anatomico discreto BrainWeb.
%
%   labels = LOADBRAINWEBGROUNDTRUTH(cfg) restituisce il volume delle
%   etichette dei tessuti del modello crisp definito in
%   cfg.dataset.groundTruthFile.
%
%   Output: array uint8 di dimensioni cfg.dataset.volumeSize con le
%   etichette originali (0...10), convenzione V(i,j,k), i = X, j = Y,
%   k = Z.
%
%   La funzione non costruisce la maschera binaria delle lesioni: quella
%   spetta alla fase di valutazione. Il ground truth serve solo per
%   valutazione e visualizzazione, mai come input della segmentazione.

    arguments
        cfg (1,1) struct
    end

    labels = readBrainwebRaw( ...
        cfg.dataset.groundTruthFile, ...
        cfg.dataset.volumeSize, ...
        cfg.dataset.groundTruthFormat.precision, ...
        cfg.dataset.groundTruthFormat.byteOrder);

end
