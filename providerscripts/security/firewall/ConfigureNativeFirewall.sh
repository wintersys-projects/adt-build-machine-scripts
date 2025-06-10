firewall_name="${1}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`" 
ACTIVE_FIREWALLS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ACTIVE_FIREWALLS`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"
VPC_IP_RANGE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh VPC_IP_RANGE`"
NO_REVERSE_PROXY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NO_REVERSE_PROXY`"
AUTHENTICATION_SERVER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh AUTHENTICATION_SERVER`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
build_machine_ip="`${BUILD_HOME}/helperscripts/GetBuildMachineIP.sh`"

#set -x

if ( [ "${ACTIVE_FIREWALLS}" = "2" ] || [ "${ACTIVE_FIREWALLS}" = "3" ] )
then
        if ( [ "${CLOUDHOST}" = "linode" ] )
        then
                all_dns_proxy_ips="`${BUILD_HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh`"

                ruleset=""
                rule_vpc='{"addresses":{"ipv4":["'${VPC_IP_RANGE}'"]},"action":"ACCEPT","protocol":"TCP","ports":"1-65535"}'
                rule_build_machine='{"addresses":{"ipv4":["'${build_machine_ip}/32'"]},"action":"ACCEPT","protocol":"TCP","ports":"'${SSH_PORT}'"}'
                rule_icmp='{"addresses":{"ipv4":["0.0.0.0/0"]},"action":"ACCEPT","protocol":"ICMP"}'

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

                if ( [ "${firewall_name}" = " adt-autoscaler" ] )
                then
                        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                        then
                                ruleset='['${rule_vpc}','${rule_build_machine}','${rule_icmp}']'
                        elif ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
                        then
                                ruleset='['${rule_vpc}','${rule_icmp}']'
                        fi
                fi

                if ( ( [ "${NO_REVERSE_PROXY}" = "0" ] && [ "${firewall_name}" = "adt-webserver" ] ) ||  [ "${firewall_name}" = "adt-authenticator" ]  ||  [ "${firewall_name}" = "adt-proxyserver" ] )
                then
                        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                        then
                                ruleset='['${rule_vpc}','${rule_build_machine}','${rule_icmp}','${rule_ssl}']'
                        else
                                ruleset='['${rule_vpc}','${rule_icmp}','${rule_ssl}']'
                        fi
                else
                        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                        then
                                ruleset='['${rule_vpc}','${rule_build_machine}','${rule_icmp}']'
                        else
                                ruleset='['${rule_vpc}','${rule_icmp}']'
                        fi
                fi

                if ( [ "${firewall_name}" = "adt-database" ] )
                then
                        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                        then
                                ruleset='['${rule_vpc}','${rule_build_machine}','${rule_icmp}']'
                        elif ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
                        then
                                ruleset='['${rule_vpc}','${rule_icmp}']'
                        fi
                fi

                /usr/local/bin/linode-cli firewalls rules-update  --inbound_policy DROP --outbound_policy ACCEPT --inbound ${ruleset} ${firewall_id}

                if ( [ "$?" = "0" ] )
                then
                        /bin/echo "ADT_FIREWALL_ID:${firewall_id}"
                fi
        fi
fi
