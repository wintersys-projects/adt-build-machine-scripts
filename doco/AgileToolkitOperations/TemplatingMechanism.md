The templating system works by holding a set of templates in the directory:

>     ${BUILD_HOME}/templatedconfigurations/templates/${CLOUDHOST}/${CLOUDHOST}[n].tmpl

There are 3 classes of template

template no 1 is for vigin style builds and you can set your values accordingly in this template when you want to deploy a new CMS instance

template no 2 is for baseline style builds and you need to set appropriate values here when you want to build from a baseline

template no 3 is for temporal style builds and again you can set your values here when you want to perform a temporal build

When you initiate the build process you will be asked which style of template you  want to build from and so presuming that you have set appropriate values in the correct template type you will be able to select 1, 2 or 3 at the appropriate time to begin the build process

The templating mechanism does its best to validate what you have put in your template but just be aware if there's something wrong in your template, like, for example, you choose an invalid VPS machine size, then, the build will fail because it will try and build a machine at a size that doesn't exist. 

The values that your template holds are selectively copied to the different machine types that you are building so that those machines are aware of your configuration wishes. This copying is done through the cloud-init process and the values you set are available in 

>     ${HOME}/runtime/autoscaler_configuration_settings.dat
>     ${HOME}/runtime/webserver_configuration_settings.dat
>     ${HOME}/runtime/database_configuration_settings.dat

respectively. What values are copied to each of the respective machines out of the total environment that is available once the template has been loaded is defined in the files:

>     ${BUILD_HOME}/builddescriptors/autoscaler_descriptor.dat
>     ${BUILD_HOME}/builddescriptors/webserver_descriptor.dat
>     ${BUILD_HOME}/builddescriptors/database_descriptor.dat

If you want to add a new value to a template you need to add it to all your templates and then update these files to reflect its addition
