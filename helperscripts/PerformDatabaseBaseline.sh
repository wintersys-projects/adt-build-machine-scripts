#!/bin/sh
######################################################################################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This will perform a baseline of your database and store it with your git storage provider
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

if ( [ ! -f  ./PerformDatabaseBaseline.sh ] )
then
    /bin/echo "Sorry, this script has to be run from the helperscripts subdirectory"
    exit
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

token_to_match="db-`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`-${BUILD_IDENTIFIER}"
/bin/echo "${BUILD_IDENTIFIER}" > ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER

if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/VPC-ACTIVE ] )
then
    ips="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh ${token_to_match} ${CLOUDHOST} ${BUILD_HOME}`"
else
    ips="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh ${token_to_match} ${CLOUDHOST} ${BUILD_HOME}`"
fi

if ( [ "${ips}" = "" ] )
then
    /bin/echo "There doesn't seem to be any databases running"
    exit
fi

DIR="`/bin/pwd`"


/bin/echo "Which Database server would you like to connect to?"
count=1
for ip in ${ips}
do
    /bin/echo "${count}:   ${ip}"
    /bin/echo "Press Y/N to connect..."
    read response
    if ( [ "${response}" = "Y" ] || [ "${response}" = "y" ] )
    then
        DB_IP=${ip}
        break
    fi
    count="`/usr/bin/expr ${count} + 1`"
done

SERVER_USERNAME="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"
SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"

DATABASE_PUBLIC_KEYS="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/database_${DB_IP}keys"

if ( [ ! -f ${DATABASE_PUBLIC_KEYS} ] )
then
    /usr/bin/ssh-keyscan  -p ${SSH_PORT} ${DB_IP} > ${DATABASE_PUBLIC_KEYS}    
    if ( [ "`/bin/cat ${DATABASE_PUBLIC_KEYS}`" = "" ] )
    then
        /usr/bin/ssh-keyscan ${DB_IP} > ${DATABASE_PUBLIC_KEYS}    
    fi
fi

if ( [ "`/bin/cat ${DATABASE_PUBLIC_KEYS}`" = "" ] )
then
    /bin/echo "Couldn't initiate ssh key scan please try again (make sure the machine is online"
    /bin/rm ${DATABASE_PUBLIC_KEYS}
    exit
fi

if ( [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/build_environment ] )
then
    ALGORITHM="rsa"
else
    ALGORITHM="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ALGORITHM`"
fi

/bin/echo ""
/bin/echo "############################################"
/bin/echo "Your git repository provider is set to:"
/usr/bin/ssh -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=${DATABASE_PUBLIC_KEYS}  -o StrictHostKeyChecking=yes -p ${SSH_PORT} -i ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${SERVER_USERNAME}@${DB_IP} "${SUDO} /home/${SERVER_USERNAME}/providerscripts/utilities/config/ExtractConfigValue.sh 'APPLICATIONREPOSITORYPROVIDER'" 2>/dev/null
/bin/echo "Your git repository username is set to:"
/usr/bin/ssh -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=${DATABASE_PUBLIC_KEYS}  -o StrictHostKeyChecking=yes -p ${SSH_PORT} -i ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${SERVER_USERNAME}@${DB_IP} "${SUDO} /home/${SERVER_USERNAME}/providerscripts/utilities/config/ExtractConfigValue.sh 'APPLICATIONREPOSITORYUSERNAME'" 2>/dev/null
/bin/echo "Your application identifier is set to:"
/usr/bin/ssh -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=${DATABASE_PUBLIC_KEYS}  -o StrictHostKeyChecking=yes -p ${SSH_PORT} -i ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${SERVER_USERNAME}@${DB_IP} "${SUDO} /home/${SERVER_USERNAME}/providerscripts/utilities/config/ExtractConfigValue.sh 'APPLICATIONIDENTIFIER'" 2>/dev/null
/bin/echo "ARE YOU ABSOLUTELY SURE THIS IS CORRECT, UNPREDICTABLE THINGS WILL HAPPEN IF IT ISN'T"
/bin/echo "PRESS THE ENTER KEY IF YOU ARE HAPPY"
/bin/echo "#############################################"
read x
/bin/echo "You MUST have a repository of name '<identifier>-db-baseline' available"
/bin/echo "If you haven't got one please create one and then tell me the <identifier> part by entering it below:"
read identifier

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

APPLICATION_REPOSITORY_PROVIDER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_REPOSITORY_PROVIDER`"
APPLICATION_REPOSITORY_USERNAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_REPOSITORY_USERNAME`"
APPLICATION_REPOSITORY_PASSWORD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_REPOSITORY_PASSWORD`"
APPLICATION_REPOSITORY_OWNER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_REPOSITORY_OWNER`"
APPLICATION_DB_REPOSITORY="${identifier}-db-baseline"

if ( [ "`${BUILD_HOME}/providerscripts/git/GitLSRemote.sh ${APPLICATION_REPOSITORY_PROVIDER} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_REPOSITORY_PASSWORD} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_DB_REPOSITORY} 2>&1`" = "" ] )
then
    /bin/echo "Empty Repository found I can use it for your baseline"
elif ( [ "`${BUILD_HOME}/providerscripts/git/GitLSRemote.sh ${APPLICATION_REPOSITORY_PROVIDER} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_REPOSITORY_PASSWORD} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_DB_REPOSITORY} | /bin/grep 'HEAD'`" != "" ] )
then
    /bin/echo "Repository with data found you will need to either delete it or rename it using the GUI and create a fresh repository for your baseline"
    exit
elif ( [ "`${BUILD_HOME}/providerscripts/git/GitLSRemote.sh ${APPLICATION_REPOSITORY_PROVIDER} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_REPOSITORY_PASSWORD} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_DB_REPOSITORY}`" = "" ] )
then
    /bin/echo "Repository not found you will need to create a repository called  using the GUI"
    exit
fi

/bin/echo "OK, ready to create baseline - press enter to confirm"
read x

/usr/bin/ssh -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=${DATABASE_PUBLIC_KEYS}  -o StrictHostKeyChecking=yes -p ${SSH_PORT} -i ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${SERVER_USERNAME}@${DB_IP} "${SUDO} /home/${SERVER_USERNAME}/providerscripts/backupscripts/CreateDBBaseline.sh ${identifier}" 2>/dev/null

if ( [ "`${BUILD_HOME}/providerscripts/git/GitLSRemote.sh ${APPLICATION_REPOSITORY_PROVIDER} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_REPOSITORY_PASSWORD} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_DB_REPOSITORY} | /bin/grep 'HEAD'`" = "" ] )
then
    /bin/echo "I am not sure that your baselined repository ${APPLICATION_DB_REPOSITORY} generated successful, please double check using the GUI account for ${APPLICATION_REPOSITORY_USERNAME} on ${APPLICATION_REPOSITORY_PROVIDER}"
else
    /bin/echo "As far as I can tell the baseline has been generated maybe go check in the repository you created earlier for the code update"
fi


