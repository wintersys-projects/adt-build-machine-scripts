#!/bin/sh
###################################################################################
# Author: Peter Winter
# Date  : 12/07/2016
# Description : This will initialise the scaling  profile values in the datastore
###################################################################################
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
##################################################################################
##################################################################################
#set -x

status () {
        /bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
        /bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
PRODUCTION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRODUCTION`"
DEVELOPMENT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DEVELOPMENT`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
#NO_AUTOSCALERS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NO_AUTOSCALERS`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
#NO_WEBSERVERS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NO_WEBSERVERS`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"

if ( [ "${PRODUCTION}" = "1" ] && [ "${DEVELOPMENT}" = "0" ] )
then
	if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:* ] )
	then
		/bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:*
	fi

#	status ""
#	status "##################################################################################################################"
#	status "Setting scaling value for number of webservers to ${NO_WEBSERVERS} distributed across ${NO_AUTOSCALER} autoscalers"
#	status "##################################################################################################################"
#	status ""

#	base_number_of_webservers="`/usr/bin/expr ${NO_WEBSERVERS} / ${NO_AUTOSCALERS}`"
#	total_base_number_of_webservers="`/usr/bin/expr ${base_number_of_webservers} \* ${NO_AUTOSCALERS}`"
#	additional_number_of_webservers="`/usr/bin/expr ${NO_AUTOSCALERS} - ${total_base_number_of_webservers}`"

#	for autoscaler_no in `printf "%d\n" $(seq 1 ${NO_AUTOSCALERS})`
#	do
 #       if ( [ "${additional_number_of_webservers}" -gt "0" ] )
  #      then
  #              new_scale_values="${new_scale_values}`/usr/bin/expr ${base_number_of_webservers} + 1`:"
  #              additional_number_of_webservers="`/usr/bin/expr ${additional_number_of_webservers} - 1`"
  #      else
  #              new_scale_values="${new_scale_values}${base_number_of_webservers}:"
  #      fi
#	done

#	new_scale_values="`/bin/echo "${new_scale_values}" | /bin/sed 's/:/ /g'`"
	
	${BUILD_HOME}/providerscripts/datastore/operations/MountDatastore.sh "scaling" "local" "scaling-${CLOUDHOST}-${REGION}"
	${BUILD_HOME}/providerscripts/datastore/operations/DeleteFromDatastore.sh "scaling" "autoscaler-*/STATIC_SCALE:" "local" "${WEBSITE_URL}-scaling-${CLOUDHOST}-${REGION}"

#	no_autoscaler="1"
#	while ( [ "${no_autoscaler}" -le "${NO_AUTOSCALERS}" ] && [ "${no_autoscaler}" -le "${NO_WEBSERVERS}" ] )
#	do
#		if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/scaling/autoscaler-${no_autoscaler} ] )
#		then
#			/bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/scaling/autoscaler-${no_autoscaler}
#		fi
#		scale_value="`/bin/echo ${new_scale_values} | /usr/bin/cut -d' ' -f${no_autoscaler}`"
#		/bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/scaling/autoscaler-${no_autoscaler}/STATIC_SCALE:${scale_value}
#		${BUILD_HOME}/providerscripts/datastore/operations/DeleteFromDatastore.sh "scaling" "*autoscaler-${no_autoscaler}*" "local" "scaling-${CLOUDHOST}-${REGION}"
#		${BUILD_HOME}/providerscripts/datastore/operations/PutToDatastore.sh "scaling" "${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/scaling/autoscaler-${no_autoscaler}/STATIC_SCALE:${scale_value}" "autoscaler-${no_autoscaler}" "local" "no" "scaling-${CLOUDHOST}-${REGION}"
#		no_autoscaler="`/usr/bin/expr ${no_autoscaler} + 1`"
#	done

#	if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
#	then
#		status ""
#		status "Press <enter> to accept these values"
#		status ""
#		read x
#	fi
fi

