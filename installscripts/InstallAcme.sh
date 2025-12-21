#!/bin/sh
######################################################################################################
# Description: This script will install the acme ssl certificate generation utility
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
email="${2}"

if ( [ "${buildos}" = "ubuntu" ] )
then
        if ( [ "`/bin/grep "^SSLCERTCLIENT:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep SSLCERTCLIENT:acme:acme`" != "" ] )
        then
                /usr/bin/wget -O -  https://get.acme.sh | /bin/sh -s email=${email} 
        elif ( [ "`/bin/grep "^SSLCERTCLIENT:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep SSLCERTCLIENT:acme:github`" != "" ] )
        then
                /usr/bin/curl https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh | sh -s -- --install-online -m ${email}
        fi
fi

if ( [ "${buildos}" = "debian" ] )
then
        if ( [ "`/bin/grep "^SSLCERTCLIENT:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep SSLCERTCLIENT:acme:acme`" != "" ] )
        then
                /usr/bin/wget -O -  https://get.acme.sh | /bin/sh -s email=${email} 
        elif ( [ "`/bin/grep "^SSLCERTCLIENT:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep SSLCERTCLIENT:acme:github`" != "" ] )
        then
                /usr/bin/curl https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh | sh -s -- --install-online -m ${email}
        fi
fi



