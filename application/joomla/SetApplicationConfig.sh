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

WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'WEBSITE_URL'`"
WEBSITE_PASSWORD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'S3_ACCESS_KEY' | /usr/bin/head -c 8`"
WEBMASTER_EMAIL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'SYSTEM_TOEMAIL_ADDRESS'`"

if ( [ "${WEBMASTER_EMAIL}" = "" ] )
then
        WEBMASTER_EMAIL="changeme@adt-installation-bootstrap.uk"
fi

if ( [ ! -d  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application ] )
then
        /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application
fi

/bin/cp ${BUILD_HOME}/application/descriptors/${APPLICATION}.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat

SYSTEM_EMAIL_PROVIDER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'SYSTEM_EMAIL_PROVIDER'`"
SYSTEM_FROMEMAIL_ADDRESS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'SYSTEM_FROMEMAIL_ADDRESS' | /bin/sed 's/_/ /g'`"
SYSTEM_TOEMAIL_ADDRESS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'SYSTEM_TOEMAIL_ADDRESS' | /bin/sed 's/_/ /g'`"
WEBSITE_DISPLAY_NAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'WEBSITE_DISPLAY_NAME'` Webmaster"
SYSTEM_EMAIL_USERNAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'SYSTEM_EMAIL_USERNAME'`"
SYSTEM_EMAIL_PASSWORD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh 'SYSTEM_EMAIL_PASSWORD'`"

if ( [ "${SYSTEM_EMAIL_PROVIDER}" = "1" ] )
then
        smtp_port="2525"
        smtp_host="smtp-pulse.com"
elif ( [ "${SYSTEM_EMAIL_PROVIDER}" = "2" ] )
then
        smtp_port="587"
        smtp_host="in.mailjet.com"
elif ( [ "${SYSTEM_EMAIL_PROVIDER}" = "3" ] )
then
        smtp_port="2525"
        smtp_host="email-smtp.eu-west-1.amazonaws.com"
fi

/bin/sed -i "s/XXXXAPPLICATION_USERNAMEXXXX/${DB_USERNAME}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXAPPLICATION_PASSWORDXXXX/${DB_PASSWORD}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXAPPLICATION_DATABASEXXXX/${DB_NAME}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXWEBSITE_URLXXXX/${WEBSITE_URL}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXWEBSITE_PASSWORDXXXX/${WEBSITE_PASSWORD}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXWEBMASTER_EMAILXXXX/${WEBMASTER_EMAIL}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat

/bin/sed -i "s/XXXXMAILERXXXX/smtp/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXMAIL_FROMXXXX/${SYSTEM_FROMEMAIL_ADDRESS}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXREPLY_TOXXXX/${SYSTEM_TOEMAIL_ADDRESS}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXFROM_NAMEXXXX/${WEBSITE_DISPLAY_NAME}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXREPLY_TO_NAMEXXXX/${WEBSITE_DISPLAY_NAME}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXSMTP_AUTHXXXX/1/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXSMTP_USERXXXX/${SYSTEM_EMAIL_USERNAME}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXSMTP_PASSXXXX/${SYSTEM_EMAIL_PASSWORD}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXSMTP_SECUREXXXX/tls/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXSMTP_PORTXXXX/${smtp_port}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat
/bin/sed -i "s/XXXXSMTP_HOSTXXXX/${smtp_host}/" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/application/${APPLICATION}.dat


