If you wish to add an SMTP service to the Agile Deployment Toolkit, then here is what you need to do.

On the build client

1. Review the code in ${BUILD_HOME}/initscripts/InitialiseSMTPMailServer.sh

2. Look for the code which adds the new SMTP Provider and sets the environment variable SYSTEM_EMAIL_PROVIDER. Add your new provider here

3. For the Autoscaler, the Webserver and the Database, connect to each one in turn and  go to the directory

${HOME}/providerscripts/email

in the same directory on each machine type (autoscaler, webserver, database) , edit the file SendEmail.sh and add your provider to the script following the code which is already there.

4) ${HOME}/providerscripts/application/email

in this directory edit the file ConfigureSMTP.sh and add your new SMTP provider code following the code that is already there as an example

That's it, you should have successfully added a new SMTP service





