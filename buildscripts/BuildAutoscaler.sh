#!/bin/sh
###############################################################################################################
# Author: Peter Winter
# Date  : 12/07/2016
# Description : This is the script which will build a functioning autoscaler server. It contains
# all the configuration settings and remote calls to the autoscaler server we are building to ensure
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

finished="0" #If the build succeeds, this will be set to "1"
counter="0" #This keeps track of how many build attempts there have been

status () {
	red="`/usr/bin/tput setaf 1`"
	norm="`/usr/bin/tput sgr0`"
	/bin/echo "${red} ${1} ${norm}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

status ""
status ""
status ""
status "#########################AUTOSCALER BUILD MESSAGES ARE IN RED#######################"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
WEBSITE_DISPLAY_NAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_DISPLAY_NAME`"
NO_AUTOSCALERS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NO_AUTOSCALERS`"
BUILDOS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS`"
BUILDOS_VERSION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS_VERSION`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
ALGORITHM="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ALGORITHM`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh INFRASTRUCTURE_REPOSITORY_OWNER`"
NO_AUTOSCALERS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NO_AUTOSCALERS`"
AS_SERVER_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AS_SERVER_TYPE`"
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"

SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"
OPTIONS="-o ConnectTimeout=10 -o ConnectionAttempts=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "

BUILD_KEY="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"
SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

# If finished=1, then we know that the autoscaler has been successfully built. We try up to 5 times before we give up if it fails
while ( [ "${finished}" != "1" ] && [ "${counter}" -lt "5" ] )
do
	counter="`/usr/bin/expr ${counter} + 1`"
	#If we are building multiple autoscalers we see how many autoscalers are running and number our current autoscaler relative to that
	autoscaler_no="${1}"

	status "OK... Building autoscaler ${autoscaler_no}. This is the ${counter} attempt of 5"

	WEBSITE_IDENTIFIER="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`"
	WEBSITE_DISPLAY_NAME_FILE="`/bin/echo ${WEBSITE_DISPLAY_NAME} | /bin/sed 's/ /_/g'`"

	#As long as this autoscaler number is lower or equal to the number of autoscalers we want, proceed with the build
	if ( [ "${autoscaler_no}" -le "${NO_AUTOSCALERS}" ] )
	then
		ip=""
		#Set a unique identifier and name for our new autoscaler server including which number autoscaler it is
		RND="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1`"
		autoscaler_name="NO-${autoscaler_no}-as-${REGION}-${BUILD_IDENTIFIER}-${RND}"

		status "Initialising a new server machine, please wait......"

		server_started="0"
		while ( [ "${server_started}" = "0" ] )
		do
			count="0"
			#Actually create the autoscaler machine. If the create fails, keep trying 
			${BUILD_HOME}/providerscripts/server/CreateServer.sh "${AS_SERVER_TYPE}" "${autoscaler_name}" 

			if ( [ "$?" != "0" ] )
			then
				status "Could not create autoscaler machine"
				/bin/touch /tmp/END_IT_ALL
			fi

			status "Interrogating for autoscaler instance being available....if this goes on forever there is a problem"
			count="0"
			while ( [ "`${BUILD_HOME}/providerscripts/server/IsInstanceRunning.sh "${autoscaler_name}" ${CLOUDHOST}`" != "running" ] && [ "${count}" -lt "120" ] )
			do
				/bin/sleep 1
				count="`/usr/bin/expr ${count} + 1`"
			done

			if ( [ "${count}" = "120" ] )
			then
				status "Machine ${autoscaler_name} didn't provision correctly"
				/bin/touch /tmp/END_IT_ALL
			fi

			status "Autoscaler type VPS instance is now available"

			#Get the ip addresses of the server we have just built
			ip=""
			private_ip=""
			count="0"

			status "Interrogating for autoscaler ip addresses....."

			while ( ( [ "${ip}" = "" ] || [ "${private_ip}" = "" ] ) && [ "${count}" -lt "10" ] )
			do
				ip="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "${autoscaler_name}" ${CLOUDHOST} | /bin/grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`"
				private_ip="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "${autoscaler_name}" ${CLOUDHOST} | /bin/grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`"
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
				status "I haven't been able to start your server for you, trying again...."
			fi
		done

		status "It looks like the machine has booted OK"

		#We should record the ip addresses of our new autoscaler in the S3 datastore for future reference
		if ( [ "${autoscaler_no}" = "1" ] )
		then
			if ( [ "`${BUILD_HOME}/providerscripts/datastore/config/toolkit/ListFromConfigDatastore.sh autoscalerpublicips/*`" != "" ] )
			then
				${BUILD_HOME}/providerscripts/datastore/config/toolkit/DeleteFromConfigDatastore.sh autoscalerpublicips/*
			fi
			if ( [ "`${BUILD_HOME}/providerscripts/datastore/config/toolkit/ListFromConfigDatastore.sh autoscalerips/*`" != "" ] )
			then
				${BUILD_HOME}/providerscripts/datastore/config/toolkit/DeleteFromConfigDatastore.sh autoscalerips/*
			fi
		fi
		${BUILD_HOME}/providerscripts/datastore/config/toolkit/PutToConfigDatastore.sh ${ip} autoscalerpublicips "no"
		${BUILD_HOME}/providerscripts/datastore/config/toolkit/PutToConfigDatastore.sh ${private_ip} autoscalerips "no"

		#If the build machine is attached to the VPC that the servers are in then we need the private IP address to connect to this autoscaler
		#with, otherwise we have to use the public IP address
		if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
		then
			as_active_ip="${private_ip}"
		elif ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
		then
			as_active_ip="${ip}"
		fi

		status "Have got the ip addresses for your autoscaler (${autoscaler_name})"
		status "Public IP address: ${ip}"
		status "Private IP address: ${private_ip}"

		if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys ] )
		then
			/bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys
		fi

		# When the call "CreateServer.sh" was made above a cloud-init (userdata) script was used to build out the machine
		# This script takes a certain amount of time to run, so, what I do here is just check for a completion flag which 
		# When present we can be fairly sure that the newly provisioned machine has completed its autoscaler machine type
		# build process. We check very frequently so there is no wasted time and up to 300 times which means we are willing to 
		# wait for up to ten minutes (which should be more than enough) for the cloud-init script to complete

		status "Waiting for the autoscaling machine ${autoscaler_name} to complete its build. If you are waiting on this for more than 10 minutes, something is likely wrong"
		status "This is the current time for your reference `/bin/date`"

		finished="0"
		alive=""
		count="0"

		while ( [ "${alive}" != "AUTOSCALER_READY" ] && [ "${count}" -lt "300" ] )
		do
			count="`/usr/bin/expr ${count} + 1`"
			/bin/sleep 2
			alive="`/usr/bin/ssh -q -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${as_active_ip} "/usr/bin/test -f /home/${SERVER_USER}/runtime/AUTOSCALER_READY && /bin/echo 'AUTOSCALER_READY'"`"
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
			#If we are here then we believe that the autoscaler didn't build correctly
			status "#########################################################################################################################"
			status "Hi, an autoscaler didn't seem to build correctly. I can destroy it and I can try again to build a new autoscaler for you."
			status "#########################################################################################################################"
			status "Press the <enter> key to be continue with the next attempt <ctrl - c> to exit"

			if ( [ "${HARDCORE}" != "1" ] )
			then
				read response
			fi

			#Delete the autoscaler IP addresses from the S3 datastore because they were clearly not needed because of failure
			${BUILD_HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh autoscalerpublicip
			${BUILD_HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh autoscalerip
			${BUILD_HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}

			#Wait until we are sure that the autoscaler server(s) are destroyed because of a faulty build
			while ( [ "`${BUILD_HOME}/providerscripts/server/NumberOfServers.sh "NO-${autoscaler_no}-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} 2>/dev/null`" != "0" ] )
			do
				/bin/sleep 5
			done    
		else
			#Happy days, if we are here then the autoscaler has built correctly
			status "An autoscaler (${autoscaler_name}) has built correctly (`/usr/bin/date`) and is accepting connections"
			counter="0"
		fi
	else
		#An appropriate looking autoscaler is already running in the current region
		status "Configured to use ${NO_AUTOSCALERS} autoscalers and found ${autoscaler_no} running whilst trying to build more"
		status "The autoscaler you are asking me to build looks like it's excess to the configured requirements"
		status "Will not be creating autoscaler"
		/bin/touch /tmp/END_IT_ALL
		finished="1"
	fi
done

#If our count got to 5, then we know that none of the attempts succeeded in building our autoscaler, so, report this and exit because we can't run without an autoscaler
if ( [ "${counter}" = "5" ] )
then
	status "The infrastructure failed to intialise because of a build problem with the autoscaler, please investigate, correct and rebuild"
	/bin/touch /tmp/END_IT_ALL
fi
