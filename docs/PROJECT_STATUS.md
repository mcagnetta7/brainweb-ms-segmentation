# Project status (hand-over)

Short entry point for a new working session. The authoritative records remain `PROJECT_SPEC.md`, `ALLOWED_TECHNIQUES.md`, `EXPERIMENT_LOG.md` and `docs/BRAINWEB_DATASET_NOTES.md`. This file only says where things stand and where to look.

Last updated: 2026-10-10, after **Phase 65**.

## Where we are

- **Roadmap:** `Macrofasi.docx` (Italian), numbered phases. Phases 1–65 are done. **Next: Phase 66, formal before/after morphology comparison (not started).**
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
- **Lesion modality:** T2 (provisional, Phase 41); `cfg.dataset.modality = "T2"`. T1 is used only for the brain mask.
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
- **Re-check the T2 modality choice under noise** (Phase 41 used `pn0` only).
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
| EXP-022 … 027 (Phases 54–59) | notes §13.33–13.38; `EXPERIMENT_LOG.md` (summary table §6, status §11) |
