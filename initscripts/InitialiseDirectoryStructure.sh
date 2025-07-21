#!/bin/sh
#########################################################################################
# Author : Peter Winter
# Date   : 13/07/2016
# Description : This will just initialise the working directory structure on the build machine
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

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
cloudhost="${1}"
build_identifier="${2}"

/bin/chown -R ${USER} ${BUILD_HOME}/.
/bin/chmod -R 700 ${BUILD_HOME}/.

#Make sure that our ssh connections are long lasting. In the case where the user is building from their own desktop machine,
#this will be changing settings on their machine so we ask it it is OK. If they are using a dedicated build server in the cloud,
#then it shouldn't matter so much
if ( [ ! -d ~/.ssh ] )
then
	/bin/mkdir ~/.ssh
fi

if ( [ ! -d ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier} ] )
then
	/bin/mkdir -p ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}
else
	/bin/rm ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/* 2>/dev/null
fi

if ( [ ! -d ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/credentials ] )
then
	/bin/mkdir -p ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/credentials
else
	/bin/rm -r ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/credentials/* 2>/dev/null
fi

if ( [ -d ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/keys ] )
then
	/bin/mkdir -p ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/keys
else
	/bin/rm -r ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/keys/* 2>/dev/null
fi

if ( [ ! -d ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/ips ] )
then
	/bin/mkdir -p ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/ips
else
	/bin/rm -r ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/ips/* 2>/dev/null
fi

if ( [ ! -d ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/cloud-init ] )
then
	/bin/mkdir -p ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/cloud-init
else
	/bin/rm -r ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/cloud-init/* 2>/dev/null
fi


if ( [ -d ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/ssl ] )
then
	/bin/mkdir -p ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/ssl
fi

if ( [ ! -d ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/logs ] )
then
	/bin/mkdir -p ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/logs
fi
