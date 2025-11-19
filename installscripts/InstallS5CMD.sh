#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Install S5CMD tool
#####################################################################################
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

if ( [ "$1" != "" ] )
then
        buildos="${1}"
fi

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s5cmd`" != "" ] )
then
        if ( [ "${buildos}" = "ubuntu" ] )
        then
                ${BUILD_HOME}/installscripts/InstallJQ.sh ${buildos}
                if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s5cmd:binary`" != "" ] )
                then
                        /usr/bin/wget "`/usr/bin/wget -q -O - https://api.github.com/repos/peak/s5cmd/releases/latest  | /usr/bin/jq -r '.assets[] | select (.name | contains ("amd64"))'.browser_download_url`"
                        /usr/bin/dpkg -i ./s5cmd_*_linux_amd64.deb
                        /bin/rm ./s5cmd_*_linux_amd64.deb
                fi
                if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s5cmd:source`" != "" ] )
                then
                        ${BUILD_HOME}/installscripts/InstallGo.sh ${buildos}
                        GOBIN=`/usr/bin/pwd` /usr/bin/go install github.com/peak/s5cmd/v2@latest                 
                        /bin/mv ./s5cmd /usr/bin/s5cmd                                      
                fi
        fi
        if ( [ "${buildos}" = "debian" ] )
        then
                ${BUILD_HOME}/installscripts/InstallJQ.sh ${buildos}
                if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s5cmd:binary`" != "" ] )
                then
                        /usr/bin/wget "`/usr/bin/wget -q -O - https://api.github.com/repos/peak/s5cmd/releases/latest  | /usr/bin/jq -r '.assets[] | select (.name | contains ("amd64"))'.browser_download_url`"
                        /usr/bin/dpkg -i ./s5cmd_*_linux_amd64.deb
                        /bin/rm ./s5cmd_*_linux_amd64.deb
                fi
                if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s5cmd:source`" != "" ] )
                then
                        ${BUILD_HOME}/installscripts/InstallGo.sh ${buildos}
                        GOBIN=`/usr/bin/pwd` /usr/bin/go install github.com/peak/s5cmd/v2@latest                 
                        /bin/mv ./s5cmd /usr/bin/s5cmd                                      
                fi
        fi
fi
