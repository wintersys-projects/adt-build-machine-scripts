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
    /bin/echo "$1" | /usr/bin/tee /dev/fd/3
}

#################JOOMLA################
if ( [ -d ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/administrator ] && [ -d ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/modules ] && [ -d ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/plugins ] && [ -d ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/templates ] )
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
    read x
    #################JOOMLA################
    #################WORDPRESS################
elif ( [ -f ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/wp-login.php ] && [ -d ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/wp-content ] && [ -f ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/wp-cron.php ] && [ -d ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/wp-admin ] && [ -d ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/wp-includes ] && [ -f ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/wp-settings.php ] )
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
    read x
    #################WORDPRESS################
    #################MOODLE################
elif ( [ -f ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/moodle/index.php ] && [ -f ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/moodle/version.php ] && [ -d ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/moodle/userpix ] && [ -d ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/moodle/report ] && [ -d ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/moodle/enrol ] && [ -d ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/moodle/theme ] )
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
    read x
    #################MOODLE################
    #################DRUPAL################
elif ( [ -f ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/core/misc/drupal.js ] && [ -d ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/themes ] && [ -d ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/vendor ] && [ -d ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/modules ] && [ -d ${INTERROGATION_HOME}/${APPLICATION_BASELINE_SOURCECODE_REPOSITORY}/profiles ] )
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
    read x
    #################DRUPAL################
fi
