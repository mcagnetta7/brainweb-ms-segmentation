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

### 13.17 Phase 40: brain-only histogram — BLOCKED / DEFERRED

**Status:** BLOCKED / DEFERRED (2026-10-04).

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
