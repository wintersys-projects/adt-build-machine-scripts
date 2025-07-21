#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This script sets up all the security keys needed by the infrastructure.
# Every time a new build is run, it removes the old keys and generates fresh new ones
# for usage. PLEASE NOTE: These keys will be written to your build client underneath
# 'the "keys" directory. You must keep these keys safe, if they leak, then your
# infrastructure could be compromised.
##################################################################################
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
####################################################################################
####################################################################################
#set -x

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`" 
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
ALGORITHM="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ALGORITHM`"

BUILD_KEY="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"

if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys ] )
then
	/bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys
else
	/bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/* 2>/dev/null
fi

if ( [ -f ${BUILD_KEY} ] )
then
	/bin/rm ${BUILD_KEY}
fi
if ( [ -f ${BUILD_KEY}.pub ] )
then
	/bin/rm ${BUILD_KEY}.pub
fi

if ( [ "${ALGORITHM}" = "rsa" ] )
then
	/usr/bin/ssh-keygen -t rsa -b 4096 -N "" -f ${BUILD_KEY}
elif ( [ "${ALGORITHM}" = "ecdsa" ] )
then
	/usr/bin/ssh-keygen -t ecdsa -b 521 -N "" -f ${BUILD_KEY}
elif ( [ "${ALGORITHM}" = "ed25519" ] )
then
	/usr/bin/ssh-keygen -t ed25519 -b 521 -N "" -f ${BUILD_KEY}
fi



/bin/chmod 700 ${BUILD_KEY}
/bin/chmod 700 ${BUILD_KEY}.pub

