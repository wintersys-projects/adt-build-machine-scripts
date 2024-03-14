#!/bin/sh
#####################################################################################
# Author : Peter Winter
# Date   : 13/07/2016
# Description : This script will register an ssh key pair
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
##################################################################################
##################################################################################
#set -x

status () {
    /bin/echo "$1" | /usr/bin/tee /dev/fd/3
}

key_name="${1}"
token="${2}"
key_substance="${3}"
cloudhost="${4}"

if ( [ "${cloudhost}" = "digitalocean" ] )
then
    /usr/bin/curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" -d '{"name":"'"${key_name}"'","public_key":"'"${key_substance}"'"}' "https://api.digitalocean.com/v2/account/keys"

    if ( [ "$?" != "0" ] )
    then
        status "Invalid token mate, try again"
        exit
    fi

    active_keys="`/usr/bin/curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" "https://api.digitalocean.com/v2/account/keys"`"
    active_keys_names="`/bin/echo ${active_keys} | /usr/bin/jq ".ssh_keys[].name"`"

    count=0
    while ( [ "${active_keys_names}" = "" ] && [ "${count}" -lt "10" ] )
    do
        /bin/sleep 5
        count="`/usr/bin/expr ${count} + 1`"
        active_keys="`/usr/bin/curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" "https://api.digitalocean.com/v2/account/keys"`"
        active_keys_names="`/bin/echo ${active_keys} | /usr/bin/jq ".ssh_keys[].name"`"
    done

    if ( [ "`/bin/echo ${active_keys_names} | /usr/bin/wc -l`" -gt "1" ] )
    then
        status ""
        status "There's more than one key with the name ${key_name} in the digital ocean account you are using please remove them all manually"
        status "Please press the Return key to continue once you have navigated to www.digitalocean.com - > settings -> security and removed the key(s) called ${key_name}"
        read response
    fi

    if ( [ "`/bin/echo ${active_keys_names} | /usr/bin/wc -l`" = "0" ] )
    then
        /usr/bin/curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" -d '{"name":"'"${key_name}"'","public_key":"'"${key_substance}"'"}' "https://api.digitalocean.com/v2/account/keys"

        if ( [ "$?" != "0" ] )
        then
            status "Invalid token mate, try again"
            exit
        fi
    fi
fi

if ( [ "${cloudhost}" = "exoscale" ] )
then
    /bin/echo ${key_substance}  > /tmp/key
    /usr/bin/exo compute ssh-key register ${key_name} /tmp/key
    /bin/rm /tmp/key
fi

if ( [ "${cloudhost}" = "linode" ] )
then
    /usr/local/bin/linode-cli sshkeys create --label "${key_name}" --ssh_key="${key_substance}"
fi

if ( [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`/bin/cat ${BUILD_HOME}/runtimedata/${cloudhost}/TOKEN`"
    status "About to create ssh key in vultr"
    /bin/sleep 1
    /usr/bin/vultr ssh-key create -n "${key_name}" -k "${key_substance}"
fi

if ( [ "${cloudhost}" = "aws" ] )
then
   /usr/bin/aws ec2 import-key-pair --key-name "${key_name}" --public-key-material "${key_substance}"
fi

