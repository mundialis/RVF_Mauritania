#!/bin/bash
#
############################################################################
#
# MODULE:      visualize.sh
# AUTHOR(S):   Lina Krisztian
#
# PURPOSE:     Create images for GRASS raster output: risk maps or spillover
# COPYRIGHT:   (C) 2025 by mundialis GmbH & Co. KG and the GRASS
#              Development Team
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
############################################################################

# Call script:
#  grass -c epsg:25832 /path/to/grassdb --exec bash visualize.sh

################
### SETTINGS ###
################

# --------- main settings -----------

# -- Output base directory
OUT_BASEDIR=/home/lkrisztian/data/mood/rvf_mauritania/paper_plots/

# -- Which raster to plot
# Options:
# - "potential_risk_map"
#   -> Expects mapset with year-month rasters <potential_risk_map*>
#   e.g. import all from /mnt/projects/mood/RVF_Mauritania/results/potential_risk_maps/model_mv06/geotiff/
# - "spillover"
#   -> Expects mapset with year-month (spillover_quintile_YYYYMM)
#      and monthly aggregated (<spillover_quintile_month_MM>) rasters
#   e.g. import all from /mnt/projects/mood/RVF_Mauritania/results/spillover/
# DATA="potential_risk_map"
DATA="spillover"

# -- legends (including title)
# Options: yes, no
LEGEND="yes"

# -- aggregation to monthly maps
# Options: yes, no
MONTH_AGG="yes"

# --------- further settings -----------

# Admin. boundary of Mauritania
AREA_FILE=/mnt/mycephfs_ro/projects/mood/RVF_Mauritania/MRT_admin_2.geojson
# Background data of surrounding countries
# BACKGROUNDAREA_FILE=/mnt/mycephfs_ro/projects/mood/RVF_Mauritania/osm_boundary_administrative_admin_level_4_area_around_mauretania.gpkg
BACKGROUNDAREA_FILE=/home/lkrisztian/data/mood/osm_boundary_administrative_admin_level_4_area_around_mauretania.gpkg

# Color rules/map
if [[ $DATA == "potential_risk_map" ]]; then
    # Note: might need to adjust manually, such that range is from 0 to 1 (for legend)
    # r.colors map=<> color=bcyr
    # r.colors.out map=<> rules=/outpath/rules/bcyr_mod
    # manually adjust min and max value within rules file to e.g. -0.001 and 1.001 (slightly above actual range);
    # and event. also remaining values, such that colors evenly split
    # r.colors map=<> rules=/outpath/rules/bcyr_mod
    COL_RULES=/mnt/mycephfs_ro/projects/mood/RVF_Mauritania/paper/figures/bcyr
else
    COL_RULES="bcyr"
fi

# Define sub-directory for output, depending on settings
if [[ $LEGEND == "yes" ]]; then
    OUT_SUBDIR="with_legend"
else
    OUT_SUBDIR="without_legend"
fi
if [[ $MONTH_AGG == "yes" ]]; then
    OUT_SUBDIR="monthly_aggregation_${OUT_SUBDIR}"
fi
OUT_DIR=${OUT_BASEDIR}/${DATA}/${OUT_SUBDIR}

# position of legend and title
LEG_POS="22.4,89,3.1,6.3"
if [[ $DATA == "potential_risk_map" ]] && [[ $MONTH_AGG == "no" ]]; then
    TITL_POS="23,96"
elif [[ $DATA == "potential_risk_map" ]] && [[ $MONTH_AGG == "yes" ]]; then
    TITL_POS="8.5,96"
elif [[ $DATA == "spillover" ]] && [[ $MONTH_AGG == "yes" ]]; then
    TITL_POS="8.5,96"
fi
# further label settings
if [[ $DATA == "potential_risk_map" ]]; then
    LABELSTEP=0.1
    LABELRANGE="0,1"
elif [[ $DATA == "spillover" ]]; then
    LABELSTEP=1.0
    LABELRANGE="1,5"
