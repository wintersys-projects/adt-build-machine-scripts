CLOUDHOST="linode"
firewall_id="${1}"

if ( [ "${CLOUDHOST}" = "linode" ] )
then
        if ( [ "`/usr/local/bin/linode-cli --json firewalls devices-list ${firewall_id} | /usr/bin/jq -r '.[]'`" = "" ] )
        then
                /usr/local/bin/linode-cli firewalls delete ${firewall_id}
        fi
fi
