#!/bin/sh
####################################################################################
# Description: This script will work out what Application we are deploying, if any.
# There are several scenarios. The 1st is that it is a virgin install of an Application
# in which case we can discern elsewhere which Application it is. We can discern our
# application type based on a baseline or on a datastore backup depending on what
# type of deployment is being made.
# Date: 07-11/2016
# Author: Peter Winter
####################################################################################
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
#####################################################################################
#####################################################################################
#set -x

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
WEBSITE_NAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_NAME`"
BUILD_ARCHIVE_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_ARCHIVE_CHOICE`"
APPLICATION_REPOSITORY_PROVIDER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_REPOSITORY_PROVIDER`"
APPLICATION_REPOSITORY_USERNAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_REPOSITORY_USERNAME`"
APPLICATION_REPOSITORY_OWNER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_REPOSITORY_OWNER`"
APPLICATION_BASELINE_SOURCECODE_REPOSITORY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_BASELINE_SOURCECODE_REPOSITORY`"
BASELINE_DB_REPOSITORY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BASELINE_DB_REPOSITORY`"

APPLICATION_REPOSITORY_TOKEN="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_REPOSITORY_TOKEN`"

if ( [ "${APPLICATION_REPOSITORY_TOKEN}" = "" ] )
then
        APPLICATION_REPOSITORY_PASSWORD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION_REPOSITORY_PASSWORD`"
else
        APPLICATION_REPOSITORY_PASSWORD="${APPLICATION_REPOSITORY_TOKEN}"
fi

website_subdomain="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{print $1}'`"
interrogation_home="${BUILD_HOME}/interrogation"

if ( [ ! -d ${interrogation_home} ] )
then
	/bin/mkdir -p ${interrogation_home}
fi

if ( [ -d ${interrogation_home} ] )
then
	/bin/rm -r ${interrogation_home}/* 1>/dev/null 2>/dev/null
fi

cd ${interrogation_home}

girepo=""

#If we are a basseline check then we expect to be able to find the baseline repository available
if ( [ "${BUILD_ARCHIVE_CHOICE}" = "baseline" ] )
then
	gitrepo="0"

	if ( [ "`${BUILD_HOME}/providerscripts/git/GitLSRemote.sh ${APPLICATION_REPOSITORY_PROVIDER} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_REPOSITORY_OWNER} ${APPLICATION_BASELINE_SOURCECODE_REPOSITORY} ${APPLICATION_REPOSITORY_PASSWORD} 2>/dev/null`" = "" ] )
	then
		status "Sorry, could not find the baseline repository for you application when I was expecting to, will have to exit..."
		/bin/touch /tmp/END_IT_ALL
	else
		status "I have found potentially usable webroot baseline sourcecode in your git repo."
		gitrepo="1"
	fi

	if ( [ "`${BUILD_HOME}/providerscripts/git/GitLSRemote.sh ${APPLICATION_REPOSITORY_PROVIDER} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_REPOSITORY_OWNER} ${BASELINE_DB_REPOSITORY} ${APPLICATION_REPOSITORY_PASSWORD} 2>/dev/null`" = "" ] )
	then
		status "Sorry, could not find the baseline repository for you application when I was expecting to, will have to exit..."
		/bin/touch /tmp/END_IT_ALL
	else
		status "I have found potentially usable database baseline sourcecode in your git repo."
	fi
 
	status "The build assets have been verified suitable for the build to proceed"
fi

#If we are a temporal build, check then we expect to be able to find a backup in the datastore
periodicity=""
if ( [ "${BUILD_ARCHIVE_CHOICE}" != "baseline" ] && [ "${BUILD_ARCHIVE_CHOICE}" != "virgin" ] )
then
	if ( [ "`/bin/echo 'hourly daily weekly monthly bimonthly' | /bin/grep ${BUILD_ARCHIVE_CHOICE}`" != "" ] )
	then
		backuparchive="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`-${BUILD_ARCHIVE_CHOICE}/applicationsourcecode.tar.gz"
		backupdbarchive="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`-db-${BUILD_ARCHIVE_CHOICE}/${WEBSITE_NAME}-DB-backup.tar.gz"
	else
		status "Your build kit doesn't seem to have a valid periodicity set"
		/bin/touch /tmp/END_IT_ALL
	fi

	datastorebucket="0"
	datastoredbbucket="0"
	${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${backuparchive}
	${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${backupdbarchive}
	archive="${interrogation_home}/applicationsourcecode.tar.gz"
	archivedb="${interrogation_home}/${WEBSITE_NAME}-DB-backup.tar.gz"

	if ( [  -f ${archive} ] )
	then
		status "I have found potentially usable backup webroot sourcecode in your datastore. The build can proceed"
		status ""
		datastorebucket="1"
	else
		status "Did not find candidate sourcecode in your datastore"
		/bin/touch /tmp/END_IT_ALL
	fi

	if ( [  -f ${archivedb} ] )
	then
		status "I have found potentially usable backup db dump in your datastore. The build can proceed"
		status ""
		datastoredbbucket="1"
	else
		status "Notice: did not find candidate db sourcecode in your datastore"
		status "Press <enter> to acknowledge and continue, otherwise, ctrl-c to exit"
		read x
	fi
fi

#If we successfully have found the a repository for our baseline then have a go at finding which application it is by baseline
if ( [ "${gitrepo}" = "1" ] )
then
	${BUILD_HOME}/providerscripts/git/GitClone.sh ${APPLICATION_REPOSITORY_PROVIDER} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_REPOSITORY_OWNER} ${APPLICATION_BASELINE_SOURCECODE_REPOSITORY} ${APPLICATION_REPOSITORY_PASSWORD}
	${BUILD_HOME}/providerscripts/git/GitClone.sh ${APPLICATION_REPOSITORY_PROVIDER} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_REPOSITORY_OWNER} ${BASELINE_DB_REPOSITORY} ${APPLICATION_REPOSITORY_PASSWORD}
	${BUILD_HOME}/application/WhichApplicationByGitAndBaseline.sh
fi

#If we successfully have found the a backup for our temporal backup then have a go at finding which application it is by backup
if ( [ "${datastorebucket}" = "1" ] )
then
	/bin/tar xvfz ${archive} -C ${interrogation_home}
	/bin/tar xvfz ${archivedb} -C ${interrogation_home}
	${BUILD_HOME}/application/WhichApplicationByDatastoreAndBackup.sh
fi

cd ${BUILD_HOME}

