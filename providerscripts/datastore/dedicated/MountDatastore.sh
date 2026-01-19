#!/bin/sh 
####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Mount a datastore to S3 and replicate it to additional provider/regions
# if replication is configured to be active. 
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
#set -x

datastore_to_mount="${1}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
S3_ACCESS_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_ACCESS_KEY`"
no_tokens="`/bin/echo "${S3_ACCESS_KEY}" | /usr/bin/fgrep -o '|' | /usr/bin/wc -l`"
no_tokens="`/usr/bin/expr ${no_tokens} + 1`"
count="1"

#Special case of the for the build machine authorisation bucket (want to tie authorisation to the same region as the build machine is running in)
if ( [ "`/bin/echo ${datastore_to_mount} | /bin/grep 'authip-adt-allowed'`" != "" ] )
then
        no_tokens="1"
fi

while ( [ "${count}" -le "${no_tokens}" ] )
do
        ${BUILD_HOME}/providerscripts/datastore/dedicated/PerformDatastoreMount.sh ${datastore_to_mount} ${count}
        count="`/usr/bin/expr ${count} + 1`"
done
