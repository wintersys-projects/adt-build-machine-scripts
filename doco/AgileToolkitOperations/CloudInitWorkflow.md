The following files need to be defined on the build machine

>     ${BUILD_HOME}/providerscripts/server/cloud-init/${CLOUDHOST}/authenticator.yaml
>     ${BUILD_HOME}/providerscripts/server/cloud-init/${CLOUDHOST}/autoscaler.yaml
>     ${BUILD_HOME}/providerscripts/server/cloud-init/${CLOUDHOST}/webserver.yaml
>     ${BUILD_HOME}/providerscripts/server/cloud-init/${CLOUDHOST}/database.yaml

Within these files the initialisation process for the server type is defined. 

Various placeholder tokens are held within these defining files such as

>     XXXXSERVER_USERXXXX
>     XXXXSERVER_USER_PASSWORDXXXX
>     XXXXSSH_PUBLIC_KEYXXXX
>     XXXXALGORITHMXXXX
>     XXXXSSH_PRIVATE_KEYXXXX

And each of these unique tokens is replaced with live data by the script 

>     ${BUILD_HOME}/initscripts/InitialiseCloudInit.sh

Once these placeholder tokens have been replaced as part of the build intialisation, the updated copy of the file is available as


>     ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/autoscaler_configuration_settings.dat
>     ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/webserver_configuration_settings.dat
>     ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/database_configuration_settings.dat

These files containing live data are then passed and used when the cli call is made to provision the machine from the script:

>     ${BUILD_HOME}/providerscripts/server/CreateServer.sh

The newly provisioned server machine will then provision itself and run the live cloud-init script that you have provided

If you want to see the log output the log files are kept under 

>     /var/log/cloud-init*

On the respective machines

----------------------

The same process needs to happen on the autoscaler machines when they provision new webservers.

The original file with placeholder tokens in it is kept at:

>     ${HOME}/providerscripts/server/cloud-init/${CLOUDHOST}/webserver.yaml

When a scaling event happens, the script

>     ${HOME}/autoscaler/InitialiseCloudInit.sh

is called which replaces the placeholders and makes the live script available at:

>     ${HOME}/runtime/cloud-init/webserver.yaml

When the script

>     ${HOME}/providerscripts/server/CreateServer.sh

is called, the live cloud-init script is passed to the cli call
