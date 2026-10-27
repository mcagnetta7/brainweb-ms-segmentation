# Project Specification

## BrainWeb Multiple Sclerosis Lesion Segmentation

## 1. Project Objective

The objective of this project is to design and implement an automatic MATLAB pipeline for the segmentation of multiple sclerosis lesions in simulated BrainWeb MRI volumes using classical Image Processing techniques.

The algorithm must produce a binary three-dimensional lesion mask:

$$
M_{pred}(x,y,z)
$$

where:

- `1` indicates a voxel classified as lesion;
- `0` indicates a voxel classified as non-lesion.

The predicted mask will be compared with the corresponding BrainWeb lesion ground truth:

$$
M_{GT}(x,y,z)
$$

to quantitatively evaluate segmentation performance.

The project is an Image Processing project and is not intended to use Machine Learning or Deep Learning approaches.

---

## 2. Dataset

The project uses MRI data from the BrainWeb Simulated Brain Database.

BrainWeb provides simulated MRI volumes and anatomical information that can be used to evaluate image-processing and segmentation algorithms.

The exact files to be used will be determined after inspecting the available multiple-sclerosis BrainWeb data.

The official BrainWeb dataset characteristics are documented in `docs/BRAINWEB_DATASET_NOTES.md`.

Primary MS phantom (decided in Phase 18):

```text
"moderate" MS lesions
BrainWeb internal name: msles2
```

It is the phantom used by the pre-computed BrainWeb MS database, so it gives access to the official pre-generated MRI configurations without depending on the custom simulation service.

The "mild" and "severe" MS phantoms are not excluded; they remain possible later extensions once the core pipeline is stable.

This choice does not determine the MRI modality, ground-truth representation, noise level, intensity non-uniformity level, slice thickness, download format or development/test split.

Possible MRI modalities include:

- T1-weighted MRI;
- T2-weighted MRI;
- Proton Density (PD) MRI.

At this stage, no modality or modality combination is assumed to be optimal.

The modalities must first be analyzed separately before deciding whether a multimodal approach is useful.

---

## 3. Ground Truth

The BrainWeb lesion ground truth will be used exclusively for:

- quantitative evaluation;
- visual comparison;
- error analysis;
- validation of spatial alignment.

The ground truth MUST NOT be used as an input to the segmentation algorithm.

The segmentation must follow this direction:

```text
MRI
 ↓
Segmentation Algorithm
 ↓
Predicted Mask
```

Only after the predicted mask has been generated:

```text
Predicted Mask ──┐
                 ├── Evaluation
Ground Truth ────┘
```

It is therefore forbidden to use ground-truth information to:

- directly locate lesions;
- determine lesion pixels during prediction;
- create lesion seeds;
- generate the brain mask;
- select thresholds for final test cases;
- remove false positives from final test cases;
- modify segmentation results manually.

The exact BrainWeb ground-truth representation must be inspected before implementation.

Possible representations may include a binary/discrete lesion mask or a fuzzy lesion membership map.

If a fuzzy representation is used, the rule used to convert it into the evaluation mask must be explicitly defined and kept fixed.

---

## 4. Main Methodological Constraints

The project must respect the following rules.

### 4.1 Classical Image Processing only

Allowed approaches must belong to classical Image Processing.

Machine Learning and Deep Learning are excluded.

Examples of excluded approaches include:

- neural networks;
- CNNs;
- U-Net;
- transformers;
- random forests;
- SVM-based lesion classifiers;
- learned segmentation models.

---

### 4.2 Automatic final pipeline

The final segmentation pipeline must operate automatically.

Manual interaction may be used during exploratory analysis, but it must not be required by the final algorithm.

The final pipeline must not require:

- manual lesion selection;
- manual ROI drawing;
- manual clicking of lesion seeds;
- manual correction of the predicted mask.

---

### 4.3 Course-compatible techniques

The segmentation pipeline should primarily use techniques covered during the Image Processing course.

The definitive list of course-compatible techniques is maintained separately in:

```text
ALLOWED_TECHNIQUES.md
```

A technique should not be added only to make the pipeline more complex.

Every processing stage must solve a specific observed problem.

---

### 4.4 Reproducibility

The same input data and configuration must produce the same segmentation result.

Important algorithm parameters must not be distributed as unexplained hard-coded constants across multiple MATLAB files.

They should eventually be centralized in the project configuration.

---

## 5. Planned Pipeline

The reference pipeline is:

```text
BrainWeb MRI
      │
      ▼
Data Loading
      │
      ▼
Data Validation
      │
      ▼
Exploratory Intensity Analysis
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
Connected Component Analysis
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
2D and 3D Visualization
```

This represents the target architecture, not a requirement to use every possible processing technique.

---

## 6. Data Loading and Validation

Before implementing segmentation, the project must determine the actual characteristics of the downloaded BrainWeb files.

The following information must be verified directly from the dataset:

- file format;
- volume dimensions;
- MATLAB datatype;
- intensity range;
- MRI modality;
- spatial orientation;
- voxel spacing;
- alignment between MRI modalities;
- alignment between MRI and lesion ground truth.

No dimensions, spacing values or file characteristics should be assumed before inspecting the actual downloaded data.

Original downloaded files must remain unchanged inside:

```text
data/raw/
```

Converted or derived files, if needed, must be stored inside:

```text
data/processed/
```

---

## 7. Exploratory Analysis

Before selecting the final segmentation method, the MRI data must be analyzed.

The analysis should include, where appropriate:

- minimum and maximum intensity;
- mean and standard deviation;
- image histograms;
- visualization of representative slices;
- comparison between available MRI modalities;
- inspection of lesion appearance relative to surrounding tissue.

The objective is to understand the data before defining thresholds or modality-combination rules.

---

## 8. Preprocessing

The first segmentation experiments must include a baseline with minimal preprocessing.

Filtering must not be introduced automatically.

Possible preprocessing techniques include:

- intensity conversion;
- intensity normalization;
- Gaussian filtering;
- mean filtering;
- median filtering.

A filter should be included in the final pipeline only if experimental evidence shows that it improves the segmentation or solves a specific noise-related problem.

Particular attention must be paid to preserving small lesion structures.

Current development choice (Phase 47): no filter. Gaussian σ = 0.5, 3 × 3, `replicate` is the validated candidate for the first "baseline + preprocessing" experiment. Median and mean 3 × 3 were rejected (EXP-002, EXP-003). See `docs/BRAINWEB_DATASET_NOTES.md`, Sections 13.22–13.25.

---

## 9. Brain Mask

A brain mask will be used to restrict lesion analysis to relevant anatomical regions and reduce background-related false detections.

The brain mask should be generated from the MRI data using Image Processing operations.

BrainWeb anatomical labels (white matter, grey matter, CSF, skull, scalp and the other discrete classes) must not be used in the core pipeline to generate, define, threshold, tune, clean, validate or correct the brain mask. The core mask is generated, tuned and validated from MRI data only (decided in Phase 48; see Section 27.1). Any anatomical-label audit would have to be a separate, explicit, post-hoc experiment with no influence on the core mask.

The brain-mask generation procedure must remain independent from the lesion ground truth.

Possible operations may include:

- thresholding;
- connected components;
- erosion;
- dilation;
- opening;
- closing;
- hole filling or related morphological operations, when justified.

The resulting brain mask must be visually validated by overlaying its boundary on the MRI.

**Current brain-mask method (Phases 50–51, development data only):** EXP-021, visually validated in Phase 51 with PASS WITH DOCUMENTED LIMITATIONS (`docs/BRAINWEB_DATASET_NOTES.md`, Sections 13.28–13.29).

```text
T1 (brain-mask source only; T2 remains the provisional lesion modality)
-> double -> /4095 -> no filter -> global Otsu on the whole volume (EXP-010)
-> 3D erosion, strel('sphere', 3)
-> 3D connected components (26-connectivity) -> largest component
-> 3D dilation, strel('sphere', 3), AND the raw Otsu foreground
-> hole filling slice by slice (2D)
```

- EXP-021 uses a **volumetric extension** of course-supported operations (erosion, dilation, connected components, largest region, hole filling), following the course skull-removal recipe. The volumetric extension itself (spherical structuring element, 26-connectivity) is **not** covered by the course PDF; it was adopted as a documented project decision after the 2D experiments EXP-010 to EXP-020.
- It is a **brain-tissue support** mask, not an intracranial-cavity mask. Documented limitations: partial loss of thin superior cortex near the vertex, exclusion of surface-open CSF, and a narrow spinal-cord continuation.
- The validation so far covers the development data `pn0`/`pn3` only. It is **not** a final held-out validation; the radius is frozen and must not be retuned on test data.

**Operational application (Phase 52):**

```text
T1 -> EXP-021 brain mask (brainMask)
T2 (lesion modality) + brainMask -> brain-only lesion-analysis domain
```

- Every later lesion-analysis statistic and segmentation step operates **only on voxels where `brainMask == true`**. Each development condition uses its own mask (`pn0` → `pn0`, `pn3` → `pn3`).
- Brain-only intensity statistics are computed from `T2(brainMask)`. The **zero-valued voxels outside a stored masked volume** (`maskedT2`) are artificial and are **never** part of intensity statistics or threshold estimation.
- The mask restricts space only; it does not classify voxels. The ventricles lie inside it (EXP-021 fills enclosed holes), so brain-only T2 values also contain ventricular CSF.

---

## 10. Lesion Candidate Detection

Lesion candidate detection must initially be based on intensity information contained in the MRI.

No fixed relationship between lesion intensity and a specific MRI modality should be assumed before inspecting the data.

The first experiments should evaluate individual modalities independently.

Only after these experiments may a multimodal strategy be introduced.

### 10.1 Baseline lesion segmentation (defined in Phase 53)

```text
Raw T2 -> double -> /4095 (fixed) -> NO FILTER
       -> EXP-021 brainMask (spatial support, Phase 52)
       -> single global upper-intensity threshold T
       -> lesionCandidateMask
```

$$
\text{lesionCandidateMask}(x) = \text{brainMask}(x) \land \big(\text{T2}_{\text{norm}}(x) > T\big)
$$

- **Modality:** T2, the provisional lesion modality (Phase 41). T1 is used only for the brain mask.
- **Representation:** normalized T2 (raw/4095), in the domain [0, 1]. A raw-value equivalent of T is exactly 4095·T. `pn0` and `pn3` are not normalized separately and not histogram-matched.
- **Comparator:** strict `>`. A voxel equal to T is not a candidate.
- **One threshold** for the whole 3D volume: no per-slice, z-dependent, local, adaptive or position-dependent threshold.
- **Output:** a logical 181 × 217 × 181 `lesionCandidateMask`, always false outside `brainMask`. It is a **candidate** mask, not the final lesion mask.
- **Not part of the baseline:** no filtering, no morphology, no connected-component filtering, no region growing, no multimodal fusion, and no manual correction.
- **T is intentionally unresolved at Phase 53.** Both its value and its estimation method are left to Phases 54–57 (manual global, iterative, Otsu, comparison). Any threshold rule must follow the Phase-37 protocol (one shared rule for `pn0` and `pn3`, never silently condition-specific).
- **Known confound:** bright ventricular CSF lies inside `brainMask` (Section 9), so high T2 intensity is **not** equated with lesion. The baseline detects high-intensity candidates and is expected to include CSF false positives. These are not removed at the baseline stage.
- Implementation: `src/segmentation/thresholdLesionCandidates.m` applies a **provided** T only (no estimation, no file access, no GT).
- Phase 54 evaluated this baseline with one manually defined threshold (EXP-022, T_raw = 3400), only as an **experimental reference**. That value is not the selected lesion threshold; the threshold method is still open (Phases 55–57).
- Phase 55 evaluated the course iterative threshold (EXP-023: T0 = mean of `T2(brainMask)`, partition `>=`/`<`, ε = 0.5/4095, same rule per condition) as a **candidate method**. Its data-derived thresholds are not project parameters, and no method has been selected yet (Phase 57).
- Phase 56 evaluated MATLAB `graythresh` (Otsu) on `T2(brainMask)` per condition (EXP-024) as a further **candidate method**. Its thresholds are data-derived and not project parameters.
- **Phase 57 (EXP-025) selected the INITIAL thresholding method: Otsu** (`graythresh` on `T2(brainMask)`, estimated per volume).
  - It had the highest pre-defined Phase-37 DevelopmentScore, the full-volume 3D Dice averaged over `pn0` and `pn3` (0.028849, against 0.027325 for manual and 0.018026 for iterative), with no tie tolerance.
  - This is the current **development baseline**, not the final segmentation pipeline. All Dice values are below 0.04, dominated by bright non-lesion structures.
  - The manual and iterative methods remain documented alternatives.
- **Phase 58 (EXP-026) replaced it as the CURRENT selected thresholding method: multi-level Otsu** (`multithresh(T2(brainMask), 2)` per volume, `imquantize` into 3 classes, candidate = `brainMask & (class == 3)`, equivalent to `T2 > upper threshold`).
  - N = 2 and the Class-3-only candidate were fixed before any result; no other N or class combination was tested.
  - DevelopmentScore 0.041545 against 0.028849 for EXP-024 (no tie tolerance). Its thresholds are data-derived and not project parameters.
  - Still a **development baseline**, not the final pipeline: Dice is about 0.04, the candidates are still about 40 times the GT volume and dominated by bright CSF-compatible structures, and about 14–16 % of the GT voxels fall in Class 2.
- **Phase 59 (EXP-027) evaluated variable / local thresholding and REJECTED it; EXP-026 is retained.**
  - The method was the course rule T = a·m + b·s, 2D slice-wise, with masked local mean and population standard deviation.
  - Of the pre-registered grid (a = 1, window {9, 21, 41} × b {0.5, 1.0, 1.5}), the best configuration was W21_B15 with DevelopmentScore 0.036103, below 0.041545.
  - It suppresses uniform bright CSF but loses periventricular lesion voxels next to the ventricles.
- **Phase 60: current development candidate-generation pipeline** (`src/segmentation/generateLesionCandidateMask.m`, parameters from `cfg.segmentation`):

  ```text
  T2 -> double -> /4095 -> EXP-021 brainMask
  -> levels = multithresh(T2norm(brainMask), 2) (per volume) -> imquantize -> Class 3
  -> candidateMask = brainMask AND (class == 3)
  ```

  - `candidateMask` is an **intermediate lesion-candidate volume**, not the final lesion segmentation. It knowingly contains bright non-lesion structures; no morphology or other post-processing rule is defined yet.
  - Canonical development outputs: `data/processed/phase60_t2_{pn0,pn3}_candidate_mask.mat`, identical voxel for voxel to the EXP-026 predictions.
- **Phase 61 diagnostic conclusion (EXP-028, no algorithm change):**
  - The dominant candidate error is large fluid-like regions in the lesion intensity class, fused with periventricular lesions; simple morphology alone is unlikely to solve it.
  - Isolated and thin false positives (erosion/opening) and lesion-border misses (dilation) motivate the morphology experiments of Phases 62–65. No operation or structuring element is selected yet.
