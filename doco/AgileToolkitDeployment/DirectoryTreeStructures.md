On the build machine

```${BUILD_HOME}/builddescriptors/autoscalerscp.dat``` - the autoscaler relevant environment variables  
```${BUILD_HOME}/builddescriptors/databasescp.dat``` - the database relevant environment variables  
```${BUILD_HOME}/builddescriptors/webserverscp.dat``` - the webserver relevant environment variables   

```${BUILD_HOME}/builddescriptors/buildstyles.dat``` - configuration of different build methods for the tools we want to work with  

--------------------------------------------

```${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER``` - the currently active build identifier - user provider string    

```/${BUILD_HOME}/runtimedata/ACTIVE_CLOUDHOST``` - the currently active cloudhost - one of "digitalocean", "exoscale", "linode", "vultr"  

```${BUILD_HOME}/runtimedata/BUILD_MACHINE_CLOUDHOST``` - same as above but your build machine could be a different cloudhost to your main cloudhost. For example, you can run your build_machine on linode but be deploying to exoscale in which case the BUILD_MACHINE_CLOUDHOST would be different to your main cloudhost  

```${BUILD_HOME}/runtimedata/PRIME_FIREWALL``` - tells the firewalling system to prime itself  

```${BUILD_HOME}/runtimedata/${cloudhost}``` - this is a main directory and for builds for a particular cloudhost, digitalocean, exoscale, linode, vultr  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}``` - a directory for a particular build_identifier for a particular cloudhost  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/APPLICATION:${application}``` - where application can be one of joomla, wordpress, drupal or moodle - this tells us which application has been or is being deployed for this particular cloudhost and build_identifier  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/autoscaler_configuration_settings.dat``` - this is the autoscaler environment settings generated from the template and possibly user input. This file will be ssh copied to any autoscaler machine that is provisioned  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/build_environment``` - this is a copy of the environment as it was immediately prior to the commencement of a build. It can be referre to to see what the system thinks things were set to and compared to what you think it should be set to  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/CLOUDHOST:${cloudhost}``` - this is alread set in the directtory path and also in the ACTIVE_CLOUDHOST file but it is also recorded here for convenient access  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/${configuration_file}``` - for example configration.php if we are deploying joomla or wp_config.php if we are deploying wordpress. We extract this file from the CMS system being deployed and configure it on the build machine with attributes like the database credentials and any other application configuration settings that we chose to modify. The configured file is then copied to the datastore and the websevers we deploy then look for it in the datastore, ready configured for our application and can simply get their own copy from the datastore and take it from there.  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/credentials``` - this contains credentials such as server username and password as well as the ssh public key and public key id. The database credentials used to configure the application we are installing are also stored here.  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/${build_identifier}``` - we already know the build_identifier from the directory path we are using, but, the build_identifier is stored here for easy access and if it is here it tells us that a build is actually in progress rather than just being prepared.   

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/CURRENTREGION``` - this tells us the current region for this particular build the region is build specific you could have a deployment to one region for one build_identifier and another deployment for another build_identifier  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/database_configuration_settings.dat``` - this is the database server environment settings as generated from the template and possibly user input. This file will be ssh copied to any database machine that is being provisioned.   

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/dbp.dat``` - this is the application specific database prefix as obtained for the current application we are installing.  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/EMERGENCY_PASSWORD``` - the linode deployments generate an emergency password for machine access through lish. The other providers don't generate an emergency password as part of the build process.  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/INITIAL_BUILD_COMPLETED``` - the existence of this file tells us that a particular build_identifier has completed its initial build process we can check for this file to see how far we are into the build  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/ips``` - this directory is used for storing ip addresses for easy access that have been generated by the build process such as database ip addresses.  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/keys``` - this holds the private and public keys for our server machines. The public key can be copied to our servers as we build them and the private key can be used from here to authenticate to the servers. This directory also contains the keys generated during our ssh_keyscan of each new machine that is build. By using strict host checking we aren't risking being spoofed as often as we would be without using strict host checking.  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/${cloudhost}${template_no}.tmpl``` this is a copy of the template that we are building from and tells us how we want our servers arranged.  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/logs``` - this is where error and output stream logs are stored for a build  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/ssl``` - the ssl certificates that we want to install on our webservers are stored here we can ssh copy them from here to our webserver and also the datastore for easy access by our webservers. They are checked for expiration as part of the build process.  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/TOKEN``` -this is the api token for our current cloudhost. It is kept here for easy access.  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/VPC_ACTIVE``` - this is a placeholder file and if it is here then it means that our build_machine is operating from within the same VPC as our server machines are.  

```${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/webserver_configuration_settings.dat``` - this is the webserver environment settings as generated from the template and possibly user input. This file will be ssh copied to any webserver machine that is being provisioned. 

------------------------------------

```${BUILD_HOME}/buildscripts``` This directory is here for holding scripts which do the main builds of different machine types in the build chain such as autoscaler type machines, webserver type machines and database time machines. Other machine types can be added to build chains such as Caching machine types if you wanted to extend to the toolkit to provide support for caching systems as well.

```${BUILD_HOME}/doco``` - this is the directory where documentation to do with the ADT can be stored, maintained and added to. You will find documentation in regard to development, deployment and operations

```${BUILD_HOME}/helperscripts``` - Here you will find helperscripts which can do things like performance of interactive machine backups or connecting to different machine types over ssh with the management of the requisite keys managed by the scripts for you

```${BUILD_HOME}/initscripts``` - This directory is for scripts which perform various initialisation processes such as the initiation of error reporting or a datastore initiation 

```${BUILD_HOME}/installscripts``` - I use just regular apt mostly to install the software and the idea is to have installation scripts which can be written and added for any additional software that you want to install in the future or if you want to install a particular software using a different installation method. And so all install scripts should be located here for organisational reasons and convenient access as well.

```${BUILD_HOME}/migration``` - If you are migrating the code base of, say, a joomla application from a different hosting provider this directory will likely be relevant to you according the recommended migration process which you can find elsewhere in this documentation

```${BUILD_HOME}/processingscripts``` - The scripts located here are for doing any kind of application specific processing that is required. Its conceivable that during a build some application types might need speical treatment which you can write code for and apply here if you need to.

```${BUILD_HOME}/selectionscripts``` - This is basically for interactive scripts where a partcular selection needs to be made, for example, which cloudhost you are deploying to and so on.

```${BUILD_HOME}/templatedconfiguration``` - Anything to do with the templates that are used to perform the build prcess is located here. In ordinary operation you will most likely clone the ADT and head to this directory to populate the variables of the appropriate template for your cloudhost of choice and build style with the values necessary for the build to proceed. 

----------------------------


Autoscaler

```${HOME}/runtime/ATOP_RUNNING``` - this flag tells us if ATOP is running or not. We can check any time to see if ATOP is running or not using this flag
```${HOME}/runtime/AUTHORISED_TO_SCALE``` - once the intial scaling is completed after a new autoscaler is provisioned, this flag is set which we can then check for to verify if we can provision new machines or not

```${HOME}/runtime/autoscalelock.file``` - this flag is a lock file such that it can be checked to see if an autoscaling cycle is active. If an autoscaling cycle is active then another autoscaling cycle can't be initiated.
```${HOME}/runtime/AUTOSCALER_READY``` - this flag tells us that an actual autoscaler machine has successfully been built. It is checked from the build-machine if we want to have more confidence that an autoscaling machine has built correctly
```${HOME}/runtime/AUTOSCALINGMONITOR``` - This file tells us that an actual webserver is in the process of being built on this autoscaler. Because each autoscaler can concurrently build multiple webservers, you will find this file indexed for each webserver that is provisioned so that we have a record we can check when we believe that that webserver is being provisioned
```${HOME}/runtime/beingbuiltips``` - Once a webserver has its ip assigned we keep a record here that we can check to tell us that that particular ip address belongs to a provisioning webserver. Once the webserver is provisioned we remove it from the beingbuildips directory. We need this so that we don't think the machine is unresponsive whilst it is provisoning and consider it a termination candidate.
```${HOME}/runtime/beingbuiltpublicips``` - this is the same as the beingbuilips but for the machines public ip addresses rather than their private ones
```${HOME}/runtime/BUILDCLIENTIP``` - this is a placeholder for the build machine's ip address. It is stored here for convenience.
```${HOME}/runtime/BUILD_IN_PROGRESS``` - this is just a generic flag that tells us that some sort of webserver provisioning is taking place on this autoscaler. It doesn't tell us how many webservers or any details only that some sort of provisioning of webservers has taken place
```${HOME}/runtime/CPU_OVERLOAD_ACKNOWLEDGED, ${HOME}/runtime/LOW_DISK_ACKNOWLEDGED, ${HOME}/runtime/LOW_MEMORY_ACKNOWLEDGED``` - this flag tells us whenever we have notified the user by email of some sort of low resource situation. Using this flag it means we only send emails periodically rather than multi times consequtively in short order as we might do without these flags
```${HOME}/runtime/FIREWALL-ACTIVE``` - this tells us that our firewall of choice is active. We can check this flag to see if we believe we have activated the firewall or not
```${HOME}/runtime/INITIALBUILDCOMPLETED``` - This flag is created by the build machine and it is set when the build machine believes that the initial build it is responsible for is completed. This is different or can be different to when it is believed that the autoscaler itself completed its own provisioning. The initial build status is used to regulate the cooling down period before the autoscaling of any additional webservers begins. This is configured to 5 minutes by default but you can change this to any value you want to suit your taste.
```${HOME}/runtime/INITIALLY_PROVISIONING``` - This tells us that a machine is literally in its initial provisioning or start up phase. This value wraps its arms around the time between when the cli call to "create server" is made and the time when that naked server is first considerd "up" or "pingable". 
```${HOME}/runtime/INITIALLY_SCALING_PROCESSSED``` - once the 5 minute cooling off period is processed after an autoscaler is provisioned this flag is set and we consider that the initial scaling has been processed which means that we are authorised to scale other new webservers now. 



Webserver

```${HOME}/runtime/AUTOSCALED_WEBSERVER_ONLINE``` - this flag is set from an autoscler on the current webserver to let us know that this webserver is online and was generated as a scaling event rather than as part of initial infrastructure provisioning
