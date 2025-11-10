#!/bin/sh

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
SSH_PORT="`${HOME}/utilities/config/ExtractConfigValue.sh 'SSHPORT'`"
DB_PORT="`${HOME}/utilities/config/ExtractConfigValue.sh 'DBPORT'`"
CLOUDHOST="`${HOME}/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
BUILD_IDENTIFIER="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILD_IDENTIFIER'`"


if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/firewallports.dat ] )
then
  /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/firewallports.dat
fi

if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER} ] )
then
  /bin/cp ${BUILD_HOME}/builddescripts/firewallports.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/firewallports.dat
  /bin/sed -i "s/SSH_PORT/${SSH_PORT}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/firewallports.dat
  /bin/sed -i "s/DB_PORT/${DB_PORT}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/firewallports.dat
fi

