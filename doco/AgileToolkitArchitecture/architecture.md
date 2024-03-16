1. When you run this toolkit it will follow several prebuild steps to make sure that it has everything that the build process needs in order. The main steps that it needs to complete successfully before the build can begin are:

   Make sure software the needed software is up to date and installed
   Select the cloudhost that you are deploying to (this overrides any values you set in the template when you deploy using the Expedited method)
   Load the values you have set in your template into memory for use in the build process (including soft errors you can act on if the template is values are considered erroneous)
   Configure the cloudhost CLI tools that you will be using for the build this involves reading a template file and replacing placeholders with template values
   Checking if you want to set SMTP settings for system emails if the values aren't set in your template
   Initialise the configuration file for the CLI tool you are using to access your S3 datastore
   Find out what type of application you are deploying by interrogating the application sourcecode and looking for indicators based on file structure as to which application type it it
   Setup/create the native firewalls but don't add any rules or machines to them machines to them.
   Insitialise the SSH security keys so that we can SSH onto our machines using a known BUILD_KEY public/private pair
   If we believe that the build machine is in the same VPC as our new servers will be check that it is and if it isn't add it to the VPC to be sure
   Generate the SSL certificate for your webserver and securely copy it to the S3 datastore where it can be obtained by any of our main server machines (webservers basically)
   
   


2. When you begin a build with this buildkit it will expect you to have selected a build chain in the file by setting a value for BUILDCHAINTYPE:

   ${BUILD_HOME}/builddescriptors/buildstylesscp.dat

   If you have selected the "standard" build chain time which you most probabaly have then for production mode the build process will build autoscaler(s), webserver and database machines by calling the files

   ${BUILD_HOME}/buildscripts/BuildAutoscaler.sh
   ${BUILD_HOME}/buildscripts/BuildWebserver.sh
   ${BUILD_HOME}/buildscripts/BuildDatabase.sh

   If you are building for DEVELOPMENT rather than production only a webserver and a database will be built

3. Once the build kit considers these machines to have been fully built a finalisation process takes place which ensures that the servers are ready for use. The finalisation process involves the exchange of configuration details making sure that each machine type has claimed to have built correctly and also that the connection to the database from the webserver is established and operational. After all of this has taken place the native firewall has rules added to it suitable for our needs (as tight as possible basically) and each of the machines we have built are added to the native firewall if our template is configured to require the use of a native firewall.





