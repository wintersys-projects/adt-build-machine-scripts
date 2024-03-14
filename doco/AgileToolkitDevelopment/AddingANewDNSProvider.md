1) To add a new DNS provider, first of all, research the provider, they must support round robin DNS loadbalancing. If they do, then you can think about adding them as a provider with this toolkit as long as they have a suitable API or CLI toolkit to programmatically access their DNS service. Cloudflare has lots of additional security services you can add with free and more extensive payed plans. 

2) Add your new DNS provider to the ${BUILDHOME}/selectionscripts/SelectDNSProvider.sh script, following the example methodologies.

3) Update ${BUILD_HOME}/providerscripts/dns/* on the Build client

4) Update ${HOME}/providerscipts/dns/* on the Autoscaler

5) Update ${HOME}/security/ObtainSSLCertificate.sh on Webserver codebase

6) Update ${HOME}/providerscripts/dns/SetupDNSFirewallRules.sh on webserver

7) update ${BUILD_HOME}/providerscripts/server/ObtainSSLCertificate.sh on buildmachine


NOTE: On the Webserver codebase when you implement ${HOME}/provider/dns/SetupDNSFirewall.sh make the rules as tight as you can. In the cloudflare case, the firewall will only except requests from  a cloudflare IP. This is the case when the DNS service is acting as a proxy and actually rerouting the requests via their service so they can filter bad actors so they never hit your site. In other cases, the DNS reuqests are routed straight to your webserver from any IP address on the internet. In this case, it is imperitive that your firewall is active and it should be set to accept requests from anywhere to port 443 and only port 443. 


