#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This will configure cloud-init scripts for each webserver machine type that
# you want to build. The result of this script is a valid cloud-init script with 
# live data ready to be passed to a VPS instance when it is provisioned using 
# a CLI call
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

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILDOS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
ALGORITHM="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ALGORITHM`"
SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"
SERVER_USER_PASSWORD_HASHED="`/usr/bin/mkpasswd -m sha512crypt ${SERVER_USER_PASSWORD}`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh INFRASTRUCTURE_REPOSITORY_OWNER`"
INFRASTRUCTURE_REPOSITORY_PROVIDER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh INFRASTRUCTURE_REPOSITORY_PROVIDER`"
SSH_PUBLIC_KEY="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub`"
SSH_PRIVATE_KEY_TRIMMED="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} | /bin/grep -v '^----' | /usr/bin/tr -d '\n'`"
TIMEZONE_CONTINENT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SERVER_TIMEZONE_CONTINENT`"
TIMEZONE_CITY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SERVER_TIMEZONE_CITY`"
BUILD_FROM_SNAPSHOT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_FROM_SNAPSHOT`"
TIMEZONE="${TIMEZONE_CONTINENT}/${TIMEZONE_CITY}"
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"

#if ( [ -f ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat ] )
#then
#	SNAPSHOT_ID="`/bin/grep webserver ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat | /usr/bin/awk -F':' '{print $NF}'`"
#fi

git_provider_domain="`${BUILD_HOME}/providerscripts/git/GitProviderDomain.sh ${INFRASTRUCTURE_REPOSITORY_PROVIDER}`"

/bin/cp /dev/null ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/webserver_configuration_settings.dat

# source in the environment from the filesystem
set -o allexport
. ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/build_environment 2>/dev/null
set +o allexport

while read param
do
	param1="`eval /bin/echo ${param}`"
	if ( [ "${param1}" != "" ] )
	then
		/bin/echo ${param1} >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/webserver_configuration_settings.dat
	fi
done < ${BUILD_HOME}/builddescriptors/webserver_descriptor.dat

webserver_configuration_settings="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/webserver_configuration_settings.dat | /usr/bin/gzip -f | /usr/bin/base64 | /usr/bin/tr -d '\n'`"

# get the build style settings zipped up and base64 encoded so that it takes up less space in the cloud-init script which is size limited
build_styles_settings="`/bin/cat ${BUILD_HOME}/builddescriptors/buildstyles.dat  | /bin/grep -v "^#" | /usr/bin/gzip -f | /usr/bin/base64 | /usr/bin/tr -d '\n'`"

from_snapshot=""
if ( [ "${BUILD_FROM_SNAPSHOT}" = "1" ] )
then
	from_snapshot="-by-snapshot"
fi

# take the packaged cloud-init scripts and make them live ready
/bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/${CLOUDHOST}/webserver${from_snapshot}.yaml ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml

#Configure the cloud-init script for the relevant application language
APPLICATION_LANGUAGE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_LANGUAGE`"
PHP_VERSION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PHP_VERSION`"

if ( [ "${APPLICATION_LANGUAGE}" = "PHP" ] )
then
	if ( [ "`/bin/grep ^PHP:cloud-init ${BUILD_HOME}/builddescriptors/buildstyles.dat`" != "" ] )
	then
		if ( [ "${BUILDOS}" = "ubuntu" ] )
		then
			/bin/sed  -i 's/#XXXXPHPUBUNTUXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
		elif ( [ "${BUILDOS}" = "debian" ] )
		then
			/bin/sed  -i 's/#XXXXPHPDEBIANXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
		fi

		/bin/sed  -i "s/XXXXPHP_VERSIONXXXX/${PHP_VERSION}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml


		php_modules="`/bin/grep ^PHP ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/sed 's/^PHP:cloud-init://g' | /usr/bin/awk -F'|' '{print $1}' | /bin/sed 's/:/ /g'`"
		php_module_list=""
		for php_module in ${php_modules}
		do
			php_modules_list="${php_modules_list} php${PHP_VERSION}-${php_module}"
		done
	fi
fi

#the way this works is that installation method for each webserver type is commented out with a placeholder token
#to enable the installastion of the webserver type that you are installing the blocking placeholder is commented out/removed
WEBSERVER_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSERVER_CHOICE`"

if ( [ "${WEBSERVER_CHOICE}" = "NGINX" ] )
then
	if ( [ "`/bin/grep ^NGINX:cloud-init ${BUILD_HOME}/builddescriptors/buildstyles.dat`" != "" ] )
	then
		/bin/sed -i 's/#XXXXNGINXXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
	fi
fi

if ( [ "${WEBSERVER_CHOICE}" = "APACHE" ] )
then
	if ( [ "`/bin/grep ^APACHE:cloud-init ${BUILD_HOME}/builddescriptors/buildstyles.dat`" != "" ] )
	then
		/bin/sed -i 's/#XXXXAPACHEXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
	fi
fi

if ( [ "${WEBSERVER_CHOICE}" = "LIGHTTPD" ] )
then
	if ( [ "`/bin/grep ^LIGHTTPD:cloud-init ${BUILD_HOME}/builddescriptors/buildstyles.dat`" != "" ] )
	then
		/bin/sed -i 's/#XXXXLIGHTTPDXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
	fi
fi

#The same technique is used for database installations as is used for webserver installations
DATABASE_INSTALLATION_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DATABASE_INSTALLATION_TYPE`"
DATABASE_DBaaS_INSTALLATION_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DATABASE_DBaaS_INSTALLATION_TYPE`"

if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Maria" ] )
then
	if ( [ "`/bin/grep ^MARIADB:cloud-init ${BUILD_HOME}/builddescriptors/buildstyles.dat`" != "" ] )
	then
		/bin/sed -i 's/#XXXXMARIADB_CLIENTXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
	fi
fi

if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep 'MySQL'`" != "" ] )
then
	if ( [ "`/bin/grep ^MARIADB:cloud-init ${BUILD_HOME}/builddescriptors/buildstyles.dat`" != "" ] )
	then
		/bin/sed -i 's/#XXXXMARIADB_CLIENTXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
	else
		/bin/sed -i 's/#XXXXMYSQL_CLIENTXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
	fi
fi

if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Postgres" ]  )
then
	if ( [ "`/bin/grep ^POSTGRES:cloud-init ${BUILD_HOME}/builddescriptors/buildstyles.dat`" != "" ] )
	then
		/bin/sed -i 's/#XXXXPOSTRGESQL_CLIENTXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
	fi
fi

if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep 'Postgres'`" != "" ] )
then
	if ( [ "`/bin/grep ^POSTGRES:cloud-init ${BUILD_HOME}/builddescriptors/buildstyles.dat`" != "" ] )
	then
		/bin/sed -i 's/#XXXXPOSTGRES_CLIENTXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
	fi
fi

#Use our source environment to configure each cloud-init script with "live" data
/bin/sed -i "s/XXXXPHP_MODULESXXXX/${php_modules_list}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
/bin/sed -i "s/XXXXSSH_PORTXXXX/${SSH_PORT}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
/bin/sed -i "s;XXXXTIMEZONEXXXX;${TIMEZONE};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
/bin/sed -i "s;XXXXBUILDSTYLES_SETTINGSXXXX;${build_styles_settings};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
/bin/sed -i "s/XXXXSERVER_USERXXXX/${SERVER_USER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
/bin/sed -i "s;XXXXSERVER_USER_PASSWORDXXXX;${SERVER_USER_PASSWORD_HASHED};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
/bin/sed -i "s;XXXXSSH_PUBLIC_KEYXXXX;${SSH_PUBLIC_KEY};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
/bin/sed -i "s;XXXXSSH_PRIVATE_KEYXXXX;${SSH_PRIVATE_KEY_TRIMMED};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
/bin/sed -i "s/XXXXGIT_PROVIDER_DOMAINXXXX/${git_provider_domain}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
/bin/sed -i "s/XXXXINFRASTRUCTURE_REPOSITORY_OWNERXXXX/${INFRASTRUCTURE_REPOSITORY_OWNER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
/bin/sed -i "s/XXXXBUILD_IDENTIFIERXXXX/${BUILD_IDENTIFIER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
/bin/sed -i "s/XXXXALGORITHMXXXX/${ALGORITHM}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
/bin/sed -i "s;XXXXWEBSERVER_CONFIGURATIONXXXX;${webserver_configuration_settings};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml


# Our cloud-init scripts should be ready, just give then a quick validate and tell the user if there are any issues
status ""
status "Validating webserver cloud-init script"
    
webserver_cloud_init_status="`/usr/bin/cloud-init schema --config-file ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml`"
status "${webserver_cloud_init_status}"
if ( [ "`/bin/echo ${webserver_cloud_init_status} | /bin/grep 'Invalid'`" != "" ] )
then
	status "Invalid webserver cloud-init configuration found. I have to exit"
	/bin/touch /tmp/END_IT_ALL
fi   

