#!/bin/sh
###############################################################################################
# Description: You can use this script to get the credentials for your application when you are
# making a virgin deployment of an application
# Author Peter Winter
# Date 22/9/2024
##############################################################################################
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
################################################################################################
###############################################################################################
#set -x

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

cloudhost="${1}"
build_identifier="${2}"

if ( [ "${cloudhost}" = "" ] )
then
        CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
else
        CLOUDHOST="${cloudhost}"
fi

if ( [ "${build_identifier}" = "" ] )
then
        BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
else
        BUILD_IDENTIFIER="${build_identifier}"
fi

if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/application_credentials.dat ] )
then
        /bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/application_credentials.dat 
else
        /bin/echo "Couldn't find any credentials for your application, sorry"
fi
