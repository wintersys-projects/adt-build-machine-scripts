You can add a new cloudhost provider relatively easily although you will need to do this in fork. You might want to add a cloudhost provider if there is a particular provider you prefer that isn't supported yet. Possible suitable additional cloudhosts might be Rackspace or Google Cloud, for example.  Each provider may have its own quirks as such, but, it should be possible to make most providers, as long as they provide and API and an access toolkit fit into this framework. You shouldn't need to worry about any of the other files in the framework when you are adding a new service provider, the only files you need to worry about are listed here. Also, the changes you make to the BUILD CLIENT should be similar in most cases to the changes you make on the autoscaler. In fact, the build client and the autoscaler do more or less the same job, launch servers, interrogate and query servers.

1) Add the cloud provider to the ${BUILD_HOME}/selectionscripts/SelectCloudhost.sh and ${BUILD_HOME}/selectionscripts/SelectCloudhostExpedited.sh

2) On the BUILD CLIENT update all the files in these directories for your new cloudhost following the examples which are already there.
       
        ${BUILD_HOME}/providerscripts/security/*.sh
        ${BUILD_HOME}/providerscripts/security/firewall/*.sh
        ${BUILD_HOME}/providerscripts/cloudhost/*.sh
        ${BUILD_HOME}/providerscripts/server/*.sh

3) On the AUTOSCALER update all the files in these directories for your new cloudhost following the examples which are already there.
       
        ${HOME}/providerscripts/security/*.sh
        ${HOME}/providerscripts/security/firewall/*.sh
        ${HOME}/providerscripts/cloudhost/*.sh
        ${HOME}/providerscripts/server/*.sh

4) On the AUTOSCALER, add your provider to ${HOME}/providerscripts/cloudhost/InstallCloudhostTools.sh

5) On the AUTOSCALER, WEBSERVER, DATABASE update the utility scripts, GetIP.sh and GetPublicIP.sh for your provider.

6) Update the scripts in ${BUILD_HOME}/helperscripts for your new cloudprovider.

Once you have updated your scripts, do some test deployments to see if it is working correctly.
