function [edges, thresholds] = detectT1CannyEdgesSlices(volume)
%DETECTT1CANNYEDGESSLICES Bordi di Canny automatici 2D, slice per slice (EXP-016).
%
%   [edges, thresholds] = DETECTT1CANNYEDGESSLICES(volume) applica a ogni
%   slice assiale, in modo indipendente:
%
%       [edges(:,:,k), thresholds(k,:)] = edge(volume(:,:,k), 'Canny')
%
%   con le soglie scelte automaticamente da MATLAB (nessuna soglia, sigma o
%   dimensione del filtro impostata a mano). La mappa dei bordi è restituita
%   grezza: nessuna morfologia, nessun collegamento o selezione di bordi.
%   La levigatura gaussiana interna fa parte dell'operatore di Canny e non
%   è un passo di preprocessing del progetto.
%
%   Input:
%     volume  volume double normalizzato in [0,1] (T1)
%
%   Output:
%     edges       mappa logica dei bordi, stesse dimensioni
%     thresholds  matrice nSlices x 2 con le soglie automatiche [bassa alta]
%                 restituite da edge (solo diagnostica)
%
%   Nessun dato di altre slice, nessun 3D, nessuna maschera in ingresso.

    arguments
        volume (:,:,:) double {mustBeReal}
    end

    nSlices = size(volume, 3);
    edges = false(size(volume));
    thresholds = zeros(nSlices, 2);

    for k = 1:nSlices
        [edges(:, :, k), threshold] = edge(volume(:, :, k), 'Canny');
        if numel(threshold) == 2
            thresholds(k, :) = threshold;
        else
            thresholds(k, :) = NaN;     % es. slice costante: soglie non definite
        end
    end

end
