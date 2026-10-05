# BrainWeb Multiple Sclerosis Lesion Segmentation

MATLAB project for the automatic segmentation of multiple sclerosis lesions in simulated BrainWeb MRI volumes using classical Image Processing techniques.

The project is developed for the Image Processing course and focuses on the application, comparison and evaluation of traditional image-processing methods without Machine Learning or Deep Learning.

---

## Project Objective

The objective is to develop an automatic processing pipeline that receives a BrainWeb MRI volume as input and produces a binary lesion mask:

$$
M_{pred}(x,y,z)
$$

where:

- `1` identifies a voxel classified as lesion;
- `0` identifies a voxel classified as non-lesion.

The predicted mask will then be compared with the corresponding BrainWeb ground truth:

$$
M_{GT}(x,y,z)
$$

to quantitatively evaluate the segmentation quality.

The ground truth is used exclusively for evaluation and visualization and must never be used to generate the predicted segmentation.

---

## Dataset

The project uses the BrainWeb Simulated Brain Database.

BrainWeb provides simulated brain MRI data with known anatomical information and ground truth, making it suitable for the quantitative evaluation of image segmentation algorithms.

The project will investigate the MRI modalities available for the selected multiple-sclerosis phantom, including:

- T1-weighted MRI;
- T2-weighted MRI;
- Proton Density (PD) MRI.

The final choice of the modality, or combination of modalities, will be made experimentally after analyzing the available data.

The exact representation of the lesion ground truth will also be verified before the segmentation pipeline is finalized.

> BrainWeb contains simulated MRI data and must not be described as a dataset of real clinical MRI acquisitions.

---

## Main Constraints

The project follows these rules:

- MATLAB implementation;
- classical Image Processing techniques only;
- no Machine Learning;
- no Deep Learning;
- automatic final segmentation;
- no manual lesion selection in the final algorithm;
- ground truth used only for evaluation and visualization;
- parameters must not be optimized using the final test data;
- processing choices must be motivated by experimental observations;
- additional processing stages are introduced only when they solve an observed problem.

---

## Planned Processing Pipeline

The initial project pipeline is:

```text
BrainWeb MRI
      │
      ▼
Data Loading and Validation
      │
      ▼
Intensity Analysis
      │
      ▼
Preprocessing
      │
      ▼
Brain Mask Extraction
      │
      ▼
Lesion Candidate Detection
      │
      ▼
Thresholding
      │
      ▼
Morphological Processing
      │
      ▼
Connected Components
      │
      ▼
Predicted Lesion Mask
      │
      ▼
Ground Truth Comparison
      │
      ▼
Quantitative Evaluation
      │
      ▼
2D / 3D Visualization
```

The first implementation will intentionally remain simple.

Additional techniques will be introduced only if they provide a measurable improvement.

Possible extensions include:

- region growing;
- multiple thresholding;
- local/variable thresholding;
- multimodal MRI combination;
- 3D connected-component analysis;
- robustness analysis at different noise levels.

---

## Image Processing Techniques

The project may use techniques covered during the Image Processing course, including:

### Intensity analysis

- grayscale image analysis;
- histograms;
- intensity normalization;
- point operations.

### Filtering

- mean filtering;
- Gaussian filtering;
- median filtering.

### Segmentation

- global thresholding;
- iterative thresholding;
- Otsu thresholding;
- multiple thresholding;
- local or variable thresholding;
- region growing;
- watershed segmentation.

### Mathematical morphology

- erosion;
- dilation;
- opening;
- closing;
- morphological reconstruction.

### Region analysis

- pixel connectivity;
- connected components;
- region labeling;
- region properties.

Not every technique listed above will necessarily be included in the final pipeline.

---

## Evaluation

The predicted lesion mask will be compared with the BrainWeb ground truth.

The planned voxel-wise evaluation includes:

- Dice coefficient;
- Intersection over Union (IoU / Jaccard);
- Precision;
- Recall / Sensitivity;
- Specificity;
- lesion volume error.

The main evaluation will be performed on the complete 3D volume.

Slice-wise analysis may additionally be used to understand where segmentation errors occur.

A lesion-wise analysis may also be performed using connected components to evaluate:

- correctly detected lesions;
- missed lesions;
- false lesion detections.

---

## Repository Structure

