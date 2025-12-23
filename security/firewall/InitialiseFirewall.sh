#!/bin/sh
######################################################################################################
# Description: Initialise the firewall for the build machine. This will either be a ufw or an iptables
# firewall
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

if ( [ "${BUILD_HOME}" = "" ] )
then
	BUILD_HOME="`/bin/cat /home/buildhome.dat`"
fi

if ( [ -f /root/FIREWALL-INITIALISED ] )
then
	exit
fi

if ( [ "${BUILD_HOME}" = "" ] )
then
	BUILD_HOME="`/bin/cat /home/buildhome.dat`"
fi

if ( [ "${BUILD_IDENTIFIER}" = "" ] )
then
	BUILD_IDENTIFIER="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER`"
fi

firewall=""

if ( [ "`/bin/grep "^FIREWALL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $2}'`" = "ufw" ] )
then
	firewall="ufw"
elif ( [ "`/bin/grep "^FIREWALL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $2}'`" = "iptables" ] )
then
	firewall="iptables"
fi

laptop_ip="`/bin/ls ${BUILD_HOME}/runtimedata/LAPTOPIP:* | /usr/bin/awk -F':' '{print $NF}'`"
buildmachine_ssh_port="`/bin/ls ${BUILD_HOME}/runtimedata/BUILDMACHINEPORT:* | /usr/bin/awk -F':' '{print $NF}'`"

if ( [ "${firewall}" = "ufw" ] )
then
	/bin/echo "y" | /usr/sbin/ufw reset	
	/usr/sbin/ufw default deny incoming
	/usr/sbin/ufw default allow outgoing
	#uncomment this if you want more general access than just ssh
	#/usr/sbin/ufw allow from ${LAPTOP_IP}
	/usr/sbin/ufw allow from ${laptop_ip} to any port ${buildmachine_ssh_port}
	/bin/echo "y" | /usr/sbin/ufw enable
	/bin/touch /root/FIREWALL-INITIALISED
elif ( [ "${firewall}" = "iptables" ] )
then

	if ( [ -f /usr/sbin/ufw ] )
	then
		/usr/sbin/ufw disable
	fi

	/usr/sbin/iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	/usr/sbin/iptables -A INPUT -p tcp --dport ${buildmachine_ssh_port} -j ACCEPT
	/usr/sbin/iptables -A INPUT -s ${laptop_ip} -p ICMP --icmp-type 8 -j ACCEPT
	/usr/sbin/iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j DROP
	/usr/sbin/iptables -I INPUT \! -s ${laptop_ip} -m state --state NEW,INVALID -p tcp --dport ${buildmachine_ssh_port} -j DROP
	/usr/sbin/iptables -A INPUT ! -s ${laptop_ip} -p icmp -m state --state INVALID,NEW -m icmp --icmp-type 8  -j DROP
	/usr/sbin/iptables -A INPUT -i lo -j ACCEPT
	/usr/sbin/iptables -A OUTPUT -o lo -j ACCEPT
	/usr/sbin/iptables -P INPUT DROP
	/usr/sbin/iptables -P FORWARD DROP
	/usr/sbin/iptables -P OUTPUT ACCEPT
	/usr/sbin/ip6tables -P INPUT DROP
	/usr/sbin/ip6tables -P FORWARD DROP
	/usr/sbin/ip6tables -P OUTPUT DROP
	/usr/sbin/ip6tables -A INPUT -i lo -j ACCEPT
	/usr/sbin/ip6tables -A OUTPUT -o lo -j ACCEPT
    /usr/sbin/iptables-save > /etc/iptables/rules.v4
    /usr/sbin/ip6tables-save > /etc/iptables/rules.v6
	/bin/touch /root/FIREWALL-INITIALISED
fi

if ( [ "`/bin/grep "^FAIL2BAN:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep active`" != "" ] )
then
	if ( [ -f /etc/fail2ban/jail.d/jail.local ] )
	then
		/bin/sed -i "s/XXXXSSHPORTXXXX/${buildmachine_ssh_port}/g" /etc/fail2ban/jail.d/jail.local
	fi
fi
