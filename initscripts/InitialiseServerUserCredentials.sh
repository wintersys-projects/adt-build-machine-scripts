#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This will generate and store our bespoke user credentials for this deployment
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
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
BUILD_FROM_SNAPSHOT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_FROM_SNAPSHOT`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"

#Set a username and password which we can set on all our servers. Once the machines are built, password authentication is
#switched off and you can find some ssh key based helper scripts here that will enable you to authenticate to your machines.
if ( [ "${BUILD_FROM_SNAPSHOT}" = "1" ] && [ -f ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/credentials.dat ] )
then
	status "Building from whole machine snapshots, server username and server password set to already existing values"
	SERVER_USER="`/bin/grep 'USERNAME' ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/credentials.dat | /usr/bin/awk -F':' '{print $NF}'`"
	SERVER_USER_PASSWORD="`/bin/grep 'PASSWORD' ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/credentials.dat | /usr/bin/awk -F':' '{print $NF}'`"
else
	status "Perfoming a regular build (not from whole machine snapshots), server username and server password being freshly generated"
	SERVER_USER="X`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-18`X"
	SERVER_USER_PASSWORD="`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-18`"
fi

/bin/echo "${SERVER_USER}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER
/bin/echo "${SERVER_USER_PASSWORD}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD
${BUILD_HOME}/helperscripts/SetVariableValue.sh "SERVER_USER=${SERVER_USER}"
${BUILD_HOME}/helperscripts/SetVariableValue.sh "SERVER_USER_PASSWORD=${SERVER_USER_PASSWORD}"

/bin/echo "${REGION}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/CURRENTREGION
