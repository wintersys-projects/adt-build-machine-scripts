#!/bin/sh
####################################################################################
# Description: This sets up the database credentials and some other configuration
# settings necessary for the wordpress application to be brought online
# Date: 07/11/2024
# Author: Peter Winter
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
#####################################################################################
#####################################################################################
#set -x

WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'WEBSITE_URL'`"
WEBSITE_USERNAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'S3_ACCESS_KEY' | /usr/bin/head -c 8`"
WEBMASTER_EMAIL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'SYSTEM_TOEMAIL_ADDRESS'`"

if ( [ ! -d  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application ] )
then
        /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application
fi

/bin/cp ${BUILD_HOME}/application/descriptors/${APPLICATION}.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat

if ( [ "`/bin/grep "^INTERACTIVE_APPLICATION_INSTALL:no" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat`" != "" ] )
then
        /bin/sed -i "s/XXXXAPPLICATION_USERNAMEXXXX/${DB_USERNAME}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat        
        /bin/sed -i "s/XXXXAPPLICATION_PASSWORDXXXX/${DB_PASSWORD}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
        /bin/sed -i "s/XXXXAPPLICATION_DATABASEXXXX/${DB_NAME}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
        /bin/sed -i "s/XXXXWEBSITE_URLXXXX/${WEBSITE_URL}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
fi


