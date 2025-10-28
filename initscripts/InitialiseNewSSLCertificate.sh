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
        /bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
        /bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}


website_url="${1}"
auth="${2}"
build_identifier="${3}"
cloudhost="${4}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

if ( [ "`/usr/bin/pwd`" != "${BUILD_HOME}" ] )
then
        cd ${BUILD_HOME}
fi

SSL_GENERATION_METHOD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSL_GENERATION_METHOD`"
SSL_GENERATION_SERVICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSL_GENERATION_SERVICE`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
DNS_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_CHOICE`"


if ( [ "${build_identifier}" != "" ] )
then
        BUILD_IDENTIFIER="${build_identifier}"
        out_file="cron-logging-out"
        exec 1>>/root/logs/${out_file}
        err_file="cron-logging-err"
        exec 2>>/root/logs/${err_file}
        /bin/cp /dev/null /root/logs/${out_file}
        /bin/cp /dev/null /root/logs/${err_file}
        if ( [ "${HARDCORE}" = "1" ] )
        then
                /bin/touch /root/HARDCORE
        fi
fi

if ( [ "${cloudhost}" != "" ] )
then
        CLOUDHOST="${cloudhost}"
fi

if ( [ "${website_url}" != "" ] && [ "${website_url}" != "none" ] )
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

generate_new="0"

if ( [ "${SSL_GENERATION_SERVICE}" = "LETSENCRYPT" ] )
then
        service_token="lets"
elif ( [ "${SSL_GENERATION_SERVICE}" = "ZEROSSL" ] )
then
        service_token="zero"
fi

ssl_bucket="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`"
ssl_bucket="${ssl_bucket}-${DNS_CHOICE}-${service_token}-ssl"

${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh ${ssl_bucket}

if ( ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${ssl_bucket}/fullchain.pem`" != "" ] && [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${ssl_bucket}/privkey.pem`" != "" ] ) || ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem ] ) )
then
        if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL} ] )
        then
                /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}
        fi

        #Override whatever is on the filesystem (if anything) with what is in the datastore
        if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${ssl_bucket}/fullchain.pem`" != "" ] && [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${ssl_bucket}/privkey.pem`" != "" ] ) 
        then
                status "Found existing SSL certificates in the datastore for website url ${WEBSITE_URL} trying to use those to save time and reissuance"
                ${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${ssl_bucket}/fullchain.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}
                ${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${ssl_bucket}/privkey.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}
        fi
        
        status "Checking that current certificate is not expired"
        if ( [ -s ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem ] && [ -s ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem ] )
        then
                if ( [ "`/usr/bin/openssl x509 -checkend 604800 -noout -in ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem | /bin/grep 'Certificate will expire'`" != "" ] )
                then
                        status "Taking action, existing certificate is expired (has 7 days or less left on its validity)"
                        /bin/mv ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem.$$.old
                        /bin/mv ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem.$$.old
                        generate_new="1"
                else
                        status "Existing certificate found to be valid, no action necessary, reusing it"
                fi
        else
                status "Valid certicate not found"
                /bin/touch /tmp/END_IT_ALL
        fi
fi

if ( [ "${website_url}" = "none" ] || ( [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem ] || [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem ] ) )
then
        generate_new="1"
elif ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem ] )
then
        ${BUILD_HOME}/providerscripts/datastore/PutToDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem ${ssl_bucket}/fullchain.pem
        ${BUILD_HOME}/providerscripts/datastore/PutToDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem ${ssl_bucket}/privkey.pem
        ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem ssl/${WEBSITE_URL}/privkey.pem
        ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem ssl/${WEBSITE_URL}/fullchain.pem
fi

if ( [ "${generate_new}" = "1" ] )
then
        #IP has been added to the DNS provider and now we have to set up the SSL certificate for this webserver

        if ( [ "${SSL_GENERATION_METHOD}" = "AUTOMATIC" ] )
        then
                if ( [ "${SSL_GENERATION_SERVICE}" = "LETSENCRYPT" ] )
                then
                        if ( [ "`/bin/grep "^SSLCERTCLIENT:lego" ${BUILD_HOME}/builddescriptors/buildstyles.dat`" = "" ] )
                        then
                                if ( [ "`/bin/grep "^SSLCERTCLIENT:" ${BUILD_HOME}/builddescriptors/buildstyles.dat`" != "" ] )
                                then
                                        /bin/sed -i 's/SSLCERTCLIENT:.*/SSLCERTCLIENT:lego/g' ${BUILD_HOME}/builddescriptors/buildstyles.dat
                                else
                                        /bin/echo "SSLCERTCLIENT:lego" >> ${BUILD_HOME}/builddescriptors/buildstyles.dat
                                fi
                        fi

                        ${BUILD_HOME}/providerscripts/security/ssl/lego/ProvisionAndArrangeSSLCertificate.sh ${WEBSITE_URL} ${auth}
                fi

                if ( [ "${SSL_GENERATION_SERVICE}" = "ZEROSSL" ] )
                then
                        if ( [ "`/bin/grep "^SSLCERTCLIENT:acme" ${BUILD_HOME}/builddescriptors/buildstyles.dat`" = "" ] )
                        then
                                if ( [ "`/bin/grep "^SSLCERTCLIENT:" ${BUILD_HOME}/builddescriptors/buildstyles.dat`" != "" ] )
                                then
                                        /bin/sed -i 's/SSLCERTCLIENT:.*/SSLCERTCLIENT:acme/g' ${BUILD_HOME}/builddescriptors/buildstyles.dat
                                else
                                        /bin/echo "SSLCERTCLIENT:acme" >> ${BUILD_HOME}/builddescriptors/buildstyles.dat
                                fi
                        fi

                        ${BUILD_HOME}/providerscripts/security/ssl/acme/ProvisionAndArrangeSSLCertificate.sh ${WEBSITE_URL} ${auth}
                        /bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem
                fi

                if ( [ "${SSL_GENERATION_METHOD}" = "MANUAL" ] )
                then
                        ${BUILD_HOME}/providerscripts/security/ssl/manual/ProvisionAndArrangeSSLCertificate.sh ${WEBSITE_URL} ${auth}
                fi
        fi

        if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem ] )
        then
                if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem.verify ] )
                then
                        /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem.verify 
                fi

                if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem.verify ] )
                then
                        /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem.verify 
                fi

                ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem ssl/${WEBSITE_URL}/privkey.pem
                ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem ssl/${WEBSITE_URL}/fullchain.pem
                ${BUILD_HOME}/providerscripts/datastore/configwrapper/GetFromConfigDatastore.sh ssl/${WEBSITE_URL}/privkey.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem.verify
                ${BUILD_HOME}/providerscripts/datastore/configwrapper/GetFromConfigDatastore.sh ssl/${WEBSITE_URL}/fullchain.pem ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem.verify

                if ( [ "`/usr/bin/diff ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem.verify ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem`" != "" ] )
                then
                        status "SSL Certificate Verification failed for ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem"
                        /bin/touch /tmp/END_IT_ALL

                fi

                if ( [ "`/usr/bin/diff ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem.verify ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem`" != "" ] )
                then
                        status "SSL Certificate Verification failed for ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem"
                        /bin/touch /tmp/END_IT_ALL
                fi

                /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem.verify 
                /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem.verify 

                status "SSL Certificates successfully validated"

                ${BUILD_HOME}/providerscripts/datastore/SyncDatastore.sh ${ssl_bucket}/fullchain.pem ${ssl_bucket}/fullchain.pem.$$.old
                ${BUILD_HOME}/providerscripts/datastore/SyncDatastore.sh ${ssl_bucket}/privkey.pem ${ssl_bucket}/privkey.pem.$$.old
                ${BUILD_HOME}/providerscripts/datastore/DeleteFromDatastore.sh ${ssl_bucket}/fullchain.pem
                ${BUILD_HOME}/providerscripts/datastore/DeleteFromDatastore.sh ${ssl_bucket}/privkey.pem
                ${BUILD_HOME}/providerscripts/datastore/PutToDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/fullchain.pem ${ssl_bucket}/fullchain.pem
                ${BUILD_HOME}/providerscripts/datastore/PutToDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${service_token}/${WEBSITE_URL}/privkey.pem ${ssl_bucket}/privkey.pem
                
                if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${ssl_bucket}/fullchain.pem`" = "" ] || [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${ssl_bucket}/privkey.pem`" = "" ] )
                then
                        ${BUILD_HOME}/providerscripts/datastore/SyncDatastore.sh ${ssl_bucket}/privkey.pem.$$.old ${ssl_bucket}/privkey.pem
                        ${BUILD_HOME}/providerscripts/datastore/SyncDatastore.sh ${ssl_bucket}/privkey.pem.$$.old ${ssl_bucket}/privkey.pem
                fi
        else
                status "SSL Certificate not successfully provisioned/generated"
                /bin/touch /tmp/END_IT_ALL
        fi
fi

if ( [ -f /root/HARDCORE ] && [ "${website_url}" = "none" ] )
then
        /bin/rm /root/HARDCORE
fi
