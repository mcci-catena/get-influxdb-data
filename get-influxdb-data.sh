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
	echo -E "$OPTPNAME: Fatal:" "$@" 1>&2
	exit 1
}


# this doesn't work well on Windows due to console issues!
typeset -r INFLUXDB_SERVER_DFLT="ithaca-power.mcci.com"
typeset -r INFLUXDB_DB_DFLT="iseechange-01"
typeset -r INFLUXDB_SERIES_DFLT="HeatData"
typeset -r INFLUXDB_USER_DFLT="nobody"
typeset -r INFLUXDB_QUERY_VARS_DFLT='t,rh,tDew,mean("tHeatData") as "tHeatIndex",p,vBat'
typeset -r INFLUXDB_QUERY_WHERE_DFLT='time > now() - 1d'
typeset -r INFLUXDB_QUERY_GROUP_DFLT='time(1ms), "displayName"'
typeset -r INFLUXDB_QUERY_FILL_DFLT="none"
typeset -r MORE=less
typeset -i DAYS_DFLT=1

#### argument scanning:  usage ####
typeset -r USAGE="${PNAME} -[Dhpv d* f* g* q* S* s* t* u* w*]"

# produce the help message.
function _help {
	$MORE 1>&2 <<.

Name:	$OPTPNAME

Function:
	Get influx data from specified server, as json.

Usage:
	$USAGE

Operation:
	A query is constructed and sent to the server, and data is returned to stdout.

Options:
	-h		displays help (this message), and exits.

	-v		talk about what we're doing.

	-D		operate in debug mode.

	-d {database}	the database within the server; default: $INFLUXDB_DB_DFLT.

	-f {fill}	the fill value. -f- means no fill clause. Default is
			$INFLUXDB_QUERY_FILL_DFLT

	-g {group}	the group clause. Default is $INFLUXDB_QUERY_GROUP_DFLT.

	-p		pretty-print the output; -np minifies the output.

	-q {vars}	the variables to query. Default is:

			$INFLUXDB_QUERY_VARS_DFLT

	-S {fqdn}	domain name of server; default is $INFLUXDB_SERVER_DFLT.

	-s {measurement} measurement series name; default is $INFLUXDB_SERIES_DFLT

	-t {days}	how many days to look back. Default is $DAYS_DFLT

	-u {userid}	the login to be used for the query; default is $INFLUXDB_USER_DFLT.

	-w {where}	the where clause. Default: $INFLUXDB_QUERY_WHERE_DFLT

Positional arguments:
	No positional arguments are availalbe.

Examples:
	To fetch the last 36 days as user somebody from default source and
	series, do the following. (The -v option causes the script to display
	the curl command.)

	\$ $OPTPNAME -u somebody -v -t36 > /tmp/data.json
	get-influxdb-data.sh: curl -G --basic --user somebody https://ithaca-power.mcci.com/influxdb:8086/query?pretty=true --data-urlencode db=iseechange-01 --data-urlencode q=SELECT mean("t") as "t",mean("rh") as "rh",mean("tDew") as "tDew",mean("tHeatData") as "tHeatIndex",mean("p") as "p",mean("vBat") as "vBat" from "HeatData" where time > now() - 36d GROUP BY time(1ms), "displayName" fill(none)
	Enter host password for user 'somebody':
	  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
	                                 Dload  Upload   Total   Spent    Left  Speed
	100   469  100   469    0     0   1486      0 --:--:-- --:--:-- --:--:--  1488
	\$

	To get all the data for sensor holt-46, between 2018-01-01 and
	2019-01-01 (note use of UTC and quoting of queries):

	\$ $OPTPNAME -u somebody -d ithaca-power -s ithaca-power \\
	    -q 'mean("powerUsed") * 2.5 as "powerUsed"' \\
	    -w '("devID" = '\''holt-46'\'') AND time >= '\''2018-01-01T04:00:00Z'\'' AND time < '\''2019-01-01T04:00:00Z'\' \\
	    -g 'time(1ms), "devID"' > /tmp/data.json -v
	get-influxdb-data.sh: curl -G --basic --user somebody https://ithaca-power.mcci.com/influxdb:8086/query?pretty=true --data-urlencode db=ithaca-power --data-urlencode q=SELECT mean("powerUsed") * 2.5 as "powerUsed" from "ithaca-power" where ("devID" = 'holt-46') AND time >= '2018-01-01T04:00:00Z' AND time < '2019-01-01T04:00:00Z' GROUP BY time(1ms), "devID" fill(none)
	  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
	                                 Dload  Upload   Total   Spent    Left  Speed
	100 10.0M    0 10.0M    0     0  1341k      0 --:--:--  0:00:07 --:--:-- 1762k
	\$
