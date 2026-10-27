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
- **Phase 96 — final freeze: COMPLETE** (2026-10-16; commit `96b1612`, tag `v3-final-frozen`, not pushed).
  - **Final primary:** v3 = `D3_M1_G0`, selected before held-out access.
  - **Definition and entry point:** frozen definition in `src/segmentation/finalSegmentationConfig.m`; entry point `src/segmentation/generateFinalPrediction.m(rawT1, rawT2)`, which regenerates the EXP-021 mask from each condition's T1.
  - **Regression:** `experiments/phase96_final_pipeline_check.m` PASS 39/39 (voxel-by-voxel reproduction of EXP-059 on pn0/pn3).
  - **Development reference (in-sample, optimistic):** Dice 0.685378241112002 / 0.694404998579949; DevelopmentScore 0.689891619845975.
  - **Manifest:** SHA-256 of 26 artifacts in `results/metrics/phase96_final_freeze_manifest.csv` (tracked copy in `docs/`). Record: `docs/PHASE96_FINAL_FREEZE.md`.
  - **Held-out:** NOT downloaded, NOT accessed. `config.m` unchanged.
  - **Git freeze:** commit `96b16124999a0d40f8df2c66b072fb3a38f10322` ("fase 96: freeze final v3 pipeline"), annotated tag `v3-final-frozen` on that commit; post-commit manifest 26/26 valid; no push.
- **Phase 97 — held-out final test: COMPLETE** (2026-10-16; `experiments/phase97_heldout_test.m` PASS 28/28; notes §13.74).
  - Primary final version v3 / `D3_M1_G0`, unchanged; held-out pn1 / pn5 / pn7 / pn9 (official BrainWeb, downloaded after the freeze).
  - **Dice:** pn1 0.692256, pn5 0.714816, pn7 0.407869, pn9 0.408943.
    - Mean held-out Dice **0.555971**; worst **0.407869** (pn7); best **0.714816** (pn5).
  - **Main finding:** robust performance at pn1 / pn5. Strong false-positive over-segmentation at pn7 / pn9: Precision 0.28–0.29, FP about 7–8×, Recall 0.68–0.75. No pass/fail threshold was pre-registered.
  - **Secondary locked versions (mean Dice):** v1 0.549262, v2 0.553320, for comparison only. v1 is best at pn7 / pn9 but degrades at pn5. The development advantage of v3 almost disappears on average.
  - Primary changed after the test: NO. Phase-96 hashes before / after: PASS.
  - Frozen source unchanged: **YES** (26/26 hashes after the test). Held-out raw files unchanged. No commit or push.
  - Outputs: `results/metrics/phase97_*.csv`, `results/figures/phase97_*.png`, `data/processed/phase97_*_prediction.mat`.
- **Phase 98 — final raw result archive: COMPLETE** (2026-10-17; `experiments/phase98_results_archive_check.m` PASS 27/27, read-only).
  - The final raw held-out results are archived and indexed.
  - **Primary final metrics:** `results/metrics/phase97_v3_heldout_metrics.csv`. **Primary final predictions:** 4 frozen v3 held-out masks `data/processed/phase97_v3_{pn1,pn5,pn7,pn9}_prediction.mat`.
  - **Secondary predictions:** 8 frozen v1 / v2 held-out masks.
  - **Result manifest:** `phase97_result_manifest.csv` (27 entries, verified). **Inventory:** `results/metrics/phase98_final_results_inventory.csv` (32 rows with SHA-256 and authoritative roles).
  - Phase-96 frozen hashes valid; held-out raw MRI unchanged.
  - **Timing:** not measured; deferred to Phase 102.
