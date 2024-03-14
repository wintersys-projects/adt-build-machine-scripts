If you look at a ready built application for drupal such as [Open Social](https://www.getopensocial.com/) it would be nice to be able to install such applications in a plug and play way. 
To install open social, then, what I do is make an expedited build with these particular values in a virgin install template for my chosen provider.

export APPLICATION="drupal" #MANDATORY  
export DRUPAL_VERSION="10.0.0"  #MANDATORY  
export APPLICATION_IDENTIFIER="3" #MANDATORY - 1 for joomla, 2 for wordpress, 3 for drupal, 4 for moodle  
export BASELINE_DB_REPOSITORY="VIRGIN"  
export APPLICATION_BASELINE_SOURCECODE_REPOSITORY="DRUPAL:social"   

The main thing to notice is that APPLICATION_BASELINE_SOURCECODE_REPOSITORY is set to "DRUPAL:social" instead of "DRUPAL:10.0.0"  
This tells the ADT to install opensocial rather than version 10.0.0 of vanilla drupal.  

You can see the changes that I made to [Open Social Install](https://github.com/wintersys-projects/adt-webserver-scripts/blob/master/providerscripts/application/configuration/drupal/InstallVirginDeployment.sh) to make this possible and for Open Social to be installed.  
You can do similarly for other drupal applications that are built by 3rd parties by modifying this script in a similar way to support the application that you want to install and then following the install process as you would for a vanilla drupal install. 

