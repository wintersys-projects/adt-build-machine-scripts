#!/bin/sh
####################################################################################
# Description: This sets up the database credentials and some other configuration
# settings necessary for the joomla application to be brought online
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

if ( [ ! -d  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application ] )
then
        /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application
fi

/bin/cp ${BUILD_HOME}/application/descriptors/${APPLICATION}.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat

if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Postgres" ] || ( [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] && [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep 'Postgres'`" != "" ] ) )
then
        DB_TYPE="pgsql"
else
        DB_TYPE="mysqli"
fi

if ( [ "${SYSTEM_EMAIL_PROVIDER}" = "1" ] )
then
        smtp_port="2525"
        smtp_host="smtp-pulse.com"
elif ( [ "${SYSTEM_EMAIL_PROVIDER}" = "2" ] )
then
        smtp_port="2525"
        smtp_host="email-smtp.eu-west-1.amazonaws.com"
elif ( [ "${SYSTEM_EMAIL_PROVIDER}" = "3" ] )
then
        smtp_port="587"
        smtp_host="in.mailjet.com"
fi

SYSTEM_FROMEMAIL_ADDRESS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'SYSTEM_FROMEMAIL_ADDRESS'`"
SYSTEM_TOEMAIL_ADDRESS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'SYSTEM_TOEMAIL_ADDRESS'`"
WEBSITE_DISPLAY_NAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'WEBSITE_DISPLAY_NAME'` Webmaster"
SYSTEM_EMAIL_USERNAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'SYSTEM_EMAIL_USERNAME'`"
SYSTEM_EMAIL_PASSWORD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'SYSTEM_EMAIL_PASSWORD'`"

#APPLICATION_VERSION=="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'JOOMLA_VERSION'`"

#/bin/sed -i "s/XXXXAPPLICATION_VERSIONXXXX/${APPLICATION_VERSION}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXAPPLICATION_USERNAMEXXXX/${DB_USERNAME}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXAPPLICATION_PASSWORDXXXX/${DB_PASSWORD}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXAPPLICATION_DATABASEXXXX/${DB_NAME}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXAPPLICATION_DB_HOSTXXXX/${DB_IDENTIFIER}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXAPPLICATION_DB_PORTXXXX/${DB_PORT}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXAPPLICATION_DB_TYPEXXXX/${DB_TYPE}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat


/bin/sed -i "s/XXXXMAILERXXXX/smtp/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXMAIL_FROMXXXX/${SYSTEM_FROMEMAIL_ADDRESS}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXREPLY_TOXXXX/${SYSTEM_TOEMAIL_ADDRESS}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXFROM_NAMEXXXX/${WEBSITE_DISPLAY_NAME}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXREPLY_TO_NAMEXXXX/smtp/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXSMTP_AUTHXXXX/1/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXSMTP_USERXXXX/${SYSTEM_EMAIL_USERNAME}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXSMTP_PASSXXXX/${SYSTEM_EMAIL_PASSWORD}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXSMTP_SECUREXXXX/tls/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXSMTP_PORTXXXX/${smtp_port}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXSMTP_HOSTXXXX/${smtp_host}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat


