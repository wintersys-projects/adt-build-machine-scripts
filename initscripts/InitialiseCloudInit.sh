#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This will configure cloud-init scripts for each machine type that
# you want to build. The result of this script is a valid cloud-init script with 
# live data ready to be passed to a VPS instance when it is provisioned using 
# a CLI call
##################################################################################
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
#set -x

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
AUTHENTICATION_SERVER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTHENTICATION_SERVER`"
PRODUCTION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRODUCTION`"
DEVELOPMENT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DEVELOPMENT`"
NO_AUTOSCALERS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NO_AUTOSCALERS`"
NO_REVERSE_PROXY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NO_REVERSE_PROXY`"
BYPASS_DB_LAYER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BYPASS_DB_LAYER`"


if ( [ "${AUTHENTICATION_SERVER}" = "1" ] )
then
	${BUILD_HOME}/initscripts/cloud-init/AuthenticatorCloudInit.sh
fi

if ( [ "${PRODUCTION}" = "1" ] && [ "${DEVELOPMENT}" = "0" ] && [ "${NO_AUTOSCALERS}" != "0" ] )
then
	${BUILD_HOME}/initscripts/cloud-init/AutoscalerCloudInit.sh
fi

if ( [ "${NO_REVERSE_PROXY}" != "0" ] )
then
	${BUILD_HOME}/initscripts/cloud-init/ReverseProxyCloudInit.sh
fi


if ( [ "${BYPASS_DB_LAYER}" != "2" ] )
then
	${BUILD_HOME}/initscripts/cloud-init/DatabaseCloudInit.sh
fi


