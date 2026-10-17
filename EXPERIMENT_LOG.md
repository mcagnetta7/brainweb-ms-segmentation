# Experiment Log

## 1. Purpose

This document records the experiments performed during the development of the BrainWeb multiple-sclerosis lesion segmentation project.

The objective is to make every relevant experimental decision:

- traceable;
- reproducible;
- comparable;
- technically justified.

The log must record not only successful experiments, but also experiments that fail or do not improve the segmentation.

A technique must not be kept in the final pipeline only because it appears visually promising.

Whenever possible, its contribution should be evaluated quantitatively.

---

## 2. General Rule

Development follows the principle:

```text
hypothesis
   ↓
controlled experiment
   ↓
result
   ↓
interpretation
   ↓
decision
```

Only one main methodological change should be introduced at a time whenever possible.

This allows the effect of that change to be evaluated independently.

Example:

```text
Experiment A
Baseline segmentation

Experiment B
Baseline + Gaussian filtering

Experiment C
Baseline + Gaussian filtering + morphology
```

Avoid changing filtering, thresholding and morphology parameters simultaneously unless the experiment explicitly studies their combined effect.

---

## 3. Experiment Identification

Each experiment must have a unique identifier.

Recommended format:

```text
EXP-001
EXP-002
EXP-003
...
```

Optional descriptive name:

```text
EXP-001 — Initial T2 thresholding baseline
EXP-002 — Gaussian filtering before Otsu
EXP-003 — Opening after thresholding
```

Experiment IDs must never be reused.

---

## 4. Experiment Status

Each experiment should have one of the following statuses:

```text
PLANNED
RUNNING
COMPLETED
REJECTED
INVALID
```

Meaning:

```text
PLANNED
Experiment defined but not yet executed.

RUNNING
Experiment currently being executed.

COMPLETED
Experiment successfully executed and analyzed.

REJECTED
Experiment executed correctly but the tested method was not retained.

INVALID
Experiment cannot be used for conclusions because of an implementation,
data, configuration or methodological problem.
```

A rejected experiment is still useful and must remain documented.

---

## 5. Experiment Template

Copy the following template for every experiment.

---

### EXP-XXX — Experiment Title

#### Status

```text
PLANNED
```

#### Date

```text
YYYY-MM-DD
```

#### Objective

Describe the specific question addressed by this experiment.

Example:

```text
Evaluate whether Gaussian filtering before Otsu thresholding improves
lesion segmentation compared with the unfiltered baseline.
```

The objective should describe one main question.

---

#### Hypothesis

Describe what is expected before running the experiment.

Example:

```text
Moderate Gaussian smoothing may reduce local intensity noise and produce
a more stable threshold, but excessive smoothing may remove small lesion
structures.
```

The hypothesis must be written before interpreting the results.

---

#### Baseline / Reference

Specify the experiment or configuration used as reference.

Example:

```text
EXP-001
```

If there is no previous baseline:

```text
None — initial baseline experiment.
```

---

#### Dataset Configuration

Record the exact BrainWeb data used.

##### BrainWeb case

```text
TBD
```

##### MRI modality

```text
TBD
```

Possible examples:

```text
T1
T2
PD
```

##### Lesion configuration

```text
TBD
```

##### Noise level

```text
TBD
```

##### RF / intensity non-uniformity

```text
TBD
```

##### Ground-truth representation

```text
TBD
```

Only fields that actually exist in the selected BrainWeb configuration
should be used after dataset inspection.

Do not assume BrainWeb parameters before verifying the downloaded data.

---

#### Development or Test Data

Specify whether the data belongs to:

```text
DEVELOPMENT
TEST
```

Parameters may be selected using development data.

Final test data must not be used to modify algorithm parameters.

---

#### Input

Describe the input used by the segmentation algorithm.

Example:

```text
T2 MRI volume
```

Ground truth must NOT be included here as an algorithm input.

---

#### Processing Pipeline

Write the exact pipeline tested.

Example:

```text
MRI
 ↓
Brain Mask
 ↓
Gaussian Filtering
 ↓
Otsu Thresholding
 ↓
Predicted Mask
```

Only include operations actually executed in this experiment.

---

#### Changed Component

Identify the main change compared with the reference experiment.

Example:

```text
Added Gaussian filtering before Otsu thresholding.
```

Whenever possible, all other pipeline components should remain unchanged.

---

#### Parameters

Record every relevant parameter.

Example:

```text
Gaussian sigma: 1.0
Gaussian filter size: automatic

Threshold method: Otsu

Connectivity: 8

Morphological processing: none
```

Do not write only:

```text
default parameters
```

if those defaults influence the result.

Relevant defaults should eventually be explicitly recorded.

---

#### Implementation

##### Main script

```text
TBD
```

##### Functions involved

```text
TBD
```

##### Configuration file

```text
TBD
```

---

#### Git Version

Record the Git commit used for the experiment.

```text
Commit:
TBD

Working tree clean:
YES / NO
```

Recommended commands:

```bash
git rev-parse --short HEAD
git status --short
```

This allows the exact source code used for an experiment to be recovered later.

The commit identifies the executed code only if the working tree is clean.
If uncommitted changes were present, describe them here.

---

#### Execution

##### MATLAB version

```text
R2026b
```

##### Image Processing Toolbox

```text
R2026b
```

##### Execution result

```text
SUCCESS / ERROR
```

##### Warnings

```text
None
```

or describe them.

##### Errors

```text
None
```

or describe them.

---

#### Quantitative Results

Record only metrics applicable to the current experiment.

##### 3D voxel-wise metrics

```text
Dice:             TBD
IoU:              TBD
Precision:        TBD
Recall:           TBD
Specificity:      TBD
Volume error (%): TBD
```

For specificity, record the region over which it was computed, since this choice is still open (see `PROJECT_SPEC.md`, Section 27.1).

##### Tuning experiments (PROJECT_SPEC.md, Section 19.2)

When the experiment compares candidates for tuning, also record:

```text
Tolerance declared before results: none / <value>
Dice_pn0:                          TBD
Dice_pn3:                          TBD
Development score (mean):          TBD
```

The tolerance must be written here before the results are seen. Without it, the highest development score wins.

Do not fabricate or estimate missing metrics.

If a metric has not yet been implemented:

```text
Not evaluated.
```

---

#### Lesion-Level Results

If lesion-level evaluation is available:

```text
Detected lesions:       TBD
Missed lesions:         TBD
False lesion detections:TBD
```

Otherwise:

```text
Not evaluated.
```

---

#### Visual Results

Record the generated figures.

Example:

```text
results/figures/EXP-XXX_prediction.png
results/figures/EXP-XXX_gt_overlay.png
results/figures/EXP-XXX_error_map.png
```

Relevant visual observations may be written here.

Example:

```text
Several false-positive regions are visible near the outer brain boundary.
Small central lesions appear partially fragmented.
```

Visual observations must not replace quantitative evaluation.

---

#### Comparison with Reference

Summarize the difference relative to the reference experiment.

Example:

```text
Metric       EXP-001    EXP-002    Difference
Dice         TBD        TBD        TBD
Precision    TBD        TBD        TBD
Recall       TBD        TBD        TBD
```

Do not conclude that a method is better based on one metric without
considering the type of errors produced.

---

#### Interpretation

Explain what the experiment shows.

Questions to consider:

```text
Did the tested modification solve the intended problem?

Did it introduce new errors?

Did it improve lesion detection?

Did it remove small lesions?

Did false positives increase or decrease?

Is the observed effect consistent across relevant slices or cases?
```

Interpretation should distinguish observed results from assumptions.

---

#### Decision

Choose one:

```text
KEEP
REJECT
INVESTIGATE FURTHER
```

Then provide the reason.

Example:

```text
Decision: REJECT

Reason:
Gaussian filtering reduced isolated false positives but also removed
several small lesion candidates and reduced recall compared with the
baseline.
```

---

#### Next Experiment

If applicable:

```text
EXP-XXX
```

Describe only the next controlled change.

---

#### Notes

Any additional technical observation that may be useful later.

---

## 6. Experiment Summary Table

Maintain this table as experiments are completed.

| ID | Description | Data | Main change | Dice pn0 | Dice pn3 | Dev score | Precision | Recall | Decision |
|---|---|---|---|---:|---:|---:|---:|---:|---|
| EXP-001 | Exploratory Gaussian smoothing (Phase 45) | T2 msles2 1mm rf0, pn0 + pn3 | Gaussian σ 0.5, 3×3 on pn3 | n/a | n/a | n/a | n/a | n/a | INVESTIGATE FURTHER (Phase 47) |
| EXP-002 | Exploratory median filtering (Phase 46) | T2 msles2 1mm rf0, pn0 + pn3 | Median 3×3, symmetric, on pn3 | n/a | n/a | n/a | n/a | n/a | REJECT as Phase 47 candidate |
| EXP-003 | Exploratory mean filtering (supplementary, before Phase 47) | T2 msles2 1mm rf0, pn0 + pn3 | Mean 3×3, replicate, on pn3 | n/a | n/a | n/a | n/a | n/a | REJECT as Phase 47 candidate |
| EXP-004 | Gaussian filter-effect evaluation (Phase 47) | T2 msles2 1mm rf0, pn0 + pn3 | Unfiltered vs Gaussian σ 0.5, 3×3 | n/a | n/a | n/a | n/a | n/a | Current filter = NONE; Gaussian kept as candidate |
| EXP-005 | Initial support mask, global Otsu (Phase 49) | T2 msles2 1mm rf0, pn0 + pn3 | One Otsu threshold per volume, applied per slice | n/a | n/a | n/a | n/a | n/a | RAW head-support mask; cleanup in Phase 50 |
| EXP-006 | Support-mask cleanup (Phase 50) | T2 msles2 1mm rf0, pn0 + pn3 | A: largest 8-conn component + fill; B: 3×3 opening first | n/a | n/a | n/a | n/a | n/a | A kept as head-support mask; B rejected; brain mask BLOCKED |
| EXP-007 | Erode → select → dilate (Phase 50, supplementary) | T2 msles2 1mm rf0, pn0 + pn3 | 3×3 erosion, largest component, 3×3 dilation, AND raw, fill | n/a | n/a | n/a | n/a | n/a | REJECTED; A remains; watershed (EXP-008) justified |
| EXP-008 | Marker-controlled watershed (Phase 50, supplementary) | T2 msles2 1mm rf0, pn0 + pn3 | 5×5 erosion marker, 3×3 morphological gradient, imimposemin + watershed | n/a | n/a | n/a | n/a | n/a | REJECTED: brain marker stays whole-head in central slices; A remains |
| EXP-009 | Reconstruction / regional-maxima markers (Phase 50, supplementary) | T2 msles2 1mm rf0, pn0 + pn3 | Opening + closing by reconstruction (3×3), imregionalmax, multi-basin union | n/a | n/a | n/a | n/a | n/a | REJECTED: scalp maxima accepted, fragmentation, k = 136 lost; strategic decision needed |
| EXP-010 | T1 brain-mask feasibility (Phase 50, supplementary) | T1 msles2 1mm rf0, pn0 + pn3 | Mask source modality T2 → T1; raw global Otsu, no cleanup | n/a | n/a | n/a | n/a | n/a | PROMISING; T1 cleanup experiment justified |
| EXP-011 | T1 largest component + fill (Phase 50, supplementary) | T1 msles2 1mm rf0, pn0 + pn3 | EXP-006 candidate-A rule applied to the T1 raw mask | n/a | n/a | n/a | n/a | n/a | REJECTED as final Phase-50 method; central T1 brain/scalp separation confirmed; identity at extremes fails |
| EXP-012 | T1 topology-based nested-component selection (Phase 50, supplementary) | T1 msles2 1mm rf0, pn0 + pn3 | Selection rule: largest component fully enclosed by another component; empty slice if none | n/a | n/a | n/a | n/a | n/a | PROMISING BUT INCOMPLETE: identity solved, one-component support truncated |
| EXP-013 | T1 immediate-parent sibling union (Phase 50, supplementary) | T1 msles2 1mm rf0, pn0 + pn3 | Anchor (EXP-012) + all direct children of its immediate parent, each filled individually | n/a | n/a | n/a | n/a | n/a | REJECTED as Phase-50 candidate; hemispheric sibling recovery confirmed; non-specific small siblings; inferior tissue inside parent |
| EXP-014 | T1 marker-controlled watershed with topology markers (Phase 50, supplementary) | T1 msles2 1mm rf0, pn0 + pn3 | Fg marker = EXP-012 anchor; non-brain = outside filled parent + outer 3×3 edge; 3×3 morph. gradient | n/a | n/a | n/a | n/a | n/a | REJECTED: basin = whole cavity incl. dark skull/CSF band; face/neck leakage inferiorly |
| EXP-015 | T1 internal dark-background skeleton marker feasibility (Phase 50, supplementary, no watershed) | T1 msles2 1mm rf0, pn0 + pn3 | internalDark = filledParent ∧ ¬raw ∧ ¬filledAnchor; bwmorph 'skel' Inf | n/a | n/a | n/a | n/a | n/a | REJECTED as raw marker: central dark-band loop confirmed, but skeleton encloses every sibling (100 %) and face/neck/orbital networks |
| EXP-016 | T1 Canny outer-brain-boundary feasibility (Phase 50, supplementary, no mask) | T1 msles2 1mm rf0, pn0 + pn3 | edge(I,'Canny') automatic, per slice, raw | n/a | n/a | n/a | n/a | n/a | PROMISING BUT PROBLEMATIC: outer cortical contour present; many competing contours; midline ambiguity; barrier diagnostic uninformative |
| EXP-017 | T1 Canny minimal-closing enclosing-contour candidate (Phase 50, supplementary) | T1 msles2 1mm rf0, pn0 + pn3 | One 3×3 closing; per-component fill; smallest region containing the whole EXP-012 anchor | n/a | n/a | n/a | n/a | n/a | REJECTED: closing fuses concentric contours, candidate = head disc (median 1.00 × filled parent); independent 2D branch at strong limitation |
| EXP-018 | T1 slice-to-slice propagation with marker-controlled watershed (Phase 50, supplementary; inter-slice authorized by user) | T1 msles2 1mm rf0, pn0 + pn3 | Seed = EXP-012 at k = 75; markers from neighbour mask eroded/dilated by disk 3; 3×3 gradient watershed | n/a | n/a | n/a | n/a | n/a | PROMISING BUT PROBLEMATIC: central + superior brain-scale with both hemispheres; inferior drift into orbit/face/neck; vertex lag |
| EXP-019 | Asymmetric slice-to-slice propagation (Phase 50, supplementary) | T1 msles2 1mm rf0, pn0 + pn3 | As EXP-018 but erosion disk 5, dilation disk 1 | n/a | n/a | n/a | n/a | n/a | REJECTED: collapse, one-pixel rim lost per slice (ridge pixels excluded + 1-px dilation) |
| EXP-020 | EXP-019 with ridge pixels assigned to foreground (Phase 50, supplementary) | T1 msles2 1mm rf0, pn0 + pn3 | Candidate = NOT background-touched basins AND NOT background | n/a | n/a | n/a | n/a | n/a | REJECTED: no collapse, no orbital drift, but superior hemisphere loss, pn3 stops at k = 145, inferior dark tissue; radii too restrictive |
| EXP-021 | 3D erode → largest 3D component → 3D dilate (Phase 50, exploratory exception; 3D not in course PDF) | T1 msles2 1mm rf0, pn0 + pn3 | Sphere r = 3, 26-conn, AND raw, 2D fill | n/a | n/a | n/a | n/a | n/a | Technically ACCEPTABLE candidate (both hemispheres, skull base without face, IoU pn0/pn3 0.985); adoption pending user decision; later frozen, Phase-51 validated and applied (Phase 52) |
| EXP-022 | Manual global T2 threshold (Phase 54) | T2 msles2 1mm rf0, pn0 + pn3, inside EXP-021 | One manual threshold T_raw = 3400 (T_norm = 3400/4095), strict >, from Phase-40 histograms | not computed | not computed | n/a | not computed | not computed | REFERENCE ESTABLISHED (candidates 4.20 % / 2.52 % of brain; mostly hyperintense structures compatible with CSF spaces) |
| EXP-023 | Iterative global T2 threshold (Phase 55) | T2 msles2 1mm rf0, pn0 + pn3, inside EXP-021 | Course iterative rule: T0 = mean, partition >= / <, eps = 0.5/4095; T_iter 2323.13 (pn0) / 2421.88 (pn3) raw-eq. | not computed | not computed | n/a | not computed | not computed | RESULT ESTABLISHED (candidates 50.25 % / 14.85 % of brain; splits main tissue populations) |
| EXP-024 | Otsu global T2 threshold (Phase 56) | T2 msles2 1mm rf0, pn0 + pn3, inside EXP-021 | graythresh(T2(brainMask)) per condition, same algorithm; T_otsu 2713.94 (pn0) / 2408.82 (pn3) raw-eq. | not computed | not computed | n/a | not computed | not computed | RESULT ESTABLISHED (candidates 13.22 % / 15.43 % of brain; two-class histogram split, not lesion-specific) |
| EXP-025 | Quantitative thresholding comparison (Phase 57) | Frozen EXP-022/023/024 predictions vs GT label 10, pn0 + pn3 | Full-volume 3D Dice; DevelopmentScore = mean(pn0, pn3); no tie tolerance | 0.0309 (Otsu) | 0.0268 (Otsu) | 0.028849 (Otsu) | not computed | not computed | SELECTED INITIAL METHOD: EXP-024 Otsu (manual 0.027325, iterative 0.018026) |
| EXP-026 | Multi-threshold T2, multithresh N = 2, Class 3 (Phase 58) | T2 msles2 1mm rf0, pn0 + pn3, EXP-021 mask | graythresh → multithresh(…, 2) + imquantize, highest class | 0.0404 | 0.0427 | 0.041545 | not computed | not computed | KEEP: current selected thresholding method (EXP-024 0.028849) |
| EXP-027 | Local T2 threshold T = m + b·s, 2D, 9-config grid (Phase 59) | T2 msles2 1mm rf0, pn0 + pn3, EXP-021 mask | Global multithresh → masked local mean/std threshold; best W21_B15 | 0.0361 | 0.0362 | 0.036103 | not computed | not computed | REJECT (EXP-026 0.041545 remains current) |
| EXP-028 | Candidate-mask error analysis (Phase 61, diagnostic) | Phase-60 candidateMask (= EXP-026), pn0 + pn3, GT label 10 | None (TP/FP/FN counts, 2D 8-neighbour topology, slice profiles) | n/a | n/a | n/a | n/a | n/a | DIAGNOSTIC RESULT ESTABLISHED (dominant FP: large fluid-like regions fused with periventricular lesions) |
| EXP-029 | Erosion / dilation probe, square 3×3, 2D (Phase 62) | Phase-60 candidateMask, pn0 + pn3, EXP-021 | One erosion or one dilation on the frozen candidate mask | 0.0352 / 0.0196 | 0.0349 / 0.0209 | 0.035040 / 0.020238 | n/a | n/a | EFFECTS QUANTIFIED: both WORSEN baseline 0.041545; no morphology selected |
| EXP-030 | Standard opening probe, square 3×3, 2D (Phase 63) | Phase-60 candidateMask, pn0 + pn3, EXP-021 | One imopen on the frozen candidate mask | 0.0566 | 0.0570 | 0.056845 | n/a | n/a | IMPROVES baseline 0.041545 (+0.0153) with the provisional probe; not selected |
| EXP-031 | Closing after the EXP-030 opening, square 3×3, 2D (Phase 64) | EXP-030 opened masks, pn0 + pn3, EXP-021 | One imclose on the opened mask (brain mask after complete closing) | 0.0561 | 0.0563 | 0.056181 | n/a | n/a | Below opening (−0.000665); EXP-030 remains best observed; not selected |
| EXP-032 | Structuring-element selection for standard opening, 4 SE grid (Phase 65) | Phase-60 candidateMask, pn0 + pn3, EXP-021 | imopen with square3 / diamond1 / square5 / diamond2 | 0.0566 | 0.0570 | 0.056845 (square3) | n/a | n/a | SELECTED DEVELOPMENT SE: square3 (diamond1 0.053937, diamond2 0.051808, square5 0.037654) |
| EXP-033 | Before / after morphology comparison (Phase 66) | Phase-60 vs Phase-65 frozen masks, pn0 + pn3 | None (evaluation of the selected opening square3) | 0.0404 → 0.0566 | 0.0427 → 0.0570 | 0.041545 → 0.056845 | n/a | n/a | MORPHOLOGY BLOCK RETAINED FOR SUBSEQUENT DEVELOPMENT (development-set comparison, not independent validation) |
| EXP-034 | 2D connected components, 8-connectivity (Phase 67) | Phase-65 selected masks, pn0 + pn3 | bwconncomp per axial slice (identification only) | n/a | n/a | n/a | n/a | n/a | COMPONENTS IDENTIFIED: 1,210 / 1,068 slice-wise instances (not unique lesions); no filtering |
| EXP-035 | 2D component properties: Area, Centroid, BoundingBox (Phase 68) | Phase-67 components, pn0 + pn3 | regionprops on the saved ccBySlice (description only) | n/a | n/a | n/a | n/a | n/a | PROPERTY TABLE ESTABLISHED: 1,210 / 1,068 rows; Area 9–1,332, median 18; no filtering |
| EXP-036 | Conservative component-area filter: remove Area == 9 (Phase 69) | Phase-65/67/68 artifacts, pn0 + pn3 | Remove whole 2D components with Area 9 | 0.0581 | 0.0581 | 0.058101 | n/a | n/a | PROVISIONALLY RETAINED FOR PHASE 70 (+0.001256; removed TP 36 / 42) |
| EXP-037 | Small-lesion protection audit of the Area-9 filter (Phase 70) | Phase-65 vs EXP-036 frozen masks, pn0 + pn3, GT 2D components | None (audit; 2D GT cross-sections, 8-connectivity) | 0.0581 | 0.0581 | 0.058101 | n/a | n/a | PROTECTION FAILED (3 / 4 cross-sections completely lost) → EXP-036 REJECTED; pipeline reverts to Phase-65 masks |
| EXP-038 | Complete predicted-volume reconstruction M_pred (Phase 71) | Phase-65 retained masks, pn0 + pn3 | 181 axial slices assembled into M_pred (representation only) | n/a | n/a | n/a | n/a | n/a | REPRESENTATION ESTABLISHED: M_pred = Phase-65 source exactly (70,878 / 67,066 voxels) |
| EXP-039 | 3D connected components of M_pred, 26-connectivity (Phase 72) | Phase-71 M_pred, pn0 + pn3 | bwconncomp(M_pred, 26), representation only (3D extension of a course concept) | n/a | n/a | n/a | n/a | n/a | 3D CANDIDATE COMPONENTS ESTABLISHED: 335 / 291 (not lesions); exact reconstruction |
| EXP-040 | Individual-modality benchmark T1 / T2 / PD, Class 1/2/3 (Phase 78) | T1/T2/PD msles2 1mm rf0, pn0 + pn3, EXP-021 | Source modality and class; multithresh N = 2 + square3 opening for all | 0.0566 (T2) | 0.0570 (T2) | 0.056845 (T2 C3) | n/a | n/a | BEST INDIVIDUAL MODALITY: T2 Class 3 (PD C3 0.016424, T1 C3 0.004280); pipeline unchanged |
| EXP-041 | T2 + PD intersection fusion (Phase 80) | Phase-78 T2 / PD Class-3 masks, pn0 + pn3 | Fusion M_T2 AND M_PD (one predefined rule, no GT) | not computed | not computed | n/a | n/a | n/a | FUSED PREDICTION GENERATED (T2 retained 99.96 % / 92.06 %); evaluation in Phase 81 |
| EXP-042 | Mono T2 vs T2 AND PD comparison (Phase 81) | Phase-71 M_pred vs EXP-041, pn0 + pn3, GT label 10 | None (evaluation of the frozen fusion) | 0.0566 → 0.0567 | 0.0570 → 0.0563 | 0.056845 → 0.056472 | n/a | n/a | REJECT_MULTIMODAL_FUSION; T2-only retained (removed pn3: 5,149 FP / 177 TP) |
| EXP-043 | Formal voxel-wise confusion matrix (Phase 82) | Phase-71 M_pred vs GT label 10, pn0 + pn3 | None (evaluation bookkeeping: TP/FP/FN/TN) | n/a | n/a | n/a | n/a | n/a | EVALUATOR VALIDATED: TN 7,036,854 / 7,040,572; TP/FP/FN = Phase 81 |
| EXP-044 | Formal Dice implementation (Phase 83) | Phase-71 M_pred vs GT label 10, pn0 + pn3 | None (evaluation: Dice from Phase-82 counts) | 0.056647 | 0.057043 | n/a | n/a | n/a | DICE FORMALIZED AND VALIDATED (= earlier T2 Dice) |
| EXP-045 | Formal IoU / Jaccard implementation (Phase 84) | Phase-71 M_pred vs GT label 10, pn0 + pn3 | None (evaluation: IoU from Phase-82 counts) | n/a | n/a | n/a | n/a | n/a | IoU FORMALIZED AND VALIDATED: 0.029149 / 0.029359 (= Dice/(2−Dice)) |
| EXP-046 | Formal Precision implementation (Phase 85) | Phase-71 M_pred vs GT label 10, pn0 + pn3 | None (evaluation: Precision from Phase-82 counts) | n/a | n/a | n/a | 0.029727 / 0.030015 | n/a | PRECISION FORMALIZED AND VALIDATED (~97 % of predicted voxels are FP) |
| EXP-047 | Formal Recall / Sensitivity implementation (Phase 86) | Phase-71 M_pred vs GT label 10, pn0 + pn3 | None (evaluation: Recall from Phase-82 counts) | n/a | n/a | n/a | n/a | 0.599943 / 0.573178 | RECALL FORMALIZED AND VALIDATED (voxel-wise; low Precision + moderate Recall) |
| EXP-048 | Formal Specificity implementation (Phase 87) | Phase-71 M_pred vs GT label 10, pn0 + pn3 | None (evaluation: Specificity from Phase-82 counts) | n/a | n/a | n/a | n/a | n/a | SPECIFICITY FORMALIZED AND VALIDATED: 0.990322 / 0.990845 (class imbalance; not overall accuracy) |
| EXP-049 | Formal GT lesion volume (Phase 88) | GT label 10 only (shared by pn0 / pn3) | None (evaluation reference: V_GT = N_GT × V_voxel) | n/a | n/a | n/a | n/a | n/a | GT VOLUME FORMALIZED: 3,512 voxels × 1 mm³ = 3,512 mm³ (3.512 mL) |
| EXP-050 | Formal predicted lesion volume (Phase 89) | Phase-71 M_pred, pn0 + pn3 separately | None (evaluation: V_pred = N_pred × V_voxel) | n/a | n/a | n/a | n/a | n/a | PREDICTED VOLUME FORMALIZED: 70,878 / 67,066 mm³ (TP + FP); no GT comparison |
| EXP-051 | Formal lesion-volume error (Phase 90) | EXP-049 V_GT + EXP-050 V_pred (pn0, pn3) | None (evaluation: \|V_pred − V_GT\| / V_GT × 100) | n/a | n/a | n/a | n/a | n/a | VOLUME ERROR: 1918.17 % / 1809.62 %, both overestimation (not an overlap metric) |
| EXP-052 | Consolidated complete-volume 3D evaluation (Phase 91) | EXP-043..051 artifacts, pn0 + pn3 | None (consolidation of formal results) | 0.056647 | 0.057043 | n/a | 0.029727 / 0.030015 | 0.599943 / 0.573178 | PRIMARY COMPLETE-3D TABLE ESTABLISHED; dominant problem = FP burden |
| EXP-053 | Slice-wise diagnostic evaluation (Phase 92) | Phase-71 M_pred vs GT label 10, pn0 + pn3, 181 axial slices | None (diagnostic profiling) | n/a | n/a | n/a | n/a | n/a | DIAGNOSTIC: FP widespread but central-heavy (k ~70-104); 40/41 GT slices with Recall 0; summed counts = Phase 91 |
| EXP-054 | Lesion-wise 3D analysis, 26-connectivity, any-overlap rule (Phase 93) | Phase-71 M_pred vs GT label 10, pn0 + pn3 | None (object-level diagnostic) | n/a | n/a | n/a | n/a | n/a | 59 GT lesions: detected 15 / 14, missed 44 / 45; false components 331 / 287; one merged object holds ~88 % of TP |
| EXP-055 | Small-vs-large GT lesion analysis, median split 7 voxels (Phase 94) | EXP-054 status + GT component sizes | None (size-stratified diagnostic) | n/a | n/a | n/a | n/a | n/a | SMALL detected 3/31, 2/31; LARGE 12/28 both; size explains failure PARTLY |
| EXP-056 | Development-only tuning, 24-configuration grid P x T x M x G (Phase 95) | T2 pn0 + pn3, GT label 10 after all predictions | Gaussian / multithresh N / opening / single-slice 3D component removal | 0.058067 | 0.058248 | 0.058158 | 0.030520 / 0.030695 | 0.59596 / 0.56919 | SELECTED P0_T2_M2_G1 (+0.00131 vs baseline); superseded by EXP-057 |
| EXP-057 | Final development experiment: T1-derived anatomical support, 36-configuration grid S x T x M x G (Phase 95) | T2 + T1 pn0 + pn3, GT label 10 after all predictions | Support S0/S1/S2 / T2 threshold TA/TB inside support / opening / single-slice 3D component removal | 0.661039 | 0.539029 | 0.600034 | 0.664366 / 0.439418 | 0.657745 / 0.697039 | SELECTED S2_TA_M2_G1 (+0.5419 vs EXP-056 winner); frozen as v1 (tag v1-frozen) |
| EXP-058 | v2 under amendment A1: noise filter (Gaussian / anisotropic on T1 / T2) x extent recovery (morphological reconstruction), 21 configurations (Phase 95) | T2 + T1 pn0 + pn3, GT label 10 after all predictions | Filter F0-F6 / recovery R0-R2 on the frozen v1 | 0.669340 | 0.653000 | 0.661169 | 0.69969 / 0.71193 | 0.64151 / 0.60308 | SELECTED F5_R0 (anisotropic T2, +0.0611 vs v1) = v2; R1/R2 rejected; frozen (tag v2-frozen) |
| EXP-059 | v3 under amendment A2: 2D/3D anisotropic diffusion x opening x component rule, 12 configurations (Phase 95) | T2 + T1 pn0 + pn3, GT label 10 after all predictions | Diffusion D2/D3 / opening none, diamond 1, square 3 / G0/G1 on the frozen v2 | 0.68538 | 0.69440 | 0.689892 | 0.64584 / 0.69263 | 0.73007 / 0.69618 | SELECTED D3_M1_G0 = v3 PRIMARY (+0.0287 vs v2); v2, v1 secondary; not yet frozen |

Preprocessing experiments without segmentation use `n/a` for the segmentation metrics.

The detailed experiment sections remain the authoritative record.

---

## 7. Rules for Parameter Tuning

The authoritative tuning criterion is defined in `PROJECT_SPEC.md`, Section 19.2. Tuning candidates are evaluated on both `pn0` and `pn3` with one shared parameter set, using the mean complete-volume 3D Dice as the primary development score.

Parameter tuning must use development data only.

Parameters include, for example:

```text
filter parameters
threshold parameters
structuring-element size
connectivity choices
component-filtering thresholds
region-growing parameters
multimodal fusion parameters
```

Once the final configuration is selected, parameters must be frozen
before running the final test evaluation.

A final-test result must never be followed by parameter modification
based on its ground truth.

If this happens, that case must be considered part of development rather
than an independent final test.

---

## 8. Rules for Ground Truth

Ground truth may be used for:

```text
quantitative evaluation
error visualization
development-set comparison
methodological analysis
```

Ground truth must not be used directly by the segmentation pipeline.

It must not determine:

```text
lesion location
segmentation seeds
candidate removal
manual segmentation correction
final-test threshold adjustment
```

---

## 9. Negative Results

Negative results must be preserved.

Examples:

```text
Gaussian filtering reduced performance.

Opening removed small lesions.

Local thresholding introduced excessive false positives.

Region growing did not improve lesion boundaries.
```

These results are scientifically useful because they justify why a
technique was excluded from the final pipeline.

Do not delete failed experiments from this log.

---

## 10. Reproducibility Rule

A completed experiment should ideally be reproducible using:

```text
Experiment ID
+
Git commit
+
Dataset configuration
+
Configuration parameters
+
MATLAB version
```

If an experiment cannot be reproduced, its results should not be used
as final project evidence.

---

## 11. Current Experiment Status

The first lesion-segmentation experiment (EXP-022, Phase 54) has been performed. It is a reference, not a selected method; no GT-based lesion metric has been computed yet.

Dataset preparation, loading, validation, visualization, the development/test and tuning protocols (Phases 17–37), the exploratory intensity analyses (Phases 38–41), the preprocessing definitions (Phases 42–44), the brain mask (Phases 48–52, EXP-021 validated and applied), the brain-only histograms (Phase 40, resumed after Phase 52) and the baseline definition (Phase 53) have been completed.

Preprocessing experiments so far:

- EXP-001 (Phase 45, Gaussian smoothing): INVESTIGATE FURTHER;
- EXP-002 (Phase 46, median filtering): REJECTED as a Phase 47 candidate;
- EXP-003 (supplementary, mean filtering): REJECTED as a Phase 47 candidate;
- EXP-004 (Phase 47, filter-effect evaluation): current development filter = NONE; Gaussian σ 0.5 is kept as the candidate for "baseline + preprocessing";
- EXP-005 (Phase 49, initial support mask): raw global-Otsu mask; it is a head-support mask with known issues for Phase 50;
- EXP-006 (Phase 50, cleanup): candidate A gives a conservative head-support mask; candidate B is rejected. An intracranial mask was not achieved (BLOCKED / NEEDS REFINEMENT);
- EXP-007 (Phase 50, erode → select → dilate): REJECTED. The separation is intermittent and loses brain support. Marker-controlled watershed (EXP-008) is the justified next candidate;
- EXP-008 (Phase 50, marker-controlled watershed): REJECTED. The watershed separates the brain plausibly where the marker is valid, but the 5×5 erosion marker still covers the whole head in the central slices. Phase 50 remains BLOCKED; candidate A is the head-support fallback;
- EXP-009 (Phase 50, reconstruction / regional-maxima markers): REJECTED. Phase 50 remains BLOCKED, and a strategic decision is required (accept a head-support mask, or use another modality for the mask);
- EXP-010 (Phase 50, T1 brain-mask feasibility): PROMISING. In the raw T1 Otsu mask a broad dark band separates the scalp from the brain in the central slices. Phase 50 remains BLOCKED until a T1 cleanup experiment is run;
- EXP-011 (Phase 50, T1 largest component + fill): REJECTED AS FINAL PHASE-50 METHOD BUT CENTRAL T1 BRAIN/SCALP SEPARATION CONFIRMED. The brain section is selected in about k = 46–133, but at the volume extremes the rule selects face/neck, the scalp ring (filled into a head disc) or the artefact, and in some upper slices `pn0` and `pn3` select different objects. Failure category B (component identity across z). Phase 50 remains BLOCKED; candidate A (T2) is the head-support fallback;
- EXP-012 (Phase 50, T1 nested-component selection): PROMISING BUT INCOMPLETE. Selecting the largest component fully enclosed by another component never selects the scalp ring, the face/neck mass or the artefact, creates no head discs, and is consistent at k = 136. However, keeping one component per slice keeps only one hemisphere in the upper slices, and the inferior slices give only small nested objects or nothing. Phase 50 remains BLOCKED;
- EXP-013 (Phase 50, T1 immediate-parent sibling union): REJECTED as the Phase-50 candidate. Both hemispheres are recovered in the upper slices, consistently in `pn0` and `pn3` (k = 136, 139, 143). However, the sibling family also adds many small nested objects of uncertain identity, and the inferior temporal/cerebellar tissue belongs to the parent component itself, so k = 40–44 do not improve. Phase 50 remains BLOCKED;
- EXP-014 (Phase 50, T1 marker-controlled watershed with the EXP-012 anchor as foreground marker): REJECTED. With only the outer edge of the parent marked as non-brain, the basin fills the whole cavity enclosed by the peripheral component, including the dark skull/CSF band (central slices degrade). In the inferior slices it floods face/neck tissue, and `pn0`/`pn3` consistency worsens. Failure category B (boundary leakage), with A (small inferior anchors) contributing. Phase 50 remains BLOCKED;
- EXP-015 (Phase 50, T1 internal dark-background skeleton marker, no watershed): REJECTED as a raw marker. At k = 91 the skeleton is a single loop in the brain/periphery dark band. However, skeletonization preserves holes, so it encloses every non-anchor foreground component: 100 % of the sibling area, including the second hemisphere at k ≈ 136. It also forms dense networks in the face/neck, orbit and sinus regions. A separate marker-selection rule would be required. Phase 50 remains BLOCKED;
- EXP-016 (Phase 50, automatic 2D Canny on T1, edge feasibility, no mask): PROMISING BUT PROBLEMATIC. An outer cortical contour is visually present in the central and upper slices, and at the base of the skull Canny separates the temporal and cerebellar tissue from the bright periphery that Otsu had merged; `pn0`/`pn3` agree (IoU 0.8028). However, there are many competing contours (scalp, skull, sulci, orbit, face/neck), the inter-hemispheric midline adds ambiguity, and the predeclared barrier test proved uninformative for Canny. An automatic contour-selection and completion method would be required. Phase 50 remains BLOCKED;
- EXP-017 (Phase 50, Canny + one 3×3 closing + per-component filling + smallest enclosure of the anchor): REJECTED. The closing and the internal edges merge the concentric contours into one component, so the smallest enclosure is the whole head, including the face/orbits inferiorly (candidate ≈ filled parent in about 120 slices). At k = 40/44 no contour contains the whole anchor (98–99.9 % enclosed). The planned independent-2D brain-mask branch (EXP-010 to EXP-017) has reached a strong limitation without an accepted candidate. Phase 50 remains BLOCKED;
- EXP-018 (Phase 50, slice-to-slice propagation with marker-controlled watershed; inter-slice information authorized by the user, 2D operations only): PROMISING BUT PROBLEMATIC.
  - Solved: the central and superior slices give a brain-scale support with both hemispheres (IoU with EXP-012 at k = 60–133: 0.96 / 0.95; k = 136: 7,869 px versus 3,451 for EXP-012), consistent between `pn0` and `pn3`.
  - Not solved: below k ≈ 45 the mask drifts into the orbit, sinuses and face/neck and never stops, and near the vertex it lags behind the shrinking brain.
  - A pre-declared anti-drift rule is needed. Phase 50 remains BLOCKED;
- EXP-019 (Phase 50, as EXP-018 with erosion disk 5 and dilation disk 1): REJECTED. The mask collapses in both directions (non-empty only at k = 47–105 / 50–101; k = 91: 5,688 versus 18,204 px), because about a one-pixel rim is lost per slice: the excluded watershed ridge falls on the mask boundary when the background marker is only 1 px away. No further radius pair was tried. EXP-018 remains the best Phase-50 result;
- EXP-020 (Phase 50, EXP-019 with watershed ridge pixels assigned to the foreground): REJECTED.
  - Fixed: the collapse is gone (k = 91: 17,893 px), and there is no orbital drift at k = 40–46.
  - Not fixed: the 1-px growth limit loses support superiorly (k = 136: one hemisphere, 2,815 / 939 px), and `pn3` stops at k = 145. Inferiorly the mask is incomplete and partly dark (Otsu fraction about 0.34 at k = 1–39), and `pn0`/`pn3` are unstable.
  - The propagation is sensitive to the marker radii. EXP-018 remains the best result; choosing radii per direction would be post-hoc tuning and needs a user decision;
- EXP-021 (Phase 50, 3D erode → largest 3D component → 3D dilate on T1; exploratory exception authorized by the user, since 3D processing is not in the course PDF): technically ACCEPTABLE.
  - The largest 3D component contains the EXP-012 seed anchor in both conditions.
  - Central and superior slices are brain-scale with both hemispheres. At the skull base the mask includes the temporal lobes, cerebellum and brainstem without orbits, face or neck.
  - `pn0`/`pn3` IoU 0.985.
  - Limitations: thin vertex cortex is partly lost, surface-open CSF is excluded, and the spinal cord is included.
  - Adoption as the project brain mask is pending the user's decision.
  - 2026-10-06: the user **froze EXP-021 (r = 3)** as the Phase-50 candidate for the Phase-51 visual validation.
  - Robustness check with r = 2 and r = 4 (descriptive only, declared before the run): the largest 3D component is the brain for every radius and both noise levels. IoU with r = 3 is ≥ 0.967 and `pn0`/`pn3` IoU is 0.978–0.989. r = 4 leaves the ventricles unfilled at k = 91. r stays 3.
  - Phase 51: PASS WITH DOCUMENTED LIMITATIONS; Phase 52: applied to T2. EXP-021 is the operational development brain-support mask.

Lesion-segmentation experiments:

- EXP-022 (Phase 54, manually defined global T2 threshold, T_raw = 3400, T_norm = 3400/4095, strict `>`, inside EXP-021): REFERENCE ESTABLISHED.
  - The threshold was chosen from the Phase-40 histograms only, frozen before any candidate, and is the same for `pn0` and `pn3`.
  - Candidates: 70,866 voxels (4.20 % of the brain mask) in `pn0` and 42,046 (2.52 %) in `pn3`, a ratio of 0.60.
  - The candidates are mostly hyperintense structures anatomically compatible with CSF spaces (ventricles, cisterns), plus scattered small bright spots; no GT-based classification. `pn3` is less permissive and more speckled.
  - No GT metric was computed (comparison in Phase 57).
- EXP-023 (Phase 55, course iterative global threshold on T2(brainMask); same rule for both conditions): RESULT ESTABLISHED.
  - T_iter = 2323.13 (`pn0`, 2 updates) and 2421.88 (`pn3`, 39 updates) raw-equivalent.
  - Candidates: 50.25 % / 14.85 % of the brain mask.
  - The method converges correctly but splits the main intensity populations of the parenchyma (not a bright-population detector) and depends on the histogram shape; the same rule behaves very differently across noise conditions and does not compensate the intensity shift.
  - Comparison in Phase 57.
- EXP-024 (Phase 56, MATLAB graythresh/Otsu on T2(brainMask); same algorithm for both conditions): RESULT ESTABLISHED.
  - T_otsu = 2713.94 (`pn0`, 169/255) and 2408.82 (`pn3`, 150/255) raw-equivalent.
  - Candidates: 13.22 % / 15.43 % of the brain mask.
  - A meaningful two-class histogram split, but not lesion-specific; CSF-compatible structures are fully selected. The `pn0`/`pn3` fractions are closer than with EXP-022/023, but the thresholds differ by about 305 raw levels.
  - Comparison in Phase 57.
- EXP-025 (Phase 57, full-volume 3D Dice of the frozen EXP-022/023/024 predictions against GT label 10; DevelopmentScore = (Dice_pn0 + Dice_pn3)/2, no tie tolerance): **SELECTED INITIAL THRESHOLDING METHOD: EXP-024 Otsu** (0.028849; manual 0.027325, iterative 0.018026).
  - All Dice values are below 0.04, dominated by bright non-lesion structures compatible with CSF.
  - This is a development baseline, not the final pipeline.
- EXP-026 (Phase 58, `multithresh(T2(brainMask), 2)` + `imquantize`, candidate = highest of 3 classes; N and class fixed before results): **KEEP, current selected thresholding method** (DevelopmentScore 0.041545 versus 0.028849 for EXP-024; Dice 0.0404 / 0.0427).
  - Upper thresholds 2956.67 (`pn0`) / 2696.31 (`pn3`) raw-equivalent; Class 3 = 8.69 % / 8.08 % of the brain mask; candidates -34 % / -48 % versus Otsu.
  - GT retention drops to 3,035 / 2,952 of 3,512 (the rest in Class 2, none in Class 1). The candidates are still about 40x the GT volume, dominated by bright CSF-compatible structures.
  - This is still a development baseline, not the final pipeline.
- EXP-027 (Phase 59, 2D slice-wise local threshold T = m + b·s on masked local T2 statistics; pre-registered grid windowSize {9, 21, 41} × b {0.5, 1.0, 1.5}, a = 1): **REJECT**.
  - Best local configuration W21_B15 (DevelopmentScore 0.036103; Dice 0.0361 / 0.0362) is below EXP-026 (0.041545). EXP-026 remains the current selected thresholding method.
  - Uniform bright CSF is largely suppressed, but periventricular lesion voxels next to bright ventricles are lost (GT captured 2,211 / 2,138 versus 3,035 / 2,952), while thin bright sulcal/edge structures and, in `pn3`, scattered speckle become candidates.

Roadmap integration milestones (not experiments):

- Phase 60 (2026-10-10): the selected EXP-026 method was formalized as the canonical development `candidateMask` (`generateLesionCandidateMask`, `experiments/phase60_generate_candidate_mask.m`, outputs `data/processed/phase60_t2_{pn0,pn3}_candidate_mask.mat`). It reproduces the frozen EXP-026 masks and thresholds exactly (146,729 / 134,794 voxels). No GT, no new metric, no new experiment ID.

- EXP-028 (Phase 61, diagnostic error analysis of the Phase-60 candidateMask): **DIAGNOSTIC RESULT ESTABLISHED**.
  - FP 143,694 / 131,842: isolated 5–7 %, thin/edge-like (1–4 neighbours) about 40 %, fully surrounded about 25 %. FN 477 / 560 mostly on lesion borders; no single-pixel enclosed hole.
  - Dominant error: large fluid-like regions in the lesion intensity class, fused with periventricular lesions; unlikely to be solved by simple morphology alone. Erosion/opening and dilation are worth testing (none selected).
- EXP-029 (Phase 62, one 2D erosion / one 2D dilation with strel('square',3) on the Phase-60 candidateMask; probe, not a selection): **EFFECTS QUANTIFIED**.
  - Erosion: DevelopmentScore 0.035040 (Δ −0.0065); removes 75 % of the FP but 77 % of the lesion voxels (not FP-selective).
  - Dilation: 0.020238 (Δ −0.0213); recovers 80–87 % of the FN but adds about 190,000–198,000 FP.
  - The dense fluid-like regions persist. No morphology or structuring element selected; the Phase-60 mask is unchanged.
- EXP-030 (Phase 63, one 2D imopen with strel('square',3) on the Phase-60 candidateMask; provisional probe): **OPENING IMPROVES THE BASELINE** (DevelopmentScore 0.056845, +0.0153; Dice 0.0566 / 0.0570).
  - It removes about 50 % of the FP and all isolated voxels, but keeps only about 69 % of the TP: small lesions are lost (FN 477 → 1,405, 560 → 1,499).
  - The dense fluid-like regions are rebuilt. Not selected; evidence for Phases 65–66.
- EXP-031 (Phase 64, one 2D imclose with strel('square',3) after the EXP-030 opening; brain mask only after the complete closing): **EXP-030 REMAINS THE BEST OBSERVED MORPHOLOGY CANDIDATE**.
  - DevelopmentScore 0.056181 (−0.000665 vs opening). Closing adds 1,192 voxels per condition, 99 % FP, and recovers only 13 / 6 opening FN.
  - About 70 % of the opening FN have no opening neighbour (whole small lesions lost), and none of them is recovered. Not selected.
- EXP-032 (Phase 65, standard opening with 4 pre-registered SEs from the Phase-60 mask; one SE shared by pn0/pn3): **SELECTED DEVELOPMENT SE: square3** (0.056845).
  - diamond1 0.053937 (keeps more TP but many more FP), diamond2 0.051808, square5 0.037654 (loses about 72 % of TP).
  - The dense fluid-like regions persist with every SE. A development selection, not frozen; config.m is unchanged.
- EXP-033 (Phase 66, before/after comparison of the frozen Phase-60 vs Phase-65 masks): **THE SELECTED MORPHOLOGY BLOCK IS RETAINED FOR SUBSEQUENT DEVELOPMENT** (DevelopmentScore 0.041545 → 0.056845, better in both conditions).
  - It removes about 51 % of the FP (98.7 % of the removed voxels are FP), but FN rise by +928 / +939.
  - The dense fluid-like FP remain. This is a development-set comparison, not independent validation; the pipeline is not frozen.
- EXP-034 (Phase 67, bwconncomp with 8-connectivity on every axial slice of the Phase-65 masks; no GT, no properties, no filtering): **2D COMPONENTS IDENTIFIED**.
  - 1,210 (`pn0`) / 1,068 (`pn3`) slice-wise component instances, at most 20–21 per slice, in slices 12–144 / 28–144.
  - These are not unique lesions.
- EXP-035 (Phase 68, regionprops Area/Centroid/BoundingBox on the saved Phase-67 components; no GT, no filtering): **PROPERTY TABLE ESTABLISHED**.
  - 1,210 / 1,068 rows. Area is 9–1,332 / 9–1,328 with median 18 (strongly right-skewed); Area ≥ 9 follows from the square-3×3 opening.
  - This is the descriptive basis for Phase 69.
- EXP-036 (Phase 69, remove 2D components with Area == 9, keep Area > 9; Area only; masks frozen before GT): **PROVISIONALLY RETAINED FOR PHASE 70** (DevelopmentScore 0.056845 → 0.058101, better in both conditions).
  - It removes 345 / 303 instances (about 4 % of the voxels, 98.5–98.8 % FP), but also 36 / 42 lesion voxels.
  - It is not final; small-lesion protection is pending.
- EXP-037 (Phase 70, 2D GT-component audit of EXP-036 vs Phase 65; no size threshold): **SMALL-LESION PROTECTION FAILED → EXP-036 REJECTED**.
  - 3 (`pn0`) / 4 (`pn3`) GT cross-sections of 13–22 pixels, each represented only by one 3×3 square, lose all support.
  - The retained development pipeline reverts to the Phase-65 opening masks, with no component filtering.
- EXP-038 (Phase 71, assembly of the 181 axial slices of the retained Phase-65 prediction into the logical 181×217×181 volume M_pred): **REPRESENTATION ESTABLISHED**.
  - M_pred is exactly identical to the source. No GT, no metrics, no components.
- EXP-039 (Phase 72, `bwconncomp(M_pred, 26)` on the complete volume; a project-specific 3D extension of the course connected-component concept): **3D CANDIDATE COMPONENTS ESTABLISHED**.
  - 335 / 291 components (from 1,210 / 1,068 2D instances), about 51 % single-slice. The largest component has 25,629 / 25,417 voxels.
  - Exact reconstruction of `M_pred`. Not a lesion count.
- Phase 73 (region-growing decision, no experiment ID): **DO_NOT_INTRODUCE_REGION_GROWING**.
  - Incomplete extent is present, but the candidates are not high-confidence lesion cores (FP > TP; largest 3D candidate object > total GT lesion volume).
  - Phases 74–77 are skipped. Pipeline unchanged.
- EXP-040 (Phase 78, T1 / T2 / PD each alone, Class 1/2/3 of multithresh N = 2, square3 opening; 18 predictions frozen before GT): **BEST INDIVIDUAL MODALITY: T2 Class 3** (0.056845, identical to the Phase-71 M_pred).
  - PD Class 3: 0.016424 (Dice 0.007287 / 0.025561, strongly condition-dependent); T1 Class 3: 0.004280. No exact tie.
  - Pipeline unchanged; no fusion.
- Phase 79 (multimodal combination selection, no experiment ID; pre-registered rule: rank 1 = primary, rank 2 = secondary if it also has more TP than rank 3 in both conditions): **SELECTED PAIR T2 + PD**.
  - PD is chosen as the most justified potentially complementary source, not as a good standalone segmenter. T1 is not selected for the first pair but is not discarded.
  - No fusion rule, no multimodal prediction, no multimodal Dice. The canonical Phase-71 `M_pred` is unchanged. EXP-041 is reserved for Phase 80.
- EXP-041 (Phase 80, one predefined fusion rule `M_T2 AND M_PD` on the frozen Phase-78 masks; no GT): **FUSED DEVELOPMENT PREDICTION GENERATED**.
  - It keeps 70,849 / 61,740 of 70,878 / 67,066 T2 voxels (99.96 % / 92.06 %). In `pn0` the fusion is almost the identity on T2.
  - The large bright / fluid-like candidate structures are largely shared by T2 and PD and are therefore not removed (the declared risk; visual observation).
  - No performance claim; evaluation in Phase 81. Phase-71 `M_pred` remains canonical.
- EXP-042 (Phase 81, full-volume Dice of the frozen T2 and T2 AND PD predictions; pre-registered rule: candidate must have a strictly higher DevelopmentScore, exact tie → T2): **REJECT_MULTIMODAL_FUSION**.
  - DevelopmentScore 0.056472 vs 0.056845 (Δ −0.000374). The Dice change is +0.000022 in `pn0` and −0.000769 in `pn3`.
  - The fusion removed mostly FP (`pn3`: 5,149 FP, 177 TP), but the removed set is slightly richer in lesion voxels (3.32 %) than the Dice break-even (2.85 %).
  - The T2-only pipeline (Phase-71 `M_pred`) is retained. The multimodal stage is complete.
- EXP-043 (Phase 82, formal voxel-wise confusion counts with `computeVoxelConfusion`; convention rows = GT, columns = prediction, `[TN FP; FN TP]`): **EVALUATOR IMPLEMENTED AND VALIDATED** (synthetic 12/12, real 46/46).
  - `pn0`: TP 2,107 / FP 68,771 / FN 1,405 / TN 7,036,854. `pn3`: TP 2,013 / FP 65,053 / FN 1,499 / TN 7,040,572.
  - TP/FP/FN reproduce Phase 81 exactly. No derived metric.
- EXP-044 (Phase 83, `computeDiceFromConfusion` on the Phase-82 counts, Dice = 2TP / (2TP + FP + FN), project convention 0/0 → 1): **DICE FORMALIZED AND VALIDATED** (synthetic 16/16, real 36/36).
  - `pn0` 0.0566473988439306 (4,214 / 74,390); `pn3` 0.0570432712743348 (4,026 / 70,578).
  - Reproduces EXP-043 counts and the earlier T2 Dice. No other metric.
- EXP-045 (Phase 84, `computeIoUFromConfusion` on the Phase-82 counts, IoU = Jaccard = TP / (TP + FP + FN), project convention 0/0 → 1): **IoU FORMALIZED AND VALIDATED** (synthetic 16/16, real 34/34).
  - `pn0` 0.0291493158834027 (2,107 / 72,283); `pn3` 0.0293590024064756 (2,013 / 68,565).
  - Reproduces EXP-043 counts and satisfies IoU = Dice/(2 − Dice) with the Phase-83 values.
- EXP-046 (Phase 85, `computePrecisionFromConfusion`, Precision = TP / (TP + FP), project convention 0/0 → 1 without implying successful detection): **PRECISION FORMALIZED AND VALIDATED** (synthetic 16/16, real 34/34).
  - `pn0` 0.0297271367702249 (2,107 / 70,878); `pn3` 0.0300152088986968 (2,013 / 67,066).
  - About 97 % of the predicted-positive voxels are FP.
- EXP-047 (Phase 86, `computeRecallFromConfusion`, Recall = Sensitivity = TP / (TP + FN), project convention 0/0 → 1 without implying good predictions): **RECALL FORMALIZED AND VALIDATED** (synthetic 16/16, real 34/34).
  - `pn0` 0.5999430523918 (2,107 / 3,512); `pn3` 0.573177676537585 (2,013 / 3,512).
  - About 60 % / 57 % of the lesion **voxels** are recovered (voxel-wise, not lesion-wise). Low Precision + moderate Recall.
- EXP-048 (Phase 87, `computeSpecificityFromConfusion`, Specificity = TN / (TN + FP), project convention 0/0 → 1): **SPECIFICITY FORMALIZED AND VALIDATED** (synthetic 16/16, real 34/34).
  - `pn0` 0.990321611399419; `pn3` 0.990844858826634, i.e. about 99 % of the non-lesion voxels are rejected.
  - Severe class imbalance: this is not overall accuracy, and it coexists with Precision ≈ 3 % and Dice ≈ 0.057.
- EXP-049 (Phase 88, `computeBinaryMaskVolume` on M_GT only, spacing 1 × 1 × 1 mm from Phase 26): **GT LESION VOLUME FORMALIZED** (synthetic 14/14, real 27/27).
  - 3,512 voxels × 1 mm³ = **3,512 mm³** (3.512 cm³ = 3.512 mL), one value shared by `pn0` and `pn3`.
  - No prediction used.
- EXP-050 (Phase 89, the same `computeBinaryMaskVolume` on the Phase-71 `M_pred`, unchanged): **PREDICTED LESION VOLUME FORMALIZED** (36/36).
  - `pn0` 70,878 voxels → **70,878 mm³** (70.878 mL); `pn3` 67,066 voxels → **67,066 mm³** (67.066 mL).
  - This is the segmented volume (TP + FP). No comparison with V_GT.
- EXP-051 (Phase 90, `computeVolumeErrorPercent` on the EXP-049 / EXP-050 volumes in mm³, PROJECT_SPEC formula |V_pred − V_GT| / V_GT × 100): **VOLUME ERROR FORMALIZED** (synthetic 16/16, real 33/33).
  - `pn0` 1918.16628701595 % (+67,366 mm³); `pn3` 1809.62414578588 % (+63,554 mm³). Both are overestimations.
  - Values above 100 % are valid. This compares total volume only, not spatial overlap.
- EXP-052 (Phase 91, consolidation of the EXP-043..051 artifacts into `exp052_complete_3d_metrics.csv`; no new metric, 59/59): **PRIMARY COMPLETE-VOLUME 3D DEVELOPMENT TABLE ESTABLISHED**.
  - Pattern: moderate Recall, very low Precision / Dice / IoU, strongly overestimated volume, Specificity high because of class imbalance.
  - Phase 92 slice-wise metrics will be diagnostic only.
- EXP-053 (Phase 92, `computeSliceWiseMetrics` over all 181 axial slices, `pn0`/`pn3`; summed counts = Phase 91, 58/58): **SLICE-WISE DIAGNOSTIC PROFILE ESTABLISHED**.
  - FP are on 121 / 117 slices, about 62–64 % of them in k ≈ 70–104 (peaks k 92–95). 37 / 33 slices are prediction-only.
  - FN peak at k 97–103. 40 / 41 GT slices have prediction but no overlap.
  - The same pattern appears in `pn0` and `pn3`. Diagnostic only: no averages, no location rule.
- EXP-054 (Phase 93, 26-connected 3D objects, pre-registered rule "match iff ≥ 1 shared voxel", many-to-many; 59/59): **LESION-WISE OBJECT ANALYSIS ESTABLISHED**.
  - There are 59 GT lesions: 15 / 14 detected and 44 / 45 missed.
  - 4 of 335 / 291 predicted components are matched; 331 / 287 are false.
  - One merged predicted object (the largest Phase-72 component) touches 13 / 12 GT lesions and holds about 88–89 % of the TP.
  - The predicted components reproduce Phase 72, and the summed overlap equals the Phase-91 TP.
- EXP-055 (Phase 94, GT lesion size = 26-connected component voxel count; median threshold 7 voxels computed from GT sizes before the outcomes were read; SMALL ≤ 7 (31 lesions), LARGE > 7 (28); 38/38): **SIZE EXPLAINS THE FAILURE PARTLY**.
  - SMALL: detected 3 / 2, with about 5 % of their voxels covered.
  - LARGE: detected 12 / 12, coverage about 0.62 / 0.59, but 16 LARGE lesions are missed in both conditions.
  - The median is evaluation-only, not a segmentation threshold.
- EXP-056 (Phase 95, pre-registered 24-configuration grid, 48 predictions before GT, Phase-37 DevelopmentScore, no tolerance; 27/27): **SELECTED DEVELOPMENT CONFIGURATION P0_T2_M2_G1**.
  - It keeps the baseline (no filter, multithresh N = 2 Class 3, square-3 opening) and adds the removal of single-slice 3D components.
  - DevelopmentScore 0.058158 vs 0.056845 (+0.00131). FP −2,287 / −1,927, TP −14 / −14.
  - Components 335 → 165 / 291 → 143. GT lesion 16 is lost (only single-slice support).
  - The dominant FP problem is only marginally reduced. Superseded by EXP-057.
- EXP-057 (Phase 95, final development experiment, pre-registered 36-configuration grid, 72 predictions before GT; synthetic 19/19, main 27/27): **SELECTED DEVELOPMENT CONFIGURATION S2_TA_M2_G1**.
  - T2 multithresh (N = 2, highest class) re-estimated inside S2 = EXP-021 AND filled T1-high AND NOT T1-low; square-3 opening; single-slice 3D component removal.
  - Dice 0.661039 / 0.539029, DevelopmentScore 0.600034 vs 0.058158. FP 66,484 → 1,167 / 63,126 → 3,123.
  - GT lesions detected 19 / 28 of 59. S2 contains 3114 / 3058 of the 3512 GT voxels (Recall ceiling).
  - pn3 has 2.7× the FP of pn0: noise sensitivity is the main declared risk. Frozen as v1 (tag `v1-frozen`).
- Protocol amendment A1 (2026-10-14): development reopened for exactly one experiment (EXP-058); primary version fixed before held-out access.
- EXP-058 (amendment A1, 21 configurations, 42 predictions before GT; synthetic 16/16, main 27/27): **SELECTED F5_R0 = v2, PRIMARY; v1 SECONDARY**.
  - The v1 pipeline with anisotropic diffusion of T2 (explicit fixed parameters), without recovery.
  - Dice 0.669340 / 0.653000, DevelopmentScore 0.661169 vs 0.600034. The pn3 FP fall from 3,123 to 857.
  - Trade-off: pn3 lesion detection 28 → 16 (SMALL 6 → 1), Recall 0.697 → 0.603.
  - The morphological reconstruction R1/R2 is rejected (it restores connected FP; R2 leaks into S1).
  - Frozen as v2 (tag `v2-frozen`).
- Protocol amendment A2 (2026-10-14): EXP-059 is the final development experiment before the test; mandatory freeze afterwards; held-out cannot modify the frozen pipeline.
- EXP-059 (amendment A2, 12 configurations, 24 predictions before GT; synthetic 13/13, main 27/27): **SELECTED D3_M1_G0 = v3, PRIMARY; v2 and v1 secondary locked versions**.
  - The v2 base with 3D whole-volume anisotropic diffusion of T2 and a diamond-1 opening, without component filter.
  - Dice 0.68538 / 0.69440, DevelopmentScore 0.689892 vs 0.661169.
  - GT lesions detected 33 / 31 of 59 (v2 18 / 16); FP 1,406 / 1,085.
  - Next: Phase 96 freeze of v3, then the held-out test.

Code debugging, syntax fixes and checks that a MATLAB function works are not experiments and are not recorded in this log.

---

## 12. Experiments

Experiment entries are added below in chronological order, using the template in Section 5 with `###` as the heading level of each experiment.

### EXP-001 — Exploratory Gaussian smoothing (Phase 45)

#### Status

```text
COMPLETED
```

#### Date

```text
2026-10-05
```

#### Objective

```text
Determine whether a correctly implemented 2D slice-wise Gaussian filter produces a
measurable denoising effect on the noisy development volume (pn3), compared with the
otherwise identical unfiltered pipeline.
```

#### Hypothesis

```text
A mild Gaussian filter (sigma 0.5) should reduce the simulated noise of pn3 and bring it
closer to the noise-free pn0, at the cost of some blurring of edges.
```

#### Baseline / Reference

```text
Phase 42 unfiltered baseline (identity), prepared with Phase 43 + Phase 44.
Clean reference: pn0 normalized, unfiltered.
```

#### Dataset Configuration

```text
Case: msles2 (moderate)   Modality: T2   Resolution: 1 mm   RF/INU: rf0
Noise: pn0 (clean reference) and pn3 (noisy condition)
Ground truth: NOT used
```

#### Development or Test Data

```text
DEVELOPMENT (PROJECT_SPEC.md Section 19.1)
```

#### Input

```text
T2 MRI volumes only (pn0, pn3).
```

#### Processing Pipeline

```text
raw T2 -> loadBrainwebMri -> convertToWorkingClass (double) -> normalizeFixedRange (/4095)
       -> [branch A: no filter] / [branch B: gaussianFilterSlices]
```

#### Changed Component

```text
Branch B adds 2D Gaussian filtering applied slice by slice (imgaussfilt).
```

#### Parameters

```text
sigma: 0.5 pixel (exploratory Phase 45 reference, the imgaussfilt default; NOT tuned)
filter size: 3x3 (2*ceil(2*sigma)+1, the MATLAB automatic size, made explicit)
padding: replicate (the imgaussfilt default)
processing: 2D, each axial slice independently (no imgaussfilt3)
```

#### Implementation

```text
Main script: experiments/gaussian_smoothing_check.m
Functions:   src/io/loadBrainwebMri.m, src/preprocessing/convertToWorkingClass.m,
             src/preprocessing/normalizeFixedRange.m, src/preprocessing/gaussianFilterSlices.m
Config:      config.m (cfg.dataset.noisyMriFiles.pn3.T2, cfg.preprocessing.*)
```

#### Git Version

```text
Commit: e85e275
Working tree clean: NO (Phase 45 code and config changes not yet committed)
```

#### Execution

```text
MATLAB R2026b, Image Processing Toolbox R2026b
Execution result: SUCCESS (all validation checks PASS)
Warnings: none   Errors: none
```

#### Quantitative Results

Segmentation metrics are not evaluated, because there is no segmentation in this phase.

Preprocessing metrics (whole volume, normalized scale, reference `pn0` unfiltered):

```text
MSE pn3 unfiltered vs pn0:                 0.002653
MSE pn3 Gaussian vs pn0:                   0.002881   (+8.61 %)
Clean-reference distortion (pn0 G vs pn0): 0.000303
Scale fit: pn3 ~ 0.8689 * pn0 + 0.0238
Scale-matched MSE unfiltered:              0.000598
Scale-matched MSE Gaussian:                0.000427   (-28.61 %)
```

#### Lesion-Level Results

```text
Not evaluated.
```

#### Visual Results

```text
results/figures/phase45_gaussian_pn0_pn3_k091.png (central slice k = 91, chosen without GT)
The filter slightly reduces the visible grain of pn3. The difference image is concentrated
on edges (skull, scalp, ventricle borders) and on scattered background noise.
```

#### Comparison with Reference

```text
Raw MSE to pn0 increases (+8.6 %). Scale-matched MSE decreases (-28.6 %).
```

#### Interpretation

```text
A global affine fit (whole volume, background included) reduces the pn3-vs-pn0 MSE by
about 77 %: a large part of the raw discrepancy is explainable by a global gain/offset
mismatch between the two stored volumes. This is a diagnostic, not proof of a physical
cause.

After removal of the fitted affine mismatch, Gaussian smoothing with sigma 0.5 reduces the
residual complete-volume MSE from 0.000598 to 0.000427 (-28.61 %). Filtering the clean pn0
introduces an MSE of 0.000303, so smoothing also alters image structure. The two numbers
come from different comparisons and are not weighed against each other.

This establishes a measurable denoising effect, but does not decide whether the filter
should be retained. Structure preservation and parameter selection are deferred to
Phase 47.

The whole-volume MSE includes the background, because no brain mask exists yet.
```

#### Decision

```text
Decision: INVESTIGATE FURTHER

Reason:
A measurable denoising effect exists under scale-matched comparison, but sigma, filter
choice and lesion preservation are Phase 47 questions. No keep/drop decision is made.
```

#### Next Experiment

```text
Phase 46: median filtering under the same protocol.
```

#### Notes

```text
pn3 was downloaded for this experiment (development data); see
docs/BRAINWEB_DATASET_NOTES.md Section 13.22 and data/raw/msles2/DOWNLOAD_INFO.txt.
The global intensity-scale mismatch between pn0 and pn3 is relevant to all later
absolute-intensity parameters (open question 17 in the dataset notes).
```

### EXP-002 — Exploratory median filtering (Phase 46)

#### Status

```text
REJECTED
```

The experiment executed correctly; the median filter is not carried into Phase 47.

#### Date

```text
2026-10-05
```

#### Objective

```text
Evaluate whether a 2D slice-wise median filter deserves to remain a candidate for the
Phase 47 filter evaluation, compared with the identical unfiltered pipeline on pn3.
```

#### Hypothesis

```text
BrainWeb noise is Rayleigh (background) / Rician (signal), not impulse-like. A median
filter is therefore not expected to be well matched, and may remove thin structures.
```

#### Baseline / Reference

```text
Phase 42 unfiltered baseline (identity), prepared with Phase 43 + Phase 44.
Clean reference: pn0 normalized, unfiltered.
```

#### Dataset Configuration

```text
Case: msles2 (moderate)   Modality: T2   Resolution: 1 mm   RF/INU: rf0
Noise: pn0 (clean reference) and pn3 (noisy condition); existing files only
Ground truth: NOT used
```

#### Development or Test Data

```text
DEVELOPMENT (PROJECT_SPEC.md Section 19.1)
```

#### Input

```text
T2 MRI volumes only (pn0, pn3).
```

#### Processing Pipeline

```text
raw T2 -> loadBrainwebMri -> convertToWorkingClass (double) -> normalizeFixedRange (/4095)
       -> [branch A: no filter] / [branch B: medianFilterSlices]
```

#### Changed Component

```text
Branch B adds 2D median filtering applied slice by slice (medfilt2).
```

#### Parameters

```text
window: 3x3 (exploratory Phase 46 window; NOT tuned, only one window tested)
padding: symmetric (medfilt2 option; no artificial border values)
processing: 2D, each axial slice independently (no medfilt3)
decision rule, declared before the results: YES only if the scale-matched MSE decreases
and the figure shows no evident artefacts; otherwise NO
```

#### Implementation

```text
Main script: experiments/median_filtering_check.m
Functions:   src/io/loadBrainwebMri.m, src/preprocessing/convertToWorkingClass.m,
             src/preprocessing/normalizeFixedRange.m, src/preprocessing/medianFilterSlices.m
Config:      config.m (unchanged in this phase)
```

#### Git Version

```text
Commit: e85e275
Working tree clean: NO (Phase 45-46 code and documentation not yet committed)
```

#### Execution

```text
MATLAB R2026b, Image Processing Toolbox R2026b
Execution result: SUCCESS (all validation checks PASS)
Warnings: none   Errors: none
```

#### Quantitative Results

Segmentation metrics are not evaluated, because there is no segmentation in this phase.

Preprocessing metrics (whole volume, normalized scale, reference `pn0` unfiltered):

```text
Raw MSE pn3 unfiltered vs pn0:             0.002653   (affected by scale mismatch)
Raw MSE pn3 median vs pn0:                 0.003917   (+47.66 %)
Affine diagnostic (unfiltered pn3 only):   pn3 ~ 0.8689 * pn0 + 0.0238, reused for both branches
Scale-matched MSE unfiltered:              0.000598
Scale-matched MSE median:                  0.001111   (+85.97 %)
Clean-reference distortion (pn0 M vs pn0): 0.001236
```

#### Lesion-Level Results

```text
Not evaluated.
```

#### Visual Results

```text
results/figures/phase46_median_pn0_pn3_k091.png (central slice k = 91, chosen without GT)
The grain of pn3 is reduced, but thin bright structures (sulcal lines, thin scalp and skull
layers) are thinned or removed, giving a patchy appearance. The difference image is
concentrated on thin structures and edges.
```

#### Comparison with Reference

```text
Scale-matched residual MSE increases (+86 %). Raw MSE increases (+48 %).
```

#### Interpretation

```text
On this diagnostic metric, the net effect of the 3x3 median filter is an increase of the
residual error. The filter also substantially alters the noise-free pn0 (recorded
separately, not weighed against the pn3 result) and removes thin structures. This is
consistent with the mismatch between median filtering and the Rayleigh/Rician noise model.
```

#### Decision

```text
Decision: REJECT (MEDIAN CANDIDATE FOR PHASE 47 = NO)

Reason:
The pre-declared rule is not met (the scale-matched MSE increases), thin structures are
visibly removed, and the noise model is not impulse-like. This is not a ranking against
Gaussian smoothing and not the final preprocessing decision.
```

#### Next Experiment

```text
Phase 47: evaluation of filtering effects. The median filter is not carried forward.
```

#### Notes

```text
The smallest tested 3x3 neighborhood already substantially worsens the diagnostic metric
and visibly alters fine structures, so there is no experimental justification to test
larger neighborhoods. Larger neighborhoods would generally be expected to smooth more
strongly, but they were not tested.
Intensity harmonization (open question 17) remains unresolved; the affine fit is
diagnostic only.
```

### EXP-003 — Exploratory mean filtering (supplementary, before Phase 47)

#### Status

```text
REJECTED
```

The experiment executed correctly; the mean filter is not carried into Phase 47.

#### Date

```text
2026-10-05
```

#### Objective

```text
Evaluate whether a 2D slice-wise mean (moving-average) filter, an allowed course
technique, deserves to remain a candidate for Phase 47, under the Phase 45-46 protocol.
This is a supplementary experiment, not a roadmap phase.
```

#### Hypothesis

```text
A 3x3 mean filter should reduce the pn3 noise, but its equal weights give much stronger
smoothing than the Phase 45 Gaussian (sigma 0.5), so edges and thin structures may be
blurred noticeably.
```

#### Baseline / Reference

```text
Phase 42 unfiltered baseline (identity), prepared with Phase 43 + Phase 44.
Clean reference: pn0 normalized, unfiltered.
```

#### Dataset Configuration

```text
Case: msles2 (moderate)   Modality: T2   Resolution: 1 mm   RF/INU: rf0
Noise: pn0 (clean reference) and pn3 (noisy condition); existing files only
Ground truth: NOT used
```

#### Development or Test Data

```text
DEVELOPMENT (PROJECT_SPEC.md Section 19.1)
```

#### Input

```text
T2 MRI volumes only (pn0, pn3).
```

#### Processing Pipeline

```text
raw T2 -> loadBrainwebMri -> convertToWorkingClass (double) -> normalizeFixedRange (/4095)
       -> [branch A: no filter] / [branch B: meanFilterSlices]
```

#### Changed Component

```text
Branch B adds a 2D mean filter applied slice by slice (imfilter + fspecial('average')).
```

#### Parameters

```text
window: 3x3, equal weights 1/9 (exploratory; NOT tuned, only one window tested)
padding: replicate (as for the Phase 45 Gaussian)
processing: 2D, each axial slice independently
kernel centre weight: mean 0.1111 vs Phase 45 Gaussian 0.6193 (documentation only)
decision rule, declared before the results: YES only if the scale-matched MSE decreases
and the figure shows no evident artefacts; otherwise NO
```

#### Implementation

```text
Main script: experiments/mean_filtering_check.m
Functions:   src/io/loadBrainwebMri.m, src/preprocessing/convertToWorkingClass.m,
             src/preprocessing/normalizeFixedRange.m, src/preprocessing/meanFilterSlices.m
Config:      config.m (unchanged)
```

#### Git Version

```text
Commit: e85e275
Working tree clean: NO (Phase 45-46 and EXP-003 work not yet committed)
```

#### Execution

```text
MATLAB R2026b, Image Processing Toolbox R2026b
Execution result: SUCCESS (all validation checks PASS)
Warnings: none   Errors: none
```

#### Quantitative Results

Segmentation metrics are not evaluated, because there is no segmentation in this experiment.

Preprocessing metrics (whole volume, normalized scale, reference `pn0` unfiltered):

```text
Raw MSE pn3 unfiltered vs pn0:             0.002653   (affected by scale mismatch)
Raw MSE pn3 mean vs pn0:                   0.005031   (+89.68 %)
Affine diagnostic (unfiltered pn3 only):   pn3 ~ 0.8689 * pn0 + 0.0238, reused for both branches
Scale-matched MSE unfiltered:              0.000598
Scale-matched MSE mean:                    0.001802   (+201.51 %)
Clean-reference distortion (pn0 M vs pn0): 0.002412
```

#### Lesion-Level Results

```text
Not evaluated.
```

#### Visual Results

```text
results/figures/exp003_mean_pn0_pn3_k091.png (central slice k = 91, chosen without GT)
The grain is removed, but the image is visibly blurred. Thin sulcal lines and the thin
skull and scalp layers are smeared. The difference image is concentrated on edges and
thin structures.
```

#### Comparison with Reference

```text
Scale-matched residual MSE increases (+202 %). Raw MSE increases (+90 %).
```

#### Interpretation

```text
On this diagnostic metric, the net effect of the 3x3 mean filter is an increase of the
residual error, and the filter strongly alters the noise-free pn0 (recorded separately).
The 3x3 neighborhood is the smallest non-trivial odd square neighborhood for a uniform
mean filter; a 1x1 mean would be the identity operation and would provide no smoothing.

This concerns the mean filter at its own, much stronger, smoothing level. It is not a
ranking of filter families against the much milder Phase 45 Gaussian kernel.
```

#### Decision

```text
Decision: REJECT (MEAN CANDIDATE FOR PHASE 47 = NO)

Reason:
The pre-declared rule is not met (the scale-matched MSE increases by about 200 %), the
image is evidently blurred, and 3x3 is already the smallest non-trivial uniform mean
neighborhood (1x1 would be the identity). This is not the final preprocessing decision.
```

#### Next Experiment

```text
Phase 47: evaluation of filtering effects. Only Gaussian smoothing is carried forward
as a candidate; median (EXP-002) and mean (EXP-003) are not.
```

#### Notes

```text
Larger windows were not tested; there is no experimental justification for them.
Intensity harmonization (open question 17) remains unresolved; the affine fit is
diagnostic only.
```

### EXP-004 — Gaussian filter-effect evaluation (Phase 47)

#### Status

```text
COMPLETED
```

#### Date

```text
2026-10-05
```

#### Objective

```text
Decide whether the retained Gaussian candidate (sigma 0.5, 3x3, replicate) is a
reasonable CURRENT DEVELOPMENT preprocessing choice, or whether the pipeline should
remain unfiltered. No parameter optimization.
```

#### Hypothesis

```text
The filter reduces noise on pn3 but also attenuates edges and fine detail on pn0. Small
lesions may be visually affected.
```

#### Baseline / Reference

```text
Unfiltered pipeline (Phase 42 + 43 + 44). Clean reference: pn0 normalized, unfiltered.
```

#### Dataset Configuration

```text
Case: msles2 (moderate)   Modality: T2   Resolution: 1 mm   RF/INU: rf0
Noise: pn0 and pn3 (development)
Ground truth: loaded only AFTER all MRI-only processing, for contour figures only
```

#### Development or Test Data

```text
DEVELOPMENT (PROJECT_SPEC.md Section 19.1)
```

#### Input

```text
T2 MRI volumes only (pn0, pn3). The GT is not an input to any processing.
```

#### Processing Pipeline

```text
raw T2 -> loadBrainwebMri -> convertToWorkingClass -> normalizeFixedRange
       -> [A: no filter] / [B: gaussianFilterSlices sigma 0.5, 3x3, replicate]
```

#### Changed Component

```text
Branch B adds the 2D slice-wise Gaussian filter (same as EXP-001).
```

#### Parameters

```text
sigma 0.5, filter size 3x3, padding replicate (declared in Phase 45)
No sigma sweep, no change of size or padding.
```

#### Implementation

```text
Main script: experiments/filter_effect_evaluation.m
Functions:   src/io/loadBrainwebMri.m, src/io/loadBrainwebGroundTruth.m (contours only),
             src/preprocessing/convertToWorkingClass.m, normalizeFixedRange.m,
             gaussianFilterSlices.m
Config:      config.m (cfg.preprocessing.filter.method = "none" added after the decision)
```

#### Git Version

```text
Commit: e85e275
Working tree clean: NO (Phase 45-47 work not yet committed)
```

#### Execution

```text
MATLAB R2026b, Image Processing Toolbox R2026b
Execution result: SUCCESS (all checks PASS, including the EXP-001 reproduction)
Warnings: none   Errors: none
```

#### Quantitative Results

Segmentation metrics are not evaluated, because no predicted lesion mask exists.

```text
Raw MSE pn3 unfiltered / Gaussian vs pn0:   0.002653 / 0.002881
Affine diagnostic:                          pn3 ~ 0.8689 * pn0 + 0.0238 (diagnostic only)
Scale-matched MSE unfiltered / Gaussian:    0.000598 / 0.000427   (-28.61 %)
Clean-reference distortion (pn0):           0.000303
Detail energy pn0 unfiltered / Gaussian:    116061 / 79608
Detail retention on pn0:                    68.59 %
Detail energy definition: sum of squared first differences along X and Y inside each
slice (no Z)
```

#### Lesion-Level Results

```text
Not evaluated (no segmentation).
```

#### Visual Results

```text
results/figures/phase47_unfiltered_vs_gaussian_k091.png
results/figures/phase47_gt_contour_unfiltered_vs_gaussian.png
k = 91: on pn0 the filter changes every tissue boundary (up to about 0.14); on pn3 it
attenuates the grain.
GT contours at k = 102 / 76 (chosen automatically, figure only): the k = 102 lesions remain
clearly visible after filtering, with softer borders. The tiny k = 76 lesions cannot be
judged conclusively at figure resolution, either with or without the filter.
```

#### Comparison with Reference

```text
pn3: scale-matched error -28.6 %. pn0: 31.4 % of the detail energy removed.
```

#### Interpretation

```text
The trade-off is mixed: denoising on pn3 against detail loss on pn0, with an
inconclusive effect on the smallest lesions. Surrogate metrics cannot settle it.
Actual merging of binary regions can only be verified once segmentation masks exist.
```

#### Decision

```text
Decision: CURRENT PREPROCESSING FILTER = NONE (development choice, not final)

Reason:
Mixed evidence, plus PROJECT_SPEC.md Sections 8 and 20: the first segmentation baseline
uses minimal preprocessing, and "baseline + preprocessing" is a separate, measured step.
Phase 37 weighs pn0 and pn3 equally, so the net effect of the filter is a
segmentation-level question.

Gaussian sigma 0.5, 3x3, replicate is NOT rejected. It is the validated candidate for
the first "baseline + preprocessing" experiment, to be decided with the Phase 37 rule.
```

#### Next Experiment

```text
First segmentation-level experiments after the brain-mask phases (48-52) and the
segmentation baseline (Phase 53); then "baseline + Gaussian" under the Phase 37 rule.
```

#### Notes

```text
No GT-derived intensity statistic was computed. The GT generated no mask, rule or
parameter. Open question 17 remains open. Phase 40 remains deferred.
```

### EXP-005 — Initial support mask with global Otsu threshold (Phase 49)

#### Status

```text
COMPLETED
```

#### Date

```text
2026-10-05
```

#### Objective

```text
Generate the first RAW binary brain/head-support mask with one automatic, MRI-derived
rule applied unchanged to pn0 and pn3.
```

#### Hypothesis

```text
A global Otsu threshold per volume separates the external background from the head. In
T2 the dark skull may leave a gap between a scalp ring and the brain.
```

#### Baseline / Reference

```text
None (first mask). No GT or anatomical labels are used as reference.
```

#### Dataset Configuration

```text
Case: msles2   Modality: T2   Resolution: 1 mm   RF/INU: rf0   Noise: pn0, pn3
Preprocessing: double + /4095, NO filter (Phase 47)
Ground truth / anatomical labels: NOT loaded
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
T2 MRI volumes only.
```

#### Processing Pipeline

```text
normalized T2 -> graythresh(volume(:)) -> scalar T -> imbinarize(slice, T) for every slice
              -> raw logical mask (no cleanup)
```

#### Changed Component

```text
New: initial support mask (src/segmentation/initialSupportMask.m).
```

#### Parameters

```text
None hand-set. T is computed automatically per volume (Otsu, 256-bin histogram).
pn0: T = 0.3059 (78/255)   pn3: T = 0.2941 (75/255)
```

#### Implementation

```text
Main script: experiments/initial_brain_mask_threshold.m
Functions:   src/segmentation/initialSupportMask.m, plus the loader and preprocessing functions
Config:      unchanged
```

#### Git Version

```text
Commit: e85e275
Working tree clean: NO (Phases 45-49 not yet committed)
```

#### Execution

```text
MATLAB R2026b. SUCCESS, all checks PASS (including mask == volume > T).
```

#### Quantitative Results

Segmentation metrics are not applicable.

```text
pn0: foreground 3,897,012 voxels (54.82 %), 181/181 non-empty slices
pn3: foreground 3,827,124 voxels (53.83 %), 181/181 non-empty slices
Foreground in k = 1 / k = 181: pn0 28,021 / 7,079; pn3 26,215 / 6,985
Cross-condition consistency (descriptive): IoU 0.9797, 1.11 % differing voxels
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/phase49_histograms_otsu_threshold.png
results/figures/phase49_raw_masks_deterministic_slices.png (k = 1, 46, 91, 136, 181; mask only)

- No external background speckles on the shown slices.
- Scalp ring + unmasked skull gap + filled brain at k = 91 and 136, i.e. a head-support mask.
- Face and neck tissue and air/sinus holes at k = 1 and 46.
- Many small noise holes inside tissue in pn3.
- Bar-shaped phantom artefact above the head at k = 181 (BrainWeb FAQ: "strange stuff
  above the head").
```

#### Comparison with Reference

```text
Not applicable.
```

#### Interpretation

```text
The automatic global threshold separates the background well, but the raw output is a
head-support mask. Whether it can become an intracranial brain mask depends on the
Phase 50 cleanup choices (component selection versus hole filling).
```

#### Decision

```text
Decision: KEEP as the RAW Phase 49 output. It is not a validated brain mask.
```

#### Next Experiment

```text
Phase 50: cleanup motivated by the observed issues (scalp ring, holes, top-slice artefact,
inferior non-brain tissue).
```

#### Notes

```text
No morphology, hole filling, connected components or manual edits. Open question 17
remains open; Phase 40 remains deferred.
```

### EXP-006 — Support-mask cleanup (Phase 50)

#### Status

```text
COMPLETED. Brain-mask goal: BLOCKED / NEEDS REFINEMENT.
```

#### Date

```text
2026-10-05
```

#### Objective

```text
Turn the raw EXP-005 head-support mask into a cleaner intracranial support candidate with
simple, justified 2D operations, using the same rule for pn0 and pn3.
```

#### Hypothesis

```text
The dark skull separates the scalp ring from the brain, so keeping the largest 2D component
per slice and filling its holes should isolate an intracranial support region.
```

#### Baseline / Reference

```text
EXP-005 raw masks, regenerated (thresholds 78/255 and 75/255 reproduced exactly).
```

#### Dataset Configuration

```text
T2, msles2, 1 mm, rf0, pn0 + pn3. No filter. No GT and no anatomical labels.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
Raw logical masks derived from the MRI only.
```

#### Processing Pipeline

```text
A: raw -> per slice: bwconncomp (8-conn) -> keep largest -> imfill holes
B: raw -> per slice: imopen strel('square',3) -> then as A   (run only after the trigger)
imfill is never applied to the raw mask.
```

#### Changed Component

```text
New: cleanSupportMaskSlices.m (2D cleanup).
```

#### Parameters

```text
Connectivity 8 (not tuned). B: a single 3x3 square opening (no sweep).
No area threshold, no slice range, no position rule.
```

#### Implementation

```text
Main script: experiments/brain_mask_cleanup.m
Functions:   src/segmentation/cleanSupportMaskSlices.m, initialSupportMask.m, plus the loader
             and preprocessing functions
Config:      unchanged
```

#### Git Version

```text
Commit: e85e275
Working tree clean: NO (Phases 45-50 not yet committed)
```

#### Execution

```text
MATLAB R2026b. SUCCESS, all checks PASS (reproduction, logical/size, voxel accounting).
```

#### Quantitative Results

```text
A, pn0: raw 3,897,012 -> clean 4,165,201 (58.59 %); removed 26,800; filled +294,989
A, pn3: raw 3,827,124 -> clean 4,160,417 (58.52 %); removed 26,659; filled +359,952
Components per slice (median/max): pn0 3/14, pn3 4/15
Cleaned consistency pn0 vs pn3: IoU 0.9982, 0.11 % voxels differing
B: opening changed 13,864 (pn0, 180 slices) / 71,763 (pn3, 181 slices) voxels;
   pn3 foreground 58.09 %
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/phase50_raw_vs_clean_masks.png
results/figures/phase50_candidateA_per_slice_diagnostics.png
results/figures/phase50_candidateB_masks.png

A: solid head discs at k = 46, 91, 136, because the scalp is connected to the brain through
   skull-ring gaps. Face and neck remain at k = 1. One top artefact bar remains at
   k = 170-181. pn3 noise holes are filled.
B: still head discs at k = 1, 46, 91. At k = 136 the brain is separated in pn0 but with a
   jagged, partly missing border; pn3 at the same slice remains a head disc (unstable).
```

#### Comparison with Reference

```text
Background clean, noise holes filled, but the scalp is not separated from the brain.
```

#### Interpretation

```text
Scalp-brain bridges through the skull ring are wider than a minimal opening can break.
Simple largest-component cleanup yields a conservative head-support mask, not an
intracranial mask.
```

#### Decision

```text
Decision: KEEP candidate A as a head-support mask candidate; REJECT candidate B
(no improvement, fragmentation, pn0/pn3 instability).
The brain-mask objective is BLOCKED / NEEDS REFINEMENT. A user decision is required
between accepting a head-support mask and declaring a new candidate (for example erosion
plus reconstruction).
```

#### Next Experiment

```text
Depends on the decision above. Phase 51 is not started.
```

#### Notes

```text
The top-slice BrainWeb artefact cannot be removed without a slice-range or position rule,
both of which are excluded. Phase 40 remains deferred; open question 17 remains open.
```

### EXP-007 — Erode → select → dilate support-mask separation (Phase 50, supplementary)

#### Status

```text
REJECTED
```

The experiment executed correctly; the method is not retained.

#### Date

```text
2026-10-05
```

#### Objective

```text
Test whether selecting the largest component BETWEEN erosion and dilation separates the
brain from the scalp, unlike candidate B, where the dilation of imopen could reconnect
regions before the selection.
```

#### Hypothesis

```text
A 3x3 erosion breaks the scalp-brain bridges; selecting before the dilation prevents
reconnection, and the AND with the raw mask prevents adding foreground.
```

#### Baseline / Reference

```text
EXP-006 candidate A (head-support mask); raw EXP-005 masks reproduced exactly.
```

#### Dataset Configuration

```text
T2, msles2, 1 mm, rf0, pn0 + pn3. No filter. No GT and no anatomical labels.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
Raw logical masks derived from the MRI only.
```

#### Processing Pipeline

```text
raw -> imerode strel('square',3) -> largest 8-conn 2D component -> imdilate strel('square',3)
    -> AND raw -> imfill holes      (per slice)
```

#### Changed Component

```text
Component selection moved between the erosion and the dilation. Same element as
candidate B, so no new parameter.
```

#### Parameters

```text
Connectivity 8; strel('square',3). No sweep.
Decision rule, declared before the results: replace A only if the central deterministic
slices show the scalp separated and an intracranial region retained, consistently for pn0
and pn3, without evident fragmentation.
```

#### Implementation

```text
Main script: experiments/brain_mask_erode_select.m
Functions:   src/segmentation/erodeSelectDilateSlices.m, cleanSupportMaskSlices.m,
             initialSupportMask.m
```

#### Git Version

```text
Commit: e85e275
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. SUCCESS, all checks PASS.
```

#### Quantitative Results

```text
pn0: foreground 4,106,241 (57.76 %; A 58.59 %); discarded after erosion 60,849; filled +301,374
pn3: foreground 4,034,949 (56.76 %; A 58.52 %); discarded after erosion 86,333; filled +408,656
Consistency pn0 vs pn3: IoU 0.9821, 1.03 % voxels differing
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/exp007_raw_A_exp007_masks.png
results/figures/exp007_area_per_slice.png

k = 1, 46, 91: still solid head discs (pn0 and pn3).
k = 136: brain separated in both conditions, but with a jagged, partly missing upper border
         (brain support lost).
Area per slice: equal to A almost everywhere. Separation only in isolated upper slices
(about k = 123-126, 132-134, 141-144), which differ between pn0 and pn3; scattered dips in
pn3. The top artefact remains.
```

#### Comparison with Reference

```text
Practically identical to A, except in a few isolated slices where support is lost.
```

#### Interpretation

```text
The scalp-brain bridges are at least 3 pixels wide, so a minimal erosion does not break
them. Where separation occurs, it is intermittent along z and removes brain support.
```

#### Decision

```text
Decision: REJECT. Candidate A remains the Phase 50 head-support candidate.
Simple threshold + components + opening + erosion/dilation are now shown to be
insufficient. Marker-controlled watershed (ALLOWED_TECHNIQUES.md Section 11) is justified
as EXP-008.
```

#### Next Experiment

```text
EXP-008: marker-controlled watershed for scalp-brain separation (to be designed).
```

#### Notes

```text
imreconstruct was deliberately not used: with a binary path still connecting brain and
scalp, reconstruction would restore the scalp.
```

### EXP-008 — Marker-controlled watershed brain/scalp separation (Phase 50, supplementary)

#### Status

```text
REJECTED
```

The experiment executed correctly; the method is not retained.

#### Date

```text
2026-10-06
```

#### Objective

```text
Determine whether a marker-controlled watershed on the MRI morphological gradient separates
the brain from the scalp/head periphery more reliably than binary morphology alone, while
preserving a conservative brain-support region.
```

#### Hypothesis

```text
The dark skull ring forms a gradient ridge between a brain marker and a peripheral marker,
so the watershed places the boundary at the brain/skull interface.
```

#### Baseline / Reference

```text
Candidate A (EXP-006) = head-support fallback; EXP-005 raw masks.
Both reproduced exactly (thresholds 78/255 and 75/255; A 4,165,201 and 4,160,417 voxels).
```

#### Dataset Configuration

```text
T2, msles2, 1 mm, rf0, pn0 + pn3. No filter. No GT and no anatomical labels.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
Normalized T2 slices, the raw Otsu mask and candidate A (all MRI-derived).
```

#### Processing Pipeline

```text
per slice:
  gradient = imdilate(I, ones(3)) - imerode(I, ones(3))
  brain marker = largest 8-conn component of imerode(raw AND A, strel('square',5))
  non-brain marker = ~A  OR  (A AND ~imerode(A, strel('square',5)))
  L = watershed(imimposemin(gradient, brainMarker | nonBrainMarker))
  candidate = imfill( (L == mode(L(brainMarker))) AND A, 'holes')
```

#### Changed Component

```text
New: watershedBrainMaskSlices.m (marker-controlled watershed).
```

#### Parameters

```text
Fixed and declared before the results: marker erosion 5x5 square (marker only), gradient
neighborhood 3x3, connectivity 8, watershed default connectivity. No sweep.
```

#### Implementation

```text
Main script: experiments/brain_mask_watershed.m
Functions:   src/segmentation/watershedBrainMaskSlices.m, cleanSupportMaskSlices.m,
             initialSupportMask.m
```

#### Git Version

```text
Commit: e85e275
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. SUCCESS, all checks PASS (markers disjoint, candidate within A, marker
inside candidate, reproduction of inputs).
```

#### Quantitative Results

```text
pn0: valid markers 181/181, overlap 0; candidate 4,027,308 (56.65 %); removed vs A 137,893;
     filled 0; 20 slices with area ratio to A < 0.95
pn3: valid markers 181/181, overlap 0; candidate 3,899,546 (54.85 %); removed vs A 260,871;
     filled 0; 39 slices with area ratio to A < 0.95
Consistency pn0 vs pn3: IoU 0.9671, 1.87 % voxels differing
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/exp008_area_ratio_per_slice.png
results/figures/exp008_pn0_markers_and_candidate.png
results/figures/exp008_pn3_markers_and_candidate.png
results/figures/exp008_gradient_watershed_lines.png

k = 136: separated marker; the watershed ridge follows a continuous brain/skull boundary
         (pn0 and pn3); coherent candidate, no EXP-007-type damage.
k = 46, 91: the 5x5 marker still includes the scalp ring connected to the interior, so the
            basin is the whole head and the candidate equals A.
k = 1: face/neck remain.   k = 181: the BrainWeb artefact remains (marker = artefact).
Separation only around k = 112-144 (intermittent), plus scattered pn3 slices around
k = 35-55 and 101.
```

#### Comparison with Reference

```text
Equal to A in most slices; a plausible separation only where the marker is valid.
```

#### Interpretation

```text
The watershed step works when given a valid brain marker. The failure is in the automatic
marker: scalp-brain bridges of about 5 px or more survive a 5x5 erosion in the central and
inferior slices.
```

#### Decision

```text
Decision: REJECT. A declared rejection condition is met: the brain marker remains a
whole-head marker in central slices.
Phase 50 remains BLOCKED / NEEDS REFINEMENT; candidate A remains the head-support fallback.
```

#### Next Experiment

```text
Not decided. Any further attempt needs a NEW, explicitly justified brain-marker definition
(not a tuned EXP-008).
```

#### Notes

```text
No erosion size, gradient or marker definition other than the declared ones was tried.
config.m and PROJECT_SPEC.md unchanged.
```

### EXP-009 — Reconstruction / regional-maxima foreground markers for the brain watershed (Phase 50, supplementary)

#### Status

```text
REJECTED
```

The experiment executed correctly; the method is not retained.

#### Date

```text
2026-10-06
```

#### Objective

```text
Replace ONLY the EXP-008 foreground-marker generator with the course scheme (opening and
closing by reconstruction, then regional maxima), to obtain internal markers.
```

#### Hypothesis

```text
Reconstruction-cleaned regional maxima give internal markers, and the unchanged watershed
then separates the brain from the scalp.

Prediction declared before the run: in T2 bright scalp layers also produce maxima, which
do not touch the 2-px shell and would be accepted.
```

#### Baseline / Reference

```text
EXP-008 (same non-brain marker, gradient and watershed), candidate A, EXP-005 masks; all
reproduced.
```

#### Dataset Configuration

```text
T2, msles2, 1 mm, rf0, pn0 + pn3. No filter. No GT and no anatomical labels.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
Normalized T2 slices, candidate A, and the EXP-008 non-brain marker.
```

#### Processing Pipeline

```text
per slice:
  J = imreconstruct(imerode(I, sq3), I, 8)
  K = imcomplement(imreconstruct(imcomplement(imdilate(J, sq3)), imcomplement(J), 8))
  maxima = imregionalmax(K, 8); keep components not touching the non-brain marker
  L = watershed(imimposemin(gradient3x3(I), markers | nonBrain))
  candidate = imfill( union(basins touched by markers) AND A, 'holes')
```

#### Changed Component

```text
Foreground-marker generator only. Basin selection changed from mode to union, as required
by the multiple-marker design.
```

#### Parameters

```text
Fixed: square 3x3 for reconstruction, connectivity 8; EXP-008 shell (square 5) and 3x3
gradient unchanged. No sweep.
```

#### Implementation

```text
experiments/brain_mask_reconstruction_markers.m
src/segmentation/reconstructionRegionalMaxMarkers.m
src/segmentation/markerWatershedUnionSlices.m
```

#### Git Version

```text
Commit: e85e275
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. SUCCESS, technical checks PASS.
```

#### Quantitative Results

```text
pn0: maxima 14,309 (retained 9,581; rejected 4,728); multiple markers in 181 slices;
     candidate 3,126,339 (43.98 %); removed vs A 1,038,862; filled +101,262;
     conflict slices 56; ratio < 0.95 in 159 slices
pn3: maxima 9,716 (retained 7,930; rejected 1,786); candidate 3,082,094 (43.35 %);
     removed vs A 1,078,323; filled +87,800; conflict slices 54; ratio < 0.95 in 160 slices
Consistency pn0 vs pn3: IoU 0.8385, 7.67 % voxels differing
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/exp009_pn0_markers_and_candidate.png
results/figures/exp009_pn3_markers_and_candidate.png
results/figures/exp009_area_ratio_per_slice.png

- Accepted markers include many peripheral scalp arcs (k = 46, 91, 136); the prediction is
  confirmed.
- The candidate is a fragmented mosaic of basins crossed by ridge lines. The area
  reduction is mostly ridges and uncovered basins, and the scalp ring persists at k = 46.
- k = 136 and about k = 128-146 revert to solid head discs: the EXP-008 success is lost.
- Face/neck (k = 1) and the artefact (k = 181) remain.
```

#### Comparison with Reference

```text
Worse than EXP-008 on the key criteria: scalp not removed, success region lost,
fragmentation, lower pn0/pn3 consistency.
```

#### Interpretation

```text
In T2, regional maxima occur both in CSF and in the bright scalp layers. A 2-px peripheral
shell cannot reject the scalp maxima. Union over hundreds of basins oversegments and
fragments the mask.
```

#### Decision

```text
Decision: REJECT. Multiple declared rejection conditions are met.
Phase 50 remains BLOCKED / NEEDS REFINEMENT; candidate A is the head-support fallback only.
No EXP-010 was started. A strategic decision is required: accept a head-support mask with
spec changes, or reconsider the brain-mask source modality (for example T1).
```

#### Next Experiment

```text
None until a methodological decision is made.
```

#### Notes

```text
The 54-56 "conflict" slices were unexpected given per-component minima imposition. They
are recorded but not investigated, since the experiment is rejected on other grounds.
```

### EXP-010 — T1 brain-mask feasibility (Phase 50, supplementary)

#### Status

```text
COMPLETED - PROMISING
```

#### Date

```text
2026-10-06
```

#### Objective

```text
Determine whether T1, used only as the brain-mask source modality, gives a raw intensity
separation between brain and scalp that is more favorable than T2.
```

#### Hypothesis

```text
In T1, skull and CSF are dark, so a broader dark band may separate the scalp from the
brain than in T2. This was an observation to verify, not an assumption.
```

#### Baseline / Reference

```text
T2 raw Otsu mask (EXP-005), regenerated with the same method; thresholds reproduced.
```

#### Dataset Configuration

```text
T1 (mask only), msles2, 1 mm, rf0, pn0 + pn3. T1 pn3 downloaded 2026-10-06 (official;
14,218,274 bytes; SHA-256 ac7c6136...d8b8fe; little-endian 0...4095).
No GT, no anatomical labels, no held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
T1 MRI volumes only (T2 masks only as structural reference).
```

#### Processing Pipeline

```text
T1 -> double -> /4095 -> no filter -> graythresh(volume(:)) -> same T on every slice
   -> RAW mask (no cleanup)
```

#### Changed Component

```text
Brain-mask source modality: T2 -> T1. Everything else is the Phase 49 baseline.
```

#### Parameters

```text
None hand-set. Otsu T computed automatically: pn0 0.2588 (66/255), pn3 0.2510 (64/255).
Component counting (8-conn) is diagnostic only.
```

#### Implementation

```text
experiments/brain_mask_t1_feasibility.m (reuses initialSupportMask.m unchanged)
config.m: only cfg.dataset.noisyMriFiles.pn3.T1 added; cfg.dataset.modality stays T2
```

#### Git Version

```text
Commit: e85e275
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. SUCCESS, all checks PASS (T1/T2 geometry, T2 reference reproduced,
mask = volume > T, data unchanged).
```

#### Quantitative Results

```text
T1 pn0: foreground 2,771,291 (38.98 %); 181/181 non-empty; components median 11, max 42;
        median largest / second-largest area 12,574 / 3,635
T1 pn3: foreground 2,727,314 (38.36 %); 181/181 non-empty; components median 16, max 50;
        median largest / second-largest area 12,444 / 3,509
T1 consistency pn0 vs pn3: IoU 0.9755, 0.96 % voxels differing
(T2 raw mask: about 54-55 % foreground)
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/exp010_pn0_t1_vs_t2_raw_masks.png
results/figures/exp010_pn3_t1_vs_t2_raw_masks.png
results/figures/exp010_t1_histograms_otsu.png

k = 91, 136: a broad, continuous dark band (skull + CSF) separates the scalp ring from a
             distinct brain object in T1; in T2 the band is a thin, broken line.
k = 46:      largely separated; anterior orbital region more complex.
k = 1:       face/neck are one mass (no improvement).
k = 181:     artefact remains.
pn0 and pn3 are qualitatively the same.
```

#### Comparison with Reference

```text
Central brain/scalp connectivity substantially reduced compared with T2 EXP-005.
```

#### Interpretation

```text
T1 contrast naturally separates the brain from the scalp in the central slices. A
subsequent cleanup still has to select the intracranial component and handle holes,
face/neck and the artefact.
```

#### Decision

```text
Decision: PROMISING. The T1 branch is justified for a later cleanup experiment, which is
NOT started. Phase 50 remains BLOCKED / NEEDS REFINEMENT; candidate A (T2) remains the
head-support fallback. T2 remains the lesion modality.
```

#### Next Experiment

```text
To be decided. Key question: does a simple automatic rule on the T1 raw mask select the
intracranial component consistently (all slices, pn0 and pn3)?
```

#### Notes

```text
Not a lesion-modality comparison, not multimodal lesion fusion. Open question 17 open;
Phase 40 deferred; Phase 51 not started.
```

---

### EXP-011 — T1 largest component + hole filling (Phase 50, supplementary)

#### Status

```text
COMPLETED - REJECTED AS FINAL PHASE-50 METHOD BUT CENTRAL T1 BRAIN/SCALP SEPARATION CONFIRMED
```

#### Date

```text
2026-10-06
```

#### Objective

```text
Determine whether the unchanged candidate-A rule (EXP-006: largest 8-connected component
per slice + hole filling), applied to the EXP-010 T1 raw mask, selects the intracranial
component consistently across slices and in both pn0 and pn3.
```

#### Hypothesis

```text
Because T1 separates scalp and brain with a broad dark band (EXP-010), the largest
component per slice may be the brain section. Known risk: at the volume extremes the
scalp/face component may be larger than the brain section.
```

#### Baseline / Reference

```text
EXP-010 T1 raw Otsu masks (thresholds 66/255 and 64/255 and foreground counts reproduced
exactly). T2 candidate A (EXP-006) is the head-support fallback.
```

#### Dataset Configuration

```text
T1 (mask only), msles2, 1 mm, rf0, pn0 + pn3. No GT, no anatomical labels, no held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
T1 MRI volumes only.
```

#### Processing Pipeline

```text
T1 -> double -> /4095 -> no filter -> graythresh(volume(:)) -> same T on every slice
   -> per slice: largest 8-connected component -> imfill(..., 'holes')
```

#### Changed Component

```text
Cleanup rule of EXP-006 candidate A applied to the T1 raw mask instead of the T2 raw mask.
```

#### Parameters

```text
Connectivity 8 (as in EXP-006). No opening, no area threshold, no position or
inter-slice rule, no 3D. Second-largest component area recorded as diagnostic only.
```

#### Implementation

```text
experiments/brain_mask_t1_largest_component.m
Reuses initialSupportMask.m and cleanSupportMaskSlices.m unchanged
(cleanSupportMaskSlices(rawMask, 8, [])). config.m not changed.
```

#### Git Version

```text
Commit: 742e04e
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. SUCCESS, all checks PASS (EXP-010 thresholds and raw foreground reproduced,
logical output of the same size, voxel accounting, input and raw data unchanged).
```

#### Quantitative Results

```text
T1 pn0: removed by selection 678,221; added by filling 472,005;
        candidate 2,565,075 voxels (36.08 %); 181/181 non-empty;
        median largest / second area 12,574 / 3,648; largest/second ratio median 3.92, min 1.020
T1 pn3: removed by selection 671,955; added by filling 491,195;
        candidate 2,546,554 voxels (35.82 %); 181/181 non-empty;
        median largest / second area 12,444 / 3,512; largest/second ratio median 4.15, min 1.001
Consistency pn0 vs pn3: IoU 0.9616, 1.4065 % voxels differing (EXP-010 raw: IoU 0.9755)
Voxel totals are a mixture of brain slices, head discs and artefact slices: NOT a brain volume.
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/exp011_t1_area_per_slice.png
results/figures/exp011_t1_pn0_cleanup_steps.png
results/figures/exp011_t1_pn3_cleanup_steps.png

k ~ 46-133:  brain section selected, scalp ring removed, filling closes ventricles/sulci
             (k = 46, 91 correct in pn0 and pn3).
k ~ 1-15:    face/neck selected and filled into a head disc (k = 1 pn0: 21,331 -> 27,754).
k ~ 37-44:   filling produces head-sized areas (k = 37 pn0: 17,779 -> 27,135).
k ~ 134-165: brain section and scalp ring of almost equal area (k = 134: 3,792 vs 3,694);
             k = 136: pn0 selects the scalp ring -> whole-head disc (3,493 -> 16,141),
             pn3 selects a small brain fragment (3,374 -> 3,413); k = 143 the opposite;
             k ~ 144-162 ring filled into a disc in both.
k ~ 16-36:   selected object differs between pn0 and pn3 in some slices
             (k = 36: 10,993 vs 6,457).
k ~ 170-181: BrainWeb artefact bar selected.
Post-hoc descriptive count (not a decision rule): filling adds <= 30 % in 136 (pn0) and
135 (pn3) slices.
```

#### Comparison with Reference

```text
Compared with T2 candidate A (whole-head disc in all slices), T1 gives a true brain
section in the central slices; at the extremes it reverts to head discs or the artefact.
```

#### Interpretation

```text
EXP-010 is confirmed: T1 contrast separates brain and scalp. The failure is the identity
rule: the largest component per slice is not the brain at the volume extremes and is
decided by a few pixels where brain and ring have similar areas.
Failure category B (automatic component identity at the volume extremes / across z),
not A (brain/scalp contrast) and not C (both).
```

#### Decision

```text
Decision: REJECTED AS FINAL PHASE-50 METHOD BUT CENTRAL T1 BRAIN/SCALP SEPARATION CONFIRMED.
The candidate is not adopted. Phase 50 remains BLOCKED / NEEDS REFINEMENT; candidate A (T2)
remains the head-support fallback. PROJECT_SPEC.md and config.m unchanged; T2 remains the
lesion modality.
```

#### Next Experiment

```text
Not started (no EXP-012). Strategic decision required: which automatic, GT-free rule
identifies the intracranial component across z? It must be declared before results.
```

#### Notes

```text
Open question 17 open; Phase 40 deferred; Phase 51 not started.
```

---

### EXP-012 — T1 topology-based nested-component selection (Phase 50, supplementary)

#### Status

```text
COMPLETED - PROMISING BUT INCOMPLETE
```

#### Date

```text
2026-10-06
```

#### Objective

```text
Determine whether a purely topological rule identifies the internal brain-support
component more reliably than global component size (EXP-011).
```

#### Hypothesis

```text
EXP-011 showed that T1 contrast already separates brain and scalp in the central slices;
the remaining problem is component identity. In a favorable slice the brain-like
foreground is a separate component completely enclosed by another foreground component
(the peripheral one). Enclosure is independent of global size, position and z.
```

#### Baseline / Reference

```text
EXP-011 (largest 8-connected component per slice + fill) on the same EXP-010 raw T1 masks
(thresholds 66/255 and 64/255 and raw foreground counts reproduced exactly).
```

#### Dataset Configuration

```text
T1 (mask only), msles2, 1 mm, rf0, pn0 + pn3. No GT, no anatomical labels, no held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
T1 MRI volumes only.
```

#### Processing Pipeline

```text
T1 -> double -> /4095 -> no filter -> graythresh(volume(:)) -> same T on every slice
   -> per slice: components C1..Cn (bwconncomp, 8-conn)
   -> for each Ci alone: enclosedRegion_i = imfill(Ci,'holes') AND NOT Ci   (enclosure test only)
   -> Cj nested in Ci (j ~= i) iff ALL pixels of Cj are in enclosedRegion_i (one parent enough)
   -> select the nested component with the largest area (ties: first in bwconncomp order)
   -> final imfill(selected,'holes')
   -> no nested component: EMPTY slice (no fallback)
```

#### Changed Component

```text
Component-selection rule only: largest of ALL components (EXP-011) -> largest of the
components that are completely enclosed by another component (EXP-012).
An automatic topology-based selection rule built from the allowed connected-component,
hole-filling and logical operations; not a separate course technique.
```

#### Parameters

```text
Connectivity 8 (imfill default 4-connected background). No area, ratio, enclosure or
overlap threshold; containment is binary. No position, centroid, bounding-box, slice-range,
inter-slice or 3D rule. No other morphology.
```

#### Implementation

```text
src/segmentation/selectNestedSupportComponentSlices.m (new)
experiments/brain_mask_t1_nested_components.m (new; reuses initialSupportMask.m unchanged)
config.m not changed.
```

#### Git Version

```text
Commit: 742e04e
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. SUCCESS, all checks PASS (input double in [0,1], EXP-010 reproduced,
8-connectivity, raw mask unchanged, selected component subset of raw mask,
candidate = fill(selected) per slice, empty output where no nested component,
input and raw data unchanged). GT and labels never loaded by the script.
```

#### Quantitative Results

```text
                                         pn0                 pn3
Slices with / without nested candidate   152 / 29            159 / 22
Enclosing components per slice med/max   1 / 2               1 / 2
Nested components per slice med/max      7 / 26              8 / 34
Median selected nested area              11,491              10,718
Same component as EXP-011                95 slices           94 slices
Different from EXP-011 (non-empty / all) 57 / 86             65 / 87
Added by final filling                   79,984              83,573
Candidate voxels                         1,536,369 (21.61 %) 1,516,701 (21.33 %)
First / last non-empty slice             1 / 164             1 / 169
No candidate: pn0 k = 18, 29-31, 33-36, 38, 161-163, 165-181
              pn3 k = 27, 29-36, 161, 170-181
pn0 vs pn3: IoU 0.9830, 0.3685 % voxels differing; candidate in both 150, only pn0 2
(k = 27, 32), only pn3 9 (k = 18, 38, 162-163, 165-169), neither 20.
Voxel totals are NOT a brain volume (truncated support, see below).
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/exp012_t1_area_per_slice.png
results/figures/exp012_t1_pn0_nested_steps.png
results/figures/exp012_t1_pn3_nested_steps.png
results/figures/exp012_t1_enclosure_relation.png
(+ scratch-only rendering of saved selections at k = 12, 40, 43, 44, 139, 143, 146, 150,
155, 158, used only to describe transitions)

k = 1:       face/neck mass NOT selected; a small enclosed component (105 / 104 px) is
             selected instead (not empty; anatomical identity not claimed).
k = 46, 91:  internal brain-like component nested and selected; ring excluded; same as
             EXP-011 in pn0 and pn3.
k = 136:     ring rejected in both conditions; both select the same internal object, one
             hemisphere (3,417 / 3,374 px); the other hemisphere is lost.
k = 181:     artefact not enclosed -> empty in both.
k ~ 45-134:  identical to EXP-011.
k ~ 134-160: intracranial foreground split into several nested components (mainly two
             hemispheres); only one kept; area falls from ~3,800 to 30 px. pn0/pn3 differ
             at k = 139 (5,605 vs 2,836) and k = 143 (4,166 vs 2,508). Empty from k = 161
             except 1-2 px specks.
k ~ 1-39:    internal tissue not enclosed: only small nested objects (105-485 px for
             k = 1-12; 2-78 px for k = 13-39) or nothing.
k ~ 40-44:   cerebellum-like component (~6,500 px) at k = 40-42; k = 43 pn0 6,583 vs pn3
             165 px; k = 44 one temporal-lobe-like component (~1,950 px).
No whole-head disc anywhere; scalp, face/neck mass and artefact never selected.
```

#### Comparison with Reference

```text
Versus EXP-011: same central result; no head discs, no face/neck mass, no artefact,
k = 136 consistent. But support is truncated to one nested component per slice at the
extremes, where EXP-011 selected wrong objects of large area.
```

#### Interpretation

```text
Topology solves component IDENTITY: the selected object is always an enclosed internal
component. The remaining limitation is COMPLETENESS: one component per slice truncates
the support where the intracranial foreground is several nested components (hemispheres
k >= ~134, cerebellum/temporal lobes k ~ 40-44); inferior slices (k <= ~39) have no
enclosed internal tissue; vertex slices are empty; a few transition slices differ between
pn0 and pn3 (k = 43, 139, 143).
```

#### Decision

```text
Decision: PROMISING BUT INCOMPLETE. Not adopted; missing slices not filled.
Phase 50 remains BLOCKED / NEEDS REFINEMENT; candidate A (T2) remains the head-support
fallback. PROJECT_SPEC.md and config.m unchanged; T2 remains the lesion modality.
```

#### Next Experiment

```text
Not started (no EXP-013). Open question for the user: whether, and by which pre-declared
rule, more than one nested component per slice may be kept, and how slices without
enclosure (inferior) should be handled.
```

#### Notes

```text
Open question 17 open; Phase 40 deferred; Phase 51 not started.
```

---

### EXP-013 — T1 immediate-parent sibling union (Phase 50, supplementary)

#### Status

```text
COMPLETED - REJECTED AS PHASE-50 CANDIDATE (hemispheric sibling recovery confirmed)
```

#### Date

```text
2026-10-06
```

#### Objective

```text
Determine whether adding the direct topological siblings of the EXP-012 anchor (all
direct children of the anchor's immediate enclosing parent) makes the brain-support
candidate more complete without reintroducing scalp, face/neck, artefact or head discs.
```

#### Hypothesis

```text
EXP-012 solved identity but kept one nested component per slice. Split brain-support
components (hemispheres, cerebellar/temporal parts) are siblings of the anchor under the
same immediate enclosing parent.
```

#### Baseline / Reference

```text
EXP-012 (saved selectedMask and candidate, reproduced exactly as the anchor).
```

#### Dataset Configuration

```text
T1 (mask only), msles2, 1 mm, rf0, pn0 + pn3. No GT, no anatomical labels, no held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
T1 MRI volumes only.
```

#### Processing Pipeline

```text
T1 -> double -> /4095 -> no filter -> graythresh(volume(:)) -> same T on every slice
   -> per slice: components (bwconncomp, 8-conn)
   -> enclosure: Ci encloses Cj iff ALL pixels of Cj in imfill(Ci,'holes') AND NOT Ci (= EXP-012)
   -> anchor = largest nested component (= EXP-012); no anchor -> EMPTY slice
   -> immediate parent of each nested Cj = enclosing component with the smallest
      enclosed-region area (tie: lowest bwconncomp index, recorded)
   -> select all Cj with immediateParent(Cj) == immediateParent(anchor)
   -> imfill each selected child individually -> union (union NOT filled)
```

#### Changed Component

```text
Selection rule only: one nested component (EXP-012) -> anchor + its direct siblings.
An automatic topology-based connected-component selection refinement built from the
allowed connected-component, hole-filling and logical operations; not a separate course
technique. Parent never in the output.
```

#### Parameters

```text
Connectivity 8 (imfill default 4-connected background). No area threshold of any kind
(sibling size, ratio, fraction of parent); area only orders enclosing parents.
No position, z, inter-slice or 3D rule. No other morphology. No fallback.
```

#### Implementation

```text
src/segmentation/selectSiblingSupportComponentsSlices.m (new; enclosure logic duplicated,
EXP-012 function unchanged)
experiments/brain_mask_t1_sibling_components.m (new; reuses initialSupportMask.m)
config.m not changed.
```

#### Git Version

```text
Commit: 742e04e
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. SUCCESS, all 32 checks PASS: EXP-010 reproduced; 8-conn; anchor identical
to EXP-012 selectedMask; filled anchor = EXP-012 candidate; selected children only direct
children (inside parent's enclosed region, in no other enclosed component's region);
parent never in candidate; candidate = union of individually filled children; empty
where no anchor; subsets of raw; data unchanged.
```

#### Quantitative Results

```text
                                         pn0                 pn3
Slices with / without anchor             152 / 29            159 / 22
Parent ties                              0                   0
Enclosing parents of anchor med/max      1 / 1               1 / 1
Direct children med/max                  7 / 26              7 / 34
Slices with siblings added               136                 143
Raw sibling area added                   44,478              48,655
Final area added over EXP-012            44,820              49,245
Union fill would add (not used)          0                   0
Candidate voxels                         1,581,189 (22.24 %) 1,565,946 (22.03 %)
First / last non-empty slice             1 / 164             1 / 169
Added area / added siblings by range (pn0 | pn3):
  k 1-39     3,559 / 232   | 3,921 / 352
  k 40-49    7,272 / 124   | 7,087 / 181
  k 50-133   7,472 / 531   | 7,178 / 568
  k 134-181  26,517 / 186  | 31,059 / 239
pn0 vs pn3: IoU 0.9851, 0.3327 % differing (EXP-012: 0.9830, 0.3685 %); candidate in
both 150, only pn0 2, only pn3 9, neither 20; direct-child count differs in 121 slices.
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/exp013_t1_area_per_slice.png
results/figures/exp013_t1_pn0_siblings_steps.png
results/figures/exp013_t1_pn3_siblings_steps.png
(predeclared diagnostic slices 1, 40, 43, 44, 46, 91, 136, 139, 143, 181)

Hierarchy: every anchor has exactly one enclosing component; direct children ~ all
             nested components of the slice.
k = 1:       parent = face/neck mass (excluded); 13 / 19 small children added
             (105 -> 227 / 104 -> 214 px).
k = 40:      parent = peripheral component that also contains lateral temporal-like
             tissue and orbital region; only small objects added (6,881 -> 7,279).
k = 43:      pn0 6,832 -> 7,268; pn3 cerebellum-like region is part of the parent,
             171 -> 534 px: discrepancy NOT reduced.
k = 44:      small anterior/lateral fragments only (1,987 -> 2,674; 1,959 -> 2,603).
k = 46:      central selection preserved + anterior orbital-region objects
             (11,656 -> 13,178; 11,437 -> 13,049).
k = 91:      practically unchanged (+13 / +10 px).
k = 136:     both hemisphere-like components recovered (3,451 -> 6,843; 3,413 -> 6,776);
             ring excluded; pn0/pn3 consistent.
k = 139/143: pn0/pn3 differences removed (5,895 vs 5,841; 4,369 vs 4,218).
k = 181:     empty (no anchor); artefact not introduced.
No whole-head disc; scalp ring, face/neck mass and artefact never selected.
```

#### Comparison with Reference

```text
Versus EXP-012: hemispheric completeness and pn0/pn3 consistency improved in the upper
slices (about 59-63 % of the added area is in k >= 134); but many small nested objects of
uncertain identity are added elsewhere, and k = 40-44 do not improve.
```

#### Interpretation

```text
Topological siblinghood recovers split hemispheres but is not specific: the same parent
encloses brain fragments and small unrelated objects (every anchor has one parent).
In inferior slices the missing brain-like tissue is 8-connected to the peripheral
component (it IS part of the parent), so no child-selection rule can recover it.
```

#### Decision

```text
Decision: REJECTED as the Phase-50 candidate (rejection condition: many small unrelated
nested objects; no k = 40-44 gain; k = 43 pn0/pn3 discrepancy remains). Positive finding
documented: hemispheric sibling recovery. No post-hoc sibling filter added.
Phase 50 remains BLOCKED / NEEDS REFINEMENT; candidate A (T2) remains the head-support
fallback. PROJECT_SPEC.md and config.m unchanged; T2 remains the lesion modality.
```

#### Next Experiment

```text
Not started (no EXP-014). Unsolved: (a) specificity of the sibling family without a
filter; (b) inferior brain-like tissue connected to the peripheral component.
Marker-controlled watershed on T1 is a possible later strategic option, NOT implemented.
```

#### Notes

```text
Open question 17 open; Phase 40 deferred; Phase 51 not started.
```

---

### EXP-014 — T1 marker-controlled watershed with topology-derived markers (Phase 50, supplementary)

#### Status

```text
COMPLETED - REJECTED
```

#### Date

```text
2026-10-06
```

#### Objective

```text
Determine whether a high-confidence internal T1 marker (EXP-012 anchor) can guide a
marker-controlled watershed on the original T1 gradient so that the selected basin
recovers split or connected intracranial support without scalp, face/neck, artefact or
head discs.
```

#### Hypothesis

```text
Pure topology is exhausted after EXP-013: in inferior slices brain-like tissue is
8-connected to the peripheral component, and component selection cannot split a connected
component. A watershed separates regions along gradient ridges. The EXP-012 anchor (not
the EXP-013 siblings) is used as the marker because it has better identity.
```

#### Baseline / Reference

```text
EXP-012 (anchor and candidate, saved) and EXP-013 (parent and candidate, saved).
EXP-008 = T2 watershed with an erosion-derived marker (different modality and marker).
```

#### Dataset Configuration

```text
T1 (mask only), msles2, 1 mm, rf0, pn0 + pn3. No GT, no anatomical labels, no held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
T1 MRI volumes only (normalized T1 for the gradient, raw T1 Otsu mask for the topology).
```

#### Processing Pipeline

```text
T1 -> double -> /4095 -> no filter -> graythresh(volume(:)) -> same T on every slice
   -> per slice: anchor = EXP-012 selection (no anchor -> EMPTY slice, no watershed)
   -> P = immediate parent (EXP-013 rule); filledParent = imfill(P,'holes')
   -> foreground marker = raw anchor (unchanged)
   -> non-brain marker = NOT filledParent
                         OR (P AND filledParent AND NOT imerode(filledParent, strel('square',3)))
   -> gradient = imdilate(I, ones(3)) - imerode(I, ones(3)) on the original normalized T1
   -> watershed(imimposemin(gradient, foreground OR non-brain))
   -> union of positive labels touched by the anchor (label 0 excluded)
      AND filledParent AND NOT non-brain -> imfill(...,'holes') once
```

#### Changed Component

```text
Region separation by marker-controlled watershed instead of component selection.
Specification clarification (decided with the user before the run, not tuning): the
boundary band is the OUTER edge of P only; the literal formula P AND NOT imerode(P) would
also mark edges around P's internal holes, contradicting the stated "outer boundary"
intent.
```

#### Parameters

```text
One predeclared configuration, no sweep: 8-connectivity; 3x3 morphological gradient;
strel('square',3) for the outer band; default watershed connectivity (8 in 2D).
No area threshold, no position/z/3D rule, no EXP-013 siblings appended.
```

#### Implementation

```text
src/segmentation/watershedFromTopologyMarkersSlices.m (new; topology logic duplicated,
EXP-012/013 unchanged)
experiments/brain_mask_t1_topology_watershed.m (new; reuses initialSupportMask.m)
config.m not changed.
```

#### Git Version

```text
Commit: 742e04e
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. SUCCESS, all checks PASS: EXP-010 reproduced; anchor = saved EXP-012
selectedMask; parent = saved EXP-013 parentMask; non-brain marker = independent
recomputation; marker overlap 0; gradient/watershed/selection/ridges recomputed
independently on the 10 diagnostic slices; candidate inside filled parent; empty where
no anchor; data unchanged.
```

#### Quantitative Results

```text
                                         pn0                 pn3
Slices with / without anchor             152 / 29            159 / 22
Parent ties / marker-overlap slices      0 / 0               0 / 0
Labels under anchor med/max; >1          1 / 1; 0            1 / 1; 0
Added by final filling                   0                   0
Candidate voxels                         2,296,618 (32.31 %) 2,280,974 (32.09 %)
Expanded / shrunk vs EXP-012 (slices)    148 / 0             153 / 0
Net gain vs EXP-012                      760,249             764,273
  k 1-39 / 40-49 / 50-133 / 134-181      76,166 / 118,715 / 408,955 / 156,413
                                         (pn3: 50,987 / 134,469 / 414,477 / 164,340)
Median EXP-014/EXP-012 area ratio        1.460               1.500
Median EXP-014/filledParent area ratio   0.814               0.816
First / last non-empty slice             1 / 164             1 / 169
pn0 vs pn3: IoU 0.9717, 0.9236 % differing (EXP-012 0.9830; EXP-013 0.9851).
Candidate in both 150, only pn0 2, only pn3 9, neither 20; expanded in both 142,
only pn0 6 (k = 2-3, 6-7, 27, 32), only pn3 11 (k = 1, 9, 18, 38, 162-163, 165-169).
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/exp014_t1_area_per_slice.png
results/figures/exp014_t1_pn0_watershed_steps.png
results/figures/exp014_t1_pn3_watershed_steps.png
(+ scratch-only tinted rendering at k = 3, 5, 8, 11, 13, 15, 46, 91, description only)

Mechanism:   ridge at the inner edge of the bright peripheral component; the dark band
             (skull + CSF in T1) has no marker and floods into the anchor basin.
k = 91:      smooth ellipse to the inner scalp edge (18,456 -> 22,601 px): successful
             central slice changed into a cavity disc.
k = 136/139/143: both hemispheres inside, together with the whole dark band
             (k = 136: 12,607 px ~ ring enclosed region 12,648); pn0/pn3 agree; ring excluded.
k = 40/43/44: basin over most of the filled parent (17,347 / 21,573 / 22,048 px pn0),
             temporal-like tissue included with peripheral tissue; k = 43 pn0/pn3 now
             similar (21,573 / 21,483).
k = 46:      leakage into lateral peripheral tissue and anterior region (11,656 -> 23,006).
k = 1:       pn0 105 px (localized); pn3 1,892 px.
k ~ 2-16:    face/neck flooding from small anchors: k = 5 8,370 (pn0) vs 2,464 (pn3);
             k = 11 19,850 / 19,738 (almost the whole head section); k = 13-15 ~3,500
             nasal/maxillary region.
k = 181:     empty; artefact not introduced.
```

#### Comparison with Reference

```text
Versus EXP-012/013: hemispheres included, but specificity lost everywhere (dark band in
all slices, face/neck inferiorly); pn0/pn3 consistency worse.
Versus EXP-008: opposite failure mode. EXP-008 failed on the foreground marker; EXP-014
has a good foreground marker centrally but an under-marked non-brain side.
```

#### Interpretation

```text
With only the outer edge of the parent as non-brain marker, the two-marker watershed
separates "cavity inside the peripheral component" from "periphery + outside", not brain
from non-brain. In k ~ 1-16 small anchors inside the face/neck mass flood that tissue.
Failure category B (watershed boundary leakage), with A (foreground-marker identity in
inferior slices) contributing.
```

#### Decision

```text
Decision: REJECTED. No retuning (no other band, gradient or marker). Phase 50 remains
BLOCKED / NEEDS REFINEMENT; candidate A (T2) remains the head-support fallback.
PROJECT_SPEC.md and config.m unchanged; T2 remains the lesion modality.
```

#### Next Experiment

```text
Not started (no EXP-015). Any redesign requires a separate methodological decision.
```

#### Notes

```text
Open question 17 open; Phase 40 deferred; Phase 51 not started.
```

---

### EXP-015 — T1 internal dark-background skeleton marker feasibility (Phase 50, supplementary)

#### Status

```text
COMPLETED - REJECTED (as raw background marker; central dark-band loop confirmed)
```

#### Date

```text
2026-10-06
```

#### Objective

```text
Determine whether a thin internal background marker can be generated automatically from
the existing T1 Otsu background inside the topological support of the EXP-012 anchor
(marker feasibility only; NO watershed).
```

#### Hypothesis

```text
EXP-014 showed that foreground-marker identity was not the primary problem: the leakage
came from the missing background marker in the internal dark band. Following the course
marker-controlled watershed workflow (dark pixels = background, thinned by
skeletonization), the skeleton of the internal Otsu background may lie in that band.
```

#### Baseline / Reference

```text
EXP-014 non-brain marker (outside filled parent + outer parent edge, no internal marker).
EXP-012 anchor and EXP-013 parent (saved, reproduced exactly).
```

#### Dataset Configuration

```text
T1 (mask only), msles2, 1 mm, rf0, pn0 + pn3. No GT, no anatomical labels, no held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
Raw T1 Otsu mask (EXP-010) and its topology only; T1 intensities only for display.
```

#### Processing Pipeline

```text
T1 -> double -> /4095 -> no filter -> graythresh(volume(:)) -> same T on every slice
   -> per slice: anchor (EXP-012), immediate parent P (EXP-013/014); no anchor -> empty
   -> filledParent = imfill(P,'holes'); filledAnchor = imfill(anchor,'holes')
   -> internalDark = filledParent AND NOT rawMask AND NOT filledAnchor
   -> internalBackgroundMarker = bwmorph(internalDark,'skel',Inf)
```

#### Changed Component

```text
New: skeletonized internal Otsu background as a candidate background marker.
No second threshold (the dark class is the existing EXP-010 Otsu background).
ALLOWED_TECHNIQUES.md section 6.8 added (bwmorph 'skel', narrowly scoped).
```

#### Parameters

```text
One fixed choice: bwmorph 'skel', Inf. No pruning, spur/endpoint removal, component
selection or size filter. 8-connectivity for foreground components; barrier diagnostic
with 4-connectivity (complement of the 8-connected skeleton line). No position/z/3D rule.
```

#### Implementation

```text
src/segmentation/internalDarkSkeletonMarkersSlices.m (new; topology logic duplicated,
EXP-012/013/014 unchanged)
experiments/brain_mask_t1_dark_background_marker.m (new; reuses initialSupportMask.m)
config.m and PROJECT_SPEC.md not changed.
```

#### Git Version

```text
Commit: 742e04e
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. SUCCESS, all 32 checks PASS: EXP-010 reproduced; anchor = saved EXP-012
selectedMask; parent = saved EXP-013 parentMask; internalDark and skeleton recomputed
independently; marker subset of internalDark; marker/anchor and marker/parent overlap 0;
empty marker where no anchor; data unchanged. No imimposemin/watershed called.
```

#### Quantitative Results

```text
                                         pn0                 pn3
Slices with / without anchor             152 / 29            159 / 22
internalDark pixels                      771,252             799,657
Skeleton pixels                          130,617             140,788
Skeleton px per anchor slice med/max     801 / 1,942         815 / 2,203
Skeleton components med/max              8 / 69              14 / 89
Anchor slices with empty skeleton        0                   0
Anchor / parent overlap slices           0 / 0               0 / 0
Barrier slices (anchor/parent separated) 152 (all)           159 (all)
Sibling area / separated by skeleton     44,478 / 44,478     48,655 / 48,655
Slices with separated sibling            136                 143
pn0 vs pn3: marker IoU 0.5988, 0.9580 % differing; marker in both 150, only pn0 2,
only pn3 9, neither 20; barrier agreement 150 / 150.
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/exp015_t1_marker_per_slice.png
results/figures/exp015_t1_pn0_marker_steps.png
results/figures/exp015_t1_pn3_marker_steps.png
results/figures/exp015_t1_marker_on_t1.png (marker diagnostic, NOT Phase-51 validation)

k = 91:      single closed loop in the brain/periphery dark band (1 / 3 comps, 675 / 680 px).
k = 136/139/143: peripheral dark-band loop present + network through the inter-hemispheric
             fissure and sulci of the non-anchor hemisphere; k = 136 other hemisphere
             (3,357 / 3,318 px) fully enclosed by marker; pn3 k = 139/143 siblings
             2,855 / 1,620 px enclosed.
k = 40-46:   dense networks (19-44 comps) through orbits, sinuses, nasal cavity and between
             cerebellum, temporal-like tissue and periphery.
k = 1:       network through face/neck dark regions (61 / 75 comps) around a 105 px anchor:
             unsuitable as non-brain marker.
k = 181:     empty (no anchor).
```

#### Comparison with Reference

```text
Versus EXP-014: provides the missing internal dark-band marker centrally (k = 91), but
also places marker around every other intracranial component and in face/neck cavities.
```

#### Interpretation

```text
Skeletonization preserves the holes of internalDark; every foreground object enclosed in
internalDark is a hole, so the skeleton always keeps a loop around it. Hence every
non-anchor foreground component inside the filled parent (siblings, second hemisphere,
temporal-like tissue) is enclosed by background marker: a structural property, not
chance. A future single-anchor watershed would be blocked from recovering them.
```

#### Decision

```text
Decision: REJECTED as a raw background marker. Positive finding: central dark-band loop.
Limiting problems: C) inter-intracranial skeleton branches (systematic, 100 % of sibling
area enclosed) and B) excessive irrelevant dark structures (face/neck, orbits, sinuses).
A separate pre-declared marker-selection rule would be required before any watershed
retry; not invented here. Phase 50 remains BLOCKED / NEEDS REFINEMENT.
```

#### Next Experiment

```text
Not started (no EXP-016). Requires a separate methodological decision.
```

#### Notes

```text
Open question 17 open; Phase 40 deferred; Phase 51 not started.
```
---

### EXP-016 — T1 Canny outer-brain-boundary feasibility (Phase 50, supplementary)

#### Status

```text
COMPLETED - PROMISING BUT PROBLEMATIC
```

#### Date

```text
2026-10-06
```

#### Objective

```text
Determine whether automatic 2D Canny on the original normalized T1 slices contains a
sufficiently continuous and structurally meaningful outer brain/periphery boundary to
justify a later boundary-based brain-mask method (edge feasibility only; no mask).
```

#### Hypothesis

```text
EXP-011..015 reduced the problem to explicit boundary identification: size/topology fail
at the extremes, watershed leaked (background marker too peripheral), the dark skeleton
is not specific. Edge detection is covered by the course and is justified now that an
experimentally observed problem requires explicit boundary information.
```

#### Baseline / Reference

```text
EXP-014 morphological gradient (same intensity transitions, not binary); EXP-012 anchor
and EXP-013 parent (reproduced) as diagnostic references only.
```

#### Dataset Configuration

```text
T1, msles2, 1 mm, rf0, pn0 + pn3. No GT, no anatomical labels, no held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
Normalized T1 slices only for edge generation; raw Otsu topology only for diagnostics.
```

#### Processing Pipeline

```text
T1 -> double -> /4095 -> no filter -> per slice [BW, thresh] = edge(I, 'Canny')
(raw edge map saved; anchor/parent only for diagnostics: filledParent domain, edge
counts on anchor/parent, 4-connected barrier test)
```

#### Changed Component

```text
New: automatic 2D Canny edge map as boundary information. ALLOWED_TECHNIQUES.md section
10: narrow EXP-016 note (no propagation, no 3D authorized).
```

#### Parameters

```text
One configuration: MATLAB automatic Canny thresholds (returned per slice, diagnostic
only). No manual thresholds, sigma or filter size; no sweep; no other detector; no
morphology, linking, pruning or contour selection. Barrier test 4-connectivity.
Optional closed-contour diagnostic not implemented (would need a selection rule).
```

#### Implementation

```text
src/segmentation/detectT1CannyEdgesSlices.m (new)
experiments/brain_mask_t1_canny_edge_feasibility.m (new; anchor/parent via the EXP-015
function, checked against saved EXP-012/013 masks)
config.m and PROJECT_SPEC.md not changed.
```

#### Git Version

```text
Commit: 742e04e
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. SUCCESS, all 18 checks PASS (EXP-010 reproduced; anchor = saved EXP-012;
parent = saved EXP-013; edges = independent edge(I,'Canny') on the 10 diagnostic slices;
data unchanged). No watershed, no mask, no inter-slice information.
```

#### Quantitative Results

```text
                                         pn0                 pn3
Edge pixels                              660,928             696,814
Edge px per slice med/max                4,038 / 4,864       4,088 / 7,182
Edge components med/max                  58 / 96             62 / 193
Largest edge component med/max           554 / 1,125         573 / 1,131
Auto low threshold median (min-max)      0.075 (0.00625-0.1) 0.075 (0.0125-0.1)
Auto high threshold median (min-max)     0.1875 (0.015625-0.25) 0.1875 (0.03125-0.25)
Edges in filledParent / on anchor /
  on parent / other inside               514,903 / 217,891 / 191,811 / 105,201
                                         (pn3: 521,372 / 216,448 / 190,911 / 114,013)
Barrier slices                           6 / 152 (k 1, 3, 5, 7, 10-11)
                                         7 / 159 (k 1, 3, 5, 7, 10-11, 132)
pn0 vs pn3: edge IoU 0.8028, 2.0894 % differing; barrier both 6, only pn3 1, neither 143.
Barrier test NOT informative for Canny: edge lines lie on anchor/parent pixels (e.g.
2,170 on the anchor at k = 91), so outer anchor and inner parent pixels share the dark
band between two contours even when contours are closed. Not redefined after the run.
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/exp016_t1_canny_per_slice.png
results/figures/exp016_t1_pn0_canny_steps.png
results/figures/exp016_t1_pn3_canny_steps.png
(edge diagnostics, NOT Phase-51 validation; + scratch-only enlarged pn0 rendering at
k = 40, 44, 91, 136, description only)

k = 91:      concentric contours (outer scalp, inner scalp/skull, outer cortex); cortical
             contour visually near-continuous but merged with sulcal invaginations;
             separate ventricular contours.
k = 136/139/143: outer cortical contour around both hemispheres + strong inter-hemispheric
             midline edges and dense sulcal edges (mixture).
k = 40/43/44: contours around each temporal-like and the cerebellar-like region, including
             edges against the bright tissue that Otsu had merged (new information); no
             single outer brain contour; orbital/sinus/muscle contours; temporal contours
             merge into lateral edges in places.
k = 46:      transition, same pattern, dense anterior contours.
k = 1:       facial/neck contours dominate; no intracranial boundary.
k = 181:     artefact bars outlined.
pn0 and pn3 qualitatively identical.
```

#### Comparison with Reference

```text
Same intensity transitions as the EXP-014 morphological gradient, but as binary one-pixel
contours usable topologically; at the base of the skull they separate tissue that the
binary Otsu topology could not.
```

#### Interpretation

```text
Useful boundary information exists (central/superior outer cortical contour; inferior
temporal/cerebellar contours) and is noise-stable, but it is embedded among many
competing contours and connected to internal edges; the superior midline splits the
interior. A contour-selection/completion method would be required.
```

#### Decision

```text
Decision: PROMISING BUT PROBLEMATIC. Limiting: C) excessive competing internal/head
contours, with D) superior midline ambiguity. Continuity not quantitatively confirmed
(barrier diagnostic uninformative for Canny). No mask produced. Phase 50 remains
BLOCKED / NEEDS REFINEMENT; PROJECT_SPEC.md and config.m unchanged.
```

#### Next Experiment

```text
Not started (no EXP-017). A contour-selection/completion method would need a separate
methodological decision.
```

#### Notes

```text
Open question 17 open; Phase 40 deferred; Phase 51 not started.
```

---

### EXP-017 — T1 Canny minimal-closing enclosing-contour candidate (Phase 50, supplementary)

#### Status

```text
COMPLETED - REJECTED
```

#### Date

```text
2026-10-06
```

#### Objective

```text
Determine whether the raw EXP-016 Canny map can be converted into an automatic
brain-support candidate by one 3x3 closing, independent filling of each connected edge
component, and selection of the smallest filled region containing the whole EXP-012
anchor (first Canny-derived candidate; EXP-016 was edge feasibility only).
```

#### Hypothesis

```text
Topological: trusted anchor ⊂ nearest closed enclosing contour (brain) ⊂ more peripheral
head contours; the smallest complete enclosure is the most local one. Course scheme:
detect edges -> link into contours -> represent boundaries.
```

#### Baseline / Reference

```text
EXP-016 raw Canny (saved, reproduced exactly); EXP-012 anchor (saved, reproduced);
EXP-012 candidate area and EXP-014 filled-parent area for descriptive comparison.
The EXP-016 barrier diagnostic is retired (unsuitable for raw Canny).
```

#### Dataset Configuration

```text
T1, msles2, 1 mm, rf0, pn0 + pn3. No GT, no anatomical labels, no held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
Normalized T1 (Canny); EXP-012 anchor as automatic internal reference.
```

#### Processing Pipeline

```text
T1 -> double -> /4095 -> per slice edge(I,'Canny') (EXP-016, unchanged)
   -> closedEdges = imclose(edges, strel('square',3))   (one closing, no thinning)
   -> no anchor -> EMPTY slice
   -> 8-connected components of closedEdges; each filled alone: imfill(Ei,'holes')
   -> enclosing iff ALL anchor pixels inside the filled region
   -> candidate = smallest enclosing filled region (tie: lowest index), used as is
   -> no enclosing region -> EMPTY slice
```

#### Changed Component

```text
Edge-to-region conversion: one 3x3 closing + independent component filling + smallest
full-anchor enclosure. ALLOWED_TECHNIQUES.md section 10: narrow EXP-017 note.
```

#### Parameters

```text
One configuration: strel('square',3), one imclose; 8-connectivity; no area, ratio or
coverage threshold; no Otsu or parent constraint; no morphology after selection; no
position/z/3D rule. Risk declared before the run: Canny lines over anchor pixels may
make full containment fail; bestCoverage recorded as description only.
```

#### Implementation

```text
src/segmentation/selectCannyEnclosingBrainCandidateSlices.m (new)
experiments/brain_mask_t1_canny_enclosing_contour.m (new)
config.m and PROJECT_SPEC.md not changed.
```

#### Git Version

```text
Commit: 742e04e
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. SUCCESS, all 24 checks PASS (EXP-010 and EXP-016 reproduced exactly;
anchor = saved EXP-012; single closing recomputed on every slice; candidate recomputed on
the 10 diagnostic slices; candidate contains the whole anchor; empty where no anchor or
no enclosure; data unchanged).
```

#### Quantitative Results

```text
                                         pn0                 pn3
Raw / closed edge pixels                 660,928 / 800,298   696,814 / 864,256
Added / removed by closing               139,370 / 0         167,442 / 0
Edge components raw -> closed (median)   58 -> 14            62 -> 15
Anchor slices / candidate / no enclosure 152 / 142 / 10      159 / 145 / 14
Enclosing regions med / max; ties        1 / 2; 0            1 / 3; 0
Slices with >= 2 enclosing regions       11                  10
Candidate voxels                         2,976,626 (41.87 %) 2,972,977 (41.82 %)
Candidate / anchor area median / max     1.76 / 27,339       1.78 / 13,131.5
Candidate / EXP-014 filledParent median  1.002 (>= 0.9 in 119 of 142)
                                         1.003 (>= 0.9 in 119 of 145)
No enclosure: pn0 k = 2, 8-9, 12, 16, 27, 40-42, 44; pn3 k = 2, 8-9, 12, 14, 20-21,
40-42, 53, 165-167 (bestCoverage 0.977-0.999 at k = 2, 8, 9, 12, 40, 44 [, 53]).
pn0 vs pn3: IoU 0.9133, 3.7925 % differing; candidate both 137, only pn0 5, only pn3 8,
neither 31.
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/exp017_t1_canny_enclosing_per_slice.png
results/figures/exp017_t1_pn0_canny_enclosing_steps.png
results/figures/exp017_t1_pn3_canny_enclosing_steps.png
(development diagnostics, NOT Phase-51 validation)

k = 91:      only enclosing region 26,741 / 26,733 px = whole-head disc incl. scalp
             (filled parent 26,677); cortical-scale enclosure not selected.
k = 43/46:   whole-head discs incl. face/orbits (28,068 / 28,434 px pn0).
k = 40/44:   pn0 no enclosure (bestCoverage 0.998 / 0.994); pn3 k = 40 none, k = 44
             head disc 28,180 px.
k = 136/139/143: region inside the scalp ring (15,115 / 14,400 / 12,434 px pn0) with both
             hemispheres and the dark band; k = 139 includes a thin scalp-contour arc;
             pn3 similar.
k = 1:       local 111 px region around the anchor.
k = 181:     empty (no anchor).
```

#### Comparison with Reference

```text
Versus EXP-012: larger but at head-support scale, not brain scale. Versus EXP-014: the
candidate is about the filled immediate parent (median ratio 1.00), i.e. the head-support
mask that EXP-006 candidate A already provided in T2.
```

#### Interpretation

```text
The single 3x3 closing plus internal-edge connections fuse the concentric scalp, skull
and cortical contours and the sulcal edges into one component (median 1 enclosing
region), so independent filling returns the outermost loop. The nested-contour /
smallest-enclosure hypothesis is not supported. Where contours stay separate, full
containment fails by a few anchor pixels (declared risk).
```

#### Decision

```text
Decision: REJECTED. Primary failure C (scalp/head contour selected), mechanism F
(closing merges unrelated contours), with D (face/orbit inferiorly) and A (no full
enclosure at k = 40/44 despite 98-99.9 % coverage). The planned independent-2D
brain-mask branch (EXP-010..017) has reached a strong limitation without an accepted
candidate. No inter-slice method implemented. Phase 50 remains BLOCKED / NEEDS
REFINEMENT; PROJECT_SPEC.md and config.m unchanged.
```

#### Next Experiment

```text
Not started (no EXP-018). Requires a strategic methodological decision.
```

#### Notes

```text
Open question 17 open; Phase 40 deferred; Phase 51 not started.
```

---

### EXP-018 — T1 slice-to-slice propagation with marker-controlled watershed (Phase 50, supplementary)

#### Status

```text
COMPLETED - PROMISING BUT PROBLEMATIC
```

#### Date

```text
2026-10-06
```

#### Objective

```text
Determine whether propagating a reliable central brain-support mask slice by slice
(markers from the adjacent accepted mask + T1 watershed) gives a brain-scale support in
all brain-bearing slices.
```

#### Hypothesis

```text
EXP-010..017: one 2D slice lacks the information to separate brain and head contours at
the volume extremes. The brain is continuous along z and the central EXP-012 slices are
reliable; markers placed tightly around the neighbour's mask prevent the EXP-014 leakage
and the EXP-017 head-level selection.
```

#### Baseline / Reference

```text
EXP-012 (seed, central reference), EXP-014 (cavity-scale), EXP-017 (head-scale).
Inter-slice information explicitly authorized by the user on 2026-10-06
(ALLOWED_TECHNIQUES.md section 10 note); 2D operations only; propagation scheme is a
project design decision, not a verified course technique.
```

#### Dataset Configuration

```text
T1, msles2, 1 mm, rf0, pn0 + pn3. No GT, no anatomical labels, no held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
Normalized T1; raw T1 Otsu topology only to choose the seed (EXP-011/012 agreement).
```

#### Processing Pipeline

```text
seed = argmax EXP-012 anchor area over slices where EXP-012 anchor == EXP-011 largest
       component; seed mask = EXP-012 candidate (pn0 and pn3: k = 75)
for k moving away from the seed, M = accepted mask of the neighbour toward the seed:
   fg = imerode(M, strel('disk',3,0))   (empty -> stop this direction)
   bg = NOT imdilate(M, strel('disk',3,0))
   g  = imdilate(I_k, ones(3)) - imerode(I_k, ones(3))
   L  = watershed(imimposemin(g, fg | bg))
   candidate_k = imfill(labels touched by fg AND NOT bg, 'holes')
```

#### Changed Component

```text
Inter-slice propagation of markers (new design element) with the EXP-014 watershed
machinery; no Otsu constraint.
```

#### Parameters

```text
One configuration: disk radius 3 for erosion and dilation, declared before the run from
the slice-to-slice change of the EXP-012 equivalent radius at k = 46-133 (median ~0.4,
p90 ~1.2, max ~3.6 px); 3x3 gradient; default watershed connectivity. No sweep.
```

#### Implementation

```text
src/segmentation/propagateBrainMaskSlices.m (new)
experiments/brain_mask_t1_zpropagation.m (new)
config.m and PROJECT_SPEC.md not changed.
```

#### Git Version

```text
Commit: 742e04e
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. First run aborted by two script-check errors (input gate also evaluated
earlier pn0 checks -> misleading "EXP-010 not reproduced"; "inside dilated neighbour"
check ignored that imfill can fill a neighbour concavity closed by the dilation).
Checks corrected; algorithm and parameters unchanged. Second run: SUCCESS, all 26 checks
PASS (EXP-010 and anchor reproduced; seed is an agreement slice and equals the saved
EXP-012 candidate; fg/bg disjoint; outside dilated neighbour only by filling;
propagation recomputed on the diagnostic slices; stopped slices empty; data unchanged).
```

#### Quantitative Results

```text
                                         pn0                 pn3
Seed slice                               75                  75
Candidate voxels                         2,025,094 (28.49 %) 1,871,056 (26.32 %)
Non-empty slices; first / last           171; 1 / 171        174; 1 / 174
Stopped slices                           10                  7
Labels touched med / max                 1 / 4               1 / 3
Added by filling; outside dilated (sl.)  422; 59 (3)         138; 20 (1)
Otsu fraction in candidate, median       0.847               0.848
  k 1-39 / 40-59 / 60-133 / 134-150 / 151-181
                                         0.469 / 0.837 / 0.930 / 0.758 / 0.542
                                         (pn3: 0.546 / 0.841 / 0.925 / 0.754 / 0.478)
IoU with EXP-012, k = 60-133             0.9593              0.9488
pn0 vs pn3: IoU 0.8924, 3.1146 % differing; candidate in both 171, only pn3 3,
neither 7.
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/exp018_t1_zpropagation_per_slice.png
results/figures/exp018_t1_pn0_zpropagation_steps.png
results/figures/exp018_t1_pn3_zpropagation_steps.png
(development diagnostics, NOT Phase-51 validation)

k = 91:      18,204 / 17,998 px (EXP-012 18,456; EXP-014 22,601): brain-scale, no dark
             band, no head disc.
k = 136/139/143: both hemispheres, no scalp ring (7,869 / 6,926 / 5,440 px pn0;
             EXP-012 3,451 / 5,729 / 4,323; EXP-014 12,607 / 11,509 / 9,940); pn3 similar.
k ~ 151-171: smooth decrease to 0 but lag (Otsu fraction down to ~0.1 near k = 160).
k = 40-46:   candidate extends into the anterior orbital/sinus region
             (14,001 / 14,674 / 14,941 / 15,420 px pn0).
k = 1:       central face/neck tissue (7,171 / 2,997 px): inferior drift, no stop.
k = 181:     empty.
```

#### Comparison with Reference

```text
Best Phase-50 result in central and superior slices (brain-scale, both hemispheres,
no scalp, no dark band, pn0/pn3 consistent). Inferior slices worse than EXP-012 empty
slices: drift into non-brain tissue.
```

#### Interpretation

```text
z-continuity provides the identity and completeness that single slices lack. At the
skull base, soft tissue continuous with the brain lets the +-3 px band follow it down
into orbit/face/neck; the erosion-based stop never triggers. Near the vertex the mask
lags the shrinking brain.
```

#### Decision

```text
Decision: PROMISING BUT PROBLEMATIC. Central/superior solved; inferior drift and vertex
lag unsolved. Not adopted. A separate pre-declared anti-drift rule is required (not
invented here). Phase 50 remains BLOCKED / NEEDS REFINEMENT.
```

#### Next Experiment

```text
Not started (no EXP-019). Requires a user decision on an anti-drift rule.
```

#### Notes

```text
Open question 17 open; Phase 40 deferred; Phase 51 not started.
```

---

### EXP-019 — Asymmetric slice-to-slice propagation (Phase 50, supplementary)

#### Status

```text
COMPLETED - REJECTED
```

#### Date

```text
2026-10-06
```

#### Objective

```text
Determine whether asymmetric markers (strong erosion, minimal dilation) stop the EXP-018
inferior drift while preserving the central/superior result.
```

#### Hypothesis

```text
The seed is the largest section, so the brain shrinks away from it: allowing ~1 px growth
per slice blocks drift; erosion larger than the max observed EXP-012 equivalent-radius
change (~3.6 px/slice) lets the mask retreat.
```

#### Baseline / Reference

```text
EXP-018 (same scheme, radius 3 / 3); EXP-012.
```

#### Dataset Configuration

```text
T1, msles2, 1 mm, rf0, pn0 + pn3. No GT, no anatomical labels, no held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
As EXP-018.
```

#### Processing Pipeline

```text
As EXP-018 with fg = imerode(M, strel('disk',5,0)), bg = NOT imdilate(M, strel('disk',1,0)).
```

#### Changed Component

```text
Erosion/dilation radii only (declared before the run).
```

#### Parameters

```text
Erosion disk 5, dilation disk 1; everything else as EXP-018 (seed k = 75). No sweep.
```

#### Implementation

```text
experiments/brain_mask_t1_zpropagation_asymmetric.m (new; propagateBrainMaskSlices.m
unchanged)
```

#### Git Version

```text
Commit: 742e04e
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. SUCCESS, all 26 checks PASS.
```

#### Quantitative Results

```text
                                         pn0                 pn3
Candidate voxels                         457,151 (6.43 %)    392,781 (5.53 %)
Non-empty slices; first / last           59; 47 / 105        52; 50 / 101
Area k = 75 -> 76 -> 80 -> 90 -> 100     19,645 -> 19,132 -> 15,383 -> 6,529 -> 1,359
                                         (pn3: 19,598 -> 19,027 -> 14,983 -> 4,257 -> 165)
Area k = 70 -> 60 -> 50                  15,661 -> 6,237 -> 851 (pn3: 15,085 -> 4,087 -> 51)
k = 91: 5,688 / 3,723 px (EXP-018: 18,204 / 17,998). pn0 vs pn3 IoU 0.8303.
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/exp019_t1_zpropagation_per_slice.png
results/figures/exp019_t1_pn0_zpropagation_steps.png
results/figures/exp019_t1_pn3_zpropagation_steps.png
Collapse in both directions from the seed; all diagnostic slices except k = 75 and 91 empty.
```

#### Comparison with Reference

```text
Much worse than EXP-018 everywhere.
```

#### Interpretation

```text
Area lost per slice near the seed (-513 px from k = 75 to 76) ~ section perimeter
(~500 px): a one-pixel rim is lost per slice. The candidate excludes watershed ridge
pixels (label 0); with the background only 1 px outside the neighbour mask, the ridge
falls on the mask's boundary pixels. In EXP-018 the 3-px band left room for the ridge.
Interaction ridge exclusion x 1-px dilation, not anticipated when the radii were
declared; it does not test the asymmetric idea itself.
```

#### Decision

```text
Decision: REJECTED (systematic collapse). No further radius pair tried (would be a
sweep). EXP-018 remains the best Phase-50 result. Phase 50 remains BLOCKED.
```

#### Next Experiment

```text
Not started (no EXP-020). Any redesign (e.g. ridge-pixel assignment) needs a separate
decision.
```

#### Notes

```text
Open question 17 open; Phase 40 deferred; Phase 51 not started.
```

---

### EXP-020 — EXP-019 with watershed ridge pixels assigned to the foreground (Phase 50, supplementary)

#### Status

```text
COMPLETED - REJECTED
```

#### Date

```text
2026-10-06
```

#### Objective

```text
Determine whether assigning watershed ridge pixels to the foreground removes the EXP-019
collapse and lets the asymmetric propagation (erosion disk 5, dilation disk 1) stop the
EXP-018 inferior drift.
```

#### Hypothesis

```text
EXP-019 collapsed only because the excluded ridge fell on the mask boundary; with ridges
assigned to the foreground the asymmetric markers can work as intended.
```

#### Baseline / Reference

```text
EXP-018 (best result), EXP-019 (collapse), EXP-012.
```

#### Dataset Configuration

```text
T1, msles2, 1 mm, rf0, pn0 + pn3. No GT, no anatomical labels, no held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
As EXP-018/019.
```

#### Processing Pipeline

```text
As EXP-019, but candidate_k = imfill(NOT ismember(L, labels touched by bg) AND NOT bg)
(ridge pixels assigned to the foreground).
```

#### Changed Component

```text
Ridge-pixel assignment only. propagateBrainMaskSlices.m: optional ridgeAssignment
argument, default "exclude" (EXP-018/019 unchanged), "foreground" for EXP-020.
```

#### Parameters

```text
As EXP-019 (erosion disk 5, dilation disk 1, seed k = 75). No sweep.
```

#### Implementation

```text
experiments/brain_mask_t1_zpropagation_ridge_foreground.m (new)
src/segmentation/propagateBrainMaskSlices.m (optional argument added)
```

#### Git Version

```text
Commit: 742e04e
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. SUCCESS, all 26 checks PASS (independent recomputation uses the new
candidate definition).
```

#### Quantitative Results

```text
                                         pn0                   pn3
Candidate voxels                         1,415,004 (19.90 %)   1,217,131 (17.12 %)
Empty slices; last non-empty             20; 161               48; 145 (first 13)
Area k = 91 / 100 / 120 / 136 / 145      17,893 / 15,261 / 7,816 / 2,815 / 1,568
                                         (pn3: 16,766 / 13,339 / 4,525 / 939 / 248)
Area k = 60 / 50 / 46 / 40 / 20 / 5      15,992 / 11,074 / 9,856 / 7,658 / 2,104 / 629
                                         (pn3: 15,926 / 10,843 / 8,697 / 6,288 / 1,290 / 0)
Otsu fraction median k 1-39 / 60-133     0.340 / 0.933 (pn3: 0.348 / 0.926)
pn0 vs pn3: IoU 0.8296, 3.4479 % differing; both 133, only pn0 28, neither 20.
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/exp020_t1_zpropagation_per_slice.png
results/figures/exp020_t1_pn0_zpropagation_steps.png
results/figures/exp020_t1_pn3_zpropagation_steps.png
k = 91: brain-scale with a lateral notch; k = 136-143: one hemisphere only;
k = 40-46: cerebellum/brainstem-centred, no orbit, lateral temporal partly missing;
k = 1: small region (319 px pn0, empty pn3).
```

#### Comparison with Reference

```text
Versus EXP-019: collapse removed. Versus EXP-018: inferior orbital drift avoided, but
superior support lost and pn0/pn3 less stable.
```

#### Interpretation

```text
Ridge fix works; the 1-px growth limit cannot recover any lost region and the 5-px
erosion lets the watershed retreat onto internal edges (sulci, fissure). Propagation is
sensitive to marker radii: radius 3 drifts inferiorly, 5/1 loses support superiorly.
```

#### Decision

```text
Decision: REJECTED. EXP-018 remains the best Phase-50 result. No further variants;
direction-specific radii chosen from these results would be post-hoc tuning and need a
user decision. Phase 50 remains BLOCKED.
```

#### Next Experiment

```text
Not started (no EXP-021).
```

#### Notes

```text
Open question 17 open; Phase 40 deferred; Phase 51 not started.
```

---

### EXP-021 — 3D erode → largest 3D component → 3D dilate on T1 (Phase 50, exploratory exception)

#### Status

```text
COMPLETED - TECHNICALLY ACCEPTABLE AS PHASE-50 CANDIDATE (adoption pending user decision)
```

#### Date

```text
2026-10-06
```

#### Objective

```text
Determine whether the volumetric extension of the course skull-removal recipe (binarize ->
break skull/brain bridges -> largest region -> fill holes) gives an automatic brain
support over the whole volume.
```

#### Hypothesis

```text
In 3D the brain is one object linked to head tissue only through relatively thin bridges;
a 3D erosion breaks them, the largest 3D component is the brain, and dilation restores
it. This addresses directly the z-information lacking in EXP-010..017 and avoids the
artificial k-1 -> k -> k+1 propagation of EXP-018..020.
```

#### Baseline / Reference

```text
EXP-012, EXP-018 (best previous), EXP-020. Technique status: volumetric extension of 2D
course techniques; 3D processing is NOT treated in the course PDF (t1.nii exercise works
on a single layer; bwconncomp presented with 2D connectivity). Exploratory exception
authorized by the user on 2026-10-06 (ALLOWED_TECHNIQUES.md section 10).
```

#### Dataset Configuration

```text
T1, msles2, 1 mm isotropic, rf0, pn0 + pn3. No GT, no anatomical labels, no held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
EXP-010 T1 raw global-Otsu mask (reproduced).
```

#### Processing Pipeline

```text
rawMask -> imerode(rawMask, strel('sphere',3))          (3D)
        -> bwconncomp(eroded, 26) -> largest component  (3D)
        -> imdilate(core, strel('sphere',3)) AND rawMask (3D)
        -> imfill(...,'holes') slice by slice           (2D)
```

#### Changed Component

```text
3D morphology and 3D connected components (exploratory exception).
```

#### Parameters

```text
One configuration, declared before the run: sphere radius 3 (breaks connections up to
~7 voxels; T2 bridges >= 3 px in EXP-007, ~5 px in EXP-008; T1 dark band wider),
26-connectivity, largest component. No sweep. Declared risk: largest component could be
neck/face; the component holding the EXP-012 seed anchor recorded as diagnostic only.
```

#### Implementation

```text
src/segmentation/brainMask3DErodeSelectDilate.m (new)
experiments/brain_mask_t1_3d_erode_select_dilate.m (new)
config.m and PROJECT_SPEC.md not changed.
```

#### Git Version

```text
Commit: 742e04e
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. SUCCESS, all 20 checks PASS (EXP-010 reproduced; 3D erosion and 26-conn
components recomputed; core = largest 3D component; candidate = 2D fill of dilated core
AND raw; data unchanged).
```

#### Quantitative Results

```text
                                         pn0                 pn3
Eroded voxels; 3D components             1,306,870; 263      1,227,539; 351
Largest / second / third                 1,015,104 / 287,327 / 2,146
                                         (pn3: 969,761 / 244,567 / 7,860)
Seed-anchor component rank               1 (= selected)      1 (= selected)
Restored / added by 2D fill              1,613,842 / 74,945  1,589,406 / 78,960
Candidate voxels                         1,688,787 (23.76 %) 1,668,366 (23.47 %)
Non-empty slices; first / last           160; 1 / 160        156; 1 / 156
Relative to T2 head support              0.405               0.401
IoU with EXP-012 / EXP-018 / EXP-020     0.861 / 0.792 / 0.710
                                         (pn3: 0.851 / 0.804 / 0.633)
pn0 vs pn3: IoU 0.9848, 0.3619 % differing.
Area k = 1/40/43/44/46/91/136/139/143/181 (pn0):
  98 / 9,922 / 10,403 / 10,622 / 11,539 / 18,196 / 6,563 / 5,572 / 4,012 / 0
```

#### Lesion-Level Results

```text
Not applicable.
```

#### Visual Results

```text
results/figures/exp021_t1_3d_area_per_slice.png
results/figures/exp021_t1_pn0_3d_steps.png
results/figures/exp021_t1_pn3_3d_steps.png
results/figures/exp021_t1_3d_orthogonal_views.png
(development diagnostics, NOT Phase-51 validation; + scratch-only rendering at
k = 8, 12, 16, 20, 25, 30, 35, 50, 155)

k = 91:      brain-scale, no scalp, no dark band.
k = 136-143: both hemispheres, no scalp ring.
k = 40-46:   temporal lobes, cerebellum, brainstem; no orbit/sinus/face; a few thin
             anterior structures at k = 46 (identity not claimed).
k = 8-35:    cerebellum, brainstem, spinal cord; temporal lobes from k ~ 25; no face/neck.
k = 1:       spinal cord only (98 px). k = 181: empty.
Vertex: fragmentary near the top (k = 155: 515 / 131 px); last slice 160 / 156.
Coronal: clean brain support incl. temporal lobes and brainstem (EXP-018 includes neck).
Mid-sagittal (fissure plane): gaps from surface-open CSF excluded by AND raw + axial fill.
```

#### Comparison with Reference

```text
Best Phase-50 candidate overall: as good as EXP-018 centrally/superiorly, much better at
the skull base and below (no face/neck), most stable across noise (IoU 0.985).
```

#### Interpretation

```text
The missing z-information is supplied directly by 3D connectivity; a radius-3 erosion is
enough to separate the brain from the remaining head tissue in BrainWeb T1. Cost: thin
vertex cortex partly lost; surface-open CSF excluded (brain-tissue support, not
intracranial cavity); spinal cord included.
```

#### Decision

```text
Decision: technically ACCEPTABLE as the Phase-50 brain-support candidate. Adoption is
pending the user's methodological decision because 3D processing is not in the course
PDF (adopt as documented volumetric extension, or report as tested exploration).
PROJECT_SPEC.md and config.m unchanged; Phase 51 not started.
```

#### Next Experiment

```text
None started. Next step depends on the adoption decision (Phase 51 visual validation of
the chosen candidate).
```

#### Notes

```text
Open question 17 open; Phase 40 deferred until Phases 51-52.
```

---

### EXP-022 — Manually defined global T2 threshold (Phase 54)

#### Status

```text
COMPLETED - REFERENCE ESTABLISHED (not a selected final method)
```

#### Date

```text
2026-10-09
```

#### Objective

```text
Establish an interpretable initial reference: what happens if lesion candidates are
defined by ONE manually chosen global upper-intensity threshold on unfiltered T2 inside
the validated EXP-021 brain support? Not an optimization.
```

#### Hypothesis

```text
None about optimality. Expected: a single global threshold will reveal the limits of
plain thresholding, in particular the bright ventricular CSF inside the brain support
and the pn0/pn3 intensity mismatch (open question 17).
```

#### Baseline / Reference

```text
Phase-53 baseline definition: lesionCandidateMask = brainMask AND (T2_norm > T).
```

#### Dataset Configuration

```text
T2, msles2, 1 mm, rf0, pn0 + pn3 (development only). EXP-021 masks per condition
(pn0 -> pn0, pn3 -> pn3). No GT, no labels, no held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
T2 pn0: data/raw/msles2/mri/t2_ai_msles2_1mm_pn0_rf0.raws
T2 pn3: data/raw/msles2/mri/t2_ai_msles2_1mm_pn3_rf0.raws
Masks:  data/processed/exp021_t1_{pn0,pn3}_3d_erode_select_dilate_candidate.mat
```

#### Processing Pipeline

```text
raw T2 -> double -> /4095 -> NO FILTER -> EXP-021 brainMask
       -> thresholdLesionCandidates(T2norm, brainMask, T_normalized)  (strict >)
       -> lesionCandidateMask
```

#### Changed Component

```text
First instantiation of the Phase-53 baseline with a manual threshold.
```

#### Parameters

```text
T_raw = 3400 ; T_normalized = 3400/4095 (exact) ; comparator ">" ; same T for pn0 and pn3.
Selection: Phase-40 brain-only T2 histograms only (phase40_brain_only_histogram_counts.csv,
columns pn0_T2 / pn3_T2). No unique common valley (pn3 valley ~3250, pn0 minimum ~3550,
pn0 step ~3430): 3400 chosen manually as one compromise between them. Frozen and
pre-registered (BRAINWEB_DATASET_NOTES.md section 13.33) before any candidate.
Disclosure: Phase-41 offline GT class statistics were known; not used, value not
adjusted toward or away from them. Exactly one threshold, no sweep.
```

#### Implementation

```text
experiments/exp022_manual_global_threshold_t2.m (uses src/segmentation/thresholdLesionCandidates.m)
```

#### Git Version

```text
Commit: 742e04e
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. All 31 checks PASS (threshold domain and exact equivalence; geometry,
finiteness and [0,1] range of T2; mask logical; output = brainMask & (T2norm > T); no
candidate outside the mask; inputs unchanged; saved masks reload identically; same T for
both conditions; no GT loader referenced in the script).
```

#### Quantitative Results

```text
                                         pn0                   pn3
Brain-mask voxels                        1,688,787             1,668,366
Candidate voxels                         70,866                42,046
Fraction of brain mask                   0.041963 (4.20 %)     0.025202 (2.52 %)
Fraction of whole volume                 0.0099683             0.0059144
Slices with candidates; first / last     141; 12 / 152         120; 12 / 146
Candidate raw T2 min / max               3401 / 4030           3401 / 4064
Candidate raw T2 mean / median           3790.5 / 3846         3578.1 / 3571
pn3 - pn0 brain fraction: -0.016761; pn3 / pn0 = 0.6006.
Descriptive only: no GT-based metric computed.
```

#### Lesion-Level Results

```text
Not computed (Phase 57 / evaluation phases).
```

#### Visual Results

```text
results/figures/exp022_manual_threshold_selection.png
results/figures/exp022_t2_pn0_candidate_overlay.png, exp022_t2_pn3_candidate_overlay.png
results/figures/exp022_t2_candidate_contact_sheet_pn0.png, ..._pn3.png

- Candidates are mostly large hyperintense structures anatomically compatible with CSF
  spaces (no GT-based classification): lateral ventricles (k ~ 71-101),
  third ventricle, fourth ventricle (k ~ 31-41), basal cisterns and the inter-hemispheric
  fissure (k ~ 61, 101-121).
- In addition, many small scattered bright spots along sulci and in the parenchyma.
- pn3: the same structures but less complete (speckled ventricles) and fewer candidates
  overall; more isolated single-pixel responses.
- No candidates near the vertex above k = 152 / 146, and none outside the brain support.
```

#### Comparison with Reference

```text
First lesion-candidate reference; to be compared with Phase 55 (iterative) and Phase 56
(Otsu) in Phase 57.
```

#### Interpretation

```text
The threshold selects predominantly hyperintense structures anatomically compatible
with CSF spaces (ventricles, cisterns); T2 hyperintensity alone is therefore not
lesion-specific. No TP/FP classification is made without GT. The common absolute threshold
behaves differently across noise conditions (pn3 candidates = 0.60 x pn0), consistent
with the downward pn3 intensity shift (open question 17). Not corrected.
```

#### Decision

```text
REFERENCE ESTABLISHED. Not kept or rejected as a final method; threshold not optimized
and not a project parameter (not in config.m).
```

#### Next Experiment

```text
Phase 55 - iterative thresholding (not started).
```

#### Notes

```text
No morphology, no connected-component analysis, no region growing, no multimodal use, no
GT, no held-out data. The threshold-selection figure title is cut at the edges (display
only).
```

---

### EXP-023 — Iterative global thresholding on brain-only T2 (Phase 55)

#### Status

```text
COMPLETED - RESULT ESTABLISHED (comparison deferred to Phase 57)
```

#### Date

```text
2026-10-09
```

#### Objective

```text
Behaviour of the course-style automatic iterative global threshold on brain-only T2
(development pn0 + pn3).
```

#### Hypothesis

```text
None about optimality. Observe what a data-derived two-class iterative split produces,
and how it reacts to the pn0/pn3 intensity difference (open question 17).
```

#### Baseline / Reference

```text
EXP-022 (manual T_raw = 3400), descriptive comparison only.
```

#### Dataset Configuration

```text
T2, msles2, 1 mm, rf0, pn0 + pn3; EXP-021 masks per condition. No GT, no labels, no
held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
brainValues = T2_norm(brainMask) per condition (never the zero-padded volume).
```

#### Processing Pipeline

```text
raw T2 -> double -> /4095 -> NO FILTER -> brainValues = T2_norm(brainMask)
   -> T0 = mean(brainValues)
   -> repeat: R_high = >= T, R_low = < T; T_next = (mu_low + mu_high)/2
      until abs(T_next - T) < 0.5/4095 (accept T_next); guard 1000 iterations
   -> thresholdLesionCandidates(T2_norm, brainMask, T_iter)   (strict >)
```

#### Changed Component

```text
Automatic iterative threshold estimation (instead of the manual EXP-022 value).
Course-source note: the written procedure recommends the average intensity as initial
value; the slide MATLAB example uses 0.5*mean. EXP-023 follows the written procedure.
```

#### Parameters

```text
Same rule for pn0 and pn3: T0 = mean; partition >= / <; T_next = (mu_low + mu_high)/2;
epsilon = 0.5/4095 (project choice: half a raw level; PDF uses 0.5 on im2double data);
maxIterations = 1000 (safety only). Not tuned. Final thresholds are algorithm outputs.
```

#### Implementation

```text
src/segmentation/estimateIterativeThreshold.m (synthetic check:
experiments/iterative_threshold_function_check.m, 19/19 PASS)
experiments/exp023_iterative_threshold_t2.m
```

#### Git Version

```text
Commit: 742e04e
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. All 41 checks PASS (inputs; T0 = mean; history re-verified per iteration
against the actual partitions; convergence before the guard; threshold finite in [0,1];
output = brainMask & (T2_norm > T_iter); no candidate outside mask; inputs unchanged;
history and masks reload identically; no GT loader referenced).
```

#### Quantitative Results

```text
                                         pn0                   pn3
T0 (raw-equivalent)                      2324.81               2102.41
T_iter (normalized / raw-equivalent)     0.567309 / 2323.13    0.591423 / 2421.88
Updates; final delta (raw)               2; 0.481              39; 0
Final mu_low / mu_high (raw)             1984.9 / 2661.3       1967.5 / 2876.3
Candidate voxels                         848,576               247,703
Fraction of brain / of volume            50.25 % / 11.94 %     14.85 % / 3.48 %
Slices with candidates; first / last     160; 1 / 160         154; 1 / 156
Candidate raw min / max / mean / median  2324/4030/2661.3/2460 2422/4064/2876.3/2742
T_iter pn3 - pn0 = +98.74 raw; T_iter - 3400 = -1076.87 (pn0), -978.12 (pn3).
EXP-022 candidate fraction: 4.20 % (pn0), 2.52 % (pn3).
```

#### Lesion-Level Results

```text
Not computed (Phase 57).
```

#### Visual Results

```text
results/figures/exp023_iterative_threshold_convergence.png
results/figures/exp023_iterative_threshold_histograms.png
results/figures/exp023_t2_{pn0,pn3}_candidate_overlay.png
results/figures/exp023_t2_candidate_contact_sheet_{pn0,pn3}.png

pn0: T_iter between the dominant narrow peak (~1859) and the second peak (~2420); half the
     brain support selected: large parenchymal regions of medium-high T2 intensity (visual
     observation, no anatomical labels), plus ventricles, cisterns, sulcal fluid.
pn3: slow rise over 39 updates to 2421.9 (above pn0); ventricles/cisterns plus fragmented,
     speckled medium-high-intensity parenchymal pixels, mostly along the outer brain surface.
Hyperintense structures compatible with CSF spaces fully selected in both conditions.
```

#### Comparison with Reference

```text
Thresholds ~1000 raw levels below EXP-022; candidate fraction 12x (pn0) and 5.9x (pn3)
larger. No method declared better (Phase 57).
```

#### Interpretation

```text
The course iterative threshold converges correctly, but the brain-only T2 distribution
does not satisfy well the implicit assumption of a bimodal separation useful for lesion
segmentation: in pn0 the method essentially splits the main intensity populations of the
parenchyma; in pn3 the noise strongly changes the convergence point and the candidate
fraction. The fixed point depends on the histogram shape (narrow peaks in pn0 vs
noise-broadened modes in pn3), so the same rule does not compensate the intensity shift.
2 vs 39 updates is not a convergence problem (both converge; history verified). Open
question 17 unresolved; no harmonization. Not rejected: comparison in Phase 57.
```

#### Decision

```text
RESULT ESTABLISHED - comparison deferred to Phase 57. Not kept/rejected as final method.
```

#### Next Experiment

```text
Phase 56 - Otsu thresholding (not started).
```

#### Notes

```text
No GT, no metrics, no tuning, no initial-threshold sweep, no filter, no morphology, no
connected components, no T1/PD intensity, no held-out data.
```

---

### EXP-024 — Otsu global thresholding on brain-only T2 (Phase 56)

#### Status

```text
COMPLETED - RESULT ESTABLISHED (final threshold-method comparison deferred to Phase 57)
```

#### Date

```text
2026-10-10
```

#### Objective

```text
Threshold and candidate segmentation produced by MATLAB's course-supported Otsu
(graythresh) applied automatically, as-is, to brain-only T2 (development pn0 + pn3).
```

#### Hypothesis

```text
None about optimality. Otsu always returns a two-class partition; the brain-only T2
distributions do not show a clearly bimodal separation attributable to a lesion class and
a non-lesion class (Phase 40), so the two classes may not correspond to the categories of
interest.
```

#### Baseline / Reference

```text
EXP-022 (manual 3400) and EXP-023 (iterative), descriptive comparison from saved CSVs.
```

#### Dataset Configuration

```text
T2, msles2, 1 mm, rf0, pn0 + pn3; EXP-021 masks per condition. No GT, no labels, no
held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
brainValues = T2_norm(brainMask) per condition (artificial zeros and full volume excluded).
```

#### Processing Pipeline

```text
raw T2 -> double -> /4095 -> NO FILTER -> brainValues = T2_norm(brainMask)
   -> T_otsu = graythresh(brainValues)   (once, unmodified)
   -> thresholdLesionCandidates(T2_norm, brainMask, T_otsu)   (strict >)
```

#### Changed Component

```text
Threshold estimator: MATLAB graythresh (Otsu).
```

#### Parameters

```text
None tuned. Same algorithm for pn0 and pn3; thresholds data-derived. Built-in behaviour:
graythresh uses an internal 256-bin histogram on [0,1] for double input, so T_otsu is a
multiple of 1/255 (observed 169/255 and 150/255); documented, not a tuning choice.
```

#### Implementation

```text
experiments/otsu_threshold_function_check.m (synthetic sanity check, 9/9 PASS)
experiments/exp024_otsu_threshold_t2.m
```

#### Git Version

```text
Commit: 742e04e
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. All 37 checks PASS (inputs; T_otsu finite real scalar in [0,1] and identical
when recomputed; output = brainMask & (T2_norm > T_otsu); no candidate outside the mask;
inputs unchanged; reload identical; no GT loader referenced).
```

#### Quantitative Results

```text
                                         pn0                    pn3
T_otsu (normalized / raw-equivalent)     0.662745 / 2713.94     0.588235 / 2408.82
Candidate voxels                         223,204                257,445
Fraction of brain / of volume            13.22 % / 3.14 %       15.43 % / 3.62 %
Slices with candidates; first / last     158; 2 / 160           155; 1 / 156
Candidate raw min / max / mean / median  2714/4030/3243.8/3130  2409/4064/2858.8/2721
T_otsu pn3 - pn0 = -305.12 raw.
T_otsu - EXP-022 (3400): -686.06 (pn0), -991.18 (pn3).
T_otsu - EXP-023: +390.81 (pn0), -13.05 (pn3).
Candidate fraction EXP-024 / EXP-022 / EXP-023: pn0 13.22 / 4.20 / 50.25 %;
pn3 15.43 / 2.52 / 14.85 %.
```

#### Lesion-Level Results

```text
Not computed (Phase 57).
```

#### Visual Results

```text
results/figures/exp024_otsu_threshold_histograms.png
results/figures/exp024_t2_{pn0,pn3}_candidate_overlay.png
results/figures/exp024_t2_candidate_contact_sheet_{pn0,pn3}.png

pn0: threshold above the second narrow peak (~2420), in the high-intensity tail;
     hyperintense structures compatible with CSF spaces (ventricles, cisterns, fissure)
     plus thin bright rims along the outer surface and sulci, small scattered spots.
pn3: threshold on the upper side of the broad second mode (close to EXP-023); CSF-compatible
     structures plus fragmented, speckled medium-high-intensity parenchymal pixels.
```

#### Comparison with Reference

```text
Between EXP-022 and EXP-023 in pn0; close to EXP-023 in pn3. pn0/pn3 candidate fractions
closer than with EXP-022/023, but thresholds differ by ~305 raw and the spatial character
differs. No method declared better.
```

#### Interpretation

```text
Otsu returns a meaningful two-class histogram split, but the brain-only T2 distributions
do not show a clearly bimodal separation attributable to a lesion class and a non-lesion
class (narrow populations in pn0, broad overlapping modes in pn3), so the two classes do
not necessarily match the categories of interest and the split is not lesion-specific; CSF-compatible structures are fully selected. The closer pn0/pn3
fractions are a property of the split, not a harmonization. Open question 17 unresolved.
```

#### Decision

```text
RESULT ESTABLISHED - final threshold-method comparison deferred to Phase 57.
```

#### Next Experiment

```text
Phase 57 - quantitative thresholding comparison (not started).
```

#### Notes

```text
No GT, no metrics, no tuning, no multithresh, no local thresholding, no filter, no
morphology, no connected components, no T1/PD intensity, no harmonization, no held-out data.
```

---

### EXP-025 — Quantitative thresholding-method comparison (Phase 57)

#### Pre-registration (written before any Dice value was computed)

```text
Candidates (frozen saved outputs, not regenerated):
  EXP-022 manual global threshold    data/processed/exp022_t2_{pn0,pn3}_manual_global_threshold_candidate.mat
  EXP-023 iterative global threshold data/processed/exp023_t2_{pn0,pn3}_iterative_threshold_candidate.mat
  EXP-024 Otsu global threshold      data/processed/exp024_t2_{pn0,pn3}_otsu_threshold_candidate.mat
GT: BrainWeb crisp msles2 (phantom_1.0mm_msles2_crisp.rawb, loadBrainwebGroundTruth),
    M_GT = (labels == 10), the same M_GT for pn0 and pn3; NOT intersected with brainMask.
Metric: full-volume 3D Dice = 2|P & G| / (|P| + |G|) on 181x217x181 (no per-slice mean).
Selection score (Phase 37): DevelopmentScore = (Dice_pn0 + Dice_pn3) / 2, equal weights.
Near-tie tolerance: NONE. The numerically highest DevelopmentScore wins.
Exact-tie breakers only: (1) higher min(Dice_pn0, Dice_pn3); (2) simpler, more
interpretable method; (3) fewer tunable parameters.
No other metric is computed (IoU, precision, recall, specificity, volume error,
lesion-wise and slice-wise metrics belong to later evaluation phases).
Outcome selects the INITIAL thresholding method only, not the final pipeline.
```

#### Status

```text
COMPLETED - INITIAL THRESHOLDING METHOD SELECTED: EXP-024 (Otsu)
```

#### Date

```text
2026-10-10
```

#### Objective

```text
Compare the three frozen baseline thresholding methods quantitatively and select the
initial thresholding method with the pre-defined Phase-37 rule.
```

#### Hypothesis

```text
None. Selection by the pre-registered DevelopmentScore rule.
```

#### Baseline / Reference

```text
EXP-022 (manual), EXP-023 (iterative), EXP-024 (Otsu): saved candidate masks.
```

#### Dataset Configuration

```text
T2-based predictions on pn0 + pn3 (development). GT: BrainWeb crisp msles2, label 10,
same M_GT for both conditions, not intersected with brainMask. No held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
Saved lesionCandidateMask files of EXP-022/023/024; loadBrainwebGroundTruth.
```

#### Processing Pipeline

```text
load frozen predictions -> integrity checks -> M_GT = labels == 10
-> Dice = 2|P&G|/(|P|+|G|) on the full volume -> DevelopmentScore = mean(pn0, pn3)
-> rank (no tolerance) -> select argmax
```

#### Changed Component

```text
None (evaluation only; no prediction regenerated).
```

#### Parameters

```text
No near-tie tolerance (pre-registered). Exact-tie breakers not needed (no tie).
```

#### Implementation

```text
experiments/exp025_thresholding_comparison.m (local Dice with synthetic sanity check;
no reusable evaluation framework yet)
config.m: cfg.segmentation.thresholdMethod = "otsu" (method only, development baseline)
```

#### Git Version

```text
Commit: 742e04e
Working tree clean: NO
```

#### Execution

```text
MATLAB R2026b. All 72 checks PASS (synthetic Dice; GT size/labels/label-10 mask; each
prediction file, size, logical, metadata experiment/condition, unchanged; Dice
denominator > 0, finite in [0,1], equal to the formula; three methods x two conditions;
development conditions only; DevelopmentScore and weaker-condition formulas; selected =
max; CSV reproduces scores; no estimator/generator/morphology called).
```

#### Quantitative Results

```text
GT lesion voxels: 3,512.
Method              pn0 pred / inter / Dice        pn3 pred / inter / Dice        DevScore
EXP-024 Otsu        223,204 / 3,505 / 0.030920     257,445 / 3,494 / 0.026778     0.028849  rank 1
EXP-022 manual       70,866 / 1,474 / 0.039635      42,046 /   342 / 0.015014     0.027325  rank 2
EXP-023 iterative   848,576 / 3,512 / 0.008243     247,703 / 3,493 / 0.027809     0.018026  rank 3
Weaker-condition Dice: 0.026778 (Otsu), 0.015014 (manual), 0.008243 (iterative).
```

#### Lesion-Level Results

```text
Not computed (later evaluation phases).
```

#### Visual Results

```text
results/figures/exp025_thresholding_dice_comparison.png
results/figures/exp025_t2_{pn0,pn3}_error_overlay.png (after scoring; k = 46, 91, 102,
136; k = 102 a known GT diagnostic slice; does not influence selection)
False positives dominated by hyperintense CSF-compatible structures (ventricles,
cisterns, sulci, fissure) and bright rims; GT lesions mostly periventricular.
```

#### Comparison with Reference

```text
Otsu highest DevelopmentScore; margin over manual 0.0015; iterative last.
```

#### Interpretation

```text
All Dice < 0.04: a single global T2 threshold is dominated by non-lesion bright voxels.
Otsu and iterative predictions contain almost all GT voxels but are 64-242x larger than
the GT; the manual 3400 is compact but cuts into the lesion intensity range and loses
most lesion voxels in pn3 (shift). Otsu is the most balanced across pn0/pn3.
Incidental: EXP-023 pn0 contains all GT voxels, so the pn0 EXP-021 mask contains every
lesion voxel (observed after freeze; not used to change the mask).
```

#### Decision

```text
SELECTED INITIAL THRESHOLDING METHOD: EXP-024 Otsu (graythresh on T2(brainMask), per
volume), by the highest Phase-37 DevelopmentScore, no tolerance, no manual override.
Development baseline, not the final pipeline. No threshold, method, mask or preprocessing
changed after seeing Dice.
```

#### Next Experiment

```text
Phase 58 - multi-threshold evaluation (not started).
```

#### Notes

```text
Development results only (not test/generalization). No IoU/precision/recall/
specificity/volume error/lesion-wise/slice-wise metrics. No held-out data.
```

---

### EXP-026 — Multi-threshold T2 segmentation with multithresh (Phase 58)

#### Pre-registration (written before EXP-026 was run and before any EXP-026 Dice was computed)

```text
Justification: Phase 40 showed several brain-only T2 intensity populations; Phase 57 showed
that every binary global threshold gives Dice < 0.04 (selected baseline EXP-024 Otsu).
Single controlled change versus EXP-024: binary Otsu (graythresh) -> multi-level Otsu
(multithresh) with numberOfThresholds = 2, i.e. 3 classes. Fixed a priori; no other N.
Estimator input: brainValues = T2norm(brainMask) (EXP-021 mask; no artificial zeros).
Classes: classVolume = imquantize(T2norm, levels); candidate = brainMask & (classVolume == 3)
(highest class only, chosen a priori because high T2 intensity is the current cue).
No Class 2+3, no other class combination, no threshold modification/offset/rounding.
Same rule for pn0 and pn3 (numerical thresholds may differ). Preprocessing NONE.
GT loaded only after both predictions are saved; M_GT = labels == 10, not intersected
with brainMask; full-volume 3D Dice; DevelopmentScore = (Dice_pn0 + Dice_pn3)/2.
Reference: EXP-024 values read from results/metrics/exp025_thresholding_method_comparison.csv.
Rule (Phase 37, no near-tie tolerance): EXP-026 score > EXP-024 score -> KEEP EXP-026 as
current thresholding method; < -> REJECT; exact tie -> higher weaker-condition Dice, then
simpler method (binary Otsu), then fewer tunable parameters.
GT counts per class (Class 1/2/3, outside brainMask) are diagnostic only.
```

#### Status

```text
COMPLETED - KEEP: EXP-026 becomes the current selected thresholding method
```

#### Date

```text
2026-10-10
```

#### Objective

```text
Test whether a three-class multi-level Otsu partition of brain-only T2 gives a better
high-intensity lesion-candidate class than binary Otsu (EXP-024).
```

#### Hypothesis

```text
Modelling three intensity populations moves the upper decision boundary to a more useful
position than the binary Otsu split.
```

#### Baseline / Reference

```text
EXP-024 Otsu (selected in Phase 57): Dice pn0 0.0309197409975476, pn3 0.0267783581203033,
DevelopmentScore 0.0288490495589255 (read from exp025_thresholding_method_comparison.csv).
```

#### Dataset Configuration

```text
T2 msles2 1 mm rf0, pn0 + pn3 (development); EXP-021 brain masks. GT crisp msles2 label 10,
same M_GT for both, not intersected with brainMask. No held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
data/raw/msles2/mri/t2_ai_msles2_1mm_{pn0,pn3}_rf0.raws
data/processed/exp021_t1_{pn0,pn3}_3d_erode_select_dilate_candidate.mat
```

#### Processing Pipeline

```text
T2 -> double -> /4095 -> levels = multithresh(T2norm(brainMask), 2)
-> classVolume = imquantize(T2norm, levels) -> candidate = brainMask & (classVolume == 3)
-> save -> (only then) GT -> full-volume Dice -> DevelopmentScore -> Phase-37 rule
```

#### Changed Component

```text
Threshold estimation: graythresh (binary Otsu) -> multithresh with 2 thresholds (3 classes),
highest class as candidate. Everything else as EXP-024.
```

#### Parameters

```text
numberOfThresholds = 2; candidate class = 3; preprocessing NONE. Thresholds are outputs of
the built-in, unmodified (returned as double; no conversion or rounding needed).
```

#### Implementation

```text
experiments/multithresh_function_check.m (synthetic, 10/10 ok)
experiments/exp026_multithresh_t2.m
config.m: cfg.segmentation.thresholdMethod = "multithresh",
          cfg.segmentation.multithresh.numberOfThresholds = 2, .candidateClass = 3
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-10. All 62 checks PASS (sources, sizes, logical mask, normalized range,
estimator input count, two finite ordered thresholds in [0,1], deterministic multithresh,
labels 1..3 inside brain, class counts sum, Class 3 = T2norm > upper threshold, no candidate
outside brainMask, inputs unchanged, saved prediction reloads, GT loaded only after both
predictions were saved, GT label 10, Dice formula, DevelopmentScore formula, comparison CSV,
no held-out condition, no graythresh/morphology/components in the script).
```

#### Quantitative Results

```text
                              pn0                              pn3
T1 (lower) normalized / raw   0.535921855921856 / 2194.6       0.486929541047188 / 1993.97647
T2 (upper) normalized / raw   0.722018722018722 / 2956.66667   0.658438554909143 / 2696.30588
Brain-mask voxels             1,688,787                        1,668,366
Class 1 voxels (fraction)     707,574 (0.418984)               724,858 (0.434472)
Class 2 voxels (fraction)     834,484 (0.494132)               808,714 (0.484734)
Class 3 voxels (fraction)     146,729 (0.086884)               134,794 (0.080794)
GT in Class 1 / 2 / 3         0 / 477 / 3,035                  0 / 560 / 2,952
GT outside brainMask          0                                0
Candidate voxels              146,729                          134,794
Intersection                  3,035                            2,952
Dice                          0.0404017545144135               0.0426879528003124
Candidate / GT ratio          41.78                            38.38
Weaker-condition Dice 0.0404017545144135; DevelopmentScore 0.0415448536573629.
DevelopmentScore EXP-026 - EXP-024 = +0.0126958041.
```

#### Lesion-Level Results

```text
Not computed (later evaluation phases).
```

#### Visual Results

```text
results/figures/exp026_multithresh_histograms.png
results/figures/exp026_t2_{pn0,pn3}_multiclass.png (k = 46, 91, 136)
results/figures/exp026_t2_gt_diagnostic_k102.png (after scoring; diagnostic only)
Class 3 still contains the whole lateral ventricles, the fourth ventricle/cisterns, sulcal
and fissural CSF and bright rims. In pn0 the lower boundary falls between the two main
parenchymal peaks; the upper boundary lies in the bright tail, above the binary Otsu cut.
At k = 102 the GT voxels missed by Class 3 are mostly lesion borders and small/faint lesions.
```

#### Comparison with Reference

```text
EXP-026 vs EXP-024: Dice pn0 0.0404 vs 0.0309; pn3 0.0427 vs 0.0268; weaker condition
0.0404 vs 0.0268. Candidate volume -34.3 % (pn0, 146,729 vs 223,204) and -47.6 % (pn3,
134,794 vs 257,445). GT retained 3,035 vs 3,505 (pn0) and 2,952 vs 3,494 (pn3).
Upper boundary +242.73 (pn0) and +287.48 (pn3) raw levels above the Otsu threshold.
```

#### Interpretation

```text
Mostly outcome C with elements of A and B: Class 3 is much smaller and keeps 86.4 % / 84.1 %
of the GT voxels; no GT voxel falls in Class 1, the lost ones are in Class 2 (lesion borders
and fainter lesions). In practice the three-class model places the candidate boundary higher
than binary Otsu, removing part of the bright parenchymal tail while keeping the CSF-like
structures. The candidates are still about 40x the GT volume: intensity alone cannot separate
the lesions from bright fluid. pn0 and pn3 behave more consistently than with EXP-024.
Incidental: GT outside brainMask = 0 in both conditions, so the pn3 EXP-021 mask also contains
every GT lesion voxel (observed after freeze; not used to change anything).
```

#### Decision

```text
KEEP EXP-026 (DevelopmentScore 0.041545 > 0.028849, no tolerance, rule applied as
pre-registered). EXP-026 is the current selected thresholding method; EXP-024 remains a
documented alternative. Development baseline, not the final pipeline. No N, class, threshold,
mask or preprocessing change after seeing Dice; no alternative N and no Class 2+3 tested.
```

#### Next Experiment

```text
Phase 59 - variable / local thresholding evaluation (not started).
```

#### Notes

```text
multithresh thresholds are not multiples of 1/255 (unlike graythresh; e.g. pn0 upper
threshold x 255 = 184.115), so binary and multi-level Otsu also differ in histogram
discretization: a built-in behaviour, not an adjustment. Development results only.
```

---

### EXP-027 — Variable / local T2 thresholding with local mean and standard deviation (Phase 59)

#### Pre-registration (written before EXP-027 was run and before any EXP-027 Dice was computed)

```text
Justification: every global threshold leaves large bright non-lesion structures (EXP-026,
current method, still ~40x the GT volume); the course offers variable thresholding from
neighbourhood statistics (ALLOWED_TECHNIQUES 5.5).
Course formula: T(x,y) = a*m(x,y) + b*s(x,y); candidate if I(x,y) > T(x,y) (strict >).
Processing: 2D, axial slice by slice (course neighbourhood of (x,y)); no 3D windows.
Project choices (not from the course):
  - square window, side windowSize, centred on the pixel;
  - masked statistics: only pixels with brainMask == true inside the window contribute;
    the window is truncated at the image border (no padding values counted);
  - m = mean of the N valid values; s = population standard deviation
    sqrt(E[x^2] - E[x]^2), negative roundoff clamped to 0;
  - statistics computed on the integer raw levels (0..4095) so that sums, sums of squares
    and N*S2 - S1^2 are exact in double; T is then divided by 4095 (the rule is linear in
    the intensity scale, so the method is unchanged; this avoids random roundoff decisions
    in the many perfectly uniform pn0 regions);
  - T not clipped; candidate = brainMask & (T2norm > T).
Fixed: a = 1. Grid: windowSize in {9, 21, 41} x b in {0.5, 1.0, 1.5} = 9 configurations
(W09_B05 ... W41_B15). Same grid for pn0 and pn3. No other a, b or window.
Preprocessing NONE; T2 only; EXP-021 masks; no combination with any global threshold;
no morphology, components, harmonization.
Order: all 18 predictions (9 configs x pn0/pn3) saved before GT is loaded.
Evaluation: GT label 10, not intersected with brainMask; full-volume 3D Dice;
DevelopmentScore = (Dice_pn0 + Dice_pn3)/2; weakerConditionDice = min.
Decision A (best local): max DevelopmentScore; exact tie -> higher weakerConditionDice; if
still exactly tied: reported as an UNRESOLVED tie (no window-size preference declared).
Decision B: best local vs EXP-026 (values from results/metrics/exp026_vs_otsu_comparison.csv):
  > KEEP EXP-027 (current method, development parameters only); < REJECT; exact tie ->
  higher weaker-condition Dice, then simpler method (EXP-026: no explicit parameters).
No near-tie tolerance anywhere.
```

#### Status

```text
COMPLETED - REJECT: best local configuration W21_B15 does not beat EXP-026
```

#### Date

```text
2026-10-10
```

#### Objective

```text
Test whether the course variable threshold T = a*m + b*s (local T2 mean and standard
deviation) reduces the bright non-lesion response of global thresholding while keeping
the lesion voxels.
```

#### Hypothesis

```text
A threshold relative to the local context suppresses large uniformly bright regions
(CSF-like structures) better than one global threshold.
```

#### Baseline / Reference

```text
EXP-026 multithresh N = 2, Class 3 (current method): Dice pn0 0.0404017545144135,
pn3 0.0426879528003124, DevelopmentScore 0.0415448536573629 (exp026_vs_otsu_comparison.csv).
```

#### Dataset Configuration

```text
T2 msles2 1 mm rf0, pn0 + pn3 (development); EXP-021 brain masks. GT crisp msles2 label 10,
same M_GT for both, not intersected with brainMask. No held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
data/raw/msles2/mri/t2_ai_msles2_1mm_{pn0,pn3}_rf0.raws
data/processed/exp021_t1_{pn0,pn3}_3d_erode_select_dilate_candidate.mat
```

#### Processing Pipeline

```text
per axial slice: masked window sums N, S1, S2 on integer raw levels (conv2, box of ones)
-> m = S1/N, s = sqrt(max(N*S2 - S1^2, 0))/N -> T = (a*m + b*s)/4095
-> candidate = brainMask & (T2norm > T) -> stack 181 slices -> save (18 files)
-> (only then) GT -> full-volume Dice -> DevelopmentScore -> decisions A and B
```

#### Changed Component

```text
Threshold: global multithresh class boundary -> 2D local mean/std threshold (no global
threshold involved).
```

#### Parameters

```text
a = 1; windowSize in {9, 21, 41}; b in {0.5, 1.0, 1.5} (pre-registered, 9 configurations,
same for pn0 and pn3). Selected (development only, not frozen): windowSize 21, b 1.5.
```

#### Implementation

```text
src/segmentation/localMeanStdThreshold2D.m
experiments/local_threshold_function_check.m (synthetic, 19/19 ok)
experiments/exp027_local_threshold_t2.m
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-10. First run stopped at the figure stage (after all numbers were printed):
a variable "image" left in the base workspace by the synthetic check shadowed image(); the
variable was renamed and the script rerun unchanged, with identical numbers. All 258 checks
PASS (216 per-configuration: outside-mask values do not contribute, counts >= 1, finite
mean/std/T, std >= 0, candidate rule, normalized rule = raw-level rule, logical, size, no
candidate outside the mask, reload; plus grid, inputs, GT order, scoring and decision checks).
```

#### Quantitative Results

```text
Rank Config   Dice pn0  Dice pn3  Weaker    DevScore    Cand pn0 / pn3      GT hit pn0 / pn3
1    W21_B15  0.036055  0.036151  0.036055  0.0361029   119,133 / 114,771   2,211 / 2,138
2    W41_B15  0.033595  0.035162  0.033595  0.0343782   141,511 / 133,171   2,436 / 2,403
3    W41_B10  0.028358  0.027054  0.027054  0.0277055   223,588 / 231,282   3,220 / 3,176
4    W21_B10  0.027118  0.025818  0.025818  0.0264678   213,322 / 221,989   2,940 / 2,911
5    W09_B15  0.021164  0.019098  0.019098  0.0201313    82,293 /  87,700     908 /   871
6    W09_B10  0.021987  0.018073  0.018073  0.0200301   166,494 / 198,007   1,869 / 1,821
7    W41_B05  0.016849  0.016007  0.016007  0.0164282   409,083 / 429,923   3,476 / 3,469
8    W21_B05  0.016774  0.015700  0.015700  0.0162373   396,268 / 421,445   3,353 / 3,336
9    W09_B05  0.016518  0.014099  0.014099  0.0153088   360,936 / 418,490   3,010 / 2,975
GT voxels 3,512. Best W21_B15: candidate/GT 33.92 (pn0), 32.68 (pn3).
Best local - EXP-026 = -0.0054419189.
```

#### Lesion-Level Results

```text
Not computed (later evaluation phases).
```

#### Visual Results

```text
results/figures/exp027_local_threshold_grid_scores.png
results/figures/exp027_best_local_{pn0,pn3}.png (k = 46, 91, 136)
results/figures/exp027_t2_gt_diagnostic_k102.png (after scoring; diagnostic only)
The large uniform bright regions (lateral ventricles, fourth ventricle) are largely NOT
selected: the threshold map is highest there. Instead the candidates follow thin bright
structures relative to darker surroundings (sulcal/fissural CSF, cortical ribbons, edges of
bright regions); pn3 adds scattered single-voxel candidates. At k = 102 the periventricular
lesion parts adjacent to the ventricle are missed, isolated round lesions are kept.
```

#### Comparison with Reference

```text
Best local vs EXP-026: candidates -18.8 % (pn0, 119,133 vs 146,729) and -14.9 % (pn3,
114,771 vs 134,794); GT captured 2,211 vs 3,035 (pn0) and 2,138 vs 2,952 (pn3), i.e. about
27 % fewer lesion voxels. Of the EXP-026 candidates the best local keeps 91,506 (pn0) and
81,994 (pn3); 27,627 / 32,777 of its candidates are new (not in EXP-026).
```

#### Interpretation

```text
Local thresholding does suppress uniform bright CSF, but the lesions are mostly
periventricular: the bright ventricle inside the window raises m and s, so lesion voxels
next to it fall below T. Thin bright structures in darker parenchyma become candidates
instead. The net effect is fewer candidates but proportionally more lost lesion voxels, so
Dice drops. Over the grid b is the dominant factor (larger b always better here) and
windows 21/41 beat 9; the best value lies on the edge of the grid (b = 1.5), which is noted
but not extended (no post-hoc grid change). pn0 and pn3 behave consistently in score
(0.0361 / 0.0362) for the best configuration; pn3 shows more isolated speckle.
Scope: no configuration of the pre-registered family/range beats EXP-026; this does not
show that local thresholding cannot work in general (larger b remains untested).
```

#### Decision

```text
A) Best local configuration: W21_B15 (window 21, a = 1, b = 1.5), highest DevelopmentScore,
   no tie.
B) REJECT EXP-027: 0.0361029 < 0.0415449 (EXP-026), no tolerance. EXP-026 remains the
   current selected thresholding method; config.m unchanged (no local parameters recorded).
No parameter outside the grid, no hybrid local/global rule, no filtering, morphology,
components or harmonization.
```

#### Next Experiment

```text
Phase 60 - generate the selected lesion candidate mask (not started).
```

#### Notes

```text
Statistics on integer raw levels make the sums exact (s = 0 exactly in uniform pn0 regions;
otherwise roundoff would decide many pn0 voxels at random). conv2 with explicit ones vectors
instead of imfilter for the same reason. Threshold maps exceed 1 in places (max 1.14), as
specified (no clipping). Minimum neighbour count 1 (pn3) / 2 (pn0): isolated mask pixels,
for which s = 0 and T = I, so they are never candidates. Development results only.
```

---

### EXP-028 — Phase-61 candidate-mask error analysis (diagnostic)

#### Status

```text
COMPLETED - DIAGNOSTIC RESULT ESTABLISHED (no method decision; EXP-026 unchanged)
```

#### Date

```text
2026-10-10
```

#### Objective

```text
Classify the structural and spatial errors of the current candidateMask (isolated pixels,
thin/edge structures, dense regions, holes/gaps, fragmentation, fusion) and identify which
morphology families are worth testing later. No change to the mask.
```

#### Hypothesis

```text
None (diagnostic).
```

#### Baseline / Reference

```text
Phase-60 canonical candidateMask (= EXP-026), data/processed/phase60_t2_{pn0,pn3}_candidate_mask.mat.
```

#### Dataset Configuration

```text
pn0 + pn3 development; GT crisp msles2 label 10, diagnostic only, loaded after the masks.
No held-out data.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
Saved Phase-60 candidate masks (not regenerated); T2 only for display; GT label 10.
```

#### Processing Pipeline

```text
load masks -> GT -> TP/FP/FN in memory only -> 2D 8-neighbour candidate count per axial slice
(conv2, 3x3 kernel with zero centre, zero padding; checked against an independent
8-shift implementation) -> counts, distributions 0..8, per-slice profiles, overlays.
```

#### Changed Component

```text
None. No segmentation change, no morphology, no connected components, nothing saved
under data/processed/.
```

#### Parameters

```text
None. Isolated = 0 candidate neighbours. Fixed slices 46/91/102/136; contact sheet every
10 slices. The optional automatic top-FP/FN slices were not needed and not used.
```

#### Implementation

```text
experiments/exp028_candidate_mask_error_analysis.m
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-10. All 51 checks PASS (input integrity, GT integrity, TP+FP = candidates,
TP+FN = GT, disjoint classes, neighbour counts integer in 0..8 and equal to the independent
implementation, isolated definition, distribution and per-slice sums, masks unchanged, no
held-out reference, no morphology/component/threshold/save call).
```

#### Quantitative Results

```text
                                pn0                         pn3
Candidates / GT                 146,729 / 3,512             134,794 / 3,512
TP / FP / FN                    3,035 / 143,694 / 477       2,952 / 131,842 / 560
Isolated candidates (TP / FP)   7,465 (22 / 7,443)          8,996 (35 / 8,961)
TP neighbours 0..8              22/72/135/264/571/588/285/400/698
                                                            35/86/134/266/493/567/326/374/671
FP neighbours 0..8              7443/14726/14013/11173/17626/21137/10849/11232/35495
                                                            8961/13185/10869/10373/15306/18002/10290/10609/34247
FN neighbours 0..8              95/84/110/116/65/6/0/1/0    73/91/106/138/119/26/7/0/0
FN with 8 neighbours (1-px hole-like)   0                   0
FP isolated / <=2 nb / 8 nb     5.2 % / 25.2 % / 24.7 %     6.8 % / 25.0 % / 26.0 %
TP isolated / <=2 nb / >=5 nb   0.7 % / 7.5 % / 64.9 %      1.2 % / 8.6 % / 65.7 %
```

#### Lesion-Level Results

```text
Not computed (no component analysis before Phase 67).
```

#### Visual Results

```text
results/figures/exp028_candidate_errors_{pn0,pn3}.png (k = 46, 91, 102, 136)
results/figures/exp028_error_contact_sheet_{pn0,pn3}.png (every 10 slices)
results/figures/exp028_fp_fn_by_slice.png, results/figures/exp028_neighbor_topology.png
```

#### Comparison with Reference

```text
Not applicable (diagnostic of the selected mask only).
```

#### Interpretation

```text
A isolated/speckle FP: present but minor (5-7 % of FP; ~99.7 % of isolated candidates are FP).
B thin/edge FP: substantial (about 40 % of FP have 1-4 neighbours): cortical/sulcal rim-like
  patterns, the fissure, a thin line along the brain-mask border.
C large dense FP: dominant (about a quarter of FP fully surrounded): regions visually
  compatible with ventricular CSF, fourth ventricle/cisterns, sylvian/fissural fluid.
D holes/gaps: no single-pixel enclosed FN; FN mostly lesion borders (1-4 neighbours,
  about 80 %) and small faint lesions missed entirely (0 neighbours, 13-20 %).
E fragmentation: not clearly observed visually; cannot be established without components.
F fusion/bridging: observed - periventricular lesion signal is contiguous with the bright
  ventricle-compatible candidate region (k = 91, 102).
G systematic intensity confound: yes - the dominant FP is bright fluid-like signal in the
  same intensity class as the lesions, large and attached to lesions.
pn3 vs pn0: more isolated FP and more FN, otherwise very similar topology.
```

#### Decision

```text
DIAGNOSTIC RESULT ESTABLISHED. EXP-026 remains the candidate-generation method;
candidateMask unchanged. Worth TESTING later (not selected): opening/erosion (isolated and
thin FP, with risk for lesion borders and small lesions), dilation (border FN, at a large
FP cost); closing has little support (no enclosed holes). The dominant error (large fluid-
like regions fused with periventricular lesions) is unlikely to be solved by simple
morphology alone. No operation or structuring element selected.
```

#### Next Experiment

```text
Phase 62 - erosion / dilation experiments (not started).
```

#### Notes

```text
GT error locations are diagnostic only: no ROI, slice range, coordinate or location prior
is derived from them. No IoU/precision/recall or lesion-wise metric was computed.
```

---

### EXP-029 — Phase-62 erosion / dilation probe

#### Pre-registration (written before EXP-029 was run and before any EXP-029 GT score)

```text
Source: Phase-60 canonical candidateMask (= EXP-026), pn0 + pn3; not regenerated, not modified.
Justification (EXP-028): isolated and thin FP exist (erosion), FN lie mostly on lesion
borders (dilation); dense fluid-like FP dominate.
Variants: baseline, erosion, dilation (exactly three per condition).
SE: strel('square', 3), one application, 2D axial slice-wise; output AND brainMask (EXP-021).
Square 3x3 is a fixed minimal exploratory probe (smallest centred square, = the 2D
8-neighbourhood of Phase 61), NOT the Phase-65 structuring-element selection.
No other SE, size, iteration, opening or closing. GT loaded only after the four outputs are saved.
Scores: full-volume Dice, DevelopmentScore = (pn0 + pn3)/2, delta vs baseline; no tolerance;
effect classification only (IMPROVES / WORSENS / UNCHANGED), no pipeline decision.
Hypotheses:
  H1 erosion removes isolated/thin FP but also lesion borders and possibly small lesions;
  H2 dilation recovers some border FN but adds substantial FP;
  H3 neither primitive selectively removes the dominant large fluid-like FP.
Prediction from EXP-028 counts (3x3 erosion keeps exactly the candidates with 8 candidate
neighbours): eroded pn0 = 698 TP + 35,495 FP = 36,193 voxels; pn3 = 671 + 34,247 = 34,918.
```

#### Status

```text
COMPLETED - EFFECTS QUANTIFIED (both primitives WORSEN the baseline; no pipeline decision)
```

#### Date

```text
2026-10-10
```

#### Objective

```text
Measure the elementary effect of one 2D erosion and one 2D dilation (square 3x3) on the
unchanged Phase-60 candidateMask: TP/FP removed or added and the Dice effect.
```

#### Hypothesis

```text
H1, H2, H3 as pre-registered above.
```

#### Baseline / Reference

```text
Phase-60 candidateMask (= EXP-026): Dice 0.0404017545144135 / 0.0426879528003124,
DevelopmentScore 0.0415448536573629 (recomputed here, identical to EXP-026).
```

#### Dataset Configuration

```text
pn0 + pn3 development; EXP-021 brain masks; GT label 10 after the outputs were saved.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
data/processed/phase60_t2_{pn0,pn3}_candidate_mask.mat; EXP-021 masks.
```

#### Processing Pipeline

```text
candidateMask -> per axial slice imerode / imdilate(strel('square',3)), once -> AND brainMask
-> save 4 outputs -> GT -> full-volume Dice, DevelopmentScore, change counts.
```

#### Changed Component

```text
Post-processing probe only (erosion or dilation); the candidate generation is unchanged.
```

#### Parameters

```text
strel('square', 3), 1 iteration, 2D slice-wise, brain-mask constrained (fixed probe, not the
Phase-65 selection).
```

#### Implementation

```text
src/segmentation/applySliceMorphology2D.m (no GT; "erode" | "dilate")
experiments/morphology_basic_function_check.m (synthetic, 13/13 ok)
experiments/exp029_erosion_dilation_probe.m
Outputs: data/processed/exp029_t2_{pn0,pn3}_{eroded,dilated}_square3_candidate.mat
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-10. All 59 checks PASS, including erosion = candidates with 8 candidate
neighbours and dilation = (candidate | >= 1 neighbour) & brainMask (independent slice-wise
reference), outputs saved before GT, baseline Dice = EXP-026, change-count algebra.
```

#### Quantitative Results

```text
Variant    Cand pn0 / pn3       TP pn0 / pn3   Dice pn0   Dice pn3   DevScore   Delta
baseline   146,729 / 134,794    3,035 / 2,952  0.040402   0.042688   0.041545    0
erosion     36,193 /  34,918      698 /   671  0.035159   0.034921   0.035040   -0.0065049
dilation   344,844 / 326,242    3,417 / 3,439  0.019618   0.020858   0.020238   -0.0213069
Erosion removed: pn0 110,536 (TP 2,337, FP 108,199; 97.9 % FP; 77.0 % of TP lost, 75.3 % of
  FP removed); pn3 99,876 (TP 2,281, FP 97,595; 97.7 % FP; 77.3 % TP lost, 74.0 % FP removed).
Dilation added: pn0 198,115 (TP 382 = 80.1 % of the 477 FN; FP 197,733 = 99.8 %);
  pn3 191,448 (TP 487 = 87.0 % of the 560 FN; FP 190,961 = 99.7 %).
Eroded counts match the pre-registered prediction (36,193 / 34,918; 698 / 671 TP).
```

#### Lesion-Level Results

```text
Not computed.
```

#### Visual Results

```text
results/figures/exp029_morphology_probe_{pn0,pn3}.png
results/figures/exp029_morphology_errors_{pn0,pn3}.png
results/figures/exp029_morphology_changes_{pn0,pn3}.png (title clipped at the right edge;
cosmetic only)
Erosion: isolated voxels and thin cortical/sulcal rims disappear entirely (k = 136 almost
empty); the ventricle-compatible regions shrink but persist; lesions are reduced to their
cores and small lesions vanish (k = 102: lesion rims turn green). Dilation: every structure
thickens by one pixel ring; lesion borders are recovered, but rims become broad bands, the
ventricle-compatible regions grow and neighbouring structures merge (more fusion).
```

#### Comparison with Reference

```text
Both primitives WORSEN the baseline DevelopmentScore (erosion -0.0065, dilation -0.0213).
```

#### Interpretation

```text
H1 supported, more strongly than expected: erosion removes FP and TP in almost the same
proportion (75 % vs 77 %), because the lesions are themselves thin (only 23 % of lesion
voxels are interior at 3x3). It is not FP-selective. H2 supported: dilation recovers 80-87 %
of the FN but each recovered voxel costs about 400-520 new FP. H3 supported: the dense
fluid-like regions survive erosion and grow under dilation. Neither primitive alone is
useful as post-processing; erosion's survivors (lesion cores) bound what an opening could
restore.
```

#### Decision

```text
EFFECTS QUANTIFIED. No morphology or structuring element selected; Phase-60 candidateMask
and EXP-026 unchanged; config.m unchanged.
```

#### Next Experiment

```text
Phase 63 - opening (not started).
```

#### Notes

```text
Development results only. No opening, closing, components, filling or held-out data.
```

---

### EXP-030 — Phase-63 standard opening probe

#### Pre-registration (written before EXP-030 was run and before any EXP-030 GT score)

```text
Source: Phase-60 canonical candidateMask (= EXP-026), pn0 + pn3; unchanged.
Motivation: EXP-028 (isolated/thin FP) and EXP-029 (erosion alone removes 77 % of TP; opening
lets the dilation stage restore what survives the erosion).
Operation: standard opening, imopen, strel('square', 3) (same provisional probe as EXP-029,
not the Phase-65 selection), once, 2D axial slice-wise, AND brainMask (EXP-021).
Checked: imopen = erosion -> dilation (applySliceMorphology2D), erosion stage = frozen EXP-029
erosion; eroded <= opened <= baseline.
Consequence stated before results: opened is a subset of baseline, so opening cannot recover
any baseline FN; any gain can only come from removing FP while keeping TP. Structures with no
surviving 3x3 erosion core cannot be restored.
GT loaded only after both opened masks are saved. Variants scored: baseline, erosion
reference (EXP-029), opening. Full-volume Dice, DevelopmentScore, delta vs baseline; no
tolerance; descriptive conclusion only (IMPROVES / WORSENS / UNCHANGED); no selection.
Hypotheses:
  H1 opening removes isolated candidates and narrow protrusions;
  H2 it restores lesion voxels around erosion-surviving cores, but lesions with no 3x3 core
     stay lost;
  H3 large dense fluid-like regions survive erosion and are largely reconstructed, so opening
     does not solve the dominant FP problem;
  H4 opening may beat erosion alone; whether it beats the baseline is unknown.
```

#### Status

```text
COMPLETED - OPENING IMPROVES THE BASELINE WITH THE PROVISIONAL SQUARE-3 PROBE (no selection)
```

#### Date

```text
2026-10-10
```

#### Objective

```text
Measure whether one standard 2D opening (square 3x3) removes isolated/thin FP while restoring
enough lesion structure to improve the unchanged Phase-60 candidateMask.
```

#### Hypothesis

```text
H1-H4 as pre-registered above.
```

#### Baseline / Reference

```text
Phase-60 candidateMask (= EXP-026), DevelopmentScore 0.0415448536573629; EXP-029 erosion
reference 0.0350399673784638 (both recomputed here and matched).
```

#### Dataset Configuration

```text
pn0 + pn3 development; EXP-021 brain masks; GT label 10 after both opened masks were saved.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
data/processed/phase60_t2_{pn0,pn3}_candidate_mask.mat; EXP-021 masks;
data/processed/exp029_t2_{pn0,pn3}_eroded_square3_candidate.mat (reference).
```

#### Processing Pipeline

```text
candidateMask -> per axial slice imopen(strel('square',3)) -> AND brainMask -> save
-> GT -> full-volume Dice, DevelopmentScore, removal/restoration counts.
```

#### Changed Component

```text
Post-processing probe: one standard opening; candidate generation unchanged.
```

#### Parameters

```text
strel('square', 3), 1 opening, 2D slice-wise, brain-mask constrained (provisional probe).
```

#### Implementation

```text
experiments/opening_basic_function_check.m (synthetic, 14/14 ok)
experiments/exp030_opening_probe.m (imopen inline; applySliceMorphology2D unchanged, used
only for the erosion -> dilation check)
Outputs: data/processed/exp030_t2_{pn0,pn3}_opened_square3_candidate.mat
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-10. All 70 checks PASS: imopen = erosion -> dilation = dilation of the frozen
EXP-029 erosion; brain constraint changed nothing; eroded <= opened <= baseline (sets, TP, FP;
FN reversed); removal/restoration algebra; outputs saved before GT; baseline and erosion Dice
reproduce EXP-026 / EXP-029; isolated after opening = 0.
```

#### Quantitative Results

```text
Variant            Cand pn0 / pn3      TP pn0 / pn3   FN pn0 / pn3  Dice pn0  Dice pn3  DevScore  Delta
baseline           146,729 / 134,794   3,035 / 2,952    477 /   560  0.040402  0.042688  0.041545   0
erosion_reference   36,193 /  34,918     698 /   671  2,814 / 2,841  0.035159  0.034921  0.035040  -0.0065049
opening             70,878 /  67,066   2,107 / 2,013  1,405 / 1,499  0.056647  0.057043  0.056845  +0.0153005
Removed by opening: pn0 75,851 (TP 928, FP 74,923; 98.8 % FP); pn3 67,728 (TP 939, FP 66,789; 98.6 % FP).
Baseline TP preserved 69.4 % / 68.2 %; baseline FP removed 52.1 % / 50.7 %.
Restored after erosion: pn0 34,685 (TP 1,409, FP 33,276); pn3 32,148 (TP 1,342, FP 30,806).
Erosion-lost TP restored 60.3 % / 58.8 %; erosion-lost FP restored 30.8 % / 31.6 %.
Isolated candidates 7,465 -> 0 (pn0), 8,996 -> 0 (pn3); after opening every candidate has >= 3
of its 8 neighbours.
```

#### Lesion-Level Results

```text
Not computed.
```

#### Visual Results

```text
results/figures/exp030_opening_probe_{pn0,pn3}.png, exp030_opening_errors_{pn0,pn3}.png,
exp030_opening_changes_{pn0,pn3}.png
Opening removes the isolated voxels and the thin cortical/sulcal/fissural rims almost
completely (k = 136 nearly empty apart from a few small blocks). The ventricle-compatible
regions and the fourth-ventricle/cistern-compatible regions are reconstructed almost entirely
(only thin peripheral parts lost). Lesions with a 3x3 core are rebuilt; small lesions and thin
lesion parts are lost (k = 91, 102: small lesions turn green). The lesion-ventricle contact at
k = 102 remains.
```

#### Comparison with Reference

```text
Opening beats both the baseline (+0.0153) and erosion alone (+0.0218).
```

#### Interpretation

```text
H1 supported (isolated -> 0, thin rims removed). H2 supported (60 % of the erosion-lost TP
restored around cores; small/thin lesions lost: FN 477 -> 1,405, 560 -> 1,499). H3 supported
(dense fluid-like regions reconstructed; 68,771 / 65,053 FP remain, about 20x the GT).
H4: opening beats erosion and, measurably, the baseline. The dilation stage restores lesion
voxels about twice as readily as FP voxels (60 % vs 31 %): lesion regions whose core survives
the 3x3 erosion are partly rebuilt, while small/thin lesion structures without such a core
are removed permanently. Dice rises because FP mass (isolated, thin, rims, narrow
connections) is removed faster than TP; the ventricular confound is not resolved. Opening cannot recover baseline FN (opened is a
subset of baseline).
```

#### Decision

```text
OPENING IMPROVES THE BASELINE WITH THE PROVISIONAL SQUARE-3 PROBE. Promising morphology
candidate for the later structuring-element evaluation (Phase 65); not selected. Phase-60
candidateMask, EXP-026 and config.m unchanged.
```

#### Next Experiment

```text
Phase 64 - closing (not started).
```

#### Notes

```text
Development results only. No closing, reconstruction, components, size rule or held-out data.
```

---

### EXP-031 — Phase-64 closing after opening

#### Pre-registration (written before EXP-031 was run and before any EXP-031 GT score)

```text
Source: EXP-030 opened masks (pn0, pn3); candidate-generation source EXP-026; not regenerated.
Operation: standard closing, imclose, strel('square', 3) (same provisional probe as
EXP-029/030, not the Phase-65 selection), once, 2D axial slice-wise. brainMask (EXP-021) is
applied only AFTER the complete closing, never between dilation and erosion. Checked against
imerode(imdilate(slice)) without intermediate clipping.
Stated before results: closing is extensive (opened <= closed), so it cannot remove any EXP-030
FP; it can only add voxels (gaps, lesion borders) at some FP / bridging cost.
GT loaded only after both closed masks are saved. Variants: baseline, opening, opening_closing.
Full-volume Dice, DevelopmentScore, deltas vs baseline and vs opening; no tolerance; no
selection.
Hypotheses:
  H1 closing recovers some opening FN in narrow gaps / along region borders;
  H2 small lesions removed entirely by opening are not recovered without nearby support;
  H3 any gain requires a favourable TP/FP ratio among the added voxels;
  H4 closing may add bridges, including lesion-to-fluid contacts;
  H5 the dense fluid-like FP regions are not removed and may become more coherent;
  H6 whether opening + closing beats opening alone is unknown.
```

#### Status

```text
COMPLETED - EXP-030 OPENING REMAINS THE BEST OBSERVED MORPHOLOGY CANDIDATE (no selection)
```

#### Date

```text
2026-10-10
```

#### Objective

```text
Measure whether one standard 2D closing (square 3x3) after the EXP-030 opening recovers local
gaps / lesion-border voxels without adding too many FP or bridges.
```

#### Hypothesis

```text
H1-H6 as pre-registered above.
```

#### Baseline / Reference

```text
Phase-60 baseline 0.0415448536573629; EXP-030 opening 0.0568453350591327 (both reproduced).
```

#### Dataset Configuration

```text
pn0 + pn3 development; EXP-021 brain masks; GT label 10 after both closed masks were saved.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
data/processed/exp030_t2_{pn0,pn3}_opened_square3_candidate.mat (authoritative input);
Phase-60 masks for reference only; EXP-021 masks.
```

#### Processing Pipeline

```text
EXP-030 opened mask -> per axial slice imclose(strel('square',3)) -> AND brainMask (only after
the complete closing) -> save -> GT -> Dice, DevelopmentScore, added-voxel and FN-gap analysis.
```

#### Changed Component

```text
One standard closing after the EXP-030 opening; everything upstream unchanged.
```

#### Parameters

```text
strel('square', 3), 1 closing, 2D slice-wise, brain mask after complete closing, no
intermediate clipping (provisional probe).
```

#### Implementation

```text
experiments/closing_basic_function_check.m (synthetic, 14/14 ok, including a case showing that
intermediate clipping would change the result)
experiments/exp031_closing_after_opening.m (imclose inline; applySliceMorphology2D not used)
Outputs: data/processed/exp031_t2_{pn0,pn3}_opened_closed_square3_candidate.mat
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-10. All 68 checks PASS: imclose = raw dilation -> erosion; brain mask applied
after the complete closing; opened <= closed, no opened voxel removed; closing additions inside
the dilation stage; TP/FP/FN algebra; outputs saved before GT; baseline and opening Dice
reproduce EXP-026 / EXP-030; FN-neighbour bins sum to the opening FN.
```

#### Quantitative Results

```text
Variant          Cand pn0 / pn3      TP pn0 / pn3   FN pn0 / pn3   Dice pn0  Dice pn3  DevScore  d vs base  d vs opening
baseline         146,729 / 134,794   3,035 / 2,952    477 /   560  0.040402  0.042688  0.041545   0          -
opening           70,878 /  67,066   2,107 / 2,013  1,405 / 1,499  0.056647  0.057043  0.056845  +0.015300   0
opening_closing   72,070 /  68,258   2,120 / 2,019  1,392 / 1,493  0.056098  0.056263  0.056181  +0.014636  -0.000665
Added by closing: pn0 1,192 (TP 13, FP 1,179; 1.1 % TP; 0.9 % of opening FN recovered);
                  pn3 1,192 (TP 6, FP 1,186; 0.5 % TP; 0.4 % of opening FN recovered).
  (equal totals in pn0 and pn3 are a coincidence; the TP/FP split differs.)
Dilation stage added: pn0 43,360 (TP 428, FP 42,932); pn3 39,829 (TP 488, FP 39,341).
  Retained by the erosion stage: TP 3.0 % / 1.2 %, FP 2.7 % / 3.0 %.
Opening FN by opening-candidate neighbours 0..8 (recovered by closing):
  pn0 977(0) / 41(0) / 137(2) / 217(3) / 26(3) / 6(4) / 0 / 1(1) / 0
  pn3 1011(0) / 46(0) / 160(1) / 235(1) / 35(1) / 12(3) / 0 / 0 / 0
```

#### Lesion-Level Results

```text
Not computed.
```

#### Visual Results

```text
results/figures/exp031_closing_probe_{pn0,pn3}.png, exp031_closing_errors_{pn0,pn3}.png,
exp031_closing_added_{pn0,pn3}.png
The few added voxels lie mostly in narrow gaps between and inside the ventricle-compatible
regions (k = 91: the thin separation between the two ventricle-like regions is partly filled,
i.e. bridging) and at a few lesion borders (k = 102). Completely missing small lesions are not
recovered. The dense fluid-like regions are unchanged apart from these fills.
```

#### Comparison with Reference

```text
Opening + closing is below opening alone (-0.000665) and above the baseline (+0.014636); both
conditions decrease (pn0 0.056647 -> 0.056098, pn3 0.057043 -> 0.056263).
```

#### Interpretation

```text
H1 weakly supported only: closing recovers 13 / 6 opening FN, slightly more often in bins with
4-7 neighbours, but most border FN stay missed. H2 supported: about 70 % of the opening FN (977 /
1,011) have no opening candidate within the 8-neighbourhood and none is recovered. H3: the added
voxels are 99 % FP, so the score drops. H4 supported visually (gaps between fluid-like regions
filled). H5 supported (fluid-like regions not removed). H6: opening + closing does not beat
opening alone. Opening already smooths the regions, so few gaps narrower than the SE remain;
closing has little to fill and fills mostly FP gaps.
Scope: standard 2D square-3 closing after square-3 opening adds no value on the development
set; this does not show that closing is useless in general.
```

#### Decision

```text
EXP-030 OPENING REMAINS THE BEST OBSERVED MORPHOLOGY CANDIDATE SO FAR. No morphology or
structuring element selected; Phase-60 candidateMask, EXP-026 and config.m unchanged.
```

#### Next Experiment

```text
Phase 65 - structuring-element selection (not started).
```

#### Notes

```text
Development results only. No reconstruction, filling, components, size rule or held-out data.
```

---

### EXP-032 — Phase-65 structuring-element selection for standard opening

#### Pre-registration (written before EXP-032 was run and before any EXP-032 GT score)

```text
Morphology family: standard opening (EXP-030 improved the baseline; erosion, dilation and
closing after opening did not). Only the structuring element changes.
Source: Phase-60 canonical candidateMask (= EXP-026), pn0 + pn3; every candidate is opened
independently from it (no opening of the EXP-030 mask).
Operation: one imopen, 2D axial slice-wise, AND brainMask (EXP-021).
Grid (exactly four, fixed):
  S1 square3  = strel('square', 3)  3x3, 9 elements  - EXP-030 reference;
  S2 diamond1 = strel('diamond', 1) 3x3, 5 elements  - sparser support at the same extent:
                may keep more thin/small lesions (and more FP);
  S3 square5  = strel('square', 5)  5x5, 25 elements - larger, more aggressive: more FP
                removed, higher small-lesion risk;
  S4 diamond2 = strel('diamond', 2) 5x5, 13 elements - same 5x5 extent with sparser support:
                separates shape/density from scale.
No line/orientation-specific, disk or custom SE; no extension after results (a boundary winner
is a documented limitation). square3 must reproduce EXP-030 exactly, otherwise TECHNICALLY
BLOCKED.
All 8 predictions (4 SE x 2 conditions) saved before GT is loaded. One SE shared by pn0/pn3.
Selection (Phase 37): highest DevelopmentScore = mean full-volume Dice; no near-tie tolerance;
exact tie -> higher weaker-condition Dice; a remaining exact tie is reported, not resolved by a
new criterion. square3 gets no preference. TP preservation / FP removal / isolated voxels are
diagnostics only.
Hypotheses: H1 diamond1 keeps more TP and more FP; H2 square5 removes more FP but loses more
small lesions; H3 diamond2 is intermediate; H4 no SE solves the dense fluid-like FP; H5 no
preference for square3.
```

#### Status

```text
COMPLETED - SELECTED DEVELOPMENT SE FOR STANDARD OPENING: square3 (strel('square',3))
```

#### Date

```text
2026-10-10
```

#### Objective

```text
Select the structuring element for the standard-opening morphology among four pre-registered
candidates, with the Phase-37 DevelopmentScore and one SE shared by pn0 and pn3.
```

#### Hypothesis

```text
H1-H5 as pre-registered above.
```

#### Baseline / Reference

```text
No morphology (Phase 60 / EXP-026) 0.0415448536573629; EXP-030 square3 opening
0.0568453350591327 (reproduced exactly, masks identical).
```

#### Dataset Configuration

```text
pn0 + pn3 development; EXP-021 brain masks; GT label 10 after all 8 predictions were saved.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
data/processed/phase60_t2_{pn0,pn3}_candidate_mask.mat (each SE applied independently).
```

#### Processing Pipeline

```text
candidateMask -> per axial slice imopen(SE) -> AND brainMask, for SE in {square3, diamond1,
square5, diamond2} -> save 8 outputs -> GT -> full-volume Dice -> DevelopmentScore -> rank.
```

#### Changed Component

```text
Structuring element of the standard opening only.
```

#### Parameters

```text
square3 = strel('square',3) 3x3/9; diamond1 = strel('diamond',1) 3x3/5;
square5 = strel('square',5) 5x5/25; diamond2 = strel('diamond',2) 5x5/13. One opening, 2D.
```

#### Implementation

```text
experiments/structuring_element_grid_check.m (synthetic, 34/34 ok)
experiments/exp032_structuring_element_selection.m
Outputs: data/processed/exp032_t2_{pn0,pn3}_opening_{square3,diamond1,square5,diamond2}_candidate.mat;
selected copies data/processed/phase65_t2_{pn0,pn3}_selected_opening_candidate.mat
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-10. All 81 checks PASS: grid definitions, one imopen per SE on 181 slices,
outputs subset of source and inside the brain mask, 8 outputs saved before GT, square3 = frozen
EXP-030 (masks and Dice), no-morphology Dice = EXP-026, exactly one winner, selected masks =
frozen winner for both conditions, config.m unchanged.
```

#### Quantitative Results

```text
Rank SE        Dice pn0  Dice pn3  Weaker    DevScore   d vs none  d vs square3
1    square3   0.056647  0.057043  0.056647  0.056845   +0.015300   0
2    diamond1  0.053521  0.054352  0.053521  0.053937   +0.012392  -0.002908
3    diamond2  0.051060  0.052555  0.051060  0.051808   +0.010263  -0.005038
4    square5   0.038859  0.036449  0.036449  0.037654   -0.003891  -0.019191
Trade-off (pn0 / pn3): voxels; TP / FP / FN; TP preserved; FP removed
square3   70,878 / 67,066; 2,107/68,771/1,405 | 2,013/65,053/1,499; 69.4 % / 68.2 %; 52.1 % / 50.7 %
diamond1  86,097 / 80,716; 2,398/83,699/1,114 | 2,289/78,427/1,223; 79.0 % / 77.5 %; 41.8 % / 40.5 %
diamond2  55,203 / 53,571; 1,499/53,704/2,013 | 1,500/52,071/2,012; 49.4 % / 50.8 %; 62.6 % / 60.5 %
square5   42,501 / 41,427;   894/41,607/2,618 |   819/40,608/2,693; 29.5 % / 27.7 %; 71.0 % / 69.2 %
Isolated voxels after every opening: 0.
```

#### Lesion-Level Results

```text
Not computed.
```

#### Visual Results

```text
results/figures/exp032_se_candidates_{pn0,pn3}.png, exp032_se_errors_{pn0,pn3}.png
(no selected-vs-square3 figure: square3 won). diamond1 leaves small plus-shaped fragments of
thin FP; square5 produces blocky regions and erases many lesions (k = 102 mostly green);
diamond2 is intermediate. The ventricle/cistern-compatible regions persist with every SE.
```

#### Comparison with Reference

```text
square3 (= EXP-030) remains the best; every other SE is lower in both conditions.
```

#### Interpretation

```text
The four SEs order by aggressiveness (TP preserved): diamond1 79 % > square3 69 % > diamond2
50 % > square5 28 %. The score peaks at square3, i.e. in the interior of this aggressiveness
range: diamond1 keeps more TP but much more FP; the 5x5 elements remove more FP but lose too
many lesions. At 3x3 the denser square beats the diamond; at 5x5 the sparser diamond beats the
square; increasing scale lowers the score in both families. H1-H3 supported; H4 supported (no
SE removes the dense fluid-like regions); H5: square3 won on the numbers only.
square3 is not on an aggressiveness boundary of the grid, but the grid is not exhaustive
(no disk, no other sizes); the result does not claim a global optimum.
```

#### Decision

```text
SELECTED DEVELOPMENT STRUCTURING ELEMENT FOR STANDARD OPENING: square3 (strel('square', 3),
3x3, 9 elements), DevelopmentScore 0.056845, shared by pn0 and pn3. Not a frozen project
parameter; config.m unchanged; candidate generation EXP-026 unchanged.
```

#### Next Experiment

```text
Phase 66 - before/after morphology comparison (not started).
```

#### Notes

```text
Development results only. No closing, reconstruction, components or held-out data.
```

---

### EXP-033 — Phase-66 formal before / after morphology comparison

#### Pre-registration (written before EXP-033 was run)

```text
Purpose: development-set before/after comparison of the selected morphology block (not
independent validation: pn0/pn3 already selected the SE in Phase 65).
BEFORE: Phase-60 canonical candidateMask (EXP-026). AFTER: Phase-65 selected masks (standard
opening, strel('square',3), 2D slice-wise, EXP-032 winner, = EXP-030). Both frozen; nothing is
regenerated; no morphology, components or thresholding is called.
Metrics: full-volume Dice, DevelopmentScore, TP/FP/FN, removed TP/FP and fractions, slice profile.
Decision rule (no tolerance): AfterDevelopmentScore > BeforeDevelopmentScore -> morphology block
RETAINED FOR SUBSEQUENT DEVELOPMENT; < -> not retained in its current form; = -> no measurable
improvement. Retained does not mean the pipeline is frozen.
```

#### Status

```text
COMPLETED - THE SELECTED MORPHOLOGY BLOCK IS RETAINED FOR SUBSEQUENT DEVELOPMENT
```

#### Date

```text
2026-10-11
```

#### Objective

```text
Formal development-set before/after comparison of the selected morphology block (standard
2D opening, strel('square',3)) against the unchanged Phase-60 candidate mask.
```

#### Hypothesis

```text
None (comparison of two frozen artifacts; pre-registered retention rule).
```

#### Baseline / Reference

```text
BEFORE: data/processed/phase60_t2_{pn0,pn3}_candidate_mask.mat (EXP-026).
AFTER: data/processed/phase65_t2_{pn0,pn3}_selected_opening_candidate.mat (EXP-032 winner,
identical to EXP-030).
```

#### Dataset Configuration

```text
pn0 + pn3 development (already used for the Phase-65 selection: not independent validation).
GT label 10, evaluation only.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
The two frozen mask sets above; T2 only for display.
```

#### Processing Pipeline

```text
load frozen masks -> integrity / identity checks -> GT -> full-volume Dice, DevelopmentScore,
TP/FP/FN, removed TP/FP, slice profiles, figures. No mask generated or saved.
```

#### Changed Component

```text
None (evaluation only).
```

#### Parameters

```text
None new. Morphology under evaluation: one 2D imopen with strel('square',3).
```

#### Implementation

```text
experiments/exp033_before_after_morphology_comparison.m
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-11. All 48 checks PASS: frozen inputs and metadata (Phase 60 / EXP-026;
Phase 65 / EXP-032, square3, 3x3, 9 elements, 2D, not frozen), AFTER = EXP-032 winner = EXP-030,
AFTER subset of BEFORE (no added voxel), Dice reproduce EXP-026 / EXP-032 / EXP-030, count
algebra, slice totals, masks / GT / config.m unchanged, no morphology / components /
thresholding / save call.
```

#### Quantitative Results

```text
                        pn0                          pn3
BEFORE voxels; TP/FP/FN 146,729; 3,035/143,694/477   134,794; 2,952/131,842/560
AFTER  voxels; TP/FP/FN  70,878; 2,107/68,771/1,405   67,066; 2,013/65,053/1,499
Dice before -> after    0.040402 -> 0.056647 (+0.016246)   0.042688 -> 0.057043 (+0.014355)
Removed (TP / FP)       75,851 (928 / 74,923)        67,728 (939 / 66,789)
Candidates removed      51.7 %                       50.2 %
TP preserved / lost     69.4 % / 30.6 %              68.2 % / 31.8 %
FP removed              52.1 %                       50.7 %
Removed that is FP      98.8 %                       98.6 %
FP removed per TP lost  80.7                         71.1
FN increase             +928                         +939
Weaker-condition Dice 0.040402 -> 0.056647; DevelopmentScore 0.041545 -> 0.056845 (+0.0153005).
```

#### Lesion-Level Results

```text
Not computed.
```

#### Visual Results

```text
results/figures/exp033_before_after_masks_{pn0,pn3}.png, exp033_before_after_errors_{pn0,pn3}.png,
exp033_removed_by_morphology_{pn0,pn3}.png, exp033_before_after_slice_profile_{pn0,pn3}.png
Isolated and thin FP, including the cortical/sulcal/fissural rims, are largely removed; the FP
reduction is proportionally largest in the inferior and superior slices, where thin rims
dominate. The central slices (about k = 70-100) keep high FP: the ventricle/cistern-compatible
regions remain. Small/thin lesions and lesion borders are lost (FN rise across the lesion-bearing
slices, most around k = 95-105). The lesion-to-fluid contacts remain. pn0 and pn3 behave alike.
```

#### Comparison with Reference

```text
AFTER beats BEFORE in both conditions.
```

#### Interpretation

```text
A. The morphology block improves the development metric in both conditions: it removes about
half of the FP (98.7 % of the removed voxels are FP, about 71-81 FP per TP lost).
B. It does not solve the dominant dense fluid-like FP (68,771 / 65,053 FP remain, about 20x the
GT), it loses small/thin lesions (FN +928 / +939) and lesion-to-fluid contacts persist.
Development-set comparison only (pn0/pn3 also selected the SE), not independent validation.
```

#### Decision

```text
THE SELECTED MORPHOLOGY BLOCK IMPROVES THE DEVELOPMENT-SET RESULT AND IS RETAINED FOR
SUBSEQUENT DEVELOPMENT PHASES: standard 2D opening, strel('square',3), one application, on the
T2 Phase-60 candidate mask. Not a frozen pipeline; config.m unchanged; EXP-026 unchanged.
```

#### Next Experiment

```text
Phase 67 - 2D connected-component analysis (not started).
```

#### Notes

```text
No new mask, morphology, components, thresholding or held-out data.
```

---

### EXP-034 — Phase-67 2D connected-component identification

#### Status

```text
COMPLETED - 2D COMPONENTS IDENTIFIED (no filtering, no properties, no GT)
```

#### Date

```text
2026-10-11
```

#### Objective

```text
Decompose the retained Phase-65 candidate masks into independent 2D connected components on
every axial slice, as the object representation for Phase 68.
```

#### Hypothesis

```text
None (structural identification).
```

#### Baseline / Reference

```text
Input: data/processed/phase65_t2_{pn0,pn3}_selected_opening_candidate.mat (EXP-026 candidates +
standard 2D opening square3, retained in Phase 66).
```

#### Dataset Configuration

```text
pn0 + pn3 development. GT not loaded.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
Phase-65 selected masks (unchanged).
```

#### Processing Pipeline

```text
for each axial slice k: CC = bwconncomp(candidateMask(:,:,k), 8) -> ccBySlice{k};
numComponentsPerSlice(k) = CC.NumObjects. No mask is modified.
```

#### Changed Component

```text
None (object identification only).
```

#### Parameters

```text
Connectivity 8 (2D), fixed a priori without GT: consistent with the 2D 8-neighbourhood used since
Phase 61; diagonally touching pixels belong to the same in-plane region. No 4 vs 8 comparison.
```

#### Implementation

```text
src/segmentation/extractConnectedComponents2D.m (bwconncomp on single 2D slices; 4 or 8 explicit)
experiments/connected_components_2d_check.m (synthetic, 14/14 ok)
experiments/exp034_connected_components_2d.m
Outputs: data/processed/phase67_t2_{pn0,pn3}_components2d.mat (ccBySlice, numComponentsPerSlice, metadata)
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-11. The first two runs stopped only at the final self-check "bwconncomp receives
single 2D slices only": the script's own forbidden-pattern strings contained the literal text
being searched for. The strings were split and the script rerun unchanged otherwise; all 27
checks PASS (provenance, 181 CC structures per condition with connectivity 8 and ImageSize
181x217, exact reconstruction of every slice from PixelIdxList, disjoint components covering all
candidate pixels, saved structures reload identically, masks / config.m unchanged, no GT /
regionprops / filtering / morphology / thresholding / 3D components).
```

#### Quantitative Results

```text
                                 pn0      pn3
Slices analysed                  181      181
Slices with / without components 121 / 60 117 / 64
First / last slice with components 12 / 144  28 / 144
Total 2D component instances     1,210    1,068
Components per slice min / max   0 / 20   0 / 21
Mean / median per slice (all 181) 6.6851 / 5   5.9006 / 5
pn0 has components at k = 12-13 and 25-26 separated by empty slices 14-24 and 27; pn3 is
contiguous from 28 to 144.
```

#### Lesion-Level Results

```text
Not computed (no GT, no matching).
```

#### Visual Results

```text
results/figures/exp034_components2d_{pn0,pn3}.png (k = 46, 91, 102, 136; label colours display only)
results/figures/exp034_component_count_by_slice.png
At k = 91 the ventricle-compatible region appears as several separate 2D components (its parts
are disconnected in-plane), next to small compact components.
```

#### Comparison with Reference

```text
Not applicable.
```

#### Interpretation

```text
The component-count profile is similar in pn0 and pn3 (most components around k = 50-105, up to
about 20 per slice). total2DComponents counts slice-wise component instances and is NOT the number
of unique MS lesions: a structure spanning several slices is counted once per slice, and one
in-plane structure may be split into several components.
```

#### Decision

```text
2D COMPONENTS IDENTIFIED; saved for Phase 68. No filtering, no properties, no GT, no 3D
connectivity; config.m unchanged.
```

#### Next Experiment

```text
Phase 68 - component properties (not started).
```

#### Notes

```text
Development data only; no held-out data.
```

---

### EXP-035 — Phase-68 2D component property extraction

#### Status

```text
COMPLETED - PROPERTY TABLE ESTABLISHED (no filtering decision)
```

#### Date

```text
2026-10-11
```

#### Objective

```text
Describe every Phase-67 2D component instance with the course-supported regionprops properties
Area, Centroid and BoundingBox.
```

#### Hypothesis

```text
None (descriptive).
```

#### Baseline / Reference

```text
Input: data/processed/phase67_t2_{pn0,pn3}_components2d.mat (ccBySlice, EXP-034, 8-connectivity,
2D axial slice-wise) on the Phase-65 selected opening masks (EXP-026 + opening square3).
```

#### Dataset Configuration

```text
pn0 + pn3 development. GT not used.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
Saved Phase-67 component structures (not recomputed); Phase-65 masks for checks and figures only.
```

#### Processing Pipeline

```text
for each slice: regionprops(ccBySlice{k}, 'Area', 'Centroid', 'BoundingBox') -> one row per
component (order of PixelIdxList preserved); independent validation against PixelIdxList.
```

#### Changed Component

```text
None (description only; masks and components unchanged).
```

#### Parameters

```text
Properties: Area, Centroid, BoundingBox only. MATLAB conventions kept: Centroid = [x column,
y row]; BoundingBox = [x, y, width, height] with origin at the outer pixel edge (min - 0.5).
```

#### Implementation

```text
src/segmentation/extractComponentProperties2D.m
experiments/component_properties_2d_check.m (synthetic, 15/15 ok)
experiments/exp035_component_properties.m
Outputs: data/processed/phase68_t2_{pn0,pn3}_component_properties.mat (componentTable, metadata)
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-11. All 44 checks PASS: provenance, 181 CC structures, rows = EXP-034 totals and
per-slice NumObjects, indices 1..NumObjects in PixelIdxList order, Area = numel(PixelIdxList),
Centroid = mean column/row, BoundingBox = min/max -0.5 (tolerance 1e-12), values inside the image,
per-slice Area sums = Phase-67 candidateVoxels, total Area = nnz(Phase-65 mask), inputs unchanged,
regionprops only in the function with exactly 3 properties, no GT / CC recomputation / filtering /
morphology / thresholding / 3D / intensity.
```

#### Quantitative Results

```text
                              pn0                 pn3
Rows (2D component instances) 1,210               1,068
Total Area (= candidate voxels) 70,878            67,066
Area min / max                9 / 1,332           9 / 1,328
Area mean / median / std      58.58 / 18 / 122.05 62.80 / 18 / 128.70
Instances with Area = 9 *    345 (28.5 %)        303 (28.4 %)
Centroid X (column) range     33 - 191.91         28 - 191
Centroid Y (row) range        26 - 155            28.5 - 155
BoundingBox width range       3 - 74              3 - 73
BoundingBox height range      3 - 56              3 - 56
* counted afterwards from results/metrics/exp035_component_properties.csv (areaPixels == 9);
  not computed by the script.
```

#### Lesion-Level Results

```text
Not computed (no GT, no matching).
```

#### Visual Results

```text
results/figures/exp035_component_area_rank.png (sorted Area, log scale, no threshold)
results/figures/exp035_component_properties_{pn0,pn3}.png (k = 46, 91, 102, 136; display transposed)
```

#### Comparison with Reference

```text
Not applicable.
```

#### Interpretation

```text
The Area distribution is strongly right-skewed: about 28 % of the instances have the minimum
Area 9 and half have at most 18 pixels (median), while a few instances reach about 1,330 pixels
(the large compact regions visible in the central slices). Area >= 9 and width/height >= 3 follow
from the square-3x3 opening (every surviving pixel lies in a 3x3 square inside the component);
this is a consequence of the morphology, not a filter; the distribution is conditioned by the
opening, so 9 or 18 are not natural thresholds for Phase 69. pn0 and pn3 have very similar ranges.
Rows are 2D slice-wise instances, not unique 3D lesions.
```

#### Decision

```text
PROPERTY TABLE ESTABLISHED. No filtering, classification or threshold. The Phase-68 property table
provides the descriptive basis for the Phase-69 false-positive filtering analysis.
```

#### Next Experiment

```text
Phase 69 - false-positive filtering analysis (not started).
```

#### Notes

```text
Development data only; no held-out data; config.m unchanged.
```

---

### EXP-036 — Phase-69 conservative component-area filtering probe

#### Pre-registration (written before EXP-036 was run and before any EXP-036 GT evaluation)

```text
Question: does removing only the minimum-area post-opening 2D component class (Area = 9 pixels)
reduce false positives enough to improve the development score?
Motivation (GT-free, Phase 68): minimum Area = 9 in both pn0 and pn3; the square-3x3 opening shapes
the size distribution; removing only the minimum class is the weakest non-trivial area rule.
Geometric note (GT-free): after a square-3x3 opening every component contains a full 3x3 square, so
an Area-9 component is exactly one 3x3 square (a structure that survived the erosion as a single
pixel). Checked in the script.
Rule: remove Area == 9, keep Area > 9; whole components only, from the saved Phase-67 PixelIdxList
and Phase-68 areaPixels (no bwconncomp / regionprops recomputation). Same rule for pn0 and pn3.
Precondition: min(areaPixels) == 9 in both conditions, otherwise TECHNICALLY BLOCKED (no change of
the threshold).
Properties used: Area only. Centroid, BoundingBox, intensity, slice index: NOT USED. Connectivity 8,
2D axial slice-wise. No threshold sweep, no second rule.
Order: both filtered masks saved before GT is loaded.
Evaluation: full-volume Dice, DevelopmentScore; no near-tie tolerance.
Decision: filtered > unfiltered -> PROVISIONALLY RETAINED FOR PHASE 70 (small-lesion protection);
< -> REJECTED; = -> not retained. Area-9 instances are not assumed to be noise.
```

#### Status

```text
COMPLETED - EXP-036 AREA-9 FILTER PROVISIONALLY RETAINED FOR PHASE 70 ANALYSIS
```

#### Date

```text
2026-10-11
```

#### Objective

```text
Test one pre-registered conservative component filter: remove the minimum-area (Area = 9) 2D
component instances of the Phase-65 mask, keep Area > 9.
```

#### Hypothesis

```text
None beyond the pre-registered question; Area-9 instances were not assumed to be noise.
```

#### Baseline / Reference

```text
Unfiltered Phase-65 mask (= Phase-66 retained morphology): DevelopmentScore 0.0568453350591327.
```

#### Dataset Configuration

```text
pn0 + pn3 development; GT label 10 loaded only after both filtered masks were saved.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
Phase-65 masks, Phase-67 ccBySlice (EXP-034), Phase-68 componentTable (EXP-035).
```

#### Processing Pipeline

```text
check min Area == 9 -> keep whole components with areaPixels > 9 (Phase-67 PixelIdxList) ->
save 2 masks -> GT -> full-volume Dice, DevelopmentScore, removed TP/FP.
```

#### Changed Component

```text
Component filter added after the retained opening (Area only).
```

#### Parameters

```text
Remove Area == 9 / keep Area > 9; Area only; connectivity 8, 2D; same rule for pn0 and pn3.
```

#### Implementation

```text
src/segmentation/filterComponentsByArea2D.m
experiments/component_area_filter_check.m (synthetic, 16/16 ok)
experiments/exp036_conservative_area_filter.m
Outputs: data/processed/exp036_t2_{pn0,pn3}_area9_filtered_candidate.mat
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-11. All 52 checks PASS: provenance, Phase-68 rows map to PixelIdxList,
min Area == 9 in both conditions, removed components all Area 9 and exact 3x3 squares, retained
all > 9, removed voxels = 9 x removed components, filtered subset of source, masks saved before
GT, TP/FP/FN algebra, unfiltered Dice = Phase 65/66, inputs and config.m unchanged, no
recomputation / centroid / box / intensity / morphology / threshold.
```

#### Quantitative Results

```text
                                 pn0                     pn3
Components before / removed / kept 1,210 / 345 / 865      1,068 / 303 / 765
Fraction of components removed   28.5 %                  28.4 %
Candidate voxels before / removed / after 70,878 / 3,105 / 67,773   67,066 / 2,727 / 64,339
Fraction of voxels removed       4.4 %                   4.1 %
Unfiltered TP / FP / FN          2,107 / 68,771 / 1,405  2,013 / 65,053 / 1,499
Filtered TP / FP / FN            2,071 / 65,702 / 1,441  1,971 / 62,368 / 1,541
Removed TP / FP                  36 / 3,069              42 / 2,685
Removed voxels that are FP       98.8 %                  98.5 %
FP removed per TP lost           85.25                   63.93
Dice before -> after             0.056647 -> 0.058105    0.057043 -> 0.058098
Weaker-condition Dice 0.056647 -> 0.058098; DevelopmentScore 0.056845 -> 0.058101 (+0.0012560).
```

#### Lesion-Level Results

```text
Not computed (no component-to-lesion matching).
```

#### Visual Results

```text
results/figures/exp036_area9_filter_{pn0,pn3}.png, exp036_area9_removed_errors_{pn0,pn3}.png,
exp036_area9_filter_by_slice.png. The removed instances are isolated 3x3 squares scattered in the
parenchyma and along sulcal/cortical bright structures; almost all removed voxels are non-lesion
at the fixed slices. The large fluid-like regions are untouched.
```

#### Comparison with Reference

```text
Improvement in both conditions (pn0 +0.001457, pn3 +0.001055).
```

#### Interpretation

```text
Removing about 28 % of the 2D component instances (about 4 % of the candidate voxels) removes
almost only FP, so Dice rises slightly in both conditions. The cost is real: 36 / 42 GT lesion voxels
contained in minimum-size (9-pixel) 2D candidate components are removed (FN +36 / +42); whether
these components are whole small lesions, 2D sections of lesions continuing on other slices or
peripheral fragments is not yet determined (no component-to-lesion matching). The dominant dense
fluid-like FP are unaffected: if retained, the filter only refines the candidate mask. The gain is small and must be weighed against small-lesion
protection in Phase 70.
```

#### Decision

```text
EXP-036 AREA-9 FILTER = PROVISIONALLY RETAINED FOR PHASE 70 ANALYSIS (DevelopmentScore 0.058101 >
0.056845, no tolerance). Not final; not a frozen parameter; config.m unchanged. No other threshold
tested.
```

#### Next Experiment

```text
Phase 70 - small-lesion protection (not started).
```

#### Notes

```text
Area-9 instances were not assumed to be noise before GT; no component-level lesion matching; no
held-out data.
```

---

### EXP-037 — Phase-70 small-lesion protection audit

#### Pre-registration (written before EXP-037 was run)

```text
Input predictions (frozen, not regenerated): BEFORE = Phase-65 opening masks; AFTER = EXP-036
Area-9 filtered masks. Filter rule already fixed in Phase 69. New segmentation parameters: NONE.
GT: evaluation only. GT components: 2D axial, bwconncomp 8-connectivity, evaluation code only
(src/evaluation). Small-lesion area threshold: NONE (GT Area reported as a continuous variable).
Primary protection constraint: zero GT 2D components with overlapBefore > 0 and overlapAfter == 0
("newly completely lost") in BOTH pn0 and pn3.
Decision: A) no reproduced strict DevelopmentScore improvement -> REJECT; B) improvement but
newly completely lost > 0 in pn0 or pn3 -> REJECT (pipeline reverts to Phase-65 masks, no
component filtering); C) improvement and zero complete losses in both -> RETAIN for subsequent
development. No partial-loss threshold, no rescue rule, no larger area threshold, no spatial
exception, no hybrid mask. A 2D GT component is not a unique 3D lesion; this is not the final
lesion-level evaluation.
```

#### Status

```text
COMPLETED - SMALL-LESION PROTECTION FAILED -> EXP-036 AREA-9 FILTER REJECTED
```

#### Date

```text
2026-10-11
```

#### Objective

```text
Audit whether the provisional EXP-036 Area-9 filter removes all predicted support of any 2D GT
lesion component that was represented before filtering.
```

#### Hypothesis

```text
None (pre-registered protection constraint).
```

#### Baseline / Reference

```text
BEFORE: Phase-65 opening masks; AFTER: EXP-036 Area-9 filtered masks (both frozen).
```

#### Dataset Configuration

```text
pn0 + pn3 development; GT label 10, evaluation only; 2D GT components with 8-connectivity.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
data/processed/phase65_t2_{pn0,pn3}_selected_opening_candidate.mat;
data/processed/exp036_t2_{pn0,pn3}_area9_filtered_candidate.mat; GT.
```

#### Processing Pipeline

```text
verify provenance and AFTER subset of BEFORE -> GT -> bwconncomp(gt slice, 8) per axial slice
(evaluation only) -> per GT component overlap before/after -> categories, area statistics ->
reproduce EXP-036 Dice / DevelopmentScore -> pre-registered decision. No mask generated or saved.
```

#### Changed Component

```text
None (audit only).
```

#### Parameters

```text
None new. GT connectivity 8 (project convention). No lesion-size threshold.
```

#### Implementation

```text
src/evaluation/auditSmallLesionProtection2D.m
experiments/small_lesion_protection_2d_check.m (synthetic, 16/16 ok; first run stopped on a test
volume that MATLAB treats as 2D (false(5,5,1)); fixed to 2 slices)
experiments/exp037_small_lesion_protection.m
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-11. All 38 checks PASS: provenance, AFTER subset of BEFORE, one row per GT 2D
component (areas sum to GT voxels), overlap formulas, category E = 0, categories cover all
components, sums of overlaps = TP before / after, removed overlap = removedTP = EXP-036 (36 / 42),
Dice and DevelopmentScores reproduce EXP-036, masks / GT / config.m unchanged, no new prediction /
filter / component / morphology / threshold / save.
```

#### Quantitative Results

```text
                                         pn0                 pn3
GT 2D component instances                328                 328
  GT Area min / median / mean / max      1 / 5 / 10.71 / 90  (same GT)
With non-zero overlap before / after     126 / 123           120 / 116
Affected by the filter                   4                   5
Partially reduced (still represented)    1 (Area 43)         1 (Area 43)
NEWLY COMPLETELY LOST                    3                   4
  GT Area of lost components             13, 14, 22          13, 13, 17, 20
  (overlap before 7-9 voxels, i.e. one 3x3 square; slices pn0 88, 105, 113; pn3 94, 104, 105, 107)
TP before / after / removed              2,107 / 2,071 / 36  2,013 / 1,971 / 42
Fraction of before TP retained           98.3 %              97.9 %
Dice before -> after                     0.056647 -> 0.058105  0.057043 -> 0.058098
DevelopmentScore 0.056845 -> 0.058101 (+0.001256), reproduced.
```

#### Lesion-Level Results

```text
Not computed (this 2D audit is not the final lesion-level protocol).
```

#### Visual Results

```text
results/figures/exp037_gt_area_vs_coverage_change_{pn0,pn3}.png, exp037_affected_gt_area_rank.png,
exp037_fixed_slice_audit_{pn0,pn3}.png. None of the complete losses falls on the fixed slices
(46, 91, 102, 136); they are documented in the audit table, no slice was added post hoc.
```

#### Comparison with Reference

```text
Development improved, protection constraint failed in both conditions.
```

#### Interpretation

```text
The filter's Dice gain comes partly at the cost of removing the only predicted support of 3 (pn0)
/ 4 (pn3) GT lesion cross-sections of 13-22 pixels, each represented only by a single 3x3
candidate square. Descriptively, the most severe damage falls on relatively small GT
2D components: the completely lost ones have Area 13-22 (pn0) / 13-20 (pn3) pixels, while the
affected components overall reach 43 pixels (no formal small-lesion threshold implied). Only about 38 % of GT 2D components (126 / 120 of
328, median Area 5 overall) had any support before filtering: small cross-sections are already
largely missed by the candidate mask and the opening.
```

#### Decision

```text
REJECT_AREA9_FILTER (case B: development improved but small-lesion protection failed: 3 / 4 newly
completely lost GT 2D components). EXP-036 is rejected for the core development pipeline; the
retained development pipeline reverts globally to the Phase-65 opening masks with NO component
filtering. No alternative threshold, rescue rule or spatial exception; config.m unchanged.
```

#### Next Experiment

```text
Phase 71 - complete predicted-volume reconstruction (not started).
```

#### Notes

```text
A 2D GT component is a lesion cross-section, not a unique 3D lesion; GT Area was not used to create
or modify the filter. No held-out data.
```

---

### EXP-038 — Phase-71 complete predicted-volume reconstruction

#### Status

```text
COMPLETED - REPRESENTATION ESTABLISHED (M_pred = Phase-65 retained prediction, exact identity)
```

#### Date

```text
2026-10-12
```

#### Objective

```text
Assemble the retained slice-wise prediction into the complete logical 3D volume M_pred(x,y,z).
```

#### Hypothesis

```text
None (representation / integrity stage).
```

#### Baseline / Reference

```text
Retained source: data/processed/phase65_t2_{pn0,pn3}_selected_opening_candidate.mat (EXP-026
candidates + standard 2D opening square3, no component filtering). EXP-036 (Area-9 filter) was
rejected by EXP-037 / Phase 70 and is not used.
```

#### Dataset Configuration

```text
pn0 + pn3 development. GT not used.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
Phase-65 masks; results/metrics/exp037_phase70_decision.csv (REJECT_AREA9_FILTER verified).
```

#### Processing Pipeline

```text
verify Phase-70 decision -> split the source into 181 axial logical slice masks ->
assemblePredictedVolume (cat along dimension 3, order preserved) -> M_pred -> exact identity checks
-> save. No segmentation operation.
```

#### Changed Component

```text
None (representation only).
```

#### Parameters

```text
None.
```

#### Implementation

```text
src/segmentation/assemblePredictedVolume.m
experiments/predicted_volume_assembly_check.m (synthetic, 12/12 ok)
experiments/exp038_reconstruct_predicted_volume.m
Outputs: data/processed/phase71_t2_{pn0,pn3}_predicted_volume.mat (M_pred, metadata)
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-12. All 33 checks PASS: Phase-70 decision reproduced, source provenance, source not
EXP-036, 181 logical 181x217 slices, M_pred logical 181x217x181 and exactly equal to the source
(volume and every slice, order preserved, voxel counts equal, xor empty), empty / non-empty slices
preserved, saved M_pred reloads with Phase 71 / EXP-038 metadata, masks and config.m unchanged,
no GT / metric / components / filter / morphology / threshold.
```

#### Quantitative Results

```text
                         pn0          pn3
M_pred size / class      181x217x181 logical   181x217x181 logical
Predicted voxels         70,878       67,066
Non-empty / empty slices 121 / 60     117 / 64
First / last non-empty   12 / 144     28 / 144
Exact identity           true         true
```

#### Lesion-Level Results

```text
Not computed.
```

#### Visual Results

```text
results/figures/exp038_predicted_volume_identity_{pn0,pn3}.png (k = 1, 46, 91, 136, 181: source,
M_pred, empty xor difference).
```

#### Comparison with Reference

```text
Identical to the Phase-65 source; voxel-level performance therefore equals Phase 65 (not recomputed).
```

#### Interpretation

```text
Phase 71 did not create a new 3D segmentation: it formalized the existing prediction as M_pred,
rebuilt explicitly from the slices with voxel-by-voxel identity; the 2D -> 3D step adds no
information. M_pred is the canonical complete-volume representation of the current development pipeline:
EXP-026 candidate generation + Phase-65 standard 2D opening square3 + no component filtering.
```

#### Decision

```text
REPRESENTATION ESTABLISHED. No segmentation decision; pipeline not frozen; config.m unchanged.
```

#### Next Experiment

```text
Phase 72 - 3D connected-component analysis (not started).
```

#### Notes

```text
No GT, no metrics, no 2D/3D connected components, no held-out data.
```

---

### EXP-039 — Phase-72 3D connected-component analysis

#### Status

```text
COMPLETED - 3D CANDIDATE COMPONENTS ESTABLISHED (structural representation; M_pred unchanged)
```

#### Date

```text
2026-10-12
```

#### Objective

```text
Represent the canonical Phase-71 M_pred as 26-connected 3D candidate components (objects that may
extend across axial slices), without modifying any prediction voxel.
```

#### Hypothesis

```text
None (structural analysis).
```

#### Baseline / Reference

```text
Input: data/processed/phase71_t2_{pn0,pn3}_predicted_volume.mat (EXP-026 + Phase-65 standard 2D
opening square3, no component filtering; EXP-036 rejected in Phase 70).
```

#### Dataset Configuration

```text
pn0 + pn3 development. GT not used.
```

#### Development or Test Data

```text
DEVELOPMENT
```

#### Input

```text
Phase-71 M_pred; Phase-67 2D component totals (descriptive comparison only).
```

#### Processing Pipeline

```text
CC3D = bwconncomp(M_pred, 26) once per complete volume -> minimal descriptors from PixelIdxList +
ind2sub (voxelCount, first/last slice, sliceSpan, occupiedSliceCount) -> exact reconstruction check.
```

#### Changed Component

```text
None (representation only).
```

#### Parameters

```text
Connectivity 26, fixed before analysis without GT: full-neighbourhood volumetric analogue of the 2D
8-connectivity used since Phase 61/67; isotropic 1 mm voxels; keeps candidates that continue
diagonally between slices connected. No 6/18/26 comparison.
Course classification: volumetric extension of course-supported connected-component analysis and
bwconncomp; the verified course material demonstrates connected components in 2D and 26-connectivity
is not claimed to be taught there (ALLOWED_TECHNIQUES section 10, EXP-039 note).
```

#### Implementation

```text
src/segmentation/extractConnectedComponents3D.m
experiments/connected_components_3d_check.m (synthetic, 18/18 ok)
experiments/exp039_connected_components_3d.m
Outputs: data/processed/phase72_t2_{pn0,pn3}_components3d.mat (CC3D, componentTable, metadata)
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-12. All 38 checks PASS (rerun with the added check occupiedSliceCount == sliceSpan,
no z gaps, for every component; identical results): provenance (Phase 71 / EXP-038, EXP-026 + square3, no
filtering, EXP-036 rejected), one bwconncomp call per complete volume with connectivity 26 and
ImageSize 181x217x181, non-empty valid disjoint PixelIdxList, exact reconstruction of M_pred, voxel
sum = nnz(M_pred), consistent slice descriptors, M_pred / config.m unchanged, saved artifacts
reload identically, no GT / regionprops3 / filter / morphology / threshold / metric.
```

#### Quantitative Results

```text
                                   pn0                      pn3
Predicted voxels                   70,878                   67,066
Phase-67 2D component instances    1,210                    1,068
3D candidate components (26-conn.) 335                      291
Single-slice / multi-slice         170 / 165 (50.7 / 49.3 %)  148 / 143 (50.9 / 49.1 %)
Voxel count min / median / mean / max   9 / 21 / 211.58 / 25,629   9 / 21 / 230.47 / 25,417
Occupied slices min / median / mean / max  1 / 1 / 2.73 / 70   1 / 1 / 2.71 / 40
Largest sliceSpan                  70                       40
```

#### Lesion-Level Results

```text
Not computed (no GT, no matching).
```

#### Visual Results

```text
results/figures/exp039_components3d_{pn0,pn3}.png (maximum-label orthogonal projections),
exp039_components3d_slices_{pn0,pn3}.png (k = 46, 91, 102, 136), exp039_component3d_voxelcount_rank.png,
exp039_component3d_slice_span_rank.png. The few largest components are extended structures in the
central slices (visually compatible with the ventricular system and midline/fissural fluid-like
regions); many small compact components are scattered through the parenchyma.
```

#### Comparison with Reference

```text
Volumetric connectivity groups the 1,210 / 1,068 slice-wise 2D instances into 335 / 291 3D candidate
components (3.61 / 3.67 2D instances per 3D component).
```

#### Interpretation

```text
About half of the 3D candidate components occupy a single slice; very large multi-slice
components are present (largest 25,629 / 25,417 voxels vs. median 21), consistent with the
persistent bright fluid-like structures of earlier phases (qualitative visual observation, not an
algorithmic anatomical identification). The reported
3D components are predicted candidate objects; their count must not be interpreted as the number of
confirmed MS lesions.
```

#### Decision

```text
3D CANDIDATE COMPONENTS ESTABLISHED. No component removed; M_pred unchanged; no GT; config.m
unchanged. Not a lesion count.
```

#### Next Experiment

```text
Phase 73 - region-growing decision (not started).
```

#### Notes

```text
Development data only; no held-out data; no regionprops3.
```

---

### Phase 73 — Region-growing applicability decision (decision entry, no experiment ID)

```text
Date: 2026-10-12.
Question: should region growing be introduced into the current lesion-segmentation pipeline?
Course compatibility: YES (seeds, similarity predicate Q, connectivity to the seeds, stop when no
neighbour satisfies the predicate; intensity-difference similarity).
Roadmap prerequisite: thresholding must provide high-confidence lesion cores while underestimating
their spatial extent. FN alone are not sufficient.
Script: experiments/phase73_region_growing_decision.m (reads saved CSVs / metadata only; no image
processing, GT, seeds, growth, prediction or save; 9/9 checks PASS).
Evidence (retained pipeline, EXP-033 after morphology + EXP-039):
  pn0: candidates 70,878; TP 2,107 / FP 68,771 / FN 1,405 (GT 3,512); 335 3D candidate components,
       largest 25,629 voxels, max 70 occupied slices.
  pn3: candidates 67,066; TP 2,013 / FP 65,053 / FN 1,499; 291 components, largest 25,417, max 40.
  Phase 70: small-lesion protection failed for the Area-9 filter (EXP-037).
Indicators: extent limitation observed (FN > 0) = true; FP burden (FP > TP) = true; large ambiguous
candidates (largest 3D candidate object > total GT lesion volume) = true; small-lesion concern = true.
Core reliability: FAIL. Prerequisite satisfied: false.
Dominant limitation: very large FP burden and persistent bright fluid-like ambiguous candidate
structures; growth from these non-specific seeds would risk enlarging false positives.
DECISION: DO_NOT_INTRODUCE_REGION_GROWING. Phases 74-77: SKIPPED BY PHASE-73 DECISION (not executed).
No new algorithm, parameter or prediction; no GT-derived seed; no held-out data; M_pred and
config.m unchanged. Region growing remains allowed and course-supported, not activated here.
Outputs: results/metrics/phase73_region_growing_evidence.csv, phase73_region_growing_decision.csv.
```

---

### EXP-040 — Phase-78 individual-modality segmentation benchmark

#### Pre-registration (written before EXP-040 was run and before any EXP-040 GT evaluation)

```text
Development data: msles2 1 mm rf0, pn0 + pn3 only. PD pn3 downloaded on 2026-10-12 for this
experiment (official BrainWeb; SHA-256 8c2ce715...3bb2d61; little-endian 0...4095); config.m gained
only its data path (cfg.dataset.noisyMriFiles.pn3.PD). Held-out data not downloaded.
Modalities: T1 / T2 / PD, each alone. Same architecture for all:
  brain support EXP-021 (same mask for T1/T2/PD within a condition); uint16 -> double -> /4095;
  preprocessing NONE; multithresh(volume(brainMask), 2) -> imquantize -> 3 classes;
  predeclared candidates: Class 1 only, Class 2 only, Class 3 only (no combinations, no other N);
  one 2D axial standard opening strel('square',3), then AND brainMask; no component filtering, no
  region growing, no multimodal fusion.
All 3 x 3 x 2 = 18 predictions saved before GT is loaded. Integrity: T2 Class 3 must equal the
Phase-71 M_pred exactly (pn0, pn3), otherwise TECHNICALLY BLOCKED.
Phase-41 GT intensity statistics are known from earlier phases but are NOT used: all three classes are
generated symmetrically for every modality, and only development Dice selects among them.
Evaluation: GT label 10, not intersected with brainMask; full-volume Dice; DevelopmentScore =
(pn0 + pn3)/2; weakerConditionDice = min. No near-tie tolerance; exact tie -> higher weaker-condition
Dice; a remaining exact tie is reported as unresolved. Best class selected within each modality, then
modalities ranked by their selected DevelopmentScore. No fusion, no Phase 79-81 work.
```

#### Status

```text
COMPLETED
```

#### Date

```text
2026-10-12
```

#### Objective

```text
Compare T1, T2 and PD as individual lesion-candidate sources under one identical architecture, and
check whether T2 (provisional modality since Phase 41) is the best single modality on development
data.
```

#### Hypothesis

```text
None numerical. Open question: is T2 Class 3 the best single-modality candidate, or does another
modality/class give a higher DevelopmentScore under the same pipeline?
```

#### Baseline / Reference

```text
Retained pipeline: Phase-71 M_pred (T2, EXP-026 multithresh N = 2 Class 3, square3 opening, no
component filtering), DevelopmentScore 0.056845 (EXP-033).
```

#### Dataset Configuration

```text
msles2, 1 mm, rf0, T1 / T2 / PD, pn0 + pn3 (PD pn3 added in this phase). GT: phantom_1.0mm_msles2_crisp,
label 10 (3,512 voxels).
```

#### Development or Test Data

```text
Development only (pn0 + pn3). Held-out pn1/pn5/pn7/pn9 not downloaded or referenced.
```

#### Input

```text
data/raw/msles2/mri/{t1,t2,pd}_ai_msles2_1mm_{pn0,pn3}_rf0.raws; EXP-021 brain masks;
Phase-71 M_pred (integrity reference only).
```

#### Processing Pipeline

```text
Per modality and condition: /4095 -> multithresh(volume(brainMask), 2) -> imquantize -> Class c AND
brainMask (c = 1, 2, 3) -> per-slice imopen strel('square',3) -> AND brainMask.
```

#### Changed Component

```text
Lesion-candidate source modality (T1 / T2 / PD) and candidate class (1 / 2 / 3).
```

#### Parameters

```text
All fixed before the run (N = 2, square3, EXP-021). Thresholds are algorithm outputs per volume.
```

#### Implementation

```text
experiments/exp040_individual_modality_benchmark.m (no new src function).
Outputs: data/processed/exp040_{t1,t2,pd}_{pn0,pn3}_class{1,2,3}_opened_candidate.mat (18 frozen
predictions); data/processed/phase78_{t1,t2,pd}_{pn0,pn3}_selected_single_modality.mat (exact
copies of each modality's selected class).
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-12. All 90 checks PASS: 6 MRI files present; masks / M_pred valid; per volume:
finite [0,1] volume, multithresh on brain voxels only, two increasing thresholds, classes 1-3
partition the brain mask, raw candidates inside the brain and opened candidates subsets of them,
raw MRI unchanged; 18 predictions saved before GT; T2 Class 3 = Phase-71 M_pred exactly (pn0 and
pn3); Dice in [0,1] on the full volume; DevelopmentScore = exact mean; aliases = frozen winners;
GT / masks / M_pred / config.m unchanged; no held-out reference; no filtering / components /
region growing / preprocessing call.
Cosmetic fix after the run (no effect on numbers): the selection markers in
exp040_single_modality_candidate_scores.png were listed in the legend as "data1-3"; the script now
hides them from the legend (the saved PNG shows the old legend until a rerun).
```

#### Quantitative Results

```text
Thresholds (raw-equivalent, t1 / t2):
  T1 pn0 1394.40 / 2005.27   T1 pn3 1294.58 / 1868.49
  T2 pn0 2194.60 / 2956.67   T2 pn3 1993.98 / 2696.31
  PD pn0 3291.89 / 3542.71   PD pn3 3020.06 / 3290.15

Modality Class  Cond  Voxels    TP     FP        FN     Dice
T1       1      pn0      70,777     3    70,774  3,509  0.000081
T1       1      pn3      67,433     7    67,426  3,505  0.000197
T1       2      pn0     732,163   988   731,175  2,524  0.002686
T1       2      pn3     702,752   585   702,167  2,927  0.001657
T1       3      pn0     651,125 1,540   649,585  1,972  0.004705
T1       3      pn3     635,646 1,232   634,414  2,280  0.003855
T2       1      pn0     660,499     0   660,499  3,512  0
T2       1      pn3     614,133     0   614,133  3,512  0
T2       2      pn0     715,184   175   715,009  3,337  0.000487
T2       2      pn3     590,061   154   589,907  3,358  0.000519
T2       3      pn0      70,878 2,107    68,771  1,405  0.056647
T2       3      pn3      67,066 2,013    65,053  1,499  0.057043
PD       1      pn0     515,881     0   515,881  3,512  0
PD       1      pn3     389,518     1   389,517  3,511  0.000005
PD       2      pn0      56,402     0    56,402  3,512  0
PD       2      pn3      21,965     8    21,957  3,504  0.000628
PD       3      pn0     788,306 2,885   785,421    627  0.007287
PD       3      pn3     163,225 2,131   161,094  1,381  0.025561

Selected class per modality (DevelopmentScore / weaker-condition Dice), no exact tie:
  T2 Class 3  0.056845 / 0.056647   rank 1
  PD Class 3  0.016424 / 0.007287   rank 2
  T1 Class 3  0.004280 / 0.003855   rank 3
```

#### Lesion-Level Results

```text
Not computed.
```

#### Visual Results

```text
results/figures/exp040_single_modality_candidate_scores.png, exp040_selected_modality_dice.png,
exp040_selected_modalities_{pn0,pn3}.png (k = 46, 91, 102, 136; TP yellow, FP red, FN green).
Qualitative observation only: T1 Class 3 covers most of the bright white-matter region; PD Class 3
in pn0 covers broad cortical/grey-matter-like regions plus the large bright / fluid-like central
structures, while in pn3 it is a sparse scattering of small blocks plus those structures; T2 Class
3 is the known Phase-71 candidate (bright / fluid-like regions plus periventricular candidates).
Visual observation, no anatomical identification.
```

#### Comparison with Reference

```text
T2 Class 3 reproduces the retained pipeline exactly (0.056845). The next-best single modality, PD
Class 3, has DevelopmentScore 0.016424 and weaker-condition Dice 0.007287; T1 Class 3 0.004280.
```

#### Interpretation

```text
Data: PD Class 3 has the most TP of any candidate (2,885 in pn0, FN 627), but with 785,421 FP; its
candidate size differs strongly between conditions (788,306 vs 163,225 voxels, ratio 4.83 computed
afterwards from the CSV), so its Dice differs by condition (0.007287 vs 0.025561). T1 never gives
a compact candidate: Classes 2 and 3 cover 635,646-732,163 voxels.
Classes 1-2: very low performance. The highest Dice among them is 0.002686 (T1 Class 2, pn0), with
988 TP but 731,175 FP; for T2 and PD, Classes 1-2 keep very little lesion signal after the opening
(at most 175 TP, T2 Class 2; PD Class 2 at most 8). More TP is not a better segmentation when it
comes with hundreds of thousands of FP.
Interpretation (not tested): in this architecture only T2 places the lesions in a small high-
intensity top class (well supported by the results). PD Class 3 is strongly sensitive to the
pn0/pn3 condition (size and Dice); no causal explanation is claimed. PD Class 3 intercepts more GT
lesion voxels than any other candidate in both conditions but is not specific on its own; how much
of this signal is complementary to T2 is not yet known. With this 3-class multithresh partition, T1 does not
produce a class specific enough for the lesions.
Scope: single-modality candidates under this one architecture (multithresh N = 2, single class,
square3 opening). It does not say whether PD or T1 can add information to T2 in a fusion.
```

#### Decision

```text
BEST INDIVIDUAL MODALITY (development): T2, Class 3. The retained pipeline (Phase-71 M_pred) is
confirmed unchanged. config.m was updated before the run only to record the PD pn3 file path; no
segmentation, threshold, morphology or selection parameter was modified (modality stays T2). No
fusion.
```

#### Next Experiment

```text
Phase 79 (multimodal) - not started.
```

#### Notes

```text
Development data only. PD pn3 download documented in DOWNLOAD_INFO.txt and
docs/BRAINWEB_DATASET_NOTES.md section 13.53. Phase-41 GT statistics not used.
```

---

### Phase 79 — Multimodal combination selection (decision entry, no experiment ID)

#### Decision rule (written before the Phase-79 script was run)

```text
Date: 2026-10-12. Question: which second modality should be paired with T2 for the first controlled
multimodal experiment (Phase 80 defines HOW, Phase 81 tests WHETHER it helps)?
Evidence: only the saved EXP-040 / Phase-78 CSVs (no MRI, no GT, no new mask, no fusion, no
multimodal Dice). EXP-041 is kept free for the Phase-80 fusion experiment.
Rule:
  primary   = the modality with individual rank 1 (expected T2);
  secondary = the modality with individual rank 2, PROVIDED it also has more TP than the remaining
              candidate in BOTH pn0 and pn3 (supporting evidence of retained lesion signal);
  if the two indicators disagree -> no automatic choice, user decision required.
No new score, weight or optimization metric. Complementarity is NOT established by this rule: the
TP counts do not say whether the secondary modality's TP are voxels missed by T2 (that would need
mask overlap, i.e. fusion, which is out of scope here).
```

#### Result

```text
Script: experiments/phase79_select_modality_combination.m (reads the EXP-040 CSVs; loads the T2
Class 3 / M_pred masks only for an identity check; no MRI, GT, threshold, morphology, fusion or
save of masks). 24/24 checks PASS (ranking reproduced from the per-class CSV, no tie, T2 Class 3 =
M_pred, no AND/OR/XOR between masks, no multimodal Dice, M_pred unchanged, config.m without fusion
fields and with unchanged segmentation parameters, no held-out reference).
                 rank  class  DevScore  Dice pn0 / pn3       TP pn0 / pn3   FP pn0 / pn3
  T2 (primary)    1     3     0.056845  0.056647 / 0.057043  2,107 / 2,013   68,771 / 65,053
  PD (secondary)  2     3     0.016424  0.007287 / 0.025561  2,885 / 2,131  785,421 / 161,094
  T1 (not sel.)   3     3     0.004280  0.004705 / 0.003855  1,540 / 1,232  649,585 / 634,414
TP-support condition: PD > T1 in pn0 (2,885 > 1,540) and pn3 (2,131 > 1,232) -> satisfied.
DECISION: SELECTED PAIR T2 + PD (T2 primary/anchor, PD secondary). PD is selected as the most
justified source of potentially complementary information, NOT as a good standalone segmenter
(poor specificity, very large FP burden, large pn0/pn3 variation). T1 not selected for the first
pair; not discarded from the project.
Fusion rule: NOT DEFINED (Phase 80). Multimodal prediction: NOT GENERATED. Multimodal Dice: NOT
COMPUTED. It is not shown that T2 + PD is better than T2 alone (Phase 81). Canonical prediction:
Phase-71 T2 M_pred, unchanged. config.m unchanged in this phase. EXP-041 kept free for Phase 80.
Outputs: results/metrics/phase79_modality_combination_decision.csv,
phase79_selected_combination.csv.
```

---

### EXP-041 — Phase-80 T2 + PD intersection fusion

#### Pre-registration (written before EXP-041 was run; no GT in this experiment)

```text
Selected pair (Phase 79): T2 + PD. Primary/anchor: T2. Secondary: PD.
Inputs: the frozen Phase-78 selected single-modality masks (T2 Class 3, PD Class 3; EXP-021,
/4095, no preprocessing, multithresh N = 2, square3 opening, no component filtering) - no MRI is
reloaded and no thresholding or opening is rerun. T2 inputs must equal Phase-71 M_pred exactly.
Fusion rule (ONE, same for pn0 and pn3, fixed before any multimodal evaluation):
  binary decision-level intersection   fusedCandidateMask = M_T2 AND M_PD.
No morphology, component filtering or region growing after the fusion.
Rationale:
  - T2 is the strongest single modality (Phase 78) and stays the anchor;
  - the dominant limitation of the T2 prediction is its very large candidate foreground;
  - PD Class 3 is much broader than T2 and unsuitable as an additive source: T2 OR PD would only
    add foreground, so OR is rejected a priori, without testing;
  - PD is therefore used only as a confirmation gate: a voxel survives only if both modalities
    mark it.
Consequence: the fused mask is a subset of T2. It can remove T2 candidates but can NEVER add a
voxel missed by T2 (it cannot recover T2 false negatives). It may also remove T2 voxels that are
lesion voxels; whether the trade-off helps is decided only in Phase 81.
Declared risk (from the Phase-78 qualitative figures, before this run): PD Class 3 also contains
the ventricles in both conditions, like T2 Class 3, so the intersection may keep much of the large
fluid-like T2 candidate regions. This is recorded now so that it cannot be used afterwards to
change the rule.
Alternative fusion rules tested: NONE (no OR, XOR, AND NOT, voting, weights).
GT: NOT USED. Outputs: structural mask-overlap statistics only (T2 / PD / fused / T2-only /
PD-only voxels and fractions). These are not performance metrics; T2 candidates not confirmed by PD
are not called false positives. Evaluation: DEFERRED TO PHASE 81. The fused mask is experimental:
Phase-71 M_pred stays canonical; config.m unchanged.
```

#### Status

```text
COMPLETED (generation only; evaluation in Phase 81)
```

#### Implementation

```text
src/segmentation/fuseCandidateMasksIntersection.m (logical 3D inputs of equal size; returns
primaryMask & secondaryMask)
experiments/multimodal_fusion_intersection_check.m (synthetic, 14/14 PASS)
experiments/exp041_t2_pd_intersection_fusion.m
Outputs: data/processed/exp041_t2_pd_{pn0,pn3}_intersection_candidate.mat (fusedCandidateMask,
metadata); results/metrics/exp041_t2_pd_fusion_summary.csv;
results/figures/exp041_t2_pd_fusion_{pn0,pn3}.png (no GT).
```

#### Git Version

```text
Commit: 64cd8e0
Working tree clean: NO
```

#### Execution

```text
MATLAB, 2026-10-12. 38/38 checks PASS: Phase-79 decision as expected; 4 Phase-78 inputs present,
logical 181x217x181, provenance EXP-040 Class 3 / EXP-021 / /4095 / multithresh 2 / square3 / no
filtering; T2 = Phase-71 M_pred (pn0, pn3); one fusion call, same rule for both conditions; fused =
T2 AND PD exactly, subset of T2 and of PD; structural counts consistent; sources and M_pred
unchanged; outputs reload identically; no GT / MRI / threshold / morphology / components / region
growing / performance metric / alternative rule / held-out reference; config.m unchanged.
```

#### Quantitative Results (structural mask overlap only, no GT)

```text
                                 pn0         pn3
T2 voxels                        70,878      67,066
PD voxels                        788,306     163,225
Fused (T2 AND PD) voxels         70,849      61,740
T2-only (not confirmed by PD)    29          5,326
PD-only                          717,457     101,485
Fraction of T2 retained          0.999591    0.920586
Fraction of T2 removed           0.000409    0.079414
Fraction of PD overlapping T2    0.089875    0.378251
Non-empty slices T2 / fused      121 / 121 (k 12-144)   117 (k 28-144) / 116 (k 28-144)
```

#### Visual Results

```text
results/figures/exp041_t2_pd_fusion_{pn0,pn3}.png (k = 46, 91, 102, 136; agreement map cyan = T2
only, magenta = PD only, white = both; modality agreement, not TP/FP/FN).
Qualitative observation only: in pn0 PD Class 3 covers essentially every T2 candidate, so the
fused mask looks identical to T2. In pn3 the T2 candidates not confirmed by PD are mostly thin
rims along the borders of T2 candidates and some small isolated spots. In both conditions the
large candidate structures already described qualitatively as bright / fluid-like are largely
shared by T2 and PD and are therefore not removed by the intersection (the risk declared in the
pre-registration; visual observation, no anatomical identification).
```

#### Interpretation

```text
Structurally, the intersection acts very differently in the two conditions with one identical
rule: in pn0 it is almost the identity on T2 (29 voxels removed); in pn3 it removes 7.9 % of the
T2 candidates. Whether the removed voxels are lesion or non-lesion voxels is unknown without GT.
Expectation stated before Phase 81 (not a result): the pn0 Dice can change only marginally; any
difference between T2 and T2 AND PD will come mainly from pn3.
```

#### Decision

```text
FUSED DEVELOPMENT PREDICTION GENERATED AND FROZEN. No performance claim. The rule is not changed
after inspection. Phase-71 M_pred remains canonical; multimodal pipeline not accepted yet.
```

#### Next Experiment

```text
Phase 81 - T2 alone vs T2 AND PD (EXP-041) development comparison.
```

---

### EXP-042 — Phase-81 mono-modal T2 vs T2+PD multimodal comparison

#### Pre-registration (written before EXP-042 was run and before any GT evaluation of EXP-041)

```text
Baseline (MONO): Phase-71 T2 M_pred (phase71_t2_{pn0,pn3}_predicted_volume.mat), frozen.
Candidate (MULTI): EXP-041 T2 AND PD (exp041_t2_pd_{pn0,pn3}_intersection_candidate.mat), frozen
in Phase 80 without GT. Neither method is regenerated or modified.
GT: labels == 10 of the crisp phantom, complete 181x217x181 volume, not intersected with any mask;
loaded only after all provenance / integrity checks.
Primary metric: full-volume Dice = 2 TP / (predicted + GT). DevelopmentScore = (Dice_pn0 +
Dice_pn3)/2; weakerConditionDice = min (reported). Diagnostics: TP / FP / FN per method and
condition; removed-voxel analysis removedByFusion = M_T2 AND NOT M_multi -> removedTP / removedFP
(evaluation only). No TN, IoU, precision, recall, specificity or volume error (later phases).
Decision rule (DevelopmentScore only, no tolerance):
  candidate score >  baseline score -> RETAIN_MULTIMODAL_FUSION
  candidate score <  baseline score -> REJECT_MULTIMODAL_FUSION
  exact tie                         -> REJECT_MULTIMODAL_FUSION (simpler T2 retained)
No requirement to win both conditions; no secondary score.
Qualitative expectation (not a result): pn0 can change only minimally (the masks differ by 29
voxels); pn3 may change more (5,326 T2 voxels removed). Whether the removed voxels are mostly TP
or FP is unknown, so the direction of the change is not assumed.
No rule modification, no alternative fusion, no thresholding / morphology / filtering / region
growing, no held-out data, config.m unchanged. If MULTI wins, exact-copy aliases
phase81_{pn0,pn3}_retained_prediction.mat are written (finalPipelineFrozen = false); if it loses or
ties, Phase-71 M_pred stays canonical and EXP-041 is kept as negative evidence.
```

#### Status

```text
COMPLETED
```

#### Implementation / Execution

```text
experiments/exp042_mono_vs_multimodal_comparison.m. MATLAB, 2026-10-12. 38/38 checks PASS:
provenance of EXP-041 and Phase-71 / Phase-78 identity verified before GT; fused subset of T2;
Phase-80 structural counts reproduced; GT = label 10 on the complete volume; TP + FN = 3,512 for
all four predictions; removed = removedTP + removedFP; multi TP / FP / FN identities hold in pn0
and pn3; DevelopmentScore exact means; decision from DevelopmentScore only; sources / GT / config.m
unchanged; no regeneration, alternative fusion, threshold, morphology, filtering, region growing,
later-phase metric or held-out reference. No alias written (candidate lost).
Cosmetic fix after the run (no effect on numbers): the subtitle of exp042_removed_voxels_*.png was
clipped on the left; it is now split over two lines (saved PNGs show the old subtitle until a rerun).
Outputs: results/metrics/exp042_mono_vs_multimodal_metrics.csv, exp042_mono_vs_multimodal_summary.csv,
exp042_fusion_removed_voxels.csv, phase81_multimodal_decision.csv; results/figures/
exp042_dice_comparison.png, exp042_removed_voxels_{pn0,pn3}.png.
```

#### Quantitative Results

```text
Method  Cond  Predicted  TP     FP      FN     Dice
T2      pn0   70,878     2,107  68,771  1,405  0.056647
T2      pn3   67,066     2,013  65,053  1,499  0.057043
T2+PD   pn0   70,849     2,107  68,742  1,405  0.056669
T2+PD   pn3   61,740     1,836  59,904  1,676  0.056274
(GT 3,512 voxels)

Removed by fusion   pn0: 29 (TP 0, FP 29)    pn3: 5,326 (TP 177 = 3.32 %, FP 5,149 = 96.68 %)

                 Dice pn0   Dice pn3   weaker     DevelopmentScore
T2               0.056647   0.057043   0.056647   0.056845
T2 AND PD        0.056669   0.056274   0.056274   0.056472
Delta            +0.000022  -0.000769             -0.000374  (LOWER)
```

#### Interpretation

```text
In both conditions the fusion removed far more FP than TP (pn0 29 / 0; pn3 5,149 / 177). In pn0
this gives a tiny Dice gain (+0.000022). In pn3 it does not improve Dice: removing a set of r
voxels containing t TP raises Dice only if t / r < TP / (predicted + GT) of the current mask
(algebraic consequence of Dice = 2TP / (P + G), derived afterwards from the saved counts). For T2
pn3 that bound is 2,013 / 70,578 = 0.0285, while the removed set has 177 / 5,326 = 0.0332: the
removed voxels are slightly richer in lesion voxels than the T2 mask as a whole, so PD
confirmation is not lesion-selective enough. The large bright / fluid-like candidates that dominate
the FP are kept by the intersection (Phase 80), so the FP burden stays about 60,000-69,000 voxels.
```

#### Decision

```text
REJECT_MULTIMODAL_FUSION (candidate DevelopmentScore 0.056472 < baseline 0.056845; predefined rule,
no tolerance). T2 AND PD removes many false candidates (especially pn3) but is not selective enough:
it also removes enough lesion signal to cancel the FP-reduction benefit. This rejects this specific
rule only; it is not a reason to try OR / weights / other combinations now (EXP-041 stays negative
evidence, not something to adjust). The retained development pipeline stays T2-only; Phase-71 M_pred remains the
canonical development prediction. EXP-041 / EXP-042 artifacts kept as negative evidence. No
alternative fusion tested, no post-hoc retuning, no held-out data, config.m unchanged.
```

#### Next Experiment

```text
Phase 82 - formal voxel-wise confusion matrix (not started).
```

---

### EXP-043 — Phase-82 formal voxel-wise confusion matrix

#### Pre-registration (written before EXP-043 was run)

```text
Roadmap phase: 82. Purpose: formal implementation and validation of voxel-wise TP / FP / FN / TN
counts (evaluation bookkeeping, not a segmentation change).
Retained prediction: Phase-71 T2 M_pred (Phase-81 decision REJECT_MULTIMODAL_FUSION verified from
phase81_multimodal_decision.csv before evaluation; otherwise TECHNICALLY BLOCKED).
Conditions: pn0 / pn3 development only. Held-out: NOT USED.
GT: BrainWeb crisp phantom, label 10, complete 181x217x181 volume (no mask / ROI / slice range).
Definitions (complete 3D volume): TP = pred 1 & GT 1; FP = pred 1 & GT 0; FN = pred 0 & GT 1;
TN = pred 0 & GT 0 (direct logical counting).
Confusion convention: rows = GT [0, 1], columns = prediction [0, 1]  ->  [TN FP; FN TP].
Function: src/evaluation/computeVoxelConfusion.m (logical masks only, same size, non-empty;
returns TP, FP, FN, TN, totalVoxels and the 2x2 matrix; no file access, no segmentation logic).
Validation: synthetic tests (experiments/voxel_confusion_check.m); exact count identities; TP / FP /
FN regression cross-check against the T2 rows of exp042_mono_vs_multimodal_metrics.csv (validation
only, counts are computed independently).
Metrics calculated: NONE (no Dice, IoU, precision, recall, specificity, accuracy, F1, volume error,
slice-wise or lesion-wise analysis). TN is a count only; its large value is not evidence of a good
segmentation. No segmentation modification, no tuning, config.m unchanged.
```

#### Status

```text
COMPLETED
```

#### Implementation / Execution

```text
src/evaluation/computeVoxelConfusion.m; experiments/voxel_confusion_check.m (synthetic, 12/12 PASS:
perfect negative, perfect match, all four categories TP 1 / FP 2 / FN 3 / TN n-6, all-positive and
all-negative prediction, size mismatch / non-logical / empty input rejected, inputs unchanged,
deterministic, matrix orientation); experiments/exp043_voxel_confusion_matrix.m (MATLAB,
2026-10-13, 46/46 PASS: Phase-81 decision verified, M_pred logical 181x217x181, GT label 10
complete volume, function without file access / segmentation logic, four counts equal to an
independent direct count, all count identities, regression with Phase 81, no derived metric,
no slice- / lesion-wise evaluation, no segmentation, sources / GT / config.m unchanged).
Label fix after the run (no effect on results): the check "complete GT used (no brain-mask
intersection)" only verifies nnz(gtMask) == nnz(labels == 10); the absence of intersection follows
from the code (gtMask = labels == 10). Renamed to "GT keeps every label-10 voxel of the volume".
Outputs: results/metrics/exp043_voxel_confusion_matrix.csv,
exp043_confusion_matrix_{pn0,pn3}.csv (rows gt0 / gt1, columns pred0 / pred1).
```

#### Quantitative Results

```text
                       pn0          pn3
Total voxels           7,109,137    7,109,137
Predicted positive     70,878       67,066
Predicted negative     7,038,259    7,042,071
GT positive            3,512        3,512
GT negative            7,105,625    7,105,625
TP                     2,107        2,013
FP                     68,771       65,053
FN                     1,405        1,499
TN                     7,036,854    7,040,572

Matrix (rows = GT [0,1], columns = prediction [0,1]):
  pn0  [7,036,854  68,771;  1,405  2,107]
  pn3  [7,040,572  65,053;  1,499  2,013]
All identities hold exactly (TP+FP, TP+FN, TN+FN, TN+FP, sum = 7,109,137). TP / FP / FN reproduce
the Phase-81 T2 diagnostic counts exactly (regression check only; counts computed independently).
```

#### Interpretation

```text
TN dominates (98.98 % / 99.04 % of the volume, computed afterwards from the CSV) because non-lesion
voxels vastly outnumber lesion voxels;
this is class imbalance, not evidence of a good segmentation (discussed formally in Phase 87).
```

#### Decision

```text
FORMAL VOXEL-WISE CONFUSION EVALUATOR IMPLEMENTED AND VALIDATED. No derived metric, no
segmentation change, no held-out data, config.m unchanged.
```

#### Next Experiment

```text
Phase 83 - formal Dice implementation (not started).
```

---

### EXP-044 — Phase-83 formal Dice implementation

#### Pre-registration (written before EXP-044 was run)

```text
Roadmap phase: 83. Purpose: formal implementation and validation of the Dice coefficient.
Prediction: Phase-71 T2 M_pred. Conditions: pn0 / pn3 development only. Held-out: NOT USED.
GT: BrainWeb crisp label 10, complete 181x217x181 volume.
Confusion source: computeVoxelConfusion (Phase 82); the Dice function does not count voxels.
Formula: Dice = 2TP / (2TP + FP + FN) (TP, FP, FN only; TN not used).
Zero-denominator convention (project implementation convention for the undefined 0/0 case, not
taken from the course material): TP = FP = FN = 0 -> Dice = 1 (identical empty positive sets).
Input validation: TP, FP, FN present, scalar, real, finite, non-negative, integer-valued; invalid
counts are rejected, never rounded or replaced.
Regression: confusion counts must equal exp043_voxel_confusion_matrix.csv exactly; Dice must
reproduce the T2 rows of exp042_mono_vs_multimodal_metrics.csv within 1e-12 (absolute; only to
absorb the ~15-significant-digit CSV text representation - the computation itself is identical).
Outputs: one Dice per volume (pn0, pn3); no DevelopmentScore, no other metric (IoU, precision,
recall, specificity, accuracy, F1, volume error), no slice- or lesion-wise evaluation, no figure.
No segmentation change, no tuning, config.m unchanged.
```

#### Status

```text
COMPLETED
```

#### Implementation / Execution

```text
src/evaluation/computeDiceFromConfusion.m; experiments/dice_metric_check.m (synthetic, via
computeVoxelConfusion -> computeDiceFromConfusion, 16/16 PASS: perfect match 1, disjoint 0,
TP 2 / FP 1 / FN 3 -> 0.5, empty prediction 0, empty GT 0, both empty 1 (convention), full-positive
match 1, symmetry, range [0,1], TN without effect, negative / non-integer / NaN / Inf / missing
field rejected, deterministic); experiments/exp044_formal_dice.m (MATLAB, 2026-10-13, 36/36 PASS).
Output: results/metrics/exp044_formal_dice.csv.
```

#### Quantitative Results

```text
        TP     FP      FN     numerator  denominator  Dice
pn0     2,107  68,771  1,405  4,214      74,390       0.0566473988439306
pn3     2,013  65,053  1,499  4,026      70,578       0.0570432712743348
Confusion counts (incl. TN) reproduce EXP-043 exactly. Denominator = predicted positives + GT
positives in both conditions. Dice reproduces the EXP-042 T2 values (|difference| < 1e-12).
```

#### Decision

```text
FORMAL DICE IMPLEMENTED AND VALIDATED. No other metric, no DevelopmentScore, no slice- or
lesion-wise evaluation, no segmentation change, no held-out data, config.m unchanged.
```

#### Next Experiment

```text
Phase 84 - formal IoU / Jaccard implementation (not started).
```

---

### EXP-045 — Phase-84 formal IoU / Jaccard implementation

#### Pre-registration (written before EXP-045 was run)

```text
Roadmap phase: 84. Purpose: formal implementation and validation of IoU / Jaccard.
Prediction: Phase-71 T2 M_pred. Conditions: pn0 / pn3 development only. Held-out: NOT USED.
GT: BrainWeb crisp label 10, complete 181x217x181 volume.
Confusion source: computeVoxelConfusion (Phase 82); the IoU function does not count voxels.
Formula: IoU = TP / (TP + FP + FN) = |M_pred ∩ M_GT| / |M_pred ∪ M_GT|. Terminology: IoU = Jaccard
index (one function, computeIoUFromConfusion; no duplicate Jaccard function or column). TN not used.
Zero-union convention (project implementation convention, consistent with Phase 83, not from the
course material): TP = FP = FN = 0 -> IoU = 1.
Input validation: TP, FP, FN numeric, scalar, real, finite, non-negative, integer; rejected
otherwise, never rounded / clamped / replaced.
Regression: counts = exp043_voxel_confusion_matrix.csv exactly; IoU = Dice / (2 - Dice) with the
Phase-83 Dice read from exp044_formal_dice.csv, within 1e-12 absolute (numeric regression
comparison only - not a segmentation, selection or tuning tolerance). The production IoU is
computed from TP / FP / FN, never converted from Dice.
Other new metrics: NONE (no precision, recall, specificity, accuracy, F1, volume error, no
DevelopmentScore, no slice- or lesion-wise evaluation, no figure). No segmentation change, no
tuning, config.m unchanged.
```

#### Status

```text
COMPLETED
```

#### Implementation / Execution

```text
src/evaluation/computeIoUFromConfusion.m; experiments/iou_metric_check.m (synthetic, via
computeVoxelConfusion -> computeIoUFromConfusion, 16/16 PASS: perfect match 1, disjoint 0,
TP 2 / FP 1 / FN 3 -> 1/3, empty prediction 0, empty GT 0, both empty 1 (convention), full-positive
match 1, symmetry, range [0,1], TN independence, negative / non-integer / NaN / Inf / missing field
rejected, deterministic); experiments/exp045_formal_iou.m (MATLAB, 2026-10-13, 34/34 PASS).
Output: results/metrics/exp045_formal_iou.csv (column iou = Jaccard index).
```

#### Quantitative Results

```text
        TP     FP      FN     intersection  union    IoU (= Jaccard)
pn0     2,107  68,771  1,405  2,107         72,283   0.0291493158834027
pn3     2,013  65,053  1,499  2,013         68,565   0.0293590024064756
Confusion counts (incl. TN) reproduce EXP-043 exactly. IoU = Dice / (2 - Dice) with the Phase-83
Dice holds in both conditions (|difference| < 1e-12; regression comparison only).
```

#### Decision

```text
FORMAL IoU / JACCARD IMPLEMENTED AND VALIDATED. No later metric, no DevelopmentScore, no slice- or
lesion-wise evaluation, no segmentation change, no held-out data, config.m unchanged.
```

#### Next Experiment

```text
Phase 85 - formal Precision implementation (not started).
```

---

### EXP-046 — Phase-85 formal Precision implementation

#### Pre-registration (written before EXP-046 was run)

```text
Roadmap phase: 85. Purpose: formal implementation and validation of Precision.
Prediction: Phase-71 T2 M_pred (Phase-81 decision re-verified). Conditions: pn0 / pn3 development
only. Held-out: NOT USED. GT: BrainWeb crisp label 10, complete 181x217x181 volume.
Confusion source: computeVoxelConfusion (Phase 82); the Precision function does not count voxels.
Formula: Precision = TP / (TP + FP) (TP + FP = predicted-positive voxels); FN and TN not used.
Zero-prediction convention (project implementation convention for the undefined 0/0 case, not
from the course material): TP = FP = 0 -> Precision = 1. It only resolves the undefined
denominator and does NOT imply successful lesion detection (with GT lesions present, Recall in
Phase 86 would reveal the failure).
Input validation: TP, FP numeric, scalar, real, finite, non-negative, integer; rejected otherwise.
Precision is not symmetric in prediction / GT: no symmetry test.
Regression: counts = exp043_voxel_confusion_matrix.csv exactly; denominator = predicted-positive
voxels exactly. Precision is not derived from Dice or IoU.
Other new metrics: NONE (no recall / sensitivity, specificity, accuracy, F1, volume error, no
DevelopmentScore, no slice- or lesion-wise evaluation, no figure). No segmentation change, no
tuning, config.m unchanged.
```

#### Status

```text
COMPLETED
```

#### Implementation / Execution

```text
src/evaluation/computePrecisionFromConfusion.m; experiments/precision_metric_check.m (synthetic, via
computeVoxelConfusion, 16/16 PASS: FP = 0 -> 1, TP = 0 -> 0, TP 3 / FP 1 -> 0.75, TP 2 / FP 2 -> 0.5,
empty prediction -> 1 (convention), full-positive match 1, FN and TN independence, range [0,1],
negative / non-integer / NaN / Inf / missing TP / missing FP rejected, deterministic);
experiments/exp046_formal_precision.m (MATLAB, 2026-10-13, 34/34 PASS, Phase-81 decision
re-verified). Output: results/metrics/exp046_formal_precision.csv.
Robustness fix after the run (no effect on results): an explicit isfile check on the Phase-81
decision file now raises "PHASE 85 TECHNICALLY BLOCKED" before readtable if the file is missing.
```

#### Quantitative Results

```text
        TP     FP      predicted positive  Precision           TP share   FP share
pn0     2,107  68,771  70,878              0.0297271367702249  2.9727 %    97.0273 %
pn3     2,013  65,053  67,066              0.0300152088986968  3.0015 %    96.9985 %
Confusion counts (incl. TN) reproduce EXP-043 exactly; denominator = predicted-positive voxels.
```

#### Interpretation

```text
Low Precision quantifies the known false-positive contamination: only about 3 % of the voxels
predicted as lesion are lesion voxels, about 97 % are FP (consistent with the large bright /
fluid-like candidates documented since Phase 61). Precision says nothing about how much of the GT
lesion volume is recovered (Recall, Phase 86).
```

#### Decision

```text
FORMAL PRECISION IMPLEMENTED AND VALIDATED. No later metric, no DevelopmentScore, no slice- or
lesion-wise evaluation, no segmentation change, no held-out data, config.m unchanged.
```

#### Next Experiment

```text
Phase 86 - formal Recall / Sensitivity implementation (not started).
```

---

### EXP-047 — Phase-86 formal Recall / Sensitivity implementation

#### Pre-registration (written before EXP-047 was run)

```text
Roadmap phase: 86. Purpose: formal implementation and validation of Recall / Sensitivity.
Prediction: Phase-71 T2 M_pred (Phase-81 decision re-verified). Conditions: pn0 / pn3 development
only. Held-out: NOT USED. GT: BrainWeb crisp label 10, complete 181x217x181 volume.
Confusion source: computeVoxelConfusion (Phase 82); the Recall function does not count voxels.
Formula: Recall = TP / (TP + FN) (TP + FN = GT-positive voxels); FP and TN not used.
Terminology: Recall = Sensitivity (one function computeRecallFromConfusion, one column recall).
Zero-GT-positive convention (project implementation convention for the undefined 0/0 case, not
from the course material): TP = FN = 0 -> Recall = 1. It only resolves the undefined denominator
when the GT has no lesion voxels and does NOT imply good predictions overall (FP would be exposed
by Precision).
Input validation: TP, FN numeric, scalar, real, finite, non-negative, integer; rejected otherwise.
No symmetry test (Recall is not symmetric in prediction / GT).
Regression: counts = exp043_voxel_confusion_matrix.csv exactly; denominator = GT-positive voxels.
Interpretation: voxel-wise lesion recovery, not lesion-wise detection; 1 - Recall reported only as
a plain-language complement (missed fraction of lesion voxels), not a new metric. The Phase-85
Precision CSV is read only for a side-by-side description; no combined score (F1, F-beta,
balanced accuracy).
Other new metrics: NONE (no specificity, accuracy, volume error, DevelopmentScore, slice- or
lesion-wise evaluation, figure). No segmentation change, no tuning, config.m unchanged.
```

#### Status

```text
COMPLETED
```

#### Implementation / Execution

```text
src/evaluation/computeRecallFromConfusion.m; experiments/recall_metric_check.m (synthetic, via
computeVoxelConfusion, 16/16 PASS: FN = 0 -> 1, TP = 0 -> 0, TP 3 / FN 1 -> 0.75, TP 2 / FN 2 -> 0.5,
empty GT -> 1 (convention), full-positive match 1, FP and TN independence, range [0,1], negative /
non-integer / NaN / Inf / missing TP / missing FN rejected, deterministic);
experiments/exp047_formal_recall.m (MATLAB, 2026-10-13, 34/34 PASS, input files isfile-checked,
Phase-81 decision re-verified). Output: results/metrics/exp047_formal_recall.csv (column recall =
Sensitivity).
```

#### Quantitative Results

```text
        TP     FN     GT positive  Recall (= Sensitivity)  lesion voxels detected / missed
pn0     2,107  1,405  3,512        0.5999430523918         59.9943 % / 40.0057 %
pn3     2,013  1,499  3,512        0.573177676537585       57.3178 % / 42.6822 %
Confusion counts (incl. TN) reproduce EXP-043 exactly; denominator = GT-positive voxels.
Side by side with Phase 85 (descriptive, no combined score): Precision 0.0297271367702249 /
0.0300152088986968.
```

#### Interpretation

```text
Voxel-wise: about 60 % (pn0) / 57 % (pn3) of the GT lesion VOXELS are recovered and about
40 % / 43 % are missed. This is not a lesion-wise detection rate (Phase 93): FN are missed lesion
voxels, which may belong to partially detected lesions, so no number of missed lesions follows.
Together with the Phase-85 Precision (about 3 %): low Precision + moderate Recall - the current
segmentation recovers a substantial fraction of lesion voxels but with very poor selectivity,
because it also labels a much larger number of non-lesion voxels as lesion.
```

#### Decision

```text
FORMAL RECALL / SENSITIVITY IMPLEMENTED AND VALIDATED. Specificity not implemented; no combined
score, no DevelopmentScore, no slice- or lesion-wise evaluation, no segmentation change, no
held-out data, config.m unchanged.
```

#### Next Experiment

```text
Phase 87 - formal Specificity implementation (not started).
```

---

### EXP-048 — Phase-87 formal Specificity implementation

#### Pre-registration (written before EXP-048 was run)

```text
Roadmap phase: 87. Purpose: formal implementation and validation of Specificity.
Prediction: Phase-71 T2 M_pred (Phase-81 decision re-verified). Conditions: pn0 / pn3 development
only. Held-out: NOT USED. GT: BrainWeb crisp label 10, complete 181x217x181 volume.
Confusion source: computeVoxelConfusion (Phase 82); the Specificity function does not count voxels.
Formula: Specificity = TN / (TN + FP) (TN + FP = GT-negative voxels); TP and FN not used.
Zero-negative-class convention (project implementation convention for the undefined 0/0 case, not
from the course material): TN = FP = 0 -> Specificity = 1; it does NOT imply a good segmentation.
Input validation: TN, FP numeric, scalar, real, finite, non-negative, integer; rejected otherwise.
No symmetry test.
Regression: counts = exp043_voxel_confusion_matrix.csv exactly; denominator = GT-negative voxels.
Critical interpretation: the non-lesion class (~7.1 million voxels vs 3,512 lesion voxels)
dominates the volume, so Specificity must NOT be read in isolation or as overall accuracy; 1 -
Specificity (FP among GT negatives) is reported only as a plain-language complement. The saved
Dice / IoU / Precision / Recall CSVs (EXP-044..047) are read only for a descriptive joint summary.
Other new metrics: NONE (no accuracy, balanced accuracy, F1, F-beta, MCC, ROC / AUC, Youden, volume
metrics, DevelopmentScore, slice- or lesion-wise evaluation, figure). No segmentation change, no
tuning, config.m unchanged.
```

#### Status

```text
COMPLETED
```

#### Implementation / Execution

```text
src/evaluation/computeSpecificityFromConfusion.m; experiments/specificity_metric_check.m
(synthetic, via computeVoxelConfusion, 16/16 PASS: FP = 0 -> 1, TN = 0 -> 0, TN 3 / FP 1 -> 0.75,
TN 2 / FP 2 -> 0.5, no GT negatives -> 1 (convention), all-negative match 1, TP and FN
independence, range [0,1], negative / non-integer / NaN / Inf / missing TN / missing FP
rejected, deterministic); experiments/exp048_formal_specificity.m (MATLAB, 2026-10-13, 34/34
PASS, input files isfile-checked, Phase-81 decision re-verified).
Output: results/metrics/exp048_formal_specificity.csv.
```

#### Quantitative Results

```text
        TN         FP      GT negative  Specificity        negatives rejected / labelled lesion
pn0     7,036,854  68,771  7,105,625    0.990321611399419  99.0322 % / 0.9678 %
pn3     7,040,572  65,053  7,105,625    0.990844858826634  99.0845 % / 0.9155 %
Confusion counts (incl. TN) reproduce EXP-043 exactly; denominator = GT-negative voxels.
Formal development metrics (read from EXP-044..047 CSVs, descriptive only):
  pn0  Dice 0.056647 | IoU 0.029149 | Precision 0.029727 | Recall 0.599943 | Specificity 0.990322
  pn3  Dice 0.057043 | IoU 0.029359 | Precision 0.030015 | Recall 0.573178 | Specificity 0.990845
```

#### Interpretation

```text
About 99 % of the GT non-lesion VOXELS are correctly classified as non-lesion. This is not
"99 % accuracy" and not overall segmentation quality: the negative class has 7,105,625 voxels vs
3,512 lesion voxels, so 68,771 / 65,053 FP are under 1 % of the negatives while still being about
33 / 32 times the TP count (68,771 / 2,107 and 65,053 / 2,013, computed afterwards from the
counts). High Specificity coexists with Precision about 3 %, Dice about 0.057 and IoU about 0.029
without contradiction: Specificity asks how many true negatives were rejected, Precision how many
predicted lesion voxels are lesion. Overall pattern: very low Dice / IoU, extremely low Precision,
moderate Recall, very high Specificity. A high Specificity is no reason to skip tuning.
```

#### Decision

```text
FORMAL SPECIFICITY IMPLEMENTED AND VALIDATED. No combined metric (accuracy, balanced accuracy, F1,
F-beta, MCC, ROC / AUC), no volume metric, no DevelopmentScore, no slice- or lesion-wise
evaluation, no segmentation change, no held-out data, config.m unchanged.
```

#### Next Experiment

```text
Phase 88 - GT lesion volume (not started).
```

---

### EXP-049 — Phase-88 formal GT lesion volume

#### Pre-registration (written before EXP-049 was run)

```text
Roadmap phase: 88. Purpose: formal calculation of the physical lesion volume of the BrainWeb GT.
GT: BrainWeb crisp phantom, M_GT = labels == 10, complete 181x217x181 volume (7,109,137 voxels),
no mask / ROI / slice selection. One shared GT anatomy: the same GT volume applies to pn0 and pn3
(noise changes the MRI simulation, not the crisp GT); one result row, not one per condition.
Voxel spacing: 1 x 1 x 1 mm, established in Phase 26 (notes 13.7.2: download-page step 1 on all
axes, "1mm isotropic" model; cross-check: GT label counts = published per-class volumes in mm^3).
config.m has no spacing field; the spacing is passed explicitly in the script with this
provenance (no config.m change). Physical voxel volume = prod(spacing) = 1 mm^3.
Formula: V_GT = N_GT * V_voxel (N_GT = nnz(M_GT)). Stored in mm^3; cm^3 = mL = mm^3 / 1000 reported
only as a unit conversion of the same quantity.
Function: src/evaluation/computeBinaryMaskVolume.m (generic: logical non-empty mask + explicit
3-element positive finite spacing; no hidden 1 mm assumption); applied ONLY to M_GT here.
Regression: N_GT must equal the established 3,512-voxel invariant (expected value only).
Prediction: NOT USED (no M_pred loaded). Predicted volume, volume error, confusion metrics,
connected components, slice- or lesion-wise volumes: NOT CALCULATED. Held-out: NOT USED. No
segmentation change, no tuning, config.m unchanged.
```

#### Status

```text
COMPLETED
```

#### Implementation / Execution

```text
src/evaluation/computeBinaryMaskVolume.m; experiments/binary_mask_volume_check.m (synthetic, 14/14
PASS: 1 voxel -> 1 mm^3, 5 voxels -> 5 mm^3, anisotropic [1 2 3] mm -> 6 mm^3 per voxel and
24 mm^3 for 4 voxels, all-false mask -> 0, unit conversion, non-logical / empty mask and wrong-
length / zero / negative / NaN / Inf spacing rejected, deterministic, inputs unchanged);
experiments/exp049_gt_lesion_volume.m (MATLAB, 2026-10-13, 27/27 PASS).
Output: results/metrics/exp049_gt_lesion_volume.csv (one row).
```

#### Quantitative Results

```text
GT: BrainWeb msles2 crisp phantom, label 10, 181 x 217 x 181 (7,109,137 voxels)
Spacing 1 x 1 x 1 mm (Phase 26) -> voxel volume 1 mm^3
GT lesion voxels N_GT = 3,512 (= established invariant)
V_GT = N_GT * V_voxel = 3,512 mm^3 = 3.512 cm^3 = 3.512 mL
Same value for pn0 and pn3 (shared crisp GT).
```

#### Interpretation

```text
3,512 lesion voxels correspond to 3,512 mm^3 because each voxel occupies 1 mm^3 (validated
spacing); count and physical volume are distinct quantities that coincide numerically only for
this geometry.
```

#### Decision

```text
GT LESION VOLUME FORMALIZED. No prediction used, no predicted volume, no volume error, no
connected components, no slice- or lesion-wise volume, no segmentation change, no held-out data,
config.m unchanged.
```

#### Next Experiment

```text
Phase 89 - predicted lesion volume (not started).
```

---

### EXP-050 — Phase-89 formal predicted lesion volume

#### Pre-registration (written before EXP-050 was run)

```text
Roadmap phase: 89. Purpose: formal calculation of the physical volume occupied by the retained
predicted lesion masks (segmented predicted-positive volume, TP + FP; not true lesion volume).
Prediction: Phase-71 T2 M_pred, pn0 and pn3 separately (one value per condition; no merge, no
average, no DevelopmentScore). Dimensions 181x217x181 verified before the volume call.
Voxel spacing: 1 x 1 x 1 mm (Phase 26, as in Phase 88), passed explicitly; V_voxel = 1 mm^3.
Formula: V_pred = N_pred * V_voxel with the unchanged Phase-88 function computeBinaryMaskVolume
(no new volume helper); N_pred also counted independently with nnz.
Regression: N_pred = TP + FP from exp043_voxel_confusion_matrix.csv (read only; no confusion
recomputation). EXP-049 CSV checked for existence / spacing provenance only; its GT volume is not
used in any arithmetic.
GT: not loaded. Comparison with V_GT, volume difference, ratio or percentage error: NOT
CALCULATED (Phase 90). Held-out: NOT USED. No segmentation change, no tuning, config.m unchanged.
```

#### Status

```text
COMPLETED
```

#### Implementation / Execution

```text
experiments/exp050_predicted_lesion_volume.m (reuses src/evaluation/computeBinaryMaskVolume.m
unchanged; MATLAB, 2026-10-13, 36/36 PASS: inputs isfile-checked, M_pred variable present,
logical, 181x217x181 before the volume call, spacing provenance = EXP-049, counts = nnz = function
voxelCount = EXP-043 TP + FP, unit conversions, Phase-71 files and the volume function unchanged,
no GT / GT-volume arithmetic / confusion metric / components / held-out reference).
Output: results/metrics/exp050_predicted_lesion_volume.csv (two rows).
```

#### Quantitative Results

```text
Spacing 1 x 1 x 1 mm -> V_voxel = 1 mm^3
        N_pred (predicted-positive voxels)  V_pred
pn0     70,878                              70,878 mm^3 = 70.878 cm^3 = 70.878 mL
pn3     67,066                              67,066 mm^3 = 67.066 cm^3 = 67.066 mL
N_pred = TP + FP of EXP-043 in both conditions.
```

#### Interpretation

```text
V_pred is the physical volume occupied by the prediction (all predicted-positive voxels, TP + FP);
it is not the true lesion volume. Formal comparison with V_GT is deferred to Phase 90.
```

#### Decision

```text
PREDICTED LESION VOLUME FORMALIZED (pn0 and pn3 separately). No GT comparison, no volume error,
no segmentation change, no held-out data, config.m unchanged.
```

#### Next Experiment

```text
Phase 90 - formal volume error (not started).
```

---

### EXP-051 — Phase-90 formal lesion-volume error

#### Pre-registration (written before EXP-051 was run)

```text
Roadmap phase: 90. Purpose: formal comparison of the Phase-89 predicted lesion volumes against the
Phase-88 GT lesion volume.
Inputs (frozen artifacts only): EXP-049 exp049_gt_lesion_volume.csv (one GT row) and EXP-050
exp050_predicted_lesion_volume.csv (pn0, pn3). No mask is loaded and no volume is recomputed.
Canonical unit: mm^3 (gtLesionVolumeMm3, predictedLesionVolumeMm3; same 1 mm^3 voxel geometry).
Formula (PROJECT_SPEC section 17, unchanged): VolumeErrorPercent = |V_pred - V_GT| / V_GT * 100.
The formal metric is absolute; signed difference and direction (overestimation /
underestimation / exact match) are reported separately as description only. Values above 100 %
are valid and are not clamped. No rounding before the calculation.
Function: src/evaluation/computeVolumeErrorPercent.m (two scalar, real, finite, non-negative
volumes; V_GT strictly positive - V_GT = 0 is rejected, no zero-GT convention; V_pred = 0 allowed).
Results kept per condition (pn0, pn3); no averaging, no DevelopmentScore.
Interpretation limits: volume error compares total physical volumes only; it is not a spatial-
overlap, localization, boundary or lesion-wise measure and does not replace Dice / IoU.
No confusion metric recomputed, no slice- or lesion-wise analysis, no segmentation change, no
tuning, no held-out data, config.m unchanged.
```

#### Status

```text
COMPLETED
```

#### Implementation / Execution

```text
src/evaluation/computeVolumeErrorPercent.m; experiments/volume_error_check.m (synthetic, 16/16 PASS:
equal volumes 0 %, 125 vs 100 -> +25 / 25 %, 75 vs 100 -> -25 / 25 % (absolute), zero prediction
-> 100 %, 210 vs 10 -> 2000 % (not capped), mm^3 / cm^3 scale invariance, negative / zero (GT) /
NaN / Inf / non-scalar inputs rejected, deterministic, inputs unchanged);
experiments/exp051_formal_volume_error.m (MATLAB, 2026-10-13, 33/33 PASS: EXP-049 one row, label 10,
3,512 voxels / 3,512 mm^3; EXP-050 rows pn0 / pn3 from Phase-71 T2 M_pred; same spacing and 1 mm^3
voxel; formula re-checked; no mask loaded, no volume recomputed).
Output: results/metrics/exp051_formal_volume_error.csv (two rows).
```

#### Quantitative Results

```text
V_GT = 3,512 mm^3 (EXP-049)
        V_pred (mm^3)  signed diff (mm^3)  |diff| (mm^3)  VolumeErrorPercent   direction
pn0     70,878         +67,366             67,366         1918.16628701595 %   overestimation
pn3     67,066         +63,554             63,554         1809.62414578588 %   overestimation
```

#### Interpretation

```text
The predicted-positive segmented volume is far larger than the physical GT lesion volume in both
conditions (errors well above 100 %, which is valid for this formula and not clipped). Derived
afterwards (not formal metrics): |diff| ~ 19.18 / 18.10 x V_GT, i.e. V_pred ~ 20.18 / 19.10 x V_GT. This is
consistent with the known over-segmentation / FP burden (Precision about 3 %, Recall about
57-60 %), but volume error is not itself an FP metric: it compares total volumes only and does not
measure spatial overlap, localization, boundaries or lesion-wise detection (two masks with equal
volume could be in different places). It does not replace Dice / IoU.
```

#### Decision

```text
FORMAL VOLUME ERROR IMPLEMENTED. No masks loaded, no volumes recomputed, no averaging, no
DevelopmentScore, no segmentation change, no held-out data, config.m unchanged.
```

#### Next Experiment

```text
Phase 91 - consolidated complete-3D metrics (not started).
```

---

### EXP-052 — Phase-91 consolidated complete-volume 3D evaluation

#### Pre-registration (written before EXP-052 was run)

```text
Roadmap phase: 91. Purpose: consolidate the already formalized complete-volume 3D development
metrics into one authoritative table (primary development evaluation).
Prediction: Phase-71 T2 M_pred. Conditions: pn0 / pn3 (kept separate). Scope: complete
181x217x181 volume (7,109,137 voxels); no slice averages, no selected slices.
Inputs (read-only, frozen): EXP-043 (TP/FP/FN/TN), EXP-044 (Dice), EXP-045 (IoU), EXP-046
(Precision), EXP-047 (Recall = Sensitivity, one column), EXP-048 (Specificity), EXP-049 (GT volume,
one shared row), EXP-050 (predicted volume), EXP-051 (volume error, direction). Each column is
taken from its own artifact; a missing / inconsistent artifact -> PHASE 91 TECHNICALLY BLOCKED (no
recovery from masks or documentation).
New metric: NONE (no metric function called, no masks / MRI loaded, no averaging, no
DevelopmentScore, no accuracy / F1 / MCC / ROC / AUC / Hausdorff...).
Consistency checks only (not saved as metrics): counts sum to 7,109,137; TP + FN = GT lesion voxels
(EXP-049); TP + FP = predicted-positive voxels (EXP-050); volumes consistent with 1 mm^3 voxels;
EXP-051 uses the EXP-049 / EXP-050 volumes; regression of IoU vs Dice / (2 - Dice), Precision,
Recall, Specificity and volume error vs the EXP-043 counts / volumes within a representation
tolerance |a - b| <= 1e-12 * max(1, |b|) (stored-value comparison only; not a tuning, selection or
near-tie tolerance). Source CSVs must be unchanged after the run.
Slice-wise (Phase 92), lesion-wise (93), size analysis (94), tuning (95): NOT PERFORMED. Held-out:
NOT USED. No figures. config.m unchanged.
```

#### Status

```text
COMPLETED
```

#### Implementation / Execution

```text
experiments/exp052_complete_3d_metrics.m (no new function). MATLAB, 2026-10-13: the first run's
pasted output was truncated at the last check, so the script was rerun (it only reads the
source CSVs and rewrites the same consolidated CSV); the rerun gives 59/59 PASS: 9 source
artifacts present, pn0 / pn3 one row each, one shared GT row (label 10), source = Phase-71 T2
M_pred, dimensions 181x217x181, counts integer and summing to 7,109,137, TP + FN = 3,512 (EXP-049),
TP + FP = EXP-050 counts, counts identical across EXP-043..048, all metrics finite and in range,
volumes and volume error consistent across EXP-049..051, regression checks (IoU vs Dice, Precision,
Recall, Specificity, volume error) within the representation tolerance, no metric function / new
metric / average / slice loop / components / masks / MRI / held-out, source CSVs unchanged
(timestamp, size, content), config.m unchanged.
Output: results/metrics/exp052_complete_3d_metrics.csv (two rows; recall = sensitivity).
```

#### Quantitative Results (primary complete-volume development results)

```text
                      pn0                  pn3
TP / FP / FN / TN     2,107 / 68,771 /      2,013 / 65,053 /
                      1,405 / 7,036,854     1,499 / 7,040,572
Dice                  0.0566473988439306   0.0570432712743348
IoU (Jaccard)         0.0291493158834027   0.0293590024064756
Precision             0.0297271367702249   0.0300152088986968
Recall (Sensitivity)  0.5999430523918      0.573177676537585
Specificity           0.990321611399419    0.990844858826634
V_GT                  3,512 mm^3           3,512 mm^3
V_pred                70,878 mm^3          67,066 mm^3
VolumeErrorPercent    1918.16628701595 %   1809.62414578588 %  (both overestimation)
```

#### Interpretation

```text
The retained pipeline recovers a moderate fraction of lesion voxels (Recall about 57-60 %) but
with a severe false-positive burden: Precision about 3 %, Dice about 0.057, IoU about 0.029, and a
predicted segmented volume about 20 times the GT lesion volume. Specificity stays about 0.99 only
because the non-lesion class has ~7.1 million voxels; it is not overall segmentation quality.
Excessive false-positive segmentation is the dominant development problem (diagnosis only; any
modification belongs to Phase 95). These are development results, not final test or
generalization performance. This table is the PRIMARY quantitative development evaluation; the
Phase-92 slice-wise metrics will be diagnostic only and must not replace it.
```

#### Decision

```text
COMPLETE-VOLUME 3D RESULTS CONSOLIDATED (primary development table). No new metric, no averaging,
no DevelopmentScore, no slice- or lesion-wise analysis, no segmentation change, no tuning, no
held-out data, config.m unchanged.
```

#### Next Experiment

```text
Phase 92 - slice-wise diagnostic metrics (not started).
```

---

### EXP-053 — Phase-92 slice-wise diagnostic evaluation

#### Pre-registration (written before EXP-053 was run)

```text
Roadmap phase: 92. Purpose: slice-wise DIAGNOSTIC evaluation of the retained Phase-71 T2 M_pred
(where FP and FN concentrate along the axial volume). The Phase-91 complete-volume table remains
the PRIMARY result; no slice metric is averaged (no mean / median) or presented as primary.
Conditions: pn0 / pn3 development only. Axis: axial, dimension 3, all slices k = 1..181
(39,277 voxels each), none excluded. GT: complete label 10 (no mask, no slice restriction).
Metrics per slice: GT-positive / predicted-positive counts, TP / FP / FN / TN (computeVoxelConfusion)
and Dice / IoU / Precision / Recall / Specificity from the existing formal functions (no new
definitions), via a new helper src/evaluation/computeSliceWiseMetrics.m (no file access, no
averaging, no components). Flags: hasGtLesion, hasPrediction, hasOverlap and denominator flags
diceIouInformative (TP+FP+FN>0), precisionInformative (TP+FP>0), recallInformative (TP+FN>0).
The CSV keeps the formal convention values (e.g. 1 on empty slices); FIGURES ONLY hide metrics with
an uninformative denominator (NaN). No slice-wise volume error, no new score.
Regression: summed slice TP / FP / FN / TN = Phase-91 counts exactly; sum GT-positive = 3,512; sum
predicted-positive = Phase-91 TP + FP.
Diagnostics: slice-category counts, max / top-5 FP and FN slices (ties: higher count, then lower
slice index), pn0 / pn3 descriptive comparison. No z cutoff, ROI, slice-specific threshold or
location rule is derived (no lesion-position leakage). No lesion-wise (Phase 93) or size (94)
analysis, no tuning (95), no MRI overlays, no held-out data, Phase-71 masks and Phase-91 CSV
unchanged, config.m unchanged.
```

#### Status

```text
COMPLETED
```

#### Implementation / Execution

```text
src/evaluation/computeSliceWiseMetrics.m; experiments/slice_wise_metrics_check.m (synthetic 5-slice
volume, 18/18 PASS); experiments/exp053_slice_wise_diagnostics.m (MATLAB, 2026-10-13, 58/58 PASS:
181 slices per condition, 362 rows, every slice 39,277 voxels and TP+FP+FN+TN = 39,277, summed
TP / FP / FN / TN = Phase-91 counts exactly, sum GT-positive = 3,512, sum predicted-positive = TP + FP,
metrics in [0,1], flags consistent, both-empty slices keep the formal conventions, categories
consistent, deterministic rankings, plotting masks leave values unchanged, no mean / median / score
/ volume error / components / location rule / held-out, Phase-71 masks, Phase-91 CSV, GT and
config.m unchanged).
Outputs: results/metrics/exp053_slice_wise_metrics.csv (362 rows), exp053_slice_diagnostic_summary.csv,
exp053_slice_top5_rankings.csv, exp053_slice_cross_condition.csv;
results/figures/exp053_{pn0,pn3}_slice_counts.png, exp053_{pn0,pn3}_slice_metrics.png.
```

#### Quantitative Results (diagnostic)

```text
Slice categories (of 181)                 pn0    pn3
GT-positive slices                         84     84   (first k 33, last k 118; 86 slices in that span)
prediction-positive slices                121    117   (first k 12 / 28, last k 144; not contiguous)
both positive                              84     84
GT-only positive                            0      0
prediction-only positive                   37     33
both empty                                 60     64
slices with TP / FP / FN                44/121/83  43/117/83

Top-5 FP slices (k:voxels)  pn0 92:1698, 93:1629, 94:1591, 95:1532, 82:1516
                            pn3 93:1650, 94:1561, 95:1490, 83:1478, 82:1465
Top-5 FN slices             pn0 100:56, 103:55, 102:54, 101:51, 97:46
                            pn3 103:59, 102:58, 100:57, 99:53, 101:52
Top-5 TP slices             pn0 102:170, 103:166, 101:138, 104:125, 98:121
                            pn3 102:166, 103:162, 101:137, 104:119, 97:118
Cross-condition: FP slices both 117, only pn0 4, only pn3 0; FN slices both 83, only pn0 0,
only pn3 0.
Derived afterwards from the CSV (descriptive only; one-off read-only sums of fpVoxels / fnVoxels
over exp053_slice_wise_metrics.csv, not printed by the script): FP on GT-empty slices 5,299 (7.7 %) / 4,355
(6.7 %); FP in k 70-104 42,824 (62.3 %) / 41,340 (63.5 %) - window chosen afterwards only to
describe the figure, not a rule; GT-positive slices with prediction but TP = 0: 40 / 41 (k 33-70
except 60, and 113/114-118), holding 489 / 517 FN (34.8 % / 34.5 % of all FN); TP > 0 only in
k 60-113 / 60-112.
```

#### Interpretation

```text
1. FP are widespread (121 / 117 of 181 slices) but strongly concentrated in the central volume:
   a broad plateau around k ~ 70-104 (about 62-64 % of all FP), peaks at k 92-95 and 82-83, and a
   secondary cluster around k ~ 52-60. Smaller FP tails extend to k 12-50 and 115-144.
2. 37 / 33 slices are prediction-only (no GT lesion voxels); they carry only ~7-8 % of the FP.
3. FN concentrate where the GT lesion load is largest (k ~ 97-103). No GT-positive slice is
   completely without prediction, but in 40 / 41 GT-positive slices (small lesion loads, k 33-70
   and 113-118) the prediction does not overlap the GT at all (Recall 0), holding about a third of
   all FN.
4. Recall on informative slices varies strongly with position (0 at k 33-70 except k 60, up to
   ~0.8-1.0 around k 80-105); Precision is close to 0 almost everywhere and only reaches ~0.4-0.45
   around k 103-104.
5. pn0 and pn3 show the same spatial pattern (same FN slices; pn0 has 4 extra low-k FP slices).
6. The slice-wise analysis supports the Phase-91 diagnosis: YES - the FP burden dominates and is
   largest in the central slices where the bright / fluid-like structures were seen in earlier
   phases (visual association, no anatomical identification).
Empty-slice warning: on slices without a positive class the formal functions return 1 by project
convention; the figures hide these values (NaN) and the CSV keeps them with explicit flags.
No slice metric is averaged; the Phase-91 complete-volume metrics remain PRIMARY. No z cutoff,
slice-specific threshold or location rule is derived.
```

#### Decision

```text
SLICE-WISE DIAGNOSTIC PROFILE ESTABLISHED. No segmentation change, no tuning, no lesion-wise or size
analysis, no held-out data, config.m unchanged.
```

#### Next Experiment

```text
Phase 93 - lesion-wise analysis (not started).
```

---

### EXP-054 — Phase-93 lesion-wise 3D connected-component analysis

#### Pre-registration (written before EXP-054 was run and before any lesion-wise result was seen)

```text
Roadmap phase: 93. Purpose: 3D lesion-wise (object-level) matching of the GT and the retained
prediction components (diagnostic; Phase 91 stays primary, Phase 92 slice-wise).
Prediction: Phase-71 T2 M_pred. Conditions: pn0 / pn3 development only. GT: complete BrainWeb crisp
label 10 (no mask, no spatial restriction, no component removed or merged).
Objects: 26-connected 3D components (bwconncomp on the complete 181x217x181 volumes) for GT and
prediction - the project's volumetric object definition, already used in Phase 72 (not claimed to
be taught in the course). No 6 / 18 / 26 comparison, no 2D identity, no slice restrictions from
Phase 92.
Matching rule (fixed now): a GT component and a predicted component match iff they share at least
one voxel (intersectionVoxelCount > 0). No overlap fraction, Dice, centroid / distance, bounding-box
or size criterion; no one-to-one assignment; many-to-many relations kept.
Definitions: detected GT lesion (TP-lesion) = GT component with >= 1 matched predicted component;
missed GT lesion = no match; matched predicted component = >= 1 GT match; false predicted component
= no GT match. Merge = predicted component with matchedGtCount > 1; split / fragmentation = GT
component with matchedPredictionCount > 1 (descriptive only, no score).
Limitation: one shared voxel counts as detection; detection does not imply good delineation. A
matched predicted component may contain many FP voxels and a detected GT lesion many FN voxels.
Regression: predicted components = Phase-72 CC3D (count and voxel lists); sum of relation overlaps =
Phase-91 TP. GT lesion count is determined, not assumed.
Not done: size filtering / classification (Phase 94), lesion-wise Precision / Recall / F1 / Dice,
regionprops3, component filtering, segmentation change, tuning, figures, held-out data. Phase-71
masks, Phase-91 / 92 artifacts and config.m unchanged.
```

#### Status

```text
COMPLETED
```

#### Implementation / Execution

```text
src/evaluation/computeLesionWiseMatches.m (bwconncomp + PixelIdxList labels, pairs from shared
voxels); experiments/lesion_wise_matching_check.m (synthetic, 17/17 PASS: perfect, partial,
one-voxel, missed, false, merge 2->1, split 1->2, mixed, 26-connected diagonal, partitions, unique
positive relations, sum of overlaps = TP, deterministic, inputs unchanged, invalid input rejected);
experiments/exp054_lesion_wise_analysis.m (MATLAB, 2026-10-13, 59/59 PASS: GT components identical
for pn0 / pn3, exact reconstruction and disjointness of all components, predicted components =
Phase-72 CC3D (count and voxel lists), sum of overlaps = Phase-91 TP, consistent relation /
merge / split counts, no one-to-one / distance / size criterion, no filtering, no held-out,
Phase-71 / 91 / 92 artifacts and config.m unchanged).
Outputs: results/metrics/exp054_lesion_wise_summary.csv, exp054_gt_lesion_status.csv,
exp054_predicted_component_status.csv, exp054_lesion_matches.csv.
```

#### Quantitative Results

```text
                                          pn0     pn3
GT lesion components (26-connected)        59      59
predicted components                      335     291   (= Phase 72)
detected GT lesions (TP-lesions)           15      14
missed GT lesions                          44      45
matched predicted components                4       4
false predicted components                331     287
GT lesions matched by > 1 prediction        1       1   (GT lesion 49, 2 predicted components)
predicted components matching > 1 GT        1       1   (13 / 12 GT lesions)
match relations                            16      15
overlap voxels across relations          2,107   2,013 (= Phase-91 TP)
GT lesions detected in both conditions 14; only pn0 1; only pn3 0.
Merged component: pn0 #124 / pn3 #92 touches 13 / 12 GT lesions and holds 1,844 / 1,792 overlap
voxels, i.e. 87.5 % / 89.0 % of all TP. In the Phase-72 table (exp039_components3d.csv, cross-
reference only) it is the 25,629 / 25,417-voxel component spanning k 68-107, so it also contains
23,785 / 23,625 FP voxels (34.6 % / 36.3 % of all FP) - derived afterwards from the CSVs. The other
three matched components hold 14, 72 and 177 (pn0) / 14, 52 and 155 (pn3) overlap voxels.
```

#### Interpretation

```text
Under the pre-registered any-overlap criterion only 15 / 14 of the 59 GT lesion objects are
counted as detected; 44 / 45 are missed. Almost all predicted components (331 / 287, ~99 %) touch
no GT lesion (98.8 % / 98.6 %). Most of the voxel-level Recall comes from ONE large predicted
component that is connected to and overlaps 13 / 12 distinct GT lesions (merging them, relative to
the GT component definition, into one predicted object) - the large central candidate already
described as bright / fluid-like (Phases 61-72) - which also carries about a third of all FP
voxels. "Detected" always means detected under the permissive any-overlap criterion; 15/59 is not
a formal lesion recall. The ~60 % voxel Recall
therefore does not mean that most lesions are found: few lesion objects are touched, and most of
the recovered lesion voxels lie in that fused object. The object-level and voxel-level results
answer different questions: false-component count != FP voxels (matched components can contain
many FP), missed-lesion count != FN voxels (detected lesions can contain FN), and one shared voxel
is enough for detection. pn0 and pn3 behave almost identically.
```

#### Decision

```text
LESION-WISE OBJECT ANALYSIS ESTABLISHED (diagnostic; Phase 91 remains primary). No size analysis,
no component filtering, no segmentation change, no tuning, no held-out data, config.m unchanged.
```

#### Next Experiment

```text
Phase 94 - small-vs-large lesion analysis (not started).
```

---

### EXP-055 — Phase-94 small-vs-large GT lesion analysis

#### Pre-registration (written before EXP-055 was run)

```text
Roadmap phase: 94. Purpose: determine whether the Phase-93 lesion-wise failures depend on GT lesion
size (diagnostic).
Lesions: complete 3D 26-connected components of the BrainWeb crisp label-10 GT (same definition as
Phase 93; IDs from the same bwconncomp enumeration). Size variable: GT component voxel count
(1 x 1 x 1 mm -> volume in mm^3 reported alongside).
Threshold: T_size = median of all GT component voxel counts, computed from the GT sizes ONLY (helper
classifyGtLesionSizes receives sizes only) and frozen BEFORE the Phase-93 detection status is read.
SMALL: size <= T_size; LARGE: size > T_size; ties at the median stay SMALL (no artificial split).
Dataset-relative, not a clinical definition. Same sizes / classes for pn0 and pn3.
Transparency: the Phase-93 detected lesion IDs are already known, but the GT lesion sizes were not
computed before this phase; the median rule was fixed in the phase prompt, not chosen afterwards.
If one class is empty -> TECHNICALLY BLOCKED BY SIZE DISTRIBUTION (no alternative threshold).
Status source: exp054_gt_lesion_status.csv (frozen Phase-93 any-overlap rule; no rematching, no
connectivity change). Diagnostics: per-lesion GT voxel coverage = totalOverlapVoxels /
gtLesionVoxels; per class: detected / missed, detection fraction (diagnostic, not "lesion recall"),
recovered GT voxels / class GT voxels; pn0 / pn3 cross-condition status by class.
Not done: predicted-component size classes or filtering, lesion-wise Dice / IoU / Precision / Recall
/ F1, regression / correlation / significance testing, threshold search, segmentation change,
tuning, held-out data. The median GT size is evaluation-only and never a segmentation or filtering
threshold. Prior EXP-052 / 053 / 054 artifacts and config.m unchanged.
```

#### Status

```text
COMPLETED
```

#### Implementation / Execution

```text
src/evaluation/classifyGtLesionSizes.m (sizes only); experiments/lesion_size_classification_check.m
(synthetic, 13/13 PASS); experiments/exp055_small_vs_large_lesions.m (MATLAB, 2026-10-13, 38/38 PASS:
GT components (26) reconstruct M_GT, sizes sum to 3,512, median computed from GT sizes only and
before the status file is read, class rule and ties correct, 59 components = Phase 93, IDs one-to-
one, Phase-93 status reproduced, overlaps within lesion sizes, coverage in [0,1], missed -> 0,
detected -> > 0, summed overlap = Phase-91 TP, identical classes pn0 / pn3, no prediction / rematch /
filtering / lesion-wise metric / model fitting / held-out, prior artifacts, GT and config.m unchanged).
Outputs: results/metrics/exp055_gt_lesion_size_analysis.csv (118 rows), exp055_size_class_summary.csv,
exp055_size_cross_condition.csv; results/figures/exp055_small_large_detection_counts.png,
exp055_lesion_size_vs_gt_coverage.png.
```

#### Quantitative Results

```text
59 GT lesions; median size threshold T_size = 7 voxels = 7 mm^3.
SMALL (<= 7): 31 lesions, sizes 1-7 (median 3), 108 GT voxels in total.
LARGE (> 7):  28 lesions, sizes 8-927 (median 29), 3,404 GT voxels in total.

            detected / missed  detection fraction  recovered / class GT voxels  coverage
pn0 SMALL        3 / 28           0.096774               6 / 108              0.055556
pn0 LARGE       12 / 16           0.428571           2,101 / 3,404             0.617215
pn3 SMALL        2 / 29           0.064516               5 / 108              0.046296
pn3 LARGE       12 / 16           0.428571           2,008 / 3,404             0.589894

Cross-condition: SMALL detected both 2, only pn0 1, only pn3 0, missed both 28;
LARGE detected both 12, only pn0 0, only pn3 0, missed both 16.
Descriptive (read afterwards from the per-lesion CSV, pn0): the 8 largest GT lesions (155-927
voxels) are all detected, with coverage 0.49-0.85; of the 20 LARGE lesions with 8-127 voxels,
16 are missed and the 4 detected ones have coverage 0.03-0.45. This is a description of the
distribution, not a new threshold.
```

#### Interpretation

```text
Lesion size is strongly associated with the failure mode: SMALL lesions are almost always missed
(detected 3 / 31 and 2 / 31; about 5 % of their voxels covered), while LARGE lesions are detected
more often (12 / 28) and better covered (about 0.59-0.62). But size explains the lesion-wise
failure only PARTLY: 16 of the 28 LARGE lesions are missed in both conditions, all in the lower
part of the LARGE range (8-127 voxels); only the biggest lesions are reliably touched. Missed
lesions are predominantly SMALL (28 / 44 and 29 / 45), but a substantial share is LARGE. Because
SMALL lesions hold only 108 of 3,512 GT voxels, they barely affect voxel-level Recall, which is
dominated by the few big lesions. Interpretation consistent with Phases 63 / 70 (not tested here):
the per-slice square3 opening removes any isolated structure that cannot contain a 3 x 3 square,
so lesions of <= 8 voxels can only survive as part of a larger candidate region. pn0 and pn3 show
the same size pattern (one extra SMALL detection in pn0).
Warnings: detection requires only one overlapping voxel; GT voxel coverage is a diagnostic support
quantity, not a new formal metric; SMALL / LARGE are dataset-relative, not clinical; the median GT
size (7 voxels) is NOT a segmentation or component-filtering threshold.
```

#### Decision

```text
SIZE-STRATIFIED LESION DIAGNOSTIC ESTABLISHED: size explains the lesion-wise failure PARTLY. No
predicted-component filtering, no segmentation change, no tuning, no held-out data, config.m
unchanged.
```

#### Next Experiment

```text
Phase 95 - development-only tuning (not started).
```

---

### EXP-056 — Phase-95 development-only final tuning

#### Pre-registration (written before EXP-056 was run; the grid is frozen here)

```text
Roadmap: Phase 95. Data: pn0 + pn3 only; held-out pn1 / pn5 / pn7 / pn9 untouched. Modality: T2.
Grid (exactly 24 = 2 x 2 x 3 x 2 configurations, 48 predictions; IDs P?_T?_M?_G?):
  P0 no filter | P1 Gaussian sigma 0.5, 3x3, replicate, 2D per slice (gaussianFilterSlices)
  T2 multithresh(T2(brainMask), 2) -> Class 3 | T3 multithresh(T2(brainMask), 3) -> Class 4
     (thresholds estimated automatically per volume, never modified; generateLesionCandidateMask)
  M0 none | M1 one 2D axial opening strel('diamond',1) | M2 one 2D axial opening strel('square',3)
     (imopen per slice, then AND brainMask)
  G0 none | G1 remove 26-connected 3D components occupying exactly one axial slice (keep
     occupiedSliceCount >= 2; no voxel-count, size, position or shape criterion)
Baseline: P0_T2_M2_G0 must reproduce Phase-71 M_pred exactly (pn0, pn3), otherwise TECHNICALLY
BLOCKED; its Dice must reproduce Phase 91.
Order: all 48 predictions generated and saved BEFORE the GT is loaded (no GT in generation).
Selection (Phase 37): complete-volume 3D Dice; DevelopmentScore = (Dice_pn0 + Dice_pn3) / 2; one
parameter set for both conditions; no near-tie tolerance. Exact-tie order: weaker-condition Dice,
then simpler configuration = fewer active blocks (P1, T3, M1/M2, G1 each count as one block; M1
counted as simpler than M2), then configuration ID. The winner's score is necessarily >= the baseline.
Secondary metrics (IoU, Precision, Recall, Specificity, TP/FP/FN/TN, volumes, volume error),
lesion-wise (Phase-93 rule) and SMALL / LARGE (Phase-94 grouping) diagnostics: POST-SELECTION ONLY,
never re-ranking. Declared point: G1 is a component-removal rule like the Phase-69 filter that the
Phase-70 small-lesion audit rejected; here, by this phase's rule, only DevelopmentScore selects, and
if the winner uses G1 (or a stronger operation) the GT lesions lost relative to the baseline are
reported without changing the selection.
Forbidden: grid extension after results, condition-specific parameters, manual thresholds,
slice / position rules, the Phase-94 7-voxel value or any GT-derived size in generation, region
growing, multimodal fusion, local thresholding, refinement around the winner. config.m unchanged;
the selected configuration is NOT yet frozen (Phase 96).
```

#### Status

```text
COMPLETED (selected development configuration; not frozen)
```

#### Implementation / Execution

```text
src/segmentation/generatePhase95Prediction.m (P -> T -> M -> G, grid values only, no GT; reuses
gaussianFilterSlices and generateLesionCandidateMask), src/segmentation/removeSingleSliceComponents3D.m;
experiments/phase95_prediction_pipeline_check.m (synthetic, 21/21 PASS; its tiny 4-level volume gives
two multithresh "did not converge" warnings, which do not affect the checks - no such warning on the
real data); experiments/exp056_development_tuning.m (MATLAB, 2026-10-13, 27/27 PASS: 24 unique
configurations, 48 predictions saved before GT, all inside the brain mask, baseline P0_T2_M2_G0 =
Phase-71 M_pred exactly and = Phase-91 Dice, exact-mean scores, rank-1 winner >= baseline, diagnostics
did not change the winner, no held-out / position / GT-size rule, sources and config.m unchanged).
Outputs: data/processed/phase95_candidates/exp056_<id>_{pn0,pn3}.mat (48),
data/processed/phase95_t2_{pn0,pn3}_selected_prediction.mat; results/metrics/exp056_tuning_grid_results.csv
(48), exp056_tuning_ranking.csv (24), exp056_selected_configuration.csv, exp056_baseline_vs_selected.csv,
exp056_selected_lesion_diagnostics.csv; results/figures/exp056_tuning_ranking.png,
exp056_baseline_vs_selected_metrics.png.
```

#### Quantitative Results

```text
Ranking (DevelopmentScore; Dice pn0 / pn3):
 1 P0_T2_M2_G1 0.058158 (0.058067 / 0.058248)  SELECTED      13 P0_T2_M0_G1 0.041999
 2 P0_T2_M2_G0 0.056845 (0.056647 / 0.057043)  baseline      14 P1_T3_M0_G1 0.041922
 3 P1_T2_M2_G1 0.056307                                       15 P0_T3_M0_G0 0.041595
 4 P0_T2_M1_G1 0.055260                                       16 P0_T2_M0_G0 0.041545
 5 P1_T2_M2_G0 0.055001                                       17 P1_T3_M1_G0 0.041505
 6 P0_T2_M1_G0 0.053937                                       18 P0_T3_M2_G1 0.041124
 7 P1_T2_M1_G1 0.052912                                       19 P1_T3_M0_G0 0.040645
 8 P1_T2_M1_G0 0.051610                                       20 P0_T3_M2_G0 0.040594
 9 P0_T3_M1_G1 0.044238                                       21 P1_T3_M2_G1 0.039286
10 P0_T3_M1_G0 0.043397                                       22 P1_T3_M2_G0 0.038531
11 P0_T3_M0_G1 0.042996                                       23 P1_T2_M0_G1 0.038479
12 P1_T3_M1_G1 0.042278                                       24 P1_T2_M0_G0 0.038275
Winner P0_T2_M2_G1: DevelopmentScore 0.058157789028849 vs baseline 0.0568453350591327
(+0.00131245, +2.3 % relative); weaker-condition Dice 0.058067 (baseline 0.056647). No exact tie.

Baseline -> selected        pn0                       pn3
Dice                        0.056647 -> 0.058067      0.057043 -> 0.058248
IoU                         0.029149 -> 0.029902      0.029359 -> 0.029998
Precision                   0.029727 -> 0.030520      0.030015 -> 0.030695
Recall                      0.59994  -> 0.59596       0.57318  -> 0.56919
TP / FP / FN                2,107/68,771/1,405 -> 2,093/66,484/1,419   2,013/65,053/1,499 -> 1,999/63,126/1,513
predicted voxels            70,878 -> 68,577          67,066 -> 65,125
volume error                1918.2 % -> 1852.6 %      1809.6 % -> 1754.4 %
Lesion-wise (post-selection, Phase-93 rule): predicted components 335 -> 165 / 291 -> 143; false
components 331 -> 162 / 287 -> 140; detected GT lesions 15 -> 14 / 14 -> 13 (SMALL 3 / 2 unchanged,
LARGE 12 -> 11 in both). Lost in both conditions: GT lesion 16 (31 voxels, LARGE); no lesion gained.
Cross-reference (Phase-72 table / EXP-054): GT lesion 16 was touched only by predicted component #103
(pn0) / #78 (pn3), a single-slice component at k 60 with 14 / 15 voxels; G1 removes it, so the 14 TP
lost per condition are exactly this lesion's overlap.
```

#### Interpretation

```text
G1 roughly halves the number of predicted 3D components (about 51 % of them are single-slice) but
removes only ~2,000 FP voxels (about 3 % of FP), because most FP voxels lie in multi-slice components,
especially the large central bright / fluid-like one. Dice rises slightly (+0.0013), Recall falls
slightly (14 TP lost per condition) and the volume overestimation remains about 1750-1850 %: the
dominant FP problem is only marginally reduced. Descriptive factor pattern across the factorial grid
(not used for selection): G1 >= G0 in all 12 matched pairs; P1 (Gaussian) < P0 in all 12 matched pairs;
T3 (N = 3) is worse than T2 whenever an opening is applied (8 / 8 pairs) but slightly better without
opening (M0, 4 / 4 pairs, all low-ranked); with T2, M2 (square 3) > M1 (diamond 1) > M0 (none). The selected rule removes the only predicted support of GT lesion 16 - the same kind of loss
that led to the rejection of EXP-036 in Phase 70; by this phase's pre-registered rule it is reported
but does not change the selection.
```

#### Decision

```text
SELECTED DEVELOPMENT CONFIGURATION: P0_T2_M2_G1 = no preprocessing; multithresh N = 2, Class 3; one 2D
axial square-3 opening; removal of single-slice 26-connected 3D components. Highest DevelopmentScore
(0.058158), selected by the Phase-37 rule only. NOT yet frozen (Phase 96 not started). No held-out data,
no grid extension, config.m unchanged.
```

#### Next Experiment

```text
Phase 96 - freeze final parameters (not started).
```

---

### EXP-057 — Phase-95 supplementary development experiment: T1-derived anatomical support

#### Pre-registration (written before EXP-057 was run; reviewed by the user and approved on 2026-10-14)

```text
Status: FINAL development experiment before Phase 96. Whatever the result, Phase 96 (freeze)
follows; no EXP-058 or further adjustment.
Data: T2 + T1, pn0 + pn3 only (T1 pn3 already downloaded); held-out untouched.
Grid (36 configurations, 72 predictions, IDs S?_T?_M?_G?):
  T1 partition (per condition, automatic): multithresh(T1norm(EXP-021), 2) -> Class 1 = T1-low
    candidate, Class 3 = T1-high candidate (terminology: candidates, not certain CSF / WM).
  S0 = EXP-021
  S1 = EXP-021 AND NOT T1-low
  S2 = EXP-021 AND imfill(T1-high, 'holes') per axial slice (default 2D connectivity) AND NOT T1-low
       ("WM-support envelope"; no component selection, closing or other step)
  TA = multithresh(T2norm(S), 2), highest class, inside S
  TB = graythresh(T2norm(S)), voxels > threshold, inside S
  (the T2 threshold is always re-estimated from the voxels of the selected support)
  M0 none | M1 one 2D opening diamond 1 | M2 one 2D opening square 3 (then AND S)
  G0 none | G1 remove 26-connected 3D components occupying one axial slice
Baseline: S0_TA_M2_G1 must equal the EXP-056 winner P0_T2_M2_G1 voxel by voxel (pn0, pn3),
  otherwise TECHNICALLY BLOCKED.
Order: all 72 predictions saved before the GT is loaded.
Selection: Phase-37 rule only (complete-volume Dice, DevelopmentScore, no tolerance). Exact ties:
  weaker-condition Dice, then fewer blocks (S1 = 1, S2 = 2, M != 0 = 1, G1 = 1; TA = TB), then ID.
Rationale (development evidence, declared): T2-bright CSF dominates FP (Phases 61, 92-93; EXP-056
  G1 removed only ~3 % of FP); in EXP-040, after the square-3 opening, T1 Class 1 held 3 / 7 TP
  (does not prove that Class 1 is a clean CSF mask). The design is informed by development results;
  pn0 / pn3 have now been used for several major choices, so part of any gain may be adaptation to
  them - generalization is judged only by the held-out test.
Declared failure modes (no post-hoc fix): partial-volume ventricle-border voxels stay T2-bright and
  outside T1-low; noisy pn3 T1-low may remove some lesion voxels; S2 includes deep GM enclosed by WM;
  juxtacortical / non-enclosed lesions may fall outside S2; TB inside S1 may split WM / GM.
Forbidden: any grid extension, erosion / closing of supports, other T1 classes or N, manual
  thresholds, ventricle-border rules, slice / position rules, GT-derived sizes, EXP-058.
Post-selection diagnostics only: secondary metrics, lesion-wise (Phase-93 rule), SMALL / LARGE.
```

#### Results (run 2026-10-14; synthetic check PASS 19/19; main script `experiments/exp057_t1_support_tuning.m` PASS 27/27)

```text
Baseline reproduction: S0_TA_M2_G1 = EXP-056 winner P0_T2_M2_G1 voxel by voxel (pn0, pn3);
  DevelopmentScore 0.058157789028849 reproduced.
T1 partition (automatic, per condition):
  pn0 thresholds 0.34051 / 0.48969; pn3 thresholds 0.31614 / 0.45629
  (exact T1-low / T1-high counts in exp057_support_summary.csv)
  Support sizes (voxels, CSV): S0 1,688,787 / 1,668,366; S1 1,531,677 / 1,523,572; S2 713,108 / 712,948
  GT voxels inside the support (evaluation only, read after selection): S0 3512 / 3512,
  S1 3508 / 3502, S2 3114 / 3058 -> S2 caps voxel Recall at 0.8867 / 0.8707.
Ranking (Phase-37 rule, no ties at the top):
  1 S2_TA_M2_G1  Dice 0.661039 / 0.539029  DevelopmentScore 0.600033865204608  (+0.541876)
  2 S2_TA_M2_G0  0.656351 / 0.503559  0.57996
  3 S2_TA_M1_G1  0.666253 / 0.440976  0.55361   (best pn0 Dice; weaker on pn3)
  5 S1_TA_M2_G1  0.433163 / 0.370416  0.40179   (best S1)
  15 S0_TA_M2_G1 0.058067 / 0.058248  0.058158  (EXP-056 winner, reproduced)
  All TA configurations in S2 with an opening rank 1-4; every TB configuration in S1 ranks last
  (Dice < 0.011: graythresh inside S1 selects a large fraction of the support, e.g. 834,259 voxels).
SELECTED (development, not frozen): S2_TA_M2_G1
  pn0: TP 2310, FP 1167, FN 1202; Precision 0.664366, Recall 0.657745, IoU 0.493695,
       Specificity 0.999836, V_pred 3477 mm3, volume error 0.997 %
  pn3: TP 2448, FP 3123, FN 1064; Precision 0.439418, Recall 0.697039, IoU 0.368953,
       Specificity 0.999560, V_pred 5571 mm3, volume error 58.63 %
  vs EXP-056 winner: FP 66,484 -> 1,167 (-98.2 %) / 63,126 -> 3,123 (-95.1 %); TP +217 / +449.
FN decomposition of the selected configuration (from the grid CSV):
  pn0 FN 1202 = 398 GT voxels outside S2 + 804 inside S2 removed by opening + G1
       (S2_TA_M0_G0 already has TP 3114 = all GT voxels inside S2)
  pn3 FN 1064 = 454 outside S2 + 610 removed by opening + G1 (S2_TA_M0_G0 TP 3058)
Lesion-wise (Phase-93 rule, 26-connected, any overlap):
  pn0 detected 19 / 59 (EXP-056 winner 14); false predicted components 0 of 20 (was 162 of 165)
  pn3 detected 28 / 59 (13); false predicted components 17 of 45 (was 140 of 143)
  SMALL detected 2 / 6 (EXP-056 winner 3 / 2); LARGE 17 / 22 (11 / 11)
  Lost vs EXP-056 winner: pn0 [21 33 44 47], pn3 [33 37 44 47]; in the Phase-94 baseline record
  these matches relied on 1-3 overlapping voxels. Newly detected: 9 (pn0), 19 (pn3).
Figures: exp057_supports.png (GT-free), exp057_tuning_ranking.png, exp057_exp056winner_vs_selected.png
```

#### Interpretation

- The hypothesis is supported on the development data. Restricting the T2 threshold to the T1-derived envelope S2 removes most of the T2-bright fluid-like false positives. The re-estimated multithresh threshold inside S2 then separates the lesion candidates from the enclosed tissue.
- In pn0, within S2, the TA candidate before morphology already contains every GT voxel of S2. The remaining FN come from two sources: GT voxels outside S2 (11.3 % / 12.9 % of GT, consistent with the declared juxtacortical / non-enclosed failure mode) and the square-3 opening + G1, which remove thin lesion voxels.
- The two conditions differ more than before: pn3 has 2.7× the FP of pn0 and a lower TA threshold inside S2 (0.5182 vs 0.6112). This suggests a sensitivity to noise that the held-out conditions pn5 / pn7 / pn9 (more noise) may amplify. This is a risk, not a measured result.
- Caveats on generalization:
  - BrainWeb is a simulation with near-piecewise-constant tissue intensities and no bias field in rf0, which favors an automatic T1 three-class partition.
  - The design was chosen after several development results on pn0 / pn3 (declared in the pre-registration).
  - Selecting among 36 configurations adds optimism, although small relative to the gap between rank 1 and the baseline.
- No fix was applied after reading the results: the selection follows the pre-registered rule.

#### Conclusion

```text
SELECTED DEVELOPMENT CONFIGURATION S2_TA_M2_G1 (DevelopmentScore 0.600034 vs 0.058158).
Final development experiment: no EXP-058. Not yet frozen; next: Phase 96 (freeze), then held-out test.
Files: data/processed/phase95_exp057_t2_{pn0,pn3}_selected_prediction.mat;
  results/metrics/exp057_{support_summary,tuning_grid_results,tuning_ranking,selected_configuration,
  exp056winner_vs_selected,selected_lesion_diagnostics}.csv
```

#### v1 freeze record (2026-10-14, before any EXP-058 work)

```text
v1 = EXP-057 selected configuration S2_TA_M2_G1, FROZEN as a development snapshot.
Pipeline (no parameter may change):
  T1, T2 -> double -> /4095 (no filter)
  brain support: EXP-021 mask (frozen, exp021_t1_{pn0,pn3}_3d_erode_select_dilate_candidate.mat)
  T1 partition: levels = multithresh(T1norm(EXP-021), 2); T1-low = class 1, T1-high = class 3
  S2 = EXP-021 AND imfill(T1-high, 'holes') per axial slice (default 2D connectivity) AND NOT T1-low
  candidate = S2 AND T2norm in highest class of multithresh(T2norm(S2), 2)
  one 2D axial opening strel('square', 3) per slice, then AND S2
  remove 26-connected 3D components occupying a single axial slice
Code: src/segmentation/computeT1AnatomicalSupport.m, generateExp057Prediction.m,
  generateLesionCandidateMask.m, removeSingleSliceComponents3D.m;
  experiments/exp057_t1_support_tuning.m (regenerates the predictions).
Development scores: Dice 0.661038775218200 (pn0) / 0.539028955191016 (pn3);
  DevelopmentScore 0.600033865204608. Predicted voxels 3,477 / 5,571.
Artifacts (SHA-256 of the saved files; a regeneration writes a new MAT header, so identity is
  then checked on the M_pred content with isequal, not on the file hash):
  data/processed/phase95_exp057_t2_pn0_selected_prediction.mat
    12147984BACB7F94BAC288F89109BF605877AEFE8611C02115BECE81E44FEB9D
  data/processed/phase95_exp057_t2_pn3_selected_prediction.mat
    AFDE41B5EC35B89ED25ED9E95D53560021D27E19F5335FDDBAFE58B887603B57
Version control: Git commit "fase 96a" + tag v1-frozen.
Held-out pn1 / pn5 / pn7 / pn9: NOT accessed, NOT downloaded.
```

### Protocol amendment A1 (2026-10-14): development reopened for one experiment (EXP-058)

```text
Original commitment: EXP-057 was pre-registered as the FINAL development experiment ("no EXP-058").
That statement is NOT rewritten; this amendment supersedes it, decided by the user after reading
the EXP-057 results.
Reason: EXP-057 changed the method from a non-working to a working segmentation (DevelopmentScore
  0.058 -> 0.600) and quantified specific residual margins: voxels removed by the opening
  (804 / 610 lesion voxels), lesion voxels outside S2 (398 / 454), pn3 noise (2.7x the FP of pn0).
Rules:
  1. v1 (S2_TA_M2_G1) is frozen BEFORE EXP-058 (record above) and is never modified.
  2. EXP-058 (v2) = exactly ONE pre-registered development experiment on pn0 + pn3 only. Its base
     configuration must reproduce v1 voxel by voxel. No EXP-059 afterwards.
  3. Primary version for the final test, fixed BEFORE any held-out access:
       primary = v2 if DevelopmentScore(v2) > DevelopmentScore(v1) (strict, Phase-37 rule),
       otherwise primary = v1; the other version is reported as secondary.
  4. Phase 96: freeze primary + secondary. Only then download pn1 / pn5 / pn7 / pn9; Phase 97
     evaluates BOTH. Held-out results cannot change which version is primary.
  5. No diagnostic using the GT is run to decide the structure of the EXP-058 grid.
Declared cost: pn0 / pn3 are used for one more design choice; part of any v2 gain may be
  adaptation to them. The held-out test judges generalization.
```

---

### EXP-058 — v2 development experiment under protocol amendment A1: noise filtering x extent recovery

#### Pre-registration (written before EXP-058 was run; reviewed by the user and approved on 2026-10-14)

```text
Status: the ONLY experiment allowed by amendment A1; no EXP-059. Development data only.
Data: T1 + T2, pn0 + pn3; held-out not accessed. EXP-021 brain mask unchanged (not recomputed).
Fixed v1 pipeline (v1 freeze record): T1 partition -> S1 / S2 -> TA inside S2 ->
  square-3 opening per slice AND S2 -> G1 (single-slice 26-connected 3D components removed).
Factor F (applied after /4095, before any support or threshold):
  F0 none
  F1 / F2 / F3  Gaussian sigma 0.5, 3x3, replicate, per axial slice (gaussianFilterSlices;
                result clipped to [0,1] as in EXP-056, error if the excursion exceeds 1e-12)
                on T1 / T2 / both
  F4 / F5 / F6  anisotropic diffusion, per axial slice, imdiffusefilt with EXPLICIT parameters
                (frozen definition, independent of future MATLAB defaults):
                  ConductionMethod "exponential", Connectivity "maximal" (8-neighbour in 2D),
                  NumberOfIterations 5, GradientThreshold = 0.10 x (max - min) of the slice;
                constant slices (max = min) returned unchanged (diffusion of a constant image is
                the identity; avoids a zero gradient threshold); same [0,1] range check as F1-F3;
                on T1 / T2 / both
                The synthetic check records whether this explicit call equals imdiffusefilt(slice)
                with default options on non-constant slices. If it does not, the explicit
                definition above still holds and the difference is documented.
  A filtered T1 changes the T1 partition, therefore S1 and S2. A filtered T2 changes TA (always
  re-estimated inside S2, as in v1) and the reconstruction masks.
Factor R (after the complete v1 pipeline; nothing is applied after R):
  R0 none (= v1 output of that F)
  R1 imreconstruct(marker = v1 output, mask = S2 AND T2f > TA_S2), 26-connectivity
     (mask = the TA candidate inside S2 before the opening)
  R2 imreconstruct(marker = v1 output, mask = S1 AND T2f > TA_S2), 26-connectivity
     (same numeric TA_S2 of the configuration; no threshold estimated in S1)
  Invariants checked for every F and condition: R0 inside R1 inside R2;
  R1 inside (S2 AND T2f > TA_S2); R2 inside (S1 AND T2f > TA_S2).
Grid: 7 F x 3 R = 21 configurations, 42 predictions, IDs F?_R?; all saved before the GT is loaded.
Base check: F0_R0 must equal the frozen v1 prediction voxel by voxel (pn0, pn3), otherwise
  TECHNICALLY BLOCKED.
Selection: Phase-37 rule (complete-volume Dice, DevelopmentScore, no tolerance). Exact ties:
  weaker-condition Dice, then fewer blocks (Gaussian 1 per filtered volume, anisotropic 2 per
  filtered volume, R1 = 1, R2 = 2), then ID.
Primary for the final test (amendment A1): the v1 DevelopmentScore is read from the frozen
  artifact results/metrics/exp057_selected_configuration.csv and verified against the recorded
  value 0.600033865204608 (sanity check). v2 = winner only if its DevelopmentScore is strictly
  higher than v1's; if the winner is F0_R0, there is no v2 and v1 is primary.
Declared failure modes (no post-hoc fix):
  - pn0 has no added noise: filtering may cost Dice there and lose on the mean score even if it
    helps pn3;
  - the Gaussian may blur lesions of a few voxels;
  - the fixed diffusion parameters may not match the noise level of each condition;
  - R1 / R2 also restore T2-bright voxels connected to a seed that are not lesion
    (e.g. ventricle-border partial-volume rims);
  - R2 may leak far into S1 along connected bright structures above TA_S2;
  - lesions with no surviving v1 seed (erased by the opening, or entirely outside S2) cannot
    be recovered by R.
Forbidden: other sigma / diffusion parameters, other filter families, filtering the EXP-021 mask
  input, thresholds estimated in S1, morphology or component rules after R, GT diagnostics
  before the run, grid extensions, EXP-059.
Post-selection diagnostics only (do not change the winner): secondary metrics, lesion-wise
  (Phase-93 rule), SMALL / LARGE, lesions lost / gained vs v1.
```

#### Results (run 2026-10-14; synthetic check PASS 16/16; main script `experiments/exp058_v2_tuning.m` PASS 27/27)

```text
Base check: F0_R0 = frozen v1 voxel by voxel (pn0, pn3); v1 DevelopmentScore read from the
  artifact and verified. (F0_R0 shows deltaVsV1 = 1.1e-16 because the CSV stores 15 significant
  digits; harmless: the A1 rule also requires winner != F0_R0, and the winner gap is 0.061.)
Synthetic INFO (recorded, not a pass condition): the explicit anisotropic call does NOT equal
  imdiffusefilt(slice) with default options; the MATLAB default gradient threshold is therefore not
  "10 % of the slice range". The frozen explicit definition holds (pre-registered).
Ranking (Phase-37 rule):
  1 F5_R0 anisotropic T2 only    Dice 0.669340 / 0.653000  DevelopmentScore 0.66116938387951 (+0.061136)
  2 F6_R0 anisotropic T1 + T2    0.6635 / 0.65099   0.65725
  3 F2_R0 Gaussian T2 only       0.64817 / 0.63998  0.64407
  4 F3_R0 Gaussian T1 + T2       0.6419 / 0.63576   0.63883
  5 F1_R0 Gaussian T1 only       0.65552 / 0.57035  0.61293
  6 F0_R0 frozen v1              0.66104 / 0.53903  0.60003
  9 F4_R0 anisotropic T1 only    0.68409 / 0.38456  0.53433 (best pn0 Dice; pn3: S2 726,829 voxels,
        TA_S2 0.5014, FP 7,998)
  R1 configurations: ranks 7-14 (best F6_R1 0.57517); R2 configurations: ranks 15-21 (< 0.035).
WINNER: F5_R0. PRIMARY VERSION FOR THE FINAL TEST (amendment A1): v2 = F5_R0; secondary: v1.
v1 vs v2 (complete volume):
  pn0: Dice 0.66104 -> 0.66934; Precision 0.66437 -> 0.69969; Recall 0.65774 -> 0.64151;
       TP 2310 -> 2253, FP 1167 -> 967, FN 1202 -> 1259; volume error 1.00 % -> 8.31 %
  pn3: Dice 0.53903 -> 0.65300; Precision 0.43942 -> 0.71193; Recall 0.69704 -> 0.60308;
       TP 2448 -> 2118, FP 3123 -> 857, FN 1064 -> 1394; volume error 58.63 % -> 15.29 %
  TA_S2 (normalized): pn0 0.6112 -> 0.6160; pn3 0.5182 -> 0.5630
Lesion-wise (Phase-93 rule):
  pn0: detected 19 -> 18; false components 0 -> 0 (of 17); SMALL 2 -> 2, LARGE 17 -> 16;
       lost [2 45], gained [12]
  pn3: detected 28 -> 16; false components 17 -> 1 (of 19); SMALL 6 -> 1, LARGE 22 -> 15;
       lost [2 12 21 24 30 32 38 43 45 46 58 59], gained none
Recovery (F0): R1 TP +572 / +554 but FP +4,606 / +9,131; R2 FP 209,719 / 584,713 (leak into S1).
Figures: exp058_filters_t2_pn3.png (GT-free), exp058_tuning_ranking.png, exp058_v1_vs_winner.png
```

#### Interpretation

- **Noise filtering of T2 is the effective block.** All four configurations that filter T2 without recovery beat v1. In pn3 the anisotropic filter raises TA_S2 from 0.518 to 0.563, cuts FP from 3,123 to 857 and brings pn3 close to pn0 (Dice 0.653 vs 0.669; predicted voxels 2,975 vs 3,220). Inside S2, the v1 noise sensitivity came mostly from the threshold on noisy T2.
- **Filtering T1 alone is unstable:** F4_R0 is the best on pn0 but the worst R0 on pn3, where S2 grows and TA_S2 drops.
- **The extent recovery failed, as declared in the pre-registration.** R1 restores lesion voxels but more FP connected to the seeds: the opening also disconnects lesion cores from adjacent T2-bright structures. R2 leaks through S1 (declared failure mode). Nothing was adjusted.
- **Trade-off of v2 (not a selection criterion):** in pn3 v2 detects fewer GT lesions under the permissive any-overlap rule (28 -> 16; SMALL 6 -> 1), and voxel Recall drops (0.697 -> 0.603). The v1 pn3 count was higher than pn0 (28 vs 19) together with 17 false components. This is compatible with noise-driven small overlaps, but it was not verified. v2 is more conservative and more consistent across conditions, at the cost of small-lesion detection.
- The selection follows the pre-registered rule; the margin over rank 2 is small (0.0039), while the "filter T2" family is consistently ahead.
- **Generalization:** the held-out levels pn5 / pn7 / pn9 are noisier than pn3. The fixed diffusion parameters (5 iterations, threshold relative to the slice range) were not tuned for them.

#### Conclusion

```text
v2 = F5_R0 (v1 pipeline with anisotropic diffusion of T2, explicit fixed parameters; no recovery).
PRIMARY for the final test: v2; SECONDARY: v1. Decided before any held-out access (amendment A1).
Development is CLOSED: no EXP-059. Next: Phase 96 (freeze v2 + v1), then held-out download and Phase 97.
Files: data/processed/phase95_exp058_v2_{pn0,pn3}_selected_prediction.mat;
  results/metrics/exp058_{tuning_grid_results,tuning_ranking,selected_configuration,v1_vs_winner,
  winner_lesion_diagnostics}.csv
```

#### v2 freeze record (2026-10-14, before any EXP-059 work)

```text
v2 = EXP-058 winner F5_R0, FROZEN as a development snapshot.
Pipeline: the frozen v1 pipeline (v1 freeze record) with ONE change: T2 (after /4095) is filtered by
  anisotropic diffusion per axial slice before the T2 threshold:
  imdiffusefilt(slice, GradientThreshold = 0.10 x (max - min) of the slice, NumberOfIterations 5,
  Connectivity "maximal" (8-neighbour), ConductionMethod "exponential"); constant slices unchanged;
  output range-checked and clipped to [0,1]. T1 not filtered; no recovery step.
Code: src/preprocessing/anisotropicDiffusionSlices.m, src/segmentation/generateExp058Prediction.m
  (config F5: filterType "anisotropic", filterT1 false, filterT2 true, recovery "R0");
  experiments/exp058_v2_tuning.m (regenerates the predictions).
Development scores: Dice 0.66934046345811 (pn0) / 0.65299830430091 (pn3);
  DevelopmentScore 0.66116938387951. Predicted voxels 3,220 / 2,975.
Artifacts (SHA-256 of the saved files; on regeneration, identity is checked on M_pred with isequal):
  data/processed/phase95_exp058_v2_pn0_selected_prediction.mat
    D0BD81358D9AD8070C923F9DFDF4A505D0E5EFD75AC6AB9EDEC58C5107AC291D
  data/processed/phase95_exp058_v2_pn3_selected_prediction.mat
    31F1E459F42ADA11204B4B342DE3E50125C08420523BF0C5F8C06D8337073BA7
Version control: Git commit "fase 96b" + tag v2-frozen.
Held-out pn1 / pn5 / pn7 / pn9: NOT accessed, NOT downloaded.
```

### Protocol amendment A2 (2026-10-14): one more development experiment (EXP-059) before the test

```text
Amendment A1 stated "no EXP-059". That statement is NOT rewritten; A2 supersedes it, decided by the
user, whose goal is the most effective algorithm possible.
Rules:
  1. v1 and v2 are frozen and never modified.
  2. EXP-059 is the final development experiment BEFORE the held-out test. After EXP-059, the
     selected primary pipeline is mandatorily frozen before any held-out data are accessed.
     No decision based on pn1 / pn5 / pn7 / pn9 may modify that frozen pipeline.
  3. Primary for the final test, fixed on development data only: primary = EXP-059 winner (v3)
     if its DevelopmentScore is strictly higher than v2's (read from the frozen artifact),
     otherwise v2.
  4. Phase 97 evaluates the primary ("primary held-out evaluation") and the other frozen
     versions ("secondary locked-version comparisons", showing the evolution of the method).
     If a secondary version scores higher on the held-out data, this is reported; it does not
     become the final algorithm. Adopting it would require confirmation on new independent data.
  5. Any development after the test (v4) is a separately declared phase. Data used to develop v4
     (e.g. rf20 / rf40, msles1 / msles3) become development data and cannot also serve as the
     independent test of v4; that would require a further untouched set.
Declared cost: pn0 / pn3 have now guided many decisions; every development score (0.661 and the
  EXP-059 result) is in-sample and optimistic by construction. The held-out result is the
  relevant measure.
```

---

### EXP-059 — v3 development experiment under amendment A2: 3D diffusion and morphology on the v2 base

#### Pre-registration (written before EXP-059 was run; reviewed by the user and approved on 2026-10-14)

```text
Status: FINAL development experiment before the held-out test (amendment A2). After EXP-059 the
  selected primary pipeline is mandatorily frozen before any held-out data are accessed.
Frozen base: v2 = F5_R0 from EXP-058.
Data: T1 + T2, pn0 + pn3; held-out not accessed. T1 not filtered; T1 partition, S2 and EXP-021
  unchanged from v2. TA (multithresh N = 2, highest class) re-estimated inside S2 on the filtered T2.
Factor D (anisotropic diffusion of T2 after /4095, explicit frozen parameters; range-checked and
  clipped to [0,1] as in EXP-058):
  D2  per axial slice: GradientThreshold_k = 0.10 x (max - min) of slice k, Connectivity "maximal"
      (8-neighbour), 5 iterations, exponential; constant slices unchanged (= v2)
  D3  whole 181 x 217 x 181 volume: GradientThreshold = 0.10 x (max - min) of the volume,
      Connectivity "maximal" (26-neighbour), 5 iterations, exponential
  D2 and D3 share the same relative rule, not the same numeric threshold: the comparison studies
  the natural 2D -> 3D extension of the filter, not an ablation of connectivity alone.
Factor M (after TA inside S2; one 2D axial opening per slice, then AND S2):
  M0 none | M1 strel('diamond', 1) | M2 strel('square', 3) (= v2)
Factor G: G0 none | G1 remove 26-connected 3D components occupying one axial slice (= v2)
Grid: 2 x 3 x 2 = 12 configurations, 24 predictions, IDs D?_M?_G?; all saved before the GT is loaded.
Base check: D2_M2_G1 must equal the frozen v2 prediction voxel by voxel (pn0, pn3), otherwise
  TECHNICALLY BLOCKED.
Selection: Phase-37 rule (complete-volume Dice, DevelopmentScore, no tolerance). Exact ties:
  weaker-condition Dice, then complexityPenalty relative to v2 (D2 = 0, D3 = 1; M0 = 0, M1 = 1,
  M2 = 1; G0 = 0, G1 = 1), then ID.
Primary (A2): the v2 DevelopmentScore is read from results/metrics/exp058_selected_configuration.csv
  and verified against 0.66116938387951. v3 = winner only if winner != D2_M2_G1 and its
  DevelopmentScore is strictly higher than v2's; otherwise v2 stays primary.
Rationale (development evidence, declared): in EXP-057 the lighter opening (M1) lost on pn3 because
  of noise; EXP-058 showed that filtering T2 was the effective robustness block, so the morphology
  selected on the noisier T2 is re-evaluated. v2 detects few SMALL lesions (2 / 1). Voxels are
  isotropic 1 mm, so 3D diffusion can use adjacent slices.
Declared failure modes (no post-hoc fix):
  - M0 / M1 may let residual noise or thin bright structures through and raise FP again;
  - with 26 neighbours and a gradient threshold relative to the whole-volume range (which can be
    larger than the slice-wise thresholds), the diffusion may be less conservative at edges and
    increase the risk of smoothing small lesions (depends on the numerical implementation);
  - the gain may be small or absent.
Structural limitation (declared, not addressed): lesions entirely outside S2 cannot be recovered by
  any later step (Recall cap 0.887 / 0.871 in EXP-057).
Forbidden: support changes, lesion recovery, search outside S2, other filter parameters or
  families, T1 filtering, held-out data.
Post-selection diagnostics only (do not change the winner or the primary): secondary metrics,
  lesion-wise (Phase-93 rule), SMALL / LARGE, lesions lost / gained vs v2.
```

#### Results (run 2026-10-14; synthetic check PASS 13/13; main script `experiments/exp059_v3_tuning.m` PASS 27/27)

```text
Base check: D2_M2_G1 = frozen v2 voxel by voxel (pn0, pn3); v2 DevelopmentScore read from the
  artifact and verified (deltaVsV2 = 1.1e-16 for the base is CSV rounding, as in EXP-058; harmless).
Ranking (Phase-37 rule):
  1 D3_M1_G0  Dice 0.68538 / 0.69440  DevelopmentScore 0.689891619845975 (+0.028722 vs v2)
  2 D3_M1_G1  0.68595 / 0.69061  0.68828
  3 D2_M1_G1  0.67788 / 0.67618  0.67703
  4 D2_M1_G0  0.67386 / 0.67365  0.67375
  5 D3_M2_G1  0.66657 / 0.65854  0.66255
  6 D3_M2_G0  0.66627 / 0.65637  0.66132
  7 D2_M2_G1  frozen v2  0.66934 / 0.65300  0.66117
  8 D2_M2_G0  0.66326 / 0.64384  0.65355
  9-12 M0 configurations: 0.551 - 0.568 (FP 3,754 - 4,768)
  Pattern: for each D and G, M1 > M2 > M0; for each M and G, D3 > D2 (all 6 pairs).
  Margin of the winner over rank 2: 0.0016 (G0 vs G1).
WINNER: D3_M1_G0. PRIMARY VERSION FOR THE FINAL TEST (amendment A2): v3 = D3_M1_G0.
v2 vs v3 (complete volume):
  pn0: Dice 0.66934 -> 0.68538; Precision 0.69969 -> 0.64584; Recall 0.64151 -> 0.73007;
       TP 2253 -> 2564, FP 967 -> 1406, FN 1259 -> 948; volume error 8.31 % -> 13.04 %
  pn3: Dice 0.65300 -> 0.69440; Precision 0.71193 -> 0.69263; Recall 0.60308 -> 0.69618;
       TP 2118 -> 2445, FP 857 -> 1085, FN 1394 -> 1067; volume error 15.29 % -> 0.51 %
  TA_S2 (normalized): pn0 0.6160 -> 0.6156; pn3 0.5630 -> 0.5654
Lesion-wise (Phase-93 rule):
  pn0: detected 18 -> 33 of 59; false components 0 -> 10 (of 43); SMALL 2 -> 6, LARGE 16 -> 27;
       lost [12], gained 16 lesions
  pn3: detected 16 -> 31; false components 1 -> 7 (of 41); SMALL 1 -> 5, LARGE 15 -> 26;
       lost [17], gained 16 lesions
Synthetic INFO: on the clean phantom diamond 1 keeps fewer voxels than square 3 (25 vs 45) because
  opening a 3x3 square with a cross removes its corners; phantom geometry only.
Figures: exp059_diffusion_2d_vs_3d.png (GT-free), exp059_tuning_ranking.png, exp059_v2_vs_winner.png
```

#### Interpretation

- **The lighter opening is the main gain, as hypothesized.** With T2 already denoised, diamond 1 beats square 3 for every D and G (+0.016 to +0.029). M0 (no opening) loses about 0.1: an opening is still needed.
- **3D diffusion adds a smaller, consistent gain** at M1 (+0.0161 / +0.0113 for G0 / G1); D3 beats D2 in all six M x G pairs. The declared risk of smoothing small lesions did not materialize on the development data.
- **v3 reverses the v2 trade-off.** Lesion detection rises from 18 / 16 to 33 / 31 of 59 GT lesions, SMALL from 2 / 1 to 6 / 5, and voxel Recall reaches about 0.70-0.73. The price is more FP voxels and 10 / 7 false components, with Precision 0.646 / 0.693.
- **pn0 and pn3 are now close** (0.685 / 0.694; pn3 slightly higher).
- **G0 vs G1:** G0 wins directly on DevelopmentScore (0.6898916 vs 0.6882820). No tie-break was involved, because no tolerance was declared. The 0.0016 margin is small and is not interpreted as a meaningful preference for removing the component filter.
- **Scope of the claims:** the grid isolates the effect of each block on the scores (D3 > D2, M1 > M2 in every pair). It does not prove a mechanism, for example that D3 preserves small lesions better. What it shows is that the D3 + M1 pipeline produces more TP and detects more lesions. LARGE lesions detected: 27 / 28 (pn0) and 26 / 28 (pn3). SMALL lesions remain the main source of missed lesions. "Detected" means at least one shared voxel (Phase-93 rule), not complete segmentation.
- **Caveat:** every development score is in-sample and optimistic (many decisions on pn0 / pn3). The 3D gradient threshold is relative to the volume range and was not tuned for the noisier held-out levels.

#### Conclusion

```text
v3 = D3_M1_G0: v1 support pipeline; T2 filtered by whole-volume 3D anisotropic diffusion (explicit
  fixed parameters); TA inside S2; one 2D diamond-1 opening per slice AND S2; no component filter.
PRIMARY for the final test: v3. Secondary locked versions: v2, v1. Fixed before any held-out access.
EXP-059 was the final development experiment before the test. Next: Phase 96, mandatory freeze of
  v3, then held-out download and Phase 97 (primary + secondary locked-version comparisons).
Files: data/processed/phase95_exp059_v3_{pn0,pn3}_selected_prediction.mat;
  results/metrics/exp059_{tuning_grid_results,tuning_ranking,selected_configuration,v2_vs_winner,
  winner_lesion_diagnostics}.csv
```

---

### PHASE 96 — FINAL FREEZE RECORD (2026-10-16; not an experiment, no EXP id)

```text
EXP-059 is the final development experiment; amendment-A2 development closes here.
PRIMARY = v3 = EXP-059 D3_M1_G0, designated on development data only, BEFORE any held-out access.
Secondary locked versions: v1 (EXP-057 S2_TA_M2_G1, tag v1-frozen), v2 (EXP-058 F5_R0, tag v2-frozen).
Frozen definition: src/segmentation/finalSegmentationConfig.m; entry point
  src/segmentation/generateFinalPrediction.m(rawT1, rawT2) (regenerates EXP-021 from each condition's T1).
Full pipeline, parameters and limitations: docs/PHASE96_FINAL_FREEZE.md.
Regression (experiments/phase96_final_pipeline_check.m): PASS 39/39
  final pn0 / pn3 = saved EXP-059 predictions voxel by voxel (3,970 / 3,530 voxels);
  regenerated EXP-021 mask = saved mask; independent step-by-step rebuild = final;
  Dice 0.685378241112002 / 0.694404998579949, DevelopmentScore 0.689891619845975 = EXP-059 artifact.
  First run stopped in the SHA-256 helper (no Java runtime in this MATLAB) -> certutil; second run
  failed one self-matching check label (software only) -> label renamed. No pipeline change.
Manifest: results/metrics/phase96_final_freeze_manifest.csv (tracked copy docs/), 26 SHA-256 entries,
  verified in MATLAB and independently with PowerShell Get-FileHash (26 / 26).
Development values are in-sample and optimistic. Held-out pn1 / pn5 / pn7 / pn9 (same msles2 anatomy,
  lesions and rf0; different noise) test robustness to unseen simulated noise, not independent-patient
  generalization.
Held-out: NOT downloaded, NOT accessed. config.m unchanged. No new experiment id.
Version control: commit "fase 96" + tag v3-final-frozen - pending user approval. No push.
Next: Phase 97 - held-out final test (primary v3; secondary locked comparisons v2, v1).
```

```text
PHASE 96 COMPLETE (2026-10-16): freeze commit 96b16124999a0d40f8df2c66b072fb3a38f10322
  ("fase 96: freeze final v3 pipeline", approved explicitly by the user); annotated tag
  v3-final-frozen -> that commit; post-commit: manifest 26/26 valid, no held-out file in the tree or
  data/raw, primary v3 / D3_M1_G0, working tree clean. No push. Held-out still NOT accessed.
READY FOR PHASE 97 - HELD-OUT FINAL TEST.
```

---

### PHASE 97 — HELD-OUT FINAL TEST (2026-10-16; final evaluation, not an experiment, no EXP id)

```text
Precondition: tag v3-final-frozen -> 96b16124999a0d40f8df2c66b072fb3a38f10322; Phase-96 manifest
  26/26 SHA-256 valid BEFORE any held-out download.
Data: official BrainWeb msles2, 1 mm, rf0, T1 + T2 at pn1 / pn5 / pn7 / pn9 (8 files, 14,218,274 bytes
  each, little-endian 0..4095, 181 x 217 x 181), downloaded 2026-10-16 after the freeze; SHA-256 in
  data/raw/msles2/DOWNLOAD_INFO.txt. No PD, no rf20 / rf40, no other phantom.
Script: experiments/phase97_heldout_test.m, PASS 28/28. Order: freeze check -> 4 v3 predictions with
  generateFinalPrediction(rawT1, rawT2), saved and re-read -> v1 / v2 secondary predictions (their
  generators first reproduced the frozen v1 / v2 pn0 / pn3 predictions exactly) -> GT -> metrics.
  config.m unchanged (held-out paths passed to the validated loader in memory only).
Automatic values (frozen rules, data-dependent; not parameters):
  pn1: brain-mask thr 0.258824; T1 levels 0.337393 / 0.484480; TA levels 0.483144 / 0.603947
  pn5: 0.247059; 0.307549 / 0.439647; 0.418543 / 0.532411
  pn7: 0.247059; 0.311726 / 0.434504; 0.382709 / 0.443473
  pn9: 0.243137; 0.320274 / 0.429859; 0.356035 / 0.414233
PRIMARY HELD-OUT RESULTS - v3 / D3_M1_G0 (complete volume, label 10):
  cond  pred   TP    FP    FN    Dice              IoU      Precision Recall   Specificity VolErr %
  pn1   3887  2561  1326   951  0.692255710231112 0.529351 0.658863  0.729214 0.999813    10.68 (+375)
  pn5   3217  2405   812  1107  0.714816466042503 0.556198 0.747591  0.684795 0.999886     8.40 (-295)
  pn7   9399  2633  6766   879  0.40786925877159  0.256178 0.280136  0.749715 0.999048   167.63 (+5887)
  pn9   8162  2387  5775  1125  0.408942950145623 0.257026 0.292453  0.679670 0.999187   132.40 (+4650)
  meanHeldOutDice 0.555971, min 0.407869 (pn7), max 0.714816 (pn5) - descriptive only.
Lesion-wise (Phase-93 rule; "detected" = at least one shared voxel), v3:
  pn1 detected 32/59, false components 9 of 41;  SMALL 5/31, LARGE 27/28; S2 holds 3117 GT voxels (0.888)
  pn5 24/59, 3 of 32;   SMALL 3/31, LARGE 21/28;  S2 3103 (0.884)
  pn7 41/59, 86 of 127; SMALL 13/31, LARGE 28/28; S2 3018 (0.859)
  pn9 44/59, 102 of 143; SMALL 16/31, LARGE 28/28; S2 2809 (0.800)
SECONDARY LOCKED COMPARISON (Dice; does NOT change the primary):
  cond  v3        v1 (S2_TA_M2_G1)  v2 (F5_R0)
  pn1   0.692256  0.661400          0.670421
  pn5   0.714816  0.412148          0.661817
  pn7   0.407869  0.562216          0.425342
  pn9   0.408943  0.561285          0.455699
  mean  0.555971  0.549262          0.553320
Result manifest: results/metrics/phase97_result_manifest.csv (27 SHA-256 entries: 8 raw held-out
  files, 12 predictions, 3 CSV, 3 figures, the script). Phase-96 manifest unchanged; the 26 frozen
  source hashes matched AFTER the test; raw held-out files unchanged.
```

#### Interpretation (descriptive; no parameter or code change)

- **Stable up to 5 % noise.** At pn1 and pn5 the v3 Dice (0.692, 0.715) is in line with the development values (0.685 / 0.694).
- **Marked degradation at 7 and 9 %, mainly through Precision.** The Dice drops to about 0.41. FP rise from 812 to 6,766 / 5,775 and the predicted volume reaches 2.3–2.7× the GT, while voxel Recall stays at 0.68–0.75.
  - The behaviour is not a gradual decline: pn5 is the best held-out condition. "Performance decreases with noise" would be an inaccurate summary.
  - The automatic T2 thresholds decrease substantially (TA level 2: 0.532 at pn5, 0.443 / 0.414 at pn7 / pn9), and the gap between the two levels narrows (0.114, 0.061, 0.058), while the FP volume increases.
  - This suggests reduced separability of lesion-like intensities within S2. The present test does not isolate the causal contribution of the thresholding stage: D3 under strong noise, the intensity distribution inside S2, the multithresh partition and the noisy-T1-derived S2 may all contribute.
  - The overlays (fixed k = 91) show FP clusters adjacent to the ventricles and in other parenchymal regions.
- **Two distinct problems at high noise:**
  1. the S2 Recall ceiling worsens, because T1 is noisy too (about 20 % of the GT voxels are outside S2 at pn9);
  2. inside what remains of S2, the T2 segmentation over-segments strongly.
- **Lesion counts rise at high noise but are not a gain.** More GT lesions are touched (41 / 44) together with 86 / 102 false components: compatible with noise-driven overlaps (any-overlap rule). Higher lesion detection does not mean better segmentation here, which shows why a permissive lesion-wise metric alone is not enough.
- **S2 ceiling:** S2 coverage of the GT falls with noise (0.888 → 0.800 at pn9).
- **The development advantage almost disappears on held-out noise.**
  - Development DevelopmentScore: v1 0.600, v2 0.661, v3 0.690. Mean held-out Dice: 0.549, 0.553, 0.556.
  - v3 stays first on average and is clearly better at pn1 and pn5. The unfiltered v1 is best at pn7 and pn9, but degrades at pn5 (0.412).
  - Each version degrades at a different noise level. Optimizing on pn0 / pn3 did not produce a uniform improvement across noise levels. This does not make the v1 → v2 → v3 development useless.
- **v3 remains the primary**, fixed before held-out access. The secondary comparison is reported, not used.
- **No pre-registered pass threshold existed,** so v3 is neither "passed" nor "failed". Phase 97 is methodologically complete regardless of the scores.
- **Summary:** the frozen v3 pipeline generalized well to moderate unseen noise levels but showed a clear robustness limit at higher simulated noise levels, where false-positive over-segmentation became the dominant failure mode.
- **Limitations:**
  - same msles2 anatomy and lesions;
  - only the simulated noise changes;
  - four noise configurations, not four subjects;
  - development values are optimistic;
  - S2 limits Recall;
  - "detected" means any overlap.

---

### PHASE 98 — FINAL RAW RESULT ARCHIVE (2026-10-17; archive and verification, not an experiment, no EXP id)

```text
Script: experiments/phase98_results_archive_check.m (read-only), PASS 27/27; console saved by the
  script itself in results/metrics/phase98_verification_console.txt (the pasted output was cut
  before the final line; the PASS line was confirmed from this log).
Verified, without rerunning segmentation or recomputing metrics on the GT:
  - tag v3-final-frozen -> 96b1612; Phase-96 manifest 26/26 hashes valid; primary v3 / D3_M1_G0;
  - Phase-97 result manifest: 27 entries (8 raw MRI + 12 predictions + 3 CSV + 3 figures + 1 script),
    unique paths, all SHA-256 valid and matching;
  - 8 held-out raw MRI: SHA-256 = DOWNLOAD_INFO.txt record, 14,218,274 bytes each;
  - 12 predictions (4 v3, 4 v1, 4 v2): M_pred logical 181x217x181; condition / version / configId
    (D3_M1_G0, S2_TA_M2_G1, F5_R0) / heldOutCondition / gtUsedForGeneration consistent; stored voxel
    count = mask voxels;
  - primary, comparison and lesion-wise CSVs: structure, roles (v3 PRIMARY HELD-OUT, v1 / v2
    SECONDARY LOCKED COMPARISON), algebraic consistency of all stored metrics with the stored
    confusion counts (TP+FN = 3512, total = 7,109,137), table voxels = mask voxels, detected +
    missed = 59, SMALL 31, LARGE 28, lesion overlap voxels = primary TP. CSVs not rewritten.
Inventory (index of existing files, no copies): results/metrics/phase98_final_results_inventory.csv,
  32 rows with SHA-256. Authoritative roles:
    PRIMARY FINAL TEST METRICS        results/metrics/phase97_v3_heldout_metrics.csv
    PRIMARY HELD-OUT PREDICTIONS      data/processed/phase97_v3_{pn1,pn5,pn7,pn9}_prediction.mat
    SECONDARY VERSION COMPARISON      results/metrics/phase97_frozen_versions_comparison.csv
    LESION-WISE DIAGNOSTICS           results/metrics/phase97_v3_lesionwise_diagnostics.csv
    PROVENANCE                        results/metrics/phase97_result_manifest.csv
    FROZEN ALGORITHM PROVENANCE       results/metrics/phase96_final_freeze_manifest.csv + tag v3-final-frozen
No persistent Phase-97 console log exists; Phase 97 was not rerun to create one (the machine-readable
  outputs and manifests are authoritative).
Runtime: not measured; deferred to Phase 102. No timing benchmark here.
No algorithm change, no new prediction, no new experiment, no metric used for a decision.
  Phase 99 not started. No commit, no push.
```

---

### PHASE 99 — RETROSPECTIVE ABLATION STUDY (2026-10-17; synthesis of saved development results, not an experiment, no EXP id)

```text
Script: experiments/phase99_ablation_study.m, PASS 14/14. Reads only saved development CSVs (EXP-026,
  EXP-030 / 033, EXP-042, EXP-056 - 059, Phase 73). No prediction, no MRI, no GT, no segmentation
  call, no held-out data. Phase-96 / 97 / 98 hashes matched before and after.
Method: each configuration is described by 7 blocks (support, threshold, filter, filter dimensionality,
  morphology, component rule, recovery) taken from the saved grid columns or, when an experiment
  fixed a block by design, from its pre-registration. A pair counts as controlled only if the
  descriptors differ exactly in the declared block (filter dimensionality is an attribute of the
  filter). Cross-experiment links verified: EXP-026 = EXP-056 P0_T2_M0_G0; EXP-030 / 033 opening =
  P0_T2_M2_G0; EXP-056 winner = EXP-057 S0_TA_M2_G1; v1 = EXP-058 F0_R0; v2 = EXP-059 D2_M2_G1.
Controlled one-factor comparisons (DevelopmentScore, development pn0 + pn3; 12/12 controlled):
  P01 opening none -> square 3 (EXP-056)       0.041545 -> 0.056845   +0.015300
  P02 G1 introduction, pre-S2 (EXP-056)         0.056845 -> 0.058158   +0.001312
  P03 support S0 -> S1 (EXP-057, TA M2 G1)      0.058158 -> 0.401790   +0.343632
  P04 support S1 -> S2                          0.401790 -> 0.600034   +0.198244
  P05 support S0 -> S2                          0.058158 -> 0.600034   +0.541876
  P06 T2 anisotropic 2D filter (EXP-058, R0)    0.600034 -> 0.661169   +0.061136
  P07 diffusion D2 -> D3 (EXP-059, M2 G1)       0.661169 -> 0.662553   +0.001384
  P08 morphology M0 -> M1 (D3, G0)              0.560347 -> 0.689892   +0.129545
  P09 morphology M2 -> M1 (D3, G0)              0.661320 -> 0.689892   +0.028572
  P10 component rule G1 -> G0 (D3, M1)          0.688278 -> 0.689892   +0.001614
  P11 recovery R0 -> R1 (EXP-058, F5)           0.661169 -> 0.562919   -0.098250
  P12 recovery R0 -> R2 (EXP-058, F5)           0.661169 -> 0.034881   -0.626288
Development trajectory (8 milestones, 7 transitions, all 7 verified as controlled single-block changes):
  EXP-026 0.041545 -> +opening 0.056845 -> +G1 0.058158 -> +S2 (v1) 0.600034 -> +aniso T2 (v2) 0.661169
  -> 2D->3D 0.662553 -> square3->diamond1 0.688278 -> -G1 (v3) 0.689892
Not retained (appendix): multimodal T2 AND PD (EXP-042) 0.056472 vs 0.056845 (-0.000374);
  region growing NOT RETAINED / NOT NUMERICALLY ABLATED (Phase 73: prerequisite not satisfied).
Outputs: results/metrics/phase99_ablation_{summary,pairwise}.csv,
  results/metrics/phase99_development_trajectory.csv, results/figures/phase99_ablation_development_score.png
No held-out result used; no new primary; v3 / D3_M1_G0 unchanged; no commit, no push.
```

#### Interpretation (development evidence only)

- **S2 anatomical support is by far the largest contribution** (+0.5419). It works in two steps: excluding T1-low (S1, +0.344) and restricting to the filled T1-high envelope (+0.198). The FP fall from 66,484 / 63,126 (S0) to 1,167 / 3,123 (S2). S2 is an automatic intensity-derived support, not a white-matter ground truth.
- **T2 anisotropic filtering is the second largest increment in the incremental development trajectory, after S2** (+0.0611). Across all controlled ablations, the diamond-1 opening against no morphology after D3 gives an even larger increment (+0.1295). This confirms that morphology remains essential in the final pipeline.
  - In pn3 it cuts the FP from 3,123 to 857 (Precision 0.439 → 0.712).
  - The trade-off is lower Recall (TP 2,448 → 2,118 in pn3).
- **Morphology remains necessary after D3:** no opening loses 0.1295 (FP 4,768 / 3,928). Diamond 1 beats square 3 by 0.0286: square 3 removes more lesion voxels (TP 2,217 / 2,083 vs 2,564 / 2,445).
- **D2 → D3 is small** (+0.0014 with square 3 and G1).
- **G1 has a small effect in both contexts:** +0.0013 before S2, and −0.0016 when kept after D3 + M1. It was not retained in v3; this does not make it harmful in general.
- **Recovery is clearly unfavourable:** R1 adds TP (+588 / +653) but far more FP (+2,913 / +2,573); R2 leaks through S1 (about 195,000 / 169,000 FP).
- **Contributions are context-dependent, not additive.** The size, and sometimes the sign, of an effect depends on the blocks already present, and each pair measures a block in one context only:
  - D3 vs D2 is +0.0014 with square 3 + G1, but +0.0161 with diamond 1 + G0 (EXP-059 grid);
  - diamond 1 lost to square 3 before filtering (EXP-057: 0.5536 vs 0.6000) and won after D3;
  - G1 helped before S2 and not after D3 + M1.
- **Block status:**
  - not retained in the final v3 (used in intermediate versions, then replaced): G1, the square-3 opening, D2 anisotropic diffusion;
  - explicitly rejected during development: Gaussian filtering, TB thresholding, recovery R1 / R2, T2 AND PD fusion;
  - not introduced: region growing.
- The held-out behaviour is analysed separately in Phase 100.

---

### PHASE 100 — NOISE ROBUSTNESS: SATISFIED BY PHASE-97 ARTIFACTS (2026-10-17; no new processing, no EXP id)

```text
Roadmap row 100 (Macrofasi.docx): "Solo dopo la pipeline stabile, confrontare diversi noise level
  BrainWeb. Le slide mostrano che il rumore puo compromettere Otsu e che lo smoothing puo migliorare
  il thresholding." Output: "Curva performance vs rumore."
Decision (user, 2026-10-17): no new analysis. The required curve and comparisons already exist from
  Phase 97 (held-out) and the frozen development references; rerunning would duplicate them or
  invite a second look at the held-out data. No prediction, no metric recomputation, no GT access.
Existing curve: results/figures/phase97_v3_noise_curves.png (Dice, Precision / Recall, predicted
  volume vs noise; pn0 / pn3 marked DEVELOPMENT, pn1 / pn5 / pn7 / pn9 HELD-OUT).
Consolidated table (values COPIED as text from the authoritative CSVs, not recomputed):
  results/metrics/phase100_noise_robustness_table.csv (6 rows, role column DEVELOPMENT / HELD-OUT)
  noise  cond  role         v3 Dice   Precision Recall  FP    TA level 2  v1 Dice (no filter)  v2 Dice (aniso 2D)
  0 %    pn0   DEVELOPMENT  0.685378  0.645844  0.730068 1406  0.615594    0.661039             0.669340
  1 %    pn1   HELD-OUT     0.692256  0.658863  0.729214 1326  0.603947    0.661400             0.670421
  3 %    pn3   DEVELOPMENT  0.694405  0.692635  0.696185 1085  0.565404    0.539029             0.652998
  5 %    pn5   HELD-OUT     0.714816  0.747591  0.684795  812  0.532411    0.412148             0.661817
  7 %    pn7   HELD-OUT     0.407869  0.280136  0.749715 6766  0.443473    0.562216             0.425342
  9 %    pn9   HELD-OUT     0.408943  0.292453  0.679670 5775  0.414233    0.561285             0.455699
Integrity: Phase-96 manifest 26/26 and Phase-97 manifest 27/27 hashes valid; nothing modified.
```

#### Answers to the roadmap questions (descriptive)

- **Noise and the automatic threshold.** The automatic T2 threshold (TA level 2, multithresh inside S2) decreases monotonically with noise: 0.616, 0.604, 0.565, 0.532, 0.443, 0.414. The v3 Dice is stable up to 5 % and then drops to about 0.41 through false positives (FP about 7–8×). This is consistent with the course observation that noise can compromise Otsu-type thresholding. The causal role of the threshold stage was not isolated.
- **Does smoothing improve the thresholding?** v1 (no filter) vs v2 (anisotropic 2D on T2) is a controlled single-block comparison (Phase 99, P06).
  - **Up to 5 % smoothing helps strongly** (pn3 0.539 → 0.653, pn5 0.412 → 0.662).
  - **At 7–9 % the filtered versions are worse than v1** (pn7 0.562 vs 0.425; pn9 0.561 vs 0.456).
  - Smoothing therefore improves thresholding at low to moderate noise but does not prevent the high-noise breakdown with the frozen parameters.
  - The unfiltered v1 is itself non-monotonic: it is poor at pn5 and better at pn7 / pn9.
- **Caveats:**
  - pn0 / pn3 are development (in-sample, optimistic);
  - one phantom and one lesion configuration;
  - only simulated noise varies;
  - six noise points;
  - the frozen pipeline is unchanged; the primary remains v3.

---

### PHASE 101 — LESION-LOAD ROBUSTNESS: BLOCKED, WAITING FOR BrainWeb CUSTOM SIMULATIONS (2026-10-17)

```text
Design (prompt): frozen v3 on matched CUSTOM simulations of msles1 (mild, 422 mm3), msles2 (moderate,
  3512 mm3) and msles3 (severe, 10104 mm3), identical settings, only lesion load varies; v3 only.
Feasibility verified: msles1 / msles3 MRI exist only as custom simulations (BrainWeb: "only used for
  the BrainWeb custom MRI simulations"); crisp msles1 / msles3 phantoms are directly downloadable.
  The custom form requires an e-mail for notification.
Action (user-authorized): six custom jobs submitted on 2026-10-17 with the user's institutional
  e-mail (address not stored in project files), all queued:
  msles1 T1 / T2, msles2 T1 / T2, msles3 T1 / T2; 1 mm, magnitude, noise 0 % (seed 1),
  INU 0 % (field A), protocol ICBM (T1 SFLASH TR 18 / TE 10 / flip 30; T2 DSE_LATE TR 3300 /
  TE 35, 120). Job numbers and full settings: data/raw/brainweb_custom/phase101/REQUESTS.txt.
  Protocol ICBM chosen because the pre-computed AI / ICBM labelling is unresolved (notes 5.1) and
  ICBM matches the published SBD parameters; custom msles2 vs pre-computed msles2 pn0 will be
  compared descriptively.
Status: TECHNICALLY BLOCKED until the simulations are delivered. Nothing downloaded, no prediction,
  no GT loaded. Pending checks after delivery: file format / 12-bit 0..4095 compatibility with the
  frozen normalization (otherwise BLOCKED - INPUT REPRESENTATION INCOMPATIBLE).
Frozen pipeline untouched; Phase 102 not started.
```

### PHASE 101 — LESION-LOAD ROBUSTNESS: COMPLETE (2026-10-17; post-freeze robustness extension, no EXP id)

```text
Data (BrainWeb CUSTOM simulations, identical settings, only the phantom varies): AI template
  (T1 SFLASH TR 35 / flip 45 / TE 10; T2 SE TR 3000 / TE 80), 1 mm, magnitude, noise 0 % (seed 1),
  INU 0 % (field A). msles1 = "mild" (422 mm3), msles2 = "moderate" (3512), msles3 = "severe" (10104).
  Raw short, little-endian 0..4095 (compatible with the frozen normalization). Crisp GT: msles1 / msles3
  downloaded 2026-10-17, msles2 = existing model. Jobs, hashes: data/raw/brainweb_custom/phase101/
  REQUESTS.txt, results/metrics/phase101_dataset_provenance.csv.
Protocol: six ICBM simulations were obtained first; custom ICBM msles2 vs pre-computed msles2 pn0 gave
  T2 corr 0.939 (different contrast) -> six AI simulations requested; AI msles2 vs pre-computed: T1 corr
  0.990, T2 corr 0.977 (about 0.89 x, not byte-identical). AI = primary; ICBM files kept, NOT used. This
  resolves notes 5.1: the pre-computed SBD matches the AI protocol. (A per-tissue intensity check used the
  known msles2 development GT; msles1 / msles3 GT were not opened before the predictions.)
Script: experiments/phase101_lesion_load_robustness.m, PASS 21/21 (first run: one check failed only
  because the expected manifest size was miscounted, 18 instead of 19; constant corrected, rerun
  identical). Order: integrity -> 3 v3 predictions with generateFinalPrediction, saved and re-read ->
  GT -> metrics. Label 10 verified: voxel counts = official lesion volumes 422 / 3512 / 10104.
Automatic values: brain-mask threshold 0.250980 (all three); T1 levels 0.336043 / 0.479115 (msles1,
  msles2), 0.336043 / 0.477207 (msles3); TA levels msles1 0.432972 / 0.469157, msles2 0.443442 / 0.561638,
  msles3 0.446221 / 0.590646.
PRIMARY RESULTS (v3 / D3_M1_G0, complete volume):
  phantom  load      GT     pred    TP    FP     FN    Dice      Precision Recall   VolErr %  FP/GT   pred/GT
  msles1   mild       422  29301   192  29109   230  0.012919  0.006553  0.454976  6843.4   68.98   69.43
  msles2   moderate  3512   3363  2276   1087  1236  0.662110  0.676777  0.648064     4.24    0.310   0.958
  msles3   severe   10104   9793  7842   1951  2262  0.788260  0.800776  0.776128     3.08    0.193   0.969
  (descriptive only: Dice mean 0.487763, min 0.012919, max 0.788260)
Lesion-wise (26-conn, any overlap) and S2:
  msles1: 13 GT lesions, 7 detected, 678 predicted components (670 false); sizes min 1 / median 8 /
          max 260; GT inside S2 301 / 422 (recall ceiling 0.713)
  msles2: 59 lesions, 22 detected, 31 components (7 false); median 7, max 927; S2 0.884
  msles3: 39 lesions, 23 detected, 33 components (1 false); median 20, max 5003; S2 0.931
  Continuous size statistics only; the Phase-94 7-voxel split was NOT applied across phantoms.
Outputs: results/metrics/phase101_{lesion_load_robustness,lesionwise_diagnostics,dataset_provenance,
  result_manifest}.csv (manifest 19 entries), results/figures/phase101_lesion_load_{metrics,overlays}.png,
  data/processed/phase101_v3_{msles1,msles2,msles3}_prediction.mat.
Integrity: Phase-96 / 97 / 98 / 99 hashes unchanged before and after; inputs unchanged; config.m
  unchanged; primary v3 unchanged; no tuning, no v4; Phase 102 not started.
```

#### Interpretation (descriptive)

- **Moderate and severe loads:** v3 behaves consistently. Custom msles2 gives Dice 0.662, in line with the pre-computed development value 0.685. The severe phantom gives the highest Dice (0.788), with the predicted volume within 3–4 % of the GT.
- **Mild load is a severe failure, through Precision.** v3 predicts 29,301 voxels for 422 lesion voxels (69× the GT; Dice 0.013). The FP are scattered parenchymal clusters (overlay, k = 70).
  - The two automatic T2 levels inside S2 almost coincide (gap 0.036, vs 0.118 for msles2 and 0.144 for msles3).
  - This is compatible with a structural property of the TA rule: the highest of three multithresh classes inside S2 is taken as "lesion", which presupposes a sufficiently large lesion-intensity population. With very few lesion voxels, the highest class falls on normal-appearing tissue.
  - The same would be expected for a lesion-free brain. This is an interpretation; it was not isolated experimentally.
- **Two further effects of lesion load:** the S2 coverage of the GT increases with load (0.713 / 0.884 / 0.931), and the median lesion size increases (8 / 7 / 20).
- **The automatic thresholds behave as expected for a shared anatomy:** brain-mask and T1 thresholds are almost identical across phantoms; only the TA levels change.
- **Limitations:**
  - the three phantoms are simulated lesion loads on the same anatomy, not independent patients;
  - one noise-free condition only;
  - custom data are close to, but not identical with, the pre-computed development domain.
  The primary pipeline remains v3; no change was made in response to these results.

---

### Protocol amendment A3 (2026-10-17): post-test development of v4 (lesion-load defect)

```text
Decision: the user opens a POST-TEST development phase (v4) to address the Phase-101 failure at mild
lesion load (msles1: 29,301 predicted vs 422 GT voxels; the two automatic T2 levels inside S2 nearly
coincide). This is outside the roadmap order and does not rewrite any earlier phase.
Rules:
  1. v3 / D3_M1_G0 (tag v3-final-frozen) remains the OFFICIAL project result; its Phase-97 / 100 / 101
     results stay as reported. v4 is reported as a post-test extension.
  2. Development data for v4 (already seen, so development by definition):
       pre-computed msles2 pn0 and pn3 (rf0, 1 mm);
       Phase-101 custom AI simulations msles1 / msles2 / msles3 (1 mm, noise 0 %, INU 0 %, seed 1).
     The Phase-97 held-out pn1 / pn5 / pn7 / pn9 are also already seen: they are NOT a test for v4
     and are not used for v4 design (amendment A2, rule 5).
  3. RESERVED v4 TEST SET, declared now, generated / downloaded only AFTER the v4 freeze:
       BrainWeb custom simulations, AI template, 1 mm, magnitude, INU 0 % (field A), random seed 2,
       T1 + T2:  (a) phantom "normal" (no lesions), noise 0 %;  (b) "normal", noise 3 %;
                 (c) msles1 (mild), noise 3 %;            (d) msles3 (severe), noise 3 %.
       8 jobs; noise reference tissue "(brightest_tissue)" as in Phase 101. Crisp GT: msles1 / msles3
       existing files; for "normal" the lesion GT is empty (evaluation by FP volume).
  4. Design sequence: (D1) a declared development diagnostic of T2 intensities inside S2 by tissue
     (development GT allowed) -> (EXP-060) ONE pre-registered experiment comparing the frozen TA rule
     with at most two classical alternatives, base case reproducing v3 voxel by voxel; adoption criteria
     fixed in the pre-registration before any EXP-060 result -> v4 freeze (commit + tag) -> test.
  5. No decision may use the reserved test set before the v4 freeze.
Declared cost: development data now include the case that revealed the defect; the v4 effect on it is
  in-sample by construction. Only the reserved test set can show whether the correction generalizes.
```

#### v4 / D1 development diagnostic (2026-10-17; experiments/v4_d1_intensity_diagnostic.m; no prediction)

```text
Filtered T2 (D3) inside S2, by development GT tissue; TA levels = multithresh(T2f(S2), 2):
  condition  TA1     TA2     gap     separability  WM-ref mean / std (S2 & T1-high, GT-free)
  pn0        0.4925  0.6156  0.1231  0.7753        0.4851 / 0.0311
  pn3        0.4476  0.5654  0.1178  0.7760        0.4401 / 0.0292
  msles1     0.4330  0.4692  0.0362  0.8086        0.4347 / 0.0242
  msles2     0.4434  0.5616  0.1182  0.7781        0.4370 / 0.0277
  msles3     0.4462  0.5906  0.1444  0.8384        0.4397 / 0.0334
Fraction of GM inside S2 above TA2: pn0 0.040, pn3 0.024, msles1 0.574, msles2 0.013, msles3 0.004;
  WM above TA2: msles1 0.079 (others <= 0.004). msles1: 91,886 voxels above TA2 before the opening.
GM 95th percentile: 0.610 / 0.546 / 0.531 / 0.532 / 0.531; lesion median 0.805 / 0.728 / 0.599 / 0.705 / 0.737.
Findings: in msles1 TA2 falls inside the GM distribution; the TA gap separates msles1, the multithresh
  separability does not; the T1-high WM reference is stable and GT-free; the T1-mid reference is
  lesion-contaminated (msles3 std 0.114). Outputs: results/metrics/v4_d1_*.csv, results/figures/v4_d1_t2_by_tissue.png.
```

### EXP-060 — v4 development experiment under amendment A3: white-matter-referenced floor for TA

#### Pre-registration (written after D1, before any EXP-060 result; approved by the user on 2026-10-17)

```text
Base: frozen v3 (D3_M1_G0). Development: pn0, pn3 (pre-computed), custom msles1 / msles2 / msles3
  (AI, noise 0). Held-out pn1-pn9 and the reserved v4 test set NOT used.
Rule family (only one, chosen after the declared D1 diagnostic on development data):
  T2 threshold = max(TA level 2, muWM + k * sigmaWM), where muWM / sigmaWM are the mean / standard
  deviation (MATLAB std, N-1) of the D3-filtered T2 inside S2 AND T1-high (class 3 of the frozen T1
  partition) - GT-free, computed per image. Candidate = S2 AND T2f > threshold. Everything else as v3
  (EXP-021, S2, D3 with range check, one 2D diamond-1 opening per slice, AND S2, no G1, no recovery).
  multithresh separability rejected as a guard by D1 (not discriminative).
Grid: k in {none (= v3), 3, 4, 5, 6}: 5 configurations x 5 development conditions; all 25 predictions
  saved before the GT is loaded.
Base check: k = none reproduces the saved v3 predictions voxel by voxel (pn0, pn3: EXP-059 files;
  msles1 / 2 / 3: Phase-101 files), otherwise TECHNICALLY BLOCKED.
Selection / adoption rule:
  objective = mean complete-volume Dice over the 5 development conditions (moderate load appears twice:
    pn0 / pn3 and custom msles2 - declared, kept for simplicity);
  non-inferiority: Dice on each of pn0, pn3, msles2, msles3 must not drop by more than 0.01 vs v3;
  v4 = the admissible k with the highest objective, only if strictly higher than v3's; exact tie ->
  larger k; if no k qualifies, there is no v4 and v3 stays.
Declared expectations / failure modes: k = 3 probably leaves GM above the floor in msles1; large k may
  cut faint lesions (msles1 lesion p05 0.486); msles1 is in-sample, so its improvement is optimistic;
  the lesion-free behaviour can only be measured on the reserved test.
Post-selection diagnostics only: FP volume, lesion-wise (Phase-93 rule), S2 coverage.
After EXP-060: v4 freeze (commit + tag) -> reserved test (8 custom jobs, seed 2).
```

#### EXP-060 results (2026-10-17; experiments/exp060_v4_tuning.m, PASS 8/8)

```text
Base k = none reproduces the saved v3 predictions voxel by voxel on all 5 development conditions;
predictions nested in k. Floors muWM + k sigmaWM (TA2 in brackets):
  pn0 [0.6156] 0.5784 / 0.6095 / 0.6407 / 0.6718     pn3 [0.5654] 0.5276 / 0.5568 / 0.5859 / 0.6151
  msles1 [0.4692] 0.5073 / 0.5315 / 0.5557 / 0.5799  msles2 [0.5616] 0.5200 / 0.5477 / 0.5754 / 0.6030
  msles3 [0.5906] 0.5399 / 0.5733 / 0.6066 / 0.6400
Dice (pn0 / pn3 / msles1 / msles2 / msles3), mean, worst drop on the good cases:
  none (v3)  0.68538 0.69440 0.01292 0.66211 0.78826   mean 0.56861
  k3         0.68538 0.69440 0.04163 0.66211 0.78826   mean 0.57436   drop 0          admissible
  k4         0.68538 0.69440 0.08964 0.66211 0.78826   mean 0.58396   drop 0          admissible
  k5         0.72157 0.71096 0.26628 0.66738 0.78761   mean 0.63076   drop 0.00065    admissible  SELECTED
  k6         0.72183 0.70741 0.24490 0.65542 0.76986   mean 0.61988   drop 0.01840    NOT admissible
RESULT: v4 = v3 with T2 threshold max(TA2, muWM + 5 sigmaWM) (mean development Dice 0.630759 vs 0.568614).
v3 vs v4 (k5): predicted / FP voxels, detected GT lesions, false components, Dice
  pn0     3970 / 1406, 33, 10, 0.685  ->  3215 / 788, 24, 3, 0.722
  pn3     3530 / 1085, 31,  7, 0.694  ->  2975 / 669, 25, 1, 0.711
  msles1 29301 / 29109, 7, 670, 0.013 ->   269 / 177,  4, 8, 0.266
  msles2  3363 / 1087, 22,  7, 0.662  ->  3033 / 849, 21, 2, 0.667
  msles3  9793 / 1951, 23,  1, 0.788  ->  9195 / 1595, 21, 0, 0.788
```

#### Interpretation

- **With k = 5 the floor exceeds TA level 2 in all five development conditions.** v4 therefore behaves, on development data, as a white-matter-referenced outlier threshold (μWM + 5σWM). The TA level only acts as a lower bound. This was visible in D1 and is stated plainly.
- **msles1:** the massive over-segmentation disappears (29,301 → 269 predicted voxels; GT 422). The Dice remains modest (0.266), with 4 of 13 lesions detected.
- **pn0 / pn3 / msles2 improve and msles3 is unchanged** (−0.0007). The cost: fewer lesions are touched (pn0 33 → 24, pn3 31 → 25) while false components fall. The higher Dice comes with fewer small detections (any-overlap rule).
- **k = 6 was rejected** by the pre-registered non-inferiority (msles3 −0.018).
- **Caveats:**
  - all values are in-sample (msles1 revealed the defect and is part of development);
  - k was chosen on the same data;
  - the behaviour on a lesion-free brain and under unseen noise is unknown until the reserved test.

Next: v4 freeze (commit + tag, user approval), then the reserved test (8 custom jobs, seed 2).

#### v4 freeze record (2026-10-17, before any reserved-test data exist)

```text
v4 = generateV4Prediction(rawT1, rawT2, 5): the frozen v3 pipeline (EXP-021, S2 from unfiltered T1,
  whole-volume D3 diffusion of T2, one 2D diamond-1 opening AND S2, no G1 / recovery) with the T2
  threshold max(TA level 2, muWM + 5 sigmaWM); muWM / sigmaWM = mean / std (N-1) of the D3-filtered
  T2 inside S2 AND T1-high (class 3), computed per image, GT-free. k = 5 is the only parameter added.
Selection: EXP-060 (amendment A3), development pn0, pn3, custom msles1 / msles2 / msles3; mean
  development Dice 0.630759 (v3 0.568614). In-sample values.
Hashes: docs/v4_freeze_manifest.csv (14 entries: generateV4Prediction.m, the shared frozen helpers
  - identical to the Phase-96 hashes -, config.m, the EXP-060 and D1 scripts, the EXP-060 CSVs).
Version control: commit "fase v4: freeze v4 (EXP-060, k = 5)" + tag v4-frozen (user-approved);
  no push. v3 / v3-final-frozen unchanged and still the official project result.
Reserved test (amendment A3) not yet generated at the time of this freeze.
```
