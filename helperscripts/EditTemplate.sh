#!/bin/sh
###########################################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This will let you edit your template as you choose
# There is a wrapper script ${BUILD_HOME}/Template.sh that calls this script and is easier to use
###########################################################################################################
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

BUILD_HOME="`/bin/cat /home/buildhome.dat`" 

if ( [ "${1}" != "" ] && [ "${2}" != "" ] )
then
	CLOUDHOST="${1}"
	template="${2}"
else
	/bin/echo "Which cloudhost do you want to view logs for (1)DigitalOcean, (2)Exoscale, (3)Linode or (4)Vultr"
	read response

	if ( [ "${response}" = "1" ] )
	then
		CLOUDHOST="digitalocean"
	fi
	if ( [ "${response}" = "2" ] )
	then
		CLOUDHOST="exoscale"
	fi
	if ( [ "${response}" = "3" ] )
	then
		CLOUDHOST="linode"
	fi
	if ( [ "${response}" = "4" ] )
	then
		CLOUDHOST="vultr"
	fi

	if ( [ "${CLOUDHOST}" != "`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_CLOUDHOST`" ] )
	then
		/bin/echo "Your chosen cloudhost provider is different to your active cloudhost provider on this build machine"
		/bin/echo "Do you want to set your chosen cloudhost to be the active cloudhost provider (Y|y)"
		read response
		if ( [ "${response}" = "Y" ] || [ "${response}" = "y" ] )
		then
			/bin/echo "${CLOUDHOST}" > ${BUILD_HOME}/runtimedata/ACTIVE_CLOUDHOST
		fi
	fi

	/bin/echo "The following templates are available, which one do you want?"
	/bin/ls ${BUILD_HOME}/templatedconfigurations/templates/${CLOUDHOST}/*tmpl | /usr/bin/awk -F'/' '{print $NF}'

	/bin/echo "Type the name of the template you want from the list above"
	read template
fi

/usr/bin/vi ${BUILD_HOME}/templatedconfigurations/templates/${CLOUDHOST}/${template}
