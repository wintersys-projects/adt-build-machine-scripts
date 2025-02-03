#!/bin/sh

status () {
        /bin/echo "$1" | /usr/bin/tee /dev/fd/3 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
TOKEN="`${BUILD_HOME}/helperscripts/GetVariableValue.sh TOKEN`"
CLOUDHOST_ACCOUNT_ID="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST_ACCOUNT_ID`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
ACCESS_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ACCESS_KEY`"
SECRET_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SECRET_KEY`"

if ( [ "${CLOUDHOST}" = "linode" ] )
then
        /bin/cp ${BUILD_HOME}/providerscripts/server/cloud-init/linode-autoscaler.dat 
