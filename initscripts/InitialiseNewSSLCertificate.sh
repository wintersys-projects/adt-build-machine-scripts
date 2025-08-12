#!/bin/sh
###################################################################################
# Author: Peter Winter
# Date  : 12/07/2016
# Description : This script will generate an SSL Certificate if one is needed
# A new SSL certificate in two cases, a SSL certificate does not already exist
# or the SSL certificate that does exists is considered close to expiring
###################################################################################
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
##################################################################################
##################################################################################
#set -x

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

website_url="${1}"
auth="${2}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
SSL_GENERATION_METHOD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSL_GENERATION_METHOD`"
SSL_GENERATION_SERVICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSL_GENERATION_SERVICE`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
DNS_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_CHOICE`"

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

generate_new="0"

ssl_bucket="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`"
ssl_bucket="${ssl_bucket}-${DNS_CHOICE}-ssl"

${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh ${ssl_bucket}

if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${ssl_bucket}/fullchain.pem`" != "" ] && [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${ssl_bucket}/privkey.pem`" != "" ] )
then
	if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL} ] )
	then
		/bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}
	fi
	status "Found existing SSL certificates in the datastore for website url ${WEBSITE_URL} trying to use those to save time and reissuance"
	${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${ssl_bucket}/fullchain.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}
	${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${ssl_bucket}/privkey.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}
	if ( [ "`/usr/bin/openssl x509 -checkend 604800 -noout -in ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem | /bin/grep 'Certificate will expire'`" != "" ] )
	then
		${BUILD_HOME}/providerscripts/datastore/DeleteFromDatastore.sh ${ssl_bucket}/privkey.pem
		${BUILD_HOME}/providerscripts/datastore/DeleteFromDatastore.sh ${ssl_bucket}/fullchain.pem                
		generate_new="1"
	fi
fi

if ( [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem ] || [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem ] )
then
	generate_new="1"
fi

if ( [ "${generate_new}" = "1" ] || [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem ] || [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem ] )
then
	#IP has been added to the DNS provider and now we have to set up the SSL certificate for this webserver

	if ( [ "${SSL_GENERATION_METHOD}" = "AUTOMATIC" ] )
	then
		if ( [ "${SSL_GENERATION_SERVICE}" = "LETSENCRYPT" ] )
		then
  			if ( [ "`/bin/grep "^SSLCERTCLIENT:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep lego`" != "" ] )
			then
   				${BUILD_HOME}/providerscripts/security/ssl/lego/ProvisionAndArrangeSSLCertificate.sh ${WEBSITE_URL}
			elif ( [ "`/bin/grep "^SSLCERTCLIENT:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep acme`" != "" ] )
   			then
	     		${BUILD_HOME}/providerscripts/security/ssl/acme/ProvisionAndArrangeSSLCertificate.sh ${WEBSITE_URL}
   			fi
  		fi
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
fi

if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem ] )
then
	if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem.verify ] )
	then
		/bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem.verify 
	fi

	if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem.verify ] )
	then
		/bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem.verify 
	fi

	${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem ssl/${WEBSITE_URL}/privkey.pem
	${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem ssl/${WEBSITE_URL}/fullchain.pem
	${BUILD_HOME}/providerscripts/datastore/configwrapper/GetFromConfigDatastore.sh ssl/${WEBSITE_URL}/privkey.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem.verify 
	${BUILD_HOME}/providerscripts/datastore/configwrapper/GetFromConfigDatastore.sh ssl/${WEBSITE_URL}/fullchain.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem.verify 

	if ( [ "`/usr/bin/diff ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem.verify ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem`" != "" ] )
	then
		status "SSL Certificate Verification failed for ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem"
		/bin/touch /tmp/END_IT_ALL

	fi

	if ( [ "`/usr/bin/diff ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem.verify ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem`" != "" ] )
	then
		status "SSL Certificate Verification failed for ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem"
		/bin/touch /tmp/END_IT_ALL
	fi

	/bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem.verify 
	/bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem.verify 

	status "SSL Certificates successfully validated"

	${BUILD_HOME}/providerscripts/datastore/DeleteFromDatastore.sh ${ssl_bucket}/fullchain.pem
	${BUILD_HOME}/providerscripts/datastore/DeleteFromDatastore.sh ${ssl_bucket}/privkey.pem
	${BUILD_HOME}/providerscripts/datastore/PutToDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem ${ssl_bucket}/fullchain.pem
	${BUILD_HOME}/providerscripts/datastore/PutToDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem ${ssl_bucket}/privkey.pem

fi
