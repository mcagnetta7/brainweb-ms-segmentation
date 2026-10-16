# Phase 96 — Final parameter and pipeline freeze

| Item | Value |
|---|---|
| Date | 2026-10-16 |
| Roadmap phase | 96 |
| Final primary version | **v3** |
| Selection source | EXP-059 (final development experiment, amendment A2) |
| Configuration | **D3_M1_G0** |
| Development conditions | `pn0` + `pn3` (msles2, 1 mm, rf0) |
| Selection criterion | Phase-37 DevelopmentScore = (Dice_pn0 + Dice_pn3) / 2, complete-volume 3D Dice, no tolerance |
| Primary designation | **made before any held-out access**. Held-out results cannot change it. |
| Held-out (`pn1`, `pn5`, `pn7`, `pn9`) | not downloaded, not accessed |
| Freeze status | READY TO FREEZE — commit and tag pending user approval (see the end of this file) |

## 1. Development reference (in-sample, NOT a test result)

Authoritative values from `results/metrics/exp059_selected_configuration.csv`, reproduced exactly by `experiments/phase96_final_pipeline_check.m` (copy: `docs/phase96_final_development_reference.csv`).

| Condition | Dice | IoU | Precision | Recall | Specificity | TP | FP | FN | Predicted voxels | Volume error |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| pn0 | 0.685378241112002 | 0.521350 | 0.645844 | 0.730068 | 0.999802 | 2,564 | 1,406 | 948 | 3,970 | 13.04 % |
| pn3 | 0.694404998579949 | 0.531869 | 0.692635 | 0.696185 | 0.999847 | 2,445 | 1,085 | 1,067 | 3,530 | 0.51 % |

**DevelopmentScore 0.689891619845975.**

`pn0` and `pn3` were used repeatedly during iterative development (Phases 53–95, amendments A1 and A2). These values are in-sample development performance and are expected to be optimistic. They are **not** an unbiased test estimate.

## 2. Frozen pipeline (v3 = D3_M1_G0)

The machine-readable definition is `src/segmentation/finalSegmentationConfig.m`. The entry point is `src/segmentation/generateFinalPrediction.m(rawT1, rawT2)`: it composes only already validated helpers and refuses to run if the configuration record differs from the frozen values.

```text
RAW T1 + RAW T2 (BrainWeb .raws, uint16 little-endian, 0..4095, 181 x 217 x 181, V(i,j,k) = X,Y,Z)
 -> double, fixed normalization (v - 0) / (4095 - 0) -> [0,1]   (no per-volume min/max, no harmonization)
 -> EXP-021 brain mask from the condition's own T1:
      graythresh(T1norm(:)), one global threshold, imbinarize per axial slice (value > threshold)
      -> imerode 3D strel('sphere', 3) -> largest 26-connected 3D component
      -> imdilate 3D strel('sphere', 3) AND raw foreground -> imfill(slice, 'holes') per axial slice
 -> S2 from the UNFILTERED T1:
      levels = multithresh(T1norm(brainMask), 2); T1-low candidate = class 1; T1-high candidate = class 3
      S2 = brainMask AND imfill(T1-high slice, 'holes') per axial slice AND NOT T1-low
 -> D3: imdiffusefilt on the WHOLE normalized T2 volume, explicit project parameters (not MATLAB defaults):
      GradientThreshold = 0.10 * (max(T2norm(:)) - min(T2norm(:))), NumberOfIterations 5,
      Connectivity "maximal" (26-neighbour), ConductionMethod "exponential";
      constant volume returned unchanged; error if the output leaves [0,1] by > 1e-12, then clipped to [0,1]
 -> TA: levels = multithresh(T2filtered(S2), 2), estimated inside S2 only;
      candidate = S2 AND T2filtered > levels(2)   (highest of 3 classes)
 -> M1: exactly one 2D axial opening per slice with strel('diamond', 1), then AND S2
 -> G0: no predicted-component filtering
 -> M_pred: logical, same size as the MRI, contained in S2
```

