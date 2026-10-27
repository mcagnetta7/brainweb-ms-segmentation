function counts = overlayErrorMapOnMRI(ax, mriSlice, predSlice, gtSlice, options)
%OVERLAYERRORMAPONMRI Mappa TP / FP / FN sopra una sezione MRI 2D (solo visualizzazione).
%
%   counts = OVERLAYERRORMAPONMRI(ax, mriSlice, predSlice, gtSlice, options)
%   disegna nell'asse ax la sezione MRI in scala di grigi e, sopra, con
%   trasparenza:
%
%       TP = pred & gt   (verde)      FP = pred & ~gt  (rosso)      FN = ~pred & gt  (blu)
%
%   Le tre categorie sono disgiunte per costruzione; i veri negativi non sono
%   colorati. Le maschere non vengono modificate (nessuna dilatazione, erosione
%   o levigatura). Convenzione di visualizzazione del progetto: sezione trasposta
%   solo per la visualizzazione, asse verticale verso l'alto, nessun flip.
%
%   options: Alpha (default 0.6), DisplayRange (default [min max] della sezione), Title.
%   counts: struct con TP, FP, FN della sezione (per la verifica della figura).

    arguments
        ax (1,1) matlab.graphics.axis.Axes
        mriSlice (:,:) double
        predSlice (:,:) logical
        gtSlice (:,:) logical
        options.Alpha (1,1) double = 0.6
        options.DisplayRange (1,2) double = [NaN NaN]
        options.Title {mustBeTextScalar} = ""
    end

    if ~isequal(size(mriSlice), size(predSlice), size(gtSlice))
        error('visualization:sizeMismatch', 'MRI, prediction and GT slices must have the same size.');
    end
    range = options.DisplayRange;
    if any(isnan(range))
        range = [min(mriSlice(:)) max(mriSlice(:))];
    end
    if range(2) <= range(1)
        range(2) = range(1) + 1;
    end

    tp = predSlice & gtSlice;
    fp = predSlice & ~gtSlice;
    fn = ~predSlice & gtSlice;
    counts = struct('TP', nnz(tp), 'FP', nnz(fp), 'FN', nnz(fn));

    gray = min(max((mriSlice.' - range(1)) / diff(range), 0), 1);
    rgb = repmat(gray, 1, 1, 3);
    colors = {tp.', [0 1 0]; fp.', [1 0 0]; fn.', [0 0.35 1]};
    for i = 1:size(colors, 1)
        m = colors{i, 1};
        for c = 1:3
            channel = rgb(:, :, c);
            channel(m) = (1 - options.Alpha) * channel(m) + options.Alpha * colors{i, 2}(c);
            rgb(:, :, c) = channel;
        end
    end

    image(ax, rgb);
    axis(ax, 'image');
    set(ax, 'YDir', 'normal', 'XTick', [], 'YTick', []);
    title(ax, options.Title, 'FontSize', 9, 'Interpreter', 'none');
end
