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

typeset OPTPNAME="$(basename "$0")"
typeset OPTPDIR="$(dirname "$0")"

function _verbose {
	if [[ $OPTVERBOSE -ne 0 ]]; then
		echo -E "$OPTPNAME:" "$@" 1>&2
	fi
}

function _debug {
	if [[ $OPTDEBUG -ne 0 ]]; then
		echo -E "$OPTPNAME:" "$@" 1>&2
	fi
}

function _fatal {
	echo -E "$OPTPNAME: Fatal: " "$@" 1>&2
	exit 1
}


# this doesn't work well on Windows due to console issues!
typeset -r INFLUXDB_SERVER_DFLT="ithaca-power.mcci.com"
typeset -r INFLUXDB_DB_DFLT="iseechange-01"
typeset -r INFLUXDB_SERIES_DFLT="HeatData"
typeset -r INFLUXDB_USER_DFLT="nobody"
typeset -i DAYS_DFLT=1

#### argument scanning:  usage ####
typeset -r USAGE="${PNAME} -[Dhpv d* O* S* s* t* u*]"

# produce the help message.
function _help {
	more 1>&2 <<.

Name:	$PNAME

Function:
	Get influx data from specified server, as json.

Usage:
	$USAGE

Operation:
	A query is constructed and sent to the server, and data is returned.

Options:
	-h		displays help (this message), and exits.

	-v		talk about what we're doing.

	-D		operate in debug mode.

	-d {database}	the database within the server; default is $INFLUXDB_DB_DFLT.

	-p		pretty-print the output; -np minifies the output.

	-S {fqdn}	domain name of server; default is $INFLUXDB_SERVER_DFLT.

	-s {series}	data series name; default is $INFLUXDB_SERIES_DEFAULT

	-t {days}	how many days to look back. Default is $DAYS_DFLT

	-u {userid}	the login to be used for the query; default is $INFLUXDB_USER_DFLT.
.
}

typeset -i OPTDEBUG=0
typeset -i OPTVERBOSE=0
typeset -i PRETTY=1
typeset INFLUXDB_SERVER="$INFLUXDB_SERVER_DFLT"
typeset INFLUXDB_DB="$INFLUXDB_DB_DFLT"
typeset INFLUXDB_SERIES="$INFLUXDB_SERIES_DFLT"
typeset INFLUXDB_USER="$INFLUXDB_USER_DFLT"
typeset -i DAYS=$DAYS_DFLT

typeset -i NEXTBOOL=1
while getopts hvnDd:pS:s:t:u: c
do
	if [ $NEXTBOOL -eq -1 ]; then
		NEXTBOOL=0
	else
		NEXTBOOL=1
	fi

	if [ $OPTDEBUG -ne 0 ]; then
		echo "Scanning option -${c}" 1>&2
	fi

	case $c in
	D)	OPTDEBUG=$NEXTBOOL;;
	h)	_help
		exit 0
		;;
	n)	NEXTBOOL=-1;;
	v)	OPTVERBOSE=$NEXTBOOL;;
	d)	INFLUXDB_DB="$OPTARG";;
	p)	PRETTY=$NEXTBOOL;;
	S)	INFLUXDB_SERVER="$OPTARG";;
	s)	INFLUXDB_SERIES="$OPTARG";;
	t)	DAYS="$OPTARG"
		if [[ "$DAYS" != "$OPTARG" ]]; then
			_fatal "-t #: not a valid number of days: $OPTARG"
		fi
		;;
	u)	INFLUXDB_USER="$OPTARG";;
	\?)	echo "$USAGE"
		exit 1;;
	esac
done

#### get rid of scanned options ####
shift $((OPTIND - 1))


if [[ $PRETTY -ne 0 ]]; then
	INFLUXDB_OPTPRETTY="pretty=true"
else
	INFLUXDB_OPTPRETTY="pretty=false"
fi

_verbose curl -G --basic --user "${INFLUXDB_USER}" \
	"https://${INFLUXDB_SERVER}/influxdb:8086/query?${INFLUXDB_OPTPRETTY}" \
	--data-urlencode "db=${INFLUXDB_DB}" \
	--data-urlencode 'q=SELECT 
		mean("t")	 	as "t", 
		mean("rh")		as "rh",
		mean("tDew")		as "tDew",
		mean("tHeatData")	as "tHeatIndex",
		mean("p")		as "p",
		mean("vBat")		as "vBat"
		 from "'"${INFLUXDB_SERIES}"'" where time > now() - '$DAYS'd GROUP BY time(1ms), "displayName" fill(none)'

curl -G --basic --user "${INFLUXDB_USER}" \
	"https://${INFLUXDB_SERVER}/influxdb:8086/query?${INFLUXDB_OPTPRETTY}" \
	--data-urlencode "db=${INFLUXDB_DB}" \
	--data-urlencode 'q=SELECT 
		mean("t")	 	as "t", 
		mean("rh")		as "rh",
		mean("tDew")		as "tDew",
		mean("tHeatData")	as "tHeatIndex",
		mean("p")		as "p",
		mean("vBat")		as "vBat"
		 from "'"${INFLUXDB_SERIES}"'" where time > now() - '$DAYS'd GROUP BY time(1ms), "displayName" fill(none)'

# end of file
