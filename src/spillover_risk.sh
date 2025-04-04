#!/bin/bash

############################################################################
#
# MODULE:      spillover_risk.sh
# AUTHOR(S):   Markus Metz
#
# PURPOSE:     RVF spillover risk calculation after Hardcastle et al. 2020
# COPYRIGHT:   (C) 2024 - 2025 by mundialis GmbH & Co. KG
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

# setting environment, so that awk works properly in all languages
unset LC_ALL
LC_NUMERIC=C
export LC_NUMERIC

# set variables (map names for human population, livestock population and
# maxent suitability maps)

# mrt_ppp_2020_1km_Aggregated_UNadj: Estimated total number of people per grid-cell.
# https://hub.worldpop.org/geodata/summary?id=37504
HUMAN_POPABS="mrt_ppp_2020_1km_Aggregated_UNadj_shifted@WorldPop_Mauritania"
# all livestock added together (CTL, GTS, SHP)
LIVESTOCK_POPDENS="GLW4-2020.D-DA_livestock_zero_30arcsec@GLW_2020_Mauritania"
MAXENT_MODEL_VERSION="mv06"

REGION="aoi_buf_rast@RVF_Mauritania"


# ---------------------
# PROCESSING
# ---------------------

# set region
g.region raster=${REGION} -p

# -- number of humans and livestock at risk per pixel

# optional preparation if needed:
# convert human population density (number / km2) to absolute number of people
# r.mapcalc "human_pop_abs = $HUMAN_POPDENS * area() / 1000000.0"

# convert livestock population density (number / km2) to absolute number of livestock
r.mapcalc "livestock_pop_abs = \"${LIVESTOCK_POPDENS}\" * area() / 1000000.0"


# -- calculate natural log: loop over all years and months

# initialize overall minima and maxima for
# log of absolute number of humans at risk
# log of proportion of humans at risk
# log of absolute number of livestock at risk
# log of proportion of livestock at risk
TOTAL_LOG_H_ABS_MIN=0.0
TOTAL_LOG_H_ABS_MAX=0.0
TOTAL_LOG_H_PROP_MIN=0.0
TOTAL_LOG_H_PROP_MAX=0.0
TOTAL_LOG_L_ABS_MIN=0.0
TOTAL_LOG_L_ABS_MAX=0.0
TOTAL_LOG_L_PROP_MIN=0.0
TOTAL_LOG_L_PROP_MAX=0.0
FIRST=1

