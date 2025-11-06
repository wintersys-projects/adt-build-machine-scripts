#!/bin/sh
#################################################################################
# Author : Peter Winter
# Date   : 13/07/2016
# Description : This script will retrieve all the record id's for the selected
# domain name (website url)
#################################################################################
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
###################################################################################
###################################################################################
#set -x

status () {
        /bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
        /bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

zoneid="${1}"
websiteurl="${2}"
email="${3}"
credentials="${4}"
dns="${5}"

if ( [ "${dns}" = "cloudflare" ] )
then
        if ( [ "`/bin/echo ${credentials} | /bin/grep ':::'`" = "" ] )
        then
                api_token="`/bin/echo ${credentials} | /usr/bin/awk -F':::' '{print $2}'`"
                /usr/bin/curl -X GET "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records?type=A&name=${websiteurl}&page=1&per_page=20&order=type&direction=desc&match=all" --header "Authorization: Bearer ${api_token}" --header "Content-Type: application/json"  | /usr/bin/jq -r '.result[].id'
        else
                authkey="${credentials}"
                /usr/bin/curl -X GET "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records?type=A&name=${websiteurl}&page=1&per_page=20&order=type&direction=desc&match=all" -H "X-Auth-Email: ${email}" -H "X-Auth-Key: ${authkey}" -H "Content-Type: application/json" | /usr/bin/jq -r '.result[].id'
        fi
fi

websiteurl="${2}"
domainurl="`/bin/echo ${2} | /usr/bin/cut -d'.' -f2-`"
subdomain="`/bin/echo ${2} | /usr/bin/awk -F'.' '{print $1}'`"
dns="${5}"

if ( [ "${dns}" = "digitalocean" ] )
then
        /usr/local/bin/doctl compute domain records list ${domainurl} -o json | /usr/bin/jq -r '.[] | select (.type == "A") | select (.name == "'${subdomain}'").id'
fi

domainurl="`/bin/echo ${2} | /usr/bin/cut -d'.' -f2-`"
subdomain="`/bin/echo ${2} | /usr/bin/awk -F'.' '{print $1}'`"
authkey="`/bin/echo ${4} | /usr/bin/awk -F':' '{print $NF}'`"
dns="${5}"

if ( [ "${dns}" = "exoscale" ] )
then
        /usr/bin/exo  --config /root/.config/exoscale/dns-exoscale.toml -O json dns show ${domainurl}  | /usr/bin/jq -r '.[] | select (.name | contains("'${subdomain}'")).id'
        #Alternative
        #/usr/bin/curl  -H "X-DNS-Token: ${authkey}" -H 'Accept: application/json' https://api.exoscale.com/dns/v1/domains/${domainurl}/records | /usr/bin/jq --arg tmp_subdomain "${subdomain}" '.[].record | select (.name == $tmp_subdomain) | .id'
fi

domain_url="`/bin/echo ${2} | /usr/bin/cut -d'.' -f2-`"
subdomain="`/bin/echo ${2} | /usr/bin/awk -F'.' '{print $1}'`"
dns="${5}"

if ( [ "${dns}" = "linode" ] )
then
        export LINODE_CLI_CONFIG=/root/.config/dns-linode-cli
        domain_id="`/usr/local/bin/linode-cli domains list --no-defaults --json | /usr/bin/jq -r '.[] | select (.domain | contains("'${domain_url}'")).id'`"
        /usr/local/bin/linode-cli domains records-list ${domain_id} --no-defaults --json | /usr/bin/jq -r '.[] | select (.name == "'${subdomain}'").id'
        unset LINODE_CLI_CONFIG
fi

domainurl="`/bin/echo ${2} | /usr/bin/cut -d'.' -f2-`"
subdomain="`/bin/echo ${2} | /usr/bin/awk -F'.' '{print $1}'`"
authkey="${4}"
dns="${5}"

if ( [ "${dns}" = "vultr" ] )
then
        /usr/bin/vultr dns record list ${domainurl} -o json | /usr/bin/jq -r '.records[] | select (.name == "'${subdomain}'").id'
fi
