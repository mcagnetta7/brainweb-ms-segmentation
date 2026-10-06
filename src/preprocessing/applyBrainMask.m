function [maskedVolume, brainValues] = applyBrainMask(volume, brainMask)
%APPLYBRAINMASK Restrizione spaziale di un volume alla maschera cerebrale (fase 52).
%
%   [maskedVolume, brainValues] = APPLYBRAINMASK(volume, brainMask)
%   restituisce due rappresentazioni distinte:
%
%     maskedVolume  copia del volume con i voxel fuori dalla maschera posti
%                   a 0 (solo visualizzazione/memorizzazione con la stessa
%                   geometria). Gli zeri inseriti sono ARTIFICIALI: non
%                   vanno mai usati in istogrammi o stime di soglia.
%     brainValues   volume(brainMask), vettore colonna dei soli valori
%                   dentro la maschera: è la popolazione di intensità
%                   cerebrale da usare per le statistiche (es. fase 40).
%
%   Dentro la maschera i valori sono copiati senza alcuna operazione
%   aritmetica. Il volume e la maschera in ingresso non vengono
%   modificati. Nessun ricampionamento, nessuna registrazione.
%
%   Input:
%     volume     volume numerico reale (es. T2 double normalizzata)
%     brainMask  maschera logica con le stesse dimensioni

    arguments
        volume {mustBeNumeric, mustBeReal}
        brainMask logical
    end

    if ~isequal(size(volume), size(brainMask))
        error('preprocessing:sizeMismatch', ...
            'Volume size [%s] differs from brain-mask size [%s].', ...
            num2str(size(volume)), num2str(size(brainMask)));
    end

    maskedVolume = volume;
    maskedVolume(~brainMask) = 0;
    brainValues = volume(brainMask);

end
