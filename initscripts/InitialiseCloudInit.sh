#!/bin/sh

status () {
        /bin/echo "$1" | /usr/bin/tee /dev/fd/3 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"

if ( [ "${CLOUDHOST}" = "linode" ] )
then
        /bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/linode-autoscaler.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/linode-webserver.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/linode-database.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
fi