- **Phase 99 — retrospective ablation study: COMPLETE** (2026-10-17; `experiments/phase99_ablation_study.m` PASS 14/14; development CSVs only, no new prediction / MRI / GT / held-out; notes §13.75).
  - 12 controlled one-factor pairs. The development trajectory EXP-026 → v3 is 7 controlled single-block steps.
  - **Largest contribution:** S2 support +0.5419 (S0 → S1 +0.3436, S1 → S2 +0.1982).
  - **Trajectory:** T2 anisotropic filtering is the second largest step after S2 (+0.0611).
  - **Across all controlled pairs:** M0 → M1 after D3 is larger (+0.1295), so morphology remains essential; M2 → M1 +0.0286.
  - **Small:** D2 → D3 +0.0014 (context-dependent) and G1 (±0.0016).
  - **Block status:**
    - not retained in v3: G1, square 3, D2;
    - rejected: Gaussian, TB, recovery (−0.098 / −0.626), T2 AND PD;
    - not introduced: region growing.
  - Outputs: `results/metrics/phase99_ablation_{summary,pairwise}.csv`, `phase99_development_trajectory.csv`, `results/figures/phase99_ablation_development_score.png`.
- **Phase 100 — noise robustness: COMPLETE, satisfied by Phase-97 artifacts** (2026-10-17; user decision; no new processing; notes §13.76).
  - **Curve:** `results/figures/phase97_v3_noise_curves.png`. **Table:** `results/metrics/phase100_noise_robustness_table.csv` (6 rows, values copied, DEVELOPMENT / HELD-OUT labelled).
  - The automatic TA threshold falls monotonically with noise. v3 is stable up to 5 % and drops at 7–9 % through false positives.
  - Smoothing (controlled v1 vs v2) helps up to 5 % but is worse than no filter at 7–9 %.
- **Phase 101 — lesion-load robustness: COMPLETE** (2026-10-17; `experiments/phase101_lesion_load_robustness.m` PASS 21/21; notes §13.77).
  - Data: matched BrainWeb custom simulations (AI template, 1 mm, 0 % noise, 0 % INU) of msles1 / msles2 / msles3. The ICBM variants were obtained but not used.
  - **v3 Dice:** mild 0.013 (29,301 predicted vs 422 GT voxels), moderate 0.662, severe 0.788. Primary v3 / D3_M1_G0 unchanged.
  - **Robustness dimension:** simulated MS lesion load. At very low lesion load the highest TA class includes high-intensity normal tissue, causing marked over-segmentation.
  - Outputs: `results/metrics/phase101_*.csv` (manifest 19 entries), `results/figures/phase101_*.png`.
- **Amendment A3 (2026-10-17): post-test development of v4 opened**, to correct the mild-lesion-load defect.
  - v3 remains the official result.
  - **Development data:** pn0, pn3 and custom msles1 / msles2 / msles3 (noise 0).
  - **Reserved test set**, generated only after the v4 freeze: custom AI, seed 2 — "normal" at 0 % and 3 %, msles1 at 3 %, msles3 at 3 %.
  - **Sequence:** D1 diagnostic (`experiments/v4_d1_intensity_diagnostic.m`, development only) → EXP-060 (pre-registered) → v4 freeze → test.
  - **D1 done:** in msles1 the TA threshold falls inside the GM distribution. The T1-high WM reference is stable and GT-free.
  - **EXP-060 done (PASS 8/8): v4 = k5**, threshold max(TA2, μWM + 5σWM).
    - Mean development Dice 0.631 vs 0.569 for v3. msles1 0.013 → 0.266 (29,301 → 269 voxels); pn0 0.722, pn3 0.711, msles2 0.667, msles3 0.788.
    - With k = 5 the floor is active in all development cases. In-sample values.
  - **v4 frozen** (commit `2525dde`, tag `v4-frozen`).
    - Secondary check on the seen pn1 / 5 / 7 / 9: v4 Dice 0.723 / 0.721 / 0.663 / 0.493 vs v3 0.692 / 0.715 / 0.408 / 0.409. v4 also removes the high-noise false-positive collapse.
  - **Amendment A4:** development continues on all 9 seen cases (in-sample); the reserved test is kept unseen.
  - **EXP-061 (hysteresis growth from the v4 cores): negative.** No configuration beats v4 (mean in-sample Dice 0.639). The best growth setting depends on the noise level. **v4 is the current best version.**
  - **Development closed.** Reserved-test protocol registered (commit `b27f9ff`).
  - **Reserved v4 test: DONE** (one shot, PASS 6/6; `experiments/v4_reserved_test.m`; custom AI, seed 2).
    - **Lesion-free phantom, false-positive voxels (v4 vs v3):** 172 vs 31,917 (noise 0 %), 30 vs 17,486 (noise 3 %).
    - **Dice (v4 vs v3):** msles1 3 % 0.341 vs 0.024; msles3 3 % 0.773 vs 0.788.
    - **Final reporting:** v3 = prospectively tested pipeline (Phase 97); **v4 = final improved pipeline**, verified on the reserved test.
