#!/bin/bash

############################################################################
#
# MODULE:      potential_risk_areas_train.sh
# AUTHOR(S):   Victoria-Leandra Brunn, Lina Krisztian
#
# PURPOSE:     Processing script for preparation and training of Maxent model
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
    echo -e "ERROR: Missing configfile.\nUsage: potential_risk_areas_train.sh /path/to/config.cfg"
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

# ---------------------
# PROCESSING
# ---------------------

g.region raster=aoi_buf_rast@RVF_Mauritania -p
r.mask -r
r.mask raster=aoi_buf_rast@RVF_Mauritania

# Helper variable, for information about loop iteration
ITER=0

# TODO: give month which should be used explicit within config (not indirect via model version)
# Set selection of used disease data for modeling
if [ ${MODEL_V} -eq "03" ]; then
    # loop / use only 10-2020 (model version 03)
    LOOP_VECT_LIST=`g.list vector pattern=${SPECIES_MAP//MONTH_YEAR/10_2020} mapset=${DISEASE_MAPSET}`
elif [ ${MODEL_V} -eq "05" ] || [ ${MODEL_V} -eq "07" ]; then
    # loop / use only the 4 month with the most data samples
    LOOP_VECT_LIST=`g.list vector pattern=${SPECIES_MAP//MONTH_YEAR/09_2020},${SPECIES_MAP//MONTH_YEAR/10_2020},${SPECIES_MAP//MONTH_YEAR/09_2022},${SPECIES_MAP//MONTH_YEAR/10_2022} mapset=${DISEASE_MAPSET}`
else
    # loop / use all given disease data
    LOOP_VECT_LIST=`g.list vector pattern=${SPECIES_MAP//MONTH_YEAR/"*"} mapset=${DISEASE_MAPSET}`
fi

