#!/bin/sh
############################################################################################
# Author : Peter Winter
# Date   : 13/07/2016
# Description : This scripts lists the number of servers of a particular type that are running
############################################################################################
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
##########################################################################################
##########################################################################################
#set -x

server_type="${1}"
cloudhost="${2}"

if ( [ "${cloudhost}" = "digitalocean" ] )
then
	/usr/local/bin/doctl compute droplet list | /bin/grep ${server_type} | /usr/bin/wc -l
fi

if ( [ "${cloudhost}" = "exoscale" ] )
then
  #  BUILD_HOME="`/usr/bin/pwd`"
	zone="`/bin/cat ${BUILD_HOME}/runtimedata/${cloudhost}/CURRENTREGION`"
	/usr/bin/exo compute instance list --zone ${zone} -O text | /bin/grep "${server_type}" | /usr/bin/wc -l
fi

if ( [ "${cloudhost}" = "linode" ] )
then
	/usr/local/bin/linode-cli linodes list --text | /bin/grep "${server_type}" | /usr/bin/wc -l 2>/dev/null
fi

if ( [ "${cloudhost}" = "vultr" ] )
then
  #  BUILD_HOME="`/usr/bin/pwd | /bin/sed 's/adt-build-machine-scripts.*/adt-build-machine-scripts/g'`"    
	export VULTR_API_KEY="`/bin/cat ${BUILD_HOME}/runtimedata/${cloudhost}/TOKEN`"
	/bin/sleep 1
	server_type="`/bin/echo ${server_type} | /usr/bin/cut -c -25`"
	/usr/bin/vultr instance list | /bin/grep ${server_type} | /usr/bin/awk '{print $2}' | /usr/bin/wc -l
fi




