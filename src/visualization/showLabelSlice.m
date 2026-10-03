function fig = showLabelSlice(labels, k, labelNames, labelColors, titleText)
%SHOWLABELSLICE Mostra una slice assiale di un volume di etichette discrete.
%
%   fig = SHOWLABELSLICE(labels, k, labelNames, labelColors, titleText)
%   apre una figura con la slice assiale k del volume di etichette
%   (convenzione V(i,j,k), i = X, j = Y, k = Z), con una colormap a
%   categorie e una barra dei colori con i nomi delle etichette.
%
%   Input:
%     labels       volume 3D di etichette intere 0...N-1 (non modificato)
%     k            indice della slice assiale
%     labelNames   N nomi, uno per etichetta 0...N-1
%     labelColors  matrice N x 3 di colori RGB, uno per etichetta
%     titleText    titolo della figura
%
%   Convenzione di visualizzazione (come nelle fasi 31-33): asse
%   orizzontale i (X) verso destra, asse verticale j (Y) verso l'alto,
%   trasposizione solo per la visualizzazione, nessun flip dei dati,
%   voxel isotropi (axis image). Nessuna indicazione destra/sinistra.
%
%   I colori servono solo alla resa grafica: un'etichetta può essere
%   evidenziata scegliendone il colore, senza modificare i dati.

    arguments
        labels (:,:,:) {mustBeNumeric}
        k (1,1) double {mustBeInteger, mustBePositive}
        labelNames (1,:) string
        labelColors (:,3) double {mustBeGreaterThanOrEqual(labelColors, 0), mustBeLessThanOrEqual(labelColors, 1)}
        titleText {mustBeTextScalar} = ""
    end

    nLabels = numel(labelNames);
    if size(labelColors, 1) ~= nLabels
        error('visualization:labelColorMismatch', ...
            'Expected %d colors, got %d.', nLabels, size(labelColors, 1));
    end
    if k > size(labels, 3)
        error('visualization:sliceOutOfRange', ...
            'Axial slice %d is outside 1...%d.', k, size(labels, 3));
    end

    slice = labels(:, :, k);                % slice(i, j)

    fig = figure('Color', 'w');
    ax = axes('Parent', fig);
    imagesc(ax, 1:size(slice, 1), 1:size(slice, 2), slice.');
    colormap(ax, labelColors);
    clim(ax, [-0.5, nLabels - 0.5]);        % un colore per ogni etichetta intera
    axis(ax, 'image');                      % voxel isotropi da 1 mm
    set(ax, 'YDir', 'normal');              % j crescente verso l'alto
    xlabel(ax, 'i  (X, dim 1)');
    ylabel(ax, 'j  (Y, dim 2)');
    title(ax, titleText, 'Interpreter', 'none');

    labelBar = colorbar(ax);
    labelBar.Ticks = 0:nLabels - 1;
    labelBar.TickLabels = compose("%d  %s", (0:nLabels - 1)', labelNames(:));
    labelBar.TickLength = 0;

end
