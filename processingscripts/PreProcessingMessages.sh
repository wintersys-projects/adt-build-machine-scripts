#!/bin/sh
###############################################################################################
# Description: Not all providers play the same so if you have any preprocessing messages you want
# to display before the build begins, you can add then into this file and it will get executed
# prior to the build commencing.
# Author: Peter Winter
# Date : 17/01/2017
###############################################################################################
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
#set -x

status ""
status ""
status "#########################################"
status "You are deploying to region: ${REGION}"
status "#########################################"
status ""

if ( [ "${PRODUCTION}" = "1" ] )
then
	status "############################################"
	status "Number of autoscalers is set to: ${NO_AUTOSCALERS}"
	status "############################################"
fi

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
	export ENABLE_DDOS_PROTECION="0"
	status "You are deploying to the Vultr VPS cloud which has an option to switch on DDOS protection for your machines."
	status "If you want to switch on DDOS projection, enter 'Y' or 'y' below, anything else and DDOS protection won't be enabled". 
	status " DDoS Protection adds 10Gbps of mitigation capacity per instance and costs an additional \$10/mo."
	status "Do you want to enable DDOS protection 'Y' or 'N'"
	if ( [ "${HARDCORE}" != "1" ] )
	then
		read response

		if ( [ "${response}" = "Y" ] || [ "${response}" = "y" ] )
		then
		   status "DDOS protection has been enabled"
		   status "Press <enter>"
		   read x
		   export ENABLE_DDOS_PROTECION="1"
		else
		   status "DDOS protection has not been enabled"
		   status "Press <enter>"
		   read x
		fi
	fi
fi

if ( [ "${APPLICATION}" = "joomla" ] && [ "${APPLICATION_IDENTIFIER}" != "1" ] )
then
	status "Your application is set to joomla and your application identifier is set to ${APPLICATION_IDENTIFIER}"
	status "The application identifier must be set to 1 for joomla otherwise bad things can happen"
	status "I am setting your application identifier to 1"
	export APPLICATION_IDENTIFIER="1"
	export APPLICATION="joomla"
	status "Press <enter> to accept"
	if ( [ "${HARDCORE}" != "1" ] )
	then
		read x
	fi
fi

if ( [ "${APPLICATION}" = "wordpress" ] && [ "${APPLICATION_IDENTIFIER}" != "2" ] )
then
	status "Your application is set to wordpress and your application identifier is set to ${APPLICATION_IDENTIFIER}"
	status "The application identifier must be set to 2 for wordpress otherwise bad things can happen"
	status "I am setting your application identifier to 2"
	export APPLICATION_IDENTIFIER="2"
	export APPLICATION="wordpress"
	status "Press <enter> to accept"
	if ( [ "${HARDCORE}" != "1" ] )
	then
		read x
	fi
fi

if ( [ "${APPLICATION}" = "drupal" ] && [ "${APPLICATION_IDENTIFIER}" != "3" ] )
then
	status "Your application is set to drupal and your application identifier is set to ${APPLICATION_IDENTIFIER}"
	status "The application identifier must be set to 3 for drupal otherwise bad things can happen"
	status "I am setting your application identifier to 3"
	export APPLICATION_IDENTIFIER="3"
	export APPLICATION="drupal"
	status "Press <enter> to accept"
	if ( [ "${HARDCORE}" != "1" ] )
	then
		read x
	fi
fi

if ( [ "${APPLICATION}" = "moodle" ] && [ "${APPLICATION_IDENTIFIER}" != "4" ] )
then
	status "Your application is set to moodle and your application identifier is set to ${APPLICATION_IDENTIFIER}"
	status "The application identifier must be set to 4 for moodle otherwise bad things can happen"
	status "I am setting your application identifier to 4"
	export APPLICATION_IDENTIFIER="4"
	export APPLICATION="moodle"
	status "Press <enter> to accept"
	if ( [ "${HARDCORE}" != "1" ] )
	then
		read x
	fi
fi

if ( [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] || [ "${BUILD_ARCHIVE_CHOICE}" = "baseline" ] )
then
	PRODUCTION="0"
	DEVELOPMENT="1"
fi

if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Postgres" ] && [ "${APPLICATION}" = "wordpress" ] )
then
	status "################################################################"
	status "Apologies, but, Wordpress doesn't support the Postgres Database."
	status "I am defaulting to mariadb. Press <enter> to acknowledge"
	status "################################################################"
	if ( [ "${HARDCORE}" != "1" ] )
	then
		read x
	fi
	DATABASE_INSTALLATION_TYPE="Maria"
fi

if ( ( [ "${DATABASE_INSTALLATION_TYPE}" = "Postgres" ] || [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep "Postgres" 2>/dev/null`" != "" ] ) && [ "${APPLICATION}" = "joomla" ] )
then
	if ( [ "${DB_PORT}" != "5432" ] )
	then
		status "################################################################"
		status "Sorry, I don't know how to set anything other than the default port - 5432 for the postgres database when using joomla"
		status "Setting expected postgres port to 5432"
		status "################################################################"
		export DB_PORT=5432
	fi
fi


if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Postgres" ] || [ "${DATABASE_DBaaS_INSTALLATION_TYPE}" = "Postgres" ] )
then
	response=""

	if ( [ "${DBaaS_DBNAME}" != "" ] )
	then
		if ( [ "${HARDCORE}" != "1" ] )
		then
			/bin/bash -c "[[ '${DBaaS_DBNAME}' =~ [A-Z] ]] && /bin/touch ${BUILD_HOME}/LOWER && /bin/echo 'I know this is your worst nightmare, but, please read carefully. I have detected that you have some upper case letters in the databse name for your postgres database. By default postgres sets the database names to lower case and so chances are, this is what your postgres has done. Please review this to see if it is the case, but I thought I would give you a chance to change your database name to all lower case.' && /bin/echo && /bin/echo 'Your database name is currently set to: ${DBaaS_DBNAME}.' && /bin/echo 'enter (Y|y) and I will set the characters  of your database name all to lower case for you...' && /bin/echo 'Press <enter> to leave as it is '"
	   
			if ( [ -f ${BUILD_HOME}/LOWER ] )
			then
				read response
			fi
	   
			if ( [ "${response}" = "Y" ] || [ "${response}" = "y" ] )
			then
				if ( [ -f ${BUILD_HOME}/LOWER ] )
				then
					/bin/rm ${BUILD_HOME}/LOWER
					DBaaS_DBNAME="`/bin/echo "${DBaaS_DBNAME}" | /usr/bin/tr '[:upper:]' '[:lower:]'`"
				fi
			fi
		
			if ( [ -f ${BUILD_HOME}/LOWER ] )
			then
				status "#################################################"
				status "Your database name is now set to: ${DBaaS_DBNAME}"
				status "Press <enter> to accept"
				status "#################################################"
				read x
			fi
		fi
	fi
fi


