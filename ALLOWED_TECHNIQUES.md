# Allowed Image Processing Techniques

## 1. Purpose

This document defines the classical Image Processing techniques that may be considered during the development of the BrainWeb multiple-sclerosis lesion segmentation project.

The list is based on the material presented during the Image Processing course.

Its purpose is to:

- keep the project aligned with the course;
- prevent unnecessary algorithmic complexity;
- provide a methodological reference for implementation;
- prevent AI-assisted development from introducing unrelated techniques without explicit approval.

Being listed in this document does NOT mean that a technique must be used.

A technique should be introduced only when it solves a specific problem observed during experimentation.

---

## 2. General Rule

The project must primarily use classical Image Processing techniques covered during the course.

The preferred development strategy is:

```text
simple method
    ↓
observe limitations
    ↓
introduce one justified technique
    ↓
measure its effect
```

Techniques must not be combined only to make the pipeline more sophisticated.

### 2.1 Processing Dimensionality

The initial image-processing pipeline is explicitly 2D and operates slice by slice.

The techniques and MATLAB functions listed in this document refer to 2D processing.

3D processing functions, such as 3D filters or 3D structuring elements, are not currently part of the allowed list.

They may only be reviewed later if required.

---

## 3. Image and Intensity Analysis

The following operations are allowed for exploratory analysis and preprocessing.

### 3.1 Grayscale Image Analysis

Allowed:

- grayscale image representation;
- pixel intensity analysis;
- intensity profiles;
- minimum and maximum intensity;
- mean and standard deviation;
- intensity histograms.

Possible uses in this project:

- inspect MRI intensity distributions;
- compare MRI modalities;
- understand tissue and lesion intensity ranges;
- support threshold-selection experiments.

---

### 3.2 Histograms

Allowed:

- image histogram computation;
- histogram visualization;
- histogram-based intensity analysis.

Histograms may be computed:

- over the complete image;
- over the brain region after brain-mask extraction;
- independently for different MRI modalities.

Histogram information may support thresholding decisions.

---

### 3.3 Intensity Transformations

Course-compatible intensity transformations may be considered when justified.

Examples include:

- intensity conversion/rescaling, if required;
- contrast transformations;
- histogram-based transformations.

No specific normalization method is assumed at this stage.

Course-compatible MATLAB operations for intensity conversion/rescaling include:

```matlab
mat2gray
im2double
```

Their use is not prescribed.

These operations must not be introduced automatically.

Their usefulness must first be demonstrated on the MRI data.

---

## 4. Spatial Filtering

Spatial filtering is allowed as a preprocessing technique.

Filtering should initially be compared against an unfiltered baseline.

---

### 4.1 Mean Filtering

Allowed.

Purpose:

- smoothing;
- reducing local intensity variations.

Possible limitation:

- may blur small structures and lesion boundaries.

It should therefore be used cautiously.

---

### 4.2 Gaussian Filtering

Allowed.

MATLAB functionality covered by the course includes approaches based on Gaussian filtering such as:

```matlab
fspecial('gaussian', ...)
imfilter(...)
imgaussfilt(...)
```

Possible project use:

- reduce noise before thresholding;
- stabilize intensity-based segmentation.

Gaussian filtering should only be retained if its effect is experimentally useful.

---

### 4.3 Median Filtering

Allowed.

MATLAB functionality includes:

```matlab
medfilt2
```

Possible use:

- reduction of impulse-like noise;
- smoothing while better preserving some image structures.

It must not automatically replace Gaussian filtering.

The choice of filter must depend on the observed noise characteristics.

---

## 5. Thresholding

Thresholding is one of the main segmentation approaches covered by the course and represents the initial segmentation family for this project.

---

### 5.1 Global Thresholding

Allowed.

A single threshold is applied to the image or region being analyzed.

General form:

```text
f(x,y) > T
```

or the corresponding inverse condition depending on the intensity characteristics of the target region.

A global threshold should generally be tested before introducing more complex methods.

---

### 5.2 Iterative Thresholding

Allowed.

The iterative thresholding procedure covered by the course may be implemented by:

1. selecting an initial threshold;
2. separating pixels into two groups;
3. computing the mean intensity of each group;
4. computing a new threshold from the two means;
5. repeating the procedure until convergence.

This method may be compared with Otsu thresholding.

---

### 5.3 Otsu Thresholding

Allowed.

MATLAB functionality:

```matlab
graythresh
imbinarize
```

Otsu's method selects a threshold by minimizing intra-class variance.

It should be used only where a global threshold is meaningful for the observed intensity distribution.

---

### 5.4 Multiple Thresholding

Allowed.

MATLAB functionality covered by the course includes:

```matlab
multithresh
imquantize
```

This approach may be useful when the intensity histogram contains more than two relevant classes.

It should not be introduced unless the data analysis indicates that binary global thresholding is insufficient.

---

### 5.5 Variable / Local Thresholding

Allowed.

A spatially variable threshold may be considered when a single global threshold cannot provide satisfactory segmentation across the image.

The course presents local thresholding based on local image statistics such as:

- neighborhood mean;
- neighborhood standard deviation.

This is a more complex alternative and should not be part of the initial baseline.

---

## 6. Mathematical Morphology

Binary mathematical morphology is allowed.

Morphological processing must be applied with caution because multiple-sclerosis lesions may be small.

Every morphological operation must have a specific purpose.

---

### 6.1 Structuring Elements

Allowed.

MATLAB functionality includes:

```matlab
strel
```

The following characteristics must always be documented:

- shape;
- size;
- reason for the selected structuring element.

---

### 6.2 Erosion

Allowed.

MATLAB functionality:

```matlab
imerode
```

Possible uses:

- shrink binary regions;
- remove thin structures;
- separate weakly connected regions.

Potential risk:

- removal of small lesion regions.

---

### 6.3 Dilation

Allowed.

MATLAB functionality:

```matlab
imdilate
```

Possible uses:

- enlarge binary regions;
- reconnect nearby structures;
- compensate for previous erosion.

Potential risk:

- merge nearby regions.

---

### 6.4 Opening

Allowed.

Opening consists of:

```text
erosion
   ↓
dilation
```

MATLAB functionality:

```matlab
imopen
```

Possible uses:

- remove small unwanted structures;
- break narrow connections;
- smooth binary regions.

Small components must not automatically be considered noise.

---

### 6.5 Closing

Allowed.

Closing consists of:

```text
dilation
   ↓
erosion
```

MATLAB functionality:

```matlab
imclose
```

Possible uses:

- close small gaps;
- connect nearby structures;
- smooth region boundaries.

---

### 6.6 Morphological Reconstruction

Allowed.

MATLAB functionality covered by the course includes:

```matlab
imreconstruct
```

Morphological reconstruction may be considered as an advanced morphological refinement.

It is not required for the baseline pipeline.

---

### 6.7 Hole Filling

Allowed.

MATLAB functionality:

```matlab
imfill
```

Hole filling may be used to fill internal holes in binary masks, particularly during brain-mask refinement, when justified.

---

### 6.8 Thinning and Skeletonization

Allowed, narrowly scoped.

Thinning and skeletonization are covered by the course; the course material shows MATLAB `bwmorph` with the `'skel'` and `'thin'` operations. (Coverage confirmed by the user against the course material when EXP-015 was requested, 2026-10-06.)

MATLAB functionality:

```matlab
bwmorph(BW, 'skel', Inf)
```

Current project use: EXP-015 (Phase 50) uses `bwmorph(..., 'skel', Inf)` only to thin a background-marker candidate for marker-controlled watershed, as in the course marker-controlled watershed workflow (dark background pixels, thinned by skeletonization so that the marker stays away from object edges).

This does NOT automatically authorize arbitrary skeleton-based processing (pruning, skeleton-based shape analysis, use in other pipeline stages) without separate justification.

---

## 7. Connectivity and Connected Components

Connected-component analysis is allowed and is expected to be particularly useful for lesion candidate analysis.

---

### 7.1 Pixel Connectivity

Allowed.

Connectivity concepts may be used to determine whether pixels belong to the same binary region.

The selected connectivity must be explicitly documented when relevant.

---

### 7.2 Connected Components

Allowed.

MATLAB functionality:

```matlab
bwconncomp
```

