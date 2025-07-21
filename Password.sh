#!/bin/sh
###############################################################################################
# Description: You can use this script to obtain the password for your chosen build
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

${BUILD_HOME}/helperscripts/DisplayPassword.sh ${1} ${2} 

#Defaults to interactive
if ( [ "$?" != "0" ] )
then
	${BUILD_HOME}/helperscripts/DisplayPassword.sh
fi
