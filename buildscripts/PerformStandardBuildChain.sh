#!/bin/sh
####################################################################################
# Author : Peter Winter
# Date   : 13/07/2016
# Description : This will perform a standard build chain (autoscaler/webserver/database)
# You can configure other build chains with alternative workflows to (for example) include
# caching server and so on. 
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
####################################################################################
####################################################################################
#set -x

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
PRODUCTION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRODUCTION`"
DEVELOPMENT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DEVELOPMENT`"
BASELINE_DB_REPOSITORY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BASELINE_DB_REPOSITORY`"
NO_AUTOSCALERS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NO_AUTOSCALERS`"
NO_WEBSERVERS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NO_WEBSERVERS`"
IN_PARALLEL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh IN_PARALLEL`"
BUILD_ARCHIVE_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_ARCHIVE_CHOICE`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"
BYPASS_DB_LAYER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BYPASS_DB_LAYER`"
MULTI_REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh MULTI_REGION`"
PRIMARY_REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRIMARY_REGION`"
AUTHENTICATION_SERVER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTHENTICATION_SERVER`"
NO_REVERSE_PROXY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NO_REVERSE_PROXY`"
SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"

pids=""

#If PRODUCTION=1 then we  need to work out how many autoscalers we want to deploy if we don't already know
if ( [ "${PRODUCTION}" = "1" ] && [ "${DEVELOPMENT}" = "0" ] && [ "${BASELINE_DB_REPOSITORY}" != "VIRGIN" ] )
then
	if ( [ "${NO_AUTOSCALERS}" = "" ] )
	then
		status "How many autoscalers do you want to deploy?"

		if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
		then
			read NO_AUTOSCALERS
		fi 

		while ! ( [ "${NO_AUTOSCALERS}" -eq "${NO_AUTOSCALERS}" ] 2> /dev/null )
		do
			status "Sorry, invalid input, try again"
			if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
			then
				read NO_AUTOSCALERS
			fi
		done
		if ( [ "${NO_AUTOSCALERS}" -lt "1" ] )
		then
			status "Number of autoscalers can't be less than 1 setting autoscalers to 1"
			status "Press <enter> to accept"

			if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
			then
				read x
			fi
			NO_AUTOSCALERS="1"
		elif ( [ "${NO_AUTOSCALERS}" -gt "5" ] )
		then
			status "Number of autoscalers can't be greater than 5 setting autoscalers to 5"
			status "Press <enter> to accept"

			if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
			then
				read x
			fi
			NO_AUTOSCALERS="5"
		else 
			status "Number of autoscalers set to ${NO_AUTOSCALERS}"
			status "Press <enter> to accept"

			if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
			then
				read x
			fi
		fi
	fi
	# If this isn't a parallelised build, then build each machine type sequentially and in turn with no need to wait
	# otherwise if it is a parallelised build type then build all the machine types concurrently and wait for them to build
	if ( [ "${NO_AUTOSCALERS}" -ne "0" ] && [ "${IN_PARALLEL}" = "0" ] )
	then
		tally="0"
		while ( [ "${tally}" -lt "${NO_AUTOSCALERS}" ] )
		do
			tally="`/usr/bin/expr ${tally} + 1`"
			${BUILD_HOME}/buildscripts/BuildAutoscaler.sh ${tally}
		done
	elif ( [ "${NO_AUTOSCALERS}" -ne "0" ] && [ "${IN_PARALLEL}" = "1" ] )
	then
		tally="0"
		while ( [ "${NO_AUTOSCALERS}" -le "5" ] && [ "${tally}" -lt "${NO_AUTOSCALERS}" ] )
		do
			tally="`/usr/bin/expr ${tally} + 1`"
			${BUILD_HOME}/buildscripts/BuildAutoscaler.sh ${tally} &
			pids="${pids} $!"
			/bin/sleep 10
		done
	fi
fi 

