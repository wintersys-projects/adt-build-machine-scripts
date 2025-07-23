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
set -x

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`" 
APPLICATION_BASELINE_SOURCECODE_REPOSITORY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_BASELINE_SOURCECODE_REPOSITORY`"
BASELINE_DB_REPOSITORY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BASELINE_DB_REPOSITORY`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
DIRECTORIES_TO_MOUNT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DIRECTORIES_TO_MOUNT`"
DATABASE_INSTALLATION_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DATABASE_INSTALLATION_TYPE`"
interrogation_home="${BUILD_HOME}/interrogation"

APPLICATION=""

if ( [ ! -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbe.dat ] )
then
	status "NOTICE: couldn't detect the database type for your application"
else
	if ( [ "`/bin/grep Maria ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbe.dat`" != "" ] )
	then
		db_type="sql"
	fi
	if ( [ "`/bin/grep MySQL ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbe.dat`" != "" ] )
	then
		db_type="sql"
	fi
	if ( [ "`/bin/grep Postgres ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbe.dat`" != "" ] )
	then
		db_type="postgres"
	fi
fi

if ( [ ! -f ${interrogation_home}/${BASELINE_DB_REPOSITORY}/applicationDB.sql ] && [ ! -f ${interrogation_home}/${BASELINE_DB_REPOSITORY}/applicationDB.psql ] )
then
	status "NOTICE: Can't find a suitable database dump file for your application"
	status "Press <enter> to acknowledge and accept <ctrl-c> to exit and investigate"
	read x
fi

if ( [ -f ${interrogation_home}/${BASELINE_DB_REPOSITORY}/applicationDB.sql ] && [ "${db_type}" != "sql" ] )
then
	status "It seems like there is a mismatch between the type of database and thw webroot type"
	/bin/touch /tmp/END_IT_ALL
fi

if ( [  "${DATABASE_INSTALLATION_TYPE}" = "MySQL" ] || [  "${DATABASE_INSTALLATION_TYPE}" = "Maria" ] ) 
then
	if ( [ "${db_type}" != "sql" ] )
	then
		status "It seems like there is a mismatch between the type of database you are installing and the database type that is configured in the template"
		/bin/touch /tmp/END_IT_ALL
	fi
fi

if ( [ -f ${interrogation_home}/${BASELINE_DB_REPOSITORY}/applicationDB.psql ] && [ "${db_type}" != "postgres" ] )
then
	status "It seems like there is a mismatch between the type of database and thw webroot type"
	/bin/touch /tmp/END_IT_ALL
fi

if ( [  "${DATABASE_INSTALLATION_TYPE}" = "Postgres" ] )
then
	if ( [ "${db_type}" != "postgres" ] )
	then
		status "It seems like there is a mismatch between the type of database you are installing and the database type that is configured in the template"
		/bin/touch /tmp/END_IT_ALL
	fi
fi

#################JOOMLA################
if ( [ "`/bin/cat ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dba.dat`" = "JOOMLA" ] )
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
		/bin/touch /tmp/END_IT_ALL
	fi

	if ( [ ! -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ] )
	then
		status "Error, cannot find db prefix file"
		/bin/touch /tmp/END_IT_ALL
	fi

	/bin/cp ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}
	${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/dbp.dat
	#################WORDPRESS################
elif ( [ "`/bin/cat ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dba.dat`" = "WORDPRESS" ] )
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
		/bin/touch /tmp/END_IT_ALL
	fi

	if ( [ ! -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ] )
	then
		status "Error, cannot find db prefix file"
		/bin/touch /tmp/END_IT_ALL
	fi

	/bin/cp ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}
	${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/dbp.dat
	#################DRUPAL################
elif ( [ "`/bin/cat ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dba.dat`" = "DRUPAL" ] )
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

	if ( [ -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/sites/default/default.settings.php ] )
	then
		/bin/cp ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/sites/default/default.settings.php ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default
	else
		status "Couldn't find drupal default configuration file in baseline webroot"
		/bin/touch /tmp/END_IT_ALL
	fi

	if ( [ ! -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ] )
	then
		status "Error, cannot find db prefix file"
		/bin/touch /tmp/END_IT_ALL
	fi

	/bin/cp ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}
	${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/dbp.dat

	#################MOODLE################
elif ( [ "`/bin/cat ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dba.dat`" = "MOODLE" ] )
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

	if ( [ -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/config.php.default ] )
	then
		/bin/cp ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/config.php.default ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default
	else
		status "Couldn't find moodle default configuration file in baseline webroot"
		/bin/touch /tmp/END_IT_ALL
	fi

	if ( [ ! -f ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ] )
	then
		status "Error, cannot find db prefix file"
		/bin/touch /tmp/END_IT_ALL
	fi

	/bin/cp ${interrogation_home}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/dbp.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}
	${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/dbp.dat
fi

/bin/rm -r ${interrogation_home}

if ( [ "${APPLICATION}" = "" ] )
then
	status "Couldn't find a recognised application type. If you are sure you are OK with this, hit <enter> otherwise <ctrl-c> and have a look into what is going on"

	if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
	then
		read x
	fi
fi

