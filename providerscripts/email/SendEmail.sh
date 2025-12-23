#!/bin/sh
################################################################################
# Description: This script is used for sending system emails. Scripts can make use
# of this whenever they need to send a system notification. 
# Date: 16-11-2016
# Author: Peter Winter
##################################################################################
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

subject="$1"
message="$2"
level="$3"
to_address="$4"
content_type="$5"
authentication="${6}"

if ( ( [ "${level}" = "ERROR" ] || [ "${level}" = "INFO" ] || [ "${level}" = "MANDATORY" ] ) && [ "${authentication}" != "AUTHENTICATION" ] )
then
	ip_address="`${HOME}/utilities/processing/GetPublicIP.sh`"
	message="MESSAGE RELATED TO MACHINE WITH IP ADDRESS: ${ip_address}: ${message}"
fi

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
FROM_ADDRESS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SYSTEM_FROM_EMAIL_ADDRESS`"
FROM_NAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITEDISPLAYNAME | /usr/bin/sed 's/_//g'`"
TO_ADDRESS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SYSTEM_FROM_TO_ADDRESS`"


if ( [ "${to_address}" != "" ] )
then
	TO_ADDRESS="${to_address}"
fi

USERNAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh EMAILUSERNAME`"
PASSWORD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh EMAILPASSWORD`"
EMAIL_PROVIDER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh EMAILPROVIDER`"


if ( [ "${level}" != "MANDATORY" ] && [ "`${BUILD_HOME}/helperscripts/GetVariableValue.sh EMAILNOTIFICATIONLEVEL`" = "ERROR" ] && [ "${level}" != "ERROR" ] )
then
	exit
fi

if ( [ "${FROM_ADDRESS}" != "" ] && [ "${TO_ADDRESS}" != "" ] && [ "${USERNAME}" != "" ] && [ "${PASSWORD}" != "" ] && [ "${subject}" != "" ] && [ "${message}" != "" ] )
then
	if ( [ "`/bin/grep "^EMAILUTIL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep EMAILUTIL:sendemail`" != "" ] )
	then
		if ( [ "${EMAIL_PROVIDER}" = "1" ] )
		then
			/usr/bin/sendemail -o tls=no -f ${FROM_ADDRESS} -t ${TO_ADDRESS} -s smtp-pulse.com:2525 -xu ${USERNAME} -xp ${PASSWORD} -u "${subject} `/bin/date`" -m ${message}
		fi
		if ( [ "${EMAIL_PROVIDER}" = "2" ] )
		then
			/usr/bin/sendemail -o tls=no -f ${FROM_ADDRESS} -t ${TO_ADDRESS} -s in.mailjet.com:2525 -xu ${USERNAME} -xp ${PASSWORD} -u "${subject} `/bin/date`" -m ${message}    		
		fi
		if ( [ "${EMAIL_PROVIDER}" = "3" ] )
		then
			/usr/bin/sendemail -o tls=no -f ${FROM_ADDRESS} -t ${TO_ADDRESS} -s email-smtp.eu-west-1.amazonaws.com -xu ${USERNAME} -xp ${PASSWORD} -u "${subject} `/bin/date`" -m ${message}
		fi
	fi

	if ( [ "`/bin/grep "^EMAILUTIL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep EMAILUTIL:ssmtp`" != "" ] )
	then
		if ( [ ! -f ${HOME}/runtime/SSMTP_INITIALISED ] )
		then
			if ( [ "${EMAIL_PROVIDER}" = "1" ] )
			then
				/bin/echo "mailhub=smtp-pulse.com:2525" >> /etc/ssmtp/ssmtp.conf
			fi
			if ( [ "${EMAIL_PROVIDER}" = "2" ] )
			then
				/bin/echo "mailhub=in-v3.mailjet.com:587" >> /etc/ssmtp/ssmtp.conf
			fi
			if ( [ "${EMAIL_PROVIDER}" = "3" ] )
			then
				/bin/echo "mailhub=email-smtp.eu-west-1.amazonaws.com" >> /etc/ssmtp/ssmtp.conf
			fi

			/bin/echo "AuthUser=${USERNAME}" >> /etc/ssmtp/ssmtp.conf
			/bin/echo "AuthPass=${PASSWORD}" >> /etc/ssmtp/ssmtp.conf
			/bin/echo "FromLineOverride=YES" >> /etc/ssmtp/ssmtp.conf
			/bin/echo "UseSTARTTLS=YES" >> /etc/ssmtp/ssmtp.conf
			/bin/touch ${HOME}/runtime/SSMTP_INITIALISED
		fi

		if ( [ "${content_type}" = "HTML" ] )
		then
			/bin/echo "${message}" | /usr/bin/mail -s "${subject}" -a "From: ${FROM_NAME} <${FROM_ADDRESS}>" "${TO_ADDRESS}" -a 'Content-Type: text/html'
		else
			/bin/echo "${message}" | /usr/bin/mail -s "${subject}" -a "From: ${FROM_NAME} <${FROM_ADDRESS}>" "${TO_ADDRESS}"
		fi
	fi
else
	status "`/bin/date`:Email not sent because of missing parameter(s)"
fi
