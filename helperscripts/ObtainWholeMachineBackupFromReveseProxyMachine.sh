#!/bin/sh
######################################################################################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This will obtain the tar archive of a whole reverseproxy machine if it available
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

if ( [ ! -f  ./ObtainWholeMachineBackupFromReveseProxyMachine.sh ] )
then
        /bin/echo "Sorry, this script has to be run from the helperscripts subdirectory"
        exit
fi

if ( [ "`/usr/bin/df . | /usr/bin/tail -1 | /usr/bin/awk -F'%' '{print $1}' | /usr/bin/awk '{print $NF}'`" -gt "90" ] )
then
        /bin/echo "Low disk space detected. This script will produce a large file you might want to free up some space"
        /bin/echo "Press <enter> to carry on <ctri-c> to quit and take action"
        read x
fi

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

/bin/echo "Which Cloudhost are you using? 1) Digital Ocean 2) Exoscale 3) Linode 4)Vultr. Please Enter the number for your cloudhost"
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
/bin/echo "What is the build identifier you want to connect to?"
/bin/echo "You have these builds to choose from: "

/bin/ls ${BUILD_HOME}/runtimedata/${CLOUDHOST}

/bin/echo "Please enter the name of the build of the server you wish to connect with"
read BUILD_IDENTIFIER

token_to_match="rp-`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`-${BUILD_IDENTIFIER}"
/bin/echo "${BUILD_IDENTIFIER}" > ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER

if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/VPC-ACTIVE ] )
then
        ips="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh ${token_to_match} ${CLOUDHOST} ${BUILD_HOME}`"
else
        ips="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh ${token_to_match} ${CLOUDHOST} ${BUILD_HOME}`"
fi

if ( [ "${ips}" = "" ] )
then
        /bin/echo "There doesn't seem to be any reverseproxys running"
        exit
fi

DIR="`/bin/pwd`"

/bin/echo "Which Reverse Proxy server would you like to connect to?"
count=1
for ip in ${ips}
do
        /bin/echo "${count}:   ${ip}"
        /bin/echo "Press Y/N to connect..."
        read response
        if ( [ "${response}" = "Y" ] || [ "${response}" = "y" ] )
        then
                RP_IP=${ip}
                break
        fi
        count="`/usr/bin/expr ${count} + 1`"
done

SERVER_USERNAME="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"
SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"

REVERSE_PROXY_PUBLIC_KEYS="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/reverseproxy_${RP_IP}keys"

if ( [ ! -f ${REVERSE_PROXY_PUBLIC_KEYS} ] )
then
        /usr/bin/ssh-keyscan  -p ${SSH_PORT} ${RP_IP} > ${REVERSE_PROXY_PUBLIC_KEYS}    
        if ( [ "`/bin/cat ${REVERSE_PROXY_PUBLIC_KEYS}`" = "" ] )
        then
                /usr/bin/ssh-keyscan ${RP_IP} > ${REVERSE_PROXY_PUBLIC_KEYS}    
        fi
fi

if ( [ "`/bin/cat ${REVERSE_PROXY_PUBLIC_KEYS}`" = "" ] )
then
        /bin/echo "Couldn't initiate ssh key scan please try again (make sure the machine is online"
        /bin/rm ${REVERSE_PROXY_PUBLIC_KEYS}
        exit
fi

if ( [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/build_environment ] )
then
        ALGORITHM="rsa"
else
        ALGORITHM="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ALGORITHM`"
fi

/bin/echo "About to attempt a whole machine backup of an reverse proxy class machine. Press <enter> to have the backup process begin"
read x

/usr/bin/ssh -q -o ConnectTimeout=5 -o ConnectionAttempts=2 -o UserKnownHostsFile=${REVERSE_PROXY_PUBLIC_KEYS} -o StrictHostKeyChecking=yes -p ${SSH_PORT} -i ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${SERVER_USERNAME}@${RP_IP} "${SUDO} /bin/rm /home/${SERVER_USERNAME}/machinedump/reverseproxy_runtime.tar 2>/dev/null ; ${SUDO} /home/${SERVER_USERNAME}/utilities/housekeeping/GenerateWholeMachineBackup.sh"

if ( [ ! -d ${BUILD_HOME}/runtimedata/wholemachinebackups/${WEBSITE_URL}/reverseproxy ] )
then
        /bin/mkdir -p ${BUILD_HOME}/runtimedata/wholemachinebackups/${WEBSITE_URL}/reverseproxy
fi

if ( [ ! -f ${BUILD_HOME}/runtimedata/wholemachinebackups/${WEBSITE_URL}/credentials.dat ] )
then
        /usr/bin/scp -o ConnectTimeout=5 -o ConnectionAttempts=2 -o UserKnownHostsFile=${REVERSE_PROXY_PUBLIC_KEYS} -o StrictHostKeyChecking=yes -P ${SSH_PORT} -i ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${SERVER_USERNAME}@${RP_IP}:/home/${SERVER_USERNAME}/machinedump/credentials.dat ${BUILD_HOME}/runtimedata/wholemachinebackups/${WEBSITE_URL}
fi
/usr/bin/scp -o ConnectTimeout=5 -o ConnectionAttempts=2 -o UserKnownHostsFile=${REVERSE_PROXY_PUBLIC_KEYS} -o StrictHostKeyChecking=yes -P ${SSH_PORT} -i ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${SERVER_USERNAME}@${RP_IP}:/home/${SERVER_USERNAME}/machinedump/reverseproxy_hidden.tar ${BUILD_HOME}/runtimedata/wholemachinebackups/${WEBSITE_URL}/reverseproxy
/usr/bin/scp -o ConnectTimeout=5 -o ConnectionAttempts=2 -o UserKnownHostsFile=${REVERSE_PROXY_PUBLIC_KEYS} -o StrictHostKeyChecking=yes -P ${SSH_PORT} -i ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${SERVER_USERNAME}@${RP_IP}:/home/${SERVER_USERNAME}/machinedump/reverseproxy_backup.tar ${BUILD_HOME}/runtimedata/wholemachinebackups/${WEBSITE_URL}/reverseproxy

/bin/echo "Verifying archive I have created for you at ${BUILD_HOME}/runtimedata/wholemachinebackups/${WEBSITE_URL}/reverseproxy/reverseproxy_backup.tar"
/usr/bin/tar tvf ${BUILD_HOME}/runtimedata/wholemachinebackups/${WEBSITE_URL}/reverseproxy/reverseproxy_backup.tar 2>&1 > /dev/null

if ( [ "$?" = "0" ] )
then
        /bin/echo "Archive Verified"
else
        /bin/echo "Archive Not Verified and is not usable"
fi
