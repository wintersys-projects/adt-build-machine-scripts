#!/bin/sh
###################################################################################
# Author: Peter Winter
# Date  : 12/07/2016
# Description : This will provision and arrange a newly provisioned SSL certificate
# when using a manul certificate
###################################################################################
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
        /bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
        /bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

website_url="${1}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
DNS_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_CHOICE`"


if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url} ] )
then
        /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}
fi

status ""
status "#############################################################################################"
status "We are setting up an SSL certificate for our webserver so it can establish secure connections"
status "#############################################################################################"

# We now need to get our SSL certificate.
# There are three cases. 1) We have a valid SSL certificate for this domain name on our filesystem and we simply copy that over to our new server
#                      2) We have an SSL certificate on our filesystem but it is expired, so we need to generate a new one and copy it over.
#                      3) We have no SSL certificate on our filesystem so we need to generate a new one and copy that over to our server

if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/fullchain.pem ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/privkey.pem ] )
then
        if ( [ "`/usr/bin/openssl x509 -checkend 604800 -noout -in ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/privkey.pem | /bin/grep 'Certificate will expire'`" != "" ] )
        then
                if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/fullchain.pem ] )
                then
                        /bin/mv ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/fullchain.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/fullchain.pem.previous`/bin/date | /bin/sed 's/ //g'`
                fi

                if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/privkey.pem ] )
                then
                        /bin/mv ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/privkey.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/privkey.pem.previous`/bin/date | /bin/sed 's/ //g'`
                fi

                if ( [ -d ${BUILD_HOME}/.lego ] )
                then
                        /bin/mv ${BUILD_HOME}/.lego ${BUILD_HOME}/.lego-previous-`/bin/date | /bin/sed 's/ //g'`
                fi

                if ( [ ! -d ${BUILD_HOME}/.lego ] )
                then
                        /bin/mkdir ${BUILD_HOME}/.lego
                fi

                ${BUILD_HOME}/providerscripts/security/ssl/manual/ObtainSSLCertificate.sh ${website_url}


                if ( [ -f ${BUILD_HOME}/.lego/certificates/${website_url}.crt ] && [ -f ${BUILD_HOME}/.lego/certificates/${website_url}.key ] )
                then
                        /bin/mv ${BUILD_HOME}/.lego/certificates/${website_url}.crt ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/fullchain.pem
                        /bin/mv ${BUILD_HOME}/.lego/certificates/${website_url}.key ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/privkey.pem
                fi

                if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/fullchain.pem ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/privkey.pem ] )
                then
                        /bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/privkey.pem
                        /bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/fullchain.pem
                        status "Have successfully generated a new certificate for your domain ${website_url} because the old certificate has expired"
                        status "Press <enter> to acknowledge"
                        if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
                        then
                                read x
                        fi
                else
                        status "Something seems to be a bit wrong. We were trying to generate a new SSL ceritificate on the webserver, but, it doesn't seem to have been generated"
                        status "Can't operate without it, this is a secure system, so have to exit. Please investigate in ${BUILD_HOME}/logs"
                        /bin/touch /tmp/END_IT_ALL
                fi
        fi
else
        if ( [ -d ${BUILD_HOME}/.lego ] )
        then
                /bin/mv ${BUILD_HOME}/.lego ${BUILD_HOME}/.lego-previous-`/bin/date | /bin/sed 's/ //g'`
        fi

        ${BUILD_HOME}/providerscripts/security/ssl/manual/ObtainSSLCertificate.sh ${website_url}

        if ( [ -f ${BUILD_HOME}/.lego/certificates/${website_url}.crt ] && [ -f ${BUILD_HOME}/.lego/certificates/${website_url}.key ] )
        then
                #All this is about is putting the generated certificate files in the right place on our nice new webserver
                /bin/mv ${BUILD_HOME}/.lego/certificates/${website_url}.crt ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/fullchain.pem
                /bin/mv ${BUILD_HOME}/.lego/certificates/${website_url}.key ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/privkey.pem

                if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/fullchain.pem ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/privkey.pem ] )
                then
                        /bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/privkey.pem
                        /bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${website_url}/fullchain.pem
                        status "Have successfully generated a new certificate for your domain ${website_url} because originally there was no certificate present on your filesystem for me to use"
                        status "Press <enter> to acknowledge"
                        if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
                        then
                                read x
                        fi
                else
                        status "Something seems to be a bit wrong. We were trying to generate a new SSL ceritificate on the webserver, but, it doesnt seem to have been generated"
                        status "Cant operate without it, this is a secure system, so have to quit. Please investigate ${BUILD_HOME}/logs"
                        /bin/touch /tmp/END_IT_ALL

                fi
        fi
fi
