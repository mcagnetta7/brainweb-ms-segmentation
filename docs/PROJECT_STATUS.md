# Project status (hand-over)

Short entry point for a new working session. The authoritative records remain `PROJECT_SPEC.md`, `ALLOWED_TECHNIQUES.md`, `EXPERIMENT_LOG.md` and `docs/BRAINWEB_DATASET_NOTES.md`. This file only says where things stand and where to look.

Last updated: 2026-10-12, after **Phase 81**.

## Where we are

- **Roadmap:** `Macrofasi.docx` (Italian), numbered phases.
  - Phases 1–73 and 78–81 are done.
  - **Phases 74–77 are skipped by the Phase-73 decision.**
  - **Multimodal stage (78–81): COMPLETE.**
  - **Next: Phase 82, formal voxel-wise confusion matrix, not started.**
- **Multimodal status (Phases 79–81):**

  | Item | Status |
  |---|---|
  | Selected pair | T2 + PD |
  | Fusion rule | T2 AND PD (EXP-041, pre-registered) |
  | Fused prediction | `data/processed/exp041_t2_pd_{pn0,pn3}_intersection_candidate.mat`, kept as negative evidence |
  | Phase 81 (EXP-042): baseline T2 DevelopmentScore | 0.056845 |
  | Phase 81 (EXP-042): candidate T2 AND PD DevelopmentScore | 0.056472 (Δ −0.000374) |
  | **Decision** | **REJECT_MULTIMODAL_FUSION** |
  | Retained development pipeline | **T2 only** |
  | Canonical prediction | the Phase-71 T2 `M_pred` |
  | Pipeline modified | NO |

  - In `pn3` the fusion removed 5,149 FP but also 177 TP: not selective enough to raise Dice.
  - Notes §13.56.

  - **Structural effect:** T2 retained 99.96 % (`pn0`, only 29 voxels removed) and 92.06 % (`pn3`). The large bright / fluid-like candidate structures are largely shared by T2 and PD and are therefore not removed (visual observation).
  - PD was chosen as a potentially complementary source, not as a good standalone segmenter.
  - T1 was not selected for the first pair, but it is not discarded.
  - Notes §13.54–13.55.
- **Phases completed after a deferral:** Phase 40 (brain-only histograms) was resumed after Phase 52. No roadmap phase is currently deferred.

## Current development pipeline

```text
Brain support (T1):  T1 -> double -> /4095 -> global Otsu (EXP-010)
                     -> 3D erode sphere(3) -> largest 26-connected component -> 3D dilate AND raw
                     -> 2D hole filling                                         = EXP-021 brainMask
Lesion candidates (T2): T2 -> double -> /4095 -> no filter
                     -> levels = multithresh(T2_norm(brainMask), 2) per volume  (selected in Phase 58)
                     -> class = imquantize(T2_norm, levels)
                     -> candidateMask = brainMask AND (class == 3)                (= T2_norm > levels(2))
                     generator: src/segmentation/generateLesionCandidateMask.m (Phase 60)
```

- **Brain mask:** EXP-021 is **frozen** (radius 3), visually validated in Phase 51 (PASS WITH DOCUMENTED LIMITATIONS) and applied in Phase 52.
  - It uses 3D processing: a volumetric extension of course operations that is **not in the course PDF**, authorized by the user as a documented exception (ALLOWED_TECHNIQUES §10).
  - It is a brain-**tissue** mask: the ventricles are included (filled), surface-open CSF is excluded, the spinal cord is included, and a little vertex cortex is lost.
- **Current thresholding method:** multi-level Otsu (EXP-026, Phase 58): `multithresh` with 2 thresholds, candidate = highest of 3 classes. DevelopmentScore 0.041545 (Dice 0.0404 `pn0` / 0.0427 `pn3`), against 0.028849 for binary Otsu (EXP-024, selected in Phase 57 over manual 0.027325 and iterative 0.018026).
  - Class 3 is 34–48 % smaller than the Otsu candidates but keeps only 86 % / 84 % of the GT voxels (the rest fall in Class 2). It is still about 40 times the GT volume, dominated by bright structures compatible with CSF (ventricles, cisterns, sulci). The lesions are mostly periventricular.
  - Phase 59 (EXP-027): local threshold T = m + b·s (2D, masked statistics), best grid configuration W21_B15 = 0.036103 → **REJECTED**; EXP-026 stays current. It suppresses uniform CSF but loses periventricular lesions.
  - This is a **development baseline, not the final pipeline**.
