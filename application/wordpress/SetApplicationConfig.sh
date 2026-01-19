#!/bin/sh
####################################################################################
# Description: This sets up the database credentials and some other configuration
# settings necessary for the wordpress application to be brought online
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

WEBSERVER_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSERVER_CHOICE`"

if ( [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/dbp.dat ] )
then
        status "Error, cannot find database prefix file"
fi

dbprefix="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/dbp.dat`"
/bin/sed -i '/DB_HOST/c\ define("DB_HOST", "'${DB_IDENTIFIER}:${DB_PORT}'");' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/wp-config.php.default
/bin/sed -i '/DB_USER/c\ define("DB_USER", "'${DB_USERNAME}'");' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/wp-config.php.default
/bin/sed -i '/DB_PASSWORD/c\ define("DB_PASSWORD", "'${DB_PASSWORD}'");' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/wp-config.php.default
/bin/sed -i '/DB_NAME/c\ define("DB_NAME", "'${DB_NAME}'");' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/wp-config.php.default
/bin/sed -i '/\$table_prefix/c\ \$table_prefix="'${dbprefix}'";' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/wp-config.php.default

if ( [ "`/bin/grep SALTEDALREADY ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/wp-config.php.default`" = "" ] )
then
        /bin/sed -i "/'AUTH_KEY'/i XXYYZZ" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/wp-config.php.default
        /bin/sed -i '/AUTH_KEY/,+7d' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/wp-config.php.default
        salts="`/usr/bin/curl https://api.wordpress.org/secret-key/1.1/salt`"
        /bin/sed -n '/XXYYZZ/q;p' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/wp-config.php.default > /tmp/firsthalf
        /bin/sed '0,/^XXYYZZ$/d' ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/wp-config.php.default > /tmp/secondhalf
        /bin/cat /tmp/firsthalf > /tmp/fullfile
        /bin/echo ${salts} >> /tmp/fullfile
        /bin/echo "/* SALTEDALREADY */" >> /tmp/fullfile
        /bin/echo "define( 'DISALLOW_FILE_EDIT', true );" >> /tmp/fullfile
        /bin/echo "define('WP_CACHE', false);" >> /tmp/fullfile
        /bin/echo "define('CONCATENATE_SCRIPTS', false);" >> /tmp/fullfile #Was occassionally getting display issues in the admin area if set to true
        /bin/echo "define('COMPRESS_SCRIPTS', true);" >> /tmp/fullfile
        /bin/echo "define('COMPRESS_CSS', true);" >> /tmp/fullfile
        /bin/echo "define('DISABLE_WP_CRON', true);" >> /tmp/fullfile
        /bin/cat /tmp/secondhalf >> /tmp/fullfile
        /bin/rm /tmp/firsthalf /tmp/secondhalf
        /bin/mv /tmp/fullfile ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/wp-config.php.default
fi

/bin/mv ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/wp-config.php.default ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/wordpress_config.ph
${BUILD_HOME}/providerscripts/datastore/config/toolkit/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/wordpress_config.php "root" "no"

if ( [ "`${BUILD_HOME}/providerscripts/datastore/config/toolkit/ListFromConfigDatastore.sh wordpress_config.php`" = "" ] )
then
        status "Didn't generate the wordpress configuration file in the config datastore, this will cause trouble later"
fi
