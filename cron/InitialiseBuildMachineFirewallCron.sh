#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : Initialise Build Machine firewall crontab
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

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

if ( [ "`/usr/bin/crontab -l | /bin/grep AdjustBuildMachineFirewall.sh`" = "" ] )
then
        /bin/echo "*/1 * * * * ${BUILD_HOME}/security/firewall/AdjustBuildMachineFirewall.sh" >> /var/spool/cron/crontabs/root
        /usr/bin/crontab -u root /var/spool/cron/crontabs/root 2>/dev/null
fi
