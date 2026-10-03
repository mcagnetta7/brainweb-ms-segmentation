%% Validazione del visualizzatore di slice assiali (fase 33)
% Carica un volume con il loader di src/io, apre il visualizzatore e ne
% verifica il comportamento: slice iniziale, cambio di slice, prima e
% ultima slice, indici non validi, corrispondenza tra indice mostrato e
% dati, volume non modificato. Alla fine il visualizzatore resta aperto
% sulla slice iniziale per l'uso interattivo.
%
% La modalità T1 è la stessa delle fasi 31-32 ed è usata solo per la
% verifica: non è la scelta della modalità baseline. Il ground truth non
% viene usato. Nessun file viene scritto.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = config();
addpath(cfg.paths.io, cfg.paths.visualization);

modality = "T1";
volume = loadBrainwebMri(cfg, modality);
volumeCopy = volume;                        % riferimento per il confronto finale
nSlices = size(volume, 3);
initialSlice = ceil(nSlices / 2);

fig = axialSliceViewer(volume, initialSlice, modality);
viewer = fig.UserData;
slider = findobj(fig, 'Style', 'slider');
editBox = findobj(fig, 'Style', 'edit');

checks = cell(0, 2);    % {descrizione, esito}
shows = @(k) viewer.getSlice() == k ...
    && isequal(viewer.image.CData, volume(:, :, k).') ...
    && contains(get(get(fig.CurrentAxes, 'Title'), 'String'), ...
                sprintf('k = %d / %d', k, nSlices));

checks(end+1, :) = {'volume size', isequal(size(volume), cfg.dataset.volumeSize)};
checks(end+1, :) = {sprintf('initial slice %d', initialSlice), shows(initialSlice)};


%% Cambio di slice tramite setSlice

for k = [1 nSlices 40 140 initialSlice]
    checks(end+1, :) = {sprintf('setSlice(%d)', k), viewer.setSlice(k) && shows(k)}; %#ok<SAGROW>
end


%% Tutte le slice, dalla prima all'ultima

allSlicesOk = true;
for k = 1:nSlices
    allSlicesOk = allSlicesOk && viewer.setSlice(k) && shows(k);
end
checks(end+1, :) = {'browse all slices 1...end', allSlicesOk};


%% Indici non validi: devono essere rifiutati senza errori

viewer.setSlice(initialSlice);
invalidInputs = {0, nSlices + 1, -5, 2.5, NaN, Inf, [1 2]};
for n = 1:numel(invalidInputs)
    value = invalidInputs{n};
    rejected = ~viewer.setSlice(value) && shows(initialSlice);
    checks(end+1, :) = {sprintf('reject %s', mat2str(value)), rejected}; %#ok<SAGROW>
end


%% Controlli dell'interfaccia (callback reali)

slider.Value = nSlices;
slider.Callback(slider, []);
checks(end+1, :) = {'slider to last slice', shows(nSlices)};

slider.Value = 37.4;
slider.Callback(slider, []);
checks(end+1, :) = {'slider 37.4 -> 37', shows(37)};

editBox.String = '1';
editBox.Callback(editBox, []);
checks(end+1, :) = {'edit box "1"', shows(1)};

editBox.String = 'abc';
editBox.Callback(editBox, []);
checks(end+1, :) = {'edit box "abc" rejected', shows(1)};

editBox.String = '500';
editBox.Callback(editBox, []);
checks(end+1, :) = {'edit box "500" rejected', shows(1)};


%% Volume non modificato

checks(end+1, :) = {'volume unchanged', isequal(volume, volumeCopy)};


%% Esito e ritorno alla slice iniziale

viewer.setSlice(initialSlice);

fprintf('\n');
for c = 1:size(checks, 1)
    if checks{c, 2}
        result = 'ok';
    else
        result = 'FAILED';
    end
    fprintf('%-30s %s\n', checks{c, 1}, result);
end

if all([checks{:, 2}])
    fprintf('\nVIEWER VALIDATION: PASS  (viewer left open at slice %d)\n', initialSlice);
else
    fprintf('\nVIEWER VALIDATION: FAIL\n');
end
