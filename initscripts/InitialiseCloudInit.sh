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

if ( [ "${CLOUDHOST}" = "linode" ] )
then
        /bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/linode-autoscaler.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/linode-webserver.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/linode-database.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        /bin/sed -i "s;XXXXBUILDSTYLES_SETTINGSXXXX;${build_styles_settings};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/sed -i "s;XXXXBUILDSTYLES_SETTINGSXXXX;${build_styles_settings};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/sed -i "s;XXXXBUILDSTYLES_SETTINGSXXXX;${build_styles_settings};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        /bin/sed -i "s/XXXXSERVER_USERXXXX/${SERVER_USER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/sed -i "s/XXXXSERVER_USERXXXX/${SERVER_USER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/sed -i "s/XXXXSERVER_USERXXXX/${SERVER_USER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        /bin/sed -i "s;XXXXSERVER_USER_PASSWORDXXXX;${SERVER_USER_PASSWORD_HASHED};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/sed -i "s;XXXXSERVER_USER_PASSWORDXXXX;${SERVER_USER_PASSWORD_HASHED};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/sed -i "s;XXXXSERVER_USER_PASSWORDXXXX;${SERVER_USER_PASSWORD_HASHED};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        /bin/sed -i "s;XXXXSSH_PUBLIC_KEYXXXX;${SSH_PUBLIC_KEY};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/sed -i "s;XXXXSSH_PUBLIC_KEYXXXX;${SSH_PUBLIC_KEY};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/sed -i "s;XXXXSSH_PUBLIC_KEYXXXX;${SSH_PUBLIC_KEY};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        /bin/sed -i "s;XXXXSSH_PRIVATE_KEYXXXX;${SSH_PRIVATE_KEY_TRIMMED};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/sed -i "s;XXXXSSH_PRIVATE_KEYXXXX;${SSH_PRIVATE_KEY_TRIMMED};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/sed -i "s;XXXXSSH_PRIVATE_KEYXXXX;${SSH_PRIVATE_KEY_TRIMMED};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        /bin/sed -i "s/XXXXGIT_PROVIDER_DOMAINXXXX/${git_provider_domain}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/sed -i "s/XXXXGIT_PROVIDER_DOMAINXXXX/${git_provider_domain}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/sed -i "s/XXXXGIT_PROVIDER_DOMAINXXXX/${git_provider_domain}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        /bin/sed -i "s/XXXXINFRASTRUCTURE_REPOSITORY_OWNERXXXX/${INFRASTRUCTURE_REPOSITORY_OWNER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/sed -i "s/XXXXINFRASTRUCTURE_REPOSITORY_OWNERXXXX/${INFRASTRUCTURE_REPOSITORY_OWNER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/sed -i "s/XXXXINFRASTRUCTURE_REPOSITORY_OWNERXXXX/${INFRASTRUCTURE_REPOSITORY_OWNER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        /bin/sed -i "s/XXXXBUILD_IDENTIFIERXXXX/${BUILD_IDENTIFIER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/sed -i "s/XXXXBUILD_IDENTIFIERXXXX/${BUILD_IDENTIFIER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/sed -i "s/XXXXBUILD_IDENTIFIERXXXX/${BUILD_IDENTIFIER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        /bin/sed -i "s/XXXXALGORITHMXXXX/${ALGORITHM}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/sed -i "s/XXXXALGORITHMXXXX/${ALGORITHM}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/sed -i "s/XXXXALGORITHMXXXX/${ALGORITHM}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        /bin/sed -i "s;XXXXAUTOSCALER_CONFIGURATIONXXXX;${autoscaler_configuration_settings};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/sed -i "s;XXXXWEBSERVER_CONFIGURATIONXXXX;${webserver_configuration_settings};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/sed -i "s;XXXXDATABASE_CONFIGURATIONXXXX;${database_configuration_settings};g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        autoscaler_cloud_init_status="`/usr/bin/cloud-init schema --config-file ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat`"
        status "${autoscaler_cloud_init_status}"
        if ( [ "`/bin/echo ${autoscaler_cloud_init_status} | /bin/grep 'Invalid'`" != "" ] )
        then
                exit
        fi     
        webserver_cloud_init_status= "`/usr/bin/cloud-init schema --config-file ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat`"
        status "${webserver_cloud_init_status}"
        if ( [ "`/bin/echo ${webserver_cloud_init_status} | /bin/grep 'Invalid'`" != "" ] )
        then
                exit
        fi   
        database_cloud_init_status= "`/usr/bin/cloud-init schema --config-file ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat`"
        status "${database_cloud_init_status}"
        if ( [ "`/bin/echo ${database_cloud_init_status} | /bin/grep 'Invalid'`" != "" ] )
        then
                exit
        fi   
fi
