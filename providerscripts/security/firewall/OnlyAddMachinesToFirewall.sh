status () {
        /bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        /bin/echo "${0}: ${1}" >> /dev/fd/4
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
ACTIVE_FIREWALLS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ACTIVE_FIREWALLS`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"

if ( [ "${ACTIVE_FIREWALLS}" = "2" ] || [ "${ACTIVE_FIREWALLS}" = "3" ] )
then
        status ""
        status ""
        status "###############################################################"
        status "Adding your machines to the firewalls, please wait...."
        status "###############################################################"

        if ( [ "${CLOUDHOST}" = "digitalocean" ] )
        then
                autoscaler_ids="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
                autoscaler_firewall_id="`/usr/local/bin/doctl -o json compute firewall list | /usr/bin/jq -r '.[] | select (.name == "adt-autoscaler-'${BUILD_IDENTIFIER}'" ).id'`"
                for autoscaler_id in ${autoscaler_ids}
                do
                        /usr/local/bin/doctl compute firewall add-droplets ${autoscaler_firewall_id} --droplet-ids ${autoscaler_id}                
                done

                webserver_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
                webserver_firewall_id="`/usr/local/bin/doctl -o json compute firewall list | /usr/bin/jq -r '.[] | select (.name == "adt-webserver-'${BUILD_IDENTIFIER}'").id'`"
                /usr/local/bin/doctl compute firewall add-droplets ${webserver_firewall_id} --droplet-ids ${webserver_id}

                database_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
                database_firewall_id="`/usr/local/bin/doctl -o json compute firewall list | /usr/bin/jq -r '.[] | select (.name == "adt-database-'${BUILD_IDENTIFIER}'" ).id'`"
                /usr/local/bin/doctl compute firewall add-droplets ${database_firewall_id} --droplet-ids ${database_id} 
        fi

        if ( [ "${CLOUDHOST}" = "exoscale" ] )
        then
                autoscaler_ids="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
                for autoscaler_id in ${autoscaler_ids}
                do
                        /usr/bin/exo compute instance security-group add ${autoscaler_id} adt-autoscaler-${BUILD_IDENTIFIER}
                done
                webserver_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
                /usr/bin/exo compute instance security-group add ${webserver_id} adt-webserver-${BUILD_IDENTIFIER}
                database_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
                /usr/bin/exo compute instance security-group add ${database_id} adt-database-${BUILD_IDENTIFIER}
        fi
        
        if ( [ "${CLOUDHOST}" = "linode" ] )
        then
                autoscaler_ids="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
                autoscaler_firewall_id="`/usr/local/bin/linode-cli --json firewalls list | /usr/bin/jq -r '.[] | select (.label == "adt-autoscaler-'${BUILD_IDENTIFIER}'").id'`"
                webserver_firewall_id="`/usr/local/bin/linode-cli --json firewalls list | /usr/bin/jq -r '.[] | select (.label == "adt-webserver-'${BUILD_IDENTIFIER}'").id'`"
                webserver_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
                database_firewall_id="`/usr/local/bin/linode-cli --json firewalls list | /usr/bin/jq -r '.[] | select (.label == "adt-database-'${BUILD_IDENTIFIER}'").id'`"
                database_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

                for autoscaler_id in ${autoscaler_ids}
                do
                        /usr/local/bin/linode-cli firewalls device-create --id ${autoscaler_id} --type linode ${autoscaler_firewall_id} 2>/dev/null
                done

                /usr/local/bin/linode-cli firewalls device-create --id ${webserver_id} --type linode ${webserver_firewall_id} 
                /usr/local/bin/linode-cli firewalls device-create --id ${database_id} --type linode ${database_firewall_id} 
        fi

        if ( [ "${CLOUDHOST}" = "vultr" ] )
        then
                autoscaler_ids="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
                firewall_id="`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description == "adt-autoscaler-'${BUILD_IDENTIFIER}'").id'`"
                for autoscaler_id in ${autoscaler_ids}
                do
                        /usr/bin/vultr instance update-firewall-group ${autoscaler_id} -f ${firewall_id}
                done
        
                webserver_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
                firewall_id="`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description == "adt-webserver-'${BUILD_IDENTIFIER}'").id'`"
                /usr/bin/vultr instance update-firewall-group ${webserver_id} -f ${firewall_id}
                database_id="`${BUILD_HOME}/providerscripts/server/ListServerIDs.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
                firewall_id="`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description == "adt-database-'${BUILD_IDENTIFIER}'").id'`"
                /usr/bin/vultr instance update-firewall-group ${database_id} -f ${firewall_id}
        fi
fi
