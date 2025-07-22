#!/bin/sh
################################################################################################################################################
# Description: Not all applications play the same, so if you have some particular post processing messages and so on that you need to display
# then you can add them here and they will be displayed to the user at the end of the build process
# Author: Peter Winter
# Date: 17/01/2017
################################################################################################################################################
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
set -x

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
ALGORITHM="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ALGORITHM`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
APPLICATION_BASELINE_SOURCECODE_REPOSITORY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_BASELINE_SOURCECODE_REPOSITORY`"
BASELINE_DB_REPOSITORY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BASELINE_DB_REPOSITORY`"
APPLICATION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION`"
DB_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DB_PORT`"
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh INFRASTRUCTURE_REPOSITORY_OWNER`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
AUTHENTICATION_SERVER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTHENTICATION_SERVER`"
DNS_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_CHOICE`"
MULTI_REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh MULTI_REGION`"

SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"
SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

BUILD_KEY="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"

OPTIONS="-o ConnectTimeout=10 -o ConnectionAttempts=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "

#If the build machine is attached to the VPC then get the private IP addresses, if it isn't, get the public ones
if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
then
	ws_ips="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "ws-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
	db_ip="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "db-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
else
	ws_ips="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "ws-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
	db_ip="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "db-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
fi

status "###############################################################################################################################"
status "`/usr/bin/banner "IMPORTANT"`"

#If this is a virgin build, show the application credentials so that the  application can be installed
if ( [ "${BASELINE_DB_REPOSITORY}" = "VIRGIN" ] )
then
	if ( [ "`/bin/grep "^BUILDCHAINTYPE:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "standard" ] || [ "`/bin/grep "^BUILDCHAINTYPE:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "database" ] )
	then
		status "###############################################################################################################################"
		status "OK, I'll be kind and show you one time your ${APPLICATION} database credentials."
		status "Please make a note of them but remember to keep them safe and secret"
		status "You can enter them in the GUI system when you install the application"
		status "#########################################"

		if ( [ "${HARDCORE}" = "1" ] )
		then
			if ( [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] )
			then
				/bin/echo "Database name: `${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_NAME'`" 
				/bin/echo "Database username: `${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_USERNAME'`" 
				/bin/echo "Database password: `${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_PASSWORD'`" 
			fi
		else
			if ( [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] )
			then
				/bin/echo "Database name: `${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_NAME'`" >&3
				/bin/echo "Database username: `${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_USERNAME'`" >&3
				/bin/echo "Database password: `${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_PASSWORD'`" >&3
			fi
		fi

		status "#########################################"
		status "The database public IP address is: `${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "db-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
		status "The database private IP address is: `${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "db-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"` (try this one first from your application if it timesout, try the public one)"
		status "The database port is ${DB_PORT}"
		status "You can make up your own database prefix but make sure to include the '_' character at the end of your prefix (for example 'dbprefix_')"
		status "#########################################"

		#Remind the deployer to add the port number to the hostname in the application when the database port is not the default port
		if ( [ "${APPLICATION}" = "joomla" ] && [ "${DB_PORT}" != "3306" ] && [ "${DB_PORT}" != "5432" ] )
		then
			status "You are not using the default port for your database"
			status "REMEMBER to tell joomla this by putting the database hostname as ${db_ip}:${DB_PORT} when you enter it in the GUI during the install process"
			status "######################################"
		fi

		if ( [ "${APPLICATION}" = "wordpress" ] && [ "${DB_PORT}" != "3306" ] )
		then
			status "You are not using the default port for your database"
			status "REMEMBER to tell wordpress this by putting the database hostname as ${db_ip}:${DB_PORT} when you enter it in the GUI during the install process"
			status "######################################"
		fi

		#Suggest the correct URL to complete the installation process for different application types
		if ( [ "${APPLICATION}" = "joomla" ] )
		then
			status ""
			status "##################################################################################################"
			status "To complete the installation of joomla please go to https://${WEBSITE_URL}/installation/index.php"
			status "##################################################################################################"
			status ""
		fi

		if ( [ "${APPLICATION}" = "drupal" ] )
		then
			status ""
			status "####################################################################"

			if ( [ "${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}" != "DRUPAL:cms" ] )
			then
				status "Waiting for the application install to have been completed at: https://${WEBSITE_URL}/core/install.php"
			else
				status "Waiting for the application install to have been completed at: https://${WEBSITE_URL}"
			fi
			status "Use the credentials listed above please"
			status ""

			trap '' 2
			status "ctrl-c is disabled until the application is installed and the caching tables are truncated"

			finished="1"
			while ( [ "${finished}" = "1" ] )
			do
				finished="0"
				for ws_ip in ${ws_ips}
				do
					if ( [ "`/usr/bin/ssh -q -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${ws_ip} "${SUDO} /home/${SERVER_USER}/application/processing/drupal/CheckUser.sh"`" != "USER ADDED" ] )
					then
						finished="1"
					fi
				done
				/bin/sleep 5
			done
		fi

		if ( [ "${APPLICATION}" = "moodle" ] )
		then
			status ""
			status "####################################################################"
			status "Moodle should be available at: https://${WEBSITE_URL}"
			status "####################################################################"
			status ""
		fi
	fi
fi

#With the drupal application the cache needs to be truncated (post install) otherwise there tends to be error messages
if ( [ "${APPLICATION}" = "drupal" ] )
then
	status "###################################################################################################################"
	status "Attempting to truncate cache ready for the application to be usable"
	status "###################################################################################################################"

	finished="1"
	while ( [ "${finished}" = "1" ] )
	do
		finished="0"
		for ws_ip in ${ws_ips}
		do
			if ( [ "`/usr/bin/ssh -q -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${ws_ip} "${SUDO} /home/${SERVER_USER}/application/processing/drupal/TruncateCache.sh"`" != "TRUNCATED" ] )
			then
				finished="1"
			fi
		done
		/bin/sleep 5
	done
	trap 2
fi

if ( [ "${APPLICATION}" = "wordpress" ] )
then
	status "========================================================================================================================================="
	status "If you have trouble accessing your new wordpress site, one thing that might be wrong is permalinks within wordpress"
	status "In this case, go to https://${WEBSITE_URL}/wp-admin, login and rebuild permalinks under settings->permalinks"
	status "========================================================================================================================================="
fi

#Remind the deployer how the firewall is configured
status "#############################BUILD-MACHINE_FIREWALL###############################################################################################"
status "Your build machine is looking for its firewall settings in the bucket: s3://`/bin/ls -l /root/FIREWALL-BUCKET* | /usr/bin/awk -F':' '{print $NF}'`"
status "Please review: https://github.com/${INFRASTRUCTURE_REPOSITORY_OWNER}/adt-build-machine-scripts/blob/main/doco/AgileToolkitDeployment/TightenBuildMachineAccess.md"
status "##################################################################################################################################################"

status "################################IMPORTANT#############################################################################################"
status "REMEMBER TO CONSULT: "
status "    ${BUILD_HOME}/doco/AgileToolkitDeployment/ApplicationConfigurationUpdate.md"
status "FOR HOW TO PERFORM APPLICATION CONFIGURATION UPDATES WITH THIS TOOLKIT"
status "################################IMPORTANT#############################################################################################"
