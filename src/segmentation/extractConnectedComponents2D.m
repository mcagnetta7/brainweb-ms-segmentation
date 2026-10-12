function [ccBySlice, numComponentsPerSlice] = extractConnectedComponents2D(candidateMask, connectivity)
%EXTRACTCONNECTEDCOMPONENTS2D Componenti connesse 2D, slice assiale per slice (fase 67).
%
%   [ccBySlice, numComponentsPerSlice] = EXTRACTCONNECTEDCOMPONENTS2D(
%   candidateMask, connectivity) applica bwconncomp a ogni slice assiale
%   (terza dimensione) in modo indipendente, con connettività 2D esplicita.
%
%   Una struttura che attraversa più slice compare come un componente
%   distinto in ogni slice: il numero totale di componenti 2D NON è il
%   numero di lesioni 3D uniche.
%
%   La funzione non carica file, non usa ground truth, non calcola
%   proprietà dei componenti (nessun regionprops), non filtra né rimuove
%   componenti e non applica morfologia. L'ingresso non viene modificato.
%
%   Input:
%     candidateMask  maschera logica 3D (righe x colonne x slice)
%     connectivity   connettività 2D: 4 oppure 8
%
%   Output:
%     ccBySlice              cell array (numero di slice x 1); ccBySlice{k}
%                            è la struttura bwconncomp della slice k
%     numComponentsPerSlice  vettore colonna con ccBySlice{k}.NumObjects

    if ~islogical(candidateMask) || ndims(candidateMask) ~= 3
        error('segmentation:invalidMask', 'Candidate mask must be a logical 3D array.');
    end
    if ~(isnumeric(connectivity) && isscalar(connectivity) && ismember(connectivity, [4 8]))
        error('segmentation:invalidConnectivity', 'Connectivity must be explicitly 4 or 8 (2D).');
    end

    nSlices = size(candidateMask, 3);
    ccBySlice = cell(nSlices, 1);
    numComponentsPerSlice = zeros(nSlices, 1);
    for k = 1:nSlices
        sliceMask = candidateMask(:, :, k);      % sempre una sola slice 2D
        ccBySlice{k} = bwconncomp(sliceMask, connectivity);
        numComponentsPerSlice(k) = ccBySlice{k}.NumObjects;
    end

end
