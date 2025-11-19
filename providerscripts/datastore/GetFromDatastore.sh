#!/bin/sh
#########################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Get a file from a bucket in the datastore. The file is obtained from the
# first s3 bucket in the chain of buckets when replication is being used. In other words
# the first region listed in S3_HOST_BASE in the template is considered to be the authoritative
# bucket 
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

datastore_to_get="${1}"
destination="${2}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
S3_HOST_BASE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_HOST_BASE`"
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
        datastore_cmd="${datastore_tool} --config=/root/.s3cfg-1 --force --recursive --host=https://${host_base} ls s3://"
        datastore_cmd1="${datastore_tool} --config=/root/.s3cfg-1 --force --recursive --host=https://${host_base} get s3://"
elif ( [ "${datastore_tool}" = "/usr/bin/s5cmd" ] )
then
        host_base="`/bin/grep host_base /root/.s5cfg-1 | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`"
        datastore_cmd="${datastore_tool} --credentials-file /root/.s5cfg-1 --endpoint-url https://${host_base} ls s3://"
        datastore_cmd1="${datastore_tool} --credentials-file /root/.s5cfg-1 --endpoint-url https://${host_base} cp s3://"
elif ( [ "${datastore_tool}" = "/usr/bin/rclone" ] )
then
        datastore_cmd="${datastore_tool} --config /root/.config/rclone/rclone.conf-1  s3:"
        datastore_cmd1="${datastore_tool} --config /root/.config/rclone/rclone.conf-1 copy s3:"
fi

if ( [ "${destination}" = "" ] )
then
        destination="."
fi

if ( [ "`${datastore_cmd}${datastore_to_get}`" = "" ] )
then
        /bin/echo "Key does not exist"
else
        count="0"
        while ( [ "`${datastore_cmd1}${datastore_to_get} ${destination} 2>&1 >/dev/null | /bin/grep "ERROR"`" != "" ] && [ "${count}" -lt "5" ] )
        do
                /bin/echo "An error has occured `/usr/bin/expr ${count} + 1` times in script ${0}"
                /bin/sleep 5
                count="`/usr/bin/expr ${count} + 1`"
        done
fi
