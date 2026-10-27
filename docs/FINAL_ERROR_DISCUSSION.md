# Final error discussion (Phase 121)

Analytical source for the report (Results / Discussion). Analysis only: every value
below is read from the frozen Phase-118/120 package or from the authoritative sources
it hashes. No segmentation was rerun and no metric was recomputed. Derived numbers
(differences, ratios, reductions) are marked **[derived]** and traced in
`results/metrics/phase121_122_claim_evidence_matrix.csv`; bracketed identifiers
`[Cnn]` refer to its rows.

Wording convention: **shows** = direct observation in a frozen table or figure;
**suggests / is consistent with** = interpretation supported by several observations;
**hypothesis** = plausible mechanism that was not isolated experimentally.

---

## 1. Scope and evidence hierarchy

Final method: **v4 / V4_K5** (`v4-frozen`, 2525dde): the frozen v3 pipeline with the
T2 threshold `max(TA level 2, μref + 5·σref)`, where μref and σref are the mean and
standard deviation of the filtered T2 inside the automatically derived **T1-high
(WM-like) reference region** within S2. The reference region is image-derived; it is
not a ground-truth white-matter segmentation. Historical reference: **v3 / D3_M1_G0**
(`v3-final-frozen`, 96b1612).

| Group | Version | Cases | Status |
|---|---|---|---|
| A — FINAL RESERVED TEST | v4 | normal_n0, normal_n3, msles1_n3, msles3_n3 (seed 2) | independent post-freeze evidence; primary |
| B — SEEN DURING v4 DEVELOPMENT | v4 | pn0, pn1, pn3, pn5, pn7, pn9, custom seed-1 msles1/2/3 | in-sample; mechanism and trends only |
| C — ORIGINAL v3 PROSPECTIVE TEST | v3 | pn1, pn5, pn7, pn9 (Phase 97) | genuine held-out evidence for v3 |

Sources: `phase119_main_results_v4_reserved.csv` (A), `phase119_v4_seen_context.csv`
(B), `phase119_v3_original_prospective_test.csv` (C); v3 values on the reserved cases
come from the v3 reference arm of the reserved test (`v4_reserved_test_results.csv`,
also in `phase119_full_results_audit.csv`). Statements about group B are never
presented as independent validation of v4.

A low Dice or Recall in this document is a property of the algorithm under a given
condition, not a failure of the experimental protocol: the protocol is what exposes
it.

## 2. Main error modes

Across all frozen evidence two opposite error modes appear:

1. **False-positive oversegmentation (dominant v3 failure).** The v3 prediction
   expands into non-lesion high-intensity tissue when lesions are absent or sparse,
   and when noise is high (sections 3, 6).
2. **False-negative under-detection (dominant remaining v4 failure).** v4 suppresses
   most of the oversegmentation, but misses lesion voxels that are excluded by S2, that
   do not exceed the raised threshold, or that are removed as very small structures
   (sections 4, 7, 8).

The v3 → v4 change therefore did not remove errors; it moved the operating point from
the first regime to the second (section 9).

## 3. False positives

### 3.1 Lesion-free reserved phantoms (group A)

On the normal phantom every predicted voxel is a false positive, so these two cases
test directly whether the method labels ordinary high-intensity tissue as lesion when
no lesion exists. Dice, IoU, Precision, Recall and volume error are undefined (NaN by
the pre-registered convention) and are not replaced by any value.

| Case | Version | Predicted = FP voxels | False components | FP / brain mask | FP / S2 | Specificity |
|---|---|---|---|---|---|---|
| normal_n0 | v4 | 172 | 10 | 1.01e-4 | 2.43e-4 | 0.999976 |
| normal_n0 | v3 | 31,917 | 723 | 1.88e-2 | 4.51e-2 | 0.995510 |
| normal_n3 | v4 | 30 | 5 | 1.82e-5 | 4.16e-5 | 0.999996 |
| normal_n3 | v3 | 17,486 | 455 | 1.06e-2 | 2.42e-2 | 0.997540 |

The reserved test **shows** that v4 reduces the false-positive volume on lesion-free
data from 31,917 to 172 voxels (noise 0 %) and from 17,486 to 30 voxels (noise 3 %);
**[derived]** these are reductions of 99.5 % and 99.8 % of the v3 volume [C01]. The
residual v4 output is not zero: 10 and 5 small false components remain [C02]. This is
the strongest independent evidence that the v4 floor generalized beyond the
development cases for the failure it was designed to address. It has no clinical
implication.

