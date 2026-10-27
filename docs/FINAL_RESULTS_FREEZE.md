# Final results freeze (Phase 118)

Date: 2026-10-17. Implementation: `experiments/phase118_120_final_results_package.m`.

The scientific evidence that enters the final report is now fixed. This is a
**scientific result freeze**, not the final repository-delivery tag (Phases 116–117
remain deferred until final repository preparation).

## Pipelines

| Role | Version | Configuration | Tag | Commit |
|---|---|---|---|---|
| **Final improved pipeline** | v4 | V4_K5: threshold = max(TA level 2, μref + 5·σref) | `v4-frozen` | `2525ddefacb21d58150db5a4b986e36919e8de3b` |
| Historical prospective reference | v3 | D3_M1_G0 | `v3-final-frozen` | `96b16124999a0d40f8df2c66b072fb3a38f10322` |

Both pipelines use T1 (brain mask and anatomical support S2) and T2 (lesion
intensity); modality in the tables = `T1 + T2`.

## Evidence hierarchy

The three groups are never mixed without an explicit label.

| Group | Label | Version | Cases | Status |
|---|---|---|---|---|
| A | **FINAL RESERVED TEST** (`FINAL_V4_RESERVED_TEST`) | v4 | normal_n0, normal_n3, msles1_n3, msles3_n3 (custom BrainWeb AI, seed 2) | reserved before the v4 freeze, evaluated once after it; primary evidence for v4 |
| B | **SEEN DURING v4 DEVELOPMENT** | v4 | pn0, pn1, pn3, pn5, pn7, pn9, custom seed-1 msles1 / msles2 / msles3 | seen directly or indirectly during v4 development (Amendment A4); not independent |
| C | **ORIGINAL v3 PROSPECTIVE TEST** (`HISTORICAL_V3_PROSPECTIVE_TEST`) | v3 | pn1, pn5, pn7, pn9 (Phase 97) | held out when v3 was frozen; its historical role is unchanged by later v4 use |

Phase 103 is reproducibility automation (26 / 26 predictions reproduced voxel by
voxel), not a new validation.

## Frozen scientific artifacts

All authoritative sources are listed with SHA-256 in
`results/metrics/phase118_final_results_source_manifest.csv`:

- v4 and v3 frozen source manifests and the Phase-96 freeze record;
- Phase 96 development reference, Phase 97 original v3 prospective test, Phase 100
  noise table;
- Phase 99 retrospective ablation (frozen);
- Phase 101 lesion-load experiment (frozen);
- v4 development evidence (D1 diagnostic, EXP-060, secondary comparison, EXP-061
  negative result);
- final v4 reserved-test results and the saved reserved v4 predictions;
- Phase 103 reproduction outputs (frozen);
- Phase 105–109 visualization outputs and indices (frozen as source artifacts);
- the existing result manifests (Phases 97, 98, 101, reserved test, 103, 105–107,
  108–109, brain context).

Raw MRI and GT files are not copied; they remain covered by the earlier manifests.

## Derived report package

Report tables (Phase 119) and the definitive figure set (Phase 120) are derived only
from these frozen sources and hashed separately in
`results/metrics/phase118_120_final_report_package_manifest.csv`
(scientific source → report derivative).

## What the freeze means

After Phase 118 it is not allowed to modify v4, create v5, change k or any
threshold, reinterpret the GT, replace predictions, change metric formulas, remove
cases, improve numbers for presentation, or alter the scientific CSVs.

Prose typos may be corrected. If a scientific result is found to be wrong, the
relevant scientific phase must be explicitly reopened; the package is never altered
silently.