- **Phase 62 (EXP-029):** one-step erosion and dilation were evaluated as a 2D probe with square 3×3. Both worsen the baseline DevelopmentScore, and the final morphology remains unselected. Square 3×3 is not a selected structuring element.
- **Phase 63 (EXP-030):** standard opening was evaluated with the same provisional square-3 structuring element as Phase 62. It improves the DevelopmentScore to 0.056845 (+0.0153) but loses small lesions. Final morphology and structuring element remain unselected.
- **Phase 64 (EXP-031):** standard closing was evaluated after the Phase-63 opening candidate (brain mask applied after the complete closing). It slightly lowers the score (0.056181), so the opening remains the best observed candidate. Final morphology remains unselected.
- **Phase 65 (EXP-032): selected development structuring element for standard opening = `strel('square', 3)`** (3×3 support, 9 elements, 2D slice-wise, one opening, shared by `pn0` and `pn3`).
  - It was chosen by DevelopmentScore (0.056845) among square3, diamond1, square5 and diamond2.
  - It is not globally frozen. The candidate generation (EXP-026) is unchanged, and no component rules are defined. The formal before/after comparison is Phase 66.
- **Phase 66 (EXP-033): standard 2D opening with `strel('square', 3)` is RETAINED FOR SUBSEQUENT DEVELOPMENT.**
  - Evidence: the development-set before/after comparison gives a DevelopmentScore of 0.041545 → 0.056845, better in both `pn0` and `pn3`. This is not independent validation.
  - Current development pipeline: EXP-026 `candidateMask` → one 2D opening with square 3×3. The overall pipeline is not frozen.
- **Phase 67 (EXP-034): object-analysis stage.** `bwconncomp` with 8-connectivity is applied to every axial slice of the retained Phase-65 morphology output (2D slice-wise components). No component filtering or property threshold is defined.
- **Phase 68 (EXP-035):** the current 2D candidate components are characterized with the course-compatible `regionprops` properties Area, Centroid and BoundingBox. These properties are descriptive only; no filtering rule is defined.
- **Phase 69 (EXP-036):** a conservative Area-9 component filter (remove whole 2D components with Area == 9) is provisionally retained, pending the Phase-70 small-lesion protection analysis. DevelopmentScore 0.056845 → 0.058101. It is not final.
- **Phase 70 (EXP-037):** the Area-9 component filter improved development Dice but was **rejected**, because it caused the complete loss of previously represented 2D GT lesion components (3 in `pn0`, 4 in `pn3`). The retained development pipeline therefore remains **unfiltered after the Phase-65 opening**. No alternative threshold was introduced.
- **Phase 71 (EXP-038): predicted mask representation.**
  - The current development prediction is represented as `M_pred(x,y,z)`, a logical binary 181×217×181 volume (`data/processed/phase71_t2_{pn0,pn3}_predicted_volume.mat`).
  - Processing up to `M_pred`: EXP-026 candidate generation, then the Phase-65 standard 2D opening with square 3×3, with no component filtering. `M_pred` is assembled from the 181 axial slices and is exactly identical to the Phase-65 masks.
  - The pipeline is not frozen.
- **Phase 72 (EXP-039):** the current development pipeline represents `M_pred` as 26-connected volumetric candidate components, for structural analysis and future lesion-level analysis (`bwconncomp(M_pred, 26)`, no voxel changed). This is a 3D extension of course-supported connected-component concepts, and 26-connectivity is not claimed to be taught in the course. The components are candidates, not confirmed lesions, and no component filtering is defined.
- **Phase 78 (EXP-040):** in the individual-modality benchmark, T2 Class 3 is the best single-modality candidate (PD Class 3 0.016424, T1 Class 3 0.004280). The development pipeline is unchanged (§15).

---

## 11. Thresholding

Thresholding represents the initial segmentation approach.

Candidate methods include:

- global thresholding;
- iterative thresholding;
- Otsu thresholding;
- multiple thresholding;
- variable/local thresholding.

The simplest suitable method should be tested first.

More complex thresholding methods should be introduced only if a simpler global method presents identifiable limitations.

Thresholds for the final test data must not be manually adjusted by observing their ground truth.

---

## 12. Morphological Processing

Morphological operations may be used to improve the binary lesion candidate mask.

Possible operations include:

- erosion;
- dilation;
- opening;
- closing;
- morphological reconstruction.

Morphology must be introduced only after inspecting the errors of the baseline segmentation.

The structuring element:

- must have a documented shape;
- must have a documented size;
- must have a clear purpose.

Aggressive morphological processing that removes small real lesions should be avoided.

---

## 13. Connected Components

Connected-component analysis will be used to identify individual candidate regions.

The initial implementation may operate slice by slice because this makes intermediate results easier to inspect and debug.

The resulting 2D masks will then be assembled into a complete 3D predicted volume.

A subsequent 3D connected-component analysis may be introduced if useful for lesion-level analysis.

MATLAB functionality may include:

```matlab
bwconncomp
regionprops
```

Candidate properties may include:

- area;
- centroid;
- bounding box;
- intensity statistics;
- spatial properties.

Any rule used to remove candidate components must be justified experimentally.

Small components must not automatically be considered noise because real multiple-sclerosis lesions may also be small.

---

## 14. Region Growing

Region growing is an optional refinement stage.

It should not be part of the initial baseline.

It may be introduced if experiments show that thresholding correctly detects high-confidence lesion cores but fails to recover their complete spatial extent.

If used:

- seeds must be generated automatically;
- seeds must not come from the ground truth;
- the similarity predicate must be explicitly defined;
- stopping criteria must be documented.

Its contribution must be evaluated against the simpler segmentation method.

If it does not provide a useful improvement, it should be excluded from the final pipeline.

Development status (Phase 73): Phase 73 evaluated whether region growing is justified for the current pipeline. Although incomplete lesion extent is present, the current candidate mask does not provide a sufficiently specific high-confidence lesion-core seed set, because substantial bright false-positive and ambiguous structures remain (FP > TP; 3D candidate objects larger than the total GT lesion volume). Region growing is therefore **not activated**, and Phases 74–77 are skipped. It remains allowed in principle.

---

## 15. Multimodal Processing

A multimodal strategy is optional.

T1, T2 and PD images must initially be evaluated independently.

A multimodal method should be considered only after understanding the behavior of the individual modalities.

Any fusion rule must be:

- explicit;
- deterministic;
- reproducible;
- derived from observed image characteristics;
- independent of final-test ground truth.

Arbitrary logical combinations of modalities should be avoided unless experimentally justified.

**Development status (Phase 78, EXP-040):** T1, T2 and PD were evaluated independently on development data (`pn0` + `pn3`).
- Each used the same architecture: EXP-021 brain mask, `multithresh` with N = 2, Class 1/2/3 each alone, and a 2D square-3×3 opening.
- **Best individual modality: T2, Class 3** (DevelopmentScore 0.056845, identical to the Phase-71 `M_pred`).
- The other modalities, with Class 3 also best: PD 0.016424 (strongly condition-dependent, Dice 0.007287 / 0.025561) and T1 0.004280.
- The lesion modality stays T2. No fusion has been performed. The question of whether PD or T1 can add information to T2 is left to the multimodal phases.

**Phase-79 decision (modality combination):** based on the Phase-78 individual-modality development benchmark, T2 is kept as the primary modality and PD is selected as the secondary modality for the first controlled multimodal experiment.
- **Why PD:** PD is not selected because it performs well alone; it has poor specificity and a very large FP burden. It is selected because, among the available secondary modalities, it gives the strongest evidence of potentially complementary lesion information: rank 2, and more TP than T1 in both conditions.
- **T1:** not selected for the first pair, but not discarded.
- **Fusion rule:** intentionally left undefined until Phase 80. No multimodal prediction exists yet, and whether T2 + PD improves on T2 alone is a Phase-81 question.

**Phase-80 fusion rule (EXP-041):** Phase 80 defines the first controlled multimodal fusion as a binary decision-level intersection, `M_multimodal = M_T2 AND M_PD`, applied to the frozen Phase-78 Class-3 masks with the same rule for every condition.
- **Roles:** T2 is kept as the anchor segmentation, and PD is used only as a confirmation gate.
- **Consequence:** the fused mask is a subset of T2. It cannot recover voxels missed by T2.
- **Pre-registration:** the rule was selected before any multimodal GT evaluation. OR was rejected a priori, and no alternative rule was tested.
- **Structural effect:** T2 retained 99.96 % (`pn0`) / 92.06 % (`pn3`).
- **No claim of improved performance** is made until Phase 81. The canonical prediction is still the Phase-71 T2 `M_pred`.

