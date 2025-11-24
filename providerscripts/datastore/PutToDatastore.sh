#!/bin/sh 
####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Put a file to a bucket in the datastore. The file is obtained from the filesystem.
# and replicated according to the replication configuration set by S3_HOST_BASE
#######################################################################################
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
######################################################################################
######################################################################################
set -x

file_to_put="${1}"
datastore_to_put_in="${2}"
delete="${3}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
S3_ACCESS_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_ACCESS_KEY`"
no_tokens="`/bin/echo "${S3_ACCESS_KEY}" | /usr/bin/fgrep -o '|' | /usr/bin/wc -l`"
no_tokens="`/usr/bin/expr ${no_tokens} + 1`"
count="1"

while ( [ "${count}" -le "${no_tokens}" ] )
do
        ${BUILD_HOME}/providerscripts/datastore/PerformPutToDatastore.sh ${file_to_put} ${datastore_to_put_in} ${delete} ${count}
        count="`/usr/bin/expr ${count} + 1`"
done
