## THE EXPEDITED BUILD  
 
To perform an expedited build, you need to spin up a secured build machine on your cloudhosting provider. You can do this by using the script: [OverrideScript](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/templatedconfigurations/templateoverrides/OverrideScript.sh) and pasting it into the user data area of the VPS machine you are provisioning through your hosting provider's gui system. You need to set the variables:  

**BUILDMACHINE_USER**   
**BUILDMACHINE_PASSWORD**  
**BUILDMACHINE_SSH_PORT**  
**LAPTOP_IP**  
**SSH**  

before pasting it into the user data area of your VPS machine.  

Once the machine has provisioned, you can ssh onto it from your latop using the command:  

**ssh -p ${BUILD_MACHINE_SSH_PORT} ${BUILDMACHINE_USER}@<build-machine-ip>**  
  
<enter> ${BUILDMACHINE_PASSWORD}  

  You then nned to review the specification [specification] (https://github.com/wintersys-projects/adt-build-machine-scripts/blob/main/templatedconfigurations/specification.md)
   and set up a template of your choice (for the provider you are using). The templates are held at:

 **${BUILD_HOME}/templatedconfigurations/templates/***

 If the templates are not configured correctly there are redimentary checks to look for this when you start the build but ultimately if the templates is wrong, the build will likel;y fail or at least have problems down the road. To be proficient in the first instance you need to understand the templateing mechanism and its interplay. It requires a little bit of work but less work than some other solutions out there. 
  
**cd ${BUILD_HOME}/adt-build-machine-scripts**  
  
**${BUILD_HOME}/ExpeditedAgileDeploymentToolkit.sh**  
  
 on your build machine and then answer the questions.
  
The expedited build will build directly from the template you set up earlier and you will need to select the template by number in the directory when as the build process is intitating 
  
  **${BUILD_HOME}/templatedconfigurations/templates/${cloudhost}**  
  
If you keep your infratructure scripts private you could potentially have a fork of this toolkit with a library of templates stored in your git repository that you pull down when you clone the repository meaning you might be ready to rock as soon as you clone the repo. You must obviously take care not to expose any private credentials by making your repositories public if you follow an apporach like this.   

  ------------------
  
## THE HARDCORE BUILD  
  
  The hardcore method provides no command line interaction its a "light it and see" method once you start it running its fate is sealed. So, you have to set everything up preflight unlike the expedited method. Personally I prefer the expedited method but there might be some use cases where the hardcore method is a better fit for you. 
  
  1. On your laptop clone the build client scripts for example (or from your fork) and configure an appropriate template as you would for the expedited build
  
  2. **git clone https://github.com/wintersys-projects/adt-build-machine-scripts.git**  
  
  3. **cd adt-build-machine-scripts**  
  
  4. **/bin/sh ./helperscripts/GenerateOverrideTemplate.sh** and answer the questions as it asks them   
  
  5. **/bin/sh ./helperscripts/GenerateHardcoreUserDataScript.sh** and answer the questions as it asks them  
  
  6. **cd ${BUILD_HOME}/userdatascripts** and find the script that you have just generated  
  
  7. Review the script and update the variables at the top of the script:  
  
**BUILDMACHINE_USER**  
**BUILDMACHINE_PASSWORD**  
**BUILDMACHINE_SSH_PORT**  
**LAPTOP_IP**  
**SSH**  
**SELECTED_TEMPLATE**  
  
  8. Once you are happy that all the variables are correct copy it in its entirety and paste it into the user-data of a new VPS machine with your cloud provider.  
  
  9. **ssh** onto the build machine that you spun up in 8. and do as **"sudo su"** and give your **BUILDMACHINE_PASSWORD**  
  
  10. **cd adt-build-machine-scripts/logs**  
  
  11. **tail -f build*out** to get the build progress  
