#!/bin/sh
######################################################################################################
# Description: This script will perform a software update
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

if ( [ "`/bin/grep "^PACKAGEMANAGER:*" ${BUILD_HOME}/builddescriptors/buildstylesscp.dat | /usr/bin/awk -F':' '{print $NF}'`" = "apt" ] )
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

if ( [ "`/bin/grep "^PACKAGEMANAGER:*" ${BUILD_HOME}/builddescriptors/buildstylesscp.dat | /usr/bin/awk -F':' '{print $NF}'`" = "apt-fast" ] )
then
        if ( [ "${buildos}" = "ubuntu" ] )
        then
                /bin/echo "deb [signed-by=/etc/apt/keyrings/apt-fast.gpg] http://ppa.launchpad.net/apt-fast/stable/ubuntu focal main" > /etc/apt/sources.list.d/apt-fast.list
                /bin/mkdir -p /etc/apt/keyrings
                if ( [ -f /etc/apt/keyrings/apt-fast.gpg ] )
                then
                        /bin/rm /etc/apt/keyrings/apt-fast.gpg
                fi
                /usr/bin/curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xBC5934FD3DEBD4DAEA544F791E2824A7F22B44BD" | gpg --dearmor -o /etc/apt/keyrings/apt-fast.gpg
                DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y update
                DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 install -y -qq apt-fast
                DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 install -y -qq aria2
                DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y install snapd
                DEBIAN_FRONTEND=noninteractive /usr/bin/apt-fast -o DPkg::Lock::Timeout=-1 -qq -y update
                DEBIAN_FRONTEND=noninteractive /usr/bin/apt-fast -o DPkg::Lock::Timeout=-1 -qq -y upgrade
                /usr/bin/snap install aria2c 
                mirrors="`/bin/grep "^deb" /etc/apt/sources.list | /bin/grep -Po 'http.* ' | /usr/bin/awk '{print $1}' | /usr/bin/sort -u | /usr/bin/uniq | /usr/bin/tr '\n' ',' | /bin/sed 's/,$//'`" 
                /bin/echo "MIRRORS=( '${mirrors}' )" >> /etc/apt-fast.conf
                /bin/echo 'DOWNLOADBELOW="aria2c -c -s ${_MAXNUM} -x ${_MAXNUM} -k 1M -q --file-allocation=none"' >> /etc/apt-fast.conf
                /bin/ln -s /usr/bin/apt-fast /usr/sbin/apt-fast  
        fi

        if ( [ "${buildos}" = "debian" ] )
        then
                /bin/echo "deb [signed-by=/etc/apt/keyrings/apt-fast.gpg] http://ppa.launchpad.net/apt-fast/stable/ubuntu focal main" > /etc/apt/sources.list.d/apt-fast.list
                /bin/mkdir -p /etc/apt/keyrings
                if ( [ -f /etc/apt/keyrings/apt-fast.gpg ] )
                then
                        /bin/rm /etc/apt/keyrings/apt-fast.gpg
                fi
                /usr/bin/curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xBC5934FD3DEBD4DAEA544F791E2824A7F22B44BD" | gpg --dearmor -o /etc/apt/keyrings/apt-fast.gpg
                DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y update
                DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 install -y -qq apt-fast
                DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 install -y -qq aria2
                DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y install snapd
                DEBIAN_FRONTEND=noninteractive /usr/bin/apt-fast -o DPkg::Lock::Timeout=-1 -qq -y update
                DEBIAN_FRONTEND=noninteractive /usr/bin/apt-fast -o DPkg::Lock::Timeout=-1 -qq -y upgrade
                /usr/bin/snap install aria2c 
                mirrors="`/bin/grep "^deb" /etc/apt/sources.list | /bin/grep -Po 'http.* ' | /usr/bin/awk '{print $1}' | /usr/bin/sort -u | /usr/bin/uniq | /usr/bin/tr '\n' ',' | /bin/sed 's/,$//'`" 
                /bin/echo "MIRRORS=( '${mirrors}' )" >> /etc/apt-fast.conf
                /bin/echo 'DOWNLOADBELOW="aria2c -c -s ${_MAXNUM} -x ${_MAXNUM} -k 1M -q --file-allocation=none"' >> /etc/apt-fast.conf
                /bin/ln -s /usr/bin/apt-fast /usr/sbin/apt-fast
        fi   
fi

