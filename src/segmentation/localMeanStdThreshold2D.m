function [candidate, thresholdMap, localMean, localStd, localCount] = ...
    localMeanStdThreshold2D(slice, maskSlice, windowSize, a, b)
%LOCALMEANSTDTHRESHOLD2D Soglia variabile del corso su una slice 2D (fase 59, EXP-027).
%
%   [candidate, thresholdMap, localMean, localStd, localCount] =
%   LOCALMEANSTDTHRESHOLD2D(slice, maskSlice, windowSize, a, b) calcola,
%   per ogni pixel della maschera, la soglia variabile del corso
%
%       T(x,y) = a * m(x,y) + b * s(x,y)
%
%   e restituisce candidate = maskSlice & (slice > T) (confronto STRETTO).
%
%   Scelte di progetto (non del corso):
%   - finestra quadrata windowSize x windowSize centrata sul pixel;
%   - statistiche MASCHERATE: contribuiscono solo i pixel con maskSlice ==
%     true dentro la finestra; al bordo dell'immagine la finestra è
%     troncata (il padding a zero vale anche per il conteggio, quindi
%     nessun valore di padding entra nelle statistiche);
%   - m = media dei N valori validi; s = deviazione standard di POPOLAZIONE
%     sqrt(E[x^2] - E[x]^2), calcolata come sqrt(N*S2 - S1^2) / N con
%     eventuali residui negativi azzerati;
%   - T non viene limitata a [0,1].
%
%   Esattezza numerica: se slice contiene intensità INTERE (es. livelli
%   grezzi 0...4095) le somme S1, S2 e N*S2 - S1^2 sono esatte in double,
%   quindi in una zona uniforme s = 0 esattamente e m coincide con il
%   valore del pixel. La regola è lineare nella scala d'intensità: il
%   chiamante può riportare T alla scala normalizzata dividendo.
%
%   La funzione non carica file, non conosce la condizione di rumore, non
%   usa ground truth, non regola parametri e non applica morfologia né
%   analisi delle componenti. Gli ingressi non vengono modificati.
%
%   Input:
%     slice       matrice 2D reale finita
%     maskSlice   maschera logica 2D con le stesse dimensioni
%     windowSize  intero dispari >= 1
%     a, b        scalari reali finiti >= 0
%
%   Output (fuori dalla maschera: candidate false, mappe NaN, conteggio 0):
%     candidate     maschera logica dei candidati
%     thresholdMap  T(x,y)
%     localMean     m(x,y)
%     localStd      s(x,y)
%     localCount    N(x,y), numero di pixel validi nella finestra

    if ~(isnumeric(slice) && isreal(slice) && ismatrix(slice))
        error('segmentation:invalidSlice', 'Slice must be a real numeric 2D array.');
    end
    if any(~isfinite(slice(:)))
        error('segmentation:invalidSlice', 'Slice must contain only finite values.');
    end
    if ~(islogical(maskSlice) && ismatrix(maskSlice))
        error('segmentation:invalidMask', 'Mask must be a logical 2D array.');
    end
    if ~isequal(size(slice), size(maskSlice))
        error('segmentation:sizeMismatch', 'Slice size [%s] differs from mask size [%s].', ...
            num2str(size(slice)), num2str(size(maskSlice)));
    end
    if ~(isnumeric(windowSize) && isscalar(windowSize) && isreal(windowSize) && isfinite(windowSize) ...
            && windowSize == round(windowSize) && windowSize >= 1 && mod(windowSize, 2) == 1)
        error('segmentation:invalidWindowSize', 'Window size must be an odd integer >= 1.');
    end
    if ~(isnumeric(a) && isscalar(a) && isreal(a) && isfinite(a) && a >= 0)
        error('segmentation:invalidCoefficient', 'Coefficient a must be a finite real scalar >= 0.');
    end
    if ~(isnumeric(b) && isscalar(b) && isreal(b) && isfinite(b) && b >= 0)
        error('segmentation:invalidCoefficient', 'Coefficient b must be a finite real scalar >= 0.');
    end

    % Somme sulla finestra con un filtro a scatola separabile di soli 1
    % (conv2 'same': padding 0 = finestra troncata al bordo). Coefficienti
    % interi espliciti, così le somme di interi restano esatte (imfilter
    % potrebbe scomporre il kernel via SVD con coefficienti non esatti).
    box = ones(windowSize, 1);
    windowSum = @(x) conv2(box, box.', x, 'same');
    valid = double(maskSlice);
    values = double(slice) .* valid;              % i pixel fuori maschera valgono 0 e non contano
    count = windowSum(valid);
    sum1 = windowSum(values);
    sum2 = windowSum(values .^ 2);

    localCount = zeros(size(slice));
    localMean = NaN(size(slice));
    localStd = NaN(size(slice));
    thresholdMap = NaN(size(slice));

    inside = maskSlice;
    n = count(inside);
    s1 = sum1(inside);
    s2 = sum2(inside);
    localCount(inside) = n;
    localMean(inside) = s1 ./ n;
    localStd(inside) = sqrt(max(n .* s2 - s1 .^ 2, 0)) ./ n;
    thresholdMap(inside) = a * localMean(inside) + b * localStd(inside);

    candidate = maskSlice & (double(slice) > thresholdMap);

end
