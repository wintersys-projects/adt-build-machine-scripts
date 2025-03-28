#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Install the tools for manipulating the Datastores
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

if ( [ "$1" != "" ] )
then
	buildos="${1}"
fi

if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s3cmd`" != "" ] )
then
	apt=""
	if ( [ "`/bin/grep "^PACKAGEMANAGER:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "apt" ] )
	then
		apt="/usr/bin/apt-get"
	elif ( [ "`/bin/grep "^PACKAGEMANAGER:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "apt-fast" ] )
	then
		apt="/usr/sbin/apt-fast"
	fi

	if ( [ "${apt}" = "/usr/sbin/apt-fast" ] && [ ! -f /usr/sbin/apt-fast ] )
	then
		apt="/usr/bin/apt-get"
	fi

	install_command="DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1 -o Dpkg::Use-Pty=0 -qq -y install " 

	if ( [ "${apt}" != "" ] )
	then
		if ( [ "${buildos}" = "ubuntu" ] )
		then
			eval ${install_command} s3cmd 2>/dev/null
		fi

		if ( [ "${buildos}" = "debian" ] )
		then
			eval ${install_command} s3cmd 2>/dev/null
		fi
	fi
elif ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s5cmd`" != "" ] )
then
	if ( [ "${buildos}" = "ubuntu" ] )
	then
		${BUILD_HOME}/installscripts/InstallGo.sh "ubuntu"
		if ( [ -d /root/scratch ] )			
		then						
			/bin/rm -r /root/scratch/*		
		else						
			/bin/mkdir /root/scratch		
		fi						

		GOBIN=/root/scratch /usr/bin/go install github.com/peak/s5cmd/v2@latest                
		if ( [ -f /root/scratch/s5cmd ] )                                                   
		then                                                                                    
			/bin/mv /root/scratch/s5cmd /usr/bin/s5cmd                                    
		fi   											
	fi	

	if ( [ "${buildos}" = "debian" ] )
	then
		${BUILD_HOME}/installscripts/InstallGo.sh "debian"
		if ( [ -d /root/scratch ] )			
		then					
			/bin/rm -r /root/scratch/*		
		else					
			/bin/mkdir /root/scratch		
		fi						
		GOBIN=/root/scratch /usr/bin/go install github.com/peak/s5cmd/v2@latest                
		if ( [ -f /root/scratch/s5cmd ] )                                                     
		then                                                                                   
			/bin/mv /root/scratch/s5cmd /usr/bin/s5cmd                                  
		fi 											
	fi
 
	if ( [ -d /root/scratch ] )
	then
		/bin/rm -r /root/scratch
	fi
fi