Connected components may be used to:

- identify individual candidate regions;
- count regions;
- access the pixels belonging to each region;
- support lesion-level analysis.

The course material explicitly uses properties such as:

```text
Connectivity
ImageSize
NumObjects
PixelIdxList
```

---

### 7.3 Region Labeling

Allowed.

MATLAB functionality may include:

```matlab
bwlabel
```

Labeling may be used when individual binary regions need to be represented with different integer labels.

---

## 8. Region Properties

Allowed.

MATLAB functionality:

```matlab
regionprops
```

Possible properties include course-compatible measurements such as:

- area;
- centroid;
- bounding box.

Other properties must not automatically be introduced simply because MATLAB provides them.

If additional properties are needed, their use should first be justified and checked against the course material.

For the initial implementation, prefer `regionprops` over introducing `regionprops3`.

`regionprops3` is not currently part of the verified course-technique list.

If size-based component analysis becomes necessary, the project should initially use the already allowed connected-component functionality, such as `bwconncomp` and `regionprops`.

`bwareaopen` is not currently part of the allowed list.

---

## 9. Region Growing

Region growing is allowed.

It is a region-based segmentation technique covered during the course.

The method is based on:

- one or more seeds;
- a similarity predicate;
- connectivity;
- progressive inclusion of neighboring pixels satisfying the predicate.

Possible project use:

```text
high-confidence lesion candidate
            ↓
           seed
            ↓
     region growing
            ↓
extended lesion candidate
```

Important constraints for this project:

- seeds must be generated automatically;
- lesion ground truth must never be used to generate seeds;
- the similarity predicate must be explicitly defined;
- region growing should only be added if thresholding identifies lesion cores but fails to recover their complete extent.

Region growing is optional and is not part of the initial baseline.

---

## 10. Edge Detection

Edge-based segmentation techniques are covered by the course and are therefore allowed in principle.

Verified techniques include:

- Roberts;
- Prewitt;
- Sobel;
- Laplacian-based approaches;
- Laplacian of Gaussian;
- Canny edge detection.

These methods are NOT currently part of the planned lesion-segmentation baseline.

They should only be introduced if an experimentally observed problem requires explicit boundary information.

They must not be added simply because they are available.

Experiment-specific note: EXP-016 (Phase 50) uses automatic 2D Canny (`edge(I, 'Canny')`, MATLAB-selected thresholds, one configuration) on the T1 brain-mask source, because EXP-011 to EXP-015 identified explicit brain/periphery boundary information as the remaining brain-mask problem. This note does not authorize inter-slice propagation or 3D processing.

Experiment-specific note: EXP-017 (Phase 50) combines course-supported Canny (EXP-016 map, unchanged) with one binary closing (`imclose`, `strel('square',3)`), connected components and hole filling to test the conversion of detected contours into a region. This does not authorize inter-slice or 3D processing.

Experiment-specific note (EXP-018, Phase 50; explicitly authorized by the user on 2026-10-06 after the independent-2D branch EXP-010..017 reached a strong limitation): slice-to-slice propagation of the brain-support mask. Every operation remains 2D and course-supported (`imerode`, `imdilate`, morphological gradient, `imimposemin`, `watershed`, `imfill`), but slice k uses the accepted mask of the adjacent slice k±1 to build its markers. The propagation scheme itself is not verified as a course technique; it is a project design decision. The same authorization covers EXP-019 (same scheme, asymmetric erosion/dilation radii) and EXP-020 (EXP-019 with watershed ridge pixels assigned to the foreground), requested by the user on 2026-10-06. This does NOT authorize 3D structuring elements, 3D filters, 3D connected components or other uses of inter-slice information.

Experiment-specific exception (EXP-021, Phase 50; explicitly authorized by the user on 2026-10-06 as an exploratory test): 3D erosion and dilation with `strel('sphere', r)`, 3D connected components (`bwconncomp(..., 26)`) and selection of the largest 3D component on the T1 raw Otsu mask. This is a **volumetric extension of 2D techniques present in the course slides** (erosion, dilation, connected components, largest region, hole filling); volumetric processing itself is **not** treated in the course PDF (the course skull-removal exercise on `t1.nii` works on a single layer, and `bwconncomp` is presented with 2D connectivity). It is documented as exploration; it does not authorize 3D processing in any other pipeline stage.

