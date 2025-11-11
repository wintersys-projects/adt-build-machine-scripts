#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date  : 13/07/2025
# Description : This will configure an SSH Private Key for the git provider if
# one is configured in the template
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
GIT_SSH_PRIVATE_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh GIT_SSH_PRIVATE_KEY`"
APPLICATION_REPOSITORY_PROVIDER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_REPOSITORY_PROVIDER`"

if ( [ "${GIT_SSH_PRIVATE_KEY}" != "" ] )
then
	if ( [ "${APPLICATION_REPOSITORY_PROVIDER}" = "github" ] )
	then
		if ( [ -f ${BUILD_HOME}/runtimedata/GITHUB_SSH_KEY ] )
		then
			if ( [ "`/bin/grep "${GIT_SSH_PRIVATE_KEY}" ${BUILD_HOME}/runtimedata/GITHUB_SSH_KEY`" = "" ] )
			then
				/bin/mv ${BUILD_HOME}/runtimedata/GITHUB_SSH_KEY ${BUILD_HOME}/runtimedata/GITHUB_SSH_KEY.$$
				/bin/echo "${GIT_SSH_PRIVATE_KEY}" > ${BUILD_HOME}/runtimedata/GITHUB_SSH_KEY
				if ( [ "`/bin/grep github.com ~/.ssh/config`" = "" ] )
				then
					/bin/echo "Host github.com
	User git
	IdentityFile ${BUILD_HOME}/runtimedata/GITHUB_SSH_KEY" >> ~/.ssh/config
			fi	fi
		fi
	fi
fi
