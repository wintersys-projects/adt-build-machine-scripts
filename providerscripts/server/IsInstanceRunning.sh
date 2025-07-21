#!/bin/sh
########################################################################################
# Author : Peter Winter
# Date:    13/07/2016
# Description : This script will determine if a machine with a given name is running or not
########################################################################################
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

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

server_type="${1}"
cloudhost="${2}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
BUILD_IDENTIFIER="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER`"

if ( [ "${cloudhost}" = "digitalocean" ] )
then
	if ( [ "`/usr/local/bin/doctl compute droplet list -o json | /usr/bin/jq -r '.[] | select (.name | contains("'${server_type}'")).status' 2>/dev/null`" = "active" ] )
	then
		/bin/echo "running"
	else
		/bin/echo "not running"
	fi
fi
if ( [ "${cloudhost}" = "exoscale" ] )
then
	zone="`/bin/cat ${BUILD_HOME}/runtimedata/${cloudhost}/${BUILD_IDENTIFIER}/CURRENTREGION`"
	if ( [ "`/usr/bin/exo compute instance list --zone ${zone} -O json | /usr/bin/jq -r '.[] | select (.name | contains("'${server_type}'")).state' 2>/dev/null`" = "running" ] )
	then
		/bin/echo "running"
	else
		/bin/echo "not running"
	fi
fi

if ( [ "${cloudhost}" = "linode" ] )
then
	if ( [ "`/usr/local/bin/linode-cli --json linodes list | /usr/bin/jq -r '.[] | select (.label | contains("'${server_type}'")).status' 2>/dev/null`" = "running" ] )
	then
		/bin/echo "running"
	else
		/bin/echo "not running"
	fi
fi

if ( [ "${cloudhost}" = "vultr" ] )
then
	server_type="`/bin/echo ${server_type} | /usr/bin/cut -c -25`"
	if ( [ "`/usr/bin/vultr instance list -o json | /usr/bin/jq -r '.instances[] | select (.label | contains("'${server_type}'")).status' 2>/dev/null`" = "active" ] )
	then
		/bin/echo "running"
	else
		/bin/echo "not running"
	fi
fi



