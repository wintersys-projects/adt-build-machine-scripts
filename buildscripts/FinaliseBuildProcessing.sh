#!/bin/sh
####################################################################################
# Author : Peter Winter
# Date   : 13/07/2016
# Description : This script will do the finalisation processing for the build process.
# It should be self evident what it does. It's basically a sharing of ip addresses
# between machines so that firewalls can be appropriately configured. We want the
# firewalls to be as explicit as possible, so, we simply only allow the ip addresses
# of specific machines throught the firewall. That is what this is for.
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
####################################################################################
####################################################################################
set -x

status ""
status ""
status ""
status ""
status ""
status "==========================================================================="
status "======================FINALISING (please wait...) ========================="
status "==========================================================================="

AUTOSCALER_PUBLIC_KEYS="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/autoscaler_keys"
WEBSERVER_PUBLIC_KEYS="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/webserver_keys"


OPTIONS_AS="-o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=${AUTOSCALER_PUBLIC_KEYS} -o StrictHostKeyChecking=yes "
OPTIONS_WS="-o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=${WEBSERVER_PUBLIC_KEYS} -o StrictHostKeyChecking=yes "
OPTIONS_DB="-o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=${DATABASE_PUBLIC_KEYS} -o StrictHostKeyChecking=yes "

SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"


${BUILD_HOME}
${CLOUDHOST}
${BUILD_IDENTIFIER}
${SERVER_USER_PASSWORD}
${ALGORITHM}
${PRODUCTION}
${REGION}
${DATABASE_INSTALLATION_TYPE}
${DEVELOPMENT}
${INPARALLEL}
${BUILD_MACHINE_VPC}
${SERVER_USER}
${SSH_PORT} 
${APPLICATION_LANGUAGE}
${BUILD_ARCHIVE_CHOICE}
${APPLICATION}
${WEBSERVER_CHOICE}
${PERSIST_ASSETS_TO_CLOUD}
${DNS_CHOICE}
${WEBSITE_URL}

SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

BUILD_KEY="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"

#Just do some checks to make sure that all the different server types are running correctly
if ( [ "${PRODUCTION}" = "1" ] && [ "`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`" = "" ] )
then
        status "It seems like something is not quite right with the build. The Autoscaler seems not to be running so the website will not function properly."
fi

if ( [ "`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`" = "" ] )
then
        status "It seems like something is not quite right with the build. The webserver seems not to be running so the website will not function properly."
fi

if (  [ "${DATABASE_INSTALLATION_TYPE}" != "None" ] && [ "`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`" = "" ] )
then
        status "It seems like something is not quite right with the build. The database seems not to be running so the website will not function properly."
fi

if ( [ "${PRODUCTION}" = "1" ] && [ "${DEVELOPMENT}" = "0" ] )
then 
        no_autoscalers="`${BUILD_HOME}/providerscripts/server/NumberOfServers.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} 2>/dev/null`"

        if ( [ "${INPARALLEL}" = "1" ] )
        then
                if ( [ "${no_autoscalers}" = "1" ] )
                then
                        if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
                        then
                                as_active_ip="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "as-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
                        else
                                as_active_ip="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "as-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
                        fi
                elif ( [ "${no_autoscalers}" != "0" ] )
                then
                        if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
                        then
                                as_active_ips="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "as-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
                        else
                                as_active_ips="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "as-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
                        fi
                fi
        fi

        if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
        then
                if ( [ "${as_active_ip}" = "" ] )
                then
                        as_active_ip="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "as-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
                fi
        elif ( [ "${as_active_ip}" = "" ] )
        then
                as_active_ip="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "as-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
        fi

        if ( [ "${no_autoscalers}" = "1" ] )
        then
                if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/EMERGENCY_PASSWORD ] )
                then
                        /usr/bin/scp ${OPTIONS_AS} -i ${BUILD_KEY} -P ${SSH_PORT} ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/EMERGENCY_PASSWORD ${SERVER_USER}@${as_active_ip}:/home/${SERVER_USER}/.ssh/EMERGENCY_PASSWORD
                fi
                /usr/bin/scp ${OPTIONS_AS} -i ${BUILD_KEY} -P ${SSH_PORT} ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/webserver_configuration_settings.dat ${SERVER_USER}@${as_active_ip}:/home/${SERVER_USER}/.ssh/webserver_configuration_settings.dat >/dev/null 2>&1        
                /usr/bin/scp ${OPTIONS_AS} -i ${BUILD_KEY} -P ${SSH_PORT} ${BUILD_HOME}/builddescriptors/buildstylesscp.dat ${SERVER_USER}@${as_active_ip}:/home/${SERVER_USER}/.ssh/buildstyles.dat >/dev/null 2>&1  
        elif ( [ "${no_autoscalers}" != "0" ] )
        then
                for as_active_ip in ${as_active_ips}
                do
                         if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/EMERGENCY_PASSWORD ] )
                         then
                                /usr/bin/scp ${OPTIONS_AS} -i ${BUILD_KEY} -P ${SSH_PORT} ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/EMERGENCY_PASSWORD ${SERVER_USER}@${as_active_ip}:/home/${SERVER_USER}/.ssh/EMERGENCY_PASSWORD
                         fi
                         /usr/bin/scp ${OPTIONS_AS} -i ${BUILD_KEY} -P ${SSH_PORT} ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/webserver_configuration_settings.dat ${SERVER_USER}@${as_active_ip}:/home/${SERVER_USER}/.ssh/webserver_configuration_settings.dat >/dev/null 2>&1        
                         /usr/bin/scp ${OPTIONS_AS} -i ${BUILD_KEY} -P ${SSH_PORT} ${BUILD_HOME}/builddescriptors/buildstylesscp.dat ${SERVER_USER}@${as_active_ip}:/home/${SERVER_USER}/.ssh/buildstyles.dat >/dev/null 2>&1    
                done
        fi
