function fusedMask = fuseCandidateMasksIntersection(primaryMask, secondaryMask)
%FUSECANDIDATEMASKSINTERSECTION Fusione binaria a livello di decisione (intersezione).
%
%   fusedMask = FUSECANDIDATEMASKSINTERSECTION(primaryMask, secondaryMask)
%   restituisce primaryMask & secondaryMask: un voxel resta candidato solo
%   se entrambe le maschere lo marcano. Il risultato è sempre un
%   sottoinsieme di entrambe le maschere; nessun voxel viene aggiunto.
%
%   Le due maschere devono essere logiche, 3D, non vuote come array e
%   della stessa dimensione. Nessuna soglia, morfologia, GT o file.

    arguments
        primaryMask {mustBeA(primaryMask, 'logical')}
        secondaryMask {mustBeA(secondaryMask, 'logical')}
    end

    if ndims(primaryMask) ~= 3 || isempty(primaryMask)
        error('fuseCandidateMasksIntersection:invalidPrimary', ...
            'The primary mask must be a non-empty 3D logical array.');
    end
    if ~isequal(size(primaryMask), size(secondaryMask))
        error('fuseCandidateMasksIntersection:sizeMismatch', ...
            'The two masks must have the same size (%s vs %s).', ...
            mat2str(size(primaryMask)), mat2str(size(secondaryMask)));
    end

    fusedMask = primaryMask & secondaryMask;
end
