#!/bin/sh
####################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This script will delete a pair of ssh keys from the cloud host provider
####################################################################################
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

key_name="${1}"
token="${2}"
cloudhost="${3}"

if ( [ "${cloudhost}" = "digitalocean" ] )
then
	key_id="`/usr/local/bin/doctl compute ssh-key list -o json | /usr/bin/jq '.[] | select (.name == "'${key_name}'").id'`"
	/usr/local/bin/doctl compute ssh-key delete ${key_id} --force 
fi
if ( [ "${cloudhost}" = "exoscale" ] )
then
	/bin/echo "Y" | /usr/bin/exo compute ssh-key  delete ${key_name} 
fi

if ( [ "${cloudhost}" = "linode" ] )
then
	key_id="`/usr/local/bin/linode-cli --json sshkeys list | /usr/bin/jq -r '.[] | select (.label == "'${key_name}'").id'`"
	/usr/local/bin/linode-cli sshkeys delete ${key_id}
fi

if ( [ "${cloudhost}" = "vultr" ] )
then
	key_id="`/usr/bin/vultr ssh-key list -o json | /usr/bin/jq -r '.ssh_keys[] | select (.name == "'${key_name}'").id'`"
	/usr/bin/vultr ssh-key delete ${key_id}
fi


