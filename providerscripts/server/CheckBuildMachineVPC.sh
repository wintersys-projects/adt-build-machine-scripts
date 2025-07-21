#!/bin/sh
###################################################################################
# Author : Peter Winter
# Date   : 15/02/2024
# Description : This script does a rudimentary check to check that your build-machine
# is connected to a VPC when its supposed to be. If we can't get a private IP address it
# means that the machine is not connected to a VPC
###################################################################################
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

cloudhost="${1}"
server_ip="${2}"

if ( [ "${cloudhost}" = "digitalocean" ] )
then
	server_name="`${BUILD_HOME}/providerscripts/server/GetServerName.sh ${server_ip} digitalocean`"
	${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh ${server_name} digitalocean 
fi

if ( [ "${cloudhost}" = "exoscale" ] )
then
	server_name="`${BUILD_HOME}/providerscripts/server/GetServerName.sh ${server_ip} exoscale`"
	${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh ${server_name} exoscale 
fi

if ( [ "${cloudhost}" = "linode" ] )
then
	server_name="`${BUILD_HOME}/providerscripts/server/GetServerName.sh ${server_ip} linode`"
	${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh ${server_name} linode 
fi

if ( [ "${cloudhost}" = "vultr" ] )
then
	server_name="`${BUILD_HOME}/providerscripts/server/GetServerName.sh ${server_ip} vultr`"
	if ( [ "${server_name}" = "" ] )
	then
		server_name="NOT_SET"
	fi
	${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh ${server_name} vultr 
fi
