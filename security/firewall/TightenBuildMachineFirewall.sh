#!/bin/sh
######################################################################################################
# Description: By creating a file: s3://authip-adt-allowed-<ip-address>/authorised-ips.dat in your S3 datastore with a list
# of ipaddresses, you can allow only machines with your listed ip addresses to access your build machine.
# The file authorised-ips.dat should be formatted with ip addresses on successive lines, for example:
#
# 111.111.111.111
# 222.222.222.222
#
# Would allow machines with ip addresses 111.111.111.111 and 222.222.222.222 to connect to your build machine
# over ssh. 
# The advice is to also manually add your build machine to a native firewall (the firewall provided by your
# cloudhost) only allowing access to your specific SSH port and your specific ip addresses. This means
# that your build machine is double firewalled and also you can add your laptop ip address to your native
# firewall when you start work for the day and need access to your build machine and you can close the machine
# off completely using the native firewall by setting the ip of your laptop to "deny" at the end of the day.
# That way your build machine is completely firewalled off except when you are working with it.
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
#set -x

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

if ( [ -f /var/spool/cron/crontabs/root ] )
then
	/bin/sed -i "/^#/d" /var/spool/cron/crontabs/root
fi

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
BUILD_IDENTIFIER="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER`"
ip="`${BUILD_HOME}/helperscripts/GetBuildMachineIP.sh`"
${BUILD_HOME}/providerscripts/server/GetServerName.sh ${ip} "${CLOUDHOST}"
CLOUDHOST="`/bin/cat ${BUILD_HOME}/runtimedata/BUILD_MACHINE_CLOUDHOST`"

if ( [ "`/bin/ls /root/FIREWALL-BUCKET:* 2>/dev/null`" = "" ] )
then
	auth_bucket="authip-adt-allowed-`/bin/echo ${ip} | /bin/sed 's/\./-/g'`"
	/bin/touch /root/FIREWALL-BUCKET:${auth_bucket}
else
	auth_bucket="`/bin/ls /root/FIREWALL-BUCKET:* | /usr/bin/awk -F':' '{print $NF}'  2>/dev/null`"
fi