# loop over disease data (which month, is specified above), to generate monthly SWD files
for VECT_POS in ${LOOP_VECT_LIST} ; do
    VECT_NEG=${VECT_POS//POS/NEG}
    # only for positive samples, where also negative samples given
    if [ `g.list vector pattern=${VECT_NEG} mapset=${DISEASE_MAPSET}` ]; then
        
        echo "Generating SWD files for ${VECT_POS}"
        
        # increase for each iteration
        ITER=$((${ITER}+1))

        # get date from current disease vector data name
        # z.B. VECT_POS=rvf_compiled_dataset_01_2020_POS
        DATE_SPLIT=(${VECT_POS//_/ })
        MONTH=${DATE_SPLIT[3]}
        YEAR=${DATE_SPLIT[4]}
        DATE_TMP="${YEAR}-${MONTH}-01"
        
        # date for precipitation: one and two month prior
        # one month prior
        DATE_1_PRIOR=$(date -I -d "$DATE_TMP - 1 month"); DATE_SPLIT=(${DATE_1_PRIOR//-/ }); 
        OMP_YEAR=${DATE_SPLIT[0]}; OMP_MONTH=${DATE_SPLIT[1]}; 
        # two month prior
        DATE_2_PRIOR=$(date -I -d "$DATE_TMP - 2 month"); DATE_SPLIT=(${DATE_2_PRIOR//-/ });
        TMP_YEAR=${DATE_SPLIT[0]}; TMP_MONTH=${DATE_SPLIT[1]}; 

        # folder for each data version -> create first
        mkdir $(dirname "$SPECIES_OUTPUT") -p

        # generate SWD files for Maxent
        # for dv01 removed:
        # - soil moisture: ${SM//YEAR_MONTH/${YEAR}_${MONTH}},\
        # for dv02 removed:
        # - dist to water bodies: ${DIST_TO_WB//YEAR_MONTH/${YEAR}_${MONTH}} \
        if [ -f ${SPECIES_OUTPUT//MONTH_YEAR/${MONTH}_${YEAR}} ]; then
            echo "${SPECIES_OUTPUT//MONTH_YEAR/${MONTH}_${YEAR}} already exists, skipping v.maxent.swd step"
        else
            v.maxent.swd species=${SPECIES//MONTH_YEAR/${MONTH}_${YEAR}} \
                bgp=${BGP//MONTH_YEAR/${MONTH}_${YEAR}} \
                evp_maps=${PREC_CURR//YEAR_MONTH/${YEAR}_${MONTH}},\
${PREC_1M//YEAR_MONTH/${OMP_YEAR}_${OMP_MONTH}},\
${PREC_2M//YEAR_MONTH/${TMP_YEAR}_${TMP_MONTH}},\
${LST_D//YEAR_MONTH/${YEAR}_${MONTH}},\
${LST_N//YEAR_MONTH/${YEAR}_${MONTH}},\
${NDVI//YEAR_MONTH/${YEAR}_${MONTH}},\
${NDWI//YEAR_MONTH/${YEAR}_${MONTH}}\
                alias_names=prec_curr,prec_1m,prec_2m,lst_d,lst_n,ndvi,ndwi \
                species_output=${SPECIES_OUTPUT//MONTH_YEAR/${MONTH}_${YEAR}} \
                bgr_output=${BGR_OUTPUT//MONTH_YEAR/${MONTH}_${YEAR}} --o
        fi

        # Concat monthly SWD files to single combined and metadata file with corresponding dates
        if [ ${ITER} -eq 1 ]; then
            if [ ${SING_MOD} -eq 1 ]; then
                SPECIES_OUTPUT_COMB=${SPECIES_OUTPUT_COMB}_single_model
            elif [ ${SING_MOD} -eq 0 ]; then
                SPECIES_OUTPUT_COMB=${SPECIES_OUTPUT_COMB}_monthly_models
            fi
            tail -n +1 "${SPECIES_OUTPUT//MONTH_YEAR/${MONTH}_${YEAR}}" > ${SPECIES_OUTPUT_COMB}
            tail -n +1 "${BGR_OUTPUT//MONTH_YEAR/${MONTH}_${YEAR}}" > ${BGR_OUTPUT_COMB}
            echo "# Dates of all used pos/neg disease samples, for training of Maxent model" > ${DISEASE_COMB_DATES}
            echo "# Data version ${DATE_V}, Model version ${MODEL_V}" >> ${DISEASE_COMB_DATES}
            echo $DATE_TMP >> ${DISEASE_COMB_DATES}
        else
            tail -n +2 "${SPECIES_OUTPUT//MONTH_YEAR/${MONTH}_${YEAR}}" >> ${SPECIES_OUTPUT_COMB}
            tail -n +2 "${BGR_OUTPUT//MONTH_YEAR/${MONTH}_${YEAR}}" >> ${BGR_OUTPUT_COMB}
            echo $DATE_TMP >> ${DISEASE_COMB_DATES}
        fi
    fi
done

if [ ${SING_MOD} -eq 1 ]; then
    # replace month-year specifics of species name within SWD files
    # otherwise one model per species trained/returned
    # -> here we want one single, trained with all month-year data combined
    for DATE in `tail -n +3 ${DISEASE_COMB_DATES}` ; do
        DATE_SPLIT=(${DATE//-/ });
        STR="${DATE_SPLIT[1]}_${DATE_SPLIT[0]}";
        sed -i -e "s/$STR/combined/g" ${SPECIES_OUTPUT_COMB};
    done
fi

# train model
mkdir ${OUT_MODEL} -p
r.maxent.train -g -j -d \
    samplesfile=${SPECIES_OUTPUT_COMB} \
    environmentallayersfile=${BGR_OUTPUT_COMB} \
    outputdirectory=${OUT_MODEL} --o
    # - flags:
    # d flag: keep duplicates
    # n flag: avoid adding more data to background samples --> when set, model seems NOT having enough data for reasonable training
    # - for test set:
    # randomtestpoints=15 OR
    # testsamplesfile=...
    # - for creation of prediction of given input sample and background vector points:
    # flag y and b + name via option <samplepredictions> and <backgroundpredictions>
