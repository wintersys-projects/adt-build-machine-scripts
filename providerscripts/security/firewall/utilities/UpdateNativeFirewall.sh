CLOUDHOST="linode"
BUILD_IDENTIFIER="test"

firewall_id="${1}"
inbound_policy="${2}"
outbound_policy="${3}"
ruleset="${4}"

if ( [ "${CLOUDHOST}" = " linode" ] )
then
        /usr/local/bin/linode-cli firewalls rules-update  --inbound_policy ${inbound_policy} --outbound_policy ${outbound_policy} --inbound ${ruleset} ${firewall_id}
fi
