#!/bin/sh
########################################################################################
# Author: Peter Winter
# Date  : 01/03/2025
# Description : This is the script which will build a functioning authentication server. It contains
# all the configuration settings and remote calls to the authentication server we are building to ensure
# that it is built correctly and functions as it is supposed to.
########################################################################################
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
#########################################################################################
#########################################################################################
#set -x
finished=0 #This will be set to 1 if the build is valid
counter="0" #This counts how many attempted builds there have been

status () {
	yellow="`/usr/bin/tput setaf 11`"
	norm="`/usr/bin/tput sgr0`"
	/bin/echo "${yellow} ${1} ${norm}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

status ""
status ""
status ""
status "#########################AUTHENTICATION SERVER BUILD MESSAGES ARE IN YELLOW#######################"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
MULTI_REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh MULTI_REGION`"
PRIMARY_REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRIMARY_REGION`"
PRODUCTION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRODUCTION`"
BUILDOS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS`"
BUILDOS_VERSION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS_VERSION`"
AUTH_SERVER_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTH_SERVER_TYPE`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
BUILD_FROM_SNAPSHOT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_FROM_SNAPSHOT`"
WEBSERVER_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSERVER_CHOICE`"
MOD_SECURITY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh MOD_SECURITY`"
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTH_SERVER_URL`"
SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"

OPTIONS="-o ConnectTimeout=10 -o ConnectionAttempts=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "
BUILD_KEY="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"
SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

#If "finished" is set to 1, then we know that a authentication server has been successfully built and is running.
#Try up to 5 times if the authenticator is failing to complete its build
while ( [ "${finished}" != "1" ] && [ "${counter}" -lt "5" ] )
do
	counter="`/usr/bin/expr ${counter} + 1`"
	status "OK... Building an authentication server. This is the ${counter} attempt of 5"

	#Check if there is an authenticator already running. If there is, then skip building the authenticator
	if ( [ "`${BUILD_HOME}/providerscripts/server/NumberOfServers.sh "auth-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} 2>/dev/null`" -eq "0" ] )
	then
		ip=""
		#Construct a unique name for this authentication server
		RND="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1`"
		authenticator_name="auth-${REGION}-${BUILD_IDENTIFIER}-0-${RND}"

		status "Initialising a new server machine, please wait......"

		server_started="0"
		while ( [ "${server_started}" = "0" ] )
		do
			count="0"
			#Actually start the server machine. Following this, there will be an active machine instance running on your cloud provider
			${BUILD_HOME}/providerscripts/server/CreateServer.sh "${AUTH_SERVER_TYPE}" "${authenticator_name}" 

			if ( [ "$?" != "0" ] )
			then
				status "Could not create authenticator machine"
				/bin/touch /tmp/END_IT_ALL
			fi

			status "Interrogating for authenticator instance being available....if this goes on forever there is a problem"
			count="0"
			while ( [ "`${BUILD_HOME}/providerscripts/server/IsInstanceRunning.sh "${authenticator_name}" ${CLOUDHOST}`" != "running" ] && [ "${count}" -lt "120" ] )
			do
				/bin/sleep 1
				count="`/usr/bin/expr ${count} + 1`"
			done

			if ( [ "${count}" = "120" ] )
			then
				status "Machine ${authenticator_name} didn't provision correctly"
				/bin/touch /tmp/END_IT_ALL
			fi

			status "Authenticator type VPS instance is now available"

			#Check that the server has been assigned its IP addresses and that they are active
			ip=""
			private_ip=""
			count="0"

			status "Interrogating for authenticator ip address....."

			#Keep trying until we get the ip addresses of our new machine, both public and private ips
			while ( ( [ "${ip}" = "" ] || [ "${private_ip}" = "" ] ) || [ "${ip}" = "0.0.0.0" ] && [ "${count}" -lt "10" ] )
			do
				ip="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "${authenticator_name}" ${CLOUDHOST} | /bin/grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`"
				private_ip="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "${authenticator_name}" ${CLOUDHOST} | /bin/grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`"
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
				status "I haven't been able to start your server, trying again...."
			fi
		done

		AUTHIP_PUBLIC=${ip}
		AUTHIP_PRIVATE=${private_ip}

		#Store the public and private ip addresses of the authenticator machine in the datastore for access elsewhere
		if ( [ "`${BUILD_HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh authenticatorpublicip/*`" != "" ] )
		then
			${BUILD_HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh authenticatorpublicip/*
		fi

		if ( [ "`${BUILD_HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh authenticatorip/*`" != "" ] )
		then
			${BUILD_HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh authenticatorip/*
		fi
		${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${ip} authenticatorpublicip
		${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${private_ip} authenticatorip

		#If the build machine is without our VPC we want the private ip address to connect with if not within the VPC we want
		#the public address to connect to
		if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
		then
			auth_active_ip="${AUTHIP_PRIVATE}"
		elif ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
		then
			auth_active_ip="${AUTHIP_PUBLIC}"
		fi

		status "Have got the ip addresses for your authenticator (${authenticator_name})"
		status "Public IP address: ${AUTHIP_PUBLIC}"
		status "Private IP address: ${AUTHIP_PRIVATE}"

		if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys ] )
		then
			/bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys
		fi

		# When the call "CreateServer.sh" was made above a cloud-init (userdata) script was used to build out the machine
		# This script takes a certain amount of time to run, so, what I do here is just check for a completion flag which 
		# When present we can be fairly sure that the newly provisioned machine has completed its authenticator machine type
		# build process. We check very frequently so there is no wasted time and up to 300 times which means we are willing to 
		# wait for up to ten minutes (which should be more than enough) for the cloud-init script to complete

		status "Waiting for the authenticator machine ${authenticator_name} to complete its build. If you are waiting on this for more than 10 minutes, something is likely wrong"
		status "This is the current time for your reference `/bin/date`"

		finished="0"
		alive=""
		count="0"

		probe_attempts="600"

		if ( [ "`/bin/grep "^${WEBSERVER_CHOICE}:source" ${BUILD_HOME}/builddescriptors/buildstyles.dat`" != "" ] && [ "${BUILD_FROM_SNAPSHOT}" != "1" ] )
		then
			status "${authenticator_name} is compiling from source, it may take a bit longer"
			probe_attempts="`/usr/bin/expr ${probe_attempts} + 150`"
			if ( [ "${MOD_SECURITY}" = "1" ] )
			then
				probe_attempts="`/usr/bin/expr ${probe_attempts} + 300`"
			fi
		fi

		while ( [ "${alive}" != "AUTHENTICATOR_READY" ] && [ "${count}" -lt "${probe_attempts}" ] )
		do
			count="`/usr/bin/expr ${count} + 1`"
			/bin/sleep 2                        
			alive="`/usr/bin/ssh -q -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${auth_active_ip} "/usr/bin/test -f /home/${SERVER_USER}/runtime/AUTHENTICATOR_READY && /bin/echo 'AUTHENTICATOR_READY'"`"
		done

		if ( [ "${count}" = "${probe_attempts}" ] )
		then
			#If we are here then the build didn't complete correctly
			finished="0"
		else
			#If we are here then we believe that the build completed correctly so the public IP address for the our authenticator machine
			#Is added to the DNS provider
			if ( [ "${MULTI_REGION}" = "0" ] || ( [ "${MULTI_REGION}" = "1" ] && [ "${PRIMARY_REGION}" = "1" ] ) )
			then
				${BUILD_HOME}/initscripts/InitialiseDNSRecord.sh ${ip} "primary" ${WEBSITE_URL} "yes"
			fi
			finished="1"
		fi

		#If $done != 1, then the authenticator didn't build properly, so, destroy the machine
		if ( [ "${finished}" != "1" ] )
		then
			status "################################################################################################################"
			status "Hi, an authenticator server didn't seem to build correctly. I can destroy it and I can try to build a new authentication server for you"
			status "################################################################################################################"
			status "Press the <enter> key to be continue with the next attempt <ctrl - c> to exit"

			if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
			then
				read response
			fi

			#Our build failed so we don't want any ip address records stored in the S3 datastore
			#We should destroy the server also because it's hosed
			${BUILD_HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh authenticatorpublicip
			${BUILD_HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh authenticatorip
			${BUILD_HOME}/providerscripts/server/DestroyServer.sh ${AUTHIP_PUBLIC} ${CLOUDHOST}

			#Wait until we are sure that the authentication server is destroyed because of a faulty build
			while ( [ "`${BUILD_HOME}/providerscripts/server/NumberOfServers.sh "auth-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} 2>/dev/null`" != "0" ] )
			do
				/bin/sleep 5
			done
		else
			#Happy days, if we are here then we are confident that an authentication server built correctly
			status "An authentication server (${authenticator_name}) has built correctly (`/usr/bin/date`) and is accepting connections"
			counter="`/usr/bin/expr ${counter} - 1`"
		fi
	else
		#An authentication server is already running in the current region ask if we can use that one
		status "It looks like you already have an authenticator running in your specified region"
		status "The authenticator you are asking me to build looks like it's excess to the configured requirements"
		status "Will not be creating authenticator"
		/bin/touch /tmp/END_IT_ALL
		finished="1"
	fi
done

#If we get to here then we know that the authentication server didn't build properly after multiple attempts, so report it and exit
if ( [ "${counter}" = "5" ] )
then
	status "The infrastructure failed to intialise because of a build problem, please investigate, correct and rebuild"
	/bin/touch /tmp/END_IT_ALL
fi
