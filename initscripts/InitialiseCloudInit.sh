#!/bin/sh

status () {
        /bin/echo "$1" | /usr/bin/tee /dev/fd/3 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"

  - name: XXXXOS_USERXXXX
    shell: /bin/bash
    groups:
      - sudo
    sudo:
      - ALL=(ALL:ALL) ALL

    shell: /bin/bash
    ssh_authorized_keys:
      - XXXXSSH_PUBLIC_KEYXXXX

if ( [ "${CLOUDHOST}" = "linode" ] )
then
        /bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/linode-autoscaler.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/linode-webserver.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/linode-database.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        /bin/sed -i "s/XXXOS_USERXXXX//g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/sed -i "s/XXXOS_USERXXXX//g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/sed -i "s/XXXOS_USERXXXX//g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
        /bin/sed -i "s/XXXXSSH_PUBLIC_KEYXXXX//g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-autoscaler.dat
        /bin/sed -i "s/XXXXSSH_PUBLIC_KEYXXXX//g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-webserver.dat
        /bin/sed -i "s/XXXXSSH_PUBLIC_KEYXXXX//g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/linode-database.dat
fi
