function normalizedVolume = normalizeFixedRange(volume, inputRange, outputRange)
%NORMALIZEFIXEDRANGE Riscalamento lineare fisso delle intensità.
%
%   normalizedVolume = NORMALIZEFIXEDRANGE(volume, inputRange, outputRange)
%   applica la trasformazione lineare
%
%     out = (in - inputRange(1)) / (inputRange(2) - inputRange(1)) ...
%           * (outputRange(2) - outputRange(1)) + outputRange(1)
%
%   con limiti fissati dalla configurazione, mai stimati dal volume
%   (niente min/max dell'immagine). È una trasformazione lineare
%   crescente: conserva l'ordinamento dei voxel e la struttura
%   dell'immagine, non aggiunge informazione.
%
%   Valori fuori da inputRange generano un errore invece di essere
%   tagliati. Dimensioni invariate.

    arguments
        volume {mustBeFloat, mustBeReal}
        inputRange (1,2) double {mustBeFinite}
        outputRange (1,2) double {mustBeFinite}
    end

    if inputRange(2) <= inputRange(1) || outputRange(2) <= outputRange(1)
        error('preprocessing:invalidRange', ...
            'Ranges must be increasing: input [%g %g], output [%g %g].', ...
            inputRange(1), inputRange(2), outputRange(1), outputRange(2));
    end

    if any(volume(:) < inputRange(1) | volume(:) > inputRange(2) | ~isfinite(volume(:)))
        error('preprocessing:valueOutOfRange', ...
            'Volume contains values outside [%g %g] or non-finite values.', ...
            inputRange(1), inputRange(2));
    end

    normalizedVolume = (volume - inputRange(1)) / (inputRange(2) - inputRange(1)) ...
        * (outputRange(2) - outputRange(1)) + outputRange(1);

end
