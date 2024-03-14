**CUSTOMISED APPLICATION DEVELOPMENT WORKFLOW SUMMARY**

IN DEVELOPMENT MODE:  

1. Deploy a virgin copy of your chosen CMS system    
2. Modify the virgin copy of your CMS system using regular CMS development practices such as installing plugins and modules to create a bespoke customised application.  
3. Once you are happy with your bespoke application create a baseline of it using (on your build machine):    
  
**${BUILD_HOME}/helperscripts/PerformWebsiteBaseline.sh** and **${BUILD_HOME}/helperscripts/PerformDatabaseBaseline.sh** 
  
4. Take the servers that are currently deployed offline (shut them down and destroy them)  
5. Deploy (for testing purposes as well as workflow purposes) from the baseline that you have created in 3.  
6. Once the baseline is deployed to your custom url, make a temporal backup of it (hourly, weekly etc.) using (on your build machine): 
  
**${BUILD_HOME}/helperscripts/PerformWebsiteBackup.sh** and **${BUILD_HOME}/helperscripts/PerformDatabaseBackup.sh**    

Click here for [more detail](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/doco/AgileToolkitDeployment/BackupProcessOverview.md) on the backup procedure/process. 
  
IN PRODUCTION MODE:  

1. Deploy from the temporal backup that you made in 7. above. You have a choice you can   
    a. Choose to make snapshots of the machines as they deploy  
    b. Just be done with it and not bother using snapshots in which case this is your "live" deployment and you can start onboarding users. Autoscaled webservers will take longer to provision using this technique but, if you are happy with that (your application doesn't need rapid scaling) that's fine.  
2. If you made snapshots of your machines, then, you need to take those servers you provisioned the snapshots from offline (shutdown and destroy them) and redeploy using the snapshots previously generated (in step a above). 
3. This is upfront effort for long term easy because once you have got your snapshots generated you can build your application off those in short order. Alternatively you can just rely on full builds but your machines will take a few minutes more to come online as you deploy them.   

--------------

**NOTE 1:**  
  
It is essential that your APPLICATION_IDENTIFIER is set when you are making a backup or a baseline.  
    
The **APPLICATIONIDENTIFIER** should be set to **1** if your application is **Joomla** based  
The **APPLICATIONIDENTIFIER** should be set to **2** if your application is **Wordpress** based  
The **APPLICATIONIDENTIFIER** should be set to **3** if your application is **Drupal** based  
The **APPLICATIONIDENTIFIER** should be set to **4** if your application is **Moodle** based  

If it is not set correctly you can modify it by executing the following scripts on your webserver machine and the database machine from the build machine:  
    
**cd ${BUILD_HOME}/helperscripts/**  

**./ExecuteOnWebserver.sh "/home/${SERVER_USERNAME}/providerscripts/utilities/StoreConfigValue.sh \"APPLICATIONIDENTIFIER\" \"(1|2|3|4)\""**  
    
**NOTE 2:**  
  
You can also make special "manual" backups which means you can take a non temporal backup at any time and it will be stored in a repository marked, "manual". 

 
