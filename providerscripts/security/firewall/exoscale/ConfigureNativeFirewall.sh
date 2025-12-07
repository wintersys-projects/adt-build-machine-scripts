#!/bin/sh
######################################################################################################
# Description: This will configure the native firewall to restrict access by ip address to our infrastructure
# according to what our configuration needs are. Sometimes machines are only accessible through the VPC they
# are in and sometimes they have to be accessible across the internet. The policy is designed to keep access
# to the machines as strict and as limited as possible. 
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

exoscale_custom_rules ()
{
	firewall_name="${1}"
	custom_ports="${2}"
        
	for custom_port_token in ${custom_ports}
	do
		if ( [ "`/bin/echo ${custom_port_token} | /usr/bin/awk -F'|' '{print $2}'`" = "ipv4" ] )
		then
			port="`/bin/echo ${custom_port_token} | /usr/bin/awk -F'|' '{print $1}'`"
			ip_address="`/bin/echo ${custom_port_token} | /usr/bin/awk -F'|' '{print $3}'`"
			/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --network ${ip_address} --port ${port} &
		fi
	done
}

status () {
        /bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
        /bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

firewall_name="${1}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`" 
ACTIVE_FIREWALLS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ACTIVE_FIREWALLS`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"
VPC_IP_RANGE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh VPC_IP_RANGE`"
NO_REVERSE_PROXY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NO_REVERSE_PROXY`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
build_machine_ip="`${BUILD_HOME}/helperscripts/GetBuildMachineIP.sh`"



if ( [ -f ${BUILD_HOME}/builddescriptors/customfirewallports.dat ] )
then
	authenticator_custom_ports="`/bin/grep "^AUTHENTICATORCUSTOMPORTS" ${BUILD_HOME}/builddescriptors/customfirewallports.dat | /usr/bin/awk -F':' '{print $2}'`"
	autoscaler_custom_ports="`/bin/grep "^AUTOSCALERCUSTOMPORTS" ${BUILD_HOME}/builddescriptors/customfirewallports.dat | /usr/bin/awk -F':' '{print $2}'`"
	reverseproxy_custom_ports="`/bin/grep "^REVERSEPROXYCUSTOMPORTS" ${BUILD_HOME}/builddescriptors/customfirewallports.dat | /usr/bin/awk -F':' '{print $2}'`"
	webserver_custom_ports="`/bin/grep "^WEBSERVERCUSTOMPORTS" ${BUILD_HOME}/builddescriptors/customfirewallports.dat | /usr/bin/awk -F':' '{print $2}'`"
	database_custom_ports="`/bin/grep "^DATABASECUSTOMPORTS" ${BUILD_HOME}/builddescriptors/customfirewallports.dat | /usr/bin/awk -F':' '{print $2}'`"
fi

if ( [ "${firewall_name}" = "adt-authenticator" ] )
then
	all_dns_proxy_ips="`${BUILD_HOME}/providerscripts/dns/GetProxyDNSIPs.sh "auth"`"
else
	all_dns_proxy_ips="`${BUILD_HOME}/providerscripts/dns/GetProxyDNSIPs.sh`"
fi

firewall_id="`/usr/bin/exo -O json compute security-group list | /usr/bin/jq -r '.[] | select (.name | contains ("'${firewall_name}'")) |  select (.name | endswith ("'-${BUILD_IDENTIFIER}'")).id'`"

if ( [ "${firewall_id}" = "" ] )
then
	/usr/bin/exo compute security-group create "${firewall_name}-${BUILD_IDENTIFIER}"
else
	rules=""
	rules="`/usr/bin/exo compute security-group show ${firewall_id} -O json | /usr/bin/jq -r '.ingress_rules[].id'`"
	rules="${rules} `/usr/bin/exo compute security-group show ${firewall_id} -O json | /usr/bin/jq -r '.egress_rules[].id'`"
	pids=""
	for ruleid in ${rules}
	do
		/usr/bin/yes | /usr/bin/exo compute security-group rule delete ${firewall_id} ${ruleid} &
		pids="${pids} $!"
	done

	for pid in ${pids}
	do
		wait ${pid}
	done
fi

if ( [ "${firewall_name}" = "adt-authenticator" ] )
then
	exoscale_custom_rules "${firewall_name}" "${authenticator_custom_ports}"
fi

if ( [ "${firewall_name}" = "adt-reverseproxy" ] )
then
	exoscale_custom_rules "${firewall_name}" "${reverseproxy_custom_ports}"
fi
                
if ( [ "${firewall_name}" = "adt-autoscaler" ] )
then
	exoscale_custom_rules "${firewall_name}" "${autoscaler_custom_ports}"
fi

if ( [ "${firewall_name}" = "adt-webserver" ] )
then
	exoscale_custom_rules "${firewall_name}" "${webserver_custom_ports}"
fi

if ( [ "${firewall_name}" = "adt-database" ] )
then
	exoscale_custom_rules "${firewall_name}" "${database_custom_ports}"
fi

if ( [ "${firewall_name}" = "adt-autoscaler" ] )
then
	if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
	then
		/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --network ${build_machine_ip}/32 --port ${SSH_PORT} &
	fi
	/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --network ${VPC_IP_RANGE} --port ${SSH_PORT} &
	/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --protocol icmp --network 0.0.0.0/0 --icmp-code 0 --icmp-type 8 &
fi

if ( [ "${firewall_name}" = "adt-webserver" ] ||  [ "${firewall_name}" = "adt-authenticator" ]  ||  [ "${firewall_name}" = "adt-reverseproxy" ] )
then
	if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
	then
		/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --network ${build_machine_ip}/32 --port ${SSH_PORT} &

		if ( [ "${NO_REVERSE_PROXY}" = "0" ] && [ "${firewall_name}" = "adt-webserver" ] ) 
		then
			/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --network ${build_machine_ip}/32 --port 443 &
		elif ( [ "${NO_REVERSE_PROXY}" != "0" ] && [ "${firewall_name}" = "adt-reverseproxy" ] )
		then
			/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --network ${build_machine_ip}/32 --port 443 &
		fi
	fi
	/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --protocol icmp --network 0.0.0.0/0 --icmp-code 0 --icmp-type 8 &
	/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --network ${VPC_IP_RANGE} --port ${SSH_PORT} &

	if ( [ "${all_dns_proxy_ips}" != "" ] && [ "${firewall_name}" != "adt-authenticator" ] )
	then
		if ( ( [ "${NO_REVERSE_PROXY}" = "0" ] && [ "${firewall_name}" = "adt-webserver" ] ) || [ "${firewall_name}" = "adt-reverseproxy" ] )
		then
			all_dns_proxy_ips="`/bin/echo ${all_dns_proxy_ips} | /bin/sed 's/,/ /g' | /bin/sed 's/^"//g' | /bin/sed 's/"$//g'`"
			for ip in ${all_dns_proxy_ips}
			do
				/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --network ${ip} --port 443 &
			done
		fi
		/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --network ${VPC_IP_RANGE} --port 443 &
	else
		/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --network 0.0.0.0/0 --port 443 &
	fi
fi

if ( [ "${firewall_name}" = "adt-database" ] )
then
	if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
	then
		/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --network ${build_machine_ip}/32 --port ${SSH_PORT} &
		/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --network ${build_machine_ip}/32 --port ${DB_PORT} &
	fi
	/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --protocol icmp --network 0.0.0.0/0 --icmp-code 0 --icmp-type 8 &
	/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --network ${VPC_IP_RANGE} --port ${SSH_PORT} &
	/usr/bin/exo compute security-group rule add ${firewall_name}-${BUILD_IDENTIFIER} --network ${VPC_IP_RANGE} --port ${DB_PORT} &
fi

/bin/echo "ADT_FIREWALL_ID:${firewall_name}-${BUILD_IDENTIFIER}"
