#!/bin/sh
#################################################################################
# Description: Ths script will work out what kind of application you are deploying
# from a backup stored in your datastore
# Author: Peter Winter
# Date: 02/01/2017
#################################################################################
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
###################################################################################
###################################################################################
#set -x

status () {
    /bin/echo "$1" | /usr/bin/tee /dev/fd/3
}

#################JOOMLA################
if ( [ -d ${INTERROGATION_HOME}/tmp/backup/administrator ] && [ -d ${INTERROGATION_HOME}/tmp/backup/modules ] && [ -d ${INTERROGATION_HOME}/tmp/backup/plugins ] && [ -d ${INTERROGATION_HOME}/tmp/backup/templates ] )
then
    /bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/APPLICATION:joomla
    APPLICATION="joomla"
    if ( [ "${DIRECTORIES_TO_MOUNT}" = "" ] )
    then
        DIRECTORIES_TO_MOUNT="images"
    fi
    status "Discovered you are deploying joomla from a datastore backup"
    status "Press the <enter> key to accept as true"
    read x
    #################JOOMLA################
    #################WORDPRESS################
elif ( [ -f ${INTERROGATION_HOME}/tmp/backup/wp-login.php ] && [ -d ${INTERROGATION_HOME}/tmp/backup/wp-content ] && [ -f ${INTERROGATION_HOME}/tmp/backup/wp-cron.php ] && [ -d ${INTERROGATION_HOME}/tmp/backup/wp-admin ] && [ -d ${INTERROGATION_HOME}/tmp/backup/wp-includes ] && [ -f ${INTERROGATION_HOME}/tmp/backup/wp-settings.php ] )
then
    /bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/APPLICATION:wordpress
    APPLICATION="wordpress"
    if ( [ "${DIRECTORIES_TO_MOUNT}" = "" ] )
    then
        DIRECTORIES_TO_MOUNT="wp-content.uploads"
    fi
    status "Discovered you are deploying wordpress from a datastore backup"
    status "Press the <enter> key to accept as true"
    read x
    #################WORDPRESS################
    #################MOODLE################
elif ( [ -f ${INTERROGATION_HOME}/tmp/backup/moodle/index.php ] && [ -f ${INTERROGATION_HOME}/tmp/backup/moodle/version.php ] && [ -d ${INTERROGATION_HOME}/tmp/backup/moodle/userpix ] && [ -d ${INTERROGATION_HOME}/tmp/backup/moodle/report ] && [ -d ${INTERROGATION_HOME}/tmp/backup/moodle/enrol ] && [ -d ${INTERROGATION_HOME}/tmp/backup/moodle/theme ] )
then
    /bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/APPLICATION:moodle
    APPLICATION="moodle"
    if ( [ "${DIRECTORIES_TO_MOUNT}" = "" ] )
    then
        DIRECTORIES_TO_MOUNT="moodledata.filedir"
    fi
    status "Discovered you are deploying moodle from a datastore backup"
    status "Press the <enter> key to accept as true"
    read x
    #################MOODLE################
    #################DRUPAL################
elif ( [ -f ${INTERROGATION_HOME}/tmp/backup/core/misc/drupal.js ] && [ -d ${INTERROGATION_HOME}/tmp/backup/themes ] && [ -d ${INTERROGATION_HOME}/tmp/backup/vendor ] && [ -d ${INTERROGATION_HOME}/tmp/backup/modules ] && [ -d ${INTERROGATION_HOME}/tmp/backup/profiles ] )
then
    /bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/APPLICATION:drupal
    APPLICATION="drupal"
    if ( [ "${DIRECTORIES_TO_MOUNT}" = "" ] )
    then
        DIRECTORIES_TO_MOUNT="sites.default.files.pictures:sites.default.files.styles:sites.default.files.inline-images"
    fi
    status "Discovered you are deploying drupalfrom a datastore backup"
    status "Press the <enter> key to accept as true"
    read x
    #################DRUPAL################
fi
