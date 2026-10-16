function finalConfig = finalSegmentationConfig()
%FINALSEGMENTATIONCONFIG Definizione congelata della pipeline finale v3 (fase 96).
%
%   finalConfig = FINALSEGMENTATIONCONFIG() restituisce la definizione
%   completa e immutabile della pipeline principale v3 (EXP-059, D3_M1_G0),
%   scelta con i soli dati di sviluppo (pn0 + pn3) prima di qualsiasi accesso
%   ai dati held-out. Contiene solo regole e parametri fissi: nessuna soglia
%   numerica misurata su una condizione (le soglie sono stimate dai dati con
%   le regole automatiche qui descritte).
%
%   Usata da generateFinalPrediction, che verifica la coerenza tra questo
%   record e gli helper congelati. Nessun GT, nessun accesso a file.

    finalConfig = struct();

    % Provenienza
    finalConfig.version = "v3";
    finalConfig.sourceExperiment = "EXP-059";
    finalConfig.sourceConfiguration = "D3_M1_G0";
    finalConfig.selectionCriterion = "Phase-37 DevelopmentScore = (Dice_pn0 + Dice_pn3) / 2";
    finalConfig.developmentConditions = ["pn0" "pn3"];
    finalConfig.heldOutUsedForSelection = false;
    finalConfig.secondaryLockedVersions = ["v1 = EXP-057 S2_TA_M2_G1" "v2 = EXP-058 F5_R0"];

    % Ingressi e normalizzazione
    finalConfig.modalities = ["T1" "T2"];
    finalConfig.t1Role = "automatic brain support (EXP-021) and anatomical support S2";
    finalConfig.t2Role = "lesion intensity segmentation";
    finalConfig.pdUsed = false;
    finalConfig.workingClass = "double";
    finalConfig.normalizationInputRange = [0 4095];
    finalConfig.normalizationOutputRange = [0 1];

    % Maschera cerebrale EXP-021 (da T1 normalizzato)
    finalConfig.brainMaskMethod = "EXP-021";
    finalConfig.brainMaskThreshold = "graythresh(T1norm(:)), one global threshold, imbinarize per axial slice (value > threshold)";
    finalConfig.brainMaskErosionElement = "sphere";
    finalConfig.brainMaskRadius = 3;
    finalConfig.brainMaskComponentConnectivity = 26;
    finalConfig.brainMaskComponentRule = "largest 3D connected component after erosion";
    finalConfig.brainMaskRestore = "imdilate(core, sphere 3) AND raw foreground";
    finalConfig.brainMaskFill = "imfill(slice, 'holes') per axial slice";

    % Partizione T1 e supporto S2 (T1 NON filtrato)
    finalConfig.t1Filtered = false;
    finalConfig.t1PartitionNumberOfThresholds = 2;
    finalConfig.t1LowClass = 1;
    finalConfig.t1HighClass = 3;
    finalConfig.support = "S2";
    finalConfig.supportDefinition = "brainMask AND imfill(T1-high slice, 'holes') per axial slice AND NOT T1-low";

    % Filtro del T2: diffusione anisotropa 3D sull'intero volume (D3)
    finalConfig.t2Filter = "anisotropic diffusion (imdiffusefilt), explicit project parameters, not MATLAB defaults";
    finalConfig.t2FilterDimensionality = "3D whole volume";
    finalConfig.t2FilterId = "D3";
    finalConfig.gradientThresholdFraction = 0.10;
    finalConfig.gradientThresholdRule = "0.10 * (max(T2norm(:)) - min(T2norm(:))); constant volume returned unchanged";
    finalConfig.numberOfIterations = 5;
    finalConfig.connectivity = "maximal";
    finalConfig.connectivityNeighbours3D = 26;
    finalConfig.conductionMethod = "exponential";
    finalConfig.filterRangeHandling = "error if output leaves [0,1] by more than 1e-12, then clipped to [0,1]";

    % Soglia T2 (TA)
    finalConfig.t2ThresholdRule = "TA";
    finalConfig.t2ThresholdNumberOfThresholds = 2;
    finalConfig.t2SelectedClass = 3;
    finalConfig.t2ThresholdEstimatedInside = "S2";
    finalConfig.t2Comparator = "S2 AND T2filtered > levels(2) (imquantize class 3)";

    % Morfologia
    finalConfig.morphology = "opening";
    finalConfig.morphologyDimensionality = "2D axial, per slice, exactly one opening, then AND S2";
    finalConfig.structuringElement = "diamond";
    finalConfig.structuringElementParameter = 1;

    % Nessun altro passo
    finalConfig.componentFilter = "none";
    finalConfig.recovery = "none";
    finalConfig.regionGrowing = "none";
end
