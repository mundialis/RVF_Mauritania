#!/bin/bash
#
############################################################################
#
# MODULE:      visualize.sh
# AUTHOR(S):   Lina Krisztian
#
# PURPOSE:     Create images for GRASS raster output: risk maps
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

# -- Output directory
IMAGE_DIR=/home/lkrisztian/data/mood/rvf_mauritania/paper_plots/potential_risk_map/with_legend
# IMAGE_DIR=/home/lkrisztian/data/mood/rvf_mauritania/paper_plots/

# -- Which raster to plot
# Options:
# - potential_risk_map -> Expects mapset with rasters <potential_risk_map*>
DATA="potential_risk_map"

# -- legends (including title)
# Options: yes, no
LEGEND="yes"

# --------- PLOS Journal requirements -----------

# File format:
# - TIFF or EPS
FILE_FORM="tif"

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
FONT_SIZE=80
TITL_SIZE=4

# Figure Files:
# Fig1.tif, Fig2.eps, and so on. Match file name to caption label and citation.
# TODO at the end?

# --------- further settings -----------

# Color rules
# Note: might need to adjust manually, such that range is from 0 to 1 (for legend)
# r.colors map=<> color=bcyr
# r.colors.out map=<> rules=/outpath/rules/bcyr_mod
# manually adjust min and max value within rules file to e.g. -0.001 and 1.001 (slightly above actual range);
# and event. also remaining values, such that colors evenly split
# r.colors map=<> rules=/outpath/rules/bcyr_mod
COL_RULES=/mnt/mycephfs_ro/projects/mood/RVF_Mauritania/paper/figures/bcyr

# Admin. boundary of Mauritania
AREA_FILE=/mnt/mycephfs_ro/projects/mood/RVF_Mauritania/MRT_admin_2.geojson
# Background data of surrounding countries
# BACKGROUNDAREA_FILE=/mnt/mycephfs_ro/projects/mood/RVF_Mauritania/osm_boundary_administrative_admin_level_4_area_around_mauretania.gpkg
BACKGROUNDAREA_FILE=/home/lkrisztian/data/mood/osm_boundary_administrative_admin_level_4_area_around_mauretania.gpkg

# position of legend and title
LEG_POS="20,75,2.5,6"
TITL_POS="35,96"

# Import vector areas 
# - Options: false, true
IMPORT_AREA=false


#################
### FUNCTIONS ###
#################

start_image () {
    # Start GRASS GIS GUI
    echo "Creating ${IMAGE_NAME} image ..."
    d.mon start=wx0
    d.font font=${FONT}
}

image_settings_and_export () {
    # image settings ad northarrow and barscale and saving image to PNG
    # d.northarrow at=95,12 width=3 font="${FONT}" fontsize=${FONT_SIZE}
    # d.barscale segment=5 font="${FONT}" fontsize=${FONT_SIZE} #bgcolor=none
    sleep 5
    mkdir ${IMAGE_DIR} -p
    if [[ $LEGEND == "yes" ]]; then
        SIZE=$SIZE_WITH_LEG
    else
        SIZE=$SIZE_WITHOUT_LEG
    fi

    d.out.file size=${SIZE} output=${IMAGE_DIR}/${RAST}.${FILE_FORM} format=$FILE_FORM --o
    echo "Created <${IMAGE_DIR}/${RAST}.png>"
    sleep 5
    d.mon stop=wx0
}


##################
### PROCESSING ###
##################

# import area and set region
if [ "$IMPORT_AREA" = true ]
then
    v.import input=${AREA_FILE} output=area
    v.import input=${BACKGROUNDAREA_FILE} output=area_background --o
fi


if [[ $DATA == "potential_risk_map" ]]
then
    # to ensure same color range for all raster maps (from 0 to 1)
    r.colors map=`g.list raster pattern=${DATA}* sep=,` rules=$COL_RULES
    # for testing only:
    # for RAST in `g.list raster pattern=${DATA}*2021*01`; do
    # for all data:
    for RAST in `g.list raster pattern=${DATA}*`; do
        # input
        start_image
        # Umgebende Länder grau im Hintergrund
        d.vect map=area_background fill_color=128:128:128 color=128:128:128
        g.region raster=$RAST vector=area -pa
        g.region w=w-0.5
        d.rast map=$RAST
        if [[ $LEGEND == "yes" ]]; then
            g.region w=w-2.5
            d.legend raster=$RAST label_step=0.1 \
                title="[%]" bgcolor=255:255:204 border_color=gray -b -t range=0,1 at=${LEG_POS} fontsize=${FONT_SIZE} font=${FONT}
        fi
        d.vect map=area fill_color=none color=0:0:0 width=2.0
        if [[ $LEGEND == "yes" ]]; then
            # title
            RASTLIST=(${RAST//_/ })
            d.text text="Probability of risk: ${RASTLIST[-1]}-${RASTLIST[-2]}" \
            color=0:0:0 at=${TITL_POS} font=${FONT} size=${TITL_SIZE} # bgcolor=255:255:255
        fi
        image_settings_and_export
    done
fi
