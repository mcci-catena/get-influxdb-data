#!/bin/bash

#
# Module: get-influxdb-data.sh
#
# Function:
#	Get raw influxdb as json (to stdout)
#
# Copyright:
#	See LICENSE file.
#
# Author:
#	Terry Moore, MCCI Corporation
#

# this doesn't work well on Windows due to console issues!
INFLUXDB_SERVER="ithaca-power.mcci.com"
INFLUXDB_DATASOURCE="iseechange-01"
INFLUXDB_SERIES="HeatData"
INFLUXDB_USER=tmm
typeset -i PRETTY=1
typeset -i DAYS=1

if [[ $PRETTY -ne 0 ]]; then
	INFLUXDB_OPTPRETTY="pretty=true"
else
	INFLUXDB_OPTPRETTY="pretty=false"
fi

curl -G --basic --user "${INFLUXDB_USER}" \
	"https://${INFLUXDB_SERVER}/influxdb:8086/query?${INFLUXDB_OPTPRETTY}" \
	--data-urlencode "db=${INFLUXDB_DATASOURCE}" \
	--data-urlencode 'q=SELECT 
		mean("t") * 1.8 + 32, 
		mean("rh"),
		mean("tDew"),
		mean("tHeatData"),
		mean("p"),
		mean("vBat")
		 from "'"${INFLUXDB_SERIES}"'" where time > now() - '$DAYS'd GROUP BY time(1ms), "displayName" fill(none)'

# end of file
