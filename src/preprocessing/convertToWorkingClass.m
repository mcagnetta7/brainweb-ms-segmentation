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

    arguments
        volume {mustBeNumeric, mustBeReal}
        workingClass {mustBeTextScalar, mustBeMember(workingClass, ["double", "single"])}
    end

    workingClass = char(workingClass);

    % Un intero è rappresentato esattamente in floating point solo fino a
    % flintmax del tipo di destinazione (2^24 per single, 2^53 per double)
    if isinteger(volume) && ~isempty(volume)
        largest = max(abs(double(volume(:))));
        if largest > flintmax(workingClass)
            error('preprocessing:inexactConversion', ...
                'Values up to %g cannot be represented exactly as %s.', ...
                largest, workingClass);
        end
    end

    workingVolume = cast(volume, workingClass);

end
