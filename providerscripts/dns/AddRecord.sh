#!/bin/sh
########################################################################
# Author : Peter Winter
# Date   : 13/07/2016
# Description : This script will add a new DNS record to the DNS provider
#########################################################################
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
################################################################################
################################################################################
#set -x

status () {
        /bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
        /bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

zoneid="${1}"
email="${2}"
credentials="${3}"
websiteurl="${4}"
ip="${5}"
proxied="${6}"
dns="${7}"

if ( [ "${dns}" = "cloudflare" ] )
then
        #authkey="${credentials}"
        api_token="`/bin/echo ${credentials} | /usr/bin/awk -F':::' '{print $2}'`"
        #Make damn sure that the DNS record gets added to the DNS system
        count="0"
        while ( ( [ "$?" != "0" ] || [ "${count}" = "0" ] ) && [ "${count}" -lt "5" ] )
        do
                count="`/usr/bin/expr ${count} + 1`"
                #keu
                #/usr/bin/curl -X POST "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records" -H "X-Auth-Email: ${email}" -H "X-Auth-Key: ${authkey}" -H "Content-Type: application/json" --data '{"type":"A","name":"'${websiteurl}'","content":"'${ip}'","proxiable":true,"proxied":'${proxied}',"ttl":120}'
                #token
                /usr/bin/curl -X POST "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records" --header "Authorization: Bearer ${api_token}" --header "Content-Type: application/json" --data '{"type":"A","name":"'${websiteurl}'","content":"'${ip}'","proxiable":true,"proxied":'${proxied}',"ttl":120}'
        done

        if ( [ "${count}" = "5" ] )
        then
                /bin/touch /tmp/END_IT_ALL
        fi
fi

websiteurl="${4}"
domainurl="`/bin/echo ${4} | /usr/bin/cut -d'.' -f2-`"
subdomain="`/bin/echo ${4} | /usr/bin/awk -F'.' '{print $1}'`"
ip="${5}"
dns="${7}"

if ( [ "${dns}" = "digitalocean" ] )
then
        #Make damn sure that the DNS record gets added to the DNS system
        count="0"
        while ( [ "${count}" -lt "5" ] && [ "`/usr/local/bin/doctl compute domain records list ${domainurl} -o json | /usr/bin/jq -r '.[] | select (.data == "'${ip}'").id'`" = "" ] )
        do
                count="`/usr/bin/expr ${count} + 1`"
                /usr/local/bin/doctl compute domain records create --record-type A --record-name ${subdomain} --record-data ${ip}  --record-ttl 60 ${domainurl}
        done

        if ( [ "${count}" = "5" ] )
        then
                /bin/touch /tmp/END_IT_ALL
        fi
fi

subdomain="`/bin/echo ${4} | /usr/bin/awk -F'.' '{print $1}'`"
domainurl="`/bin/echo ${4} | /usr/bin/cut -d'.' -f2-`"
ip="${5}"
dns="${7}"

if ( [ "${dns}" = "exoscale" ] )
then
        #Make damn sure that the DNS record gets added to the DNS system
        count="0"

        id="`/usr/bin/exo dns list -O json | /usr/bin/jq -r '.[] | select (.name == "'${domainurl}'").id'`"

        if ( [ "${id}" != "" ] )
        then
                while ( [ "${count}" -lt "5" ] && [ "`/usr/bin/exo dns show ${id} -O json | /usr/bin/jq -r '.[] | select (.content == "'${ip}'").id'`" = "" ] )
                do
                        count="`/usr/bin/expr ${count} + 1`"
                        /usr/bin/exo dns add A ${domainurl} -a ${ip} -n ${subdomain} -t 60
                done
        fi

        if ( [ "${count}" = "5" ] || [ "${id}" = "" ] )
        then
                /bin/touch /tmp/END_IT_ALL
        fi
fi

subdomain="`/bin/echo ${4} | /usr/bin/awk -F'.' '{print $1}'`"
domain_url="`/bin/echo ${4} | /usr/bin/cut -d'.' -f2-`"
ip="${5}"
dns="${7}"

if ( [ "${dns}" = "linode" ] )
then
        domain_id="`/usr/local/bin/linode-cli --json domains list | /usr/bin/jq -r '.[] | select (.domain | contains("'${domain_url}'")).id'`"
        #Make damn sure that the DNS record gets added to the DNS system
        count="0"
        while ( [ "${count}" -lt "5" ] && [ "`/usr/local/bin/linode-cli domains records-list ${domain_id} --json | /usr/bin/jq -r '.[] | select (.target == "'${ip}'").id'`" = "" ] )
        do
                count="`/usr/bin/expr ${count} + 1`"
                /usr/local/bin/linode-cli domains records-create ${domain_id} --type A --name ${subdomain} --target ${ip} --ttl_sec 60
        done

        if ( [ "${count}" = "5" ] )
        then
                /bin/touch /tmp/END_IT_ALL
        fi
fi

subdomain="`/bin/echo ${4} | /usr/bin/awk -F'.' '{print $1}'`"
domainurl="`/bin/echo ${4} | /usr/bin/cut -d'.' -f2-`"
ip="${5}"
dns="${7}"

if ( [ "${dns}" = "vultr" ] )
then
        #Make damn sure that the DNS record gets added to the DNS system
        count="0"
        while ( [ "${count}" -lt "5" ] && [ "`/usr/bin/vultr dns record list ${domainurl} -o json | /usr/bin/jq -r '.records[] | select (.data == "'${ip}'").id'`" = "" ] )
        do
                count="`/usr/bin/expr ${count} + 1`"
                /usr/bin/vultr dns record create ${domainurl} -n ${subdomain} -t A -d "${ip}" --priority=10 --ttl=60
        done

        if ( [ "${count}" = "5" ] )
        then
                /bin/touch /tmp/END_IT_ALL
        fi
fi



