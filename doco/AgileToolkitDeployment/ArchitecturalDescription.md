### DEVELOPMENT MODE

In development mode, there are three machine types a "single webserver" and a "single database" server and a "build machine" upon which the server build process is initiated.  
Its possible for the build machine to be your own laptop if you are running some version of linux, but it is  
  
  **not recommended because it will make configuration changes to your machine**.  
    
What you can do is run a **dedicated** "Ubuntu" or "Debian" Linux off a usb stick with persistent storage on your laptop to perform your builds on and have that USB as your "build usb", this would save you a bit of money because you won't need to be running a (small) build machine in the cloud all the time.  
  
The webserver and the database share their configurations using the S3 object store of your cloudhost provider.   

Managed databases are not intended to be used in development mode, rather, use the custom installed database that is provisioned within the build process itself whilst you are in development mode.  
  
### PRODUCTION MODE

In production mode, there are four machine types: there is are autoscaler machines, there are webserver machines, there is a database server and there's a build machine upon which the build is initiated. There can also be (should also be) a managed database running to which your webservers are connecting.  
The autoscaler machine monitors the webservers for responsiveness and is responsible for initiating (and performing) the build of new webservers according to [scaling criteria](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/doco/AgileToolkitDeployment/ScalingConfiguration.md) (statically defined).  
The webservers have their ip addresses registered with a DNS system and load balancing between them performed using round robin.  
The Database server is responsible for runnng the database system. The Database system can use DBaaS managed databases but our own "database machine" still needs to run in such a scenario as we depend on our own custom backups which our database machine generates.


### FIREWALLING  

The firewalling by default works as follows, there are two layers to the firewalling, the cloudhost's native firewall and the ufw firewall running on the machines themselves:  

All machines allow SSH connections from your build machine and between each other only.  
Only webservers and autoscalers can connect to the database port (2035 by default)  
If you are using a managed database only machines in your private network can connect to the managed DB or the specific ip addresses of your webservers/database machine.  
If you are using Cloudflare, only Cloudflare ip addresses [Cloudflare IPs](https://www.cloudflare.com/en-gb/ips/) can connect to your webservers. Direct connections are not allowed to your webserver, only connections through the "Cloudflare Proxy". If you are not using Cloudflare, then, connections to ports 443 and 80 are allowed from anywhere. Cloudflare does provide some attractive features such as your being able to use "zero trust acccess control" to prevent direct access to anything that you don't explicitly allow. The similar solution I have provided for naked DNS systems where access to 443 and 80 has to be allowed from anywhere is the [Gateway Guardian (which uses basic auth)](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/doco/AgileToolkitDeployment/GatewayGuardian.md) and possibly there is the idea of using a [Registration Server](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/doco/AgileToolkitDeployment/RegistrationServer.md).  

### ADDITIONAL THOUGHTS  

On both the development mode and production mode temporal application backups can be made from the webservers and the database machines. 
Cron is used to schedule system processes on all machines and there is a defined process for [application development workflow](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/doco/AgileToolkitDeployment/ApplicatonWorkflow.md) starting in development mode and working up towards full production deployments with multiple webservers.
Applications can be deployed from baselines or from temporal backups depending on your needs. Temporal backups should always be kept private to your organisation where as baselines can be made public if you wish to share your prebuilt customised bespoke appliction with other developers 

**VERY IMPORTANT: - with appropriate care taken not to have sensitive credentials in the codebase/SQL dump of the baselines you are making public**  
  
It is envisioned that possibly you might want to sell your baselined applications to 3rd parties, possibly for a fiscal price and that it should be possible to have a "reviews site" with links to baselined repositories where other developers can review the prebuilt (meaning that all 3rd the pluings/modules are already installed and configured for you) applications you have baselined. In this way, suites of applications can be directly deployed such as prearranged blogging sites, prearranged social networking solutions and prearranged ecommerce setups and so on. Hope that is clear what I am trying to achieve here. 
