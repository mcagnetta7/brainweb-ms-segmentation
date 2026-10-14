function errorInfo = computeVolumeErrorPercent(gtVolume, predictedVolume)
%COMPUTEVOLUMEERRORPERCENT Errore percentuale di volume (definizione di PROJECT_SPEC).
%
%   errorInfo = COMPUTEVOLUMEERRORPERCENT(gtVolume, predictedVolume) confronta
%   due volumi fisici scalari espressi nella stessa unità:
%
%       signedDifference   = predictedVolume - gtVolume
%       absoluteDifference = |predictedVolume - gtVolume|
%       volumeErrorPercent = absoluteDifference / gtVolume * 100
%
%   La metrica formale è assoluta e non è limitata a 100 %. La differenza
%   con segno serve solo per descrivere la direzione dell'errore.
%
%   Entrambi i volumi: numerici, scalari, reali, finiti, non negativi.
%   gtVolume deve essere strettamente positivo (la formula divide per V_GT;
%   nessuna convenzione per V_GT = 0). predictedVolume = 0 è valido.
%   Nessun accesso a file, nessuna maschera, nessuna altra metrica.

    arguments
        gtVolume
        predictedVolume
    end

    validateVolume(gtVolume, 'gtVolume');
    validateVolume(predictedVolume, 'predictedVolume');
    if gtVolume == 0
        error('computeVolumeErrorPercent:zeroGtVolume', ...
            'gtVolume must be strictly positive: the percentage error is undefined for V_GT = 0.');
    end

    errorInfo = struct();
    errorInfo.gtVolume = double(gtVolume);
    errorInfo.predictedVolume = double(predictedVolume);
    errorInfo.signedDifference = errorInfo.predictedVolume - errorInfo.gtVolume;
    errorInfo.absoluteDifference = abs(errorInfo.signedDifference);
    errorInfo.volumeErrorPercent = errorInfo.absoluteDifference / errorInfo.gtVolume * 100;
end

function validateVolume(v, name)
%VALIDATEVOLUME Volume scalare numerico, reale, finito e non negativo.
    if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ~isfinite(v) || v < 0
        error('computeVolumeErrorPercent:invalidVolume', ...
            '%s must be a numeric, real, finite, non-negative scalar.', name);
    end
end
