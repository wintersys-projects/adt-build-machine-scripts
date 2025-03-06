#!/bin/sh
###################################################################################
# Author: Peter Winter
# Date  : 12/07/2016
# Description : This script will generate an SSL Certificate if one is needed
# A new SSL certificate in two cases, a SSL certificate does not already exist
# or the SSL certificate that does exists is considered close to expiring
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
        /bin/echo "$1" | /usr/bin/tee /dev/fd/3 2>/dev/null
}

website_url="${1}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
SSL_GENERATION_METHOD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSL_GENERATION_METHOD`"
SSL_GENERATION_SERVICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSL_GENERATION_SERVICE`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"

if ( [ "${website_url}" != "" ] )
then
        WEBSITE_URL="${website_url}"
else
        WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
fi

#IP has been added to the DNS provider and now we have to set up the SSL certificate for this webserver

if ( [ "${SSL_GENERATION_METHOD}" = "AUTOMATIC" ] )
then
        if ( [ "${SSL_GENERATION_SERVICE}" = "LETSENCRYPT" ] )
        then
                if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL} ] )
                then
                        /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}
                fi

                status ""
                status "#############################################################################################"
                status "We are setting up an SSL certificate for our webserver so it can establish secure connections"
                status "#############################################################################################"

                # We now need to get our SSL certificate.
                # There's three cases. 1) We have a valid SSL certificate for this domain name on our filesystem and we simply copy that over to our new server
                #                      2) We have an SSL certificate on our filesystem but it is expired, so we need to generate a new one and copy it over.
                #                      3) We have no SSL certificate on our filesystem so we need to generate a new one and copy that over to our server

                if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem ] )
                then
                        if ( [ "`/usr/bin/openssl x509 -checkend 604800 -noout -in ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem | /bin/grep 'Certificate will expire'`" != "" ] )
                        then
                                if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem ] )
                                then
                                        /bin/mv ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem.previous`/bin/date | /bin/sed 's/ //g'`
                                fi

                                if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem ] )
                                then
                                        /bin/mv ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem.previous`/bin/date | /bin/sed 's/ //g'`
                                fi

                                if ( [ -d ${BUILD_HOME}/.lego ] )
                                then
                                        /bin/mv ${BUILD_HOME}/.lego ${BUILD_HOME}/.lego-previous-`/bin/date | /bin/sed 's/ //g'`
                                fi

                                if ( [ ! -d ${BUILD_HOME}/.lego ] )
                                then
                                        /bin/mkdir ${BUILD_HOME}/.lego
                                fi

                                ${BUILD_HOME}/providerscripts/server/ObtainSSLCertificate.sh ${WEBSITE_URL}

                                if ( [ -f ${BUILD_HOME}/.lego/certificates/${WEBSITE_URL}.crt ] && [ -f ${BUILD_HOME}/.lego/certificates/${WEBSITE_URL}.key ] )
                                then
                                        /bin/mv ${BUILD_HOME}/.lego/certificates/${WEBSITE_URL}.crt ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem
                                        /bin/mv ${BUILD_HOME}/.lego/certificates/${WEBSITE_URL}.key ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem
                                        /bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/ssl.pem
                                        /bin/cp ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/ssl.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem
                                        /bin/mv ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/ssl.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem
                                fi


                                if (    [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem ] )
                                then
                                        /bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem
                                        /bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem
                                        status "Have successfully generated a new certificate for your domain ${WEBSITE_URL} because the old certificate has expired"
                                        status "Press <enter> to acknowledge"
                                        if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
                                        then
                                                read x
                                        fi
                                else
                                        status "Something seems to be a bit wrong. We were trying to generate a new SSL ceritificate on the webserver, but, it doesn't seem to have been generated"
                                        status "Can't operate without it, this is a secure system, so have to exit. Please investigate in ${BUILD_HOME}/logs"
                                        /usr/bin/kill -9 $PPID
                                fi
                        fi
                else

                        if ( [ -d ${BUILD_HOME}/.lego ] )
                        then
                                /bin/mv ${BUILD_HOME}/.lego ${BUILD_HOME}/.lego-previous-`/bin/date | /bin/sed 's/ //g'`
                        fi

                        #There was no certificate so generate one and copy it back to the build client for later use
                        ${BUILD_HOME}/providerscripts/server/ObtainSSLCertificate.sh ${WEBSITE_URL}

                        if ( [ -f ${BUILD_HOME}/.lego/certificates/${WEBSITE_URL}.crt ] && [ -f ${BUILD_HOME}/.lego/certificates/${WEBSITE_URL}.key ] )
                        then
                                #All this is about is putting the generated certificate files in the right place on our nice new webserver
                                /bin/mv ${BUILD_HOME}/.lego/certificates/${WEBSITE_URL}.crt ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem
                                /bin/mv ${BUILD_HOME}/.lego/certificates/${WEBSITE_URL}.key ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem
                              #  /bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/ssl.pem
                              #  /bin/cp ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/ssl.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem
                              #  /bin/mv ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/ssl.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem


                                if (    [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem ] )
                                then
                                        /bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem
                                        /bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem
                                        status "Have successfully generated a new certificate for your domain ${WEBSITE_URL} because originally there was no certificate present on your filesystem for me to use"
                                        status "Press <enter> to acknowledge"
                                        if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
                                        then
                                                read x
                                        fi
                                else
                                        status "Something seems to be a bit wrong. We were trying to generate a new SSL ceritificate on the webserver, but, it doesnt seem to have been generated"
                                        status "Cant operate without it, this is a secure system, so have to quit. Please investigate ${BUILD_HOME}/logs"
                                        /usr/bin/kill -9 $PPID
                                fi
                        fi
                fi

        fi
