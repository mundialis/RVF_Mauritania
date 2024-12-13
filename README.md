# RVF_Mauritania
Repository for modeling of Rift Valley Fever (RVF) in Mauritania

## Potential Risk Areas
- Tool for Analysis: [Maxent](https://biodiversityinformatics.amnh.org/open_source/maxent/)
  - used within GRASS GIS: 
    - `r.maxent.setup`:
      - Note: need to have java installed
- Analysis
  - Input: prepared Disease Data and Covariates
    - ? TODO: short description of concrete input + how prepared (resmapling, ..)
    - TODO:
      - instead of binary water bodies, use distance to water bodies (e.g. with `r.grow.distance`)
      - neglect/don't use soil moisture
  - Analysis Procedure:
    - Train Model:
      - AOI/Region Setting
        - use all given positive and negative samples -> AOI defined by them (Covariates only sampled at negative/positive result coordinates)
        - in future following could be further tested/investigated (optional)
          - only give positive samples -> negative samples will be sampled as background points by MaxEnt tool
            - analyse impact of different region settings (e.g. only area buffered around given positive samples vs. complete Mauretania, ...)
      - Combine all given positive and negative samples from all months/years
        - Sample Covariates for all given positive and negative results (i.e. create monhtly SWD files) and combine them --> use this as input to train one single model
          - TODO:
            - check for balanced dataset -> approx. same number of positive and negative samples
            - compare result with single month trained model (i.e. october 2020 modell)
        - Optional/further ideas:
          - train monthly models (for which enough positive (and negative) samples given) + apply to all data + average results
    - Apply Model
      - apply model to all monthly data (from 2019-2023)
    - Creation of binary maps
      - TODO: Define/Compute threshold for creation of binary potential risk maps
        - e.g. check Maxent html-output: Table with Cloglog threshold for various "common threshold" with corresponding omission rate
          - Explanation to graphs (from tutorial): "This allows the program to do some simple statistical analysis. Much of the analysis used the use of a **threshold to make a binary prediction, with suitable conditions predicted above the threshold and unsuitable below**. The first plot shows how testing and training omission and predicted area vary with the choice of cumulative threshold"
          - see also paper [Phillips, S.J., R.P. Anderson, and R.E. Schapire. 2006. Maximum entropy modeling of
species geographic distributions. Ecological Modelling](https://www.whoi.edu/cms/files/phillips_etal_2006_53467.pdf)
          - Notes:
            - Omission and Comission Error: Metric for classification results (dependent on TruePositives, FalsePositives, ...)
            - p-value (only if test data given) -> statistical significance
    - Optional further Analysis
      - Finetune set of covariates - Approach:
        - first use all (previous selected) covariates
        - then iterative removal of non useful datasets
          - use feature importance e.g. jackknife plots
        - Additional: check features/mathematical transformations (done by Maxent) -> amount, selection, ...
          - see parameters from `r.maxent.train`: `lq2lqptthreshold`, `l2lqthreshold`, `hingethreshold` and flags `l,q,p,t,h,a`
      - Note: if multiple models (i.e. monhtly models used), has to be done for each of them

### Versions

Data (or rather SWD files) in: `/mnt/projects/mood/RVF_Mauritania/maxent/SWD_files`

| Data version (dv) | Input | Notes |
| - | - | - |
|  - | precipitation (current month + 1 month previous + 2 month previous), <br/> lst day and night, <br/> NDVI, <br/> NDWI, <br/> soil moisture, <br/> water bodies (categorical) | not versioned; used for first tests with october 2020 model; <br/>  corresponds to SWD files `bgr_10_2020` and `species_10_2020` |
| 01 | precipitation (current month + 1 month previous + 2 month previous), <br/> lst day and night, <br/> NDVI, <br/> NDWI, <br/> distance to waterr bodies | |
| 02 | as 01 but without distance to water bodies | |

Model results in : `/mnt/projects/mood/RVF_Mauritania/maxent/models/`

|Model version | Used data version | Description |
| - | - | - |
| - | - | not versioned; first tests with october 2020 model; <br/> results within `model_10_2020` and with test data splitted `model_10_2020_with_testdata`|
| 01 | 01 | single model with combined disease data |
| 02 | 01 | monthly models (for each month with at least single positive sample) |
| 03 | 02 | monhtly model, only for octobre 2020 |