**Phase-81 decision (EXP-042):** Phase 81 compared the predefined T2+PD intersection quantitatively against the retained T2 baseline, on full-volume Dice with the pre-registered DevelopmentScore rule.
- **Result:** the fusion did not improve the DevelopmentScore (0.056472 vs 0.056845; Dice `pn0` +0.000022, `pn3` −0.000769), so it was **rejected**.
- **Why:** it removed mostly FP (`pn3`: 5,149 FP, 177 TP), but not selectively enough to raise Dice.
- **Retained pipeline:** the simpler T2-only pipeline, with the Phase-71 `M_pred` as canonical development prediction. EXP-041/042 are kept as negative evidence.
- **Not done:** no alternative fusion rule was tested and nothing was retuned.

---

## 16. Predicted Mask

The final segmentation output must be a binary volume:

```text
M_pred
```

with exactly the same spatial dimensions as the evaluation ground truth:

```text
M_GT
```

Before evaluation, the implementation must verify that:

```matlab
isequal(size(M_pred), size(M_GT))
```

and that both masks have a valid binary representation.

---

## 17. Evaluation

The primary evaluation will compare the complete predicted 3D lesion volume with the corresponding ground truth.

**Implementation status (Phase 82, EXP-043):** Phase 82 implemented the formal voxel-wise confusion-count foundation (`src/evaluation/computeVoxelConfusion.m`).
- For binary `M_pred` and `M_GT`, TP, FP, FN and TN are counted over the complete 3D volume.
- The confusion-matrix convention is rows = ground truth and columns = prediction, giving `[TN FP; FN TP]`.
- Derived metrics remain assigned to subsequent roadmap phases (Dice 83, IoU 84, Precision 85, Recall 86, Specificity 87).

**Implementation status (Phase 83, EXP-044):** Phase 83 implemented the Dice coefficient as a reusable metric derived from the formal Phase-82 TP/FP/FN counts (`src/evaluation/computeDiceFromConfusion.m`): `Dice = 2TP / (2TP + FP + FN)`.
- The metric is evaluated over the complete 3D volume.
- For the degenerate case TP = FP = FN = 0, the implementation defines Dice = 1 as an explicit project convention for identical empty positive sets.
- Development values for the retained T2 `M_pred`: `pn0` 0.0566473988439306, `pn3` 0.0570432712743348.
- IoU, Precision, Recall and Specificity remain assigned to subsequent roadmap phases.

**Implementation status (Phase 84, EXP-045):** Phase 84 implemented Intersection over Union (IoU), equivalently the Jaccard index, as a reusable metric derived from the formal voxel confusion counts (`src/evaluation/computeIoUFromConfusion.m`): `IoU = TP / (TP + FP + FN)`.
- The metric is evaluated over the complete 3D volume.
- For the degenerate case TP = FP = FN = 0, the implementation defines IoU = 1 as an explicit project convention for identical empty positive sets.
- The production implementation derives IoU directly from TP/FP/FN. Its known relationship with Dice is used only as a regression validation.
- Development values: `pn0` 0.0291493158834027, `pn3` 0.0293590024064756.
- Precision, Recall and Specificity remain assigned to subsequent phases.

**Implementation status (Phase 85, EXP-046):** Phase 85 implemented Precision as a reusable metric derived from the formal voxel confusion counts (`src/evaluation/computePrecisionFromConfusion.m`): `Precision = TP / (TP + FP)`.
- The metric is evaluated over the complete 3D prediction.
- For TP = FP = 0, the implementation defines Precision = 1 as an explicit project convention for an empty predicted-positive set. This special-case value must not be interpreted as evidence of successful lesion detection.
- Development values: `pn0` 0.0297271367702249, `pn3` 0.0300152088986968.
- Recall/Sensitivity and Specificity remain assigned to subsequent phases.

**Implementation status (Phase 86, EXP-047):** Phase 86 implemented Recall, equivalently Sensitivity, as a reusable metric derived from the formal voxel confusion counts (`src/evaluation/computeRecallFromConfusion.m`): `Recall = TP / (TP + FN)`.
- The metric measures the fraction of ground-truth lesion voxels recovered by the prediction over the complete 3D volume. It is voxel-wise, not a lesion-wise detection rate.
- For TP = FN = 0, the implementation defines Recall = 1 as an explicit project convention for a GT with no positive lesion voxels. This special-case value must not be interpreted as evidence of good predictions overall.
- Development values: `pn0` 0.5999430523918, `pn3` 0.573177676537585.
- Specificity remains assigned to Phase 87.

**Implementation status (Phase 87, EXP-048):** Phase 87 implemented Specificity as a reusable metric derived from the formal voxel confusion counts (`src/evaluation/computeSpecificityFromConfusion.m`): `Specificity = TN / (TN + FP)`.
- The metric measures the fraction of ground-truth non-lesion voxels correctly classified as non-lesion over the complete 3D volume.
- For TN = FP = 0, the implementation defines Specificity = 1 as an explicit project convention for a GT containing no negative-class voxels.
- Because non-lesion voxels greatly outnumber lesion voxels, Specificity must not be interpreted in isolation. A high Specificity may coexist with a very low Precision and poor overlap metrics.
- Development values: `pn0` 0.990321611399419, `pn3` 0.990844858826634, alongside Precision ≈ 0.03 and Dice ≈ 0.057.

**Implementation status (Phase 88, EXP-049):** Phase 88 formalized the physical ground-truth lesion volume as `V_GT = N_GT × V_voxel` (`src/evaluation/computeBinaryMaskVolume.m`).
- N_GT is the number of label-10 lesion voxels, and V_voxel is derived from the validated voxel spacing.
- For the selected BrainWeb msles2 1-mm isotropic dataset, the physical voxel volume is 1 mm³, giving V_GT = 3,512 voxels × 1 mm³ = 3,512 mm³ (3.512 mL).
- The GT volume is a property of the shared crisp lesion anatomy and is not condition-specific between `pn0` and `pn3`.
- Predicted lesion volume and volume error remain assigned to Phases 89 and 90.

**Implementation status (Phase 89, EXP-050):** Phase 89 formalized the physical predicted lesion volume as `V_pred = N_pred × V_voxel`, with the same `computeBinaryMaskVolume`.
- N_pred is the number of positive voxels in the retained binary prediction, and V_voxel is derived from the validated voxel spacing.
- The calculation is performed separately for `pn0` and `pn3` because their retained predicted masks differ: 70,878 mm³ and 67,066 mm³ respectively.
- The predicted volume represents all predicted-positive voxels and therefore contains both true-positive and false-positive contributions.
- Formal comparison with V_GT and percentage volume error remain assigned to Phase 90.

**Implementation status (Phase 90, EXP-051):** Phase 90 implemented the formal lesion-volume error defined in this specification (`src/evaluation/computeVolumeErrorPercent.m`): `VolumeError = |V_pred − V_GT| / V_GT × 100`.
- V_GT is read from the formal Phase-88 output and V_pred from the formal Phase-89 output.
- The calculation uses physical volumes expressed consistently in mm³.
- The formal metric is absolute; overestimation or underestimation is reported separately as interpretation.
- Development values: `pn0` 1918.16628701595 %, `pn3` 1809.62414578588 %, both overestimation.
- Volume error quantifies disagreement in total segmented physical volume and does not replace spatial-overlap metrics such as Dice or IoU.

