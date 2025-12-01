#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This will take any assets that the script is configured to take out
# of a baseline that is being installed and copy the assets to the S3 datastore
# ready to be mounted into the webroot of your infrastructure's webserver(s)
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
DIRECTORIES_TO_MOUNT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DIRECTORIES_TO_MOUNT | /bin/sed 's/:/ /g'`"
PERSIST_ASSETS_TO_DATASTORE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PERSIST_ASSETS_TO_DATASTORE`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"

if ( [ "${PERSIST_ASSETS_TO_DATASTORE}" = "1" ] )
then
        interrogation_home="${BUILD_HOME}/interrogation"
        for directory_to_mount in ${DIRECTORIES_TO_MOUNT}
        do
                if ( [ "`/bin/echo ${directory_to_mount} | /bin/grep 'merge='`" = "" ] )
                then
                        subdir="${directory_to_mount}"        
                        directory_to_mount="`/bin/echo ${directory_to_mount} | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                        asset_datastore="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`-assets-${directory_to_mount}"

                        ${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh "${asset_datastore}"

                        if ( [ -f ${interrogation_home}/${subdir} ] )
                        then
                                if ( [ ! -z "`/bin/ls ${interrogation_home}/${subdir}`" ] )
                                then
                                        ${BUILD_HOME}/providerscripts/datastore/SyncDatastore.sh ${interrogation_home}/${subdir}/ ${asset_datastore}
                                fi
                        fi
                fi
        done
fi
