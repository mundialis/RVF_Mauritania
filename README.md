# RVF_Mauritania
Repository for modeling of Rift Valley Fever (RVF) in Mauritania

## Potential Risk Areas
- Tool for Analysis: [Maxent](https://biodiversityinformatics.amnh.org/open_source/maxent/)
  - used within GRASS GIS
  - Installation with `r.maxent.setup`:
    - Note: need to have java installed
- Analysis
  - In short (details see below):
    - Define configuration file: [potential_risk_areas_config.cfg](config/potential_risk_areas_config.cfg)
    - Train Model: [potential_risk_areas_train.sh](src/potential_risk_areas_train.sh)
    - Apply Mode: [potential_risk_areas_predict.sh](src/potential_risk_areas_predict.sh)
  - Input: prepared Disease Data and Covariates
    - defined within [config](config/potential_risk_areas_config.cfg)
    - see also table in section [Data Versions](#data-versions)
  - Analysis procedure:
    - Train model:
      - Script: [potential_risk_areas_train.sh](src/potential_risk_areas_train.sh)
      - AOI/Region Setting
        - use all given positive and negative samples -> AOI defined by them (Covariates only sampled at negative/positive result coordinates)
        - in future following could be further tested/investigated (optional)
          - only give positive samples -> negative samples will be sampled as background points by MaxEnt tool
            - analyse impact of different region settings (e.g. only area buffered around given positive samples vs. complete Mauretania, ...)
      - Model options: Usage of monthly disease data
        - Option 1: Single Model
          -  Combine all given positive and negative samples from all months/years
          - Sample Covariates for all given positive and negative results (i.e. create monhtly SWD files) and combine them --> use this as input to train one single model
        - Option 2: Monthly Models
          - train monthly models (for which enough positive (and negative) samples given)
        - Note: see also table in section [Model Versions](#model-versions)
    - Apply model
      - Script: [potential_risk_areas_predict.sh](src/potential_risk_areas_predict.sh)
      - apply model to all monthly data
        - from 2019-2023, see also `PREDICTION` section within [config](config/potential_risk_areas_config.cfg)
    - Further analysis ideas
      - Finetune Input - Approach:
        - Covariates
          - first use all (previous selected) covariates
          - then iterative removal of non useful datasets
          - use feature importance e.g. jackknife plots
          - Note: partially already done (see [Data Versions](#data-versions))
        - Features/Mathematical transformations (done by Maxent)
          - amount, selection, ...
          - see parameters from `r.maxent.train`: `lq2lqptthreshold`, `l2lqthreshold`, `hingethreshold` and flags `l,q,p,t,h,a`
        - Note: if multiple models (i.e. monhtly models used), has to be done for each of them

### Data Versions

Data (or rather SWD files) in: `/mnt/projects/mood/RVF_Mauritania/maxent/SWD_files`

| Data version (dv) | Input | Notes |
| - | - | - |
|  - | precipitation (current month + 1 month previous + 2 month previous), <br/> lst day and night, <br/> NDVI, <br/> NDWI, <br/> soil moisture, <br/> water bodies (categorical) | not versioned; used for first tests with october 2020 model; <br/>  corresponds to SWD files `bgr_10_2020` and `species_10_2020` |
| 01 | precipitation (current month + 1 month previous + 2 month previous), <br/> lst day and night, <br/> NDVI, <br/> NDWI, <br/> distance to waterr bodies | |
| 02 | as 01 but without distance to water bodies | |

### Model Versions

Model results in : `/mnt/projects/mood/RVF_Mauritania/maxent/models/`

|Model version | Used data version | Training presence samples | Training all samples (background and presence) | Description | Notes |
| - | - | - | - | - | - |
| - | - | 53/46 | 187/182 | not versioned; first tests with october 2020 model; <br/> results within `model_10_2020` and with test data splitted `model_10_2020_with_testdata`| |
| 01 | 01 | 152 | 752 | single model with all disease data combined | variable contribution: ca. 70 % impact of current precipitation |
| 02 | 01 | dependent on month | dependent on month | monthly models (for each month with at least one single positive sample) | for monthly models very different results when applying model + within variable contribution; mostly precipitation driving factor of model |
| 03 | 02 | 53 | 187| monthly model, only for octobre 2020 | variable contribution: roughly 40 % for 2 month prior and 40 % for 1 month prior precipitation |
| 04 | 02 | 152 | 752 | single model with all disease data combined | variable contribution: ca. 80 % impact of current precipitation|
| 05 | 02 | 132| 437 | single model with 09/10 2020 and 09/10 2022 data combined (the four month with the most positive disease data) | variable contribution: 30 % lst night, 30 % current month precipitation <br/> application results has a lot of round/circle structures with strong borders of change in risk (coming from precipitation) |
| 06 | 02 | 282 | 820| as mv04, but keep duplicates during training| less strong impact of current precipitation on model (ca. 45 %), followed by precipitation 1 month prior (20 %) and 2 month prior (14 %) <br/> keeping duplicates during training results in less strong changes in risk (in some month e.g. 05-2020, 06-2020, ... ) compared to mv04 |
| 07 | 02 | 232 | 487| as mv05, but keep duplicates during training | precipitation 2 month prior strongest impact on model (ca. 50 %) <br/> similar geometric patterns (coming from precipitation) as in mv05|


Notes:
- when using all data: current month precipitation mostly major driver of model
- for monthly models it depends (10-2020: seems to deliver "good" results -> 2 month prior precipitation large driver, but not the only driver)
- keeping duplicates makes difference on model results -> no clear indication if results better/or worse, or rather dependent on model version
- Best results so far:
  - "Best" means: model is not mainly driven by single Covariate + application to 2020 looks reasonable (no strong risk change "borders", geometric features/artefacts (?), ...)
  - **mv03** or **mv06** (but differences between them; mv06 eventually more reliable, cause more data used for training, compared to mv03)
