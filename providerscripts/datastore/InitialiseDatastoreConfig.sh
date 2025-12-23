#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: There are various tools that can be integrated with S3 storage providers
# and here is where they are configured ready for use. The credentials and configurations
# necessary for each class of tool are configured here such that the servers can communicate
# with the S3 service in any manner. 
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
####################################################################################
####################################################################################
#set -x

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
S3_ACCESS_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_ACCESS_KEY`"
S3_SECRET_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_SECRET_KEY`"
S3_LOCATION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_LOCATION`"
S3_HOST_BASE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_HOST_BASE`"
no_tokens="`/bin/echo "${S3_ACCESS_KEY}" | /usr/bin/fgrep -o '|' | /usr/bin/wc -l`"
no_tokens="`/usr/bin/expr ${no_tokens} + 1`"
count="1"

while ( [ "${count}" -le "${no_tokens}" ] )
do
        ${BUILD_HOME}/initscripts/InitialiseDatastoreConfig.sh "`/bin/echo "${S3_ACCESS_KEY}" | /usr/bin/cut -d "|" -f ${count}`" "`/bin/echo "${S3_SECRET_KEY}" | /usr/bin/cut -d "|" -f ${count}`" "`/bin/echo "${S3_LOCATION}" | /usr/bin/cut -d "|" -f ${count}`" "`/bin/echo "${S3_HOST_BASE}" | /usr/bin/cut -d "|" -f ${count}`" ${count}
        count="`/usr/bin/expr ${count} + 1`"
done
