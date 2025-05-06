#!/bin/sh
######################################################################################
# Description: This script will install the cloudhost tools for the provider you have
# selected. These tools will give API access to the provider which can then be used by
# the other scripts to manipulate resourced on that providers infrastructure.
# Date: 07-11-2016
# Author: Peter Winter
######################################################################################
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
######################################################################################
######################################################################################
#set -x

cloudhost="${1}"
buildos="${2}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

if ( [ "${cloudhost}" = "digitalocean" ] )
then
	status "Installing/Updating Digital Ocean cloudhost cli tool (doctl)"
	${BUILD_HOME}/installscripts/InstallDoctl.sh "${buildos}"
fi

if ( [ "${cloudhost}" = "exoscale" ] )
then
	status "Installing/Updating Exoscale cloudhost cli tool (exo)"
	${BUILD_HOME}/installscripts/InstallExo.sh "${buildos}"
fi

if ( [ "${cloudhost}" = "linode" ] )
then
	status "Installing/Updating Linode cloudhost cli tool (linode-cli)"
	${BUILD_HOME}/installscripts/InstallLinodeCLI.sh "${buildos}"
fi

if ( [ "${cloudhost}" = "vultr" ] )
then
	status "Installing/Updating Vultr cloudhost cli tool (vultr-cli)"
	${BUILD_HOME}/installscripts/InstallSudo.sh "${buildos}"
	${BUILD_HOME}/installscripts/InstallVultrCLI.sh "${buildos}"        
fi

