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

key_name="${1}"
token="${2}"
cloudhost="${3}"

if ( [ "${cloudhost}" = "digitalocean" ] )
then
    /usr/bin/curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" "https://api.digitalocean.com/v2/account/keys" | /usr/bin/jq ".ssh_keys[].name" > runtimedata/names
    /usr/bin/curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" "https://api.digitalocean.com/v2/account/keys" | /usr/bin/jq ".ssh_keys[].id" > runtimedata/ids
    key_ids=""
    id_indexes="`/bin/cat -n runtimedata/names | /bin/grep ${key_name} | /usr/bin/awk '{print $1}'`"
    for id_index in ${id_indexes}
    do
        key_ids="${key_ids} `/bin/sed "${id_index}q;d" runtimedata/ids`"
    done
    /bin/echo "KEY IDS="${key_ids}

    #Delete the keys we had from 'old' builds so that our fresh keys are used instead

    for id in ${key_ids}
    do
        /usr/bin/curl -X DELETE -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" "https://api.digitalocean.com/v2/account/keys/${id}"
    done
fi
if ( [ "${cloudhost}" = "exoscale" ] )
then
    /bin/echo "Y" | /usr/bin/exo compute ssh-key  delete ${key_name} 
fi

if ( [ "${cloudhost}" = "linode" ] )
then
    keyids="`/usr/local/bin/linode-cli --text sshkeys list | /bin/grep ${key_name} | /usr/bin/awk '{print $1}'`"

    for keyid in ${keyids}
    do
        /usr/local/bin/linode-cli sshkeys delete ${keyid}
    done
fi

if ( [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`/bin/cat ${BUILD_HOME}/runtimedata/${cloudhost}/TOKEN`"
    /bin/sleep 1
    for key_id in `/usr/bin/vultr ssh-key list | /bin/grep ".*-.*-" | /usr/bin/awk '{print $1}' | /usr/bin/head -n -1`
    do
        /usr/bin/vultr ssh-key delete ${key_id}
    done
fi

if ( [ "${cloudhost}" = "aws" ] )
then
    /usr/bin/aws ec2 delete-key-pair --key-name ${key_name}
fi