fi

#Do some checks to find out if the build has completed correctly, before we say we are finished
/bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/INITIAL_BUILD_COMPLETED

if ( [ "${as_active_ips}" != "" ] )
then
        for autoscaler_ip in `/bin/echo ${as_active_ips} | /bin/sed 's/:/ /g'`
        do
                test ${PRODUCTION} -eq 1 && /usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_AS} ${SERVER_USER}@${as_active_ip} "${SUDO} /bin/touch /home/${SERVER_USER}/runtime/INITIAL_BUILD_COMPLETED"
        done
elif ( [ "${as_active_ip}" != "" ] )
then
        test ${PRODUCTION} -eq 1 && /usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_AS} ${SERVER_USER}@${as_active_ip} "${SUDO} /bin/touch /home/${SERVER_USER}/runtime/INITIAL_BUILD_COMPLETED"
fi

#status "Testing to see if the build is completed. This may take several attempts. Endless waiting (more than a few minutes) and something must be wrong"

#buildcompleted="`/usr/bin/ssh -p ${SSH_PORT} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "/bin/ls /home/${SERVER_USER}/runtime/BUILDCOMPLETED" 2>/dev/null`"

#while ( [ "${buildcompleted}" = "" ] )
#do
#       /bin/sleep 10
#       buildcompleted="`/usr/bin/ssh -p ${SSH_PORT} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "/bin/ls /home/${SERVER_USER}/runtime/BUILDCOMPLETED" 2>/dev/null`"
#done

#This enables the application to have any post processing done that it needs. There is pre and post processing either side of the build process
status "Performing any post processing that is needed for your application...please wait, depending on your application's requirements"
/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "/home/${SERVER_USER}/providerscripts/application/processing/PerformPostProcessingByApplication.sh ${SERVER_USER}" >&3


#We are satisfied that all is well, so let's try and see if the application is actually online and active

status ""
status "##############################################################################################################################"
status "The build might pause here"
status "Anything more than a few minutes then you need to investigate what the hold-up is because something might be wrong"
status "##############################################################################################################################"
status ""

if ( [ "${APPLICATION_LANGUAGE}" != "" ] )
then
        status "Checking that ${APPLICATION_LANGUAGE} has fully installed...."
        application_language_installed="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "/bin/ls /home/${SERVER_USER}/runtime/installedsoftware/InstallApplicationLanguage.sh"`" >&3

        while ( [ "${application_language_installed}" = "" ] )
        do
                /bin/sleep 1
                application_language_installed="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "/bin/ls /home/${SERVER_USER}/runtime/installedsoftware/InstallApplicationLanguage.sh"`" 2>&1 > /dev/null
        done
fi

if ( [ "${BUILD_ARCHIVE_CHOICE}" != "virgin" ] )
then
        status "Checking that the application configuration for ${APPLICATION} has fully installed...."
        application_configuration_installed=""

        while ( [ "${application_configuration_installed}" = "" ] )
        do
                /usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "${SUDO} /home/${SERVER_USER}/providerscripts/application/configuration/SetApplicationConfiguration.sh" >&3
                application_configuration_installed="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "/bin/ls /home/${SERVER_USER}/runtime/INITIAL_CONFIG_SET"`" 2>&1 > /dev/null
                /bin/sleep 1
        done
fi

status "Checking that the webserver ${WEBSERVER_CHOICE} has fully installed...."