- **Candidate-mask errors (Phase 61, EXP-028, diagnostic):** the mask is unchanged. FP are about 25 % fully surrounded (fluid-like regions compatible with the ventricles and cisterns), about 40 % thin/edge-like and 5–7 % isolated. FN lie mostly on lesion borders, with no enclosed holes. Periventricular lesions are fused with the ventricle-compatible region. Erosion/opening and dilation are worth testing; simple morphology alone is unlikely to fix the dominant error.
- **Morphology status (Phase 62, EXP-029):** the primitive effects have been evaluated with square 3×3, 2D, as a probe. Erosion (0.035040) and dilation (0.020238) both worsen the baseline (0.041545). Erosion is not FP-selective (lesions are thin), and dilation adds about 400–520 FP per recovered FN. No morphology or structuring element is selected; the source candidate is still EXP-026 / Phase 60. The helper is `src/segmentation/applySliceMorphology2D.m`.
  - Phase 63 (EXP-030): standard opening (square 3×3, 2D) **improves** the baseline to 0.056845 (+0.0153). It removes thin and isolated FP but loses small lesions (FN 477 → 1,405 / 560 → 1,499), and the fluid-like regions are rebuilt. It is a promising candidate for Phases 65–66 but is not selected; the canonical candidate mask is still Phase 60 / EXP-026.
  - Phase 64 (EXP-031): closing after the opening (square 3×3, brain mask only after the complete closing) gives 0.056181 (−0.000665 vs opening). It adds about 1,200 voxels per condition, 99 % FP, and does not recover the small lesions removed by the opening.
  - **Phase 65 (EXP-032): current selected development morphology = standard opening with `strel('square', 3)`** (DevelopmentScore 0.056845). It beats diamond1 (0.053937), diamond2 (0.051808) and square5 (0.037654) in both conditions. The selected masks are `data/processed/phase65_t2_{pn0,pn3}_selected_opening_candidate.mat` (identical to EXP-030). This is not a frozen project parameter; `config.m` is unchanged.
  - **Phase 66 (EXP-033): morphology RETAINED FOR SUBSEQUENT DEVELOPMENT.** The development-set before/after comparison gives 0.041545 → 0.056845, better in both conditions. Remaining limitations: the dense fluid-like FP (about 20 times the GT) and the lost small/thin lesions (FN +928 / +939).
  - **Current development pipeline:** EXP-026 candidates → standard 2D opening `strel('square', 3)` (Phase-65 masks).
- **Objects (Phase 67, EXP-034):** 2D connected components with 8-connectivity, slice by slice, on the Phase-65 masks (`src/segmentation/extractConnectedComponents2D.m`). Outputs: `data/processed/phase67_t2_{pn0,pn3}_components2d.mat`, with 1,210 / 1,068 slice-wise instances; these are not unique lesions. No filtering, no properties, no GT.
- **Component properties (Phase 68, EXP-035):** `regionprops` Area, Centroid and BoundingBox on the saved Phase-67 components (`src/segmentation/extractComponentProperties2D.m`). Outputs: `data/processed/phase68_t2_{pn0,pn3}_component_properties.mat` and `results/metrics/exp035_component_properties.csv`. Area is 9–1,332 pixels with median 18. No GT, no filtering.
- **Component filter (Phase 69, EXP-036):** removal of whole 2D components with Area == 9 was provisionally retained, but it was **REJECTED in Phase 70 (EXP-037)** for small-lesion protection failure: 3 (`pn0`) / 4 (`pn3`) GT 2D lesion cross-sections lost all predicted support. **The current retained pipeline is the Phase-65 standard opening square3 with NO component filtering.** DevelopmentScore 0.056845 → 0.058101. It also removes 36 / 42 GT lesion voxels contained in 9-pixel 2D components; whether these are whole small lesions or fragments is not yet determined. Outputs: `data/processed/exp036_t2_{pn0,pn3}_area9_filtered_candidate.mat` (`src/segmentation/filterComponentsByArea2D.m`). Not frozen; `config.m` is unchanged.
- **Predicted volume (Phase 71, EXP-038):** `M_pred` is a logical 181×217×181 volume in `data/processed/phase71_t2_{pn0,pn3}_predicted_volume.mat`, exactly equal to the Phase-65 retained masks (70,878 / 67,066 voxels). It is the canonical complete-volume representation. No component filtering, since EXP-036 was rejected in Phase 70. 3D connected components are not yet performed.
- **3D candidate components (Phase 72, EXP-039):** `bwconncomp(M_pred, 26)` gives 335 (`pn0`) / 291 (`pn3`) candidate components, outputs `data/processed/phase72_t2_{pn0,pn3}_components3d.mat`.
  - About half occupy a single slice; very large multi-slice components are present (largest 25,629 / 25,417 voxels).
  - `M_pred` is not modified, no GT, no filtering. Unique confirmed lesions are not established.
  - This is a project-specific 3D extension of the course concept (ALLOWED_TECHNIQUES §10 note).
