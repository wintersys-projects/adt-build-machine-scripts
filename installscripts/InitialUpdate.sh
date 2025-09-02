#!/bin/sh
######################################################################################################
# Description: This script will perform a software update it is called during the intial build phase
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

if ( [ "`/bin/grep "^PACKAGEMANAGER:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "apt" ] )
then
	if ( [ "${buildos}" = "ubuntu" ] )
	then
		/usr/bin/yes | /usr/bin/dpkg --configure -a
		DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 install -y -qq apt-utils
		DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y update --allow-change-held-packages    
	fi

	if ( [ "${buildos}" = "debian" ] )
	then
		/usr/bin/yes | /usr/bin/dpkg --configure -a
		DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 install -y -qq apt-utils 
		DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y update --allow-change-held-packages    
	fi
fi

if ( [ "`/bin/grep "^PACKAGEMANAGER:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "apt-fast" ] )
then
	if ( [ "${buildos}" = "ubuntu" ] )
	then
		apt_fast_url='https://raw.githubusercontent.com/ilikenwf/apt-fast/master'

		if ( [ -f /usr/local/sbin/apt-fast ] )
		then
			/bin/rm -f /usr/local/sbin/apt-fast
		fi

		/usr/bin/wget "${apt_fast_url}"/apt-fast -O /usr/sbin/apt-fast
		/bin/chmod +x /usr/sbin/apt-fast

		if ( [ ! -f /etc/apt-fast.conf ] )
		then
			/usr/bin/wget "$apt_fast_url"/apt-fast.conf -O /etc/apt-fast.conf
		fi
                
		DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y install snapd
		DEBIAN_FRONTEND=noninteractive /usr/sbin/apt-fast -o DPkg::Lock::Timeout=-1 -qq -y update
		/usr/bin/snap install aria2c 
		/bin/echo 'DOWNLOADBELOW="aria2c -c -s ${_MAXNUM} -x ${_MAXNUM} -k 1M -q --file-allocation=none"' >> /etc/apt-fast.conf
	fi

	if ( [ "${buildos}" = "debian" ] )
	then
		if ( [ -f /usr/local/sbin/apt-fast ] )
		then
			/bin/rm -f /usr/local/sbin/apt-fast
		fi

		/usr/bin/wget "${apt_fast_url}"/apt-fast -O /usr/sbin/apt-fast
		/bin/chmod +x /usr/sbin/apt-fast

		if ( [ ! -f /etc/apt-fast.conf ] )
		then
			/usr/bin/wget "$apt_fast_url"/apt-fast.conf -O /etc/apt-fast.conf
		fi
		
  		DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y install snapd
		DEBIAN_FRONTEND=noninteractive /usr/sbin/apt-fast -o DPkg::Lock::Timeout=-1 -qq -y update
		/usr/bin/snap install aria2c 
		/bin/echo 'DOWNLOADBELOW="aria2c -c -s ${_MAXNUM} -x ${_MAXNUM} -k 1M -q --file-allocation=none"' >> /etc/apt-fast.conf

	fi   
fi

