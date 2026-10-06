function [candidate, foregroundMarker, backgroundMarker, ridgeMask, diagnostics] = propagateBrainMaskSlices( ...
    volume, seedMask, seedSlice, erosionElement, dilationElement, gradientNeighborhood, ridgeAssignment)
%PROPAGATEBRAINMASKSLICES Propagazione slice per slice della maschera con watershed (EXP-018).
%
%   [candidate, foregroundMarker, backgroundMarker, ridgeMask, diagnostics] =
%   PROPAGATEBRAINMASKSLICES(volume, seedMask, seedSlice, erosionElement,
%   dilationElement, gradientNeighborhood) parte dalla slice seme e procede
%   verso l'alto (k = seed+1, ..., end) e verso il basso (k = seed-1, ..., 1).
%   Per ogni slice k, con M = maschera già accettata della slice vicina
%   verso il seme (k-1 salendo, k+1 scendendo):
%
%     1. marker del primo piano = imerode(M, erosionElement)
%        se è vuoto la propagazione in quella direzione si FERMA: k e tutte
%        le slice successive restano vuote
%     2. marker di sfondo = NOT imdilate(M, dilationElement)
%     3. gradiente morfologico della slice T1 k:
%        imdilate(I, nhood) - imerode(I, nhood)
%     4. watershed(imimposemin(gradiente, primo piano OR sfondo))
%        (connettività predefinita, 8 in 2D)
%     5. candidato, secondo ridgeAssignment (argomento opzionale):
%        "exclude" (predefinito, EXP-018/019): unione delle etichette
%        positive toccate dal marker del primo piano, AND NOT sfondo; le
%        linee di cresta (etichetta 0) restano escluse
%        "foreground" (EXP-020): tutti i pixel che NON appartengono a un
%        bacino toccato dal marker di sfondo, AND NOT sfondo; le linee di
%        cresta sono quindi assegnate al primo piano
%        poi un solo imfill 'holes'
%
%   Tutte le operazioni sono 2D; l'unica informazione da un'altra slice è
%   la maschera accettata della slice adiacente. Nessuna soglia di
%   intensità, nessun vincolo da Otsu, nessuna regola di posizione, nessun
%   3D, nessun ground truth.
%
%   Input:
%     volume                volume T1 double normalizzato in [0,1]
%     seedMask              maschera 2D logica della slice seme
%     seedSlice             indice della slice seme
%     erosionElement        strel per il marker del primo piano
%     dilationElement       strel per il marker di sfondo
%     gradientNeighborhood  intorno del gradiente morfologico, es. ones(3)
%
%   Output:
%     candidate         maschera propagata (la slice seme = seedMask)
%     foregroundMarker  marker del primo piano per slice
%     backgroundMarker  marker di sfondo per slice
%     ridgeMask         linee di cresta del watershed
%     diagnostics       vettori per slice: foregroundArea, backgroundArea,
%                       bandArea, labelsTouched, basinArea, addedByFilling,
%                       candidateArea, stopped (true se oltre l'arresto)

    arguments
        volume (:,:,:) double {mustBeReal}
        seedMask (:,:) logical
        seedSlice (1,1) double {mustBeInteger, mustBePositive}
        erosionElement
        dilationElement
        gradientNeighborhood (:,:) double
        ridgeAssignment (1,1) string {mustBeMember(ridgeAssignment, ["exclude", "foreground"])} = "exclude"
    end

    nSlices = size(volume, 3);
    if ~isequal(size(seedMask), [size(volume, 1) size(volume, 2)]) || seedSlice > nSlices
        error('segmentation:invalidSeed', 'Seed mask or seed slice incompatible with the volume.');
    end

    candidate = false(size(volume));
    foregroundMarker = false(size(volume));
    backgroundMarker = false(size(volume));
    ridgeMask = false(size(volume));
    names = {'foregroundArea', 'backgroundArea', 'bandArea', 'labelsTouched', 'basinArea', ...
        'addedByFilling', 'candidateArea'};
    for f = 1:numel(names)
        diagnostics.(names{f}) = zeros(nSlices, 1);
    end
    diagnostics.stopped = false(nSlices, 1);

    candidate(:, :, seedSlice) = seedMask;
    diagnostics.candidateArea(seedSlice) = nnz(seedMask);

    directions = {seedSlice + 1:nSlices, seedSlice - 1:-1:1};
    steps = [-1, 1];                    % vicino verso il seme: k-1 salendo, k+1 scendendo
    for d = 1:2
        stopped = false;
        for k = directions{d}
            if stopped
                diagnostics.stopped(k) = true;
                continue
            end
            previous = candidate(:, :, k + steps(d));
            foreground = imerode(previous, erosionElement);
            if ~any(foreground(:))
                stopped = true;
                diagnostics.stopped(k) = true;
                continue
            end
            background = ~imdilate(previous, dilationElement);

            sliceImage = volume(:, :, k);
            gradientImage = imdilate(sliceImage, gradientNeighborhood) - imerode(sliceImage, gradientNeighborhood);
            labels = watershed(imimposemin(gradientImage, foreground | background));

            touched = unique(labels(foreground));
            touched = touched(touched > 0);
            if ridgeAssignment == "exclude"
                basin = ismember(labels, touched) & ~background;
            else
                backgroundLabels = unique(labels(background));
                backgroundLabels = backgroundLabels(backgroundLabels > 0);
                basin = ~ismember(labels, backgroundLabels) & ~background;
            end
            filled = imfill(basin, 'holes');

            foregroundMarker(:, :, k) = foreground;
            backgroundMarker(:, :, k) = background;
            ridgeMask(:, :, k) = labels == 0;
            diagnostics.foregroundArea(k) = nnz(foreground);
            diagnostics.backgroundArea(k) = nnz(background);
            diagnostics.bandArea(k) = nnz(~foreground & ~background);
            diagnostics.labelsTouched(k) = numel(touched);
            diagnostics.basinArea(k) = nnz(basin);
            diagnostics.addedByFilling(k) = nnz(filled) - nnz(basin);
            diagnostics.candidateArea(k) = nnz(filled);
            candidate(:, :, k) = filled;

            if ~any(filled(:))
                stopped = true;         % niente da propagare oltre
            end
        end
    end

end
