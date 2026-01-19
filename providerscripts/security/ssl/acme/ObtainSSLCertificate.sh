#!/bin/sh
#####################################################################################
# Description: This is a script which will generate an SSL Certificate. When a webserver
# is being built from the build client and not through the autoscaling mechanism, there
# are 3 scenarios
#
# 1) No certificate has been issued for the current domain name before in which case,
# one is generated and stored in the build directory hierarchy where it can be retrieved later
#
# 2) A certificate has been generated before for this domain name and we want to reuse it
# by selecting it from the build client filesystem where we stored it in 1. In this case,
# this script will not be used to generate a certificate.
#
# 3) There is a previously issued certificate we can use, but, it has expired, in which case
# this script will be used to generate a new certificate.
#
# Something to be aware of. There are limits set on certificate issuance so, if you run
# scenario 1, several times as you would if you are making "HARDCORE" builds then if you are
# not issuing staging certificates then you will hit the issuing limit and the certificate
# will fail to generate. To work around this (but only if you are testing) then set
# SSL_LIVE_CERT="0" in your template to generate a staging certicate free of issuing limits
# rather than a live certificate which has issuance constraints. 
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
#######################################################################################################
#######################################################################################################
#set -x

website_url="${1}"
auth="${2}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
SYSTEM_FROMEMAIL_ADDRESS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'SYSTEM_FROMEMAIL_ADDRESS'`"
ROOT_DOMAIN="`/bin/echo ${website_url} | /usr/bin/cut -d'.' -f2-`"
DNS_USERNAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_USERNAME`"
DNS_SECURITY_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_SECURITY_KEY`"
DNS_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_CHOICE`"
BUILDOS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS`"
SSL_GENERATION_METHOD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSL_GENERATION_METHOD`"
SSL_GENERATION_SERVICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSL_GENERATION_SERVICE`"
SSL_LIVE_CERT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSL_LIVE_CERT`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"

if ( [ "${website_url}" != "" ] )
then
        WEBSITE_URL="${website_url}"
else
        WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
fi

if ( [ "${auth}" = "yes" ] )
then
        WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTH_SERVER_URL`"
        DNS_USERNAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTH_DNS_USERNAME`"
        DNS_SECURITY_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTH_DNS_SECURITY_KEY`"
        DNS_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTH_DNS_CHOICE`"
fi

if ( [ "${SSL_GENERATION_SERVICE}" = "ZEROSSL" ] )
then
        server="zerossl"
fi

if ( [ "${SYSTEM_FROMEMAIL_ADDRESS}" = "" ] )
then
        SYSTEM_FROMEMAIL_ADDRESS="${DNS_USERNAME}"
fi

if ( [ -f ~/.acme.sh/acme.sh ] )
then
        /bin/rm -r ~/.acme.sh
fi

${BUILD_HOME}/installscripts/InstallSocat.sh ${BUILDOS}
${BUILD_HOME}/installscripts/InstallAcme.sh ${BUILDOS} ${SYSTEM_FROMEMAIL_ADDRESS} #"https://acme-v02.api.letsencrypt.org/directory "

if ( [ "`/bin/grep -r ${SYSTEM_FROMEMAIL_ADDRESS} ~/.acme.sh`" = "" ] )
then
        ~/.acme.sh/acme.sh --register-account -m "${SYSTEM_FROMEMAIL_ADDRESS}" 
else
        ~/.acme.sh/acme.sh --update-account -m "${SYSTEM_FROMEMAIL_ADDRESS}" --force
fi

~/.acme.sh/acme.sh --set-default-ca --server "${server}"
~/.acme.sh/acme.sh --remove --domain ${WEBSITE_URL} 

count="0"

