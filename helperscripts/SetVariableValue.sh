#!/bin/sh
###########################################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : The build environment is stored in a file and you can set the value of a variable using
# this script
###########################################################################################################
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

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_CLOUDHOST`"
BUILD_IDENTIFIER="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER`"
BUILD_ENVIRONMENT="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/build_environment"

if ( [ "${1}" != "" ] )
then
	keyvalue="${1}"
fi

key="`/bin/echo ${keyvalue} | /usr/bin/awk -F'=' '{print $1}'`"

if ( [ "`/bin/grep "^${key}=" ${BUILD_ENVIRONMENT}`" = "" ] )
then
	/bin/echo "${keyvalue}" >> ${BUILD_ENVIRONMENT}
else
	/bin/sed -i "s/${key}=.*/${keyvalue}/" ${BUILD_ENVIRONMENT}
fi
