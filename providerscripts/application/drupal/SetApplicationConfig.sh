#!/bin/sh
####################################################################################
# Description: This sets up the database credentials and some other configuration
# settings necessary for the drupal application to be brought online
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

/usr/bin/perl -i -pe 'BEGIN{undef $/;} s/^\$databases.\;/\$databases = [];/smg' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default

if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Postgres" ] || ( [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] && [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep 'Postgres'`" != "" ] ) )
then
        credentialstring="\$databases ['default']['default'] =array (\n 'database' => '${DB_NAME}', \n 'username' => '${DB_USERNAME}', \n 'password' => '${DB_PASSWORD}', \n 'host' => '${DB_IDENTIFIER}', \n 'port' => '${DB_PORT}', \n 'driver' => 'pgsql', \n 'prefix' => '${dbprefix}', \n 'collation' => 'utf8mb4_general_ci',\n);"
else
        credentialstring="\$databases ['default']['default'] =array (\n 'database' => '${DB_NAME}', \n 'username' => '${DB_USERNAME}', \n 'password' => '${DB_PASSWORD}', \n 'host' => '${DB_IDENTIFIER}', \n 'port' => '${DB_PORT}', \n 'driver' => 'mysql', \n 'prefix' => '${dbprefix}', \n 'collation' => 'utf8mb4_general_ci',\n);"
fi

/bin/sed -i "/^\$databases/{:1;/;/!{N;b 1}
         s/.*/${credentialstring}/g}" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default

/bin/sed -i '/.*$settings\["file_temp_path"\]/c$settings["file_temp_path"] = "/tmp";' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default

if ( [ -f /var/www/html/salt ] )
then
        salt="`/bin/cat /var/www/html/salt`"
fi

if ( [ "${salt}" = "" ] )
then
        salt="`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-16 | /usr/bin/tr '[:upper:]' '[:lower:]'`"
fi

/bin/sed -i "/^\$settings\['hash_salt'\]/c\$settings['hash_salt'] = '${salt}';" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default

if ( [ "`/bin/grep 'ADDED BY CONFIG PROCESS' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default`" = "" ] )
then
        /bin/echo "#====ADDED BY CONFIG PROCESS=====" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default
        /bin/echo '$config["package_manager.settings"]["executables"]["composer"] = "/usr/local/bin/composer";' >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default
        /bin/echo '$config["package_manager.settings"]["executables"]["rsync"] = "/usr/bin/rsync";' >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default
        /bin/echo '$settings["trusted_host_patterns"] = [ ".*" ];' >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default
        /bin/echo '$settings["config_sync_directory"] = "/var/www/html/sites/default";'>>  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default
        /bin/echo '$config["system.performance"]["css"]["preprocess"] = FALSE;' >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default
        /bin/echo '$config["system.performance"]["js"]["preprocess"] = FALSE;' >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default
        /bin/echo '$settings["file_private_path"] = $app_root . "/../private";' >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default
fi

${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/settings.php.default drupal_settings.php
