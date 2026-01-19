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

/bin/echo "What is the build identifier you want to adjust scaling for?"
/bin/echo "You have these builds to choose from: "

/bin/ls ${BUILD_HOME}/runtimedata/${CLOUDHOST}

/bin/echo "Please enter the name of the build of the server you wish to connect with"
read BUILD_IDENTIFIER

/bin/echo "${BUILD_IDENTIFIER}" > ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER

SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
TOKEN="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1 | /usr/bin/tr '[:upper:]' '[:lower:]'`"

scaling_profile="`${BUILD_HOME}/providerscripts/datastore/config/toolkit/ListFromConfigDatastore.sh STATIC_SCALE:* STATIC_SCALE:`"
stripped_scaling_profile="`/bin/echo ${scaling_profile} | /bin/sed 's/.*STATIC_SCALE://g' | /bin/sed 's/:/ /g'`"
original_scale_value="0"

for value in ${stripped_scaling_profile}
do
	original_scale_value="`/usr/bin/expr ${original_scale_value} + ${value}`"
done

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

REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
number_of_autoscalers="`${BUILD_HOME}/providerscripts/server/NumberOfServers.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} 2>/dev/null`"

if ( [ "${number_of_autoscalers}" = "0" ] )
then
	/bin/echo "There doesn't seem to be any autoscalers running it's pointless trying to set a scaling value"
	exit
fi

number_of_webservers="${new_scale_value}"

/bin/echo "You are running ${number_autoscalers} and you are asking me to build ${new_scale_value} webservers"

base_number_of_webservers="`/usr/bin/expr ${number_of_webservers} / ${number_of_autoscalers}`"
total_base_number_of_webservers="`/usr/bin/expr ${base_number_of_webservers} \* ${number_of_autoscalers}`"
additional_number_of_webservers="`/usr/bin/expr ${number_of_webservers} - ${total_base_number_of_webservers}`"

new_scale_values="STATIC_SCALE"
for autoscaler_no in `printf "%d\n" $(seq 1 ${number_of_autoscalers})`
do
	if ( [ "${additional_number_of_webservers}" -gt "0" ] )
	then
		new_scale_values="${new_scale_values}:`/usr/bin/expr ${base_number_of_webservers} + 1`"
		additional_number_of_webservers="`/usr/bin/expr ${additional_number_of_webservers} - 1`"
	else
		new_scale_values="${new_scale_values}:${base_number_of_webservers}"
	fi
done

/bin/echo "Deleting existing Scaling Profile from datastore"
${BUILD_HOME}/providerscripts/datastore/config/toolkit/DeleteFromConfigDatastore.sh STATIC_SCALE: "yes"

if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:* ] )
then
	/bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:*
fi

/bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/${new_scale_values}
${BUILD_HOME}/providerscripts/datastore/config/toolkit/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/${new_scale_values} "root" "no"


if ( [ "`${BUILD_HOME}/providerscripts/datastore/config/toolkit/ListFromConfigDatastore.sh ${new_scale_values}`" != "" ] )
then
        /bin/echo "New Scaling Profile is present in the datastore : ${new_scale_values}"
fi

scaling_profile="`${BUILD_HOME}/providerscripts/datastore/config/toolkit/ListFromConfigDatastore.sh STATIC_SCALE:*`"
stripped_scaling_profile="`/bin/echo ${scaling_profile} | /bin/sed 's/.*STATIC_SCALE://g' | /bin/sed 's/:/ /g'`"
total_number_of_webservers="0"

for value in ${stripped_scaling_profile}
do
	total_number_of_webservers="`/usr/bin/expr ${total_number_of_webservers} + ${value}`"
done

/bin/echo ""
/bin/echo "Your number of webservers has been successfully set to: ${total_number_of_webservers}"
/bin/echo ""
