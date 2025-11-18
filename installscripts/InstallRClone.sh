#!/bin/sh
######################################################################################################
# Description: This script will install rclone
# Author: Peter Winter
# Date: 17/01/2017
#######################################################################################################
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
#######################################################################################################
#######################################################################################################
#set -x

if ( [ "${1}" != "" ] )
then
        buildos="${1}"
fi

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

apt=""
if ( [ "`/bin/grep "^PACKAGEMANAGER:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "apt" ] )
then
        apt="/usr/bin/apt"
elif ( [ "`/bin/grep "^PACKAGEMANAGER:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "apt-get" ] )
then
        apt="/usr/bin/apt-get"
fi

export DEBIAN_FRONTEND=noninteractive 
install_command="${apt} -o DPkg::Lock::Timeout=-1 -o Dpkg::Use-Pty=0 -qq -y install " 

cwd="`/usr/bin/pwd`"

if ( [ "${apt}" != "" ] )
then
        if ( [ "${buildos}" = "ubuntu" ] )
        then
                if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep rclone:repo`" != "" ] )
                then
                        eval ${install_command} rclone
                fi
                if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep rclone:binary`" != "" ] )
                then
                        eval ${install_command} unzip 
                        cd /opt
                        /usr/bin/wget https://downloads.rclone.org/rclone-current-linux-amd64.zip
                        /usr/bin/unzip /opt/rclone*.zip
                        /bin/cp rclone*amd64/rclone /usr/bin/rclone
                        cd ${cwd}
                fi
                if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep rclone:script`" != "" ] )
                then
                        /usr/bin/curl https://rclone.org/install.sh | /usr/bin/bash
                        cd ${cwd}
                fi   
                if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep rclone:source`" != "" ] )
                then
                        ${BUILD_HOME}/installscripts/InstallGo.sh ${buildos}
                        cd /opt
                        /usr/bin/git clone https://github.com/rclone/rclone.git 
                        cd /opt/rclone
                        /usr/bin/go build
                        /bin/mv /opt/rclone/rclone /usr/bin/rclone
                        /bin/rm -r /opt/rclone
                        cd ${cwd}
                fi
        fi

        if ( [ "${buildos}" = "debian" ] )
        then
                if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep rclone:repo`" != "" ] )
                then
                        eval ${install_command} rclone
                fi
                if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep rclone:binary`" != "" ] )
                then
                        eval ${install_command} unzip 
                        cd /opt
                        /usr/bin/wget https://downloads.rclone.org/rclone-current-linux-amd64.zip
                        /usr/bin/unzip /opt/rclone*.zip
                        /bin/cp rclone*amd64/rclone /usr/bin/rclone
                        cd ${cwd}
                fi
                if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep rclone:script`" != "" ] )
                then
                        /usr/bin/curl https://rclone.org/install.sh | /usr/bin/bash
                        cd ${cwd}
                fi     
                if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep rclone:source`" != "" ] )
                then
                        ${BUILD_HOME}/installscripts/InstallGo.sh ${buildos}
                        cd /opt
                        /usr/bin/git clone https://github.com/rclone/rclone.git 
                        cd /opt/rclone
                        /usr/bin/go build
                        /bin/mv /opt/rclone/rclone /usr/bin/rclone
                        /bin/rm -r /opt/rclone
                        cd ${cwd}
                fi
        fi
fi

