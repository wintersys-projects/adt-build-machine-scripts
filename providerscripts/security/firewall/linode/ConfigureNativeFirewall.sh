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
set -x

linode_custom_rules ()
{
        custom_ports="${1}"
        custom_rules=""
        for custom_port_token in ${custom_ports}
        do
                if ( [ "`/bin/echo ${custom_port_token} | /usr/bin/awk -F'|' '{print $2}'`" = "ipv4" ] )
                then
                        port="`/bin/echo ${custom_port_token} | /usr/bin/awk -F'|' '{print $1}'`"
                        ip_address="`/bin/echo ${custom_port_token} | /usr/bin/awk -F'|' '{print $3}'`"
                        custom_rules=${custom_rules}',{"addresses":{"ipv4":["'${ip_address}'"]},"action":"ACCEPT","protocol":"TCP","ports":"'${port}'"}'
                fi
        done
        #custom_rules="`/bin/echo ${custom_rules} | /bin/sed 's/,$//g'`"
        /bin/echo "${custom_rules}"
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


ruleset=""
rule_vpc='{"addresses":{"ipv4":["'${VPC_IP_RANGE}'"]},"action":"ACCEPT","protocol":"TCP","ports":"1-65535"}'
rule_build_machine='{"addresses":{"ipv4":["'${build_machine_ip}/32'"]},"action":"ACCEPT","protocol":"TCP","ports":"'${SSH_PORT}'"}'
rule_build_machine_ssl='{"addresses":{"ipv4":["'${build_machine_ip}/32'"]},"action":"ACCEPT","protocol":"TCP","ports":"443"}'
rule_icmp='{"addresses":{"ipv4":["0.0.0.0/0"]},"action":"ACCEPT","protocol":"ICMP"}'
custom_rules=""

if ( [ "${firewall_name}" = "adt-authenticator" ] )
then
        custom_rules="`linode_custom_rules "${authenticator_custom_ports}"`"
fi

if ( [ "${firewall_name}" = "adt-reverseproxy" ] )
then
        custom_rules="`linode_custom_rules "${reverseproxy_custom_ports}"`"
fi

if ( [ "${firewall_name}" = "adt-autoscaler" ] )
then
        custom_rules="`linode_custom_rules "${autoscaler_custom_ports}"`"
fi

if ( [ "${firewall_name}" = "adt-webserver" ] )
then
        custom_rules="`linode_custom_rules "${webserver_custom_ports}"`"
fi

if ( [ "${firewall_name}" = "adt-database" ] )
then
        custom_rules="`linode_custom_rules "${database_custom_ports}"`"
fi

if ( [ "${all_dns_proxy_ips}" = "" ] )
then
        rule_ssl='{"addresses":{"ipv4":["0.0.0.0/0"]},"action":"ACCEPT","protocol":"TCP","ports":"443"}'
else
        rule_ssl='{"addresses":{"ipv4":['${all_dns_proxy_ips}']},"action":"ACCEPT","protocol":"TCP","ports":"443"}'
fi

firewall_id="`/usr/local/bin/linode-cli --json firewalls list | /usr/bin/jq -r '.[] | select (.label | contains ("'${firewall_name}'")) |  select (.label | endswith ("'-${BUILD_IDENTIFIER}'")).id'`"

if ( [ "${firewall_id}" = "" ] )
then
        firewall_id="`/usr/local/bin/linode-cli firewalls create --json --label "${firewall_name}-${BUILD_IDENTIFIER}" --rules.inbound_policy DROP   --rules.outbound_policy ACCEPT | /usr/bin/jq -r '.[].id'`"
else
        /usr/local/bin/linode-cli firewalls rules-update --inbound '[]' --outbound '[]' --inbound_policy DROP --outbound_policy ACCEPT ${firewall_id}
fi

ruleset=""

if ( [ "${firewall_name}" = "adt-autoscaler" ] )
then
        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
        then
                ruleset=${rule_vpc}','${rule_build_machine}','${rule_icmp}${custom_rules}
        elif ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
        then
                ruleset=${rule_vpc}','${rule_icmp}${custom_rules}
        fi
fi

if ( ( [ "${NO_REVERSE_PROXY}" = "0" ] && [ "${firewall_name}" = "adt-webserver" ] ) ||  [ "${firewall_name}" = "adt-authenticator" ]  ||  [ "${firewall_name}" = "adt-reverseproxy" ] )
then
        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
        then
                ruleset=${rule_vpc}','${rule_build_machine}','${rule_build_machine_ssl}','${rule_icmp}','${rule_ssl}${custom_rules}
        else
                ruleset=${rule_vpc}','${rule_icmp}','${rule_ssl}${custom_rules}
        fi
else
        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
        then
                if ( [ "${NO_REVERSE_PROXY}" != "0" ] && [ "${firewall_name}" = "adt-webserver" ] )
                then
                        ruleset=${rule_vpc}','${rule_build_machine}','${rule_icmp}${custom_rules}
                fi
        else
                ruleset=${rule_vpc}','${rule_icmp}${custom_rules}
        fi
fi

if ( [ "${firewall_name}" = "adt-database" ] )
then
        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
        then
                ruleset=${rule_vpc}','${rule_build_machine}','${rule_icmp}${custom_rules}
        elif ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
        then
                ruleset=${rule_vpc}','${rule_icmp}${custom_rules}
        fi
fi

ruleset='['${ruleset}']'

/usr/local/bin/linode-cli firewalls rules-update  --inbound_policy DROP --outbound_policy ACCEPT --inbound ${ruleset} ${firewall_id}

if ( [ "$?" = "0" ] )
then
        /bin/echo "ADT_FIREWALL_ID:${firewall_id}"
fi