---

## 11. Watershed Segmentation

Watershed segmentation is covered by the course and is allowed in principle.

The course also discusses problems such as oversegmentation and marker-based approaches.

Watershed is NOT part of the initial project pipeline.

It should only be considered if region separation becomes a specific problem that cannot be solved adequately using the simpler planned methods.

---

## 12. Techniques Preferred for the Initial Project

The techniques most directly relevant to the first implementation are:

```text
Intensity analysis
        ↓
Histograms
        ↓
Optional smoothing
        ↓
Brain-mask extraction
        ↓
Thresholding
        ↓
Binary morphology
        ↓
Connected components
        ↓
Region properties
```

The initial candidate MATLAB functions therefore include:

```matlab
graythresh
imbinarize

fspecial
imfilter
imgaussfilt
medfilt2

strel
imerode
imdilate
imopen
imclose

bwconncomp
bwlabel
regionprops
```

This is not a requirement to use every function.

---

## 13. Techniques Available as Later Extensions

The following course-compatible techniques should be considered only after the baseline has been evaluated:

```text
Multiple thresholding
Variable/local thresholding
Morphological reconstruction
Region growing
Edge-based segmentation
Watershed segmentation
```

They require an explicit experimental justification before being incorporated into the final pipeline.

---

## 14. Techniques Not Automatically Allowed

Claude Code or any other development tool must NOT introduce new image-processing techniques that are absent from this document without explicit review.

Examples include:

- clustering-based segmentation;
- k-means segmentation;
- fuzzy c-means;
- graph-cut segmentation;
- active contours;
- level-set segmentation;
- superpixels;
- machine-learning classifiers;
- Deep Learning;
- pretrained segmentation models.

This does not necessarily mean that every classical technique in this list is absent from the scientific literature or unsuitable in general.

It means that these techniques are outside the currently verified course-based project scope unless explicitly reviewed and approved.

---

## 15. Evaluation Metrics Are Separate from Segmentation Techniques

The quantitative evaluation metrics planned for the project include:

- Dice coefficient;
- IoU / Jaccard;
- Precision;
- Recall / Sensitivity;
- Specificity;
- lesion volume error.

These metrics are used to evaluate the predicted segmentation against the BrainWeb ground truth.

They must NOT be interpreted as segmentation techniques.

The currently reviewed course slides do not provide the main methodological basis for these evaluation metrics.

Their inclusion is motivated by the need to quantitatively evaluate the segmentation against the available ground truth.

---

## 16. Ground Truth Restriction

No technique listed in this document may use the lesion ground truth to generate the segmentation.

The following is allowed:

```text
MRI
 ↓
Image Processing
 ↓
Predicted Mask
 ↓
Evaluation against Ground Truth
```

The following is forbidden:

```text
Ground Truth
     ↓
threshold selection / seed selection /
candidate removal / segmentation correction
     ↓
Predicted Mask
```

---

## 17. Implementation Rule for AI-Assisted Development

Before introducing an Image Processing technique, the implementation must answer:

1. Is the technique included in this document?
2. What observed problem does it solve?
3. Is a simpler technique already sufficient?
4. What parameter or parameters does it introduce?
5. How will its contribution be evaluated?

If the technique is not listed in this document, implementation must stop until the technique has been manually reviewed.

This restriction applies to image-processing and segmentation techniques that affect the generated segmentation.

It does NOT require the following utility functions to be individually listed in this document:

- file loading/saving;
- datatype inspection;
- assertions and validation;
- plotting and visualization;
- experiment logging;
- general MATLAB programming.

However, utility functions must not introduce hidden segmentation logic.

Claude Code must not autonomously expand the algorithm beyond the techniques and constraints defined here and in `PROJECT_SPEC.md`.

---

## 18. Core Principle

The final pipeline should contain the minimum number of processing stages necessary to obtain a meaningful and interpretable segmentation.

More processing steps do not automatically imply a better Image Processing project.

Every final processing stage must be both:

```text
theoretically justified
        +
experimentally justified
```