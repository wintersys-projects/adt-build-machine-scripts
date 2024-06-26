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

BUILD_KEY="${BUILD_HOME}/keys/${CLOUDHOST}/${BUILD_IDENTIFIER}/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"

TOKEN=""

if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/TOKEN ] )
then
	TOKEN="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/TOKEN 2>/dev/null`"
fi

if ( [ "${TOKEN}" = "" ] )
then
	TOKEN="none"
fi

if ( [ ! -d ${BUILD_HOME}/keys/${CLOUDHOST}/${BUILD_IDENTIFIER} ] )
then
	/bin/mkdir -p ${BUILD_HOME}/keys/${CLOUDHOST}/${BUILD_IDENTIFIER}
else
	/bin/rm ${BUILD_HOME}/keys/${CLOUDHOST}/${BUILD_IDENTIFIER}/* 2>/dev/null
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
fi

/bin/chmod 700 ${BUILD_KEY}
/bin/chmod 700 ${BUILD_KEY}.pub

#Use a varaible for easy access to the build key

if ( [ "${GENERATE_SNAPSHOTS}" = "1" ] )
then
	snapshot_id="`/bin/echo ${SERVER_USER} | /usr/bin/cut -c1-4`"
	key_name="${snapshot_id}-${PUBLIC_KEY_NAME}-${BUILD_IDENTIFIER}"
	${BUILD_HOME}/providerscripts/security/DeleteSSHKeyPair.sh "${key_name}" "${TOKEN}" ${CLOUDHOST}
	${BUILD_HOME}/providerscripts/security/RegisterSSHKeyPair.sh "${key_name}" "${TOKEN}" "`/bin/cat ${BUILD_KEY}.pub`" ${CLOUDHOST}
elif ( [ "${AUTOSCALE_FROM_SNAPSHOTS}" = "1" ] )
then
	snapshot_id="`/bin/echo ${SNAPSHOT_ID} | /usr/bin/cut -c1-4`"
	key_name="${snapshot_id}-${PUBLIC_KEY_NAME}-${BUILD_IDENTIFIER}"
else
	key_name="${PUBLIC_KEY_NAME}-${BUILD_IDENTIFIER}"
	${BUILD_HOME}/providerscripts/security/DeleteSSHKeyPair.sh "${key_name}" "${TOKEN}" ${CLOUDHOST}
	${BUILD_HOME}/providerscripts/security/RegisterSSHKeyPair.sh "${key_name}" "${TOKEN}" "`/bin/cat ${BUILD_KEY}.pub`" ${CLOUDHOST}
fi

PUBLIC_KEY_ID="`${BUILD_HOME}/providerscripts/security/GetSSHKeyID.sh \"${key_name}\" ${CLOUDHOST}`"

if ( [ ! -d ${BUILD_HOME}/buildconfiguration/${CLOUDHOST}/${BUILD_IDENTIFIER}-credentials ] )
then
	/bin/mkdir -p ${BUILD_HOME}/buildconfiguration/${CLOUDHOST}/${BUILD_IDENTIFIER}-credentials
fi

/bin/echo ${key_name} > ${BUILD_HOME}/buildconfiguration/${CLOUDHOST}/${BUILD_IDENTIFIER}-credentials/PUBLICKEYNAME
/bin/echo ${PUBLIC_KEY_ID} > ${BUILD_HOME}/buildconfiguration/${CLOUDHOST}/${BUILD_IDENTIFIER}-credentials/PUBLICKEYID
