#!/bin/sh
########################################################################################
# Author: Peter Winter
# Date  : 12/07/2016
# Description : This is the script which will build a functioning webserver server. It contains
# all the configuration settings and remote calls to the webserver server we are building to ensure
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

finished="0" #This will tell us if the build has failed or succeeded finished="1" means the build succeeded
counter="0" #This tracks how many build attempts there has been

status () {
	cyan="`/usr/bin/tput setaf 4`"
	norm="`/usr/bin/tput sgr0`"
	/bin/echo "${cyan} ${1} ${norm}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

status ""
status ""
status ""
status "#########################WEBSERVER BUILD MESSAGES ARE IN BLUE#######################"


BUILD_HOME="`/bin/cat /home/buildhome.dat`"
PRODUCTION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRODUCTION`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
PRODUCTION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRODUCTION`"
BUILDOS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS`"
BUILDOS_VERSION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS_VERSION`"
WS_SERVER_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WS_SERVER_TYPE`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
BUILD_FROM_SNAPSHOT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_FROM_SNAPSHOT`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh INFRASTRUCTURE_REPOSITORY_OWNER`"
NO_REVERSE_PROXY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NO_REVERSE_PROXY`"
WEBSERVER_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSERVER_CHOICE`"
MOD_SECURITY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh MOD_SECURITY`"
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
MULTI_REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh MULTI_REGION`"

SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"

OPTIONS="-o ConnectTimeout=10 -o ConnectionAttempts=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "
OPTIONS_AUTOSCALER="-o ConnectTimeout=10 -o ConnectionAttempts=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "
BUILD_KEY="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"
SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "


#If "finished" is set to 1, then we know that a webserver has been successfully built and is running.
#Try up to 5 times if the webserver is failing to complete its build
while ( [ "${finished}" != "1" ] && [ "${counter}" -lt "5" ] )
do
	counter="`/usr/bin/expr ${counter} + 1`"
	webserver_no="${1}"
	
	status "OK... Building webserver ${webserver_no}. This is the ${counter} attempt of 5"
	WEBSITE_IDENTIFIER="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`"


	#Check if there is a webserver already running. If there is, then skip building the webserver
	if ( [ "${webserver_no}" -le "${NO_WEBSERVERS}" ] )
	then
		ip=""
		#Construct a unique name for this webserver
		RND="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1`"
		webserver_name="ws-${REGION}-${BUILD_IDENTIFIER}-1-${RND}-init-${webserver_no}"

		status "Initialising a new server machine, please wait......"

		server_started="0"
		while ( [ "${server_started}" = "0" ] )
		do
			count="0"
			#Actually start the server machine. Following this, there will be an active machine instance running on your cloud provider
			${BUILD_HOME}/providerscripts/server/CreateServer.sh "${WS_SERVER_TYPE}" "${webserver_name}" 

			if ( [ "$?" != "0" ] )
			then
				status "Could not create webmaster machine"
				/bin/touch /tmp/END_IT_ALL
			fi

			status "Interrogating for webserver instance being available....if this goes on forever there is a problem"
			count="0"
			while ( [ "`${BUILD_HOME}/providerscripts/server/IsInstanceRunning.sh "${webserver_name}" ${CLOUDHOST}`" != "running" ] && [ "${count}" -lt "120" ] )
			do
				/bin/sleep 1
				count="`/usr/bin/expr ${count} + 1`"
			done

			if ( [ "${count}" = "120" ] )
			then
				status "Machine ${webserver_name} didn't provision correctly"
				/bin/touch /tmp/END_IT_ALL
			fi

			status "Webserver type VPS instance is now available"

			#Check that the server has been assigned its IP addresses and that they are active
			ip=""
			private_ip=""
			count="0"

			status "Interrogating for webserver ip address....."

			#Keep trying until we get the ip addresses of our new machine, both public and private ips
			while ( ( [ "${ip}" = "" ] || [ "${private_ip}" = "" ] ) || [ "${ip}" = "0.0.0.0" ] && [ "${count}" -lt "10" ] )
			do
				ip="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "${webserver_name}" ${CLOUDHOST} | /bin/grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`"
				private_ip="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "${webserver_name}" ${CLOUDHOST} | /bin/grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`"
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

		WSIP_PUBLIC=${ip}
		WSIP_PRIVATE=${private_ip}

	#	if ( [ "${MULTI_REGION}" = "1" ] )
#		then
#			${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${WSIP_PUBLIC} multiregionwebserverpublicips/${public_ip} "no"
#		fi

		#Store our IP addresses in the S3 datastore
		if ( [ "${webserver_no}" = "1" ] )
		then
			if ( [ "`${BUILD_HOME}/providerscripts/datastore/operations/ListFromDatastore.sh "config" "webserverpublicips/*"`" != "" ] )
			then
				${BUILD_HOME}/providerscripts/datastore/operations/DeleteFromDatastore.sh "config" "webserverpublicips/*"
			fi
			if ( [ "`${BUILD_HOME}/providerscripts/datastore/operations/ListFromDatastore.sh "config" "webserverips/*"`" != "" ] )
			then
				${BUILD_HOME}/providerscripts/datastore/operations/DeleteFromDatastore.sh "config" "webserverips/*"
			fi
		fi
		${BUILD_HOME}/providerscripts/datastore/operations/PutToDatastore.sh "config" "${ip}" "webserverpublicips" "local" "no"
		${BUILD_HOME}/providerscripts/datastore/operations/PutToDatastore.sh "config" "${private_ip}" "webserverips" "local" "no"

		#If the build machine is attached to the VPC we want the private IP address if not we want the public one 

		if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
		then
			ws_active_ip="${WSIP_PRIVATE}"
		elif ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
		then
			ws_active_ip="${WSIP_PUBLIC}"
		fi

		status "Have got the ip addresses for your webserver (${webserver_name})"
		status "Public IP address: ${WSIP_PUBLIC}"
		status "Private IP address: ${WSIP_PRIVATE}"

		if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys ] )
		then
			/bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys
		fi

		# When the call "CreateServer.sh" was made above a cloud-init (userdata) script was used to build out the machine
		# This script takes a certain amount of time to run, so, what I do here is just check for a completion flag which 
		# When present we can be fairly sure that the newly provisioned machine has completed its webserver machine type
		# build process. We check very frequently so there is no wasted time and up to 300 times which means we are willing to 
		# wait for up to ten minutes (which should be more than enough) for the cloud-init script to complete

		status "Waiting for the webserver machine ${webserver_name} to complete its build. If you are waiting on this for more than 10 minutes, something is likely wrong"
		status "This is the current time for your reference `/bin/date`"

		#So, looking good. Now what we have to do is keep monitoring for the build process for our webserver to complete
		finished="0"
		alive="" 
		count="0"

		probe_attempts="600"

		if ( [ "`/bin/grep "^${WEBSERVER_CHOICE}:source" ${BUILD_HOME}/builddescriptors/buildstyles.dat`" != "" ] && [ "${BUILD_FROM_SNAPSHOT}" != "1" ] )
		then
			status "${webserver_name} is compiling from source, it may take a bit longer"
			probe_attempts="`/usr/bin/expr ${probe_attempts} + 150`"
			if ( [ "${MOD_SECURITY}" = "1" ] )
			then
				probe_attempts="`/usr/bin/expr ${probe_attempts} + 300`"
			fi
		fi

		while ( [ "${alive}" != "WEBSERVER_READY" ] && [ "${count}" -lt "${probe_attempts}" ] )
		do
			count="`/usr/bin/expr ${count} + 1`"
			/bin/sleep 2
			alive="`/usr/bin/ssh -q -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${ws_active_ip} "/usr/bin/test -f /home/${SERVER_USER}/runtime/WEBSERVER_READY && /bin/echo 'WEBSERVER_READY'"`"
		done

		if ( [ "${count}" = "${probe_attempts}" ] )
		then
			#If we are here then the build didn't succeed
			finished="0"
		else
			#If we are here then the build did succeed and we can add the IP address to the DNS system
			if ( [ "${NO_REVERSE_PROXY}" = "0" ] )
			then
				if ( [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DNS_PRIMED ] )
				then
					/bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DNS_PRIMED
					${BUILD_HOME}/initscripts/InitialiseDNSRecord.sh ${ip} "primary"
				else
					${BUILD_HOME}/initscripts/InitialiseDNSRecord.sh ${ip} "secondary"	
				fi
			fi
			finished="1"
		fi

		#If $done != 1, then the webserver didn't build properly, so, destroy the machine
		if ( [ "${finished}" != "1" ] )
		then
			status "################################################################################################################"
			status "Hi, a webserver didn't seem to build correctly. I can destroy it and I can try to build a new webserver for you"
			status "################################################################################################################"
			status "Press the <enter> key to be continue with the next attempt <ctrl - c> to exit"

			if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
			then
				read response
			fi

			#We don't want the IP addresses of a failed build in our S3 datastore
			${BUILD_HOME}/providerscripts/datastore/operations/DeleteFromDatastore.sh "config" "webserverpublicips" "root" "local"
			${BUILD_HOME}/providerscripts/datastore/operations/DeleteFromDatastore.sh "config" "webserverips" "root" "local"
			${BUILD_HOME}/providerscripts/server/DestroyServer.sh ${WSIP_PUBLIC} ${CLOUDHOST}

			#Wait until we are sure that the webserver is destroyed because of a faulty build
			while ( [ "`${BUILD_HOME}/providerscripts/server/NumberOfServers.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} 2>/dev/null`" != "0" ] )
			do
				/bin/sleep 30
			done
		else
			#Happy days if we are here. we believe a build has been successful
			status "A webserver (${webserver_name}) has built correctly (`/usr/bin/date`) and is accepting connections"
			counter="`/usr/bin/expr ${counter} - 1`"
		fi
	else
		#Am appropriate webserver seems to be already running for this reason
		status "Configured to use ${NO_WEBSERVERS} webservers and found ${webserver_no} running whilst trying to build more"
		status "The webserver you are asking me to build looks like it's excess to the configured requirements"
		status "Will not be creating webserver"
		/bin/touch /tmp/END_IT_ALL
		finished="1"
	fi
done

#If we get to here then we know that the webserver didn't build properly after several attempts, so report it and exit
if ( [ "${counter}" = "5" ] )
then
	status "The infrastructure failed to intialise because of a build problem, plese investigate, correct and rebuild"
	/bin/touch /tmp/END_IT_ALL
fi