- **Phase 102 — runtime measurement: SKIPPED / NOT REQUIRED FOR CORE PROJECT** (user decision, 2026-10-17). No real-time or computational-efficiency requirement was defined.
- **Phase 103 — automated experiment runner: COMPLETE** (2026-10-17; PASS 13/13).
  - **Runner:** `experiments/phase103_experiment_runner.m`, one command.
  - **Suite:** 13 cases (6 pre-computed, 3 custom seed 1, 4 reserved replays) × frozen v3 + v4 = 26 combinations. All 26 reproduce the saved predictions voxel by voxel and the authoritative TP / FP / FN exactly. The 39 registry input references correspond to 30 distinct files (26 MRI + 4 GT).
  - **Purpose:** automated reproducibility of the current evaluation suite; not new evidence.
  - Outputs: `results/metrics/phase103_{runner_metrics,case_summary,runner_manifest}.csv`, `phase103_runner_verification.txt`.
- **Phase 104 — CSV / MAT export: COMPLETE / FULFILLED BY PHASE 103.** The runner already exports the consolidated CSVs, and the predictions are archived as MAT files.
- **Phases 105–107 — final 2D visualization: COMPLETE** (2026-10-17; PASS 10/10).
  - Combined implementation: `experiments/phase105_107_final_2d_visualization.m`; v4 only.
  - Cases: pn3, reserved_msles1_n3, reserved_msles3_n3, plus a normal-phantom diagnostic.
  - Deterministic display slices: 102 / 70 / 104 / 83.
  - Figures in `results/figures/`:
    - `phase105_v4_mri_prediction.png`;
    - `phase106_v4_mri_ground_truth.png`;
    - `phase107_v4_tp_fp_fn.png`;
    - `phase107_v4_normal_false_positive_diagnostic.png`.
  - Index and manifest: `results/metrics/phase105_107_{visualization_index,figure_manifest}.csv`.
- **Phases 108–109 — final 3D visualization: COMPLETE** (2026-10-17; PASS 11/11).
  - Phase 108: COMPLETE; Phase 109: COMPLETE. Combined implementation: `experiments/phase108_109_final_3d_visualization.m`; helper `src/visualization/renderMask3DSurface.m`.
  - Same three cases and saved v4 predictions as Phases 105–107; complete 3D masks; X = dim 1, Y = dim 2, Z = dim 3 (display-only permutation for `isosurface`); 1 mm isotropic; fixed view(3) (az −37.5, el 30); full-volume limits; no smoothing / filtering / downsampling. Counts reproduce Phase 103.
  - Figures in `results/figures/`:
    - `phase108_v4_3d_prediction.png`;
    - `phase109_v4_3d_gt_prediction_comparison.png`;
    - `phase109_v4_3d_tp_fp_fn.png`.
  - Optional brain-context variant (PASS 8/8, `experiments/phase108_109_brain_context_3d.m`): EXP-021 brain mask from T1, alpha 0.07, display only; `phase108_v4_3d_prediction_brain_context.png`, `phase109_v4_3d_gt_prediction_brain_context.png`.
  - Index and manifests: `results/metrics/phase108_109_{visualization_index,figure_manifest,brain_context_index,brain_context_manifest}.csv`.
