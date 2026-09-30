function cfg = config()
%CONFIG Configurazione centrale del progetto di segmentazione delle lesioni SM in BrainWeb.
%
%   cfg = CONFIG() restituisce una struttura contenente i percorsi e le
%   impostazioni di progetto attualmente note.
%
%   I parametri specifici del dataset e degli algoritmi devono essere
%   aggiunti solo dopo essere stati determinati tramite l'ispezione dei
%   dati o esperimenti controllati.
%
%   Nessun parametro di segmentazione che appartiene alla configurazione
%   di progetto deve essere scritto direttamente nelle funzioni di
%   elaborazione.

    %% Radice del progetto

    cfg.paths.projectRoot = fileparts(mfilename('fullpath'));


    %% Cartelle dei dati

    cfg.paths.data = fullfile(cfg.paths.projectRoot, 'data');

    cfg.paths.rawData = fullfile( ...
        cfg.paths.data, ...
        'raw');

    cfg.paths.processedData = fullfile( ...
        cfg.paths.data, ...
        'processed');


    %% Cartelle del codice sorgente

    cfg.paths.src = fullfile( ...
        cfg.paths.projectRoot, ...
        'src');

    cfg.paths.io = fullfile( ...
        cfg.paths.src, ...
        'io');

    cfg.paths.preprocessing = fullfile( ...
        cfg.paths.src, ...
        'preprocessing');

    cfg.paths.segmentation = fullfile( ...
        cfg.paths.src, ...
        'segmentation');

    cfg.paths.evaluation = fullfile( ...
        cfg.paths.src, ...
        'evaluation');

    cfg.paths.visualization = fullfile( ...
        cfg.paths.src, ...
        'visualization');


    %% Cartella degli esperimenti

    cfg.paths.experiments = fullfile( ...
        cfg.paths.projectRoot, ...
        'experiments');


    %% Cartelle dei risultati

    cfg.paths.results = fullfile( ...
        cfg.paths.projectRoot, ...
        'results');

    cfg.paths.figures = fullfile( ...
        cfg.paths.results, ...
        'figures');

    cfg.paths.metrics = fullfile( ...
        cfg.paths.results, ...
        'metrics');


    %% Cartella della documentazione

    cfg.paths.docs = fullfile( ...
        cfg.paths.projectRoot, ...
        'docs');


    %% Strategia di elaborazione

    % L'implementazione iniziale è volutamente 2D, slice per slice.
    % Le tecniche di elaborazione 3D richiedono una revisione esplicita
    % prima dell'uso.
    cfg.processing.dimension = "2D-slicewise";


    %% Configurazione del dataset
    %
    % Questi valori restano volutamente non definiti finché il dataset
    % BrainWeb effettivo non è stato ispezionato.

    cfg.dataset.case = "";
    cfg.dataset.modality = "";
    cfg.dataset.lesionConfiguration = "";
    cfg.dataset.noiseLevel = "";
    cfg.dataset.rfInhomogeneity = "";
    cfg.dataset.groundTruthType = "";


    %% Parametri degli algoritmi
    %
    % I parametri verranno aggiunti qui solo quando richiesti da una fase
    % di elaborazione implementata e giustificati da un esperimento.
    %
    % Esempio di struttura futura:
    %
    % cfg.preprocessing.gaussianSigma = ...
    % cfg.segmentation.thresholdMethod = ...
    % cfg.morphology.structuringElement = ...
    %
    % Non definire questi valori prima della fase di progetto
    % corrispondente.

end