```text
brainweb-ms-segmentation/
│
├── data/
│   ├── raw/
│   └── processed/
│
├── src/
│   ├── io/
│   ├── preprocessing/
│   ├── segmentation/
│   ├── evaluation/
│   └── visualization/
│
├── experiments/
│
├── results/
│   ├── figures/
│   └── metrics/
│
├── docs/
│
└── README.md
```

### `data/raw`

Contains the original BrainWeb files exactly as downloaded.

Files in this directory must never be modified by the processing pipeline and are excluded from Git.

### `data/processed`

Contains eventual converted, normalized or derived data.

### `src/io`

MATLAB functions responsible for:

- loading BrainWeb volumes;
- reading file formats;
- validating dimensions and metadata.

### `src/preprocessing`

Preprocessing operations such as:

- intensity normalization;
- filtering;
- preparation of MRI volumes.

### `src/segmentation`

Core segmentation pipeline, including:

- brain-mask extraction;
- lesion candidate detection;
- thresholding;
- morphological processing;
- connected-component processing;
- optional region growing.

### `src/evaluation`

Functions for quantitative comparison between predicted segmentation and ground truth.

### `src/visualization`

Functions for:

- MRI slice visualization;
- segmentation overlays;
- error visualization;
- 3D visualization.

### `experiments`

Scripts used for controlled experiments, comparisons and parameter studies.

### `results`

Generated quantitative and visual results.

---

## Requirements

Current development environment:

- MATLAB R2026b;
- Image Processing Toolbox R2026b.

The following MATLAB Image Processing Toolbox functions have already been verified as available:

```matlab
graythresh
imbinarize
imgaussfilt
imopen
imclose
bwconncomp
regionprops
```

Additional MATLAB functions may be used as the project evolves.

---

## Development Workflow

Development is performed incrementally.

Each processing stage must be validated before proceeding to the next one.

The intended workflow is:

```text
implement
   ↓
execute in MATLAB
   ↓
inspect results
   ↓
validate methodology
   ↓
commit stable version
   ↓
next phase
```

Important algorithmic parameters should eventually be centralized in a configuration file instead of being scattered as hard-coded values throughout the source code.

---

## Experimental Strategy

The project will follow a progressive experimental approach.

A simple baseline will be implemented first:

```text
MRI
↓
Brain Mask
↓
Thresholding
↓
Prediction
```

Then individual processing stages may be added:

```text
MRI
↓
Preprocessing
↓
Brain Mask
↓
Thresholding
↓
Morphology
↓
Connected Components
↓
Prediction
```

Each additional stage must be evaluated separately to determine whether it actually improves the segmentation.

This approach will make it possible to understand the contribution of each component instead of relying on an unnecessarily complex pipeline.

---

## Ground Truth Policy

A strict separation is maintained between segmentation and evaluation.

Correct workflow:

```text
MRI
 │
 ▼
Segmentation Algorithm
 │
 ▼
Predicted Mask
```

Only after the prediction has been produced:

```text
Predicted Mask
      │
      ▼
Comparison
      ▲
      │
Ground Truth
```

The ground truth must therefore never influence the generation of the predicted lesion mask.

---

## Open Questions

The following points must be resolved before the corresponding project phases.

### Development / test data split

Parameters must not be optimized using the final test data, but the split between development and test data has not been defined yet.

BrainWeb provides a single multiple-sclerosis anatomical phantom, available with different lesion severities (mild, moderate, severe) and different noise and RF-inhomogeneity levels.

The split will therefore be defined along these acquisition conditions rather than across independent subjects.

It must be decided and documented when the MRI volumes are selected, and at the latest before any threshold or parameter tuning.

### BrainWeb file format

BrainWeb volumes can be downloaded in MINC format or as raw byte/short data.

MATLAB does not provide a native MINC reader, so the raw format is likely the simplest to load.

The available formats, volume dimensions, data type and byte order must be verified when studying the dataset, before implementing the data loader.

---

## Current Status

Project initialization.

Completed:

- GitHub repository creation;
- local development environment setup;
- MATLAB R2026b verification;
- Image Processing Toolbox installation and verification;
- initial repository directory structure;
- `.gitignore` configuration.

Next steps:

1. finalize project documentation;
2. configure the initial MATLAB project files;
3. study the BrainWeb dataset structure;
4. select and download the required MRI volumes;
5. implement the BrainWeb data loader;
6. validate MRI and ground-truth visualization;
7. begin exploratory intensity analysis.

---

## Academic Context

University Image Processing project.

The aim is not only to obtain a final segmentation result, but also to study and justify the behavior of the individual Image Processing techniques used throughout the pipeline.
