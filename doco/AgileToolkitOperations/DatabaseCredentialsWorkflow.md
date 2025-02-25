The credentials for your database service are configured on the build machine when you are running the main script before the actual server builds begin.

The script 

>     ${BUILD_HOME}/ExpeditedAgileDeploymentToolkit.sh 

at the appointed time will call 

>     ${BUILD_HOME}/initscripts/InitialiseDatabaseService.sh


If your database service is a managed service then if that service is not running yet then the process is started to provision the database (DBaaS) according to how you have defined your template. This may take some time. If the database service is already running then it is presumed that that is the service to be used and the process proceeds promptly.

Once the DBaaS is provisioned one way or the other, this script obtains the credentials from the DBaaS provider that have been assigned to the DBaaS system and you now have your database credentials.

The credentials are then stored on the build machine for use later on at the bottom of 

>     ${BUILD_HOME}/initscripts/InitialiseDatabaseService.sh

If possible, a SSL certificate for DBaaS connections is obtained from the DBaaS provider where you have provisioned your database and stored in 

>     ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DBaaS_CERT


If your database is self managed and it's just you spinning up a Mariadb, MySQL or Postgres instance on a VPS machine then all that this script does is assign some credentials to be used as the credentials for your database when it is spun up later in the build process as part of your build chain. The credentials that are defined here are also stored on the build machine for later usage.

In both cases (managed and self managed) the database credentials are passed over to the database machine running on the VPS using the 

>     ${BUILD_HOME)/builddescriptors/database_descriptor.dat 

mechanism. This mechanism uses cloud-init to pass all the necessary environment information to a particular machine (including the database credentials) type using cloud-init when the database VPS machine is provisioned

In the case when its not a virgin installation of an application type that we are installing, applications such as Joomla and Wordpress that this toolkit supports need to have their database credentials configured. Because the build machine knows and has assigned all the credentials that the application needs we configure the application's candidate configuration file on the build machine and copy the updated the pre-configured configuration file for the current application to the S3 datastore before we begin to build the servers. The webserver can then download the configuration file from S3 as part of its build process making the configured application ready and online in short order.

This is done in the 

>     ${BUILD_HOME}/providerscripts/application/SetApplicationConfig.sh 

file on the build machine

The webserver downloads and installs the application specific configuration file that the build-machine has kindly prepared for it in the file:

>     ${HOME}/providerscripts/application/configuration/SetApplicationConfiguration.sh
