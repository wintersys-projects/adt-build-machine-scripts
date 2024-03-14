Adding a new application is a fairly involved process, but it's not too difficult in most cases. There's a procedure that you need to follow and as long as the application itself isn't too quirky, it should work OK. Here are the steps:  

The BUILD MACHINE scripts need to be updated as follows to cater for a newly supported application:

1) In the BUILD CLIENT scripts, you need to update 

&#0036;BUILD_HOME/providerscripts/application/WhichApplicationByGitAndBackup.sh  
&#0036;BUILD_HOME/providerscripts/application/WhichApplicationByGitAndBaseline.sh  
&#0036;BUILD_HOME/providerscripts/application/WhichApplicationByDatastoreAndBaseline.sh  
&#0036;BUILD_HOME/providerscripts/application/WhichApplicationByDatastoreAndBackup.sh  

&#0036;BUILD_HOME/processingscripts/PreProcessingMessaages.sh  
&#0036;BUILD_HOME/processingscripts/PostProcessingMessaages.sh 

2) On the webserver you will need to add code according to the pattern of the default supported applications in the following places:

   &#0036;HOME/providerscripts/webserver/configuration/
     
   &#0036;HOME/providerscripts/application
   
   &#0036;HOME/security/GatewayGuardian.sh
   
3) on the database machine you need to modify the following for your application 

   &#0036;HOMEproviderscripts/application

4) on the autoscaler you need to provide:

   &#0036;HOMEautoscaler/SelectHeadFile.sh



