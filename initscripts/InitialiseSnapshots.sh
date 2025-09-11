#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This will determine the presence of the snapshot ids that we need
# If they don't exist on the filesystem already we check in the datastore. The
# process for generating snapshots writes the snapshot metadata to the datastore
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
BUILD_FROM_SNAPSHOT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_FROM_SNAPSHOT`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
DNS_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_CHOICE`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"

if (  [ "${BUILD_FROM_SNAPSHOT}" = "1" ] )
then
        snap_bucket="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`"
        snap_bucket="${snap_bucket}-${DNS_CHOICE}-snap"
        if ( [ ! -f ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat ] )
        then
                if ( [ ! -d ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots ] )
                then
                        /bin/mkdir -p ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots
                fi

                ${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${snap_bucket}/snapshot_ids.dat ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots
                ${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${snap_bucket}/db_credentials.dat.candidate ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots
                ${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${snap_bucket}/db_credentials.dat ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots
                ${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${snap_bucket}/credentials.dat ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots
        fi

        if ( [ ! -f ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat ] )
        then
                /bin/touch /tmp/END_IT_ALL
        fi

        /bin/echo "`/bin/grep webserver ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat | /usr/bin/awk -F':' '{print $NF}'`"
     #   ${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${snap_bucket}/keys.tar.gz ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots
        
     #   if ( [ -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys ] )
     #   then
     #           /bin/tar xvfz ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/keys.tar.gz -C ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys
     #   fi
fi
