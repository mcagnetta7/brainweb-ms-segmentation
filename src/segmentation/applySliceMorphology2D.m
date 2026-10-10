function result = applySliceMorphology2D(mask, brainMask, operation, se)
%APPLYSLICEMORPHOLOGY2D Morfologia binaria 2D slice assiale per slice, vincolata alla maschera cerebrale.
%
%   result = APPLYSLICEMORPHOLOGY2D(mask, brainMask, operation, se) applica
%   l'operazione elementare richiesta a ogni slice assiale (terza
%   dimensione) in modo indipendente, una sola volta, e interseca il
%   risultato con brainMask:
%
%       result(:,:,k) = op(mask(:,:,k), se) & brainMask(:,:,k)
%
%   Nessuna informazione passa tra slice adiacenti (nessuna morfologia 3D).
%
%   La funzione non carica file, non usa ground truth, non conosce la
%   condizione di rumore e non sceglie l'elemento strutturante. Gli
%   ingressi non vengono modificati.
%
%   Input:
%     mask        maschera logica 3D dei candidati
%     brainMask   maschera logica 3D con le stesse dimensioni (EXP-021)
%     operation   "erode" | "dilate"
%     se          elemento strutturante 2D (oggetto strel)
%
%   Output:
%     result      maschera logica 3D

    if ~islogical(mask) || ~islogical(brainMask)
        error('segmentation:invalidMask', 'Mask and brain mask must be logical arrays.');
    end
    if ~isequal(size(mask), size(brainMask))
        error('segmentation:sizeMismatch', 'Mask size [%s] differs from brain-mask size [%s].', ...
            num2str(size(mask)), num2str(size(brainMask)));
    end
    if ~isa(se, 'strel') || ~ismatrix(se.Neighborhood)
        error('segmentation:invalidStructuringElement', 'The structuring element must be a 2D strel.');
    end
    switch string(operation)
        case "erode"
            op = @imerode;
        case "dilate"
            op = @imdilate;
        otherwise
            error('segmentation:unsupportedOperation', 'Unsupported operation "%s".', operation);
    end

    result = false(size(mask));
    for k = 1:size(mask, 3)
        result(:, :, k) = op(mask(:, :, k), se) & brainMask(:, :, k);
    end

end
