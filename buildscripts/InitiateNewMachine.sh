#!/bin/sh
####################################################################################
# Author : Peter Winter
# Date   : 13/07/2016
# Description : This will initialise a new machine with things like its SSH key
# and custom user. Its the same process to intiate a machine for all types of machine
# (autoscaler, webserver, database)
# I choose not to use cloud-init
####################################################################################
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
set -x

status () {
        /bin/echo "$1" | /usr/bin/tee /dev/fd/3 2>/dev/null
}

initiation_ip="${1}"
machine_type="${2}"
public_keys="${3}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
ALGORITHM="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ALGORITHM`"
DEFAULT_USER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DEFAULT_USER`"
SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"

BUILD_KEY="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"

OPTIONS="-o ConnectTimeout=10 -o ConnectionAttempts=5 -o UserKnownHostsFile=${public_keys} -o StrictHostKeyChecking=yes "

loop="0"
connected="0"
sshpass="0"
while ( [ "${connected}" = "0" ] && [ "${loop}" -lt "20" ] )
do
        /usr/bin/ssh ${OPTIONS} -o "PasswordAuthentication=no" -i ${BUILD_KEY} ${SERVER_USER}@${initiation_ip} '/bin/touch /tmp/alive.$$' 2>/dev/null
        if ( [ "$?" = "0" ] )
        then
                connected="1"
        fi
        /bin/sleep 10
        loop="`/usr/bin/expr ${loop} + 1`"
done

if ( [ "${connected}" != "1" ] )
then
        status "Sorry could not connect to the ${machine_type}. Is it possible that your CLOUDHOST_PASSWORD hasn't been set?"
        exit
fi

/usr/bin/scp ${OPTIONS} -i ${BUILD_KEY} ${BUILD_KEY} ${SERVER_USER}@${initiation_ip}:/home/${SERVER_USER}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY

status "It looks like the ${machine_type} machine with ip address ${initiation_ip} is booted and accepting connections, so, let's pass it all our configuration stuff that it needs"
