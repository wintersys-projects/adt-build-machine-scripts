1. On your latop clone the main repository:  

git clone https://github.com/wintersys-projects/adt-build-machine-scripts.git

2. Setup the approrpiate template with live values for the build that you want:

   ${BUILD_HOME{/templstedconfigurations/templates/\<provider\>

3. cd ./adt-build-machine-scripts/helperscripts

4. run the script GenerateOverrideScript.sh

   /bin/sh ./GenerateOverrideScript.sh

 5. When you run the script answer the initial questions which would look like this if you were deploying a temporal build template for linode:

>      root@localhost:/home/agile-deployer/adt-build-machine-scripts/helperscripts# sh GenerateOverride.sh
>      ############################################################################################################
>      WARNING: THERE IS NO SANITY CHECKING IF YOU USE THIS SCRIPT WHICH MEANS THAT IF YOU ENTER ANYTHING INCORRECT
>      YOU WON'T FIND OUT ABOUT IT UNTIL YOU CONFIGURE A BUILD USING THE OUTPUT FROM THIS SCRIPT AND THE BUILD FAILS
>      AT THE END, THIS SCRIPT WILL OUTPUT ITS CONFIGURATION AND YOU CAN TAKE A COPY OF THE OUTPUT AND STORE IT ON YOUR LAPTOP OR DESKTOP
>      FOR USE IN CURRENT AND FUTURE DEPLOYMENTS
>      BE AWARE THAT THE OUTPUT GENERATED WILL CONTAIN SENSITIVE INFORMATION WHICH YOU NEED TO KEEP SECURE
>      ############################################################################################################
>      Press <enter> to continue
>
>      Which Cloudhost are you using? 1) Digital Ocean 2) Exoscale 3) Linode 4) Vultr. Please Enter the number for your cloudhost  
>      3
>      Please tell us which template you wish to override
>      1.                   VIRGIN DEVELOPMENT MODE INSTALLATION OF JOOMLA, WORDPRESS, DRUPAL or MOODLE
>      2.                   BASELINED DEVELOPMENT MODE DEPLOY OF A BASELINED JOOMLA WORDPRESS DRUPAL OR MOODLE APPLICATION
>      3.                   TEMPORAL PRODUCTION MODE DEPLOY OF A BACKED UP JOOMLA WORDPRESS DRUPAL OR MOODLE APPLICATION  
>      Please input a number between 1 and 3 to select a template to override
>      3
>      ###############################################################################
>       YOU NEED TO SET ALL OF THESE VARIABLES TO SANE VALUES FOR THE BUILD TO FUNCTION
>       ###############################################################################
>       Press <enter to begin>

When you are ready press <enter> to review the values that you have set for your build process