if ( [ "${IN_PARALLEL}" = "0" ] && [ "${PRODUCTION}" = "1" ] )
then
	tally="0"
	while ( [ "${NO_WEBSERVERS}" -le "5" ] && [ "${tally}" -lt "${NO_WEBSERVERS}" ] )
	do
		tally="`/usr/bin/expr ${tally} + 1`"
		${BUILD_HOME}/buildscripts/BuildWebserver.sh ${tally} 
		/bin/sleep 10
	done

	if ( [ "${BYPASS_DB_LAYER}" != "2" ] )
	then
		${BUILD_HOME}/buildscripts/BuildDatabase.sh
	fi

	if ( [ "${AUTHENTICATION_SERVER}" = "1" ] )
	then
		if ( [ "${NO_AUTHENTICATORS}" != "0" ] )
		then
			tally="0"
			while ( [ "${tally}" -lt "${NO_AUTHENTICATORS}" ] )
			do
				tally="`/usr/bin/expr ${tally} + 1`"
				${BUILD_HOME}/buildscripts/BuildAuthenticator.sh ${tally}
				/bin/sleep 10
			done
		fi		
	fi
	
	if ( [ "${NO_REVERSE_PROXY}" != "0" ] )
	then
		tally="0"
		while ( [ "${tally}" -lt "${NO_REVERSE_PROXY}" ] )
		do
			tally="`/usr/bin/expr ${tally} + 1`"
			${BUILD_HOME}/buildscripts/BuildReverseProxy.sh ${tally}
		done
	fi
elif ( [ "${IN_PARALLEL}" = "1" ] && [ "${PRODUCTION}" = "1" ] )
then
	tally="0"
	while ( [ "${NO_WEBSERVERS}" -le "5" ] && [ "${tally}" -lt "${NO_WEBSERVERS}" ] )
	do
		tally="`/usr/bin/expr ${tally} + 1`"
		${BUILD_HOME}/buildscripts/BuildWebserver.sh ${tally} &
		pids="${pids} $!"
		/bin/sleep 10
	done

	if ( [ "${BYPASS_DB_LAYER}" != "2" ] )
	then
		${BUILD_HOME}/buildscripts/BuildDatabase.sh &
		pids="${pids} $!"
	fi

	if ( [ "${AUTHENTICATION_SERVER}" = "1" ] )
	then
		if ( [ "${NO_AUTHENTICATORS}" != "0" ] )
		then
			tally="0"
			while ( [ "${tally}" -lt "${NO_AUTHENTICATORS}" ] )
			do
				tally="`/usr/bin/expr ${tally} + 1`"
				${BUILD_HOME}/buildscripts/BuildAuthenticator.sh ${tally} &
				pids="${pids} $!"
				/bin/sleep 10
			done
		fi		
	fi

	if ( [ "${NO_REVERSE_PROXY}" -ne "0" ] )
	then
		tally="0"
		while ( [ "${NO_REVERSE_PROXY}" -le "5" ] && [ "${tally}" -lt "${NO_REVERSE_PROXY}" ] )
		do
			tally="`/usr/bin/expr ${tally} + 1`"
			${BUILD_HOME}/buildscripts/BuildReverseProxy.sh ${tally} &
			pids="${pids} $!"
			/bin/sleep 10
		done
	fi
fi

