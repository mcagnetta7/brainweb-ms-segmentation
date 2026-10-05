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
    % Valori decisi e verificati nelle fasi 18-28
    % (vedi docs/BRAINWEB_DATASET_NOTES.md, sezione 13).

    cfg.dataset.case = "msles2";
    cfg.dataset.modality = "T2";            % modalità iniziale, provvisoria (fase 41)
    cfg.dataset.lesionConfiguration = "moderate";
    cfg.dataset.noiseLevel = "pn0";
    cfg.dataset.rfInhomogeneity = "rf0";
    cfg.dataset.groundTruthType = "crisp";


    %% File BrainWeb
    %
    % File originali, immutabili, scaricati nella fase 22.

    cfg.dataset.rawDir = fullfile( ...
        cfg.paths.rawData, ...
        'msles2');

    cfg.dataset.mriFiles.T1 = fullfile( ...
        cfg.dataset.rawDir, 'mri', 't1_ai_msles2_1mm_pn0_rf0.raws');

    cfg.dataset.mriFiles.T2 = fullfile( ...
        cfg.dataset.rawDir, 'mri', 't2_ai_msles2_1mm_pn0_rf0.raws');

    cfg.dataset.mriFiles.PD = fullfile( ...
        cfg.dataset.rawDir, 'mri', 'pd_ai_msles2_1mm_pn0_rf0.raws');

    % File MRI di sviluppo con rumore (protocollo della fase 36). Solo i
    % file effettivamente scaricati; nessuna configurazione di test.
    cfg.dataset.noisyMriFiles.pn3.T2 = fullfile( ...
        cfg.dataset.rawDir, 'mri', 't2_ai_msles2_1mm_pn3_rf0.raws');

    cfg.dataset.groundTruthFile = fullfile( ...
        cfg.dataset.rawDir, 'ground_truth', 'phantom_1.0mm_msles2_crisp.rawb');


    %% Formato e geometria dei file raw
    %
    % Verificati sui file scaricati (fasi 24-27). Il volume ricostruito
    % segue la convenzione V(i,j,k) con i = X, j = Y, k = Z; nel file X
    % varia più velocemente e Z più lentamente.

    cfg.dataset.volumeSize = [181 217 181];     % [X Y Z]

    % MRI "raw short (12 bit)": interi a 16 bit little-endian, valori
    % 0...4095. La documentazione BrainWeb indica big-endian, ma i file
    % scaricati sono little-endian (fase 24).
    cfg.dataset.mriFormat.precision = "uint16";
    cfg.dataset.mriFormat.byteOrder = "ieee-le";

    % Ground truth "raw byte (unsigned)": un byte per voxel, etichette
    % 0...10. L'ordine dei byte non ha effetto su dati a 8 bit.
    cfg.dataset.groundTruthFormat.precision = "uint8";
    cfg.dataset.groundTruthFormat.byteOrder = "ieee-le";


    %% Rappresentazione numerica di lavoro (fase 43)
    %
    % I volumi MRI vengono caricati come uint16 (valori grezzi 0...4095) e
    % convertiti in questo tipo per l'elaborazione, con un cast che
    % conserva i valori: nessuna normalizzazione, nessun riscalamento.

    cfg.preprocessing.workingClass = "double";


    %% Normalizzazione delle intensità (fase 44)
    %
    % Riscalamento lineare fisso dal dominio a 12 bit di BrainWeb a [0,1]:
    %   I_norm = (I - 0) / (4095 - 0)
    % I limiti non dipendono dall'immagine. Serve perché le funzioni MATLAB
    % per immagini assumono valori double in [0,1].

    cfg.preprocessing.normalization.method = "fixed-12bit";
    cfg.preprocessing.normalization.inputRange = [0 4095];
    cfg.preprocessing.normalization.outputRange = [0 1];


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
