#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This will create the DNS record for your current domain and is called
# at the end of building a webserver
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
        /bin/echo "${script_name}: ${1}" >> /dev/fd/4  2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
DIRECTORIES_TO_MOUNT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DIRECTORIES_TO_MOUNT | /bin/sed 's/:/ /g'`"
PERSIST_ASSETS_TO_CLOUD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PERSIST_ASSETS_TO_CLOUD`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"

if ( [ "${PERSIST_ASSETS_TO_CLOUD}" = "1" ] )
then
        interrogation_home="${BUILD_HOME}/interrogation/tmp/backup"
        for directory_to_mount in ${DIRECTORIES_TO_MOUNT}
        do
                if ( [ "${directory_to_mount}" = "WHOLE-WEBROOT" ] )
                then
                        subdir=""
                else
                        subdir="${directory_to_mount}"
                fi
                directory_to_mount="`/bin/echo ${directory_to_mount} | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                asset_datastore="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`-assets-${directory_to_mount}"

                ${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh "${asset_datastore}"

                if ( [ ! -z "`/bin/ls ${interrogation_home}/${subdir}`" ] )
                then
                        ${BUILD_HOME}/providerscripts/datastore/SyncDatastore.sh ${interrogation_home}/${subdir}/ ${asset_datastore}
                fi

        done
fi
