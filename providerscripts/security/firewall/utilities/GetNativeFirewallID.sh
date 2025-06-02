CLOUDHOST="linode"
BUILD_IDENTIFIER="test"

firewall_name="${1}"

set -x

if ( [ "${CLOUDHOST}" = "linode" ] )
then
        /usr/local/bin/linode-cli --json firewalls list | /usr/bin/jq -r '.[] | select (.label | contains ("'${firewall_name}'")) |  select (.label | endswith ("'-${BUILD_IDENTIFIER}'")).id'
fi
