#!/bin/sh
########################################################################################################
# Author: Peter Winter
# Date  : 13/01/2022
# Description : You can grant laptop ip addresses access to your build machine using this script.
# The firewall of your build machine will allow SSH connections from the ip address that you provide.
# You should also manually attach your build machine to a native firewall provided by your VPS vendor
# configured to allow the IP addresses of your laptop(s) access to your build machine  also.
# This gives "double firewalling" protection to your build-machine because it will hold a lot of your
# sensitive credentials on it
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

if ( [ "`/bin/ls /root/FIREWALL-BUCKET:*  2>/dev/null`" != "" ] )
then
	IDENTIFIER="`/bin/ls /root/FIREWALL-BUCKET:* | /usr/bin/awk -F':' '{print $NF}'  2>/dev/null`"
else
	/bin/echo "You can't run this script until you have performed at least one deployment of your web property"
	/bin/echo "When you make your first deployment this will tell me the access and secret keys that I need to access your datastore"
	/bin/echo "Without access to your datastore, this mecahnism won't work"
	exit
fi

if ( [ ! -f  ./AllowLaptopIP.sh ] )
then
	/bin/echo "Sorry, this script has to be run from the helperscripts subdirectory"
	exit
fi

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
BUILD_IDENTIFIER="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER`"

/bin/echo "Which datastore provider are you using? 1) Digital Ocean 2) Exoscale 3) Linode 4) Vultr. Please Enter the number for your cloudhost"
read response
if ( [ "${response}" = "1" ] )
then
	DATASTORE_PROVIDER="digitalocean"
elif ( [ "${response}" = "2" ] )
then
	DATASTORE_PROVIDER="exoscale"
elif ( [ "${response}" = "3" ] )
then
	DATASTORE_PROVIDER="linode"
elif ( [ "${response}" = "4" ] )
then
	DATASTORE_PROVIDER="vultr"
else
	/bin/echo "Unrecognised  cloudhost. Exiting ...."
	exit
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

if ( [ ! -d ${BUILD_HOME}/runtimedata/${DATASTORE_PROVIDER}/${BUILD_IDENTIFIER}/ips ] )
then
	/bin/mkdir -p ${BUILD_HOME}/runtimedata/${DATASTORE_PROVIDER}/${BUILD_IDENTIFIER}/ips
fi

/bin/echo "Please enter the IP address of your laptop that you are modifying access for. You can find the ip address of your laptop using: www.whatsmyip.com"
read ip

/bin/echo "Do you want to add or remove access for this ip address?"
/bin/echo "1) Add  2) Remove"
read mode

while ( [ "`/bin/echo "1 2" | /bin/grep ${mode}`" = "" ] )
do
	/bin/echo "I don't recognise that input..."
	/bin/echo "Please enter 1 or 2"
	read mode
done

${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${IDENTIFIER}/authorised-ips.dat ${BUILD_HOME}/runtimedata/${DATASTORE_PROVIDER}/${BUILD_IDENTIFIER}/ips

if ( [ ! -f ${BUILD_HOME}/runtimedata/${DATASTORE_PROVIDER}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat ] )
then
	/bin/echo "Couldn't find existing authorised ip addresses"
	${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh ${IDENTIFIER}
fi

if ( [ "${mode}" = "1" ] )
then
	/bin/echo ${ip} >> ${BUILD_HOME}/runtimedata/${DATASTORE_PROVIDER}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat
else
	/bin/sed -i "/${ip}/d" ${BUILD_HOME}/runtimedata/${DATASTORE_PROVIDER}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat
fi

/bin/cat ${BUILD_HOME}/runtimedata/${DATASTORE_PROVIDER}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat | /usr/bin/sort | /usr/bin/uniq >> ${BUILD_HOME}/runtimedata/${DATASTORE_PROVIDER}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat.$$
/bin/mv ${BUILD_HOME}/runtimedata/${DATASTORE_PROVIDER}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat.$$ ${BUILD_HOME}/runtimedata/${DATASTORE_PROVIDER}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat
${BUILD_HOME}/providerscripts/datastore/PutToDatastore.sh ${BUILD_HOME}/runtimedata/${DATASTORE_PROVIDER}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat ${IDENTIFIER}/authorised-ips.dat
/bin/touch  ${BUILD_HOME}/runtimedata/${DATASTORE_PROVIDER}/${BUILD_IDENTIFIER}/FIREWALL-EVENT
${BUILD_HOME}/providerscripts/datastore/PutToDatastore.sh ${BUILD_HOME}/runtimedata/${DATASTORE_PROVIDER}/${BUILD_IDENTIFIER}/FIREWALL-EVENT ${IDENTIFIER}/FIREWALL-EVENT
/bin/rm ${BUILD_HOME}/runtimedata/${DATASTORE_PROVIDER}/${BUILD_IDENTIFIER}/FIREWALL-EVENT
