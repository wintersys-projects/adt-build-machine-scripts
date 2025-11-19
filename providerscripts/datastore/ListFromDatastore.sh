#!/bin/sh
#########################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Get a file from a bucket in the datastore
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
        config_file="`/bin/grep -H ${datastore_region} /root/.s3cfg-* | /usr/bin/awk -F':' '{print $1}'`"
		if ( [ "${file_to_list}" = "" ] )
        then
        	datastore_cmd="${datastore_tool} --config=${config_file} --recursive ls"
        else
        	datastore_cmd="${datastore_tool} --config=${config_file} --recursive ls s3://"
        fi
elif ( [ "${datastore_tool}" = "/usr/bin/s5cmd" ] )
then
        config_file="`/bin/grep -H ${datastore_region} /root/.s5cfg-* | /usr/bin/awk -F':' '{print $1}'`"
        host_base="`/bin/grep host_base ${config_file} | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
		if ( [ "${file_to_list}" = "" ] )
        then
        	datastore_cmd="${datastore_tool} --credentials-file ${config_file} --endpoint-url https://${host_base} ls"
        else
        	datastore_cmd="${datastore_tool} --credentials-file ${config_file} --endpoint-url https://${host_base} ls s3://"
        fi
elif ( [ "${datastore_tool}" = "/usr/bin/rclone" ] )
then
        config_file="`/bin/grep -H ${datastore_region} /root/.config/rclone/rclone.conf-* | /usr/bin/awk -F':' '{print $1}'`"

        if ( [ "${file_to_list}" = "" ] )
        then
                datastore_cmd="${datastore_tool} --config ${config_file} lsd s3:"
        else
                datastore_cmd="${datastore_tool} --config ${config_file} ls s3:"
        fi
fi

if ( [ "${file_to_list}" = "" ] )
then
	${datastore_cmd} 2>/dev/null
else
	${datastore_cmd} ${file_to_list} 2>/dev/null
fi