fi

# --------- PLOS Journal requirements -----------

# File format:
# - TIFF or EPS for Journal
# - png for Latex
FILE_FORM="png"

# Dimensions:
# - Width: 789 – 2250 pixels (at 300 dpi); 6.68 cm - 19.05 cm
# - Height maximum: 2625 pixels (at 300 dpi); 22.23 cm
# Resolution:
# - 300 – 600 dpi
# File size:
# - <10 MB
# for 300 dpi: 3315,3520 -> 3315/300*2.54 and 3520/300*2.54 -> 28 cm and 30 cm
# for 600 dpi: 3315,3520 -> 3315/600*2.54 and 3520/600*2.54 -> 14 cm and 15 cm
SIZE_WITH_LEG="3315,3520"
# set differently to remove white border at top (if no title)
SIZE_WITHOUT_LEG="3315,3275"

# Text within figures:
# - Arial, Times, or Symbol font only in 8-12 point
# fonts not available; sans -> Similar to Arial
FONT="sans"
# TODO: check
FONT_SIZE=100 #80
TITL_SIZE=6 #4

# Figure Files:
# Fig1.tif, Fig2.eps, and so on. Match file name to caption label and citation.
# TODO at the end?


#################
### FUNCTIONS ###
#################

start_image () {
    # Start GRASS GIS GUI
    echo "Creating ${IMAGE_NAME} image ..."
    d.mon start=wx0
    d.font font=${FONT}
}

add_map () {
    # Raster to plot
    RAST=$1
    # Legend yes/no
    LEGEND=$2
    # Title for legend
    LEGEND_TITLE=$3
    # Title for figure
    FIGURE_TITLE=$4

    # Umgebende Länder grau im Hintergrund
    d.vect map=area_background fill_color=128:128:128 color=128:128:128
    # Raster map
    g.region raster=$RAST vector=area -pa
    g.region w=w-0.5
    d.rast map=$RAST
    if [[ $LEGEND == "yes" ]]; then
        g.region w=w-2.5
        d.legend raster=$RAST label_step=${LABELSTEP} \
            title="${LEGEND_TITLE}" bgcolor=255:255:204 border_color=gray -b -t range="${LABELRANGE}" at=${LEG_POS} fontsize=${FONT_SIZE} font=${FONT}
    fi
    # Adming. boundaries of Mauretania
    d.vect map=area fill_color=none color=0:0:0 width=2.0
    if [[ $LEGEND == "yes" ]]; then
        # Title
        d.text text="${FIGURE_TITLE}" \
        color=0:0:0 at=${TITL_POS} font=${FONT} size=${TITL_SIZE} # bgcolor=255:255:255
    fi
}

image_settings_and_export () {
    # image settings ad northarrow and barscale and saving image to PNG
    # d.northarrow at=95,12 width=3 font="${FONT}" fontsize=${FONT_SIZE}
    # d.barscale segment=5 font="${FONT}" fontsize=${FONT_SIZE} #bgcolor=none
    sleep 5
    mkdir ${OUT_DIR} -p
    if [[ $LEGEND == "yes" ]]; then
        SIZE=$SIZE_WITH_LEG
    else
        SIZE=$SIZE_WITHOUT_LEG
    fi

    d.out.file size=${SIZE} output=${OUT_DIR}/${RAST}.${FILE_FORM} format=$FILE_FORM --o
    echo "Created <${OUT_DIR}/${RAST}.${FILE_FORM}>"
    sleep 5
    d.mon stop=wx0
}

month_num2str () {
    # -- Given month (as number) to month name
    MONTH=$1
    # Within english + use dummy year and day
    echo $(env LC_TIME=en_US.UTF-8 date -d "2020-${MONTH}-01" +"%b")
}


##################
### PROCESSING ###
##################

