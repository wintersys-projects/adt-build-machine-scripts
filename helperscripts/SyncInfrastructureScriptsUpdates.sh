#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 11/08/2021
# Description: This script is run to sync changes made in the development area to the
# live scripts area
#######################################################################################
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
########################################################################################
########################################################################################
#set -x

/bin/echo "This script will sync the scripts in the development area with the live scripts area"
/bin/echo "Press <enter> to perform sync <ctrl-c> to exit"
read x

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

/bin/sh ${BUILD_HOME}/installscripts/InstallRsync.sh "`/bin/cat /etc/issue | /usr/bin/tr '[:upper:]' '[:lower:]' | /bin/egrep -o '(ubuntu|debian)'`"

/usr/bin/rsync -a /home/development/ ${BUILD_HOME}
/bin/chown -R root:root ${BUILD_HOME}
