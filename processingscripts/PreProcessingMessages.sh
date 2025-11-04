#!/bin/sh
###############################################################################################
# Description: Not all providers play the same so if you have any preprocessing messages you want
# to display before the build begins, you can add then into this file and it will get executed
# prior to the build commencing.
# Author: Peter Winter
# Date : 17/01/2017
###############################################################################################
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
#set -x

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
PRODUCTION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRODUCTION`"
NO_AUTOSCALERS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NO_AUTOSCALERS`"
APPLICATION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION`"
#APPLICATION_REPOSITORY_TOKEN="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_REPOSITORY_TOKEN`"
BUILD_ARCHIVE_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_ARCHIVE_CHOICE`"
DATABASE_INSTALLATION_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DATABASE_INSTALLATION_TYPE`"
DATABASE_DBaaS_INSTALLATION_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DATABASE_DBaaS_INSTALLATION_TYPE`"
DB_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DB_PORT`"
DB_NAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DB_NAME`"

#Juat point out what region this deployment is to
status ""
status ""
status "#########################################"
status "You are deploying to region: ${REGION}"
status "#########################################"
status ""

#Let the deployer how many autoscalers are set to be built
if ( [ "${PRODUCTION}" = "1" ] )
then
	status "############################################"
	status "Number of autoscalers is set to: ${NO_AUTOSCALERS}"
	status "############################################"
fi

#if ( [ "${APPLICATION_REPOSITORY_TOKEN}" = "" ] )
#then
#	status "I find that the variable APPLICATION_REPOSITORY_TOKEN isn't set in your template so I am setting it to 'none' for you"
# 	status "This variable has to be set to a value or 'none' it can't be blank"
#        ${BUILD_HOME}/helperscripts/SetVariableValue.sh "APPLICATION_REPOSITORY_PASSWORD=none"
#fi

#If we want DDOS protection on our vultr instance it can be set to "on" in response to these questions
if ( [ "${CLOUDHOST}" = "vultr" ] )
then
	ENABLE_DDOS_PROTECION="0"
	status "You are deploying to the Vultr VPS cloud which has an option to switch on DDOS protection for your machines."
	status "If you want to switch on DDOS projection, enter 'Y' or 'y' below, anything else and DDOS protection won't be enabled". 
	status " DDoS Protection adds 10Gbps of mitigation capacity per instance and costs an additional \$10/mo."
	status "Do you want to enable DDOS protection 'Y' or 'N'"
	if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
	then
		read response

		if ( [ "${response}" = "Y" ] || [ "${response}" = "y" ] )
		then
			status "DDOS protection has been enabled"
			status "Press <enter>"
			read x
			export ENABLE_DDOS_PROTECION="1"
		else
			status "DDOS protection has not been enabled"
			status "Press <enter>"
			read x
		fi
	fi
	${BUILD_HOME}/helperscripts/SetVariableValue.sh "ENABLE_DDOS_PROTECION=${ENABLE_DDOS_PROTECION}"
fi

#We can't be in production mode and also be deploying a virgin or a baseline application
if ( [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] || [ "${BUILD_ARCHIVE_CHOICE}" = "baseline" ] )
then
	PRODUCTION="0"
	DEVELOPMENT="1"
	${BUILD_HOME}/helperscripts/SetVariableValue.sh "PRODUCTION=${PRODUCTION}"
	${BUILD_HOME}/helperscripts/SetVariableValue.sh "DEVELOPMENT=${DEVELOPMENT}"
fi

#If the database name has upper case characters in it when deploying to a DBaaS Postgres instance, set the database name to lower case
if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Postgres" ] || [ "${DATABASE_DBaaS_INSTALLATION_TYPE}" = "Postgres" ] )
then
	response=""

	if ( [ "${DB_NAME}" != "" ] )
	then
		if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
		then
			/bin/bash -c "[[ '${DB_NAME}' =~ [A-Z] ]] && /bin/touch ${BUILD_HOME}/LOWER && /bin/echo 'I know this is your worst nightmare, but, please read carefully. I have detected that you have some upper case letters in the databse name for your postgres database. By default postgres sets the database names to lower case and so chances are, this is what your postgres has done. Please review this to see if it is the case, but I thought I would give you a chance to change your database name to all lower case.' && /bin/echo && /bin/echo 'Your database name is currently set to: ${DB_NAME}.' && /bin/echo 'enter (Y|y) and I will set the characters  of your database name all to lower case for you...' && /bin/echo 'Press <enter> to leave as it is '"

			if ( [ -f ${BUILD_HOME}/LOWER ] )
			then
				read response
			fi

			if ( [ "${response}" = "Y" ] || [ "${response}" = "y" ] )
			then
				if ( [ -f ${BUILD_HOME}/LOWER ] )
				then
					/bin/rm ${BUILD_HOME}/LOWER
					DB_NAME="`/bin/echo "${DB_NAME}" | /usr/bin/tr '[:upper:]' '[:lower:]'`"
				fi
			fi

			if ( [ -f ${BUILD_HOME}/LOWER ] )
			then
				status "#################################################"
				status "Your database name is now set to: ${DB_NAME}"
				status "Press <enter> to accept"
				status "#################################################"
				read x
			fi
			${BUILD_HOME}/helperscripts/SetVariableValue.sh "DB_NAME=${DB_NAME}"
		fi
	fi
fi


