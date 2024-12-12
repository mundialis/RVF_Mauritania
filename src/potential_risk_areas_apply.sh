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
    # TODO: check model output name --> (and if all species data used)
    # TODO: for testing: only smaller time range (config)
    r.maxent.predict \
        lambdafile=${OUT_MODEL}/${SPECIES_MAP//MONTH_YEAR/${MONTH}_${YEAR}}.lambdas \
        rasters=${PREC_CURR//YEAR_MONTH/${YEAR}_${MONTH}},\
          ${PREC_1M//YEAR_MONTH/${OMP_YEAR}_${OMP_MONTH}},\
          ${PREC_2M//YEAR_MONTH/${TMP_YEAR}_${TMP_MONTH}},\
          ${LST_D//YEAR_MONTH/${YEAR}_${MONTH}},\
          ${LST_N//YEAR_MONTH/${YEAR}_${MONTH}},\
          ${NDVI//YEAR_MONTH/${YEAR}_${MONTH}},\
          ${NDWI//YEAR_MONTH/${YEAR}_${MONTH}},\
          # ${SM//YEAR_MONTH/${YEAR}_${MONTH}},\
          ${DIST_TO_WB//YEAR_MONTH/${YEAR}_${MONTH}} \
        variables=${PREC_CURR_MAP//YEAR_MONTH/${YEAR}_${MONTH}},\
          ${PREC_1M_MAP/${OMP_YEAR}_${OMP_MONTH}},\
          ${PREC_2M_MAP/${TMP_YEAR}_${TMP_MONTH}},\
          ${LST_D_MAP//YEAR_MONTH/${YEAR}_${MONTH}},\
          ${LST_N_MAP//YEAR_MONTH/${YEAR}_${MONTH}},\
          ${NDVI_MAP//YEAR_MONTH/${YEAR}_${MONTH}},\
          ${NDWI_MAP//YEAR_MONTH/${YEAR}_${MONTH}},\
          # ${SM_MAP//YEAR_MONTH/${YEAR}_${MONTH}},\
          ${DIST_TO_WB_MAP//YEAR_MONTH/${YEAR}_${MONTH}} \
        output=model_${MONTH}_${YEAR}
    
    # next month: for next iteration
    DATE_TMP=$(date -I -d "$DATE_TMP + 1 month"); 
done
