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
%
%   Nella v4 si usa solo S2: la zona in cui cercare le lesioni. In T1 il liquor è
%   scuro (classe Low, esclusa) e la sostanza bianca chiara (classe High); le lesioni,
%   più scure della sostanza bianca circostante, formano cavità nella classe High,
%   che il riempimento reintegra nel supporto. S0 e S1 restano per lo studio di
%   ablazione. details.t1ThresholdsNormalized è riusato dalla v4 per la regione
%   di riferimento WM-like.

    % --- Validazione degli ingressi ------------------------------------------------
    % T1 normalizzata come array 3D di double, maschera cerebrale come volume logico.
    arguments
        t1Norm (:, :, :) double
        brainMask (:, :, :) logical
    end

    % T1 e maschera devono avere le stesse dimensioni e la maschera non può essere vuota.
    if ~isequal(size(t1Norm), size(brainMask)) || ~any(brainMask(:))
        error('computeT1AnatomicalSupport:invalidInput', 'T1 and brain mask must match in size; mask non-empty.');
    end
    % La T1 deve essere finita e normalizzata in [0, 1].
    if any(~isfinite(t1Norm(:))) || min(t1Norm(:)) < 0 || max(t1Norm(:)) > 1
        error('computeT1AnatomicalSupport:invalidVolume', 'T1 must be finite and normalized to [0,1].');
    end

    % --- Partizione della T1 in tre classi ---------------------------------------
    % Due soglie di Otsu (multithresh) calcolate SOLO sui voxel della maschera
    % cerebrale (indicizzazione logica t1Norm(brainMask)): dividono le intensità in
    % tre classi (scura / intermedia / chiara).
    levels = double(multithresh(t1Norm(brainMask), 2));
    % imquantize assegna a ogni voxel del volume il numero della sua classe (1, 2 o 3)
    % confrontando l'intensità con le due soglie.
    classVolume = imquantize(t1Norm, levels);
    % Classe Low (1, intensità T1 più basse, comprende il liquor) dentro la maschera.
    t1Low = brainMask & classVolume == 1;
    % Classe High (3, intensità T1 più alte, compatibile con la sostanza bianca).
    t1High = brainMask & classVolume == 3;
    % Riempimento della classe High slice per slice: imfill(..., 'holes') chiude le
    % regioni completamente racchiuse dalla classe High in ogni slice assiale.
    filledHigh = false(size(t1High));
    for k = 1:size(t1High, 3)
        filledHigh(:, :, k) = imfill(t1High(:, :, k), 'holes');
    end

    % --- Supporti -----------------------------------------------------------------
    % S0: la sola maschera cerebrale; S1: maschera meno la classe Low;
    % S2: maschera AND High riempita AND NOT Low (il supporto usato dalla v4).
    supports = struct();
    supports.S0 = brainMask;
    supports.S1 = brainMask & ~t1Low;
    supports.S2 = brainMask & filledHigh & ~t1Low;

    % --- Valori intermedi -----------------------------------------------------------
    % Le due soglie della T1 (riusate dalla v4) e il numero di voxel di ogni maschera.
    details = struct('t1ThresholdsNormalized', levels, 't1LowVoxels', nnz(t1Low), 't1HighVoxels', nnz(t1High), ...
        'filledHighVoxels', nnz(filledHigh & brainMask), 'S0Voxels', nnz(supports.S0), ...
        'S1Voxels', nnz(supports.S1), 'S2Voxels', nnz(supports.S2));
end
