#!/bin/sh
######################################################################################################
# Description: This script will install the linode cli
# Author: Peter Winter
# Date: 17/01/2017
#######################################################################################################
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
#######################################################################################################
#######################################################################################################
#set -x

if ( [ "${1}" != "" ] )
then
	buildos="${1}"
fi

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

apt=""
if ( [ "`/bin/grep "^PACKAGEMANAGER:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "apt" ] )
then
	apt="/usr/bin/apt-get"
elif ( [ "`/bin/grep "^PACKAGEMANAGER:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "apt-fast" ] )
then
	apt="/usr/sbin/apt-fast"
fi

export DEBIAN_FRONTEND=noninteractive 
install_command="${apt} -o DPkg::Lock::Timeout=-1 -o Dpkg::Use-Pty=0 -qq -y install " 

if ( [ "${buildos}" = "ubuntu" ] )
then
	eval ${install_command} pipx
	if ( [ -f /usr/local/bin/linode-cli ] )
	then
		/usr/bin/pipx upgrade linode-cli 
	else
		/usr/bin/pipx install linode-cli 
  		/usr/bin/pipx ensurepath
		/usr/bin/ln -s /root/.local/bin/linode-cli /usr/local/bin/linode-cli
	fi
fi

if ( [ "${buildos}" = "debian" ] )
then
	eval ${install_command} pipx
	if ( [ -f /usr/local/bin/linode-cli ] )
	then
		/usr/bin/pipx upgrade linode-cli 
	else
		/usr/bin/pipx install linode-cli 
		/usr/bin/pipx ensurepath
		/usr/bin/ln -s /root/.local/bin/linode-cli /usr/local/bin/linode-cli
	fi
fi

