#!/bin/sh
########################################################################################
# Author: Peter Winter
# Date  : 12/07/2016
# Description: If you are deploying a DBaaS system, this will tighten the firewalling system
# so that the databases are only accessible by ip addresses that we are using. 
# This is applied towards the end of the build process
# It depends on whether the DBaaS service is run in the same VPC as our server machines.
# If it is then access is available through the VPC if it isn't then individual IP addresses
# have to be granted access. That is why you see some providers with processing needed here
# when the DBaaS isn't running in the same VPC as the servers are. 
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

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
MULTI_REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh MULTI_REGION`"
PRIMARY_REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRIMARY_REGION`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
DATABASE_INSTALLATION_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DATABASE_INSTALLATION_TYPE`"
DATABASE_DBaaS_INSTALLATION_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DATABASE_DBaaS_INSTALLATION_TYPE`"
DB_NAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DB_NAME`"

if ( [ "${MULTI_REGION}" = "0" ] || ( [ "${MULTI_REGION}" = "1" ] && [ "${PRIMARY_REGION}" = "1" ] ) )
then
	webserver_ip="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "ws-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
	database_ip="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "db-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"

	if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep DBAAS`" != "" ] )
	then    
		database_details="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/sed 's/^.*DBAAS://g'`"
		database_region="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $2}'`"
	fi


	if ( [ "${CLOUDHOST}" = "digitalocean" ] && [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
	then
		:
		#Because the DBaaS setup is in the same VPC as your machines we don't need to tighten its firewall because its only accessible from within the VPC
	fi


	if ( [ "${CLOUDHOST}" = "exoscale" ] && [ "${DATABASE_INSTALLATION_TYPE}"="DBaaS" ] )
	then
		#The DBaaS solution from exoscale is not accessible from the private network ip address range so we have to allow the public IP addresses individually

		ips="${webserver_ip},${database_ip}"
		database_type="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $1}'`"

		if ( [ "${database_type}" = "Postgres" ] )
		then
			status "Tightening the firewall on your postgres database for your webserver with following IPs: ${ips}"    
			/usr/bin/exo dbaas update --zone ${database-region} ${DB_NAME} --pg-ip-filter=${ips}
		elif ( [ "${database_type}" = "MySQL" ] )
		then
			status "Tightening the firewall on your mysql database for your webserver with following IPs: ${ips}"    
			/usr/bin/exo dbaas update --zone ${database_region} ${DB_NAME} --mysql-ip-filter=${ips}
		fi
	fi

	if ( [ "${CLOUDHOST}" = "linode" ] && [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
	then
		#The DBaaS solution from linode is not accessible from the vpc ip address range so we have to allow the public IP addresses individually

		allow_list=" --allow_list ${webserver_ip}/32 --allow_list ${database_ip}/32"
		database_type="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $1}'`"
		label="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $7}'`"

		if ( [ "${database_type}" = "MySQL" ] )
		then
			database_id="`/usr/local/bin/linode-cli --json databases mysql-list | jq -r '.[] | select(.label | contains ("'${label}'")) | .id'`"
			/usr/local/bin/linode-cli databases mysql-update ${database_id} ${allow_list}
		elif ( [ "${database_type}" = "Postgres" ] )
		then
			database_id="`/usr/local/bin/linode-cli --json databases postgresql-list | /usr/bin/jq '.[] | select(.label | contains ("'${label}'")) | .id'`"
			/usr/local/bin/linode-cli databases mysql-update ${database_id} ${allow_list}
		fi
	fi

	if ( [ "${CLOUDHOST}" = "vultr" ] && [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
	then
		:
		#Because the DBaaS setup is in the same VPC as your machines we don't need to tighten its firewall because its only accessible from within the VPC
	fi

fi



