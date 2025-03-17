#!/bin/sh
########################################################################################
# Author: Peter Winter
# Date  : 12/07/2016
# Description : This is the script which will build a functioning webserver. It contains
# all the configuration settings and remote calls to the webserver we are building to ensure
# that it is built correctly and functions as it is supposed to.
########################################################################################
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
#########################################################################################
#########################################################################################
set -x
done=0
counter="0"
count="0"

status () {
        cyan="`/usr/bin/tput setaf 4`"
        norm="`/usr/bin/tput sgr0`"
        /bin/echo "${cyan} ${1} ${norm}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        /bin/echo "${0}: ${1}" >> /dev/fd/4
}

status ""
status ""
status ""
status "#########################WEBSERVER BUILD MESSAGES ARE IN BLUE#######################"


BUILD_HOME="`/bin/cat /home/buildhome.dat`"
PRODUCTION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRODUCTION`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
PRODUCTION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRODUCTION`"
BUILDOS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS`"
BUILDOS_VERSION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS_VERSION`"
WS_SERVER_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WS_SERVER_TYPE`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh INFRASTRUCTURE_REPOSITORY_OWNER`"
BUILD_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_CHOICE`"
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"

SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
#SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"

#if ( [ "${DEFAULT_USER}" = "root" ] )
#then
#        SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "
#else
#        SUDO="DEBIAN_FRONTEND=noninteractive /usr/bin/sudo -S -E "
#fi

#CUSTOM_USER_SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "
OPTIONS="-o ConnectTimeout=10 -o ConnectionAttempts=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "
OPTIONS_AUTOSCALER="-o ConnectTimeout=10 -o ConnectionAttempts=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "
PUBLIC_KEY_ID="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/PUBLICKEYID`"
BUILD_KEY="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"

#If "done" is set to 1, then we know that a webserver has been successfully built and is running.
#Try up to 5 times if the webserver is failing to complete its build
while ( [ "${done}" != "1" ] && [ "${counter}" -lt "5" ] )
do
        counter="`/usr/bin/expr ${counter} + 1`"
        status "OK... Building a webserver. This is the ${counter} attempt of 5"
        WEBSITE_IDENTIFIER="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`"
 
        #Check if there is a webserver already running. If there is, then skip building the webserver
        if ( [ "`${BUILD_HOME}/providerscripts/server/NumberOfServers.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} 2>/dev/null`" -eq "0" ] )
        then
                ip=""
                #Construct a unique name for this webserver
                RND="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1`"

                webserver_name="ws-${REGION}-${BUILD_IDENTIFIER}-0-${RND}"

                status "Initialising a new server machine, please wait......"

                server_started="0"
                while ( [ "${server_started}" = "0" ] )
                do
                        count="0"
                        #Actually start the server machine. Following this, there will be an active machine instance running on your cloud provider
                        ${BUILD_HOME}/providerscripts/server/CreateServer.sh "${WS_SERVER_TYPE}" "${webserver_name}" 

                        #Keep trying if the first time wasn't successful
                        while ( [ "$?" != "0" ] && [ "${count}" -lt "10" ] )
                        do
                                count="`/usr/bin/expr ${count} + 1`"
                                /bin/sleep 10
                                ${BUILD_HOME}/providerscripts/server/CreateServer.sh "${WS_SERVER_TYPE}" "${webserver_name}" 
                        done

                        if ( [ "${count}" = "10" ] )
                        then
                                status "Could not create webserver machine"
                                /usr/bin/kill -9 $PPID                        
                        fi

                        #Check that the server has been assigned its IP addresses and that they are active
                        ip=""
                        private_ip=""
                        count="0"
   
                        #Keep trying until we get the ip addresses of our new machine, both public and private ips
                        while ( ( [ "${ip}" = "" ] || [ "${private_ip}" = "" ] ) || [ "${ip}" = "0.0.0.0" ] && [ "${count}" -lt "20" ] )
                        do
                                status "Interrogating for webserver ip address....."
                                ip="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "${webserver_name}" ${CLOUDHOST} | /bin/grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`"
                                private_ip="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "${webserver_name}" ${CLOUDHOST} | /bin/grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`"
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
                                status "I haven't been able to start your server, trying again...."
                        fi
           done
    
                WSIP_PUBLIC=${ip}
                WSIP_PRIVATE=${private_ip}

                ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${ip} webserverpublicips/${ip}
                ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${private_ip} webserverips/${private_ip}

                if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
                then
                        ws_active_ip="${WSIP_PRIVATE}"
                elif ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                then
                        ws_active_ip="${WSIP_PUBLIC}"
                fi

                status "Have got the ip addresses for your webserver (${webserver_name})"
                status "Public IP address: ${WSIP_PUBLIC}"
                status "Private IP address: ${WSIP_PRIVATE}"

                if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys ] )
                then
                        /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys
                fi

                        status "Waiting for the webserver machine ${webserver_name} to complete its build. If you are waiting on this for more than 10 minutes, something is likely wrong"
                        status "This is the current time for your reference `/bin/date`"


                        #So, looking good. Now what we have to do is keep monitoring for the build process for our webserver to complete
                        done="0"
                        alive=""
                        alive="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${ws_active_ip} "/bin/ls /home/${SERVER_USER}/runtime/WEBSERVER_READY"`"

                        count="0"
                        while ( [ "${alive}" != "/home/${SERVER_USER}/runtime/WEBSERVER_READY" ] && [ "${count}" -lt "300" ] )
                        do
                                count="`/usr/bin/expr ${count} + 1`"
                                /bin/sleep 2
                                alive="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${ws_active_ip} "/bin/ls /home/${SERVER_USER}/runtime/WEBSERVER_READY"`"
                        done

                        if ( [ "${count}" = "300" ] )
                        then
                                done="0"
                        else
                                ${BUILD_HOME}/initscripts/InitialiseDNSRecord.sh ${ip}
                                done="1"
                        fi

                        #If $done != 1, then the webserver didn't build properly, so, destroy the machine
                        if ( [ "${done}" != "1" ] )
                        then
                                status "################################################################################################################"
                                status "Hi, a webserver didn't seem to build correctly. I can destroy it and I can try to build a new webserver for you"
                                status "################################################################################################################"
                                status "Press the <enter> key to be continue with the next attempt <ctrl - c> to exit"
                                if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
                                then
                                        read response
                                fi

                                ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh webserverpublicips
                                ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh webserverips

                                ${BUILD_HOME}/providerscripts/server/DestroyServer.sh ${WSIP_PUBLIC} ${CLOUDHOST}

                                #Wait until we are sure that the image server(s) are destroyed because of a faulty build
                                while ( [ "`${BUILD_HOME}/providerscripts/server/NumberOfServers.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} 2>/dev/null`" != "0" ] )
                                do
                                        /bin/sleep 30
                                done
                        else
                                status "A webserver (${webserver_name}) has built correctly (`/usr/bin/date`) and is accepting connections"
                                counter="`/usr/bin/expr ${counter} - 1`"
                        fi
        else
                status "A webserver is already running, using that one"
                status "Press enter if this is OK with you"
                if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
                then
                        read response
                fi
                done=1
        fi
done

#If we get to here then we know that the webserver didn't build properly, so report it and exit

if ( [ "${counter}" = "5" ] )
then
        status "The infrastructure failed to intialise because of a build problem, plese investigate, correct and rebuild"
        /usr/bin/kill -9 $PPID
fi
