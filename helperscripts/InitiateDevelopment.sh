#!/bin/sh
########################################################################################################
# Author: Peter Winter
# Date  : 13/01/2022
# Description : This script will clone the current latest version of the ADT infrastructure repositories
# based on which provider you have them hosted with, the username of the account they are hosted under
# and the branch that you wish to develop against.
# If there are any other development directories that exist when this script is run those directories are
# archived and the results of this being run becomes the current active development. For example, if you were
# developing against another branch and you re-ran this then the branch that you specify here would become
# the branch that you are developing against and any previous development arrangements would be archived
# as ${BUILD_HOME}/development.archive.$$
########################################################################################################
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
#######################################################################################################
#######################################################################################################
#set -x

if ( [ ! -f  ./InitiateDevelopment.sh ] )
then
	/bin/echo "Sorry, this script has to be run from the helperscripts subdirectory"
	exit
fi

/bin/echo "Please enter the username for the git account where your repositories are hosted"
read username

/bin/echo "Please enter the name of the branch that you wish to clone"
read branch

/bin/echo "Which provider are your adt infrastructure repositories hosted with?"
/bin/echo "1) Github 2) Bitbucket 3) GitLab"
read provider

while ( [ "`/bin/echo 1 2 3 | /bin/grep ${provider}`" = "" ] )
do
        /bin/echo "That is not a valid provider, please try again"
        read provider
done

if ( [ "${[provider}" = "1" ] )
then
        provider="github.com"
elif ( [ "${[provider}" = "2" ] )
then
        provider="bitbucket.org"
elif ( [ "${[provider}" = "3" ] )
then
        provider="gitlab.com"
fi


BUILD_HOME="`/bin/cat /home/buildhome.dat`"

if ( [ -d ${BUILD_HOME}/development ] )
then
        /bin/mv ${BUILD_HOME}/development ${BUILD_HOME}/development.archive.$$
fi

if ( [ ! -d ${BUILD_HOME}/development ] )
then
        /bin/mkdir -p ${BUILD_HOME}/development/autoscaler
        /bin/mkdir -p ${BUILD_HOME}/development/webserver
        /bin/mkdir -p ${BUILD_HOME}/development/database
fi

/bin/echo "USERNAME:${username}" > ${BUILD_HOME}/development/.config
/bin/echo "BRANCH:${branch}" >> ${BUILD_HOME}/development/.config
/bin/echo "PROVIDER:${provider}" >> ${BUILD_HOME}/development/.config


/usr/bin/git clone  -b ${branch} --single-branch https://${provider}/${username}/adt-autoscaler-scripts.git ${BUILD_HOME}/development/autoscaler
/usr/bin/git clone  -b ${branch} --single-branch https://${provider}/${username}/adt-webserver-scripts.git ${BUILD_HOME}/development/webserver
/usr/bin/git clone  -b ${branch} --single-branch https://${provider}/${username}/adt-database-scripts.git ${BUILD_HOME}/development/database
