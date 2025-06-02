CLOUDHOST="linode"
BUILD_IDENTIFIER="test"

firewall_name="${1}"
inbound_policy="${2}"
outbound_policy="${3}"

if ( [ "${CLOUDHOST}" = "linode" ] )
then
        /usr/local/bin/linode-cli firewalls create --label "${firewall_name}-${BUILD_IDENTIFIER}" --rules.inbound_policy ${inbound_policy}   --rules.outbound_policy ${outbound_policy}
fi
