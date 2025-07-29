/usr/local/bin/linode-cli --json linodes ips-list 80988701 | /usr/bin/jq -r '.[].ipv6.slaac.address'