fi
if ( [ "${SSL_GENERATION_METHOD}" = "MANUAL" ] )
then
        response="INPUTNEW"

        if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem ] )
        then
                status "There is a certificate I can use. Do you want me to use that?, or are you going to give me a new one?"
                status "Found a certificate for this domain. For your info, this is its expiry date"
                /usr/bin/openssl x509 -in ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem -noout -enddate
                status "Please enter Y to use the existing one. Anything else to input a new one"
                if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
                then
                        read response
                fi
        fi
        if ( ( [ "${response}" != "Y" ] && [ "${response}" != "y" ] ) || [ "${response}" = "INPUTNEW" ] )
        then
                if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL} ] )
                then
                        /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}
                fi

                status "You have selected the manual method of generating an SSL certificate. This presumes that you have the necessary SSL files from a 3rd party"
                status "Certificate provider. So, here I will have to ask you to input the certificates so that I can pass them over to your servers"
                status "So, mate, please paste your certificate chain here. <ctrl d> when done"
                status "ESSENTIAL - Only copy from the first dash in the file '-' to the last dash in the file. Do not copy any prefixed whitespace or suffixed whitespace"

                fullchain=`cat`
                /bin/echo "${fullchain}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem
                /bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem

                status "Cheers. So, mate, please paste your certifcate key here. <ctrl d> when done"
                status "ESSENTIAL - Only copy from the first dash in the file '-' to the last dash in the file. Do not copy any prefixed whitespace or suffixed whitespace"

                privkey=`cat`
                /bin/echo "${privkey}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem
                /bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem
        fi
fi

if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem ] )
then
        if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem.verify ] )
        then
                /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem.verify 
        fi

        if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem.verify ] )
        then
                /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem.verify 
        fi

        ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem ssl/${WEBSITE_URL}/privkey.pem
        ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem ssl/${WEBSITE_URL}/fullchain.pem
        ${BUILD_HOME}/providerscripts/datastore/configwrapper/GetFromConfigDatastore.sh ssl/${WEBSITE_URL}/privkey.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem.verify 
        ${BUILD_HOME}/providerscripts/datastore/configwrapper/GetFromConfigDatastore.sh ssl/${WEBSITE_URL}/fullchain.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem.verify 

        if ( [ "`/usr/bin/diff ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem.verify ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem`" != "" ] )
        then
                status "SSL Certificate Verification failed for ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem"
                kill -9 $PPID
        fi

        if ( [ "`/usr/bin/diff ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem.verify ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem`" != "" ] )
        then
                status "SSL Certificate Verification failed for ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem"
                kill -9 $PPID
        fi

        /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem.verify 
        /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem.verify 

        status "SSL Certificates successfully validated"
fi
