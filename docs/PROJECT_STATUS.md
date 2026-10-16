# Project status (hand-over)

Short entry point for a new working session. The authoritative records remain `PROJECT_SPEC.md`, `ALLOWED_TECHNIQUES.md`, `EXPERIMENT_LOG.md` and `docs/BRAINWEB_DATASET_NOTES.md`. This file only says where things stand and where to look.

Last updated: 2026-10-14, after **Phase 95 including EXP-057**.

## Where we are

- **Roadmap:** `Macrofasi.docx` (Italian), numbered phases.
  - Phases 1–73 and 78–95 are done.
  - **Phases 74–77 are skipped by the Phase-73 decision.**
  - **Multimodal stage (78–81): COMPLETE.**
  - **Confusion-matrix-based voxel-wise metrics (82–87): COMPLETE.**
  - **Volumetric evaluation (88–90): COMPLETE.**
  - **v1 = S2_TA_M2_G1 FROZEN (2026-10-14, Git tag `v1-frozen`).** Freeze record in `EXPERIMENT_LOG.md` after EXP-057.
  - **Protocol amendment A1 (2026-10-14):** development is reopened for exactly one experiment, EXP-058 (v2: noise filter F × reconstruction R). Primary for the test = v2 only if its DevelopmentScore is strictly higher than v1's, otherwise v1. The primary is fixed before any held-out access, and both versions are tested in Phase 97. No EXP-059.
  - **EXP-058 (v2), complete — PRIMARY VERSION FOR THE FINAL TEST: v2 = `F5_R0`; secondary: v1.**
    - v2 = the v1 pipeline with T2 filtered by anisotropic diffusion (`src/preprocessing/anisotropicDiffusionSlices.m`, `imdiffusefilt` per slice, 5 iterations, exponential, 8-neighbour, gradient threshold 0.10 × slice range). Generator: `src/segmentation/generateExp058Prediction.m` with config F5 (`filterType` "anisotropic", T2 only, `recovery` "R0").
    - Dice 0.669340 / 0.653000; DevelopmentScore **0.661169** (v1 0.600034). pn3 FP 3,123 → 857; Precision 0.700 / 0.712, Recall 0.642 / 0.603.
    - Trade-off: pn3 detects 16 of 59 GT lesions (v1 28), SMALL 1 (v1 6).
    - The morphological reconstruction (R1/R2) is rejected by the grid.
    - Files: `data/processed/phase95_exp058_v2_{pn0,pn3}_selected_prediction.mat`. Notes §13.72.
  - **v2 FROZEN (2026-10-14, tag `v2-frozen`).**
  - **Amendment A2 (2026-10-14):** EXP-059 (v3: D2/D3 anisotropic × opening M0/M1/M2 × G0/G1 on the v2 base) is the final development experiment before the test.
    - Primary = v3 only if strictly better than v2 on the DevelopmentScore, otherwise v2; it is fixed before any held-out access.
    - Phase 97 evaluates the primary plus the frozen secondary versions.
  - **EXP-059 (v3), complete — PRIMARY VERSION FOR THE FINAL TEST: v3 = `D3_M1_G0`; secondary locked versions: v2, v1.**
    - v3 = the v2 base with:
      - T2 filtered by whole-volume 3D anisotropic diffusion (`src/preprocessing/anisotropicDiffusionVolume3D.m`: 26-neighbour, 5 iterations, exponential, gradient threshold 0.10 × volume range);
      - TA inside S2;
      - one 2D `diamond 1` opening per slice AND S2;
      - no component filter.
    - Generator: `src/segmentation/generateExp059Prediction.m`.
    - Dice 0.68538 / 0.69440; DevelopmentScore **0.689892**. Precision 0.646 / 0.693, Recall 0.730 / 0.696. GT lesions detected 33 / 31 of 59 (SMALL 6 / 5).
    - Files: `data/processed/phase95_exp059_v3_{pn0,pn3}_selected_prediction.mat`. Notes §13.73.
  - **Phase 95: COMPLETE** (final development experiment EXP-059).
