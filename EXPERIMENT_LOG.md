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
Candidate voxels                         223,202                257,444
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
EXP-024 Otsu        223,202 / 3,505 / 0.030920     257,444 / 3,494 / 0.026778     0.028849  rank 1
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
