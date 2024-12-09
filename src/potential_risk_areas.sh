# ---------------------
# VARIABLE DEFINITION
# ---------------------
MONTH=10
YEAR=2020

# ---- Output (SWD files)
OUT_PATH=/mnt/projects/mood/RVF_Mauritania/maxent/SWD_files/
SPECIES_OUTPUT=${OUT_PATH}/species_${MONTH}_${YEAR}
BGR_OUTPUT=${OUT_PATH}/bgr_${MONTH}_${YEAR}

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
# Note: two mapsets depending on timestamp
# TODO
WB_MAP=c_gls_WB300_GLOBE_S2_V2.0.1_MR_WB_res_${YEAR}_${MONTH}_01T00_00_00
WB_MAPSET=CLMS_water_bodies_from2020_Mauritania
WB=${WB_MAP}@${WB_MAPSET}

# current monthly rainfall + one month prior + two month prior
# TODO: selection of one and two month prior
# - month 1 or 2 prior with datetime or similar (e.g. jan 2020) (not just -1, -2)
# - two digits
# - special case for jan and feb 2019
PREC_CURR=ERA5_land_monthly_prectot_sum_30sec_${YEAR}_${MONTH}_01T00_00_00@ERA5_prectot_daily_Mauritania
PREC_1M=ERA5_land_monthly_prectot_sum_30sec_${YEAR}_0$((${MONTH}-1))_01T00_00_00@ERA5_prectot_daily_Mauritania
PREC_2M=ERA5_land_monthly_prectot_sum_30sec_${YEAR}_0$((${MONTH}-2))_01T00_00_00@ERA5_prectot_daily_Mauritania

# LST day and night
LST_D=lst_day_monthly_${YEAR}_${MONTH}@MODIS_LST_Mauritania
LST_N=lst_night_monthly_${YEAR}_${MONTH}@MODIS_LST_Mauritania

# MODIS NDVI + NDWI
NDVI=ndvi_filt_${YEAR}_${MONTH}_01T00_00_00@MODIS_NDVI_Mauritania
NDWI=ndwi_veg_monthly_${YEAR}_${MONTH}@MODIS_NDWI_veg_Mauritania

# soil moisture
SM=sm_surface_monthly_${YEAR}_${MONTH}@NSIDC_SMAP_soil_moisture_Mauritania

# ---------------------
# PROCESSING
# ---------------------

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
v.maxent.swd species=${SPECIES_MAP} bgp=${BGP_MAP} evp_maps=${WB_RENAME},${PREC_CURR},${PREC_1M},${PREC_2M},${LST_D},${LST_N},${NDVI},${NDWI},${SM} species_output=${SPECIES_OUTPUT} bgr_output=${BGR_OUTPUT}