- **Phase 96 — final freeze: READY TO FREEZE, WAITING FOR USER GIT APPROVAL** (2026-10-16).
  - **Final primary:** v3 = `D3_M1_G0`, selected before held-out access.
  - **Definition and entry point:** frozen definition in `src/segmentation/finalSegmentationConfig.m`; entry point `src/segmentation/generateFinalPrediction.m(rawT1, rawT2)`, which regenerates the EXP-021 mask from each condition's T1.
  - **Regression:** `experiments/phase96_final_pipeline_check.m` PASS 39/39 (voxel-by-voxel reproduction of EXP-059 on pn0/pn3).
  - **Development reference (in-sample, optimistic):** Dice 0.685378241112002 / 0.694404998579949; DevelopmentScore 0.689891619845975.
  - **Manifest:** SHA-256 of 26 artifacts in `results/metrics/phase96_final_freeze_manifest.csv` (tracked copy in `docs/`). Record: `docs/PHASE96_FINAL_FREEZE.md`.
  - **Held-out:** NOT downloaded, NOT accessed. `config.m` unchanged.
  - **Pending:** local commit `fase 96` + tag `v3-final-frozen` (no push), after user approval.
- **Next: Phase 97 — held-out final test** (download pn1/5/7/9; primary v3, secondary locked comparisons v2, v1).
- **Phase 95 supplementary experiment (EXP-057), complete — CURRENT SELECTED DEVELOPMENT CONFIGURATION:**
  - **Search:** 36 configurations / 72 predictions on `pn0`/`pn3` (T1-derived support S0/S1/S2 × T2 threshold TA/TB inside the support × opening M0/M1/M2 × G0/G1), all generated before the GT. The baseline S0_TA_M2_G1 reproduces the EXP-056 winner voxel by voxel.
  - **Selected: `S2_TA_M2_G1`.**
    - Support S2 = EXP-021 AND per-slice `imfill(T1-high, 'holes')` AND NOT T1-low, from `multithresh(T1(EXP-021), 2)` (`src/segmentation/computeT1AnatomicalSupport.m`).
    - Threshold: `multithresh(T2(S2), 2)`, highest class; one 2D `square 3` opening; single-slice 3D component removal (`src/segmentation/generateExp057Prediction.m`).
  - **Scores:** Dice 0.661039 / 0.539029; DevelopmentScore **0.600034** (EXP-056 winner 0.058158). Precision 0.664 / 0.439, Recall 0.658 / 0.697; FP 1,167 / 3,123; GT lesions detected 19 / 28 of 59.
  - **Limits:** S2 holds 3,114 / 3,058 of the 3,512 GT voxels (Recall cap); `pn3` has 2.7× the FP of `pn0` (noise risk for held-out); BrainWeb's idealized intensities favor the T1 partition.
  - Files: `data/processed/phase95_exp057_t2_{pn0,pn3}_selected_prediction.mat`. **Not yet frozen (Phase 96).** Notes §13.71.
- **Phase 95 tuning (EXP-056), complete (superseded by EXP-057):**
  - **Search:** 24 configurations / 48 predictions on `pn0`/`pn3`, all generated before the GT. The baseline `P0_T2_M2_G0` reproduces Phase 71.
  - **Selected development configuration: `P0_T2_M2_G1`.**
    - Preprocessing: none.
    - Threshold rule: `multithresh` N = 2, Class 3.
    - Morphology: one 2D axial `square 3` opening.
    - Geometric rule: remove 26-connected 3D components occupying one axial slice.
  - **Scores:** Dice `pn0` 0.058067, `pn3` 0.058248; DevelopmentScore 0.058158, i.e. **+0.00131** vs the Phase-71 baseline.
  - **Effect:** FP −2,287 / −1,927, TP −14 / −14; components 335→165 / 291→143. GT lesion 16 is lost (only single-slice support). The FP burden is only marginally reduced.
  - **Status:** held-out not accessed. **Final parameter freeze: NOT YET — Phase 96.** Notes §13.70.
- **Small vs large GT lesions (Phase 94, EXP-055), DIAGNOSTIC:**
  - **Split:** median GT size = 7 voxels (7 mm³), computed from the GT only and before the outcomes. SMALL ≤ 7 (31 lesions), LARGE > 7 (28); dataset-relative, not clinical.
  - **SMALL:** detected 3 / 31 (`pn0`) and 2 / 31 (`pn3`), GT voxel coverage about 0.05.
  - **LARGE:** detected 12 / 28 in both, coverage 0.617 / 0.590. 16 LARGE lesions (8–127 voxels) are missed in both conditions.
  - **Conclusion:** size explains the failure PARTLY.
  - The median is NOT a segmentation threshold. Notes §13.69.
