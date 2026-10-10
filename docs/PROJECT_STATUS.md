# Project status (hand-over)

Short entry point for a new working session. The authoritative records remain `PROJECT_SPEC.md`, `ALLOWED_TECHNIQUES.md`, `EXPERIMENT_LOG.md` and `docs/BRAINWEB_DATASET_NOTES.md`. This file only says where things stand and where to look.

Last updated: 2026-10-10, after **Phase 57**.

## Where we are

- **Roadmap:** `Macrofasi.docx` (Italian), numbered phases. Phases 1–57 are done. **Next: Phase 58, multi-threshold evaluation (not started).**
- **Phases completed after a deferral:** Phase 40 (brain-only histograms) was resumed after Phase 52. No roadmap phase is currently deferred.

## Current development pipeline

```text
Brain support (T1):  T1 -> double -> /4095 -> global Otsu (EXP-010)
                     -> 3D erode sphere(3) -> largest 26-connected component -> 3D dilate AND raw
                     -> 2D hole filling                                         = EXP-021 brainMask
Lesion candidates (T2): T2 -> double -> /4095 -> no filter
                     -> lesionCandidateMask = brainMask AND (T2_norm > T)        (Phase 53, strict >)
                     -> T = graythresh(T2_norm(brainMask)) per volume            (Otsu, selected in Phase 57)
```

- **Brain mask:** EXP-021 is **frozen** (radius 3), visually validated in Phase 51 (PASS WITH DOCUMENTED LIMITATIONS) and applied in Phase 52.
  - It uses 3D processing: a volumetric extension of course operations that is **not in the course PDF**, authorized by the user as a documented exception (ALLOWED_TECHNIQUES §10).
  - It is a brain-**tissue** mask: the ventricles are included (filled), surface-open CSF is excluded, the spinal cord is included, and a little vertex cortex is lost.
- **Initial thresholding method:** Otsu (EXP-024), selected in Phase 57 (EXP-025) by DevelopmentScore 0.028849, against manual 0.027325 and iterative 0.018026.
  - All Dice values are below 0.04. The candidates contain almost all GT lesion voxels but are dominated by bright non-lesion structures compatible with CSF (ventricles, cisterns, sulci). The lesions are mostly periventricular.
  - This is a **development baseline, not the final pipeline**.
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

Reusable functions: `src/preprocessing/applyBrainMask.m`, `src/segmentation/thresholdLesionCandidates.m`, `src/segmentation/estimateIterativeThreshold.m`, `src/segmentation/brainMask3DErodeSelectDilate.m`, `src/visualization/overlayMaskBoundaryOnMRI.m`.

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
- **Coverage observation (Phase 57):** the `pn0` EXP-021 mask contains all 3,512 GT lesion voxels. This was observed after the freeze and not used for any change; the `pn3` coverage was not established.

## Where to read details

| Topic | Location |
|---|---|
| Protocol, tuning rule, open decisions | `PROJECT_SPEC.md` §19.1, §19.2, §27 |
| Brain-mask architecture; baseline definition and threshold history | `PROJECT_SPEC.md` §9; §10.1 |
| Brain-mask strategy and all EXP-005…021 experiments | `docs/BRAINWEB_DATASET_NOTES.md` §13.26–13.28 |
| Phase 51 validation, Phase 52 application | notes §13.29, §13.30 |
| Phase 40 histograms, Phase 53 baseline | notes §13.31, §13.32 |
| EXP-022 / 023 / 024 / 025 (Phases 54–57) | notes §13.33–13.36; `EXPERIMENT_LOG.md` (summary table §6, status §11) |
