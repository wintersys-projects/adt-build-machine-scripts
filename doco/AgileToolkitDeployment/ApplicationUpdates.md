OFFLINE UPDATING 

**BEFORE DOING ANYTHING MAKE SURE YOU HAVE GOT WORKING BACKUPS OF YOUR WEBSITE. YOU MIGHT WANT TO SIMPLY RENAME YOUR HOURLY BACKUPS WITH A .orig or .working DIRECTLY USING YOUR GIT PROVIDER'S GUI SO THAT THEY ARE NOT OVERWRITTEN BY THIS PROCESS AND YOU CAN ROLL BACK TO THEM IF SOMETHING GOES WRONG**

1. Put your website into maintenance mode through the CMS administration panel. Your visitors should then see "Maintenance mode - come back later"
2. Switch your deployment infrastucture into maintenance mode

if You have multiple autoscalers running **MAKE SURE** that you run this script one time for **each autoscaler** to switch them all to maintenance mode  

**cd ${BUILD_HOME}/helperscripts  
/bin/sh ./ExecuteOnAutoscaler.sh MAINTENANCE_MODE_ON**  

3. Switching into maintenance mode will scale down your infrastructure so that only one webserver is running and hence no other webroots to sync to. Be aware that if any backups are made whilst you are in maintenance mode they might be inconsistent if they are made midway through your CMS plugin/modules update/upgrade. You can then make updates as you desire including full CMS version updates whilst in maintenance mode.

4. Thoroughly test your website is operating as expected and then either manually generate temporal backups of your application webroot using "PerformWebsiteBackup.sh" or wait for hourly backups to be made by the system. **NOTE IF YOU DIDN'T DO THE PRELIMINARY RENAME, THEN, GENERATING NEW HOURLY BACKUPS WILL OVERWRITE YOUR ORIGINAL HOURLY BACKUPS WHICH COULD BE BAD**  
    #### IMPORTANT NOTE: If you deployed your website from backup periodicities other than hourly, such as daily, weekly and so on, you will need to make backups of your updated webroot and database for those periodicities. For a daily backup periodicity you can do that with the following commands on your one running webserver and database:
    
    run ${HOME}/providerscripts/backupscripts/Backup.sh HOURLY <build_identifier>

5. Check the integrity of the backups. CheckApplicationRepositoryIntegrity.sh

6. Switch maintenance mode off

if You have multiple autoscalers running **MAKE SURE** that you run this script one time for each autoscaler to switch off maintenance mode for them all

**cd ${BUILD_HOME}/helperscripts  
/bin/sh ./ExecuteOnAutoscaler.sh MAINTENANCE_MODE_OFF**  

7. Your website will then scale up to the number of webservers it is set to scale to when in full operation

8. Take your CMS out of maintenance mode using the administration panel of the CMS itself. 

9. Your site should then be online and ready for visitors again. 
