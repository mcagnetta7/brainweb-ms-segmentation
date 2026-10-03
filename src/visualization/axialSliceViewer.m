function fig = axialSliceViewer(volume, initialSlice, label)
%AXIALSLICEVIEWER Visualizzatore semplice delle slice assiali di un volume.
%
%   fig = AXIALSLICEVIEWER(volume, initialSlice, label) apre una figura
%   che mostra la slice assiale k di un volume già caricato (convenzione
%   V(i,j,k), i = X, j = Y, k = Z) e permette di cambiare k con uno
%   slider o scrivendo l'indice nella casella di testo.
%
%   Input:
%     volume        volume 3D già caricato (non viene modificato)
%     initialSlice  slice iniziale (default: slice centrale)
%     label         testo mostrato nel titolo, es. la modalità
%
%   Output:
%     fig  handle della figura. fig.UserData contiene:
%            setSlice(k)  imposta la slice k; restituisce false e lascia
%                         la slice corrente se k non è valido
%            getSlice()   restituisce la slice mostrata
%            image        handle dell'immagine
%
%   Convenzione di visualizzazione (come nelle fasi 31-32): asse
%   orizzontale i (X) verso destra, asse verticale j (Y) verso l'alto,
%   trasposizione solo per la visualizzazione, nessun flip dei dati,
%   voxel isotropi (axis image). Nessuna indicazione destra/sinistra.
%
%   L'intensità viene mappata in scala di grigi sul minimo e massimo del
%   volume, uguale per tutte le slice, solo per la resa grafica.

    arguments
        volume (:,:,:) {mustBeNumeric}
        initialSlice (1,1) double {mustBeInteger, mustBePositive} = ceil(size(volume, 3) / 2)
        label {mustBeTextScalar} = ""
    end

    nSlices = size(volume, 3);
    if nSlices < 2
        error('visualization:tooFewSlices', ...
            'The viewer needs at least 2 axial slices.');
    end
    if initialSlice > nSlices
        error('visualization:sliceOutOfRange', ...
            'Axial slice %d is outside 1...%d.', initialSlice, nSlices);
    end

    displayRange = double([min(volume(:)) max(volume(:))]);
    if displayRange(2) <= displayRange(1)
        displayRange(2) = displayRange(1) + 1;
    end

    currentSlice = initialSlice;

    fig = figure('Color', 'w', 'Name', 'Axial slice viewer', ...
        'NumberTitle', 'off');

    ax = axes('Parent', fig, 'Position', [0.10 0.22 0.80 0.70]);
    img = imagesc(ax, 1:size(volume, 1), 1:size(volume, 2), ...
        volume(:, :, currentSlice).');
    colormap(ax, gray);
    clim(ax, displayRange);
    axis(ax, 'image');                      % voxel isotropi da 1 mm
    set(ax, 'YDir', 'normal');              % j crescente verso l'alto
    xlabel(ax, 'i  (X, dim 1)');
    ylabel(ax, 'j  (Y, dim 2)');

    slider = uicontrol(fig, 'Style', 'slider', 'Units', 'normalized', ...
        'Position', [0.10 0.08 0.62 0.05], ...
        'Min', 1, 'Max', nSlices, 'Value', currentSlice, ...
        'SliderStep', [1 10] / (nSlices - 1), ...
        'Callback', @onSlider);

    editBox = uicontrol(fig, 'Style', 'edit', 'Units', 'normalized', ...
        'Position', [0.75 0.08 0.15 0.05], ...
        'String', num2str(currentSlice), ...
        'Callback', @onEdit);

    status = uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.10 0.01 0.80 0.05], ...
        'String', '', 'BackgroundColor', 'w', ...
        'HorizontalAlignment', 'left');

    updateTitle();

    fig.UserData = struct( ...
        'setSlice', @setSlice, ...
        'getSlice', @getSlice, ...
        'image', img);


    function accepted = setSlice(k)
    %SETSLICE Mostra la slice k se è un indice valido.
        isValid = isnumeric(k) && isscalar(k) && isfinite(k) ...
            && k == round(k) && k >= 1 && k <= nSlices;

        if ~isValid
            status.String = sprintf( ...
                'Invalid slice index. Valid range: 1 ... %d.', nSlices);
            editBox.String = num2str(currentSlice);
            slider.Value = currentSlice;
            accepted = false;
            return
        end

        currentSlice = double(k);
        img.CData = volume(:, :, currentSlice).';
        slider.Value = currentSlice;
        editBox.String = num2str(currentSlice);
        status.String = '';
        updateTitle();
        accepted = true;
    end


    function k = getSlice()
    %GETSLICE Restituisce l'indice della slice mostrata.
        k = currentSlice;
    end


    function onSlider(source, ~)
        setSlice(round(source.Value));
    end


    function onEdit(source, ~)
        setSlice(str2double(source.String));
    end


    function updateTitle()
        title(ax, sprintf('%s  -  axial slice k = %d / %d', ...
            label, currentSlice, nSlices), 'Interpreter', 'none');
    end

end
