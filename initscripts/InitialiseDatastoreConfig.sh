#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : # Description : This will initialise the datastore configuration file 
# for the datastore provider you are using
# Templates are held in the "${BUILD_HOME}/initscripts/configfiles/datastore" subdirectory
##################################################################################
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
####################################################################################
####################################################################################
#set -x

status () {
        /bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
        /bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
BUILDOS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS`"
S3_ACCESS_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_ACCESS_KEY`"
S3_SECRET_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_SECRET_KEY`"
S3_LOCATION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_LOCATION`"
S3_HOST_BASE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_HOST_BASE`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
MULTI_REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh MULTI_REGION`"
PRIMARY_REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRIMARY_REGION`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"

if ( [ "${1}" != "" ] )
then
        if ( [ "${1}" -eq "${1}" 2>/dev/null ] )
        then
                count="${1}"
        else
                S3_ACCESS_KEY="${1}"
        fi
fi

if ( [ "${2}" != "" ] )
then
        S3_SECRET_KEY="${2}"
fi

if ( [ "${3}" != "" ] )
then
        S3_LOCATION="${3}"
fi

if ( [ "${4}" != "" ] )
then
        S3_HOST_BASE="${4}"
fi

if ( [ "${5}" != "" ] )
then
        count="${5}"
fi

status ""
status "##############################"
status "Configuring datastore tools..."
status "##############################"

#${BUILD_HOME}/installscripts/InstallDatastoreTools.sh "${BUILDOS}" 2>&1 >/dev/null

if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s3cmd`" != "" ] )
then
        if ( [ -f ${BUILD_HOME}/.s3cfg-${count} ] )
        then
                /bin/rm ${BUILD_HOME}/.s3cfg-${count}
        fi

        /bin/cp ${BUILD_HOME}/initscripts/configfiles/datastore/s3-cfg.tmpl  ${BUILD_HOME}/.s3cfg-${count}

        if ( [ "${S3_ACCESS_KEY}" != "" ] )
        then
                /bin/sed -i "s/XXXXACCESSKEYXXXX/${S3_ACCESS_KEY}/" ${BUILD_HOME}/.s3cfg-${count}
        else 
                status "Couldn't find the access key for your datastore, can't go on without it, will have to exit"
                /bin/touch /tmp/END_IT_ALL

        fi

        if ( [ "${S3_SECRET_KEY}" != "" ] )
        then
                /bin/sed -i "s;XXXXSECRETKEYXXXX;${S3_SECRET_KEY};" ${BUILD_HOME}/.s3cfg-${count}
        else 
                status "Couldn't find the secret key for your datastore, can't go on without it, will have to exit"
                /bin/touch /tmp/END_IT_ALL
        fi

        if ( [ "${S3_LOCATION}" != "" ] )
        then
                /bin/sed -i "s/XXXXLOCATIONXXXX/${S3_LOCATION}/" ${BUILD_HOME}/.s3cfg-${count}
        else 
                status "Couldn't find the secret key for your datastore, can't go on without it, will have to exit"  
                /bin/touch /tmp/END_IT_ALL
        fi

        if ( [ "${S3_HOST_BASE}" != "" ] )
        then
                /bin/sed -i "s/XXXXHOSTBASEXXXX/${S3_HOST_BASE}/" ${BUILD_HOME}/.s3cfg-${count}

                if ( [ "`/bin/grep '^alias s3cmd=' /root/.bashrc`" = "" ] )
                then
                        /bin/echo "alias s3cmd='/usr/bin/s3cmd --config=/root/.s3cfg-1 --host=https://${S3_HOST_BASE} '" >> /root/.bashrc
                fi
        else 
                status "Couldn't find the hostbase parameter for your datastore, can't go on without it, will have to exit"
                /bin/touch /tmp/END_IT_ALL
        fi

        if ( [ -f /root/.s3cfg-${count} ] )
        then
                /bin/rm /root/.s3cfg-${count}
        fi

        /bin/cp ${BUILD_HOME}/.s3cfg-${count} /root/.s3cfg-${count}
fi

if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s5cmd`" != "" ] )
then
        if ( [ -f ${BUILD_HOME}/.s5cfg-${count} ] )
        then
                /bin/rm ${BUILD_HOME}/.s5cfg-${count}
        fi

        if ( [ "${S3_ACCESS_KEY}" != "" ] )
        then
                /bin/echo "[default]" > ${BUILD_HOME}/.s5cfg-${count}
                /bin/echo "aws_access_key_id = ${S3_ACCESS_KEY}" >> ${BUILD_HOME}/.s5cfg-${count}
        else 
                status "Couldn't find the access key for your datastore, can't go on without it, will have to exit"
                /bin/touch /tmp/END_IT_ALL
        fi

        if ( [ "${S3_SECRET_KEY}" != "" ] )
        then
                /bin/echo "aws_secret_access_key = ${S3_SECRET_KEY}" >> ${BUILD_HOME}/.s5cfg-${count}
        else 
                status "Couldn't find the secret key for your datastore, can't go on without it, will have to exit"
                /bin/touch /tmp/END_IT_ALL
        fi

        if ( [ "${S3_HOST_BASE}" != "" ] )
        then
                /bin/echo "host_base = ${S3_HOST_BASE}" >> ${BUILD_HOME}/.s5cfg-${count}

                if ( [ "`/bin/grep '^alias s5cmd=' /root/.bashrc`" = "" ] )
                then
                        /bin/echo "alias s5cmd='/usr/bin/s5cmd --credentials-file /root/.s5cfg-1 --endpoint-url https://`/bin/echo ${S3_HOST_BASE} | /usr/bin/awk -F'|' '{print $1}'` '" >> /root/.bashrc
                fi
        else 
                status "Couldn't find the hostbase parameter for your datastore, can't go on without it, will have to exit"
                /bin/touch /tmp/END_IT_ALL
        fi

        if ( [ -f /root/.s5cfg-${count} ] )
        then
                /bin/rm /root/.s5cfg-${count}
        fi

        /bin/cp ${BUILD_HOME}/.s5cfg-${count} /root/.s5cfg-${count}
fi


if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep rclone`" != "" ] )
then
        if ( [ -f ${BUILD_HOME}/.rclone.cfg-${count} ] )
        then
                /bin/rm ${BUILD_HOME}/.rclone.cfg-${count}
        fi

        /bin/cp ${BUILD_HOME}/initscripts/configfiles/datastore/rclone-cfg.tmpl ${BUILD_HOME}/.rclone.cfg-${count}

        if ( [ "${S3_ACCESS_KEY}" != "" ] )  
        then
                /bin/sed -i "s/XXXXACCESSKEYXXXX/${S3_ACCESS_KEY}/" ${BUILD_HOME}/.rclone.cfg-${count}
        else
                /bin/echo "Couldn't find the S3_ACCESS_KEY setting"
                /bin/touch /tmp/END_IT_ALL
        fi

        if ( [ "${S3_SECRET_KEY}" != "" ] )
        then
                /bin/sed -i "s/XXXXSECRETKEYXXXX/${S3_SECRET_KEY}/" ${BUILD_HOME}/.rclone.cfg-${count}
        else
                /bin/echo "Couldn't find the S3_SECRET_KEY setting" 
                /bin/touch /tmp/END_IT_ALL
        fi

        if ( [ "${S3_LOCATION}" != "" ] )
        then
                /bin/sed -i "s/XXXXLOCATIONXXXX/${S3_LOCATION}/" ${BUILD_HOME}/.rclone.cfg-${count}
        else
                /bin/echo "Couldn't find the S3_LOCATION setting" 
                /bin/touch /tmp/END_IT_ALL
        fi

        if ( [ "${S3_HOST_BASE}" != "" ] )
        then
                /bin/sed -i "s/XXXXHOSTBASEXXXX/${S3_HOST_BASE}/" ${BUILD_HOME}/.rclone.cfg-${count}
                if ( [ "`/bin/grep '^alias rclone=' /root/.bashrc`" = "" ] )
                then
                        /bin/echo "alias rclone='/usr/bin/rclone --config /root/.config/rclone/rclone.conf-1 --s3-endpoint https://`/bin/echo ${S3_HOST_BASE} | /usr/bin/awk -F'|' '{print $1}'` '" >> /root/.bashrc
                fi
        else
                /bin/echo "Couldn't find the S3_HOST_BASE setting" 
                /bin/touch /tmp/END_IT_ALL
        fi
        if ( [ ! -d /root/.config/rclone ] )
        then
                /bin/mkdir -p /root/.config/rclone
        fi

        if ( [ ! -d ${BUILD_HOME}/.config/rclone ] )
        then
                /bin/mkdir -p ${BUILD_HOME}/.config/rclone
        fi

        /bin/cp ${BUILD_HOME}/.rclone.cfg-${count} /root/.config/rclone/rclone.conf-${count}
        /bin/cp ${BUILD_HOME}/.rclone.cfg-${count} ${BUILD_HOME}/.config/rclone/rclone.conf-${count}

fi

${BUILD_HOME}/providerscripts/datastore/dedicated/MountDatastore.sh "1$$agile" 3>&1 2>/dev/null
${BUILD_HOME}/providerscripts/datastore/dedicated/DeleteDatastore.sh "1$$agile" 3>&1 2>/dev/null

if ( [ "$?" != "0" ] )
then
        status "I can't access your datastore, it isn't possible to continue. Please check the following settings in the template you are using:"
        status "S3_ACCESS_KEY,S3_SECRET_KEY,S3_LOCATION and S3_HOST_BASE"
        /bin/touch /tmp/END_IT_ALL
fi

if ( [ "${MULTI_REGION}" = "1" ] && [ "${PRIMARY_REGION}" = "1" ]  )
then
        multi_region_bucket="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`-multi-region"
        if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${multi_region_bucket}`" != "" ] && [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
        then
                status "####################HALT################################"
                status "You are deploying a primary region, are you sure as I am about to delete existing multi-region"
                status "credentials and any existing primary region configuration are you sure 100%? (Y|y), anything else to exit"
                status "####################HALT###############################"
                read response
                if ( [ "`/bin/echo "Y y" | /bin/grep ${response}`" = "" ] )
                then
                        /bin/touch /tmp/END_IT_ALL
                fi 
        fi
        if ( [ "`${BUILD_HOME}/providerscripts/datastore/dedicated/ListFromDatastore.sh ${multi_region_bucket}`" != "" ] )
        then
                ${BUILD_HOME}/providerscripts/datastore/dedicated/DeleteFromDatastore.sh ${multi_region_bucket}/*
        else
                ${BUILD_HOME}/providerscripts/datastore/dedicated/MountDatastore.sh "${multi_region_bucket}"
        fi
fi

website_bucket="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`"
if ( [ "${MULTI_REGION}" = "0" ] || ( [ "${MULTI_REGION}" = "1" ] && [ "${PRIMARY_REGION}" = "1" ] ) )
then
        for bucket in `${BUILD_HOME}/providerscripts/datastore/dedicated/ListDatastore.sh | /bin/grep "${website_bucket}-config" | grep -Eo "${website_bucket}.*(/|$)" | /usr/bin/uniq`
        do
                ${BUILD_HOME}/providerscripts/datastore/dedicated/DeleteFromDatastore.sh ${bucket}/* "yes"
                ${BUILD_HOME}/providerscripts/datastore/config/toolkit/DeleteConfigDatastore.sh ${bucket}
        done
fi
