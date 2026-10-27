function [h, info] = renderMask3DSurface(ax, mask, color, alpha)
%RENDERMASK3DSURFACE Superficie 3D del bordo di una maschera binaria (solo visualizzazione).
%
%   [h, info] = RENDERMASK3DSURFACE(ax, mask, color, alpha) disegna nell'asse ax
%   l'isosuperficie a livello 0.5 della maschera binaria 3D mask, con colore
%   uniforme color e trasparenza alpha.
%
%   Convenzione delle coordinate (progetto): X = dimensione 1 dell'array,
%   Y = dimensione 2, Z = dimensione 3, indici di voxel con passo 1 mm.
%   Poiché isosurface associa le colonne di V a X e le righe a Y, le prime due
%   dimensioni vengono scambiate SOLO nella copia di visualizzazione; la maschera
%   in ingresso non viene modificata. La copia viene anche circondata da un bordo
%   di zeri (coordinate 0 e N+1) perché ogni componente produca una superficie
%   chiusa anche se tocca il bordo del volume: nessun voxel viene aggiunto o tolto.
%
%   Nessuna levigatura, interpolazione, sottocampionamento, filtraggio di
%   componenti o operazione morfologica: tutti i voxel contribuiscono alla
%   superficie. Maschera vuota: nessuna isosuperficie, h vuoto.
%
%   info: voxelCount, vertexCount, faceCount, e per i vertici il riquadro
%   [min max] lungo X / Y / Z (per verificare la convenzione: per una maschera
%   non vuota deve coincidere con il riquadro dei voxel ± 0.5).

    arguments
        ax (1,1) matlab.graphics.axis.Axes
        mask (:,:,:) logical
        color (1,3) double
        alpha (1,1) double = 1
    end

    info = struct('voxelCount', nnz(mask), 'vertexCount', 0, 'faceCount', 0, ...
        'vertexRange', NaN(3, 2));
    h = gobjects(0);
    if info.voxelCount == 0
        return
    end

    sz = size(mask, 1:3);
    displayVolume = zeros(sz([2 1 3]) + 2, 'single');
    displayVolume(2:end-1, 2:end-1, 2:end-1) = permute(mask, [2 1 3]);
    x = 0:sz(1) + 1; y = 0:sz(2) + 1; z = 0:sz(3) + 1;
    fv = isosurface(x, y, z, displayVolume, 0.5);

    h = patch(ax, 'Faces', fv.faces, 'Vertices', fv.vertices, 'FaceColor', color, ...
        'EdgeColor', 'none', 'FaceAlpha', alpha, 'FaceLighting', 'gouraud');
    info.vertexCount = size(fv.vertices, 1);
    info.faceCount = size(fv.faces, 1);
    info.vertexRange = [min(fv.vertices, [], 1).' max(fv.vertices, [], 1).'];
end
