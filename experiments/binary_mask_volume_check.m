%% Controllo sintetico di computeBinaryMaskVolume (maschere artificiali, nessun dato reale)

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.evaluation);

sz = [4 5 3];
unit = [1 1 1];

m1 = false(sz); m1(2, 3, 2) = true;                          % 1 voxel
m5 = false(sz); m5(1, 1:5, 1) = true;                        % 5 voxel
m4 = false(sz); m4(3, 1:4, 3) = true;                        % 4 voxel
aniso = [1 2 3];                                             % voxel da 6 mm^3
m4Copy = m4; anisoCopy = aniso;

v1 = computeBinaryMaskVolume(m1, unit);
v5 = computeBinaryMaskVolume(m5, unit);
v4 = computeBinaryMaskVolume(m4, aniso);
v0 = computeBinaryMaskVolume(false(sz), unit);

checks = {
    "1 one voxel, unit spacing: count 1, voxel 1 mm^3, volume 1 mm^3", v1.voxelCount == 1 && v1.voxelVolumeMm3 == 1 && v1.volumeMm3 == 1
    "2 five voxels, unit spacing: volume 5 mm^3",     v5.voxelCount == 5 && v5.volumeMm3 == 5
    "3 anisotropic [1 2 3] mm: voxel 6 mm^3, 4 voxels -> 24 mm^3", v4.voxelVolumeMm3 == 6 && v4.voxelCount == 4 && v4.volumeMm3 == 24
    "4 valid all-false mask: count 0, volume 0 mm^3", v0.voxelCount == 0 && v0.volumeMm3 == 0
    "unit conversion: cm^3 = mL = mm^3 / 1000",       v4.volumeCm3 == 24 / 1000 && v4.volumeMl == v4.volumeCm3
    "5 non-logical mask rejected",                    throwsError(@() computeBinaryMaskVolume(double(m1), unit))
    "6 empty array rejected",                         throwsError(@() computeBinaryMaskVolume(false(0, 3), unit))
    "7 spacing of wrong length rejected",             throwsError(@() computeBinaryMaskVolume(m1, [1 1])) && ...
                                                       throwsError(@() computeBinaryMaskVolume(m1, [1 1 1 1]))
    "8 zero spacing rejected",                        throwsError(@() computeBinaryMaskVolume(m1, [1 0 1]))
    "9 negative spacing rejected",                    throwsError(@() computeBinaryMaskVolume(m1, [1 -1 1]))
    "10 NaN spacing rejected",                        throwsError(@() computeBinaryMaskVolume(m1, [1 NaN 1]))
    "11 Inf spacing rejected",                        throwsError(@() computeBinaryMaskVolume(m1, [Inf 1 1]))
    "12 deterministic",                               isequal(computeBinaryMaskVolume(m4, aniso), v4)
    "13 inputs unchanged",                            isequal(m4, m4Copy) && isequal(aniso, anisoCopy)
    };

for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-65s %s\n', checks{c, 1}, result);
end
if any(~[checks{:, 2}])
    error('binaryMaskVolumeCheck:failed', 'Synthetic volume check failed.');
end
fprintf('\nSYNTHETIC VOLUME CHECK: PASS (%d)\n', size(checks, 1));

function tf = throwsError(fn)
%THROWSERROR Vero se la chiamata genera un errore.
    try
        fn();
        tf = false;
    catch
        tf = true;
    end
end
