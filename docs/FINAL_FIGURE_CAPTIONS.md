# Final figure captions (Phase 120)

Definitive report figures, indexed in `results/metrics/phase120_final_figure_index.csv`.
All figures show the final pipeline **v4 (V4_K5)** and the same three cases, fixed
before Phase 120: `pn3` (moderate lesion load, BrainWeb pre-computed, development
reference), `reserved_msles1_n3` (mild, final reserved test, seed 2) and
`reserved_msles3_n3` (severe, final reserved test, seed 2); 3 % noise in all three.

## F1 — Final 2D overview

`results/figures/phase120_final_2d_overview.png`

Final v4 segmentation on one axial T2 slice per case (rows: moderate, mild, severe).
Columns: original T2; T2 with the ground-truth lesions (label 10, cyan); T2 with the
v4 prediction (yellow); error map with true positives (green), false positives (red)
and false negatives (blue), true negatives not coloured. The slice of each case is the
axial slice with the most ground-truth lesion voxels, chosen for display only and
identical to Phases 105–107 (k = 102, 70, 104). Masks are shown unchanged.

## F2 — 3D final v4 prediction

`results/figures/phase108_v4_3d_prediction_brain_context.png`

Complete 3D v4 lesion mask (yellow) of each case. The grey, highly transparent surface
is the boundary of the automatic EXP-021 brain mask derived from T1 by the pipeline,
shown only as spatial context; it is not an anatomical cortical reconstruction and not
a ground-truth brain surface. Same fixed view, full-volume limits and 1 mm isotropic
geometry for every case; X, Y, Z = array dimensions 1, 2, 3 (no left / right labels).

## F3 — 3D ground truth vs v4 prediction

`results/figures/phase109_v4_3d_gt_prediction_brain_context.png`

Complete 3D ground-truth lesion volume (cyan) and v4 prediction (yellow), both
semi-transparent, in the same coordinates; the grey surface is the automatic EXP-021
T1-derived brain mask (display context only, not an anatomical reconstruction).
Overlap appears as mixed colour, disagreement as single-colour regions. Same view and
limits as F2. Alternative without brain context:
`results/figures/phase109_v4_3d_gt_prediction_comparison.png`.

## F4 — 3D error geometry (optional)

`results/figures/phase109_v4_3d_tp_fp_fn.png`

Complete 3D true positives (green, prediction ∩ GT), false positives (red, prediction
outside GT) and false negatives (blue, GT not predicted) of the v4 prediction, without
brain context. Same view and limits as F2–F3. No component is removed, smoothed or
enlarged.