- **Lesion-wise analysis (Phase 93, EXP-054), DIAGNOSTIC:**
  - **Method:** 26-connected 3D objects; the pre-registered rule is "match iff ≥ 1 shared voxel", many-to-many (PROJECT_SPEC §18).
  - **Result:** 59 GT lesions, 15 / 14 detected and 44 / 45 missed. 4 of 335 / 291 predicted components are matched and 331 / 287 are false.
  - **Large component:** a single large predicted component (the largest Phase-72 component, k 68–107) is connected to and overlaps 13 / 12 distinct GT lesions. It holds about 88–89 % of the TP plus about 35 % of the FP.
  - "Detected" is meant under the permissive any-overlap rule; it is not a lesion recall.
  - **Regression:** PASS against Phase 72 (components) and Phase 91 (TP). Notes §13.68.
- **Slice-wise diagnostics (Phase 92, EXP-053), DIAGNOSTIC ONLY:**
  - Files: `results/metrics/exp053_slice_wise_metrics.csv` (362 rows), `exp053_slice_diagnostic_summary.csv`, and the figures `results/figures/exp053_{pn0,pn3}_slice_{counts,metrics}.png`.
  - The summed counts equal Phase 91.
  - FP are widespread (121 / 117 slices) but central-heavy (about 62–64 % in k ≈ 70–104, peaks k 92–95).
  - 40 / 41 GT-positive slices with small lesion loads have no overlap (Recall 0).
  - `pn0`/`pn3` have the same pattern.
  - No location rule was derived; the Phase-91 metrics stay primary. Notes §13.67.
- **PRIMARY development evaluation (Phase 91, EXP-052):** `results/metrics/exp052_complete_3d_metrics.csv`.
  - It covers the complete 181×217×181 volume for Phase-71 T2 `M_pred`, `pn0`/`pn3` separately, consolidated from EXP-043..051 with no new metric (59/59).

  | | Dice | IoU | Precision | Recall | Specificity | V_pred | Volume error |
  |---|---:|---:|---:|---:|---:|---:|---:|
  | `pn0` | 0.056647 | 0.029149 | 0.029727 | 0.599943 | 0.990322 | 70,878 mm³ | 1918.17 % |
  | `pn3` | 0.057043 | 0.029359 | 0.030015 | 0.573178 | 0.990845 | 67,066 mm³ | 1809.62 % |

  - V_GT = 3,512 mm³; both volume errors are overestimations.
  - **Dominant problem:** a severe FP burden. Specificity is high only because of class imbalance.
  - **Tuning:** done in Phase 95 (see above).
- **Evaluation status (Phases 82–90):**
  - **Prediction:** Phase-71 T2 `M_pred`, conditions `pn0`/`pn3`.
  - **Phase 82 (EXP-043):** `src/evaluation/computeVoxelConfusion.m`, validated (synthetic 12/12, real 46/46).
    - Convention: rows = GT, columns = prediction, `[TN FP; FN TP]`.
    - TP/FP/FN/TN: `pn0` 2,107 / 68,771 / 1,405 / 7,036,854; `pn3` 2,013 / 65,053 / 1,499 / 7,040,572.
  - **Phase 83 (EXP-044):** `src/evaluation/computeDiceFromConfusion.m`, formalized and validated (synthetic 16/16, real 36/36).
    - Dice = 2TP / (2TP + FP + FN); project convention 0/0 → 1.
    - Dice: `pn0` **0.0566473988439306**, `pn3` **0.0570432712743348**.
  - **Phase 84 (EXP-045):** `src/evaluation/computeIoUFromConfusion.m`, IoU = Jaccard, formalized and validated (synthetic 16/16, real 34/34).
    - IoU = TP / (TP + FP + FN); project convention 0/0 → 1; matches Dice/(2 − Dice).
    - IoU: `pn0` **0.0291493158834027**, `pn3` **0.0293590024064756**.
  - **Phase 85 (EXP-046):** `src/evaluation/computePrecisionFromConfusion.m`, formalized and validated (synthetic 16/16, real 34/34).
    - Precision = TP / (TP + FP); project convention 0/0 → 1, which does not imply detection.
    - Precision: `pn0` **0.0297271367702249**, `pn3` **0.0300152088986968**, i.e. about 97 % of the predicted voxels are FP.
  - **Phase 86 (EXP-047):** `src/evaluation/computeRecallFromConfusion.m`, Recall = Sensitivity, formalized and validated (synthetic 16/16, real 34/34).
    - Recall = TP / (TP + FN); project convention 0/0 → 1.
    - Recall: `pn0` **0.5999430523918**, `pn3` **0.573177676537585**, i.e. about 60 % / 57 % of the lesion **voxels** recovered (voxel-wise, not lesion-wise).
  - **Phase 87 (EXP-048):** `src/evaluation/computeSpecificityFromConfusion.m`, formalized and validated (synthetic 16/16, real 34/34).
    - Specificity = TN / (TN + FP); project convention 0/0 → 1.
    - Specificity: `pn0` **0.990321611399419**, `pn3` **0.990844858826634**.
    - Severe class imbalance (7,105,625 negatives vs 3,512 lesion voxels): this is not overall accuracy.
  - **Joint pattern:** very low Dice/IoU, extremely low Precision, moderate Recall, very high Specificity.
  - **Phase 88 (EXP-049):** `src/evaluation/computeBinaryMaskVolume.m`.
    - GT label 10: 3,512 voxels; spacing 1 × 1 × 1 mm (Phase 26), so the voxel volume is 1 mm³.
    - **GT lesion volume 3,512 mm³** (3.512 cm³ = 3.512 mL), the same for `pn0`/`pn3`.
  - **Phase 89 (EXP-050):** same `computeBinaryMaskVolume` on `M_pred`, spacing 1 × 1 × 1 mm, voxel volume 1 mm³.
    - `pn0`: 70,878 voxels → **70,878 mm³** (70.878 mL).
    - `pn3`: 67,066 voxels → **67,066 mm³** (67.066 mL).
    - This is the segmented volume (TP + FP). The GT volume is not compared here.
  - **Phase 90 (EXP-051):** `src/evaluation/computeVolumeErrorPercent.m`, |V_pred − V_GT| / V_GT × 100, computed from the EXP-049 / EXP-050 CSVs (no masks loaded).
    - `pn0`: |diff| 67,366 mm³ → **1918.16628701595 %**, overestimation.
    - `pn3`: |diff| 63,554 mm³ → **1809.62414578588 %**, overestimation.
    - This measures total volume only, not overlap.
  - Held-out data not accessed; pipeline unchanged. Notes §13.57–13.65.
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
  - No fusion. T1 is used for the brain mask and, since EXP-057, for the anatomical support S2 (not as a lesion-signal source).
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

