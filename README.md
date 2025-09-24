# README #

You can read about and find tutorials about the "Agile Deployment Toolkit" [here](https://www.wintersys-projects.uk)

-----------------------------

**${BUILD_HOME}/adt-build-machine-scripts/application**  
Here we have scripts related to the custom application that is being deployed, "Joomla, Wordpress, Drupal or Moodle"  

**${BUILD_HOME}/adt-build-machine-scripts/builddescriptors**  
This is where the builddescriptors are for the current build. You can make changes to the files that are here to configure a different build out  

**${BUILD_HOME}/adt-build-machine-scripts/buildscripts**  
These scripts will build different classes of server machine, for example, database, webserver or autoscaler machine types  

**${BUILD_HOME}/adt-build-machine-scripts/cron**
Scripts to do with any cron tasks that need to be run on your build machine (note, if your build machine is not online 24/7 you will need to review what cronjobs are set and perform them manually)

**${BUILD_HOME}/adt-build-machine-scripts/helperscripts**  
Utility scripts that can help you manage different workflows that your servers need  

**${BUILD_HOME}/adt-build-machine-scripts/initscripts**  
Initialisation scripts that intialised and configure different aspects of the build process  

**${BUILD_HOME}/adt-build-machine-scripts/installscripts**  
Scripts that install onto the build machine the software that is required for the build to succeed  

**${BUILD_HOME}/adt-build-machine-scripts/processingscripts**  
Scripts that perform an pre or post processing that the current build run requires  

**${BUILD_HOME}/adt-build-machine-scripts/providerscripts**  
Scripts that relate to 3rd party services that the build depends on such as a git provider or a cloudhost provider  

**${BUILD_HOME}/adt-build-machine-scripts/security** 
Functionality related to security that isn't provider specific. 

**${BUILD_HOME}/adt-build-machine-scripts/selectionscripts**  
Scripts that prompt for selection between particular service options when there needs to be a choice made.   

**${BUILD_HOME}/adt-build-machine-scripts/templatedconfigurations**  
Scripts related to the templating system of the current build

**${BUILD_HOME}/adt-build-machine-scripts/utilities**
Scripts thst provide general utility functions needed by the tooling

-----------------------

Early on in the development of this toolkit I supported AWS but I decided to strip out the AWS code that I had developed because it required various additional customisation and I want to keep the "core" of the toolkit as standardised as possible. The idea here is that I don't intend to modify these core repositories with additional function but rather to simply maintain and enhance the core 'as is' based on feedback from the community and to have any further customisations done in forks of these core repos. If you want to get stuck in with your own fork that supports AWS (possibly with features like EFS as well) then you might be interested in these archived repos that have the original AWS code that I developed and which might give you some pointers on how to go about it. 

[AWS Build Machine](https://github.com/wintersys-projects/adt-build-machine-scripts-withaws)  
[AWS Autoscaler](https://github.com/wintersys-projects/adt-autoscaler-scripts-withaws)  
[AWS Webserver](https://github.com/wintersys-projects/adt-webserver-scripts-withaws)  
[AWS Database](https://github.com/wintersys-projects/adt-database-scripts-withaws)  





