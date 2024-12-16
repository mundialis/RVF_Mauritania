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

|Model version | Used data version | Description | Notes |
| - | - | - | - |
| - | - | not versioned; first tests with october 2020 model; <br/> results within `model_10_2020` and with test data splitted `model_10_2020_with_testdata`| |
| 01 | 01 | single model with all disease data combined | variable contribution: ca. 70 % impact of current precipitaion |
| 02 | 01 | monthly models (for each month with at least single positive sample) | very different results when applying model + within variable contribution; mostly precipitation driving factor or model |
| 03 | 02  <br/> (presence samples: 53, All samples: 187)| monhtly model, only for octobre 2020 | variable contribution: roughly 40 % for 2 month prior and 40 % for 1 month prior precipitation |
| 04 | 02 <br/> (presence samples: 152, All samples: 752) | single model with all disease data combined | variable contribution: ca. 80 % impact of current precipitaion|
| 05 | 02 <br/> (presence samples: 132, All samples: 437) | single model with 09/10 2020 and 09/10 2022 data combined (the month with the most positive disease data) | variable contribution: 30 % lst night, 30 % current month precipitation <br/> application results has a lot of round/circle structures with strong borders of change in risk |
| 06 | 02 <br/> (presence samples: 282, All samples: 820)| as mv04, but keep duplicates during training| less strong impact of current precipitation on model (ca. 45 %), followed by precipitation 1 month prior (20 %) and 2 month prior (14 %) <br/> keeping duplicates during training results in less strong changes in risk (in some month e.g. 05-2020, 06-2020, ... ) compared to mv04 |
| 07 | 02 <br/> (presence samples: 232, All samples: 487)| as mv05, but keep duplicates during training | precipitation 2 month earlier strongest impact on model (ca. 50 %) <br/> similar strange geometric patterns as in mv05|


Notes:
- when using all data: current month precipitation major driver of model
- for monthly models it depends (10-2020: seems to deliver "good" results -> 2 month prior precipitation large driver, but not the only driver)
- keeping duplicates makes difference on model results -> no clear indication if results better/or worse, or rather dependent on model version
- Best results so far: mv03 or mv06 (but differences between them)
  - "Best": model is not mainly driven by single Covariate + application to 2020 looks reasonable (no strong risk change "borders", geometric features/artefacts (?), ...) 
