#!/bin/sh
###################################################################################
# Description : This will validate our template against the quick spec definitions.
# These are just rudimentary checks and it can't be 100% guaranteed that there is nothing
# misconfigured in the template if these checks pass, but, we can be more confident that
# the template is correctly configured. 
# Author: Peter Winter
# Date  : 13/07/2020
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
####################################################################################
####################################################################################
#set -x

status () {
	status_set="1"
	yellow="`/usr/bin/tput setaf 11`"
	norm="`/usr/bin/tput sgr0`"
	/bin/echo "${yellow} ${1} ${norm}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
	/bin/echo ""
}

status1 () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

status2 () {
	cyan="`/usr/bin/tput setaf 6`"
	norm="`/usr/bin/tput sgr0`"
	/bin/echo "${cyan} ${1} ${norm}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

echo () {
	status_set="1"
	yellow="`/usr/bin/tput setaf 11`"
	norm="`/usr/bin/tput sgr0`"
	/bin/echo "${yellow} ${1} ${norm}" 
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
quick_specification="${BUILD_HOME}/templatedconfigurations/quick_specification.dat"
status_set="0"

if ( [ "${1}" != "" ] )
then
	templatefile="${1}"
	. ${templatefile} 2>/dev/null
fi

status1 2>/dev/null

if ( [ "$?" = "0" ] )
then
	log_command="status "
	log_command1="status1 "
else
	/bin/echo ""
	log_command="echo "
	log_command1="/bin/echo "
fi

log_command2="status2 "

${log_command1} ""
/usr/bin/banner "ATTENTION"
${log_command1} ""

${log_command1} "######################################################################################################################################################################"
${log_command1} "If you see any warning messages below its because I believe that you might want to double check some values in  your template in some way before you make a deployment"
${log_command1} "You may get some soft warnings if you check them out and find them to be soft you can safely continue whilst ignoring them"
${log_command1} "Your currently active template is :${templatefile})"
${log_command1} "######################################################################################################################################################################"

${log_command1} ""

${log_command1} "####################TEMPLATE VALIDATION REPORT BEGINNING####################"

if ( [ "`/bin/grep "^BUILDOS " ${quick_specification} | /bin/grep -w "${BUILDOS}"`" = "" 2>/dev/null ] )
then
	${log_command} "Your value for the variable BUILDOS (${BUILDOS}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^BUILDOS_VERSION " ${quick_specification} | /bin/grep -w "${BUILDOS_VERSION}" 2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable BUILDOS_VERSION (${BUILDOS_VERSION}) doesn't appear to be valid please review"
else
	if ( [ "${BUILDOS_VERSION}" != "24.04" ] && [ "${BUILDOS}" = "ubuntu" ] )
	then
		${log_command} "Your value for the variable BUILDOS_VERSION (${BUILDOS_VERSION}) doesn't appear to be valid please review"
	elif ( ( [ "${BUILDOS_VERSION}" != "12" ] && [ "${BUILDOS_VERSION}" != "13" ] ) && [ "${BUILDOS}" = "debian" ] )
	then
		${log_command} "Your value for the variable BUILDOS_VERSION (${BUILDOS_VERSION}) doesn't appear to be valid please review"
	fi
fi

if ( [ "`/bin/grep "^APPLICATION " ${quick_specification} | /bin/grep -w "${APPLICATION}" 2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable APPLICATION (${APPLICATION}) doesn't appear to be valid please review"
fi

for host_base in `/bin/echo ${S3_HOST_BASE} | /bin/sed 's/:/ /g'`
do
	datastore_choice="`/bin/echo ${DATASTORE_CHOICE} | /usr/bin/tr '[:lower:]' '[:upper:]'`"
	if ( [ "`/bin/grep "^S3_HOST_BASE " ${quick_specification} | /bin/grep -w "${host_base}" 2>/dev/null `" = "" ] )
	then
		if ( [ "`/bin/grep "^S3_HOST_BASE " ${quick_specification} | /bin/grep -w "${host_base}" | /bin/grep ${datastore_choice}`" = "" ] )
		then
			${log_command} "Your value for the variable S3_HOST_BASE (${host_base}) doesn't appear to be valid please review"
		fi
	fi
done

S3_ACCESS_KEY="`${HOME}/utilities/config/ExtractConfigValue.sh 'S3ACCESSKEY'`"
no_tokens1="`/bin/echo "${S3_ACCESS_KEY}" | /usr/bin/fgrep -o '|' | /usr/bin/wc -l`"
no_tokens1="`/usr/bin/expr ${no_tokens} + 1`"

S3_SECRET_KEY="`${HOME}/utilities/config/ExtractConfigValue.sh 'S3ACCESSKEY'`"
no_tokens2="`/bin/echo "${S3_SECRET_KEY}" | /usr/bin/fgrep -o '|' | /usr/bin/wc -l`"
no_tokens2="`/usr/bin/expr ${no_tokens} + 1`"

S3_LOCATION="`${HOME}/utilities/config/ExtractConfigValue.sh 'S3ACCESSKEY'`"
no_tokens3="`/bin/echo "${S3_LOCATION}" | /usr/bin/fgrep -o '|' | /usr/bin/wc -l`"
no_tokens3="`/usr/bin/expr ${no_tokens} + 1`"

S3_HOST_BASE="`${HOME}/utilities/config/ExtractConfigValue.sh 'S3HOSTBASE'`"
no_tokens4="`/bin/echo "${S3_HOST_BASE}" | /usr/bin/fgrep -o '|' | /usr/bin/wc -l`"
no_tokens4="`/usr/bin/expr ${no_tokens} + 1`"

if ( [ "${no_tokens1}" != "${no_tokens2}" ] || [ "${no_tokens2}" != "${no_tokens3}" ] || [ "${no_tokens3}" != "${no_tokens4}" ] )
then
	${log_command} "There seems to be an inconsistent number of values for your datastore parameters"
	${log_command} "S3_ACCESS_KEY ( ${no_tokens1} values configured ) S3_SECRET_KEY ( ${no_tokens2} values configured )"
	${log_command} "S3_LOCATION ( ${no_tokens3} values configured )  S3_HOST_BASE ( ${no_tokens4} values configured )"
fi

if ( [ "`/bin/grep "^S3_LOCATION " ${quick_specification} | /bin/grep -w "${S3_LOCATION}" 2>/dev/null `" = "" ] )
then
	datastore_choice="`/bin/echo ${DATASTORE_CHOICE} | /usr/bin/tr '[:lower:]' '[:upper:]'`"
	if ( [ "`/bin/grep "^S3_LOCATION " ${quick_specification} | /bin/grep -w "${S3_LOCATION}" | /bin/grep ${datastore_choice}  2>/dev/null `" = "" ] )
	then
		${log_command} "Your value for the variable S3_LOCATION (${S3_LOCATION}) doesn't appear to be valid please review"
	fi
fi

if ( [ "`/bin/grep "^EMAIL_NOTIFICATION_LEVEL " ${quick_specification} | /bin/grep -w "${EMAIL_NOTIFICATION_LEVEL}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable EMAIL_NOTIFICATION_LEVEL (${EMAIL_NOTIFICATION_LEVEL}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^DNS_CHOICE " ${quick_specification} | /bin/grep -w "${DNS_CHOICE}" 2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable DNS_CHOICE (${DNS_CHOICE}) doesn't appear to be valid please review"
fi

if ( [ "${BUILD_FROM_SNAPSHOT}" = "1" ] && ( [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] || [ "${BUILD_ARCHIVE_CHOICE}" = "baseline" ] ) )
then
	${log_command} "Your BUILD_ARCHIVE_CHOICE Is set to ${BUILD_ARCHIVE_CHOICE} and that can't be when you are deploying from snapshots"
	${log_command} "You have to deploy from a temporal backup if you are building your servers based on snapshots"
fi

if ( [ "`/bin/grep "^APPLICATION_REPOSITORY_PROVIDER " ${quick_specification} | /bin/grep -w "${APPLICATION_REPOSITORY_PROVIDER}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable APPLICATION_REPOSITORY_PROVIDER (${APPLICATION_REPOSITORY_PROVIDER}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^BUILD_MACHINE_VPC " ${quick_specification} | /bin/grep -w "${BUILD_MACHINE_VPC}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable BUILD_MACHINE_VPC (${BUILD_MACHINE_VPC}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^SYSTEM_EMAIL_PROVIDER " ${quick_specification} | /bin/grep -w "${SYSTEM_EMAIL_PROVIDER}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable SYSTEM_EMAIL_PROVIDER (${SYSTEM_EMAIL_PROVIDER}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^PRODUCTION " ${quick_specification} | /bin/grep -w "${PRODUCTION}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable PRODUCTION (${PRODUCTION}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^DEVELOPMENT " ${quick_specification} | /bin/grep -w "${DEVELOPMENT}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable DEVELOPMENT (${DEVELOPMENT}) doesn't appear to be valid please review"
fi

if ( [ "${PRODUCTION}" = "1" ] && [ "${DEVELOPMENT}" != "0" ] || [ "${PRODUCTION}" = "0" ] && [ "${DEVELOPMENT}" != "1" ]  )
then
	${log_command} "It looks like your values for PRODUCTION ( ${PRODUCTION}) and DEVELOPMENT (${DEVELOPMENT}) are inconsistent"
fi

if ( [ "`/bin/grep "^AUTHENTICATION_SERVER " ${quick_specification} | /bin/grep -w "${AUTHENTICATION_SERVER}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable AUTHENTICATION_SERVER (${AUTHENTICATION_SERVER}) doesn't appear to be valid please review"
fi

if ( [ "${AUTHENTICATION_SERVER}" = "1" ] && ( [ "${SYSTEM_EMAIL_PROVIDER}" = "" ] || [ "${SYSTEM_TOEMAIL_ADDRESS}" = "" ] || [ "${SYSTEM_FROMEMAIL_ADDRESS}" = "" ] || [ "${SYSTEM_EMAIL_USERNAME}" = "" ] || [ "${SYSTEM_EMAIL_PASSWORD}" = "" ] ) )
then
	${log_command} "You are deploying an authentication server and so SMTP must be fully setup and it looks like it isn't"
fi

if ( [ "${AUTHENTICATION_SERVER}" = "1" ] && ( [ "${AUTH_SERVER_URL}" = "" ] || [ "${AUTH_DNS_USERNAME}" = "" ] || [ "${AUTH_DNS_SECURITY_KEY}" = "" ] || [ "${USER_EMAIL_DOMAIN}" = "" ] ) )
then
	${log_command} "You are deploying an authentication server and it looks like its DNS system might not be set up"
fi


if ( [ "${AUTHENTICATION_SERVER}" = "1" ] && [ "`/bin/grep "^AUTH_DNS_CHOICE " ${quick_specification} | /bin/grep -w "${AUTH_DNS_CHOICE}" 2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable AUTH_DNS_CHOICE (${AUTH_DNS_CHOICE}) doesn't appear to be valid please review"
fi

if ( [ "${AUTHENTICATION_SERVER}" = "1" ] && [ "${DNS_CHOICE}" = "cloudflare" ] )
then
	${log_command} "You are deploying an authentication server and it looks like your main DNS provider is set to cloudflare which it shouldn't be"
fi

if ( [ "${DNS_CHOICE}" = "cloudflare" ] && [ "`/bin/echo ${DNS_SECURITY_KEY} | /bin/grep ':::'`" = "" ] )
then
	${log_command} "Your value for DNS_SECURITY_KEY seems to be malformed"
fi

if ( [ "`/bin/grep "^WEBSERVER_CHOICE " ${quick_specification} | /bin/grep -w "${WEBSERVER_CHOICE}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable WEBSERVER_CHOICE (${WEBSERVER_CHOICE}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^REVERSE_PROXY_WEBSERVER " ${quick_specification} | /bin/grep -w "${REVERSE_PROXY_WEBSERVER}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable REVERSE_PROXY_WEBSERVER (${REVERSE_PROXY_WEBSERVER}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^DATABASE_INSTALLATION_TYPE " ${quick_specification} | /bin/grep -w "${DATABASE_INSTALLATION_TYPE}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable DATABASE_INSTALLATION_TYPE (${DATABASE_INSTALLATION_TYPE}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^PERSIST_ASSETS_TO_DATASTORE " ${quick_specification} | /bin/grep -w "${PERSIST_ASSETS_TO_DATASTORE}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable PERSIST_ASSETS_TO_DATASTORE (${PERSIST_ASSETS_TO_DATASTORE}) doesn't appear to be valid please review"
fi

existing_build_identifiers="`/bin/ls ${BUILD_HOME}/runtimedata/${CLOUDHOST}`"

if ( [ "`/bin/echo ${existing_build_identifiers} | /bin/grep -w "${BUILD_IDENTIFIER}"`" = "" ] && [ "`/bin/echo ${existing_build_identifiers} | /bin/grep -Eo "${BUILD_IDENTIFIER}"`" != "" ] )
then
	${log_command} "Your BUILD_IDENTIFIER {${BUILD_IDENTIFIER}) seems to be a substring of an existing BUILD_IDENTIFIER this is NOT recommended"
	${log_command} "For example, if you have BUILD_IDENTIFIERis such as '1test' or 'test2' then 'test' is not a valid BUILD_IDENTIFIER"
fi

build_identifier_length="`/bin/echo "${BUILD_IDENTIFIER}" | /bin/grep "^[a-zA-Z0-9-]*$" | /bin/grep -v "\-$" | /usr/bin/wc -c`"

if ( [ "${build_identifier_length}" = "0" ] )
then
	${log_command} "it looks like your build identifier (${BUILD_IDENTIFIER}) is not valid"
fi

if ( [ "${build_identifier_length}" -gt "12" ] )
then
	${log_command} "it looks like your build identifier (${BUILD_IDENTIFIER}) is more than 12 characters"
fi

if ( [ "${VPC_IP_RANGE}" = "" ] )
then
	${log_command} "Your value for the variable VPC_IP_RANGE seems not to be set this is a MANDATORY SETTING"
fi

if ( [ "`/bin/grep "^BUILD_ARCHIVE_CHOICE " ${quick_specification} | /bin/grep -w "${BUILD_ARCHIVE_CHOICE}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable BUILD_ARCHIVE_CHOICE (${BUILD_ARCHIVE_CHOICE}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^APPLICATION_LANGUAGE " ${quick_specification} | /bin/grep -w "${APPLICATION_LANGUAGE}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable APPLICATION_LANGUAGE (${APPLICATION_LANGUAGE}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^INPARALLEL " ${quick_specification} | /bin/grep -w "${INPARALLEL}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable INPARALLEL (${INPARALLEL}) doesn't appear to be valid please review"
	export INPARALLEL="0"
fi

if ( ! [ `/usr/bin/expr match "${MAX_WEBSERVERS}" '^\([0-9]\+\)$'` ] )
then
	${log_command} "Your value for the variable MAX_WEBSERVERS (${MAX_WEBSERVERS}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^SYNC_WEBROOTS " ${quick_specification} | /bin/grep -w "${SYNC_WEBROOTS}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable SYNC_WEBROOTS (${SYNC_WEBROOTS}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^NO_AUTOSCALERS " ${quick_specification} | /bin/grep -w "${NO_AUTOSCALERS}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable NO_AUTOSCALERS (${NO_AUTOSCALERS}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^NO_WEBSERVERS " ${quick_specification} | /bin/grep -w "${NO_WEBSERVERS}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable NO_WEBSERVERS (${NO_WEBSERVERS}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^NO_REVERSE_PROXY " ${quick_specification} | /bin/grep -w "${NO_REVERSE_PROXY}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable NO_REVERSE_PROXY (${NO_REVERSE_PROXY}) doesn't appear to be valid please review"
fi

if ( [ "${NO_REVERSE_PROXY}" != "0" ] && [ "`/bin/grep "^REVERSE_PROXY_CHOICE " ${quick_specification} | /bin/grep -w "${REVERSE_PROXY_WEBSERVER}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your webserver choice ${REVERSE_PROXY_WEBSERVER}  can't be used as a reverse proxy"
fi

if ( [ "${NO_REVERSE_PROXY}" != "0" ] && [ "${WEBSERVER_CHOICE}" = "NGINX" ] && [ "`/bin/grep "^NGINX:source" ${BUILD_HOME}/builddescriptors/buildstyles.dat`" = "" ] )
then
	if ( [ "${MOD_SECURITY}" = "1" ] )
	then
		${log_command} "To use NGINX as a reverse proxy with modsecurity enabled NGINX needs to be compiled from source which you can configure in ${BUILD_HOME}/builddescriptors/buildstyles.dat"
	fi
fi

if ( [ "${DEVELOPMENT}" = "1" ] && [ "${DEVELOPMENT}" = "1" ] && [ "${NO_AUTOSCALERS}" != "0" ] )
then
	${log_command} "You are in development mode, NO_AUTOSCALERS should be 0 not  (${NO_AUTOSCALERS}) and so doesn't appear to be valid please review"
  	${BUILD_HOME}/helperscripts/SetVariableValue.sh "NO_AUTOSCALERS=0"
fi

if ( [ "${PRODUCTION}" = "1" ] && [ "${DEVELOPMENT}" = "1" ] && [ "${NO_AUTOSCALERS}" = "0" ] )
then
	${log_command} "You are in production mode, NO_AUTOSCALERS should not be 0 and so doesn't appear to be valid please review"
fi

if ( [ "${PRODUCTION}" = "0" ] && [ "${DEVELOPMENT}" = "1" ] && [ "${NO_WEBSERVERS}" != "1" ] )
then
	${log_command} "In development mode, the number of webservers has to be 1"
  	${BUILD_HOME}/helperscripts/SetVariableValue.sh "NO_WEBSERVERS=1"
fi

if ( [ "`/bin/grep "^PHP_VERSION " ${quick_specification} | /bin/grep -w "${PHP_VERSION}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable PHP_VERSION (${PHP_VERSION}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^REGION " ${quick_specification} | /bin/grep -w "${REGION}"  2>/dev/null `" = "" ] )
then
	cloudhost="`/bin/echo ${CLOUDHOST} | /usr/bin/tr '[:lower:]' '[:upper:]'`"
	#this is only set for the exoscale host
	if ( [ "${cloudhost}" = "exoscale" ] )
	then
		if ( [ "`/bin/grep "^REGION " ${quick_specification} | /bin/grep -w "${REGION}" | /bin/grep ${cloudhost} 2>/dev/null `" = "" ] )
		then
			${log_command} "Your value for the variable REGION (${REGION}) doesn't appear to be valid please review"
		fi
	fi
fi

if ( [ "${MULTI_REGION}" = "0" ] || ( [ "${MULTI_REGION}" = "1" ] && [ "${PRIMARY_REGION}" = "1" ] ) )
then
	if ( [ "${CLOUDHOST}" = "digitalocean" ] && [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] && [ "${DB_PORT}" != "25060" ] )
	then
		${log_command} "Your value for the variable DB_PORT is ${DB_PORT} and it can only be '25060' in this configuration"
	fi
fi

if ( [ "`/bin/grep "^DB_SERVER_TYPE " ${quick_specification} | /bin/grep -w "${DB_SERVER_TYPE}"  2>/dev/null `" = "" ] )
then
	cloudhost="`/bin/echo ${CLOUDHOST} | /usr/bin/tr '[:lower:]' '[:upper:]'`"
	if ( [ "`/bin/grep "^DB_SERVER_TYPE " ${quick_specification} | /bin/grep -w "${DB_SERVER_TYPE}" | /bin/grep ${cloudhost} 2>/dev/null `" = "" ] )
	then
		${log_command} "Your value for the variable DB_SERVER_TYPE (${DB_SERVER_TYPE}) doesn't appear to be valid please review"
	fi
fi

if ( [ "`/bin/grep "^AS_SERVER_TYPE " ${quick_specification} | /bin/grep -w "${AS_SERVER_TYPE}"  2>/dev/null `" = "" ] )
then
	cloudhost="`/bin/echo ${CLOUDHOST} | /usr/bin/tr '[:lower:]' '[:upper:]'`"
	if ( [ "`/bin/grep "^AS_SERVER_TYPE " ${quick_specification} | /bin/grep -w "${AS_SERVER_TYPE}" | /bin/grep ${cloudhost} 2>/dev/null `" = "" ] )
	then
		${log_command} "Your value for the variable AS_SERVER_TYPE (${AS_SERVER_TYPE}) doesn't appear to be valid please review"
	fi
fi

if ( [ "`/bin/grep "^WS_SERVER_TYPE " ${quick_specification} | /bin/grep -w "${WS_SERVER_TYPE}"  2>/dev/null `" = "" ] )
then
	cloudhost="`/bin/echo ${CLOUDHOST} | /usr/bin/tr '[:lower:]' '[:upper:]'`"
	if ( [ "`/bin/grep "^WS_SERVER_TYPE " ${quick_specification} | /bin/grep -w "${WS_SERVER_TYPE}" | /bin/grep ${cloudhost} 2>/dev/null `" = "" ] )
	then
		${log_command} "Your value for the variable WS_SERVER_TYPE (${WS_SERVER_TYPE}) doesn't appear to be valid please review"
	fi
fi

if ( [ "`/bin/grep "^MACHINE_TYPE " ${quick_specification} | /bin/grep -w "${MACHINE_TYPE}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable MACHINE_TYPE (${MACHINE_TYPE}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^ALGORITHM " ${quick_specification} | /bin/grep -w "${ALGORITHM}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable ALGORITHM (${ALGORITHM}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^INFRASTRUCTURE_REPOSITORY_PROVIDER " ${quick_specification} | /bin/grep -w "${INFRASTRUCTURE_REPOSITORY_PROVIDER}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable INFRASTRUCTURE_REPOSITORY_PROVIDER (${INFRASTRUCTURE_REPOSITORY_PROVIDER}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^BYPASS_DB_LAYER " ${quick_specification} | /bin/grep -w "${BYPASS_DB_LAYER}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable BYPASS_DB_LAYER (${BYPASS_DB_LAYER}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^SSL_GENERATION_METHOD " ${quick_specification} | /bin/grep -w "${SSL_GENERATION_METHOD}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable SSL_GENERATION_METHOD (${SSL_GENERATION_METHOD}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^SSL_GENERATION_SERVICE " ${quick_specification} | /bin/grep -w "${SSL_GENERATION_SERVICE}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable SSL_GENERATION)_SERVICE (${SSL_GENERATION_SERVICE}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^SSL_LIVE_CERT " ${quick_specification} | /bin/grep -w "${SSL_LIVE_CERT}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable SSL_LIVE_CERT (${SSL_LIVE_CERT}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^SSLCERTCLIENT:lego" ${BUILD_HOME}/builddescriptors/buildstyles.dat`" != "" ] && [ "${SSL_GENERATION_SERVICE}" != "LETSENCRYPT" ] )
then
	${log_command} "There seems to be a mismatch between your SSL CLIENT software choice in ${BUILD_HOME}/builddescriptors/buildstyles.dat"
 	${log_command} "and your chosen ssl generation service (${SSL_GENERATION_SERVICE})"
  	${log_command} "The 'lego' SSL CLIENT can only be used with the LETSENCRYPT certificate service"
fi

if ( [ "`/bin/grep "^SSLCERTCLIENT:acme" ${BUILD_HOME}/builddescriptors/buildstyles.dat`" != "" ] && [ "${SSL_GENERATION_SERVICE}" != "ZEROSSL" ] )
then
	${log_command} "There seems to be a mismatch between your SSL CLIENT software choice in ${BUILD_HOME}/builddescriptors/buildstyles.dat"
 	${log_command} "and your chosen ssl generation service (${SSL_GENERATION_SERVICE})"
  	${log_command} "The 'acme' SSL CLIENT can only be used with the ZEROSSL certificate service"
fi

if ( [ "`/bin/grep "^ACTIVE_FIREWALLS " ${quick_specification} | /bin/grep -w "${ACTIVE_FIREWALLS}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable ACTIVE_FIREWALLS (${ACTIVE_FIREWALLS}) doesn't appear to be valid please review"
fi

if ( [ "${APPLICATION}" = "joomla" ] && [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] )
then
	joomla_version="`/bin/echo ${JOOMLA_VERSION} | /bin/sed 's/\./-/g'`"
	joomla_major_version="`/bin/echo ${joomla_version} | /usr/bin/awk -F'-' '{print $1}'`"

	if ! /usr/bin/curl --head --silent --fail https://downloads.joomla.org/cms/joomla${joomla_major_version}/${joomla_version}/Joomla_${joomla_version}-Stable-Full_Package.zip 1>&2 >/dev/null 
	then
		${log_command} "I don't seem to be able to find a download link for the joomla version you are wanting to install (${JOOMLA_VERSION})"
	fi
	if ( [ "${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}" != "JOOMLA:${JOOMLA_VERSION}" ] )
	then
		${log_command} "Your value for variable APPLICATION_BASELINE_SOURCECODE_REPOSITORY (${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}) doesn't appear to be valid please review"
	fi
fi

if ( [ "${APPLICATION}" = "drupal" ] && [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] )
then
	if ! /usr/bin/curl --head --silent --fail https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz 1>&2 >/dev/null
	then
		if ( [ "${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}" != "DRUPAL:social" ] && [ "${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}" != "DRUPAL:cms" ] )
		then
			${log_command} "I don't seem to be able to find a download link for the drupal version you are wanting to install (${DRUPAL_VERSION})"
		fi
	fi
	if ( [ "${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}" != "DRUPAL:${DRUPAL_VERSION}" ] && [ "${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}" != "DRUPAL:social" ] && [ "${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}" != "DRUPAL:cms" ] )
	then
		${log_command} "Your value for variable APPLICATION_BASELINE_SOURCECODE_REPOSITORY (${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}) doesn't appear to be valid please review"
	fi
fi

if ( [ "${APPLICATION}" = "moodle" ] && [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] )
then
	if ( [ "${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}" != "MOODLE" ] )
	then
		${log_command} "Your value for variable APPLICATION_BASELINE_SOURCECODE_REPOSITORY (${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}) doesn't appear to be valid please review"
	fi
fi

if ( [ "${APPLICATION}" = "joomla" ] )
then
	if ( [ "`/bin/echo "8.1 8.2 8.3 8.4" | /bin/grep "${PHP_VERSION}"`" = "" ] )
	then
		${log_command} "I am suspicious that the version of PHP you are installing isn't compatible with joomla"
	fi
fi

if ( [ "${APPLICATION}" = "wordpress" ] )
then
	if ( [ "`/bin/echo "8.1 8.2 8.3 8.4" | /bin/grep "${PHP_VERSION}"`" = "" ] )
	then
		${log_command} "I am suspicious that the version of PHP you are installing isn't compatible with wordpress"
	fi
fi

if ( [ "${APPLICATION}" = "drupal" ] )
then
	if ( [ "`/bin/echo "8.1 8.2 8.3 8.4" | /bin/grep "${PHP_VERSION}"`" = "" ] )
	then
		${log_command} "I am suspicious that the version of PHP you are installing isn't compatible with drupal"
	fi
fi

if ( [ "${APPLICATION}" = "moodle" ] )
then
	if ( [ "`/bin/echo "8.1 8.2 8.3 8.4" | /bin/grep "${PHP_VERSION}"`" = "" ] )
	then
		${log_command} "I am suspicious that the version of PHP you are installing isn't compatible with moodle"
	fi
fi

php_version="`/bin/echo ${PHP_VERSION} | /bin/sed 's/\.//g'`"
if ( [ "${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}" = "DRUPAL:cms" ] && [ "${php_version}" -lt "82" ] )
then
	${log_command} "At the time of development, Drupal CMS requires PHP 8.2 or higher. You are trying to install PHP version ${PHP_VERSION}"
fi

if ( [ "${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}" = "DRUPAL:cms" ] && [ "${php_version}" -lt "81" ] )
then
	${log_command} "At the time of development, Drupal Opensocial requires PHP 8.1 or higher. You are trying to install PHP version ${PHP_VERSION}"
fi

if ( [ "`/bin/echo "${DNS_USERNAME}" | /bin/grep '^[a-zA-Z0-9]*@[a-zA-Z0-9]*\.[a-zA-Z0-9]*$'`" = "" ] && [ "`/bin/echo "${DNS_USERNAME}" | /bin/grep '^[a-zA-Z0-9]*@[a-zA-Z0-9]*\.[a-zA-Z0-9]*\.[a-zA-Z0-9]*$'`" = "" ] )
then
	${log_command} "It looks to me like the email address for the variable DNS_USERNAME (${DNS_USERNAME}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/echo "${SYSTEM_TOEMAIL_ADDRESS}" | /bin/grep '^[a-zA-Z0-9]*@[a-zA-Z0-9]*\.[a-zA-Z0-9]*$'`" = "" ] && [ "`/bin/echo "${SYSTEM_TOEMAIL_ADDRESS}" | /bin/grep '^[a-zA-Z0-9]*@[a-zA-Z0-9]*\.[a-zA-Z0-9]*\.[a-zA-Z0-9]*$'`" = "" ] )
then
	${log_command} "It looks to me like the email address for the variable SYSTEM_TOEMAIL_ADDRESS (${SYSTEM_TOEMAIL_ADDRESS}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/echo "${SYSTEM_FROMEMAIL_ADDRESS}" | /bin/grep '^[a-zA-Z0-9]*@[a-zA-Z0-9]*\.[a-zA-Z0-9]*$'`" = "" ] && [ "`/bin/echo "${SYSTEM_FROMEMAIL_ADDRESS}" | /bin/grep '^[a-zA-Z0-9]*@[a-zA-Z0-9]*\.[a-zA-Z0-9]*\.[a-zA-Z0-9]*$'`" = "" ] )
then
	${log_command} "It looks to me like the email address for the variable SYSTEM_FROMEMAIL_ADDRESS (${SYSTEM_FROMEMAIL_ADDRESS}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/echo "${GIT_EMAIL_ADDRESS}" | /bin/grep '^[a-zA-Z0-9]*@[a-zA-Z0-9]*\.[a-zA-Z0-9]*$'`" = "" ] && [ "`/bin/echo "${GIT_EMAIL_ADDRESS}" | /bin/grep '^[a-zA-Z0-9]*@[a-zA-Z0-9]*\.[a-zA-Z0-9]*\.[a-zA-Z0-9]*$'`" = "" ] )
then
	${log_command} "It looks to me like the email address for the variable GIT_EMAIL_USERNAME (${GIT_EMAIL_ADDRESS}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/echo ${WEBSITE_URL} | /bin/grep -P '(?=^.{5,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)'`" = "" ] )
then
	${log_command} "It looks to me like the value for the variable WEBSITE_URL ${WEBSITE_URL}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{print $2}'`" != "${WEBSITE_NAME}" ] )
then
	${log_command} "It looks to me like the value for the variable WEBSITE_NAME (${WEBSITE_NAME}) doesn't appear to be valid please review"
fi

continents="`cd /usr/share/zoneinfo && /usr/bin/find * -type f -or -type l | /usr/bin/sort | /usr/bin/awk -F'/' '{print $1}' | /usr/bin/uniq | /bin/sed ':a;N;$!ba;s/\n/ /g'`"

if ( [ "`/bin/echo ${continents} | /bin/grep "${SERVER_TIMEZONE_CONTINENT}"`" = "" ] )
then
	${log_command} "It looks like your variable SERVER_TIMEZONE_CONTINENT ${SERVER_TIMEZONE_CONTINENT}) doesn't appear to be valid please review"
fi

cities="`cd /usr/share/zoneinfo/${SERVER_TIMEZONE_CONTINENT} && /usr/bin/find * -type f -or -type l | /usr/bin/sort`" 

if ( [ "`/bin/echo ${cities} | /bin/grep "${SERVER_TIMEZONE_CITY}"`" = "" ] )
then
	${log_command} "It looks like your variable SERVER_TIMEZONE_CITY (${SERVER_TIMEZONE_CITY}) doesn't appear to be valid please review"
fi

if ( [ "${BUILD_ARCHIVE_CHOICE}" = "baseline" ] )
then
	if ( [ "`${BUILD_HOME}/providerscripts/git/GitLSRemote.sh ${APPLICATION_REPOSITORY_PROVIDER} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_REPOSITORY_OWNER} ${BASELINE_DB_REPOSITORY} ${APPLICATION_REPOSITORY_TOKEN}`" = "" ] )
	then
		${log_command} "I believe that the repository you have set for variable BASELINE_DB_REPOSITORY (${BASELINE_DB_REPOSITORY}) doesn't appear to be valid please review"
	fi
	if ( [ "`${BUILD_HOME}/providerscripts/git/GitLSRemote.sh ${APPLICATION_REPOSITORY_PROVIDER} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_REPOSITORY_OWNER} ${APPLICATION_BASELINE_SOURCECODE_REPOSITORY} ${APPLICATION_REPOSITORY_TOKEND}`" = "" ] )
	then
		${log_command} "I believe that the repository you have set for variable APPLICATION_BASELINE_SOURCECODE_REPOSITORY (${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}) doesn't appear to be valid please review"
	fi
fi

if ( ( [ "${CLOUDHOST}" = "linode" ] || [ "${CLOUDHOST}" = "exoscale" ] ) && [ "${CLOUDHOST_ACCOUNT_ID}" = "" ] )
then
	${log_command} "It looks like CLOUDHOST_ACCOUNT_ID is blank this should definitely not be the case for ${CLOUDHOST}"
fi

if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Postgres" ] && [ "`/bin/grep ^PHP ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep pgsql`" = "" ] )
then
	${log_command} "It looks like you are trying to install Postgres without PHP support for postgres (pgsql)"
fi

if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Maria" ] && [ "`/bin/grep ^PHP ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep mysqli`" = "" ] )
then
	${log_command} "It looks like you are trying to install MariaDB without PHP support for mysql (mysqli)"
fi

if ( [ "${DATABASE_INSTALLATION_TYPE}" = "MySQL" ] && [ "`/bin/grep ^PHP ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep mysqli`" = "" ] )
then
	${log_command} "It looks like you are trying to install MySQL without PHP support for mysql (mysqli)"
fi

if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep MySQL`" != "" ] && [ "`/bin/grep ^PHP ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep mysqli`" = "" ] )
then
	${log_command} "It looks like you are trying to install MySQL without PHP support for mysql (mysqli)"
fi

if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep Postgres`" != "" ] && [ "`/bin/grep ^PHP ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep pgsql`" = "" ] )
then
	${log_command} "It looks like you are trying to install Postgres without PHP support for postgres (pgsql)"
fi

if ( [ "`/bin/grep "^MULTI_REGION " ${quick_specification} | /bin/grep -w "${MULTI_REGION}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable MULTI_REGION (${MULTI_REGION}) doesn't appear to be valid please review"
fi

if ( [ "`/bin/grep "^PRIMARY_REGION " ${quick_specification} | /bin/grep -w "${PRIMARY_REGION}"  2>/dev/null `" = "" ] )
then
	${log_command} "Your value for the variable PRIMARY_REGION (${PRIMARY_REGION}) doesn't appear to be valid please review"
fi

if ( [ "${MULTI_REGION}" = "1" ] && [ "${NO_REVERSE_PROXY}" = "0" ] )
then
	${log_command} "You are set to deploy to multiple regions which means that you have to use reverse proxy machines"
	${log_command} "Currently your number of reverse proxy machines is set to zero"
fi

if ( [ "${MULTI_REGION}" = "1" ] && [ "${PRIMARY_REGION}" = "0" ] && [ "${DBaaS_PUBLIC_ENDPOINT}" = "" ] )
then
	${log_command} "You are configured for multi region deployment and this is not the primary region"
	${log_command} "When this is the case you have to have a DBaaS public endpoint set"
	${log_command} "Currenlty your DBaaS_PUBLIC_ENDPOINT is set to ''"
fi

if ( [ "${MULTI_REGION}" = "1" ] && [ "${DATABASE_INSTALLATION_TYPE}" != "DBaaS" ] )
then
	${log_command} "You are making a multi region deployment and your database installation type is not DBaaS"
	${log_command} "This is not allowed, please correct"
fi

if ( [ "${ACTIVE_FIREWALLS}" = "0" ] || [ "${ACTIVE_FIREWALLS}" = "1" ] )
then
	${log_command} "It is highly advised that you have a native firewall active because you may experience connection issues to your webproperty across the Internet otherwise"
	${log_command} "Currently, your value for ACTIVE_FIREWALLS is set to ${ACTIVE_FIREWALLS}"
	${log_command} "It needs to be set to 2 or 3"
fi

if ( [ "${MULTI_REGION}" = "1" ] && [ "${BUILD_FROM_SNAPSHOT}" = "1" ] )
then
	${log_command} "Please be aware that you are in multi-region mode and you are also building from snapshots this could complicate things"
	${log_command} "And is therefore not recommended. Rather, it is preferred to just perform regular builds when in multi-region mode"
	${log_command} "That said, if you are adventurous you could give it a go"
fi

if ( [ "${MULTI_REGION}" = "1" ] && ( [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] || [ "${BUILD_ARCHIVE_CHOICE}" = "baseline" ] ) )
then
	${log_command} "Your BUILD_ARCHIVE_CHOICE Is set to ${BUILD_ARCHIVE_CHOICE} and that can't be when you are deploying for multiple regions"
	${log_command} "You have to deploy from a temporal backup if you are building your servers for multiple regions"
fi

if ( [ "${BYPASS_DB_LAYER}" = "0" ] && [ "${MULTI_REGION}" = "1" ] && [ "${PRIMARY_REGION}" = "0" ] )
then
	${log_command} "Your BYPASS_DB_LAYER setting is set to 0 you probably want it to be set to 1 or 2 when you are in multi region mode and not a primary region"
fi

if ( [ "${MULTI_REGION}" = "1" ] && [ "${PRIMARY_REGION}" = "0" ] && [ "${DBaaS_PUBLIC_ENDPOINT}" = "" ] )
then
	${log_command} "When mutli region is active and primary region is not, DBaaS_PUBLIC_ENDPOINT must be set, and, right now, it isn't"
fi

if ( [ "${status_set}" = "0" ] )
then
	${log_command2} "YOUR TEMPLATE LOOKS TO BE FULLY VALIDATED"
fi

${log_command1} ""
${log_command1} "####################TEMPLATE VALIDATION REPORT ENDING####################"

${log_command1} "Press <enter> when you have reviewed and accepted any messages that have appeared above (if there are none then you are all set already and just press enter)"

if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
then
	read x
fi
