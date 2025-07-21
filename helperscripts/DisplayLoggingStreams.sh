#!/bin/sh
###########################################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This is just a shortcut error script for displaying your output or error logs from your current build
# There is a wrapper script ${BUILD_HOME}/Log.sh which calls this script and is easier to use
###########################################################################################################
# License Agreement:
# This file is part of The Agile Deployment Toolkit.
# The Agile Deployment Toolkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# The Agile Deployment Toolkit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with The Agile Deployment Toolkit.  If not, see <http://www.gnu.org/licenses/>.
#######################################################################################################
#######################################################################################################
#set -x

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

if ( [ "${1}" != "" ] && [ "${2}" != "" ] && [ "${3}" != "" ]  && [ "${4}" != "" ] )
then
	CLOUDHOST="${1}"
	BUILD_IDENTIFIER="${2}"
	response="${3}"
	response1="${4}"
else 
	/bin/echo "Which cloudhost do you want to view logs for DigitalOcean (do), Exoscale (exo), Linode (lin) or Vultr (vul)"
	/bin/echo "Please type one of do, exo, lin, vul"
	read cloudhost
fi

if ( [ "${cloudhost}" = "do" ] || [ "${CLOUDHOST}" = "do" ] )
then
	CLOUDHOST="digitalocean"
elif ( [ "${cloudhost}" = "exo" ] || [ "${CLOUDHOST}" = "exo" ] )
then
	CLOUDHOST="exoscale"
elif ( [ "${cloudhost}" = "lin" ] || [ "${CLOUDHOST}" = "lin" ] )
then
	CLOUDHOST="linode" 
elif ( [ "${cloudhost}" = "vul" ] || [ "${CLOUDHOST}" = "vul" ] )
then
	CLOUDHOST="vultr"
fi

if ( [ "${CLOUDHOST}" != "`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_CLOUDHOST`" ] )
then
	/bin/echo "Your chosen cloudhost provider is different to your active cloudhost provider on this build machine"
	/bin/echo "Do you want to set your chosen cloudhost to be the active cloudhost provider (Y|y)"
	read response
	if ( [ "${response}" = "Y" ] || [ "${response}" = "y" ] )
	then
		/bin/echo "${CLOUDHOST}" > ${BUILD_HOME}/runtimedata/ACTIVE_CLOUDHOST
	fi
fi

if ( [ "${BUILD_IDENTIFIER}" = "" ] )
then
	/bin/echo "What is the build identifier you want to connect to?"
	/bin/echo "You have these builds to choose from: "

	/bin/ls ${BUILD_HOME}/runtimedata/${CLOUDHOST}

	/bin/echo "Please enter the name of the build of the server you wish to connect with"
	read BUILD_IDENTIFIER
fi

if ( [ "${response}" = "" ] )
then
	/bin/echo "tail (t) or cat (c) or vim (v)"
	read response
fi

if ( [ "${response1}" = "" ] )
then
	/bin/echo "Do you want out (1) or err (2) or stat (3)"
	read response1
fi

error_stream="`/bin/ls -ltr ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs | /bin/grep build_err | /usr/bin/tail -1 | /usr/bin/awk '{print $NF}'`"
output_stream="`/bin/ls -ltr ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs | /bin/grep build_out | /usr/bin/tail -1 | /usr/bin/awk '{print $NF}'`"
status_stream="`/bin/ls -ltr ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs | /bin/grep build_stat | /usr/bin/tail -1 | /usr/bin/awk '{print $NF}'`"
if ( [ "${response1}" = "1" ] )
then
	if ( [ "${response}" = "t" ] )
	then
		/bin/tail -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${output_stream}
	elif ( [ "${response}" = "c" ] )
	then
		/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${output_stream}
	elif ( [ "${response}" = "v" ] )
	then
		/usr/bin/vi ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${output_stream}
	fi
elif ( [ "${response1}" = "2" ] )
then
	if ( [ "${response}" = "t" ] )
	then
		/bin/tail -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${error_stream}
	elif ( [ "${response}" = "c" ] )
	then
		/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${error_stream}
	elif ( [ "${response}" = "v" ] )
	then
		/usr/bin/vi ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${error_stream}
	fi
elif ( [ "${response1}" = "3" ] )
then
	if ( [ "${response}" = "t" ] )
	then
		/bin/tail -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${status_stream}
	elif ( [ "${response}" = "c" ] )
	then
		/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${status_stream}
	elif ( [ "${response}" = "v" ] )
	then
		/usr/bin/vi ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${status_stream}
	fi
fi