- **Region growing (Phase 73):** **NOT ACTIVATED** (decision NO). The current candidate mask is not a sufficiently specific high-confidence lesion-core representation (FP > TP; 3D candidate objects larger than the total GT lesion volume). Phases 74–77 are skipped by the Phase-73 decision. The pipeline and the Phase-71 `M_pred` are unchanged.
- **Lesion modality:** T2; `cfg.dataset.modality = "T2"`. It was provisional in Phase 41 and was **confirmed on `pn0` + `pn3` in Phase 78 (EXP-040)**.
  - Each modality was tested alone with the same architecture (multithresh N = 2, Class 1/2/3, square3 opening).
  - T2 Class 3: 0.056845 (= `M_pred`). PD Class 3: 0.016424. T1 Class 3: 0.004280.
  - No fusion. T1 is used only for the brain mask.
  - PD `pn3` was downloaded in Phase 78 (see `DOWNLOAD_INFO.txt`). `config.m` gained only its data path.
- **Preprocessing:** NONE (Phase 47). Gaussian σ 0.5 is kept as a candidate for a later "baseline + preprocessing" check.

## Frozen artefacts (in `data/processed/`, excluded from Git; regenerate with the listed script)

| Artefact | File(s) | Script |
|---|---|---|
| EXP-021 brain mask | `exp021_t1_{pn0,pn3}_3d_erode_select_dilate_candidate.mat` (`candidate`) | `experiments/brain_mask_t1_3d_erode_select_dilate.m` |
| Brain-masked T2 (Phase 52) | `phase52_t2_{pn0,pn3}_brain_masked.mat` | `experiments/phase52_apply_exp021_brain_mask_to_t2.m` |
| EXP-022 manual threshold (3400) | `exp022_t2_{pn0,pn3}_manual_global_threshold_candidate.mat` | `experiments/exp022_manual_global_threshold_t2.m` |
| EXP-023 iterative threshold | `exp023_t2_{pn0,pn3}_iterative_threshold_candidate.mat` | `experiments/exp023_iterative_threshold_t2.m` |
| EXP-024 Otsu threshold | `exp024_t2_{pn0,pn3}_otsu_threshold_candidate.mat` | `experiments/exp024_otsu_threshold_t2.m` |
| EXP-027 local threshold (rejected, 9 configs) | `exp027_t2_{pn0,pn3}_local_W??_B??_candidate.mat` | `experiments/exp027_local_threshold_t2.m` |
| **Phase-60 canonical candidateMask (current)** | `phase60_t2_{pn0,pn3}_candidate_mask.mat` (`candidateMask`, identical to EXP-026) | `experiments/phase60_generate_candidate_mask.m` |
| EXP-026 multithresh (selected method) | `exp026_t2_{pn0,pn3}_multithresh_candidate.mat` (`lesionCandidateMask`, `classVolumeInBrain`) | `experiments/exp026_multithresh_t2.m` |

Reusable functions: `src/segmentation/generateLesionCandidateMask.m` (current candidate generator), `src/preprocessing/applyBrainMask.m`, `src/segmentation/thresholdLesionCandidates.m`, `src/segmentation/localMeanStdThreshold2D.m`, `src/segmentation/estimateIterativeThreshold.m`, `src/segmentation/brainMask3DErodeSelectDilate.m`, `src/visualization/overlayMaskBoundaryOnMRI.m`.

