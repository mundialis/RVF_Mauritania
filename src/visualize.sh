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

# Parameter
# Admin. boundary of Mauritania
AREA_FILE=/mnt/mycephfs_ro/projects/mood/RVF_Mauritania/MRT_admin_2.geojson
# BACKGROUNDAREA_FILE=/mnt/mycephfs_ro/projects/mood/RVF_Mauritania/osm_boundary_administrative_admin_level_4_area_around_mauretania.gpkg
BACKGROUNDAREA_FILE=/home/lkrisztian/data/mood/osm_boundary_administrative_admin_level_4_area_around_mauretania.gpkg
# Output directory
# IMAGE_DIR=/home/lkrisztian/data/mood/rvf_mauritania/paper_plots/potential_risk_map/with_legend
IMAGE_DIR=/home/lkrisztian/data/mood/rvf_mauritania/paper_plots/

# Which raster to plot
# Options:
# - potential_risk_map -> Expects mapset with rasters <potential_risk_map*>
DATA="potential_risk_map"
# - Options: yes, no
LEGEND="yes"

# ------------ TODO

FONT="romand"
FONT_TITLE="romand"
FONT_SIZE=40
SIZE="3315,3120"  # ca 300 dpi (2480 x 3507 Pixeln)
LEG_POS="25,75,3,6"

# Images to create
# - Options: false, true
IMPORT_AREA=false


### FUNCTIONS ##############################################################
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
    d.out.file size=${SIZE} output=${IMAGE_DIR}/${RAST}.png --o
    echo "Created <${IMAGE_DIR}/${RAST}.png>"
    sleep 5
    d.mon stop=wx0
}


############################################################################


# import area and set region
if [ "$IMPORT_AREA" = true ]
then
    v.import input=${AREA_FILE} output=area
    v.import input=${BACKGROUNDAREA_FILE} output=area_background --o
fi


if [[ $DATA == "potential_risk_map" ]]
then
    # TODO: welche color map
    # to ensure same color range for all raster maps
    r.colors map=`g.list raster pattern=${DATA}* sep=,` color=bcyr
    for RAST in `g.list raster pattern=${DATA}*2021_01`; do
    # TODO: for all data
    # for RAST in `g.list raster pattern=${DATA}*`; do
        # input
        start_image
        # Umgebende Länder grau im Hintergrund
        d.vect map=area_background fill_color=128:128:128 color=128:128:128
        g.region raster=$RAST vector=area -pa
        g.region w=w-0.5 n=n+1
        d.rast map=$RAST
        if [[ $LEGEND == "yes" ]]; then
            g.region w=w-2.5
            d.legend raster=$RAST label_step=0.1 \
                title="[percentage]" bgcolor=255:255:204 border_color=gray -b -t range=0,1 at=${LEG_POS} fontsize=${FONT_SIZE} font=${FONT}
        fi
        d.vect map=area fill_color=none color=0:0:0 width=2.0
        # TODO title? oder in latex subfigures
        RASTLIST=(${RAST//_/ })
        d.text text="Potential risk map: ${RASTLIST[-1]}-${RASTLIST[-2]}" at=15,96 font=${FONT_TITLE} size=4 color=0:0:0
        image_settings_and_export
    done
fi