if ( [ "${IN_PARALLEL}" = "1" ]  && [ "${DEVELOPMENT}" = "1" ] )
then
	tally="0"
	while ( [ "${NO_WEBSERVERS}" -le "5" ] && [ "${tally}" -lt "${NO_WEBSERVERS}" ] )
	do
		tally="`/usr/bin/expr ${tally} + 1`"
		${BUILD_HOME}/buildscripts/BuildWebserver.sh ${tally} &
		pids="${pids} $!"
		/bin/sleep 10
	done

	if ( [ "${BYPASS_DB_LAYER}" != "2" ] )
	then
		${BUILD_HOME}/buildscripts/BuildDatabase.sh &
		pids="${pids} $!"
	fi

	if ( [ "${AUTHENTICATION_SERVER}" = "1" ] )
	then
		if ( [ "${NO_AUTHENTICATORS}" != "0" ] )
		then
			tally="0"
			while ( [ "${tally}" -lt "${NO_AUTHENTICATORS}" ] )
			do
				tally="`/usr/bin/expr ${tally} + 1`"
				${BUILD_HOME}/buildscripts/BuildAuthenticator.sh ${tally} &
				pids="${pids} $!"
				/bin/sleep 10
			done
		fi		
	fi

	if ( [ "${NO_REVERSE_PROXY}" -ne "0" ] )
	then
		tally="0"
		while ( [ "${NO_REVERSE_PROXY}" -le "5" ] && [ "${tally}" -lt "${NO_REVERSE_PROXY}" ] )
		do
			tally="`/usr/bin/expr ${tally} + 1`"
			${BUILD_HOME}/buildscripts/BuildReverseProxy.sh ${tally} &
			pids="${pids} $!"
			/bin/sleep 10
		done
	fi
fi

# $pids will be empty of its not a parallelised build and this will do nothing if it is a parallelised build then wait on each pid
# when all pids wait condition is satisified, the build will proceed. 
for pid in ${pids}
do
	wait ${pid}
done

# And so now we have all the information we need to set the application configuration and store it in the datastore. In particular
# we have the database connection details in all scenarios and so we can set the application's configuration now
if ( [ "${BUILD_ARCHIVE_CHOICE}" != "virgin" ] )
then
	${BUILD_HOME}/application/SetApplicationConfig.sh
fi

# If the build machine is connected to the VPC then we need the private ip addresses of our machines, if not we need the public ones
if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
then
	AUTOSCALER_PUBLIC_KEYS="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/autoscaler_keys"
	if ( [ "${PRODUCTION}" = "1" ] && [ "${NO_AUTOSCALERS}" -gt "1" ] )
	then
		as_active_ips="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "as-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
	elif ( [ "${PRODUCTION}" = "1" ] && [ "${NO_AUTOSCALERS}" -eq "1" ] )
	then
		as_active_ip="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "as-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
	fi
	ws_active_ip="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "ws-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
	db_active_ip="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "db-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
elif ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
then
	if ( [ "${PRODUCTION}" = "1" ] && [ "${NO_AUTOSCALERS}" -gt "1" ] )
	then
		as_active_ips="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "as-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
	elif ( [ "${PRODUCTION}" = "1" ] && [ "${NO_AUTOSCALERS}" -eq "1" ] )
	then
		as_active_ip="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "as-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
	fi
	ws_active_ip="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "ws-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
	db_active_ip="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "db-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
fi

# Simply report that so far, so good
if ( [ "${PRODUCTION}" = "1" ] )
then
	if ( [ "${AUTHENTICATION_SERVER}" = "1" ] )
	then
		status "Authentication server, Autoscaler, Webserver and Database built correctly....."
	elif ( [ "${AUTHENTICATION_SERVER}" = "1" ] && [ "${NO_REVERSE_PROXY}" != "0" ] )
	then
		status "Authentication server, Reverse proxy, Autoscaler, Webserver and Database built correctly....."
	elif ( [ "${NO_REVERSE_PROXY}" != "0" ] )
	then
		status "Reverse Proxy, Autoscaler, Webserver and Database built correctly....."
	fi
elif ( [ "${DEVELOPMENT}" = "1" ] )
then
	status "Webserver and Database built correctly....."
fi

# And adjust the build machine firewall just as a routine process
if ( [ ! -f /root/FIRST_EVER_BUILD ] )
then
	/bin/touch /root/FIRST_EVER_BUILD
	/bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/PRIME_FIREWALL
fi
${BUILD_HOME}/security/firewall/AdjustBuildMachineFirewall.sh

export CLOUDHOST="${cloudhost_holder}"

##Do the build finalisation procedures
${BUILD_HOME}/buildscripts/FinaliseBuildProcessing.sh
