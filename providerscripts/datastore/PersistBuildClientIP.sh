#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date  : 13/07/2021
# Description :  This will record your build client IP in the S3 system which will ensure
# that the firewall grants access to your laptop onto your build machine
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
######################################################################################
######################################################################################
#set -x

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"

if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstylesscp.dat | /bin/grep s3cmd`" != "" ] )
then
        datastore_tool="/usr/bin/s3cmd put "
        tool_name="s3cmd"
elif ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstylesscp.dat | /bin/grep s5cmd`" != "" ] )
then
        host_base="`/bin/grep host_base /root/.s5cfg | /bin/grep host_base | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_tool="/usr/bin/s5cmd --credentials-file /root/.s5cfg --endpoint-url https://${host_base} cp "
fi

${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh "adt-${BUILD_IDENTIFIER}"
${BUILD_HOME}/providerscripts/datastore/DeleteFromDatastore.sh "adt-${BUILD_IDENTIFIER}/*" 
build_client_ip="`${BUILD_HOME}/helperscripts/GetBuildClientIP.sh`"
/bin/touch /tmp/${build_client_ip}
${datastore_tool} /tmp/${build_client_ip} s3://adt-${BUILD_IDENTIFIER}
