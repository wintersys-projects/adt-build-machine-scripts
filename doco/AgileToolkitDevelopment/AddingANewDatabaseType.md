1) On the build client, add the option for your new database to ${BUILD_HOME}/initscripts/InitialiseDatabase.sh

2) On the DATABASE codebase, add a directory for your new database in ${HOME}/providerscripts/singledb/{{{DB-NAME}}}

3) On the DATABASE codebase, in your newly created directory add the files Install{{{DB-NAME}}} and Initialise{{{DB-NAME}}}

4) On the DATABASE codebase, modify the file ${HOME}/providerscripts/singledb/InstallSingleDB.sh and add the option for your newly supported DB type.

5) On the DATABASE codebase, modify the file ${HOME}/applicationdb/InstallApplicationDB.sh and at the bottom of it modify it for your application. Add a subdirectory for you database type and the code to install an application into that type of database. Following the code in the examples should make it clear.

6) On the DATABASE codebase, modify the file ${HOME}/providerscripts/backupscripts/Backup.sh around about line 80 to support your database. If it is a NOSQL database for example, it will be a bit different or if it is not an mysql equivalent database, then it might be a bit different and so on.

7) On the WEBSERVER codebase, update each application which you want to have support available for your new database type. You do this by editing the scripts in ${HOME}/providerscripts/application/configuration/*

8) On the WEBSERVER codebase, maodify the script ${HOME}/utilities/InstallDatabaseClient.sh

9) Create a new alive.php script for your database type. Modify ${HOME}/providerscripts/utilities/CheckServerAlive.sh script to call the script specific to your database type.

10) Create a script specific to your database type called ${HOME}/providerscripts/utilities/dbalive/XXXalive.php
