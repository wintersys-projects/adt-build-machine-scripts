


/usr/local/bin/doctl compute droplet list -o json | jq -r '.[] | select ( .name == "build-machine" ).status'
