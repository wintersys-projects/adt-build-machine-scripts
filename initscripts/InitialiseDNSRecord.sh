#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This will create the DNS record for your current domain and is called
# at the end of building a webserver. Once this is called a webserver will have been
# added to the DNS system
##################################################################################
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

ip="${1}" #the IP address of the webserver
record="${2}"
website_url="${3}" #The URL of the website
auth="${4}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
DNS_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_CHOICE`"
DNS_USERNAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_USERNAME`"
DNS_SECURITY_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_SECURITY_KEY`"
DNS_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_CHOICE`"
MULTI_REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh MULTI_REGION`"
PRIMARY_REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRIMARY_REGION`"

if ( [ "${website_url}" != "" ] )
then
	WEBSITE_URL="${website_url}"
else
	WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
fi


if ( [ "${auth}" = "yes" ] )
then
	WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTH_SERVER_URL`"
	DNS_USERNAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTH_DNS_USERNAME`"
	DNS_SECURITY_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTH_DNS_SECURITY_KEY`"
	DNS_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTH_DNS_CHOICE`"
fi

SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"

if ( [ "${DNS_CHOICE}" != "NONE" ] )
then
	#If we get to here then we know that the webserver was built correctly
	#We have to configure it some more and add it to the DNS provider's DNS so we can access the webserver
	#Please note, we make use of the implicit DNS roundrobin loadbalancing system with our webservers
	name="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{print $1}'`"

	#Create  zone if it doesn't already exist
	zonename="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
	zoneid="`${BUILD_HOME}/providerscripts/dns/GetZoneID.sh "${zonename}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"`"

	if ( [ "${zoneid}" = "" ] )
	then
		${BUILD_HOME}/providerscripts/dns/CreateZone.sh "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${WEBSITE_URL}" "${DNS_CHOICE}"
	fi

	status "We are adding our DNS records to the DNS provider you selected, in this case ${DNS_CHOICE}"
	zoneid="`${BUILD_HOME}/providerscripts/dns/GetZoneID.sh "${zonename}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"`"

	if ( [ "${DNS_CHOICE}" = "cloudflare" ] )
	then
		while ( [ "${zoneid}" = "" ] )
		do
			status "Attempting to get zone id for the DNS system (this may take a few retries)....if, after some time, I can't get your zone id check that your nameservers are configured correctly. Please wait...."
			/bin/sleep 30
			zoneid="`${BUILD_HOME}/providerscripts/dns/GetZoneID.sh "${zonename}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"`"
		done
	fi

	if ( [ "${MULTI_REGION}" = "0" ] || ( [ "${MULTI_REGION}" = "1" ] && [ "${PRIMARY_REGION}" = "1" ] ) )
	then 
		recordids="`${BUILD_HOME}/providerscripts/dns/GetAllRecordIDs.sh  "${zoneid}" "${WEBSITE_URL}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"`"


		if ( [ "${record}" = "primary" ] )
		then
			if ( [ "${recordids}" != "" ] )
			then
				for recordid in ${recordids}
				do
					${BUILD_HOME}/providerscripts/dns/DeleteRecord.sh "${zoneid}" "${recordid}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}" "${WEBSITE_URL}"
				done
			fi
		fi
	fi

	${BUILD_HOME}/providerscripts/dns/AddRecord.sh "${zoneid}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${WEBSITE_URL}" "${ip}" "true" "${DNS_CHOICE}"
fi