Specificity stays above 0.995 even for v3, whose output on normal_n0 is a 31,917-voxel
false lesion volume [C03]: on these volumes Specificity alone does not reveal the
failure (see `FINAL_LIMITATIONS.md`, section 13).

### 3.2 Why v3 oversegments: the semantics of the highest T2 class

v3 thresholds the filtered T2 inside S2 with `multithresh(·, 2)` and labels the highest
class as lesion. Phase 101 (v3, custom seed 1) **shows** that at mild lesion load the
two TA thresholds were much closer (0.433 / 0.469; gap **[derived]** 0.036) than at
moderate (0.443 / 0.562; gap 0.118) and severe load (0.446 / 0.591; gap 0.144), and
that the mild-load prediction contained 29,109 FP voxels against 422 GT voxels (Dice
0.013) [C04]. The reserved test repeats the pattern on unseen seed-2 data: v3 on
msles1_n3 predicts 16,891 voxels for 422 GT voxels (Dice 0.024, Precision 0.012) [C05].

`multithresh` only partitions intensities; it does not know what a lesion is. The
results **suggest** a structural limitation of assigning lesion semantics to the
highest automatically partitioned T2 class when lesion prevalence is very low: the
highest class is then populated mainly by high-intensity normal tissue [C06]. The
mechanism is an interpretation; the share of each tissue in the highest class was not
isolated as a separate experiment.

### 3.3 Residual false positives of v4

On lesion-containing data v4 still produces false positives, but few of them form
isolated false components: pn3 669 FP voxels with 1 false component; msles3_n3 1,132
FP voxels with 0 false components; msles1_n3 64 FP voxels with 2 false components
[C07]. In the final displayed slices and in the 3D error figure, many of the residual
false positives appear as thin peripheral extensions of the lesion regions
(qualitative observation) [C08]. This is
**consistent with** boundary disagreement (partial-volume and filtered-intensity
transitions) rather than with detection of spurious structures; the boundary
mechanism was not measured separately.

## 4. False negatives

v4 raises the effective threshold above TA2 in every evaluated condition (the floor is
active in all 13 v4 rows of the audit table) [C09]. The direct consequence on the seen
and reserved data is higher Precision, fewer FP and lower Recall than v3 (section 9).

The frozen data allow a partial decomposition of the false negatives, because every
prediction lies inside S2 (`predictionInsideS2 = 1`): GT voxels outside S2 are false
negatives by construction. **[derived]** On msles1_n3, 110 of the 322 false-negative
voxels (GT: 422 voxels) lie outside S2 and are therefore structurally unrecoverable by
the downstream pipeline; the corresponding counts are 686 of the 3,025 false-negative
voxels on msles3_n3, 454 of 1,206 on pn3 and 703 of 2,345 on pn9 [C10]. The remaining false negatives lie inside S2 and were lost to the T2
threshold or to the diamond-1 opening; the frozen evidence does not separate these two
causes.

Plausible contributors inside S2 (**hypothesis**, not isolated per voxel):

- lesion voxels whose filtered T2 does not exceed the WM-like outlier floor
  (μref + 5σref), i.e. weak or low-contrast lesion parts;
- peripheral voxels of lesions whose core is segmented (partial-volume borders);
- very small components that contain no voxel above the threshold, or that are
  removed by the opening.

Not every false negative has the same cause, and no individual missed lesion is
attributed to a specific mechanism here.

## 5. Effect of lesion load

### 5.1 Mild load (msles1_n3, group A)

| Version | Dice | Precision | Recall | Predicted | FP | Detected GT lesions | False components |
|---|---|---|---|---|---|---|---|
| v4 | 0.341 | 0.610 | 0.237 | 164 | 64 | 4 / 13 | 2 |
| v3 | 0.024 | 0.012 | 0.495 | 16,891 | 16,682 | 7 / 13 | 399 |

The reserved test **shows** that v4 removes the catastrophic oversegmentation of v3 at
mild load and raises Dice and Precision by an order of magnitude [C11]. It also shows
that v4 Recall is low (0.237), that only 4 of 13 GT lesions are touched by the
prediction, and that 26 % of the GT voxels lie outside S2 (fractionGtInsideS2 =
0.739) [C12]. Mild lesion load is therefore not solved. v4 converts the dominant
failure mode from severe oversegmentation to a more conservative under-detection
regime [C13]. The development case custom seed-1 msles1 (group B) shows the same
pattern (v4 Dice 0.266, Recall 0.218, versus v3 Dice 0.013).

### 5.2 Moderate load (msles2)

Moderate load has only seen evidence for v4 (pn0–pn9, custom seed-1 msles2; group B).
At low and moderate noise v4 Dice lies between 0.667 and 0.723, with Precision above
Recall in every case [C14]. This is the condition the pipeline was developed on and is
not independent evidence.

### 5.3 Severe load (msles3_n3, group A)

| Version | Dice | Precision | Recall | FP | FN | Detected GT lesions |
|---|---|---|---|---|---|---|
| v4 | 0.773 | 0.862 | 0.701 | 1,132 | 3,025 | 18 / 39 |
| v3 | 0.788 | 0.811 | 0.765 | 1,796 | 2,375 | 23 / 39 |

On this reserved case **v3 has the higher Dice** (0.788 vs 0.773; **[derived]**
difference 0.014) and the higher Recall; v4 has fewer FP and higher Precision [C15].
v4 does not dominate v3 in every metric and condition. At severe load, where the
highest T2 class is well populated by lesions, the v3 assumption holds and the v4
floor mainly removes lesion-border voxels: v4 adopts a more conservative operating
point, at a small Dice cost here and a large Dice gain at mild load.

### 5.4 Lesion load and the v3 threshold assumption

Taken together (Phase 101 and reserved test), lesion load is the factor that most
clearly separates the two versions: the v3 failure is concentrated where lesions are
absent or sparse, which is **consistent with** the threshold-semantics interpretation
of section 3.2 [C06].

## 6. Effect of noise

### 6.1 v3, original prospective test (group C)

| Case | Noise | Dice | Precision | Recall | FP | Predicted components |
|---|---|---|---|---|---|---|
| pn1 | 1 % | 0.692 | 0.659 | 0.729 | 1,326 | 41 |
| pn5 | 5 % | 0.715 | 0.748 | 0.685 | 812 | 32 |
| pn7 | 7 % | 0.408 | 0.280 | 0.750 | 6,766 | 127 |
| pn9 | 9 % | 0.409 | 0.292 | 0.680 | 5,775 | 143 |

The Phase-97 test **shows** stable behaviour from 1 % to 5 % noise (Dice 0.692 and
0.715; not monotonic) followed by a marked degradation from 7 % onward [C16]. The
degradation is driven mainly by the increase of false positives and the resulting
collapse of Precision (0.280 / 0.292), rather than by a collapse of Recall, which stays
at 0.68–0.75 [C17].

### 6.2 v4 on the same noise levels (group B, in-sample)

| Case | Dice | Precision | Recall | FP |
|---|---|---|---|---|
| pn1 | 0.723 | 0.760 | 0.689 | 763 |
| pn5 | 0.721 | 0.836 | 0.634 | 438 |
| pn7 | 0.663 | 0.896 | 0.526 | 214 |
| pn9 | 0.493 | 0.953 | 0.332 | 58 |

These cases were seen during v4 development and are not an independent v4 test. On
them, v4 does not show the high-noise FP explosion: FP decreases with noise and
Precision increases [C18]. The cost is a steep Recall decline (0.689 → 0.332), so at
9 % noise the dominant v4 limitation is sensitivity [C19]. Between pn1 and pn9 the
floor μref + 5σref decreases less (0.628 → 0.554) than TA2 (0.604 → 0.414), so the
margin by which the floor exceeds TA2 grows (**[derived]** 0.024 → 0.140), while σref
increases (0.031 → 0.039) [C39]. This is **consistent with** the floor becoming the
decisive, and relatively stricter, criterion as noise increases.

### 6.3 High-noise mechanism

The Phase-97 data show three concurrent changes as noise increases:

- the two TA levels move and their separation shrinks (**[derived]** gap 0.121 at pn1,
  0.114 at pn5, 0.061 at pn7, 0.058 at pn9);
- v3 FP increase strongly at pn7 / pn9;
- the GT coverage of S2 declines (fractionGtInsideS2 0.888, 0.884, 0.859, 0.800) [C20].

The observed threshold behaviour is consistent with reduced intensity separability,
while the concurrent reduction in S2 lesion coverage indicates that both candidate
support and T2 classification contribute to the high-noise failure mode [C21]. The
evidence does not isolate `multithresh` as the single cause, and overlap between
denoised tissue distributions is a **hypothesis** compatible with these observations.

## 7. Small-lesion sensitivity

Lesion-wise detection uses the established rule: a GT lesion (26-connected component)
is **detected if at least one predicted voxel overlaps it**. A detected lesion is
therefore not necessarily well segmented, and this caveat applies to every lesion count
below [C22].

- v4 touches 4 / 13 (msles1_n3) and 18 / 39 (msles3_n3) GT lesions on the reserved
  test, and 9–25 / 59 on the seen msles2 cases, while recovering more than 60 % of the
  lesion volume (Recall) in the moderate and severe cases up to 5 % noise [C23]. Many GT components are therefore missed
  entirely, and the missed ones are not compensated by the voxel-level Dice.
- For v3 (Phase 101, seed 1), the median size of missed GT lesions was 1.5, 5 and 2.5
  voxels against 27, 36.5 and 93 voxels for detected lesions (mild / moderate /
  severe), with GT lesions as small as 1 voxel in all three phantoms [C24]. Missed
  lesions are predominantly the smallest ones.
- Phase-97 lesion-wise counts for v3 rise at high noise (41 and 44 detected at pn7 /
  pn9 versus 32 and 24 at pn1 / pn5) while Dice falls [C25]. This is **consistent
  with** incidental overlaps produced by spreading false positives and illustrates why
  the any-overlap count must not be read as segmentation quality.

The Phase-94 split (small ≤ 7 voxels) was defined on msles2 and is not transferred to
msles1 / msles3; cross-load statements here use the continuous size statistics of
Phase 101.

Small and weak lesions are expected to be vulnerable to S2 exclusion, to the v4 floor
and to the opening (**hypothesis** for individual lesions; the per-lesion cause was not
isolated).

## 8. Anatomical support, filtering and morphology (Phase 99, development only)

The ablation is a retrospective synthesis on pn0 / pn3 (development data); its values
are development scores, not test results.

**S2 — the largest single improvement and a hard Recall ceiling.** Adding the
T1-derived support S2 raised the development score from 0.058 to 0.600 (+0.542), the
largest step of the whole trajectory, by reducing FP from 66,484 / 63,126 to 1,167 /
3,123 voxels (pn0 / pn3) [C26]. Because the downstream stages only act inside S2, the
fraction of GT inside S2 is an upper bound on Recall: 0.739 (msles1_n3), 0.932
(msles3_n3), 0.871 (pn3), 0.800 (pn9) [C27]. S2 is simultaneously the largest source
of FP suppression and a hard limit on achievable sensitivity: an explicit
sensitivity / specificity trade-off rather than a contradiction.

**Denoising.** 2D anisotropic diffusion on T2 added +0.061 to the development score
(FP 1,167 / 3,123 → 967 / 857) [C28]. The 2D → 3D extension added only +0.0014 [C29]:
its measured contribution is small compared with S2 and with the introduction of
filtering.

**Morphology.** After 3D filtering, removing the opening (M0) left 4,768 / 3,928 FP
and a score of 0.560; diamond-1 (M1) gave 0.690 [C30]. The more aggressive square-3
(M2) removed more FP (926 / 752) but also more true positives (TP 2,217 / 2,083 vs
2,564 / 2,445 with M1) and scored 0.661 [C31]. Morphology therefore remains useful
after denoising, and its useful strength is limited by the loss of real lesion voxels;
its effect depends on the upstream support and filtering.

**G1 (single-slice component removal).** Small positive effect at an earlier stage
(+0.0013); after D3 + M1 removing it was marginally better (+0.0016), so it is not in
the final configuration [C32].

**Recovery R1 / R2.** Both increased TP but increased FP much more (R1: FP 967 / 857 →
3,880 / 3,430; R2: → 194,862 / 168,758), lowering the score by 0.098 and 0.626; not
retained [C33].

**Hysteresis / region growing (EXP-061, in-sample).** Growth from the v4 cores
recovered lesion extent at high noise (e.g. pn9 Dice 0.493 → 0.669 with growth inside
S2, 0.717 with growth into S1) but spread strongly into normal tissue at low noise or
low load (pn0: 241,247 predicted voxels with growth into S1; msles1: Precision 0.0008)
[C34]. Region growing is not intrinsically inadequate: the useful expansion strength
depended strongly on the image condition, so a single frozen rule could not be
justified from the available evidence, and choosing it per noise level on the seen
cases would have been tuning on evaluation data. EXP-061 was not retained.

## 9. Precision / Recall trade-off introduced by v4

