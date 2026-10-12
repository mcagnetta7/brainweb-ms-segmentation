function CC3D = extractConnectedComponents3D(M_pred, connectivity)
%EXTRACTCONNECTEDCOMPONENTS3D Componenti connesse 3D del volume predetto completo (fase 72).
%
%   CC3D = EXTRACTCONNECTEDCOMPONENTS3D(M_pred, connectivity) applica
%   bwconncomp all'INTERO volume logico 3D con connettività volumetrica
%   esplicita (6, 18 o 26). Serve solo a rappresentare i voxel di primo
%   piano già esistenti come oggetti 3D: nessun voxel viene aggiunto o
%   rimosso.
%
%   Estensione volumetrica, specifica del progetto, del concetto di
%   componenti connesse del corso (mostrato in 2D). Le componenti sono
%   oggetti CANDIDATI, non lesioni confermate.
%
%   La funzione non usa ground truth, non filtra, non applica morfologia o
%   soglie e non calcola proprietà (nessun regionprops3). L'ingresso non
%   viene modificato.
%
%   Input:
%     M_pred        maschera logica 3D
%     connectivity  6, 18 oppure 26
%
%   Output:
%     CC3D          struttura bwconncomp (Connectivity, ImageSize,
%                   NumObjects, PixelIdxList)

    if ~islogical(M_pred) || ndims(M_pred) ~= 3
        error('segmentation:invalidMask', 'M_pred must be a logical 3D array.');
    end
    if ~(isnumeric(connectivity) && isscalar(connectivity) && ismember(connectivity, [6 18 26]))
        error('segmentation:invalidConnectivity', 'Connectivity must be explicitly 6, 18 or 26 (3D).');
    end

    CC3D = bwconncomp(M_pred, connectivity);

end