**Implementation status (Phase 91, EXP-052):** Phase 91 consolidated the formal evaluation metrics computed in Phases 82–90 into the primary complete-volume 3D development result (`results/metrics/exp052_complete_3d_metrics.csv`).
- The consolidated table contains, for `pn0` and `pn3`: confusion counts, Dice, IoU/Jaccard, Precision, Recall/Sensitivity, Specificity, GT lesion volume, predicted lesion volume and percentage volume error.
- These results refer to the complete 181×217×181 volume. No metric is obtained by averaging arbitrary per-slice values.
- Slice-wise evaluation remains diagnostic and is assigned to Phase 92.

**Implementation status (Phase 92, EXP-053):** Phase 92 implemented slice-wise evaluation as a diagnostic analysis only (`src/evaluation/computeSliceWiseMetrics.m`).
- For every axial slice, voxel-wise confusion counts and the already formalized Dice, IoU, Precision, Recall and Specificity metrics are computed with the same definitions as the complete-volume evaluation.
- The Phase-91 complete-volume 3D results remain the primary quantitative evaluation. The summed slice counts reproduce them exactly, and per-slice metrics are not averaged to replace the whole-volume metrics.
- Explicit denominator-validity flags are retained, because project conventions for empty positive sets may otherwise produce values of 1 on diagnostically empty slices.
- Slice-wise results are used only to identify where FP and FN are concentrated, not to define location-specific segmentation rules.

Planned metrics include:

### Dice coefficient

$$
Dice =
\frac{2TP}
{2TP + FP + FN}
$$

### Intersection over Union

$$
IoU =
\frac{TP}
{TP + FP + FN}
$$

### Precision

$$
Precision =
\frac{TP}
{TP + FP}
$$

### Recall / Sensitivity

$$
Recall =
\frac{TP}
{TP + FN}
$$

### Specificity

$$
Specificity =
\frac{TN}
{TN + FP}
$$

### Lesion volume error

$$
VolumeError =
\frac{|V_{pred}-V_{GT}|}
{V_{GT}}
\times 100
$$

The primary results should be computed over the complete 3D volume.

Slice-wise metrics may additionally be used for diagnostic purposes.

Because non-lesion voxels are expected to greatly outnumber lesion voxels, specificity must not be interpreted in isolation.

---

## 18. Lesion-Level Evaluation

An optional lesion-level evaluation may be implemented using connected components.

The objective is to distinguish between:

- correctly detected lesions;
- missed lesions;
- false lesion detections.

Before performing final experiments, a fixed rule must be established to determine when a predicted component matches a ground-truth component.

The matching rule has not yet been selected.

**Matching rule fixed (Phase 93, EXP-054, pre-registered before any lesion-wise result):**
- **Objects:** lesion objects are 26-connected 3D components, the same volumetric object definition as Phase 72.
- **Matching:** a GT lesion component and a predicted component are matched if they share at least one voxel.
  - Matching is many-to-many; no one-to-one assignment is forced.
  - No minimum overlap fraction, centroid-distance criterion or size threshold is used.
- **Definitions:**
  - A GT lesion is **detected** if it has at least one matched predicted component, and **missed** otherwise.
  - A predicted component is a **false lesion detection** if it overlaps no GT lesion component.
- **Limitation:** the rule is intentionally permissive. A one-voxel overlap counts as lesion detection, so lesion-level detection must be interpreted together with the voxel-wise overlap metrics.
- This resolves the open matching-rule question above. The previous sentence is kept as history.

Development result (Phase-71 T2 `M_pred`): the GT has 59 lesion components.

| | Detected GT lesions | Missed GT lesions | Predicted components | False predicted components |
|---|---:|---:|---:|---:|
| `pn0` | 15 | 44 | 335 | 331 |
| `pn3` | 14 | 45 | 291 | 287 |

**Implementation status (Phase 94, EXP-055):** Phase 94 stratifies the 26-connected GT lesion components by size for diagnostic analysis.
- **Size variable:** the GT component voxel count.
- **Threshold:** the median GT lesion size (7 voxels), calculated from the GT size distribution before the Phase-93 detection outcomes are used.
- **Classes:** GT lesions with size ≤ median are SMALL (31) and those above the median are LARGE (28). This split is dataset-relative and is not a clinical lesion-size definition.
- **Result:** SMALL lesions detected 3 / 31 (`pn0`) and 2 / 31 (`pn3`); LARGE 12 / 28 in both. Lesion size explains the lesion-wise failure only partly.
- The size threshold is evaluation-only and must never be used as a segmentation or component-filtering threshold. The Phase-93 matching rule is unchanged.

---

## 19. Development and Test Separation

Parameter selection and final evaluation must be separated.

Dataset configurations used to:

- select thresholds;
- choose filtering parameters;
- choose structuring-element sizes;
- define candidate-filtering rules;
- select modality combinations;

belong to the development process.

After parameters have been selected, they must be frozen.

The final evaluation must then be executed without modifying the parameters based on final-test ground truth.

### 19.1 Development/test protocol (Phase 36)

| Role | Configurations | Use |
|---|---|---|
| **Development** | `msles2`, 1 mm, `rf0`, **`pn0` + `pn3`**, T1/T2/PD, with the crisp GT | exploratory analysis, modality comparison, preprocessing, brain mask, thresholding, morphology, component rules, parameter selection |
| **Held-out test** | `msles2`, 1 mm, `rf0`, **`pn1`, `pn5`, `pn7`, `pn9`**, only the modality or modalities of the final pipeline | final evaluation with frozen parameters |
| **Extensions** (outside the core protocol) | `rf20`/`rf40`; thick slices; `msles1`/`msles3` | optional additional experiments |

The split is defined by simulation configuration:

- **Slices.** A random split of slices (for example 70 % / 30 %) is rejected. The slices belong to one continuous, spatially correlated 3D phantom, so such a split would give a misleading impression of independent test data.
- **Modalities.** T1, T2 and PD are not partitions. They are different representations of the same anatomy, all available in development so that the baseline modality can be chosen later.

**Why `pn0` and `pn3` are development:**

- `pn0` has already been inspected, visualized and overlaid with the GT (Phases 24–35). It cannot be an untouched test set.
- `pn3` provides observed noise during development. This lets the filtering phases decide on real noise (Section 8) instead of on noise-free data only.
- `pn3` is part of the development set but has not been downloaded yet. It will be downloaded in a later phase, when it is first needed.

**Why `rf0` only:** RF/INU is kept at `rf0` in the core protocol to isolate noise as the only perturbation variable. Noise and non-uniformity are not varied at the same time, so it is clear what is being measured. `rf20`/`rf40` remain possible additional robustness experiments.

**Held-out test rules:**

- The held-out configurations are downloaded only after the parameters have been frozen (roadmap Phase 96) and before the final test is run (Phase 97). The freeze must be recorded with a Git commit or tag before the download.
- Held-out images and results must not influence any parameter, rule or design decision. If a held-out configuration is ever used to change the pipeline, it becomes development data and must be reported as such.

**Spatial rule (no lesion-position leakage):** no segmentation rule, ROI, slice range, mask or parameter may be derived from the absolute position of the `msles2` lesions. For example, the following are forbidden:

- "consider only voxels in these coordinates";
- "ignore candidates beyond this region";
- "analyse only slices 70–120 because that is where the lesions are";
- "use this ROI because the GT shows where the lesions are".

Only generic spatial rules independent of the GT are allowed, such as requiring membership in a brain mask obtained automatically from the MRI.

This rule matters because the GT of every noise configuration is the same crisp `msles2` model, already inspected during development.

**Ground truth:** the GT is never an input of the segmentation.

- During development it may be used only as a reference to evaluate candidate methods and parameters. The detailed tuning rule is defined in Phase 37.
- In the final test it is used only after the prediction, to compute the metrics.

**Reporting:**

