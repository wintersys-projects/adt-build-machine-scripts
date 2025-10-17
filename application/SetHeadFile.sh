#!/bin/sh
################################################################################
#Description: This scripts allows us to set the point of access to an application
# so that we can test whether it is online using curl. It isn't guaranteed that
# every application's point of access will be index.php and that is why we need this
# so we can customise our "head file" on an application by application basis
#Author: Peter Winter
#Date: 12/01/2024
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
###############################################################################
###############################################################################
#set -x

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

if ( [ "${APPLICATION_LANGUAGE}" = "HTML" ] )
then
	headfile="index.html"
elif ( [ "${APPLICATION_LANGUAGE}" = "PHP" ] )
then
	headfile="index.php"
	if ( [ "${APPLICATION}" = "joomla" ] )
	then
		headfile="index.php"
	fi
	if (  [ "${APPLICATION}" = "wordpress" ] )
	then
		headfile="index.php"
	fi
	if (  [ "${APPLICATION}" = "drupal" ] )
	then
		headfile="index.php"
	fi
	if (  [ "${APPLICATION}" = "moodle" ] )
	then
		headfile="index.php"
	fi
fi