while ( [ "${webserver_installed}" = "" ] )
do
        webserver_installed="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "/bin/ls /home/${SERVER_USER}/runtime/installedsoftware/InstallWebserver.sh"`" 2>&1 > /dev/null
        /bin/sleep 1
done


status "Checking that all core software has fully installed...."
core_software_installed=""

while ( [ "${core_software_installed}" = "" ] )
do
        core_software_installed="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "/bin/ls /home/${SERVER_USER}/runtime/ALL_CORE_SOFTWARE_INSTALLED"`" 2>&1 > /dev/null
        /bin/sleep 1
done

status "Checking that the bespoke application has been installed...."
bespoke_application_installed=""

while ( [ "${bespoke_application_installed}" = "" ] )
do
        bespoke_application_installed="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "/bin/ls /home/${SERVER_USER}/runtime/BESPOKE_APPLICATION_INSTALLED"`" 2>&1 > /dev/null
        /bin/sleep 1
done

if ( [ "${PERSIST_ASSETS_TO_CLOUD}" = "1" ] )
then
        status "Checking that your assets are mounted..."
        assets_mounted=""

        while ( [ "${assets_mounted}" = "" ] )
        do
                /usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "${SUDO} /home/${SERVER_USER}/providerscripts/datastore/SetupAssetsStore.sh"
                assets_mounted="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "${SUDO} /home/${SERVER_USER}/providerscripts/utilities/status/AreAssetsMounted.sh"`"
                /bin/sleep 1
        done
fi

if ( [ "${DNS_CHOICE}" != "NONE" ] )
then
        if ( [ "${BUILD_ARCHIVE_CHOICE}" != "virgin" ] )
        then
                status "Checking that your application is fully responsive...."

                server_alive=""
                while ( [ "`/bin/echo ${server_alive} | /bin/grep ALIVE`" = "" ] )
                do
                        server_alive="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "${SUDO} /home/${SERVER_USER}/providerscripts/application/monitoring/CheckServerAlive.sh"`" 2>&1 > /dev/null
                        /bin/sleep 1
                done
        fi
fi

if ( [ "${WEBSERVER_CHOICE}" != "" ] )
then
        status "Checking that ${WEBSERVER_CHOICE} is up and running...."
        count="0"
        webserver_running=""
        while ( [ "${webserver_running}" = "0" ] && [ "${count}" -lt "5" ] )
        do
                count="`/usr/bin/expr ${count} + 1`"
               status "Webserver not running yet, trying to start the ${WEBSERVER_CHOICE} webserver...this is attempt ${count} of 5"
                /usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "${SUDO} /home/${SERVER_USER}/providerscripts/webserver/RestartWebserver.sh" 2>&1 > /dev/null
                webserver_running="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "${SUDO} /home/${SERVER_USER}/providerscripts/webserver/IsAWebserverRunning.sh"`"
                /bin/sleep 10
        done

        if ( [ "${count}" = "5" ] )
        then
                status "Failed to start the webserver...you might want to take look into why on the webserver and then press <enter> if it is resolved"
                read response
        fi
 
        . ${BUILD_HOME}/providerscripts/application/SetHeadFile.sh
  
        status "The Website isn't online yet. It can take a minute for the software on your machines to settle down post install. I will try again...please wait"
 
        while ( [ "`/usr/bin/curl -I --max-time 60 --insecure https://${ws_active_ip}:443/${headfile} | /bin/grep -E 'HTTP/2 200|HTTP/2 301|HTTP/2 302|HTTP/2 303|200 OK|302 Found|301 Moved Permanently'`" = "" ] )
        do
                /bin/sleep 1
        done
fi

status "Seeing this message means I am confident that it is 'all systems go' (once all systems go no more capitalism or communism, right?)"

#Tell our infrastructure, 'yes, I am happy that you are up and running and functioning correctly'.
#Other scripts can then check if the build has completed correctly before they action
/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS_WS} ${SERVER_USER}@${ws_active_ip} "${SUDO} /bin/touch /home/${SERVER_USER}/runtime/INSTALLED_SUCCESSFULLY"

${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh INSTALLED_SUCCESSFULLY INSTALLED_SUCCESSFULLY

status "Build process fully complete"

#Print a final little congratulations message to say the build is good and that the application should now be online
status "`/bin/date`"
status "OK, good news, all done your servers are configured and responsive"
status "If you check with your acceleration/DNS provider, in this case : ${DNS_CHOICE} and once you see ip addresses appear for your domain: ${WEBSITE_URL}"
status "You should shortly be able to navigate to your website in your browser at: https://${WEBSITE_URL}"
status ""
status ""
status "###################################################################################################"
status "Thanks for using our build kit - ANY PROBS, GIVE AT LEAST A COUPLE OF  MINUTES before investigating"
status "###################################################################################################"
