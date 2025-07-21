#!/bin/sh
####################################################################################
# Description: This will set the application configuration for use by the webservers
# The application configuration (for example configuration.php for Joomla) will be
# set here and uploaded to the config bucket in the datastore and the websevers will
# pull the configuration from there. You can extend the application specific settings
# to any level of detail right the way up to configuring every configurable setting 
# if you chose to. What I do here is set the bare minimum to get the application 
# online which basically means database and hostname/ip address
# Workflow is:
# 1. generate a valid configuration file for our application using live values
# 2. copy the configuration file to the S3 datastore for use anywhere in the build
# 3. Have each webserver obtain the configuration file that has been set here for its live usage
# 4. Application configuration updates through an application GUI or through direct
# config file modification are copied to the datastore and pushed out to every webserver
# in the current server fleet by the webserver that happened to be the one that the
# configuration update applied to.
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
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
APPLICATION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION`"
BUILD_ARCHIVE_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_ARCHIVE_CHOICE`"
DB_USERNAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_USERNAME'`"
DB_PASSWORD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_PASSWORD'`"
DB_NAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_NAME'`"
DB_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_PORT'`"
DB_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_IDENTIFIER'`"

if ( [ "`/bin/echo ${DB_USERNAME} | /bin/grep ':::'`" != "" ] )
then
	DB_USERNAME="`/bin/echo ${DB_USERNAME} | /bin/sed 's/:::/ /g' | /usr/bin/awk '{print $NF}'`"
fi

if ( [ "`/bin/echo ${DB_PASSWORD} | /bin/grep ':::'`" != "" ] )
then
	DB_PASSWORD="`/bin/echo ${DB_PASSWORD} | /bin/sed 's/:::/ /g' | /usr/bin/awk '{print $NF}'`"
fi

if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" = "1" ] )
then
	if ( [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] )
	then
		/bin/echo "Database name: ${DB_NAME}" 
		/bin/echo "Database username: ${DB_USERNAME}" 
		/bin/echo "Database password: ${DB_PASSWORD}" 
	fi
else
	if ( [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] )
	then
		/bin/echo "Database name: ${DB_NAME}" >&3
		/bin/echo "Database username: ${DB_USERNAME}" >&3
		/bin/echo "Database password: ${DB_PASSWORD}" >&3
	fi
fi

. ${BUILD_HOME}/application/${APPLICATION}/SetApplicationConfig.sh

