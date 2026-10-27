function [M_pred, details] = generateV4Prediction(rawT1, rawT2, k)
%GENERATEV4PREDICTION Pipeline v3 con soglia minima riferita alla sostanza bianca (EXP-060, v4).
%
%   [M_pred, details] = GENERATEV4PREDICTION(rawT1, rawT2, k) ripete la pipeline
%   congelata v3 (D3_M1_G0) con gli stessi helper, cambiando solo la soglia del T2:
%
%       soglia = max(TA livello 2, muWM + k * sigmaWM)
%
%   dove muWM e sigmaWM sono media e deviazione standard (std, N-1) del T2 filtrato
%   (D3) dentro S2 AND T1-alto (classe 3 della partizione T1 congelata): riferimento
%   ricavato dall'immagine, senza GT. Con k = NaN la soglia è TA livello 2 (= v3).
%
%   Passi: normalizzazione fissa 0..4095 -> 0..1; maschera EXP-021 (initialSupportMask,
%   brainMask3DErodeSelectDilate sfera 3, 26); S2 (computeT1AnatomicalSupport, T1 non
%   filtrato); D3 (anisotropicDiffusionVolume3D, controllo e limitazione a [0,1]);
%   TA = multithresh(T2f(S2), 2); candidato = S2 AND T2f > soglia; una apertura 2D
%   diamond 1 per slice, AND S2. Nessun GT, nessun accesso a file.
%
%   k: NaN (nessun minimo) oppure uno scalare della griglia preregistrata {3, 4, 5, 6}.
%
%   Ingressi:
%     rawT1, rawT2  volumi grezzi letti dal file (interi 0..4095, 181 x 217 x 181)
%     k             coefficiente della soglia minima; nella v4 finale k = 5
%   Uscite:
%     M_pred        maschera logica delle lesioni (vero = lesione), stesse dimensioni
%     details       struttura con soglie e conteggi intermedi (solo per controllo)
%
%   Nota sui nomi: muWM / sigmaWM corrispondono a mu_ref / sigma_ref della relazione;
%   la regione di riferimento è "WM-like" (ricavata dalla T1), non una segmentazione
%   della sostanza bianca.

    % --- Validazione degli ingressi ------------------------------------------------
    % Il blocco arguments fa controllare a MATLAB tipo e forma degli ingressi prima
    % di eseguire la funzione: T1 e T2 devono essere array 3D di numeri reali, k uno scalare.
    arguments
        rawT1 (:, :, :) {mustBeNumeric, mustBeReal}
        rawT2 (:, :, :) {mustBeNumeric, mustBeReal}
        k (1, 1) double
    end

    % k ammesso: NaN (nessuna soglia minima, comportamento identico alla v3) oppure
    % uno dei valori della griglia di scelta {3, 4, 5, 6}.
    if ~(isnan(k) || ismember(k, [3 4 5 6]))
        error('generateV4Prediction:invalidK', 'k must be NaN or one of 3, 4, 5, 6 (EXP-060 grid).');
    end
    % T1 e T2 vengono combinate voxel per voxel: devono avere le stesse dimensioni.
    if ~isequal(size(rawT1), size(rawT2))
        error('generateV4Prediction:sizeMismatch', 'T1 and T2 volumes must have the same size.');
    end

    % --- 1. Conversione e normalizzazione (relazione, Sezione 3.2) -------------------
    % Funzione anonima: conversione esatta in double, poi trasformazione lineare a
    % intervallo fisso [0, 4095] -> [0, 1] (intervallo nominale BrainWeb, non stimato).
    normalize = @(raw) normalizeFixedRange(convertToWorkingClass(raw, "double"), [0 4095], [0 1]);
    % Volumi normalizzati T1n e T2n.
    t1Norm = normalize(rawT1);
    t2Norm = normalize(rawT2);

    % --- 2. Maschera cerebrale e supporto S2, solo dalla T1 (Sezioni 3.3-3.4) -------
    % Soglia di Otsu globale sulla T1: maschera grezza di primo piano e valore della soglia.
    [rawForeground, brainMaskThreshold] = initialSupportMask(t1Norm);
    % Maschera cerebrale B: erosione 3D (sfera di raggio 3), componente connessa 3D
    % più grande (connettività 26), dilatazione limitata alla maschera grezza,
    % riempimento dei buchi slice per slice.
    brainMask = brainMask3DErodeSelectDilate(rawForeground, 3, 26);
    % Partizione della T1 dentro B in tre classi (Low / media / High) e supporti S0, S1, S2;
    % supportDetails contiene le due soglie della T1, riusate più avanti.
    [supports, supportDetails] = computeT1AnatomicalSupport(t1Norm, brainMask);
    % S2 = B AND High riempita slice per slice AND NOT Low: zona in cui cercare le lesioni.
    S2 = supports.S2;

    % --- 3. Filtraggio della T2 (Sezione 3.5) ---------------------------------------
    % Diffusione anisotropa 3D (Perona-Malik): 5 iterazioni, conduzione esponenziale,
    % 26 vicini, soglia del gradiente 0,10 x range del volume.
    t2f = anisotropicDiffusionVolume3D(t2Norm);
    % Quanto il risultato esce dall'intervallo [0, 1]: -min > 0 se ci sono valori
    % negativi, max - 1 > 0 se ci sono valori sopra 1; lo 0 evita risultati negativi.
    excursion = max([0, -min(t2f(:)), max(t2f(:)) - 1]);
    % Uno scostamento superiore all'errore di arrotondamento indica un problema reale.
    if excursion > 1e-12
        error('generateV4Prediction:rangeError', 'Diffusion output leaves [0,1] by %g.', excursion);
    end
    % Riporta in [0, 1] gli scostamenti dovuti solo all'arrotondamento numerico.
    t2f = min(max(t2f, 0), 1);

    % --- 4. Soglia: livello TA e soglia minima WM-like (Sezioni 3.6-3.7) -------------
    % Due soglie di Otsu (multithresh, 3 classi) calcolate SOLO sui voxel della T2
    % filtrata dentro S2 (indicizzazione logica t2f(S2)); levels(2) è il livello TA.
    levels = double(multithresh(t2f(S2), 2));
    % Classe T1 alta NON riempita: imquantize assegna a ogni voxel la classe 1, 2 o 3
    % secondo le due soglie della T1; si tiene la classe 3, limitata alla maschera cerebrale.
    t1High = brainMask & imquantize(t1Norm, supportDetails.t1ThresholdsNormalized) == 3;
    % Regione di riferimento WM-like R = S2 AND High: intensità della T2 filtrata nei suoi
    % voxel. Le cavità aggiunte dal riempimento (dove stanno le lesioni) sono escluse.
    reference = t2f(S2 & t1High);
    % Media e deviazione standard (normalizzazione N-1) della regione di riferimento.
    muWM = mean(reference);
    sigmaWM = std(reference);
    if isnan(k)
        % Caso v3: nessuna soglia minima, si usa solo il livello TA.
        floorValue = NaN;
        threshold = levels(2);
    else
        % Caso v4: soglia minima mu + k*sigma (k = 5) e soglia finale = massimo tra il
        % livello TA e la soglia minima. Il livello TA non può scendere sotto la soglia
        % minima: è l'unica differenza tra v3 e v4.
        floorValue = muWM + k * sigmaWM;
        threshold = max(levels(2), floorValue);
    end

    % --- 5. Candidati e post-processing morfologico (Sezione 3.8) -------------------
    % Candidati: voxel dentro S2 con T2 filtrata strettamente maggiore della soglia finale.
    candidate = S2 & t2f > threshold;
    % Volume vuoto (tutto falso) da riempire slice per slice.
    opened = false(size(candidate));
    % Elemento strutturante: diamante di raggio 1 (croce 3 x 3).
    se = strel('diamond', 1);
    % Apertura morfologica 2D (erosione + dilatazione) applicata a ogni slice assiale:
    % rimuove voxel isolati e frange più sottili dell'elemento strutturante.
    for slice = 1:size(candidate, 3)
        opened(:, :, slice) = imopen(candidate(:, :, slice), se);
    end
    % Maschera finale: intersezione con S2. L'apertura non aggiunge voxel, quindi il
    % risultato è già dentro S2; l'intersezione resta come vincolo esplicito.
    M_pred = opened & S2;

    % --- 6. Valori intermedi restituiti per controllo e documentazione --------------
    % k usato, soglia della maschera grezza, soglie della T1, livelli della T2, statistiche
    % della regione di riferimento, soglia minima e finale, attivazione della soglia
    % minima, numero di voxel candidati, finali e di S2, e il supporto S2 stesso.
    details = struct('k', k, 'brainMaskThreshold', brainMaskThreshold, ...
        't1ThresholdsNormalized', supportDetails.t1ThresholdsNormalized, 'taLevels', levels, ...
        'muWM', muWM, 'sigmaWM', sigmaWM, 'referenceVoxels', numel(reference), 'floorValue', floorValue, ...
        'threshold', threshold, 'floorActive', ~isnan(k) && floorValue > levels(2), ...
        'candidateVoxels', nnz(candidate), 'finalVoxels', nnz(M_pred), 'S2Voxels', nnz(S2), 'S2', S2);
end
