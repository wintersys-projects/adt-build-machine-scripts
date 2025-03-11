For Linode it's possible to use "StackScripts" to make your deployment. What you will have to do is generate the StackScript which will only be useful on Linode and you can do this as follows. Using Stackscripts can be easier to deploy from because you can configure the parameters using a GUI system and then just have a "Hardcore" style build proceed. 

1. Perform a test expedited build using the parameters you require for your deployment. This will mean that you have a pre-populated template which deploys succcessfully which can be used that basis for generating the userdata or stack script.  

2. On the same machine that you performed (and tested) the expedited build run the script:  

>     ${BUILD_HOME}/helperscripts/GenerateOverrideScript.sh  
    
You should select the provider and template number (1, 2 or 3) that you wish to generate from  
    
Once the script has completed successsfully it will be available in  
    
>     ${BUILD_HOME}/overridescripts  
    
3. To generate the Stackscript, run
    
>     ${BUILD_HOME}/helperscripts/GenerateHardcoreUserDataScript.sh stack  
    
This will write the User Data / Stack Script to   
    
>     ${BUILD_HOME}/userdatascripts/<name you gave>  
    
 4. The script ${BUILD_HOME}/userdatascripts/<name you gave> can then be used as a Stackscript on Linode. My Stackscript for the ADT has ID 635271 you are welcome to use that. It is called "AgileDeploymentToolkitDemos" it is publically available and I use it for my "Quick Demo" example deployments. 
