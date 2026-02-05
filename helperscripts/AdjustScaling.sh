#!/bin/sh
########################################################################################################
# Author: Peter Winter
# Date  : 13/01/2022
# Description : This script will adjust the webserver scaling settings for your autoscaler(s). In other words
# if you use this script to set a scaling value of "5" then 5 webservers will be provisioned in short order
########################################################################################################
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

if ( [ ! -f  ./AdjustScaling.sh ] )
then
        /bin/echo "Sorry, this script has to be run from the helperscripts subdirectory"
        exit
fi

/bin/echo "Remember, scaling takes 5 minutes to come online after the completion of an initial build. If less than 5 minutes has passed, wait a bit, then adjust scaling"
/bin/echo "Press <enter> to acknowledge"
read x

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

if ( [ "`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRODUCTION`" != "1" ] )
then
        /bin/echo "You are not in PRODUCTION mode, cannot set scaling parameters"
        exit
fi

/bin/echo "Which cloudhost service are you using? 1) Digital Ocean 2) Exoscale 3) Linode 4) Vultr. Please Enter the number for your cloudhost"
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

/bin/echo "Please enter the name of the build of the server you wish to connect with"
/bin/ls ${BUILD_HOME}/runtimedata/${CLOUDHOST}
read BUILD_IDENTIFIER

/bin/echo "Please enter the full URL of the website you want to alter the scaling configuration for, for example, www.testwebsite.uk"

read website_url

website_url="`/bin/echo  ${website_url} | /bin/sed 's/\./-/g'`"

regions="`${BUILD_HOME}/providerscripts/datastore/operations/ListDatastore.sh "scaling" "${website_url}-scaling-${CLOUDHOST}" | /bin/sed "s/.*${CLOUDHOST}//g" | /bin/sed 's/^-//g'`"

if ( [ "${regions}" != "" ] )
then
        /bin/echo "I have found scaling profiles in the following regions for cloudhost ${CLOUDHOST}:"
        /bin/echo "${regions}"
        /bin/echo "Please type the region (exactly) that you want to update"
        read region
        autoscalers="`${BUILD_HOME}/providerscripts/datastore/operations/ListFromDatastore.sh "scaling" "STATIC_SCALE" "${website_url}-scaling-${CLOUDHOST}-${region}" | /usr/bin/awk '{print $NF}'`"
        /bin/echo "I found the following scaling profiles:"
        /bin/echo "${autoscalers}"
        /bin/echo "Please enter the full name of the autoscaler you want to update the scaling profile for, for example, 'autoscaler-1'"
        read autoscaler
        while ( [ "`/bin/echo ${autoscaler} | /bin/grep 'autoscaler-[0-9]'`" = "" ] )
        do
                /bin/echo "That doesn't seem like a valid value for an autoscaler, try again"
                read autoscaler
        done
        /bin/echo "Please enter the number of webservers you want to update to for ${autoscaler}, for example, '5' if you want your autoscaler to spin up 5 webservers"
        read no_webservers
        /bin/echo "I am updating autoscaler ${autoscaler} to provision ${no_webservers} webservers, is this correct (Y|N)"
        read response

        if ( [ "${response}" = "Y" ] || [ "${response}" = "y" ] )
        then
                if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/scaling/${autoscaler} ] )
                then
                        /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/scaling/${autoscaler}
                fi
                ${BUILD_HOME}/providerscripts/datastore/operations/DeleteFromDatastore.sh "scaling" "${autoscaler}/STATIC_SCALE:*" "local" "${website_url}-scaling-${CLOUDHOST}-${region}"
                /bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/scaling/${autoscaler}/STATIC_SCALE:${no_webservers}
                ${BUILD_HOME}/providerscripts/datastore/operations/PutToDatastore.sh "scaling" "${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/scaling/${autoscaler}/STATIC_SCALE:${no_webservers}" "${autoscaler}" "local" "no" "scaling-${CLOUDHOST}-${region}"
        else
                exit
        fi
fi
