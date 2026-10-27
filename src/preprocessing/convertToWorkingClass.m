function workingVolume = convertToWorkingClass(volume, workingClass)
%CONVERTTOWORKINGCLASS Converte un volume MRI nel tipo numerico di lavoro.
%
%   workingVolume = CONVERTTOWORKINGCLASS(volume, workingClass) restituisce
%   il volume convertito in workingClass ("double" o "single") con un
%   cast semplice che conserva i valori numerici: un valore grezzo 4095
%   resta 4095.
%
%   Non è una normalizzazione: a differenza di im2double o mat2gray, la
%   scala delle intensità non cambia. Dimensioni invariate.
%
%   Ingressi:
%     volume        volume da convertire (nella v4: interi uint16 letti dal file)
%     workingClass  tipo di destinazione, "double" o "single" (la v4 usa "double")
%   Uscita:
%     workingVolume stesso volume, stessi valori, nel nuovo tipo numerico

    % --- Validazione degli ingressi ------------------------------------------------
    % volume deve contenere numeri reali; workingClass deve essere un testo e può
    % valere solo "double" o "single": qualsiasi altro valore viene rifiutato.
    arguments
        volume {mustBeNumeric, mustBeReal}
        workingClass {mustBeTextScalar, mustBeMember(workingClass, ["double", "single"])}
    end

    % Da stringa ("double") ad array di caratteri ('double'), il formato usato da
    % flintmax e cast più avanti.
    workingClass = char(workingClass);

    % --- Controllo che la conversione sia esatta ----------------------------------
    % Un intero è rappresentato esattamente in floating point solo fino a
    % flintmax del tipo di destinazione (2^24 per single, 2^53 per double)
    % Il controllo serve solo per volumi di tipo intero (isinteger guarda il tipo,
    % non i valori) e non vuoti.
    if isinteger(volume) && ~isempty(volume)
        % Valore assoluto più grande del volume: volume(:) mette tutti i voxel in un
        % vettore colonna; double(...) prima di abs evita la saturazione degli interi.
        largest = max(abs(double(volume(:))));
        % Oltre flintmax alcuni interi verrebbero arrotondati: la funzione si ferma
        % invece di perdere precisione. Con BrainWeb il massimo è 4095, quindi il
        % controllo passa sempre ma garantisce che la conversione sia esatta.
        if largest > flintmax(workingClass)
            error('preprocessing:inexactConversion', ...
                'Values up to %g cannot be represented exactly as %s.', ...
                largest, workingClass);
        end
    end

    % --- Conversione --------------------------------------------------------------
    % cast cambia solo il tipo dei numeri, non i valori né le dimensioni:
    % il uint16 4095 diventa il double 4095.
    workingVolume = cast(volume, workingClass);

end
