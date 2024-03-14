If your provider has security groups or a firewall native to their service (not the ufw used by your machines internally), then, you will need to allow access through their firewall to the ports that the toolkit uses to run. If the provider native firewall doesn't allow requests through that you need to be let through, obviously, the build won't complete. So, as a general overview for my current setup I need to let the following through any cloudnative firewall which I do using their GUI:

1. Whatever your SSH port is set to. In my case, I set this to 1035 so I need a rule where the firewall/security group allows access to port 1035 for all machines
2. Whatever your Database port is set to. In my case I set this to 2035 so I need a rule where the firewall/security group allows access to port 2035 for the webservers.
3. The ports that you webserver can be reached on needs to be accessible. In my case, this is port 80 and port 443 (when using cloudflare, only cloudflare IP addresses are allowed access). 
4. The machines need to be able to ping each other, so the ICMP firewall setting needs to be open as well.

These values should all be set automatically by the script, but, failure to set any of these values according to your usage will fail the build (it will likely have timeouts). If you see any timeouts, suspect firewalling issues. 
