#!/bin/sh
#####################################################################################
# Description: Direct the request for a new SSL certificate to the configured provider
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

BUILD_HOME="`/bin/cat /home/buildhome.dat`"


if ( [ "`/bin/grep "^SSLCERTCLIENT:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep lego`" != "" ] )
then
	${BUILD_HOME}/providerscripts/security/ssl/lego/ObtainSSLCertificate.sh ${website_url}
elif ( [ "`/bin/grep "^SSLCERTCLIENT:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep acme`" != "" ] )
then
	${BUILD_HOME}/providerscripts/security/ssl/acme/ObtainSSLCertificate.sh ${website_url}
fi