- **Phase 111 — COMPLETE — artificial-case validation of evaluation metrics** (2026-10-20; `experiments/phase111_artificial_metric_validation.m`, PASS 75/75; tolerance 1e-12, counts exact).
  - Confusion counts checked on a hand-specified 3×3 case (TP 2, FP 1, FN 1, TN 5); Dice 2/3, IoU 1/2, Precision 2/3, Recall 2/3, Specificity 5/6 verified against hard-coded values; volumes and volume error (0 %, 25 % over / under, spacing scaling) verified.
  - Empty-mask edge cases: the existing low-level convention (zero denominator → 1 for Dice / IoU / Precision / Recall / Specificity; `computeVolumeErrorPercent` rejects V_GT = 0) is confirmed and unchanged; the lesion-free reporting policy (NaN overlap metrics, Specificity = TN/(TN+FP)) is verified on the frozen audit table and runner.
  - Lesion-wise diagnostics (26-connectivity, ≥ 1 shared voxel) verified on an artificial 3D case (3 GT lesions, 2 detected, 1 missed, 1 false component).
  - No BrainWeb data, segmentation, formula or scientific result changed. Outputs: `results/metrics/phase111_{artificial_metric_validation.csv,validation_summary.txt}`.
- **Phases 110, 112–115 — DEFERRED TO PRE-DELIVERY QA** (user decision, 2026-10-17; Phase 111 completed separately on 2026-10-20 to support report Chapter 4). They concern software validation (110 assertions, 111 synthetic TP / FP / FN test), separation of responsibilities (112), dead-code removal (113), magic numbers (114) and MATLAB comments (115), not additional scientific experiments. To be revisited before final delivery / fresh-clone validation. Rule for that time: 112–115 must not change v4 behaviour; after any refactoring the Phase-103 runner is the regression test and must still reproduce 26 / 26 predictions voxel by voxel (one changed voxel = not a pure cleanup).
- **Phases 116–117 — final commit / tag: DEFERRED UNTIL FINAL REPOSITORY PREPARATION** (after the pre-delivery cleanup).
- **Phases 118–120 — final results package: COMPLETE** (2026-10-17; PASS 17/17; `experiments/phase118_120_final_results_package.m`). No segmentation rerun, no metric recomputed, no case removed.
  - **Phase 118 — scientific results frozen:** `docs/FINAL_RESULTS_FREEZE.md`; 52 sources in `results/metrics/phase118_final_results_source_manifest.csv`. Evidence hierarchy: FINAL RESERVED TEST (v4, 4 cases) / SEEN DURING v4 DEVELOPMENT (v4, 9 cases) / ORIGINAL v3 PROSPECTIVE TEST (v3, 4 cases).
  - **Phase 119 — report tables generated:** `results/metrics/phase119_main_results_v4_reserved.csv` (primary, 4 rows; `_report.csv` rounded), `phase119_v4_seen_context.csv` (9), `phase119_v3_original_prospective_test.csv` (4), `phase119_full_results_audit.csv` (26).
  - **Phase 120 — definitive figure set:** F1 `results/figures/phase120_final_2d_overview.png` (slices 102 / 70 / 104); F2 `phase108_v4_3d_prediction_brain_context.png`; F3 `phase109_v4_3d_gt_prediction_brain_context.png`; F4 (optional) `phase109_v4_3d_tp_fp_fn.png`. Index `results/metrics/phase120_final_figure_index.csv`; captions `docs/FINAL_FIGURE_CAPTIONS.md`.
  - Package manifest: `results/metrics/phase118_120_final_report_package_manifest.csv` (11 artifacts).
- **Phase 121 — COMPLETE — critical error analysis** (2026-10-17; `docs/FINAL_ERROR_DISCUSSION.md`).
- **Phase 122 — COMPLETE — project limitations documented** (2026-10-17; `docs/FINAL_LIMITATIONS.md`).
  - Traceability: `results/metrics/phase121_122_claim_evidence_matrix.csv` (59 claims). Analysis only; frozen package unchanged.
- **Next: Phase 123 — report introduction** (not started).
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
