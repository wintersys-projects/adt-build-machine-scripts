#!/bin/sh
###############################################################################################################
# Author: Peter Winter
# Date  : 12/07/2016
# Description : This script builds the autoscaler. It depends on having the environment it requires set up through the
#"initialisation" scripts which you can find in the same directory. These scripts look more complicated than they really
# are. All that is happening is we are copying over some files to our new autoscaler and executing a few commands (mostly
# to install software) remotely on the autoscaler.
# The purpose of the autoscaler is to monitor the number of active and responsive webservers and if, according to
# configuration, there should be more or less than are currently active, they are shutdown or newly provisioned
# accordingly. For more information on how to configure the autoscaling, please review the documentation.
# Note, the autoscaling is not dynamic, so in a way it is scaling rather than autoscaling. Autoscaling requires that
# machine usage is monitored and additional capacity provisioned or removed accordingly. The way this works is
# you review machine usage and adjust your capacity accordingly which will then be automatically scaled out.
# If you application has huge and unpredicable swings in usage, then this mechanism might not be suitable rather,
# it is for applications that have consistent predictable usage profiles within tight bounds.
###############################################################################################################
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

done=0
counter="0"
count="0"

status () {
        yellow="`/usr/bin/tput setaf 1`"
        norm="`/usr/bin/tput sgr0`"
        /bin/echo "${yellow} ${1} ${norm}" | /usr/bin/tee /dev/fd/3 2>/dev/null
}

status ""
status ""
status ""
status "#########################AUTOSCALER BUILD MESSAGES ARE IN RED#######################"

#For our remote commands, we have various options that we want to be set. To keep things as clean as possible
#We set out options for our ssh command and scp command here and pass them in through the variable ${OPTIONS}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
DEFAULT_USER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DEFAULT_USER`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
WEBSITE_DISPLAY_NAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_DISPLAY_NAME`"
NO_AUTOSCALERS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NO_AUTOSCALERS`"
BUILDOS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS`"
BUILDOS_VERSION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS_VERSION`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
ALGORITHM="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ALGORITHM`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh INFRASTRUCTURE_REPOSITORY_OWNER`"
NO_AUTOSCALERS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NO_AUTOSCALERS`"
AS_SIZE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AS_SIZE`"
AS_SERVER_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AS_SERVER_TYPE`"
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"


SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"

if ( [ "${DEFAULT_USER}" = "root" ] )
then
        SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "
else
        SUDO="DEBIAN_FRONTEND=noninteractive /usr/bin/sudo -S -E "
fi

CUSTOM_USER_SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

AUTOSCALER_PUBLIC_KEYS="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/autoscaler_keys"
OPTIONS="-o ConnectTimeout=10 -o ConnectionAttempts=5 -o UserKnownHostsFile=${AUTOSCALER_PUBLIC_KEYS} -o StrictHostKeyChecking=yes "
PUBLIC_KEY_ID="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/PUBLICKEYID`"

BUILD_KEY="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"

