# RVF_Mauritania
Repository for modeling of Rift Valley Fever (RVF) in Mauritania.  

The analysis includes
- calculation of potential risk areas (suitability maps), depending on environmental conditions and
- calculation of spillover potential, depending on the suitability maps and livestock and animal data.

## Calculation of potential risk areas
- Tool for Analysis: [Maxent](https://biodiversityinformatics.amnh.org/open_source/maxent/)
  - Used within GRASS GIS
  - Installation with [`r.maxent.setup`](https://grass.osgeo.org/grass-stable/manuals/addons/r.maxent.setup.html):
    - Note: need to have java installed
- Analysis
  - Define configuration file: [potential_risk_areas_config.cfg](config/potential_risk_areas_config.cfg)
  - Train model: [potential_risk_areas_train.sh](src/potential_risk_areas_train.sh)
  - Apply model: [potential_risk_areas_predict.sh](src/potential_risk_areas_predict.sh)

### Analysis procedure:
#### Input
- Prepared disease data and covariates
- Defined within [config](config/potential_risk_areas_config.cfg)
- For different data versions see table [potential_risk_areas_data_versions](potential_risk_areas_data_versions.md)

#### Train model:
- Script: [potential_risk_areas_train.sh](src/potential_risk_areas_train.sh)
- AOI/Region setting
  - Use all given positive and negative samples -> AOI defined by them (Covariates only sampled at negative/positive result coordinates)
- Model options: Usage of monthly disease data
  - Option 1: single model
    - Combine all given positive and negative samples from all months/years
    - Sample covariates for all given positive and negative results (i.e. create monhtly SWD files) and combine them --> use this as input to train one single model
  - Option 2: monthly models
    - Train monthly models (for which enough positive (and negative) samples given)
  - For different model versions see table [potential_risk_areas_model_versions](potential_risk_areas_model_versions.md)
#### Apply model
- Script: [potential_risk_areas_predict.sh](src/potential_risk_areas_predict.sh)
- Apply model to all monthly data
  - From 2019-2023, see also `PREDICTION` section within [config](config/potential_risk_areas_config.cfg)
    

## Calculation of spillover potential
The spillover potential calculation follows [Hardcastle et al. 2020](https://doi.org/10.1016/j.ijid.2020.07.043) with two differences:
- the geographic units are not administrative areas but pixels
- livestock movement from [Jahel et al. 2020](https://doi.org/10.1038/s41598-020-65132-8) is included

The main script is [spillover_risk.sh](src/spillover_risk.sh) which includes livestock movement:
the number of animals per pixel is increased with increasing movement through a pixel to simulate more contacts between animals.

Input data for the spillover risk calculation are
- potential risk calculated with maxent for each month separately (see above)
- human population per pixel
- livestock population per pixel
- livestock movement, separately for the dry and wet season