- Results on `pn0` and `pn3` are development (in-sample) results and are optimistic.
- In any performance-versus-noise table or plot, `pn0` and `pn3` must be explicitly marked as development, and `pn1`, `pn5`, `pn7`, `pn9` as held-out. They must not be presented as six equivalent test points.

**Limitations:**

- The protocol does not provide an independent-subject test set. Development and held-out configurations share the same `msles2` anatomy and the same lesions. The held-out evaluation therefore measures robustness to simulated acquisition noise, not generalization to unseen patients.
- Even with the spatial rule above, the held-out test is not independent with respect to the lesions. For example, a component-size rule chosen on `pn0`/`pn3` (Phase 69) is developed on the same lesion sizes present in the test. The test measures robustness to noise, not generalization to new lesion morphologies.
- `msles1`/`msles3`, obtainable only through custom simulations, would change the lesion load. They would be a stronger additional experiment, but the core project does not depend on them.

### 19.2 Tuning criterion (Phase 37)

This rule is defined before any parameter optimization. It applies to every later choice of method, threshold, filter parameter, morphology parameter, structuring element, component-filtering rule, optional processing block and any future multimodal rule. Phase 37 defines the rule only; the tuning itself happens in later phases, ending with roadmap Phase 95.

**Phase-95 implementation (EXP-056):** development-only tuning on `pn0` + `pn3`, applying this rule unchanged.
- **Grid:** a pre-registered, finite grid of 24 configurations (48 predictions, all generated before the GT was loaded):
  - P: none / Gaussian σ 0.5, 3 × 3, replicate;
  - T: `multithresh` N = 2 (Class 3) / N = 3 (Class 4);
  - M: none / one 2D opening `diamond 1` / one 2D opening `square 3`;
  - G: none / removal of 26-connected 3D components occupying a single axial slice.
- **Selection:** complete-volume 3D Dice; DevelopmentScore = (Dice_pn0 + Dice_pn3)/2; no tolerance.
- **Winner (selected development parameters): `P0_T2_M2_G1`.** It uses no preprocessing, `multithresh` N = 2 with Class 3, one 2D axial square-3 opening, and removes single-slice 3D components.
  - DevelopmentScore 0.058158 (Dice 0.058067 / 0.058248), +0.00131 vs the Phase-71 baseline.
- **Not used:** held-out data, position rules, GT-derived size thresholds and grid extensions.
- **Status:** superseded by EXP-057 below.

**Phase-95 supplementary experiment (EXP-057, final development experiment):** same rule, unchanged.
- **Grid:** 36 pre-registered configurations (72 predictions before the GT):
  - S: brain support S0 = EXP-021; S1 = S0 AND NOT T1-low; S2 = S0 AND per-slice filled T1-high AND NOT T1-low (T1 partition `multithresh(T1(EXP-021), 2)`);
  - T: TA `multithresh(T2(S), 2)` highest class / TB `graythresh(T2(S))`, always re-estimated inside S;
  - M: none / opening `diamond 1` / opening `square 3`;
  - G: none / removal of single-slice 26-connected 3D components.
- **Winner (selected development parameters): `S2_TA_M2_G1`.** DevelopmentScore 0.600034 (Dice 0.661039 / 0.539029) vs 0.058158 for `P0_T2_M2_G1`.
- **Status:** frozen as **v1** (tag `v1-frozen`).

**Protocol amendment A1 and EXP-058 (v2):** one further pre-registered experiment on top of the frozen v1.
- **Grid:** 21 configurations:
  - F: none / Gaussian σ 0.5 / anisotropic diffusion with fixed explicit parameters, on T1, T2 or both;
  - R: none / morphological reconstruction inside S2 / towards S1.
- **Winner = v2 = `F5_R0`** (anisotropic diffusion of T2, no recovery). DevelopmentScore 0.661169 (Dice 0.669340 / 0.653000).
- **Primary for the final test:** v2; **secondary:** v1. This was fixed before any held-out access, and both versions are tested in Phase 97.
- **Status:** frozen as **v2** (tag `v2-frozen`).

**Protocol amendment A2 and EXP-059 (v3):** the final development experiment before the test.
- **Grid:** 12 configurations on top of v2:
  - D: 2D slice-wise / 3D whole-volume anisotropic diffusion of T2;
  - M: no opening / diamond 1 / square 3;
  - G: none / single-slice component removal.
- **Winner = v3 = `D3_M1_G0`.** DevelopmentScore 0.689892 (Dice 0.68538 / 0.69440).
- **Primary for the final test:** v3; v2 and v1 are secondary locked versions. This was fixed before any held-out access.
- **Status:** Phase 95 COMPLETE.

**Phase 96 (final freeze):** v3 = `D3_M1_G0` is frozen as the final primary pipeline. It was selected on development data only, before any held-out access.
- **Frozen parameter set:** `src/segmentation/finalSegmentationConfig.m`. **Entry point:** `src/segmentation/generateFinalPrediction.m` (raw T1 + T2).
- **Pipeline:**
  1. fixed normalization 0..4095 → 0..1;
  2. EXP-021 brain mask from the condition's own T1;
  3. S2 from the unfiltered T1;
  4. whole-volume 3D anisotropic diffusion of T2 (5 iterations, exponential, 26-neighbour, gradient threshold 0.10 × volume range);
  5. TA = `multithresh(T2f(S2), 2)`, highest class;
  6. one 2D axial `diamond 1` opening AND S2;
  7. no component filter, recovery or region growing.
- **Regression:** the entry point reproduces the EXP-059 predictions voxel by voxel (Phase-96 check 39/39). SHA-256 manifest of 26 artifacts. Full record: `docs/PHASE96_FINAL_FREEZE.md`.
- **Held-out:** not yet accessed. Phase 97 evaluates v3 (primary) plus v2 and v1 (secondary locked versions). It measures robustness to unseen simulated noise on the same msles2 phantom, not independent-patient generalization.
- **Unchanged rules:** GT is never a segmentation input; `pn0`/`pn3` are development; `pn1`/`pn5`/`pn7`/`pn9` are held-out; no held-out result may change the frozen pipeline.

**Phase 97 (held-out final test, executed 2026-10-16):** Phase 96 was COMPLETE and frozen before held-out access.
- The primary v3 / `D3_M1_G0` was evaluated unchanged on `pn1` / `pn5` / `pn7` / `pn9` (official BrainWeb, msles2, 1 mm, rf0, T1 + T2).
- **Complete-volume Dice:** 0.692 / 0.715 / 0.408 / 0.409 (mean 0.556). Good robustness at pn1 / pn5; marked degradation at pn7 / pn9, dominated by false-positive over-segmentation.
- **Secondary locked versions** v1 / v2 are reported for comparison only and do not change the primary.
- **Interpretation:** robustness to unseen simulated noise on the same msles2 anatomy and lesion configuration, **not** independent-patient generalization. Details: `EXPERIMENT_LOG.md` (Phase 97 record); notes §13.74.
- **Frozen segmentation parameters:** unchanged.

**Phase 98 (final-result provenance):** the Phase-97 outputs were verified read-only and indexed in `results/metrics/phase98_final_results_inventory.csv`.
- **Authoritative files:**
  - primary final metrics: `phase97_v3_heldout_metrics.csv`;
  - primary predictions: the 4 `phase97_v3_*` masks;
  - the result manifest: `phase97_result_manifest.csv`;
  - the frozen-algorithm provenance: the Phase-96 manifest plus tag `v3-final-frozen`.
- Stored CSV values keep full precision; rounding belongs only to presentation tables.

**Phase 99 (final-method rationale):** a retrospective ablation on development results only (`results/metrics/phase99_ablation_*.csv`). Main contributions:
- S2 support (+0.542), the largest by far;
- T2 anisotropic filtering (+0.061);
- the diamond-1 opening after D3 (+0.130 vs no opening, +0.029 vs square 3);
- small effects for D2 → D3 and G1.

Recovery reduced the score. The frozen parameters are unchanged.