| Not part of the final pipeline | |
|---|---|
| Component filtering (G1) | none |
| Recovery (R1 / R2 reconstruction) | none |
| Region growing | none |
| PD | not used |
| Gaussian filtering, D2 slice-wise diffusion | not used |
| Filtering of T1 | none |
| Saved pn0 / pn3 brain masks | not used (the mask is regenerated from each condition's T1) |
| Numeric thresholds measured on development data | none (all thresholds are data-dependent outputs of the frozen automatic rules) |

**Note on unused fields:** `generateFinalPrediction` passes `componentConnectivity = 26` and `minimumOccupiedSlices = 2` to the shared helper only because its configuration schema requires them. With `componentFilter = "none"` (G0) they are never used: **no component of the final prediction is removed**. Likewise, `connectivityNeighbours3D = 26` in the final configuration refers to the D3 diffusion neighbourhood, not to any connected-component step on the prediction.

**Data-dependent values are not parameters:** the brain-mask threshold (0.258824 / 0.250980) and the TA levels (pn0 0.615594, pn3 0.565404) are outputs of the frozen automatic rules on each image. They are never hard-coded, and the held-out conditions will produce their own values with the same rules.

**Roles:** T1 provides the automatic brain support (EXP-021) and the anatomical support S2; T2 provides the lesion intensity segmentation. "S2", "T1-low candidate", "T1-high candidate" and "WM-support envelope" are intensity-based supports, not clinically exact tissue masks.

**Volumetric extensions:** the EXP-021 brain mask (3D erosion / component / dilation) and the D3 whole-volume anisotropic diffusion are project extensions of classical course techniques. They are not claimed to have been taught as volumetric pipelines in the course (ALLOWED_TECHNIQUES §4.4 and §10).

## 3. Known limitations (frozen, declared before Phase 97)

- **S2 structural limitation:** the algorithm searches only inside S2. Lesion voxels outside S2 cannot be segmented by any later stage (in EXP-057, S2 contained 3,114 / 3,058 of the 3,512 GT voxels, a voxel-Recall cap of 0.887 / 0.871). The restriction was kept because expanding the search towards S1 had reintroduced severe false-positive contamination (EXP-057 S1; EXP-058 R2).
- **Small lesions** remain the main source of missed lesions (detected SMALL: 6 / 5 of 31 in EXP-059).
- **Optimistic development estimate:** see §1.
- **Held-out interpretation:** `pn1`, `pn5`, `pn7` and `pn9` share the same msles2 anatomy, the same lesion configuration and the same rf0 setup; only the simulated noise level differs. The held-out evaluation therefore tests **robustness to unseen simulated noise conditions**, not generalization to independent patients. The fixed D3 parameters were not tuned for noise levels above 3 %.

## 4. Version lineage (all frozen; only v3 is primary)

| Version | Source | Configuration | DevelopmentScore | Role in Phase 97 | Tag |
|---|---|---|---:|---|---|
| v1 | EXP-057 | S2_TA_M2_G1 | 0.600034 | secondary locked version | `v1-frozen` |
| v2 | EXP-058 | F5_R0 | 0.661169 | secondary locked version | `v2-frozen` |
| **v3** | **EXP-059** | **D3_M1_G0** | **0.689892** | **PRIMARY** | `v3-final-frozen` (pending) |

If v1 or v2 score higher than v3 on some held-out condition, this is reported, but the primary designation does not change. Adopting another version would require confirmation on new independent data (amendment A2).

## 5. Regression validation (`experiments/phase96_final_pipeline_check.m`, PASS 39/39)

- **Exact reproduction:** the final entry point, starting from raw MRI and regenerating the EXP-021 mask, reproduces the saved EXP-059 D3_M1_G0 predictions **voxel by voxel** (`isequal`) for `pn0` (3,970 voxels) and `pn3` (3,530).
- **Regenerated brain mask:** equal to the saved EXP-021 masks.
- **Independent rebuild:** a step-by-step rebuild without the wrappers (S2, D3, TA inside S2, class 3, diamond-1 opening) equals the final output.
- **Metrics:** Dice and DevelopmentScore equal the EXP-059 artifact (up to the CSV's 15-digit text rounding); the confusion counts equal those of the saved predictions exactly.
- **Static code checks:** no GT argument, no file access, no square 3, G1, recovery, region growing, PD, Gaussian or D2 in the entry point, and no position or size rule.
- **Held-out protection:** no held-out file exists in `data/raw` or in the outputs; `config.m` has no held-out path and is unchanged.
- **Immutability:** raw MRI and GT are unchanged, and the v1 / v2 predictions match their recorded SHA-256.
- **Implementation note:** this MATLAB installation has no Java runtime, so SHA-256 is computed with Windows `certutil`. It was also verified independently with PowerShell `Get-FileHash`: 26 / 26 match.

## 6. SHA-256 manifest

`results/metrics/phase96_final_freeze_manifest.csv`, with a tracked copy at `docs/phase96_final_freeze_manifest.csv`: 26 artifacts. It covers:
- the final configuration and entry point, and the D3, S2, TA / opening, EXP-021, normalization and loader helpers;
- `config.m`;
- the EXP-059 CSVs and predictions, the EXP-059 script, this regression check and the development reference;
- the historical v1 / v2 predictions.

Files in `data/processed/` and `results/metrics/` are excluded from Git, so the manifest is their provenance record. This document is not in the manifest because it receives the commit identifiers after the freeze; it is versioned by the tag.

## 7. Version-control freeze

| Item | Value |
|---|---|
| Commit message | `fase 96` |
| Tag | `v3-final-frozen` |
| Commit hash | pending user approval |
| Push | none |
