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
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
DNS_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_CHOICE`"

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
	machine_type="auth"
	machine_label="authenticator"
elif ( [ "${response}" = "2" ] )
then
	machine_type="-rp"
	machine_label="reverseproxy"
elif ( [ "${response}" = "3" ] )
then
	machine_type="-as"
	machine_label="autoscaler"
elif ( [ "${response}" = "4" ] )
then
	machine_type="ws"
	machine_label="webserver"
elif ( [ "${response}" = "5" ] )
then
	machine_type="db"
	machine_label="database"
else
	/bin/echo "Unrecognised response"
	exit
fi

if ( [ ! -d ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots ] )
then
	/bin/mkdir -p ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots
fi

SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"

/bin/echo "USERNAME:${SERVER_USER}" > ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/credentials.dat
/bin/echo "PASSWORD:${SERVER_USER_PASSWORD}" >> ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/credentials.dat

if ( [ ! -d ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots ] )
then
	/bin/mkdir -p ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots
fi

if ( [ -f ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/db_credentials.dat.candidate ] )
then
	/bin/cp ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/db_credentials.dat.candidate ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/db_credentials.dat
fi

machine_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "${machine_type}-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} | /usr/bin/head -n 1`"

if ( [ "${machine_id}" = "" ] )
then
	/bin/echo "Sorry couldn't find a machine of type ${machine_label} to generate a snapshot of"
	/bin/echo "I have to exit, please investigate"
	exit
fi

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
	machine_name="`/usr/local/bin/doctl compute droplet list -o json | /usr/bin/jq -r '.[] | select (.id == '${machine_id}' ).name'`"

	if ( [ "${machine_name}" = "" ] )
	then
		/bin/echo "Couldn't find a machine to snapshot"
		exit
	fi
	if ( [ "`/usr/local/bin/doctl compute snapshot list -o json | /usr/bin/jq '.[] | select (.name == "'${machine_name}'").id'`" != "" ] )
	then
		/bin/echo "A snapshot for machine ${machine_name} already exists, delete it and retry if you want to generate a new snapshot"
		exit
	fi

	/bin/echo "##############################################################################################"
	/bin/echo "################MAKING A SNAPSHOT OF MACHINE: ${machine_name} #####################"
	/bin/echo "##############################################################################################"

	/usr/local/bin/doctl compute droplet-action snapshot --snapshot-name "${machine_name}" ${machine_id}

	/bin/echo "Trying to verify newly generated snapshot  - this should take less than one minute"
	while ( [ "`/usr/local/bin/doctl compute snapshot list -o json | /usr/bin/jq -r '.[] | select (.name == "'${machine_name}'").id'`" = "" ] )
	do
		/bin/sleep 5
	done

	snapshot_id="`/usr/local/bin/doctl compute snapshot list -o json | /usr/bin/jq -r '.[] | select (.name == "'${machine_name}'").id'`" 

	/bin/echo "Successfully obtained snasphot id:${snapshot_id}"

	/bin/echo "Trying to update stored snapshot ids located at: ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat"

	if ( [ -f ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat ] )
	then
		if ( [ "`/bin/grep ${machine_label} ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat`" != "" ] )
		then
			/bin/sed -i "s/.*${machine_label}.*/${machine_label}:${snapshot_id}/" ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat
		else
			/bin/echo "${machine_label}:${snapshot_id}" >> ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat
		fi
		/bin/echo "Stored snapshot ids updated"
	else
		/bin/echo "${machine_label}:${snapshot_id}" > ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat
		/bin/echo "Stored snapshot ids generated"
	fi
fi

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
	region_id="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/CURRENTREGION`"
	machine_name="`/usr/bin/exo compute instance list --zone ${region_id} -O json | /usr/bin/jq -r '.[] | select (.name | contains ( "'${machine_type}'-'${region_id}'-'${BUILD_IDENTIFIER}'")).name' | /usr/bin/head -1`"
	machine_id="`/usr/bin/exo compute instance list --zone ch-gva-2 -O json | /usr/bin/jq -r '.[] | select ( .name == "'${machine_name}'").id'`"


	/bin/echo "##############################################################################################"
	/bin/echo "################MAKING A SNAPSHOT OF MACHINE: ${machine_name} #####################"
	/bin/echo "##############################################################################################"

	/usr/bin/exo compute instance snapshot create -z ${region_id} ${machine_id}
	snapshot_id="`/usr/bin/exo compute instance snapshot list -O json  | /usr/bin/jq -r '.[] | select ( .instance == "'${machine_name}'").id'`"
	/bin/echo "Is the machine you  are snapshotting  based on 1) ubuntu or 2) debian?"
	/bin/echo "Please enter a value of 1 or 2 to make a choice"
	read response

	while ( [ "`/bin/echo 1 2 | /bin/grep "${response}"`" = "" ] )
	do
		/bin/echo "Invalid response, try again"
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

	snapshot_id="`/usr/bin/exo compute instance-template register --boot-mode legacy --disable-password --from-snapshot ${snapshot_id} --zone ${region_id} --username ${target_os} ${machine_name} -O json | /usr/bin/jq -r '.id'`"
fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then
	machine_name="`/usr/local/bin/linode-cli linodes list --no-defaults --json | /usr/bin/jq -r '.[] | select (.id == '${machine_id}').label'`"
	disk_id="`/usr/local/bin/linode-cli linodes disks-list ${machine_id} --no-defaults --json | /usr/bin/jq -r '.[] | select (.filesystem == "ext4").id'`"

	/bin/echo "##############################################################################################"
	/bin/echo "################MAKING A SNAPSHOT OF MACHINE: ${machine_label} #####################"
	/bin/echo "##############################################################################################"

	snapshot_id="`/usr/local/bin/linode-cli images create --disk_id ${disk_id} --label ${machine_name} --no-defaults --json | /usr/bin/jq -r '.[].id'`"
fi

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
	export VULTR_API_KEY="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/TOKEN`"

	if ( [ "`/usr/bin/vultr snapshot list -o json | /usr/bin/jq -r '.snapshots[] | select (.description == "'${machine_label}'-'${SERVER_USER}'").id'`" != "" ] )
	then
		/bin/echo "A snapshot of your current machine already exists, please delete it if you want to make a new one"
		exit
	fi

	/bin/echo "##############################################################################################"
	/bin/echo "################MAKING A SNAPSHOT OF MACHINE: ${machine_label} #####################"
	/bin/echo "##############################################################################################"

	/usr/bin/vultr snapshot create -i ${machine_id} -d "${machine_label}-${SERVER_USER}"
	if ( [ "$?" = "0" ] )
	then
		/bin/echo "Waiting to get the id of your snapshot"

		while ( [ "`/usr/bin/vultr snapshot list -o json | /usr/bin/jq -r '.snapshots[] | select (.description == "'${machine_label}'-'${SERVER_USER}'").id'`" = "" ] )
		do
			/bin/sleep 5
		done

		snapshot_id="`/usr/bin/vultr snapshot list -o json | /usr/bin/jq -r '.snapshots[] | select (.description == "'${machine_label}'-'${SERVER_USER}'").id'`"

		/bin/echo "Snapshot generated. It has an id of ${snapshot_id}"
	else
		/bin/echo "Error creating snapshot...exiting without creating one"
		exit
	fi
fi

/bin/echo "Trying to update stored snapshot ids located at: ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat"

if ( [ -f ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat ] )
then
	if ( [ "`/bin/grep ${machine_label} ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat`" != "" ] )
	then
		/bin/sed -i "s;.*${machine_label}.*;${machine_label}:${snapshot_id};" ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat
	else
		/bin/echo "${machine_label}:${snapshot_id}" >> ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat
	fi
	/bin/echo "Stored snapshot ids updated"
else
	/bin/echo "${machine_label}:${snapshot_id}" > ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat
	/bin/echo "Stored snapshot ids generated"
fi

/bin/echo "Storing snapshot metadata in the datastore"
snap_bucket="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`"
snap_bucket="${snap_bucket}-${DNS_CHOICE}-snap"

${BUILD_HOME}/providerscripts/datastore/operations/MountDatastore.sh ${snap_bucket}
${BUILD_HOME}/providerscripts/datastore/operations/PutToDatastore.sh ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat ${snap_bucket}
${BUILD_HOME}/providerscripts/datastore/operations/PutToDatastore.sh ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/db_credentials.dat.candidate ${snap_bucket}
${BUILD_HOME}/providerscripts/datastore/operations/PutToDatastore.sh ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/db_credentials.dat ${snap_bucket}
${BUILD_HOME}/providerscripts/datastore/operations/PutToDatastore.sh ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/credentials.dat ${snap_bucket}

cwd="`/usr/bin/pwd`"
cd ${BUILD_HOME}/runtimedata/${CLOUDHOST}/test-build/keys
/bin/tar cvfz keys.tar.gz *BUILD_KEY*
cd ${cwd}

${BUILD_HOME}/providerscripts/datastore/operations/PutToDatastore.sh  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/keys.tar.gz ${snap_bucket}













