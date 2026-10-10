function [threshold, history] = estimateIterativeThreshold(values, epsilon, maxIterations)
%ESTIMATEITERATIVETHRESHOLD Soglia globale iterativa del corso (fase 55).
%
%   [threshold, history] = ESTIMATEITERATIVETHRESHOLD(values, epsilon,
%   maxIterations) stima una soglia sui soli valori forniti:
%
%     T0 = mean(values)                      (descrizione scritta del corso)
%     ripeti:
%       R_high = values >= T,  R_low = values < T
%       mu_high = mean(values(R_high)),  mu_low = mean(values(R_low))
%       T_next  = (mu_low + mu_high) / 2
%       delta   = abs(T_next - T)
%       se delta < epsilon: soglia finale = T_next, fine
%       altrimenti T = T_next
%
%   Nota sulle fonti del corso: il testo indica come valore iniziale la
%   media dell'intensità; l'esempio MATLAB delle slide usa 0.5*mean. Qui si
%   segue la descrizione scritta (T0 = media).
%
%   La funzione non carica file, non conosce la condizione di rumore, la
%   maschera o il ground truth, non genera candidati e non regola
%   parametri. Se un gruppo diventa vuoto o la convergenza non avviene
%   entro maxIterations, si ferma con un errore (nessuna soglia di ripiego).
%
%   Input:
%     values         vettore reale finito non vuoto (es. T2(brainMask))
%     epsilon        tolleranza di convergenza, scalare reale finito > 0
%     maxIterations  limite di sicurezza, intero scalare >= 1
%
%   Output:
%     threshold  soglia finale (T_next dell'ultima iterazione)
%     history    struttura con vettori per iterazione: iteration,
%                thresholdCurrent, meanLow, meanHigh, thresholdNext, delta,
%                countLow, countHigh; più initialThreshold

    if ~(isnumeric(values) && isreal(values) && isvector(values) && ~isempty(values))
        error('segmentation:invalidValues', 'Values must be a non-empty real numeric vector.');
    end
    if any(~isfinite(values))
        error('segmentation:invalidValues', 'Values must contain only finite numbers.');
    end
    if ~(isnumeric(epsilon) && isreal(epsilon) && isscalar(epsilon) && isfinite(epsilon) && epsilon > 0)
        error('segmentation:invalidEpsilon', 'Epsilon must be a finite real scalar > 0.');
    end
    if ~(isnumeric(maxIterations) && isscalar(maxIterations) && isfinite(maxIterations) ...
            && maxIterations >= 1 && maxIterations == round(maxIterations))
        error('segmentation:invalidMaxIterations', 'maxIterations must be an integer scalar >= 1.');
    end

    values = double(values(:));
    current = mean(values);

    history.initialThreshold = current;
    history.iteration = zeros(0, 1);
    history.thresholdCurrent = zeros(0, 1);
    history.meanLow = zeros(0, 1);
    history.meanHigh = zeros(0, 1);
    history.thresholdNext = zeros(0, 1);
    history.delta = zeros(0, 1);
    history.countLow = zeros(0, 1);
    history.countHigh = zeros(0, 1);

    for iteration = 1:maxIterations
        high = values >= current;
        low = ~high;
        if ~any(high) || ~any(low)
            error('segmentation:emptyPartition', ...
                'Iterative threshold produced an empty partition at iteration %d (T = %.10g).', ...
                iteration, current);
        end
        meanLow = mean(values(low));
        meanHigh = mean(values(high));
        next = (meanLow + meanHigh) / 2;
        delta = abs(next - current);

        history.iteration(end+1, 1) = iteration;
        history.thresholdCurrent(end+1, 1) = current;
        history.meanLow(end+1, 1) = meanLow;
        history.meanHigh(end+1, 1) = meanHigh;
        history.thresholdNext(end+1, 1) = next;
        history.delta(end+1, 1) = delta;
        history.countLow(end+1, 1) = nnz(low);
        history.countHigh(end+1, 1) = nnz(high);

        if delta < epsilon
            threshold = next;
            return
        end
        current = next;
    end

    error('segmentation:notConverged', ...
        'Iterative threshold did not converge within %d iterations (last delta %.10g).', ...
        maxIterations, delta);

end
