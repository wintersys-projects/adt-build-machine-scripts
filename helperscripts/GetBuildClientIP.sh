#!/bin/sh
###########################################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : Get the ip address of our build machine
###########################################################################################################
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

export BUILD_MACHINE_IP="`/usr/bin/wget http://ipinfo.io/ip -qO -`"

if ( [ "${BUILD_MACHINE_IP}" = "" ] )
then
	export BUILD_MACHINE_IP="`/usr/bin/curl -4 icanhazip.com`"
fi

if ( [ "${BUILD_MACHINE_IP}" = "" ] )
then
	export BUILD_MACHINE_IP="`/bin/hostname -I | /usr/bin/awk '{print $1}'`"
fi

if ( [ "${BUILD_MACHINE_IP}" = "" ] )
then
	/bin/echo "Couldn't get build machine IP address after 3 separate attempts, having to exit"
	exit
else 
	/bin/echo ${BUILD_MACHINE_IP}
fi
