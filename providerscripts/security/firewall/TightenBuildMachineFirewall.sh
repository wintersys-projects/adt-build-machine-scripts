#!/bin/sh
######################################################################################################
# Description: By creating a file: s3://authip-adt-allowed-RND/authorised-ips.dat in your S3 style datastore with a list
# of ipaddresses, you can allow only machines with your listed ip addresses to access your build machine.
# The file authorised-ips.dat should be formatted with ip addresses on successive lines, for example:
#
# 111.111.111.111
# 222.222.222.222
#
# Would allow machines with ip addresses 111.111.111.111 and 222.222.222.222 to connect to your build machine
# Author: Peter Winter
# Date: 17/01/2021
#######################################################################################################
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
set -x

if ( [ -f /var/spool/cron/crontabs/root ] )
then
	/bin/sed -i "/^#/d" /var/spool/cron/crontabs/root
fi

if ( [ "${1}" != "" ] )
then
	BUILD_HOME="${1}"
fi

if ( [ "${2}" != "" ] )
then
	DATASTORE_CHOICE="${2}"
fi

if ( [ "${3}" != "" ] )
then
	CLOUDHOST="${3}"
fi

ip="`${BUILD_HOME}/helperscripts/GetBuildClientIP.sh`"
${BUILD_HOME}/providerscripts/server/GetServerName.sh ${ip} "" "1" 2>/dev/null

if ( [ "${CLOUDHOST}" != "`/bin/cat ${BUILD_HOME}/runtimedata/BUILD_MACHINE_CLOUDHOST`" ] )
then
	CLOUDHOST="`${BUILD_HOME}/runtimedata/BUILD_MACHINE_CLOUDHOST`"
fi

if ( [ "`/bin/ls /root/FIREWALL-BUCKET:* 2>/dev/null`" = "" ] )
then
	IDENTIFIER="authip-adt-allowed-`/usr/bin/tr -dc a-z0-9 </dev/urandom | /usr/bin/head -c 6; echo`"
	/bin/touch /root/FIREWALL-BUCKET:${IDENTIFIER}
else
	IDENTIFIER="`/bin/ls /root/FIREWALL-BUCKET:* | /usr/bin/awk -F':' '{print $NF}'  2>/dev/null`"
fi

${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh ${DATASTORE_CHOICE} "${IDENTIFIER}" "${BUILD_HOME}"

if ( [ "`/usr/bin/crontab -l | /bin/grep Tighten | /bin/grep ${IDENTIFIER}`" = "" ] )
then
	/bin/echo "*/1 * * * * ${BUILD_HOME}/providerscripts/security/firewall/TightenBuildMachineFirewall.sh ${BUILD_HOME} ${DATASTORE_CHOICE} ${CLOUDHOST} ${IDENTIFIER}" >> /var/spool/cron/crontabs/root
	/usr/bin/crontab -u root /var/spool/cron/crontabs/root
fi

if ( [ "`/usr/bin/crontab -l | /bin/grep 'apt' | /bin/grep 'update' | /bin/grep 'upgrade'`" = "" ] )
then
	/bin/echo "45 4 * * * /usr/bin/apt -y -qq update && /usr/bin/apt -y -qq upgrade && /usr/sbin/shutdown -r now" >> /var/spool/cron/crontabs/root
fi

if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${DATASTORE_CHOICE} ${IDENTIFIER}/FIREWALL-EVENT ${BUILD_HOME}`" != "" ] )
then
	${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${DATASTORE_CHOICE} ${IDENTIFIER}/FIREWALL-EVENT ${BUILD_HOME}/runtimedata/FIREWALL-EVENT ${BUILD_HOME} 
fi

if ( [ -f ${BUILD_HOME}/runtimedata/FIREWALL-EVENT ] || [ -f ${BUILD_HOME}/runtimedata/PRIME_FIREWALL ] )
then
	/bin/rm ${BUILD_HOME}/runtimedata/*FIREWALL*  2>/dev/null

	if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${DATASTORE_CHOICE} ${IDENTIFIER}/FIREWALL-EVENT ${BUILD_HOME}`" != "" ] )
	then
		${BUILD_HOME}/providerscripts/datastore/DeleteFromDatastore.sh ${DATASTORE_CHOICE} ${IDENTIFIER}/FIREWALL-EVENT ${BUILD_HOME}
	fi
	
	if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${DATASTORE_CHOICE} ${IDENTIFIER}/authorised-ips.dat ${BUILD_HOME}`" != "" ] )
	then
		 ${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${DATASTORE_CHOICE} ${IDENTIFIER}/authorised-ips.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat ${BUILD_HOME} 
	fi
	
	if ( [ "${LAPTOP_IP}" = "" ] )
	then
		if ( [ -f ${BUILD_HOME}/runtimedata/LAPTOPIP:* ] )
		then
			LAPTOP_IP="`/bin/ls ${BUILD_HOME}/runtimedata/LAPTOPIP:* | /usr/bin/awk -F':' '{print $NF}'  2>/dev/null`"
		fi
	fi 

	if ( [ "${LAPTOP_IP}" != "" ] )
	then
		if ( [ "${LAPTOP_IP}" != "BYPASS" ] )
		then
		
		   if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips ] )
		   then
			   /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips
		   fi
		   
		   /bin/echo "${LAPTOP_IP}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat
		   /usr/bin/uniq ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat.$$
		   /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat
		   /bin/mv ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat.$$ ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat
		   
		   if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${DATASTORE_CHOICE} ${IDENTIFIER} ${BUILD_HOME}`" = "" ] )
		   then
			   ${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh ${DATASTORE_CHOICE} ${IDENTIFIER} ${BUILD_HOME}
		   fi
		   ${BUILD_HOME}/providerscripts/datastore/PutToDatastore.sh ${DATASTORE_CHOICE} ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat ${IDENTIFIER}/authorised-ips.dat ${BUILD_HOME}
		fi
   fi

   ips="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat | /bin/tr '\n' ' '`"

   if ( [ "${ips}" != "" ] )
   then
		/usr/bin/yes | /usr/sbin/ufw reset
		/usr/sbin/ufw default deny incoming
		/usr/sbin/ufw default allow outgoing
   
		for ip in ${ips}
   		do
          		# /usr/sbin/ufw allow from ${ip} proto tcp to any port 1036
	   		/usr/sbin/ufw allow from ${ip}
   		done

		/usr/bin/yes | /usr/sbin/ufw enable
	fi
 
. ${BUILD_HOME}/ providerscripts/security/firewall/AttachBuildMachineToNativeFirewall.sh

   if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat.$$ ] && [ "`/usr/bin/diff ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat.$$ ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat`" != "" ] )
   then
	   /bin/cp ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat.$$
   fi
fi
