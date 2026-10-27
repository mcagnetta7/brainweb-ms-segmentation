# Project limitations (Phase 122)

Analytical source for the report's limitations section. It refers to the frozen
Phase-118/120 package; bracketed identifiers `[Cnn]` refer to
`results/metrics/phase121_122_claim_evidence_matrix.csv`. The error analysis itself is
in `docs/FINAL_ERROR_DISCUSSION.md`.

---

## 1. Dataset realism

All images are **simulated** BrainWeb MRI (pre-computed msles2 volumes and custom
simulations of the msles1, msles2, msles3 and normal phantoms). BrainWeb provides an
exact, controlled ground truth, controlled noise and lesion load, and fully
reproducible experiments; these properties made the controlled comparisons of this
project possible. The same properties limit external validity: the results cannot be
transferred automatically to real clinical MRI, real patients or real scanners. No
clinical MRI was used [C40].

## 2. Anatomical diversity

Anatomical diversity is strongly limited to the BrainWeb environment used: msles1,
msles2, msles3 and the normal phantom change the lesion load, and the noise levels and
seeds change the noise realization, but they do not form a cohort of independent
anatomies. The project therefore does not estimate inter-patient
variability or population-level performance. The reserved seed-2 test provides
unseen simulated noise realizations of the phantoms, not new independent human
anatomy [C41].

## 3. Ground-truth realism

The evaluation uses the crisp discrete BrainWeb label volume (label 10 = MS lesion),
which gives an exact voxel label for every position. Real lesion annotation involves
expert interpretation, boundary uncertainty and inter-rater variability. None of these
is represented, and no annotation uncertainty was measured [C42].

## 4. Acquisition and scanner diversity

All volumes are 1 mm isotropic, use the BrainWeb AI protocol (T1 and T2 sequences of
the pre-computed SBD database) and have 0 % intensity non-uniformity (rf0 / INU 0 %).
The following were **not evaluated**: other scanners, field strengths, pulse sequences
or sequence parameters, reconstruction pipelines, slice thickness or anisotropic
resolution, motion artifacts and intensity non-uniformity (bias field) [C43].

## 5. Intensity and contrast dependence

The method is intensity-driven: the brain mask and S2 depend on the T1 intensity
partition, the lesion threshold depends on the T2 intensity partition (TA) and on the
statistics of the WM-like T2 reference region (μref, σref). The thresholds are
automatic, but the **rule** that turns them into a decision (highest T2 class, lower
bound μref + 5σref) depends on the intensity distributions produced by the simulated
acquisition. Automatic thresholding is not acquisition invariance [C44].

## 6. Fixed normalization assumption

The frozen pipeline normalizes the raw volumes with a fixed 0..4095 → 0..1 mapping,
matching the BrainWeb raw representation. Application to arbitrary clinical DICOM /
NIfTI data would require a validated intensity preprocessing and normalization
strategy; the fixed BrainWeb normalization is not assumed to generalize [C45].

## 7. Lesion-load coverage

Three simulated lesion loads (mild, moderate, severe) and the lesion-free phantom were
evaluated. This exposed the most important failure mode of v3, but three BrainWeb
phantoms do not form a continuous or population-wide model of lesion burden, and the
mild / moderate / severe categories are simulated lesion-burden levels, not clinical
stages of multiple sclerosis [C46].

## 8. Noise robustness

Noise was varied from 0 % to 9 % on the pre-computed msles2 volumes (pn0–pn9), and at
0 % and 3 % on the custom phantoms. For v4, the noise trend (Recall falling to 0.332 at
9 %) comes from cases seen during development; the reserved test covers only 0 % and
3 % noise. v4 behaviour at high noise on unseen data was therefore not tested [C47].

## 9. Reserved-test size

The final v4 reserved test contains four conditions: normal_n0, normal_n3, msles1_n3
and msles3_n3, two of which are lesion-free variants of the same normal phantom, and
no moderate-load case. It provides independent post-freeze evidence for the targeted
failure modes (lesion-free and low-load FP control), but it is small and is not broad
external validation [C48].

## 10. Generalization and development / test asymmetry

**v4 development used seen data.** After Amendment A4 the cases pn0, pn1, pn3, pn5,
pn7, pn9 and custom seed-1 msles1 / msles2 / msles3 were used as development evidence
for v4 (EXP-060 selected k = 5 on them; EXP-061 was evaluated on them). Results on
these cases are in-sample, development-context evidence and not independent v4
validation; the reserved seed-2 set is the only independent post-freeze evidence
[C49].

**v3 / v4 evidence asymmetry.** v3 has an original prospective test on pn1 / pn5 /
pn7 / pn9 (Phase 97). v4 was developed with those cases already seen and has a
separate, smaller reserved test. Comparisons between v3 and v4 across all tables
therefore do not share the same methodological status. This is a consequence of the
sequential development history, not an error, and it is preserved explicitly in the
result tables [C50].

**No statistical population inference.** The experimental units are controlled
simulation conditions, not a patient cohort. No confidence intervals, p-values or
significance tests were computed, and none are claimed; the study is a deterministic
experimental / engineering validation [C51].

## 11. Algorithmic limitations of the classical method

The final method is a classical deterministic image-processing pipeline. This was a
methodological choice compatible with the course techniques, with clear advantages:
it is interpretable, reproducible, needs no training data, and each processing block
has a direct, testable role (Phase 99). Its limitations are equally direct: there is
no learned representation of lesion appearance, limited ability to model complex
tissue and lesion intensity distributions, one fixed rule across acquisition domains,
and a Precision / Recall balance that can only be moved by changing hand-designed
rules (as the v3 → v4 change and EXP-061 showed) [C52].

**Fixed k = 5.** The v4 floor removes the catastrophic FP failure, but makes the
segmentation more conservative. k = 5 was selected on the declared development set
(EXP-060, grid 3–6); it is not shown to be optimal outside the tested BrainWeb
settings and is not a universal threshold for MS lesions [C53].

**Slice-wise morphology.** The final diamond-1 opening is applied per axial slice, so
the morphological cleanup does not model the 3D lesion shape. The pipeline is not
purely 2D: filtering is 3D anisotropic diffusion, the brain mask uses 3D erosion /
selection / dilation, and evaluation and connected-component diagnostics are 3D [C54].

## 12. Small and weak lesions, and the hard S2 support

**Small / weak lesions.** The method is vulnerable to lesions that contain few voxels,
have limited T2 contrast, lie partly outside S2 or do not exceed the v4 floor. This is
reflected in the low Recall at mild load and high noise, in the many GT components
never touched by the prediction, and in the FN visible in the final figures [C55].
Lesion biology is not inferred from intensity.

**Hard S2 support.** Prediction is constrained to S2, so GT voxels outside S2 cannot be
recovered downstream; the fraction of GT inside S2 is an explicit Recall ceiling
(0.739 on msles1_n3, 0.800 on pn9). This is one of the most important structural
limitations. Phase 99 also showed that S2 was the strongest single source of FP
reduction; both sides of this trade-off are part of the design [C27].

## 13. Evaluation limitations

- **Specificity and class imbalance.** Non-lesion voxels dominate the volume, so
  Specificity remains very high even for poor segmentations (v3 on normal_n0: 0.9955
  with 31,917 FP voxels). The project therefore emphasizes Dice, Precision, Recall, FP,
  FN, volume error and lesion-wise diagnostics [C03].
- **Lesion-wise matching.** A GT lesion counts as detected if at least one predicted
  voxel overlaps it. Detected counts therefore do not mean complete segmentation, and
  can even increase when false positives spread (v3, pn7 / pn9). No object-level Dice,
  Hausdorff or boundary-distance metric was computed [C22].
- **Undefined metrics on lesion-free data.** On the normal phantom, Dice, IoU,
  Precision, Recall and volume error are undefined (NaN); FP voxels, false components
  and Specificity are reported instead [C02].
- **Display-slice selection.** Final 2D slices were selected by the maximum number of
  GT lesion voxels, for display only; they are representative lesion-containing views,
  not random slices, and do not represent average slice-level performance. The 3D
  figures show the complete masks and reduce this limitation [C56].

## 14. Software and reproducibility scope

Scientific reproducibility is documented: frozen tags for v3 and v4, SHA-256 manifests
for sources and results, and an automated runner that reproduces 26 / 26 predictions
voxel by voxel (Phase 103). Runtime was not measured (Phase 102 skipped): the project
makes no claim about real-time performance, workflow latency, computational efficiency
or deployment suitability; this is a scope limitation, not an accuracy weakness [C57].
Final software QA (consolidated assertions, a synthetic metric test, cleanup,
refactoring, constants and comment audit; Phases 110–115) is scheduled before
delivery and is a project-status item, not a scientific limitation [C58].

## 15. Future validation needs

Possible directions, none implemented in this project:

- evaluation on real clinical MRI with expert annotations, across several subjects;
- scanner, field-strength and sequence variability, including bias-field conditions;
- a validated intensity normalization for non-BrainWeb data;
- more independent reserved cases, including moderate load and high noise for v4;
- recovery of weak / small lesions without re-introducing FP explosion;
- adaptive support strategies that preserve the specificity of S2 while relaxing its
  hard Recall ceiling;
- carefully constrained volumetric growth or connectivity rules whose strength does
  not depend on per-condition tuning;
- runtime profiling, if deployment becomes relevant;
- optionally, a comparison with learning-based methods, as one possible reference
  rather than a required next step [C59].

## Conclusion

The results show reproducible behaviour on controlled BrainWeb simulations, including
an independent post-freeze reserved test of the final v4 pipeline, but they do not
establish clinical or population-level generalization. The method remains dependent on
the simulated MRI intensity distributions, on a fixed BrainWeb normalization, on a
hard anatomical support and on a fixed classical decision rule; its v4 operating point
favours false-positive control over sensitivity. Validation on independent real MRI
data and broader acquisition conditions is required before any conclusion about
clinical applicability can be drawn.