# If done=1, then we know that the autoscaler has been successfully built. We try up to 5 times before we give up if it fails
while ( [ "${done}" != "1" ] && [ "${counter}" -lt "5" ] )
do
        counter="`/usr/bin/expr ${counter} + 1`"
        autoscaler_no="`${BUILD_HOME}/providerscripts/server/NumberOfServers.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} 2>/dev/null`"

        if ( [ "${autoscaler_no}" = "" ] )
        then
                autoscaler_no="1"
        fi

        status "OK... Building autoscaler `/usr/bin/expr ${no_autoscalers} + 1`. This is the ${counter} attempt of 5"

        WEBSITE_IDENTIFIER="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`"
        WEBSITE_DISPLAY_NAME_FILE="`/bin/echo ${WEBSITE_DISPLAY_NAME} | /bin/sed 's/ /_/g'`"

        if ( [ "${autoscaler_no}" -le "${NO_AUTOSCALERS}" ] )
        then
                ip=""
                #Set a unique identifier and name for our new autoscaler server
                RND="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1`"
             #   autoscaler_name="NO-${autoscaler_no}-autoscaler-${RND}-`/bin/echo ${BUILD_IDENTIFIER} | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                autoscaler_name="NO-${autoscaler_no}-as-${REGION}-${BUILD_IDENTIFIER}-${RND}"

                status "Initialising a new server machine, please wait......"

                server_started="0"
                while ( [ "${server_started}" = "0" ] )
                do
                        count="0"
                        #Actually create the autoscaler machine. If the create fails, keep trying again - it must be a provider issue
                        ${BUILD_HOME}/providerscripts/server/CreateServer.sh "${AS_SERVER_TYPE}" "${autoscaler_name}" 

                        #Somehow we failed, let's try again...
                        while ( [ "$?" != 0 ] && [ "${count}" -lt "10" ] )
                        do
                                count="`/usr/bin/expr ${count} + 1`"
                                /bin/sleep 10
                                ${BUILD_HOME}/providerscripts/server/CreateServer.sh "${AS_SERVER_TYPE}" "${autoscaler_name}" 

                        done

                        if ( [ "${count}" -eq "10" ] )
                        then
                                 status "Couldn't autoscaler create server"
                                 exit
                        fi

                        #Get the ip addresses of the server we have just built
                        ip=""
                        private_ip=""
                        count="0"

                        while ( ( [ "${ip}" = "" ] || [ "${private_ip}" = "" ] ) && [ "${count}" -lt "20" ] )
                        do
                                status "Interrogating for autoscaler ip addresses....."
                                ip="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "${autoscaler_name}" ${CLOUDHOST} | /bin/grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`"
                                private_ip="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "${autoscaler_name}" ${CLOUDHOST} | /bin/grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`"
                                /bin/sleep 10
                                count="`/usr/bin/expr ${count} + 1`"
                        done

                        if ( [ "${ip}" != "" ] && [ "${private_ip}" != "" ] )
                        then
                                server_started="1"
                        elif ( [ "${ip}" != "" ] && [ "${private_ip}" = "" ] )
                        then
                                status "Found a public ip address but not a private ip address"
                                status "This likely means that there is some sort problem with the VPC"
                        else
                                status "I haven't been able to start your server for you, trying again...."
                        fi
           done

      #     ${BUILD_HOME}/providerscripts/server/EnsureServerAttachedToVPC.sh "${CLOUDHOST}" "${autoscaler_name}" "${private_ip}"
          
                status "It looks like the machine has booted OK"
                ASIP_PUBLIC=${ip}
                ASIP_PRIVATE=${private_ip}

                ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${ip} autoscalerpublicip/${ip}
                ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${private_ip} autoscalerip/${private_ip}

                if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
                then
                        as_active_ip="${ASIP_PRIVATE}"
                elif ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                then
                        as_active_ip="${ASIP_PUBLIC}"
                fi

                ASIPS="${ASIPS}${ASIP_PUBLIC}:"
                ASIP_PRIVATES="${ASIP_PRIVATES}${ASIP_PRIVATE}:"

                ASIPS_CLEANED="`/bin/echo ${ASIPS} | /bin/sed 's/\:/ /g'`"
                ASIPS_PRIVATES_CLEANED="`/bin/echo ${ASIP_PRIVATES} | /bin/sed 's/\:/ /g'`"

                if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
                then
                        as_active_ips="${ASIPS_PRIVATES_CLEANED}"
                elif ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                then
                        as_active_ips="${ASIPS_CLEANED}"
                fi

                status "Have got the ip addresses for your autoscaler (${autoscaler_name})"
                status "Public IP address: ${ASIP_PUBLIC}"
                status "Private IP address: ${ASIP_PRIVATE}"

                if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys ] )
                then
                        /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys
                fi

                status "Performing SSH keyscan on your new autoscaler machine (I allow up to 15 attempts). If this does fail, check BUILD_MACHINE_VPC in your template"

                AUTOSCALER_PUBLIC_KEYS_NUMBERED="${AUTOSCALER_PUBLIC_KEYS}:${autoscaler_no}"

                if ( [ -f ${AUTOSCALER_PUBLIC_KEYS_NUMBERED} ] )
                then
                        /bin/rm ${AUTOSCALER_PUBLIC_KEYS_NUMBERED}
                fi

                /usr/bin/ssh-keyscan ${as_active_ip} >> ${AUTOSCALER_PUBLIC_KEYS_NUMBERED}

                keytry="1"
               # while ( [ "`/usr/bin/diff -s ${AUTOSCALER_PUBLIC_KEYS_NUMBERED} /dev/null | /bin/grep identical`" != "" ] && [ "${keytry}" -lt "15" ] )
                while ( ( [ "`/usr/bin/diff -s /dev/null ${AUTOSCALER_PUBLIC_KEYS_NUMBERED} | /bin/grep identical`" != "" ] || [ "`/bin/grep 'ed25519' ${AUTOSCALER_PUBLIC_KEYS_NUMBERED}`" = "" ) && [ "${keytry}" -lt "15" ] )
                do
                        status "Couldn't scan for autoscaler ${autoscaler_name} ssh-keys attempt ${keytry} (this is normal and expected) .... trying again"
                        /bin/sleep 10

                        /usr/bin/ssh-keyscan ${as_active_ip} >> ${AUTOSCALER_PUBLIC_KEYS_NUMBERED}

                        if ( [ "`/usr/bin/diff -s /dev/null ${AUTOSCALER_PUBLIC_KEYS_NUMBERED} | /bin/grep identical`" != "" ] )
                        then
                                /usr/bin/ssh-keyscan -p ${SSH_PORT} ${as_active_ip} >> ${AUTOSCALER_PUBLIC_KEYS_NUMBERED}
                        fi

                        keytry="`/usr/bin/expr ${keytry} + 1`"
                done 

                if ( [ "${keytry}" = "15" ] )
                then
                        status "Couldn't obtain ssh-keys, having to destroy the machine and try again"
                        ${BUILD_HOME}/providerscripts/server/DestroyServer.sh ${ASIP_PUBLIC} ${CLOUDHOST}
                else
                        if ( [ -f ${AUTOSCALER_PUBLIC_KEYS_NUMBERED} ] )
                        then
                                /bin/cat ${AUTOSCALER_PUBLIC_KEYS_NUMBERED} >> ${AUTOSCALER_PUBLIC_KEYS}
                                /bin/rm ${AUTOSCALER_PUBLIC_KEYS_NUMBERED}
                        fi

                        status "Successfully scanned remote autoscaler ${autoscaler_name} for ssh-keys"
                        status "Waiting for the autoscaling machine ${autoscaler_name} to complete its build. If you are waiting on this for more than 10 minutes, something is likely wrong"
                        status "This is the current time for your reference `/bin/date`"
                        
                        
                        #Wait for the machine to become responsive before we check its integrity

                        done="0"
                        alive=""
                        #checking that the autoscaler is "built and alive" The last thing that the as.sh script does is reboot the machine
                        #that is our autoscaler. We do some rudimentary checking to detect when it is back up again post reboot.
           
           
                   count="0"
                   while ( [ "${alive}" != "/home/${SERVER_USER}/runtime/AUTOSCALER_READY" ] && [ "${count}" -le "300" ] )
                   do
                           count="`/usr/bin/expr ${count} + 1`"
                           /bin/sleep 2
                           alive="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${as_active_ip} "/bin/ls /home/${SERVER_USER}/runtime/AUTOSCALER_READY"`"
                   done
                   
                   if ( [ "${alive}" != "/home/${SERVER_USER}/runtime/AUTOSCALER_READY" ] )
                   then
                                status "#########################################################################################################################"
                                status "Hi, an autoscaler didn't seem to build correctly. I can destroy it and I can try again to build a new autoscaler for you."
                                status "#########################################################################################################################"
                                status "Press the <enter> key to be continue with the next attempt <ctrl - c> to exit"
                                if ( [ "${HARDCORE}" != "1" ] )
                                then
                                        read response
                                fi
                                
                                ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh autoscalerpublicip
                                ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh autoscalerip

                                ${BUILD_HOME}/providerscripts/server/DestroyServer.sh ${ASIP_PUBLIC} ${CLOUDHOST}

                                #Wait until we are sure that the image server(s) are destroyed because of a faulty build
                                while ( [ "`${BUILD_HOME}/providerscripts/server/NumberOfServers.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} 2>/dev/null`" != "0" ] )
                                do
                                        /bin/sleep 30
                                done
                        else
                                done="1"
                                if ( [ "${NO_AUTOSCALERS}" -eq "1" ] )
                                then
                                        status "An autoscaler (${autoscaler_name}) has built correctly (`/usr/bin/date`) and is accepting connections"
                                else
                                        autoscaler_built_rank="`/bin/ls  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/AUTOSCALER_BUILT-* | /usr/bin/wc -l 2>/dev/null`"
                                        autoscaler_built_rank="`/usr/bin/expr ${autoscaler_built_rank} + 1`"
                                        /bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/AUTOSCALER_BUILT-${autoscaler_built_rank}

                                        status "An autoscaler (${autoscaler_name}) has built correctly (`/usr/bin/date`) and is accepting connections"

                                        if ( [ "${autoscaler_built_rank}" -eq "${NO_AUTOSCALERS}" ] )
                                        then
                                                /bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/MULTI_AUTOSCALER_BUILT 
                                                /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/AUTOSCALER_BUILT-*
                                        fi
                                fi
                                counter="0"
                        fi
                fi
        else
                status "Autoscaler is already running. Will use that one..."
                status "Press Enter if this is OK"
                if ( [ "${HARDCORE}" != "1" ] )
                then
                        read response
                fi
                done="1"
        fi
done

#If our count got to 5, then we know that none of the attempts succeeded in building our autoscaler, so, report this and exit because we can't run without an autoscaler

if ( [ "${counter}" = "5" ] )
then
        status "The infrastructure failed to intialise because of a build problem with the autoscaler, please investigate, correct and rebuild"
        exit
fi
