function lesionCandidateMask = thresholdLesionCandidates(volume, brainMask, threshold)
%THRESHOLDLESIONCANDIDATES Baseline: soglia globale superiore dentro la maschera cerebrale (fase 53).
%
%   lesionCandidateMask = THRESHOLDLESIONCANDIDATES(volume, brainMask,
%   threshold) applica la baseline definita nella fase 53:
%
%       lesionCandidateMask = brainMask AND (volume > threshold)
%
%   - confronto STRETTO ">": un voxel uguale alla soglia NON è candidato;
%   - una sola soglia per tutto il volume 3D;
%   - fuori dalla maschera l'uscita è sempre false;
%   - nessuna morfologia, nessun filtro sulle componenti, nessun region
%     growing, nessuna fusione multimodale.
%
%   La funzione applica una soglia FORNITA: non la stima, non carica file,
%   non usa ground truth e non conosce la condizione di rumore. Gli
%   ingressi non vengono modificati.
%
%   Input:
%     volume     volume reale finito nella rappresentazione di lavoro
%                (T2 double normalizzata /4095); valori fuori da [0,1]
%                sono rifiutati (es. un volume grezzo 0...4095)
%     brainMask  maschera logica con le stesse dimensioni (EXP-021)
%     threshold  scalare reale finito nel dominio normalizzato [0,1]
%
%   Output:
%     lesionCandidateMask  maschera logica dei candidati (NON la maschera
%                          finale delle lesioni)

    if ~(isnumeric(volume) && isreal(volume))
        error('segmentation:invalidVolume', 'Volume must be a real numeric array.');
    end
    if any(~isfinite(volume(:)))
        error('segmentation:invalidVolume', 'Volume must contain only finite values.');
    end
    if ~isempty(volume) && (min(volume(:)) < 0 || max(volume(:)) > 1)
        error('segmentation:invalidVolume', ...
            'Volume values must lie in the normalized domain [0, 1] (found %g to %g).', ...
            min(volume(:)), max(volume(:)));
    end
    if ~islogical(brainMask)
        error('segmentation:invalidMask', 'Brain mask must be a logical array.');
    end
    if ~isequal(size(volume), size(brainMask))
        error('segmentation:sizeMismatch', ...
            'Volume size [%s] differs from brain-mask size [%s].', ...
            num2str(size(volume)), num2str(size(brainMask)));
    end
    if ~(isnumeric(threshold) && isreal(threshold) && isscalar(threshold) && isfinite(threshold))
        error('segmentation:invalidThreshold', 'Threshold must be a finite real scalar.');
    end
    if threshold < 0 || threshold > 1
        error('segmentation:invalidThreshold', ...
            'Threshold %g is outside the normalized domain [0, 1].', threshold);
    end

    lesionCandidateMask = brainMask & (volume > threshold);

end
