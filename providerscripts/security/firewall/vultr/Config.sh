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

vultr_custom_rules ()
{
	firewall_id="${1}"
	custom_ports="${2}"
        
	for custom_port_token in ${custom_ports}
	do
		if ( [ "`/bin/echo ${custom_port_token} | /usr/bin/awk -F'|' '{print $2}'`" = "ipv4" ] )
		then
			port="`/bin/echo ${custom_port_token} | /usr/bin/awk -F'|' '{print $1}'`"
			ip_address="`/bin/echo ${custom_port_token} | /usr/bin/awk -F'|' '{print $3}'`"
			/usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=${port} --size=32 --ip-type=v4 --subnet=${ip_address}                      
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
AUTHENTICATION_SERVER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTHENTICATION_SERVER`"
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

firewall_id="`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description == "'${firewall_name}'-'${BUILD_IDENTIFIER}'").id'`"

if ( [ "${firewall_id}" = "" ] )
then
	firewall_id="`/usr/bin/vultr firewall group create -o json | /usr/bin/jq -r '.firewall_group.id'`"
	/usr/bin/vultr firewall group update ${firewall_id} --description "${firewall_name}-${BUILD_IDENTIFIER}"
else
	rules="`/usr/bin/vultr firewall rule list ${firewall_id} -o json | /usr/bin/jq -r '.firewall_rules[].id'`"
	for rule in ${rules}
	do
		/usr/bin/vultr firewall rule delete ${firewall_id} ${rule}
	done
fi

if ( [ "${firewall_name}" = "adt-authenticator" ] )
then
	vultr_custom_rules "${firewall_id}" "${authenticator_custom_ports}"
fi

if ( [ "${firewall_name}" = "adt-reverseproxy" ] )
then
	vultr_custom_rules "${firewall_id}" "${reverseproxy_custom_ports}"
fi
                
if ( [ "${firewall_name}" = "adt-autoscaler" ] )
then
	vultr_custom_rules "${firewall_id}" "${autoscaler_custom_ports}"
fi

if ( [ "${firewall_name}" = "adt-webserver" ] )
then
	vultr_custom_rules "${firewall_id}" "${webserver_custom_ports}"
fi

if ( [ "${firewall_name}" = "adt-database" ] )
then
	vultr_custom_rules "${firewall_id}" "${database_custom_ports}"
fi

if ( [ "${firewall_name}" = "adt-autoscaler" ] )
then
	if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
	then
		/usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=${SSH_PORT} --size=32 --ip-type=v4 --subnet=${build_machine_ip}/32                        
	fi
	/usr/bin/vultr firewall rule create ${firewall_id} --protocol=icmp --size=32 --ip-type=v4 --subnet=0.0.0.0/0
fi

if ( ( [ "${NO_REVERSE_PROXY}" = "0" ] && [ "${firewall_name}" = "adt-webserver" ] ) ||  [ "${firewall_name}" = "adt-authenticator" ]  ||  [ "${firewall_name}" = "adt-reverseproxy" ] )
then	
	if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
	then
		/usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=${SSH_PORT} --size=32 --ip-type=v4 --subnet=${build_machine_ip}/32                        
	fi
	/usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=443 --size=32 --ip-type=v4 --subnet=${build_machine_ip}/32                        
else
	if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
	then
		if ( [ "${NO_REVERSE_PROXY}" != "0" ] && [ "${firewall_name}" = "adt-webserver" ] )
		then
			/usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=${SSH_PORT} --size=32 --ip-type=v4 --subnet=${build_machine_ip}/32                        
			/usr/bin/vultr firewall rule create ${firewall_id} --protocol=icmp --size=32 --ip-type=v4 --subnet=0.0.0.0/0
		fi
	fi
fi

if ( [ "${all_dns_proxy_ips}" != "" ] )
then
	if ( ( [ "${NO_REVERSE_PROXY}" = "0" ] && [ "${firewall_name}" = "adt-webserver" ] ) || [ "${firewall_name}" = "adt-reverseproxy" ] || [ "${firewall_name}" = "adt-authenticator" ] )
	then
		/usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=443 --size=32 --ip-type=v4  --source=cloudflare --subnet=10.0.0.0/8
		/usr/bin/vultr firewall rule create ${firewall_id} --protocol=icmp --size=32 --ip-type=v4 --subnet=0.0.0.0/0
	fi
elif ( ( [ "${NO_REVERSE_PROXY}" = "0" ] && [ "${firewall_name}" = "adt-webserver" ] ) || [ "${firewall_name}" = "adt-reverseproxy" ] || [ "${firewall_name}" = "adt-authenticator" ] )
then
		/usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=443 --size=32 --ip-type=v4 --subnet=0.0.0.0/0
fi

/usr/bin/vultr firewall rule create ${firewall_id} --protocol=icmp --size=32 --ip-type=v4 --subnet=0.0.0.0/0

if ( [ "${firewall_name}" = "adt-database" ] )
then
	if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
	then
		/usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=${SSH_PORT} --size=32 --ip-type=v4 --subnet=${build_machine_ip}/32
	fi
	/usr/bin/vultr firewall rule create ${firewall_id} --protocol icmp --size 32 --ip-type v4 -s 0.0.0.0/0
fi

/bin/echo "ADT_FIREWALL_ID:${firewall_id}"
fi
