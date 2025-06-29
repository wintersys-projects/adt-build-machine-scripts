#!/bin/sh
####################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will create a snapshot of a machine
####################################################################################
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
#####################################################################################
#####################################################################################
#set -x

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"

/bin/echo "Do you want to snapshot an 1. authenticator, 2. reverse proxy, 3. autoscaler, 4. webserver or 5. database machine type?"
/bin/echo "Please enter a value between 1 and 5 to make a selection"
read response

while ( [ "`/bin/echo "1 2 3 4 5" | /bin/grep "${response}"`" = "" ] )
do
        /bin/echo "Invalid input, please try again"
        read response
done

if ( [ "${response}" = "1" ] )
then
    machine_type="^auth-"
elif ( [ "${response}" = "2" ] )
then
    machine_type="\-rp-"
elif ( [ "${response}" = "3" ] )
then
   machine_type="\-as-"
elif ( [ "${response}" = "4" ] )
then
    machine_type="^ws-"
elif ( [ "${response}" = "5" ] )
then
    machine_type="^db-"
else
        /bin/echo "Unrecognised response"
        exit
fi

machine_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "${machine_type}-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} | /usr/bin/head -n 1`"

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
        machine_id="`/usr/local/bin/doctl compute droplet list | /bin/grep autoscaler | /usr/bin/awk '{print $1}'`"
        machine_name="`/usr/local/bin/doctl compute droplet list | /bin/grep autoscaler | /usr/bin/awk '{print $2}'`"

        /bin/echo "########################SNAPSHOTING YOUR MACHINE####################################"

        /usr/local/bin/doctl compute droplet-action snapshot --snapshot-name "${machine_name}" ${machine_id}
fi

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
        region_id="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/CURRENTREGION`"

        /bin/echo "########################SNAPSHOTING YOUR MACHNIE IN THE BACKGROUND####################################"

        machine_name="`/usr/bin/exo compute instance list --zone ${region_id} -O json | /usr/bin/jq -r '.[].name'`"
        machine_id="`/usr/bin/exo compute instance list --zone ch-gva-2 -O json | /usr/bin/jq -r '.[] | select ( .name == "'${machine_name}'").id'`"
        /usr/bin/exo compute instance snapshot create -z ${region_id} ${machine_id}
        snapshot_id="`/usr/bin/exo compute instance snapshot list -O json  | /usr/bin/jq -r '.[] | select ( .instance == "'${machine_name}'").id'`"
        /bin/echo "Is the machine you  are snapshotting  based on 1) ubuntu or 2) debian?"
        /bin/echo "Please enter a value of 1 or 2 to make a choice"
        read response

        while ( [ "`/bin/echo 1 2 | /bin/grep "${response}"`" = "" ] )
        do
                /bin/echo "Invalid resonose, try again"
                read response
        done

        if ( [ "${response}" = "1" ] )
        then
                target_os="ubuntu"
        elif ( [ "${response}" = "2" ] )
        then
                target_os="debian"
        else
                /bin/echo "Unrecognised response"
                exit
        fi

        /usr/bin/exo compute instance-template register --boot-mode legacy --disable-password --from-snapshot ${snapshot_id} --zone ${region_id} --username ${target_os} ${machine_name} 
fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then
        machine_name="`/usr/local/bin/linode-cli linodes list --json | /usr/bin/jq -r '.[] | select (.id == "'${machine_id}'").label'`"
        disk_id="`/usr/local/bin/linode-cli linodes disks-list ${machine_id} --json | /usr/bin/jq -r '.[] | select (.filesystem == "ext4").id'`"
        /bin/echo "########################SNAPSHOTTING YOUR MACHINE####################################"
        /usr/local/bin/linode-cli images create --disk_id ${disk_id} --label ${machine_name}
fi

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
        export VULTR_API_KEY="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/TOKEN`"

        SUBID="`/usr/bin/vultr instance list | /bin/grep  autoscaler | /usr/bin/awk '{print $1}' | /usr/bin/head -1`"
        /bin/echo "########################SNAPSHOTING YOUR MACHINE IN THE BACKGROUND####################################"
        /usr/bin/vultr snapshot create -i ${SUBID} -d "autoscaler-${SERVER_USER}"
        /bin/touch ${HOME}/.ssh/SNAPSHOT:${SUBID}
fi
