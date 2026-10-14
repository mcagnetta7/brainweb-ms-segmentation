function [supports, details] = computeT1AnatomicalSupport(t1Norm, brainMask)
%COMPUTET1ANATOMICALSUPPORT Supporti anatomici S0 / S1 / S2 derivati da T1 (EXP-057).
%
%   [supports, details] = COMPUTET1ANATOMICALSUPPORT(t1Norm, brainMask)
%   partiziona automaticamente il T1 dentro la maschera cerebrale:
%
%       levels  = multithresh(t1Norm(brainMask), 2)      -> 3 classi
%       T1-low  = brainMask & classe 1   (candidato a T1 molto scuro)
%       T1-high = brainMask & classe 3   (candidato a T1 brillante)
%
%   e restituisce:
%       supports.S0 = brainMask
%       supports.S1 = brainMask & ~T1-low
%       supports.S2 = brainMask & imfill(T1-high, 'holes') per slice & ~T1-low
%
%   imfill usa la connettività 2D predefinita, slice assiale per slice.
%   Nessuna selezione di componenti, chiusura o altro passaggio. I nomi
%   indicano candidati di intensità, non tessuti certi. Nessun GT, nessun
%   accesso a file.

    arguments
        t1Norm (:, :, :) double
        brainMask (:, :, :) logical
    end

    if ~isequal(size(t1Norm), size(brainMask)) || ~any(brainMask(:))
        error('computeT1AnatomicalSupport:invalidInput', 'T1 and brain mask must match in size; mask non-empty.');
    end
    if any(~isfinite(t1Norm(:))) || min(t1Norm(:)) < 0 || max(t1Norm(:)) > 1
        error('computeT1AnatomicalSupport:invalidVolume', 'T1 must be finite and normalized to [0,1].');
    end

    levels = double(multithresh(t1Norm(brainMask), 2));
    classVolume = imquantize(t1Norm, levels);
    t1Low = brainMask & classVolume == 1;
    t1High = brainMask & classVolume == 3;
    filledHigh = false(size(t1High));
    for k = 1:size(t1High, 3)
        filledHigh(:, :, k) = imfill(t1High(:, :, k), 'holes');
    end

    supports = struct();
    supports.S0 = brainMask;
    supports.S1 = brainMask & ~t1Low;
    supports.S2 = brainMask & filledHigh & ~t1Low;

    details = struct('t1ThresholdsNormalized', levels, 't1LowVoxels', nnz(t1Low), 't1HighVoxels', nnz(t1High), ...
        'filledHighVoxels', nnz(filledHigh & brainMask), 'S0Voxels', nnz(supports.S0), ...
        'S1Voxels', nnz(supports.S1), 'S2Voxels', nnz(supports.S2));
end
