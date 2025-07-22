#!/bin/sh
##############################################################################################################
# Author: Peter Winter
# Date  : 12/07/2016
# Description : This is the script which will build a functioning database server. It contains
# all the configuration settings and remote calls to the database server we are building to ensure
# that it is built correctly and functions as it is supposed to.
###############################################################################################################
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
finished="0" #If the build succeeds, this will be set to 1
counter="0" #This counts up how many build attempts there has been

status () {
	red="`/usr/bin/tput setaf 7`"
	norm="`/usr/bin/tput sgr0`"
	/bin/echo "${red} ${1} ${norm}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

status ""
status ""
status ""
status "#########################DATABASE BUILD MESSAGES ARE IN WHITE#######################"


BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
DATABASE_INSTALLATION_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DATABASE_INSTALLATION_TYPE`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
BUILDOS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS`"
BUILDOS_VERSION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS_VERSION`"
DB_SERVER_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DB_SERVER_TYPE`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh INFRASTRUCTURE_REPOSITORY_OWNER`"
BASELINE_DB_REPOSITORY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BASELINE_DB_REPOSITORY`"
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
WEBSITE_IDENTIFIER="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`"

SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"

OPTIONS="-o ConnectTimeout=10 -o ConnectionAttempts=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "
BUILD_KEY="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"
SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

#If we are done then we can stop otherwise retry up to 5 times
while ( [ "${finished}" != "1" ] && [ "${counter}" -lt "5" ] && [ "${DATABASE_INSTALLATION_TYPE}" != "None" ] )
do
	counter="`/usr/bin/expr ${counter} + 1`"
	status "OK... building a database server. This is attempt ${counter} of 5"

	#Make sure a database is not already running
	if ( [ "`${BUILD_HOME}/providerscripts/server/NumberOfServers.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} 2>/dev/null`" -eq "0" ] )
	then
		ip=""
		#Create an identifier from our the user name we allocated to identify the database server
		RND="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1`"
		database_name="db-${REGION}-${BUILD_IDENTIFIER}-${RND}"

		status "Initialising a new server machine, please wait......"

		server_started="0"
		while ( [ "${server_started}" = "0" ] )
		do
			count="0"
			#Actually spin up the machine we are going to build on
			${BUILD_HOME}/providerscripts/server/CreateServer.sh "${DB_SERVER_TYPE}" "${database_name}"

			if ( [ "$?" != "0" ] )
			then
				status "Could not create database machine"
				/bin/touch /tmp/END_IT_ALL
			fi

			status "Interrogating for database instance being available....if this goes on forever there is a problem"
			count="0"

			while ( [ "`${BUILD_HOME}/providerscripts/server/IsInstanceRunning.sh "${database_name}" ${CLOUDHOST}`" != "running" ] && [ "${count}" -lt "120" ] )
			do
				/bin/sleep 1
				count="`/usr/bin/expr ${count} + 1`"
			done

			if ( [ "${count}" = "120" ] )
			then
				status "Machine ${database_name} didn't provision correctly"
				/bin/touch /tmp/END_IT_ALL
			fi

			status "Database type VPS instance is now available"

			#Check that the server has been assigned its IP addresses and that they are active
			ip=""
			private_ip=""
			count="0"

			status "Interrogating for database ip address....."

			while ( ( [ "${ip}" = "" ] || [ "${private_ip}" = "" ] ) && [ "${count}" -lt "10" ] )
			do
				ip="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "${database_name}" ${CLOUDHOST} | /bin/grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`"
				private_ip="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "${database_name}" ${CLOUDHOST} | /bin/grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`"
				/bin/sleep 5
				count="`/usr/bin/expr ${count} + 1`"
			done

			if ( [ "${ip}" != "" ] && [ "${private_ip}" != "" ] )
			then
				server_started="1"
			elif ( [ "${ip}" != "" ] && [ "${private_ip}" = "" ] )
			then
				status "Found a public ip address but not a private ip address"
				status "This likely means that there is some sort problem with the VPC"
			else
				status "Haven't been able to start your server, I will try again....." 
			fi
		done

		DBIP_PUBLIC="${ip}"
		DBIP_PRIVATE="${private_ip}"
		DB_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DB_IDENTIFIER`"

		#Record the database IP address for later reference if this is a self managed database rather than a DB managed by a cloudhost
		if ( [ "${DB_IDENTIFIER}" = "self-managed" ] )
		then
			${BUILD_HOME}/helperscripts/SetVariableValue.sh "DB_IDENTIFIER=${DBIP_PRIVATE}"
		fi

		#Add the IP addresse of the database server to the S3 datastore
		if ( [ "`${BUILD_HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh databasepublicip/*`" != "" ] )
		then
			${BUILD_HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh databasepublicip/*
		fi
		if ( [ "`${BUILD_HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh databaseip/*`" != "" ] )
		then
			${BUILD_HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh databaseip/*
		fi
		${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${ip} databasepublicip/${ip}
		${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${private_ip} databaseip/${private_ip}

		#If the build machine is attached to the VPC we want the private IP address if it isn't we want the public one
		if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
		then
			db_active_ip="${DBIP_PRIVATE}"
		elif ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
		then
			db_active_ip="${DBIP_PUBLIC}"
		fi


		#Store the IP addresses on the filesystem of the build machine in case we need to reference them

		if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/DBIP:* ] )
		then
			/bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/DBIP:*
		fi

		if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/DBPRIVATEIP:* ] )
		then
			/bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/DBPRIVATEIP:*
		fi

		if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips ] )
		then
			/bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips
		fi

		/bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/DBIP:${DBIP_PUBLIC}
		/bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/DBPRIVATEIP:${DBIP_PRIVATE}

		#We create an ip mask for our server this is used when we set access privileges and so on within the database
		#and we want to allow access from machines on our private network
		IP_MASK="`/bin/echo ${DBIP_PRIVATE} | /bin/grep -oE '[0-9]{1,3}\.[0-9]{1,3}' | /usr/bin/head -1`"
		IP_MASK=${IP_MASK}".%.%"

		status "Have got the ip addresses for your database (${database_name})"
		status "Public IP address: ${DBIP_PUBLIC}"
		status "Private IP address: ${DBIP_PRIVATE}"

		if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys ] )
		then
			/bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys
		fi

		if ( [ "${BASELINE_DB_REPOSITORY}" != "" ] )
		then
			/usr/bin/ssh -q -p ${SSH_PORT} ${OPTIONS} -i ${BUILD_KEY} ${SERVER_USER}@${db_active_ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/utilities/config/StoreConfigValue.sh 'BASELINEDBREPOSITORY' ${BASELINE_DB_REPOSITORY}" 
		fi

		# When the call "CreateServer.sh" was made above a cloud-init (userdata) script was used to build out the machine
		# This script takes a certain amount of time to run, so, what I do here is just check for a completion flag which 
		# When present we can be fairly sure that the newly provisioned machine has completed its database machine type
		# build process. We check very frequently so there is no wasted time and up to 300 times which means we are willing to 
		# wait for up to ten minutes (which should be more than enough) for the cloud-init script to complete

		status "Waiting for the database machine ${database_name} to complete its build. If you are waiting on this for more than 10 minutes, something is likely wrong"
		status "This is the current time for your reference `/bin/date`"

		#Check that the database is built and ready for action
		finished="0"
		alive=""
		count="0"
		while ( [ "${alive}" != "DATABASE_READY" ] && [ "${count}" -lt "300" ] )
		do
			count="`/usr/bin/expr ${count} + 1`"
			/bin/sleep 2
			alive="`/usr/bin/ssh -q -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${db_active_ip} "/usr/bin/test -f /home/${SERVER_USER}/runtime/DATABASE_READY && /bin/echo 'DATABASE_READY'"`"
		done

		if ( [ "${count}" = "300" ] )
		then
			finished="0"
		else
			finished="1"
		fi

		#If $done != 1 then it means the DB server didn't build correctly and fully, so destroy the machine it was being built on
		if ( [ "${finished}" != "1" ] )
		then
			#If we are here then it means we didn't build successfully and we will have to try again
			status "###########################################################################################################################"
			status "Hi, a database server didn't seem to build correctly. I can destroy it and try again to build a new database server for you"
			status "###########################################################################################################################"
			status "Press the <enter> key to be continue with the next attempt <ctrl - c> to exit"

			if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
			then
				read response
			fi

			#We failed so we don't want the IP addresses in our datastore
			${BUILD_HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh databasepublicip
			${BUILD_HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh databaseip
			${BUILD_HOME}/providerscripts/server/DestroyServer.sh ${DBIP_PUBLIC} ${CLOUDHOST}

			#Wait until we are sure that the database server(s) are destroyed because of a faulty build
			while ( [ "`${BUILD_HOME}/providerscripts/server/NumberOfServers.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} 2>/dev/null`" != "${built}" ] )
			do
				/bin/sleep 5
			done 
			count1="`/usr/bin/expr ${count1} - 1`"
		else
			#Happy days, if we are here, then it means that the database server is believed to have been built correctly
			status "A database server (${database_name}) has built correctly (`/usr/bin/date`) and is accepting connections"
			counter="`/usr/bin/expr ${counter} - 1`"
		fi
	else
		#A datatbase server is already running
		status "It looks like you already have a database running in your specified region"
		status "The database you are asking me to build looks like it's excess to the configured requirements"
		status "Will not be creating database"
		/bin/touch /tmp/END_IT_ALL
		finished="1"
	fi
done

#If we get to here then we know that the database hasn't built correctly after several attmepts, so report it and exit
if ( [ "${counter}" = "5" ] )
then
	status "The infrastructure failed to intialise because of a build problem, please investigate, correct and rebuild"
	/bin/touch /tmp/END_IT_ALL
fi
