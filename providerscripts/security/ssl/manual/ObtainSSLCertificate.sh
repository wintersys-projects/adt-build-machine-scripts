#!/bin/sh
#####################################################################################
# Description: This is a script will allow you to manually enter an ssl certificate
# This will not work in hardcore mode you will have to be doing an expedited build
#####################################################################################
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

status () {
        /bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
        /bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

website_url="${1}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIERS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
BUILDOS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS`"
DNS_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_CHOICE`"
SSL_LIVE_CERT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSL_LIVE_CERT`"
DNS_USERNAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_USERNAME`"
DNS_SECURITY_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_SECURITY_KEY`"
SSL_GENERATION_METHOD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSL_GENERATION_METHOD`"
SSL_GENERATION_SERVICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSL_GENERATION_SERVICE`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"
SUDO="/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

if ( [ "${website_url}" != "" ] )
then
        WEBSITE_URL="${website_url}"
else
        WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
fi

if ( [ "${SSL_GENERATION_METHOD}" = "MANUAL" ] )
then
	response="INPUTNEW"

	if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem ] )
	then
		status "There is a certificate I can use. Do you want me to use that?, or are you going to give me a new one?"
		status "Found a certificate for this domain. For your info, this is its expiry date"
		/usr/bin/openssl x509 -in ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem -noout -enddate
		status "Please enter Y to use the existing one. Anything else to input a new one"
		if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
		then
			read response
		fi
	fi
	
 	if ( ( [ "${response}" != "Y" ] && [ "${response}" != "y" ] ) || [ "${response}" = "INPUTNEW" ] )
	then
		if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL} ] )
		then
			/bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}
		fi

		status "You have selected the manual method of generating an SSL certificate. This presumes that you have the necessary SSL files from a 3rd party"
		status "Certificate provider. So, here I will have to ask you to input the certificates so that I can pass them over to your servers"
		status "So, mate, please paste your certificate chain here. <ctrl d> when done"
		status "ESSENTIAL - Only copy from the first dash in the file '-' to the last dash in the file. Do not copy any prefixed whitespace or suffixed whitespace"

		fullchain=`cat`
		/bin/echo "${fullchain}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem
		/bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem

		status "Cheers. So, mate, please paste your certifcate key here. <ctrl d> when done"
		status "ESSENTIAL - Only copy from the first dash in the file '-' to the last dash in the file. Do not copy any prefixed whitespace or suffixed whitespace"

		privkey=`cat`
		/bin/echo "${privkey}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem
		/bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem
	fi
fi
 
