# ---------------------
# READ CONFIG
# ---------------------

if [ "$#" -ne 1 ]; then
    echo -e "ERROR: Missing configfile.\nUsage: main.sh /path/to/config.cfg"
    exit 1
fi
end=$1  

# source config
CONFFIGFILE=$1

# -- Configuration

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

# ---------------------
# VARIABLE DEFINITION
# ---------------------

#STARTDATE="2019-01-01"
#ENDDATE="2023-12-01"
# for precipitation data 2 months prior are need therefore earliest analysis month March 2019
STARTDATE=$(date -I -d "$STARTDATE + 1 month")
DATE_TMP=${STARTDATE}

while [ "$DATE_TMP" != ${ENDDATE} ]; do    
      
    DATE_TMP=$(date -I -d "$DATE_TMP + 1 month"); 

    DATE_SPLIT=(${DATE_TMP//-/ })
    MONTH=${DATE_SPLIT[1]}
    YEAR=${DATE_SPLIT[0]}

    # selection of one and two month prior
    # - month 1 or 2 prior with datetime or similar (e.g. jan 2020) (not just -1, -2)
    # - two digits
    # - special case for jan and feb 2019
    DATE_1_PRIOR=$(date -I -d "$DATE_TMP - 1 month"); DATE_SPLIT=(${DATE_1_PRIOR//-/ }); 
    MONTH_1_PRIOR_YEAR=${DATE_SPLIT[0]}; MONTH_1_PRIOR=${DATE_SPLIT[1]}; 
    DATE_2_PRIOR=$(date -I -d "$DATE_TMP - 2 month"); DATE_SPLIT=(${DATE_2_PRIOR//-/ });
    MONTH_2_PRIOR_YEAR=${DATE_SPLIT[0]}; MONTH_2_PRIOR=${DATE_SPLIT[1]}; 
    echo "$DATE_TMP; $MONTH_1_PRIOR_YEAR - $MONTH_1_PRIOR; $MONTH_2_PRIOR_YEAR - $MONTH_2_PRIOR";

    # ---- Output (SWD files + Models)
    OUT_PATH=/mnt/projects/mood/RVF_Mauritania/maxent/
    SPECIES_OUTPUT=${OUT_PATH}/SWD_files/species_${MONTH}_${YEAR}
    BGR_OUTPUT=${OUT_PATH}/SWD_files/bgr_${MONTH}_${YEAR}
    OUT_PATH_MODEL=${OUT_PATH}/models/

    # ---- Species/disease data
    DISEASE_MAPSET=RVF_Mauritania_disease_data
    # positive samples
    SPECIES_MAP=rvf_compiled_dataset_${MONTH}_${YEAR}_POS
    SPECIES=${SPECIES_MAP}@${DISEASE_MAPSET}
    # negative samples
    # TODO: not all positive samples have negative samples!
    BGP_MAP=rvf_compiled_dataset_${MONTH}_${YEAR}_NEG
    BGP=${BGP_MAP}@${DISEASE_MAPSET}

    # ---- Covariates
    # - CLMS: water bodies
    # TODO: two mapsets depending on timestamp
    WB_MAP=c_gls_WB300_GLOBE_S2_V2.0.1_MR_WB_res_${YEAR}_${MONTH}_01T00_00_00
    WB_MAPSET=CLMS_water_bodies_from2020_Mauritania
    WB=${WB_MAP}@${WB_MAPSET}

    # current monthly rainfall + one month prior + two month prior
    PREC_CURR_MAP=ERA5_land_monthly_prectot_sum_30sec_${YEAR}_${MONTH}_01T00_00_00
    PREC_1M_MAP=ERA5_land_monthly_prectot_sum_30sec_${MONTH_1_PRIOR_YEAR}_${MONTH_1_PRIOR}_01T00_00_00
    PREC_2M_MAP=ERA5_land_monthly_prectot_sum_30sec_${MONTH_2_PRIOR_YEAR}_${MONTH_2_PRIOR}_01T00_00_00
    PREC_MAPSET=ERA5_prectot_daily_Mauritania
    PREC_CURR=${PREC_CURR_MAP}@${PREC_MAPSET}
    PREC_1M=${PREC_1M_MAP}@${PREC_MAPSET}
    PREC_2M=${PREC_2M_MAP}@${PREC_MAPSET}

    # LST day and night
    LST_D_MAP=lst_day_monthly_${YEAR}_${MONTH}_1km
    LST_N_MAP=lst_night_monthly_${YEAR}_${MONTH}_1km
    LST_MAPSET=MODIS_LST_Mauritania
    LST_D=${LST_D_MAP}@${LST_MAPSET}
    LST_N=${LST_N_MAP}@${LST_MAPSET}

    # MODIS NDVI + NDWI
    NDVI_MAP=ndvi_filt_${YEAR}_${MONTH}_01T00_00_00
    NDVI=${NDVI_MAP}@MODIS_NDVI_Mauritania
    NDWI_MAP=ndwi_veg_monthly_${YEAR}_${MONTH}_1km
    NDWI=${NDWI_MAP}@MODIS_NDWI_veg_Mauritania

    # soil moisture
    SM_MAP=sm_surface_monthly_${YEAR}_${MONTH}_1km
    SM=${SM_MAP}@NSIDC_SMAP_soil_moisture_Mauritania


    # ---------------------
    # PROCESSING
    # ---------------------

    g.region raster=aoi_buf_rast@RVF_Mauritania -p
    r.mask raster=aoi_buf_rast@RVF_Mauritania

    # apply model
    # TODO: here currently applied to trained data
    r.maxent.predict \
        lambdafile=${OUT_MODEL}/${SPECIES_MAP}.lambdas \
        rasters=${PREC_CURR},${PREC_1M},${PREC_2M},${LST_D},${LST_N},${NDVI},${NDWI},${SM},${WB_RENAME} \
        variables=${PREC_CURR_MAP},${PREC_1M_MAP},${PREC_2M_MAP},${LST_D_MAP},${LST_N_MAP},${NDVI_MAP},${NDWI_MAP},${SM_MAP},wb \
        output=model_${MONTH}_${YEAR}_test_apply
    # for run with separated test data (15% less data)
    r.maxent.predict \
        lambdafile=${OUT_MODEL_TESTDATA}/${SPECIES_MAP}.lambdas \
        rasters=${PREC_CURR},${PREC_1M},${PREC_2M},${LST_D},${LST_N},${NDVI},${NDWI},${SM},${WB_RENAME} \
        variables=${PREC_CURR_MAP},${PREC_1M_MAP},${PREC_2M_MAP},${LST_D_MAP},${LST_N_MAP},${NDVI_MAP},${NDWI_MAP},${SM_MAP},wb \
        output=model_${MONTH}_${YEAR}_test_apply_testdata
done