# Check if output dir empty, exit if not
if [ -d "$OUT_DIR" ]; then
    if find ${OUT_DIR} -mindepth 1 -maxdepth 1 | read; then
        echo "ERROR: $OUT_DIR is not empty. Delete folder content first, or define different folder."
        exit 1
    fi
fi

# Import area and set region
if [ `g.list vect pattern='area'` ]
then
    echo "Vector map <area> already imported, skipping..."
else
    v.import input=${AREA_FILE} output=area
fi
if [ `g.list vect pattern='area_background'` ]
then
    echo "Vector map <area_background> already imported, skipping..."
else
    v.import input=${BACKGROUNDAREA_FILE} output=area_background
fi
g.region vector=area

# Raster maps
if [[ $DATA == "potential_risk_map" ]]
then
    if [[ $MONTH_AGG == "no" ]]
    then 
        # To ensure same color range for all raster maps (from 0 to 1)
        r.colors map=`g.list raster pattern=${DATA}* exclude=*agg* sep=,` rules=$COL_RULES
        for RAST in `g.list raster pattern=${DATA}* exclude=*agg*`; do
            start_image
            LEGEND_TITLE="[%]"
            RASTLIST=(${RAST//_/ })
            MONTH_STR=`month_num2str "${RASTLIST[-1]}"`
            FIGURE_TITLE="Probability of risk: ${MONTH_STR} ${RASTLIST[-2]}"
            add_map "${RAST}" "${LEGEND}" "${LEGEND_TITLE}" "${FIGURE_TITLE}"
            image_settings_and_export
        done
    elif [[ $MONTH_AGG == "yes" ]]
    then
        for MONTH in `seq -f '%02g' 1 12`; do
            RAST_AGG=`g.list raster pattern=${DATA}*_${MONTH} sep=","`
            echo ""
            echo "Averaging maps:"
            for RAST_AGG_ITER in ${RAST_AGG//","/" "}; do echo ${RAST_AGG_ITER}; done
            # Averaging
            RAST_AV_OUT=${DATA}_monthly_agg_${MONTH}
            r.series input=${RAST_AGG} output=${RAST_AV_OUT} method=average
            r.colors map=`g.list raster pattern=${DATA}* sep=,` rules=$COL_RULES --q
            # Create maps
            start_image
            LEGEND_TITLE="[%]"
            MONTH_STR=`month_num2str "${MONTH}"`
            FIGURE_TITLE="Monthly aggregated probability of risk: ${MONTH_STR}"
            add_map "${RAST_AV_OUT}" "${LEGEND}" "${LEGEND_TITLE}" "${FIGURE_TITLE}"
            image_settings_and_export
        done
    else
        echo "Non valid option for <MONTH_AGG>. Allowed: "yes" or "no", but given $MONTH_AGG"
        exit 1
    fi
elif [[ $DATA == "spillover" ]]
then
    if [[ $MONTH_AGG == "no" ]]
    then
        echo "NOTE: Not yet implemented: <DATA>=$DATA and <MONTH_AGG>=$MONTH_AGG"
    elif [[ $MONTH_AGG == "yes" ]]
    then
        # to ensure same color range for all raster maps (from 0 to 1)
        r.colors map=`g.list raster pattern=${DATA}*_month* sep=,` color=$COL_RULES
        for RAST in `g.list raster pattern=${DATA}*_month*`; do
            start_image
            LEGEND_TITLE=" "
            RASTLIST=(${RAST//_/ })
            MONTH_STR=`month_num2str "${RASTLIST[-1]}"`
            FIGURE_TITLE="Monthly quintiles of spillover potential: ${MONTH_STR}"
            add_map "${RAST}" "${LEGEND}" "${LEGEND_TITLE}" "${FIGURE_TITLE}"
            image_settings_and_export
        done
    else
        echo "Non valid option for <MONTH_AGG>. Allowed: "yes" or "no", but given $MONTH_AGG"
        exit 1
    fi
else
    echo "Non valid option for <DATA>. Allowed: "potential_risk_map" or "spillover", but given $DATA"
    exit 1
fi
