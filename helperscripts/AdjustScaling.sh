#!/bin/sh
########################################################################################################
# Author: Peter Winter
# Date  : 13/01/2022
# Description : This script will adjust the scaling settings for your infrastructure
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

/bin/echo "What is the build identifier you want to allow access for?"
/bin/echo "You have these builds to choose from: "

/bin/ls ${BUILD_HOME}/runtimedata/${CLOUDHOST}

/bin/echo "Please enter the name of the build of the server you wish to connect with"
read BUILD_IDENTIFIER

/bin/echo "${BUILD_IDENTIFIER}" > ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER

SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
TOKEN="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1 | /usr/bin/tr '[:upper:]' '[:lower:]'`"

original_scale_value="`${BUILD_HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh STATIC_SCALE:* | /usr/bin/awk -F':' '{print $NF}'`"

if ( [ "${original_scale_value}" != "" ] )
then
        /bin/echo "Scaling value is currently set to ${original_scale_value} webservers"
fi

/bin/echo "Please enter the number of webservers that you want to scale to"
read new_scale_value

while ( ! [ "${new_scale_value}" -eq "${new_scale_value}" ] || [ "${new_scale_value}" -lt "2" ] ) 2> /dev/null
do
        /bin/echo "Sorry integers 2 or higher only"
        read new_scale_value
done

/bin/echo ""
/bin/echo "Your number of webservers is about to be set to ${new_scale_value}"
/bin/echo "Enter 'Y' or 'y' to accept, anything else to abort"
read response

if ( [ "${response}" != "Y" ] && [ "${response}" != "y" ] )
then
        exit
fi

${BUILD_HOME}/providerscripts/datastore/configwrapper/MultiDeleteConfigDatastore.sh STATIC_SCALE:
if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:* ] )
then
        /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:*
fi
/bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:${new_scale_value}
${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:${new_scale_value} STATIC_SCALE:${new_scale_value}

new_no_webservers="`${BUILD_HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh STATIC_SCALE:* | /usr/bin/awk -F':' '{print $NF}'`"

/bin/echo ""
/bin/echo "Your number of webservers has been successfully set to: ${new_no_webservers}"
/bin/echo ""



