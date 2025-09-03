#!/bin/sh
######################################################################################################
# Description: This script will install iptables
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
	apt="/usr/bin/apt"
elif ( [ "`/bin/grep "^PACKAGEMANAGER:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "apt-get" ] )
then
	apt="/usr/bin/apt-get"
fi

export DEBIAN_FRONTEND=noninteractive 
install_command="${apt} -o DPkg::Lock::Timeout=-1 -o Dpkg::Use-Pty=0 -qq -y install " 

if ( [ "${apt}" != "" ] )
then
	if ( [ "${buildos}" = "ubuntu" ] )
	then
		if ( [ -f /usr/sbin/ufw ] )                                                                             
		then                                                                                                    
			/usr/sbin/ufw disable                                                                           
		fi                                                                                                      

		eval ${install_command} iptables                 

		/bin/echo iptables-persistent iptables-persistent/autosave_v4 boolean true | /usr/bin/sudo debconf-set-selections 
		/bin/echo iptables-persistent iptables-persistent/autosave_v4 boolean true | /usr/bin/sudo debconf-set-selections 

		eval ${install_command} netfilter-persistent     
		eval ${install_command} iptables-persistent      
	fi

	if ( [ "${buildos}" = "debian" ] )
	then
		if ( [ -f /usr/sbin/ufw ] )                                                                            
		then                                                                                                    
			/usr/sbin/ufw disable                                                                           
		fi   
	
		eval ${install_command} iptables
  
		/bin/echo iptables-persistent iptables-persistent/autosave_v4 boolean true | /usr/bin/sudo debconf-set-selections 
		/bin/echo iptables-persistent iptables-persistent/autosave_v4 boolean true | /usr/bin/sudo debconf-set-selections 

		eval ${install_command} netfilter-persistent     
		eval ${install_command} iptables-persistent     
	fi
fi