**Phase 101 (lesion-load robustness):** frozen v3 on matched BrainWeb custom simulations of msles1 / msles2 / msles3 (AI, 1 mm, 0 % noise, 0 % INU).
- **Dice:** 0.013 / 0.662 / 0.788.
- At mild load the highest TA class does not necessarily represent a distinct lesion population and includes high-intensity normal tissue, producing marked over-segmentation. This is a structural limitation of "highest class = lesion" as lesion prevalence varies.
- These are simulated lesion burdens on one anatomy, not independent-patient generalization. The parameters are unchanged.

**Post-test extension v4 (amendments A3 / A4):** v4 = v3 with the T2 threshold max(TA2, μref + 5σref). The reference is the image-derived WM-like region S2 ∩ T1-high, not a GT mask. Selected in EXP-060 and frozen with tag `v4-frozen`.
- **Reserved test** (protocol fixed before data generation; custom AI, seed 2):
  - lesion-free phantom: 172 / 30 false-positive voxels (v3: 31,917 / 17,486);
  - msles1 3 %: Dice 0.341 (v3 0.024); msles3 3 %: Dice 0.773 (v3 0.788).
- **Reporting:** v3 is the prospectively tested pipeline; v4 is the final improved pipeline.

**Reproducibility (Phase 103):** the final evaluation suite can be reproduced through one registry-driven experiment runner (`experiments/phase103_experiment_runner.m`). It executes the frozen v3 and v4 pipelines on all 13 registered project cases and exports consolidated metrics.

All reported final evaluation results can be reproduced through this single runner. It reproduces the previously stored predictions voxel by voxel and their confusion counts: 26 / 26 combinations.

**Data:**

- Tuning uses only the development configurations of Section 19.1.
- Final tuning evaluates every candidate on both `pn0` and `pn3`, with otherwise matching conditions: same modality or modalities, 1 mm, `rf0`.
- **One parameter set** is applied unchanged to both. Separate parameter sets for `pn0` and `pn3` are not allowed.

**Primary metric:** the Dice coefficient (Section 17) computed on the **complete 3D predicted lesion volume** against the binary GT (label 10).

**Development score:**

$$
DevelopmentScore = \frac{Dice_{pn0} + Dice_{pn3}}{2}
$$

`pn0` (clean) and `pn3` (realistic non-zero noise) have equal weight. This prevents tuning only for the clean volume, while `pn1`, `pn5`, `pn7`, `pn9` stay held out.

The two values share the same anatomy and lesions. They are NOT independent samples, folds or a cross-validation. The score is a reproducible development criterion, not an estimate of generalization.

**Selection procedure** for each comparison between candidates:

1. The candidate must first satisfy all methodological constraints (Sections 3, 4, 19.1 and this section; ALLOWED_TECHNIQUES.md).
2. Produce one complete 3D prediction for `pn0` and one for `pn3`.
3. Evaluate both predictions against the GT.
4. Record `Dice_pn0` and `Dice_pn3` separately, together with the development score.
5. Select the candidate with the highest development score.

No candidate may be selected by a manual judgment made after seeing the results.

**Ties and near-ties:**

- Phase 37 defines no numerical tolerance.
- An experiment may declare a tolerance in its log entry **before** its results are seen. Candidates whose development scores differ by less than that tolerance are then treated as equivalent, and the preference is, in order:
  1. better Dice in the weaker of the two conditions (`pn0`, `pn3`);
  2. the simpler and more interpretable solution;
  3. fewer tunable parameters.
- Without a pre-declared tolerance, the highest development score wins, and the tie-breakers apply only to exactly equal scores.

**Visibility:** for every candidate considered seriously, `Dice_pn0`, `Dice_pn3` and the development score are all kept and reported, so that it is visible whether an improvement comes from only one noise condition.

**Secondary metrics:** Precision, Recall, IoU and lesion volume error (Section 17), when available, are diagnostic only. They help explain why candidates differ. They are NOT combined into a weighted score. Specificity must not drive tuning, because non-lesion voxels vastly outnumber lesion voxels.

**Methods and optional blocks:** the same rule decides whether an optional processing block is kept. A block stays only if it solves an observed problem or improves the development score, following the incremental strategy of Section 20: baseline, then preprocessing, morphology, component filtering and optional methods, each only if justified. A more complex block is never kept just because it exists.

**Fair comparisons:** candidates with tunable parameters are compared under the same tuning effort. A candidate must not be tuned extensively while its competitor keeps arbitrary parameters. This applies also when modalities are compared. T1, T2 and PD are never train/validation/test partitions.

**No slice-specific tuning:** every parameter applies through one automatic rule to the whole volume. Forbidden examples:

- different thresholds for different slices;
- morphology parameters for manually chosen slices;
- ignoring difficult slices;
- tuning only on slices known to contain lesions.

Locally adaptive methods are allowed only if their local behaviour is computed automatically from the MRI by a general rule. Slice-wise results may be used for diagnosis, never as the optimization objective.

**No lesion-position leakage:** the Section 19.1 rule applies. No parameter, ROI, mask, slice interval, candidate rule or processing decision may be derived from the absolute positions of the `msles2` lesions. Generic MRI-derived spatial rules, such as membership in an automatic brain mask, remain allowed.

**No GT intensity leakage:** class intensity statistics computed from the GT, such as the Phase 41 lesion and tissue means, medians, standard deviations and distributions, must not be used to set thresholds, normalization ranges, intensity intervals, exclusion rules or any other segmentation parameter. For example, "threshold at the midpoint between the lesion and WM means" and "lesion = intensity above a value observed in the GT" are forbidden. Such statistics may only support analysis decisions, such as the choice of the initial modality.

**Role of the GT:**

```text
Allowed:    MRI -> candidate segmentation -> predicted mask -> compare with GT -> metric -> compare candidates
Forbidden:  GT  -> feature / rule / ROI / seed / mask -> predicted mask
```

The GT may influence **which** candidate is selected, through its evaluation score. It must never take part in **generating** a candidate segmentation. This rule does not authorize the anatomical GT classes as a brain mask. That question remains open (Section 27.1) and the brain mask stays MRI-derived.

**Iterative development:** testing values, inspecting development results, refining ranges and repeating experiments are allowed, provided that:

- only development data are used;
- every meaningful experiment is logged;
- the final rule stays automatic and reproducible.

Iterative development is not an untouched validation, so final `pn0`/`pn3` results are in-sample and optimistic.

**Logging:** every tuning experiment is recorded in EXPERIMENT_LOG.md with at least:

- identifier and date;
- pipeline stage tuned;
- modality or modalities;
- development conditions;
- parameter values;
- enabled processing blocks;
- the tolerance, if one was declared before the results;
- `Dice_pn0`, `Dice_pn3` and the development score;
- relevant secondary metrics;
- decision and a short justification.

**Held-out protection:** `pn1`, `pn5`, `pn7`, `pn9` must not influence any choice of method, parameter, threshold, filter, morphology, component rule, modality or retained block. They are not downloaded before the Phase 96 freeze. If a held-out configuration ever influences a design decision, it is no longer held out, and this must be reported.

**Relationship to the final phases:**

- Phase 95: a single final parameter set is selected with this rule.
- Phase 96: the parameters are frozen and the freeze is recorded in version control. Only then are the held-out data downloaded.
- Phase 97: the final test runs without any change. No parameter may change in response to held-out results.

**Limitation:** all development and held-out data come from the single `msles2` phantom (Section 19.1). The tuning criterion selects parameters reproducibly. It provides no independent-subject validation.

---

## 20. Experimental Strategy

Development must proceed incrementally.

The first meaningful baseline should be approximately:

```text
MRI
 ↓
Brain Mask
 ↓
Thresholding
 ↓
Predicted Mask
```

Subsequent experiments may evaluate:

```text
Baseline
   +
Preprocessing
```

