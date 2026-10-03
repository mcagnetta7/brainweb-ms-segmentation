function [fig, nOverlayPixels] = showLesionOverlay(mri, labels, k, lesionLabel, titleText)
%SHOWLESIONOVERLAY Sovrappone le lesioni del ground truth a una slice MRI.
%
%   [fig, nOverlayPixels] = SHOWLESIONOVERLAY(mri, labels, k, lesionLabel,
%   titleText) mostra la slice assiale k della MRI in scala di grigi e,
%   sopra, in rosso semitrasparente, i voxel della stessa slice del
%   ground truth che hanno etichetta lesionLabel.
%
%   Input:
%     mri          volume MRI già caricato (non modificato)
%     labels       volume di etichette già caricato (non modificato)
%     k            indice della slice assiale, uguale per MRI e GT
%     lesionLabel  etichetta da sovrapporre (BrainWeb: 10 = MS Lesion)
%     titleText    titolo della figura
%
%   Output:
%     fig             handle della figura
%     nOverlayPixels  numero di pixel sovrapposti nella slice
%
%   La maschera della lesione è temporanea e serve solo alla
%   visualizzazione. MRI e GT usano la stessa convenzione delle fasi
%   31-34: asse orizzontale i (X) verso destra, asse verticale j (Y)
%   verso l'alto, stessa trasposizione solo per la visualizzazione,
%   nessun flip, axis image. Nessuna indicazione destra/sinistra.

    arguments
        mri (:,:,:) {mustBeNumeric}
        labels (:,:,:) {mustBeNumeric}
        k (1,1) double {mustBeInteger, mustBePositive}
        lesionLabel (1,1) double {mustBeInteger, mustBeNonnegative}
        titleText {mustBeTextScalar} = ""
    end

    if ~isequal(size(mri), size(labels))
        error('visualization:sizeMismatch', ...
            'MRI size [%s] differs from GT size [%s].', ...
            num2str(size(mri)), num2str(size(labels)));
    end
    if k > size(mri, 3)
        error('visualization:sliceOutOfRange', ...
            'Axial slice %d is outside 1...%d.', k, size(mri, 3));
    end

    overlayColor = [1 0 0];
    overlayAlpha = 0.5;

    mriSlice = mri(:, :, k);                        % (i, j)
    lesionSlice = labels(:, :, k) == lesionLabel;   % (i, j), solo per la visualizzazione
    nOverlayPixels = nnz(lesionSlice);

    displayRange = double([min(mri(:)) max(mri(:))]);
    if displayRange(2) <= displayRange(1)
        displayRange(2) = displayRange(1) + 1;
    end

    iAxis = 1:size(mriSlice, 1);
    jAxis = 1:size(mriSlice, 2);

    fig = figure('Color', 'w');
    ax = axes('Parent', fig);

    % MRI in scala di grigi
    imagesc(ax, iAxis, jAxis, mriSlice.');
    colormap(ax, gray);
    clim(ax, displayRange);
    hold(ax, 'on');

    % Lesioni del GT: immagine rossa visibile solo dove la maschera è vera,
    % con la stessa trasposizione della MRI
    overlay = repmat(reshape(overlayColor, 1, 1, 3), size(lesionSlice, 2), size(lesionSlice, 1));
    image(ax, iAxis, jAxis, overlay, 'AlphaData', overlayAlpha * double(lesionSlice.'));

    % Voce di legenda
    patch(ax, NaN, NaN, overlayColor, 'FaceAlpha', overlayAlpha, ...
        'EdgeColor', 'none', ...
        'DisplayName', sprintf('GT lesion (label %d)', lesionLabel));
    legend(ax, 'Location', 'southoutside');

    hold(ax, 'off');
    axis(ax, 'image');                              % voxel isotropi da 1 mm
    set(ax, 'YDir', 'normal');                      % j crescente verso l'alto
    xlabel(ax, 'i  (X, dim 1)');
    ylabel(ax, 'j  (Y, dim 2)');
    title(ax, titleText, 'Interpreter', 'none');

end
