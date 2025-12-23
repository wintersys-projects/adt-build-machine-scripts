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

status () {
        /bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
        /bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

website_url="${1}"
auth="${2}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
BUILDOS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS`"
DNS_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_CHOICE`"
SSL_LIVE_CERT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSL_LIVE_CERT`"
DNS_USERNAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_USERNAME`"
DNS_SECURITY_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_SECURITY_KEY`"
SSL_GENERATION_METHOD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSL_GENERATION_METHOD`"
SSL_GENERATION_SERVICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSL_GENERATION_SERVICE`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"
SUDO="/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

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

export GOROOT=/usr/local/go
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

if ( [ ! -f /usr/bin/lego ] )
then
        ${BUILD_HOME}/installscripts/InstallLego.sh ${BUILDOS}
fi

if ( [ ! -d ${BUILD_HOME}/.lego/accounts ] )
then
        /bin/mkdir -p  ${BUILD_HOME}/.lego/accounts 
fi

if ( [ ! -d ${BUILD_HOME}/.lego/certificates ] )
then
        /bin/mkdir -p  ${BUILD_HOME}/.lego/certificates 
fi

server=""
if ( [ "${SSL_GENERATION_METHOD}" = "AUTOMATIC" ] && [ "${SSL_GENERATION_SERVICE}" = "LETSENCRYPT" ] )
then
        if ( [ "${SSL_LIVE_CERT}" = "0" ] )
        then
                server="--server=https://acme-staging-v02.api.letsencrypt.org/directory"
        fi
elif ( [ "${SSL_GENERATION_METHOD}" = "AUTOMATIC" ] && [ "${SSL_GENERATION_SERVICE}" = "ZEROSSL" ] )
then
        server="--server https://acme.zerossl.com/v2/DV90"
fi

status "Generating new SSL certificate for the ${DNS_CHOICE} DNS service"

if ( [ "${DNS_CHOICE}" = "cloudflare" ] )
then
        zonename="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
        zoneid="`${BUILD_HOME}/providerscripts/dns/GetZoneID.sh "${zonename}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"`"

        if ( [ "${zoneid}" = "" ] )
        then
                ${BUILD_HOME}/providerscripts/dns/CreateZone.sh "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${WEBSITE_URL}" "${DNS_CHOICE}"
        fi

        api_token="`/bin/echo ${DNS_SECURITY_KEY} | /usr/bin/awk -F':::' '{print $2}'`"
        command="CLOUDFLARE_DNS_API_TOKEN="${api_token}" /usr/bin/lego --email ${DNS_USERNAME} --domains ${WEBSITE_URL} --dns ${DNS_CHOICE} ${server} --dns.propagation-wait 60s --dns.resolvers '1.1.1.1:53,8.8.8.8:53' --dns-timeout=120 --accept-tos run"
fi

if ( [ "${DNS_CHOICE}" = "digitalocean" ] )
then
        command="DO_AUTH_TOKEN="${DNS_SECURITY_KEY}"  DO_POLLING_INTERVAL=30 DO_PROPAGATION_TIMEOUT=600 /usr/bin/lego --email ${DNS_USERNAME} --domains ${WEBSITE_URL} --dns ${DNS_CHOICE} ${server} --dns.resolvers '1.1.1.1:53,8.8.8.8:53' --dns.propagation-wait 60s --dns-timeout=120 --accept-tos run"
fi

if ( [ "${DNS_CHOICE}" = "exoscale" ] )
then
        EXOSCALE_API_KEY="`/bin/echo ${DNS_SECURITY_KEY} | /usr/bin/awk -F':' '{print $1}'`"
        EXOSCALE_API_SECRET="`/bin/echo ${DNS_SECURITY_KEY} | /usr/bin/awk -F':' '{print $2}'`"
        command="EXOSCALE_API_KEY=${EXOSCALE_API_KEY} EXOSCALE_API_SECRET=${EXOSCALE_API_SECRET} EXOSCALE_POLLING_INTERVAL=30 EXOSCALE_PROPAGATION_TIMEOUT=600 /usr/bin/lego --email ${DNS_USERNAME} --dns ${DNS_CHOICE} ${server} --domains ${WEBSITE_URL} --dns.propagation-wait 60s --dns.resolvers '1.1.1.1:53,8.8.8.8:53' --dns-timeout=120 --accept-tos run"
fi

if ( [ "${DNS_CHOICE}" = "linode" ] )
then
        #LINODE_TOKEN="`/bin/echo ${DNS_SECURITY_KEY} | /usr/bin/awk -F':' '{print $1}'`"
        command="LINODE_TOKEN=${DNS_SECURITY_KEY}  LINODE_POLLING_INTERVAL=30 LINODE_PROPAGATION_TIMEOUT=600 LINODE_HTTP_TIMEOUT=120 /usr/bin/lego --email ${DNS_USERNAME} --dns ${DNS_CHOICE} ${server} --domains ${WEBSITE_URL} --dns-timeout=120 --cert.timeout 120   --dns.propagation-wait 60s --dns.resolvers '1.1.1.1:53,8.8.8.8:53' --accept-tos run"
fi

if ( [ "${DNS_CHOICE}" = "vultr" ] )
then
        #VULTR_API_KEY="`/bin/echo ${DNS_SECURITY_KEY} | /usr/bin/awk -F':' '{print $1}'`"
        command="VULTR_API_KEY=${DNS_SECURITY_KEY} VULTR_POLLING_INTERVAL=30 VULTR_PROPAGATION_TIMEOUT=600  LEGO_DISABLE_CNAME_SUPPORT=true /usr/bin/lego --email ${DNS_USERNAME} --dns ${DNS_CHOICE} ${server} --domains ${WEBSITE_URL} --dns-timeout=120 --dns.propagation-wait 60s --dns.resolvers '1.1.1.1:53,8.8.8.8:53' --accept-tos run"
       
fi

if ( [ "`/usr/bin/stat /usr/bin/lego | /bin/grep "File" | /usr/bin/awk '{print $NF}'`" = "/snap/bin/lego" ] )
then
        if ( [ -f /var/snap/lego/common/.lego/certificates/${WEBSITE_URL}.issuer.crt ] )
        then
                if ( [ ! -d ${BUILD_HOME}/.lego/certificates ] )
                then
                        /bin/mkdir -p ${BUILD_HOME}/.lego/certificates
                fi
                /bin/cp /var/snap/lego/common/.lego/certificates/${WEBSITE_URL}.issuer.crt ${BUILD_HOME}/.lego/certificates/${WEBSITE_URL}.issuer.crt
        fi
fi

if ( [ ! -f ${BUILD_HOME}/.lego/certificates/${WEBSITE_URL}.issuer.crt ] )
then
        status "Please wait, valid certificate not found, trying to issue SSL certificate for your domain ${WEBSITE_URL}"
        eval ${command}
        count="1"
        while ( [ "`/usr/bin/find ${BUILD_HOME}/.lego/certificates/${WEBSITE_URL}.issuer.crt -mmin -5 2>/dev/null`" = "" ] && [ "${count}" -lt "5" ] )
        do
                count="`/usr/bin/expr ${count} + 1`"
                /bin/sleep 5
                status "Failed to generate SSL Certificate, this is attempt ${count}"
                eval ${command}
        done
fi

if ( [ "${count}" = "5" ] )
then
        status "FAILED TO ISSUE SSL CERTIFICATE  (what is SSL_LIVE_CERT set to and have you hit an issuance limit for ${WEBSITE_URL}?)"
        status "Will have to exit, can't continue without the SSL certificate being set up"
        /bin/touch /tmp/END_IT_ALL
fi