if ( [ "${DNS_CHOICE}" = "cloudflare" ] )
then
        zonename="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
        zoneid="`${BUILD_HOME}/providerscripts/dns/GetZoneID.sh "${zonename}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"`"

        if ( [ "${zoneid}" = "" ] )
        then
                ${BUILD_HOME}/providerscripts/dns/CreateZone.sh "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${WEBSITE_URL}" "${DNS_CHOICE}"
        fi

        if ( [ "`/bin/echo ${DNS_SECURITY_KEY} | /bin/grep ':::'`" != "" ] )
        then
                account_id="`/bin/echo ${DNS_SECURITY_KEY} | /usr/bin/awk -F':::' '{print $1}'`"
                api_token="`/bin/echo ${DNS_SECURITY_KEY} | /usr/bin/awk -F':::' '{print $2}'`"

                export CF_Account_ID="${account_id}"
                export CF_Token="${api_token}"
        else
                export CF_Key="${DNS_SECURITY_KEY}"
                export CF_Email="${DNS_USERNAME}"
        fi

        ~/.acme.sh/acme.sh --issue --dns dns_cf -d "${WEBSITE_URL}" --server ${server} --standalone
        if ( [ "$?" != "0" ] )
        then
                ~/.acme.sh/acme.sh --renew --dns dns_cf -d "${WEBSITE_URL}" --server ${server} --standalone
        fi               
fi


if ( [ "${DNS_CHOICE}" = "digitalocean" ] )
then
        if ( [ -f ~/.acme.sh/dnsapi/dns_dgon.sh ] )
        then
                /bin/cp ${BUILD_HOME}/providerscripts/security/ssl/acme/acme-overrides/digitalocean.sh ~/.acme.sh/dnsapi/dns_dgon.sh
        fi

        ~/.acme.sh/acme.sh --issue --dns dns_dgon -d "${WEBSITE_URL}" --server ${server} --standalone

        if ( [ "$?" != "0" ] )
        then
                ~/.acme.sh/acme.sh --renew --dns dns_dgon -d "${WEBSITE_URL}" --server ${server} --standalone
        fi
fi

if ( [ "${DNS_CHOICE}" = "exoscale" ] )
then
        if ( [ -f ~/.acme.sh/dnsapi/dns_exoscale.sh ] )
        then
                /bin/cp ${BUILD_HOME}/providerscripts/security/ssl/acme/acme-overrides/exoscale.sh ~/.acme.sh/dnsapi/dns_exoscale.sh
        fi
        
        ~/.acme.sh/acme.sh --issue --dns dns_exoscale -d "${WEBSITE_URL}" --server ${server} --standalone 
        
        if ( [ "$?" != "0" ] )
        then
                ~/.acme.sh/acme.sh --issue --dns dns_exoscale -d "${WEBSITE_URL}" --server ${server} --standalone 
        fi
                
fi

if ( [ "${DNS_CHOICE}" = "linode" ] )
then
        if ( [ -f ~/.acme.sh/dnsapi/dns_linode_v4.sh ] )
        then
                /bin/cp ${BUILD_HOME}/providerscripts/security/ssl/acme/acme-overrides/linode.sh ~/.acme.sh/dnsapi/dns_linode_v4.sh
        fi
        ~/.acme.sh/acme.sh --issue --dns dns_linode_v4 -d "${WEBSITE_URL}" --server ${server} --standalone

        if ( [ "$?" != "0" ] )
        then
                ~/.acme.sh/acme.sh --renew --dns dns_linode_v4 -d "${WEBSITE_URL}" --server ${server} --standalone
        fi
fi

if ( [ "${DNS_CHOICE}" = "vultr" ] )
then
        if ( [ -f ~/.acme.sh/dnsapi/dns_vultr.sh ] )
        then
                /bin/cp ${BUILD_HOME}/providerscripts/security/ssl/acme/acme-overrides/vultr.sh ~/.acme.sh/dnsapi/dns_vultr.sh
        fi
        ~/.acme.sh/acme.sh --issue --dns dns_vultr -d "${WEBSITE_URL}" --server ${server} --standalone
        
        if ( [ "$?" != "0" ] )
        then
                ~/.acme.sh/acme.sh --renew --dns dns_vultr -d "${WEBSITE_URL}" --server ${server} --standalone
        fi
        
fi


