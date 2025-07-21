#!/bin/sh
######################################################################################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This will perform a temporal style backup of your webroot and store it in your S3 datastore
######################################################################################################################################################
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

WEB_IP=""

if ( [ ! -f  ./PerformWebsiteBackup.sh ] )
then
	/bin/echo "Sorry, this script has to be run from the helperscripts subdirectory"
	exit
fi

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

/bin/echo "Which Cloudhost are you using? 1) Digital Ocean 2) Exoscale 3)Linode 4)Vultr. Please Enter the number for your cloudhost"
read response
if ( [ "${response}" = "1" ] )
then
	CLOUDHOST="digitalocean"
elif ( [ "${response}" = "2" ] )
then
	CLOUDHOST="exoscale"
elif ( [ "${response}" = "3" ] )
then
	CLOUDHOST="linode"
elif ( [ "${response}" = "4" ] )
then
	CLOUDHOST="vultr"
else
	/bin/echo "Unrecognised  cloudhost. Exiting ...."
	exit
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

/bin/echo "What is the build Identifer for your build?"
/bin/echo "You have these builds to choose from: "

/bin/ls ${BUILD_HOME}/runtimedata/${CLOUDHOST}

/bin/echo "Please enter the name of the build of the server you wish to connect with"
read BUILD_IDENTIFIER
/bin/echo "${BUILD_IDENTIFIER}" > ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
	export VULTR_API_KEY="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/TOKEN`"
fi

token_to_match="ws-`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`-${BUILD_IDENTIFIER}"

if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/VPC-ACTIVE ] )
then
	ips="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh ${token_to_match} ${CLOUDHOST} ${BUILD_HOME}`"
else
	ips="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh ${token_to_match} ${CLOUDHOST} ${BUILD_HOME}`"
fi

if ( [ "${ips}" = "" ] )
then
	/bin/echo "There doesn't seem to be any webservers running"
	exit
fi

/bin/echo "Which webserver would you like to connect to?"
count=1
for ip in ${ips}
do
	/bin/echo "${count}:   ${ip}"
	/bin/echo "Press Y/N to connect..."
	read response
	if ( [ "${response}" = "Y" ] || [ "${response}" = "y" ] )
	then
		WEB_IP=${ip}
		break
	fi
	count="`/usr/bin/expr ${count} + 1`"
done

/bin/echo "Which periodicity of backup do you want to make, 1) HOURLY 2)DAILY 3) WEEKLY 4)MONTHLY 5)BIMONTHLY 6)MANUAL 7)ALL"
/bin/echo "Please enter one of 1,2,3,4,5,6,7"
read periodicity

while ( [ "`/bin/echo '1 2 3 4 5 6 7' | /bin/grep ${periodicity}`" = "" ] )
do
	/bin/echo "Sorry, that's not a valid selection, please try again"
	read periodicity
done

if ( [ "${periodicity}" = "1" ] )
then
	periodicity="HOURLY"
fi

if ( [ "${periodicity}" = "2" ] )
then
	periodicity="DAILY"
fi

if ( [ "${periodicity}" = "3" ] )
then
	periodicity="WEEKLY"
fi

if ( [ "${periodicity}" = "4" ] )
then
	periodicity="MONTHLY"
fi

if ( [ "${periodicity}" = "5" ] )
then
	periodicity="BIMONTHLY"
fi

if ( [ "${periodicity}" = "6" ] )
then
	periodicity="MANUAL"
	if ( [ ! -d ${BUILD_HOME}/manualbackups ] )
	then
		/bin/mkdir -p ${BUILD_HOME}/manualbackups/backup.$$
		/bin/mv ${BUILD_HOME}/manualbackups/* ${BUILD_HOME}/manualbackups/backup.$$
	fi
fi

if ( [ "${periodicity}" = "7" ] )
then
	periodicity="HOURLY DAILY WEEKLY MONTHLY BIMONTHLY"
fi

SERVER_USERNAME="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"
SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"

WEBSERVER_PUBLIC_KEYS="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/webserver_${WEB_IP}keys"

if ( [ ! -f ${WEBSERVER_PUBLIC_KEYS} ] )
then
	/usr/bin/ssh-keyscan  -p ${SSH_PORT} ${WEB_IP} > ${WEBSERVER_PUBLIC_KEYS}    
	if ( [ "`/bin/cat ${WEBSERVER_PUBLIC_KEYS}`" = "" ] )
	then
		/usr/bin/ssh-keyscan ${WEB_IP} > ${WEBSERVER_PUBLIC_KEYS}    
	fi
fi

if ( [ "`/bin/cat ${WEBSERVER_PUBLIC_KEYS}`" = "" ] )
then
	/bin/echo "Couldn't initiate ssh key scan please try again (make sure the machine is online"
	/bin/rm ${WEBSERVER_PUBLIC_KEYS}
	exit
fi

if ( [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/build_environment ] )
then
	ALGORITHM="rsa"
else
	ALGORITHM="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ALGORITHM`"
fi

if ( [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/build_environment ] )
then
	ALGORITHM="rsa"
else
	ALGORITHM="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ALGORITHM`"
fi

build_identifier="`/usr/bin/ssh -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=${WEBSERVER_PUBLIC_KEYS} -o StrictHostKeyChecking=yes -p ${SSH_PORT} -i ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${SERVER_USERNAME}@${WEB_IP} "${SUDO} /home/${SERVER_USERNAME}/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'" 2>/dev/null`"
/bin/echo "Build identifier is set to: ${build_identifier}"
/bin/echo "OK, ready to create backup - press enter to confirm"
read x

for period in ${periodicity}
do
	/bin/echo "Making backup for ${period} periodicity"
	/bin/sleep 5
	/usr/bin/ssh -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=${WEBSERVER_PUBLIC_KEYS} -o StrictHostKeyChecking=yes -p ${SSH_PORT} -i ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${SERVER_USERNAME}@${WEB_IP} "${SUDO} /home/${SERVER_USERNAME}/application/backupscripts/Backup.sh ${period} ${build_identifier}" 2>/dev/null
done

if ( [ "${period}" = "MANUAL" ] )
then
	/usr/bin/scp -o ConnectTimeout=5 -o ConnectionAttempts=2 -o UserKnownHostsFile=${WEBSERVER_PUBLIC_KEYS} -o StrictHostKeyChecking=yes -P ${SSH_PORT} -i ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} "${SERVER_USERNAME}@${WEB_IP}:/tmp/backup_archive/*.tar.gz" ${BUILD_HOME}/manualbackups
	/bin/echo"######################################################################"
	/bin/echo "BACKUP STORED IN ${BUILD_HOME}/manualbackups"
	/bin/echo "#####################################################################"
fi
