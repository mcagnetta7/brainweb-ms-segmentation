function [foregroundMarker, diagnostics] = reconstructionRegionalMaxMarkers( ...
    volume, nonBrainMarker, element, connectivity)
%RECONSTRUCTIONREGIONALMAXMARKERS Marker interni da ricostruzione e massimi regionali (2D).
%
%   [foregroundMarker, diagnostics] = RECONSTRUCTIONREGIONALMAXMARKERS(
%   volume, nonBrainMarker, element, connectivity) genera, per ogni slice
%   assiale, i marker del primo piano per il watershed:
%
%     1. apertura per ricostruzione:
%          J = imreconstruct(imerode(I, element), I, connectivity)
%     2. chiusura per ricostruzione (duale, sul complemento):
%          K = imcomplement(imreconstruct(imcomplement(imdilate(J, element)),
%                                         imcomplement(J), connectivity))
%     3. massimi regionali: imregionalmax(K, connectivity)
%     4. componenti connesse dei massimi (connectivity): una componente
%        che tocca nonBrainMarker viene scartata; tutte le altre sono
%        tenute (nessuna soglia di area, nessuna regola di posizione,
%        nessuna "componente più grande")
%
%   La ricostruzione serve solo a generare i marker: l'immagine usata dal
%   watershed resta quella originale.
%
%   Output:
%     foregroundMarker  marker interni accettati (logico), disgiunti da
%                       nonBrainMarker per costruzione
%     diagnostics       vettori per slice: nMaxima, nRejected, nRetained,
%                       retainedArea, overlap

    arguments
        volume (:,:,:) double {mustBeReal}
        nonBrainMarker (:,:,:) logical
        element
        connectivity (1,1) double {mustBeMember(connectivity, [4 8])}
    end

    if ~isequal(size(volume), size(nonBrainMarker))
        error('segmentation:sizeMismatch', 'Volume and marker must have the same size.');
    end

    nSlices = size(volume, 3);
    foregroundMarker = false(size(volume));
    diagnostics.nMaxima = zeros(nSlices, 1);
    diagnostics.nRejected = zeros(nSlices, 1);
    diagnostics.nRetained = zeros(nSlices, 1);
    diagnostics.retainedArea = zeros(nSlices, 1);
    diagnostics.overlap = zeros(nSlices, 1);

    for k = 1:nSlices
        sliceImage = volume(:, :, k);
        nonBrain = nonBrainMarker(:, :, k);

        prepared = markerPreparationImage(sliceImage, element, connectivity);
        maxima = imregionalmax(prepared, connectivity);

        components = bwconncomp(maxima, connectivity);
        diagnostics.nMaxima(k) = components.NumObjects;
        retained = false(size(sliceImage));
        for c = 1:components.NumObjects
            pixels = components.PixelIdxList{c};
            if any(nonBrain(pixels))
                diagnostics.nRejected(k) = diagnostics.nRejected(k) + 1;
            else
                retained(pixels) = true;
                diagnostics.nRetained(k) = diagnostics.nRetained(k) + 1;
            end
        end

        diagnostics.retainedArea(k) = nnz(retained);
        diagnostics.overlap(k) = nnz(retained & nonBrain);
        foregroundMarker(:, :, k) = retained;
    end

end


function prepared = markerPreparationImage(sliceImage, element, connectivity)
%MARKERPREPARATIONIMAGE Apertura e poi chiusura per ricostruzione di una slice.

    opened = imreconstruct(imerode(sliceImage, element), sliceImage, connectivity);
    prepared = imcomplement(imreconstruct( ...
        imcomplement(imdilate(opened, element)), imcomplement(opened), connectivity));

end
