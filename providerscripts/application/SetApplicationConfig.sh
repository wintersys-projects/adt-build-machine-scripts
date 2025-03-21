#!/bin/sh
####################################################################################
# Description: This will set the application configuration for use by the webservers
# The application configuration (for example configuration.php for Joomla) will be
# set here and uploaded to the config bucket in the datastore and the websevers will
# pull the configuration from there. You can extend the application specific settings
# to any level of detail right the way up to configuring every configurable setting 
# if you chose to. What I do here is set the bare minimum to get the application 
# online which basically means database and hostname/ip address
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

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" >> /dev/fd/4  2>/dev/null
}

database_ip="${1}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
APPLICATION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION`"
BUILD_ARCHIVE_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_ARCHIVE_CHOICE`"
database_username="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_USERNAME'`"
database_password="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_PASSWORD'`"
database_name="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_NAME'`"
db_port="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_PORT'`"
database_identifier="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_IDENTIFIER'`"

if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" = "1" ] )
then
	if ( [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] )
	then
		/bin/echo "Database name: ${database_name}" 
		/bin/echo "Database username: ${database_username}" 
		/bin/echo "Database password: ${database_password}" 
	fi
else
	if ( [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] )
	then
		/bin/echo "Database name: ${database_name}" >&3
		/bin/echo "Database username: ${database_username}" >&3
		/bin/echo "Database password: ${database_password}" >&3
	fi
fi

. ${BUILD_HOME}/providerscripts/application/${APPLICATION}/SetApplicationConfig.sh

