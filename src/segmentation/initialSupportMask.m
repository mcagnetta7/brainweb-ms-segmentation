function [mask, threshold] = initialSupportMask(volume)
%INITIALSUPPORTMASK Maschera grezza di supporto testa/cervello con Otsu globale.
%
%   [mask, threshold] = INITIALSUPPORTMASK(volume) calcola UNA soglia di
%   Otsu (graythresh) sulla distribuzione di tutti i voxel del volume e la
%   applica identica a ogni slice assiale con imbinarize (primo piano:
%   valore > soglia).
%
%   Input:
%     volume  volume double già convertito e normalizzato in [0,1]
%             (non modificato)
%
%   Output:
%     mask       maschera logica grezza, stesse dimensioni del volume
%     threshold  soglia scalare usata (stimata dai dati, non scelta a mano)
%
%   Nessun filtro, morfologia, riempimento di buchi o selezione di
%   componenti connesse: la maschera è volutamente grezza (fase 49).
%   graythresh usa un istogramma di 256 bin per i double in [0,1].
%
%   Nella v4 riceve la T1 normalizzata: la maschera grezza separa la testa dallo
%   sfondo e contiene ancora cranio e scalpo; la pulizia è fatta da
%   brainMask3DErodeSelectDilate.

    % --- Validazione degli ingressi ------------------------------------------------
    % Il volume deve essere un array 3D di double reali.
    arguments
        volume (:,:,:) double {mustBeReal}
    end

    % graythresh presuppone valori in [0, 1]: se anche un solo voxel è fuori
    % intervallo, NaN o infinito, la funzione si ferma (protezione contro un volume
    % non normalizzato).
    if any(volume(:) < 0 | volume(:) > 1 | ~isfinite(volume(:)))
        error('segmentation:invalidRange', ...
            'Volume must contain finite values in [0,1].');
    end

    % Una soglia globale per volume: tutti i voxel, nessuna esclusione
    % volume(:) mette tutti i voxel in un vettore; graythresh applica il metodo di
    % Otsu (soglia che minimizza la varianza delle intensità dentro le due classi,
    % qui sfondo scuro e testa) e restituisce un numero in [0, 1].
    threshold = graythresh(volume(:));

    % Stessa soglia applicata a ogni slice, indipendentemente
    % Volume logico vuoto (tutto falso) delle stesse dimensioni.
    mask = false(size(volume));
    % Per ogni slice assiale k: imbinarize mette vero dove l'intensità è maggiore
    % della soglia globale. Il risultato equivale a volume > threshold.
    for k = 1:size(volume, 3)
        mask(:, :, k) = imbinarize(volume(:, :, k), threshold);
    end

end
