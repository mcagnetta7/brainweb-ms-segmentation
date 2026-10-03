function fig = showAxialSlice(volume, k, titleText)
%SHOWAXIALSLICE Mostra una singola slice assiale di un volume.
%
%   fig = SHOWAXIALSLICE(volume, k, titleText) apre una figura con la
%   slice assiale k del volume (convenzione V(i,j,k), i = X, j = Y,
%   k = Z) e restituisce l'handle della figura.
%
%   Convenzione di visualizzazione:
%     - asse orizzontale: i (X, dimensione 1), crescente verso destra;
%     - asse verticale:   j (Y, dimensione 2), crescente verso l'alto;
%     - la slice viene trasposta solo per la visualizzazione, perché
%       MATLAB disegna le righe della matrice in verticale;
%     - nessun flip dei dati; la direzione destra/sinistra anatomica di
%       X non è nota e non viene indicata.
%
%   L'intensità viene mappata in scala di grigi sul minimo e massimo
%   della slice solo per la resa grafica: il volume non viene
%   modificato.

    arguments
        volume (:,:,:) {mustBeNumeric}
        k (1,1) double {mustBeInteger, mustBePositive}
        titleText {mustBeTextScalar} = ""
    end

    if k > size(volume, 3)
        error('visualization:sliceOutOfRange', ...
            'Axial slice %d is outside 1...%d.', k, size(volume, 3));
    end

    slice = volume(:, :, k);                % slice(i, j)

    fig = figure('Color', 'w');
    imagesc(1:size(slice, 1), 1:size(slice, 2), slice.');
    colormap(gray);
    axis image;                             % voxel isotropi da 1 mm
    set(gca, 'YDir', 'normal');             % j crescente verso l'alto
    xlabel('i  (X, dim 1)');
    ylabel('j  (Y, dim 2)');
    title(titleText, 'Interpreter', 'none');

end