- **Minor software polish for the final refactoring** (no effect on results):
  - `classifyGtLesionSizes` should check `isvector` explicitly, because it currently flattens a matrix.
  - The EXP-055 figure title should read "SMALL ≤ 7; LARGE > 7".

- **Evidence for the later tuning stage (Phase 95), an observation only:** after Phases 85–86 the dominant limitation of the retained T2 pipeline is selectivity, not lesion-voxel recovery.
  - Precision is about 3 %, while Recall is about 57–60 % of the lesion voxels.
  - A tuning candidate would have to reduce FP strongly without losing the TP that sustain that Recall.
  - Nothing has been tuned yet; any change must follow the pre-registered Phase-37 rule.

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
| Phase 82 formal voxel-wise confusion matrix (EXP-043) | notes §13.57 |
| Phase 83 formal Dice (EXP-044) | notes §13.58 |
| Phase 84 formal IoU / Jaccard (EXP-045) | notes §13.59 |
| Phase 85 formal Precision (EXP-046) | notes §13.60 |
| Phase 86 formal Recall / Sensitivity (EXP-047) | notes §13.61 |
| Phase 87 formal Specificity (EXP-048) | notes §13.62 |
| Phase 88 GT lesion volume (EXP-049) | notes §13.63 |
| Phase 89 predicted lesion volume (EXP-050) | notes §13.64 |
| Phase 90 lesion-volume error (EXP-051) | notes §13.65 |
| Phase 91 consolidated complete-3D metrics (EXP-052, PRIMARY table) | notes §13.66 |
| Phase 92 slice-wise diagnostics (EXP-053) | notes §13.67 |
| Phase 93 lesion-wise analysis (EXP-054), matching rule | notes §13.68; PROJECT_SPEC §18 |
| Phase 94 small vs large GT lesions (EXP-055) | notes §13.69 |
| Phase 95 development-only tuning (EXP-056) | notes §13.70; PROJECT_SPEC §19.2 |
| Phase 95 T1-derived anatomical support (EXP-057, final development experiment) | notes §13.71; PROJECT_SPEC §19.2 |
| v1 freeze, amendment A1, EXP-058 (v2) | notes §13.72; `EXPERIMENT_LOG.md` after EXP-057 |
| v2 freeze, amendment A2, EXP-059 (v3) | notes §13.73; `EXPERIMENT_LOG.md` after EXP-058 |
| Phase 96 final freeze (v3 pipeline, regression, manifest) | `docs/PHASE96_FINAL_FREEZE.md`; `EXPERIMENT_LOG.md` (Phase 96 record) |
| EXP-022 … 027 (Phases 54–59) | notes §13.33–13.38; `EXPERIMENT_LOG.md` (summary table §6, status §11) |
