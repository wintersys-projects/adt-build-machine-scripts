#!/bin/sh
###############################################################################################
# Description: You can use this script to interact with the logging streams for your chosen build
# Author Peter Winter
# Date 22/9/2020
##############################################################################################
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
################################################################################################
###############################################################################################
#set -x

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

#You can set yourself up with oneliners to access particular log or error streams this will provide you with rapid access to your build streams
#You should comment out the interactive call above and comment in a command like the ones shown below which are appropriate for you
#For example, if you ran this script ${BUILD_HOME}/Log.sh c 2 you would "cat" the error stream for "vultr" with build_identifier "crew"
#For example, if you ran this script ${BUILD_HOME}/Log.sh v 1 you would "edit" the output stream for "vultr" with build_identifier "crew"
#For example, if you ran this script ${BUILD_HOME}/Log.sh t 1 you would "tail" the output stream for "vultr" with build_identifier "crew"
#If you are running for linode (for example you would need to change this script up front according to the subsequent examples
#The actual log files are stored at ${BUILD_HOME}/runtimedata/<cloudhost>/<build_identifier>/logs

#${BUILD_HOME}/helperscripts/DisplayLoggingStreams.sh vultr crew ${1} ${2} 

${BUILD_HOME}/helperscripts/DisplayLoggingStreams.sh linode crew ${1} ${2} 
#${BUILD_HOME}/helperscripts/DisplayLoggingStreams.sh digitalocean crew2 ${1} ${2}

#Defaults to interactive
if ( [ "$?" != "0" ] )
then
	${BUILD_HOME}/helperscripts/DisplayLoggingStreams.sh
fi
