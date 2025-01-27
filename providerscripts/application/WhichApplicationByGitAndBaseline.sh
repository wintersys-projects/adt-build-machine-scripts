#!/bin/sh
#######################################################################################
# Description: This script will work out what type of application you are building based
# on a sourcecode baseline stored in git
# Author: Peter Winter
# Date: 05/01/2017
########################################################################################
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
########################################################################################
########################################################################################
#set -x

status () {
	/bin/echo "$1" | /usr/bin/tee /dev/fd/3 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`" 
APPLICATION_BASELINE_SOURCECODE_REPOSITORY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_BASELINE_SOURCECODE_REPOSITORY`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
DIRECTORIES_TO_MOUNT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DIRECTORIES_TO_MOUNT`"
interrogation_home="${BUILD_HOME}/interrogation"

APPLICATION=""

#################JOOMLA################
if ( [ -d ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/administrator ] && [ -d ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/modules ] && [ -d ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/plugins ] && [ -d ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/templates ] )
then
	/bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/APPLICATION:joomla
	APPLICATION="joomla"
	interrogated="1"
	if ( [ "${DIRECTORIES_TO_MOUNT}" = "" ] )
	then
		DIRECTORIES_TO_MOUNT="images"
	fi
	status "Discovered you are deploying joomla from a git repo baseline"
	status "Press the <enter> key to accept as true"
	if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
	then
		read x
	fi
 
 	if ( [ -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/configuration.php.default ] )
  	then
 		/bin/cp ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/configuration.php.default ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/configuration.php.default
	else
 		status "Couldn't find joomla default configuration file in baseline webroot"
   		exit
   	fi
    
 	if ( [ ! -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ] )
 	then
  		status "Error, cannot find db prefix file"
    		exit
    	fi
     
 	/bin/cp ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}	
   	${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/dbp.dat
 #################JOOMLA################
	#################WORDPRESS################
elif ( [ -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/wp-login.php ] && [ -d ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/wp-content ] && [ -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/wp-cron.php ] && [ -d ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/wp-admin ] && [ -d ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/wp-includes ] && [ -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/wp-settings.php ] )
then
	/bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/APPLICATION:wordpress
	APPLICATION="wordpress"
	interrogated="1"
	if ( [ "${DIRECTORIES_TO_MOUNT}" = "" ] )
	then
		DIRECTORIES_TO_MOUNT="wp-content.uploads"
	fi
	status "Discovered you are deploying wordpress from a git repo baseline"
	status "Press the <enter> key to accept as true"
	if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
	then
		read x
	fi
 	if ( [ -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/wp-config.php.default ] )
  	then
        	/bin/cp ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/wp-config.php.default ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/wp-config.php.default
        else
	 	status "Couldn't find joomla default configuration file in baseline webroot"
   		exit
	fi
	if ( [ ! -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ] )
        then
                status "Error, cannot find db prefix file"
                exit
        fi
        /bin/cp ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}
        ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/dbp.dat
	#################WORDPRESS################
	#################MOODLE################
elif ( [ -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/moodle/index.php ] && [ -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/moodle/version.php ] && [ -d ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/moodle/userpix ] && [ -d ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/moodle/report ] && [ -d ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/moodle/enrol ] && [ -d ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/moodle/theme ] )
then
	/bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/APPLICATION:moodle
	APPLICATION="moodle"
	interrogated="1"
	if ( [ "${DIRECTORIES_TO_MOUNT}" = "" ] )
	then
		DIRECTORIES_TO_MOUNT="moodledata.filedir"
	fi
	status "Discovered you are deploying moodle from a git repo baseline"
	status "Press the <enter> key to accept as true"
	if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
	then
		read x
	fi

 	if ( [ -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/moodle/config.php.default ] )
  	then
        	/bin/cp ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/moodle/config.php.default ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default
        else
	 	status "Couldn't find moodle default configuration file in baseline webroot"
   		exit
	fi
	if ( [ ! -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ] )
        then
                status "Error, cannot find db prefix file"
                exit
        fi
        /bin/cp ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}
        ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/dbp.dat

 
	#################MOODLE################
	#################DRUPAL################
elif ( [ -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/core/misc/drupal.js ] && [ -d ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/themes ] && [ -d ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/vendor ] && [ -d ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/modules ] && [ -d ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/profiles ] )
then
	/bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/APPLICATION:drupal
	APPLICATION="drupal"
	interrogated="1"
	if ( [ "${DIRECTORIES_TO_MOUNT}" = "" ] )
	then
		DIRECTORIES_TO_MOUNT="sites.default.files.pictures:sites.default.files.styles:sites.default.files.inline-images"
	fi
	status "Discovered you are deploying drupal from a git repo baseline"
	status "Press the <enter> key to accept as true"
	if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
	then
		read x
	fi
  
 	if ( [ -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/sites/default/settings.php.default ] )
  	then
        	/bin/cp ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/sites/default/settings.php.default ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default
        else
	 	status "Couldn't find drupal default configuration file in baseline webroot"
   		exit
	fi
	if ( [ ! -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ] )
        then
                status "Error, cannot find db prefix file"
                exit
        fi
        /bin/cp ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}
	${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/dbp.dat

	#################DRUPAL################
fi

if ( [ "${APPLICATION}" = "" ] )
then
	status "Couldn't find a recognised application type. If you are sure you are OK with this, hit <enter> otherwise <ctrl-c> and have a look into what is going on"
	if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
	then
		read x
	fi
fi

