#!/bin/sh
#########################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: List a file in the config datastore
#########################################################################################
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
#########################################################################################
#########################################################################################
#set -x

file_to_list="${1}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
S3_HOST_BASE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_HOST_BASE`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
TOKEN="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1 | /usr/bin/tr '[:upper:]' '[:lower:]'`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
config_bucket="`/bin/echo "${WEBSITE_URL}"-config | /bin/sed 's/\./-/g'`-${TOKEN}"

datastore_region="`/bin/echo "${S3_HOST_BASE}" | /bin/sed 's/|/ /g' | /usr/bin/awk '{print $1}' | /bin/sed -E 's/(.digitaloceanspaces.com|sos-|.exo.io|.linodeobjects.com|.vultrobjects.com)//g'`"
datastore_tool=""

if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s3cmd`" != "" ] )
then
        datastore_tool="/usr/bin/s3cmd"
elif ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s5cmd`" != "" ] )
then
        datastore_tool="/usr/bin/s5cmd"
elif ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep rclone`" != "" ] )
then
        datastore_tool="/usr/bin/rclone"
fi

if ( [ "${datastore_tool}" = "/usr/bin/s3cmd" ] )
then
        host_base="`/bin/grep host_base /root/.s3cfg-1 | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_cmd="${datastore_tool} --config=/root/.s3cfg-1 --force --recursive --host=https://${host_base} ls s3://${config_bucket}/"
elif ( [ "${datastore_tool}" = "/usr/bin/s5cmd" ] )
then
        host_base="`/bin/grep host_base /root/.s5cfg-1 | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_cmd="${datastore_tool} --credentials-file /root/.s5cfg-1 --endpoint-url https://${host_base} ls s3://${config_bucket}/"
elif ( [ "${datastore_tool}" = "/usr/bin/rclone" ] )
then
        host_base="`/bin/grep ^endpoint /root/.config/rclone/rclone.conf-1 | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        if ( [ "${file_to_list}" = "" ] )
        then
                datastore_cmd="${datastore_tool} --config /root/.config/rclone/rclone.conf-1  --s3-endpoint ${host_base} lsd s3:${config_bucket}/"
        else
                datastore_cmd="${datastore_tool} --config /root/.config/rclone/rclone.conf-1  --s3-endpoint ${host_base} ls s3:${config_bucket}/"
        fi
fi

${datastore_cmd}${file_to_list} 