.
}

typeset -i OPTDEBUG=0
typeset -i OPTVERBOSE=0
typeset -i PRETTY=1
typeset INFLUXDB_SERVER="$INFLUXDB_SERVER_DFLT"
typeset INFLUXDB_DB="$INFLUXDB_DB_DFLT"
typeset INFLUXDB_SERIES="$INFLUXDB_SERIES_DFLT"
typeset INFLUXDB_USER="$INFLUXDB_USER_DFLT"
typeset INFLUXDB_QUERY_FILL="$INFLUXDB_QUERY_FILL_DFLT"
typeset INFLUXDB_QUERY_GROUP="$INFLUXDB_QUERY_GROUP_DFLT"
typeset INFLUXDB_QUERY_VARS="$INFLUXDB_QUERY_VARS_DFLT"
typeset INFLUXDB_QUERY_WHERE="$INFLUXDB_QUERY_WHERE_DFLT"
typeset -i DAYS=$DAYS_DFLT

typeset -i NEXTBOOL=1
while getopts hvnDd:f:g:pq:S:s:t:u:w: c
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
	f)	INFLUXDB_QUERY_FILL="$OPTARG";;
	g)	INFLUXDB_QUERY_GROUP="$OPTARG";;
	p)	PRETTY=$NEXTBOOL;;
	q)	INFLUXDB_QUERY_VARS="$OPTARG";;
	S)	INFLUXDB_SERVER="$OPTARG";;
	s)	INFLUXDB_SERIES="$OPTARG";;
	t)	DAYS="$OPTARG"
		if [[ "$DAYS" != "$OPTARG" ]]; then
			_fatal "-t #: not a valid number of days: $OPTARG"
		fi
		INFLUXDB_QUERY_WHERE="time > now() - ${DAYS}d"
		;;
	u)	INFLUXDB_USER="$OPTARG";;
	w)	INFLUXDB_QUERY_WHERE="$OPTARG";;
	\?)	echo "$USAGE"
		exit 1;;
	esac
done

#### get rid of scanned options ####
shift $((OPTIND - 1))

if [[ $# != 0 ]]; then
	_fatal "extra arguments:" "$@"
fi

if [[ $PRETTY -ne 0 ]]; then
	INFLUXDB_OPTPRETTY="pretty=true"
else
	INFLUXDB_OPTPRETTY="pretty=false"
fi

#### calculate the vars from the query. input is a comma-separated list of specs.
#### each spec is either a simple name, or 'expr as label'
function _expandquery {
	{ printf "%s\n" "$@" |
		awk 'BEGIN { FS=","; OFS="," }
		     { for (i=1; i <= NF; ++i)
		     	{
			if ($i ~ /^[a-zA-Z0-9_.-]+$/)
				$i = "mean(\"" $i "\") as \"" $i "\""
		     	}
			print;
		     }
		' ; } || _fatal "_expandquery failed:" "$@"
}

typeset QUERY_VAR_STRING
_expandquery "$INFLUXDB_QUERY_VARS" >/dev/null
QUERY_VAR_STRING="$(_expandquery "$INFLUXDB_QUERY_VARS")"

typeset QUERY_FILL_STRING
if [[ "$INFLUXDB_QUERY_FILL" != "-" ]]; then
	QUERY_FILL_STRING=" fill($INFLUXDB_QUERY_FILL)"
else
	QUERY_FILL_STRING=
fi

typeset QUERY_STRING='SELECT '"${QUERY_VAR_STRING}"' from "'"${INFLUXDB_SERIES}"'" where '"${INFLUXDB_QUERY_WHERE}"' GROUP BY '"${INFLUXDB_QUERY_GROUP}${QUERY_FILL_STRING}" || _fatal "_expandquery failed"
_verbose curl -G --basic --user "${INFLUXDB_USER}" \
	"https://${INFLUXDB_SERVER}/influxdb:8086/query?${INFLUXDB_OPTPRETTY}" \
	--data-urlencode "db=${INFLUXDB_DB}" \
	--data-urlencode "q=$QUERY_STRING"

curl -G --basic --user "${INFLUXDB_USER}" \
	"https://${INFLUXDB_SERVER}/influxdb:8086/query?${INFLUXDB_OPTPRETTY}" \
	--data-urlencode "db=${INFLUXDB_DB}" \
	--data-urlencode "q=$QUERY_STRING"

# end of file
