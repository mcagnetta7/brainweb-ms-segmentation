function boundaryForDisplay = overlayMaskBoundaryOnMRI(ax, mriSlice, maskSlice, options)
%OVERLAYMASKBOUNDARYONMRI Mostra il contorno di una maschera sopra una sezione MRI 2D.
%
%   boundaryForDisplay = OVERLAYMASKBOUNDARYONMRI(ax, mriSlice, maskSlice,
%   options) disegna nell'asse ax la sezione MRI in scala di grigi e, sopra,
%   il contorno della maschera. Il contorno è estratto solo per la
%   visualizzazione con il principio morfologico del bordo:
%
%       boundaryForDisplay = maskSlice AND NOT imerode(maskSlice, true(3))
%
%   La maschera e la MRI non vengono modificate (le variabili restano
%   separate dal contorno). Convenzione di visualizzazione delle fasi
%   31-34: la sezione è trasposta solo per la visualizzazione, asse
%   verticale verso l'alto, nessun flip, axis image.
%
%   Input:
%     ax         asse in cui disegnare
%     mriSlice   sezione 2D MRI (double, es. normalizzata in [0,1])
%     maskSlice  sezione 2D logica della maschera, stesse dimensioni
%     options    name-value opzionali:
%                  BoundaryColor  colore RGB del contorno (default giallo)
%                  ShowFill       true per aggiungere il riempimento
%                                 semitrasparente (default false)
%                  FillAlpha      trasparenza del riempimento (default 0.35)
%                  DisplayRange   intervallo di grigi (default [0 1])
%                  Title          titolo dell'asse (default "")
%
%   Output:
%     boundaryForDisplay  contorno 2D logico (solo visualizzazione)

    arguments
        ax (1,1) matlab.graphics.axis.Axes
        mriSlice (:,:) double
        maskSlice (:,:) logical
        options.BoundaryColor (1,3) double = [1 1 0]
        options.ShowFill (1,1) logical = false
        options.FillAlpha (1,1) double = 0.35
        options.DisplayRange (1,2) double = [0 1]
        options.Title {mustBeTextScalar} = ""
    end

    if ~isequal(size(mriSlice), size(maskSlice))
        error('visualization:sizeMismatch', 'MRI slice and mask slice must have the same size.');
    end

    boundaryForDisplay = maskSlice & ~imerode(maskSlice, true(3));

    gray = (mriSlice.' - options.DisplayRange(1)) / diff(options.DisplayRange);
    gray = min(max(gray, 0), 1);
    rgb = repmat(gray, 1, 1, 3);
    if options.ShowFill
        fill = maskSlice.';
        for c = 1:3
            channel = rgb(:, :, c);
            channel(fill) = (1 - options.FillAlpha) * channel(fill) + options.FillAlpha * options.BoundaryColor(c);
            rgb(:, :, c) = channel;
        end
    end
    edgePixels = boundaryForDisplay.';
    for c = 1:3
        channel = rgb(:, :, c);
        channel(edgePixels) = options.BoundaryColor(c);
        rgb(:, :, c) = channel;
    end

    image(ax, rgb);
    axis(ax, 'image');
    set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
    title(ax, options.Title, 'FontSize', 8, 'Interpreter', 'none');

end
