#!/bin/bash

############################################################################
#
# MODULE:      potential_risk_areas_predict.sh
# AUTHOR(S):   Victoria-Leandra Brunn, Lina Krisztian
#
# PURPOSE:     Processing script for prediction of Maxent model
# COPYRIGHT:   (C) 2024 by mundialis GmbH & Co. KG
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
#############################################################################

# ---------------------
# CONFIGURATION
# ---------------------

if [ "$#" -ne 1 ]; then
    echo -e "ERROR: Missing configfile.\nUsage: potential_risk_areas_predict.sh /path/to/config.cfg"
    exit 1
fi

# source config
CONFFIGFILE=$1


# Check and if given source the config
if [ -f "${CONFFIGFILE}" ]; then
  source "${CONFFIGFILE}"
else
  echo "Required config file ${CONFFIGFILE} does not exist."
  exit 1
fi

# check variables
if [ -z "$STARTDATE" ] ; then
  echo "ERROR: STARTDATE is not set"
  exit 1
fi

if [ -z "$ENDDATE" ] ; then
  echo "ERROR: ENDDATE is not set"
  exit 1
fi

# Note: for precipitation data 2 months prior are need therefore
#       earliest analysis month March 2019 (STARTDATE + 2 month)
DATE_TMP=$(date -I -d "$STARTDATE + 2 month")
# stopdata: enddate + 1 month,
# so that enddate is calculated within while loop in last iteration
STOPDATE=$(date -I -d "$ENDDATE + 1 month")

# ---------------------
# PROCESSING
# ---------------------

g.region raster=aoi_buf_rast@RVF_Mauritania -p
r.mask -r
r.mask raster=aoi_buf_rast@RVF_Mauritania

while [ "$DATE_TMP" != ${STOPDATE} ]; do    
    DATE_SPLIT=(${DATE_TMP//-/ })
    MONTH=${DATE_SPLIT[1]}
    YEAR=${DATE_SPLIT[0]}

    # selection of:
    # one month prior
    DATE_1_PRIOR=$(date -I -d "$DATE_TMP - 1 month"); DATE_SPLIT=(${DATE_1_PRIOR//-/ }); 
    OMP_YEAR=${DATE_SPLIT[0]}; OMP_MONTH=${DATE_SPLIT[1]}; 
    # two month prior
    DATE_2_PRIOR=$(date -I -d "$DATE_TMP - 2 month"); DATE_SPLIT=(${DATE_2_PRIOR//-/ });
    TMP_YEAR=${DATE_SPLIT[0]}; TMP_MONTH=${DATE_SPLIT[1]}; 

    # TODO: 
    # for dist to water bodies: data for 2023-04 are missing, since they are not available from CLMS
    # -> e.g. use previous month in this case

    # apply model
    # Note: removed:
    # - soil moisture: ${SM//YEAR_MONTH/${YEAR}_${MONTH}},
    if [ ${MODEL_V} -eq "01" ] || [ ${MODEL_V} -eq "02" ]; then
      RASTERS="${PREC_CURR//YEAR_MONTH/${YEAR}_${MONTH}},\
${PREC_1M//YEAR_MONTH/${OMP_YEAR}_${OMP_MONTH}},\
${PREC_2M//YEAR_MONTH/${TMP_YEAR}_${TMP_MONTH}},\
${LST_D//YEAR_MONTH/${YEAR}_${MONTH}},\
${LST_N//YEAR_MONTH/${YEAR}_${MONTH}},\
${NDVI//YEAR_MONTH/${YEAR}_${MONTH}},\
${NDWI//YEAR_MONTH/${YEAR}_${MONTH}},\
${DIST_TO_WB//YEAR_MONTH/${YEAR}_${MONTH}}"
      VARIABLES=ERA5_land_monthly_prectot_sum_30sec_2020_01_01T00_00_00,ERA5_land_monthly_prectot_sum_30sec_2019_12_01T00_00_00,ERA5_land_monthly_prectot_sum_30sec_2019_11_01T00_00_00,lst_day_monthly_2020_01_1km,lst_night_monthly_2020_01_1km,ndvi_filt_2020_01_01T00_00_00,ndwi_veg_monthly_2020_01_1km,dist_to_wb_2020_01_scaled
    elif [ ${MODEL_V} -eq "03" ]; then
    RASTERS="${PREC_CURR//YEAR_MONTH/${YEAR}_${MONTH}},\
${PREC_1M//YEAR_MONTH/${OMP_YEAR}_${OMP_MONTH}},\
${PREC_2M//YEAR_MONTH/${TMP_YEAR}_${TMP_MONTH}},\
${LST_D//YEAR_MONTH/${YEAR}_${MONTH}},\
${LST_N//YEAR_MONTH/${YEAR}_${MONTH}},\
${NDVI//YEAR_MONTH/${YEAR}_${MONTH}},\
${NDWI//YEAR_MONTH/${YEAR}_${MONTH}},\
${DIST_TO_WB//YEAR_MONTH/${YEAR}_${MONTH}}"
      VARIABLES=ERA5_land_monthly_prectot_sum_30sec_2020_10_01T00_00_00,ERA5_land_monthly_prectot_sum_30sec_2020_09_01T00_00_00,ERA5_land_monthly_prectot_sum_30sec_2020_08_01T00_00_00,lst_day_monthly_2020_10_1km,lst_night_monthly_2020_10_1km,ndvi_filt_2020_10_01T00_00_00,ndwi_veg_monthly_2020_10_1km
    else
      RASTERS="${PREC_CURR//YEAR_MONTH/${YEAR}_${MONTH}},\
${PREC_1M//YEAR_MONTH/${OMP_YEAR}_${OMP_MONTH}},\
${PREC_2M//YEAR_MONTH/${TMP_YEAR}_${TMP_MONTH}},\
${LST_D//YEAR_MONTH/${YEAR}_${MONTH}},\
${LST_N//YEAR_MONTH/${YEAR}_${MONTH}},\
${NDVI//YEAR_MONTH/${YEAR}_${MONTH}},\
${NDWI//YEAR_MONTH/${YEAR}_${MONTH}}"
      VARIABLES=prec_curr,prec_1m,prec_2m,lst_d,lst_n,ndvi,ndwi
    fi
    if [ ${SING_MOD} -eq 1 ]; then
      r.maxent.predict \
          lambdafile=${OUT_MODEL}/${SPECIES_MAP//MONTH_YEAR/combined}.lambdas \
          rasters=${RASTERS} \
          variables=${VARIABLES} \
          output=model_${MONTH}_${YEAR}_mv${MODEL_V} --o --v
    else
      # Note: loop over monthly models, which should be applied
      # (check reasonable models with html output of maxent)
      # for model version 03:
      # for MODEL_DATE in "10_2020"; do
      for MODEL_DATE in "11_2020" "08_2022" "10_2022" "09_2020" "09_2022" "10_2020"; do
        r.maxent.predict \
          lambdafile=${OUT_MODEL}/${SPECIES_MAP//MONTH_YEAR/${MODEL_DATE}}.lambdas \
          rasters=${RASTERS} \
          variables=${VARIABLES} \
          output=model_${MONTH}_${YEAR}_monthmodel_${MODEL_DATE}_mv${MODEL_V} --o --v
      done
    fi
    
    # next month: for next iteration
    DATE_TMP=$(date -I -d "$DATE_TMP + 1 month"); 
done
