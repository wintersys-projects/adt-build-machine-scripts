The heart of this toolkit is the templating system. You set the configurations you want in your templates and the build process will be dependant on the values that you set.  

What I want to do here is simply show you how you might go about configuring your template values for some different scenarious you might like to configure a deployment to support.   

Any valid configuration will undoubtably have some combination of these scenarios for the deployment to be successful, for example, its no use configuring this toolkit make a  
Postgres database deployment if you are deploying Wordpress because as far as I know Wordpress doesn't support postgres out of the box and so such a configuration would result in a failed build with the way that I do things. Its not impossible for wordpress using postrgres to be supported here, but, I chose not to because Postgres is not commonly used or supported by plugin developers?  

If you look  

[here](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/main/processingscripts/PreProcessingMessages.sh)  

then about line 170 you will see that this suggested scenario of misconfiguration is checked for but its not clear that all such misconfigurations can be checked for and  therefore, the onus is on you, as a deployer to know what configurations are appropriate for what you are trying to achieve.  

If you are deploying a virgin application you should make modifications to template 1 for your current cloudhoat provier. If you are deploying a baselined application you should modify template 2 for your current cloudhost provider and if you are deploying from a temporal backup you should modify template 2 for the appropriate cloudhost

---------------------------------

#### Objective 1

To deploy a virgin Joomla application you need to set the following values in your template:

export APPLICATION="joomla" #MANDATORY
export APPLICATION_IDENTIFIER="1" #MANDATORY
export JOOMLA_VERSION="5.0.3" #MANDATORY (depending on the above settings - a joomla deployment)
export APPLICATION_BASELINE_SOURCECODE_REPOSITORY="JOOMLA:5.0.3" #MANDATORY
export BASELINE_DB_REPOSITORY="VIRGIN"
export BUILD_ARCHIVE_CHOICE="virgin"
export BUILD_CHOICE="0"

#### Objective 2

To deploy a virgin Wordpress application you need to set the following values in your template:

export APPLICATION="wordpress" #MANDATORY
export APPLICATION_IDENTIFIER="2" #MANDATORY
export APPLICATION_BASELINE_SOURCECODE_REPOSITORY="WORDPRESS" #MANDATORY
export BASELINE_DB_REPOSITORY="VIRGIN"
export BUILD_ARCHIVE_CHOICE="virgin"
export BUILD_CHOICE="0"


#### Objective 3

To deploy a virgin Drupal application you need to set the following values in your template:

export APPLICATION="drupal" #MANDATORY
export APPLICATION_IDENTIFIER="3" #MANDATORY
export APPLICATION_BASELINE_SOURCECODE_REPOSITORY="DRUPAL:10.2.4" #MANDATORY
export BASELINE_DB_REPOSITORY="VIRGIN"
export BUILD_ARCHIVE_CHOICE="virgin"
export BUILD_CHOICE="0"

#### Objective 4

To deploy a virgin Moodle application you need to set the following values in your template:

export APPLICATION="moodle" #MANDATORY
export APPLICATION_IDENTIFIER="4" #MANDATORY
export APPLICATION_BASELINE_SOURCECODE_REPOSITORY="MOODLE" #MANDATORY
export BASELINE_DB_REPOSITORY="VIRGIN"
export BUILD_ARCHIVE_CHOICE="virgin"
export BUILD_CHOICE="0"

#### Objective 5

To deploy a virgin Opensocial application you need to set the following values in your template:

export APPLICATION="drupal" #MANDATORY
export APPLICATION_IDENTIFIER="3" #MANDATORY
export APPLICATION_BASELINE_SOURCECODE_REPOSITORY="DRUPAL:social" #MANDATORY
export BASELINE_DB_REPOSITORY="VIRGIN"
export BUILD_ARCHIVE_CHOICE="virgin"
export BUILD_CHOICE="0"

--------------------------------------------------------------


