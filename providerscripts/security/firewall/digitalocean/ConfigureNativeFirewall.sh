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

digitalocean_custom_rules ()
{
        custom_ports="${1}"
        custom_rules=""
        for custom_port_token in ${custom_ports}
        do
                if ( [ "`/bin/echo ${custom_port_token} | /usr/bin/awk -F'|' '{print $2}'`" = "ipv4" ] )
                then
                        port="`/bin/echo ${custom_port_token} | /usr/bin/awk -F'|' '{print $1}'`"
                        ip_address="`/bin/echo ${custom_port_token} | /usr/bin/awk -F'|' '{print $3}'`"
                        custom_rules=${custom_rules}" protocol:tcp,ports:${port},address:${ip_address}"
               
                fi
        done
        custom_rules="`/bin/echo ${custom_rules} | /bin/sed 's/,$//g'`"
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

firewall_id="`/usr/local/bin/doctl -o json compute firewall list | /usr/bin/jq -r '.[] | select (.name == "'${firewall_name}'-'${BUILD_IDENTIFIER}'").id'`"

if ( [ "${firewall_id}" != "" ] )
then
        /usr/local/bin/doctl compute firewall delete ${firewall_id} --force
fi

while ( [ "`/usr/local/bin/doctl -o json compute firewall list | /usr/bin/jq -r '.[] | select (.name == "'${firewall_name}'-'${BUILD_IDENTIFIER}'").id'`" != "" ] )
do
        /bin/sleep 5
done

/usr/local/bin/doctl compute firewall create --name "${firewall_name}-${BUILD_IDENTIFIER}"  --outbound-rules "protocol:tcp,ports:all,protocol:tcp,ports:all,address:0.0.0.0/0 protocol:udp,ports:all,address:0.0.0.0/0 protocol:icmp,address:0.0.0.0/0"
firewall_id="`/usr/local/bin/doctl -o json compute firewall list | /usr/bin/jq -r '.[] | select (.name == "'${firewall_name}'-'${BUILD_IDENTIFIER}'").id'`"

custom_rules=""
                
if ( [ "${firewall_name}" = "adt-authenticator" ] )
then
        custom_rules="`digitalocean_custom_rules "${authenticator_custom_ports}"`"
fi

if ( [ "${firewall_name}" = "adt-reverseproxy" ] )
then
        custom_rules="`digitalocean_custom_rules "${reverseproxy_custom_ports}"`"
fi
                
if ( [ "${firewall_name}" = "adt-autoscaler" ] )
then
        custom_rules="`digitalocean_custom_rules "${autoscaler_custom_ports}"`"
fi

if ( [ "${firewall_name}" = "adt-webserver" ] )
then
        custom_rules="`digitalocean_custom_rules "${webserver_custom_ports}"`"
fi

if ( [ "${firewall_name}" = "adt-database" ] )
then
        custom_rules="`digitalocean_custom_rules "${database_custom_ports}"`"
fi
                
if ( [ "${firewall_name}" = "adt-autoscaler" ] )
then
        machine_identifier="as-${REGION}-${BUILD_IDENTIFIER}"

        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
        then
                rules="protocol:tcp,ports:${SSH_PORT},address:${build_machine_ip}/32"                        
        fi

        rules="${rules} protocol:tcp,ports:${SSH_PORT},address:${VPC_IP_RANGE} protocol:icmp,address:0.0.0.0/0"
        rules="`/bin/echo ${rules} | /usr/bin/tr -s ' '`"                
fi

if ( [ "${firewall_name}" = "adt-webserver" ] ||  [ "${firewall_name}" = "adt-authenticator" ]  ||  [ "${firewall_name}" = "adt-reverseproxy" ] )
then
        if ( [ "${firewall_name}" = "adt-webserver" ] )
        then
                machine_identifier="ws-${REGION}-${BUILD_IDENTIFIER}"
        elif ( [ "${firewall_name}" = "adt-authenticator" ] )
        then
                machine_identifier="auth-${REGION}-${BUILD_IDENTIFIER}"
        elif ( [ "${firewall_name}" = "adt-reverseproxy" ] )
        then
                machine_identifier="rp-${REGION}-${BUILD_IDENTIFIER}"
        fi

        if ( [ "${NO_REVERSE_PROXY}" = "0" ] && [ "${firewall_name}" = "adt-webserver" ] ||  [ "${firewall_name}" = "adt-authenticator" ] )
        then
                if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                then
                        rules="protocol:tcp,ports:443,address:${build_machine_ip}/32 protocol:tcp,ports:${SSH_PORT},address:${build_machine_ip}/32"
                else
                        rules="protocol:tcp,ports:${SSH_PORT},address:${build_machine_ip}/32"
                fi
        else
                if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                then
                        if ( [ "${NO_REVERSE_PROXY}" != "0" ] && [ "${firewall_name}" = "adt-webserver" ] )
                        then
                                rules="protocol:tcp,ports:443,address:${build_machine_ip}/32 protocol:tcp,ports:${SSH_PORT},address:${build_machine_ip}/32 "
                        fi
                fi
        fi

        if ( ( [ "${NO_REVERSE_PROXY}" != "0" ] && [ "${firewall_name}" = "adt-reverseproxy" ] ) || ( [ "${NO_REVERSE_PROXY}" = "0" ] &&  [ "${firewall_name}" = "adt-webserver" ] ) )
        then
                if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                then
                        rules="protocol:tcp,ports:443,address:${build_machine_ip}/32 protocol:tcp,ports:${SSH_PORT},address:${build_machine_ip}/32"
                fi
        fi

        if ( [ "${all_dns_proxy_ips}" != "" ] )
        then
                if ( ( [ "${NO_REVERSE_PROXY}" = "0" ] && [ "${firewall_name}" = "adt-webserver" ] ) || [ "${firewall_name}" = "adt-reverseproxy" ] || [ "${firewall_name}" = "adt-authenticator" ] )
                then
                        for ip in ${all_dns_proxy_ips}
                        do
                                rules=${rules}" protocol:tcp,ports:443,address:${ip} " 
                        done
                        rules=${rules}" protocol:tcp,ports:${SSH_PORT},address:${VPC_IP_RANGE} protocol:tcp,ports:22,address:${VPC_IP_RANGE} "
                fi
        elif ( ( [ "${NO_REVERSE_PROXY}" = "0" ] && [ "${firewall_name}" = "adt-webserver" ] ) || [ "${firewall_name}" = "adt-reverseproxy" ] || [ "${firewall_name}" = "adt-authenticator" ] )
        then
                rules=${rules}" protocol:tcp,ports:22,address:${VPC_IP_RANGE} protocol:tcp,ports:443,address:0.0.0.0/0 "
        fi

        rules=${rules}"  protocol:tcp,ports:443,address:${VPC_IP_RANGE} protocol:tcp,ports:${SSH_PORT},address:${VPC_IP_RANGE}"
        rules=${rules}" protocol:icmp,address:0.0.0.0/0"
        rules="`/bin/echo ${rules} | /usr/bin/tr -s ' '`"
fi

if ( [ "${firewall_name}" = "adt-database" ] )
then
        machine_identifier="db-${REGION}-${BUILD_IDENTIFIER}"

        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
        then
                rules="protocol:tcp,ports:${SSH_PORT},address:${build_machine_ip}/32"
        fi

        rules="${rules} protocol:tcp,ports:${SSH_PORT},address:${VPC_IP_RANGE} protocol:tcp,ports:${DB_PORT},address:${VPC_IP_RANGE} protocol:icmp,address:0.0.0.0/0"
        rules="`/bin/echo ${rules} | /usr/bin/tr -s ' '`"                
fi

if ( [ "${custom_rules}" != "" ] )
then
        rules="${rules} ${custom_rules}"

        /usr/local/bin/doctl compute firewall add-rules ${firewall_id} --inbound-rules "${rules}" --outbound-rules "protocol:tcp,ports:all,protocol:tcp,ports:all,address:0.0.0.0/0 protocol:udp,ports:all,address:0.0.0.0/0 protocol:icmp,address:0.0.0.0/0"

        machine_ids=""
        while ( [ "${machine_ids}" = "" ] )
        do
                machine_ids="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "${machine_identifier}" ${CLOUDHOST}`"
                /bin/sleep 5
        done

        for machine_id in ${machine_ids}
        do
                /usr/local/bin/doctl compute firewall add-droplets ${firewall_id} --droplet-ids ${machine_id}                
        done
fi