# use log(1 + x):
# output will be >= 0, no large negative values
# input can be zero
g.message "natural logs ..."
for YEAR in `seq 2019 2023` ; do
  FIRSTMONTH=1
  LASTMONTH=12
  if [ $YEAR -eq 2019 ] ; then
    FIRSTMONTH=3
  fi
  
  for MONTH in `seq $FIRSTMONTH $LASTMONTH` ; do
    MONTH2D=`printf "%02d\n" $MONTH`

    g.message "$YEAR $MONTH2D ..."

    MAXENT_SUITABILITY="model_${MONTH2D}_${YEAR}_${MAXENT_MODEL_VERSION}@RVF_Mauritania_potential_risk_areas"

    # absolute number of humans at risk
    r.mapcalc "human_abs_risk_${YEAR}${MONTH2D} = $HUMAN_POPABS * $MAXENT_SUITABILITY" || exit 1

    # proportion of humans at risk: MAXENT_SUITABILITY

    # add livestock movement to livestock population
    # wet season: June to October
    # dry season: November to May
    MOVEMENTMAP=""
    if [ $MONTH -eq 11 ] || [ $MONTH -eq 12 ] || [ $MONTH -eq 1 ] || [ $MONTH -eq 2 ] || [ $MONTH -eq 3 ] || [ $MONTH -eq 4 ] || [ $MONTH -eq 5 ] ; then
      MOVEMENTMAP="Current_dry_1km_nodata_scaled2@livestock_movement_Mauritania"
    fi
    if [ $MONTH -eq 6 ] || [ $MONTH -eq 7 ] || [ $MONTH -eq 8 ] || [ $MONTH -eq 9 ] || [ $MONTH -eq 10 ] ; then
      MOVEMENTMAP="Current_wet_1km_nodata_scaled2@livestock_movement_Mauritania"
    fi
    # modified number of livestock: more movement -> more animals
    r.mapcalc "livestock_abs_move_${YEAR}${MONTH2D} = livestock_pop_abs * (1 + $MOVEMENTMAP)" || exit 1

    # absolute number of livestock at risk
    r.mapcalc "livestock_abs_risk_${YEAR}${MONTH2D} = livestock_abs_move_${YEAR}${MONTH2D} * $MAXENT_SUITABILITY" || exit 1

    # proportion of livestock at risk: MAXENT_SUITABILITY

    # natural log of humans at risk
    r.mapcalc "human_abs_risk_log_${YEAR}${MONTH2D} = log(1 + human_abs_risk_${YEAR}${MONTH2D})" || exit 1
    r.mapcalc "human_prop_risk_log_${YEAR}${MONTH2D} = log(1 + $MAXENT_SUITABILITY)" || exit 1

    # natural log of livestock at risk
    r.mapcalc "livestock_abs_risk_log_${YEAR}${MONTH2D} = log(1 + livestock_abs_risk_${YEAR}${MONTH2D})" || exit 1
    r.mapcalc "livestock_prop_risk_log_${YEAR}${MONTH2D} = log(1 + $MAXENT_SUITABILITY)" || exit 1

    # minimum and maximum of these 4 logs across all pixels, months, and years
    if [ $FIRST -eq 1 ] ; then
      FIRST=0

      eval `r.info -s human_abs_risk_log_${YEAR}${MONTH2D}`
      TOTAL_LOG_H_ABS_MIN=$min
      TOTAL_LOG_H_ABS_MAX=$max

      eval `r.info -s human_prop_risk_log_${YEAR}${MONTH2D}`
      TOTAL_LOG_H_PROP_MIN=$min
      TOTAL_LOG_H_PROP_MAX=$max

      eval `r.info -s livestock_abs_risk_log_${YEAR}${MONTH2D}`
      TOTAL_LOG_L_ABS_MIN=$min
      TOTAL_LOG_L_ABS_MAX=$max

      eval `r.info -s livestock_prop_risk_log_${YEAR}${MONTH2D}`
      TOTAL_LOG_L_PROP_MIN=$min
      TOTAL_LOG_L_PROP_MAX=$max
    else
      eval `r.info -s human_abs_risk_log_${YEAR}${MONTH2D}`
      TOTAL_LOG_H_ABS_MIN=`echo $TOTAL_LOG_H_ABS_MIN $min | awk '{printf "%g\n", ($1 < $2 ? $1 : $2)}'`
      TOTAL_LOG_H_ABS_MAX=`echo $TOTAL_LOG_H_ABS_MAX $max | awk '{printf "%g\n", ($1 > $2 ? $1 : $2)}'`

      eval `r.info -s human_prop_risk_log_${YEAR}${MONTH2D}`
      TOTAL_LOG_H_PROP_MIN=`echo $TOTAL_LOG_H_PROP_MIN $min | awk '{printf "%g\n", ($1 < $2 ? $1 : $2)}'`
      TOTAL_LOG_H_PROP_MAX=`echo $TOTAL_LOG_H_PROP_MAX $max | awk '{printf "%g\n", ($1 > $2 ? $1 : $2)}'`

      eval `r.info -s livestock_abs_risk_log_${YEAR}${MONTH2D}`
      TOTAL_LOG_L_ABS_MIN=`echo $TOTAL_LOG_L_ABS_MIN $min | awk '{printf "%g\n", ($1 < $2 ? $1 : $2)}'`
      TOTAL_LOG_L_ABS_MAX=`echo $TOTAL_LOG_L_ABS_MAX $max | awk '{printf "%g\n", ($1 > $2 ? $1 : $2)}'`

      eval `r.info -s livestock_prop_risk_log_${YEAR}${MONTH2D}`
      TOTAL_LOG_L_PROP_MIN=`echo $TOTAL_LOG_L_PROP_MIN $min | awk '{printf "%g\n", ($1 < $2 ? $1 : $2)}'`
      TOTAL_LOG_L_PROP_MAX=`echo $TOTAL_LOG_L_PROP_MAX $max | awk '{printf "%g\n", ($1 > $2 ? $1 : $2)}'`
    fi
  done
done

