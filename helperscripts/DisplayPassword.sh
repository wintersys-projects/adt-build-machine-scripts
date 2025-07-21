#!/bin/sh
###########################################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This is just a shortcut error script for displaying your password for a build
# There is a wrapper script ${BUILD_HOME}/Password.sh which calls this script and is easier to use
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

if ( [ "${1}" != "" ] && [ "${2}" != "" ] )
then
	CLOUDHOST="${1}"
	BUILD_IDENTIFIER="${2}"
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

/bin/echo "The server password is:"
/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD
