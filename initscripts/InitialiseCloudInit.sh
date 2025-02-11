#!/bin/sh

#set -x

status () {
        /bin/echo "$1" | /usr/bin/tee /dev/fd/3 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
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
TIMEZONE="${TIMEZONE_CONTINENT}/${TIMEZONE_CITY}"
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"

git_provider_domain="`${BUILD_HOME}/providerscripts/git/GitProviderDomain.sh ${INFRASTRUCTURE_REPOSITORY_PROVIDER}`"

/bin/cp /dev/null ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/autoscaler_configuration_settings.dat
/bin/cp /dev/null ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/webserver_configuration_settings.dat
/bin/cp /dev/null ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/database_configuration_settings.dat

set -o allexport
. ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/build_environment
set +o allexport

while read param
do
        param1="`eval /bin/echo ${param}`"
        if ( [ "${param1}" != "" ] )
        then
                /bin/echo ${param1} >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/autoscaler_configuration_settings.dat
        fi
done < ${BUILD_HOME}/builddescriptors/autoscalerscp.dat

autoscaler_configuration_settings="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/autoscaler_configuration_settings.dat | /usr/bin/gzip -f | /usr/bin/base64 | /usr/bin/tr -d '\n'`"

while read param
do
        param1="`eval /bin/echo ${param}`"
        if ( [ "${param1}" != "" ] )
        then
                /bin/echo ${param1} >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/webserver_configuration_settings.dat
        fi
done < ${BUILD_HOME}/builddescriptors/webserverscp.dat

webserver_configuration_settings="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/webserver_configuration_settings.dat | /usr/bin/gzip -f | /usr/bin/base64 | /usr/bin/tr -d '\n'`"

while read param
do
        param1="`eval /bin/echo ${param}`"
        if ( [ "${param1}" != "" ] )
        then
                /bin/echo ${param1} >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/database_configuration_settings.dat
        fi
done < ${BUILD_HOME}/builddescriptors/databasescp.dat

database_configuration_settings="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/database_configuration_settings.dat | /usr/bin/gzip -f | /usr/bin/base64 | /usr/bin/tr -d '\n'`"

build_styles_settings="`/bin/cat ${BUILD_HOME}/builddescriptors/buildstylesscp.dat  | /bin/grep -v "^#" | /usr/bin/gzip -f | /usr/bin/base64 | /usr/bin/tr -d '\n'`"

/bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/${CLOUDHOST}/autoscaler.yaml ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
/bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/${CLOUDHOST}/webserver.yaml ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
/bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/${CLOUDHOST}/database.yaml ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml

APPLICATION_LANGUAGE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_LANGUAGE`"
PHP_VERSION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PHP_VERSION`"

if ( [ "${APPLICATION_LANGUAGE}" = "PHP" ] )
then
        if ( [ "`/bin/grep ^PHP:cloud-init ${BUILD_HOME}/builddescriptors/buildstylesscp.dat`" != "" ] )
        then
                /bin/sed  -i 's/#XXXXPHPXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
                /bin/sed  -i "s/XXXXPHP_VERSIONXXXX/${PHP_VERSION}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
                
                PHP_VERSION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PHP_VERSION`"
                php_modules="`/bin/grep ^PHP ${BUILD_HOME}/builddescriptors/buildstylesscp.dat | /bin/sed 's/^PHP:cloud-init://g' | /usr/bin/awk -F'|' '{print $1}' | /bin/sed 's/:/ /g'`"
                php_module_list=""
                for php_module in ${php_modules}
                do
                        php_modules_list="${php_modules_list} php${PHP_VERSION}-${php_module}"
                done
        fi
fi

WEBSERVER_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSERVER_CHOICE`"

if ( [ "${WEBSERVER_CHOICE}" = "NGINX" ] )
then
        if ( [ "`/bin/grep ^NGINX:cloud-init ${BUILD_HOME}/builddescriptors/buildstylesscp.dat`" != "" ] )
        then
                /bin/sed -i 's/#XXXXNGINXXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
        fi
fi

if ( [ "${WEBSERVER_CHOICE}" = "APACHE" ] )
then
        if ( [ "`/bin/grep ^APACHE:cloud-init ${BUILD_HOME}/builddescriptors/buildstylesscp.dat`" != "" ] )
        then
                /bin/sed -i 's/#XXXXAPACHEXXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
        fi
fi

DATABASE_INSTALLATION_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DATABASE_INSTALLATION_TYPE`"
DATABASE_DBaaS_INSTALLATION_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DATABASE_DBaaS_INSTALLATION_TYPE`"

if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Maria" ] )
then
        if ( [ "`/bin/grep ^MARIADB:cloud-init ${BUILD_HOME}/builddescriptors/buildstylesscp.dat`" != "" ] )
        then
                /bin/sed -i 's/#XXXXMARIADB_CLIENTXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
                /bin/sed -i 's/#XXXXMARIADB_SERVERXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
        fi
fi

if ( [ "${DATABASE_DBaaS_INSTALLATION_TYPE}" = "Maria" ] )
then
        if ( [ "`/bin/grep ^MARIADB:cloud-init ${BUILD_HOME}/builddescriptors/buildstylesscp.dat`" != "" ] )
        then
                /bin/sed -i 's/#XXXXMARIADB_CLIENTXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
                /bin/sed -i 's/#XXXXMARIADB_CLIENTXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
        fi
fi

if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Postgres" ]  )
then
        if ( [ "`/bin/grep ^POSTGRES:cloud-init ${BUILD_HOME}/builddescriptors/buildstylesscp.dat`" != "" ] )
        then
                /bin/sed -i 's/#XXXXPOSTRGESQL_CLIENTXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
                /bin/sed -i 's/#XXXXPOSTRGESQL_SERVERXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
        fi
fi

if ( [ "${DATABASE_DBaaS_INSTALLATION_TYPE}" = "Postgres" ] )
then
        if ( [ "`/bin/grep ^POSTGRES:cloud-init ${BUILD_HOME}/builddescriptors/buildstylesscp.dat`" != "" ] )
        then
                /bin/sed -i 's/#XXXXPOSTGRES_CLIENTXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
                /bin/sed -i 's/#XXXXPOSTGRES_CLIENTXXXX//g' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
        fi
fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then

        /bin/sed -i "s/XXXXPHP_MODULESXXXX/${php_modules_list}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
        /bin/sed -i "s/XXXXSSH_PORTXXXX/${SSH_PORT}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
        /bin/sed -i "s/XXXXSSH_PORTXXXX/${SSH_PORT}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
        /bin/sed -i "s/XXXXSSH_PORTXXXX/${SSH_PORT}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
        /bin/sed -i "s;XXXXTIMEZONEXXXX;${TIMEZONE};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
        /bin/sed -i "s;XXXXTIMEZONEXXXX;${TIMEZONE};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
        /bin/sed -i "s;XXXXTIMEZONEXXXX;${TIMEZONE};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
        /bin/sed -i "s;XXXXBUILDSTYLES_SETTINGSXXXX;${build_styles_settings};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
        /bin/sed -i "s;XXXXBUILDSTYLES_SETTINGSXXXX;${build_styles_settings};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
        /bin/sed -i "s;XXXXBUILDSTYLES_SETTINGSXXXX;${build_styles_settings};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
        /bin/sed -i "s/XXXXSERVER_USERXXXX/${SERVER_USER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
        /bin/sed -i "s/XXXXSERVER_USERXXXX/${SERVER_USER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
        /bin/sed -i "s/XXXXSERVER_USERXXXX/${SERVER_USER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
        /bin/sed -i "s;XXXXSERVER_USER_PASSWORDXXXX;${SERVER_USER_PASSWORD_HASHED};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
        /bin/sed -i "s;XXXXSERVER_USER_PASSWORDXXXX;${SERVER_USER_PASSWORD_HASHED};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
        /bin/sed -i "s;XXXXSERVER_USER_PASSWORDXXXX;${SERVER_USER_PASSWORD_HASHED};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
        /bin/sed -i "s;XXXXSSH_PUBLIC_KEYXXXX;${SSH_PUBLIC_KEY};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
        /bin/sed -i "s;XXXXSSH_PUBLIC_KEYXXXX;${SSH_PUBLIC_KEY};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
        /bin/sed -i "s;XXXXSSH_PUBLIC_KEYXXXX;${SSH_PUBLIC_KEY};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
        /bin/sed -i "s;XXXXSSH_PRIVATE_KEYXXXX;${SSH_PRIVATE_KEY_TRIMMED};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
        /bin/sed -i "s;XXXXSSH_PRIVATE_KEYXXXX;${SSH_PRIVATE_KEY_TRIMMED};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
        /bin/sed -i "s;XXXXSSH_PRIVATE_KEYXXXX;${SSH_PRIVATE_KEY_TRIMMED};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
        /bin/sed -i "s/XXXXGIT_PROVIDER_DOMAINXXXX/${git_provider_domain}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
        /bin/sed -i "s/XXXXGIT_PROVIDER_DOMAINXXXX/${git_provider_domain}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
        /bin/sed -i "s/XXXXGIT_PROVIDER_DOMAINXXXX/${git_provider_domain}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
        /bin/sed -i "s/XXXXINFRASTRUCTURE_REPOSITORY_OWNERXXXX/${INFRASTRUCTURE_REPOSITORY_OWNER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
        /bin/sed -i "s/XXXXINFRASTRUCTURE_REPOSITORY_OWNERXXXX/${INFRASTRUCTURE_REPOSITORY_OWNER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
        /bin/sed -i "s/XXXXINFRASTRUCTURE_REPOSITORY_OWNERXXXX/${INFRASTRUCTURE_REPOSITORY_OWNER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
        /bin/sed -i "s/XXXXBUILD_IDENTIFIERXXXX/${BUILD_IDENTIFIER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
        /bin/sed -i "s/XXXXBUILD_IDENTIFIERXXXX/${BUILD_IDENTIFIER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
        /bin/sed -i "s/XXXXBUILD_IDENTIFIERXXXX/${BUILD_IDENTIFIER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
        /bin/sed -i "s/XXXXALGORITHMXXXX/${ALGORITHM}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
        /bin/sed -i "s/XXXXALGORITHMXXXX/${ALGORITHM}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
        /bin/sed -i "s/XXXXALGORITHMXXXX/${ALGORITHM}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
        /bin/sed -i "s;XXXXAUTOSCALER_CONFIGURATIONXXXX;${autoscaler_configuration_settings};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
        /bin/sed -i "s;XXXXWEBSERVER_CONFIGURATIONXXXX;${webserver_configuration_settings};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
        /bin/sed -i "s;XXXXWEBSERVER_CONFIGURATIONXXXX;${webserver_configuration_settings};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
        /bin/sed -i "s;XXXXDATABASE_CONFIGURATIONXXXX;${database_configuration_settings};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml

        autoscaler_cloud_init_status="`/usr/bin/cloud-init schema --config-file ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml`"

        status "${autoscaler_cloud_init_status}"
        if ( [ "`/bin/echo ${autoscaler_cloud_init_status} | /bin/grep 'Invalid'`" != "" ] )
        then
                status "Invalid autoscaler cloud-init configuration found. I have to exit"
                exit
        fi     
        webserver_cloud_init_status="`/usr/bin/cloud-init schema --config-file ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml`"
        status "${webserver_cloud_init_status}"
        if ( [ "`/bin/echo ${webserver_cloud_init_status} | /bin/grep 'Invalid'`" != "" ] )
        then
                status "Invalid webserver cloud-init configuration found. I have to exit"
                exit
        fi   
        database_cloud_init_status="`/usr/bin/cloud-init schema --config-file ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml`"
        status "${database_cloud_init_status}"
        if ( [ "`/bin/echo ${database_cloud_init_status} | /bin/grep 'Invalid'`" != "" ] )
        then
                status "Invalid database cloud-init configuration found. I have to exit"
                exit
        fi   
fi