# -- scale the log maps to be between 0 and 10 using the overall minima and maxima
#    and calculate geometric mean
g.message "rescale log maps ..."
for YEAR in `seq 2019 2023` ; do
  FIRSTMONTH=1
  LASTMONTH=12
  if [ $YEAR -eq 2019 ] ; then
    FIRSTMONTH=3
  fi
  
  for MONTH in `seq $FIRSTMONTH $LASTMONTH` ; do
    MONTH2D=`printf "%02d\n" $MONTH`

    g.message "$YEAR $MONTH2D ..."

    MAXENT_SUITABILITY="model_${MONTH2D}_${YEAR}_${MAXENT_MODEL_VERSION}"

    # scale natural log of absolute number of humans at risk
    r.mapcalc "human_abs_risk_log_scaled_${YEAR}${MONTH2D} = ((human_abs_risk_log_${YEAR}${MONTH2D} - $TOTAL_LOG_H_ABS_MIN) / ($TOTAL_LOG_H_ABS_MAX - $TOTAL_LOG_H_ABS_MIN)) * 10.0" || exit 1

    # scale natural log of proportion of humans at risk
    r.mapcalc "human_prop_risk_log_scaled_${YEAR}${MONTH2D} = ((human_prop_risk_log_${YEAR}${MONTH2D} - $TOTAL_LOG_H_PROP_MIN) / ($TOTAL_LOG_H_PROP_MAX - $TOTAL_LOG_H_PROP_MIN)) * 10.0" || exit 1

    # scale natural log of absolute number of livestock at risk
    r.mapcalc "livestock_abs_risk_log_scaled_${YEAR}${MONTH2D} = ((livestock_abs_risk_log_${YEAR}${MONTH2D} - $TOTAL_LOG_L_ABS_MIN) / ($TOTAL_LOG_L_ABS_MAX - $TOTAL_LOG_L_ABS_MIN)) * 10.0" || exit 1

    # scale natural log of proportion of livestock at risk
    r.mapcalc "livestock_prop_risk_log_scaled_${YEAR}${MONTH2D} = ((livestock_prop_risk_log_${YEAR}${MONTH2D} - $TOTAL_LOG_L_PROP_MIN) / ($TOTAL_LOG_L_PROP_MAX - $TOTAL_LOG_L_PROP_MIN)) * 10.0" || exit 1

    # geometric mean for humans at risk
    r.mapcalc "human_geomean_${YEAR}${MONTH2D} = sqrt(human_abs_risk_log_scaled_${YEAR}${MONTH2D} * human_prop_risk_log_scaled_${YEAR}${MONTH2D})" || exit 1

    # geometric mean for livestock at risk
    r.mapcalc "livestock_geomean_${YEAR}${MONTH2D} = sqrt(livestock_abs_risk_log_scaled_${YEAR}${MONTH2D} * livestock_prop_risk_log_scaled_${YEAR}${MONTH2D})" || exit 1

    # geometric mean for humans and livestock at risk -> final spillover potential
    r.mapcalc "spillover_geomean_${YEAR}${MONTH2D} = sqrt(human_geomean_${YEAR}${MONTH2D} * livestock_geomean_${YEAR}${MONTH2D})" || exit 1
    
    # without zero values
    r.mapcalc "spillover_geomean_nozero_${YEAR}${MONTH2D} = if(spillover_geomean_${YEAR}${MONTH2D} == 0, null(), spillover_geomean_${YEAR}${MONTH2D})" || exit 1
  done
done

# -- quintile ranking for each spillover value from all geographic units (pixels), months, and years, excluding 0 cells
# r.univar with all spillover_geomean_* maps
# the commandline must not become too long !
MAPLIST=`g.list rast mapset=. pattern=spillover_geomean_nozero_* separator=comma`
eval `r.univar -ge map=$MAPLIST percentile=20,40,60,80`

RULESFILE=`g.tempfile pid=$$`

# write rules for r.recode to file
echo "0:${percentile_20}:1
${percentile_20}:${percentile_40}:2
${percentile_40}:${percentile_60}:3
${percentile_60}:${percentile_80}:4
${percentile_80}:10:5" >$RULESFILE

# assign coded quintile to each pixel according to the quintile its value falls into
# loop over all monthly maps and recode (with copy)
g.message "Recode spillover to quintiles ..."
for YEAR in `seq 2019 2023` ; do
  FIRSTMONTH=1
  LASTMONTH=12
  if [ $YEAR -eq 2019 ] ; then
    FIRSTMONTH=3
  fi
  
  for MONTH in `seq $FIRSTMONTH $LASTMONTH` ; do
    MONTH2D=`printf "%02d\n" $MONTH`

    g.message "$YEAR $MONTH2D ..."

    r.recode input=spillover_geomean_${YEAR}${MONTH2D} output=spillover_quintile_${YEAR}${MONTH2D} rules=$RULESFILE || exit 1
  done
done

# average quintile for each pixel and month across all years
g.message "average quintile per month over all years ..."
for MONTH in `seq 1 12` ; do
  MONTH2D=`printf "%02d\n" $MONTH`

  g.message "$MONTH2D ..."

  # all maps over all years for this month: average quintile:
  # synoptic spillover potential for each pixel and month across all years
  MAPLIST=`g.list rast mapset=. pattern=spillover_quintile_????${MONTH2D} separator=comma`
  r.series input=$MAPLIST method=average output=spillover_quintile_month_${MONTH2D} || exit 1
done

# average geomean for each pixel and month across all years
g.message "average geomean per month over all years ..."
for MONTH in `seq 1 12` ; do
  MONTH2D=`printf "%02d\n" $MONTH`

  g.message "$MONTH2D ..."

  # all maps over all years for this month: average geomean:
  # synoptic spillover potential for each pixel and month across all years
  MAPLIST=`g.list rast mapset=. pattern=spillover_geomean_????${MONTH2D} separator=comma`
  r.series input=$MAPLIST method=average output=spillover_geomean_month_${MONTH2D} || exit 1
done

exit 0
