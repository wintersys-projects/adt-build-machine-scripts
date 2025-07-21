#!/bin/sh
####################################################################################
# Description: This sets up the database credentials and some other configuration
# settings necessary for the moodle application to be brought online
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
 
if ( [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/dbp.dat ] )
then
        status "Error, cannot find database prefix file"
fi

dbprefix="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/dbp.dat`"
#Set session handler to be database. May (will) get issues if trying to use filesystem
/bin/sed -i '/\/\/.*\\core\\session\\database/s/^\/\///' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default 
/bin/sed -i '/\/\/.*session_database_acquire_lock_timeout/s/^\/\///' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default

if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Maria" ] || ( [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] && [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep 'Maria'`" != "" ] ) )
then
        /bin/sed -i '/->dbtype /c\    $CFG->dbtype    = "'mariadb'";' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default
elif ( [ "${DATABASE_INSTALLATION_TYPE}" = "MySQL" ] || ( [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] && [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep 'MySQL'`" != "" ] ) )
then
        /bin/sed -i '/->dbtype /c\    $CFG->dbtype    = "'mysqli'";' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default
elif ( [ "${DATABASE_INSTALLATION_TYPE}" = "Postgres" ] || ( [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] && [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep 'Postgres'`" != "" ] ) )
then
        /bin/sed -i '/->dbtype /c\    $CFG->dbtype    = "'pgsql'";' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default
fi

/bin/sed -i '/->prefix /c\    $CFG->prefix    = "'${dbprefix}'";' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default
/bin/sed -i '/->dbuser /c\    $CFG->dbuser    = "'${DB_USERNAME}'";' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default
/bin/sed -i '/->dbname /c\    $CFG->dbname    = "'${DB_NAME}'";' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default
/bin/sed -i '/->dbpass /c\    $CFG->dbpass    = "'${DB_PASSWORD}'";' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default
/bin/sed -i '/->dbhost /c\    $CFG->dbhost    = "'${DB_IDENTIFIER}'";' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default
/bin/sed -i '/dbport/c\     "dbport" => "'${DB_PORT}'",' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default 
/bin/sed -i '0,/$CFG->wwwroot/ s/$CFG->wwwroot.*/$CFG->wwwroot = "https:\/\/'${WEBSITE_URL}'";/' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default
/bin/sed -i '0,/$CFG->dataroot/ s/$CFG->dataroot.*/$CFG->dataroot = "\/var\/www\/moodledata";/' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default 

${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/config.php.default moodle_config.php

if ( [ "`${BUILD_HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh moodle_config.php`" = "" ] )
then
        status "Didn't generate the moodle configuration file in the config datastore, this will cause trouble later"
fi



