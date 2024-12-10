# ---------------------
# VARIABLE DEFINITION
# ---------------------

MONTH=10
YEAR=2020

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
# TODO: selection of one and two month prior
# - month 1 or 2 prior with datetime or similar (e.g. jan 2020) (not just -1, -2)
# - two digits
# - special case for jan and feb 2019
PREC_CURR_MAP=ERA5_land_monthly_prectot_sum_30sec_${YEAR}_${MONTH}_01T00_00_00
PREC_1M_MAP=ERA5_land_monthly_prectot_sum_30sec_${YEAR}_0$((${MONTH}-1))_01T00_00_00
PREC_2M_MAP=ERA5_land_monthly_prectot_sum_30sec_${YEAR}_0$((${MONTH}-2))_01T00_00_00
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

# TODO?: 
# für kleiner region berechnen? nur grob da wo disease daten oder ganz Mauretanien
g.region raster=aoi_buf_rast@RVF_Mauritania -p
r.mask raster=aoi_buf_rast@RVF_Mauritania

# TODO: rename CLMS water bodie data:
WB_RENAME=${WB_MAP//./_}
g.copy raster=${WB},${WB_RENAME}

# ? TODO: rename species column
g.copy vector=${SPECIES},${SPECIES_MAP}
v.db.renamecolumn map=${SPECIES_MAP} column=species,animal_species
g.copy vector=${BGP},${BGP_MAP}
v.db.renamecolumn map=${BGP_MAP} column=species,animal_species

# generate SWD files for Maxent
v.maxent.swd species=${SPECIES_MAP} bgp=${BGP_MAP} evp_maps=${PREC_CURR},${PREC_1M},${PREC_2M},${LST_D},${LST_N},${NDVI},${NDWI},${SM} evp_cat=${WB_RENAME} alias_cat=wb species_output=${SPECIES_OUTPUT} bgr_output=${BGR_OUTPUT}

# train model
OUT_MODEL=${OUT_PATH_MODEL}/model_${MONTH}_${YEAR}
mkdir ${OUT_MODEL}
r.maxent.train -y -b -g \
    samplesfile=${SPECIES_OUTPUT} \
    environmentallayersfile=${BGR_OUTPUT} \
    togglelayertype=wb \
    samplepredictions=model_${MONTH}_${YEAR}_samplepred \
    backgroundpredictions=model_${MONTH}_${YEAR}_bgrdpred \
    outputdirectory=${OUT_MODEL}
# with seperate test data + jackknife validation
OUT_MODEL_TESTDATA=${OUT_PATH_MODEL}/model_${MONTH}_${YEAR}_with_testdata
mkdir ${OUT_MODEL_TESTDATA}
r.maxent.train -y -b -g -j\
    samplesfile=${SPECIES_OUTPUT} \
    environmentallayersfile=${BGR_OUTPUT} \
    togglelayertype=wb \
    samplepredictions=model_${MONTH}_${YEAR}_samplepred_testdata \
    backgroundpredictions=model_${MONTH}_${YEAR}_bgrdpred_testdata \
    outputdirectory=${OUT_MODEL_TESTDATA} \
    randomtestpoints=15

# apply model
# TODO: here currently applied to trained data
r.maxent.predict \
    lambdafile=${OUT_MODEL}/${SPECIES_MAP}.lambdas \
    rasters=${PREC_CURR},${PREC_1M},${PREC_2M},${LST_D},${LST_N},${NDVI},${NDWI},${SM},${WB_RENAME} \
    variables=${PREC_CURR_MAP},${PREC_1M_MAP},${PREC_2M_MAP},${LST_D_MAP},${LST_N_MAP},${NDVI_MAP},${NDWI_MAP},${SM_MAP},wb \
    output=model_${MONTH}_${YEAR}_test_apply
# 
r.maxent.predict \
    lambdafile=${OUT_MODEL_TESTDATA}/${SPECIES_MAP}.lambdas \
    rasters=${PREC_CURR},${PREC_1M},${PREC_2M},${LST_D},${LST_N},${NDVI},${NDWI},${SM},${WB_RENAME} \
    variables=${PREC_CURR_MAP},${PREC_1M_MAP},${PREC_2M_MAP},${LST_D_MAP},${LST_N_MAP},${NDVI_MAP},${NDWI_MAP},${SM_MAP},wb \
    output=model_${MONTH}_${YEAR}_test_apply_testdata
