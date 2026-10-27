function [candidate, selectedCore, diagnostics] = brainMask3DErodeSelectDilate(rawMask, radius, connectivity)
%BRAINMASK3DERODESELECTDILATE Erosione 3D -> componente 3D più grande -> dilatazione 3D (EXP-021).
%
%   [candidate, selectedCore, diagnostics] =
%   BRAINMASK3DERODESELECTDILATE(rawMask, radius, connectivity):
%
%     1. eroded = imerode(rawMask, strel('sphere', radius))        (3D)
%     2. componenti connesse 3D di eroded (bwconncomp, connectivity)
%     3. selectedCore = componente 3D più grande (parità: prima
%        nell'ordine di bwconncomp)
%     4. restored = imdilate(selectedCore, strel('sphere', radius))
%        AND rawMask                                                 (3D)
%     5. candidate = imfill(restored(:,:,k), 'holes') slice per slice (2D)
%
%   
%
%   Input:
%     rawMask       maschera logica grezza 3D (T1 Otsu, EXP-010)
%     radius        raggio della sfera (voxel, 1 mm isotropo)
%     connectivity  connettività 3D delle componenti: 6, 18 oppure 26
%
%   Output:
%     candidate     maschera candidata
%     selectedCore  componente 3D scelta dopo l'erosione (prima della
%                   dilatazione)
%     diagnostics   struttura: erodedVoxels, nComponents, componentSizes
%                   (ordinate, decrescenti), selectedIndex, restoredVoxels,
%                   addedByFilling
%
%   Nessuna soglia di area, nessuna regola di posizione, nessun ground truth.
%
%   Nella v4 è chiamata con radius = 3 e connectivity = 26, e la sua prima uscita
%   (candidate) è la maschera cerebrale B. Idea: l'erosione stacca il cervello dai
%   tessuti extracerebrali collegati da ponti sottili, la componente più grande è il
%   cervello, la dilatazione limitata alla maschera grezza ne restituisce l'estensione.

    % --- Validazione degli ingressi ------------------------------------------------
    % rawMask deve essere un volume logico 3D; radius un intero positivo;
    % connectivity uno dei tre valori ammessi in 3D (facce, + spigoli, + vertici).
    arguments
        rawMask (:,:,:) logical
        radius (1,1) double {mustBeInteger, mustBePositive}
        connectivity (1,1) double {mustBeMember(connectivity, [6 18 26])}
    end

    % --- 1. Erosione 3D ------------------------------------------------------------
    % Elemento strutturante 3D: sfera di raggio radius (nella v4: 3 voxel = 3 mm).
    element = strel('sphere', radius);
    % Erosione: un voxel resta vero solo se tutta la sfera centrata su di esso è dentro
    % la maschera. Assottiglia la maschera e interrompe i ponti sottili tra cervello
    % e tessuti extracerebrali.
    eroded = imerode(rawMask, element);

    % --- 2. Componenti connesse 3D -----------------------------------------------
    % bwconncomp etichetta le regioni separate della maschera erosa; con
    % connectivity = 26 due voxel sono collegati se condividono faccia, spigolo o vertice.
    components = bwconncomp(eroded, connectivity);
    % Numero di voxel di ogni componente: PixelIdxList contiene, per ogni componente,
    % l'elenco degli indici dei suoi voxel; numel ne conta gli elementi.
    sizes = cellfun(@numel, components.PixelIdxList);
    % Diagnostica: voxel dopo l'erosione, numero di componenti, dimensioni ordinate.
    diagnostics.erodedVoxels = nnz(eroded);
    diagnostics.nComponents = components.NumObjects;
    diagnostics.componentSizes = sort(sizes, 'descend');

    % Uscite inizializzate vuote (tutto falso) e diagnostica a zero.
    selectedCore = false(size(rawMask));
    candidate = false(size(rawMask));
    diagnostics.selectedIndex = 0;
    diagnostics.restoredVoxels = 0;
    diagnostics.addedByFilling = 0;
    % Caso limite: se l'erosione ha cancellato tutto non c'è nulla da selezionare,
    % e la funzione restituisce maschere vuote.
    if components.NumObjects == 0
        return
    end

    % --- 3. Selezione della componente più grande -------------------------------
    % max restituisce anche la posizione del massimo (in caso di parità, la prima);
    % ~ scarta il valore massimo, che non serve.
    [~, index] = max(sizes);
    diagnostics.selectedIndex = index;
    % Il nucleo selezionato: vero solo nei voxel della componente più grande (il cervello).
    selectedCore(components.PixelIdxList{index}) = true;

    % --- 4. Dilatazione 3D limitata alla maschera grezza -----------------------
    % La dilatazione con la stessa sfera restituisce al nucleo il suo spessore;
    % l'AND con rawMask impedisce di aggiungere voxel che la soglia di Otsu aveva
    % escluso, così le strutture staccate dall'erosione non rientrano.
    restored = imdilate(selectedCore, element) & rawMask;
    diagnostics.restoredVoxels = nnz(restored);

    % --- 5. Riempimento dei buchi slice per slice -------------------------------
    % In ogni slice assiale, imfill(..., 'holes') riempie le regioni completamente
    % racchiuse dalla maschera (es. zone scure in T1 circondate da tessuto cerebrale).
    for k = 1:size(rawMask, 3)
        candidate(:, :, k) = imfill(restored(:, :, k), 'holes');
    end
    % Diagnostica: quanti voxel ha aggiunto il riempimento.
    diagnostics.addedByFilling = nnz(candidate) - nnz(restored);

end