then:

```text
Baseline
   +
Morphology
```

then, only when justified:

```text
Baseline
   +
Connected-component filtering
```

and optionally:

```text
Region Growing
Multimodal Processing
Noise Robustness
```

The effect of each additional processing stage should be measured independently whenever possible.

---

## 21. Noise Robustness

Noise robustness is considered an extension of the core project.

It must be investigated only after a stable segmentation pipeline has been obtained.

If BrainWeb configurations with different noise levels are available for the selected case, the fixed final segmentation method may be applied to them to evaluate how segmentation performance changes with noise.

Parameters should not be independently retuned for every noise level unless the experiment explicitly studies parameter tuning.

Under the development/test protocol (Section 19.1), `pn0` and `pn3` are development configurations, while `pn1`, `pn5`, `pn7` and `pn9` are held-out. In any noise-robustness result, the two groups must be reported separately.

---

## 22. Visualization

The project should provide visual tools to inspect results.

Planned visualizations include:

- original MRI slice;
- ground-truth lesion overlay;
- predicted lesion overlay;
- comparison between prediction and ground truth;
- visualization of true positives;
- visualization of false positives;
- visualization of false negatives;
- final 3D lesion visualization.

Visualization code must remain separate from the segmentation algorithm.

Implemented (Phases 105–109, final v4 only): 2D overlays of prediction, GT and TP / FP / FN on T2 slices;
3D final prediction rendering; 3D GT / prediction comparison; 3D TP / FP / FN comparison; optional 3D
brain-context variant (transparent automatic brain mask, display only). 3D convention: X = array
dimension 1, Y = dimension 2, Z = dimension 3, 1 mm isotropic; no left / right labels.

Final results status (Phase 118): v4 (V4_K5, tag `v4-frozen`) is the final improved pipeline; v3
(D3_M1_G0, tag `v3-final-frozen`) is the original prospective reference (Phase 97). The final v4 reserved
test is complete and the result package is frozen (`docs/FINAL_RESULTS_FREEZE.md`).

---

## 23. Software Architecture

The project uses the following directory structure:

```text
data/
├── raw/
└── processed/

src/
├── io/
├── preprocessing/
├── segmentation/
├── evaluation/
└── visualization/

experiments/

results/
├── figures/
└── metrics/

docs/
```

Responsibilities must remain separated.

### `src/io`

Dataset loading and validation.

### `src/preprocessing`

Image preprocessing operations.

### `src/segmentation`

Brain mask and lesion segmentation algorithms.

### `src/evaluation`

Segmentation metrics and quantitative analysis.

### `src/visualization`

2D and 3D visualization.

### `experiments`

Scripts used to compare different configurations.

---

## 24. MATLAB Code Requirements

MATLAB code should follow these principles:

- functions should have clear responsibilities;
- input and output arguments should be explicit;
- avoid unnecessary global variables;
- avoid absolute filesystem paths;
- important parameters should be centralized;
- generated data must not overwrite raw data;
- segmentation code must not access ground truth;
- evaluation code may access both prediction and ground truth;
- figures should not contain logic required by the segmentation;
- experimental code should remain separate from reusable source functions.

The future `main.m` file should orchestrate the pipeline rather than contain the complete implementation.

---

## 25. Version Control

Git will be used to preserve stable project milestones.

A stable commit should be created after meaningful stages such as:

```text
dataset loader
MRI visualization
ground-truth loader
brain mask
baseline segmentation
morphological refinement
connected-component analysis
evaluation metrics
final visualization
```

Generated BrainWeb data and automatically generated results must remain excluded according to `.gitignore`.

---

## 26. Out of Scope

The following approaches are outside the scope of the project:

- Machine Learning;
- Deep Learning;
- neural-network segmentation;
- pretrained medical segmentation models;
- manual segmentation as the final method;
- ground-truth-assisted segmentation;
- clinical diagnosis;
- claiming validation on real clinical MRI data.

The project evaluates an Image Processing segmentation pipeline on simulated BrainWeb MRI data.

---

## 27. Open Decisions

The following decisions must NOT be made before inspecting the actual BrainWeb data:

- exact simulated configurations of the primary MS phantom (slice thickness, noise level, intensity non-uniformity level);
- whether and when to use the "mild" and "severe" MS phantoms as extensions;
- whether the initial baseline modality (T2, decided provisionally in Phase 41) must be revised after `pn3` is introduced;
- whether multimodal processing is necessary;
- exact lesion ground-truth representation;
- ground-truth binarization rule, if necessary;
- whether the Gaussian filter candidate (σ = 0.5, 3 × 3) improves the segmentation (current development choice: no filter, Phase 47);
- thresholding method;
- threshold values;
- morphological operations;
- structuring-element sizes;
- candidate-component filtering rules;
- whether region growing is useful;
- lesion-level matching criterion;
- RF/INU levels for any additional robustness experiment;
- how intensity-dependent parameters transfer across noise conditions, given the global intensity-scale mismatch between stored BrainWeb volumes found in Phase 45. The Phase 44 normalization standardizes the storage domain only; it is not an inter-volume harmonization.

These decisions must be based on data inspection and controlled experiments rather than assumptions.

The primary MS phantom ("moderate", `msles2`) has already been decided (Section 2).
The development/test split and the noise configurations of the held-out test have been decided in Phase 36 (Section 19.1).
The tuning criterion has been defined in Phase 37 (Section 19.2).
The intensity normalization strategy has been decided in Phase 44: fixed linear mapping 0…4095 → 0…1 (`docs/BRAINWEB_DATASET_NOTES.md`, Section 13.21).

### 27.1 Points Requiring Clarification

The following points of this specification are ambiguous or incomplete and must be clarified at the indicated project phase.

- **Development/test split and noise robustness** (Sections 19 and 21).
  The exact number and organization of the available BrainWeb multiple-sclerosis cases and configurations must first be verified from the downloaded dataset.
  The development/test strategy must then be defined using independent cases or acquisition configurations whenever possible.
  Noise configurations used for robustness analysis must not accidentally become a source of parameter tuning for the final test.
  With a single primary phantom (Section 2), all core-project configurations share the same anatomy and lesions; see `docs/BRAINWEB_DATASET_NOTES.md`, Section 13.1.
  To be clarified when selecting and downloading the MRI volumes.
  **Resolved in Phase 36:** see Section 19.1.

- **Anatomical labels and the brain mask** (Section 9).
  Section 3 forbids the lesion ground truth for brain-mask generation, but the use of BrainWeb anatomical labels (white matter, grey matter, CSF) is only discouraged "whenever possible".
  It must be decided whether anatomical labels are fully forbidden or allowed only for validating the brain mask.
  To be clarified before implementing brain-mask extraction.
  **Resolved in Phase 48:** the core brain mask is generated, tuned and validated from MRI data only. Anatomical labels are not used as mask inputs, oracle masks, or references for threshold selection, morphology tuning or component filtering. Phase 51 validates the mask with MRI boundary overlays. See Section 9 and `docs/BRAINWEB_DATASET_NOTES.md`, Section 13.26.

- **Specificity region** (Section 17).
  Computed over the complete volume, true negatives include all background voxels and specificity will be close to 100%.
  It must be decided whether specificity is also computed inside the brain mask only.
  To be clarified before implementing the evaluation metrics.

- **Volume error with empty ground truth** (Section 17).
  The lesion volume error is undefined when $V_{GT} = 0$, which can happen in slice-wise analysis.
  A rule for this case must be defined (for example, reporting the metric as undefined or computing it only on slices containing lesions).
  To be clarified before implementing slice-wise metrics.

---

## 28. Core Principle

The project must remain interpretable.

For every processing block, it should be possible to answer:

> What problem does this operation solve, and what evidence shows that it is useful?

If a processing stage cannot be justified theoretically or experimentally, it should not be included in the final pipeline.
