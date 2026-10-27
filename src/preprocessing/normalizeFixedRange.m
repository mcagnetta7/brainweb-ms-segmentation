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
%
%   Ingressi:
%     volume       volume in virgola mobile (nella v4: uscita di convertToWorkingClass)
%     inputRange   intervallo di partenza [a b] (nella v4: [0 4095])
%     outputRange  intervallo di arrivo [c d] (nella v4: [0 1])
%   Uscita:
%     normalizedVolume  volume riscalato; nella v4 equivale a volume / 4095

    % --- Validazione degli ingressi ------------------------------------------------
    % mustBeFloat: il volume deve essere già double o single (con un intero la
    % divisione verrebbe arrotondata); ogni intervallo è un vettore di 2 numeri finiti.
    arguments
        volume {mustBeFloat, mustBeReal}
        inputRange (1,2) double {mustBeFinite}
        outputRange (1,2) double {mustBeFinite}
    end

    % Gli intervalli devono essere crescenti: un intervallo invertito capovolgerebbe
    % le intensità, uno di larghezza zero darebbe una divisione per zero.
    % || è l'"oppure" tra singoli valori, con valutazione abbreviata.
    if inputRange(2) <= inputRange(1) || outputRange(2) <= outputRange(1)
        error('preprocessing:invalidRange', ...
            'Ranges must be increasing: input [%g %g], output [%g %g].', ...
            inputRange(1), inputRange(2), outputRange(1), outputRange(2));
    end

    % Ogni voxel deve stare nell'intervallo di ingresso ed essere finito: | combina
    % le tre condizioni voxel per voxel, any è vero se almeno un voxel le viola.
    % Un valore fuori intervallo (es. file letto con l'ordine dei byte sbagliato)
    % interrompe l'elaborazione invece di essere tagliato silenziosamente.
    if any(volume(:) < inputRange(1) | volume(:) > inputRange(2) | ~isfinite(volume(:)))
        error('preprocessing:valueOutOfRange', ...
            'Volume contains values outside [%g %g] or non-finite values.', ...
            inputRange(1), inputRange(2));
    end

    % --- Trasformazione lineare [a, b] -> [c, d] ----------------------------------
    % (in - a) porta l'inizio a 0, / (b - a) porta l'intervallo a [0, 1],
    % * (d - c) lo allarga alla larghezza di arrivo, + c lo sposta all'inizio di arrivo.
    % Applicata a tutti i voxel in un colpo solo, senza cicli.
    normalizedVolume = (volume - inputRange(1)) / (inputRange(2) - inputRange(1)) ...
        * (outputRange(2) - outputRange(1)) + outputRange(1);

end
