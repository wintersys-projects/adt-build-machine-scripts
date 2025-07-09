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

#set -x

if ( [ "${ACTIVE_FIREWALLS}" = "2" ] || [ "${ACTIVE_FIREWALLS}" = "3" ] )
then
        if ( [ "${CLOUDHOST}" = "digitalocean" ] )
        then
                all_dns_proxy_ips="`${BUILD_HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh`"
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

                        if ( [ "${NO_REVERSE_PROXY}" = "1" ] && [ "${firewall_name}" = "adt-reverseproxy" ] )
                        then
                                if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                                then
                                            rules="protocol:tcp,ports:443,address:${build_machine_ip}/32 protocol:tcp,ports:${SSH_PORT},address:${build_machine_ip}/32"
                                else
                                            rules="protocol:tcp,ports:${SSH_PORT},address:${build_machine_ip}/32"
                                fi
                        fi

                        if ( [ "${all_dns_proxy_ips}" != "" ] && [ "${firewall_name}" != "adt-authenticator" ] )
                        then
                            if ( ( [ "${NO_REVERSE_PROXY}" = "0" ] && [ "${firewall_name}" = "adt-webserver" ] ) || [ "${firewall_name}" = "adt-reverseproxy" ] )
                            then
                                for ip in ${all_dns_proxy_ips}
                                do
                                      rules=${rules}" protocol:tcp,ports:443,address:${ip} " 
                                done
                                rules=${rules}" protocol:tcp,ports:${SSH_PORT},address:${VPC_IP_RANGE} protocol:tcp,ports:22,address:${VPC_IP_RANGE} "
                            fi
                         else
                               rules=${rules}" protocol:tcp,ports:${SSH_PORT},address:${VPC_IP_RANGE} protocol:tcp,ports:22,address:${VPC_IP_RANGE} protocol:tcp,ports:443,address:0.0.0.0/0 "
                         fi

                         rules=${rules}"  protocol:tcp,ports:443,address:${VPC_IP_RANGE} " 
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
        if ( [ "${CLOUDHOST}" = "exoscale" ] )
        then
                all_dns_proxy_ips="`${BUILD_HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh`"

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

                if ( [ "${firewall_name}" = "adt-autoscaler" ] )
                then
                        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                        then
                                /usr/bin/exo compute security-group rule add adt-autoscaler-${BUILD_IDENTIFIER} --network ${build_machine_ip}/32 --port ${SSH_PORT} &
                        fi
                        /usr/bin/exo compute security-group rule add adt-autoscaler-${BUILD_IDENTIFIER} --network ${VPC_IP_RANGE} --port ${SSH_PORT} &
                        /usr/bin/exo compute security-group rule add adt-autoscaler-${BUILD_IDENTIFIER} --protocol icmp --network 0.0.0.0/0 --icmp-code 0 --icmp-type 8 &
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
                                /usr/bin/exo compute security-group rule add adt-database-${BUILD_IDENTIFIER} --network ${build_machine_ip}/32 --port ${SSH_PORT} &
                                /usr/bin/exo compute security-group rule add adt-database-${BUILD_IDENTIFIER} --network ${build_machine_ip}/32 --port ${DB_PORT} &
                        fi

                        /usr/bin/exo compute security-group rule add adt-database-${BUILD_IDENTIFIER} --protocol icmp --network 0.0.0.0/0 --icmp-code 0 --icmp-type 8 &
                        /usr/bin/exo compute security-group rule add adt-database-${BUILD_IDENTIFIER} --network ${VPC_IP_RANGE} --port ${SSH_PORT} &
                        /usr/bin/exo compute security-group rule add adt-database-${BUILD_IDENTIFIER} --network ${VPC_IP_RANGE} --port ${DB_PORT} &
                fi

                /bin/echo "ADT_FIREWALL_ID:${firewall_name}-${BUILD_IDENTIFIER}"
        fi
        
        if ( [ "${CLOUDHOST}" = "linode" ] )
        then
                all_dns_proxy_ips="`${BUILD_HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh`"

                ruleset=""
                rule_vpc='{"addresses":{"ipv4":["'${VPC_IP_RANGE}'"]},"action":"ACCEPT","protocol":"TCP","ports":"1-65535"}'
                rule_build_machine='{"addresses":{"ipv4":["'${build_machine_ip}/32'"]},"action":"ACCEPT","protocol":"TCP","ports":"'${SSH_PORT}'"}'
                rule_build_machine_ssl='{"addresses":{"ipv4":["'${build_machine_ip}/32'"]},"action":"ACCEPT","protocol":"TCP","ports":"443"}'
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

                if ( [ "${firewall_name}" = "adt-autoscaler" ] )
                then
                        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                        then
                                ruleset='['${rule_vpc}','${rule_build_machine}','${rule_icmp}']'
                        elif ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
                        then
                                ruleset='['${rule_vpc}','${rule_icmp}']'
                        fi
                fi

                if ( ( [ "${NO_REVERSE_PROXY}" = "0" ] && [ "${firewall_name}" = "adt-webserver" ] ) ||  [ "${firewall_name}" = "adt-authenticator" ]  ||  [ "${firewall_name}" = "adt-reverseproxy" ] )
                then
                        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                        then
                                ruleset='['${rule_vpc}','${rule_build_machine}','${rule_build_machine_ssl}','${rule_icmp}','${rule_ssl}']'
                        else
                                ruleset='['${rule_vpc}','${rule_icmp}','${rule_ssl}']'
                        fi
                else
                        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                        then
                                if ( [ "${NO_REVERSE_PROXY}" != "0" ] && [ "${firewall_name}" = "adt-webserver" ] )
                                then
                                        ruleset='['${rule_vpc}','${rule_build_machine}','${rule_icmp}']'
                                fi
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

       if ( [ "${CLOUDHOST}" = "vultr" ] )
        then
                all_dns_proxy_ips="`${BUILD_HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh`"

                firewall_id="`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description == "'${firewall_name}'-'${BUILD_IDENTIFIER}'").id'`"
                
                if ( [ "${firewall_id}" = "" ] )
                then
                        firewall_id="`/usr/bin/vultr firewall group create -o json | /usr/bin/jq -r '.firewall_group.id'`"
                        /usr/bin/vultr firewall group update ${firewall_id} --description "${firewall_name}-${BUILD_IDENTIFIER}"
                else
                        if ( [ "`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.id == "'${firewall_id}'")|.instance_count'`" = "0" ] )
                        then
                                rules="`/usr/bin/vultr firewall rule list ${firewall_id} -o json | /usr/bin/jq -r '.firewall_rules[].id'`"
                                for rule in ${rules}
                                do
                                        /usr/bin/vultr firewall rule delete ${firewall_id} ${rule}
                                done
                        fi
                fi

                if ( [ "${firewall_name}" = "adt-autoscaler" ] )
                then
                        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                        then
                                /usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=${SSH_PORT} --size=32 --ip-type=v4 --subnet=${build_machine_ip}/32                        
                        fi
                        /usr/bin/vultr firewall rule create ${firewall_id} --protocol=icmp --size=32 --ip-type=v4 --subnet=0.0.0.0/0
                fi

                if ( [ "${firewall_name}" = "adt-webserver" ] ||  [ "${firewall_name}" = "adt-authenticator" ]  ||  [ "${firewall_name}" = "adt-reverseproxy" ] )
                then
                        if ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                        then
                                /usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=${SSH_PORT} --size=32 --ip-type=v4 --subnet=${build_machine_ip}/32                        
                        fi

                        if ( [ "${all_dns_proxy_ips}" != "" ] && [ "${firewall_name}" != "adt-authenticator" ] )
                        then
                                if ( ( [ "${NO_REVERSE_PROXY}" = "0" ] && [ "${firewall_name}" = "adt-webserver" ] ) || [ "${firewall_name}" = "adt-reverseproxy" ] )
                                then
                                        /usr/bin/vultr firewall rule create ${firewall_id} --protocol=tcp --port=443 --size=32 --ip-type=v4  --source=cloudflare --subnet=10.0.0.0/8
                                        /usr/bin/vultr firewall rule create ${firewall_id} --protocol=icmp --size=32 --ip-type=v4 --subnet=0.0.0.0/0
                                fi
                        else
                                /usr/bin/vultr firewall rule create ${firewall_id} --protocol=icmp --size=32 --ip-type=v4 --subnet=0.0.0.0/0                       
                        fi
                fi

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
fi
