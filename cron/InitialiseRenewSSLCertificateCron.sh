#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : Initialise Renew SSL Certificate cron
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
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"

if ( [ "`/usr/bin/crontab -l | /bin/grep InitialiseNewSSLCertificate.sh | /bin/grep -w "${BUILD_IDENTIFIER}" | /bin/grep -w "${CLOUDHOST}"`" = "" ] )
then
        /bin/echo '#10 3 * * * 'export HARDCORE="1" && ${BUILD_HOME}'/initscripts/InitialiseNewSSLCertificate.sh "none" "none" "'${BUILD_IDENTIFIER}'" "'${CLOUDHOST}'"' >> /var/spool/cron/crontabs/root
        /usr/bin/crontab -u root /var/spool/cron/crontabs/root 2>/dev/null
fi

if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
then
        if ( [ "`/usr/bin/crontab -l | /bin/grep "InitialiseNewSSLCertificate.sh" | /bin/grep "${BUILD_IDENTIFIER}" | /bin/grep "${CLOUDHOST}" | /bin/grep "^#"`" != "" ] )
        then
                status "Please note: the Initialise New SSL Certificate cronjob is currently commented out. If you want to enable SSL certificate renewal please uncomment the line shown below in your crontab"
                status "`/usr/bin/crontab -l | /bin/grep "InitialiseNewSSLCertificate.sh" | /bin/grep "${BUILD_IDENTIFIER}" | /bin/grep "${CLOUDHOST}" | /bin/grep "^#"`"
                status "Press <enter> to continue"
                read x
        fi
fi
        
