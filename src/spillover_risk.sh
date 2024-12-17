#!/bin/bash

# setting environment, so that awk works properly in all languages
unset LC_ALL
LC_NUMERIC=C
export LC_NUMERIC

# number of humans and livestock at risk per pixel

# optional preparation if needed:
# convert human population density (number / km2) to absolute number of people
HUMAN_POPDENS=""
r.mapcalc "human_pop_abs = $HUMAN_POPDENS * area() / 1000000.0"

# convert livestock population density (number / km2) to absolute number of livestock
LIVESTOCK_POPDENS=""
r.mapcalc "livestock_pop_abs = $LIVESTOCK_POPDENS * area() / 1000000.0"


# loop over all years and months

# intitialize overall minima and maxima for
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

for YEAR in `seq 2019 2023` ; do
  for MONTH in `seq 1 12` ; do
    MONTH2D=`prinf "%02d\n" $MONTH`

    # TODO: adjust to actual map names
    MAXENT_SUITABILITY="maxent_prefix_${YEAR}${MONTH2D}"

    # absolute number of humans at risk
    r.mapcalc "human_abs_risk_${YEAR}${MONTH2D} = human_pop_abs * $MAXENT_SUITABILITY"

    # proportion at risk: MAXENT_SUITABILITY

    # absolute number of livestock at risk
    r.mapcalc "livestock_abs_risk_${YEAR}${MONTH2D} = livestock_pop_abs * $MAXENT_SUITABILITY"

    # proportion at risk: MAXENT_SUITABILITY

    # natural log of humans at risk
    r.mapcalc "human_abs_risk_log_${YEAR}${MONTH2D} = log(human_abs_risk_${YEAR}${MONTH2D})"
    r.mapcalc "human_prop_risk_log_${YEAR}${MONTH2D} = log($MAXENT_SUITABILITY)"

    # natural log of livestock at risk
    r.mapcalc "livestock_abs_risk_log_${YEAR}${MONTH2D} = log(livestock_abs_risk_${YEAR}${MONTH2D})"
    r.mapcalc "livestock_prop_risk_log_${YEAR}${MONTH2D} = log($MAXENT_SUITABILITY)"

    # minimum and maximum of these 4 logs across all pixels, months, and years
    eval `r.info -s human_abs_risk_log_${YEAR}${MONTH2D}`
    if [ $FIRST -eq 1 ] ; then
      FIRST=0
      TOTAL_LOG_H_ABS_MIN=$min
      TOTAL_LOG_H_ABS_MAX=$max
    else
      TOTAL_LOG_H_ABS_MIN=`echo $TOTAL_LOG_H_ABS_MIN $min | awk '{printf "%g\n", $1 < $2 ? $1 : $2}'`
      TOTAL_LOG_H_ABS_MAX=`echo $TOTAL_LOG_H_ABS_MAX $max | awk '{printf "%g\n", $1 > $2 ? $1 : $2}'`
    fi
    eval `r.info -s human_prop_risk_log_${YEAR}${MONTH2D}`
    if [ $FIRST -eq 1 ] ; then
      FIRST=0
      TOTAL_LOG_H_PROP_MIN=$min
      TOTAL_LOG_H_PROP_MAX=$max
    else
      TOTAL_LOG_H_PROP_MIN=`echo $TOTAL_LOG_H_PROP_MIN $min | awk '{printf "%g\n", $1 < $2 ? $1 : $2}'`
      TOTAL_LOG_H_PROP_MAX=`echo $TOTAL_LOG_H_PROP_MAX $max | awk '{printf "%g\n", $1 > $2 ? $1 : $2}'`
    fi
    eval `r.info -s livestock_abs_risk_log_${YEAR}${MONTH2D}`
    if [ $FIRST -eq 1 ] ; then
      FIRST=0
      TOTAL_LOG_L_ABS_MIN=$min
      TOTAL_LOG_L_ABS_MAX=$max
    else
      TOTAL_LOG_L_ABS_MIN=`echo $TOTAL_LOG_L_ABS_MIN $min | awk '{printf "%g\n", $1 < $2 ? $1 : $2}'`
      TOTAL_LOG_L_ABS_MAX=`echo $TOTAL_LOG_L_ABS_MAX $max | awk '{printf "%g\n", $1 > $2 ? $1 : $2}'`
    fi
    eval `r.info -s livestock_prop_risk_log_${YEAR}${MONTH2D}`
    if [ $FIRST -eq 1 ] ; then
      FIRST=0
      TOTAL_LOG_L_PROP_MIN=$min
      TOTAL_LOG_L_PROP_MAX=$max
    else
      TOTAL_LOG_L_PROP_MIN=`echo $TOTAL_LOG_H_PROP_MIN $min | awk '{printf "%g\n", $1 < $2 ? $1 : $2}'`
      TOTAL_LOG_L_PROP_MAX=`echo $TOTAL_LOG_H_PROP_MAX $max | awk '{printf "%g\n", $1 > $2 ? $1 : $2}'`
    fi
  done
done

# scale the log maps to be between 0 and 10 using to overall minima and maxima
for YEAR in `seq 2019 2023` ; do
  for MONTH in `seq 1 12` ; do
    MONTH2D=`prinf "%02d\n" $MONTH`

    # TODO: adjust to actual map names
    MAXENT_SUITABILITY="maxent_prefix_${YEAR}${MONTH2D}"

    # scale natural log of absolute number of humans at risk
    r.mapcalc "human_abs_risk_log_scaled_${YEAR}${MONTH2D} = ((human_abs_risk_log_${YEAR}${MONTH2D} - $TOTAL_LOG_H_ABS_MIN) / ($TOTAL_LOG_H_ABS_MAX - $TOTAL_LOG_H_ABS_MIN)) * 10.0"

    # scale natural log of proportion of humans at risk
    r.mapcalc "human_prop_risk_log_scaled_${YEAR}${MONTH2D} = ((human_prop_risk_log_${YEAR}${MONTH2D} - $TOTAL_LOG_H_PROP_MIN) / ($TOTAL_LOG_H_PROP_MAX - $TOTAL_LOG_H_PROP_MIN)) * 10.0"

    # scale natural log of absolute number of livestock at risk
    r.mapcalc "livestock_abs_risk_log_scaled_${YEAR}${MONTH2D} = ((livestock_abs_risk_log_${YEAR}${MONTH2D} - $TOTAL_LOG_L_ABS_MIN) / ($TOTAL_LOG_L_ABS_MAX - $TOTAL_LOG_L_ABS_MIN)) * 10.0"

    # scale natural log of proportion of livestock at risk
    r.mapcalc "livestock_prop_risk_log_scaled_${YEAR}${MONTH2D} = ((livestock_prop_risk_log_${YEAR}${MONTH2D} - $TOTAL_LOG_L_PROP_MIN) / ($TOTAL_LOG_L_PROP_MAX - $TOTAL_LOG_L_PROP_MIN)) * 10.0"

    # geometric mean for humans at risk
    r.mapcalc "human_geomean_${YEAR}${MONTH2D} = sqrt(human_abs_risk_log_scaled_${YEAR}${MONTH2D} * human_prop_risk_log_scaled_${YEAR}${MONTH2D})"

    # geometric mean for livestock at risk
    r.mapcalc "livestock_geomean_${YEAR}${MONTH2D} = sqrt(livestock_abs_risk_log_scaled_${YEAR}${MONTH2D} * livestock_prop_risk_log_scaled_${YEAR}${MONTH2D})"
  done
done

# quintile ranking for each spillover value from all geographic units (pixels), months, and years

# average quintile for each pixel and month across all years
