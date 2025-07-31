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

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
SYSTEM_FROMEMAIL_ADDRESS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'SYSTEM_FROMEMAIL_ADDRESS'`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'WEBSITE_URL'`"
DNS_SECURITY_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_SECURITY_KEY`"


${BUILD_HOME}/installscripts/InstallAcme.sh ${SYSTEM_FROMEMAIL_ADDRESS}

~/.acme.sh/acme.sh --register-account -m ${DNS_SECURITY_KEY}

if ( [ "${DNS_CHOICE}" = "cloudflare" ] )
then
	:
fi

if ( [ "${DNS_CHOICE}" = "digitalocean" ] )
then
	export DO_API_KEY=${DNS_SECURITY_KEY} ~/.acme.sh/acme.sh --issue -dns dns_dgon -d ${WEBSITE_URL}
fi

if ( [ "${DNS_CHOICE}" = "exoscale" ] )
then
	:
fi

if ( [ "${DNS_CHOICE}" = "linode" ] )
then
	export LINODE_V4_API_KEY=${DNS_SECURITY_KEY} ~/.acme.sh/acme.sh --issue --dns dns_linode_v4 -d ${WEBSITE_URL}
fi

if ( [ "${DNS_CHOICE}" = "vultr" ] )
then
	:
fi
