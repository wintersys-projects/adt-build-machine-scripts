#!/bin/sh
####################################################################################
# Description: This will set the application configuration for use by the webservers
# The application configuration (for example configuration.php for Joomla) will be
# set here and uploaded to the config bucket in the datastore and the websevers will
# pull the configuration from there. You can extend the application specific settings
# to any level of detail right the way up to configuring every configurable setting 
# if you chose to. What I do here is set the bare minimum to get the application 
# online which basically means database and hostname/ip address
# Date: 07/11/2024
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

database_ip="${1}"

#BUILD_HOME="`/bin/cat /home/buildhome.dat`"
#CLOUDHOST="`/bin/cat ${BUILD_HOME}/runtimedata/BUILD_MACHINE_CLOUDHOST`"
#BUILD_IDENTIFIER="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER`"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
APPLICATION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh APPLICATION`"
BUILD_ARCHIVE_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_ARCHIVE_CHOICE`"
database_username="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DBaaS_USERNAME'`"
database_password="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DBaaS_PASSWORD'`"
database_name="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DBaaS_DBNAME'`"
database_port="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DB_PORT'`"
database_identifier="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'DBaaS_HOSTNAME'`"

 
#if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DBaaS_HOSTNAME ] )
#then
       # DB_HOSTNAME="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DBaaS_HOSTNAME`"
#        db_hostname="`/bin/sed 5!d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred`"
#fi

#db_port="`/bin/sed 4!d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred`"

db_ip="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "db-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
#if ( [ "${DB_PORT}" = "" ] )
#then
#     DB_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DB_PORT`"
#fi

#if ( [ "${DB_HOSTNAME}" = "" ] )
#then
 #       if ( [ "${DBIP_PRIVATE}" = "" ] )
  #      then
   #             DBIP_PRIVATE="`/bin/ls ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/DBPRIVATEIP:* | /usr/bin/awk -F':' '{print $NF}'`"
  #      fi
 
   #     if ( [ "${DBIP_PUBLIC}" = "" ] )
   #     then
   #             DBIP_PUBLIC="`/bin/ls ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/DBIP:* | /usr/bin/awk -F':' '{print $NF}'`"
   #     fi
#fi

if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" = "1" ] )
then
        if ( [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] )
        then
                /bin/echo "Database name: ${database_name}" 
                /bin/echo "Database username: ${database_username}" 
                /bin/echo "Database password: ${database_password}" 
       # else
       #         database_name="`/bin/sed 1!d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred`"
       #         database_username="`/bin/sed 3!d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred`"
       #         database_password="`/bin/sed 2!d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred`"
        fi
else
        if ( [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] )
        then
                /bin/echo "Database name: ${database_name}" >&3
                /bin/echo "Database username: ${database_username}" >&3
                /bin/echo "Database password: ${database_password}" >&3
              #  /bin/echo "Database name: `/bin/sed 1!d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred`" >&3
              #  /bin/echo "Database username: `/bin/sed 3!d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred`" >&3
              #  /bin/echo "Database password: `/bin/sed 2!d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred`" >&3
       # else
        #        database_name="`/bin/sed 1!d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred`"
        #        database_username="`/bin/sed 3!d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred`"
        #        database_password="`/bin/sed 2!d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred`"
        fi
fi

#DBIP_PRIVATE="`/bin/ls ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/DBPRIVATEIP:* | /usr/bin/awk -F':' '{print $NF}'`"

#if ( [ "${db_hostname}" != "" ] )
#then
#     database_identifier="${db_hostname}"
#else
#     database_identifier="${db_ip}"
#fi

. ${BUILD_HOME}/providerscripts/application/${APPLICATION}/SetApplicationConfig.sh