${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh "${auth_bucket}"

if ( [ ! -f /var/spool/cron/crontabs/root ] )
then
	/bin/touch /var/spool/cron/crontabs/root
fi

if ( [ "`/usr/bin/crontab -l | /bin/grep TightenBuildMachineFirewall.sh`" = "" ] )
then
	/bin/echo "*/1 * * * * ${BUILD_HOME}/security/firewall/TightenBuildMachineFirewall.sh" >> /var/spool/cron/crontabs/root
	/usr/bin/crontab -u root /var/spool/cron/crontabs/root 2>/dev/null
fi

if ( [ "`/usr/bin/crontab -l | /bin/grep 'apt' | /bin/grep 'update' | /bin/grep 'upgrade'`" = "" ] )
then
	/bin/echo "45 4 * * * /usr/bin/apt -y -qq update && /usr/bin/apt -y -qq upgrade && /usr/sbin/shutdown -r now" >> /var/spool/cron/crontabs/root
fi

if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${auth_bucket}/FIREWALL-EVENT`" != "" ] )
then
	${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${auth_bucket}/FIREWALL-EVENT ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/FIREWALL-EVENT 
fi

if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/FIREWALL-EVENT ] || [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/PRIME_FIREWALL ] )
then
	if ( [ -f  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/FIREWALL-EVENT ] )
	then
		/bin/rm  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/FIREWALL-EVENT 
	fi

	if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/PRIME_FIREWALL ] )
	then
		/bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/PRIME_FIREWALL
	fi

	if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${auth_bucket}/FIREWALL-EVENT`" != "" ] )
	then
		${BUILD_HOME}/providerscripts/datastore/DeleteFromDatastore.sh ${auth_bucket}/FIREWALL-EVENT 
	fi

	if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${auth_bucket}/authorised-ips.dat`" != "" ] )
	then
		${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${auth_bucket}/authorised-ips.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat ${BUILD_HOME} 
	fi

	if ( [ "${laptop_ip}" = "" ] )
	then
		if ( [ -f ${BUILD_HOME}/runtimedata/LAPTOPIP:* ] )
		then
			laptop_ip="`/bin/ls ${BUILD_HOME}/runtimedata/LAPTOPIP:* | /usr/bin/awk -F':' '{print $NF}'  2>/dev/null`"
		fi
	fi 

	if ( [ "${laptop_ip}" != "" ] )
	then
		if ( [ "${laptop_ip}" != "BYPASS" ] )
		then
			if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips ] )
			then
				/bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips
			fi
			/bin/echo "${laptop_ip}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat
			/usr/bin/uniq ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat.$$
			/bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat
			/bin/mv ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat.$$ ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat

			if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${auth_bucket}`" = "" ] )
			then
				${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh ${auth_bucket}
			fi
			${BUILD_HOME}/providerscripts/datastore/PutToDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat ${auth_bucket}/authorised-ips.dat
		fi
	fi

	ips="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat | /bin/tr '\n' ' '`"

	if ( [ "${ips}" != "" ] )
	then
		firewall=""
		if ( [ "`/bin/grep "^FIREWALL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "ufw" ] )
		then
			firewall="ufw"
		elif ( [ "`/bin/grep "^FIREWALL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "iptables" ] )
		then
			firewall="iptables"
		fi

		if ( [ "${firewall}" = "ufw" ] )
		then
			/usr/bin/yes | /usr/sbin/ufw reset
			/usr/sbin/ufw default deny incoming
			/usr/sbin/ufw default allow outgoing

			buildmachine_ssh_port="`/bin/ls ${BUILD_HOME}/runtimedata/BUILDMACHINEPORT:* | /usr/bin/awk -F':' '{print $NF}'`"

			if ( [ "${buildmachine_ssh_port}" = "" ] )
			then
				buildmachine_ssh_port="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"
			fi

			if ( [ "${buildmachine_ssh_port}" = "" ] )
			then
				for ip in ${ips}
				do
					/usr/sbin/ufw allow from ${ip}
				done       
			else
				for ip in ${ips}
				do
					/usr/sbin/ufw allow from ${ip} proto tcp to any port ${buildmachine_ssh_port}
				done
			fi
			/usr/bin/yes | /usr/sbin/ufw enable
		elif ( [ "${firewall}" = "iptables" ] )
		then
			/usr/sbin/iptables -F
			buildmachine_ssh_port="`/bin/ls ${BUILD_HOME}/runtimedata/BUILDMACHINEPORT:* | /usr/bin/awk -F':' '{print $NF}'`"

			/usr/sbin/iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
			/usr/sbin/iptables -A INPUT -s `/bin/echo ${ips} | /bin/sed 's/ /,/g'` -p ICMP --icmp-type 8 -j ACCEPT
			/usr/sbin/iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j DROP
			/usr/sbin/iptables -I INPUT  -s `/bin/echo ${ips} | /bin/sed 's/ /,/g'` -m state --state NEW,RELATED,ESTABLISHED,NEW -p tcp --dport ${buildmachine_ssh_port} -j ACCEPT
			/usr/sbin/iptables -A INPUT  -s `/bin/echo ${ips} | /bin/sed 's/ /,/g'` -p icmp -m state --state RELATED,ESTABLISHED,NEW -m icmp --icmp-type 8 -j ACCEPT
			/usr/sbin/iptables -A INPUT -i lo -j ACCEPT
			/usr/sbin/iptables -A OUTPUT -o lo -j ACCEPT
			/usr/sbin/iptables -P INPUT DROP
			/usr/sbin/iptables -P FORWARD DROP
			/usr/sbin/iptables -P OUTPUT ACCEPT
			/usr/sbin/ip6tables -P INPUT DROP
			/usr/sbin/ip6tables -P FORWARD DROP
			/usr/sbin/ip6tables -P OUTPUT DROP
			${BUILD_HOME}/helperscripts/RunServiceCommand.sh netfilter-persistent save
		fi
	fi

	if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat.$$ ] && [ "`/usr/bin/diff ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat.$$ ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat`" != "" ] )
	then
		/bin/cp ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat.$$
	fi
fi