## Rules that must not be broken

- **Data:**
  - Development data is `msles2`, 1 mm, `rf0`, **`pn0` + `pn3`** only.
  - The held-out `pn1`/`pn5`/`pn7`/`pn9` must not be downloaded or accessed before the Phase-96 freeze.
  - `data/raw/` is immutable.
- **GT (label 10):**
  - It is used **only for evaluation**, never to generate, tune or select anything inside a method.
  - Anatomical labels are excluded even from brain-mask validation (Phase 48).
  - In the evaluation the GT is **not** intersected with `brainMask`.
- **Selection (Phase 37):** DevelopmentScore = (Dice_pn0 + Dice_pn3)/2, computed on the full 3D volume. The tie tolerance (if any) and every threshold, radius or rule are **declared before** seeing the results. There is no parameter sweep and no retuning afterwards.
- **Brain-only statistics** use `T2(brainMask)`, never the zero-padded `maskedT2(:)`.
- **Techniques:** check `ALLOWED_TECHNIQUES.md` before introducing any technique; if a technique is unlisted, stop and ask.
- **Wording:** without GT, candidates are described neutrally ("hyperintense structures compatible with CSF spaces"), never as lesions or false positives.
- **Workflow:** the user runs MATLAB and pastes the output; the assistant writes the scripts, inspects the figures and CSVs, documents, then stops. Commits happen only on request. Replies are in Italian; documentation is in English.

## Open points and reminders

- **Open question 17:** `pn3 ≈ 0.869·pn0 + 0.024` (whole-volume intensity mismatch). Unresolved; no harmonization so far.
- **After the segmentation baseline:** run "baseline + Gaussian σ 0.5" under the Phase-37 rule (decided in Phase 47).
- ~~Re-check the T2 modality choice under noise~~: done in Phase 78 (EXP-040, T2 best on `pn0` + `pn3`).
- **Coverage observation (Phases 57–58):** the EXP-021 masks of both `pn0` and `pn3` contain all 3,512 GT lesion voxels. This was observed after the freeze and not used for any change.

## Where to read details

| Topic | Location |
|---|---|
| Protocol, tuning rule, open decisions | `PROJECT_SPEC.md` §19.1, §19.2, §27 |
| Brain-mask architecture; baseline definition and threshold history | `PROJECT_SPEC.md` §9; §10.1 |
| Brain-mask strategy and all EXP-005…021 experiments | `docs/BRAINWEB_DATASET_NOTES.md` §13.26–13.28 |
| Phase 51 validation, Phase 52 application | notes §13.29, §13.30 |
| Phase 40 histograms, Phase 53 baseline | notes §13.31, §13.32 |
| Phase 60 canonical candidate mask | notes §13.39 |
| Phase 61 error analysis (EXP-028) and morphology motivation | notes §13.40 |
| Phase 62 erosion / dilation probe (EXP-029) | notes §13.41 |
| Phase 63 opening probe (EXP-030) | notes §13.42 |
| Phase 64 closing after opening (EXP-031) | notes §13.43 |
| Phase 65 structuring-element selection (EXP-032) | notes §13.44 |
| Phase 66 before/after morphology comparison (EXP-033) | notes §13.45 |
| Phase 67 2D connected components (EXP-034) | notes §13.46 |
| Phase 68 component properties (EXP-035) | notes §13.47 |
| Phase 69 conservative Area-9 filter (EXP-036) | notes §13.48 |
| Phase 70 small-lesion protection audit (EXP-037) | notes §13.49 |
| Phase 71 complete predicted volume M_pred (EXP-038) | notes §13.50 |
| Phase 72 3D connected components (EXP-039) | notes §13.51 |
| Phase 73 region-growing decision (no EXP id) | notes §13.52 |
| Phase 78 individual-modality benchmark (EXP-040), PD pn3 download | notes §13.53 |
| Phase 79 multimodal combination selection (no EXP id) | notes §13.54 |
| Phase 80 T2 AND PD fusion rule (EXP-041) | notes §13.55 |
| Phase 81 mono vs multimodal comparison (EXP-042) | notes §13.56 |
| EXP-022 … 027 (Phases 54–59) | notes §13.33–13.38; `EXPERIMENT_LOG.md` (summary table §6, status §11) |