| Case (group) | Precision v3 → v4 | Recall v3 → v4 |
|---|---|---|
| msles1_n3 (A) | 0.012 → 0.610 | 0.495 → 0.237 |
| msles3_n3 (A) | 0.811 → 0.862 | 0.765 → 0.701 |
| pn1 (C for v3 / B for v4) | 0.659 → 0.760 | 0.729 → 0.689 |
| pn9 (C for v3 / B for v4) | 0.292 → 0.953 | 0.680 → 0.332 |

In every lesion-containing reserved and seen case Precision increases and Recall
decreases from v3 to v4 [C35]. v3 is more sensitive in difficult cases but can
oversegment catastrophically; v4 is more selective, with a lower FP burden and much
better behaviour when lesions are absent or sparse, at the price of lower Recall in
weak, noisy or mild-load settings. Neither metric is treated as intrinsically more
important: the final v4 design deliberately favours robustness against catastrophic
FP oversegmentation while accepting a more conservative sensitivity profile [C36].
This is an interpretation of the observed trade-off, not a clinically optimized
operating point.

## 10. v3 → v4 progression

- **v3 assumption:** the highest T2 class inside S2 is lesion.
- **Observed v3 failures:** catastrophic oversegmentation at mild load (Phase 101,
  confirmed on the reserved msles1_n3 and normal phantoms) and FP growth at high noise
  (Phase 97).
- **v4 change:** a WM-like intensity-derived lower bound, max(TA2, μref + 5σref), with
  k = 5 chosen on the declared development set (EXP-060: admissible values 3–5, k = 6
  rejected by the pre-registered drop limit).
- **Reserved outcome:** the intended FP control generalized to the four unseen seed-2
  conditions (section 3.1, 5.1); the cost appeared as lower Recall, and on msles3_n3 as
  a slightly lower Dice than v3 (section 5.3).

v4 does not solve every problem; it trades a large reduction of FP instability for a
moderate loss of sensitivity.

## 11. What the 2D and 3D visualizations show

Qualitative evidence only; display slices were chosen by the maximum number of GT
lesion voxels and are not representative of average slice performance.

- **pn3, k = 102 (F1):** lesion cores are covered; FP appear as thin rims around the
  periventricular lesions and FN as small isolated GT spots, consistent with the
  measured Precision 0.775 / Recall 0.657 [C08].
- **reserved_msles1_n3, k = 70 (F1):** the displayed slice shows mostly FN along the
  thin periventricular lesion with a small segmented part, consistent with the low
  Recall [C37].
- **reserved_msles3_n3, k = 104 (F1):** the major lesion structures are covered;
  residual FN regions are visible on smaller lesions and thin FP rims on the large
  confluent ones [C37].
- **3D (F2–F4):** the complete masks show that lesions occupy several separate regions
  around the ventricles and extend across many slices; in the mild case most GT
  components appear as unmatched (FN) structures; in the severe case FP form thin
  layers on the borders of the large confluent lesions. The volumetric view makes the
  differences in lesion burden directly visible and shows that success on one 2D
  slice does not imply complete 3D delineation [C38]. In F2 / F3 the grey surface is
  the automatic EXP-021 T1-derived brain mask used by the pipeline, shown only as
  spatial context; it is not a cortical or ground-truth anatomical surface.

## 12. Overall error profile

**What works under the tested simulated conditions**

- fully automatic, deterministic operation with image-derived thresholds;
- strong FP suppression through the T1-derived support S2;
- improved robustness of the v4 floor against lesion-free, low-load and high-noise FP
  oversegmentation;
- very low residual FP on the lesion-free reserved phantoms (172 and 30 voxels);
- Dice 0.67–0.79 at moderate and severe simulated lesion load up to 5 % noise (seen
  data and reserved msles3_n3);
- reproducible results (Phase 103: 26 / 26 predictions reproduced voxel by voxel).

**Main remaining failure modes**

- conservative under-detection, with low Recall at mild load and at high noise;
- missed small and weak lesions (many GT components never touched);
- sensitivity to high noise, now expressed as Recall loss rather than FP growth;
- hard exclusion of GT voxels outside S2.

**Conclusion.** The final v4 pipeline substantially reduces the false-positive
instability observed with v3, particularly for lesion-free and low-lesion-load
conditions (reserved test) and for noisy conditions (seen data). This improvement is
obtained by shifting the operating point toward greater selectivity. The remaining
dominant limitation is under-detection: weak, small or support-excluded lesion voxels
may be missed, especially under difficult intensity conditions, and on the severe
reserved case v3 retains a slightly higher Dice. The final method should thus be
interpreted as a conservative classical segmentation pipeline whose main strength,
under the tested simulated conditions, is false-positive control rather than maximal
sensitivity.
