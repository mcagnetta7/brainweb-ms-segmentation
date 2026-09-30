%% BrainWeb Multiple Sclerosis Lesion Segmentation
% Punto di ingresso principale del progetto di Image Processing.
%
% La pipeline di elaborazione completa verrà aggiunta in modo incrementale.
% Nella fase attuale del progetto questo script si limita a:
%   - caricare la configurazione centrale;
%   - verificare le cartelle di progetto attese;
%   - riportare la configurazione attuale del progetto.
%
% Non vengono ancora usati dati BrainWeb né eseguiti algoritmi di
% segmentazione.

clearvars;
close all;
clc;

%% Caricamento della configurazione di progetto

cfg = config();


%% Verifica della struttura del progetto

requiredDirectories = {
    cfg.paths.rawData
    cfg.paths.processedData
    cfg.paths.src
    cfg.paths.io
    cfg.paths.preprocessing
    cfg.paths.segmentation
    cfg.paths.evaluation
    cfg.paths.visualization
    cfg.paths.experiments
    cfg.paths.results
    cfg.paths.figures
    cfg.paths.metrics
    cfg.paths.docs
};

for i = 1:numel(requiredDirectories)
    assert( ...
        isfolder(requiredDirectories{i}), ...
        'Project directory not found: %s', ...
        requiredDirectories{i});
end


%% Stato del progetto

fprintf('BrainWeb MS Lesion Segmentation\n');
fprintf('-------------------------------\n');
fprintf('Project root: %s\n', cfg.paths.projectRoot);
fprintf('Processing strategy: %s\n', cfg.processing.dimension);
fprintf('Project structure: OK\n');
fprintf('Dataset configured: NO\n');
fprintf('Segmentation pipeline implemented: NO\n');
