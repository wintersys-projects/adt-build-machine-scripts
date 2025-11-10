#!/bin/sh

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
SSH_PORT="`${HOME}/utilities/config/ExtractConfigValue.sh 'SSHPORT'`"
DB_PORT="`${HOME}/utilities/config/ExtractConfigValue.sh 'DBPORT'`"


/bin/cp ${BUILD_HOME}/builddescripts/firewallports.dat
