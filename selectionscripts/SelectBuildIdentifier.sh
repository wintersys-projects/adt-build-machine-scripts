#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : For operational reasons we need to have the build identifier available
# before we read the template this is not a problme when we are hardcore but when we
# are expedited we need to have the BUILD_IDENTIFIER available up front.
# The easiest way to do this is just to ask the user interactively to input a value 
# for a build identifier and make it clear to them that it will override and overwrite
# any setting that they have previously held in their template. 
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

while ( [ "${BUILD_IDENTIFIER}" = "" ] && [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" = "0" ] )
do
	status ""
	status ""
	status "##################################################################################################"
	status "#####Can you give us a BUILD IDENTIFIER for this build run. What you tell us here will override any"
	status "value that has been defined in your template"
	status "If you want to have numbered builds you shouldn't write 'build-1', 'build-2' and so on because of"
	status "Possible truncation. Rather, you should write '1-build', '2-build'"
	status "###################################################################################################"
	status "Enter Build Identifier please:"
			
	if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
	then
		read BUILD_IDENTIFIER

		while ( [ "${BUILD_IDENTIFIER}" = "" ] )
		do
			status "The build identifier can't be blank, try again...."
			read BUILD_IDENTIFIER
		done
	fi
 	if ( [ -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER} ] )
  	then
   		status ""
     		status "#################################################################################################################"
   		status "You already have a directory structure matching build identifier ${BUILD_IDENTIFIER}"
     		status "If you are VERY sure this is OK and you want to continue enter (Y|y) anything else to select a new build identifier"
     		status "#################################################################################################################"
       		read response
	 	if ( [ "${response}" != "Y" ] && [ "${response}" != "y" ] )
   		then
     			BUILD_IDENTIFIER=""
		fi
  	fi
done

BUILD_IDENTIFIER="`/bin/echo ${BUILD_IDENTIFIER} | /usr/bin/tr '[:upper:]' '[:lower:]' | /usr/bin/cut -c -8`"

if ( [ ! -d ${BUILD_HOME}/runtimedata ] )
then
	/bin/mkdir ${BUILD_HOME}/runtimedata
fi

/bin/echo "${BUILD_IDENTIFIER}" > ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER
