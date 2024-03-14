To add a new variable to the build kit,

On the build client repository, add the new variable to **${BUILD_HOME}/builddescriptors/envdump.dat**  

If you want the variable to be available on autoscaler machines:  
On the build client repository, add the new variable to **${BUILD_HOME}/builddescriptors/autoscalerscp.dat**  

If you want the variable to be available on the webserver machines:  
On the build client repository, add the new variable to **${BUILD_HOME}/builddescriptors/webserverscp.dat**  

if you want the variable to be available on the database machines:  
On the build client repository, add the new variable to **${BUILD_HOME}/builddescriptors/databasescp.dat**  

NOTE: there needs to be an empty line at the end of each file so that all of the lines are read by the script

It is then a devlopment task as to how to access the values of these variables which are stored in

**${HOME}/.ssh/autoscaler_configuration_settings.dat** on the autoscaler  
**${HOME}/.ssh/webserver_configuration_settings.dat** on the autoscaler  
**${HOME}/.ssh/database_configuration_settings.dat** on the autoscaler  
