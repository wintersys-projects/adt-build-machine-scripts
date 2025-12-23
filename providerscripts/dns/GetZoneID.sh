#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 13/07/2016
# Description : This script is used to get the "zoneid" for a particular "zone name".
# Please refer to your DNS provider's documentation for more information
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
#######################################################################################
#######################################################################################
#set -x

zonename="${1}"
email="${2}"
credentials="${3}"
dns="${4}"

if ( [ "${dns}" = "cloudflare" ] )
then
        if ( [ "`/bin/echo ${credentials} | /bin/grep ':::'`" != "" ] )
        then
                api_token="`/bin/echo ${credentials} | /usr/bin/awk -F':::' '{print $2}'`"
                /usr/bin/curl -X GET "https://api.cloudflare.com/client/v4/zones?name=${zonename}&status=active&page=1&per_page=20&order=status&direction=desc&match=all" --header "Authorization: Bearer ${api_token}" --header "Content-Type: application/json" | /usr/bin/jq -r '.result[].id' 
        else
                authkey="${credentials}"
                /usr/bin/curl -X GET "https://api.cloudflare.com/client/v4/zones?name=${zonename}&status=active&page=1&per_page=20&order=status&direction=desc&match=all" -H "X-Auth-Email: ${email}" -H "X-Auth-Key: ${authkey}" -H "Content-Type: application/json" | /usr/bin/jq -r '.result[].id'
        fi
fi


