1) To add a new webserver type, modify ${HOME}/providerscripts/websever/InstallWebserver.sh in the WEBSERVER scripts

2) Modify ${HOME}/providerscripts/websever/RestartWebserver.sh  for your new webserver type 

3) Add an option for your new webserver on the BUILD CLIENT script, ${BUILD_HOME}/selectionscripts/SelectWebserver.sh

Do some tests to make sure it installs and runs correctly. 
