#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 11/08/2021
# Description: This script is run to push changes made in the development area to the
# appropriate git repository and also syncs the development area with the live scripts
#######################################################################################
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

/bin/echo "This script will push the scripts in the development area to the git repository and will sync the development script area with the live script area"
/bin/echo "Press <enter> to perform sync <ctrl-c> to exit"
read x

commit_message="${1}"
branch="${2}"

if ( [ "${branch}" = "" ] )
then
        BRANCH="`/bin/grep "^GITBRANCH:" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`"
else
        BRANCH="${branch}"
fi

if ( [ "${BRANCH}" = "main" ] )
then
        /bin/echo "Direct pushes to the main branch are not allowed"
        exit
elif ( [ "${BRANCH}" = "" ] )
then
        /bin/echo "There is no branch set"
        exit
fi

if ( [ "${commit_message}" = "" ] )
then
        /bin/echo "Commit message not set"
        exit
fi

/bin/echo "Attempting to push to branch ${BRANCH} with commit message '"${commit_message}"'"
/bin/echo "Press <enter> to confirm <ctrl-c> to exit"
read x

GIT_USER="`${HOME}/utilities/config/ExtractConfigValue.sh 'GITUSER'`"
GIT_EMAIL_ADDRESS="`${HOME}/utilities/config/ExtractConfigValue.sh 'GITEMAILADDRESS'`"

/usr/bin/git config --global user.email "${GIT_EMAIL_ADDRESS}"
/usr/bin/git config --global user.name "${GIT_USER}"

/usr/bin/git add . 

/bin/echo "Press <enter> to commit and push these files to the git repo <ctrl-c> to abort"
read x

/usr/bin/git commit -m "${commit_message}"
/usr/bin/git push -u origin ${BRANCH}

/usr/bin/rsync -a /home/development/ ${HOME}
/bin/chown -R www-data:www-data ${HOME}
