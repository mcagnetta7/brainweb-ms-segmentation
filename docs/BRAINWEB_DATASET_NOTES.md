# BrainWeb Dataset Notes

## 1. Purpose

This document records what the official BrainWeb Simulated Brain Database (SBD) offers for the multiple-sclerosis (MS) lesion segmentation project.

It is a research and documentation note, written before any project data is selected or downloaded (Phase 17).

The research sections (2–9) do NOT select:

- the MS phantom or simulated volumes to use;
- the MRI modality;
- the ground-truth representation;
- the development/test split;
- any processing parameter.

Project decisions taken after the research are recorded separately in Section 13.

Every statement is labelled as one of:

| Label | Meaning |
|---|---|
| **VERIFIED** | Stated explicitly by an official BrainWeb source (cited). |
| **INTERPRETATION** | Our reasoning or project implication, derived from verified facts but not stated by BrainWeb. |
| **UNRESOLVED** | Not clearly answered by the official sources; must be verified later, usually on the downloaded data. |
| **PROJECT DECISION** | A choice made by the project team (Section 13). It is not a BrainWeb fact. |

All sources were consulted on 2026-10-03.

> **VERIFIED** — BrainWeb states that the SBD "is still considered 'under development', both in terms of the anatomical model and the simulation itself. What you get today may not be the same as what you get tomorrow!" [S1]
>
> **INTERPRETATION** — The download date of every project file should be recorded, since the served data may change over time.

---

## 2. Official Sources

Only official BrainWeb pages hosted by the McConnell Brain Imaging Centre (MNI, McGill University) were used.

| ID | Source | URL |
|---|---|---|
| S1 | BrainWeb home page | https://brainweb.bic.mni.mcgill.ca/brainweb/ |
| S2 | MS Lesion Brain Database (selection form) | https://brainweb.bic.mni.mcgill.ca/brainweb/selection_ms.html |
| S3 | Anatomical Model of MS Lesion Brain ("moderate") | https://brainweb.bic.mni.mcgill.ca/brainweb/anatomic_ms.html |
| S4 | Anatomical Model of "mild" MS Lesion Brain | https://brainweb.bic.mni.mcgill.ca/brainweb/anatomic_ms1.html |
| S5 | Anatomical Model of "severe" MS Lesion Brain | https://brainweb.bic.mni.mcgill.ca/brainweb/anatomic_ms3.html |
| S6 | Details on Anatomical Model of MS Lesion Brain | https://brainweb.bic.mni.mcgill.ca/brainweb/anatomic_ms_details.html |
| S7 | Anatomical Model of Normal Brain | https://brainweb.bic.mni.mcgill.ca/brainweb/anatomic_normal.html |
| S8 | About the Simulated Brain Database | https://brainweb.bic.mni.mcgill.ca/brainweb/about_sbd.html |
| S9 | FAQ | https://brainweb.bic.mni.mcgill.ca/brainweb/faq.html |
| S10 | About Data Download Formats | https://brainweb.bic.mni.mcgill.ca/brainweb/about_data_formats.html |
| S11 | About the MRI Simulator | https://brainweb.bic.mni.mcgill.ca/brainweb/mri_sim.html |
| S12 | Tissue MR parameters | https://brainweb.bic.mni.mcgill.ca/brainweb/tissue_mr_parameters.txt |
| S13 | Custom MRI simulations request form | https://brainweb.bic.mni.mcgill.ca/cgi/bw/submit_request |
| S14 | Download page, discrete MS model | https://brainweb.bic.mni.mcgill.ca/cgi/brainweb2?alias=phantom_1.0mm_msles2_crisp&download=1 |
| S15 | Download page, fuzzy MS lesion map | https://brainweb.bic.mni.mcgill.ca/cgi/brainweb2?alias=phantom_1.0mm_msles2_wml&download=1 |
| S16 | Download pages, simulated MS MRI volumes | Reached by submitting the S2 form with "[Download]" (POST to `https://brainweb.bic.mni.mcgill.ca/cgi/brainweb2`); no static URL. Inspected for T1, T2 and PD at 1 mm, 3% noise, 20% INU, and for T2 at 5 mm. |

**Reproducing S16.** The S16 pages are generated dynamically. They were obtained with an HTTP POST to `https://brainweb.bic.mni.mcgill.ca/cgi/brainweb2` using the same fields as the S2 form:

```text
from_select=1
modality_value=T2          (also T1 and PD)
slice_value=1mm            (also 5mm, for T2 only)
noise_value=pn3
field_value=rf20
download=[Download]
```

Equivalent command (returns only the HTML download page, not image data):

```bash
curl -d "from_select=1&modality_value=T2&slice_value=1mm&noise_value=pn3&field_value=rf20&download=%5BDownload%5D" \
     https://brainweb.bic.mni.mcgill.ca/cgi/brainweb2
```

On 2026-10-03, the returned page for this query was titled "BrainWeb download: T2 AI msles2 1mm pn3 rf20" and stated "Modality=T2, Protocol=AI, Phantom_name=msles2, Slice_thickness=1mm, Noise=3%, INU=20%".
Manually selecting the same options in the S2 form and pressing "[Download]" should lead to the same page.

Download pages (S14–S16) were opened only to read the displayed volume information and the format options.
No image data was downloaded.

Publications cited by BrainWeb [S1, S11] (not consulted directly for this note):

- C.A. Cocosco, V. Kollokian, R.K.-S. Kwan, A.C. Evans, "BrainWeb: Online Interface to a 3D MRI Simulated Brain Database", NeuroImage 5(4), S425, 1997.
- R.K.-S. Kwan, A.C. Evans, G.B. Pike, "MRI simulation-based evaluation of image-processing and classification methods", IEEE TMI 18(11):1085–97, 1999.
- R.K.-S. Kwan, A.C. Evans, G.B. Pike, "An Extensible MRI Simulator for Post-Processing Evaluation", VBC'96, LNCS 1131, 135–140, 1996.
- D.L. Collins et al., "Design and Construction of a Realistic Digital Brain Phantom", IEEE TMI 17(3):463–468, 1998.

---

## 3. MS Phantom Inventory

### 3.1 Available MS anatomical models

**VERIFIED** — BrainWeb provides three MS anatomical models ("phantoms"), named by lesion load [S3, S4, S5, S13]:

| Official name | Internal phantom name | Discrete-model MS lesion volume (mm³) | Source |
|---|---|---:|---|
| "mild" MS lesions | `msles1` | 422 | S4 |
| "moderate" MS lesions | `msles2` | 3512 | S3 |
| "severe" MS lesions | `msles3` | 10104 | S5 |

**VERIFIED** — Only the "moderate" model was used to generate the pre-computed MS lesion database (available since January 1997). The "mild" and "severe" models "are only used for the BrainWeb custom MRI simulations". [S3, S4, S5]

**VERIFIED** — The MS lesions were "segmented from real scans" and "added to the 'Normal Brain' anatomical model [...], inside the White-Matter." [S6]

**VERIFIED** — BrainWeb also offers "Twenty normal anatomical models" [S1]. They are normal (non-MS) models.

**INTERPRETATION** — The three MS models appear to share the same underlying head anatomy, differing in lesion load. This is suggested by S6 and by the identical discrete-model volumes of background, fat, skin, skull and connective tissue across S3–S5. BrainWeb does not state this explicitly for each severity.

**INTERPRETATION** — Consequently, the three severities, and the different noise/INU levels of the same severity, are not independent subjects.

### 3.2 Pre-computed versus custom data

**VERIFIED** — The pre-computed MS SBD is fixed to "3 modalities, 5 slice thicknesses, 6 levels of noise, and 3 levels of intensity non-uniformity". Simulations with arbitrary parameters can be requested via the custom MRI simulations interface. [S2]

**VERIFIED** — The custom simulations form offers the phantoms "mild MS lesions", "moderate MS lesions", "severe MS lesions" and "normal". It asks for an e-mail address to notify the requester when the simulation is completed. [S13]

**INTERPRETATION** — Pre-computed MS data: 3 × 5 × 6 × 3 = 270 volume configurations, all based on the "moderate" phantom.

**UNRESOLVED** — The current availability and turnaround time of the custom simulation service. The form is online [S13], but no request has been made.

---

## 4. Anatomical and Lesion Ground Truth Data

### 4.1 Fuzzy tissue membership volumes

**VERIFIED** — Each anatomical model consists of "a set of 3-dimensional 'fuzzy' tissue membership volumes, one for each tissue class". Voxel values reflect "the proportion of tissue present in that voxel, in the range [0,1]". [S3, S4, S5]

**VERIFIED** — The fuzzy volumes listed for the MS models are: Background, CSF, Grey Matter, White Matter, Fat, Muscle / Skin, Skin, Skull, Glial Matter, Connective, MS Lesion. [S3, S4, S5]

**VERIFIED** — The fuzzy MS-lesion volume of the moderate model has alias `phantom_1.0mm_msles2_wml` and is described as "MS phantom, fuzzy, white matter lesions". Its MINC volume information is "unsigned byte 0 to 255". [S3, S15]

**VERIFIED** — The fuzzy phantom "was used to describe the tissue within each voxel during the simulation process." [S9]

### 4.2 Discrete (crisp) anatomical model

**VERIFIED** — A discrete model provides an integer class label per voxel, "representing the tissue which contributes the most to that voxel". The labels are: 0=Background, 1=CSF, 2=Grey Matter, 3=White Matter, 4=Fat, 5=Muscle/Skin, 6=Skin, 7=Skull, 8=Glial Matter, 9=Connective, 10=MS Lesion. [S3]

**VERIFIED** — The discrete moderate model has alias `phantom_1.0mm_msles2_crisp`, described as "MS phantom, discrete", with MINC volume information "unsigned byte 0 to 10". [S3, S14]

**VERIFIED** — "A discrete phantom was not used in the simulation process", but may be used "when comparing simulated data against the underlying tissue types". [S9]

**VERIFIED** — BrainWeb's guidance: if a method estimates partial volume (tissue fractions), "the fuzzy model is probably what you want. Otherwise, the discrete model will probably do..." [S9]

### 4.3 Candidate lesion ground truth

**INTERPRETATION** — Two official candidates exist for lesion ground truth:

1. the discrete model with label `10` (MS Lesion);
2. the fuzzy MS-lesion membership volume (`..._wml`), which would require an explicit and fixed binarization rule (PROJECT_SPEC.md, Section 3).

The choice is NOT made in this document.

**INTERPRETATION** — Because our project produces a binary mask, not tissue fractions, BrainWeb's own guidance [S9] points toward the discrete model. This is only an indication, not a decision.

**UNRESOLVED** — The meaning of the "Glial Matter" class (label 8) and its relationship to MS lesions. It appears in both the normal and MS models [S3, S7] and is not explained on the consulted pages.

**UNRESOLVED** — How the fuzzy lesion values in [0,1] map to the stored "unsigned byte 0 to 255" [S15], especially in raw format, where values are "scaled such that it will use the entire 0...255 range" [S10]. To be verified on downloaded data.

**UNRESOLVED** — Whether a discrete lesion label and the corresponding fuzzy lesion map agree voxel by voxel. To be verified on downloaded data.

### 4.4 Other anatomical data

**VERIFIED** — The intensity non-uniformity (INU) fields used for the simulations (field A, B, C, 20% version) can be downloaded. "For other INU levels, these fields are rescaled linearly." [S8]

**VERIFIED** — For the normal model, the fuzzy data set is also available for thicker slices (3, 5, 7, 9 mm) as tar files [S7, S9 "Are there anatomical models for thick slices too?"].

**UNRESOLVED** — The MS model pages [S3, S4, S5] list only 1 mm volumes. No thick-slice MS anatomical model was found on the consulted pages.

---

## 5. MRI Modalities

**VERIFIED** — The pre-computed MS database offers three modalities: `T1`, `T2`, `PD` (proton density). [S1, S2]

**VERIFIED** — The voxel values of the pre-computed images are "magnitude values, rather than complex, real or imaginary". [S2]

**VERIFIED** — Custom simulations offer the templates PD/T1/T2 × protocols AI/ICBM. They also offer scan techniques CEFAST, DSE_EARLY, DSE_LATE, FISP, FLASH, IR, SE and SFLASH, with editable TR, TI, flip angle and TE, and image types magnitude/real/imaginary. [S13, S9]

**VERIFIED** — The tissue MR parameters used by the simulator are published. [S12]

| Tissue (label) | T1 (ms) | T2 (ms) | T2* (ms) | PD |
|---|---:|---:|---:|---:|
| CSF (1) | 2569 | 329 | 58 | 1 |
| Grey matter (2) | 833 | 83 | 69 | 0.86 |
| White matter (3) | 500 | 70 | 61 | 0.77 |
| MS lesion (10) | 752 | 237 | 204 | 0.76 |

Other tissues are listed in S12. In S12, label 9 is named "MEAT", while S3 calls it "Connective".

**VERIFIED** — BrainWeb cannot provide the true per-tissue intensities of a simulated image, but suggests computing per-tissue histograms using the anatomical model. [S9]

**INTERPRETATION** — Relaxation parameters alone do not determine how lesions appear in a given image, which also depends on the pulse sequence. Lesion appearance per modality must be observed on the data (PROJECT_SPEC.md, Section 10).

### 5.1 Ambiguity: pulse-sequence protocol of the pre-computed data

**VERIFIED** — S8 states that the pre-generated SBD used the pulse sequence "as in the ICBM {T1,T2,PD} template of custom simulations".

**VERIFIED** — The download pages of the pre-computed MS volumes are titled, for example, "T2 AI msles2 1mm pn3 rf20" and state "Protocol=AI" for T1, T2 and PD. [S16]

**UNRESOLVED** — The two official sources disagree (ICBM versus AI). This is not resolved here. The query needed to reproduce the S16 page is recorded in Section 2.

---

## 6. Simulation Parameters

### 6.1 Pre-computed MS database

**VERIFIED** — Parameters and exact terminology of the selection form [S2]:

| BrainWeb term | Values | Form value codes |
|---|---|---|
| Modality | T1, T2, PD | `T1`, `T2`, `PD` |
| Slice thickness ("in-plane pixel size is always 1x1mm") | 1mm, 3mm, 5mm, 7mm, 9mm | `1mm` … `9mm` |
| Noise ("calculated relative to the brightest tissue") | 0%, 1%, 3%, 5%, 7%, 9% | `pn0` … `pn9` |
| Intensity non-uniformity ("RF") | 0%, 20%, 40% | `rf0`, `rf20`, `rf40` |

**VERIFIED** — Form defaults: T1, 1mm, 3% noise, 20% INU. [S2]

### 6.2 Noise

**VERIFIED** — Noise has "Rayleigh statistics in the background and Rician statistics in the signal regions". The percentage is "the percent ratio of the standard deviation of the white Gaussian noise versus the signal for a reference tissue". [S9]

**VERIFIED** — The Gaussian noise is added to the real and imaginary components before the magnitude is computed. [S9]

### 6.3 Ambiguity: noise reference tissue

**VERIFIED** — S2 says noise is "calculated relative to the brightest tissue". The FAQ section "How is the simulated noise calculated?" says the percentage is "relative to the average real and imaginary values of the overall brightest tissue class". [S2, S9]

**VERIFIED** — S8 and the FAQ section "What do you mean by '5% noise'?" say that for the pre-computed SBD the reference tissue was "White Matter for T1, and CSF for T2 and PD images". [S8, S9]

**UNRESOLVED** — These statements are not obviously consistent: the brightest tissue may or may not be the stated reference tissue. This is not resolved here.

### 6.4 Intensity non-uniformity (INU / "RF")

**VERIFIED** — "For a 20% level, the multiplicative INU field has a range of values of 0.90 ... 1.10 over the brain area", scaled linearly for other levels (for example 0.80 ... 1.20 for 40%). [S9]

**VERIFIED** — The INU fields "were estimated from real MRI scans". They "are not linear, but are slowly-varying fields of a complex shape". [S9]

**VERIFIED** — Pre-computed SBD: field A for T1, field B for T2, field C for PD. [S8]

### 6.5 Custom simulations

**VERIFIED** — Configurable parameters [S13]:

- Phantom (mild / moderate / severe MS, normal);
- template (PD/T1/T2, AI/ICBM);
- Slice thickness [mm] (range 1...10);
- Scan technique, TR, TI, Flip angle, Echo time(s);
- Image Type;
- Noise reference tissue (including "(brightest_tissue)", CSF, MS_lesion, grey_matter, white_matter and others);
- Noise level [%] (0...100);
- Random generator seed;
- INU field (A, B, C);
- INU ("RF") level [%] (-100...100).

**VERIFIED** — A non-zero random seed reproduces the same noise realization, while seed 0 gives different noise each time. [S9, S13]

---

## 7. Spatial Metadata

These values are documentation only.
They must NOT be placed in `config.m` and must be verified on each downloaded file.

**VERIFIED** — Anatomical models: "1mm isotropic voxel grid in Talairach space, with dimensions 181x217x181 (XxYxZ) and start coordinates -90,-126,-72 (x,y,z)." [S3, S4, S5]

**VERIFIED** — Volume information shown on the download pages [S14, S15, S16]:

| Volume | MINC image type | zspace (length / step / start) | yspace | xspace |
|---|---|---|---|---|
| Discrete MS model (`msles2_crisp`) | unsigned byte 0 to 10 | 181 / 1 / -72 | 217 / 1 / -126 | 181 / 1 / -90 |
| Fuzzy MS lesion (`msles2_wml`) | unsigned byte 0 to 255 | 181 / 1 / -72 | 217 / 1 / -126 | 181 / 1 / -90 |
| T1, T2, PD, 1mm, pn3, rf20 | signed short 0 to 4095 | 181 / 1 / -72 | 217 / 1 / -126 | 181 / 1 / -90 |
| T2, 5mm, pn3, rf20 | signed short 0 to 4095 | 36 / 5 / -72 | 217 / 1 / -126 | 181 / 1 / -90 |

**VERIFIED** — The dimension order is given as "zspace yspace xspace". [S10, S14–S16]

**VERIFIED** — "In-plane pixel size is always 1x1mm"; slice thickness changes only the Z sampling. [S2, S10]

**INTERPRETATION** — The site states dimensions, voxel steps and start coordinates. It does not explicitly state the anatomical meaning of each image axis (for example which axis is left–right) or the display orientation of a slice in MATLAB. These must be verified visually after download.

**UNRESOLVED** — The spatial metadata of configurations not inspected here (3, 7, 9 mm; other noise/INU levels). They are expected to follow the same pattern but were not checked.

---

## 8. File Formats and Download Mechanism

### 8.1 Download mechanism

**VERIFIED** — Pre-computed volumes are chosen through the selection form [S2]. Pressing "[Download]" opens a download page showing the volume information. That page offers [S14–S16]:

- **File format**: MINC (default), raw byte (unsigned), raw short (12 bit);
- **Compression**: none, gnuzip (default), bzip2;
- optional fields Name / Institution / E-mail ("we would appreciate it if you would provide us with the following information").

**VERIFIED** — Anatomical model volumes are downloaded through equivalent download pages linked from S3–S5.

**VERIFIED** — Custom simulations are requested through S13, and the requester is notified by e-mail when the simulation completes.

### 8.2 MINC

**VERIFIED** — MINC files "contain both data and header information". MINC was developed at the McConnell Brain Imaging Centre. [S10]

**VERIFIED** — BrainWeb lists EMMA as a package for "working with MINC files directly from Matlab", and notes that "some of the tools, such as EMMA, are no longer actively supported". [S10]

**UNRESOLVED** — Which MINC version (MINC1/netCDF or MINC2/HDF5) is served. This determines whether standard MATLAB functions can read the file. To be verified only if MINC is considered.

### 8.3 Raw formats

**VERIFIED** — Raw data is "just a long sequence of integers, with no header". The header information "is not downloaded, but just displayed at the top of the download page". [S10]

**VERIFIED** — Voxel order: "the 'X' coordinate changes fastest, and the 'Z' changes slowest". [S10]

**VERIFIED** — raw byte (unsigned): one byte per voxel, "scaled such that it will use the entire 0...255 range". Exception: crisp models are not scaled and contain values 0...10. [S10]

**VERIFIED** — raw short (12 bit): two bytes per voxel, scaled to 0...4095, with the same exception for crisp models. [S10]

**VERIFIED** — BrainWeb data is produced on a big-endian server. On little-endian machines (Intel PC), raw short data requires byte swapping. [S10]

> **Note added in Phase 22:** the raw short files actually downloaded on 2026-10-03 are little-endian. This documentation statement is legacy; see Section 13.5.4.

**INTERPRETATION** — For MATLAB loading, raw data needs:

- the dimensions and Z step copied from the download page;
- the correct data type;
- the correct byte order for raw short (documented as big-endian, but verified little-endian on the downloaded files, see Section 13.5.4);
- the X-fastest voxel order.

None of this is stored in the file, so the download-page information must be saved alongside each raw file (for example as a text note in `data/raw/`).

**INTERPRETATION** — Raw byte loses intensity precision compared with raw short (8 bit versus 12 bit), and both formats lose the original real-valued intensity scale.

---

## 9. MRI / Ground Truth Spatial Relationship

**VERIFIED** — The simulated MRI volumes are generated from the fuzzy anatomical model. [S9, S2: the simulations "are based on an anatomical model of a brain with MS lesions, which can serve as the ground truth"]

**VERIFIED** — For 1 mm volumes, the displayed grid of the MRI volumes (T1, T2, PD) is identical to that of the discrete and fuzzy MS models: same lengths, steps and start coordinates. [S14, S15, S16]

**INTERPRETATION** — For 1 mm volumes, MRI and anatomical model are therefore expected to be voxel-wise aligned without registration, because both come from the same simulation grid. BrainWeb does not state this in so many words.

**INTERPRETATION** — For thick-slice MRI volumes (for example 5 mm: 36 slices, step 5), the grid differs from the 1 mm anatomical model. No thick-slice MS anatomical model was found (Section 4.4), so a direct voxel-wise comparison would require an explicit resampling rule.

**UNRESOLVED** — To be verified after download:

- that MRI and ground-truth arrays have identical dimensions;
- that lesions overlay correctly on the MRI (visual check);
- that orientation and axis order are interpreted identically for MRI and ground truth;
- that the three modalities are aligned with each other.

> **Update (Phase 28, Section 13.7.4):** verified for the downloaded 1 mm `pn0` `rf0` data. The four volumes are voxel-wise aligned. Only the left/right direction of the X axis remains unresolved.

---

## 10. Implications for Our Project

All points in this section are **INTERPRETATION**.

1. **Pre-computed data use one lesion configuration.** All pre-computed MS volumes come from the "moderate" phantom. Using "mild" or "severe" requires custom simulations.
2. **Independence of cases.** Different noise, INU or slice-thickness configurations share the same anatomy and lesions. This is handled by the development/test protocol defined in Phase 36; see Section 13.14 and PROJECT_SPEC.md, Section 19.1.
3. **Ground truth on the 1 mm grid.** The consulted MS anatomical-model pages provide 1 mm volumes; no thick-slice MS anatomical model was identified (Section 4.4). Configurations with 1 mm slices avoid resampling the ground truth.
4. **Raw format is self-contained only with the download-page header.** If raw is chosen, the header text must be preserved alongside the file.
5. **Endianness.** The documentation [S10] describes raw short files as big-endian, but the files actually downloaded are little-endian (Section 13.5.4). The byte order must be taken from the verified files, not from the documentation.
6. **Ground truth stays evaluation-only.** Neither the discrete nor the fuzzy model may be used by the segmentation (PROJECT_SPEC.md, Section 3). This includes the anatomical classes, pending the open question on the brain mask (PROJECT_SPEC.md, Section 27.1).
7. **2D slice-wise processing.** The data are 3D volumes. Slice extraction must follow the verified axis order (ALLOWED_TECHNIQUES.md, Section 2.1).
8. **No real clinical data.** BrainWeb data are simulated, consistent with README.md and PROJECT_SPEC.md, Section 26.

---

## 11. Open Questions

1. ~~Which MS phantom(s) to use.~~ Primary phantom decided in Phase 18: "moderate" (`msles2`), see Section 13.1. Still open: whether and when to add "mild"/"severe" through custom simulations as later extensions.
2. ~~Which modality, or combination, for the baseline.~~ Decided in Phase 41 (Section 13.18): T2 is the initial, provisional baseline modality, to be re-checked when `pn3` enters development. Multimodal processing remains open.
3. ~~Which ground-truth representation: discrete label 10 or fuzzy lesion map with a binarization rule.~~ Decided in Phase 20: discrete model, label 10 (Section 13.3).
4. Meaning of the "Glial Matter" class and whether it relates to lesions. Not needed for the core pipeline: anatomical labels are excluded from the brain mask (Phase 48, Section 13.26).
5. Mapping between stored fuzzy values (0–255) and membership fractions [0,1]. Relevant only if the optional fuzzy supplementary analysis is performed.
6. Agreement between discrete and fuzzy lesion representations. Relevant only if the optional fuzzy supplementary analysis is performed.
7. Pre-computed pulse-sequence protocol: ICBM [S8] versus AI [S16].
8. Noise reference tissue of the pre-computed data: "brightest tissue" [S2, S9] versus WM/CSF [S8, S9].
9. ~~Which download format to prefer: MINC, raw byte or raw short.~~ Decided in Phase 22: raw short for MRI, raw byte for the ground truth, no compression (Section 13.5).
10. MINC version served, if MINC is considered.
11. ~~Axis-to-anatomy correspondence~~ Mostly resolved in Phases 27–28 (Section 13.7.3): axial/coronal/sagittal mapping, anterior (+j) and superior (+k) verified. Still open: left/right direction of +i, and slice display orientation for figures.
12. Whether thick-slice MS anatomical models exist anywhere on the site.
13. ~~Which slice thickness, noise and INU levels to use.~~ Initial configuration decided: 0% noise (`pn0`, Phase 21, Section 13.4), 0% INU (`rf0`) and 1 mm slices (Phase 22, Section 13.5). Still open: INU levels for any later experiment.
14. ~~Development/test strategy, given that configurations share the same anatomy.~~ Resolved in Phase 36: PROJECT_SPEC.md, Section 19.1 (summary in Section 13.14).
15. ~~Non-zero noise configurations for the robustness extension.~~ Resolved in Phase 36: `pn3` is development; `pn1`, `pn5`, `pn7`, `pn9` are held-out (Section 13.14).
16. Current availability of the custom simulation service.
17. Cross-condition intensity harmonization, and the transfer of intensity-dependent parameters between `pn0` and `pn3` (and later the held-out conditions). Raised in Phase 45 (Section 13.22.2); not resolved by the Phase 44 normalization (Section 13.21).

---

## 12. Decisions Explicitly NOT Made Yet

- Additional simulated configurations outside the Phase 36 development/test protocol (Section 13.14).
- Whether and when to use the "mild" and "severe" phantoms as extensions.
- Use of multimodal processing and any fusion rule (the initial baseline modality is T2, see Section 13.18).
- Simulation configuration used for the modality comparison.
- Whether to perform the optional fuzzy-WML supplementary analysis, and any fuzzy binarization rule (the primary ground truth is decided, see Section 13.3).
- INU levels for any additional robustness experiment (the core protocol uses `rf0`, see Section 13.14).
- Any preprocessing, thresholding or other algorithm parameter.
- Any change to `config.m`.

---

## 13. Project Decisions

This section records choices made by the project team after the Phase 17 research.

They are **PROJECT DECISIONS**, not facts stated by BrainWeb.

The research findings in Sections 2–9 remain unchanged.

### 13.1 Primary MS phantom (Phase 18)

**PROJECT DECISION** — The primary MS phantom for the core project is:

```text
"moderate" MS lesions
BrainWeb internal name: msles2
```

**Reason (practical and methodological):**

- The "moderate" phantom is the one used by the pre-computed MS database (Section 3.1, [S3]).
- It therefore gives access to the official pre-generated MRI configurations (Section 6.1) without depending on the custom simulation service, whose current availability is unresolved (Section 3.2).

The choice is NOT based on any BrainWeb claim that the "moderate" phantom is inherently better than the others.

**Scope:**

- The "mild" (`msles1`) and "severe" (`msles3`) phantoms are not excluded permanently.
- They remain possible later robustness/generalization extensions, to be considered only after the core segmentation pipeline is stable.

**INTERPRETATION** — With a single primary phantom, all core-project data share the same anatomy and the same lesions (Section 10, point 2). This is relevant to the development/test strategy. At Phase 18 this remained undecided; it was later resolved in Phase 36 (Section 13.14).

**Not decided by this choice:**

- MRI modality (T1, T2, PD or combinations);
- ground-truth representation;
- noise level;
- intensity non-uniformity ("RF") level;
- slice thickness;
- download format;
- development/test split;
- preprocessing or segmentation parameters.

### 13.2 MRI modality selection strategy (Phase 19)

**PROJECT DECISION** — The initial exploratory analysis of the primary phantom (`msles2`) will include all three modalities available in the pre-computed MS database [S2]:

```text
T1
T2
PD
```

This is NOT a decision to use the three modalities simultaneously in the segmentation algorithm.

**Strategy:**

- T1, T2 and PD will initially be studied separately.
- When comparing modalities, the same simulation configuration (slice thickness, noise level, INU level) should be used for all three, so that the modality is the main changing factor.
- The objective is to compare their actual image and lesion-intensity characteristics on the data.
- The baseline modality will be selected only after actual data inspection.

**Reason:** PROJECT_SPEC.md (Sections 2, 10 and 15) requires the modalities to be analyzed separately before choosing a modality or a multimodal approach. Section 5 of this document shows that lesion appearance cannot be inferred from the published tissue parameters alone.

**INTERPRETATION** — Even with identical nominal settings, the pre-computed modalities are not simulated under perfectly identical conditions. The noise reference tissue differs (White Matter for T1, CSF for T2 and PD), and so does the INU field (A for T1, B for T2, C for PD) [S8, S9; see also the ambiguity in Section 6.3]. These differences should be kept in mind when interpreting the comparison.

**Still undecided:**

- baseline MRI modality;
- multimodal processing;
- any fusion rule (none may be introduced at this stage);
- the simulation configuration used for the comparison (slice thickness, noise, INU; the noise level was decided later, in Phase 21, see Section 13.4);
- ground-truth representation (decided later, in Phase 20, see Section 13.3) and download format.

No modality is currently considered superior.

### 13.3 Primary lesion ground truth (Phase 20)

**PROJECT DECISION** — The primary lesion ground truth is the official BrainWeb discrete (crisp) anatomical model of the primary phantom:

```text
Model:        discrete (crisp) anatomical model of msles2
BrainWeb alias: phantom_1.0mm_msles2_crisp
Lesion class: label 10 = MS Lesion
Binary ground truth: M_GT = 1 where label == 10, 0 elsewhere
```

The alias, label meaning and value range are from Sections 4.2 and 7 [S3, S14].

**Reason:**

- The project produces a binary lesion mask, not partial-volume (tissue-fraction) estimates.
- BrainWeb indicates that the fuzzy model is appropriate for methods that estimate tissue fractions, "otherwise, the discrete model will probably do" [S9]. It also states that the discrete model may be used "when comparing simulated data against the underlying tissue types" [S9].
- The discrete model avoids introducing an arbitrary binarization threshold for the fuzzy lesion membership map.

**Fuzzy WML map:** the fuzzy MS-lesion map (`phantom_1.0mm_msles2_wml`) is NOT selected as the primary ground truth. It remains available only for a possible later supplementary analysis. No fuzzy-membership binarization rule is defined.

**Ground-truth policy** (consistent with PROJECT_SPEC.md, Section 3):

- The ground truth is evaluation and visualization data only.
- No segmentation stage may use it as input. The segmentation pipeline operates only on the MRI data.
- It must NOT be used to generate the predicted segmentation, create the brain mask, select seeds, remove candidate regions, or manually correct the prediction.
- It must NOT be used to determine thresholds or tune any parameter (including morphology) on final test data.
- Comparing configurations on development data through evaluation metrics against the ground truth remains allowed, as defined in PROJECT_SPEC.md, Section 19, and EXPERIMENT_LOG.md, Section 7.

**INTERPRETATION** — Each discrete label marks the tissue "which contributes the most to that voxel" [S3]. Voxels where the lesion is present but not dominant are therefore not labelled 10. Small lesions and lesion borders may be represented more conservatively than in the fuzzy map. Against the selected ground truth, such voxels are still counted as false positives or false negatives by the metrics. However, a discrepancy there may also depend on how the reference is defined, and does not necessarily reflect an intrinsic failure of the algorithm.

**Still to be verified on the downloaded data** (Section 4.3):

- that label 10 is present and spatially plausible;
- the meaning of label 8 ("Glial Matter") and whether it relates to lesions;
- the agreement between label 10 and the fuzzy lesion map, only if the supplementary analysis is later performed.

**Not decided by this choice:**

- baseline MRI modality;
- noise level, INU level and slice thickness;
- download format;
- development/test split;
- any segmentation parameter.

**INTERPRETATION** — The discrete model is provided on the 1 mm grid (Sections 4.4 and 9). If thick-slice MRI configurations were ever selected, comparing them with this ground truth would require an explicit resampling rule.

### 13.4 Initial noise level (Phase 21)

**PROJECT DECISION** — The initial MRI configuration, used for the exploratory modality analysis and for the development of the core segmentation pipeline, uses:

```text
Noise level:    0%
BrainWeb code:  pn0
```

The value and code are among the officially available pre-computed options (Section 6.1, [S2]).

The 0% noise level applies consistently to T1, T2 and PD during the initial modality comparison (Section 13.2).

**Reason:**

- The first version of the pipeline should be developed and understood under the cleanest available BrainWeb condition.
- At this stage the project studies MRI characteristics, lesion appearance, modality differences and the behavior of the classical image-processing pipeline.
- Using 0% noise isolates the core pipeline from the noise variable, so that noise is not introduced as an additional experimental factor at the same time.

**Scope:**

- This does NOT mean that the final project will only use noise-free data.
- Noise robustness remains a later experimental extension (PROJECT_SPEC.md, Section 21).
- The other officially available noise levels (1%, 3%, 5%, 7%, 9% [S2]) may later be used to evaluate degradation and robustness once the core pipeline is stable.
- The exact subset of non-zero noise levels for that study is NOT decided.

**INTERPRETATION** — Consequences to keep in mind:

1. **Noise-reference ambiguity.** At 0% noise, the noise-reference ambiguity of Section 6.3 does not affect the initial data. It becomes relevant again for the robustness study.
2. **Background and preprocessing.** BrainWeb models noise as Rayleigh in the background and Rician in signal regions [S9]. Without noise, background and tissue intensities may appear cleaner than in any noisy configuration. Operations that work on noise-free data, for example brain-mask extraction or global thresholds, may behave differently once noise is added. This is precisely what the robustness study must measure. Under PROJECT_SPEC.md, Section 8, a filter cannot be justified on noise-free data by a noise-related problem.
3. **Parameter transfer and data separation.** PROJECT_SPEC.md, Section 21, states that parameters should not be retuned for each noise level. Parameters developed at 0% noise will therefore be applied unchanged to the noisy configurations. At Phase 21, how noisy configurations relate to the development/test split remained open. It was later resolved in Phase 36 (Section 13.14): `pn3` was added to development, and `pn1`, `pn5`, `pn7`, `pn9` became held-out.

**Not decided by this choice:**

- initial INU ("RF") level;
- slice thickness;
- download format;
- baseline MRI modality;
- multimodal processing;
- preprocessing filters;
- segmentation thresholds or other parameters;
- development/test split;
- non-zero noise levels for the robustness extension.

### 13.5 Initial dataset download (Phase 22)

This subsection uses four labels:

| Label | Meaning |
|---|---|
| **PROJECT DECISION** | Choice made by the project team. |
| **VERIFIED FROM DOWNLOAD PAGE** | Shown on the official BrainWeb download page or in the HTTP response when the file was served. |
| **VERIFIED FROM ACTUAL FILE** | Checked directly on the downloaded binary files. |
| **STILL TO BE VERIFIED** | Must be checked by inspecting the file contents in a later phase. |

#### 13.5.1 Download configuration

**PROJECT DECISION** — In addition to Sections 13.1–13.4, the initial clean dataset uses:

```text
INU ("RF") level:   0%  (BrainWeb code rf0)
Slice thickness:    1 mm
MRI file format:    raw short (12 bit)
GT file format:     raw byte (unsigned)
Compression:        none
```

**PROJECT DECISION** — Exactly four files were downloaded: the T1, T2 and PD volumes of `msles2` at 1 mm, `pn0`, `rf0`, and the discrete `msles2` model. The fuzzy WML map, noisy or INU configurations, thick slices, other phantoms and custom simulations were NOT downloaded.

#### 13.5.2 Download procedure

- Download date: 2026-10-03.
- Server: `https://brainweb.bic.mni.mcgill.ca/cgi/brainweb2` (official BrainWeb).
- MRI volumes: S2 form fields `modality_value`, `slice_value=1mm`, `noise_value=pn0`, `field_value=rf0`, followed by the download form with `format_value=raw_short` and `zip_value=none`.
- Ground truth: S14 download page (`alias=phantom_1.0mm_msles2_crisp`), followed by the download form with `format_value=raw_byte` and `zip_value=none`.
- The optional Name / Institution / E-mail fields were left empty.
- Files were saved under the names given by the server and were not modified.

#### 13.5.3 Files obtained

Stored under `data/raw/msles2/`, which is excluded from Git. A local copy of this record is in `data/raw/msles2/DOWNLOAD_INFO.txt`.

| File | Location | Configuration (download-page title) | Bytes | SHA-256 |
|---|---|---|---:|---|
| `t1_ai_msles2_1mm_pn0_rf0.raws` | `data/raw/msles2/mri/` | T1 AI msles2 1mm pn0 rf0 | 14218274 | `c94e3bb8d0df62c4d52b5a7eaff0673f73e828a345d2ff8ee3feee8bd3a91fd0` |
| `t2_ai_msles2_1mm_pn0_rf0.raws` | `data/raw/msles2/mri/` | T2 AI msles2 1mm pn0 rf0 | 14218274 | `113ebc5e1ba1e57fe4b5f6fd2686f1b869023615b54191dd31f4eee6a1362071` |
| `pd_ai_msles2_1mm_pn0_rf0.raws` | `data/raw/msles2/mri/` | PD AI msles2 1mm pn0 rf0 | 14218274 | `956de7a09f8b058eb84395ec48c5e660e31b6ea59abe4a2765192203be936497` |
| `phantom_1.0mm_msles2_crisp.rawb` | `data/raw/msles2/ground_truth/` | phantom_1.0mm_msles2_crisp ("MS phantom, discrete") | 7109137 | `d1c0270a8fb27a5ba8364a885fe83f701441171f0b3474fdd0fc0ec8ae6ae06b` |

**VERIFIED FROM DOWNLOAD PAGE** — For each MRI volume the page states "Modality=<T1|T2|PD>, Protocol=AI, Phantom_name=msles2, Slice_thickness=1mm, Noise=0%, INU=0%" and "image: signed__ short 0 to 4095". The ground-truth page states "MS phantom, discrete" and "image: unsigned byte 0 to 10". All four pages show the same grid: zspace 181 / 1 / -72, yspace 217 / 1 / -126, xspace 181 / 1 / -90, in the order "zspace yspace xspace".

**VERIFIED FROM DOWNLOAD PAGE** — Each file was served with HTTP 200 and `Content-Type: application/octet-stream`. The filenames above come from the server's `Content-Disposition` header.

**VERIFIED FROM ACTUAL FILE** — All four files exist and are non-empty. Their sizes are consistent with a complete volume on the documented grid (181 × 217 × 181), and there is no evidence of truncation. File size alone, however, is not absolute proof of content integrity.

**VERIFIED FROM ACTUAL FILE** — The SHA-256 checksums above were computed on the downloaded files and later re-checked successfully.

**VERIFIED FROM ACTUAL FILE** — Read-only inspection on 2026-10-03:

| Property | Result |
|---|---|
| Total voxels per file | 7,109,137 (= 181 × 217 × 181) |
| MRI bytes per voxel | 2 |
| Ground-truth bytes per voxel | 1 |
| MRI byte order | little-endian (see Section 13.5.4) |
| MRI value range (T1, T2, PD, read as little-endian) | 0 … 4095 |
| Ground-truth value range | 0 … 10 |
| Label 10 (MS Lesion) present | yes, 3,512 voxels |

**VERIFIED FROM ACTUAL FILE** — Voxel count per ground-truth label:

| Label | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Voxels | 3001960 | 371988 | 903198 | 671323 | 146516 | 617499 | 726649 | 362561 | 5581 | 298350 | 3512 |

These counts match exactly the per-class volumes (mm³) of the discrete model published on S3 (Section 3.1). At 1 mm³ per voxel, this confirms that the file is the official `msles2` discrete model.

#### 13.5.4 Discrepancies and ambiguities

- **Byte order of the MRI files.** The BrainWeb format page states that raw short data is produced on a "big-endian" server and must be byte-swapped on Intel PCs [S10]. The actual downloaded files are **little-endian**. Read as little-endian, all three volumes span the documented range 0…4095. Read as big-endian, values reach 65295, incompatible with 12-bit data. The documentation statement is therefore treated as legacy and does not describe the files served on 2026-10-03.
- The served files report "Protocol=AI", consistent with the earlier observation in Section 5.1. The ICBM-versus-AI ambiguity remains unresolved.
- No discrepancy between the requested and the served configuration was observed.

#### 13.5.5 Still to be verified (file-inspection phase)

**STILL TO BE VERIFIED:**

- anatomical meaning of the dimension order (X fastest, Z slowest, as documented) and correct reshaping;
- axis orientation and slice display orientation;
- spatial plausibility of label 10 (location of the lesions);
- alignment between the three modalities, and between MRI and ground truth.

> **Update (Phases 25–28, Section 13.7):** all items above were verified, except the left/right direction of the X axis and the display orientation for figures.

No loader has been implemented and `config.m` has not been updated.

### 13.6 Verified file format (Phase 24)

This subsection records the binary file format only.

All checks were read-only and treated each file as a one-dimensional byte stream. No reshaping, visualization or spatial analysis was performed. The SHA-256 checksums of Section 13.5.3 were re-checked after the inspection and are unchanged.

Sources are distinguished as:

- **DOC**: BrainWeb documentation [S10];
- **PAGE**: download-page information [S14, S16];
- **FILE**: verified on the actual downloaded files (2026-10-03).

#### 13.6.1 Size and voxel count

| Item | Value | Source |
|---|---|---|
| Documented dimensions | X = 181, Y = 217, Z = 181 | DOC, PAGE |
| Expected voxel count | 181 × 217 × 181 = 7,109,137 | computed |
| MRI file size (each of T1, T2, PD) | 14,218,274 bytes = 7,109,137 × 2 | FILE |
| Ground-truth file size | 7,109,137 bytes = 7,109,137 × 1 | FILE |

No discrepancy between dimensions, file size and bytes per voxel.

#### 13.6.2 MRI files (`.raws`)

| Aspect | Value | Source |
|---|---|---|
| BrainWeb format name | "raw short (12 bit)", scaled to 0…4095 | DOC, PAGE |
| Download-page value range | "signed__ short 0 to 4095" | PAGE |
| Documented byte order | big-endian | DOC (legacy, see below) |
| File extension | `.raws` | FILE |
| Bytes per voxel | 2 | FILE |
| Binary representation required | 16-bit integer, **little-endian** | FILE |
| Signedness | All values are non-negative and ≤ 4095, so signed (int16) and unsigned (uint16) little-endian readings give identical values | FILE |

**FILE** — Byte-order check on each MRI file:

| File | Little-endian range | Big-endian range (uint16) | Values > 4095 if read big-endian |
|---|---|---|---:|
| T1 | 0 … 4095 | 0 … 65295 | 4,634,772 |
| T2 | 0 … 4095 | 0 … 65295 | 5,723,125 |
| PD | 0 … 4095 | 0 … 65295 | 5,627,203 |

Read as little-endian, all three files have no negative values and no values above 4095. This is compatible with the documented 12-bit range. Read as big-endian, the values are incompatible with it.

**FILE** — These three specific files, downloaded on 2026-10-03, are little-endian. This confirms the Phase 22 finding (Section 13.5.4). It is NOT generalized to other BrainWeb raw files. The DOC statement (big-endian) is preserved in Section 8.3 as historical documentation.

#### 13.6.3 Ground-truth file (`.rawb`)

| Aspect | Value | Source |
|---|---|---|
| BrainWeb format name | "raw byte (unsigned)", crisp models not scaled (0…10) | DOC |
| Download-page value range | "unsigned byte 0 to 10" | PAGE |
| File extension | `.rawb` | FILE |
| Bytes per voxel | 1 | FILE |
| Binary representation | unsigned 8-bit integer (byte order not applicable) | FILE |
| Observed range | 0 … 10 | FILE |
| Unique labels present | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 (11 labels) | FILE |
| Voxels with label 10 | 3,512 (same as Phase 22) | FILE |

#### 13.6.4 Metadata required by a future loader

- File path and the expected byte count.
- Element type: 16-bit integer, little-endian (MRI); unsigned 8-bit (ground truth).
- Documented dimensions: X = 181, Y = 217, Z = 181.
- Documented storage order: "the 'X' coordinate changes fastest, and the 'Z' changes slowest" (DOC).

How MATLAB should reshape or permute the stream, the meaning of the array dimensions, and image or anatomical orientation are NOT decided in Phase 24.

#### 13.6.5 Unresolved file-format issues

None. The only open documentation conflict for these files is the byte order, already resolved on the actual files as little-endian.

### 13.7 Phases 25–28: dimensions, spacing, orientation, alignment

Labels used in this section:

- **META**: official BrainWeb metadata (download pages S14, S16; S3);
- **FILE**: verified on the downloaded files;
- **CONVENTION**: internal project convention;
- **UNRESOLVED**.

All checks were read-only. They used temporary Python/numpy scripts in a scratchpad outside the repository, deleted afterwards. A temporary 3D reconstruction was used only for Phases 27–28. No loader was written.

#### 13.7.1 Phase 25 — Verified dimensions

**FILE** — Every file holds 7,109,137 samples. Dividing by 181 × 217 gives exactly 181.

**FILE** — The dimensions were also verified from the stream content itself, not only from the product. For each file, the mean absolute difference between samples at distance *s* is minimal at:

- *s* = 181 among strides 170–194, so rows have 181 samples;
- *s* = 181 × 217 = 39,277 among multiples 181 × 210 … 181 × 224, so planes have 181 × 217 samples.

This holds for T1, T2, PD and GT separately. Wrong row lengths (180, 182) or plane sizes (181 × 216, 181 × 218) give clearly larger differences.

**Result:**

| | T1 | T2 | PD | GT |
|---|---|---|---|---|
| Fastest dimension length | 181 | 181 | 181 | 181 |
| Middle dimension length | 217 | 217 | 217 | 217 |
| Slowest dimension length (number of slices) | 181 | 181 | 181 | 181 |
| Total voxels | 7,109,137 | 7,109,137 | 7,109,137 | 7,109,137 |
| Consistent with META (xspace 181, yspace 217, zspace 181) | yes | yes | yes | yes |

#### 13.7.2 Phase 26 — Verified voxel spacing

**META** — For all four files the download pages list a step of 1 for xspace, yspace and zspace, with starts -90 (x), -126 (y), -72 (z). The selected configuration is "Slice_thickness=1mm", and "in-plane pixel size is always 1x1mm" [S2]. The anatomical model is "1mm isotropic" [S3].

**FILE** — Independent cross-check: the voxel count of each GT label equals the per-class volume in mm³ published on S3 (Section 13.5.3). This holds only if one voxel is 1 mm³.

**Result:**

```text
Spacing (X, Y, Z):  1 mm, 1 mm, 1 mm
Voxel volume:       1 mm^3
```

These are matrix-independent physical quantities. Coordinate starts and orientation are recorded separately (13.7.3). No lesion-volume metric was computed.

#### 13.7.3 Phase 27 — Orientation and internal axis convention

**META / DOC** — In the raw stream, "the 'X' coordinate changes fastest, and the 'Z' changes slowest" [S10]. The download pages list dimensions in the order "zspace yspace xspace" (slowest to fastest), all with positive step.

**FILE** — The stride analysis of 13.7.1 confirms this order: fastest 181 (X), middle 217 (Y), slowest 181 (Z).

**CONVENTION** — Internal MATLAB array convention for all later code:

```text
V(i, j, k)
  dim 1 = i = X  (181)   raw fastest
  dim 2 = j = Y  (217)
  dim 3 = k = Z  (181)   raw slowest
```

MATLAB is column-major, so reading the stream and reshaping it to `[181 217 181]`, without permute, gives this layout directly.

**FILE (MATLAB)** — Verified with a temporary, read-only check run in MATLAB R2026b (no files written, no loader created):

- T1 read with `fread(..., 'uint16=>uint16')` as `ieee-le` and reshaped to `[181 217 181]`: 7,109,137 samples, size `[181 217 181]`, range 0…4095.
- For 1,000 random voxels, `V(i,j,k)` equals stream element `i + 181*(j-1) + 181*217*(k-1)`.
- GT reshaped the same way: 3,512 voxels with label 10, spanning dim 1 = 37–126, dim 2 = 77–188, dim 3 = 33–118. The dim-3 slice with most label-10 voxels is k = 102.
- These values are identical to those of the numpy (column-major) reconstruction used for the visual identification of the views. The MATLAB layout is therefore the verified layout.

**CONVENTION** — World coordinates in mm (from META starts and steps, MATLAB 1-based indices):

```text
x = -90  + (i - 1)
y = -126 + (j - 1)
z = -72  + (k - 1)
```

**FILE** — Views identified by temporary visual inspection of central slices of T1, T2, PD and GT:

| View | Fixed index | Image plane |
|---|---|---|
| Axial | k (dim 3) | dim 1 × dim 2 |
| Coronal | j (dim 2) | dim 1 × dim 3 |
| Sagittal | i (dim 1) | dim 2 × dim 3 |

**FILE** — Anatomical directions established visually:

- **Increasing j (Y) points anterior**: frontal lobes and face at high j; occipital lobe and cerebellum at low j.
- **Increasing k (Z) points superior**: vertex at high k; skull base and neck at low k.
- The sagittal slice at i = 91 (x = 0) shows the corpus callosum and the midline structures, consistent with the documented x start of -90.

**UNRESOLVED** — The left/right direction of increasing i (X) cannot be proven from the images, because the phantom is nearly symmetric and has no laterality marker. The standard Talairach convention (+x = right) would imply that increasing i points right. This is an **INTERPRETATION**: BrainWeb states "Talairach space" [S3] but does not state the axis directions explicitly.

**Not decided here:** the display orientation (transposition and flips) of slices in figures. It belongs to the visualization phases. During inspection, slices were shown transposed with the origin at the bottom, for inspection only.

#### 13.7.4 Phase 28 — Verified alignment

**META** — T1, T2, PD and the GT share identical grid definitions on the download pages: same lengths, steps 1/1/1 and starts -90/-126/-72, in the same dimension order.

**FILE** — Structural compatibility: identical dimensions (13.7.1), identical spacing (13.7.2), same storage order (13.7.3).

**FILE** — Spatial correspondence was tested for integer shifts of -2 to +2 voxels along each axis (125 combinations):

| Test | Result |
|---|---|
| MRI–MRI: correlation of 3D gradient magnitude (T1–T2, T1–PD, T2–PD) | maximum at shift (0, 0, 0) for all pairs |
| MRI–GT: mean MRI gradient on GT tissue-label boundaries (T1, T2, PD) | maximum at shift (0, 0, 0) for all three |
| MRI support (value > 0) vs GT non-background | not informative: at pn0 most MRI background voxels are non-zero (only 4.6–8.1 % are 0), and the scores were flat across small shifts |

**FILE** — Limited visual check: an axial slice (k = 102) with GT contours overlaid on T1, T2 and PD.

- CSF contours (label 1) follow the ventricles and sulci in all three modalities.
- Lesion contours (label 10) lie in periventricular white matter.
- Of the 6-neighbours of lesion voxels, 76.7 % are white matter (label 3), 9.1 % CSF, 8.1 % grey matter and 6.0 % glial matter (label 8).

The GT was used only for this spatial validation.

**Conclusion:**

- T1, T2, PD and the GT are on the same grid and voxel-wise aligned, with no detectable integer-voxel offset.
- They can be treated as voxel-wise aligned in the project, without registration, for this 1 mm `pn0` `rf0` configuration.
- Sub-voxel misregistration is not tested, and is not expected for data simulated on the same phantom grid.

**Remaining uncertainty:** the left/right direction of i (13.7.3). It does not affect alignment, since all four volumes share the same storage order.

### 13.8 Phases 29–30: BrainWeb loader

#### 13.8.1 Phase 29 — Loader implementation

The loader lives in `src/io/`:

| Function | Responsibility |
|---|---|
| `readBrainwebRaw(filePath, volumeSize, precision, byteOrder)` | Generic raw reader (see below). |
| `loadBrainwebMri(cfg, modality)` | Returns the T1, T2 or PD volume using `cfg.dataset`. Rejects other modalities. |
| `loadBrainwebGroundTruth(cfg)` | Returns the discrete label volume using `cfg.dataset`. |

`readBrainwebRaw` does the following:

- checks that the file exists and that its size is exactly `prod(volumeSize)` × bytes per sample;
- opens the file read-only with an explicit byte order and always closes it (`onCleanup`);
- reads exactly the expected number of samples and rejects missing or extra data;
- reshapes the samples to `volumeSize`.

**Supported formats:** `uint8` and `uint16`, little- or big-endian. In this project they are used for the MRI raw short files (`uint16`, `ieee-le`, as verified in Phase 24) and the crisp raw byte file (`uint8`).

**Output convention:** `V(i,j,k)` with i = X, j = Y, k = Z and size `[181 217 181]`. This is a plain column-major reshape, without permute, as verified in Phase 27 (Section 13.7.3).

**Raw values preserved:**

- MRI volumes are returned as `uint16` with the stored values (0…4095). No rescaling, normalization, clipping or type conversion is applied.
- The GT is returned as `uint8` with the original labels 0…10. The loader does NOT compute `GT == 10`; building the binary lesion mask belongs to the evaluation stage.

**Configuration:** file paths, volume size and formats are centralized in `config.m` under `cfg.dataset`:

- `rawDir`, `mriFiles.T1/T2/PD`, `groundTruthFile`;
- `volumeSize`;
- `mriFormat`, `groundTruthFormat`.

All paths are built relative to the project root.

The dataset-identification fields (`case`, `lesionConfiguration`, `noiseLevel`, `rfInhomogeneity`, `groundTruthType`) were filled with the decided values. `modality` remains empty because the baseline is not chosen. No algorithm parameter was added. `main.m` was not changed.

#### 13.8.2 Phase 30 — Loader validation

The script `experiments/validate_brainweb_loader.m` calls the real loader on all four files. It is read-only and produces no figures or files. It was run in MATLAB R2026b on 2026-10-03.

| Volume | Size | numel | Class | Min | Max | NaN/Inf |
|---|---|---:|---|---:|---:|---|
| T1 | 181 × 217 × 181 | 7,109,137 | uint16 | 0 | 4095 | none |
| T2 | 181 × 217 × 181 | 7,109,137 | uint16 | 0 | 4095 | none |
| PD | 181 × 217 × 181 | 7,109,137 | uint16 | 0 | 4095 | none |
| GT | 181 × 217 × 181 | 7,109,137 | uint8 | 0 | 10 | none |

- GT labels present: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10. Label 10 has 3,512 voxels, matching the invariant of Sections 13.5–13.6.
- All four volumes have identical size.
- Error handling was also exercised: a missing file, wrong dimensions and an unsupported modality each raise the expected error identifier (`brainweb:fileNotFound`, `brainweb:wrongFileSize`, `brainweb:unsupportedModality`).

**Result: PASS.** All 27 checks passed.

The MATLAB Code Analyzer reports no issues for the loader functions and `config.m`. For the validation script it only suggests preallocating the `checks` cell array, a performance hint with no effect on correctness.

### 13.9 Phase 31: first MRI slice visualization

- **Code:**
  - `src/visualization/showAxialSlice.m` displays one axial slice of a volume;
  - `experiments/show_first_axial_slice.m` runs the Phase 31 check.

  Run in MATLAB R2026b on 2026-10-03. `main.m` was not changed.
- **Volume:** T1 (`t1_ai_msles2_1mm_pn0_rf0.raws`), loaded with `loadBrainwebMri`, size 181 × 217 × 181. T1 was used only for this display test; it is NOT the baseline modality choice. The GT was not used.
- **Slice:** axial, fixed dimension 3, central index k = 91 (`ceil(181/2)`, z = +18 mm).

**Display convention** (used by `showAxialSlice`):

| Aspect | Choice |
|---|---|
| Horizontal axis | i (X, dimension 1), increasing to the right |
| Vertical axis | j (Y, dimension 2), increasing upward (`YDir normal`) |
| Transpose | display-only `slice.'`, needed because MATLAB draws matrix rows vertically |
| Flip of the data | none |
| Aspect ratio | 1:1 (`axis image`), justified by the 1 mm isotropic spacing |
| Intensity | grayscale, `imagesc` maps the slice min–max to the colormap for rendering only; the volume is unchanged (MATLAB passes it by value) |

**Result:** the slice shows recognizable anatomy at the level of the lateral ventricles: grey and white matter, ventricles, interhemispheric fissure, skull and scalp. Frontal lobes appear at the top (high j) and occipital lobes at the bottom, consistent with +j = anterior (Section 13.7.3).

**Figure:** `results/figures/phase31_t1_axial_k091.png` (excluded from Git).

**Unresolved:** the left/right direction of +i is still unknown, so the figure carries no left/right label.

### 13.10 Phase 32: orthogonal MRI visualization

- **Code:**
  - `src/visualization/showOrthogonalSlices.m` receives an already loaded volume;
  - `experiments/show_orthogonal_views.m` runs the Phase 32 check.

  Run in MATLAB R2026b on 2026-10-03. `main.m` was not changed.
- **Volume:** T1, as in Phase 31, loaded with `loadBrainwebMri`, size 181 × 217 × 181. It was used only for visual verification; it is NOT the baseline choice. The GT was not used.
- **Common point:** (i0, j0, k0) = (91, 109, 91), the central voxel (`ceil(size/2)`).

**Views:**

| View | Slice | Horizontal axis | Vertical axis |
|---|---|---|---|
| Axial | k = 91, `V(:,:,91)` | i (X), to the right | j (Y), upward |
| Coronal | j = 109, `V(:,109,:)` | i (X), to the right | k (Z), upward |
| Sagittal | i = 91, `V(91,:,:)` | j (Y), to the right | k (Z), upward |

**Display rules:**

- The same rule as Phase 31 is applied to every panel: first remaining dimension horizontal, second vertical.
- The singleton dimension is removed with `reshape`, and each slice is transposed for display only.
- `YDir normal` is used; no data flip is applied.
- Aspect ratio is 1:1 (`axis image`), justified by the 1 mm isotropic spacing.
- Intensity: grayscale with one common display range, equal to the volume min–max, in all three panels. It affects rendering only.
- Dotted cross-reference lines mark the positions of the other two slices.

**Checks:**

- The function asserts that the three extracted slices share the voxel (i0, j0, k0).
- The cross-reference lines meet at the same anatomical point in all panels.
- The source volume is unchanged (passed by value, no processing).

**Result:** the anatomy is recognizable in all three views:

- axial: lateral ventricles;
- coronal: ventricles, corpus callosum, temporal lobes;
- sagittal (midline): corpus callosum, cerebellum, brainstem.

Superior is at the top of the coronal and sagittal views, and anterior is at the top of the axial view and on the right of the sagittal view. This is consistent with Section 13.7.3.

**Figure:** `results/figures/phase32_t1_orthogonal_i091_j109_k091.png` (excluded from Git).

**Unresolved:** the left/right direction of +i, so no left/right labels are shown.

### 13.11 Phase 33: axial slice-by-slice viewer

- **Code:**
  - `src/visualization/axialSliceViewer.m`: `fig = axialSliceViewer(volume, initialSlice, label)`;
  - `experiments/validate_axial_slice_viewer.m` validates the viewer.

  Run in MATLAB R2026b on 2026-10-03. `main.m` was not changed.
- **Input:** an already loaded 3D volume; the viewer does not read files. Validated with T1 from `loadBrainwebMri`, the same modality as Phases 31–32. It is NOT the baseline choice. The GT was not used.
- **Slices:** axial only. Initial slice k = 91 (central, default `ceil(nSlices/2)`). Valid range k = 1 … 181.
- **Interaction:** a slider (steps of 1 and 10 slices) and an edit box for typing k. The title shows `<label> - axial slice k = <k> / 181`.
- **Invalid indices:** non-integer, non-finite, non-scalar or out-of-range values are rejected without error. The current slice is kept, and the message "Invalid slice index. Valid range: 1 ... 181." is shown. Slider values are rounded to the nearest integer.
- **Display convention:** the same as Phases 31–32:
  - i (X) horizontal, to the right; j (Y) vertical, upward;
  - display-only transpose, no data flip, `axis image`, no left/right labels;
  - grayscale with a fixed range equal to the volume min–max for every slice, for rendering only.
- **Programmatic access:** `fig.UserData.setSlice(k)`, `getSlice()` and the image handle, used for testing.

**Validation:** 21/21 checks passed (**PASS**):

- initial slice;
- `setSlice` to 1, 181, 40, 140, 91;
- browsing all slices 1…181, where the displayed data equals `volume(:,:,k)` transposed and the title shows the same k;
- rejection of 0, 182, -5, 2.5, NaN, Inf, `[1 2]`;
- real UI callbacks: slider to the last slice, slider 37.4 → 37, edit box "1", "abc" rejected, "500" rejected;
- volume unchanged.

The viewer holds the volume in memory, so browsing never accesses the raw file.

**Limitations:**

- axial direction only;
- one volume at a time;
- no zoom management, overlays or modality selection (by design for this phase).

### 13.12 Phase 34: ground-truth visualization

- **Code:**
  - `src/visualization/showLabelSlice.m` displays one axial slice of an already loaded label volume;
  - `experiments/show_ground_truth.m` runs the Phase 34 check.

  Run in MATLAB R2026b on 2026-10-03. `main.m` and `config.m` were not changed.
- **GT:** `phantom_1.0mm_msles2_crisp.rawb`, loaded with `loadBrainwebGroundTruth`. Size 181 × 217 × 181, class `uint8`, labels 0…10, 3,512 voxels with label 10.
- **Slice:** axial k = 102, chosen automatically as the slice with the most label-10 voxels (224). This choice is used for GT visualization only and must not be reused in segmentation. No MRI was displayed and no overlay was made.
- **Display convention:** the same as Phases 31–33: i (X) horizontal to the right, j (Y) vertical upward, display-only transpose, no data flip, `axis image`, no left/right labels.
- **Colors:**
  - categorical colormap with one color per label (`clim` −0.5…10.5), not a continuous intensity scale;
  - colorbar with label numbers and BrainWeb names;
  - label 10 is emphasized in bright red through the colormap only; no binary mask is created and the GT is unchanged (`isequal` with a copy).

**Result:** all checks passed (**PASS**). The label map is interpretable: tissue classes are distinguishable, and the label-10 lesions are clearly visible, mostly periventricular within white matter.

**Observation, not a decision:** in this slice, label 8 (Glial Matter) appears as a thin layer at the ventricle borders, next to some lesions. This is relevant to open question 4 (Section 11) but does not resolve it.

**Figure:** `results/figures/phase34_gt_axial_k102.png` (excluded from Git).

**Unresolved:** the left/right direction of +i (no left/right labels).

### 13.13 Phase 35: MRI + ground-truth overlay

- **Code:**
  - `src/visualization/showLesionOverlay.m` receives an already loaded MRI and GT, and rejects mismatched sizes;
  - `experiments/show_mri_gt_overlay.m` runs the Phase 35 check.

  Run in MATLAB R2026b on 2026-10-03. `main.m` and `config.m` were not changed.
- **Data:**
  - MRI: T1 (`t1_ai_msles2_1mm_pn0_rf0.raws`), the same as Phases 31–33, used only for this check; it is NOT the baseline choice;
  - GT: `phantom_1.0mm_msles2_crisp.rawb`;
  - both loaded with the Phase 29 loader, both 181 × 217 × 181.
- **Slices,** selected automatically from the GT for visualization only (not a segmentation parameter):
  - main slice k = 102, the slice with the most label-10 voxels (224 pixels);
  - check slice k = 76, the median of the lesion-containing slices (18 pixels).
- **Overlay:**
  - T1 in grayscale, with the volume min–max as display range;
  - label-10 pixels of the same slice in red with transparency (alpha 0.5), with the legend "GT lesion (label 10)";
  - the lesion mask is a temporary local variable of the display function; it is not saved and is not part of the loader.
- **Orientation:** MRI and GT use exactly the same slice index and the same display transform: i (X) horizontal to the right, j (Y) upward, display-only transpose, `YDir normal`, no flip, `axis image`. No additional transform was needed.

**Checks:** all passed (**PASS**):

- both volume sizes;
- overlaid pixel count equal to the label-10 count of each slice;
- MRI unchanged and GT unchanged (`isequal` with copies).

**Qualitative result:**

- At k = 102 the lesions lie in periventricular white matter, several against the lateral-ventricle walls, and none falls outside brain tissue.
- At k = 76 the small lesions sit at the tips of the frontal horns and follow the ventricle border.
- No systematic shift, transpose or flip is visible.

Spatial integrity between MRI and GT is visually confirmed, consistent with the quantitative Phase 28 result (Section 13.7.4).

**Figures** (excluded from Git):

- `results/figures/phase35_t1_gt_overlay_k102.png`
- `results/figures/phase35_t1_gt_overlay_k076_check.png`

**Unresolved:** the left/right direction of +i (no left/right labels). It does not affect the overlay, since MRI and GT share the same convention.

### 13.14 Development/test protocol (Phase 36)

**PROJECT DECISION** — The authoritative definition is PROJECT_SPEC.md, Section 19.1. Summary:

| Role | Configurations |
|---|---|
| Development | `msles2`, 1 mm, `rf0`, `pn0` + `pn3`, T1/T2/PD, crisp GT |
| Held-out test | `msles2`, 1 mm, `rf0`, `pn1`, `pn5`, `pn7`, `pn9`, final-pipeline modality only |
| Extensions | `rf20`/`rf40`, thick slices, `msles1`/`msles3` |

Consequences for the dataset:

- `pn3` (T1, T2, PD, 1 mm, `rf0`) belongs to development but has not been downloaded yet. It will be downloaded in a later phase, when first needed.
- The held-out configurations are downloaded only after the parameter freeze (roadmap Phase 96), recorded by a Git commit or tag, and before the final test (Phase 97).
- All configurations share the same crisp GT (`phantom_1.0mm_msles2_crisp`, Section 13.5), which has already been inspected. For this reason the spatial rule of PROJECT_SPEC.md, Section 19.1 forbids any rule, ROI, slice range, mask or parameter derived from the absolute lesion positions.
- This extends the Phase 21 decision (Section 13.4): `pn0` remains the initial configuration, and `pn3` is added to development. It also refines the Phase 21 scope ("other noise levels later"): `pn1`, `pn5`, `pn7`, `pn9` are now the held-out test conditions.

**Limitation:** this is not an independent-subject test. The held-out evaluation measures robustness to simulated noise on the same anatomy and lesions; it does not measure generalization to new patients or new lesion morphologies.

### 13.15 Phase 38: basic MRI intensity statistics

- **Data:**
  - T1, T2 and PD of `msles2`, 1 mm, `pn0`, `rf0` (development), loaded with `loadBrainwebMri`;
  - class `uint16`, 181 × 217 × 181 = 7,109,137 voxels each;
  - the GT was not used.
- **Code:** `experiments/basic_intensity_statistics.m`, run in MATLAB R2026b on 2026-10-04.
- **Scope:** statistics over the **complete 3D volume, background included** (intentional for Phase 38).
- **Computation:**
  - values are converted to `double` only inside the computation; the volumes are unchanged (`isequal` with copies);
  - the standard deviation uses N−1 normalization.

| Modality | Min | Max | Mean | Std |
|---|---:|---:|---:|---:|
| T1 | 0 | 4095 | 877.43 | 943.90 |
| T2 | 0 | 4095 | 1370.07 | 1268.77 |
| PD | 0 | 4095 | 1876.61 | 1646.22 |

The values were recomputed independently, read-only with numpy, and match.

**Histogram:**

- one bin per raw integer value 0…4095 (edges −0.5:1:4095.5), the same for all modalities, using all voxels;
- the checks confirm that the histogram counts sum to the voxel count and that the mean recomputed from the histogram matches.

**Descriptive observations:**

- All three modalities span the full 0…4095 range.
- Under this configuration the mean is highest for PD, then T2, then T1.
- Each histogram shows a large concentration of voxels at the low end of the range and several narrow, well-separated peaks, consistent with noise-free simulated data.
- Interpreting background versus brain and the individual peaks belongs to Phases 39–40.

**Limitations:**

- Complete-volume statistics include all background voxels and are strongly influenced by them. They do not describe brain tissue alone; brain-only statistics belong to Phase 40.
- BrainWeb scales each raw short volume to use the full 0…4095 range (Section 8.3). Raw values, means and standard deviations are therefore descriptive within each volume, and are not directly comparable across modalities as physical intensities.

**Outputs** (excluded from Git):

- `results/metrics/phase38_basic_intensity_statistics.csv`
- `results/figures/phase38_basic_intensity_profile.png` (log-scale y axis for display, labelled "basic descriptive intensity profile")

No modality was selected, and no threshold, preprocessing or brain-mask decision was made.

### 13.16 Phase 39: global histogram analysis

- **Data:** the same files as Phase 38 (T1, T2, PD of `msles2`, 1 mm, `pn0`, `rf0`), loaded with `loadBrainwebMri`. All three are 181 × 217 × 181 = 7,109,137 voxels. The GT was not used.
- **Code:** `experiments/global_histograms.m`, run in MATLAB R2026b on 2026-10-04.
- **Definition:** histogram of **all** voxels of the complete volume, background included. No bin is removed and no brain mask is used.
- **Binning:** the same as Phase 38, one bin per raw integer value 0…4095 (edges −0.5:1:4095.5), identical for all modalities.
- **Checks:**
  - same size for all three volumes;
  - histogram total equal to the voxel count;
  - zero bin equal to the zero-voxel count;
  - figures saved;
  - volumes unchanged.

| Modality | Zero voxels | Zero % | Most frequent value (mode) | Median |
|---|---:|---:|---:|---:|
| T1 | 573,328 | 8.06 | 0 | 636 |
| T2 | 329,998 | 4.64 | 0 | 1615 |
| PD | 334,892 | 4.71 | 0 | 3115 |

The values were recomputed independently, read-only with numpy, and match.

**Background in the global distribution:**

- Zero is the most frequent value in every modality, but it covers only 4.6–8.1 % of the voxels. The background is therefore **not** exclusively zero at `pn0`.
- The low end of the range forms a dominant cluster of small non-zero values. In T1 the next most frequent values are 3, 2, 1 and 4.
- As a descriptive reporting point only, not a threshold and not used anywhere, the raw values 0…100 contain 41.3 % (T1), 37.4 % (T2) and 36.9 % (PD) of all voxels (numpy check).
- On a linear y axis this cluster dominates and compresses the rest of the distribution; the logarithmic view (display only, same counts) is needed to see the remaining structure.

**Observed shapes** (raw-value positions read approximately from the figures; no tissue identity is assigned):

- **T1:**
  - after the low-end cluster, a broad continuum up to about 2380, with narrow peaks near 690, 1560, 1740 and 2370;
  - above about 2380 the counts drop sharply into a low, flat tail up to 4095;
  - median 636 < mean 877 (Phase 38): right-skewed.
- **T2:**
  - low-end cluster with a narrow peak near 75;
  - a step increase near 1320;
  - narrow peaks near 1860 (the most frequent non-zero value, 1859) and 2420;
  - a long plateau up to a small peak near 3990;
  - median 1615 > mean 1370.
- **PD:**
  - low-end cluster with a narrow peak near 85;
  - a long low plateau between about 200 and 3100;
  - an abrupt rise to the most frequent non-zero value (3133), followed by peaks near 3650 and 3870;
  - median 3115 > mean 1877: the distribution is split into a low and a high group.

The three modalities have clearly different global shapes, but this says nothing about suitability for segmentation; the modality comparison belongs to Phase 41. The narrow peaks are consistent with noise-free simulated data.

**Limitation:** the global histogram mixes background, extracranial structures and brain tissue. The background cluster and non-brain signal can hide or compress differences between brain tissues. This motivates the brain-only analysis of Phase 40, which is not started here.

**Outputs** (excluded from Git):

- `results/figures/phase39_t1_global_histogram.png`
- `results/figures/phase39_t2_global_histogram.png`
- `results/figures/phase39_pd_global_histogram.png`
- `results/metrics/phase39_global_histogram_summary.csv`

Each figure shows the same counts on a linear and a logarithmic y axis.

No GT, brain mask, threshold, preprocessing or modality choice was used or made.

### 13.17 Phase 40: brain-only histogram — BLOCKED / DEFERRED (resumed and completed in Section 13.31)

**Status:** BLOCKED / DEFERRED (2026-10-04); **resumed after Phase 52 and completed on 2026-10-08 (Section 13.31).**

**Reason:** the roadmap defines Phase 40 as "Dopo la brain mask, analizzare solo i tessuti cerebrali". Its prerequisite is a validated, MRI-derived brain mask. The roadmap builds and validates that mask only in Phases 48–52:

- Phase 48: method;
- Phase 49: initial threshold;
- Phase 50: morphological cleanup;
- Phase 51: visual validation;
- Phase 52: application.

None of these phases has been executed. The repository was inspected on 2026-10-04: `src/segmentation/`, `src/preprocessing/` and `data/processed/` are empty, and no MATLAB file implements a brain mask.

**Decision:** no brain mask was improvised to run Phase 40.

- No GT labels were used as an oracle mask (forbidden by PROJECT_SPEC.md, Section 3, and by the open question in Section 27.1).
- No `MRI > 0` mask was used. As Phase 39 showed, the background is not even exclusively zero (Section 13.16), and non-zero voxels include extracranial structures.
- No provisional threshold, morphology or connected-component mask was created.
- No brain-only histogram or statistic was produced, and no Phase 40 result was fabricated.

**Still valid:** the Phase 38 statistics and the Phase 39 global histograms.

**Resume:** after Phase 52, using the validated mask from the brain-mask phases. Then:

- reuse the Phase 39 binning (one bin per raw value 0…4095);
- apply the same mask to T1, T2 and PD;
- compare the results qualitatively with Section 13.16.

The roadmap is not renumbered or reordered; Phase 40 keeps its number and is simply executed later.

### 13.18 Phase 41: T1 / T2 / PD comparison and initial modality

- **Data:**
  - T1, T2 and PD of `msles2`, 1 mm, `pn0`, `rf0` (development), raw values from `loadBrainwebMri`, unchanged;
  - the crisp GT (`phantom_1.0mm_msles2_crisp.rawb`) is used **only as an offline analytical reference**, with labels 10 (lesion, 3,512 voxels), 3 (WM, 671,323), 2 (GM, 903,198) and 1 (CSF, 371,988);
  - no held-out data and no `pn3`;
  - no brain mask (Phase 40 remains deferred, Section 13.17).
- **Code:** `experiments/compare_modalities.m`, run in MATLAB R2026b on 2026-10-04. The values were recomputed independently, read-only with numpy, and match.

**Measures,** comparing the lesion (L) with each tissue T, computed on raw values:

$$
S = \frac{|\mu_L - \mu_T|}{\sqrt{\frac{\sigma_L^2 + \sigma_T^2}{2}}}
\qquad
OVL = \sum_b \min\big(p_L(b),\, p_T(b)\big)
$$

- $S$ is a symmetric standardized separation, deliberately not weighted by voxel count, so the small lesion class is not dominated by the large tissue classes. It is scale-invariant and is the **primary cross-modality measure**.
- $OVL$ is the overlap of the normalized distributions, using bins of 32 raw values over 0…4095, the same for all modalities. It ranges from 0 (no overlap) to 1 (identical distributions). $p_L$ and $p_T$ are normalized separately, each summing to 1 (verified by the script check).

  $OVL$ is a histogram-based estimate that depends on the binning; it is not an absolute measure. Comparing modalities is legitimate only because all of them use identical bins, and small differences are not meaningful. For example, 0.0023 (T2) versus 0.0017 (PD) for lesion versus WM means "almost no overlap in both", not that PD is better.
- $|\mu_L - \mu_T|$ is also reported, but it is in raw units. Each raw short volume is scaled independently to 0…4095 (Section 8.3), so it is not comparable across modalities.

**Class statistics** (raw values):

| Modality | Lesion mean / median / std | WM mean / median / std | GM mean / std | CSF mean / std |
|---|---|---|---|---|
| T1 | 1976.5 / 1993 / 124.9 | 2298.5 / 2355 / 101.0 | 1714.3 / 158.6 | 833.4 / 192.0 |
| T2 | 3320.5 / 3305.5 / 300.9 | 1933.4 / 1878 / 107.9 | 2469.5 / 208.0 | 3607.6 / 355.9 |
| PD | 3800.2 / 3797 / 130.5 | 3195.7 / 3149 / 84.7 | 3618.4 / 77.0 | 3710.8 / 263.9 |

**Separability** (S / OVL; |Δμ| in raw units):

| Lesion versus | T1 | T2 | PD |
|---|---|---|---|
| **WM** (primary) | 2.83 / 0.125 (322) | **6.14** / 0.0023 (1387) | 5.50 / **0.0017** (605) |
| **CSF** (secondary) | **7.06** / **0.0008** (1143) | 0.87 / 0.618 (287) | 0.43 / 0.395 (89) |
| **GM** | 1.84 / 0.246 (262) | **3.29** / **0.103** (851) | 1.70 / 0.382 (182) |

**Distributions** (`phase41_class_distributions_offline_gt.png`):

- **T1:** lesions are darker than WM and lie between GM and WM, with partial overlap with both.
- **T2:** lesions are bright and well separated from WM and largely from GM, but they span the same high range as CSF.
- **PD:** lesions are well separated from WM, but they lie among the GM and CSF peaks.

**Matched slices** (`phase41_matched_slices.png`): axial k = 102 and k = 76, the same indices for all modalities, chosen from the GT for visualization only as in Phase 35. The display range is the per-volume min–max, for display only.

- At k = 102 the periventricular lesions are clearly visible as bright regions on dark WM in T2. In T1 they appear as a slightly darker grey close to GM. In PD they are faint under this display mapping.
- At k = 76 the small lesions are hard to see in all modalities. In T2 the ventricles and sulci (CSF) are as bright as the lesions.
- The faintness of PD is partly due to the display mapping. The quantitative values above are the evidence.

**PROJECT DECISION — initial baseline modality: T2** (provisional).

**Rationale:**

1. **Primary comparison (lesion versus WM):** T2 and PD both separate lesions from WM almost completely (S 6.14 and 5.50; OVL ≈ 0.002). T1 is clearly worse (S 2.83; OVL 0.125). This excludes T1 but does not, by itself, decide between T2 and PD.
2. **Lesion versus GM:** T2 is clearly better than PD (S 3.29 versus 1.70; OVL 0.10 versus 0.38).
3. **Visual contrast at matched slices:** T2 shows the lesions most clearly.
4. **Suitability for a simple intensity-based baseline:** in T2 the lesions are the hyperintense class relative to the surrounding brain parenchyma (WM and GM).

**Result:**

- **Clear** against T1.
- **Moderately supported** against PD: the two are close on the primary measure, and T2 is preferred on the lesion–GM comparison and on visual contrast.

**Main risk recorded for later phases:** in T2 the lesions overlap strongly with CSF (OVL 0.62, S 0.87). An intensity-only T2 baseline is therefore expected to confuse CSF (ventricles, sulci) with lesions.

- PD has the same problem (OVL 0.40, S 0.43); with S the problem is larger in PD, with OVL it is smaller.
- T1 separates lesions from CSF very well (S 7.06). This is information for a possible later multimodal investigation, which is NOT decided here.
- A simple rule such as "take the very bright voxels" is therefore expected to mix CSF and lesions.
- A future brain mask will **not** remove this problem automatically, because intracranial CSF (ventricles, sulci) lies inside the brain region.
- How to handle CSF must be solved later with MRI-derived, generic methods, without GT or lesion coordinates.

**Limitations:**

- At `pn0`/`rf0` the within-class dispersion includes no contribution from simulated noise or INU. It is determined mainly by tissue composition, partial volume and the characteristics of the simulated model. The separability observed at `pn0` is therefore a favourable condition and must be interpreted as optimistic with respect to noisy data.
- The class distributions come from the crisp model, where every voxel carries the label of its dominant tissue. They do not represent the partial-volume components the way a fuzzy map would. This does not invalidate the comparison between modalities, but the statistics describe dominant-label classes, not pure tissues.
- The choice is an **initial, provisional** modality. It will be re-checked when `pn3` enters development; a drastic change under noise would be an experimental reason to reconsider it.
- This is an initial modality for this classical pipeline on this BrainWeb configuration. It is not a clinical or general statement about MS imaging.

**GT use and leakage:**

- The GT was used only to extract aggregate class statistics for this comparison.
- No lesion coordinates, slice intervals, ROIs or GT masks were transferred to any segmentation code.
- The class statistics above (means, medians, standard deviations, distributions) **must not be used** to set thresholds, normalization ranges, intensity intervals, exclusion rules or any other segmentation parameter. They may only justify the modality choice (PROJECT_SPEC.md, Section 19.2). This includes rules such as "lesion = intensity above a value observed in the GT". Phase 41 motivates the choice of T2; it does not provide operational numbers for the segmentation.

**Outputs** (excluded from Git):

- `results/metrics/phase41_modality_comparison.csv`
- `results/figures/phase41_class_distributions_offline_gt.png`
- `results/figures/phase41_matched_slices.png`

No threshold, filter, brain mask, segmentation or multimodal rule was introduced.

### 13.19 Phase 42: unfiltered preprocessing baseline

- **Input:** T2 (`t2_ai_msles2_1mm_pn0_rf0.raws`), the provisional initial modality of Phase 41, now recorded as `cfg.dataset.modality = "T2"` in `config.m` (the field existed and was empty). Configuration `msles2`, 1 mm, `pn0`, `rf0`. Loaded with `loadBrainwebMri`: class `uint16`, 181 × 217 × 181, values 0…4095.
- **Definition:** the preprocessing baseline is the **identity**. The loader output is used as is: no filtering, numeric conversion, normalization, clipping or any other change.
- **Code:** `experiments/unfiltered_preprocessing_baseline.m`, run in MATLAB R2026b on 2026-10-05. No preprocessing function was created, because none is needed for an identity.
- **Checks (PASS):**
  - values identical voxel by voxel (`isequal`);
  - same class and size, both as configured;
  - no NaN/Inf;
  - identical to an independent second read of the raw file.
- **No copy saved:** the reference is rebuilt from raw file + loader + identity rule.
- **Figure:** `results/figures/phase42_t2_unfiltered_baseline_k091.png`, central axial slice k = 91, chosen without GT and labelled "Unfiltered preprocessing baseline".
- **Purpose:** this is the "no filter" reference for Phases 45–47 (Gaussian, median, filter evaluation). The same identity rule applies unchanged to `pn3` when it is introduced.

The GT was not used, `pn3` was not downloaded, and Phase 40 remains deferred.

### 13.20 Phase 43: controlled numeric conversion

- **Representations:**
  - storage: `uint16`, raw BrainWeb values 0…4095, as returned by the loader; the raw file remains authoritative;
  - working: `double`, recorded as `cfg.preprocessing.workingClass = "double"` in `config.m`.
- **Code:**
  - `src/preprocessing/convertToWorkingClass.m`: a plain `cast` to `double` or `single`. It rejects integer values beyond `flintmax` of the target class, which cannot happen for `uint16`;
  - `experiments/numeric_conversion_check.m`: the validation script, which stops with an error if a check fails.

  Run in MATLAB R2026b on 2026-10-05.
- **Why `double`:**
  - it is MATLAB's default floating-point type;
  - it represents every integer 0…4095 exactly;
  - later arithmetic avoids integer rounding and saturation;
  - the raw intensity scale is unchanged.

  This is a numeric-representation decision, not a normalization.

**Result on T2 (PASS):**

- input `uint16` with range 0…4095; output `double` with range 0…4095;
- size 181 × 217 × 181 before and after;
- every voxel is identical: `isequal` holds, and 0 voxels differ;
- min and max unchanged, no NaN/Inf, loader output untouched.

**Other types:**

- `single` also represents the values exactly; this was verified for documentation only. It is not selected, and there is no second pipeline.
- `uint8` is unsuitable for the MRI: 4,241,023 of 7,109,137 voxels exceed 255. No `uint8` MRI was created.
- The GT stays `uint8` because it holds labels 0…10; this has no bearing on the MRI type.

**Not used:**

- `im2double`: for `uint16` it rescales by the class range (4095 → about 0.0625), which would change the intensity scale.
- `mat2gray`: it is a rescaling; any normalization belongs to Phase 44.

Course compatibility (ALLOWED_TECHNIQUES.md, Section 3.3) does not mean these functions must be used.

**Pipeline after Phase 43:**

```text
raw file -> loader (uint16, 0...4095) -> convertToWorkingClass -> double, still 0...4095
```

No filtering, normalization, GT access or saved copy. Raw files are unchanged.

### 13.21 Phase 44: intensity normalization

- **Input:** the Phase 43 working volume (T2, `double`, 0…4095).
- **Alternatives considered:**
  - **A — none:** keep `double` 0…4095;
  - **B — fixed 12-bit to unit range:** `I_norm = I / 4095`.
  - Rejected without further testing: per-volume min–max and `mat2gray` with automatic limits (image-dependent scale), z-score (volume-dependent, dominated by the background, no brain mask yet), and any GT-based normalization (forbidden; Phase 41 statistics are not used).

**PROJECT DECISION — `NORMALIZATION = FIXED_12BIT_TO_UNIT_RANGE`:**

$$
I_{norm} = \frac{I - 0}{4095 - 0}\,(1 - 0) + 0 = \frac{I}{4095}
$$

The configuration is `cfg.preprocessing.normalization` with `method = "fixed-12bit"`, `inputRange = [0 4095]` and `outputRange = [0 1]`.

**Rationale:**

- **Practical:** MATLAB image functions treat `double` images as lying in [0,1]. They convert internally with `im2uint8`, which saturates every value above 1. The validation shows `im2uint8([0 0.5 1 2 4095]) = [0 128 255 255 255]`. With a 0…4095 `double` image, histogram- and intensity-based functions of the course (`imhist`, `graythresh`, `imbinarize`, `imshow`) would therefore saturate almost every non-zero voxel. Option A would require bypassing them or passing explicit ranges everywhere.
- **Reproducibility:** the limits are the verified 12-bit storage domain. They are fixed in the configuration and never estimated from the current image, so the same rule applies unchanged to every matching BrainWeb volume.
- **Mathematics:** the transformation is a positive linear rescaling. It preserves voxel ordering, intensity ratios, histogram shape and image structure. It adds no information and **does not by itself improve lesion separation**.

**Implementation:**

- `src/preprocessing/normalizeFixedRange.m` applies the formula with the configured limits. It never inspects the image min/max, and it raises an error for values outside `inputRange` instead of clipping them.
- `experiments/normalization_check.m` validates it. It was run in MATLAB R2026b on 2026-10-05 and stops with an error on failure.

**Validation on T2 (PASS):**

- same size; class `double`; all values finite; range [0, 1];
- 0 → 0 and 4095 → 1;
- result **exactly equal** to `I / 4095` (`isequal`);
- ordering preserved (same number of unique values, strictly increasing);
- histogram identical when the original bin edges (−0.5:1:4095.5) are divided by 4095, so there are no independent automatic bins;
- Phase 43 working volume and raw data unchanged;
- **negative tests:** −1, 4096, NaN and Inf are each rejected with the specific error `preprocessing:valueOutOfRange`, not clipped. The test passes only if that exact identifier is raised.

`im2uint8` appears only in the validation script, as a demonstration; it is not part of the pipeline.

**Bug found by the negative tests and fixed:**

- `normalizeFixedRange` passed the vector `inputRange` as a formatted argument to `error`. Unlike `sprintf`, `error` requires scalar formatted arguments.
- As a result, out-of-range input raised `MATLAB:error:nonScalarInput` instead of the intended error. The input was still rejected, but with a wrong identifier and an unclear message.
- Both error messages in the function now pass scalar values. The other `error` calls in the project were checked, and they pass only scalars or text.
- After the fix, all 15 checks pass.

**Pipeline after Phase 44:**

```text
raw -> loader (uint16, 0...4095) -> convertToWorkingClass (double, 0...4095) -> normalizeFixedRange (double, 0...1)
```

**Scope of the decision:** `FIXED_12BIT_TO_UNIT_RANGE` standardizes the **numeric storage domain** to [0,1]. It is **not** an inter-volume intensity harmonization. BrainWeb scales each raw short volume to use the full 0…4095 range (Section 8.3), so the raw scale is already volume-dependent upstream. Dividing every volume by 4095 puts all of them in [0,1], but it does not guarantee that a value such as 0.70 has the same meaning in `pn0` and in `pn3`.

Phase 45 confirmed this empirically (Section 13.22.2). The question of cross-condition intensity harmonization, and of how intensity-dependent parameters transfer between conditions, is therefore an open question (Section 11, question 17). It is not resolved by Phase 44.

No GT, Phase 41 statistics, filtering, brain mask or segmentation was used. `pn3` was not downloaded, and Phase 40 remains deferred.

### 13.22 Phase 45: exploratory Gaussian smoothing

#### 13.22.1 pn3 introduced as development data

- **Download:** only `t2_ai_msles2_1mm_pn3_rf0.raws`, from the official server on 2026-10-05, with the same procedure as Section 13.5.2.
  - Download page: "T2 AI msles2 1mm pn3 rf0", "Modality=T2, Protocol=AI, Phantom_name=msles2, Slice_thickness=1mm, Noise=3%, INU=0%".
  - MINC info: "signed__ short 0 to 4095", with the same grid as `pn0`.
  - Served filename: `t2_ai_msles2_1mm_pn3_rf0.raws`; 14,218,274 bytes; SHA-256 `52af70628f1211ccef850f61e715d4d743102eaf29ad1337cdeb61bbccfe0f7e`.
- **Verified from the file:** little-endian, 7,109,137 samples, values 0…4095. Read as big-endian, values reach 65295. Size, class and range were also checked through the loader.
- **Record:** `data/raw/msles2/DOWNLOAD_INFO.txt`. No held-out configuration was downloaded.
- **Configuration:** `cfg.dataset.noisyMriFiles.pn3.T2`.
- **Loader:** `loadBrainwebMri(cfg, modality, noiseLevel)` gained an optional third argument. Without it, the behaviour is unchanged; the Phase 30 validation was re-run and passed 27/27.

#### 13.22.2 Scale difference between pn0 and pn3 (MRI-only diagnostic)

A complete-volume affine diagnostic gives `pn3 ≈ 0.869 · pn0 + 0.024` (least-squares fit over all voxels, background included), with `mean(pn3 − pn0) = −0.020`. This reveals a substantial global intensity-scale mismatch between the two stored volumes. It is not a uniform percentage change: the fit has an offset, and it is dominated by whichever voxels are most numerous, including the background. No tissue-level statement is made, since no brain mask or tissue classes were used. In addition, `pn3` has only 56 zero voxels, against 329,998 in `pn0`.

This is consistent with the Phase 44 scope note (Section 13.21): `I/4095` standardizes the storage domain but does not harmonize intensities across volumes. Under the single-parameter-set rule of Phase 37, a parameter defined in absolute intensity units may not transfer between the two conditions. This is recorded as open question 17 (Section 11).

#### 13.22.3 Experiment

- **Code:**
  - `src/preprocessing/gaussianFilterSlices.m`: `imgaussfilt` on each axial slice, never `imgaussfilt3`;
  - `experiments/gaussian_smoothing_check.m`.

  Run in MATLAB R2026b on 2026-10-05; logged as EXP-001 in EXPERIMENT_LOG.md.
- **Preparation**, identical for all volumes: loader, then `convertToWorkingClass` (`double`), then `normalizeFixedRange` (/4095), giving T2 in [0,1].
- **Compared:**
  - `pn0` unfiltered (clean reference);
  - `pn3` unfiltered;
  - `pn3` Gaussian.
- **Exploratory Phase 45 reference parameters,** not selected from data and not final:
  - σ = 0.5 pixel (the `imgaussfilt` default);
  - filter size 3 × 3 (`2·ceil(2σ)+1`, the MATLAB automatic size, made explicit);
  - padding `replicate` (the `imgaussfilt` default).
- **Checks (PASS):**
  - `pn3` size, class and range;
  - same geometry as `pn0`;
  - inputs `double` in [0,1];
  - output size, class and finiteness;
  - **2D slice by slice**: changing slice 50 changes no other output slice;
  - normalized and raw `pn3` unchanged.

| Measure (whole volume, normalized scale) | Value |
|---|---:|
| MSE `pn3` unfiltered vs `pn0` | 0.002653 |
| MSE `pn3` Gaussian vs `pn0` | 0.002881 |
| Relative change | **+8.61 %** |
| Clean-reference distortion: MSE `pn0` Gaussian vs `pn0` | 0.000303 |
| Scale-matched MSE `pn3` unfiltered vs (0.8689 · `pn0` + 0.0238) | 0.000598 |
| Scale-matched MSE `pn3` Gaussian vs the same reference | 0.000427 |
| Scale-matched relative change | **−28.61 %** |

**Interpretation (preliminary):**

- A global affine fit reduces the unfiltered `pn3`-versus-`pn0` MSE by approximately 77 % (0.002653 → 0.000598). This indicates that a large part of the raw discrepancy is explainable by a global gain/offset mismatch. Because the fit uses the complete volume, background included, this is a diagnostic only, not proof of a physical cause.
- With the requested raw MSE, the Gaussian filter increases the error (+8.6 %); this metric is dominated by the global mismatch, which no filter can remove.
- After removal of the fitted global affine mismatch, for diagnostic purposes, Gaussian smoothing with σ = 0.5 reduces the residual complete-volume MSE from 0.000598 to 0.000427 (−28.61 %).
- Filtering the clean `pn0` reference introduces an MSE of 0.000303, confirming that smoothing also alters image structure. The two numbers come from different comparisons and are not subtracted or weighed against each other.
- These results establish a measurable denoising effect, but they do not determine whether the filter should be retained. Preservation of relevant structures and parameter selection are deferred to Phase 47.
- The affine reference is fitted on `pn3` itself, a mild dependence on the evaluated data; the same fit is used for both branches.
- The whole-volume MSE includes the background, because no brain mask exists yet (Phase 40 deferred).

**Visual check** (`phase45_gaussian_pn0_pn3_k091.png`, central slice k = 91, chosen without GT):

- `pn3` shows visible grain, which the filter slightly reduces;
- the difference image shows that the filter mostly changes edges (skull, scalp, ventricle borders) and scattered background noise.

**Not decided:**

- no final σ, no parameter sweep, and no keep/drop decision for Gaussian smoothing: these belong to Phase 47;
- no claim about lesion preservation;
- no median filter: that is Phase 46.

No GT, held-out data, brain mask or segmentation was used.

**Outputs** (excluded from Git):

- `results/metrics/phase45_gaussian_pn3_sigma0p5.csv`
- `results/figures/phase45_gaussian_pn0_pn3_k091.png`

### 13.23 Phase 46: exploratory median filtering

- **Noise model:** BrainWeb documents Rayleigh noise in the background and Rician noise in signal regions [S9]. Median filtering is mainly suited to impulse-like (outlier) noise, so it was **not** expected to be well matched. It was evaluated, not inserted automatically.
- **Data:** T2, `msles2`, 1 mm, `rf0`. `pn0` is the unfiltered clean reference and `pn3` the noisy condition; both existing development files. Both are prepared identically: loader, then `double`, then /4095, giving [0,1].
- **Code:**
  - `src/preprocessing/medianFilterSlices.m`: `medfilt2` on each axial slice, never `medfilt3`;
  - `experiments/median_filtering_check.m`.

  Run in MATLAB R2026b on 2026-10-05; logged as EXP-002.
- **Exploratory Phase 46 parameters,** neither tuned nor final:
  - window 3 × 3;
  - padding `symmetric`, one of the options listed by the installed `medfilt2` documentation ("zeros" default | "symmetric" | "indexed"). It was chosen because it introduces no artificial values at the borders.

  Only one window was tested.
- **Decision rule, declared in the script before the results:** `YES` only if the scale-matched MSE decreases and the figure shows no evident artefacts; otherwise `NO`.
- **Affine diagnostic:** estimated once on unfiltered `pn3` (`pn3 ≈ 0.8689 · pn0 + 0.0238`, the same as Phase 45) and reused unchanged for both branches. It is diagnostic only and is not part of the pipeline (open question 17).
- **Checks (PASS):**
  - same geometry for `pn0` and `pn3`;
  - inputs `double` in [0,1];
  - output size, class and finiteness;
  - output within [0,1];
  - 2D slice by slice (changing slice 50 changes no other slice);
  - normalized and raw `pn3` unchanged.

| Measure (whole volume, normalized scale) | Value |
|---|---:|
| Raw MSE `pn3` unfiltered vs `pn0` (affected by the scale mismatch) | 0.002653 |
| Raw MSE `pn3` median vs `pn0` | 0.003917 |
| Raw relative change | +47.66 % |
| Scale-matched MSE unfiltered | 0.000598 |
| Scale-matched MSE median | 0.001111 |
| Scale-matched relative change | **+85.97 %** |
| Clean-reference distortion: MSE `pn0` median vs `pn0` | 0.001236 |

**Visual check** (`phase46_median_pn0_pn3_k091.png`, central slice k = 91, chosen without GT):

- the median filter reduces the grain of `pn3`;
- it visibly thins or removes thin bright structures, such as sulcal lines and the thin scalp and skull layers, and gives a patchy appearance;
- the difference image concentrates on thin structures and edges.

These are generic observations; no lesion-specific claim is made.

**PROJECT DECISION — MEDIAN CANDIDATE FOR PHASE 47 = NO.**

**Rationale:**

1. **Declared rule:** the scale-matched residual MSE increases by 86 %. On this diagnostic metric, the net effect of the 3 × 3 median is an increase of the residual error.
2. **Clean-reference distortion:** applied to the noise-free `pn0`, the filter alone introduces an MSE of 0.001236, so it substantially alters noise-free image structure. This is recorded separately and not weighed against the `pn3` result.
3. **Visual behaviour:** thin structures are removed, which is a generic artefact.
4. **Theory:** the documented noise model (Rayleigh/Rician) is not the impulse-like noise for which median filtering is designed.

The decision concerns only whether the median filter is carried into Phase 47. It is not a ranking against Gaussian smoothing, and it is not the final preprocessing decision. Since the smallest tested 3 × 3 neighborhood already substantially worsens the diagnostic metric and visibly alters fine structures, there is no experimental justification to test larger median neighborhoods in the current pipeline. Larger neighborhoods would generally be expected to produce stronger local smoothing, but they were not tested.

No GT, held-out data, brain mask or segmentation was used. Intensity harmonization (open question 17) remains unresolved, and `config.m` was not changed.

**Outputs** (excluded from Git):

- `results/metrics/phase46_median_pn3_3x3.csv`
- `results/figures/phase46_median_pn0_pn3_k091.png`

### 13.24 Supplementary EXP-003: exploratory mean (moving-average) filtering

**Why it was added:** EXP-003 is a supplementary experiment run before Phase 47. It is not a roadmap phase, and the phases are not renumbered. The mean filter is an allowed technique (ALLOWED_TECHNIQUES.md, Section 4.1; PROJECT_SPEC.md, Section 8), and the course uses it in a denoising experiment evaluated by MSE. Testing it alongside the Gaussian (Phase 45) and median (Phase 46) filters means that the three classical course filters relevant to this problem are evaluated under one protocol.

The following were deliberately **not** tested, because they are poorly matched to the Rayleigh/Rician BrainWeb noise or add unjustified complexity:

- weighted median and min/max/rank-order filters (designed for impulse-like noise);
- Butterworth and other frequency-domain filters (the course targets them at periodic noise);
- Wiener filtering (a restoration/deconvolution context);
- anisotropic filters (only named in the course material);
- sharpening (not a denoising method).

Apart from the plain median filter, none of these is in the allowed-techniques list.

**Setup:**

- **Data and protocol:** identical to Phases 45–46: T2, `msles2`, 1 mm, `rf0`; `pn0` as unfiltered reference and `pn3` as noisy condition; loader, then `double`, then /4095.
- **Code:**
  - `src/preprocessing/meanFilterSlices.m`: `imfilter` with `fspecial('average', [3 3])` on each axial slice;
  - `experiments/mean_filtering_check.m`.

  Run in MATLAB R2026b on 2026-10-05.
- **Exploratory parameters,** neither tuned nor final: window 3 × 3 (equal weights 1/9); padding `replicate`, as for the Gaussian filter. Only one window was tested.
- **Smoothing strength (documentation only):** the centre weight of the 3 × 3 mean kernel is 0.1111, against 0.6193 for the Phase 45 Gaussian kernel (σ = 0.5, 3 × 3). With the same window size, the mean filter is a much stronger smoother.
- **Decision rule, declared before the results:** `YES` only if the scale-matched MSE decreases and the figure shows no evident artefacts; otherwise `NO`.
- **Affine diagnostic:** estimated once on unfiltered `pn3` (`0.8689 · pn0 + 0.0238`) and reused for both branches. It is diagnostic only.
- **Checks (PASS):**
  - same geometry for `pn0` and `pn3`;
  - inputs `double` in [0,1];
  - kernel weights sum to 1;
  - output size, class and finiteness;
  - output within [0,1];
  - 2D slice by slice;
  - normalized and raw `pn3` unchanged.

| Measure (whole volume, normalized scale) | Value |
|---|---:|
| Raw MSE `pn3` unfiltered vs `pn0` (affected by the scale mismatch) | 0.002653 |
| Raw MSE `pn3` mean vs `pn0` | 0.005031 |
| Raw relative change | +89.68 % |
| Scale-matched MSE unfiltered | 0.000598 |
| Scale-matched MSE mean | 0.001802 |
| Scale-matched relative change | **+201.51 %** |
| Clean-reference distortion: MSE `pn0` mean vs `pn0` | 0.002412 |

**Visual check** (`exp003_mean_pn0_pn3_k091.png`, central slice k = 91, chosen without GT):

- the grain of `pn3` is removed, but the image is visibly blurred;
- thin sulcal lines and the thin skull and scalp layers are smeared;
- the difference image concentrates on edges and thin structures.

No lesion-specific claim is made.

**PROJECT DECISION — MEAN CANDIDATE FOR PHASE 47 = NO.**

**Rationale:**

1. **Declared rule:** the scale-matched residual MSE increases by about 200 %. On this diagnostic metric, the net effect of the 3 × 3 mean filter is an increase of the residual error.
2. **Clean-reference distortion:** applied to the noise-free `pn0`, the filter alone introduces an MSE of 0.002412, so it substantially alters noise-free structure. This is recorded separately.
3. **Visual behaviour:** the image is evidently blurred.
4. **Smallest non-trivial neighborhood:** 3 × 3 is the smallest non-trivial odd square neighborhood for a uniform mean filter. A 1 × 1 mean would be the identity operation and would provide no smoothing. There is no experimental justification for testing larger windows, which were not tested.

**Scope:** this result concerns the 3 × 3 mean filter at its own, much stronger, smoothing level. It is not a ranking of filter families against the Gaussian filter, whose Phase 45 kernel is far milder. It is not the final preprocessing decision.

No GT, held-out data, brain mask or segmentation was used. `config.m` was not changed, and open question 17 remains open.

**Outputs** (excluded from Git):

- `results/metrics/exp003_mean_pn3_3x3.csv`
- `results/figures/exp003_mean_pn0_pn3_k091.png`

### 13.25 Phase 47: evaluation of the filter effect (EXP-004)

**Context:**

- Median 3 × 3 (EXP-002) and mean 3 × 3 (EXP-003) were each rejected by their own pre-declared rule.
- Gaussian σ = 0.5, 3 × 3, `replicate` (EXP-001) is the only filtering candidate entering Phase 47.
- The three experiments were **not** an equal-strength ranking. The mean 3 × 3 kernel (centre weight 0.111) is far stronger than the Gaussian σ = 0.5 kernel (0.619).

**Comparison:** unfiltered versus Gaussian σ = 0.5, 3 × 3, `replicate`. There was no sweep: σ, size and padding are those declared in Phase 45.

**Why σ = 0.5 is evaluated:**

- it was declared before the Phase 45 results;
- it is the `imgaussfilt` default, with 3 × 3 support;
- it produced a measurable reduction of the scale-matched residual error;
- it is far milder than the rejected mean filter.

It is a development parameter, not an optimum.

**Data and code:**

- T2, `msles2`, 1 mm, `rf0`; `pn0` and `pn3`, prepared as in Phases 43–44.
- `experiments/filter_effect_evaluation.m`, run in MATLAB R2026b on 2026-10-05.
- **Order enforced:** all MRI-only processing and metrics come first; the GT is loaded afterwards, only to draw the lesion contours in a figure.

| Measure (whole volume, normalized scale) | Value |
|---|---:|
| Raw MSE `pn3` unfiltered / Gaussian vs `pn0` | 0.002653 / 0.002881 |
| Affine diagnostic (from unfiltered `pn3`) | `pn3 ≈ 0.8689 · pn0 + 0.0238` |
| Scale-matched MSE unfiltered / Gaussian | 0.000598 / 0.000427 (**−28.61 %**) |
| Clean-reference distortion (MSE `pn0` Gaussian vs `pn0`) | 0.000303 |
| Detail energy `pn0` unfiltered / Gaussian | 116,061 / 79,608 |
| **Detail retention on `pn0`** | **68.59 %** |

- The EXP-001 values were reproduced within a relative tolerance of 1e-4 (check PASS).
- **Detail energy:**

  $$
  E = \sum \big(\Delta_x V\big)^2 + \sum \big(\Delta_y V\big)^2
  $$

  These are first-order finite differences along X and Y inside each axial slice, with no Z differences, summed over the volume.
- No acceptance threshold existed for the detail retention, and none was introduced.

**Central slice** (k = 91, chosen without GT; `phase47_unfiltered_vs_gaussian_k091.png`):

- On the noise-free `pn0`, the filter changes every tissue boundary (ventricles, sulci, skull, scalp), with absolute differences up to about 0.14 on the [0,1] scale (the difference panels have their own colour bars).
- On `pn3`, the filter attenuates the grain; the change is spread over noise and edges.

**GT overlay** (`phase47_gt_contour_unfiltered_vs_gaussian.png`):

- **Slices:** k = 102 (224 lesion pixels) and k = 76 (18 pixels), selected automatically from the GT with the Phase 35/41 rule, only for the figure. They define no ROI or parameter, and the whole volume was processed identically. The figure shows full slices with the same contour in all four panels (`pn0` and `pn3`, each unfiltered and Gaussian).
- **Observations:**
  - At k = 102 every outlined lesion remains clearly visible as a bright region after filtering, in both `pn0` and `pn3`, with slightly softer borders. No obvious loss of lesion visibility was observed there.
  - At k = 76 the lesions are tiny (a few pixels each). At this figure resolution, and with the contour drawn on top, their preservation cannot be judged conclusively in either the filtered or the unfiltered versions.

**Region fusion:** at the grayscale preprocessing stage, Phase 47 can assess blurring and loss of separability (the detail retention, the edge differences and the overlays). Actual merging of binary candidate regions can only be verified once segmentation masks exist.

**PROJECT DECISION — CURRENT PREPROCESSING FILTER = NONE** (`cfg.preprocessing.filter.method = "none"`).

**Rationale:** the evidence is mixed.

- The Gaussian filter measurably reduces the scale-matched residual error on `pn3` (−28.6 %).
- On the noise-free `pn0` it removes about 31 % of the 2D detail energy and changes every tissue boundary.
- For the smallest lesions, its effect is visually inconclusive.

No surrogate metric can settle this trade-off. The project documents prescribe how to proceed:

1. PROJECT_SPEC.md, Section 8: the first segmentation experiments must include a baseline with minimal preprocessing; filtering must not be introduced automatically and is kept only if evidence shows that it improves the segmentation.
2. PROJECT_SPEC.md, Section 20: the first baseline is MRI → brain mask → thresholding, and "baseline + preprocessing" follows as a separately measured step.
3. Phase 37: the development score weighs `pn0` and `pn3` equally. On `pn0` the filter can only remove detail, while on `pn3` it removes noise, so its net effect is a segmentation-level question.

**Status of the Gaussian candidate:** Gaussian σ = 0.5, 3 × 3, `replicate` is **not rejected**. It is the validated candidate for the first "baseline + preprocessing" experiment, to be decided with the Phase 37 rule once complete 3D predictions exist. Phase 47 does not replace that rule and finds no optimum. No parameter is frozen; the final freeze happens in Phases 95–96.

No GT-derived intensity statistic was computed or used. The GT generated no mask, rule or parameter. No threshold, brain mask, morphology or held-out data was used. Open question 17 (intensity harmonization) remains open, and Phase 40 remains deferred.

**Outputs** (excluded from Git):

- `results/metrics/phase47_filter_effect_evaluation.csv`
- `results/figures/phase47_unfiltered_vs_gaussian_k091.png`
- `results/figures/phase47_gt_contour_unfiltered_vs_gaussian.png`

### 13.26 Phase 48: brain-mask strategy (method definition only)

**Status:** COMPLETE. This is a design phase: no mask, threshold, morphology or code was produced.

**Purpose:** to remove the external image background, restrict later lesion analysis to the anatomically relevant head/brain region, and reduce obvious background-related false positives.

**Target:** `brainMask(i,j,k) ∈ {false, true}`, with the same size as the MRI. It is a **conservative anatomical support region** that contains the complete brain and the intracranial regions relevant for lesion analysis, while excluding the external background.

- It is **not** an aggressive or perfect skull-stripping mask.
- It may retain some skull, scalp or other head structures if that avoids excluding brain tissue.
- **Design priority:** avoid excluding relevant brain tissue. A voxel excluded by the mask can never be recovered by later stages. This is a generic principle; it uses no knowledge of lesion positions.

**Input:** T2 (current initial modality), loaded and then converted to `double` (Phase 43) and normalized by /4095 (Phase 44), with **no filter** (Phase 47). The Gaussian candidate is not used for the mask. T1, PD and multimodal masks are not considered.

**Planned pipeline:**

```text
T2 raw -> loader -> double -> /4095 -> no smoothing
  -> automatic MRI-derived threshold -> initial support mask        [Phase 49]
  -> morphological / connected-component cleanup, only if justified [Phase 50]
  -> MRI-boundary overlay validation                               [Phase 51]
  -> validated support mask applied to later processing            [Phase 52]
```

Phase 40 resumes after Phase 52.

**Principles:**

- **One method for `pn0` and `pn3`:** a single automatic rule, unchanged for both. Separate constants such as `threshold_pn0` and `threshold_pn3` are not allowed.
- **Automatic, MRI-derived threshold:** the initial mask comes from an automatic intensity threshold computed from the MRI by the same algorithm for every volume. A simple global histogram-based method is the preferred starting family for Phase 49. No threshold was computed or chosen here.
- **No fixed absolute threshold** (for example `I > 0.12` chosen on `pn0`):
  - the Phase 44 normalization standardizes only the storage domain;
  - Phase 45 found a substantial global intensity-scale mismatch between `pn0` and `pn3` (open question 17, unresolved);
  - a hand-picked constant would therefore not transfer.
- **`MRI > 0` is not a brain mask:**
  - the `pn3` background is noisy (only 56 zero voxels in `pn3`, Section 13.22.2);
  - the `pn0` background is not exclusively zero either (Section 13.16);
  - non-zero voxels include extracranial structures.
- **2D slice by slice:** the same automatic rule is applied to each axial slice, and the 2D masks are assembled into a 3D logical volume. No 3D filtering, 3D morphology or 3D connected components. Manual per-slice thresholds are forbidden; a slice-adaptive threshold is allowed only if it is produced automatically by one general rule.
- **Cleanup (Phase 50):**
  - opening, closing, erosion, dilation, hole filling and connected-component cleanup may be needed;
  - structuring elements, sizes, connectivity and component rules are decided only after observing the actual Phase 49 mask errors.
- **Validation (Phase 51):** visual inspection of MRI with the mask boundary overlaid.

**Anatomical labels (PROJECT_SPEC.md, Section 27.1 — resolved in Phase 48):**

- The core brain mask is generated, tuned and validated from MRI data only.
- BrainWeb anatomical labels are not used as mask inputs or oracle masks, or as references for thresholds, morphology, component filtering, ROIs, exclusions or corrections. They are not used even as the primary validation reference.
- Any label-based audit would be a separate, explicit, post-hoc experiment with no influence on the core mask; none is planned now.
- The lesion GT is likewise excluded, and no GT file was loaded.

**Issues carried into Phase 49** (expectations, not results):

1. **Per-volume or per-slice threshold:** both are "one automatic rule". A per-slice threshold may behave poorly on extreme slices with little or no head, where in `pn3` it could split pure background noise into "foreground". Phase 49 must choose and justify one option.
2. **Expected T2 structure:** bright scalp, dark skull, bright brain (Phase 45/47 figures). A foreground threshold may therefore yield a scalp ring plus the brain, with a dark skull gap or interior holes. Hole filling or closing may be needed in Phase 50; this must be verified on the actual mask.
3. **Consequences of the conservative choice:** retaining scalp and fat, which are bright in T2, may shift some false-positive burden to the lesion-segmentation phases. The resumed Phase 40 histogram would then describe a "head-support" region rather than brain only. Intracranial CSF stays inside any brain mask (Section 13.18).

**Constraints for Phases 49–52, added after the Phase 48 review:**

- **Head-support versus brain mask: a decision gate before Phase 52.**
  - In Phases 49–50 the mask may be conservative and include extracranial structures.
  - Before Phase 51/52 is closed, it must be **explicitly decided** whether the result is sufficiently intracranial to be used and named as a true brain (intracranial-support) mask, or whether it is essentially a **head-support mask**.
  - If it remains a head mask, this is not necessarily a failure, but it must be named as such. Extracranial structures would then remain admissible in the lesion search after Phase 52, and Phase 40 must **not** be resumed as a "brain-only" histogram until this inconsistency is resolved.
- **Phase 49 threshold order:**
  - First test a **single automatic rule estimated globally per volume** and applied slice by slice. This remains compatible with 2D processing.
  - Move to a slice-adaptive automatic rule only if the global rule clearly fails, for example because a per-slice threshold may fit pure background noise on the extreme slices of `pn3`.
- **Ring hypothesis:** the scalp-ring / skull-gap pattern remains a hypothesis. Hole filling or closing in Phase 50 is justified only if Phase 49 actually shows it.

**Unchanged:** open question 17 remains unresolved, and Phase 40 remains deferred. The specificity-region question (PROJECT_SPEC.md, Section 27.1) is not addressed here. `config.m` was not modified.

### 13.27 Phase 49: raw initial support mask (EXP-005)

**Method:** one global Otsu threshold per volume.

- `graythresh(volume(:))` uses all voxels, with no exclusion or pre-masking. For `double` input in [0,1], `graythresh` uses a 256-bin histogram, so T is quantized to those bins.
- The same scalar T is applied to every axial slice with `imbinarize` (foreground = value > T). The script verifies `mask == volume > T`.
- The rule is the same for `pn0` and `pn3`; each threshold is estimated from its own volume, and none was chosen by hand.
- Global per volume was chosen over per slice (Section 13.26): it is the simpler automatic baseline and avoids estimating thresholds on extreme slices that are mostly background. It involves no 3D spatial operator. Per-slice thresholds were not tested.
- Otsu is not an intensity-harmonization method; open question 17 remains open.

**Data and code:**

- T2, `msles2`, 1 mm, `rf0`; `pn0` and `pn3`, prepared as loader, then `double`, then /4095, with no filter.
- `src/segmentation/initialSupportMask.m` (the location follows PROJECT_SPEC.md, Section 23) and `experiments/initial_brain_mask_threshold.m`.
- Run in MATLAB R2026b on 2026-10-05.

**Checks (PASS):**

- input `double` in [0,1];
- one finite threshold in (0,1);
- mask size and `logical` class;
- mask neither all false nor all true;
- mask equal to `volume > T`;
- normalized volumes and raw files unchanged.

| | `pn0` | `pn3` |
|---|---:|---:|
| Otsu threshold T | 0.3059 (= 78/255) | 0.2941 (= 75/255) |
| Foreground voxels | 3,897,012 (54.82 %) | 3,827,124 (53.83 %) |
| Non-empty / empty slices | 181 / 0 | 181 / 0 |
| Foreground in first (k = 1) / last (k = 181) slice | 28,021 / 7,079 | 26,215 / 6,985 |

Cross-condition mask consistency (`pn0` versus `pn3`, MRI-only, descriptive; no cut-off): IoU 0.9797, with 1.11 % of voxels differing.
**Raw-mask observations** (`phase49_raw_masks_deterministic_slices.png`; mask-only views at deterministic slices k = 1, 46, 91, 136, 181; no MRI overlay):

- **Histograms** (`phase49_histograms_otsu_threshold.png`): in `pn0`, T lies in the valley just below the start of the main tissue intensities. In `pn3`, T lies well above the background-noise peak (about 0.03).
- **External background:** no speckles are visible outside the head on the shown slices, even in `pn3`.
- **Ring structure, now observed and no longer a hypothesis:** at k = 91 and k = 136 the mask shows an outer foreground ring (scalp), a thin unmasked ring (the skull, dark in T2) and a filled interior (brain). The raw output is therefore a **head-support mask**, not an intracranial mask.
- **Inferior slices:**
  - at k = 1 and k = 46, face and neck tissues are included, with dark unmasked regions (sinus/air-like structures);
  - in `pn3` there are many small scattered holes inside tissue, where noise crosses T;
  - at k = 46 the dark skull gap is incomplete in places.
- **Top slice:** at k = 181 the mask contains two horizontal bar-shaped regions that do not follow a head shape. They match the structure "above the head" seen in the Phase 32 coronal view, which BrainWeb describes as "strange stuff above the head" propagated from the scans used to build the model [S9]. The threshold includes it because it is bright.
- **Consistency:** all 181 slices are non-empty in both conditions, and `pn0` and `pn3` masks are very similar.

**Issues identified for Phase 50** (to be addressed there, not fixed here):

1. **Scalp ring versus brain:** where the skull gap is continuous, the scalp ring and the brain interior are separate 2D foreground regions. A 2D connected-component rule could isolate an intracranial region, but wherever the gap is broken (for example around k = 46) the two may be connected.
2. **Hole filling is a double-edged choice:** filling would close the small `pn3` noise holes and the interior dark regions, but filling inside a closed scalp ring would also fill the skull gap and turn the mask into a solid head mask. The choice determines whether the result can be a brain mask.
3. **Phantom artefact above the head:** the extent across the top slices still needs to be inspected.
4. **Inferior slices:** face, neck and air/sinus structures (and the extent of non-brain tissue there) need a decision.
5. **`pn3` speckle holes:** small isolated false negatives inside tissue.

**Status and terminology:** this is a **RAW support mask**, not a validated brain mask. The head-support versus brain-mask decision gate (Section 13.26) remains open for Phases 50–52.

No morphology, hole filling, connected components or manual edits were used; the GT, anatomical labels and held-out data were not used. Phase 40 remains deferred, and `config.m` was not modified.

**Outputs** (excluded from Git):

- masks: `data/processed/phase49_t2_pn0_initial_support_mask.mat`, `data/processed/phase49_t2_pn3_initial_support_mask.mat` (variables `mask`, `threshold`);
- metrics: `results/metrics/phase49_initial_support_mask.csv`;
- figures: `results/figures/phase49_histograms_otsu_threshold.png`, `results/figures/phase49_raw_masks_deterministic_slices.png`.

### 13.28 Phase 50: cleanup of the support mask (EXP-006)

**Status: BLOCKED / NEEDS REFINEMENT as a brain (intracranial) mask.** Candidate A is retained as a conservative **head-support** mask candidate.

**Input:** the Phase 49 raw masks, regenerated from T2 `pn0`/`pn3`. The thresholds exactly reproduce EXP-005 (78/255 and 75/255; check PASS).

**Order of operations:** `imfill` is **never** applied to the raw mask. In the raw mask the dark skull separates a scalp ring from the brain, so filling first would close the skull gap and produce a solid head. Holes are therefore filled only after a single component has been selected.

**Code:**

- `src/segmentation/cleanSupportMaskSlices.m`: 2D, slice by slice; optional `imopen`, then `bwconncomp` keeping only the largest component, then `imfill(..., 'holes')` on that component only;
- `experiments/brain_mask_cleanup.m`.

Run in MATLAB R2026b on 2026-10-05.

**Candidate A:** 8-connected 2D components per slice, keep the largest, then fill holes in it. There is no closing, no standalone erosion or dilation, no area threshold, no slice range, no position rule and no 3D processing. `imfill` uses its default background connectivity (4 in 2D), which is topologically consistent with 8-connected foreground.

| Candidate A | `pn0` | `pn3` |
|---|---:|---:|
| Raw foreground | 3,897,012 (54.82 %) | 3,827,124 (53.83 %) |
| Removed by component selection | 26,800 | 26,659 |
| Added by hole filling | 294,989 | 359,952 |
| Cleaned foreground | 4,165,201 (58.59 %) | 4,160,417 (58.52 %) |
| Components per slice before cleanup: median / max | 3 / 14 | 4 / 15 |
| Slices with more than one component | 133 | 149 |
| Non-empty / empty slices | 181 / 0 | 181 / 0 |

Cleaned-mask consistency (`pn0` versus `pn3`, descriptive): IoU 0.9982, with 0.11 % of voxels differing.

**Candidate A observations** (mask only: `phase50_raw_vs_clean_masks.png`, `phase50_candidateA_per_slice_diagnostics.png`):

- **Scalp not removed.** In the central slices (k = 46, 91, 136) the result is a **solid head disc**. The scalp ring is connected to the brain through interruptions of the thin dark skull ring, already visible in the raw masks at k = 91 and k = 136. The largest component is therefore scalp and brain together, and filling closes the skull gap. The per-slice diagnostics confirm this: almost nothing is removed in the central slices, while filling adds about 1,000–4,500 voxels per slice.
- **Face and neck** (k = 1) remain, merged into the head disc.
- **Top-slice artefact:** in about k = 170–181, component selection removes one of the two bars, but the other remains as the largest component. Large removals (more than 500 voxels) occur almost only there: 12 slices in `pn0`, 13 in `pn3`.
- **`pn3` noise holes:** filled.
- **External background:** clean.

**Candidate B: triggered and evaluated.**

- **Trigger,** documented after inspecting A and before interpreting B: the scalp remains attached to the selected component through narrow bridges at the skull-ring interruptions.
- **Definition:** a minimal 2D opening with `strel('square', 3)`, then the same steps as A. There was a single run, with no other sizes or shapes.
- **Opening changes:** 13,864 voxels in 180 slices (`pn0`); 71,763 voxels in 181 slices (`pn3`). Final foreground in `pn3`: 58.09 %.
- **Observations** (`phase50_candidateB_masks.png`):
  - k = 1, 46 and 91 are still solid head discs in both conditions, so the bridges are wider than a 3 × 3 opening can break;
  - at k = 136 the opening separates the brain in `pn0`, but with a jagged, partially missing upper border (fragmentation and loss of support), while the same slice in `pn3` remains a head disc, so the behaviour is unstable between conditions;
  - the top artefact remains.
- **Decision:** candidate B is **not retained**. It does not solve the scalp attachment, and it introduces fragmentation and `pn0`/`pn3` instability. Larger elements were not tried, as required.

**Selected cleanup rule (identical for `pn0` and `pn3`):** candidate A, that is the largest 8-connected 2D component per slice followed by hole filling. The output is a conservative **head-support** mask:

- it retains the brain;
- it has a clean background and filled noise holes;
- it still includes scalp, skull gap, face and neck, and the BrainWeb artefact in the top slices.

It is **not** an intracranial brain mask.

**Possible directions, not decided here** (a user decision before Phase 51/52):

1. **Accept a head-support mask:** name it as such, accept that scalp and fat (bright in T2) remain admissible in the lesion search, and do not resume Phase 40 as "brain-only".
2. **Separate the brain more strongly within allowed techniques:** for example a larger erosion to break the scalp–brain bridges, selection of the largest component, then reconstruction (morphological reconstruction, ALLOWED_TECHNIQUES.md, Section 6.6) or dilation back. This would be a new, explicitly declared candidate, outside the "no sweep" scope of the current Phase 50.
3. **Top-slice artefact:** no rule in Phase 50 removes it without a slice range or position heuristic, both of which are excluded. It needs an explicit decision.

No GT, anatomical labels, slice cutoff, area threshold, Gaussian filtering or held-out data were used. Preprocessing remains no filter, open question 17 remains open, and Phase 40 remains deferred. No MRI overlay was made, so Phase 51 has not started.

**Supplementary EXP-007 (still Phase 50): erode → select → dilate.**

- **Rationale:** in candidate B, `imopen` erodes and then dilates **before** component selection. If the erosion had broken the scalp–brain bridges, the dilation could have reconnected them first. EXP-007 changes only the position of the selection.
- **Pipeline:** raw mask, then `imerode` with `strel('square', 3)`, then the largest 8-connected component, then `imdilate` with the same element, then the logical AND with the raw mask, then `imfill` holes. The structuring element is the same as B, so no new parameter is introduced.
- **Code:** `src/segmentation/erodeSelectDilateSlices.m` and `experiments/brain_mask_erode_select.m`; run on 2026-10-05.
- **Decision rule, declared before the results:** EXP-007 replaces A only if the central deterministic slices show the scalp separated and an intracranial region retained, consistently for `pn0` and `pn3`, without evident fragmentation.
- **Morphological reconstruction** (`imreconstruct`) was deliberately not used first: with a binary path still connecting brain and scalp in the raw mask, reconstruction would propagate through it and restore the scalp.

| EXP-007 | `pn0` | `pn3` |
|---|---:|---:|
| Foreground fraction: raw / A / EXP-007 | 54.82 % / 58.59 % / 57.76 % | 53.83 % / 58.52 % / 56.76 % |
| Eroded voxels discarded by selection | 60,849 | 86,333 |
| Added by hole filling | 301,374 | 408,656 |
| EXP-007 foreground voxels | 4,106,241 | 4,034,949 |

Consistency between `pn0` and `pn3`: IoU 0.9821, with 1.03 % of voxels differing.

**Observations** (`exp007_raw_A_exp007_masks.png`, `exp007_area_per_slice.png`):

- At k = 1, 46 and 91 the result is still a **solid head disc** in both conditions. Even a 3 × 3 erosion does not break the scalp–brain bridges, so they are at least 3 pixels wide.
- At k = 136 the brain is separated in both conditions, but with a jagged, partly missing upper border. Part of the brain support is lost, which is the most serious error for a conservative mask.
- **Mask area per slice:** EXP-007 equals A almost everywhere. The scalp is removed only in a few isolated upper slices (about k = 123–126, 132–134 and 141–144, differing between `pn0` and `pn3`), with a few scattered dips in `pn3` at lower slices. The separation is therefore **intermittent along z**, which would give an inconsistent, partly head and partly brain mask.
- The top-slice artefact remains.

**Decision:** EXP-007 is **rejected**: the declared rule is not met, separation is intermittent, and brain support is lost where separation occurs. Candidate A remains the Phase 50 head-support candidate. Threshold, components, minimal opening and simple erosion/dilation have now been shown experimentally to be insufficient to separate the brain from the scalp.

This is the situation that ALLOWED_TECHNIQUES.md, Section 11 describes for **marker-controlled watershed**: region separation has become a specific problem that the simpler methods do not solve. This led to EXP-008, below.

**Supplementary EXP-008 (still Phase 50): marker-controlled watershed.**

- **Justification:**
  - EXP-006 and EXP-007 showed that threshold, components, minimal opening and simple erosion/dilation do not separate the brain from the scalp;
  - ALLOWED_TECHNIQUES.md, Section 11 allows watershed for exactly this case;
  - the course skull-removal exercise follows binarization, region extraction, removal of the skull–brain bridge, brain extraction and hole filling.
- **Single configuration, declared before the results; no sweep:**
  - **Morphological gradient:** `imdilate(I, ones(3)) − imerode(I, ones(3))` on the normalized T2 slice. No Sobel, Prewitt, Canny or LoG.
  - **Brain marker:** `imerode(raw ∩ A, strel('square', 5))`, then the largest 8-connected component.
    - `raw ∩ A` is the unfilled raw mask restricted to the candidate-A component. Using it guarantees, by construction, that the brain marker is disjoint from the non-brain marker; this was declared before the run.
    - The 5 × 5 erosion produces the **marker only**; the final boundary comes from the watershed, unlike EXP-007.
    - 5 × 5 is the next odd square after the failed 3 × 3, it is the only larger size tested, and it is not called optimal.
  - **Non-brain marker:** everything outside A, plus the peripheral shell `A ∧ ¬imerode(A, square 5)`.
  - **Watershed:** `imimposemin(gradient, brainMarker | nonBrainMarker)`, the course step "modify the segmentation function so that minima are imposed at marker locations" (checked against the installed documentation), then `watershed` with its default 2D connectivity of 8.
  - **Basin selection:** automatic. The brain basin is the most frequent watershed label under the brain marker; ridge pixels (label 0) are not included. The basin is then intersected with A and its holes are filled.
- **Code:** `src/segmentation/watershedBrainMaskSlices.m` and `experiments/brain_mask_watershed.m`; run on 2026-10-06.
- **Checks (PASS):**
  - EXP-005 thresholds and EXP-006 candidate-A counts reproduced exactly;
  - brain marker within the raw mask;
  - markers disjoint on all slices;
  - candidate logical and within A;
  - brain marker inside the candidate;
  - data unchanged.

| EXP-008 | `pn0` | `pn3` |
|---|---:|---:|
| Valid / empty brain-marker slices | 181 / 0 | 181 / 0 |
| Marker-overlap slices / marker on more than one label | 0 / 0 | 0 / 0 |
| Candidate foreground | 4,027,308 (56.65 %) | 3,899,546 (54.85 %) |
| Removed relative to A | 137,893 | 260,871 |
| Added by hole filling | 0 | 0 |
| Non-empty slices (first / last) | 181 (1 / 181) | 181 (1 / 181) |
| Slices with area ratio to A below 0.95 | 20 | 39 |

Consistency between `pn0` and `pn3`: IoU 0.9671, with 1.87 % of voxels differing.

**Observations** (`exp008_pn0_markers_and_candidate.png`, `exp008_pn3_markers_and_candidate.png`, `exp008_gradient_watershed_lines.png`, `exp008_area_ratio_per_slice.png`):

- **The watershed works when the marker is correct.** At k = 136 the 5 × 5 marker is separated, and the watershed ridge follows a continuous brain/skull boundary in both `pn0` and `pn3`. The resulting candidate is coherent, without the missing-border damage seen in EXP-007.
- **The brain marker fails in the central and inferior slices.** At k = 46 and k = 91 the scalp ring remains connected to the interior after the 5 × 5 erosion, so the scalp–brain bridges are about 5 pixels wide or more. The "brain" marker therefore covers scalp and brain, the selected basin is the whole head, and the candidate equals A (area ratio about 1).
- **Separation along z:** it occurs in `pn0` only at k = 112–115, 118, 124–126, 131 and 133–143. In `pn3` it occurs in about the same upper range, plus scattered slices around k = 35–55 and k = 101. It is therefore intermittent and differs between conditions.
- **Unresolved:** at k = 1 the face and neck remain, and at k = 181 the bar-shaped BrainWeb artefact remains (selected as the marker).

**Decision: EXP-008 REJECTED.** A declared rejection condition is met: the 5 × 5 brain marker remains a whole-head marker in the central slices. As a result, the central filled-head discs persist and the separation is intermittent along z and inconsistent between `pn0` and `pn3`. No other erosion size, gradient or marker definition was tried.

**Methodological conclusion:** in the slices where its marker is valid, the watershed itself separates the brain from the periphery plausibly. The failure lies in the **automatic brain-marker construction**: a fixed erosion of the raw mask cannot break scalp–brain bridges of about 5 pixels or more. Any further attempt would need a new, explicitly justified marker definition as a new experiment, not a tuned EXP-008.

**Phase 50 status:** BLOCKED / NEEDS REFINEMENT. Candidate A remains the conservative **head-support** fallback and is not promoted to a brain mask. `config.m` and `PROJECT_SPEC.md` were not changed.

**Supplementary EXP-009 (still Phase 50): reconstruction / regional-maxima foreground markers.**

- **Motivation:** EXP-008 showed that the watershed separates the brain plausibly when its foreground marker is internal; the failure was the binary-erosion marker. Following the course's marker-controlled watershed scheme, EXP-009 changed **only** the foreground-marker generator.
- **Fixed configuration; no sweep:**
  - opening by reconstruction: `imreconstruct(imerode(I, square 3), I, 8)`;
  - closing by reconstruction (the dual, on the complement): `imcomplement(imreconstruct(imcomplement(imdilate(J, square 3)), imcomplement(J), 8))`;
  - `imregionalmax(..., 8)`;
  - every 8-connected maximum component that does **not** touch the unchanged EXP-008 non-brain marker is kept. There is no largest-component rule and no size or position rule.
  - The reconstruction serves only to generate markers; the watershed still uses the 3 × 3 morphological gradient of the **original** image, unchanged from EXP-008.
  - **Basin selection:** the union of all watershed basins touched by any accepted foreground marker (ridges excluded), intersected with A, then hole filling.
- **Prediction declared before the run:**
  - in T2 the regional maxima lie mainly in CSF and in the bright scalp/subcutaneous layers;
  - the non-brain shell is only 2 pixels thick, so many scalp maxima would not touch it, would be accepted as "internal", and would bring the scalp back through their basins.
- **Code:**
  - `src/segmentation/reconstructionRegionalMaxMarkers.m`;
  - `src/segmentation/markerWatershedUnionSlices.m`;
  - `experiments/brain_mask_reconstruction_markers.m`.

  Run on 2026-10-06; documentation of `imreconstruct`, `imregionalmax` and `imcomplement` checked in the installed MATLAB.
- **Technical checks (PASS):** EXP-005 and candidate A reproduced; markers disjoint; candidate logical and within A; data unchanged.

| EXP-009 | `pn0` | `pn3` |
|---|---:|---:|
| Regional-maximum components: total / retained / rejected (touching the non-brain marker) | 14,309 / 9,581 / 4,728 | 9,716 / 7,930 / 1,786 |
| Slices with 0 / 1 / several retained markers | 0 / 0 / 181 | 0 / 3 / 178 |
| Marker-overlap slices | 0 | 0 |
| Slices where a selected basin also contains non-brain-marker pixels | 56 | 54 |
| Candidate foreground | 3,126,339 (43.98 %) | 3,082,094 (43.35 %) |
| Removed relative to A / added by filling | 1,038,862 / 101,262 | 1,078,323 / 87,800 |
| Slices with area ratio to A below 0.95 | 159 | 160 |

Consistency between `pn0` and `pn3`: IoU 0.8385, with 7.67 % of voxels differing.

**Observations** (`exp009_pn0_markers_and_candidate.png`, `exp009_pn3_markers_and_candidate.png`, `exp009_area_ratio_per_slice.png`):

- **Accepted markers:** they are scattered over the whole head, including many **peripheral scalp arcs** (visible at k = 46, 91 and 136) that do not touch the 2-pixel shell. This confirms the declared prediction.
- **Candidate structure:** the candidate is a **mosaic** of hundreds of basins crossed by black watershed ridge lines, so it is severely fragmented. The area ratio of about 0.7 comes mainly from these ridge lines and from uncovered basins, not from genuine scalp removal; at k = 46 the outer scalp ring is still included.
- **k = 136 is degraded:** the successful EXP-008 separation is lost, and the slice becomes a solid head disc again, because basins seeded in the scalp are included. The same happens across about k = 128–146.
- **k = 1** (face/neck) and **k = 181** (BrainWeb artefact, fragmented): both remain.
- **Conflict basins:** a selected basin contains non-brain pixels in 54–56 slices. `imimposemin` should give each marker component its own basin, so this needs explanation; one possible cause is that some marker components fall on watershed ridges or that adjacent marker pixels are imposed as a single minimum. It is recorded and not investigated further, as EXP-009 is rejected on other grounds.

**Decision: EXP-009 REJECTED.** Several declared rejection conditions are met:

- the regional maxima include peripheral scalp structures;
- k = 46 and k = 91 are not resolved;
- the final mask is strongly fragmented;
- the good k = 136 separation is lost;
- `pn0` and `pn3` are less consistent;
- face, neck and the artefact remain.

No other reconstruction size, shell, gradient or marker scheme was tried, and **no EXP-010 was started**.

**Phase 50 status:** BLOCKED / NEEDS REFINEMENT. Candidate A remains the **head-support fallback only**. `config.m` and `PROJECT_SPEC.md` were not changed.

**Methodological conclusion of Phase 50 (EXP-006 to EXP-009):**

- On T2, every course-based approach tested fails to separate the brain from the scalp: threshold with components, minimal opening, erode–select–dilate, marker-controlled watershed with an erosion marker, and with reconstruction/regional-maxima markers.
- The watershed delimits the brain plausibly only where an internal marker exists (EXP-008, about k = 112–144).
- The obstacle is the T2 contrast: the scalp is bright like the brain, and is connected to it across the thin dark skull. Bright CSF and scalp also both produce regional maxima.
- A **strategic decision** is now required, outside Phase 50:
  1. formally accept a head-support mask, with the corresponding specification changes; or
  2. reconsider the source modality for brain-mask extraction, for example T1 as a dedicated brain-mask modality, alongside T2 for lesion detection.

  Neither option is implemented.

**Supplementary EXP-010 (still Phase 50): T1 brain-mask feasibility.**

- **Strategic reason:** the T2 brain-mask branch (EXP-005 to EXP-009) is documented as unsuccessful. In T2 the scalp and the brain are both bright and connected across the thin dark skull. EXP-010 changes **one factor only**: the brain-mask source modality, from T2 to T1.
  - T1 is evaluated **only as an anatomical support modality for the mask**.
  - T2 remains the provisional lesion modality, and `cfg.dataset.modality` is unchanged.
  - This is not a lesion modality comparison and not multimodal lesion fusion. The intended architecture, if successful, would be T1 → brain support mask and T2 → lesion segmentation inside that support.
- **Data:**
  - `t1_ai_msles2_1mm_pn0_rf0.raws` was already present.
  - `t1_ai_msles2_1mm_pn3_rf0.raws` was **downloaded on 2026-10-06** from the official server with the documented procedure:
    - download page "T1 AI msles2 1mm pn3 rf0", "Modality=T1, Protocol=AI, Phantom_name=msles2, Slice_thickness=1mm, Noise=3%, INU=0%", with the same grid;
    - 14,218,274 bytes; SHA-256 `ac7c6136d99f83fc6bcbf44111d2541996a146e946433f8af2f39e95a9d8b8fe`;
    - little-endian, values 0…4095;
    - recorded in `DOWNLOAD_INFO.txt`; no held-out data downloaded.
  - `config.m` gained only the path `cfg.dataset.noisyMriFiles.pn3.T1`.
- **Geometry:** T1 and T2 share size 181 × 217 × 181, the same loader convention, 1 mm, `rf0` and `msles2` (check PASS). The T1 mask was not applied to T2.
- **Method:** identical to Phase 49, with no cleanup. The steps are `double`, /4095, no filter, then one global Otsu threshold (`graythresh` on all voxels) applied to every slice. `initialSupportMask.m` was reused unchanged, as it contains nothing T2-specific. Connected components were counted only as a diagnostic.
- **Code:** `experiments/brain_mask_t1_feasibility.m`; run on 2026-10-06. Checks PASS, including the reproduction of the EXP-005 T2 thresholds used as reference.

| T1 raw mask | `pn0` | `pn3` |
|---|---:|---:|
| Otsu threshold | 0.2588 (66/255) | 0.2510 (64/255) |
| Foreground | 2,771,291 (38.98 %) | 2,727,314 (38.36 %) |
| Non-empty / empty slices | 181 / 0 | 181 / 0 |
| Foreground in k = 1 / k = 181 | 21,558 / 2,909 | 21,113 / 2,760 |
| Components per slice (8-conn), median / max | 11 / 42 | 16 / 50 |
| Slices with more than one component | 175 | 180 |
| Median area of largest / second-largest component | 12,574 / 3,635 | 12,444 / 3,509 |

Consistency of the T1 raw masks (`pn0` versus `pn3`): IoU 0.9755, with 0.96 % of voxels differing. For comparison, the T2 raw mask covers about 54–55 % of the volume.

**Observations** (`exp010_pn0_t1_vs_t2_raw_masks.png`, `exp010_pn3_t1_vs_t2_raw_masks.png`, `exp010_t1_histograms_otsu.png`):

- **Histograms:** T lies in the valley between the dark group (which in T1 includes CSF and skull) and the tissue intensities.
- **k = 91 and k = 136:** in T1 the scalp ring is separated from the brain interior by a **broad, continuous dark band**, because skull and CSF are both dark in T1. The brain appears as a distinct internal object, with internal holes (dark ventricles and sulci) and a jagged cortical edge. In T2 the separation is a thin, interrupted line, and the raw mask is a connected head.
- **k = 46:** the separation is largely present. The anterior orbital region is more complex, and some contact between peripheral and internal foreground may exist there.
- **k = 1:** face and neck form one connected tissue mass in T1 as well, so there is no improvement.
- **k = 181:** the BrainWeb artefact remains; one bar is selected, with fragments of the second.
- **`pn0` and `pn3`:** same qualitative structure; `pn3` has slightly more speckle.
- **Component statistics:** a second-largest component of about 3,600 pixels (median) suggests that the scalp and the brain often form separate objects.

**Decision: EXP-010 PROMISING.**

- In the central slices the T2 head-disc connectivity problem is substantially reduced in the raw T1 mask.
- Brain-like internal foreground and peripheral foreground are naturally more separable.
- The pattern appears in both `pn0` and `pn3`.

This does **not** mean that the brain mask is complete. Face/neck and the top artefact remain, and the T1 raw mask has internal holes and a jagged cortical boundary that a later cleanup would have to handle.

**Phase 50 status:** still **BLOCKED / NEEDS REFINEMENT**. A T1 branch is now justified for a later cleanup experiment, which has not been started. Candidate A (T2) remains the head-support fallback. `PROJECT_SPEC.md` was not changed; this is a development finding, not a method.

**Next question for a later T1 cleanup experiment** (not implemented): does a simple automatic rule on the T1 raw mask select the **intracranial** component rather than the scalp ring consistently across slices and in both `pn0` and `pn3`? The rule could be, for example, the largest 8-connected component per slice followed by hole filling. The known T2 risk applies: near the vertex or in inferior slices, the scalp or face component may be larger than the brain section.

**Supplementary EXP-011 (still Phase 50): T1 largest component + hole filling.**

- **Question:** does the unchanged candidate-A rule (EXP-006), applied to the EXP-010 T1 raw mask, select the intracranial component consistently across slices and in both `pn0` and `pn3`?
- **Method:** T1 → `double` → /4095 → no filter → global Otsu per volume (EXP-010, thresholds and raw foreground reproduced exactly) → per slice, the largest 8-connected component → `imfill(..., 'holes')`. `initialSupportMask.m` and `cleanSupportMaskSlices.m` were reused unchanged (`cleanSupportMaskSlices(rawMask, 8, [])`). No other morphology, area threshold, position rule, inter-slice continuity rule, 3D processing or ground truth. The second-largest component area per slice was recorded as a diagnostic only.
- **Code:** `experiments/brain_mask_t1_largest_component.m`; run on 2026-10-06. Checks PASS (EXP-010 reproduced, logical output of the same size, voxel accounting, input and raw data unchanged).

| T1 EXP-011 candidate | `pn0` | `pn3` |
|---|---:|---:|
| Raw foreground (EXP-010) | 2,771,291 | 2,727,314 |
| Removed by component selection | 678,221 | 671,955 |
| Added by hole filling | 472,005 | 491,195 |
| Candidate voxels | 2,565,075 (36.08 %) | 2,546,554 (35.82 %) |
| Non-empty / empty slices | 181 / 0 | 181 / 0 |
| Components per slice (8-conn), median / max | 11 / 42 | 16 / 50 |
| Median largest / second-largest area | 12,574 / 3,648 | 12,444 / 3,512 |
| Largest-to-second area ratio, median / minimum | 3.92 / 1.020 | 4.15 / 1.001 |

The median second-largest area here is taken over the slices that have a second component; EXP-010 reported 3,635 / 3,509 with a different slice set, so the two values are not contradictory.

Consistency of the candidates (`pn0` versus `pn3`): IoU 0.9616, with 1.4065 % of voxels differing (EXP-010 raw masks: IoU 0.9755).

**Observations** (`exp011_t1_area_per_slice.png`, `exp011_t1_pn0_cleanup_steps.png`, `exp011_t1_pn3_cleanup_steps.png`):

- **Central slices (about k = 46–133):** the selected component is the brain section. The scalp ring is removed and filling only closes ventricles and sulci (final area close to the largest-component area). Same result in `pn0` and `pn3` at k = 46 and k = 91 (at k = 46 the selected object is the temporal lobes and cerebellum).
- **Inferior slices (about k = 1–15):** face and neck form the largest component and filling turns it into a head disc (k = 1: largest 21,331, final 27,754 in `pn0`).
- **About k = 37–44:** filling again produces a head-sized area (k = 37: largest 17,779, final 27,135 in `pn0`), i.e. the selected object encloses the head, not the brain.
- **Upper slices (about k = 134–165):** the brain section and the scalp ring have almost the same area (ratio close to 1, e.g. k = 134: 3,792 versus 3,694). Which one wins is decided by a few pixels:
  - at k = 136 `pn0` selects the scalp ring, which filling turns into a whole-head disc (3,493 → 16,141), while `pn3` selects a small brain fragment (3,374 → 3,413). The two noise conditions select **structurally different objects** in the same slice;
  - k = 143 shows the opposite (`pn0` 4,166 → 4,323; `pn3` 3,955 → 14,312);
  - from about k = 144 to k = 162 the ring is filled into a disc in both conditions.
- **About k = 16–36:** the largest-component areas of `pn0` and `pn3` differ markedly in some slices (e.g. k = 36: 10,993 versus 6,457), so the selected object is not stable across noise there either.
- **Top slices (about k = 170–181):** the BrainWeb artefact bar is selected (k = 181).
- **Descriptive count (post hoc, not a decision rule):** in 136 (`pn0`) and 135 (`pn3`) slices hole filling adds at most 30 % to the selected component; the slices above that ratio coincide with the ranges listed above (`pn0`: k = 1–15, 37, 39–44, 135–138, 144–162; `pn3`: k = 2–15, 37–44, 135, 137–139, 143–162).

**Decision: EXP-011 REJECTED AS FINAL PHASE-50 METHOD BUT CENTRAL T1 BRAIN/SCALP SEPARATION CONFIRMED.**

- The T1 contrast hypothesis of EXP-010 is confirmed: where the brain section is clearly the largest object, the largest-component rule isolates it from the scalp in both `pn0` and `pn3`.
- The rule fails because "largest component per slice" does not identify the brain at the volume extremes. Failure category **B (automatic component identity at the volume extremes / across z)**, not A (insufficient brain/scalp contrast) and not C (both): where the brain is selected, the T1 contrast is sufficient.
- The resulting mask is a mixture of brain slices, head discs and artefact slices, so it is neither a brain mask nor a clean head-support mask. It is **not** adopted, and the voxel totals above must not be read as brain volume.

**Phase 50 status:** still **BLOCKED / NEEDS REFINEMENT**. Candidate A (T2) remains the head-support fallback. `PROJECT_SPEC.md` and `config.m` were not changed; `cfg.dataset.modality` remains T2.

**Strategic question for the user** (no EXP-012 started): which automatic, GT-free rule should identify the intracranial component across z, given that the per-slice area is ambiguous at the extremes? The rule must be declared before results and must not use lesion or label information.

**Supplementary EXP-012 (still Phase 50): T1 topology-based nested-component selection.**

- **Motivation:** EXP-011 showed that T1 contrast already separates brain and scalp in the central slices; the remaining problem is the **identity** of the selected component, because "largest component" fails at the volume extremes. EXP-012 changes **only the component-selection rule**: everything else (T1, global Otsu per volume, `pn0` + `pn3`, no filter, 8-connected components, 2D slice by slice, final hole filling, no GT) is unchanged.
- **Nature of the method:** an automatic topology-based component-selection rule implemented using the course-compatible connected-component and hole-filling operations (plus logical operations). It is not presented as a separate segmentation technique.
- **Rule, per slice** (`selectNestedSupportComponentSlices.m`):
  1. components C1…Cn of the raw mask (`bwconncomp`, 8-connectivity); none is assumed to be brain or scalp;
  2. for each Ci alone: enclosedRegion_i = `imfill(Ci, 'holes')` AND NOT Ci. This filling is used **only to test enclosure**, never as output. `imfill` uses its default 4-connected background, the topological complement of 8-connected foreground;
  3. Cj (j ≠ i) is **nested in Ci** only if **every** pixel of Cj lies in enclosedRegion_i (complete containment, no partial overlap, no tolerance); one enclosing parent is enough. Ci is called an enclosing component; no anatomical meaning is assigned to it;
  4. the nested component with the largest area is selected (ties: first in `bwconncomp` order). This is the only area comparison;
  5. final `imfill(..., 'holes')` of the selected component only (the second, conceptually different use of hole filling).
  - **No nested component → empty slice.** No fallback to EXP-011, to neighbouring slices or to any other component.
  - No other morphology, no area threshold of any kind, no position, centroid, bounding-box, slice-range or z rule, no 3D.
- **Code:** `experiments/brain_mask_t1_nested_components.m`; run on 2026-10-06. Checks PASS (input double in [0, 1], EXP-010 threshold and raw foreground reproduced, 8-connectivity, raw mask unchanged, selected component ⊆ raw mask, candidate = fill(selected) in every slice, empty output wherever no nested component exists, input and raw data unchanged). The script never loads GT or anatomical labels.

| T1 EXP-012 candidate | `pn0` | `pn3` |
|---|---:|---:|
| Slices with / without a nested candidate | 152 / 29 | 159 / 22 |
| Enclosing components per slice, median / max | 1 / 2 | 1 / 2 |
| Nested components per slice, median / max | 7 / 26 | 8 / 34 |
| Median selected nested area (slices with a candidate) | 11,491 | 10,718 |
| Slices with the same component as EXP-011 | 95 | 94 |
| Slices with a different component from EXP-011 (non-empty / including empty) | 57 / 86 | 65 / 87 |
| Added by final filling | 79,984 | 83,573 |
| Candidate voxels | 1,536,369 (21.61 %) | 1,516,701 (21.33 %) |
| First / last non-empty slice | 1 / 164 | 1 / 169 |

Slices without a nested candidate: `pn0` k = 18, 29–31, 33–36, 38, 161–163, 165–181; `pn3` k = 27, 29–36, 161, 170–181.

Consistency `pn0` versus `pn3`: IoU 0.9830, 0.3685 % of voxels differing. Candidate in both: 150 slices; only `pn0`: 2 (k = 27, 32); only `pn3`: 9 (k = 18, 38, 162–163, 165–169); neither: 20. The IoU is dominated by the large central slices.

**Observations** (`exp012_t1_area_per_slice.png`, `exp012_t1_pn0_nested_steps.png`, `exp012_t1_pn3_nested_steps.png`, `exp012_t1_enclosure_relation.png`; plus a scratch-only rendering of the saved selections at k = 12, 40, 43, 44, 139, 143, 146, 150, 155, 158, used only to describe the transitions, not to change anything):

- **k = 1:** the face/neck mass is **not** selected. It encloses a small separate component (105 px in `pn0`, 104 in `pn3`), which is selected. k = 1 is therefore not empty; the selected object is small and its anatomical identity is not claimed.
- **k = 46:** the internal brain-like component is nested inside the peripheral ring and selected; the ring is excluded. Same component as EXP-011, in both conditions.
- **k = 91:** the brain-like component is nested and selected; same component as EXP-011 in both conditions.
- **k = 136 (key test):** the peripheral ring is **rejected** in both conditions (it is not nested). Both `pn0` and `pn3` select the **same internal object**: one cerebral hemisphere (3,417 and 3,374 px). The EXP-011 identity switch is resolved, but the other hemisphere is a separate nested component and is lost.
- **k = 181:** the artefact bars are not enclosed by anything, so no candidate exists and the slice is empty in both conditions.
- **Central slices (k = 45–134):** identical selection to EXP-011 (brain section) in both conditions; the other slices with the same selection as EXP-011 are k = 139–143 (`pn0`) and k = 136, 140–142 (`pn3`).
- **Upper slices (k = 134–160):** the intracranial foreground splits into several nested components (mainly the two hemispheres), and the rule keeps only one. The selected area falls from about 3,800 px to 30 px; it is consistently a single hemisphere or cortical fragment. Transient differences between noise conditions: k = 139 (`pn0` 5,605 px, both hemispheres connected; `pn3` 2,836 px, one hemisphere) and k = 143 (4,166 versus 2,508). From k = 161 the slices are empty, apart from 1–2 px specks in `pn3` (k = 162–169) and `pn0` (k = 164).
- **Inferior slices (k = 1–39):** the internal tissue is not enclosed by a separate component, so only small nested objects are selected: 105–485 px for k = 1–12 (a small round object in the posterior midline at k = 1 and k = 12), 2–78 px for k = 13–39 (speckle-sized), or nothing.
- **k = 40–44:** k = 40–42 select a cerebellum-like component (about 6,500 px) in both conditions. At k = 43, `pn0` selects it (6,583 px) while `pn3` selects a 165 px fragment. At k = 44 only one temporal-lobe-like component (about 1,950 px) is selected.
- **No whole-head disc** in any slice: final filling adds only 79,984 / 83,573 voxels in total. The scalp ring, the face/neck mass and the artefact are never selected.

**Decision: EXP-012 PROMISING BUT INCOMPLETE.**

- Solved: **component identity**. The selected object is always an internal (enclosed) component. Scalp, face/neck mass and artefact are never selected; no head discs are produced; k = 136 is consistent across `pn0` and `pn3`. The central T1 separation is preserved unchanged.
- Remaining limitation: **completeness**. Selecting **one** nested component per slice truncates the support wherever the intracranial foreground consists of several nested components (two hemispheres for about k ≥ 134, cerebellum and temporal lobes around k = 40–44). In inferior slices (about k ≤ 39) the internal tissue is not enclosed by a separate component, so only small or speckle-sized nested objects are selected, and the vertex slices are empty. A few transition slices differ between `pn0` and `pn3` (k = 43, 139, 143).
- The candidate is not complete enough to justify Phase 51. Missing slices are **not** filled. The voxel totals are not a brain volume.

**Phase 50 status:** still **BLOCKED / NEEDS REFINEMENT**. Candidate A (T2) remains the head-support fallback. `PROJECT_SPEC.md` and `config.m` were not changed; `cfg.dataset.modality` remains T2. No EXP-013 was started.

**Open question for the user:** whether, and by which pre-declared rule, more than one nested component per slice may be kept (for example all nested components inside the same enclosing parent), and how the inferior slices, where no enclosure exists, should be handled.

**Supplementary EXP-013 (still Phase 50): T1 immediate-parent sibling union.**

- **Motivation:** EXP-012 solved component **identity** but kept one nested component per slice, so the support is incomplete where the intracranial foreground is split (one hemisphere at k = 136; one cerebellar or temporal part at k = 40–44). EXP-013 changes **only the selection rule**: the EXP-012 component becomes an **anchor**, and all **direct children of the anchor's immediate parent** are selected.
- **Nature of the method:** an automatic topology-based connected-component selection refinement built only from allowed connected-component, hole-filling and logical operations. It is not a separately taught segmentation technique.
- **Rule, per slice** (`selectSiblingSupportComponentsSlices.m`; the enclosure logic is duplicated, and `selectNestedSupportComponentSlices.m` is unchanged):
  1. enclosure relation **identical to EXP-012**: Ci encloses Cj (j ≠ i) iff every pixel of Cj lies in `imfill(Ci,'holes') AND NOT Ci` (8-connected components, complete containment, no tolerance);
  2. anchor = the EXP-012 selection (largest nested component; first index on ties). No anchor → empty slice;
  3. **immediate parent** of each nested component = among the components that enclose it, the one with the **smallest enclosed-region area**; on a tie, the lowest `bwconncomp` index, recorded as a tie. Area here only orders a hierarchy of components that already completely contain the child; it never removes a component;
  4. **selection = all components whose immediate parent equals the anchor's immediate parent** (the anchor included). The parent itself is never selected, and neither are grandchildren or children of other parents;
  5. **each selected child is filled individually** (`imfill(...,'holes')`), then the union is taken. The union is **not** filled again;
  6. no area threshold of any kind (sibling size, ratio, fraction of the parent), no fallback, no position, z or 3D rule, no other morphology, no GT.
- **Code:** `experiments/brain_mask_t1_sibling_components.m`; run on 2026-10-06. Checks PASS, including checks independent of the function:
  - the anchor is identical to the saved EXP-012 `selectedMask`, and the filled anchor equals the EXP-012 candidate;
  - every selected child lies in the parent's enclosed region and in no other enclosed component's enclosed region;
  - the parent is never in the candidate;
  - the candidate equals the union of the individually filled children;
  - the output is empty where there is no anchor;
  - input and raw data are unchanged.

| T1 EXP-013 candidate | `pn0` | `pn3` |
|---|---:|---:|
| Slices with / without anchor | 152 / 29 | 159 / 22 |
| Parent ties | 0 | 0 |
| Enclosing parents of the anchor, median / max | 1 / 1 | 1 / 1 |
| Direct children per slice (slices with anchor), median / max | 7 / 26 | 7 / 34 |
| Slices with siblings added beyond the anchor | 136 | 143 |
| Raw sibling area added | 44,478 | 48,655 |
| Final area added over EXP-012 | 44,820 | 49,245 |
| Area that filling the union would have added (not used) | 0 | 0 |
| Candidate voxels | 1,581,189 (22.24 %) | 1,565,946 (22.03 %) |
| First / last non-empty slice | 1 / 164 | 1 / 169 |

Empty slices are those of EXP-012 (no anchor), by construction.

Consistency `pn0` versus `pn3`: IoU 0.9851, 0.3327 % of voxels differing (EXP-012: 0.9830, 0.3685 %). Candidate in both: 150 slices; only `pn0`: 2; only `pn3`: 9; neither: 20. The direct-child count differs between `pn0` and `pn3` in 121 slices, mostly by a few small components. Siblings are added in both conditions in k = 1–16, 37, 39–76, 80–157 and 164; only in `pn0` at k = 19 and 28; only in `pn3` at k = 21–22, 38, 78–79, 158–160 and 162.

**Where the area is added:**

| k range | Added area, `pn0` | Added siblings, `pn0` | Added area, `pn3` | Added siblings, `pn3` |
|---|---:|---:|---:|---:|
| 1–39 | 3,559 | 232 | 3,921 | 352 |
| 40–49 | 7,272 | 124 | 7,087 | 181 |
| 50–133 | 7,472 | 531 | 7,178 | 568 |
| 134–181 | 26,517 | 186 | 31,059 | 239 |

**Observations** (`exp013_t1_area_per_slice.png`, `exp013_t1_pn0_siblings_steps.png`, `exp013_t1_pn3_siblings_steps.png`; predeclared diagnostic slices 1, 40, 43, 44, 46, 91, 136, 139, 143, 181, with no special processing):

- **Hierarchy:** every anchor has exactly **one** enclosing component, and there are no parent ties. In practice the direct children of the anchor's parent are almost all the nested components of the slice (k = 1: 13 of 13 in `pn0`; k = 136: 10 of 10). So the "same immediate parent" constraint barely restricts the set compared with "all nested components".
- **k = 1:** the immediate parent is the face/neck mass, which is not selected. Its 13 (`pn0`) / 19 (`pn3`) direct children are all small objects around the anchor (227 / 214 px in total). These small unwanted components are added; the face/neck mass stays excluded.
- **k = 40:** the parent is the large peripheral component, which at this level **also contains the lateral temporal-like tissue and the orbital region**. The cerebellum-like anchor is kept. Siblings add only small objects (midline fragments and a thin posterior crescent inside the ring): 6,881 → 7,279 px (`pn0`).
- **k = 43:** in `pn0` it is the same as k = 40 (6,832 → 7,268). In `pn3` the cerebellum-like region is **part of the parent component** itself, so it cannot be a child. The candidate stays small (171 → 534 px, small fragments only). The `pn0`/`pn3` discrepancy is **not** reduced.
- **k = 44:** one temporal-like anchor plus small anterior and lateral fragments (1,987 → 2,674 px in `pn0`; 1,959 → 2,603 in `pn3`). The other inferior parts are inside the parent component, so there is no meaningful completeness gain.
- **k = 46:** the central selection is preserved, but siblings add objects in the **anterior orbital region** and small fragments (11,656 → 13,178 px in `pn0`; 11,437 → 13,049 in `pn3`).
- **k = 91:** practically unchanged (18,456 → 18,469 in `pn0`; 18,413 → 18,423 in `pn3`).
- **k = 136 (key completeness test):** both hemisphere-like components are direct children of the same ring parent and **both are recovered** in `pn0` (3,451 → 6,843 px) and `pn3` (3,413 → 6,776). The outer ring stays excluded, and `pn0`/`pn3` are now structurally consistent.
- **k = 139 and k = 143:** the EXP-012 `pn0`/`pn3` differences disappear: 5,895 versus 5,841 px at k = 139, and 4,369 versus 4,218 px at k = 143. Both conditions show both hemispheres.
- **Upper slices (k = 134–150):** the area roughly doubles where the hemispheres are separate (for example k = 134: 3,885 → 7,709 in `pn0`). The candidate area now decreases smoothly toward the vertex. Some slices near the vertex gain almost nothing (k = 155: 972 → 999).
- **k = 181:** no anchor, so the slice is empty; the artefact is not introduced.
- **Unchanged:** no whole-head disc anywhere. Filling the union would have added nothing (0 px in both conditions). The scalp ring, the face/neck mass and the artefact are never selected.

**Decision: EXP-013 REJECTED as the Phase-50 candidate. Its specific positive finding is confirmed: direct-sibling union recovers the split hemispheres in the upper slices and makes `pn0`/`pn3` consistent there.**

- **Rejection condition met:** sibling union adds **many small nested objects of uncertain identity** (hundreds of components in k = 1–49, for example around the k = 1 anchor, posterior crescents at k = 40–43, and anterior orbital-region objects at k = 44–46). Removing them would need a size or other filter, which this experiment forbids.
- **Not achieved:** a completeness gain at k = 40–44. The missing inferior tissue (temporal-like regions, and the cerebellum-like region in `pn3` at k = 43) belongs to the **parent component itself**, which is 8-connected to the peripheral foreground. No child-selection rule can recover it, and the k = 43 `pn0`/`pn3` discrepancy remains.
- **Still missing:** inferior slices (k ≲ 39) and vertex slices without enclosed internal tissue, as in EXP-012.
- **Precise remaining problems:**
  - (a) the topological family is **not specific**: the same parent encloses brain fragments and small unrelated objects;
  - (b) in the inferior slices, brain-like tissue is **connected to the peripheral component** and is therefore not a separate object at all.

**Phase 50 status:** still **BLOCKED / NEEDS REFINEMENT**. Candidate A (T2) remains the head-support fallback. `PROJECT_SPEC.md` and `config.m` were not changed; `cfg.dataset.modality` remains T2. No EXP-014 was started, and marker-controlled watershed on T1 is not implemented.

**Supplementary EXP-014 (still Phase 50): T1 marker-controlled watershed with topology-derived markers.**

- **Why watershed now:**
  - After EXP-013, selecting among components that are already separate was exhausted: in the inferior slices the brain-like tissue is 8-connected to the peripheral component, and no component-selection rule can split a connected component.
  - Marker-controlled watershed is the course-compatible region-separation method for this.
  - T1 was chosen because EXP-010 to EXP-013 established a broader dark brain/periphery band, `pn0`/`pn3` stability and a reliable topological anchor identity.
- **Difference from EXP-008:** EXP-008 was a T2 watershed whose foreground marker came from a 5×5 erosion and covered the whole head in the central slices (a marker failure). EXP-014 is a T1 watershed whose foreground marker is the topology-derived EXP-012 anchor, which has high identity confidence. It is not a rerun of EXP-008.
- **Why the EXP-012 anchor and not EXP-013:** a smaller marker with reliable identity is preferred over a larger, less specific one (EXP-013 added many uncertain small objects).
- **One predeclared configuration** (`watershedFromTopologyMarkersSlices.m`), with no sweep. Per slice:
  1. **Topology:** enclosure relation and anchor identical to EXP-012. No anchor → empty slice and no watershed.
  2. **Immediate parent P:** chosen with the EXP-013 rule.
  3. **Foreground marker:** the raw anchor, unchanged (not eroded, not enlarged, no siblings added).
  4. **Support domain:** `filledParent = imfill(P,'holes')`, used only as a support domain.
  5. **Non-brain marker:** `NOT filledParent OR (P AND filledParent AND NOT imerode(filledParent, strel('square',3)))`. This keeps only the **outer** 3×3 edge of P. *Specification clarification, decided with the user before the run and not a tuning step:* the prompt's literal formula `P AND NOT imerode(P, square3)` would also mark the edges around P's internal holes, contradicting the stated "outer boundary band" intent. The conceptual requirement takes precedence, so internal parent edges stay free.
  6. **Gradient:** 3×3 morphological gradient of the **original normalized T1** slice, `imdilate(I, ones(3)) - imerode(I, ones(3))`. No other operator.
  7. **Watershed:** `imimposemin(gradient, foreground OR non-brain)`, then `watershed` (default connectivity, 8 in 2D).
  8. **Candidate:** union of the positive labels touched by the anchor (ridge label 0 excluded), AND filledParent, AND NOT non-brain marker; then one `imfill(...,'holes')`.
  - No EXP-013 siblings appended, no area threshold, no position, z or 3D rule, no GT. The only morphology is the 3×3 erosion for the boundary band and the final filling.
- **Code:** `experiments/brain_mask_t1_topology_watershed.m`; run on 2026-10-06. Checks PASS:
  - EXP-010 reproduced;
  - the anchor equals the saved EXP-012 `selectedMask`, and the parent equals the saved EXP-013 `parentMask`;
  - the non-brain marker, recomputed independently, matches;
  - marker overlap is 0;
  - gradient, watershed, basin selection and ridges recomputed independently on the 10 diagnostic slices match;
  - the candidate lies inside the filled parent, and slices without an anchor are empty;
  - input and raw data are unchanged.

| T1 EXP-014 candidate | `pn0` | `pn3` |
|---|---:|---:|
| Slices with / without anchor | 152 / 29 | 159 / 22 |
| Parent ties / marker-overlap slices | 0 / 0 | 0 / 0 |
| Positive labels under the anchor, median / max; slices with > 1 | 1 / 1; 0 | 1 / 1; 0 |
| Added by final filling | 0 | 0 |
| Non-brain pixels in the final candidate | 0 | 0 |
| Candidate voxels | 2,296,618 (32.31 %) | 2,280,974 (32.09 %) |
| Slices expanded / shrunk versus EXP-012 | 148 / 0 | 153 / 0 |
| Net gain over EXP-012 | 760,249 | 764,273 |
| of which k = 1–39 / 40–49 / 50–133 / 134–181 | 76,166 / 118,715 / 408,955 / 156,413 | 50,987 / 134,469 / 414,477 / 164,340 |
| Median EXP-014 / EXP-012 area ratio (slices with anchor) | 1.460 | 1.500 |
| Median EXP-014 / filledParent area ratio | 0.814 | 0.816 |
| Non-empty slices; first / last | 152; 1 / 164 | 159; 1 / 169 |

(EXP-012: 1,536,369 / 1,516,701 voxels; EXP-013: 1,581,189 / 1,565,946.)

Consistency `pn0` versus `pn3`: IoU 0.9717, 0.9236 % of voxels differing. This is worse than EXP-012 (0.9830, 0.3685 %) and EXP-013 (0.9851, 0.3327 %). Candidate in both: 150; only `pn0`: 2; only `pn3`: 9; neither: 20. Expanded in both: 142 slices; only `pn0`: 6 (k = 2–3, 6–7, 27, 32); only `pn3`: 11 (k = 1, 9, 18, 38, 162–163, 165–169).

**Observations** (`exp014_t1_area_per_slice.png`, `exp014_t1_pn0_watershed_steps.png`, `exp014_t1_pn3_watershed_steps.png`; predeclared slices 1, 40, 43, 44, 46, 91, 136, 139, 143, 181; plus a scratch-only tinted rendering of the saved candidates at k = 3, 5, 8, 11, 13, 15, 46, 91, used only for description):

- **Mechanism:**
  - The ridge forms at the **inner edge of the bright peripheral component**, just inside the outer-edge marker.
  - The dark band between the anchor and the periphery (skull and CSF in T1) has no competing marker, so it floods into the anchor basin.
  - The basin is therefore the **whole cavity enclosed by the peripheral component**, not the brain support (median 81 % of the filled parent).
- **k = 91:** the candidate is a smooth ellipse up to the inner scalp edge (22,601 px versus 18,456 for EXP-012), including the dark skull/CSF band. The central slice where EXP-012 was successful is **changed**: it now gives an intracranial-cavity disc instead of brain support.
- **k = 136, 139, 143:** both hemispheres are inside the candidate, but so is the whole dark band (k = 136: 12,607 px, about equal to the ring's 12,648 px enclosed region). `pn0` and `pn3` agree (12,607 / 12,587; 11,509 / 11,518; 9,940 / 9,933). The outer ring stays excluded.
- **k = 40, 43, 44:** the basin grows from the anchor over most of the filled parent (17,347 / 21,573 / 22,048 px in `pn0`). It includes the temporal-like tissue, but also peripheral tissue with a jagged anterior border. At k = 43 the `pn0`/`pn3` discrepancy disappears in area (21,573 / 21,483) because both conditions flood the same cavity.
- **k = 46:** the basin extends into **lateral peripheral tissue** (one side) and the anterior region (23,006 / 23,749 px versus 11,656 / 11,437).
- **k = 1:** `pn0` stays localized (105 px). `pn3` expands to 1,892 px around the anchor.
- **Inferior slices (k ≈ 2–16):** where the anchor is a small object enclosed in the face/neck mass, the basin **floods face/neck tissue**:
  - k = 5: 8,370 px (`pn0`) versus 2,464 (`pn3`), posterior neck region;
  - k = 11: 19,850 / 19,738 px, almost the whole head section;
  - k = 13–15: about 3,500 px, the nasal/maxillary region.

  `pn0` and `pn3` diverge at k = 2–7.
- **k = 181:** no anchor, so empty; the artefact is not introduced.
- **Filling:** final filling added 0 voxels. No whole-head disc arises from filling. However, at k = 11 the watershed basin itself covers almost the whole head section.

**Decision: EXP-014 REJECTED.**

- **Rejection conditions met:**
  - the basin expands beyond the brain support into the dark skull/CSF band in practically every slice with an anchor;
  - central successful slices degrade (k = 46, 91);
  - face/neck becomes a large candidate in the inferior slices (up to about 19,850 px at k = 11);
  - `pn0`/`pn3` consistency worsens.
- **Positive observations:** the foreground identity of EXP-012 is preserved in the central and upper slices; the outer ring and the artefact are never included; the basin is always a single label.
- **Failure category: B (watershed boundary leakage)**, contributed by A (foreground-marker identity) in the inferior slices. Precisely:
  - (B) with a non-brain marker on the outer edge only and no marker in the dark band, the two-marker watershed splits "cavity inside the peripheral component" from "periphery + outside", not "brain" from "non-brain";
  - (A) in k ≈ 1–16 the anchor is a small object enclosed in the face/neck mass, and its basin floods that tissue.
- **Comparison with EXP-008, opposite failure modes:**
  - EXP-008 failed on the **foreground marker** (whole-head marker), while the boundary was good where the marker was valid;
  - EXP-014 has a good foreground marker in the central slices, but the **non-brain side is under-marked**, so the boundary moves outward to the inner edge of the periphery.

**Phase 50 status:** still **BLOCKED / NEEDS REFINEMENT**. Candidate A (T2) remains the head-support fallback. `PROJECT_SPEC.md` and `config.m` were not changed; `cfg.dataset.modality` remains T2. No parameter was retuned, and no EXP-015 was started.

**Supplementary EXP-015 (still Phase 50): T1 internal dark-background skeleton marker feasibility.** This is background-**marker** feasibility work. No watershed was run, and the output is **not** a brain mask.

- **Motivation:** EXP-014 showed that the foreground marker (EXP-012 anchor) was not the main problem. The leakage came from the absence of a background marker in the internal dark band between the brain-like foreground and the peripheral tissue.
- **Course rationale:** in the course's marker-controlled watershed workflow, dark pixels are taken as background and the background marker is thinned by skeletonization so that it stays away from object edges. `ALLOWED_TECHNIQUES.md` §6.8 was added for this narrowly scoped use.
- **No second threshold:** the dark/background class is the existing EXP-010 global-Otsu background (`rawMask == 0`). No other threshold, local Otsu, multithresh or percentile was introduced.
- **Definition, per slice** (`internalDarkSkeletonMarkersSlices.m`; topology logic duplicated, EXP-012/013/014 unchanged):
  - anchor = EXP-012 selection; P = immediate parent (EXP-013/014 rule). No anchor → empty marker;
  - `filledParent = imfill(P,'holes')` (search support only); `filledAnchor = imfill(anchor,'holes')`, which excludes the anchor's own dark holes, such as the ventricles;
  - `internalDark = filledParent AND NOT rawMask AND NOT filledAnchor`, the only dark-region definition;
  - `internalBackgroundMarker = bwmorph(internalDark,'skel',Inf)`, with no pruning, no spur or endpoint removal, no component selection and no size filter. It is not combined with the external background.
- **Diagnostics (descriptive only):**
  - **Barrier test:** in `filledParent AND NOT marker`, does a region exist that contains pixels of both the anchor and P? It uses **4-connectivity**: an 8-connected one-pixel skeleton line can be crossed diagonally by 8-connected paths, so 4-connectivity is the complementary topology for which the line acts as a separator.
  - **Separated sibling area:** the area of the anchor's direct siblings (EXP-013 definition) that lies in no 4-connected region shared with the anchor.
- **Code:** `experiments/brain_mask_t1_dark_background_marker.m`; run on 2026-10-06. All 32 checks PASS:
  - EXP-010 is reproduced; the anchor equals the saved EXP-012 `selectedMask` and the parent equals the saved EXP-013 `parentMask`;
  - `internalDark` and the skeleton, recomputed independently, match;
  - the marker lies inside `internalDark` and does not overlap the anchor or the parent;
  - the marker is empty wherever there is no anchor;
  - input and raw data are unchanged.

| T1 EXP-015 marker | `pn0` | `pn3` |
|---|---:|---:|
| Slices with / without anchor | 152 / 29 | 159 / 22 |
| internalDark pixels (total) | 771,252 | 799,657 |
| Skeleton pixels (total) | 130,617 | 140,788 |
| Skeleton pixels per anchor slice, median / max | 801 / 1,942 | 815 / 2,203 |
| Skeleton components per anchor slice (8-conn), median / max | 8 / 69 | 14 / 89 |
| Anchor slices with an empty skeleton | 0 | 0 |
| Anchor / parent overlap slices | 0 / 0 | 0 / 0 |
| Slices where the skeleton is a complete anchor/parent barrier | 152 (all anchor slices) | 159 (all anchor slices) |
| Direct-sibling area / of which separated from the anchor by the skeleton | 44,478 / 44,478 | 48,655 / 48,655 |
| Slices with a separated sibling | 136 | 143 |

`pn0` versus `pn3`: marker IoU 0.5988, 0.9580 % of voxels differing. A low pixelwise IoU is expected for one-pixel skeletons. Marker in both: 150 slices; only `pn0`: 2; only `pn3`: 9; neither: 20. Barrier agreement in the 150 slices with an anchor in both conditions: 150 / 150. The skeleton component count is higher in `pn3` (median 14 versus 8).

**Observations** (`exp015_t1_marker_per_slice.png`, `exp015_t1_pn0_marker_steps.png`, `exp015_t1_pn3_marker_steps.png`, `exp015_t1_marker_on_t1.png`; the last is a marker diagnostic visualization, not a Phase-51 boundary validation):

- **k = 91 (key central test):** the marker is a **single closed loop** (1 / 3 components; 675 / 680 px) in the middle of the dark brain/periphery band, with almost no other branches. The anchor's ventricles are excluded by `filledAnchor`. This is exactly the missing EXP-014 background marker.
- **k = 136, 139, 143 (key upper test):** the peripheral dark-band loop is present. In addition, the skeleton forms a **network through the inter-hemispheric fissure and the sulci of the non-anchor hemisphere**. At k = 136 the other hemisphere-like component (3,357 / 3,318 px) is completely enclosed by marker. At k = 139 and 143 in `pn3`, where the anchor is one hemisphere, 2,855 and 1,620 px of sibling are enclosed.
- **k = 40, 43, 44, 46:** a dense network (19–44 components, 1,437–1,748 px) through the orbits, sinuses, nasal cavity, and the dark spaces between the cerebellum, the temporal-like tissue and the periphery. The temporal-like tissue that belongs to the parent component is surrounded by marker branches, as are the small siblings.
- **k = 1:** the skeleton spreads through the face/neck dark regions (61 / 75 components, 1,389 / 1,245 px) around a 105 px anchor. It is dominated by face/neck structures and is obviously unsuitable as a non-brain marker for a future watershed there.
- **k = 181:** no anchor, so the marker is empty; the artefact generates no marker.
- **Structural reason for the sibling separation:** skeletonization preserves the topology (the holes) of `internalDark`. Every foreground object enclosed in `internalDark` is a hole of it, so the skeleton keeps a closed loop around it. With this rule, **every** non-anchor foreground object inside the filled parent is necessarily enclosed by background marker: siblings, other hemisphere, temporal-like regions inside the parent's hole. The 100 % separation is therefore a property of the construction, not a coincidence.

**Decision: EXP-015 REJECTED as a background marker in its raw form. The central dark-band loop is confirmed.**

- **Positive:** where the anchor is the whole brain section (central slices, for example k = 91), the skeleton is a thin closed loop in the brain/periphery dark band. It is disjoint from the anchor and the parent, and topologically consistent between `pn0` and `pn3` (barrier agreement 150 / 150).
- **Rejection conditions met:**
  - **(C) inter-intracranial skeleton branches:** the marker systematically encloses every foreground component other than the anchor, including the second hemisphere at k ≈ 136. A future single-anchor watershed would be **blocked** from recovering them.
  - **(B) excessive irrelevant dark structures:** face/neck dark regions dominate the inferior slices (k = 1), and the orbits, sinuses and nasal cavity produce dense networks at k = 40–46.
- **Required before any watershed retry:** a separate, pre-declared marker-selection rule that keeps the dark-band loop around the brain-support family and discards branches between intracranial components and in face/neck cavities. This rule is **not** invented here.

**Phase 50 status:** still **BLOCKED / NEEDS REFINEMENT**. Candidate A (T2) remains the head-support fallback. `PROJECT_SPEC.md` and `config.m` were not changed; `cfg.dataset.modality` remains T2. No EXP-016 was started.

**Supplementary EXP-016 (still Phase 50): T1 Canny outer-brain-boundary feasibility.** This is an edge-**feasibility** investigation. No brain mask, no contour closing or filling, and no watershed.

- **Motivation:** EXP-011 to EXP-015 reduced the remaining problem to explicit brain-boundary identification:
  - size and topology fail at the volume extremes;
  - the watershed leaked because the background marker was too peripheral;
  - the generic dark skeleton is not specific.

  Edge-based segmentation is covered by the course (`ALLOWED_TECHNIQUES.md` §10, now with a narrow EXP-016 note). The course also includes an exercise on extracting the outer contour of the brain.
- **One configuration** (`detectT1CannyEdgesSlices.m`): `[BW, thresh] = edge(I, 'Canny')` on each normalized T1 slice, independently. MATLAB's automatic thresholds are used and returned as [low high] for diagnosis only. No manual threshold, sigma or filter size; no sweep; no other edge detector; no external preprocessing (Canny's internal smoothing belongs to the operator). The edge map is saved raw: no morphology, linking, pruning or component selection.
- **Diagnostics only:** the EXP-012 anchor and the EXP-013 immediate parent (reproduced, checks PASS) define `filledParent` as a local domain. They never influence edge generation.
  - Recorded: edges inside the domain, on the anchor and on the parent.
  - **Barrier test (predeclared):** do the 4-connected regions of `filledParent AND NOT edges` contain a region with pixels of both the anchor and the parent? 4-connectivity, as in EXP-015.
  - The optional closed-contour diagnostic was **not** implemented, because it would have required a contour-selection rule.
- **Code:** `experiments/brain_mask_t1_canny_edge_feasibility.m`; run on 2026-10-06. All 18 checks PASS:
  - EXP-010 is reproduced; the anchor equals the saved EXP-012 `selectedMask` and the parent equals the saved EXP-013 `parentMask`;
  - the edges, recomputed independently with `edge(I,'Canny')` on the 10 diagnostic slices, match;
  - input and raw data are unchanged.

| T1 EXP-016 raw Canny | `pn0` | `pn3` |
|---|---:|---:|
| Edge pixels (total) | 660,928 | 696,814 |
| Edge pixels per slice, median / max | 4,038 / 4,864 | 4,088 / 7,182 |
| Edge components per slice (8-conn), median / max | 58 / 96 | 62 / 193 |
| Largest edge component, median / max | 554 / 1,125 | 573 / 1,131 |
| Automatic low threshold, median (min–max) | 0.075 (0.00625–0.1) | 0.075 (0.0125–0.1) |
| Automatic high threshold, median (min–max) | 0.1875 (0.015625–0.25) | 0.1875 (0.03125–0.25) |
| Edges inside filledParent / on anchor / on parent / other inside | 514,903 / 217,891 / 191,811 / 105,201 | 521,372 / 216,448 / 190,911 / 114,013 |
| Barrier slices (of anchor slices) | 6 of 152 (k = 1, 3, 5, 7, 10–11) | 7 of 159 (k = 1, 3, 5, 7, 10–11, 132) |

`pn0` versus `pn3`: edge-volume IoU 0.8028, 2.0894 % of voxels differing. This is high for one-pixel edges. Barrier classification in the 150 slices with an anchor in both: both 6, only `pn3` 1 (k = 132), neither 143. The automatic thresholds are identical in `pn0` and `pn3` at most diagnostic slices.

**Limitation of the barrier diagnostic (identified after the run, not corrected):** Canny places its one-pixel line on the intensity transition, and 217,891 / 216,448 edge pixels lie **on** the anchor itself (k = 91: 2,170). The outermost anchor pixels and the innermost parent pixels can therefore fall into the same dark band **between** two edge lines, and the test reports "connected" even when the contours are closed. At k = 136–143 the region between the two scalp contours is correctly isolated, but the region inside the inner scalp contour still contains parent pixels. The barrier result is therefore **not informative** about contour continuity for Canny. It was not redefined after the results; the assessment relies on the figures.

**Observations** (`exp016_t1_canny_per_slice.png`, `exp016_t1_pn0_canny_steps.png`, `exp016_t1_pn3_canny_steps.png`; edge diagnostics, not Phase-51 validation; plus a scratch-only enlarged rendering of `pn0` at k = 40, 44, 91, 136, used for description only):

- **k = 91 (central reference):**
  - Canny gives **concentric contours**: the outer scalp edge, the inner scalp/skull edge, and the outer cortical contour, which appears visually almost continuous around the brain.
  - The cortical contour is **merged with sulcal invaginations**, and there are separate ventricular contours.
  - The outer brain boundary is present, but it is one of several nested contours and is attached to internal edges.
- **k = 136, 139, 143:** an outer cortical contour surrounds **both** hemispheres, inside the two scalp contours. There are also strong **inter-hemispheric midline edges** and dense sulcal edges connected to it. This is a mixture: the information to enclose both hemispheres exists, but the midline edge splits the interior.
- **k = 40, 43, 44 (base of the skull):**
  - Canny draws contours **around each temporal-like region and around the cerebellum-like region**.
  - These include edges between grey brain-like tissue and the very bright anterior/lateral tissue that the Otsu mask had merged into one foreground component. This is **new information** compared with the binary Otsu topology.
  - However, the brain is not enclosed by one outer contour here: it is several separately contoured objects among orbital, sinus, muscle and scalp contours, and in places the temporal contours merge into lateral edges.
- **k = 46:** a transition slice, with the same pattern; the anterior orbital and sinus region is densely contoured.
- **k = 1:** dominated by facial/neck contours (67 / 60 components); no distinguishable intracranial boundary.
- **k = 181:** the artefact bars are outlined (1,096 / 1,083 edge pixels); no brain-mask result.
- **`pn0` / `pn3`:** qualitatively the same edge structures in all diagnostic slices.
- **Comparison with the morphological gradient:** Canny is a thinned, thresholded gradient. It shows the same intensity transitions as the EXP-014 gradient, but as binary one-pixel contours. These can be analysed topologically, which the gradient could not be without markers.

**Decision: EXP-016 PROMISING BUT PROBLEMATIC.**

- **Present:**
  - a visually near-continuous outer cortical contour in the central and upper slices, which in principle encloses both hemispheres;
  - at the base of the skull, contours that separate temporal-like and cerebellar-like tissue from the bright periphery that Otsu had merged;
  - high `pn0`/`pn3` consistency.
- **Problematic:**
  - **(C) excessive competing contours:** concentric scalp, skull and brain contours, sulcal and ventricular edges connected to the cortical contour, a strong inter-hemispheric midline, and dense orbital, sinus and face/neck contours;
  - **(D) superior hemisphere-boundary ambiguity** from the midline edges;
  - the inferior brain is several separately contoured objects rather than one;
  - continuity could not be confirmed quantitatively, because the predeclared barrier diagnostic is uninformative for Canny (see above).
- **Required next:** an automatic contour-selection and contour-completion method before any boundary-to-mask conversion. It is **not** implemented here. The 2D branch is not yet exhausted, so no inter-slice method is proposed.

**Phase 50 status:** still **BLOCKED / NEEDS REFINEMENT**. Candidate A (T2) remains the head-support fallback. `PROJECT_SPEC.md` and `config.m` were not changed; T2 remains the lesion modality. No EXP-017 was started.

**Supplementary EXP-017 (still Phase 50): T1 Canny minimal-closing enclosing-contour candidate.** EXP-016 was edge feasibility only. EXP-017 is the **first Canny-derived brain-support candidate**.

- **Motivation:** EXP-016 found useful but non-specific boundary information. EXP-017 tests one minimal edge-to-region conversion: detect edges, link them into contours, represent boundaries (the course's edge-based segmentation scheme).
- **Retired diagnostic:** the EXP-016 barrier test is not reused, because it is unsuitable for raw Canny (edge lines lie on anchor and parent pixels).
- **Rule, per slice** (`selectCannyEnclosingBrainCandidateSlices.m`):
  1. Raw EXP-016 Canny map, reproduced exactly (`edge(I,'Canny')`, automatic thresholds).
  2. **One** `imclose(edges, strel('square',3))`; no thinning afterwards.
  3. 8-connected components of the closed edges, **each filled independently** with `imfill(...,'holes')`. The whole map is never filled, and components are never united.
  4. A filled region qualifies only if **every** anchor pixel lies inside it.
  5. The candidate is the qualifying region with the **smallest area** (ties: lowest index), used as is.
  6. No anchor, or no qualifying region → empty slice, with no fallback.

  There is no Otsu or parent constraint, no morphology after selection, no position, z or 3D rule, and no GT.
- **Risk declared before the run:** because Canny lines can pass over anchor pixels, the full-containment rule could reject a cortical contour that misses a few anchor pixels. For this, `bestCoverage` (the largest anchor fraction inside a single filled region) was recorded for description only. `ALLOWED_TECHNIQUES.md` §10 has a narrow EXP-017 note.
- **Code:** `experiments/brain_mask_t1_canny_enclosing_contour.m`; run on 2026-10-06. All 24 checks PASS:
  - EXP-016 Canny is reproduced exactly; the anchor equals the saved EXP-012 `selectedMask`;
  - the single closing, recomputed independently on every slice, matches, and the candidate, recomputed on the diagnostic slices, matches;
  - every candidate contains the whole anchor, and slices without an anchor or an enclosure are empty;
  - input and raw data are unchanged.

| T1 EXP-017 candidate | `pn0` | `pn3` |
|---|---:|---:|
| Raw / closed edge pixels | 660,928 / 800,298 | 696,814 / 864,256 |
| Added / removed by closing | 139,370 / 0 | 167,442 / 0 |
| Edge components per slice, raw → closed (median; max) | 58 → 14 (96 → 26) | 62 → 15 (193 → 64) |
| Slices with anchor / with candidate / anchor but no enclosure | 152 / 142 / 10 | 159 / 145 / 14 |
| Enclosing regions per anchor slice, median / max; ties | 1 / 2; 0 | 1 / 3; 0 |
| Slices with ≥ 2 enclosing regions | 11 | 10 |
| Candidate voxels | 2,976,626 (41.87 %) | 2,972,977 (41.82 %) |
| Candidate / anchor area, median / max | 1.76 / 27,339 | 1.78 / 13,131.5 |
| Candidate / EXP-014 filledParent area, median; slices ≥ 0.9 | 1.002; 119 of 142 | 1.003; 119 of 145 |
| First / last non-empty slice | 1 / 164 | 1 / 169 |

Anchor slices without an enclosure: `pn0` k = 2, 8–9, 12, 16, 27, 40–42, 44; `pn3` k = 2, 8–9, 12, 14, 20–21, 40–42, 53, 165–167. Their `bestCoverage` is 0.977–0.999 at k = 2, 8, 9, 12, 40, 44 (and 53 in `pn3`), so **almost** the whole anchor is enclosed but a few pixels lie outside. At the other slices it is 0–0.31.

`pn0` versus `pn3`: IoU 0.9133, 3.7925 % of voxels differing. Candidate in both: 137; only `pn0`: 5; only `pn3`: 8; neither: 31.

**Observations** (`exp017_t1_canny_enclosing_per_slice.png`, `exp017_t1_pn0_canny_enclosing_steps.png`, `exp017_t1_pn3_canny_enclosing_steps.png`; development diagnostics, not Phase-51 validation):

- **Mechanism:** the closing (+139,370 / +167,442 px) and the internal edges join the concentric scalp, skull and cortical contours and the sulcal edges into **one connected component**. The median number of components drops from 58 to 14, and there is usually one enclosing region per slice. Filling that component fills its **outermost** loop. The nested contour hierarchy that the "smallest enclosure" hypothesis needs therefore does not survive.
- **k = 91 (central reference):** the only enclosing region is 26,741 px (`pn0`) / 26,733 px (`pn3`), a **whole-head disc** that includes the scalp (EXP-014 filled parent: 26,677). Otsu foreground outside it: 149 / 115 px. The cortical-scale enclosure is **not** selected.
- **k = 43, 46:** whole-head discs including the **face and orbital region** (28,068 and 28,434 px in `pn0`; 15 Otsu components inside).
- **k = 40, 44:** no enclosure in `pn0` (`bestCoverage` 0.998 / 0.994: a few anchor pixels lie outside the contour). In `pn3`, k = 40 has no enclosure and k = 44 is a 28,180 px head disc.
- **k = 136, 139, 143:** a region inside the scalp ring, around 0.9–0.94 of the filled parent (15,115 / 14,400 / 12,434 px in `pn0`), containing both hemispheres and the dark skull/CSF band. At k = 139 the selected edge component also includes a thin outer scalp contour arc. `pn0` and `pn3` are similar (15,123 / 13,449 / 12,429).
- **k = 1:** a tiny local region around the anchor (111 px); face/neck not included.
- **k = 181:** no anchor, so empty.

**Decision: EXP-017 REJECTED.**

- **Primary failure: C (scalp/head contour selected).** In about 120 slices per condition the candidate is head-support-sized (candidate / filled-parent ratio ≥ 0.9, median 1.00). This includes the central reference slice and face/orbit at the base of the skull (**D**).
- **Mechanism: F (closing merges unrelated contours).** Together with the internal-edge connections, the single 3×3 closing fuses the concentric contours, so independent component filling cannot separate brain-level from head-level enclosure.
- **Secondary: A.** At k = 40/44 (and k = 2, 8, 9, 12) no contour contains the whole anchor, although 98–99.9 % is enclosed. This is the risk declared before the run.
- **Not met:** the central cortical-scale enclosure (the hypothesis of nested contours with the smallest one at the brain is **not supported**) and inferior completeness. In the superior slices the cavity-level region includes both hemispheres, but also the dark band.
- **2D branch:** the inferior failure is not the only one here, since the central slices fail too. EXP-017 was the last planned independent-2D attempt, and the planned independent-2D brain-mask branch (EXP-010 to EXP-017) has **reached a strong limitation without an accepted candidate**. No inter-slice method is implemented.

**Phase 50 status:** still **BLOCKED / NEEDS REFINEMENT**. Candidate A (T2) remains the head-support fallback. `PROJECT_SPEC.md` and `config.m` were not changed; T2 remains the lesion modality. No EXP-018 was started.

**Supplementary EXP-018 (still Phase 50): T1 slice-to-slice propagation with marker-controlled watershed.**

- **Motivation and authorization:** EXP-010 to EXP-017 showed that a single 2D slice does not contain enough information to tell the brain contour from the head contour at the volume extremes. The brain is one object that is continuous along z, and the central slices are reliable. On 2026-10-06 the user explicitly authorized inter-slice propagation for EXP-018 (`ALLOWED_TECHNIQUES.md` §10 note): all operations stay 2D, and only the accepted mask of the adjacent slice is used. The propagation scheme is a project design decision, not a verified course technique. No 3D operation is used.
- **One configuration, declared before the run** (`propagateBrainMaskSlices.m`):
  - **Seed slice:** among the slices where the EXP-012 anchor equals the EXP-011 largest component, the one with the largest anchor (automatic; `pn0` and `pn3` both give k = 75). The seed mask is the EXP-012 candidate on that slice.
  - **Propagation** away from the seed (k = seed+1 … 181 using k−1; k = seed−1 … 1 using k+1), with M the neighbouring accepted mask:
    - foreground marker = `imerode(M, strel('disk',3,0))`;
    - background marker = `NOT imdilate(M, strel('disk',3,0))`;
    - 3×3 morphological gradient of the T1 slice k, `imimposemin` + `watershed`;
    - candidate = basins touched by the foreground AND NOT background, then one `imfill`.
  - **Stop:** an empty foreground marker stops that direction.
  - **Radius:** 3 px, chosen from the slice-to-slice change of the equivalent radius of the EXP-012 candidates at k = 46–133 (median about 0.4, 90th percentile about 1.2, maximum about 3.6 px). This uses existing data, not EXP-018 results.
  - No Otsu constraint, no sweep, no GT.
- **Code:** `experiments/brain_mask_t1_zpropagation.m`; run on 2026-10-06. All 26 checks PASS:
  - EXP-010 and the EXP-012 anchor are reproduced; the seed is an agreement slice, and its mask equals the saved EXP-012 candidate;
  - the markers are disjoint; pixels outside the dilated neighbour arise only from hole filling;
  - the propagation, recomputed independently on the diagnostic slices, matches; slices after a stop are empty;
  - input and raw data are unchanged.
- **Debugging note:** the first run stopped with a misleading "EXP-010 not reproduced" message, caused by two script errors:
  - the input gate also evaluated the earlier `pn0` checks;
  - the check "candidate inside dilated neighbour" was too strict, because the final `imfill` can legitimately fill a concavity of the neighbour that the dilation closes into a ring.

  Both checks were corrected. The algorithm and its parameters were not changed.

| T1 EXP-018 candidate | `pn0` | `pn3` |
|---|---:|---:|
| Seed slice | 75 | 75 |
| Candidate voxels | 2,025,094 (28.49 %) | 1,871,056 (26.32 %) |
| Non-empty slices; first / last | 171; 1 / 171 | 174; 1 / 174 |
| Stopped (empty) slices | 10 | 7 |
| Labels touched per slice, median / max | 1 / 4 | 1 / 3 |
| Added by filling; of which outside the dilated neighbour (slices) | 422; 59 (3) | 138; 20 (1) |
| Raw-Otsu fraction inside candidate, median | 0.847 | 0.848 |
| Raw-Otsu fraction by range k = 1–39 / 40–59 / 60–133 / 134–150 / 151–181 | 0.469 / 0.837 / 0.930 / 0.758 / 0.542 | 0.546 / 0.841 / 0.925 / 0.754 / 0.478 |
| IoU with EXP-012, k = 60–133 | 0.9593 | 0.9488 |

(EXP-012: 1,536,369 / 1,516,701 voxels; EXP-014: 2,296,618 / 2,280,974.) `pn0` versus `pn3`: IoU 0.8924, 3.1146 % of voxels differing. Candidate in both: 171 slices; only `pn3`: 3; neither: 7.

**Observations** (`exp018_t1_zpropagation_per_slice.png`, `exp018_t1_pn0_zpropagation_steps.png`, `exp018_t1_pn3_zpropagation_steps.png`; development diagnostics, not Phase-51 validation):

- **Central slices (k ≈ 60–133):** the propagated mask reproduces the brain-scale EXP-012 support (IoU 0.96 / 0.95; Otsu fraction about 0.93). k = 91: 18,204 px versus 18,456 for EXP-012; the cavity-scale EXP-014 was 22,601. The watershed boundary stays at the brain/CSF edge inside the ±3 px band. There is **no** leakage into the dark skull/CSF band (the EXP-014 failure) and **no** head disc (the EXP-017 failure).
- **Superior slices (k ≈ 134–150):** **both hemispheres** are included without the scalp ring and without most of the dark band. k = 136: 7,869 / 7,846 px versus EXP-012 3,451 / 3,413 (one hemisphere) and EXP-014 12,607 / 12,587 (cavity). k = 139: 6,926 / 6,903; k = 143: 5,440 / 5,239. `pn0` and `pn3` agree closely. The EXP-012 hemisphere split and the EXP-011 identity switch are both resolved.
- **Near the vertex (k ≈ 151–171):** the area decreases smoothly to 0 (`pn0` 3,074 → 13 px between k = 150 and 171), but the Otsu fraction drops (median 0.54 / 0.48, minimum about 0.1 at k ≈ 160). The mask **lags** behind the shrinking brain and keeps dark tissue for a few slices before stopping.
- **Inferior slices (k ≲ 45): failure.** Going down, the mask does **not** shrink with the brain. The area decreases only slowly, from about 14,000 px at k = 40 to 7,171 (`pn0`) / 2,997 (`pn3`) at k = 1, and the Otsu fraction falls to about 0.47 / 0.55. At k = 40–46 the candidate extends into the **anterior orbital/sinus region**. At k = 1 it covers central face/neck structures. The propagation follows soft tissue continuous with the brain through the skull base (**drift**), and the stop rule never triggers there. `pn0` and `pn3` drift differently at the lowest slices (k = 1: 7,171 versus 2,997 px).
- **k = 181:** empty (propagation stopped above k = 171 / 174); the artefact is not reached.

**Decision: EXP-018 PROMISING BUT PROBLEMATIC.**

- **Solved, for the first time in Phase 50:** a brain-scale support in the central and superior slices that includes both hemispheres, excludes the scalp, the dark band and the artefact, and is consistent between `pn0` and `pn3`. It uses only one seed and 2D operations.
- **Not solved:**
  - **inferior drift:** below about k = 45 the propagated mask enters the orbital, sinus and face/neck tissue and never terminates;
  - **vertex lag:** dark tissue is retained near the top.

  The inferior part is not acceptable for Phase 51.
- **Required before acceptance:** a separate, pre-declared rule that prevents downward drift at the skull base (for example a stop or limiting criterion). It is **not** invented here and requires a user decision. The radius was not changed after the results.

**Phase 50 status:** still **BLOCKED / NEEDS REFINEMENT**. Candidate A (T2) remains the head-support fallback. `PROJECT_SPEC.md` and `config.m` were not changed; T2 remains the lesion modality. No EXP-019 was started.

**Supplementary EXP-019 (still Phase 50): asymmetric slice-to-slice propagation.**

- **Change from EXP-018, declared before the run:** only the two radii change, to erosion `strel('disk',5,0)` and dilation `strel('disk',1,0)`.
  - Rationale: the seed is the largest section, so the brain shrinks away from it. Growth was limited to about 1 px per slice to stop the EXP-018 inferior drift.
  - Erosion was set larger than the maximum observed EXP-012 equivalent-radius change (about 3.6 px per slice) so that the mask could retreat.
  - Everything else is identical to EXP-018: seed k = 75, gradient, watershed, `imfill`, stop rule. The inter-slice authorization covers EXP-019 (`ALLOWED_TECHNIQUES.md` §10).
- **Code:** `experiments/brain_mask_t1_zpropagation_asymmetric.m` (reuses `propagateBrainMaskSlices.m` unchanged); run on 2026-10-06. All 26 checks PASS.

| T1 EXP-019 | `pn0` | `pn3` |
|---|---:|---:|
| Candidate voxels | 457,151 (6.43 %) | 392,781 (5.53 %) |
| Non-empty slices; first / last | 59; 47 / 105 | 52; 50 / 101 |
| Area k = 75 → 76 → 80 → 90 → 100 | 19,645 → 19,132 → 15,383 → 6,529 → 1,359 | 19,598 → 19,027 → 14,983 → 4,257 → 165 |
| Area k = 70 → 60 → 50 | 15,661 → 6,237 → 851 | 15,085 → 4,087 → 51 |

`pn0` versus `pn3`: IoU 0.8303. The candidate **collapses** in both directions from the seed. At k = 91 it is 5,688 / 3,723 px, against 18,204 / 17,998 for EXP-018. Every diagnostic slice except the seed and k = 91 is empty.

**Mechanism:** the area lost per slice near the seed (−513 px from k = 75 to 76) is about the perimeter of the section (about 500 px for 19,600 px), so **a one-pixel rim is lost at every slice**. The candidate excludes the watershed ridge pixels (label 0). With a background marker only 1 px outside the neighbouring mask, the 1-px ridge falls on the mask's own boundary pixels, so each propagation step removes them and the error accumulates. In EXP-018 the 3-px band left room for the ridge outside the true boundary. The failure is therefore an interaction between ridge exclusion and the 1-px dilation; it says nothing about the asymmetric-radius idea itself. This interaction was not anticipated when the radii were declared.

**Decision: EXP-019 REJECTED** (systematic collapse). The radii were not changed after the results, and no further radius pair was tried, since that would amount to a sweep. Any redesign (for example, how ridge pixels are assigned) requires a separate decision.

**Phase 50 status:** still **BLOCKED / NEEDS REFINEMENT**. EXP-018 remains the best Phase-50 result, good in the central and superior slices, with inferior drift. No EXP-020 was started.

**Supplementary EXP-020 (still Phase 50): EXP-019 with watershed ridge pixels assigned to the foreground.**

- **Change from EXP-019:** only the ridge assignment changes. The candidate is now `imfill(NOT (basins touched by the background marker) AND NOT background, 'holes')`, so ridge pixels go to the foreground. `propagateBrainMaskSlices.m` gained an optional `ridgeAssignment` argument; its default `"exclude"` keeps EXP-018/019 reproducible.
- **Unchanged from EXP-019:** radii (erosion disk 5, dilation disk 1), seed k = 75, gradient and stop rule.
- **Code:** `experiments/brain_mask_t1_zpropagation_ridge_foreground.m`; run on 2026-10-06. All 26 checks PASS.

| T1 EXP-020 | `pn0` | `pn3` |
|---|---:|---:|
| Candidate voxels | 1,415,004 (19.90 %) | 1,217,131 (17.12 %) |
| Empty slices; last non-empty | 20; 161 | 48; 145 (first 13) |
| Area k = 91 / 100 / 120 / 136 / 145 | 17,893 / 15,261 / 7,816 / 2,815 / 1,568 | 16,766 / 13,339 / 4,525 / 939 / 248 |
| Area k = 60 / 50 / 46 / 40 / 20 / 5 | 15,992 / 11,074 / 9,856 / 7,658 / 2,104 / 629 | 15,926 / 10,843 / 8,697 / 6,288 / 1,290 / 0 |
| Raw-Otsu fraction, median k = 1–39 / 60–133 | 0.340 / 0.933 | 0.348 / 0.926 |

`pn0` versus `pn3`: IoU 0.8296, 3.4479 % of voxels differing. Candidate in both: 133 slices; only `pn0`: 28; neither: 20.

**Observations** (`exp020_t1_zpropagation_per_slice.png`, `exp020_t1_pn0_zpropagation_steps.png`, `exp020_t1_pn3_zpropagation_steps.png`):

- **Near the seed:** no one-pixel-rim collapse. The ridge fix works at k = 91 (17,893 versus 18,204 for EXP-018), but a lateral **notch** has appeared.
- **Upward:** the support is lost progressively.
  - At k = 136 only **one hemisphere** remains (2,815 / 939 px, against 7,869 / 7,846 for EXP-018).
  - `pn3` stops at k = 145.
  - Once a region is lost it cannot come back: with a 1-px dilation the mask can grow only about 1 px per slice. The 5-px erosion lets the watershed retreat onto internal edges, such as sulci and the inter-hemispheric fissure.
- **Downward:**
  - No orbital/sinus drift at k = 40–46. Compared with EXP-018 this is an improvement: the candidate is a cerebellum/brainstem-centred region of 7,658–9,856 px in `pn0`.
  - However, the lateral temporal tissue is only partly included (k = 46: 9,856 versus 11,656 for EXP-012).
  - Further down the mask continues through dark tissue (Otsu fraction median about 0.34 at k = 1–39).
  - `pn0` and `pn3` diverge (`pn3` is empty below k = 13).

**Decision: EXP-020 REJECTED.**

- The ridge fix removed the EXP-019 collapse.
- The asymmetric radii (1 px growth) are too restrictive: superior hemisphere loss, a lateral notch, an early `pn3` stop and `pn0`/`pn3` instability.
- The inferior drift into the orbits is avoided, but the inferior support is incomplete and partly dark.
- No further radius or ridge variants were tried.

**Overall propagation finding (EXP-018 to EXP-020):** the slice-to-slice propagation is **sensitive to its marker radii**.
- Symmetric radius 3 drifts into the orbit, sinuses and face/neck below about k = 45, but is the best result in the central and superior slices.
- Asymmetric 5/1 avoids that drift but loses support superiorly.
- Choosing radii per direction from these development results would be post-hoc tuning and would need an explicit decision.

**Phase 50 status:** still **BLOCKED / NEEDS REFINEMENT**. EXP-018 remains the best Phase-50 result. No EXP-021 was started.

**Supplementary EXP-021 (still Phase 50): 3D erode → largest 3D component → 3D dilate on T1 (exploratory exception).**

- **Status of the technique:** this is a **volumetric extension of 2D techniques present in the course slides** (erosion, dilation, connected components, largest region, hole filling). Volumetric processing itself is **not** treated in the course PDF. The course skull-removal exercise on `t1.nii` works on a single layer, and `bwconncomp` is presented with 2D connectivity. The user explicitly authorized it on 2026-10-06 as an exploratory test (`ALLOWED_TECHNIQUES.md` §10 exception), to be decided upon after the results.
- **One configuration, declared before the run** (`brainMask3DErodeSelectDilate.m`):
  1. the EXP-010 T1 raw Otsu mask;
  2. `imerode` with `strel('sphere',3)` (3D);
  3. `bwconncomp(...,26)`, then the **largest** 3D component (as in the course recipe "largest region");
  4. `imdilate` with the same sphere, AND the raw mask;
  5. `imfill(...,'holes')` slice by slice (2D).

  The radius 3 breaks connections up to about 7 voxels wide (the T2 bridges measured at ≥ 3 px in EXP-007 and about 5 px in EXP-008; the T1 dark band is wider) while keeping the white-matter core. The risk declared before the run was that the largest component could be the neck/face block; the component containing the EXP-012 seed anchor was recorded **as a diagnostic only**.
- **Code:** `experiments/brain_mask_t1_3d_erode_select_dilate.m`; run on 2026-10-06. All 20 checks PASS:
  - EXP-010 is reproduced;
  - the 3D erosion and the 26-connected components, recomputed independently, match;
  - the selected core is the largest 3D component;
  - the candidate equals the dilated core AND raw mask, filled slice by slice;
  - input and raw data are unchanged.

| T1 EXP-021 | `pn0` | `pn3` |
|---|---:|---:|
| Eroded voxels; 3D components | 1,306,870; 263 | 1,227,539; 351 |
| Largest / second / third component | 1,015,104 / 287,327 / 2,146 | 969,761 / 244,567 / 7,860 |
| Component holding the EXP-012 seed anchor | rank 1 (= selected) | rank 1 (= selected) |
| Restored (dilated core AND raw) / added by 2D fill | 1,613,842 / 74,945 | 1,589,406 / 78,960 |
| Candidate voxels | 1,688,787 (23.76 %) | 1,668,366 (23.47 %) |
| Non-empty slices; first / last | 160; 1 / 160 | 156; 1 / 156 |
| Area relative to T2 head support | 0.405 | 0.401 |
| IoU with EXP-012 / EXP-018 / EXP-020 | 0.861 / 0.792 / 0.710 | 0.851 / 0.804 / 0.633 |

`pn0` versus `pn3`: IoU **0.9848**, 0.3619 % of voxels differing. This is the highest of all candidates covering the whole brain.

| Area at slice k | 1 | 40 | 43 | 44 | 46 | 91 | 136 | 139 | 143 | 181 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| EXP-021 `pn0` | 98 | 9,922 | 10,403 | 10,622 | 11,539 | 18,196 | 6,563 | 5,572 | 4,012 | 0 |
| EXP-021 `pn3` | 98 | 9,809 | 10,249 | 10,451 | 11,094 | 18,122 | 6,491 | 5,523 | 3,903 | 0 |
| EXP-018 `pn0` | 7,171 | 14,001 | 14,674 | 14,941 | 15,420 | 18,204 | 7,869 | 6,926 | 5,440 | 0 |
| EXP-012 `pn0` | 105 | 6,881 | 6,832 | 1,987 | 11,656 | 18,456 | 3,451 | 5,729 | 4,323 | 0 |

**Observations** (`exp021_t1_3d_area_per_slice.png`, `exp021_t1_pn0_3d_steps.png`, `exp021_t1_pn3_3d_steps.png`, `exp021_t1_3d_orthogonal_views.png`; plus a scratch-only rendering at k = 8, 12, 16, 20, 25, 30, 35, 50, 155, used for description only):

- **Identity:** the largest 3D component after erosion is the one that contains the EXP-012 anchor of the seed slice, in both conditions. The second component (287,327 / 244,567 voxels) is the remaining head tissue. The declared risk did not occur.
- **Central slices (k = 91):** brain-scale (18,196 px, against 18,456 for EXP-012 and 18,204 for EXP-018). No scalp and no dark band.
- **Superior slices (k = 136–143):** **both hemispheres** are included, without the scalp ring (k = 136: 6,563 px, against 3,451 for EXP-012). The near-vertex slices are fragmentary (for example k = 155: 515 / 131 px), and the last non-empty slice is 160 / 156 (EXP-012: about 163; EXP-018: 171 / 174). Thin cortex at the vertex is partly lost, as expected from the erosion.
- **Skull base (k = 40–46):** temporal-lobe-like regions, cerebellum and brainstem are included (9,922–11,539 px), with **no orbital, sinus or face tissue**. This is where every previous method failed. At k = 46 a few thin anterior structures are included; their anatomical identity is not claimed.
- **Lower slices (k = 8–35):** cerebellum, brainstem and spinal cord. The temporal lobes appear from about k = 25. There is no face/neck tissue, in `pn0` or `pn3`. At k = 1 only the cord remains (98 px). Including the spinal cord is the expected behaviour (continuous neural tissue).
- **k = 181:** empty; the artefact is not included.
- **Orthogonal views:** the coronal view shows a clean brain support, with both hemispheres, the temporal lobes and the brainstem, and without the neck tissue that EXP-018 includes. The **mid-sagittal** plane (i = 91) lies in the inter-hemispheric fissure. Because the candidate is the dilated core AND the raw Otsu mask, filled only axially, CSF spaces open to the surface (fissure, sulci) are excluded, which gives horizontal gaps in that view. It is a brain-tissue support, not an intracranial-cavity mask.

**Decision: EXP-021 is technically ACCEPTABLE as the Phase-50 brain-support candidate.**

- **Criteria met:**
  - the brain identity is selected automatically;
  - the central and superior slices are brain-scale, with both hemispheres;
  - the skull base and lower slices are much better than every previous method, with temporal lobes, cerebellum and brainstem and no face/neck;
  - scalp and artefact are excluded;
  - `pn0`/`pn3` agree (IoU 0.985);
  - one configuration, no manual choice, no GT.
- **Known limitations:**
  - thin vertex cortex is partly lost;
  - surface-open CSF (fissure, sulci) is excluded;
  - the spinal cord is included down to k = 1;
  - a few thin anterior structures appear at k = 46.
- **Adoption is NOT decided here.** EXP-021 relies on 3D processing that is not in the course PDF. The user decides whether to adopt it as the project brain mask (documented as a volumetric extension of course techniques) or to report it as tested exploration. `PROJECT_SPEC.md` and `config.m` were not changed.

**Phase 50 status:** a technically acceptable candidate (EXP-021) is available, **pending the user's methodological decision**. Phase 51 has not been started.

**EXP-021 frozen (user decision, 2026-10-06), declared before the robustness check:**
- EXP-021 is **frozen as is** as the Phase-50 brain-support candidate for the Phase-51 visual validation: sphere radius 3, 26-connectivity, largest 3D component, dilation AND raw, 2D fill.
- No further modification of the method follows from development results.
- A **robustness check** with radius 2 and radius 4 is run **only to report sensitivity**. The radius stays 3 **whatever the outcome**: the check selects nothing.
- A lesion-GT coverage check (fraction of lesion voxels inside the mask) is **not** run; it needs a separate user decision and could only be done after the freeze, without feeding back into the mask.

**EXP-021 radius robustness check (descriptive only; radius stays 3):** `experiments/brain_mask_t1_3d_radius_sensitivity.m`, run on 2026-10-06. Radius 3 reproduces the frozen EXP-021 exactly in both conditions. No masks were saved.

| Radius | Noise | 3D comps | Largest / second | Largest holds seed anchor | Candidate voxels | Last non-empty | IoU vs r = 3 | Area k = 40 / 44 / 91 / 136 / 150 |
|---:|---|---:|---|---|---:|---:|---:|---|
| 2 | `pn0` | 158 | 1,285,513 / 541,407 | yes | 1,723,147 | 160 | 0.977 | 10,250 / 10,926 / 18,395 / 6,686 / 1,719 |
| 2 | `pn3` | 213 | 1,251,996 / 501,454 | yes | 1,707,897 | 160 | 0.974 | 10,091 / 10,753 / 18,290 / 6,613 / 1,672 |
| 3 | `pn0` | 263 | 1,015,104 / 287,327 | yes | 1,688,787 | 160 | 1 | 9,922 / 10,622 / 18,196 / 6,563 / 1,626 |
| 3 | `pn3` | 351 | 969,761 / 244,567 | yes | 1,668,366 | 156 | 1 | 9,809 / 10,451 / 18,122 / 6,491 / 1,427 |
| 4 | `pn0` | 118 | 819,102 / 157,968 | yes | 1,645,701 | 156 | 0.974 | 9,785 / 10,425 / 16,737 / 6,319 / 1,325 |
| 4 | `pn3` | 125 | 768,104 / 140,924 | yes | 1,612,718 | 156 | 0.967 | 9,636 / 10,249 / 16,400 / 6,176 / 1,250 |

`pn0`/`pn3` IoU: 0.9887 (r = 2), 0.9848 (r = 3), 0.9779 (r = 4). (`exp021_t1_3d_radius_sensitivity.csv`; `exp021_t1_3d_radius_sensitivity_area.png`, `exp021_t1_3d_radius_sensitivity_mosaic.png`.)

- **Identity is radius-independent:** for every radius and both noise levels, the largest 3D component is the brain and contains the seed anchor. At the skull base the mask holds the temporal lobes and cerebellum without face/neck for all radii (mosaic).
- **Small, monotonic size effect:** a larger radius gives a slightly smaller mask (1.72 M → 1.69 M → 1.65 M voxels in `pn0`), with less vertex cortex.
  - At r = 4 the ventricles at k = 91 are **no longer filled** (16,737 px, and the coronal view shows open ventricles). The less-restored tissue no longer encloses them in the axial plane.
  - r = 2 restores slightly more. Its margin between the brain and the second component is narrower in relative terms (1,285,513 versus 541,407) but still large.
- **Conclusion:** the EXP-021 result is **robust** to ±1 voxel of radius (IoU ≥ 0.967 with r = 3; `pn0`/`pn3` IoU ≥ 0.978). As declared, **r = 3 is kept**. The check does not justify any change, and none was made.

**EXP-021 outputs** (excluded from Git):

- candidates: `data/processed/exp021_t1_pn0_3d_erode_select_dilate_candidate.mat`, `data/processed/exp021_t1_pn3_3d_erode_select_dilate_candidate.mat` (variables `candidate`, `core`, `radius`, `threshold`);
- metrics: `results/metrics/exp021_t1_3d_summary.csv`, `results/metrics/exp021_t1_3d_per_slice.csv`;
- figures: `results/figures/exp021_t1_3d_area_per_slice.png`, `results/figures/exp021_t1_pn0_3d_steps.png`, `results/figures/exp021_t1_pn3_3d_steps.png`, `results/figures/exp021_t1_3d_orthogonal_views.png`.

**EXP-020 outputs** (excluded from Git):

- candidates: `data/processed/exp020_t1_pn0_zpropagation_candidate.mat`, `data/processed/exp020_t1_pn3_zpropagation_candidate.mat` (not adopted);
- metrics: `results/metrics/exp020_t1_zpropagation_summary.csv`, `results/metrics/exp020_t1_zpropagation_per_slice.csv`;
- figures: `results/figures/exp020_t1_zpropagation_per_slice.png`, `results/figures/exp020_t1_pn0_zpropagation_steps.png`, `results/figures/exp020_t1_pn3_zpropagation_steps.png`.

**EXP-019 outputs** (excluded from Git):

- candidates: `data/processed/exp019_t1_pn0_zpropagation_candidate.mat`, `data/processed/exp019_t1_pn3_zpropagation_candidate.mat` (not adopted);
- metrics: `results/metrics/exp019_t1_zpropagation_summary.csv`, `results/metrics/exp019_t1_zpropagation_per_slice.csv`;
- figures: `results/figures/exp019_t1_zpropagation_per_slice.png`, `results/figures/exp019_t1_pn0_zpropagation_steps.png`, `results/figures/exp019_t1_pn3_zpropagation_steps.png`.

**EXP-018 outputs** (excluded from Git):

- candidates: `data/processed/exp018_t1_pn0_zpropagation_candidate.mat`, `data/processed/exp018_t1_pn3_zpropagation_candidate.mat` (variables `candidate`, `seedSlice`, `threshold`; not adopted);
- metrics: `results/metrics/exp018_t1_zpropagation_summary.csv`, `results/metrics/exp018_t1_zpropagation_per_slice.csv`;
- figures: `results/figures/exp018_t1_zpropagation_per_slice.png`, `results/figures/exp018_t1_pn0_zpropagation_steps.png`, `results/figures/exp018_t1_pn3_zpropagation_steps.png`.

**EXP-017 outputs** (excluded from Git):

- candidates: `data/processed/exp017_t1_pn0_canny_enclosing_candidate.mat`, `data/processed/exp017_t1_pn3_canny_enclosing_candidate.mat` (variables `candidate`, `closedEdges`, `selection`, `enclosingAreas`, `threshold`; not adopted);
- metrics: `results/metrics/exp017_t1_canny_enclosing_summary.csv`, `results/metrics/exp017_t1_canny_enclosing_per_slice.csv`;
- figures: `results/figures/exp017_t1_canny_enclosing_per_slice.png`, `results/figures/exp017_t1_pn0_canny_enclosing_steps.png`, `results/figures/exp017_t1_pn3_canny_enclosing_steps.png`.

**EXP-016 outputs** (excluded from Git):

- edges: `data/processed/exp016_t1_pn0_canny_edges.mat`, `data/processed/exp016_t1_pn3_canny_edges.mat` (variables `cannyEdges`, `thresholds`; raw edge maps, not masks);
- metrics: `results/metrics/exp016_t1_canny_summary.csv`, `results/metrics/exp016_t1_canny_per_slice.csv`;
- figures: `results/figures/exp016_t1_canny_per_slice.png`, `results/figures/exp016_t1_pn0_canny_steps.png`, `results/figures/exp016_t1_pn3_canny_steps.png`.

**EXP-015 outputs** (excluded from Git):

- markers: `data/processed/exp015_t1_pn0_dark_background_marker.mat`, `data/processed/exp015_t1_pn3_dark_background_marker.mat` (variables `internalDark`, `internalBackgroundMarker`, `anchorMask`, `parentMask`, `threshold`; marker candidates, not masks);
- metrics: `results/metrics/exp015_t1_dark_background_marker_summary.csv`, `results/metrics/exp015_t1_dark_background_marker_per_slice.csv`;
- figures: `results/figures/exp015_t1_marker_per_slice.png`, `results/figures/exp015_t1_pn0_marker_steps.png`, `results/figures/exp015_t1_pn3_marker_steps.png`, `results/figures/exp015_t1_marker_on_t1.png`.

**EXP-014 outputs** (excluded from Git):

- candidates: `data/processed/exp014_t1_pn0_watershed_support_mask_candidate.mat`, `data/processed/exp014_t1_pn3_watershed_support_mask_candidate.mat` (variables `candidate`, `foregroundMarker`, `nonBrainMarker`, `parentMask`, `threshold`; not adopted);
- metrics: `results/metrics/exp014_t1_watershed_summary.csv`, `results/metrics/exp014_t1_watershed_per_slice.csv`;
- figures: `results/figures/exp014_t1_area_per_slice.png`, `results/figures/exp014_t1_pn0_watershed_steps.png`, `results/figures/exp014_t1_pn3_watershed_steps.png`.

**EXP-013 outputs** (excluded from Git):

- candidates: `data/processed/exp013_t1_pn0_siblings_support_mask_candidate.mat`, `data/processed/exp013_t1_pn3_siblings_support_mask_candidate.mat` (variables `candidate`, `anchorMask`, `parentMask`, `selectedChildrenMask`, `threshold`; not adopted);
- metrics: `results/metrics/exp013_t1_siblings_summary.csv`, `results/metrics/exp013_t1_siblings_per_slice.csv`;
- figures: `results/figures/exp013_t1_area_per_slice.png`, `results/figures/exp013_t1_pn0_siblings_steps.png`, `results/figures/exp013_t1_pn3_siblings_steps.png`.

**EXP-012 outputs** (excluded from Git):

- candidates: `data/processed/exp012_t1_pn0_nested_support_mask_candidate.mat`, `data/processed/exp012_t1_pn3_nested_support_mask_candidate.mat` (variables `candidate`, `selectedMask`, `threshold`; not adopted);
- metrics: `results/metrics/exp012_t1_nested_summary.csv`, `results/metrics/exp012_t1_nested_per_slice.csv`;
- figures: `results/figures/exp012_t1_area_per_slice.png`, `results/figures/exp012_t1_pn0_nested_steps.png`, `results/figures/exp012_t1_pn3_nested_steps.png`, `results/figures/exp012_t1_enclosure_relation.png`.

**EXP-011 outputs** (excluded from Git):

- candidates: `data/processed/exp011_t1_pn0_support_mask_candidate.mat`, `data/processed/exp011_t1_pn3_support_mask_candidate.mat` (variables `candidate`, `threshold`; not adopted);
- metrics: `results/metrics/exp011_t1_largest_component_summary.csv`, `results/metrics/exp011_t1_largest_component_per_slice.csv`;
- figures: `results/figures/exp011_t1_area_per_slice.png`, `results/figures/exp011_t1_pn0_cleanup_steps.png`, `results/figures/exp011_t1_pn3_cleanup_steps.png`.

**EXP-010 outputs** (excluded from Git):

- raw masks: `data/processed/exp010_t1_pn0_raw_support_mask.mat`, `data/processed/exp010_t1_pn3_raw_support_mask.mat`;
- metrics: `results/metrics/exp010_t1_raw_mask_summary.csv`, `results/metrics/exp010_t1_component_diagnostics.csv`;
- figures: `results/figures/exp010_pn0_t1_vs_t2_raw_masks.png`, `results/figures/exp010_pn3_t1_vs_t2_raw_masks.png`, `results/figures/exp010_t1_histograms_otsu.png`.

**EXP-009 outputs** (excluded from Git):

- masks: `data/processed/exp009_reconstruction_t2_pn0_support_mask.mat`, `data/processed/exp009_reconstruction_t2_pn3_support_mask.mat`;
- metrics: `results/metrics/exp009_reconstruction_markers_summary.csv`, `results/metrics/exp009_reconstruction_markers_per_slice.csv`;
- figures: `results/figures/exp009_area_ratio_per_slice.png`, `results/figures/exp009_pn0_markers_and_candidate.png`, `results/figures/exp009_pn3_markers_and_candidate.png`.

**EXP-008 outputs** (excluded from Git):

- masks: `data/processed/exp008_watershed_t2_pn0_support_mask.mat`, `data/processed/exp008_watershed_t2_pn3_support_mask.mat`;
- metrics: `results/metrics/exp008_watershed_summary.csv`, `results/metrics/exp008_watershed_per_slice.csv`;
- figures: `results/figures/exp008_area_ratio_per_slice.png`, `results/figures/exp008_pn0_markers_and_candidate.png`, `results/figures/exp008_pn3_markers_and_candidate.png`, `results/figures/exp008_gradient_watershed_lines.png`.

**Outputs** (excluded from Git):

- EXP-007 masks: `data/processed/exp007_t2_pn0_support_mask.mat`, `data/processed/exp007_t2_pn3_support_mask.mat` (not selected); metrics `results/metrics/exp007_erode_select_dilate_summary.csv`, `results/metrics/exp007_area_per_slice.csv`; figures `results/figures/exp007_raw_A_exp007_masks.png`, `results/figures/exp007_area_per_slice.png`;
- masks: `data/processed/phase50_t2_pn0_support_mask_candidate.mat`, `data/processed/phase50_t2_pn3_support_mask_candidate.mat` (variables `mask`, `cleanupRule`; candidate A);
- metrics: `results/metrics/phase50_support_mask_cleanup_summary.csv`, `results/metrics/phase50_support_mask_cleanup_per_slice.csv`;
- figures: `results/figures/phase50_raw_vs_clean_masks.png`, `results/figures/phase50_candidateA_per_slice_diagnostics.png`, `results/figures/phase50_candidateB_masks.png`.

### 13.29 Phase 51: visual validation of the EXP-021 brain mask

Phase 51 is a **roadmap validation** of the frozen EXP-021 brain-support mask. It is not an experiment and not EXP-022: no algorithm or parameter was changed, and the mask was neither recomputed nor edited.

- **Mask validated:** `data/processed/exp021_t1_pn0_3d_erode_select_dilate_candidate.mat` and `..._pn3_...` (variable `candidate`; frozen radius 3).
- **MRI:** `t1_ai_msles2_1mm_pn0_rf0.raws` and `t1_ai_msles2_1mm_pn3_rf0.raws` (development data only; normalized /4095, no filter). No GT, no anatomical labels, no held-out data.
- **Method** (`experiments/phase51_validate_exp021_brain_mask.m`, display utility `src/visualization/overlayMaskBoundaryOnMRI.m`):
  - The primary view is the T1 with the mask **boundary**.
  - The boundary is extracted for display only, on each 2D section, as `mask AND NOT imerode(mask, true(3))` (the morphological boundary). It is kept separate from the mask.
- **Views:**
  - axial contact sheet every 5 slices plus k = 181;
  - enlarged axial diagnostic slices k = 1, 40, 43, 44, 46, 91, 136, 139, 143, 160, 181 (boundary and semi-transparent fill);
  - coronal planes j = 54, 109, 163 and sagittal planes i = 45, 91, 136 (1/4, 1/2, 3/4 of each dimension);
  - mask-only central planes and projections along the three axes;
  - `pn0` and `pn3` with identical indices and display conventions.
- **Checks:** all 16 checks PASS (sizes, logical mask, finite MRI, frozen radius 3; mask, saved file and raw MRI unchanged after display).

Descriptive statistics, which do not replace the visual validation: 1,688,787 / 1,668,366 voxels; 160 / 156 non-empty slices (1 to 160 / 1 to 156); area at k = 150 / 155 / 160 = 1,626 / 515 / 30 (`pn0`) and 1,427 / 131 / 0 (`pn3`); `pn0`/`pn3` IoU 0.9848.

**Visual findings** (categories: A important tissue exclusion, B minor tissue exclusion, C extracranial inclusion, D expected non-brain exclusion, E documented support extension, F display artefact). The per-view table is in `results/metrics/phase51_exp021_visual_validation.csv`, written from visual inspection.

- **Central slices (k ≈ 66–126):** the boundary follows the cortical surface of **both hemispheres**. Scalp and skull are excluded, the ventricles are filled, and only surface-open fissure/sulcal CSF is excluded (D). No false internal holes cross visible tissue.
- **Cerebellum, brainstem, temporal lobes:** retained (axial k = 16–61; coronal j = 54 and 109; sagittal i = 45 and 136). The temporal lobes appear from k ≈ 26.
- **Skull base, orbit, sinus, face, neck:** excluded. The coronal view at j = 163 stops at the frontal base above the orbits, and j = 109 has no neck tissue. Minor uncertain inclusions (C?, negligible): a few thin structures between the orbits at k = 46 (possibly inferior gyrus rectus/olfactory region or ethmoid septa; identity not claimed) and a tiny isolated contour at k = 21.
- **Spinal cord (E):** a narrow continuation of the brainstem down to k = 1 (98 px), with no face or neck tissue around it (axial k = 1–11, sagittal i = 91, projections).
- **Superior artefact:** excluded (no mask at k ≥ 161).
- **Vertex (B, the main limitation):**
  - At k ≈ 131–141 a little outer cortical rim is excluded at sulcal openings.
  - At k ≈ 146–160 cortex that is **visibly present in the MRI** is only partly covered: fragments at k = 151, a small strip at k = 156, 30 / 0 px at k = 160. The coronal view at j = 54 shows the superior cortex partly cut.
  - The loss concerns thin, tangentially cut superior gyri and is small in volume. It is not a lobe-level or hemisphere-level loss.
- **Mid-sagittal plane (i = 91):** gaps and horizontal stripes come from the interhemispheric-fissure CSF and the slice-wise axial hole filling (D). The corpus callosum, thalamus, brainstem and cord are retained. CSF exclusion was assessed separately from tissue exclusion.
- **`pn0` versus `pn3`:** the same anatomical behaviour in every view. `pn3` ends 4 slices earlier at the vertex.

**Checklist (both conditions):**

1. major cerebral tissue retained: yes;
2. both hemispheres: yes;
3. cerebellum: yes;
4. brainstem: yes;
5. temporal lobes: yes;
6. thin superior cortex: **partly** (B, k ≈ 146–160);
7. scalp excluded: yes;
8. orbits excluded: yes;
9. face excluded: yes (negligible uncertain structures at k = 46);
10. neck excluded: yes;
11. artefact excluded: yes;
12. large false internal holes: no;
13. sagittal gaps explained by CSF/fissure: yes;
14. spinal cord included: yes, as a narrow continuation;
15. does the spinal cord compromise the later lesion analysis: no. It is a small, narrow brain-continuous support with no extracranial tissue; reasoning from the support role only, without lesion GT.

No important (A) exclusion was found, and no manual correction is required.

**Decision: Phase 51 PASS WITH DOCUMENTED LIMITATIONS.**

- **Limitations:**
  - (B) partial loss of thin superior cortex near the vertex (about k ≥ 146);
  - (D) surface-open CSF excluded, since this is a brain-tissue support and not an intracranial-cavity mask;
  - (E) a narrow spinal-cord continuation;
  - (C?) negligible uncertain structures at k = 46 and k = 21.
- **EXP-021 is the visually validated development brain-mask method** (development data `pn0`/`pn3` only, not held-out validation).
- **Phase 50 status:** PASS (EXP-021 frozen and validated).

Ready for Phase 52 (not started). Phase 40 remains deferred until after Phase 52.

**Phase 51 outputs** (excluded from Git):

- figures:
  - `results/figures/phase51_exp021_axial_contact_sheet_pn0.png`, `results/figures/phase51_exp021_axial_contact_sheet_pn3.png`;
  - `results/figures/phase51_exp021_axial_diagnostic_pn0.png`, `results/figures/phase51_exp021_axial_diagnostic_pn3.png`;
  - `results/figures/phase51_exp021_coronal_validation.png`, `results/figures/phase51_exp021_sagittal_validation.png`;
  - `results/figures/phase51_exp021_orthogonal_mask_validation.png`;
- metrics: `results/metrics/phase51_exp021_descriptive_statistics.csv`, `results/metrics/phase51_exp021_visual_validation.csv`.

### 13.30 Phase 52: application of the EXP-021 brain mask to T2

Phase 52 is a **roadmap implementation step**. It is not an experiment and not EXP-022: EXP-021 was neither recomputed nor modified.

- **Source masks:** the frozen, Phase-51-validated EXP-021 masks `data/processed/exp021_t1_pn0_3d_erode_select_dilate_candidate.mat` and `..._pn3_...` (variable `candidate`). The mask is **T1-derived**, and no new mask was generated from T2.
- **Target:** T2 `t2_ai_msles2_1mm_pn0_rf0.raws` and `t2_ai_msles2_1mm_pn3_rf0.raws` (paths from `config.m`), development data only.
  - The masks are applied per condition (`pn0` mask → `pn0` T2, `pn3` mask → `pn3` T2), never crossed.
  - T2 uses the validated loader, then `double`, then /4095. Preprocessing: NONE. No registration, resampling, interpolation or resize.
- **Application rule:** `analysisDomain = brainMask` (the EXP-021 `candidate`). Every later lesion-related statistic or operation uses only voxels with `brainMask == true`. The mask is a spatial restriction only: it does not classify lesion, tissue or CSF.
- **Two representations** (`src/preprocessing/applyBrainMask.m`):
  - `maskedT2`: the normalized T2 with exactly 0 outside the mask, kept full size for display, storage and geometry compatibility. **The zeros are artificial** and must never enter histograms or threshold estimation.
  - `brainValues = T2(brainMask)`: the **authoritative brain-only intensity population**. Phase 40 and all later statistics must use `T2(brainMask)`, **not** `maskedT2(:)`, which would recreate a large artificial background peak. `brainValues` is not stored, because it is reproduced exactly by indexing.
- **Script:** `experiments/phase52_apply_exp021_brain_mask_to_t2.m`; run on 2026-10-07. All 32 checks PASS:
  - geometry before application: T2 and mask both 181 × 217 × 181 and identical, mask logical, T2 finite, frozen radius 3;
  - after application: T2 and mask unchanged; in-mask values identical to T2; outside-mask values exactly 0; `numel(brainValues) = nnz(mask)` and `brainValues = T2(brainMask)`; no NaN/Inf; raw T2 unchanged on reload; saved output reloads identically.

| T2 + EXP-021 mask | `pn0` | `pn3` |
|---|---:|---:|
| Total voxels | 7,109,137 | 7,109,137 |
| Mask (retained) voxels | 1,688,787 (23.76 %) | 1,668,366 (23.47 %) |
| Excluded voxels | 5,420,350 (76.24 %) | 5,440,771 (76.53 %) |
| Brain-only T2 min / max | 0.3158 / 0.9841 | 0.2252 / 0.9924 |
| Brain-only T2 mean / std | 0.5677 / 0.1129 | 0.5134 / 0.1041 |
| In-mask voxels modified / non-zero voxels outside the mask | 0 / 0 | 0 / 0 |

These statistics are descriptive only; the distribution is not interpreted here. The lower `pn3` mean is in line with the known whole-volume relation pn3 ≈ 0.869·pn0 + 0.024 (open question 17, still unresolved).

**Visual application check** (`results/figures/phase52_t2_pn0_brain_mask_application.png`, `..._pn3_...`; k = 1, 40, 46, 91, 136, 143, 160):

- **Alignment:** the T1-derived boundary follows the T2 brain outline in every slice shown, with **no systematic shift**, consistent with the shared BrainWeb geometry.
- **Excluded regions:** scalp, skull, orbits and face are excluded on T2. The bright surface CSF of the sulci and fissure is outside the mask, as expected for a tissue mask.
- **Observation for later phases, not interpreted here:** the **ventricles** are inside the mask, because EXP-021 fills enclosed holes slice by slice, and in T2 they are **very bright**. The brain-only T2 population therefore contains ventricular CSF together with brain tissue. This has to be taken into account in Phase 40 and the lesion-segmentation phases. No decision is taken here.
- **Known EXP-021 limitations carried over:** small vertex support (k = 160: 30 px), a narrow spinal-cord continuation (k = 1), and the thin uncertain structures at k = 46.

**Decision: Phase 52 PASS.** EXP-021 is now the operational brain-support mask for the subsequent lesion-related development stages. No GT or labels were used, no lesion segmentation was run, and no Phase-40 histogram was produced. **Ready to resume Phase 40** (brain-only histogram analysis on `T2(brainMask)`), not started.

**Phase 52 outputs** (excluded from Git):

- data: `data/processed/phase52_t2_pn0_brain_masked.mat`, `data/processed/phase52_t2_pn3_brain_masked.mat` (variables `maskedT2`, `brainMask`, `metadata`);
- metrics: `results/metrics/phase52_t2_brain_mask_application.csv`;
- figures: `results/figures/phase52_t2_pn0_brain_mask_application.png`, `results/figures/phase52_t2_pn3_brain_mask_application.png`.

### 13.31 Phase 40 (resumed): brain-only histogram analysis

Phase 40 was deferred on 2026-10-04 (Section 13.17) and resumed after Phase 52, as declared there.

- **Mask:** the frozen, Phase-51-validated EXP-021 brain mask, used per condition (`pn0` mask for `pn0` volumes, `pn3` mask for `pn3`).
- **Values:** `volume(brainMask)`, the raw `uint16` values inside the mask. The zero-padded `maskedT2` is **never** used (Section 13.30).
- **Data:**
  - `pn0`: T1, T2 and PD, the same configuration as Phases 38–39;
  - `pn3`: T1 and T2. The PD `pn3` volume was never downloaded and is not needed.
  - No GT, labels or held-out data.
- **Binning:** as in Phase 39, one bin per raw value 0…4095 (edges −0.5:1:4095.5), identical for all modalities.
- **Code:** `experiments/brain_only_histograms.m`; run on 2026-10-08. All 25 checks PASS: volume and mask sizes match; histogram total equals `nnz(mask)`; histogram-based mean equals the value mean; the global total equals all voxels; volumes are unchanged.

| Condition / modality | Brain voxels | Min | Max | Mean | Median | Std | Mode | Zero voxels in mask | Global mean / median (Phases 38–39 reference) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `pn0` T1 | 1,688,787 | 371 | 2394 | 1897.62 | 1830 | 400.21 | 2373 | 0 | 877.43 / 636 |
| `pn0` T2 | 1,688,787 | 1293 | 4030 | 2324.81 | 2327 | 462.32 | 1859 | 0 | 1370.07 / 1615 |
| `pn0` PD | 1,688,787 | 1904 | 4036 | 3459.96 | 3554 | 235.57 | 3133 | 0 | 1876.61 / 3115 |
| `pn3` T1 | 1,668,366 | 363 | 2484 | 1771.75 | 1731 | 372.80 | 1634 | 0 | 847.48 / 572 |
| `pn3` T2 | 1,668,366 | 922 | 4064 | 2102.41 | 2067 | 426.34 | 2155 | 0 | 1287.74 / 1455 |

Figures: `results/figures/phase40_{t1,t2,pd}_pn0_brain_only_histogram.png` and `phase40_{t1,t2}_pn3_brain_only_histogram.png`. Each shows the linear count, the log count (display only) and a shape comparison with the Phase 39 global histogram, each normalized to its own total.

**Descriptive observations** (positions read approximately from the figures; **no tissue identity is assigned and no threshold is derived**):

- **Background removed:** the dominant low-end cluster of the global histograms (Phase 39: 0…100 raw values hold about 37–41 % of all voxels) is **completely absent**. No brain voxel is 0, and every mean and median rises strongly. The brain-only distribution is far less dominated by a single cluster.
- **`pn0` T2:**
  - a narrow dominant peak near 1859 (the mode), a second narrow peak near 2420, and a small peak near 3990, with a continuum between them and a step near 3430;
  - a low shelf of very few voxels between about 1300 and 1850;
  - these are the same narrow peaks seen in the global T2 histogram (Section 13.16), so those global peaks are produced by voxels inside the brain support;
  - 137,080 voxels (8.1 %) lie at raw ≥ 3000 (a descriptive count, not a threshold).
- **`pn0` T1:**
  - narrow peaks near 690, 1740 and 2373 (the mode); the global peak near 1560 is absent inside the mask;
  - the high tail above about 2390 of the global T1 histogram is absent, so the brightest T1 voxels are outside the brain support;
  - **circularity (declared before the run):** there is a sharp **step at raw value 1060**, the EXP-010 Otsu threshold (66/255 × 4095 ≈ 1060). The count jumps from 102 at 1059 to 225 at 1060. Only 64,917 voxels (3.8 %) lie below it, and they come from the slice-wise filling of enclosed holes (for example the ventricles). The T1 brain-only histogram is therefore **shaped by the mask construction** and is not an independent description of T1 tissue.
- **`pn0` PD:** narrow peaks near 3133 (the mode), 3650 and 3870, and a sparse tail above 3870. A handful of isolated values lie between 1900 and 3100.
- **`pn3` T2:**
  - noise turns the narrow `pn0` peaks into **broad, overlapping modes** near 1730 and 2190 (the mode is 2155), with a deep valley between them, plus a small broad hump near 3560;
  - the range widens to 922–4064;
  - the positions are lower than in `pn0`, in line with the whole-volume relation pn3 ≈ 0.869·pn0 + 0.024 (for example 0.869·1859 + 98 ≈ 1713, 0.869·2420 + 98 ≈ 2201, 0.869·3990 + 98 ≈ 3565; open question 17, still unresolved).
  - 79,129 voxels (4.7 %) lie at raw ≥ 3000.
- **`pn3` T1:** mode 1634, range 363–2484 (statistics only).

**Interpretation limits:**

- The mask is a brain-**tissue** support: surface-open CSF is excluded, but the ventricles are included (Section 13.30). The brain-only distributions therefore mix brain tissue with ventricular CSF.
- The T1 histogram is truncated by construction at the Otsu threshold, and T2/PD are indirectly selected by the T1-based mask.
- Assigning peaks to tissues, or deriving lesion thresholds, is out of scope here. It belongs to the segmentation phases, under the Phase-37 development protocol.

**Decision: Phase 40 COMPLETE** (brain-only histogram analysis, descriptive). No GT, threshold, segmentation or modality change; T2 remains the provisional lesion modality.

**Phase 40 outputs** (excluded from Git):

- metrics: `results/metrics/phase40_brain_only_histogram_summary.csv`, `results/metrics/phase40_brain_only_histogram_counts.csv`;
- figures: `results/figures/phase40_t1_pn0_brain_only_histogram.png`, `results/figures/phase40_t2_pn0_brain_only_histogram.png`, `results/figures/phase40_pd_pn0_brain_only_histogram.png`, `results/figures/phase40_t1_pn3_brain_only_histogram.png`, `results/figures/phase40_t2_pn3_brain_only_histogram.png`.

### 13.32 Phase 53: baseline lesion-segmentation method (definition only)

Phase 53 is a **method-definition** phase. No threshold value was chosen, no threshold experiment was run, and no lesion metric was computed. It is not EXP-022.

- **Status of the inputs:**
  - Phase 40 is complete (Section 13.31).
  - T2 remains the provisional lesion modality (Phase 41). T1 only provides the brain mask.
  - EXP-021 (Phases 50–52) is the operational spatial support.
  - Baseline preprocessing is NONE (Phase 47).
- **Baseline pipeline:**

  ```text
  raw T2 -> double -> /4095 -> no filter -> EXP-021 brainMask -> one global upper threshold T -> lesionCandidateMask
  ```

  `lesionCandidateMask = brainMask AND (T2_norm > T)`, with:
  - a **strict `>`** comparator;
  - **one T** for the whole 3D volume, in the normalized [0, 1] domain (raw equivalent exactly 4095·T);
  - a logical 181 × 217 × 181 output, always false outside `brainMask`;
  - no morphology, component filtering, region growing, multimodal fusion or manual correction.

  The output is a **candidate** mask, not a final lesion mask.
- **Deferred on purpose:** the value of T and its estimation method (Phases 54–57). Any later rule must follow the Phase-37 protocol (one shared rule for `pn0` and `pn3`).
- **Ventricular-CSF ambiguity (known, not solved):** EXP-021 includes the ventricles, and ventricular CSF is very bright in T2 (Sections 13.30–13.31). High T2 intensity is **not** equated with lesion. The baseline is a high-intensity candidate detector and is expected to produce CSF false positives. No ventricle exclusion, CSF threshold, T1 suppression or label use was introduced.
- **Implementation:** `src/segmentation/thresholdLesionCandidates.m` applies a **provided** threshold only. It validates the volume (real, finite, values in [0, 1], so for example a raw 0…4095 volume is rejected), the mask (logical, same size) and the threshold (finite real scalar in [0, 1]); it does not estimate T, load files or use GT.
- **Software check:** `experiments/lesion_threshold_function_check.m` uses **synthetic arrays and an artificial threshold only** (no BrainWeb data, no real threshold). It verifies:
  - the output has the same size as the input and is logical;
  - the output equals `brainMask AND volume > T` and is never true outside the mask;
  - voxels equal to T are false (strict `>`);
  - T = 1 gives no candidates, T = 0 keeps only in-mask values above 0, and an empty mask gives an empty output;
  - the inputs are unchanged;
  - the negative tests raise the exact identifiers: size mismatch, non-logical mask, threshold < 0, > 1, NaN, Inf or non-scalar, a NaN in the volume, and a volume outside [0, 1] (raw-scale and negative values).

  It was run in MATLAB R2026b on 2026-10-08, and all 21 checks of the first version pass. After a user review, the explicit [0, 1] volume-range check was added (the documentation stated the domain, but the function did not enforce it), together with two negative tests. Rerun on 2026-10-08: all 23 checks pass.
- No GT, labels or held-out data were used, and no segmentation experiment was executed. `config.m` is unchanged (no threshold parameter added); `PROJECT_SPEC.md` gained Section 10.1.

**Decision: Phase 53 COMPLETE.** The baseline lesion segmentation is a single global upper-intensity threshold on unfiltered normalized T2 inside the validated EXP-021 brain-support mask. The threshold value and the threshold-selection method remain intentionally unresolved. Ready for Phase 54 (manual global threshold, as an experiment), not started.

### 13.33 Phase 54: manually defined global T2 threshold (EXP-022)

**Pre-registration (written before any EXP-022 candidate mask was generated):**

- **Threshold source:** only the saved Phase-40 brain-only T2 histograms (`results/metrics/phase40_brain_only_histogram_counts.csv`, columns `pn0_T2` and `pn3_T2`; 4096 bins, one per raw value), read in 100-value windows:
  - `pn0`: counts decline steadily after the peak near 2420. There is a step between 3300–3399 (13,777) and 3400–3499 (9,236), a minimum between about 3500 and 3699 (6,903 and 7,005), then a rise to the narrow high-intensity peak near 3990 (3900–3999: 28,364).
  - `pn3`: counts decline to a valley at 3200–3299 (7,924), then a broad high-intensity hump peaking at 3500–3599 (13,848).
- **Choice:** there is **no unique common valley**: the `pn3` valley is near 3250 and the `pn0` minimum is near 3550. One single compromise value was therefore chosen manually: **T_raw = 3400**. It lies between the two valleys, almost at the `pn0` step (about 3430), and separates the main lower/mid-intensity population from the brighter high-intensity population in both conditions.
  - The choice is heuristic and ambiguous by nature; it has no optimality meaning.
  - **T_normalized = 3400/4095 = 0.830280830…**, passed to `thresholdLesionCandidates` with the strict `>` comparator.
  - The same value is used for `pn0` and `pn3`.
- **Disclosure of GT exposure:** the project already contains offline GT class statistics for T2 from Phase 41 (Section 13.18; for example the lesion mean 3320.5 and the CSF mean 3607.6). They were known when this threshold was chosen and cannot be "unseen". They were **not** used for the choice, which follows the histogram features listed above, and the value was not adjusted toward or away from them. No GT was loaded in Phase 54.
- **Status:** **FROZEN FOR EXP-022.** Exactly one threshold, no sweep, no change after the results.

**EXP-022 results** (run on 2026-10-09 with the frozen T_raw = 3400; `experiments/exp022_manual_global_threshold_t2.m`; all 31 checks PASS):

| | `pn0` | `pn3` |
|---|---:|---:|
| Brain-mask voxels | 1,688,787 | 1,668,366 |
| Candidate voxels | 70,866 | 42,046 |
| Fraction of brain mask / of whole volume | 4.20 % / 1.00 % | 2.52 % / 0.59 % |
| Slices with candidates; first / last | 141; 12 / 152 | 120; 12 / 146 |
| Candidate raw T2 min / max / mean / median | 3401 / 4030 / 3790.5 / 3846 | 3401 / 4064 / 3578.1 / 3571 |

With the same absolute threshold, `pn3` gives 0.60 × the candidate fraction of `pn0` (difference −0.0168). This is consistent with the downward `pn3` intensity shift (open question 17). It was not corrected.

**Visual behaviour** (overlays at k = 46, 91, 136 and contact sheets every 10 slices; no GT, no TP/FP/FN):

- The candidates are **predominantly hyperintense structures anatomically compatible with CSF spaces** (no GT-based classification): the lateral ventricles (k ≈ 71–101), the third ventricle, the fourth ventricle (k ≈ 31–41), the basal cisterns and the inter-hemispheric fissure (k ≈ 61, 101–121). The ventricular-brightness issue predicted in Phase 53 is therefore observed directly.
- Many **small scattered bright spots** lie along sulci and in the parenchyma.
- `pn3` shows the same structures but is less complete (speckled ventricles), with more isolated single-pixel responses and fewer candidates overall.
- There are no candidates near the vertex above k = 152 / 146, and none outside the brain support.

**Limitations:**

- The threshold selects predominantly hyperintense structures anatomically compatible with CSF spaces, in particular ventricles and cisterns; T2 hyperintensity alone is therefore not lesion-specific. Without GT no TP/FP classification is made.
- One absolute threshold behaves differently across the noise conditions.
- The threshold is a heuristic compromise, with no common valley.
- No quality judgement is possible without the GT evaluation scheduled later.

**Status:** EXP-022 is the **REFERENCE ESTABLISHED** for Phase 54. It is not a selected method, and the threshold is not a project parameter. No GT, metric, sweep, morphology, component analysis or held-out data was used. **Phase 54 COMPLETE**; ready for Phase 55 (iterative thresholding), not started.

**Outputs** (excluded from Git):

- candidates: `data/processed/exp022_t2_pn0_manual_global_threshold_candidate.mat`, `data/processed/exp022_t2_pn3_manual_global_threshold_candidate.mat` (variables `lesionCandidateMask`, `metadata`);
- metrics: `results/metrics/exp022_manual_global_threshold_summary.csv`;
- figures:
  - `results/figures/exp022_manual_threshold_selection.png`;
  - `results/figures/exp022_t2_pn0_candidate_overlay.png`, `results/figures/exp022_t2_pn3_candidate_overlay.png`;
  - `results/figures/exp022_t2_candidate_contact_sheet_pn0.png`, `results/figures/exp022_t2_candidate_contact_sheet_pn3.png`.

### 13.34 Phase 55: iterative global thresholding on brain-only T2 (EXP-023)

- **Course algorithm:**
  1. choose an initial threshold;
  2. split the analysed intensities into two groups;
  3. take the mean of each group;
  4. set the new threshold to the average of the two means;
  5. repeat until the change is below a predefined parameter.
- **Course-source discrepancy (documented):** the prose recommends the **average intensity** as the initial value, but the slide MATLAB example uses `T1 = 0.5*mean(f(:))`. EXP-023 follows the written procedure: **T0 = mean of the analysed values**. Other initializations were not investigated, and the course exercise that sweeps initial thresholds was not run.
- **Analysed values:** `brainValues = T2_norm(brainMask)` (EXP-021, per condition). Never the zero-padded volume.
- **Fixed rule, identical for `pn0` and `pn3`:**
  - T0 = mean(brainValues);
  - partition: `R_high = values >= T`, `R_low = values < T`;
  - update: T_next = (μ_low + μ_high)/2;
  - convergence: |T_next − T| < ε with a strict `<`, the accepted threshold being T_next;
  - a safety guard of 1000 iterations;
  - an empty group, or no convergence within the guard, stops the run with an error (no fallback).
- **ε = 0.5/4095** (normalized units), which is half of one raw BrainWeb level. This is a **project choice**: the PDF example uses a tolerance of 0.5, but on `im2double` data, a different scale. ε was not tuned.
- The final threshold value is an **algorithm output per condition**, not a shared manual parameter.
- **Two comparators:** the estimation partition uses `>=` / `<`, while candidate generation keeps the Phase-53 contract `brainMask & (T2_norm > T_iter)`, with a strict `>` (`thresholdLesionCandidates`, unchanged).
- **Code:**
  - estimator `src/segmentation/estimateIterativeThreshold.m`, validated with synthetic data only by `experiments/iterative_threshold_function_check.m` (19 checks PASS, including the empty-partition and no-convergence errors);
  - experiment `experiments/exp023_iterative_threshold_t2.m`, run on 2026-10-09, with all 41 checks PASS (the history was re-verified independently, iteration by iteration, against the actual partitions).

| EXP-023 | `pn0` | `pn3` |
|---|---:|---:|
| T0 (normalized / raw-equivalent) | 0.567721 / 2324.81 | 0.513410 / 2102.41 |
| Final T_iter (normalized / raw-equivalent) | 0.567309 / 2323.13 | 0.591423 / 2421.88 |
| Threshold updates; final delta (raw-equivalent) | 2; 0.481 | 39; 0 |
| Final μ_low / μ_high (raw-equivalent) | 1984.9 / 2661.3 | 1967.5 / 2876.3 |
| Brain-mask voxels | 1,688,787 | 1,668,366 |
| Candidate voxels | 848,576 | 247,703 |
| Fraction of brain / of whole volume | 50.25 % / 11.94 % | 14.85 % / 3.48 % |
| Slices with candidates; first / last | 160; 1 / 160 | 154; 1 / 156 |
| Candidate raw T2 min / max / mean / median | 2324 / 4030 / 2661.3 / 2460 | 2422 / 4064 / 2876.3 / 2742 |

Histories: `results/metrics/exp023_iterative_threshold_history_{pn0,pn3}.csv`.

**Descriptive comparison with EXP-022** (T_raw = 3400):

- T_iter − 3400 = −1076.87 (`pn0`) and −978.12 (`pn3`) raw-equivalent.
- Candidate fraction of the brain: 50.25 % against 4.20 % (`pn0`), and 14.85 % against 2.52 % (`pn3`).
- No method is declared better (Phase 57).

**Observations** (figures `exp023_iterative_threshold_convergence.png`, `exp023_iterative_threshold_histograms.png`, `exp023_t2_{pn0,pn3}_candidate_overlay.png`, `exp023_t2_candidate_contact_sheet_{pn0,pn3}.png`; same slices and the same contact-sheet step as EXP-022; no GT, no TP/FP):

- **`pn0`:**
  - T0 (the brain-only mean) is already almost a fixed point, so the run converges after 2 updates.
  - T_iter = 2323.1 falls **between the dominant narrow peak (≈ 1859) and the second peak (≈ 2420)** of the brain-only histogram.
  - The algorithm therefore splits the two main intensity populations instead of isolating a small bright population.
  - The candidates (half of the brain support) are **large parenchymal regions of medium-high T2 intensity** (the whole intermediate-intensity population), together with the ventricles, cisterns and sulcal fluid. This is a visual observation on the MRI, not an anatomical classification: no labels were used.
- **`pn3`:**
  - The threshold rises slowly from 2102.4 to 2421.9 over 39 updates and ends **above** the `pn0` value, although `pn3` intensities are globally shifted downward.
  - With broad overlapping modes the fixed point lies elsewhere.
  - The candidates are the ventricles and cisterns plus **fragmented, speckled parenchymal pixels of medium-high intensity**, mostly along the outer brain surface (the upper tail of the intermediate population).
- **`pn0` / `pn3`:** the same rule gives very different behaviour (candidate fraction 0.50 versus 0.15). The automatic per-volume threshold does **not** compensate the intensity shift descriptively, because its fixed point depends on the **shape** of each distribution (narrow peaks versus noise-broadened modes). Open question 17 remains unresolved, and no harmonization was applied.
- **Ventricular ambiguity:** the hyperintense structures compatible with CSF spaces (ventricles, cisterns) are fully selected in both conditions, as in EXP-022.
- **Methodological conclusion:** the course iterative threshold **converges correctly** in both conditions. However, the brain-only T2 distribution does not satisfy well the implicit assumption of a bimodal separation useful for lesion segmentation:
  - in `pn0` the method essentially splits the main intensity populations of the parenchyma;
  - in `pn3` the noise strongly changes the convergence point and the candidate fraction.

  The 2 versus 39 updates are not a convergence problem, because both runs converge and every step of the history was verified. They reflect a separation reached almost immediately in `pn0`, against a long migration of the threshold on the noise-broadened `pn3` distribution. EXP-023 is not declared rejected: the method comparison belongs to Phase 57.

**Status:** EXP-023 is a **RESULT ESTABLISHED**. It is not kept or rejected as a final method (the comparison is in Phase 57). The thresholds are data-derived outputs and are not stored in `config.m`. No GT, metric, tuning, filter, morphology, component analysis or held-out data was used. **Phase 55 COMPLETE**; ready for Phase 56 (Otsu), not started.

**Outputs** (excluded from Git):

- candidates: `data/processed/exp023_t2_pn0_iterative_threshold_candidate.mat`, `data/processed/exp023_t2_pn3_iterative_threshold_candidate.mat` (variables `lesionCandidateMask`, `metadata`, `history`);
- metrics: `results/metrics/exp023_iterative_threshold_summary.csv`, `results/metrics/exp023_iterative_threshold_history_pn0.csv`, `results/metrics/exp023_iterative_threshold_history_pn3.csv`;
- figures:
  - `results/figures/exp023_iterative_threshold_convergence.png`, `results/figures/exp023_iterative_threshold_histograms.png`;
  - `results/figures/exp023_t2_pn0_candidate_overlay.png`, `results/figures/exp023_t2_pn3_candidate_overlay.png`;
  - `results/figures/exp023_t2_candidate_contact_sheet_pn0.png`, `results/figures/exp023_t2_candidate_contact_sheet_pn3.png`.

### 13.35 Phase 56: Otsu global thresholding on brain-only T2 (EXP-024)

- **Method:** the course-supported MATLAB built-in **`graythresh`** (Otsu: it minimizes the within-class variance, which is equivalent to maximizing the between-class variance of a two-class split), applied **as-is**.
- **Input population:** `brainValues = T2_norm(brainMask)` (EXP-021, per condition). The artificial zeros outside the mask and the whole volume are excluded.
- **Estimation:** `T_otsu = graythresh(brainValues)`, called once per condition with the same algorithm for `pn0` and `pn3`. The thresholds are data-derived and may differ. There was no adjustment, offset, clamping or alternative variant, and no `multithresh` or custom Otsu. The Phase-40 histogram was used for the figure only.
- **Built-in behaviour (documented, not a tuning step):** on double data `graythresh` builds an internal **256-bin** histogram over [0, 1], so T_otsu is a multiple of 1/255. In raw-equivalent units this is a step of about 16.06. Observed: 255·T_otsu = 169 (`pn0`) and 150 (`pn3`), both exact integers.
- **Candidates:** `thresholdLesionCandidates(T2_norm, brainMask, T_otsu)`, which keeps the strict `>` of Phase 53, unchanged.
- **Code:**
  - `experiments/otsu_threshold_function_check.m` (synthetic sanity check, 9/9 PASS; Otsu is not re-implemented);
  - `experiments/exp024_otsu_threshold_t2.m`, run on 2026-10-10 with all 37 checks PASS (inputs; T_otsu a finite real scalar in [0, 1] and identical when recomputed; output = `brainMask & (T2_norm > T_otsu)`; no candidate outside the mask; inputs unchanged; reload identical; no GT loader referenced).

| EXP-024 | `pn0` | `pn3` |
|---|---:|---:|
| T_otsu (normalized / raw-equivalent) | 0.662745 (169/255) / 2713.94 | 0.588235 (150/255) / 2408.82 |
| Brain-mask voxels | 1,688,787 | 1,668,366 |
| Candidate voxels | 223,204 | 257,445 |
| Fraction of brain / of whole volume | 13.22 % / 3.14 % | 15.43 % / 3.62 % |
| Slices with candidates; first / last | 158; 2 / 160 | 155; 1 / 156 |
| Candidate raw T2 min / max / mean / median | 2714 / 4030 / 3243.8 / 3130 | 2409 / 4064 / 2858.8 / 2721 |

T_otsu pn3 − pn0 = −305.12 raw-equivalent.

**Descriptive comparison** (read from the saved EXP-022/023 summaries; no method declared better):

| | `pn0` | `pn3` |
|---|---:|---:|
| T_otsu − EXP-022 (3400) | −686.06 | −991.18 |
| T_otsu − EXP-023 (T_iter) | +390.81 | −13.05 |
| Candidate fraction EXP-024 / EXP-022 / EXP-023 | 13.22 % / 4.20 % / 50.25 % | 15.43 % / 2.52 % / 14.85 % |

**Observations** (`exp024_otsu_threshold_histograms.png`, `exp024_t2_{pn0,pn3}_candidate_overlay.png`, `exp024_t2_candidate_contact_sheet_{pn0,pn3}.png`; same slices and the same contact-sheet step as EXP-022/023; no GT, no TP/FP):

- **`pn0`:** T_otsu = 2713.9 lies **above the second narrow peak (≈ 2420)**, in the decreasing high-intensity tail. Otsu separates the block of the two dominant populations from the brighter tail. The candidates are:
  - the hyperintense structures compatible with CSF spaces (ventricles, cisterns, fissure);
  - thin bright rims along the outer brain surface and the sulci;
  - small scattered spots.

  They are much less widespread than EXP-023 and broader than EXP-022.
- **`pn3`:** T_otsu = 2408.8 lies on the upper side of the broad second mode, almost at the EXP-023 value (−13.05), and the candidate fraction is similar to EXP-023. The candidates are the same CSF-compatible structures plus a **fragmented, speckled** set of medium-high-intensity parenchymal pixels, mostly along the outer surface.
- **`pn0` / `pn3`:**
  - The candidate fractions are much closer (13.2 % versus 15.4 %) than with EXP-022 (4.2 % versus 2.5 %) or EXP-023 (50.3 % versus 14.8 %).
  - However, the thresholds differ by about 305 raw levels and the spatial character differs: compact bright tail in `pn0`, speckled parenchymal pixels in `pn3`.
  - The similarity of the fractions is a property of the two-class split of each histogram, not a harmonization. Open question 17 remains unresolved, and no harmonization was applied.
- **Relation to Phase 40:** Otsu always builds a two-class partition by definition. However, the brain-only T2 distributions do **not show a clearly bimodal separation attributable to a lesion class and a non-lesion class**: `pn0` has several narrow populations and `pn3` broad overlapping modes. The two classes Otsu returns are therefore a meaningful **histogram** split, but they do not necessarily correspond to the two categories of interest, so the split is **not lesion-specific**.
- **Interpretation of the fractions:** Otsu produces much more similar candidate amounts in `pn0` and `pn3` than EXP-022 or EXP-023, and it reacts to the different distributions (threshold −305 raw levels in `pn3`) instead of imposing an absolute threshold. Similar fractions do **not** mean identical spatial behaviour (compact bright tail in `pn0`, diffuse fragmented population in `pn3`), and they say nothing yet about lesion quality, which has not been measured.
- **Ventricular ambiguity:** the hyperintense structures compatible with CSF spaces are fully selected in both conditions, as in EXP-022 and EXP-023.

**Status:** EXP-024 is a **RESULT ESTABLISHED**; the final threshold-method comparison is deferred to Phase 57. The thresholds are data-derived and are not project parameters. No GT, metric, tuning, filter, morphology, component analysis or held-out data was used. **Phase 56 COMPLETE**; ready for Phase 57, not started. Note: in the histogram figure the labels of the close `pn3` lines (Otsu 2408.8 and EXP-023 2421.9) overlap; this is a display issue only.

**Outputs** (excluded from Git):

- candidates: `data/processed/exp024_t2_pn0_otsu_threshold_candidate.mat`, `data/processed/exp024_t2_pn3_otsu_threshold_candidate.mat` (variables `lesionCandidateMask`, `metadata`);
- metrics: `results/metrics/exp024_otsu_threshold_summary.csv`;
- figures:
  - `results/figures/exp024_otsu_threshold_histograms.png`;
  - `results/figures/exp024_t2_pn0_candidate_overlay.png`, `results/figures/exp024_t2_pn3_candidate_overlay.png`;
  - `results/figures/exp024_t2_candidate_contact_sheet_pn0.png`, `results/figures/exp024_t2_candidate_contact_sheet_pn3.png`.

### 13.36 Phase 57: quantitative comparison of the thresholding methods (EXP-025)

- **Why GT is allowed now:** all three methods (EXP-022 manual, EXP-023 iterative, EXP-024 Otsu) were defined, executed and frozen **without GT**. The GT is used **only for evaluation**, following the direction MRI → method → saved prediction → GT comparison. EXP-025 evaluates the **saved** candidate masks and calls no threshold estimator, candidate generator or morphology (the script checks its own text for this).
- **GT:** `phantom_1.0mm_msles2_crisp.rawb` via `loadBrainwebGroundTruth`, with `M_GT = (labels == 10)` (3,512 voxels). The **same** `M_GT` is used for `pn0` and `pn3`, because they are noise simulations of the same `msles2` phantom.
  - `M_GT` is **not intersected with the brain mask**: a lesion voxel excluded by EXP-021 would count as a false negative of the whole pipeline.
  - The predictions themselves are already constrained to EXP-021.
- **Metric:** full-volume 3D Dice = 2|P ∩ G| / (|P| + |G|) on 181 × 217 × 181 (no per-slice average). DevelopmentScore = (Dice_pn0 + Dice_pn3)/2 (Phase 37).
- **Pre-registration:** written in `EXPERIMENT_LOG.md` before any Dice was computed. **No near-tie tolerance**: the highest score wins. Tie-breakers apply only to an exact tie (none occurred).
- No other formal metric was computed; IoU, precision, recall, specificity, volume error, lesion-wise and slice-wise metrics belong to the later evaluation phases.
- **Code:** `experiments/exp025_thresholding_comparison.m`, run on 2026-10-10 with all 72 checks PASS. These include a synthetic Dice check (identical masks 1, disjoint masks 0, partial overlap 0.5, symmetry) and integrity checks on every saved prediction (size, logical type, metadata experiment and condition, unchanged).

| Method | Condition | Predicted voxels | Intersection with GT | Dice |
|---|---|---:|---:|---:|
| EXP-022 manual (3400) | `pn0` | 70,866 | 1,474 | 0.039635 |
| EXP-022 manual (3400) | `pn3` | 42,046 | 342 | 0.015014 |
| EXP-023 iterative (2323.13 / 2421.88) | `pn0` | 848,576 | 3,512 | 0.008243 |
| EXP-023 iterative | `pn3` | 247,703 | 3,493 | 0.027809 |
| EXP-024 Otsu (2713.94 / 2408.82) | `pn0` | 223,204 | 3,505 | 0.030920 |
| EXP-024 Otsu | `pn3` | 257,445 | 3,494 | 0.026778 |

| Rank | Method | Dice `pn0` | Dice `pn3` | Weaker condition | **DevelopmentScore** |
|---:|---|---:|---:|---:|---:|
| 1 | **EXP-024 Otsu** | 0.030920 | 0.026778 | 0.026778 | **0.028849** |
| 2 | EXP-022 manual | 0.039635 | 0.015014 | 0.015014 | 0.027325 |
| 3 | EXP-023 iterative | 0.008243 | 0.027809 | 0.008243 | 0.018026 |

(`results/metrics/exp025_thresholding_dice_by_condition.csv`, `results/metrics/exp025_thresholding_method_comparison.csv`, `results/figures/exp025_thresholding_dice_comparison.png`.)

**Decision: the SELECTED INITIAL THRESHOLDING METHOD is EXP-024, Otsu (`graythresh` on T2(brainMask), per volume).** It has the highest pre-defined Phase-37 DevelopmentScore.

- The margin over EXP-022 is small (0.0015). No tolerance was declared, so the numerical rule applies as is; there was no manual override.
- This is a **development baseline**, not the final segmentation pipeline: Phases 58–59 may still evaluate multi-level and local thresholding, and the later phases morphology, components, region growing and multimodality.
- `config.m` records only the selected **method** (`cfg.segmentation.thresholdMethod = "otsu"`, no threshold value).

**Interpretation** (diagnostic overlays `exp025_t2_{pn0,pn3}_error_overlay.png`, drawn after scoring at k = 46, 91, 102, 136; k = 102 is a GT diagnostic slice already known from earlier inspection and does not influence the selection):

- **All three Dice values are very low (< 0.04).** A single global T2 threshold inside EXP-021 is dominated by false positives: the candidates are 12–242 times larger than the 3,512 GT voxels.
- **EXP-024 Otsu:** the prediction contains almost all GT voxels (3,505 / 3,494 of 3,512). The low Dice comes from the large predicted volume, mainly the hyperintense CSF-compatible structures (ventricles, cisterns, sulci, fissure) and bright rims, which are non-lesion voxels.
- **EXP-022 manual:** the most compact prediction, but T = 3400 lies inside the bright range of the lesions. It keeps only 1,474 (`pn0`) and 342 (`pn3`) GT voxels, and with the downward `pn3` intensity shift it loses most of them: the weakest condition.
- **EXP-023 iterative:** it contains all GT voxels in `pn0` but selects half of the brain, so `pn0` has the lowest Dice.
- **`pn0` / `pn3`:** they differ substantially for EXP-022 and EXP-023 and much less for Otsu (0.0309 versus 0.0268).
- **Lesion location (visual, after scoring):** the GT lesions in the diagnostic slices lie mostly periventricular, next to the very bright ventricular CSF. This explains why intensity alone cannot separate them.
- **Incidental observation:** EXP-023 `pn0` contains all 3,512 GT voxels, so the `pn0` EXP-021 mask contains every GT lesion voxel. This was observed after the freeze and is not used to change the mask.
- **Not changed:** no threshold, method, mask or preprocessing was changed after seeing the Dice values. EXP-022/023/024 remain frozen, and no CSF removal or post-processing was added.

These are **development** results (`pn0`, `pn3`), not test or generalization performance; no held-out data was used. **Phase 57 COMPLETE.** The Phase-40 multi-population histograms and these results (the main limitation is bright non-lesion fluid in the same high-intensity range) justify the next roadmap step, Phase 58 (multi-threshold evaluation), not started.

### 13.37 Phase 58: multi-threshold T2 segmentation with multithresh (EXP-026)

- **Why multi-threshold now:** ALLOWED_TECHNIQUES §5.4 allows `multithresh`/`imquantize` only when binary global thresholding is shown to be insufficient. Both conditions hold: the Phase-40 brain-only T2 histograms show more than two relevant populations, and in Phase 57 every binary global threshold gave Dice < 0.04.
- **Single controlled change versus EXP-024:** `graythresh` → `multithresh(brainValues, 2)`, with `brainValues = T2norm(brainMask)` (EXP-021 mask, no artificial zeros). Everything else is unchanged: T2, /4095, preprocessing NONE, `pn0` + `pn3`, no morphology or component analysis.
- **Pre-registered (log, before running):** N = 2 thresholds (3 classes), the minimal extension beyond binary thresholding. Candidate = **Class 3 only** (`brainMask & (imquantize(T2norm, levels) == 3)`), chosen a priori because high T2 intensity is the current cue. Same rule for both conditions; numerical thresholds may differ. Selection by the Phase-37 DevelopmentScore against EXP-024, no tolerance.
- **Why it is still multi-threshold:** the final mask equals `T2norm > levels(2)` (verified voxel by voxel), but `levels(2)` comes from the joint three-class Otsu optimization, not from binary Otsu.
- **Built-in behaviour:** `multithresh` returned `double` thresholds (no conversion needed). Unlike `graythresh`, its thresholds are not multiples of 1/255 (`pn0` upper × 255 = 184.115), so the two methods also differ in histogram discretization. This is not an adjustment.
- **GT order:** GT was loaded only after both predictions were saved (checked by the script). It was used for Dice and for diagnostic per-class counts only.
- **Code:** `experiments/multithresh_function_check.m` (synthetic, 10/10 ok) and `experiments/exp026_multithresh_t2.m` (62/62 checks PASS), run on 2026-10-10.

| | `pn0` | `pn3` |
|---|---:|---:|
| Lower threshold T1 (normalized / raw-eq.) | 0.535922 / 2194.60 | 0.486930 / 1993.98 |
| Upper threshold T2 (normalized / raw-eq.) | 0.722019 / 2956.67 | 0.658439 / 2696.31 |
| EXP-024 Otsu threshold (raw-eq., reference) | 2713.94 | 2408.82 |
| Class 1 voxels (fraction of brain mask) | 707,574 (0.4190) | 724,858 (0.4345) |
| Class 2 voxels | 834,484 (0.4941) | 808,714 (0.4847) |
| Class 3 voxels = candidates | 146,729 (0.0869) | 134,794 (0.0808) |
| GT voxels in Class 1 / 2 / 3 | 0 / 477 / 3,035 | 0 / 560 / 2,952 |
| GT voxels outside brain mask | 0 | 0 |
| Intersection with GT | 3,035 | 2,952 |
| Candidate / GT ratio | 41.78 | 38.38 |
| **Dice** | **0.040402** | **0.042688** |

| Method | Dice `pn0` | Dice `pn3` | Weaker condition | **DevelopmentScore** | Current selection |
|---|---:|---:|---:|---:|---|
| EXP-024 Otsu | 0.030920 | 0.026778 | 0.026778 | 0.028849 | no |
| **EXP-026 multithresh (N = 2, Class 3)** | 0.040402 | 0.042688 | 0.040402 | **0.041545** | **yes** |

(`results/metrics/exp026_multithresh_summary.csv`, `results/metrics/exp026_vs_otsu_comparison.csv`; EXP-024 values read from `exp025_thresholding_method_comparison.csv`.) Difference: +0.0126958.

**Decision: KEEP EXP-026. It is the current selected thresholding method** by the pre-registered DevelopmentScore rule, applied without tolerance or override. EXP-024 remains a documented alternative. `config.m` records the method family only: `thresholdMethod = "multithresh"`, `numberOfThresholds = 2`, `candidateClass = 3`, with no threshold values. This is still a **development baseline**, not the final pipeline.

**Interpretation** (figures `exp026_multithresh_histograms.png`, `exp026_t2_{pn0,pn3}_multiclass.png` at k = 46/91/136, and the post-scoring diagnostic `exp026_t2_gt_diagnostic_k102.png`):

- **Histogram:** in `pn0` the lower boundary falls between the two main parenchymal peaks, and the upper one lies in the bright tail, 242.73 raw levels above binary Otsu. In `pn3` (broader, noisier peaks) the boundaries sit in the same relative positions, 287.48 levels above Otsu.
- **Candidate volume decreased:** −34.3 % in `pn0` (146,729 vs 223,204) and −47.6 % in `pn3` (134,794 vs 257,445).
- **GT retention decreased:** 3,035 vs 3,505 (`pn0`, 86.4 %) and 2,952 vs 3,494 (`pn3`, 84.1 %). No GT voxel falls in Class 1; the lost ones are in Class 2. At k = 102 they are mostly lesion borders and small or faint lesions.
- **Bright fluid remains:** Class 3 still contains the whole lateral ventricles, the fourth ventricle and cisterns, sulcal and fissural CSF, and bright rims. The candidates are still about 40 times the GT volume.
- **Overall:** mostly outcome C (much smaller Class 3 that keeps most GT voxels), with elements of A (the bright CSF-compatible structures are unchanged) and B (14–16 % of GT moves to Class 2). The three-class model mainly places the decision boundary higher than binary Otsu. The gain comes from removing part of the bright parenchymal tail, not from separating lesions from fluid. Intensity alone remains insufficient. `pn0`/`pn3` behave more consistently (Dice 0.0404 / 0.0427) than with EXP-024.
- **Incidental:** no GT voxel lies outside the brain mask in either condition, so the `pn3` EXP-021 mask also contains all 3,512 GT voxels. This was observed after the freeze and changes nothing.
- **Not done:** no other N, no Class 2+3, no threshold change, no morphology or component filtering, no harmonization, no held-out data.

These are **development** results, not test performance. **Phase 58 COMPLETE.** Next roadmap step: Phase 59 (variable / local thresholding), not started.

### 13.38 Phase 59: variable / local T2 thresholding (EXP-027)

- **Why local thresholding now:** after Phase 58 every global rule still selects large bright non-lesion structures (EXP-026 candidates about 40 times the GT volume). The course offers a spatially variable threshold from neighbourhood statistics (ALLOWED_TECHNIQUES §5.5).
- **From the course:** `T(x,y) = a·m(x,y) + b·s(x,y)` with the local mean m and local standard deviation s, and the candidate rule `I(x,y) > T(x,y)`. The neighbourhood is that of a pixel (x,y), so processing is **2D, axial slice by slice**; the 181 binary slices are stacked into the 3D prediction. No 3D window.
- **Project choices (not from the course):**
  - square window `windowSize × windowSize`, centred on the pixel;
  - **masked statistics**: only pixels with `brainMask == true` inside the window contribute; at the image border the window is truncated (the zero padding also applies to the count, so no padding value enters the statistics);
  - **population** standard deviation, `s = sqrt(N·S2 − S1²)/N` with negative roundoff clamped to 0;
  - statistics computed on the **integer raw levels** (0…4095), then `T/4095`. The rule is linear in the intensity scale, so the method is unchanged, but the sums become exact. Without this, the many perfectly uniform `pn0` regions would get random ±roundoff in s and `I > m` would be decided by roundoff. The window sums use `conv2` with explicit vectors of ones, for the same reason (`imfilter` may factor the kernel by SVD with inexact coefficients);
  - T is not clipped (max 1.14 in the normalized domain); comparator strict `>`; no combination with any global threshold.
- **Pre-registered grid (log, before running):** a = 1; windowSize ∈ {9, 21, 41}; b ∈ {0.5, 1.0, 1.5}. That gives 9 configurations, the same for `pn0` and `pn3`. Selection by DevelopmentScore, then weaker-condition Dice; a remaining exact tie would have been reported as unresolved. No tolerance.
- **Order:** all 18 predictions were saved before the GT was loaded (checked).
- **Code:** `src/segmentation/localMeanStdThreshold2D.m`, `experiments/local_threshold_function_check.m` (synthetic, 19/19 ok), and `experiments/exp027_local_threshold_t2.m` (258/258 checks PASS, 216 of them per configuration, including invariance to outside-mask values). The first run stopped at the figure stage, after all numbers had been printed, because of a variable `image` left in the workspace by the synthetic check; the rerun gave identical numbers.

| Rank | Configuration | Dice `pn0` | Dice `pn3` | Weaker | **DevelopmentScore** | Candidates `pn0` / `pn3` | GT captured `pn0` / `pn3` |
|---:|---|---:|---:|---:|---:|---:|---:|
| 1 | **W21_B15** | 0.036055 | 0.036151 | 0.036055 | **0.036103** | 119,133 / 114,771 | 2,211 / 2,138 |
| 2 | W41_B15 | 0.033595 | 0.035162 | 0.033595 | 0.034378 | 141,511 / 133,171 | 2,436 / 2,403 |
| 3 | W41_B10 | 0.028358 | 0.027054 | 0.027054 | 0.027706 | 223,588 / 231,282 | 3,220 / 3,176 |
| 4 | W21_B10 | 0.027118 | 0.025818 | 0.025818 | 0.026468 | 213,322 / 221,989 | 2,940 / 2,911 |
| 5 | W09_B15 | 0.021164 | 0.019098 | 0.019098 | 0.020131 | 82,293 / 87,700 | 908 / 871 |
| 6 | W09_B10 | 0.021987 | 0.018073 | 0.018073 | 0.020030 | 166,494 / 198,007 | 1,869 / 1,821 |
| 7 | W41_B05 | 0.016849 | 0.016007 | 0.016007 | 0.016428 | 409,083 / 429,923 | 3,476 / 3,469 |
| 8 | W21_B05 | 0.016774 | 0.015700 | 0.015700 | 0.016237 | 396,268 / 421,445 | 3,353 / 3,336 |
| 9 | W09_B05 | 0.016518 | 0.014099 | 0.014099 | 0.015309 | 360,936 / 418,490 | 3,010 / 2,975 |

(`results/metrics/exp027_local_threshold_grid.csv` with the threshold-map and neighbour-count statistics, `exp027_local_threshold_config_comparison.csv`, `exp027_vs_exp026_comparison.csv`, `results/figures/exp027_local_threshold_grid_scores.png`.)

**Decision A: the best local configuration is W21_B15** (window 21, a = 1, b = 1.5), with no tie.
**Decision B: REJECT EXP-027.** Its DevelopmentScore of 0.036103 is below the 0.041545 of EXP-026 (difference −0.0054419). **EXP-026 remains the current selected thresholding method.** `config.m` is unchanged, and the local parameters are not recorded as current.

**Behaviour** (figures `exp027_best_local_{pn0,pn3}.png` at k = 46/91/136; post-scoring diagnostic `exp027_t2_gt_diagnostic_k102.png`):

- **Candidate volume decreased relative to EXP-026:** −18.8 % in `pn0` (119,133 vs 146,729) and −14.9 % in `pn3` (114,771 vs 134,794). The candidates are still 33.9 / 32.7 times the GT volume.
- **Substantial GT loss:** 2,211 vs 3,035 (`pn0`) and 2,138 vs 2,952 (`pn3`) lesion voxels captured, i.e. 63.0 % / 60.9 % of the GT against 86.4 % / 84.1 %.
- **Bright CSF reduced:** the lateral and fourth ventricles are largely not selected, because the threshold map is highest there.
- **Edge-like and thin structures increased:** sulcal and fissural CSF, the cortical ribbon and the borders of bright regions become candidates. 27,627 (`pn0`) and 32,777 (`pn3`) of the best-local candidates are not in EXP-026.
- **Noise:** `pn3` adds scattered isolated voxels and speckle, including inside ventricle borders. The scores of the best configuration are nevertheless similar (0.0361 / 0.0362).
- **Main failure mode:** the lesions are mostly **periventricular**. The bright ventricle inside the window raises m and s, so lesion voxels next to it fall below T; at k = 102 the parts of the large lesions adjacent to the ventricle are missed, while isolated round lesions are kept. The method answers "bright relative to the neighbourhood", which suppresses uniformly bright regions but also the lesions that touch them.
- **Grid trend:** b dominates (b = 1.5 is best for every window), and windows 21/41 beat 9. The best value lies on the edge of the grid (b = 1.5). This is noted as a limitation but was **not** extended: the grid was pre-registered.
- **Scope of the conclusion:** EXP-027 shows that **no configuration of the pre-registered family and range** (a = 1, window {9, 21, 41}, b {0.5, 1.0, 1.5}) beats EXP-026. It does not show that local thresholding cannot work in general. The score still rising at b = 1.5 suggests that larger b might behave differently, but that remains untested; extending the grid after seeing the results would be post-hoc tuning.
- **Not done:** no parameter outside the grid, no separate `pn0`/`pn3` parameters, no hybrid local/global rule, no filtering, morphology, component analysis or harmonization, no held-out data.

These are **development** results. **Phase 59 COMPLETE.** Next roadmap step: Phase 60 (generate the selected lesion candidate mask), not started.

### 13.39 Phase 60: canonical lesion candidate mask (from EXP-026)

- **Status of the thresholding block:** the method exploration of Phases 54–59 is complete for now. EXP-026 (`multithresh` N = 2, Class 3) is the selected method; EXP-027 (local thresholding) was rejected. Phase 60 is an **integration step, not an experiment**: no new experiment ID, no GT, no new metric.
- **Method (unchanged EXP-026 rule):** for each volume, `levels = multithresh(T2norm(brainMask), 2)`, `classVolume = imquantize(T2norm, levels)`, `candidateMask = brainMask & (classVolume == 3)`, which is equivalent to `T2norm > levels(2)` (checked). The thresholds are re-estimated from the data; no numerical threshold is stored anywhere.
- **Code:**
  - `src/segmentation/generateLesionCandidateMask.m` is the reusable generator. It reads the method parameters from `cfg.segmentation` (`thresholdMethod = "multithresh"`, `numberOfThresholds = 2`, `candidateClass = 3`) and refuses any class other than the highest one. It loads no files and uses no GT, metrics, morphology or components.
  - `experiments/candidate_mask_function_check.m` is the synthetic software check.
  - `experiments/phase60_generate_candidate_mask.m` is the orchestration script, run on 2026-10-10 with 55/55 checks PASS. It does not call the GT loader.
- **Canonical outputs:** `data/processed/phase60_t2_{pn0,pn3}_candidate_mask.mat`, with the variable `candidateMask` and metadata (source EXP-026, thresholds, `gtUsedForGeneration = false`, `finalSegmentation = false`). The EXP-026 files are left untouched.

| | `pn0` | `pn3` |
|---|---:|---:|
| Lower threshold (normalized / raw-eq.) | 0.535922 / 2194.60 | 0.486930 / 1993.98 |
| Upper threshold (normalized / raw-eq.) | 0.722019 / 2956.67 | 0.658439 / 2696.31 |
| Brain-mask voxels | 1,688,787 | 1,668,366 |
| Candidate voxels (fraction of brain mask) | 146,729 (0.0869) | 134,794 (0.0808) |
| First / last non-empty axial slice | 11 / 154 | 2 / 155 |
| Identical to frozen EXP-026 mask and thresholds | yes | yes |

(`results/metrics/phase60_candidate_mask_summary.csv`; no new figures, because the EXP-026 overlays `exp026_t2_{pn0,pn3}_multiclass.png` show the same masks.)

- **Not the final segmentation:** `candidateMask` is an intermediate lesion-candidate volume. The known over-segmentation (bright CSF-compatible structures, about 40 times the GT volume per EXP-026) is **intentionally left untouched** here.

**Phase 60 COMPLETE.** Next roadmap step: Phase 61 (candidate-mask error analysis), not started.

### 13.40 Phase 61: candidate-mask error analysis (EXP-028, diagnostic)

- **Source:** the canonical Phase-60 masks `data/processed/phase60_t2_{pn0,pn3}_candidate_mask.mat` (`candidateMask`, = EXP-026). They were loaded, not regenerated, and verified unchanged at the end.
- **GT role:** label 10, loaded after the masks and used **only for diagnosis**. TP/FP/FN masks exist only in memory and nothing is saved under `data/processed/`. No ROI, slice range, coordinate or location prior is derived from the error locations.
- **Topology tool:** the number of candidate pixels in the 2D 8-neighbourhood, per axial slice (`conv2`, 3×3 kernel with a zero centre, zero padding). It matches an independent 8-shift implementation (no wrap-around between slices, no artificial border neighbours). This is **not** component analysis (that comes in Phase 67): no labels, no objects, no areas.
- **Code:** `experiments/exp028_candidate_mask_error_analysis.m`, 51/51 checks PASS. No morphology, components, thresholding or `save`.

| | `pn0` | `pn3` |
|---|---:|---:|
| Candidates / GT | 146,729 / 3,512 | 134,794 / 3,512 |
| TP / FP / FN | 3,035 / 143,694 / 477 | 2,952 / 131,842 / 560 |
| Isolated candidates (TP / FP) | 7,465 (22 / 7,443) | 8,996 (35 / 8,961) |
| FP with 0 / ≤ 2 / 8 candidate neighbours | 5.2 % / 25.2 % / 24.7 % | 6.8 % / 25.0 % / 26.0 % |
| TP with 0 / ≤ 2 / ≥ 5 candidate neighbours | 0.7 % / 7.5 % / 64.9 % | 1.2 % / 8.6 % / 65.7 % |
| FN by candidate neighbours 0…8 | 95 / 84 / 110 / 116 / 65 / 6 / 0 / 1 / 0 | 73 / 91 / 106 / 138 / 119 / 26 / 7 / 0 / 0 |
| FN with all 8 neighbours (single-pixel hole-like) | 0 | 0 |

(Full distributions: `results/metrics/exp028_neighbor_distribution.csv`; per-slice counts: `exp028_error_counts_by_slice.csv`; summary: `exp028_candidate_error_summary.csv`. Figures: `exp028_candidate_errors_{pn0,pn3}.png`, `exp028_error_contact_sheet_{pn0,pn3}.png`, `exp028_fp_fn_by_slice.png`, `exp028_neighbor_topology.png`.)

**Error taxonomy:**

- **A. Isolated / speckle-like candidates: present, minor.** Isolated voxels are 5.2 % (`pn0`) and 6.8 % (`pn3`) of the FP, and about 99.7 % of all isolated candidates are FP. However, 22 / 35 TP voxels are isolated too, so small real lesions exist at this scale.
- **B. Thin / edge-like FP: substantial.** About 40 % of the FP have 1–4 candidate neighbours (`pn0` 40.0 %, `pn3` 37.7 %). Visually these are cortical/sulcal rim-like patterns, the interhemispheric fissure, and a thin line along the brain-mask border, present in almost every slice of the contact sheets.
- **C. Large / dense FP: dominant.** About a quarter of the FP are fully surrounded by candidates (8 neighbours), and 55 % have ≥ 5. Visually these are broad compact regions compatible with ventricular CSF (the lateral ventricles in full), the fourth ventricle and cisterns, and sylvian/fissural fluid. The FP profile peaks around k ≈ 50–100 (diagnostic only).
- **D. Hole / gap-like FN: no enclosed holes; boundary loss.** There is **no** single-pixel enclosed FN, and only 7 (`pn0`) / 33 (`pn3`) FN have 5–7 neighbours. About 80 % of the FN have 1–4 candidate neighbours, i.e. they lie on lesion borders next to detected signal. 13–20 % have none: small, faint lesions missed entirely, e.g. the frontal dots around k = 51–61. The 8-neighbour count detects only single-pixel enclosed gaps; no larger enclosed gap is visible in the fixed slices or contact sheets.
- **E. Fragmentation: not clearly observed.** In the inspected slices each visible GT lesion appears as one contiguous TP patch with FN at its border. A definitive answer needs component analysis (Phase 67).
- **F. Fusion / bridging: observed.** The periventricular lesion signal is contiguous with the bright candidate region compatible with ventricular CSF: at k = 91 and k = 102 the TP voxels (yellow) touch the ventricle-compatible FP region (red) directly. Thin rim-like candidates also link neighbouring sulcal structures.
- **G. Systematic non-morphological confound: yes, and it is the main problem.** The dominant FP are bright, fluid-like structures in the same intensity class as the lesions. They are as large as, or larger than, the lesions and are often attached to them. Shape operators cannot separate them selectively.
- **`pn0` vs `pn3`:** the topology is very similar. `pn3` has more isolated FP (8,961 vs 7,443), more FN (560 vs 477, more of them with 4–6 neighbours, i.e. ragged lesion borders under noise), and noisier FP edges. At k = 46 the fourth-ventricle-compatible region is selected fully in `pn0` but only along its rim in `pn3`.

**Morphology families worth testing later** (none selected; no operation, structuring-element shape or size chosen; no morphology was run):

- **Erosion / opening:** justified by the isolated and thin FP (A, B; about a quarter of the FP have ≤ 2 neighbours). Risks: the FN already sit on lesion borders, and small lesions include isolated TP, so erosion will cost lesion voxels.
- **Dilation:** might recover border FN (D), since about 80 % of the FN touch detected signal, but at a large FP cost, because the dense FP regions would grow too.
- **Closing:** weak support. There are no enclosed single-pixel holes, and closing would mainly merge thin FP structures further (it worsens F).
- **Limit:** the dominant error (C + F + G, large fluid-like regions attached to periventricular lesions) is **unlikely to be solved by simple morphology alone**. Generic, automatic and experimentally validated rules (e.g. component-level analysis or other cues in later phases) would be needed. No rule is derived here.

**Phase 61 COMPLETE.** EXP-026 remains the candidate-generation method and `candidateMask` is unchanged. Next: Phase 62 (erosion / dilation experiments), not started.

### 13.41 Phase 62: erosion / dilation probe (EXP-029)

- **Motivation (EXP-028):**
  - **Erosion** tests whether removing one boundary layer suppresses the isolated and thin false positives (FP), and at what cost in lesion voxels.
  - **Dilation** tests whether adding one layer recovers the lesion-border misses (FN), and at what cost in new FP and fusion.
- **Setup (pre-registered in the log before running):**
  - input: the unchanged Phase-60 `candidateMask` (= EXP-026);
  - `strel('square', 3)`, applied once, 2D slice by slice (`src/segmentation/applySliceMorphology2D.m`), with the output intersected with EXP-021;
  - three variants (baseline, erosion, dilation); the four outputs were saved before the GT was loaded; no tolerance, no pipeline decision.
- **Why square 3×3:** it is the smallest centred square and equals the 2D 8-neighbourhood of Phase 61, so it measures the effect of about one pixel layer without a parameter sweep. It is a **fixed exploratory probe, not the Phase-65 structuring-element selection.**
- **Code:** `experiments/morphology_basic_function_check.m` (synthetic, 13/13 ok) and `experiments/exp029_erosion_dilation_probe.m` (59/59 checks PASS). An independent reference confirms the result: erosion keeps exactly the candidates with 8 candidate neighbours, and dilation equals `(candidate | ≥ 1 neighbour) & brainMask`. The eroded counts match the prediction made from EXP-028 before the run.

| Variant | Candidates `pn0` / `pn3` | TP `pn0` / `pn3` | Dice `pn0` | Dice `pn3` | **DevelopmentScore** | Δ vs baseline |
|---|---:|---:|---:|---:|---:|---:|
| baseline | 146,729 / 134,794 | 3,035 / 2,952 | 0.040402 | 0.042688 | **0.041545** | 0 |
| erosion | 36,193 / 34,918 | 698 / 671 | 0.035159 | 0.034921 | 0.035040 | −0.0065049 |
| dilation | 344,844 / 326,242 | 3,417 / 3,439 | 0.019618 | 0.020858 | 0.020238 | −0.0213069 |

| Change | `pn0` | `pn3` |
|---|---:|---:|
| Removed by erosion (TP / FP) | 110,536 (2,337 / 108,199) | 99,876 (2,281 / 97,595) |
| FP share of removed; TP lost; FP removed | 97.9 %; 77.0 %; 75.3 % | 97.7 %; 77.3 %; 74.0 % |
| Added by dilation (TP = recovered FN / FP) | 198,115 (382 / 197,733) | 191,448 (487 / 190,961) |
| FN recovered; FP share of added | 80.1 % of 477; 99.8 % | 87.0 % of 560; 99.7 % |

(`results/metrics/exp029_erosion_dilation_summary.csv`, `exp029_morphology_effect_comparison.csv`, `exp029_morphology_change_counts.csv`. Figures: `exp029_morphology_probe_{pn0,pn3}.png`, `exp029_morphology_errors_{pn0,pn3}.png`, `exp029_morphology_changes_{pn0,pn3}.png`; the title of the last one is clipped on the right, which is cosmetic only.)

**Effects (both primitives WORSEN the baseline DevelopmentScore):**

- **Erosion is not FP-selective.** 97.9 % of the removed voxels are FP, but only because FP dominate the mask: erosion removes 75 % of the FP **and 77 % of the lesion voxels**.
  - The lesions are themselves thin at this scale: only 23 % of the lesion voxels are interior to a 3×3 square.
  - Visually, the isolated voxels and the thin cortical/sulcal rims disappear completely (k = 136 is almost empty).
  - The regions compatible with the ventricles shrink but persist.
  - The lesions are reduced to their cores, and small lesions vanish (at k = 102 the lesion borders become FN).
- **Dilation recovers most border FN, at a prohibitive cost.** It recovers 80–87 % of the FN (382 / 487 voxels) but adds about 190,000–198,000 FP, i.e. roughly 400–520 new FP per recovered lesion voxel. The candidate volume more than doubles.
  - Visually, every structure gains a one-pixel ring, and the rims become broad bands.
  - The ventricle-compatible regions grow, and neighbouring structures and periventricular lesions merge further, so fusion increases.
- **Hypotheses:**
  - **H1 supported**, more strongly than expected (the loss of lesion signal is about as large as the FP removal).
  - **H2 supported.**
  - **H3 supported:** the dense fluid-like regions survive erosion and grow under dilation.
- **Conclusion:** neither primitive alone is useful as post-processing, and neither replaces the Phase-60 mask. **No morphology operation or structuring element is selected**; EXP-026 / Phase 60 remains the candidate baseline, and `config.m` is unchanged.
- **Implications for Phase 63 (opening = erosion followed by dilation):**
  - Opening can only restore structures that survive the erosion. With square 3×3 that is the 698 / 671 interior lesion voxels plus a ring, so lesions without a 3×3 interior would be lost.
  - On the other hand, it would remove the isolated and thin FP, which erosion showed to be the fully removable part.
  - It is not expected to touch the dense fluid-like regions.

These are development results; no opening, closing, component analysis, hole filling or held-out data was used. **Phase 62 COMPLETE.** Next: Phase 63 (opening), not started.

### 13.42 Phase 63: standard opening probe (EXP-030)

- **Why opening, although erosion alone worsened the score:** opening = erosion followed by dilation with the same structuring element. The dilation can rebuild structures whose core survives the erosion, while structures with no surviving core (isolated voxels, thin rims, small lesions) stay removed.
- **Setup (pre-registered in the log):**
  - `imopen` with `strel('square', 3)`, the same provisional probe as EXP-029 (not the Phase-65 selection), applied once, 2D slice by slice;
  - the result is intersected with EXP-021, which changed nothing (as expected);
  - the input is the unchanged Phase-60 `candidateMask`; both outputs were saved before the GT was loaded.
- **Stated before results:** `opened ⊆ baseline`, so opening **cannot recover any baseline FN**. Its only possible gain is removing FP while keeping TP.
- **Code:** `experiments/opening_basic_function_check.m` (synthetic, 14/14 ok) and `experiments/exp030_opening_probe.m` (70/70 checks PASS). The checks include:
  - `imopen` = erosion → dilation, and its erosion stage = the frozen EXP-029 erosion;
  - eroded ⊆ opened ⊆ baseline, together with the TP/FP/FN orderings;
  - baseline and erosion Dice reproduced exactly.

| Variant | Candidates `pn0` / `pn3` | TP `pn0` / `pn3` | FN `pn0` / `pn3` | Dice `pn0` | Dice `pn3` | **DevelopmentScore** | Δ vs baseline |
|---|---:|---:|---:|---:|---:|---:|---:|
| baseline | 146,729 / 134,794 | 3,035 / 2,952 | 477 / 560 | 0.040402 | 0.042688 | 0.041545 | 0 |
| erosion (EXP-029 reference) | 36,193 / 34,918 | 698 / 671 | 2,814 / 2,841 | 0.035159 | 0.034921 | 0.035040 | −0.0065049 |
| **opening** | 70,878 / 67,066 | 2,107 / 2,013 | 1,405 / 1,499 | 0.056647 | 0.057043 | **0.056845** | **+0.0153005** |

| Change | `pn0` | `pn3` |
|---|---:|---:|
| Removed by opening (TP / FP) | 75,851 (928 / 74,923) | 67,728 (939 / 66,789) |
| Baseline TP preserved; baseline FP removed | 69.4 %; 52.1 % | 68.2 %; 50.7 % |
| Restored after erosion (TP / FP) | 34,685 (1,409 / 33,276) | 32,148 (1,342 / 30,806) |
| Erosion-lost TP restored; erosion-lost FP restored | 60.3 %; 30.8 % | 58.8 %; 31.6 % |
| Isolated candidates before → after | 7,465 → 0 | 8,996 → 0 |

(`results/metrics/exp030_opening_summary.csv`, `exp030_opening_score_comparison.csv`, `exp030_opening_change_analysis.csv`. Figures: `exp030_opening_probe_{pn0,pn3}.png`, `exp030_opening_errors_{pn0,pn3}.png`, `exp030_opening_changes_{pn0,pn3}.png`.)

**Result: OPENING IMPROVES THE BASELINE WITH THE PROVISIONAL SQUARE-3 PROBE** (+0.0153, DevelopmentScore 0.056845, the best so far). It also beats erosion alone (+0.0218), in both conditions, and the gain is consistent between `pn0` and `pn3`.

- **Selective restoration:** the dilation stage restores about 60 % of the lesion voxels removed by the erosion but only about 31 % of the removed FP voxels. Lesion candidate regions whose core is large enough to survive the 3×3 erosion are partly rebuilt by the following dilation; small or thin lesion structures without such a core are removed permanently (hence the FN increase), and so are thin FP structures. Overall, opening removes about half of the FP at the cost of about 31 % of the TP.
- **Isolated / thin FP (H1 supported):** isolated candidates drop to 0 (after opening every candidate has at least 3 of its 8 neighbours). The thin cortical, sulcal and fissural rims disappear almost completely: k = 136 is nearly empty apart from a few small blocks.
- **Small / thin lesions (H2 supported):** only lesion regions with a core that survives the 3×3 erosion are (partly) rebuilt, while small lesions and thin lesion parts without such a core are lost (at k = 91 and 102 small lesions turn green). FN rise from 477 to 1,405 (`pn0`) and from 560 to 1,499 (`pn3`). This is the main cost and a clear small-lesion risk.
- **Where the gain comes from:** opening does not find more lesions (it is anti-extensive). The Dice rises because it removes FP mass (isolated voxels, thin structures, cortical/sulcal rims, narrow connections) faster than it loses TP. It does not resolve the ventricular confound.
- **Dense fluid-like FP (H3 supported):** the ventricle-compatible regions and the fourth-ventricle/cistern-compatible regions are reconstructed almost entirely; only thin peripheral parts are removed. 68,771 / 65,053 FP remain, about 20 times the GT volume.
- **Lesion–fluid contact:** the contact at k = 102 is unchanged.
- **H4:** opening beats erosion and, measurably, the baseline.
- **Not final:** this is evidence for Phases 65–66, and it is limited to square 3×3. **No morphology operation or structuring element is selected.** The Phase-60 `candidateMask` (EXP-026) remains the canonical baseline, and `config.m` is unchanged. A negative or positive result with another structuring element is not implied.

These are development results; no closing, reconstruction, component analysis, size rule or held-out data was used. **Phase 63 COMPLETE.** Next: Phase 64 (closing), not started.

### 13.43 Phase 64: closing after opening (EXP-031)

- **Why after the opening:** the morphology sequence of the roadmap (opening, then closing) and the Phase-63 result. EXP-030 is the best observed candidate, but it raised the FN from 477 / 560 to 1,405 / 1,499. Closing applied to the **EXP-030 opened mask** tests whether the gaps it opened or exposed can be refilled.
- **Setup (pre-registered in the log):**
  - `imclose` with `strel('square', 3)`, the same provisional probe as Phases 62–63, applied once, 2D slice by slice.
  - The EXP-021 brain mask is applied **only after the complete closing**. Clipping the intermediate dilation would change the operation near the mask border; a synthetic case in `closing_basic_function_check.m` shows this. So the Phase-62 helper, which clips every step, was **not** used.
  - Both outputs were saved before the GT was loaded.
- **Stated before results:** closing is extensive (opened ⊆ closed, verified: no opened voxel removed), so it cannot remove any EXP-030 FP and can only add voxels.
- **Code:** `experiments/closing_basic_function_check.m` (14/14 ok) and `experiments/exp031_closing_after_opening.m` (68/68 checks PASS).

| Variant | Candidates `pn0` / `pn3` | TP `pn0` / `pn3` | FN `pn0` / `pn3` | Dice `pn0` | Dice `pn3` | **DevelopmentScore** | Δ vs baseline | Δ vs opening |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| baseline | 146,729 / 134,794 | 3,035 / 2,952 | 477 / 560 | 0.040402 | 0.042688 | 0.041545 | 0 | – |
| opening (EXP-030) | 70,878 / 67,066 | 2,107 / 2,013 | 1,405 / 1,499 | 0.056647 | 0.057043 | **0.056845** | +0.015300 | 0 |
| opening + closing | 72,070 / 68,258 | 2,120 / 2,019 | 1,392 / 1,493 | 0.056098 | 0.056263 | 0.056181 | +0.014636 | **−0.000665** |

| Change vs opening | `pn0` | `pn3` |
|---|---:|---:|
| Added by closing (TP / FP) | 1,192 (13 / 1,179) | 1,192 (6 / 1,186) |
| TP share of added; opening FN recovered | 1.1 %; 0.9 % | 0.5 %; 0.4 % |
| Dilation stage added (TP / FP) | 43,360 (428 / 42,932) | 39,829 (488 / 39,341) |
| Kept by the erosion stage: TP; FP | 3.0 %; 2.7 % | 1.2 %; 3.0 % |

The equal totals of 1,192 added voxels in `pn0` and `pn3` are a coincidence; the TP/FP split differs.

| Opening-FN by opening-candidate neighbours | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `pn0` FN (recovered) | 977 (0) | 41 (0) | 137 (2) | 217 (3) | 26 (3) | 6 (4) | 0 | 1 (1) | 0 |
| `pn3` FN (recovered) | 1,011 (0) | 46 (0) | 160 (1) | 235 (1) | 35 (1) | 12 (3) | 0 | 0 | 0 |

(`results/metrics/exp031_closing_summary.csv`, `exp031_closing_score_comparison.csv`, `exp031_closing_change_analysis.csv`, `exp031_fn_gap_recovery.csv`. Figures: `exp031_closing_probe_{pn0,pn3}.png`, `exp031_closing_errors_{pn0,pn3}.png`, `exp031_closing_added_{pn0,pn3}.png`.)

**Result: EXP-030 OPENING REMAINS THE BEST OBSERVED MORPHOLOGY CANDIDATE SO FAR.** Closing lowers the score in both conditions (Δ −0.000665 vs opening). It stays above the Phase-60 baseline (+0.014636), but only because of the opening.

- **Local gaps / lesion borders (H1, only weakly supported):** closing recovers only 13 / 6 of the 1,405 / 1,499 opening FN. Recovery is somewhat more likely in the bins with 4–7 opening neighbours, but most border FN remain.
- **Completely missing small lesions (H2 supported):** about 70 % of the opening FN (977 / 1,011) have **no** opening candidate in their 8-neighbourhood, and none of them is recovered. Closing cannot recreate lesions that the opening removed entirely.
- **FP cost (H3):** 99 % of the added voxels are FP, so the score drops. The erosion stage removes about 97 % of the dilation-stage additions, TP and FP alike: closing is not selective.
- **Fusion / bridging (H4, supported visually):** the few added voxels lie mostly in narrow gaps between and inside the ventricle-compatible regions. At k = 91 the thin separation between the two ventricle-like regions is partly filled, which adds bridging; a few voxels are added at lesion borders (k = 102).
- **Dense fluid-like FP (H5 supported):** these regions are unchanged apart from these small fills.
- **H6:** opening + closing does not beat opening alone.
- **Why so little effect:** the opening has already smoothed the candidate regions, so few gaps narrower than the 3×3 element remain. Closing has little to fill, and what it fills is mostly between FP regions.
- **Scope of the conclusion:** EXP-031 shows that standard 2D closing with square 3×3, applied after the square-3×3 opening, adds no value on the development set. It does not show that closing is useless in general.
- **Not final:** these results are limited to square 3×3. **No morphology operation or structuring element is selected.** EXP-026 / Phase 60 remains the canonical candidate baseline, and `config.m` is unchanged.

These are development results; no reconstruction, hole filling, component analysis, size rule or held-out data was used. **Phase 64 COMPLETE.** Next: Phase 65 (structuring-element selection), not started.

### 13.44 Phase 65: structuring-element selection for standard opening (EXP-032)

- **Why opening:** it is the only morphology family that improved the candidate mask. Erosion (EXP-029), dilation (EXP-029) and closing after opening (EXP-031) all scored lower. Phase 65 changes only its structuring element (SE).
- **Pre-registered grid** (log, before running), with every candidate opened independently from the Phase-60 `candidateMask` (2D slice-wise, one `imopen`, AND EXP-021):

| Candidate | MATLAB | Support | Elements | Motivation |
|---|---|---|---:|---|
| square3 | `strel('square', 3)` | 3×3 | 9 | EXP-030 reference |
| diamond1 | `strel('diamond', 1)` | 3×3 | 5 | sparser at the same extent: may keep more thin/small lesions |
| square5 | `strel('square', 5)` | 5×5 | 25 | larger, more aggressive: more FP removed, more lesion loss |
| diamond2 | `strel('diamond', 2)` | 5×5 | 13 | same 5×5 extent, sparser: separates density from scale |

  - No line, disk or custom SE was used, and the grid was not extended after the results.
  - All 8 predictions were saved before the GT was loaded, and one SE is shared by `pn0` and `pn3`.
  - Selection follows Phase 37: highest DevelopmentScore, no tolerance.
- **Code:** `experiments/structuring_element_grid_check.m` (34/34 ok) and `experiments/exp032_structuring_element_selection.m` (81/81 checks PASS).
  - square3 reproduces EXP-030 exactly (masks and Dice).
  - The selected masks are exact copies of the frozen winner.
  - `config.m` is unchanged (checked).

| Rank | SE | Dice `pn0` | Dice `pn3` | Weaker | **DevelopmentScore** | Δ vs no morphology | Δ vs square3 |
|---:|---|---:|---:|---:|---:|---:|---:|
| 1 | **square3** | 0.056647 | 0.057043 | 0.056647 | **0.056845** | +0.015300 | 0 |
| 2 | diamond1 | 0.053521 | 0.054352 | 0.053521 | 0.053937 | +0.012392 | −0.002908 |
| 3 | diamond2 | 0.051060 | 0.052555 | 0.051060 | 0.051808 | +0.010263 | −0.005038 |
| 4 | square5 | 0.038859 | 0.036449 | 0.036449 | 0.037654 | −0.003891 | −0.019191 |

The no-morphology reference (Phase 60) scores 0.041545.

| SE | Voxels `pn0` / `pn3` | TP preserved `pn0` / `pn3` | FP removed `pn0` / `pn3` | FN `pn0` / `pn3` |
|---|---:|---:|---:|---:|
| diamond1 | 86,097 / 80,716 | 79.0 % / 77.5 % | 41.8 % / 40.5 % | 1,114 / 1,223 |
| square3 | 70,878 / 67,066 | 69.4 % / 68.2 % | 52.1 % / 50.7 % | 1,405 / 1,499 |
| diamond2 | 55,203 / 53,571 | 49.4 % / 50.8 % | 62.6 % / 60.5 % | 2,013 / 2,012 |
| square5 | 42,501 / 41,427 | 29.5 % / 27.7 % | 71.0 % / 69.2 % | 2,618 / 2,693 |

(`results/metrics/exp032_structuring_element_scores.csv`, `exp032_structuring_element_condition_metrics.csv`, `exp032_structuring_element_tradeoff.csv`, `exp032_selected_structuring_element.csv`. Figures: `exp032_se_candidates_{pn0,pn3}.png`, `exp032_se_errors_{pn0,pn3}.png`. There is no selected-vs-square3 figure, because square3 won.) No SE leaves any isolated voxel.

**Decision: the SELECTED DEVELOPMENT SE for standard opening is square3** (`strel('square', 3)`, 3×3 support, 9 elements), with DevelopmentScore 0.056845, shared by `pn0` and `pn3`.

- **square3 remains** the provisional element used since Phase 62. It won on the numbers only, with no preference, and is better than every other SE in **both** conditions.
- **Canonical selected masks:** `data/processed/phase65_t2_{pn0,pn3}_selected_opening_candidate.mat`.
- **Status:** a development selection, **not a frozen project parameter**. `config.m` is unchanged, and the candidate generation is still EXP-026.

**Interpretation:**

- **Aggressiveness ordering:** by the share of TP preserved, the four SEs order as diamond1 (79 %) > square3 (69 %) > diamond2 (50 %) > square5 (28 %). The FP removal follows the opposite order (41 % < 52 % < 62 % < 71 %).
  - The score peaks at **square3**, an interior point of this range.
  - diamond1 keeps more lesion voxels but also many more FP.
  - The 5×5 elements remove more FP but lose too many lesions.
- **Shape at 3×3 (square3 vs diamond1):** the denser square scores higher. diamond1 survives on thin structures with a cross-shaped core and leaves small "+"-shaped fragments of thin FP (fixed slices).
- **Shape at 5×5 (square5 vs diamond2):** here the sparser diamond scores much higher. square5 erases most lesions (k = 102 mostly FN) and produces blocky regions.
- **Scale (square3 → square5, diamond1 → diamond2):** a larger scale lowers the score in both families. square5 even falls below the no-morphology reference.
- **Isolated / thin FP:** every SE removes all isolated voxels and most thin rims; diamond1 keeps the most thin fragments.
- **Small / thin lesions:** lesion loss grows steadily with aggressiveness, from 21–22 % (diamond1) to 71–72 % (square5) of the baseline TP.
- **Dense fluid-like FP (H4 supported):** the regions compatible with the ventricles and cisterns persist with every SE. No SE solves this problem.
- **Hypotheses:** H1–H3 are supported. H5: square3 received no preference.
- **Limitations:**
  - The grid is small and deliberately not exhaustive (no disks, no other sizes or shapes).
  - square3 is not on an aggressiveness boundary of the grid, but the result does **not** claim a global optimum.
  - The diamond1 → square3 → diamond2 steps are coarse.

These are development results; no closing, reconstruction, component analysis or held-out data was used. **Phase 65 COMPLETE.** Next: Phase 66 (before/after morphology comparison), not started.

### 13.45 Phase 66: before / after morphology comparison (EXP-033)

- **BEFORE:** the Phase-60 canonical `candidateMask` (EXP-026), `data/processed/phase60_t2_{pn0,pn3}_candidate_mask.mat`.
- **AFTER:** the Phase-65 selected masks, `data/processed/phase65_t2_{pn0,pn3}_selected_opening_candidate.mat`, made with standard opening, `strel('square', 3)` (3×3, 9 elements), one application, 2D slice by slice. They are verified identical to the EXP-032 winner and to EXP-030.
- **Method:** a pure comparison of two frozen artifacts. Nothing is regenerated or saved, and no morphology, component or threshold function is called (checked). GT label 10 is used for evaluation only.
- **Pre-registered rule** (no tolerance): the block is retained for subsequent development if the DevelopmentScore after morphology is higher than before.
- **Code:** `experiments/exp033_before_after_morphology_comparison.m` (48/48 checks PASS).
- **Status of this comparison:** it is a **development-set before/after comparison**, not an independent validation, because `pn0` and `pn3` were also used to select the structuring element in Phase 65.

| | `pn0` before | `pn0` after | `pn3` before | `pn3` after |
|---|---:|---:|---:|---:|
| Candidate voxels | 146,729 | 70,878 | 134,794 | 67,066 |
| TP / FP / FN | 3,035 / 143,694 / 477 | 2,107 / 68,771 / 1,405 | 2,952 / 131,842 / 560 | 2,013 / 65,053 / 1,499 |
| Dice | 0.040402 | **0.056647** | 0.042688 | **0.057043** |

| | before | after | Δ |
|---|---:|---:|---:|
| Weaker-condition Dice | 0.040402 | 0.056647 | |
| **DevelopmentScore** | 0.041545 | **0.056845** | **+0.0153005** |
| Δ Dice `pn0` / `pn3` | | | +0.016246 / +0.014355 |

| Change | `pn0` | `pn3` |
|---|---:|---:|
| Removed voxels (TP / FP) | 75,851 (928 / 74,923) | 67,728 (939 / 66,789) |
| Candidates removed | 51.7 % | 50.2 % |
| TP preserved / lost | 69.4 % / 30.6 % | 68.2 % / 31.8 % |
| FP removed | 52.1 % | 50.7 % |
| Removed voxels that are FP | 98.8 % | 98.6 % |
| FP removed per TP lost | 80.7 | 71.1 |
| FN increase | +928 | +939 |

(`results/metrics/exp033_before_after_metrics.csv`, `exp033_before_after_development_summary.csv`, `exp033_morphology_change_summary.csv`, `exp033_before_after_by_slice.csv`. Figures: `exp033_before_after_masks_{pn0,pn3}.png`, `exp033_before_after_errors_{pn0,pn3}.png`, `exp033_removed_by_morphology_{pn0,pn3}.png`, `exp033_before_after_slice_profile_{pn0,pn3}.png`.)

**A. Does morphology help the development metric? Yes.** **THE SELECTED MORPHOLOGY BLOCK IMPROVES THE DEVELOPMENT-SET RESULT AND IS RETAINED FOR SUBSEQUENT DEVELOPMENT PHASES.**

- The improvement occurs in both conditions.
- It removes about half of the FP, and almost every removed voxel is FP (about 71–81 FP per TP lost).

**B. What morphology does not solve:**

- **Dense fluid-like FP:** the regions compatible with the ventricles and cisterns remain (68,771 / 65,053 FP, about 20 times the GT volume). The slice profiles show that the FP reduction is proportionally largest in the inferior and superior slices, where thin rims dominate, while the central slices (about k = 70–100) keep high FP.
- **Small / thin lesions:** FN rise by +928 (`pn0`) and +939 (`pn3`) across the lesion-bearing slices, most around k ≈ 95–105. Small lesions and lesion borders are removed; this is the main cost.
- **Lesion-to-fluid contacts:** these remain visible (k = 102).

**Visual summary:**

- Isolated voxels and thin cortical/sulcal/fissural rims are largely removed.
- Small and thin lesion signal is lost.
- The fluid-like regions remain.
- The effect is similar in `pn0` and `pn3`.

**Retention status:** the standard 2D opening with `strel('square', 3)`, applied once to the T2 Phase-60 candidate mask, is **retained for subsequent development**. The overall project pipeline is **not** frozen, `config.m` is unchanged, and EXP-026 / Phase 60 remains the canonical candidate generation.

These are development results; no held-out data was used. **Phase 66 COMPLETE.** Next: Phase 67 (2D connected-component analysis), not started.

### 13.46 Phase 67: 2D connected components (EXP-034)

- **Source masks:** `data/processed/phase65_t2_{pn0,pn3}_selected_opening_candidate.mat`, i.e. the EXP-026 candidates followed by standard 2D opening with square 3×3 (retained in Phase 66). Their provenance is verified from the metadata, and they are unchanged.
- **Definition:** `bwconncomp(candidateMask(:,:,k), 8)` on every axial slice independently (`src/segmentation/extractConnectedComponents2D.m`). The call always receives a single 181×217 slice, never the volume.
- **Why 8-connectivity:** it is a project choice fixed without GT. The analysis is strictly 2D; it matches the 2D 8-neighbourhood used since Phase 61; and diagonally touching pixels are treated as one in-plane region rather than split. 4- and 8-connectivity were not compared.
- **Not done:** no GT, no Dice, no component properties (no `regionprops`, no sizes; those are Phase 68), no filtering (Phase 69), no 3D connectivity (Phase 72).
- **Code:** `experiments/connected_components_2d_check.m` (synthetic, 14/14 ok) and `experiments/exp034_connected_components_2d.m` (27/27 checks PASS).
  - Every slice is reconstructed exactly from `PixelIdxList`, and the components are disjoint and cover all candidate pixels.
  - The first two runs stopped at the script's own forbidden-pattern self-check (its search strings contained the searched text). This was fixed by splitting the strings; nothing else changed.
- **Outputs:** `data/processed/phase67_t2_{pn0,pn3}_components2d.mat` (`ccBySlice`, `numComponentsPerSlice`, `metadata`), plus `results/metrics/exp034_components_by_slice.csv` (362 rows) and `exp034_component_summary.csv`.

| | `pn0` | `pn3` |
|---|---:|---:|
| Slices analysed | 181 | 181 |
| Slices with / without components | 121 / 60 | 117 / 64 |
| First / last slice with components | 12 / 144 | 28 / 144 |
| **Total 2D component instances** | **1,210** | **1,068** |
| Components per slice: min / max | 0 / 20 | 0 / 21 |
| Mean / median per slice (over all 181 slices) | 6.69 / 5 | 5.90 / 5 |

- **Slice coverage:** `pn0` has a few components at k = 12–13 and 25–26, separated by empty slices (14–24 and 27); `pn3` is contiguous from 28 to 144. The range is descriptive only and is not a processing ROI.
- **Count profile** (`results/figures/exp034_component_count_by_slice.png`): the profile is similar in `pn0` and `pn3`, with most components around k ≈ 50–105 and up to about 20 per slice. `pn0` has slightly more components in most slices.
- **Fixed slices** (`exp034_components2d_{pn0,pn3}.png`; label colours are for display only and carry no identity across slices): at k = 91 the ventricle-compatible region appears as **several separate 2D components** whose parts are disconnected in-plane, next to small compact components. This is a neutral observation; the components are not classified.
- **Warning:** `total2DComponents` is the number of **slice-wise component instances**, **not** the number of unique MS lesions. A structure spanning several slices is counted once per slice, and one in-plane structure may be split into several components.

**Phase 67 COMPLETE.** Next: Phase 68 (component properties), not started.

### 13.47 Phase 68: 2D component properties (EXP-035)

- **Source objects:** the saved Phase-67 decomposition `data/processed/phase67_t2_{pn0,pn3}_components2d.mat` (`ccBySlice`, EXP-034, 8-connectivity, 2D slice-wise) on the Phase-65 selected opening masks. Components are **not** recomputed; the Phase-65 masks are used only for checks and figures.
- **Properties:** `regionprops(ccBySlice{k}, 'Area', 'Centroid', 'BoundingBox')` and nothing else (`src/segmentation/extractComponentProperties2D.m`). There is one row per 2D component instance, with `componentIndexInSlice` in `PixelIdxList` order. These indices are local to the slice and do not identify 3D lesions.
- **MATLAB conventions (stored without conversion):**
  - `Centroid = [x, y]`, where x is the **column** coordinate (1…217, second volume index) and y the **row** coordinate (1…181, first volume index).
  - `BoundingBox = [x, y, width, height]`, with its origin at the outer pixel edge (minimum column/row − 0.5).
  - The figures show the slice transposed, as in all earlier phases, so a pixel (row r, column c) is drawn at x = r, y = c, and the overlays account for this.
- **Code:** `experiments/component_properties_2d_check.m` (15/15 ok) and `experiments/exp035_component_properties.m` (44/44 checks PASS).
  - Every Area, Centroid and BoundingBox is validated independently against `PixelIdxList` (tolerance 1e-12).
  - The row counts reproduce the EXP-034 totals and per-slice counts.
  - The per-slice Area sums reproduce the Phase-67 candidate voxels, and the total Area equals `nnz` of the Phase-65 mask.
- **Not done:** no GT, no intensity statistics, no other `regionprops` property, no 3D properties, no classification, no filtering, no area bins.

| | `pn0` | `pn3` |
|---|---:|---:|
| Property rows (2D component instances) | 1,210 | 1,068 |
| Total Area (= candidate voxels) | 70,878 | 67,066 |
| Area min / max | 9 / 1,332 | 9 / 1,328 |
| Area mean / median / std | 58.58 / 18 / 122.05 | 62.80 / 18 / 128.70 |
| Instances with Area = 9 (share) ¹ | 345 (28.5 %) | 303 (28.4 %) |
| Centroid X (column) range | 33 – 191.91 | 28 – 191 |
| Centroid Y (row) range | 26 – 155 | 28.5 – 155 |
| BoundingBox width range | 3 – 74 | 3 – 73 |
| BoundingBox height range | 3 – 56 | 3 – 56 |

(`results/metrics/exp035_component_properties.csv` with one row per instance, `exp035_component_property_summary.csv`, `exp035_component_properties_by_slice.csv` with 362 rows and NaN area statistics for empty slices. Figures: `exp035_component_area_rank.png`, `exp035_component_properties_{pn0,pn3}.png`.)

¹ Not computed by the EXP-035 script. It was obtained afterwards by counting the rows with `areaPixels == 9` in `results/metrics/exp035_component_properties.csv`, and is reproducible from that file.

- **Area distribution (descriptive):** strongly right-skewed.
  - About 28 % of the instances have the minimum Area of 9 pixels (see the table note), and half have at most 18 pixels (median).
  - A few instances are very large, about 1,330 pixels. These are the large compact regions in the central slices; at k = 91 the ventricle-compatible region appears as several such large components.
  - The `pn0` and `pn3` distributions are very similar; `pn3` has fewer instances with a slightly higher mean.
- **Minimum size:** Area ≥ 9 and width/height ≥ 3 are a **consequence of the square-3×3 opening**: every surviving pixel lies in a 3×3 square contained in the component. This is not a filter. The observed size distribution is therefore already conditioned by the selected morphology: values such as 9 or 18 must not be read as natural thresholds for Phase 69.
- **Spatial extent:** the centroids span most of the brain support in both directions with nearly identical ranges in `pn0` and `pn3`, and the boxes range from 3×3 up to about 74×56 pixels. These values are descriptive only and carry no spatial rule.
- **Fixed slices:** small compact components are scattered through the parenchyma next to a few large compact regions. Labels are neutral; no component is classified.
- **Warning:** the properties describe **2D slice-wise candidate instances** and do not identify unique 3D lesions.

The Phase-68 property table provides the descriptive basis for the Phase-69 false-positive filtering analysis. **Phase 68 COMPLETE.**

### 13.48 Phase 69: conservative component-area filter (EXP-036)

- **Why only Area:**
  - Phase 68 measured Area, Centroid and BoundingBox. Of these, only Area has a generic, position-independent rationale.
  - Centroid and BoundingBox would introduce spatial rules, and absolute lesion positions must never drive a rule.
  - No intensity feature was computed, to avoid a second filtering dimension in the same experiment.
- **Why Area = 9, chosen without GT:**
  - Phase 68 found a minimum Area of exactly 9 in both conditions. Removing only this minimum class is the weakest non-trivial area rule.
  - The square-3×3 opening makes every component contain a full 3×3 square, so an Area-9 component is **exactly one 3×3 square**, i.e. a structure that survived the erosion as a single pixel. This was verified for every removed component.
  - No threshold sweep and no second rule were used.
- **Rule (pre-registered in the log):** remove Area == 9, keep Area > 9. Components are removed whole, using the Phase-67 `PixelIdxList` and the Phase-68 `areaPixels` (no recomputation), and the same rule applies to `pn0` and `pn3`.
  - Precondition `min(Area) == 9`: verified in both conditions.
  - Both filtered masks were saved before the GT was loaded.
- **Code:** `src/segmentation/filterComponentsByArea2D.m`, `experiments/component_area_filter_check.m` (16/16 ok) and `experiments/exp036_conservative_area_filter.m` (52/52 checks PASS).

| | `pn0` | `pn3` |
|---|---:|---:|
| 2D component instances before / removed / kept | 1,210 / 345 / 865 | 1,068 / 303 / 765 |
| Instances removed | 28.5 % | 28.4 % |
| Candidate voxels before / removed / after | 70,878 / 3,105 / 67,773 | 67,066 / 2,727 / 64,339 |
| Voxels removed | 4.4 % | 4.1 % |
| TP / FP / FN before | 2,107 / 68,771 / 1,405 | 2,013 / 65,053 / 1,499 |
| TP / FP / FN after | 2,071 / 65,702 / 1,441 | 1,971 / 62,368 / 1,541 |
| Removed TP / FP | 36 / 3,069 | 42 / 2,685 |
| Removed voxels that are FP | 98.8 % | 98.5 % |
| FP removed per TP lost | 85.3 | 63.9 |
| Dice before → after | 0.056647 → **0.058105** | 0.057043 → **0.058098** |

| | unfiltered | Area-9 filtered | Δ |
|---|---:|---:|---:|
| Weaker-condition Dice | 0.056647 | 0.058098 | |
| **DevelopmentScore** | 0.056845 | **0.058101** | **+0.0012560** |

(`results/metrics/exp036_area9_filter_metrics.csv`, `exp036_area9_filter_development_summary.csv`, `exp036_area9_filter_change_summary.csv`, `exp036_area9_filter_by_slice.csv`. Figures: `exp036_area9_filter_{pn0,pn3}.png`, `exp036_area9_removed_errors_{pn0,pn3}.png`, `exp036_area9_filter_by_slice.png`.)

**Decision: EXP-036 AREA-9 FILTER = PROVISIONALLY RETAINED FOR PHASE 70 ANALYSIS.**

- The DevelopmentScore improves (no tolerance), and Dice rises in both conditions.
- This is **not** a final or frozen parameter, and `config.m` is unchanged.

**Interpretation:**

- **Benefit:** removing about 28 % of the 2D component instances, but only about 4 % of the candidate voxels, removes almost only FP (98.5–98.8 %).
- **Cost:** the filter also removes real lesion signal: 36 (`pn0`) / 42 (`pn3`) GT lesion voxels contained in minimum-size (9-pixel) 2D candidate components, so FN rise by the same amounts.
  - What these components are relative to complete 3D lesions is **not yet determined**. They could be whole small lesions, 2D sections of lesions that continue on other slices, or peripheral fragments of larger lesions; no component-to-lesion matching has been defined.
  - This cost is the main input to Phase 70.
- **The gain is small** (+0.0013), much smaller than the opening's (+0.0153).
- **Fixed slices:** the removed instances are isolated 3×3 squares scattered in the parenchyma and along sulcal and cortical bright structures. The large fluid-like regions are untouched.
- **Role:** if the filter survives Phase 70, it only refines the candidate mask by removing small objects. The large dense fluid-like FP, the dominant confound, are unaffected.
- **Not done:** Area-9 instances were **not** assumed to be noise before GT evaluation. No component-level lesion matching was performed, and no other threshold, spatial, bounding-box or intensity rule was tested. Small-lesion protection is explicitly left to Phase 70.

These are development results; no held-out data was used. **Phase 69 COMPLETE.** Next: Phase 70 (small-lesion protection), not started.

### 13.49 Phase 70: small-lesion protection audit (EXP-037)

- **Compared:** the two frozen predictions. BEFORE is the Phase-65 opening masks; AFTER is the EXP-036 Area-9 filtered masks, verified to be a subset of BEFORE. No mask was generated or saved.
- **Why 2D GT cross-sections:** the GT is decomposed into 2D components per axial slice with 8-connectivity (the project convention), in evaluation code only (`src/evaluation/auditSmallLesionProtection2D.m`). A 2D GT component is a **lesion cross-section, not a unique 3D lesion**, and this audit is **not** the final lesion-level evaluation protocol.
- **Why no size cutoff:** there is no justified numerical lesion-size threshold, so GT Area is reported as a continuous descriptive variable only.
- **Pre-registered protection criterion:** no GT 2D component may go from non-zero predicted overlap before filtering to zero after ("newly completely lost"), in both `pn0` and `pn3`. Partial losses are only described.
- **Decision rule:**
  - **A:** DevelopmentScore not improved → reject.
  - **B:** improved but at least one complete loss → reject, and revert to the Phase-65 masks.
  - **C:** improved with no complete loss → retain.
- **Code:** `experiments/small_lesion_protection_2d_check.m` (16/16 ok) and `experiments/exp037_small_lesion_protection.m` (38/38 checks PASS). The script reproduces EXP-036 exactly (removed TP 36 / 42, Dice, DevelopmentScores).

| | `pn0` | `pn3` |
|---|---:|---:|
| GT 2D component instances (Area min / median / mean / max = 1 / 5 / 10.7 / 90) | 328 | 328 |
| With non-zero overlap before / after | 126 / 123 | 120 / 116 |
| Affected by the filter | 4 | 5 |
| Partially reduced, still represented | 1 (Area 43) | 1 (Area 43) |
| **Newly completely lost** | **3** | **4** |
| GT Area of the lost components | 13, 14, 22 | 13, 13, 17, 20 |
| TP before / after / removed | 2,107 / 2,071 / 36 | 2,013 / 1,971 / 42 |
| Fraction of before TP retained | 98.3 % | 97.9 % |

DevelopmentScore 0.056845 → 0.058101 (+0.001256, reproduced). Dice `pn0` 0.056647 → 0.058105; `pn3` 0.057043 → 0.058098.

(`results/metrics/exp037_small_lesion_component_audit.csv` with one row per GT 2D component, `exp037_small_lesion_protection_summary.csv`, `exp037_phase70_decision.csv`. Figures: `exp037_gt_area_vs_coverage_change_{pn0,pn3}.png`, `exp037_affected_gt_area_rank.png`, `exp037_fixed_slice_audit_{pn0,pn3}.png`.)

**Decision: REJECT_AREA9_FILTER** (case B). The development score improves, but small-lesion protection **fails in both conditions**.

- **EXP-036 is rejected**, and the retained development pipeline **reverts globally to the Phase-65 standard-opening masks, with no component filtering**.
- No alternative size threshold, no GT-derived rescue rule, no spatial exception and no hybrid mask was introduced. GT Area was not used to create or modify the filter. `config.m` is unchanged.

**Interpretation:**

- **What was lost:** each of the 3 (`pn0`) / 4 (`pn3`) lost cross-sections (13–22 pixels) was represented **only** by a single 3×3 candidate square (7–9 overlapping voxels). The lost cross-sections lie on slices 88, 105 and 113 (`pn0`) and 94, 104, 105 and 107 (`pn3`). None falls on the fixed display slices; they are documented in the audit table, and no slice was added post hoc.
- **Size pattern (descriptive):** the most severe damage falls on relatively small GT 2D components. The completely lost ones have Area 13–22 pixels in `pn0` and 13–20 pixels in `pn3`, while the components affected overall reach 43 pixels (the one partial reduction, slice 103). No formal "small lesion" threshold is implied.
- **Context:** only about 38 % of the GT 2D components (126 / 120 of 328, overall median Area 5) had any predicted support before filtering. Small cross-sections are already largely missed by the candidate generation and the opening, so protecting the few that remain matters.

These are development results; no held-out data was used. **Phase 70 COMPLETE.** Next: Phase 71 (complete predicted-volume reconstruction), not started.

### 13.50 Phase 71: complete predicted volume M_pred (EXP-038)

- **Retained source:** the Phase-65 selected opening masks `data/processed/phase65_t2_{pn0,pn3}_selected_opening_candidate.mat`, i.e. EXP-026 candidate generation followed by standard 2D opening with square 3×3 and **no component filtering**.
  - The Area-9 filter (EXP-036) was rejected in Phase 70 (EXP-037). The script verifies `REJECT_AREA9_FILTER` in `exp037_phase70_decision.csv` and never uses the EXP-036 masks, not even as a fallback.
- **Assembly:**
  - The source volume is split explicitly into 181 axial logical slice masks.
  - These are concatenated along the third dimension in their original order (`src/segmentation/assemblePredictedVolume.m`), giving `M_pred(x,y,z)`, a **logical 181×217×181** volume.
  - Nothing is interpolated, filled, shifted, cropped or reordered.
- **Code:** `experiments/predicted_volume_assembly_check.m` (12/12 ok) and `experiments/exp038_reconstruct_predicted_volume.m` (33/33 checks PASS).
- **Outputs:** `data/processed/phase71_t2_{pn0,pn3}_predicted_volume.mat` (`M_pred`, `metadata`), `results/metrics/exp038_predicted_volume_summary.csv` and `exp038_predicted_volume_by_slice.csv` (362 rows), plus the figures `exp038_predicted_volume_identity_{pn0,pn3}.png` (source, `M_pred` and the empty xor difference at k = 1, 46, 91, 136, 181).

| | `pn0` | `pn3` |
|---|---:|---:|
| `M_pred` size / class | 181×217×181 logical | 181×217×181 logical |
| Predicted voxels | 70,878 | 67,066 |
| Non-empty / empty slices | 121 / 60 | 117 / 64 |
| First / last non-empty slice | 12 / 144 | 28 / 144 |
| Exactly identical to the Phase-65 source (volume and every slice) | yes | yes |

- **Integrity:**
  - No voxel is added or removed, and the xor with the source is empty.
  - Empty and non-empty slices are preserved, and the slice range is descriptive only (not an ROI).
  - Voxel-level performance is therefore identical to Phase 65 and was not recomputed.
- **Not done:** no GT, no metrics, no segmentation change, no 2D or 3D connected components (3D components are Phase 72).
- **What Phase 71 is (and is not):** it did **not create** a new 3D segmentation. It formalized the already existing prediction as `M_pred`, rebuilding it explicitly from the slices and verifying voxel-by-voxel identity. The step from 2D slices to the 3D volume adds no information.
- **Status:** `M_pred` is the **canonical complete-volume representation** of the current development pipeline. The pipeline is not frozen.

**Phase 71 COMPLETE.** Next: Phase 72 (3D connected-component analysis), not started.

### 13.51 Phase 72: 3D connected components of M_pred (EXP-039)

- **Source:** the canonical Phase-71 `M_pred` (`data/processed/phase71_t2_{pn0,pn3}_predicted_volume.mat`), i.e. EXP-026 candidates followed by the Phase-65 standard 2D opening with square 3×3 and **no component filtering** (EXP-036 was rejected in Phase 70). `M_pred` is not modified.
- **Operation:** one `bwconncomp(M_pred, 26)` per complete volume (`src/segmentation/extractConnectedComponents3D.m`). This is only a new **representation** of the same foreground voxels.
- **Why 26-connectivity** (fixed before the analysis, without GT; no 6/18/26 comparison):
  - it is the full-neighbourhood volumetric analogue of the 2D 8-connectivity used since Phases 61 and 67;
  - the voxels are isotropic (1 mm);
  - candidates that continue diagonally between slices stay connected.
- **Course classification:** a **volumetric extension, specific to this project**, of the course-supported connected-component concept and `bwconncomp`. The verified course material demonstrates connected components in 2D, and 26-connectivity is **not** claimed to be taught there. This is recorded in a narrow note in ALLOWED_TECHNIQUES §10.
- **Descriptors:** taken only from `PixelIdxList` and `ind2sub`: voxel count, first and last slice, slice span, and number of occupied slices. No `regionprops3`, no 3D shape features.
- **Code:** `experiments/connected_components_3d_check.m` (18/18 ok, covering face, edge and corner contacts and diagonal steps between slices) and `experiments/exp039_connected_components_3d.m` (38/38 checks PASS after a rerun with an added check: `occupiedSliceCount == sliceSpan` for every component, since a connected component cannot skip a slice; identical results).
  - The union of `PixelIdxList` reconstructs `M_pred` **exactly**, and the components are disjoint.
  - The voxel counts sum to `nnz(M_pred)`.
- **Outputs:** `data/processed/phase72_t2_{pn0,pn3}_components3d.mat` (`CC3D`, `componentTable`, `metadata`) and `results/metrics/exp039_components3d.csv`, `exp039_components3d_summary.csv`, `exp039_components3d_by_slice.csv`.

| | `pn0` | `pn3` |
|---|---:|---:|
| Predicted voxels | 70,878 | 67,066 |
| Phase-67 2D component instances | 1,210 | 1,068 |
| **3D candidate components (26-connected)** | **335** | **291** |
| Single-slice / multi-slice components | 170 / 165 (50.7 % / 49.3 %) | 148 / 143 (50.9 % / 49.1 %) |
| Voxel count min / median / mean / max | 9 / 21 / 211.6 / 25,629 | 9 / 21 / 230.5 / 25,417 |
| Occupied slices min / median / mean / max | 1 / 1 / 2.73 / 70 | 1 / 1 / 2.71 / 40 |
| Largest slice span | 70 | 40 |

**Interpretation (descriptive):**

- **2D to 3D:** volumetric connectivity groups the slice-wise 2D instances into fewer 3D candidate components, about 3.6–3.7 2D instances per 3D component (`pn0` 3.61, `pn3` 3.67).
- **Single-slice components:** about half of the components occupy one slice only. This is described, not filtered; a real small lesion can appear in a single slice.
- **Very large components:** very large multi-slice 3D candidate components are present. The largest has 25,629 voxels in `pn0` and 25,417 in `pn3`, against a median of 21, and slice spans reach 70 (`pn0`) and 40 (`pn3`).
  - This is consistent with the persistence of the large bright, fluid-like structures seen in earlier phases.
  - Visually (projections `exp039_components3d_{pn0,pn3}.png`) they are extended central structures compatible with the ventricular system and midline/fissural fluid-like regions. This is a qualitative observation, not an algorithmic anatomical identification.
- **`pn0` vs `pn3`:** very similar distributions.
- **Warning:** the reported 3D components are predicted **candidate objects**. Their count must **not** be interpreted as the number of confirmed MS lesions.
- **Not done:** no GT, no matching, no filtering, no `regionprops3`, no morphology or thresholds; `config.m` is unchanged.

**Phase 72 COMPLETE.** Next: Phase 73 (region-growing decision), not started.

### 13.52 Phase 73: region-growing decision

- **Roadmap criterion:** region growing is introduced only if thresholding identifies **high-confidence lesion cores** but fails to recover their **complete extent**. Both conditions are required. False negatives alone are not sufficient: growth starts from seeds, and non-specific seeds would be expanded too.
- **Course compatibility:** region growing is course-supported, using seed points, a similarity predicate Q (e.g. intensity difference), connectivity to the seeds, and stopping when no neighbour satisfies Q. The decision below is therefore **not** due to course incompatibility.
- **Method:** this is a decision, not an experiment, and no experiment ID is used. `experiments/phase73_region_growing_decision.m` only reads saved results:
  - the retained-prediction metrics of EXP-033;
  - the 3D structure of EXP-039;
  - the Phase-70 outcome of EXP-037;
  - the `M_pred` metadata.

  It does no image processing, generates no seed or prediction, and loads no GT (9/9 checks PASS).
- **Indicators** (simple comparisons on existing values, no new metric or threshold):
  - the false-positive burden is FP > TP;
  - a "large ambiguous candidate" is a single 3D candidate object larger than the **total** GT lesion volume;
  - incomplete extent is FN > 0.

| | `pn0` | `pn3` |
|---|---:|---:|
| Retained candidate voxels | 70,878 | 67,066 |
| TP / FP / FN (GT 3,512) | 2,107 / 68,771 / 1,405 | 2,013 / 65,053 / 1,499 |
| 3D candidate components | 335 | 291 |
| Largest 3D candidate component (voxels) | 25,629 | 25,417 |
| Max occupied slices | 70 | 40 |

(`results/metrics/phase73_region_growing_evidence.csv`, `phase73_region_growing_decision.csv`.)

- **Incomplete lesion extent: present.** Some GT lesion voxels are missed (FN 1,405 / 1,499). Phases 61–63 showed border losses and small lesions removed by the opening, and Phase 70 showed that cleanup can remove the only support of small cross-sections.
- **High-confidence lesion cores: NOT present.**
  - The retained mask has about 32 FP per TP.
  - **Data:** the largest 3D candidate component contains 25,629 voxels in `pn0` and 25,417 in `pn3`, i.e. more than 7 times the total number of GT lesion voxels (7.30× and 7.24×). It extends over up to 70 and 40 slices respectively.
  - **Interpretation:** these data, together with the earlier qualitative analyses of the bright, fluid-like structures (Phases 61, 66 and 72, visually compatible with the ventricular system), confirm that the candidate mask is not a sufficiently specific set of high-confidence lesion cores. Size alone does not prove that a given component is a false positive.
- **Risk:** growing from these candidates would expand non-lesion structures, not selectively recover missing lesion borders.

**Decision: DO_NOT_INTRODUCE_REGION_GROWING** (core-reliability criterion FAIL; prerequisite not satisfied).

- **Phases 74–77** (seed selection, similarity predicate, region growing, region-growing evaluation): **SKIPPED BY THE PHASE-73 DECISION**. They are not executed and not marked complete.
- **Pipeline unchanged:** EXP-026 candidates → Phase-65 opening with square 3×3 → no component filtering → Phase-71 `M_pred`. `config.m` is unchanged, and no held-out data was used.
- **Scope:** region growing is **not justified for the current pipeline**. This says nothing against region growing for MS segmentation in general, and it remains an allowed technique.

**Phase 73 COMPLETE.** Next active roadmap phase: Phase 78 (individual-modality analysis).

### 13.53 Phase 78: individual-modality segmentation benchmark (EXP-040)

- **New data: PD pn3.** The required PD `pn3` volume was missing. With the user's approval it was downloaded on 2026-10-12 from the official BrainWeb server, using the same S2 form procedure as T2/T1 `pn3`, with the optional who_* fields left empty.
  - File: `data/raw/msles2/mri/pd_ai_msles2_1mm_pn3_rf0.raws`, 14,218,274 bytes.
  - SHA-256: `8c2ce715602c5e42b8c322be1c8b3fb055966fcff76fc484f5e84d2503bb2d61`.
  - Format check: read little-endian it gives 0…4095; read big-endian it reaches 65295. It differs from PD `pn0` (mean |pn3 − pn0| = 209.1 raw levels).
  - The download is recorded in `DOWNLOAD_INFO.txt`. Existing raw files were not modified.
  - `config.m` gained only the data path `cfg.dataset.noisyMriFiles.pn3.PD` (user approval). No pipeline parameter was added. Held-out data was not downloaded.
- **Design (pre-registered in EXPERIMENT_LOG, EXP-040):** T1, T2 and PD are each used alone, with the same architecture:
  - the EXP-021 brain mask, normalization /4095 and no preprocessing;
  - `multithresh(volume(brainMask), 2)` → `imquantize` → Class 1, Class 2 and Class 3, each alone;
  - one 2D axial opening with `strel('square',3)`, then AND brainMask.

  This gives 18 predictions, all saved before the GT was loaded. The Phase-41 GT statistics were not used; all three classes were generated symmetrically.
- **Integrity:** T2 Class 3 is exactly the Phase-71 `M_pred` in both conditions. Script `experiments/exp040_individual_modality_benchmark.m`, 90/90 checks PASS.

| Modality (selected class) | Dice `pn0` | Dice `pn3` | Weaker Dice | DevelopmentScore | Candidate voxels `pn0` / `pn3` | TP / FP / FN `pn0` | TP / FP / FN `pn3` | Rank |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| T2 (Class 3) | 0.056647 | 0.057043 | 0.056647 | 0.056845 | 70,878 / 67,066 | 2,107 / 68,771 / 1,405 | 2,013 / 65,053 / 1,499 | 1 |
| PD (Class 3) | 0.007287 | 0.025561 | 0.007287 | 0.016424 | 788,306 / 163,225 | 2,885 / 785,421 / 627 | 2,131 / 161,094 / 1,381 | 2 |
| T1 (Class 3) | 0.004705 | 0.003855 | 0.003855 | 0.004280 | 651,125 / 635,646 | 1,540 / 649,585 / 1,972 | 1,232 / 634,414 / 2,280 | 3 |

(`results/metrics/exp040_modality_summary.csv`; all 18 candidates in `exp040_single_modality_candidate_metrics.csv`, per-class scores in `exp040_single_modality_development_summary.csv`.)

- **Other classes:** within every modality, Class 3 is the best class, and Classes 1 and 2 perform very poorly.
  - The highest Dice among them is 0.002686, from T1 Class 2 in `pn0`. That candidate reaches 988 TP (585 in `pn3`) but produces 731,175 FP.
  - For T2 and PD, Classes 1–2 capture very little lesion signal after the opening: at most 175 TP (T2 Class 2) and at most 8 TP (PD Class 2). T2 Class 1 and PD Class 1 in `pn0` have no TP.
  - More TP therefore does not mean a better segmentation when the TP come with hundreds of thousands of FP.
- **Thresholds (raw-equivalent, t1 / t2):**
  - T1: 1394.40 / 2005.27 (`pn0`), 1294.58 / 1868.49 (`pn3`)
  - T2: 2194.60 / 2956.67 (`pn0`), 1993.98 / 2696.31 (`pn3`)
  - PD: 3291.89 / 3542.71 (`pn0`), 3020.06 / 3290.15 (`pn3`)
- **Data:**
  - PD Class 3 has the most TP of any candidate (2,885 in `pn0`), but with 785,421 FP.
  - Its size depends strongly on the condition: 788,306 versus 163,225 voxels, a ratio of 4.83 computed afterwards from the CSV. So does its Dice: 0.007287 versus 0.025561.
  - T1 produces no compact candidate: its Classes 2 and 3 have 635,646–732,163 voxels.
- **Visual observation (qualitative only, `exp040_selected_modalities_{pn0,pn3}.png`):**
  - T1 Class 3 covers most of the bright white-matter region.
  - PD Class 3 covers broad grey-matter-like regions plus the large bright / fluid-like central structures in `pn0`. In `pn3` it is a sparse scattering of small blocks plus those structures. These are visual observations, with no anatomical identification.
  - T2 Class 3 is the known Phase-71 candidate.
- **Interpretation (not tested):**
  - Under this architecture only T2 puts the lesions into a small, high-intensity top class. The results support this well.
  - PD Class 3 is strongly sensitive to the `pn0`/`pn3` condition in candidate size and Dice. No causal explanation is claimed.
  - PD Class 3 contains more GT lesion voxels than any other candidate, in both conditions, but on its own it is not specific. How much of this overlaps with T2 and how much is complementary is not yet known.
  - With this 3-class multithresh partition, T1 does not produce a class that is specific enough for the lesions.
- **Scope:** this compares single-modality candidates under one architecture. It does not say whether PD or T1 can add complementary information to T2 in a fusion (Phase 79).

**Decision: BEST INDIVIDUAL MODALITY (development) = T2, Class 3.**
- The retained pipeline (Phase-71 `M_pred`) is confirmed unchanged.
- `config.m` was updated before the run only to record the PD `pn3` file path; it did not change during the run. No segmentation, threshold, morphology or selection parameter was modified, and the lesion modality stays T2.
- No fusion was performed. Phase 79 has not started.
- Selected-class copies were saved as `data/processed/phase78_{t1,t2,pd}_{pn0,pn3}_selected_single_modality.mat`.

**Phase 78 COMPLETE.**

### 13.54 Phase 79: multimodal combination selection

- **Purpose:** Phase 79 chooses only the **input modalities** of the first controlled multimodal experiment. Phase 80 will define **how** they are fused, and Phase 81 will test **whether** fusion improves on T2 alone.
- **Method:** a decision, not an experiment; no experiment ID is used, and EXP-041 is kept for Phase 80.
  - Evidence: only the saved EXP-040 / Phase-78 CSVs.
  - The decision rule was pre-registered in EXPERIMENT_LOG before the run:
    - the primary modality is the one with individual rank 1;
    - the secondary is the one with rank 2, provided it also has more TP than the rank-3 modality in both `pn0` and `pn3`;
    - otherwise the user decides.
  - No new score, weight or metric was introduced.
  - Script: `experiments/phase79_select_modality_combination.m`, 24/24 checks PASS. It loads the T2 Class 3 and `M_pred` masks only for an identity check; no MRI, no GT, no thresholding, no morphology, no fusion.

| Modality | Rank | Class | DevelopmentScore | Dice `pn0` / `pn3` | TP `pn0` / `pn3` | FP `pn0` / `pn3` | FN `pn0` / `pn3` | Role |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| T2 | 1 | 3 | 0.056845 | 0.056647 / 0.057043 | 2,107 / 2,013 | 68,771 / 65,053 | 1,405 / 1,499 | primary |
| PD | 2 | 3 | 0.016424 | 0.007287 / 0.025561 | 2,885 / 2,131 | 785,421 / 161,094 | 627 / 1,381 | secondary |
| T1 | 3 | 3 | 0.004280 | 0.004705 / 0.003855 | 1,540 / 1,232 | 649,585 / 634,414 | 1,972 / 2,280 | not selected for the first pair |

(`results/metrics/phase79_modality_combination_decision.csv`, `phase79_selected_combination.csv`.)

- **T2 stays the primary (anchor) modality.** It has the highest DevelopmentScore by a large margin and is the current retained segmentation modality (Phase-71 `M_pred`, reproduced exactly).
- **PD as the secondary modality:**
  - It has the second-highest DevelopmentScore, about 3.8 times that of T1 (0.016424 / 0.004280, computed afterwards from the CSV).
  - Its Class 3 contains more TP than T1 Class 3 in both conditions.
  - PD intercepts more GT lesion voxels than T2 in both conditions (2,885 versus 2,107 in `pn0`; 2,131 versus 2,013 in `pn3`). How much of this signal is complementary to T2 is not yet known.
  - **Warning:** PD performs **poorly as a standalone segmentation modality**. It has very large FP burdens (785,421 / 161,094) and large `pn0`/`pn3` variation in candidate size and Dice, with no causal explanation claimed. It cannot replace T2.
  - **Limit of the evidence:** the TP counts do not show whether PD's TP are voxels that T2 misses. Checking that needs mask overlap, i.e. fusion, which is out of scope here. Complementarity is therefore a hypothesis to investigate, not a result.
- **T1:** it has the lowest DevelopmentScore, fewer TP than PD in both conditions and very broad candidates (about 635,000–651,000 voxels). It is **not selected for the first multimodal pair**, but it is **not discarded**: it remains available if the T2 + PD strategy fails or later evidence motivates revisiting it.

**Decision: SELECTED PAIR = T2 + PD** (T2 primary, PD secondary).
- PD is the most justified modality to investigate as a complementary source to T2. It was **not** selected because it segments lesions well.
- **No fusion rule has been defined**, no multimodal prediction has been generated, and no multimodal Dice has been computed.
- It has **not** been shown that T2 + PD is better than T2 alone; that is Phase 81.
- The canonical prediction remains the Phase-71 T2 `M_pred`, unchanged. `config.m` is unchanged in this phase, and no held-out data was used.

**Phase 79 COMPLETE.** Next: Phase 80, definition of one reproducible T2 + PD fusion rule.

### 13.55 Phase 80: T2 + PD fusion rule (EXP-041)

- **Pair (Phase 79):** T2 + PD, with T2 as the primary (anchor) and PD as the secondary modality. The script checked the Phase-79 CSV before fusing.
- **Fusion rule:** one rule, fixed and pre-registered before any multimodal evaluation, the same for `pn0` and `pn3`. It is a binary decision-level intersection: `M_multimodal = M_T2 AND M_PD`.
  - **Inputs:** the frozen Phase-78 masks (T2 Class 3, PD Class 3; EXP-021, /4095, multithresh N = 2, square3 opening). The T2 masks equal Phase-71 `M_pred` exactly.
  - **Nothing recomputed:** no MRI was reloaded and no thresholding or opening was rerun. No morphology, component filtering or region growing was applied after the fusion.
  - **No GT** was used.
- **Why T2 is the anchor:** it is by far the strongest single modality, and its main limitation is a very large candidate foreground.
- **Why PD only confirms:** PD Class 3 is much broader than T2, so it is unsuitable as an additive source. A voxel survives only if both modalities mark it.
- **Why OR was rejected a priori, without testing:** `T2 OR PD` would contain every PD voxel and could only add foreground to T2, which conflicts with the current problem.
- **Limitation:** the fused mask is a subset of T2. It can only keep or remove T2 candidates; **it cannot recover voxels missed by T2** (T2 false negatives). It can also remove T2 lesion voxels.
- **Declared risk (pre-registered):** PD Class 3 also contains the large bright / fluid-like structures (visually compatible with the ventricles), so the intersection may keep them.
- **Implementation:**
  - `src/segmentation/fuseCandidateMasksIntersection.m`;
  - synthetic check: 14/14;
  - `experiments/exp041_t2_pd_intersection_fusion.m`: 38/38 checks PASS.
- **Structural mask-overlap statistics** (not performance metrics; `results/metrics/exp041_t2_pd_fusion_summary.csv`):

| | `pn0` | `pn3` |
|---|---:|---:|
| T2 voxels | 70,878 | 67,066 |
| PD voxels | 788,306 | 163,225 |
| Fused T2 AND PD voxels | 70,849 | 61,740 |
| T2-only (not confirmed by PD) | 29 | 5,326 |
| PD-only | 717,457 | 101,485 |
| Fraction of T2 retained / removed | 0.999591 / 0.000409 | 0.920586 / 0.079414 |
| Fraction of PD overlapping T2 | 0.089875 | 0.378251 |
| Non-empty slices T2 / fused | 121 / 121 | 117 / 116 |

- **Effect by condition:** the same rule behaves very differently in the two conditions.
  - In `pn0` PD Class 3 covers practically every T2 candidate, so the fusion is almost the identity on T2: only 29 voxels are removed.
  - In `pn3` it removes 7.9 % of the T2 candidates.
  - The T2 voxels not confirmed by PD are **not** called false positives: whether they are lesion voxels is unknown without GT.
- **Visual observation (qualitative, `exp041_t2_pd_fusion_{pn0,pn3}.png`, agreement maps without GT):**
  - In `pn3` the unconfirmed T2 voxels are mostly thin rims along the borders of T2 candidates, plus some small isolated spots.
  - In both conditions the large candidate structures already described qualitatively as bright / fluid-like are largely shared by T2 and PD. They are therefore not removed by the intersection, as the declared risk anticipated. This is a visual observation; no anatomical identity is claimed without a specific check.
- **Expectation for Phase 81** (stated now, not a result): the `pn0` Dice can change only marginally, so any difference will come mainly from `pn3`.

**Decision:** the fused development prediction is **generated and frozen**, and the rule is not changed after inspection.
- **No performance claim** is made: the evaluation is deferred to Phase 81.
- **Canonical prediction:** Phase-71 `M_pred` remains canonical; the multimodal pipeline is not accepted yet.
- **Unchanged:** `config.m` is unchanged, and no held-out data was used.

**Phase 80 COMPLETE.** Next: Phase 81, comparison of T2 alone with T2 + PD.

### 13.56 Phase 81: mono-modal T2 vs T2 + PD comparison (EXP-042)

- **Methods compared:** both were frozen before any GT evaluation, and neither was regenerated or modified.
  - **Baseline:** the Phase-71 T2 `M_pred`.
  - **Candidate:** EXP-041 `T2 AND PD`.
  - **Checks before the GT was loaded:** EXP-041 provenance, the Phase-78 T2 alias equal to `M_pred`, the fused masks contained in T2, and the Phase-80 counts reproduced.
- **Evaluation:**
  - GT: label 10 on the complete 181×217×181 volume, not intersected with any mask.
  - Metric: full-volume Dice and DevelopmentScore = mean of `pn0` and `pn3`. TP/FP/FN and the removed-voxel classification are diagnostics only.
  - Script: `experiments/exp042_mono_vs_multimodal_comparison.m`, 38/38 checks PASS.
- **Pre-registered rule (EXPERIMENT_LOG):** the fusion is retained only if its DevelopmentScore is strictly higher than the baseline's. A lower score or an exact tie rejects it, and the simpler T2 is retained. No tolerance is used, and there is no requirement to win both conditions.

| Method | Condition | Predicted | TP | FP | FN | Dice |
|---|---|---:|---:|---:|---:|---:|
| T2 | `pn0` | 70,878 | 2,107 | 68,771 | 1,405 | 0.056647 |
| T2 | `pn3` | 67,066 | 2,013 | 65,053 | 1,499 | 0.057043 |
| T2 AND PD | `pn0` | 70,849 | 2,107 | 68,742 | 1,405 | 0.056669 |
| T2 AND PD | `pn3` | 61,740 | 1,836 | 59,904 | 1,676 | 0.056274 |

| | Dice `pn0` | Dice `pn3` | Weaker Dice | DevelopmentScore |
|---|---:|---:|---:|---:|
| T2 | 0.056647 | 0.057043 | 0.056647 | **0.056845** |
| T2 AND PD | 0.056669 | 0.056274 | 0.056274 | 0.056472 |
| Δ (fusion − T2) | +0.000022 | −0.000769 | | −0.000374 |

(GT 3,512 voxels; `results/metrics/exp042_*.csv`, `phase81_multimodal_decision.csv`.)

- **Voxels removed by the fusion** (`exp042_fusion_removed_voxels.csv`):
  - `pn0`: 29 voxels, all FP.
  - `pn3`: 5,326 voxels: 5,149 FP (96.68 %) and 177 TP (3.32 %).
  - The confusion-count identities hold exactly in both conditions: TP of the fusion = T2 TP − removed TP; FP of the fusion = T2 FP − removed FP; FN of the fusion = T2 FN + removed TP.
- **Why mostly-FP removal did not raise Dice in `pn3`:** the explanation below is an algebraic consequence of Dice = 2TP / (P + G), derived afterwards from the saved counts; it is not a new score.
  - Removing r voxels that contain t TP raises Dice only if t / r < TP / (P + G) of the current mask.
  - For T2 `pn3` that limit is 2,013 / 70,578 = 0.0285. The removed set has 177 / 5,326 = 0.0332, so it is slightly *richer* in lesion voxels than the T2 mask as a whole.
  - PD confirmation is therefore not lesion-selective enough. The large bright / fluid-like candidates, which carry most of the FP, are shared by T2 and PD and stay in the mask (Phase 80), so FP remain about 60,000–69,000 voxels.
- **Removed-voxel figures** (`exp042_removed_voxels_{pn0,pn3}.png`, fixed slices 46/91/102/136): generated after the evaluation and not used to change anything. In `pn3` the removed voxels lie mostly along candidate borders, including some lesion borders (orange) at k = 91/102. This is a qualitative observation.

**Decision: REJECT_MULTIMODAL_FUSION** (0.056472 < 0.056845, predefined rule).
- **Retained:** the simpler **T2-only pipeline** remains the retained development pipeline, and **the Phase-71 `M_pred` remains the canonical development prediction**.
- **Kept as negative evidence:** EXP-041 and EXP-042 artifacts are preserved. No alias was written.
- **No post-hoc changes:** no alternative fusion was tested and nothing was retuned after the GT. `config.m` is unchanged, and no held-out data was used.
- **Conclusion:** T2 AND PD does remove many false candidates, especially in `pn3`, but the filter is not selective enough. It also removes enough lesion signal to cancel the benefit of the FP reduction. Because the starting mask is extremely unbalanced (2,013 TP against 65,053 FP in `pn3`), losing even 177 TP weighs heavily on Dice.
- **Scope:** this rejects this one predefined rule (T2 AND PD with Class-3 masks). It does not show that PD carries no useful information in general.
- **Not a reason to try other rules:** this observation must not be used to try OR, weights or other combinations now, because that would violate the experimental design. EXP-041 remains valid negative evidence, not something to "fix".

**Phase 81 COMPLETE. The multimodal stage (Phases 78–81) is complete.** Next: Phase 82, formal voxel-wise confusion matrix.

### 13.57 Phase 82: formal voxel-wise confusion matrix (EXP-043)

- **Prediction evaluated:** the retained Phase-71 T2 `M_pred`. The Phase-81 decision (`REJECT_MULTIMODAL_FUSION`, canonical = Phase-71 T2 `M_pred`) was verified from `phase81_multimodal_decision.csv` first. EXP-041 is not evaluated as the retained method.
- **Conditions:** `pn0` and `pn3` only (development). No held-out data.
- **GT:** `M_GT = labels == 10` on the **complete** 181×217×181 volume, with no brain mask, ROI or slice range. A lesion voxel outside the prediction support stays a FN.
- **Definitions:** direct logical counting over the complete 3D volume.
  - **TP:** prediction 1, GT 1.
  - **FP:** prediction 1, GT 0.
  - **FN:** prediction 0, GT 1.
  - **TN:** prediction 0, GT 0.
- **Matrix orientation:** rows = ground truth [0, 1], columns = prediction [0, 1].

  | | prediction 0 | prediction 1 |
  |---|---|---|
  | **GT 0** | TN | FP |
  | **GT 1** | FN | TP |

  i.e. `[TN FP; FN TP]`.
- **Reusable evaluator:** `src/evaluation/computeVoxelConfusion.m`.
  - **Input:** logical masks only, same size, non-empty. There is no conversion, thresholding or reshaping; invalid input raises an error.
  - **Output:** TP, FP, FN, TN, `totalVoxels` and `confusionMatrix = [TN FP; FN TP]`.
  - **Scope:** no file access, no segmentation logic and no derived metric. It is independent of BrainWeb paths, conditions and modality.
- **Synthetic validation:** `experiments/voxel_confusion_check.m`, 12/12 PASS.
  - Count cases: perfect negative; perfect match; all four categories with hand-counted values (TP 1, FP 2, FN 3, TN n − 6); all-positive and all-negative predictions.
  - Rejected inputs: size mismatch, non-logical masks and empty arrays.
  - Behaviour: inputs unchanged, deterministic results, matrix orientation.
- **Real evaluation:** `experiments/exp043_voxel_confusion_matrix.m`, 46/46 checks PASS. Each count is also verified against an independent direct count.

| | `pn0` | `pn3` |
|---|---:|---:|
| Total voxels | 7,109,137 | 7,109,137 |
| Predicted positive / negative | 70,878 / 7,038,259 | 67,066 / 7,042,071 |
| GT positive / negative | 3,512 / 7,105,625 | 3,512 / 7,105,625 |
| TP | 2,107 | 2,013 |
| FP | 68,771 | 65,053 |
| FN | 1,405 | 1,499 |
| TN | 7,036,854 | 7,040,572 |
| Matrix `[TN FP; FN TP]` | `[7,036,854 68,771; 1,405 2,107]` | `[7,040,572 65,053; 1,499 2,013]` |

(`results/metrics/exp043_voxel_confusion_matrix.csv`; `exp043_confusion_matrix_{pn0,pn3}.csv`, with rows gt0/gt1 and columns pred0/pred1.)

- **Arithmetic checks:** all hold exactly in both conditions.
  - TP + FP = predicted positives.
  - TP + FN = GT positives (3,512).
  - TN + FN = predicted negatives.
  - TN + FP = GT negatives.
  - TP + FP + FN + TN = 7,109,137 = `numel(M_pred)` = `numel(M_GT)`.
- **Regression:** TP/FP/FN reproduce exactly the Phase-81 (EXP-042) T2 diagnostic counts. The cross-check is for validation only; the counts were computed independently.
- **Check-label note:** the check reported as "complete GT used (no brain-mask intersection)" verifies that the GT keeps all label-10 voxels (`nnz(gtMask) == nnz(labels == 10)`). The absence of any intersection follows from the code itself (`gtMask = labels == 10`, nothing applied afterwards). After the run the label was renamed to "GT keeps every label-10 voxel of the volume"; results are unchanged.
- **TN:** it is very large (98.98 % of the volume in `pn0`, 99.04 % in `pn3`, computed afterwards from the CSV) because non-lesion voxels vastly outnumber lesion voxels. It is recorded as a count only. Its size is class imbalance, **not** evidence of a good segmentation (formal discussion in Phase 87).
- **Not done:**
  - no Dice, IoU, precision, recall, specificity, accuracy, F1 or volume error (Phases 83+);
  - no slice-wise analysis (Phase 92) and no lesion-wise analysis;
  - no TP/FP/FN/TN masks saved and no figure;
  - no segmentation change and no tuning; `config.m` unchanged.

**Phase 82 COMPLETE.** Next: Phase 83, formal Dice implementation.

### 13.58 Phase 83: formal Dice coefficient (EXP-044)

- **Definition:** `Dice = 2TP / (2TP + FP + FN)`, equivalently 2|M_pred ∩ M_GT| / (|M_pred| + |M_GT|). TN does not enter the formula.
- **Architecture:** `M_pred + M_GT → computeVoxelConfusion` (Phase 82) `→ TP/FP/FN/TN → computeDiceFromConfusion → Dice`. The Dice function does not count voxels itself.
- **Reusable function:** `src/evaluation/computeDiceFromConfusion.m`.
  - **Input:** the confusion structure. TP, FP and FN must be present and be real, finite, non-negative integer scalars; otherwise an error is raised, with no rounding or replacement.
  - **Scope:** no file access, no segmentation logic and no other metric.
- **Zero-denominator convention:** when TP = FP = FN = 0, the function returns Dice = 1 (both positive sets empty, hence identical). This is an explicit **project implementation convention** for the mathematically undefined 0/0 case, not a statement from the course material. It is covered by a synthetic test and is to be used consistently.
- **Synthetic validation:** `experiments/dice_metric_check.m`, 16/16 PASS. The masks go through `computeVoxelConfusion` and then `computeDiceFromConfusion`.
  - Value cases: perfect match 1; disjoint sets 0; TP 2 / FP 1 / FN 3 → 0.5; empty prediction with lesions 0; prediction with empty GT 0; both empty 1 (convention); full-positive match 1.
  - Properties: symmetry (FP ↔ FN), range [0, 1], TN without effect, determinism.
  - Rejected inputs: negative, non-integer, NaN or Inf counts and a missing field.
- **Real evaluation** (`experiments/exp044_formal_dice.m`, 36/36 checks PASS): Phase-71 T2 `M_pred`, complete-volume GT label 10, `pn0`/`pn3` only.

| | TP | FP | FN | 2TP | 2TP + FP + FN | Dice |
|---|---:|---:|---:|---:|---:|---:|
| `pn0` | 2,107 | 68,771 | 1,405 | 4,214 | 74,390 | 0.0566473988439306 |
| `pn3` | 2,013 | 65,053 | 1,499 | 4,026 | 70,578 | 0.0570432712743348 |

(`results/metrics/exp044_formal_dice.csv`.)

- **Validation:**
  - The confusion counts, TN included, reproduce EXP-043 exactly.
  - The denominator equals predicted positives + GT positives in both conditions.
  - The formal Dice reproduces the earlier T2 development values (EXP-042), within 1e-12. That tolerance only absorbs the CSV text representation; the computation is identical.
- **Scope:**
  - One Dice per volume; no DevelopmentScore aggregate was computed in this phase.
  - No IoU, precision, recall, specificity, accuracy, F1 or volume error (Phases 84+).
  - No slice-wise or lesion-wise evaluation and no figure.
  - No segmentation change and no tuning; `config.m` unchanged; no held-out data.

**Phase 83 COMPLETE.** Next: Phase 84, formal IoU / Jaccard implementation.

### 13.59 Phase 84: formal IoU / Jaccard index (EXP-045)

- **Definition:** `IoU = TP / (TP + FP + FN) = |M_pred ∩ M_GT| / |M_pred ∪ M_GT|`.
  - For binary sets, **IoU and the Jaccard index are the same metric**. There is one implementation and one result column (`iou`); there is no duplicate Jaccard function or column.
  - TN does not enter the formula.
- **Architecture:** `M_pred + M_GT → computeVoxelConfusion` (Phase 82) `→ TP/FP/FN/TN → computeIoUFromConfusion → IoU`.
- **Reusable function:** `src/evaluation/computeIoUFromConfusion.m`.
  - **Input:** the same validation as the Dice function. TP, FP and FN must be real, finite, non-negative integer scalars, otherwise an error is raised.
  - **Scope:** no file access, no voxel counting and no other metric.
- **Zero-union convention:** when TP = FP = FN = 0, the function returns IoU = 1 (identical empty positive sets). This is an explicit **project implementation convention**, consistent with the Phase-83 Dice convention and not taken from the course material.
- **Relationship with Dice:** the identity IoU = Dice / (2 − Dice) is used **only as a regression validation** against the formal Phase-83 Dice (`exp044_formal_dice.csv`).
  - The production IoU is computed from TP/FP/FN and is never converted from Dice.
  - The 1e-12 comparison tolerance is numeric only. It is not a segmentation, selection or tuning tolerance.
- **Synthetic validation:** `experiments/iou_metric_check.m`, 16/16 PASS. The masks go through `computeVoxelConfusion` and then `computeIoUFromConfusion`.
  - Value cases: perfect match 1; disjoint sets 0; TP 2 / FP 1 / FN 3 → 1/3; empty prediction 0; empty GT 0; both empty 1 (convention); full-positive match 1.
  - Properties: symmetry, range [0, 1], TN independence, determinism.
  - Rejected inputs: negative, non-integer, NaN or Inf counts and a missing field.
- **Real evaluation** (`experiments/exp045_formal_iou.m`, 34/34 checks PASS): Phase-71 T2 `M_pred`, complete-volume GT label 10, `pn0`/`pn3` only.

| | TP | FP | FN | Intersection | Union | IoU (= Jaccard) |
|---|---:|---:|---:|---:|---:|---:|
| `pn0` | 2,107 | 68,771 | 1,405 | 2,107 | 72,283 | 0.0291493158834027 |
| `pn3` | 2,013 | 65,053 | 1,499 | 2,013 | 68,565 | 0.0293590024064756 |

(`results/metrics/exp045_formal_iou.csv`.)

- **Validation:** the confusion counts, TN included, reproduce EXP-043 exactly, and IoU = Dice/(2 − Dice) holds in both conditions.
- **Scope:**
  - One IoU per volume; no DevelopmentScore.
  - No precision, recall, specificity, accuracy, F1 or volume error (Phases 85+).
  - No slice-wise or lesion-wise evaluation and no figure.
  - No segmentation change and no tuning; `config.m` unchanged; no held-out data.

**Phase 84 COMPLETE.** Next: Phase 85, formal Precision implementation.

### 13.60 Phase 85: formal Precision (EXP-046)

- **Definition:** `Precision = TP / (TP + FP)`, where TP + FP = all predicted-positive voxels. It is the fraction of the voxels predicted as lesion that are lesion voxels in the GT, so it measures the false-positive contamination of the predicted mask.
- **Inputs:** it depends only on TP and FP; FN and TN do not affect it. It is **not symmetric** in prediction and GT, so there is no symmetry test.
- **Architecture:** `M_pred + M_GT → computeVoxelConfusion` (Phase 82) `→ computePrecisionFromConfusion → Precision`.
- **Reusable function:** `src/evaluation/computePrecisionFromConfusion.m`.
  - **Input:** TP and FP must be real, finite, non-negative integer scalars, otherwise an error is raised.
  - **Scope:** no file access, no voxel counting and no other metric. Precision is not derived from Dice or IoU.
- **Zero-denominator convention:** TP = FP = 0 (empty prediction) gives Precision = 1. This is an explicit **project implementation convention** for the undefined 0/0 case, not taken from the course material.
  - It only means there are no false-positive predicted voxels.
  - It does **not** indicate successful lesion detection: if the GT contains lesions, Recall (Phase 86) would reveal the failure.
- **Synthetic validation:** `experiments/precision_metric_check.m`, 16/16 PASS. The masks go through `computeVoxelConfusion` and then `computePrecisionFromConfusion`.
  - Value cases: no FP → 1; no TP → 0; TP 3 / FP 1 → 0.75; TP 2 / FP 2 → 0.5; empty prediction → 1 (convention); full-positive match → 1.
  - Properties: FN independence, TN independence, range [0, 1], determinism.
  - Rejected inputs: negative, non-integer, NaN or Inf counts, and a missing TP or FP field.
- **Real evaluation** (`experiments/exp046_formal_precision.m`, 34/34 checks PASS): Phase-71 T2 `M_pred` (Phase-81 decision re-verified), complete-volume GT label 10, `pn0`/`pn3` only.

| | TP | FP | Predicted positive (= TP + FP) | Precision | TP share | FP share |
|---|---:|---:|---:|---:|---:|---:|
| `pn0` | 2,107 | 68,771 | 70,878 | 0.0297271367702249 | 2.9727 % | 97.0273 % |
| `pn3` | 2,013 | 65,053 | 67,066 | 0.0300152088986968 | 3.0015 % | 96.9985 % |

(`results/metrics/exp046_formal_precision.csv`.)

- **Validation:** the confusion counts, TN included, reproduce EXP-043 exactly, and the denominator equals the predicted-positive voxel count.
- **Interpretation:**
  - Only about 3 % of the voxels predicted as lesion are lesion voxels; about 97 % are false positives.
  - This quantifies the large FP burden documented since Phase 61 (bright / fluid-like candidate structures).
  - Precision does **not** say how much of the GT lesion volume is recovered; that is Recall, in Phase 86.
- **Scope:**
  - No recall/sensitivity, specificity, accuracy, F1 or volume error; no DevelopmentScore.
  - No slice-wise or lesion-wise evaluation and no figure.
  - No segmentation change and no tuning; `config.m` unchanged; no held-out data.

**Phase 85 COMPLETE.** Next: Phase 86, formal Recall / Sensitivity implementation.

### 13.61 Phase 86: formal Recall / Sensitivity (EXP-047)

- **Definition:** `Recall = TP / (TP + FN)`, where TP + FN = all GT lesion voxels. It is the fraction of the ground-truth lesion **voxels** recovered by the prediction.
  - For binary lesion segmentation, **Recall and Sensitivity are the same metric**. There is one implementation and one result column (`recall`).
  - It depends only on TP and FN; FP and TN do not affect it. It is not symmetric in prediction and GT, so there is no symmetry test.
- **Architecture:** `M_pred + M_GT → computeVoxelConfusion` (Phase 82) `→ computeRecallFromConfusion → Recall`.
- **Reusable function:** `src/evaluation/computeRecallFromConfusion.m`.
  - **Input:** TP and FN must be real, finite, non-negative integer scalars, otherwise an error is raised.
  - **Scope:** no file access, no voxel counting and no other metric.
- **Zero-denominator convention:** TP = FN = 0 (no GT lesion voxels) gives Recall = 1. This is an explicit **project implementation convention**, not taken from the course material.
  - It only resolves the undefined denominator.
  - It does **not** imply good predictions overall: false positives with an empty GT would be exposed by Precision.
- **Synthetic validation:** `experiments/recall_metric_check.m`, 16/16 PASS. The masks go through `computeVoxelConfusion` and then `computeRecallFromConfusion`.
  - Value cases: no FN → 1; no TP → 0; TP 3 / FN 1 → 0.75; TP 2 / FN 2 → 0.5; empty GT → 1 (convention); full-positive match → 1.
  - Properties: FP independence, TN independence, range [0, 1], determinism.
  - Rejected inputs: negative, non-integer, NaN or Inf counts, and a missing TP or FN field.
- **Real evaluation** (`experiments/exp047_formal_recall.m`, 34/34 checks PASS): Phase-71 T2 `M_pred` (Phase-81 decision re-verified, input files checked), complete-volume GT label 10, `pn0`/`pn3` only.

| | TP | FN | GT positive (= TP + FN) | Recall (= Sensitivity) | Lesion voxels detected | Lesion voxels missed |
|---|---:|---:|---:|---:|---:|---:|
| `pn0` | 2,107 | 1,405 | 3,512 | 0.5999430523918 | 59.9943 % | 40.0057 % |
| `pn3` | 2,013 | 1,499 | 3,512 | 0.573177676537585 | 57.3178 % | 42.6822 % |

(`results/metrics/exp047_formal_recall.csv`. The "missed" column is 1 − Recall, given only as a plain-language complement and not a new metric.)

- **Validation:** the confusion counts, TN included, reproduce EXP-043 exactly, and the denominator equals the GT-positive voxel count (3,512).
- **Interpretation:**
  - About 60 % (`pn0`) and 57 % (`pn3`) of the GT lesion **voxels** are detected; about 40 % and 43 % are missed.
  - This is **voxel-wise**, not a lesion-wise detection rate (Phase 93). FN are missed lesion voxels, which may belong to partially detected lesions, so no number of missed lesions can be inferred.
- **With the Phase-85 Precision** (0.0297271367702249 / 0.0300152088986968, read from `exp046_formal_precision.csv`): the pattern is **low Precision + moderate Recall**.
  - The current segmentation recovers a substantial fraction of the lesion voxels.
  - It does so with very poor selectivity, because it also labels a much larger number of non-lesion voxels as lesion.
  - No combined score (F1, F-beta, balanced accuracy) was computed.
- **Scope:**
  - No specificity, accuracy or volume error; no DevelopmentScore.
  - No slice-wise or lesion-wise evaluation and no figure.
  - No segmentation change and no tuning; `config.m` unchanged; no held-out data.

**Phase 86 COMPLETE.** Next: Phase 87, formal Specificity implementation.

### 13.62 Phase 87: formal Specificity (EXP-048)

- **Definition:** `Specificity = TN / (TN + FP)`, where TN + FP = all GT non-lesion voxels. It is the fraction of ground-truth non-lesion **voxels** correctly classified as non-lesion.
  - It depends only on TN and FP; TP and FN do not affect it. There is no symmetry test, because the metric refers to the actual negatives.
- **Architecture:** `M_pred + M_GT → computeVoxelConfusion` (Phase 82) `→ computeSpecificityFromConfusion → Specificity`.
- **Reusable function:** `src/evaluation/computeSpecificityFromConfusion.m`.
  - **Input:** TN and FP must be real, finite, non-negative integer scalars, otherwise an error is raised.
  - **Scope:** no file access, no voxel counting and no other metric.
- **Zero-denominator convention:** TN = FP = 0 (no GT negative voxels) gives Specificity = 1. This is an explicit **project implementation convention** for the undefined 0/0 case, not taken from the course material, and it does not imply a good segmentation.
- **Synthetic validation:** `experiments/specificity_metric_check.m`, 16/16 PASS. The masks go through `computeVoxelConfusion` and then `computeSpecificityFromConfusion`.
  - Value cases: no FP → 1; no TN → 0; TN 3 / FP 1 → 0.75; TN 2 / FP 2 → 0.5; no GT negatives → 1 (convention); all-negative match → 1.
  - Properties: TP independence, FN independence, range [0, 1], determinism.
  - Rejected inputs: negative, non-integer, NaN or Inf counts, and a missing TN or FP field.
- **Real evaluation** (`experiments/exp048_formal_specificity.m`, 34/34 checks PASS): Phase-71 T2 `M_pred` (Phase-81 decision re-verified, input files checked), complete-volume GT label 10, `pn0`/`pn3` only.

| | TN | FP | GT negative (= TN + FP) | Specificity | Negatives correctly rejected | Negatives labelled lesion |
|---|---:|---:|---:|---:|---:|---:|
| `pn0` | 7,036,854 | 68,771 | 7,105,625 | 0.990321611399419 | 99.0322 % | 0.9678 % |
| `pn3` | 7,040,572 | 65,053 | 7,105,625 | 0.990844858826634 | 99.0845 % | 0.9155 % |

(`results/metrics/exp048_formal_specificity.csv`. The last column is 1 − Specificity, a plain-language complement and not a new metric.)

- **Validation:** the confusion counts, TN included, reproduce EXP-043 exactly, and the denominator equals the GT-negative voxel count.
- **Class imbalance (critical):** the GT has 7,105,625 non-lesion voxels and only 3,512 lesion voxels.
  - So 68,771 / 65,053 false-positive voxels are less than 1 % of the negatives, while still being about 33 / 32 times the number of TP. The ratios 68,771 / 2,107 and 65,053 / 2,013 were computed afterwards from the counts.
  - "About 99 % of the non-lesion voxels are correctly classified as non-lesion" is the correct reading. It is **not** "99 % accuracy" or "99 % segmentation quality", and Specificity must not be read on its own.
- **High Specificity and low Precision coexist without contradiction:**
  - Specificity asks: of all true non-lesion voxels, how many were rejected?
  - Precision asks: of all voxels predicted as lesion, how many are lesion?
- **Formal development metrics so far** (read from the EXP-044..047 CSVs, descriptive only, no recomputation and no combined score):

| | Dice | IoU | Precision | Recall | Specificity |
|---|---:|---:|---:|---:|---:|
| `pn0` | 0.056647 | 0.029149 | 0.029727 | 0.599943 | 0.990322 |
| `pn3` | 0.057043 | 0.029359 | 0.030015 | 0.573178 | 0.990845 |

- **Overall pattern:** very low Dice and IoU, extremely low Precision, moderate Recall and very high Specificity.
  - In relative terms, the method rejects the vast majority of the non-lesion voxels.
  - In absolute terms, it still produces many more FP voxels than TP lesion voxels.
  - A high Specificity is therefore **no** reason to skip the later tuning stage.
- **Scope:**
  - No accuracy, balanced accuracy, F1, F-beta, MCC, ROC/AUC or Youden index.
  - No volume metrics (Phases 88–90) and no DevelopmentScore.
  - No slice-wise or lesion-wise evaluation and no figure.
  - No segmentation change and no tuning; `config.m` unchanged; no held-out data.

**Phase 87 COMPLETE.** All voxel-wise metrics based on the confusion matrix planned in Phases 82–87 are complete. Phases 88–90 will add volumetric quantities, which are also voxel-derived but are not confusion-matrix metrics. Next: Phase 88, GT lesion volume.

### 13.63 Phase 88: GT lesion volume (EXP-049)

- **GT:** the BrainWeb `msles2` crisp phantom (`phantom_1.0mm_msles2_crisp.rawb`), `M_GT = labels == 10`.
  - It is the complete 181 × 217 × 181 array (7,109,137 voxels), with no mask, ROI or slice selection.
  - Label 10 = MS lesion; no other label is involved.
- **Geometry:** the spacing is 1 × 1 × 1 mm, **established in Phase 26** (§13.7.2: download-page step 1 on all axes, "1mm isotropic" model). Phase 88 uses this geometry and does not discover it.
  - `config.m` has no spacing field, so the script passes `[1 1 1]` mm explicitly with this provenance; `config.m` is unchanged.
  - Physical voxel volume = 1 × 1 × 1 = 1 mm³.
- **Formula:** `V_GT = N_GT × V_voxel`, with `N_GT = nnz(M_GT)` and `V_voxel = prod(spacing)`.
  - The result is stored in mm³.
  - cm³ = mL = mm³ / 1000 is reported only as a unit conversion of the same quantity.
- **Reusable function:** `src/evaluation/computeBinaryMaskVolume.m`. It is generic (logical non-empty mask plus an explicit 3-element positive finite spacing) and has no hidden 1 mm assumption. In this phase it is applied **only** to `M_GT`.
- **Synthetic validation:** `experiments/binary_mask_volume_check.m`, 14/14 PASS.
  - Value cases: 1 voxel → 1 mm³; 5 voxels → 5 mm³; anisotropic [1 2 3] mm → 6 mm³ per voxel and 24 mm³ for 4 voxels; a valid all-false mask → 0 mm³; unit conversion.
  - Rejected inputs: non-logical or empty mask; spacing of wrong length, zero, negative, NaN or Inf.
  - Behaviour: deterministic, inputs unchanged.
- **Result** (`experiments/exp049_gt_lesion_volume.m`, 27/27 checks PASS; `results/metrics/exp049_gt_lesion_volume.csv`, one row):

| Quantity | Value |
|---|---:|
| GT lesion voxel count `N_GT` | 3,512 voxels |
| Voxel physical volume `V_voxel` | 1 mm³ |
| GT lesion volume `V_GT` | **3,512 mm³** |
| Same volume in cm³ / mL | 3.512 cm³ = 3.512 mL |

- **Count and volume are distinct quantities:** 3,512 lesion voxels correspond to 3,512 mm³ because each voxel occupies 1 mm³ (validated spacing). The two values coincide only for this geometry.
- **Regression:** `N_GT` was computed independently and reproduces the established 3,512-voxel invariant (Phase 22, §13.5.3), which equals the per-class lesion volume published by BrainWeb.
- **One shared value:** the crisp GT anatomy is the same for `pn0` and `pn3` (noise changes only the MRI simulation), so there is one GT lesion volume for both conditions.
- **Scope:**
  - No `M_pred` loaded, no predicted volume (Phase 89) and no volume error (Phase 90).
  - No confusion metric recomputed; no connected components; no slice-wise or lesion-wise volumes.
  - No segmentation change; no held-out data.

**Phase 88 COMPLETE.** Next: Phase 89, predicted lesion volume.

### 13.64 Phase 89: predicted lesion volume (EXP-050)

- **Prediction:** the retained Phase-71 T2 `M_pred`.
  - `pn0` and `pn3` are evaluated **separately**, because their masks differ. There is no merging, averaging or DevelopmentScore.
  - Each mask is verified before use: the `M_pred` variable is present, logical, 181 × 217 × 181 (7,109,137 voxels). It is not regenerated or modified.
- **Geometry:** 1 × 1 × 1 mm, the spacing validated in Phase 26 and used in Phase 88 (consistent with the EXP-049 CSV). The voxel volume is 1 mm³.
- **Formula:** `V_pred = N_pred × V_voxel`, where `N_pred = nnz(M_pred)`.
  - The volume is computed with the **same, unchanged** Phase-88 function `computeBinaryMaskVolume`; there is no new volume helper.
  - The physical-volume calculation is therefore the same for GT and prediction.
- **Result** (`experiments/exp050_predicted_lesion_volume.m`, 36/36 checks PASS; `results/metrics/exp050_predicted_lesion_volume.csv`):

| | Predicted-positive voxels `N_pred` | `V_pred` (mm³) | cm³ = mL |
|---|---:|---:|---:|
| `pn0` | 70,878 | 70,878 | 70.878 |
| `pn3` | 67,066 | 67,066 | 67.066 |

- **Regression:** `N_pred` equals `nnz(M_pred)`, the function's `voxelCount` and TP + FP from EXP-043 in both conditions.
  - The Phase-71 files and the volume function were unchanged after the run.
- **Meaning:** `V_pred` is the physical volume occupied by the prediction, i.e. all predicted-positive voxels (TP + FP).
  - Strict term: **predicted-positive segmented volume**; "predicted lesion volume" is used only in this sense.
  - It is not the true lesion volume. With Precision ≈ 3 % (Phase 85), most of it is false positives.
- **No comparison:** the GT was not loaded, and no difference, ratio or percentage error with respect to V_GT was computed. The formal comparison is Phase 90.
- **Scope:**
  - No confusion metric recomputed; no connected components; no slice-wise or lesion-wise volumes.
  - No segmentation change and no tuning; `config.m` unchanged; no held-out data.

**Phase 89 COMPLETE.** Next: Phase 90, formal volume error.

### 13.65 Phase 90: formal lesion-volume error (EXP-051)

- **Inputs:** only the frozen artifacts.
  - V_GT comes from EXP-049 (Phase 88, one row: label 10, 3,512 voxels, 3,512 mm³).
  - V_pred comes from EXP-050 (Phase 89, rows `pn0`/`pn3`, Phase-71 T2 `M_pred`).
  - No mask is loaded and no volume is recomputed.
  - Both volumes are in **mm³**, with the same 1 × 1 × 1 mm spacing and 1 mm³ voxel; the script checks this.
- **Formula** (PROJECT_SPEC §17, unchanged): `VolumeErrorPercent = |V_pred − V_GT| / V_GT × 100`.
  - The formal metric is **absolute**. The signed difference and the direction (overestimation / underestimation / exact match) are reported separately and only for description.
  - Values above 100 % are valid and are **not** clamped. No rounding is applied before the calculation.
- **Reusable function:** `src/evaluation/computeVolumeErrorPercent.m`.
  - It takes two scalar, real, finite, non-negative volumes in the same unit. V_GT must be strictly positive: V_GT = 0 is rejected, and no convention is defined for it.
  - V_pred = 0 is allowed and gives 100 %.
  - There is no file access and no other metric.
- **Synthetic validation:** `experiments/volume_error_check.m`, 16/16 PASS.
  - Value cases: equal volumes → 0 %; 125 vs 100 → +25 / 25 %; 75 vs 100 → −25 / 25 % (absolute); zero prediction → 100 %; 210 vs 10 → 2000 % (not capped); the same 25 % in mm³ and in cm³.
  - Rejected inputs: negative, zero (GT), NaN, Inf or non-scalar volumes.
  - Behaviour: deterministic, inputs unchanged.
- **Result** (`experiments/exp051_formal_volume_error.m`, 33/33 checks PASS; `results/metrics/exp051_formal_volume_error.csv`):

| | V_GT (mm³) | V_pred (mm³) | V_pred − V_GT (mm³) | \|V_pred − V_GT\| (mm³) | VolumeErrorPercent | Direction |
|---|---:|---:|---:|---:|---:|---|
| `pn0` | 3,512 | 70,878 | +67,366 | 67,366 | 1918.16628701595 % | overestimation |
| `pn3` | 3,512 | 67,066 | +63,554 | 63,554 | 1809.62414578588 % | overestimation |

- **Interpretation:**
  - In both conditions the predicted-positive segmented volume is far larger than the physical GT lesion volume, which is why the errors are well above 100 %.
  - Precise reading, with ratios derived afterwards from the CSV and not formal metrics:
    - the **difference** is about 19.18 × V_GT (`pn0`) and 18.10 × V_GT (`pn3`);
    - equivalently, **V_pred** itself is about 20.18 × V_GT and 19.10 × V_GT.
    - "1918 % error" therefore means "V_pred ≈ 20 × V_GT", not "19 × V_GT".
  - This is consistent with the known over-segmentation and false-positive burden: Precision is about 3 % (Phase 85) and Recall about 57–60 % (Phase 86).
  - Volume error is **not** itself an FP metric. It compares total volumes only.
- **Limitation:** VolumeErrorPercent measures disagreement in **total physical volume**.
  - It does not measure spatial overlap, lesion localization, boundary agreement or lesion-wise detection: a prediction could have the correct total volume in the wrong place.
  - It never replaces Dice or IoU.
- **Scope:** results are kept separate per condition, with no averaging and no DevelopmentScore.
  - No confusion metric recomputed; no slice-wise or lesion-wise analysis; no connected components.
  - No segmentation change and no tuning; `config.m` unchanged; no held-out data.

**Phase 90 COMPLETE.** Next: Phase 91, consolidated complete-3D metrics.

### 13.66 Phase 91: consolidated complete-volume 3D evaluation (EXP-052)

- **Purpose:** collect the formal results of Phases 82–90, check their provenance and mutual consistency, and fix one authoritative table as the **primary quantitative development evaluation**.
  - No new metric is introduced and no metric function is called.
  - No mask or MRI is loaded, and nothing is averaged.
- **Domain:** the complete 181 × 217 × 181 volume (7,109,137 voxels) for each condition. No value is an average or median of slice-wise metrics or a selected-slice metric.
- **Prediction and conditions:** Phase-71 T2 `M_pred`, with `pn0` and `pn3` kept separate (no DevelopmentScore, no average).
- **Sources (read-only; unchanged after the run, checked by timestamp, size and content):**

| Column(s) | Source |
|---|---|
| TP / FP / FN / TN (supporting counts, Phase 82) | EXP-043 |
| Dice | EXP-044 |
| IoU (= Jaccard) | EXP-045 |
| Precision | EXP-046 |
| Recall (= Sensitivity, one column) | EXP-047 |
| Specificity | EXP-048 |
| GT lesion volume (one shared row) | EXP-049 |
| Predicted lesion volume | EXP-050 |
| Volume error and direction | EXP-051 |

- **Consistency checks** (`experiments/exp052_complete_3d_metrics.m`, 59/59 PASS). These are checks only and are not saved as metrics.
  - **Counts:** TP + FP + FN + TN = 7,109,137; TP + FN = 3,512 (EXP-049); TP + FP = EXP-050 predicted-positive voxels; the counts are identical across EXP-043..048.
  - **Ranges:** all metrics are finite and in range.
  - **Volumes:** the volumes and the volume error agree across EXP-049..051, and the direction matches the sign.
  - **Regression:** IoU vs Dice / (2 − Dice), Precision / Recall / Specificity vs the counts, and the volume error vs its formula, within the stored-value representation tolerance.
  - **Rerun:** the first pasted run was truncated at the last check, so the script was rerun (it only reads CSVs) and passed 59/59.
- **Primary complete-volume 3D development results** (`results/metrics/exp052_complete_3d_metrics.csv`):

| | `pn0` | `pn3` |
|---|---:|---:|
| TP / FP / FN / TN | 2,107 / 68,771 / 1,405 / 7,036,854 | 2,013 / 65,053 / 1,499 / 7,040,572 |
| Dice | 0.0566473988439306 | 0.0570432712743348 |
| IoU (Jaccard) | 0.0291493158834027 | 0.0293590024064756 |
| Precision | 0.0297271367702249 | 0.0300152088986968 |
| Recall (Sensitivity) | 0.5999430523918 | 0.573177676537585 |
| Specificity | 0.990321611399419 | 0.990844858826634 |
| V_GT | 3,512 mm³ | 3,512 mm³ |
| V_pred | 70,878 mm³ | 67,066 mm³ |
| Volume error | 1918.16628701595 % (overestimation) | 1809.62414578588 % (overestimation) |

- **Interpretation (taken together):**
  - The retained pipeline recovers a moderate fraction of the lesion voxels: Recall is about 57–60 %.
  - It does so with a **severe false-positive burden**. Precision is about 3 %, Dice about 0.057 and IoU about 0.029, and the predicted segmented volume is about 20 times the GT lesion volume.
  - Specificity is about 0.99 only because the non-lesion class has about 7.1 million voxels against 3,512 lesion voxels. It is **not** overall segmentation quality.
  - **Excessive false-positive segmentation is the dominant development problem.** This is a diagnosis only; any change belongs to the tuning stage (Phase 95).
- **Status of the results:** these are **development** results on `pn0`/`pn3`. They are not final test or generalization performance; the held-out evaluation follows after tuning and the freeze.
- **Primary vs diagnostic:** this table is the **primary** quantitative result because every metric refers to the complete 3D volume. The Phase-92 slice-wise metrics will be **diagnostic only**, to see where the pipeline fails, and must not replace it.
- **Scope:**
  - No slice-wise, lesion-wise or size analysis; no figures.
  - No segmentation change and no tuning; `config.m` unchanged; no held-out data.

**Phase 91 COMPLETE.** Next: Phase 92, slice-wise diagnostic metrics.

### 13.67 Phase 92: slice-wise diagnostic evaluation (EXP-053)

- **Purpose:** this phase is **diagnostic only**: it shows where along the axial volume the retained segmentation fails.
  - The Phase-91 complete-volume table remains the **primary** result.
  - No slice metric is averaged (no mean or median) or presented as primary.
- **Data:**
  - Prediction: Phase-71 T2 `M_pred`, `pn0` and `pn3`.
  - GT: complete label 10, with no mask and no slice restriction.
  - Axis: axial, dimension 3, all slices k = 1..181 (each 181 × 217 = 39,277 voxels); no slice is excluded.
- **Method:** the new helper `src/evaluation/computeSliceWiseMetrics.m` reuses the formal functions (`computeVoxelConfusion`, Dice / IoU / Precision / Recall / Specificity) slice by slice. It introduces no new definition and computes no averages.
  - Each row also carries the flags `hasGtLesion`, `hasPrediction`, `hasOverlap` and the denominator flags `diceIouInformative` (TP + FP + FN > 0), `precisionInformative` (TP + FP > 0) and `recallInformative` (TP + FN > 0).
  - Synthetic check: `experiments/slice_wise_metrics_check.m`, 18/18 PASS.
- **Empty-slice conventions:**
  - On slices without a positive class, the formal functions return 1 by project convention (Dice/IoU, Precision, Recall).
  - The CSV keeps these formal values together with the flags.
  - **In the figures, missing points mean that the metric was intentionally hidden for an uninformative denominator.**
- **Regression:** `experiments/exp053_slice_wise_diagnostics.m`, 58/58 PASS.
  - The **summed** slice TP / FP / FN / TN reproduce the Phase-91 counts exactly in both conditions.
  - The summed GT-positive voxels equal 3,512, and the summed predicted-positive voxels equal TP + FP.
  - The whole-volume Dice comes from the whole-volume counts; it is **not** the mean of the slice Dice values.
- **Slice categories** (`exp053_slice_diagnostic_summary.csv`; descriptive counts, not scores):

| | `pn0` | `pn3` |
|---|---:|---:|
| GT-positive slices (≥ 1 lesion voxel; first k = 33, last k = 118) | 84 | 84 |
| Prediction-positive slices | 121 (first k = 12, last k = 144) | 117 (first k = 28, last k = 144) |
| Both positive | 84 | 84 |
| GT-only positive | 0 | 0 |
| Prediction-only positive | 37 | 33 |
| Both empty | 60 | 64 |
| Slices with TP / FP / FN | 44 / 121 / 83 | 43 / 117 / 83 |

- **Top-5 slices** (`exp053_slice_top5_rankings.csv`; ties broken by higher count, then lower k):
  - **FP:**
    - `pn0`: 92 (1,698), 93 (1,629), 94 (1,591), 95 (1,532), 82 (1,516).
    - `pn3`: 93 (1,650), 94 (1,561), 95 (1,490), 83 (1,478), 82 (1,465).
  - **FN:**
    - `pn0`: 100 (56), 103 (55), 102 (54), 101 (51), 97 (46).
    - `pn3`: 103 (59), 102 (58), 100 (57), 99 (53), 101 (52).
  - **TP:**
    - `pn0`: 102 (170), 103 (166), 101 (138), 104 (125), 98 (121).
    - `pn3`: 102 (166), 103 (162), 101 (137), 104 (119), 97 (118).
- The first/last indices are not contiguous ranges: k 33–118 contains 86 slices, of which 84 are GT-positive; k 12–144 contains 133 slices, of which 121 are prediction-positive in `pn0`.
- **Derived afterwards from the CSV** (descriptive only). These figures come from a one-off read-only pass over `exp053_slice_wise_metrics.csv`: sums of `fpVoxels` / `fnVoxels` over the stated slice sets. They are not printed by the EXP-053 script.
  - FP on GT-empty slices: 5,299 (7.7 %) in `pn0`, 4,355 (6.7 %) in `pn3`.
  - FP in k 70–104: 42,824 (62.3 %) in `pn0`, 41,340 (63.5 %) in `pn3`. This window was chosen afterwards only to describe the figure; it is not a rule.
  - GT-positive slices with prediction but TP = 0: 40 in `pn0` and 41 in `pn3` (k 33–70 except 60, and 113/114–118). They hold 489 / 517 FN, i.e. 34.8 % / 34.5 % of all FN.
- **Findings** (figures `exp053_{pn0,pn3}_slice_counts.png`, `exp053_{pn0,pn3}_slice_metrics.png`):
  1. **FP: widespread, but concentrated centrally.**
     - FP appear on 121 / 117 of the 181 slices.
     - They form a broad plateau around k ≈ 70–104 (about 62–64 % of all FP), with peaks at k 92–95 and 82–83.
     - There is a secondary cluster around k ≈ 52–60, and smaller tails at k 12–50 and 115–144.
  2. **Prediction-only slices:** 37 / 33 slices, carrying only about 7–8 % of the FP.
  3. **FN:**
     - FN concentrate where the GT lesion load is largest (k ≈ 97–103).
     - No GT-positive slice is completely without prediction.
     - However, in 40 / 41 GT-positive slices with small lesion loads (k 33–70 and 113–118) the prediction does not overlap the GT at all (Recall 0). These slices hold about a third of all FN.
  4. **Metrics by position** (informative slices only):
     - Recall varies strongly with position: 0 at k 33–70 except k 60, up to about 0.8–1.0 around k 80–105.
     - Precision is close to 0 almost everywhere and only reaches about 0.4–0.45 around k 103–104.
  5. **`pn0` vs `pn3`:** the spatial pattern is the same.
     - FP slices: 117 in both, 4 only in `pn0` (the extra low-k slices), none only in `pn3`.
     - FN slices: 83 in both and identical.
     - The maximum FP and FN slices lie in the same regions.
  6. **Phase-91 diagnosis supported: YES.** The FP burden dominates and is largest in the central slices, where earlier phases showed bright, fluid-like candidate structures. This is a visual association only, with no anatomical identification.
- **No location rule:** these patterns must **not** be turned into a z cutoff, ROI, slice-specific threshold or slice exclusion (no lesion-position leakage). Any future adaptation must be automatic, image-derived and formally tested in the tuning stage (Phase 95).
- **Scope:**
  - No slice-wise volume error; no components; no lesion-wise (Phase 93) or size (Phase 94) analysis; no MRI overlays.
  - No segmentation change and no tuning.
  - The Phase-71 masks, the Phase-91 CSV, the GT and `config.m` are unchanged; no held-out data.

**Phase 92 COMPLETE.** Next: Phase 93, lesion-wise analysis.

### 13.68 Phase 93: lesion-wise 3D connected-component analysis (EXP-054)

- **Purpose:** object-level, **diagnostic** evaluation. Phase 91 remains the primary result, and Phase 92 the slice-wise diagnostic.
- **Data:**
  - Prediction: Phase-71 T2 `M_pred`, `pn0` and `pn3`.
  - GT: complete label 10, with no mask, no restriction and no component removed or merged.
- **Objects:** 26-connected 3D components of the complete 181 × 217 × 181 volumes, for both GT and prediction.
  - This is the project's volumetric object definition, already used for the prediction in Phase 72. It is a volumetric extension of classical connected components and is not claimed to be taught in the course.
  - No connectivity comparison was done, no 2D identity was used, and no Phase-92 slice information was used.
- **Matching rule** (pre-registered before any lesion-wise result): a GT component and a predicted component **match iff they share at least one voxel** (intersection > 0).
  - There is no overlap-fraction, Dice, distance, bounding-box or size criterion. This avoids choosing an arbitrary threshold before the results are known.
  - Relations are **many-to-many**, with no one-to-one assignment.
  - **Limitation:** a single shared voxel is enough for "detected", so detection does not imply good delineation or coverage. Overlap voxel counts are stored to make weak matches visible.
- **Definitions:**
  - **Detected GT lesion (TP-lesion):** a GT component with at least one matched predicted component.
  - **Missed GT lesion:** a GT component with no match.
  - **Matched predicted component:** a predicted component with at least one GT match.
  - **False predicted component:** a predicted component with no GT match.
  - **Merge:** a predicted component with matchedGtCount > 1.
  - **Split / fragmentation:** a GT component with matchedPredictionCount > 1.
  - These are descriptive only; no score is derived from them.
- **Implementation:** `src/evaluation/computeLesionWiseMatches.m` (`bwconncomp` + `PixelIdxList`, pairs from shared voxels; no `regionprops3`).
  - Synthetic check: `experiments/lesion_wise_matching_check.m`, 17/17 PASS.
  - Real run: `experiments/exp054_lesion_wise_analysis.m`, 59/59 PASS.
- **Regression** (all PASS):
  - The GT components are identical for `pn0` and `pn3`.
  - All components reconstruct their masks exactly and are mutually disjoint.
  - The predicted components equal the Phase-72 `CC3D` (335 / 291), in both count and voxel lists.
  - The sum of the relation overlaps equals the Phase-91 TP (2,107 / 2,013).

| | `pn0` | `pn3` |
|---|---:|---:|
| GT lesion components (26-connected) | 59 | 59 |
| Predicted components | 335 | 291 |
| Detected GT lesions (TP-lesions) | 15 | 14 |
| Missed GT lesions | 44 | 45 |
| Matched predicted components | 4 | 4 |
| False predicted components | 331 | 287 |
| GT lesions matched by > 1 prediction (split) | 1 | 1 |
| Predicted components matching > 1 GT lesion (merge) | 1 | 1 |
| Match relations | 16 | 15 |
| Overlap voxels across relations (= TP) | 2,107 | 2,013 |

(`results/metrics/exp054_lesion_wise_summary.csv`, `exp054_gt_lesion_status.csv`, `exp054_predicted_component_status.csv`, `exp054_lesion_matches.csv`.)

- **One large predicted component dominates the matches.** A single large predicted component is connected to and overlaps several distinct GT lesions: relative to the GT component definition, it merges many separate lesions into one predicted object (matchedGtCount > 1).
  - Predicted component #124 (`pn0`) / #92 (`pn3`) touches **13 / 12 GT lesions** and holds 1,844 / 1,792 overlap voxels, i.e. **87.5 % / 89.0 % of all TP**.
  - In the Phase-72 table (`exp039_components3d.csv`, cross-reference only) this is the 25,629 / 25,417-voxel component spanning k 68–107.
  - It therefore also contains 23,785 / 23,625 FP voxels, about 34.6 % / 36.3 % of all FP. These figures were derived afterwards from the CSVs.
  - This is the large central candidate described since Phase 61 as bright / fluid-like and fused with periventricular lesions (a visual description, no anatomical identification).
  - The other three matched components hold 14, 72 and 177 overlap voxels in `pn0`, and 14, 52 and 155 in `pn3`.
  - The single split case is GT lesion 49, touched by two predicted components in both conditions.
- **Interpretation:**
  - Under the permissive any-overlap criterion (> 0 voxels) only 15 / 14 of the 59 GT lesion objects count as detected, and 44 / 45 are missed. 15/59 is a count under that criterion, not a formal "lesion recall".
  - 98.8 % / 98.6 % of the predicted components (331 / 287) touch no GT lesion; only 4 touch any lesion.
  - Most of the voxel-level Recall (about 60 %) comes from **that single large predicted component overlapping many distinct GT lesions**. The voxel Recall therefore does not mean that most lesions are found: few lesion objects are touched at all.
  - Together with the earlier results, the method produces many false objects plus one large central T2-bright structure. That structure contains voxels of many true lesions together with a very large amount of non-lesion tissue. This explains why moderate voxel Recall, few touched lesions, Precision ≈ 3 % and a strongly overestimated volume coexist (diagnosis for Phase 95).
  - The object-level view complements the voxel-level pattern "moderate Recall, very low Precision". The FP burden is spread over hundreds of false objects plus one very large mixed object.
- **Warnings:**
  - The **false-component count is not the FP voxel count**: a matched component, such as the merged one, can contain many FP voxels.
  - The **missed-lesion count is not the FN voxel count**: a detected lesion can still contain FN voxels.
  - **One shared voxel counts as detection** under the pre-registered rule; overlap quality remains described by Dice, IoU and Recall.
- **`pn0` vs `pn3`:** almost identical. 14 lesions are detected in both conditions, 1 only in `pn0` and none only in `pn3`, with the same merged and split structure.
- **Scope:**
  - No size classification or size-dependent rates (Phase 94); no lesion-wise Precision, Recall, F1 or Dice.
  - No component filtering; no segmentation change; no tuning; no figures.
  - The Phase-71 masks, the Phase-91/92 artifacts and `config.m` are unchanged; no held-out data.

**Phase 93 COMPLETE.** Next: Phase 94, small-vs-large lesion analysis.

### 13.69 Phase 94: small-vs-large GT lesion analysis (EXP-055)

- **Purpose:** a diagnostic check of whether the Phase-93 lesion-wise failures depend on lesion size.
  - Lesion identity is unchanged: 26-connected 3D GT components, the same `bwconncomp` enumeration as Phase 93.
  - Matching is unchanged: the frozen Phase-93 status (`exp054_gt_lesion_status.csv`) is reused, with no rematching.
- **Size and threshold:**
  - **Size** is the GT component voxel count, which equals the volume in mm³ with 1 × 1 × 1 mm voxels.
  - **Threshold:** `T_size` = median of the 59 GT component sizes = **7 voxels (7 mm³)**.
  - The threshold is computed **from the GT sizes only**, by `src/evaluation/classifyGtLesionSizes.m`, which receives the sizes alone, and **before** the Phase-93 status is read. The script sections are ordered this way and the order is checked.
  - **SMALL** = size ≤ 7; **LARGE** = size > 7. Ties at the median stay SMALL, with no artificial split. The classes are identical for `pn0` and `pn3`.
  - **Transparency:** the Phase-93 detected IDs were already known, but no GT size had been computed before this phase. The median rule was fixed in the phase specification, not chosen afterwards.
- **Meaning of SMALL / LARGE:** dataset-relative diagnostic groups for this `msles2` GT, **not** a clinical lesion-size definition.
- **Validation:**
  - Synthetic check: `experiments/lesion_size_classification_check.m`, 13/13 PASS.
  - Real run: `experiments/exp055_small_vs_large_lesions.m`, 38/38 PASS. This includes: 59 components = Phase 93, sizes summing to 3,512, summed overlap = Phase-91 TP, missed lesions with coverage 0, detected lesions with coverage > 0.
- **GT voxel coverage** = overlap voxels / GT lesion voxels. It is a **diagnostic support quantity**, not a new formal metric and not a "lesion recall".

| Class | Lesions | Size range (median) | GT voxels |
|---|---:|---|---:|
| SMALL (≤ 7) | 31 | 1–7 (3) | 108 |
| LARGE (> 7) | 28 | 8–927 (29) | 3,404 |

| | Detected / missed | Detection fraction (diagnostic) | Recovered / class GT voxels | GT voxel coverage |
|---|---:|---:|---:|---:|
| `pn0` SMALL | 3 / 28 | 0.0968 | 6 / 108 | 0.0556 |
| `pn0` LARGE | 12 / 16 | 0.4286 | 2,101 / 3,404 | 0.6172 |
| `pn3` SMALL | 2 / 29 | 0.0645 | 5 / 108 | 0.0463 |
| `pn3` LARGE | 12 / 16 | 0.4286 | 2,008 / 3,404 | 0.5899 |

(`results/metrics/exp055_gt_lesion_size_analysis.csv` (118 rows), `exp055_size_class_summary.csv`, `exp055_size_cross_condition.csv`; figures `exp055_small_large_detection_counts.png`, `exp055_lesion_size_vs_gt_coverage.png`.)

- **Cross-condition:**
  - SMALL: detected in both 2, only in `pn0` 1, only in `pn3` 0, missed in both 28.
  - LARGE: detected in both 12, and missed in both 16.
- **Distribution** (read afterwards from the per-lesion CSV for `pn0`, descriptive only, not a threshold):
  - The 8 largest GT lesions (155–927 voxels) are all detected, with coverage 0.49–0.85.
  - Of the 20 LARGE lesions with 8–127 voxels, 16 are missed; the 4 detected ones have coverage 0.03–0.45.
  - `pn3` shows the same picture in the figure.
- **Answers:**
  - Missed lesions are **predominantly SMALL**: 28 of 44 in `pn0`, 29 of 45 in `pn3`. But **16 LARGE lesions are also completely missed** in both conditions, all in the lower part of the LARGE range (8–127 voxels).
  - SMALL lesions are almost always missed, with about 5 % of their voxels covered. LARGE lesions are detected more often and better covered (about 0.59–0.62).
  - The few biggest lesions carry most of the voxel-level Recall. SMALL lesions hold only 108 of the 3,512 GT voxels (≈ 3.08 %), so almost all of them can be missed without a proportional drop in voxel Recall. This helps explain how voxel Recall ≈ 57–60 % coexists with only 14–15 of 59 lesions touched.
  - `pn0` and `pn3` show the same size pattern.
  - **Lesion size explains the current lesion-wise failure PARTLY.** Size is strongly associated with failure, but even many lesions above the median are missed; only the biggest ones are reliably touched.
- **Hypothesis only** (consistent with Phases 63 and 70, not demonstrated by Phase 94): the per-slice 3 × 3 square opening removes any isolated structure that cannot contain a 3 × 3 square. Lesions of ≤ 8 voxels can therefore only survive as part of a larger candidate region.
  - Phase 94 does not isolate the effect of morphology from thresholding or the other steps.
  - This must be tested experimentally during tuning.
- **Warnings:**
  - Detection requires only one overlapping voxel.
  - GT voxel coverage is diagnostic.
  - SMALL / LARGE are dataset-relative.
  - The **median GT size (7 voxels) is NOT a segmentation or predicted-component filtering threshold** and must never be used as one (no GT leakage).
- **Scope:**
  - No predicted-component size classes or filtering; no lesion-wise Dice / IoU / Precision / Recall / F1; no correlation or model fitting.
  - No segmentation change and no tuning.
  - The prior artifacts, the GT and `config.m` are unchanged; no held-out data.

**Phase 94 COMPLETE.** Next: Phase 95, development-only tuning.

### 13.70 Phase 95: development-only tuning (EXP-056)

- **Motivation (Phases 91–94):**
  - Precision is about 3 % with Recall about 57–60 %, and the volume is overestimated by about 1,800–1,900 %.
  - FP are widespread, and hundreds of predicted 3D components are completely false. About half of them occupy a single slice (Phase 72).
  - SMALL lesions are especially vulnerable.
  - The aim is to reduce FP without destroying TP. The winner is selected only by the Phase-37 rule.
- **Frozen grid** (pre-registered in EXPERIMENT_LOG before any result): 2 × 2 × 3 × 2 = **24 configurations**, i.e. 48 predictions, with IDs `P?_T?_M?_G?`.

| Factor | Options | Why |
|---|---|---|
| P preprocessing | P0 none; P1 Gaussian σ 0.5, 3 × 3, replicate, 2D per slice | re-assesses the Phase-47 Gaussian candidate with complete-volume Dice |
| T threshold | T2 = `multithresh(T2(brainMask), 2)`, Class 3 (EXP-026); T3 = `multithresh(…, 3)`, Class 4 | a stricter automatic high-intensity partition; thresholds are never modified |
| M morphology | M0 none; M1 one 2D opening `diamond 1`; M2 one 2D opening `square 3` (Phase 65) | preserves small/thin structures vs less / current aggressiveness |
| G geometry | G0 none; G1 remove 26-connected 3D components that occupy exactly one axial slice | a generic continuity rule on the predicted object; no size, position or GT-derived value |

- **Implementation:** `src/segmentation/generatePhase95Prediction.m` (P → T → M → G; it accepts only grid values and has no GT argument) and `src/segmentation/removeSingleSliceComponents3D.m`.
  - Synthetic check: `experiments/phase95_prediction_pipeline_check.m`, 21/21 PASS. Its tiny 4-level synthetic volume produces two `multithresh` "did not converge" warnings, which do not affect the checks. No such warning appeared on the real data.
  - Real run: `experiments/exp056_development_tuning.m`, 27/27 PASS. All 48 predictions were generated and saved (`data/processed/phase95_candidates/`) **before** the GT was loaded. The baseline `P0_T2_M2_G0` reproduces the Phase-71 `M_pred` exactly and the Phase-91 Dice.
- **Selection rule (Phase 37):**
  - Metric: complete-volume 3D Dice; DevelopmentScore = (Dice_pn0 + Dice_pn3) / 2, with one parameter set for both conditions and no near-tie tolerance.
  - Exact-tie order (declared, not needed): weaker-condition Dice, then fewer active blocks (M1 counted as simpler than M2), then ID.
- **Ranking** (`exp056_tuning_ranking.csv`, figure `exp056_tuning_ranking.png`):

| Rank | Config | Dice `pn0` | Dice `pn3` | DevelopmentScore |
|---:|---|---:|---:|---:|
| 1 | **P0_T2_M2_G1** | 0.058067 | 0.058248 | **0.058158** |
| 2 | P0_T2_M2_G0 (baseline) | 0.056647 | 0.057043 | 0.056845 |
| 3 | P1_T2_M2_G1 | 0.055822 | 0.056791 | 0.056307 |
| 4 | P0_T2_M1_G1 | 0.054745 | 0.055775 | 0.055260 |
| 5 | P1_T2_M2_G0 | 0.054313 | 0.055689 | 0.055001 |
| 6 | P0_T2_M1_G0 | 0.053521 | 0.054352 | 0.053937 |
| 7 | P1_T2_M1_G1 | 0.051961 | 0.053863 | 0.052912 |
| 8 | P1_T2_M1_G0 | 0.050688 | 0.052532 | 0.051610 |
| 9–24 | all T3 configurations and all M0 configurations | | | 0.038275 – 0.044238 |

- **Winner: P0_T2_M2_G1**. It uses no preprocessing, `multithresh` N = 2 with Class 3, one 2D axial square-3 opening, and removes single-slice 26-connected 3D components.
  - DevelopmentScore **0.058157789028849** vs baseline 0.0568453350591327: **+0.00131245**, about +2.3 % relative. Both conditions improve, and so does the weaker-condition Dice (0.058067).
  - No exact tie occurred.
- **Baseline vs selected** (post-selection diagnostics; `exp056_baseline_vs_selected.csv`, figure `exp056_baseline_vs_selected_metrics.png`):

| | `pn0` baseline → selected | `pn3` baseline → selected |
|---|---|---|
| Dice | 0.056647 → 0.058067 | 0.057043 → 0.058248 |
| IoU | 0.029149 → 0.029902 | 0.029359 → 0.029998 |
| Precision | 0.029727 → 0.030520 | 0.030015 → 0.030695 |
| Recall | 0.59994 → 0.59596 | 0.57318 → 0.56919 |
| TP / FP / FN | 2,107 / 68,771 / 1,405 → 2,093 / 66,484 / 1,419 | 2,013 / 65,053 / 1,499 → 1,999 / 63,126 / 1,513 |
| Predicted voxels (mm³) | 70,878 → 68,577 | 67,066 → 65,125 |
| Volume error | 1918.2 % → 1852.6 % | 1809.6 % → 1754.4 % |

- **Lesion-wise** (post-selection, Phase-93 rule, Phase-94 groups; `exp056_selected_lesion_diagnostics.csv`):
  - Predicted components drop from 335 to 165 (`pn0`) and from 291 to 143 (`pn3`). False components drop from 331 to 162 and from 287 to 140.
  - Detected GT lesions drop from 15 to 14 and from 14 to 13. SMALL detections are unchanged (3 / 2); LARGE drop from 12 to 11.
  - **GT lesion 16** (31 voxels, LARGE) is lost in both conditions, and no lesion is gained. Its only predicted support was a single-slice component at k 60: #103 with 14 voxels in `pn0`, #78 with 15 voxels in `pn3` (Phase-72 / EXP-054 cross-reference). G1 removes it, and the 14 TP lost per condition are exactly this overlap.
- **Interpretation:**
  - G1 halves the number of predicted objects but removes only about 2,000 FP voxels, about 3 % of the FP. Most FP voxels lie in multi-slice components, above all the large central bright / fluid-like one.
  - Dice rises slightly, Recall falls slightly, and the volume overestimation remains about 1,750–1,850 %. **The dominant FP problem is only marginally reduced.**
  - The selected rule removes the only predicted support of one GT lesion. This is the same kind of loss that led to rejecting EXP-036 in Phase 70. By this phase's pre-registered rule it is reported but does not change the selection.
- **Factor pattern across the factorial grid** (descriptive only, not used for selection):
  - G1 ≥ G0 in all 12 matched pairs.
  - P1 (Gaussian) < P0 in all 12 matched pairs.
  - T3 is worse than T2 whenever an opening is applied (M1/M2, 8 of 8 matched pairs). Without opening (M0), T3 is slightly better (4 of 4), but all M0 configurations rank low.
  - With T2, M2 > M1 > M0.
- **Scope:**
  - No held-out data and no grid extension or refinement after the results.
  - No position rule and no GT-derived size threshold (the Phase-94 7-voxel value is not used).
  - No region growing, multimodal fusion or local thresholding.
  - `config.m` unchanged.
- **Status of the configuration:** selected at the **development** level only and **NOT yet frozen** for the final test (Phase 96). Ideas for further gains, for example targeting the large central component, are future work outside EXP-056.

**Phase 95 COMPLETE.** Next: Phase 96, freeze final parameters.


### 13.71 Phase 95 (supplementary, final development experiment): T1-derived anatomical support (EXP-057)

- **Why:** EXP-056 showed that size and continuity filters remove only about 3 % of the FP. The dominant FP are T2-bright, fluid-like structures. EXP-057 tests whether a T1-derived support, with the T2 threshold re-estimated inside it, removes them. Pre-registered and approved by the user before running; declared to be the last development experiment.
- **Code:**
  - `src/segmentation/computeT1AnatomicalSupport.m` (S0 / S1 / S2 from `multithresh(T1(EXP-021), 2)`; per-slice `imfill` of T1-high; T1-low subtracted);
  - `src/segmentation/generateExp057Prediction.m` (TA / TB inside the support, opening, G1);
  - synthetic check `experiments/exp057_support_pipeline_check.m` (19/19);
  - main script `experiments/exp057_t1_support_tuning.m` (27/27).
- **Grid:** S0/S1/S2 × TA/TB × M0/M1/M2 × G0/G1 = 36 configurations, 72 predictions, all saved before the GT was loaded (`data/processed/phase95_exp057_candidates/`). The baseline S0_TA_M2_G1 equals the EXP-056 winner voxel by voxel.
- **Supports (GT-free figure `results/figures/exp057_supports.png`):** S2 covers the WM-compatible region and the deep structures it encloses (neutral description, no anatomical check). In infratentorial slices (k = 46) much of the brain falls in S1 but not in S2. S2 has 713,108 / 712,948 voxels, about 42 % / 43 % of S0.
- **Result:** **selected S2_TA_M2_G1**.
  - Dice 0.661039 (`pn0`) / 0.539029 (`pn3`); DevelopmentScore **0.600034** vs 0.058158 for the EXP-056 winner.
  - Precision 0.664 / 0.439, Recall 0.658 / 0.697. V_pred 3,477 / 5,571 mm³; volume error 1.00 % / 58.63 %.
  - FP 66,484 → 1,167 / 63,126 → 3,123; TP +217 / +449.
  - The four S2 + TA + opening configurations occupy ranks 1–4. For the same support, morphology and component rule, TB is worse than TA in every case. TB in S1 is the worst family (Dice < 0.011).
- **Where the remaining errors are (evaluation only):**
  - S2 contains 3,114 / 3,058 of the 3,512 GT voxels, so the voxel Recall is capped at 0.887 / 0.871.
  - `pn0` FN 1,202 = 398 outside S2 + 804 removed by the opening + G1.
  - `pn3` FN 1,064 = 454 outside S2 + 610 removed by the opening + G1.
  - Before morphology, TA inside S2 contains every GT voxel of S2 in both conditions.
- **Lesion-wise (Phase-93 rule):**
  - Detected 19 / 28 of 59 GT lesions (EXP-056 winner: 14 / 13).
  - False predicted components 0 of 20 / 17 of 45.
  - SMALL detected 2 / 6, LARGE 17 / 22.
  - Lost vs the EXP-056 winner: lesions 21, 33, 44, 47 (`pn0`) and 33, 37, 44, 47 (`pn3`); in the Phase-94 baseline record these matches relied on 1–3 overlapping voxels.
- **Limits and risks (declared):**
  - `pn3` already has 2.7× the FP of `pn0` and a lower TA threshold inside S2 (0.518 vs 0.611): noise sensitivity, possibly larger at `pn5`/`pn7`/`pn9`. This is not measured.
  - BrainWeb has near-piecewise-constant tissue intensities (rf0), which favors the T1 partition.
  - The design follows several development results on `pn0`/`pn3`; generalization is judged only by the held-out test.
- **Not used:** held-out data, position rules, GT-derived sizes, grid extensions or post-hoc fixes. `config.m` unchanged.
- **Status:** selected development configuration, **NOT yet frozen**. EXP-057 is the final development experiment.

**Phase 95 (including EXP-057) COMPLETE.** Next: Phase 96, freeze final parameters.


### 13.72 Phase 95, amendment A1: v1 freeze and v2 experiment (EXP-058)

- **v1 freeze:** S2_TA_M2_G1 (EXP-057) frozen on 2026-10-14 (commit "fase 96a", tag `v1-frozen`). The configuration and SHA-256 of the prediction files are in `EXPERIMENT_LOG.md`.
- **Amendment A1:** after EXP-057 the user reopened development for exactly one experiment. The primary version for the final test is fixed before any held-out access (v2 only if strictly better than v1 on the DevelopmentScore), and both versions are tested.
- **EXP-058 grid:** 7 F × 3 R = 21 configurations on top of the frozen v1.
  - F: none; Gaussian σ 0.5 on T1 / T2 / both; anisotropic diffusion on T1 / T2 / both.
  - R: none; morphological reconstruction from the v1 seeds inside S2 (R1) or towards S1 (R2).
  - The anisotropic diffusion is a narrow, user-approved project exception (ALLOWED_TECHNIQUES §4.4). It uses `imdiffusefilt` with explicit fixed parameters: 5 iterations, exponential conduction, 8-neighbour, gradient threshold 0.10 × slice range.
- **Code:**
  - `src/preprocessing/anisotropicDiffusionSlices.m`;
  - `src/segmentation/generateExp058Prediction.m`;
  - synthetic check `experiments/exp058_filter_recovery_check.m` (16/16);
  - main script `experiments/exp058_v2_tuning.m` (27/27).
- **Default parameters:** the explicit call is not identical to `imdiffusefilt` with default options. The frozen explicit definition applies, as pre-registered.
- **Result:** **v2 = F5_R0** (anisotropic diffusion of T2 only, no recovery).
  - DevelopmentScore 0.661169 vs 0.600034 for v1; Dice 0.669 / 0.653.
  - In pn3 the FP fall from 3,123 to 857, and TA_S2 rises from 0.518 to 0.563 (close to pn0's 0.616).
  - All T2-filtered configurations beat v1. Filtering T1 alone is unstable (anisotropic: best pn0, poor pn3).
- **Recovery rejected by the grid:** R1 adds more FP than TP, because the opening also disconnects lesion cores from adjacent bright structures. R2 leaks into S1 (up to about 585,000 predicted voxels). Both failure modes were declared in advance.
- **Trade-off:** in pn3, v2 detects fewer GT lesions (28 → 16, SMALL 6 → 1) and has a lower Recall (0.697 → 0.603). It is more conservative and more consistent across conditions.
- **Status:** v2 primary, v1 secondary; development closed (no EXP-059). Next: Phase 96, freeze of both versions, then held-out download and Phase 97.
