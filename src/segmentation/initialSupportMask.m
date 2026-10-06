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

    arguments
        volume (:,:,:) double {mustBeReal}
    end

    if any(volume(:) < 0 | volume(:) > 1 | ~isfinite(volume(:)))
        error('segmentation:invalidRange', ...
            'Volume must contain finite values in [0,1].');
    end

    % Una soglia globale per volume: tutti i voxel, nessuna esclusione
    threshold = graythresh(volume(:));

    % Stessa soglia applicata a ogni slice, indipendentemente
    mask = false(size(volume));
    for k = 1:size(volume, 3)
        mask(:, :, k) = imbinarize(volume(:, :, k), threshold);
    end

end
