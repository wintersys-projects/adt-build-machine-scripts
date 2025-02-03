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
                        
if ( [ "${CLOUDHOST}" = "linode" ] )
then
        /bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/linode-autoscaler.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/linode-webserver.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/linode-database.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
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
        /bin/sed -i "s/XXXXINFRASTRUCTURE_REPOSITORY_PROVIDERXXXX/${infrastructure_repository_provider}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/sed -i "s/XXXXINFRASTRUCTURE_REPOSITORY_PROVIDERXXXX/${infrastructure_repository_provider}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/sed -i "s/XXXXINFRASTRUCTURE_REPOSITORY_PROVIDERXXXX/${infrastructure_repository_provider}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        /bin/sed -i "s/XXXXINFRASTRUCTURE_REPOSITORY_OWNERXXXX/${INFRASTRUCTURE_REPOSITORY_OWNER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/sed -i "s/XXXXINFRASTRUCTURE_REPOSITORY_OWNERXXXX/${INFRASTRUCTURE_REPOSITORY_OWNER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/sed -i "s/XXXXINFRASTRUCTURE_REPOSITORY_OWNERXXXX/${gINFRASTRUCTURE_REPOSITORY_OWNER}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        /bin/sed -i "s/XXXXALGORITHMXXXX/${ALGORITHM}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/sed -i "s/XXXXALGORITHMXXXX/${ALGORITHM}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/sed -i "s/XXXXALGORITHMXXXX/${ALGORITHM}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        status "`/usr/bin/cloud-init schema --config-file ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat`"
        status "`/usr/bin/cloud-init schema --config-file ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat`"
        status "`/usr/bin/cloud-init schema --config-file ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat`"

fi
