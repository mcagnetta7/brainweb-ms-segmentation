function fig = showOrthogonalSlices(volume, center, titleText)
%SHOWORTHOGONALSLICES Mostra le viste assiale, coronale e sagittale.
%
%   fig = SHOWORTHOGONALSLICES(volume, center, titleText) apre una figura
%   con tre pannelli che passano tutti per il voxel center = [i0 j0 k0]
%   (convenzione V(i,j,k), i = X, j = Y, k = Z) e restituisce l'handle
%   della figura.
%
%   Viste:
%     - assiale:  V(:, :, k0)  orizzontale i, verticale j
%     - coronale: V(:, j0, :)  orizzontale i, verticale k
%     - sagittale: V(i0, :, :) orizzontale j, verticale k
%
%   Stessa regola della fase 31 per ogni pannello: la prima dimensione
%   rimasta va in orizzontale (crescente verso destra) e la seconda in
%   verticale (crescente verso l'alto); la trasposizione serve solo per
%   la visualizzazione e nessun flip viene applicato ai dati. La
%   direzione destra/sinistra anatomica di X non è nota e non viene
%   indicata.
%
%   Le linee tratteggiate indicano la posizione delle altre due slice,
%   per verificare l'intersezione comune. L'intensità viene mappata in
%   scala di grigi sul minimo e massimo del volume, uguale nei tre
%   pannelli, solo per la resa grafica: il volume non viene modificato.

    arguments
        volume (:,:,:) {mustBeNumeric}
        center (1,3) double {mustBeInteger, mustBePositive}
        titleText {mustBeTextScalar} = ""
    end

    volumeSize = size(volume, 1:3);
    if any(center > volumeSize)
        error('visualization:centerOutOfRange', ...
            'Center [%s] is outside the volume size [%s].', ...
            num2str(center), num2str(volumeSize));
    end

    i0 = center(1);
    j0 = center(2);
    k0 = center(3);

    axialSlice = volume(:, :, k0);                                  % (i, j)
    coronalSlice = reshape(volume(:, j0, :), volumeSize([1 3]));    % (i, k)
    sagittalSlice = reshape(volume(i0, :, :), volumeSize([2 3]));   % (j, k)

    % Le tre slice devono condividere il voxel (i0, j0, k0)
    assert(axialSlice(i0, j0) == coronalSlice(i0, k0) && ...
           axialSlice(i0, j0) == sagittalSlice(j0, k0), ...
        'The three slices do not share the voxel (i0, j0, k0).');

    displayRange = double([min(volume(:)) max(volume(:))]);
    if displayRange(2) <= displayRange(1)
        displayRange(2) = displayRange(1) + 1;
    end

    fig = figure('Color', 'w');
    layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact');
    title(layout, titleText, 'Interpreter', 'none');

    drawPanel(nexttile(layout), axialSlice, displayRange, ...
        sprintf('Axial  (k = %d)', k0), ...
        'i  (X, dim 1)', 'j  (Y, dim 2)', [i0 j0]);

    drawPanel(nexttile(layout), coronalSlice, displayRange, ...
        sprintf('Coronal  (j = %d)', j0), ...
        'i  (X, dim 1)', 'k  (Z, dim 3)', [i0 k0]);

    drawPanel(nexttile(layout), sagittalSlice, displayRange, ...
        sprintf('Sagittal  (i = %d)', i0), ...
        'j  (Y, dim 2)', 'k  (Z, dim 3)', [j0 k0]);

end


function drawPanel(ax, slice, displayRange, panelTitle, xLabel, yLabel, crossPoint)
%DRAWPANEL Disegna una slice 2D: dim 1 in orizzontale, dim 2 in verticale.

    imagesc(ax, 1:size(slice, 1), 1:size(slice, 2), slice.');
    colormap(ax, gray);
    clim(ax, displayRange);
    axis(ax, 'image');                      % voxel isotropi da 1 mm
    set(ax, 'YDir', 'normal');              % dim 2 crescente verso l'alto

    xline(ax, crossPoint(1), ':', 'Color', [1 0.6 0]);
    yline(ax, crossPoint(2), ':', 'Color', [1 0.6 0]);

    title(ax, panelTitle);
    xlabel(ax, xLabel);
    ylabel(ax, yLabel);

end
