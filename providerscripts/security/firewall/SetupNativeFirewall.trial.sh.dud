#!/bin/sh
########################################################################################
# Author: Peter Winter
# Date  : 12/07/2021
# Description : This will set up the native firewall. 
# It will allow SSH connections from the build machine and access to port 443 if we are
# using a proxy service as well as access to the database port that our database server is 
# run on. There is a firewall type for each class of machine, autoscaler, webserver, database
# and the appropriate firewall is applied to its corresponding class of machine
########################################################################################
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
#########################################################################################
#########################################################################################
#set -x

status () {
        /bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
        /bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

pre_build="${1}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`" 
ACTIVE_FIREWALLS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ACTIVE_FIREWALLS`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"
DB_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DB_PORT`"
VPC_IP_RANGE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh VPC_IP_RANGE`"
REVERSE_PROXY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REVERSE_PROXY`"
AUTHENTICATION_SERVER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTHENTICATION_SERVER`"

if ( [ "${ACTIVE_FIREWALLS}" = "2" ] || [ "${ACTIVE_FIREWALLS}" = "3" ] )
then
        build_machine_ip="`${BUILD_HOME}/helperscripts/GetBuildMachineIP.sh`"

        status ""
        status ""
        status "###############################################################"
        status "Just adjusting your native firewalling system , please wait...."
        status "###############################################################"

        if ( [ "${CLOUDHOST}" = "digitalocean" ] )
        then
                if ( [ "${pre_build}" = "0" ] )
                then
                        autoscaler_ids="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

                        rules=""

                        if ( [ "${autoscaler_ids}" != "" ] )
                        then
                                if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                                then
                                        rules="protocol:tcp,ports:${SSH_PORT},address:${build_machine_ip}/32"
                                fi

                                rules="${rules} protocol:tcp,ports:${SSH_PORT},address:${VPC_IP_RANGE} protocol:icmp,address:0.0.0.0/0"
                                rules="`/bin/echo ${rules} | /usr/bin/tr -s ' '`"

                                autoscaler_firewall_id="`/usr/local/bin/doctl -o json compute firewall list | /usr/bin/jq -r '.[] | select (.name == "adt-autoscaler-'${BUILD_IDENTIFIER}'" ).id'`"
                                /usr/local/bin/doctl compute firewall add-rules ${autoscaler_firewall_id} --inbound-rules "${rules}"

                                for autoscaler_id in ${autoscaler_ids}
                                do
                                        /usr/local/bin/doctl compute firewall add-droplets ${autoscaler_firewall_id} --droplet-ids ${autoscaler_id}                
                                done
                        fi

                        webserver_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

                        if ( [ "${webserver_id}" != "" ] )
                        then
                                rules=""

                                if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                                then
                                        rules="protocol:tcp,ports:${SSH_PORT},address:${build_machine_ip}/32"
                                fi

                                ${BUILD_HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh

                                if ( [ "${alldnsproxyips}" != "" ] )
                                then
                                        for ip in ${alldnsproxyips}
                                        do
                                                rules=${rules}" protocol:tcp,ports:443,address:${ip} " 
                                        done
                                        rules=${rules}" protocol:tcp,ports:${SSH_PORT},address:${VPC_IP_RANGE} protocol:tcp,ports:22,address:${VPC_IP_RANGE} "
                                else
                                        rules=${rules}" protocol:tcp,ports:${SSH_PORT},address:${VPC_IP_RANGE} protocol:tcp,ports:22,address:${VPC_IP_RANGE} protocol:tcp,ports:443,address:0.0.0.0/0 "
                                fi
                                rules=${rules}"  protocol:tcp,ports:443,address:${VPC_IP_RANGE} " 
                                rules=${rules}" protocol:icmp,address:0.0.0.0/0"
                                rules="`/bin/echo ${rules} | /usr/bin/tr -s ' '`"

                                webserver_firewall_id="`/usr/local/bin/doctl -o json compute firewall list | /usr/bin/jq -r '.[] | select (.name == "adt-webserver-'${BUILD_IDENTIFIER}'").id'`"
                                /usr/local/bin/doctl compute firewall add-rules ${webserver_firewall_id} --inbound-rules "${rules}"
                                /usr/local/bin/doctl compute firewall add-droplets ${webserver_firewall_id} --droplet-ids ${webserver_id}
                        fi

                        database_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

                        if ( [ "${database_id}" != "" ] )
                        then
                                rules=""
                                if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                                then
                                        rules="protocol:tcp,ports:${SSH_PORT},address:${build_machine_ip}/32"
                                fi

                                rules="${rules} protocol:tcp,ports:${SSH_PORT},address:${VPC_IP_RANGE} protocol:tcp,ports:${DB_PORT},address:${VPC_IP_RANGE} protocol:icmp,address:0.0.0.0/0"
                                rules="`/bin/echo ${rules} | /usr/bin/tr -s ' '`"

                                database_firewall_id="`/usr/local/bin/doctl -o json compute firewall list | /usr/bin/jq -r '.[] | select (.name == "adt-database-'${BUILD_IDENTIFIER}'" ).id'`"
                                /usr/local/bin/doctl compute firewall add-rules ${database_firewall_id} --inbound-rules "${rules}"
                                /usr/local/bin/doctl compute firewall add-droplets ${database_firewall_id} --droplet-ids ${database_id}                
                        fi
                elif ( [ "${pre_build}" = "1" ] )
                then
                        firewall_ids="`/usr/local/bin/doctl -o json compute firewall list | /usr/bin/jq -r '.[] | select (.name | contains ("adt-autoscaler")) | select (.name | endswith("'-${BUILD_IDENTIFIER}'") | not).id'`"
                        firewall_ids="${firewall_ids} `/usr/local/bin/doctl -o json compute firewall list | /usr/bin/jq -r '.[] | select (.name | contains ("adt-webserver")) | select (.name | endswith("'-${BUILD_IDENTIFIER}'") | not).id'`"
                        firewall_ids="${firewall_ids} `/usr/local/bin/doctl -o json compute firewall list | /usr/bin/jq -r '.[] | select (.name | contains ("adt-database")) | select (.name | endswith("'-${BUILD_IDENTIFIER}'") | not).id'`"

                        if ( [ "${firewall_ids}" != "" ] )
                        then
                                for firewall_id in ${firewall_ids}
                                do
                                        if ( [ "`/usr/local/bin/doctl -o json compute firewall list | /usr/bin/jq -r '.[] | select (.id == "'${firewall_id}'").droplet_ids[]'`" = "" ] )
                                        then
                                                /bin/echo "y" | /usr/local/bin/doctl compute firewall delete ${firewall_id} --force 
                                        fi
                                done
                        fi

                        if ( [ "`/usr/local/bin/doctl compute firewall list -o json | /usr/bin/jq -r '.[] | select (.name == "adt-autoscaler-'${BUILD_IDENTIFIER}'").id'`" = "" ] )
                        then
                                /usr/local/bin/doctl compute firewall create --name "adt-autoscaler-${BUILD_IDENTIFIER}" --outbound-rules "protocol:tcp,ports:all,address:0.0.0.0/0 protocol:udp,ports:all,address:0.0.0.0/0 protocol:icmp,address:0.0.0.0/0"
                        fi

                        if ( [ "`/usr/local/bin/doctl compute firewall list -o json | /usr/bin/jq -r '.[] | select (.name == "adt-webserver-'${BUILD_IDENTIFIER}'").id'`" = "" ] )
                        then
                                /usr/local/bin/doctl compute firewall create --name "adt-webserver-${BUILD_IDENTIFIER}" --outbound-rules "protocol:tcp,ports:all,address:0.0.0.0/0 protocol:udp,ports:all,address:0.0.0.0/0 protocol:icmp,address:0.0.0.0/0"
                        fi

                        if ( [ "`/usr/local/bin/doctl compute firewall list -o json | /usr/bin/jq -r '.[] | select (.name == "adt-database-'${BUILD_IDENTIFIER}'").id'`" = "" ] )
                        then
                                /usr/local/bin/doctl compute firewall create --name "adt-database-${BUILD_IDENTIFIER}" --outbound-rules "protocol:tcp,ports:all,address:0.0.0.0/0 protocol:udp,ports:all,address:0.0.0.0/0 protocol:icmp,address:0.0.0.0/0"
                        fi
        fi 
    fi

        if ( [ "${CLOUDHOST}" = "exoscale" ] )
        then
                if ( [ "${pre_build}" = "0" ] )
                then
                        autoscaler_ids="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

                        if ( [ "${autoscaler_ids}" != "" ] )
                        then
                                if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                                then
                                        /usr/bin/exo compute security-group rule add adt-autoscaler-${BUILD_IDENTIFIER} --network ${build_machine_ip}/32 --port ${SSH_PORT}
                                fi
                                /usr/bin/exo compute security-group rule add adt-autoscaler-${BUILD_IDENTIFIER} --network ${VPC_IP_RANGE} --port ${SSH_PORT}
                                /usr/bin/exo compute security-group rule add adt-autoscaler-${BUILD_IDENTIFIER} --protocol icmp --network 0.0.0.0/0 --icmp-code 0 --icmp-type 8

                                for autoscaler_id in ${autoscaler_ids}
                                do
                                        /usr/bin/exo compute instance security-group add ${autoscaler_id} adt-autoscaler-${BUILD_IDENTIFIER}
                                done
                        fi

                        webserver_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

                        if ( [ "${webserver_id}" != "" ] )
                        then
                                if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                                then
                                        /usr/bin/exo compute security-group rule add adt-webserver-${BUILD_IDENTIFIER} --network ${build_machine_ip}/32 --port ${SSH_PORT}
                                fi

                                /usr/bin/exo compute security-group rule add adt-webserver-${BUILD_IDENTIFIER} --protocol icmp --network 0.0.0.0/0 --icmp-code 0 --icmp-type 8
                                /usr/bin/exo compute security-group rule add adt-webserver-${BUILD_IDENTIFIER} --network ${VPC_IP_RANGE} --port ${SSH_PORT}

                                ${BUILD_HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh

                                if ( [ "${alldnsproxyips}" != "" ] )
                                then
                                alldnsproxyips="`/bin/echo ${alldnsproxyips} | /bin/sed 's/,/ /g' | /bin/sed 's/^"//g' | /bin/sed 's/"$//g'`"
                                        for ip in ${alldnsproxyips}
                                        do
                                                /usr/bin/exo compute security-group rule add adt-webserver-${BUILD_IDENTIFIER} --network ${ip} --port 443
                                        done
                                        /usr/bin/exo compute security-group rule add adt-webserver-${BUILD_IDENTIFIER} --network ${VPC_IP_RANGE} --port 443
                                else
                                        /usr/bin/exo compute security-group rule add adt-webserver-${BUILD_IDENTIFIER} --network 0.0.0.0/0 --port 443
                                fi
                                /usr/bin/exo compute instance security-group add ${webserver_id} adt-webserver-${BUILD_IDENTIFIER}
                        fi
                        database_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

                        if ( [ "${database_id}" != "" ] )
                        then
                                if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                                then
                                        /usr/bin/exo compute security-group rule add adt-database-${BUILD_IDENTIFIER} --network ${build_machine_ip}/32 --port ${SSH_PORT}
                                        /usr/bin/exo compute security-group rule add adt-database-${BUILD_IDENTIFIER} --network ${build_machine_ip}/32 --port ${DB_PORT}
                                fi

                                /usr/bin/exo compute security-group rule add adt-database-${BUILD_IDENTIFIER} --protocol icmp --network 0.0.0.0/0 --icmp-code 0 --icmp-type 8
                                /usr/bin/exo compute security-group rule add adt-database-${BUILD_IDENTIFIER} --network ${VPC_IP_RANGE} --port ${SSH_PORT}
                                /usr/bin/exo compute security-group rule add adt-database-${BUILD_IDENTIFIER} --network ${VPC_IP_RANGE} --port ${DB_PORT}
                                /usr/bin/exo compute instance security-group add ${database_id} adt-database-${BUILD_IDENTIFIER}
                        fi
                elif ( [ "${pre_build}" = "1" ] )
                then
                        firewall_ids="`/usr/bin/exo -O json compute security-group list | /usr/bin/jq -r '.[] | select (.name | contains ("adt-autoscaler")) |  select (.name | endswith ("'-${BUILD_IDENTIFIER}'") | not).id'`"
                        firewall_ids="${firewall_ids} `/usr/bin/exo -O json compute security-group list | /usr/bin/jq -r '.[] | select (.name | contains ("adt-webserver")) |  select (.name | endswith ("'-${BUILD_IDENTIFIER}'") | not).id'`"
                        firewall_ids="${firewall_ids} `/usr/bin/exo -O json compute security-group list | /usr/bin/jq -r '.[] | select (.name | contains ("adt-database")) |  select (.name | endswith ("'-${BUILD_IDENTIFIER}'") | not).id'`"

                        if ( [ "${firewall_ids}" != "" ] )
                        then
                                for firewall_id in ${firewall_ids}
                                do
                                        if ( [ "`/usr/bin/exo -O json compute security-group show ${firewall_id} | /usr/bin/jq -r '.instances'`" = "null" ] )
                                then
                                                /bin/echo "y" | /usr/bin/exo compute  security-group delete ${firewall_id}
                                        fi
                                done
                        fi

                        if ( [ "`/usr/bin/exo -O json compute security-group list | /usr/bin/jq -r '.[] | select (.name == "adt-autoscaler-'${BUILD_IDENTIFIER}'").id'`" = "" ] )
                        then
                                /usr/bin/exo compute security-group create adt-autoscaler-${BUILD_IDENTIFIER} 
                        fi
                        if ( [ "`/usr/bin/exo -O json compute security-group list | /usr/bin/jq -r '.[] | select (.name == "adt-webserver-'${BUILD_IDENTIFIER}'").id'`" = "" ] )
                        then
                        /usr/bin/exo compute security-group create adt-webserver-${BUILD_IDENTIFIER} 
                fi
                        if ( [ "`/usr/bin/exo -O json compute security-group list | /usr/bin/jq -r '.[] | select (.name == "adt-database-'${BUILD_IDENTIFIER}'").id'`" = "" ] )
                        then
                                /usr/bin/exo compute security-group create adt-database-${BUILD_IDENTIFIER} 
                        fi
        fi
    fi

        if ( [ "${CLOUDHOST}" = "linode" ] )
        then       
                if ( [ "${pre_build}" = "0" ] )
                then
                        ${BUILD_HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh

                        ruleset=""
                        rule_vpc='{"addresses":{"ipv4":["'${VPC_IP_RANGE}'"]},"action":"ACCEPT","protocol":"TCP","ports":"1-65535"}'
                        rule_build_machine='{"addresses":{"ipv4":["'${build_machine_ip}/32'"]},"action":"ACCEPT","protocol":"TCP","ports":"'${SSH_PORT}'"}'
                        rule_icmp='{"addresses":{"ipv4":["0.0.0.0/0"]},"action":"ACCEPT","protocol":"ICMP"}'

                        if ( [ "${alldnsproxyips}" = "" ] )
                        then
                                rule_ssl='{"addresses":{"ipv4":["0.0.0.0/0"]},"action":"ACCEPT","protocol":"TCP","ports":"443"}'
                        else
                                rule_ssl='{"addresses":{"ipv4":['${alldnsproxyips}']},"action":"ACCEPT","protocol":"TCP","ports":"443"}'
                        fi

                        autoscaler_ids="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

                        autoscaler_firewall_id="`${BUILD_HOME}/providerscripts/security/firewall/utilities/GetNativeFirewallID.sh "adt-autoscaler"`"
                        
                        if ( [ "${autoscaler_firewall_id}" = "" ] )
                        then
                                ${BUILD_HOME}/providerscripts/security/firewall/utilities/CreateNativeFirewall.sh "adt-autoscaler" DROP ACCEPT
                                autoscaler_firewall_id"`${BUILD_HOME}/providerscripts/security/firewall/utilities/GetNativeFirewallID.sh "adt-autoscaler"`"
                        fi

                        ruleset=""

                        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                        then
                                ruleset='['${rule_vpc}','${rule_build_machine}','${rule_icmp}']'
                        elif ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
                        then
                                ruleset='['${rule_vpc}','${rule_icmp}']'
                        fi

                        ${BUILD_HOME}/providerscripts/security/firewall/utilities/UpdateNativeFirewall.sh "${autoscaler_firewall_id}" DROP ACCEPT ${ruleset}

                        webserver_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
                        proxyserver_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "rp-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
                        authenticator_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "auth-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

                        webserver_firewall_id="`${BUILD_HOME}/providerscripts/security/firewall/utilities/GetNativeFirewallID.sh "adt-webserver"`"
                        proxyserver_firewall_id="`${BUILD_HOME}/providerscripts/security/firewall/utilities/GetNativeFirewallID.sh "adt-proxyserver"`"
                        authenticator_firewall_id="`${BUILD_HOME}/providerscripts/security/firewall/utilities/GetNativeFirewallID.sh "adt-authenticator"`"

                        if ( [ "${webserver_firewall_id}" = "" ] )
                        then
                                ${BUILD_HOME}/providerscripts/security/firewall/utilities/CreateNativeFirewall.sh "adt-webserver" DROP ACCEPT
                                webserver_firewall_id"`${BUILD_HOME}/providerscripts/security/firewall/utilities/GetNativeFirewallID.sh "adt-webserver"`"
                        fi

                        if ( [ "${proxyserver_firewall_id}" = "" ] )
                        then
                                ${BUILD_HOME}/providerscripts/security/firewall/utilities/CreateNativeFirewall.sh "adt-proxyserver" DROP ACCEPT
                                proxyserver_firewall_id"`${BUILD_HOME}/providerscripts/security/firewall/utilities/GetNativeFirewallID.sh "adt-proxyserver"`"
                        fi

                        if ( [ "${authenticator_firewall_id}" = "" ] )
                        then
                                ${BUILD_HOME}/providerscripts/security/firewall/utilities/CreateNativeFirewall.sh "adt-authenticator" DROP ACCEPT
                                authenticator_firewall_id"`${BUILD_HOME}/providerscripts/security/firewall/utilities/GetNativeFirewallID.sh "adt-authenticator"`"
                        fi
                        
#                       ips="`/bin/echo ${ips} | /bin/sed 's/,$//g'`"

                        if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
                        then
                                rule_build_machine=""
                        fi

                        firewall_names="adt-webserver adt-proxyserver adt-authenticator"

                        for firewall_name in ${firewall_names}
                        do
                                if ( [ "${alldnsproxyips}" = "" ] )
                                then
                                        if ( [ "${REVERSE_PROXY}" = "1" ] )
                                        then
                                                if ( "${rule_build_machine}" != "" ] )
                                                then
                                                        if ( [ "${firewall_name}" = "adt-webserver" ] )
                                                        then
                                                                ruleset='['${rule_vpc}','${rule_build_machine}','${rule_icmp}']'
                                                        elif ( [ "${firewall_name}" = "adt-proxyserver" ] )
                                                        then
                                                                ruleset='['${rule_vpc}','${rule_build_machine}','${rule_icmp}','${rule_ssl}']'
                                                        elif ( [ "${firewall_name}" = "adt-authenticator" ] )
                                                        then
                                                                ruleset='['${rule_vpc}','${rule_build_machine}','${rule_icmp}','${rule_ssl}']'
                                                        fi
                                                else
                                                        if ( [ "${firewall_name}" = "adt-webserver" ] )
                                                        then
                                                                ruleset='['${rule_vpc}','${rule_icmp}']'
                                                        elif ( [ "${firewall_name}" = "adt-proxyserver" ] )
                                                        then
                                                                ruleset='['${rule_vpc}','${rule_icmp}','${rule_ssl}']'
                                                        elif ( [ "${firewall_name}" = "adt-authenticator" ] )
                                                        then
                                                                ruleset='['${rule_vpc}','${rule_icmp}','${rule_ssl}']'
                                                        fi
                                                fi
                                        else
                                                if ( "${rule_build_machine}" != "" ] )
                                                then
                                                        if ( [ "${firewall_name}" = "adt-webserver" ] )
                                                        then
                                                                ruleset='['${rule_vpc}','${rule_build_machine}','${rule_icmp}','${rule_ssl}']'
                                                        elif ( [ "${firewall_name}" = "adt-authenticator" ] )
                                                        then
                                                                ruleset='['${rule_vpc}','${rule_build_machine}','${rule_icmp}','${rule_ssl}']'
                                                        fi
                                                else
                                                        if ( [ "${firewall_name}" = "adt-webserver" ] )
                                                        then
                                                                ruleset='['${rule_vpc}','${rule_icmp}','${rule_ssl}']'
                                                        elif ( [ "${firewall_name}" = "adt-authenticator" ] )
                                                        then
                                                                ruleset='['${rule_vpc}','${rule_icmp}','${rule_ssl}']'
                                                        fi
                                                fi
                                        fi
                                fi

                                if ( [ "${firewall_name}" = "adt-webserver" ] )
                                then
                                        ${BUILD_HOME}/providerscripts/security/firewall/utilities/UpdateNativeFirewall.sh "${webserver_firewall_id}" DROP ACCEPT ${ruleset}
                                elif ( [ "${firewall_name}" = "adt-proxyserver" ] && [ "${REVERSE_PROXY}" = "1" ] )
                                then
                                        if ( [ "${REVERSE_PROXY}" = "1" ] )
                                        then
                                                ${BUILD_HOME}/providerscripts/security/firewall/utilities/UpdateNativeFirewall.sh "${proxyserver_firewall_id}" DROP ACCEPT ${ruleset}
                                        else
                                                ${BUILD_HOME}/providerscripts/security/firewall/utilities/DeleteNativeFirewall.sh "${proxyserver_firewall_id}"
                                        fi
                                elif ( [ "${firewall_name}" = "adt-authenticator" ] )
                                then
                                        if ( [ "${AUTHENTICATION_SERVER}" = "1" ] )
                                        then
                                                ${BUILD_HOME}/providerscripts/security/firewall/utilities/UpdateNativeFirewall.sh "${authenticator_firewall_id}" DROP ACCEPT ${ruleset}
                                        else
                                                ${BUILD_HOME}/providerscripts/security/firewall/utilities/DeleteNativeFirewall.sh "${authenticator_firewall_id}"
                                        fi
                                fi
                        done


                        database_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
                        database_firewall_id="`${BUILD_HOME}/providerscripts/security/firewall/utilities/GetNativeFirewallID.sh "adt-database"`"

                        if ( [ "${database_firewall_id}" = "" ] )
                        then
                                ${BUILD_HOME}/providerscripts/security/firewall/utilities/CreateNativeFirewall.sh "adt-database" DROP ACCEPT
                                database_firewall_id"`${BUILD_HOME}/providerscripts/security/firewall/utilities/GetNativeFirewallID.sh "adt-database"`"
                        fi

                        ruleset=""

                        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                        then
                                ruleset='['${rule_vpc}','${rule_build_machine}','${rule_icmp}']'
                        elif ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
                        then
                                ruleset='['${rule_vpc}','${rule_icmp}']'
                        fi

                        ${BUILD_HOME}/providerscripts/security/firewall/utilities/UpdateNativeFirewall.sh "${database_firewall_id}" DROP ACCEPT ${ruleset}

                        for autoscaler_id in ${autoscaler_ids}
                        do
                                /usr/local/bin/linode-cli firewalls device-create --id ${autoscaler_id} --type linode ${autoscaler_firewall_id} 2>/dev/null
                        done

                        for proxyserver_id in ${proxyserver_ids}
                        do
                                /usr/local/bin/linode-cli firewalls device-create --id ${proxyserver_id} --type linode ${proxyserver_firewall_id} 2>/dev/null
                        done

                        for authenticator_id in ${authenticator_ids}
                        do
                                /usr/local/bin/linode-cli firewalls device-create --id ${authenticator_id} --type linode ${authenticator_firewall_id} 2>/dev/null
                        done

                        /usr/local/bin/linode-cli firewalls device-create --id ${webserver_id} --type linode ${webserver_firewall_id} 
                        /usr/local/bin/linode-cli firewalls device-create --id ${database_id} --type linode ${database_firewall_id} 
                elif ( [ "${pre_build}" = "1" ] )
                then
                        firewall_ids=""
                        firewall_names="adt-autoscaler adt-webserver adt-database adt-proxyserver adt-authenticator"

                        for firewall_name in ${firewall_names}
                        do
                                firewall_ids="`${BUILD_HOME}/providerscripts/security/firewall/utilities/GetNativeFirewallID.sh "${firewall_name}"`"
                        done

                        if ( [ "${firewall_ids}" != "" ] )
                        then
                                for firewall_id in ${firewall_ids}
                                do
                                        ${BUILD_HOME}/providerscripts/security/firewall/utilities/DeleteNativeFirewall.sh "${firewall_id}"
                                done
                        fi

                        for firewall_name in ${firewall_names}
                        do
                                ${BUILD_HOME}/providerscripts/security/firewall/utilities/CreateNativeFirewall.sh ${firewall_name} ACCEPT ACCEPT
                        done
                        
        fi    
    fi


        if ( [ "${CLOUDHOST}" = "vultr" ] )
        then
                if ( [ "${pre_build}" = "0" ] )
                then
                        #VPC_IP_RANGE doesn't need to be allowed by the firewall for vultr, machines in the same VPC can communiate by default by private IP
                        autoscaler_ids="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

                        if ( [ "${autoscaler_ids}" != "" ] )
                        then
                                firewall_id="`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description == "adt-autoscaler-'${BUILD_IDENTIFIER}'").id'`"
                                if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                                then
                                        /usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=${SSH_PORT} --size=32 --ip-type=v4 --subnet=${build_machine_ip}/32
                                fi

                                /usr/bin/vultr firewall rule create ${firewall_id} --protocol icmp --size 32 --ip-type v4 -s 0.0.0.0/0

                                for autoscaler_id in ${autoscaler_ids}
                                do
                                        /usr/bin/vultr instance update-firewall-group ${autoscaler_id} -f ${firewall_id}
                                done
                        fi  
   
                        webserver_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

                        if ( [ "${webserver_id}" != "" ] )
                        then
                                firewall_id="`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description == "adt-webserver-'${BUILD_IDENTIFIER}'").id'`"    
                                ${BUILD_HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh

                                if ( [ "${alldnsproxyips}" != "" ] )
                                then
                                        /usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=443 --size=32 --ip-type=v4  --source=cloudflare --subnet=10.0.0.0/8
                                        /usr/bin/vultr firewall rule create ${firewall_id} --protocol=icmp --size=32 --ip-type=v4 --subnet=0.0.0.0/0
                                else 
                                        /usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=443 --size=32 --ip-type=v4 --subnet=0.0.0.0/0
                                        /usr/bin/vultr firewall rule create ${firewall_id} --protocol=icmp --size=32 --ip-type=v4 --subnet=0.0.0.0/0
                                fi

                                if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                                then
                                        /usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=${SSH_PORT} --size=32 --ip-type=v4 --subnet=${build_machine_ip}/32
                                fi

                                /usr/bin/vultr firewall rule create ${firewall_id} --protocol icmp --size 32 --ip-type v4 -s 0.0.0.0/0
                                /usr/bin/vultr instance update-firewall-group ${webserver_id} -f ${firewall_id}
                        fi

                        database_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

                        if ( [ "${database_id}" != "" ] )
                        then
                                firewall_id="`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description == "adt-database-'${BUILD_IDENTIFIER}'").id'`"

                                if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                                then
                                        /usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=${SSH_PORT} --size=32 --ip-type=v4 --subnet=${build_machine_ip}/32
                                fi
                                /usr/bin/vultr firewall rule create ${firewall_id} --protocol icmp --size 32 --ip-type v4 -s 0.0.0.0/0
                                /usr/bin/vultr instance update-firewall-group ${database_id} -f ${firewall_id}
                        fi
                elif ( [ "${pre_build}" = "1" ] )
                then
                        # cleanup any hangover firewalls
                        firewall_ids="`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description | contains ("adt-autoscaler")) |  select (.description | endswith ("'-${BUILD_IDENTIFIER}'") | not).id'`"
                        firewall_ids="${firewall_ids} `/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description | contains ("adt-webserver")) |  select (.description | endswith ("'-${BUILD_IDENTIFIER}'") | not).id'`"
                        firewall_ids="${firewall_ids} `/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description | contains ("adt-database")) |  select (.description | endswith ("'-${BUILD_IDENTIFIER}'") | not).id'`"
                
                        if ( [ "${firewall_ids}" != "" ] )
                        then
                                for firewall_id in ${firewall_ids}
                                do
                                        if ( [ "`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.id == "'${firewall_id}'")|.instance_count'`" = "0" ] )
                                        then
                                                /usr/bin/vultr firewall group delete ${firewall_id}
                                        fi
                                done
                        fi

                        if ( [ "`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description == "adt-autoscaler-'${BUILD_IDENTIFIER}'").id'`" = "" ] )
                        then        
                                firewall_id="`/usr/bin/vultr firewall group create -o json | /usr/bin/jq -r '.firewall_group.id'`"  
                                /usr/bin/vultr firewall group update ${firewall_id} --description "adt-autoscaler-${BUILD_IDENTIFIER}"
                        fi
                        
                        if ( [ "`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description == "adt-webserver-'${BUILD_IDENTIFIER}'").id'`" = "" ] )
                        then
                                firewall_id="`/usr/bin/vultr firewall group create -o json | /usr/bin/jq -r '.firewall_group.id'`"  
                                /usr/bin/vultr firewall group update ${firewall_id} --description "adt-webserver-${BUILD_IDENTIFIER}"
                        fi
                        
                        if ( [ "`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description == "adt-database-'${BUILD_IDENTIFIER}'").id'`" = "" ] )
                        then
                                firewall_id="`/usr/bin/vultr firewall group create -o json | /usr/bin/jq -r '.firewall_group.id'`"  
                                /usr/bin/vultr firewall group update ${firewall_id} --description "adt-database-${BUILD_IDENTIFIER}"
                        fi
                fi
        fi
fi
