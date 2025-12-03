#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Install the S3CMD tool 
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

if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s3cmd`" != "" ] )
then
        apt=""
        if ( [ "`/bin/grep "^PACKAGEMANAGER:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "apt" ] )
        then
                apt="/usr/bin/apt"
        elif ( [ "`/bin/grep "^PACKAGEMANAGER:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "apt-get" ] )
        then
                apt="/usr/bin/apt-get"
        fi

        install_command="DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1 -o Dpkg::Use-Pty=0 -qq -y install " 

        if ( [ "${apt}" != "" ] )
        then
                if ( [ "${buildos}" = "ubuntu" ] )
                then
                        if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s3cmd:repo`" != "" ] )
                        then
                                eval ${install_command} s3cmd
                        elif ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s3cmd:source`" != "" ] )
                        then
                                eval ${install_command} python3 python3-dateutil
                                /usr/bin/ln -s /usr/bin/python3 /usr/bin/python
								${BUILD_HOME}/providerscripts/git/GitClone.sh "github" "" "s3tools" "s3cmd" ""
                                /bin/cp ./s3cmd/s3cmd /usr/bin/s3cmd
                                /bin/cp -r ./s3cmd/S3 /usr/bin/
                                /bin/rm -r ./s3cmd
                        fi
                fi
                if ( [ "${buildos}" = "debian" ] )
                then
                        if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s3cmd:repo`" != "" ] )
                        then
                                eval ${install_command} s3cmd
                        elif ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s3cmd:source`" != "" ] )
                        then
                                eval ${install_command} python3 python3-dateutil
                                /usr/bin/ln -s /usr/bin/python3 /usr/bin/python
								${BUILD_HOME}/providerscripts/git/GitClone.sh "github" "" "s3tools" "s3cmd" ""
                                /bin/cp ./s3cmd/s3cmd /usr/bin/s3cmd
                                /bin/cp -r ./s3cmd/S3 /usr/bin/
                                /bin/rm -r ./s3cmd
                        fi
                fi
        fi
fi
