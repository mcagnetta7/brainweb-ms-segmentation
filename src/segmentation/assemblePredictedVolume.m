function M_pred = assemblePredictedVolume(sliceMasks)
%ASSEMBLEPREDICTEDVOLUME Ricompone le maschere 2D per slice nel volume 3D M_pred (fase 71).
%
%   M_pred = ASSEMBLEPREDICTEDVOLUME(sliceMasks) concatena lungo la terza
%   dimensione le maschere logiche 2D di sliceMasks, nell'ordine dato:
%   M_pred(:,:,k) = sliceMasks{k}. Nessuna elaborazione d'immagine, nessuna
%   interpolazione tra slice, nessun ground truth. Gli ingressi non vengono
%   modificati.
%
%   Input:
%     sliceMasks  cell array non vuoto di matrici logiche 2D della stessa
%                 dimensione
%
%   Output:
%     M_pred      volume logico (righe x colonne x numero di slice)

    if ~iscell(sliceMasks) || isempty(sliceMasks)
        error('segmentation:invalidSlices', 'sliceMasks must be a non-empty cell array.');
    end
    sliceSize = size(sliceMasks{1});
    for k = 1:numel(sliceMasks)
        s = sliceMasks{k};
        if ~islogical(s) || ~ismatrix(s) || ~isequal(size(s), sliceSize)
            error('segmentation:invalidSlices', 'Slice %d must be a logical 2D mask of size [%s].', ...
                k, num2str(sliceSize));
        end
    end

    M_pred = cat(3, sliceMasks{:});

end
