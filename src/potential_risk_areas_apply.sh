#!/bin/bash

# TODO: header

# ---------------------
# CONFIGURATION
# ---------------------

if [ "$#" -ne 1 ]; then
    echo -e "ERROR: Missing configfile.\nUsage: potential_risk_areas_apply.sh /path/to/config.cfg"
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

    # apply model
    # Note: removed soil moisture: ${SM//YEAR_MONTH/${YEAR}_${MONTH}},
    r.maxent.predict \
        lambdafile=${OUT_MODEL}/${SPECIES_MAP//MONTH_YEAR/combined}.lambdas \
        rasters=${PREC_CURR//YEAR_MONTH/${YEAR}_${MONTH}},\
${PREC_1M//YEAR_MONTH/${OMP_YEAR}_${OMP_MONTH}},\
${PREC_2M//YEAR_MONTH/${TMP_YEAR}_${TMP_MONTH}},\
${LST_D//YEAR_MONTH/${YEAR}_${MONTH}},\
${LST_N//YEAR_MONTH/${YEAR}_${MONTH}},\
${NDVI//YEAR_MONTH/${YEAR}_${MONTH}},\
${NDWI//YEAR_MONTH/${YEAR}_${MONTH}},\
${DIST_TO_WB//YEAR_MONTH/${YEAR}_${MONTH}} \
        variables=ERA5_land_monthly_prectot_sum_30sec_2020_01_01T00_00_00,ERA5_land_monthly_prectot_sum_30sec_2019_12_01T00_00_00,ERA5_land_monthly_prectot_sum_30sec_2019_11_01T00_00_00,lst_day_monthly_2020_01_1km,lst_night_monthly_2020_01_1km,ndvi_filt_2020_01_01T00_00_00,ndwi_veg_monthly_2020_01_1km,dist_to_wb_2020_01 \
        output=model_${MONTH}_${YEAR} --o --v
#         ${PREC_CURR_MAP//YEAR_MONTH/${YEAR}_${MONTH}},\
# ${PREC_1M_MAP//YEAR_MONTH/${OMP_YEAR}_${OMP_MONTH}},\
# ${PREC_2M_MAP//YEAR_MONTH/${TMP_YEAR}_${TMP_MONTH}},\
# ${LST_D_MAP//YEAR_MONTH/${YEAR}_${MONTH}},\
# ${LST_N_MAP//YEAR_MONTH/${YEAR}_${MONTH}},\
# ${NDVI_MAP//YEAR_MONTH/${YEAR}_${MONTH}},\
# ${NDWI_MAP//YEAR_MONTH/${YEAR}_${MONTH}},\
# ${DIST_TO_WB_MAP//YEAR_MONTH/${YEAR}_${MONTH}} \
    
    # next month: for next iteration
    DATE_TMP=$(date -I -d "$DATE_TMP + 1 month"); 
done
