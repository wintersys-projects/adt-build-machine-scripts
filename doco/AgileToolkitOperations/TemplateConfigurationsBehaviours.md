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

To deploy a virgin Joomla application you need to set the following values in template 1:

export APPLICATION="joomla"<br>
export APPLICATION_IDENTIFIER="1"<br>
export JOOMLA_VERSION="5.0.3"<br>
export APPLICATION_BASELINE_SOURCECODE_REPOSITORY="JOOMLA:5.0.3"<br>
export BASELINE_DB_REPOSITORY="VIRGIN"<br>
export BUILD_ARCHIVE_CHOICE="virgin"<br>
export BUILD_CHOICE="0"<br>

#### Objective 2

To deploy a virgin Wordpress application you need to set the following values in template 1:

export APPLICATION="wordpress"<br>
export APPLICATION_IDENTIFIER="2"<br>
export APPLICATION_BASELINE_SOURCECODE_REPOSITORY="WORDPRESS"<br>
export BASELINE_DB_REPOSITORY="VIRGIN"<br>
export BUILD_ARCHIVE_CHOICE="virgin"<br>
export BUILD_CHOICE="0"<br>


#### Objective 3

To deploy a virgin Drupal application you need to set the following values in template 1:

export APPLICATION="drupal" <br>
export APPLICATION_IDENTIFIER="3"<br>
export APPLICATION_BASELINE_SOURCECODE_REPOSITORY="DRUPAL:10.2.4"<br>
export BASELINE_DB_REPOSITORY="VIRGIN"<br>
export BUILD_ARCHIVE_CHOICE="virgin"<br>
export BUILD_CHOICE="0"<br>

#### Objective 4

To deploy a virgin Moodle application you need to set the following values in template 1:

export APPLICATION="moodle"<br>
export APPLICATION_IDENTIFIER="4"<br>
export APPLICATION_BASELINE_SOURCECODE_REPOSITORY="MOODLE"<br>
export BASELINE_DB_REPOSITORY="VIRGIN"<br>
export BUILD_ARCHIVE_CHOICE="virgin"<br>
export BUILD_CHOICE="0"<br>

#### Objective 5

To deploy a virgin Opensocial application you need to set the following values in template 1:

export APPLICATION="drupal"<br>
export APPLICATION_IDENTIFIER="3"<br>
export APPLICATION_BASELINE_SOURCECODE_REPOSITORY="DRUPAL:social"<br>
export BASELINE_DB_REPOSITORY="VIRGIN"<br>
export BUILD_ARCHIVE_CHOICE="virgin"<br>
export BUILD_CHOICE="0"<br>

--------------------------------------------------------------

#### Objective 6

To deploy a baselined application in template 2, you modify as in the following example for a joomla application

export APPLICATION="joomla"<br>
export APPLICATION_IDENTIFIER="1"<br>
export APPLICATION_BASELINE_SOURCECODE_REPOSITORY="examplewebsite-webroot-sourcecode-baseline"<br>
export BASELINE_DB_REPOSITORY="examplewebsite-db-baseline"<br>
export BUILD_ARCHIVE_CHOICE="baseline"<br>
export BUILD_CHOICE="1"<br>

#### Objective 7

To deploy a temporal application with hourly peridicity in template 3, you modify as in the following example for a joomla application

export APPLICATION="joomla"<br>
export APPLICATION_IDENTIFIER="1"<br>
export BUILD_ARCHIVE_CHOICE="hourly"<br>
export BUILD_CHOICE="2"<br>

----------------------------------------------------------------------

#### Objective 8

To deploy PHP version 8.1 you set the following values in the appropriate template

export APPLICATION_LANGUAGE="PHP"<br>
export PHP_VERSION="8.1"<br>

#### Objective 9

To deploy PHP version 8.3 you set the following values in the appropriate template

export APPLICATION_LANGUAGE="PHP"<br>
export PHP_VERSION="8.3"<br>

-----------------------------------------------------------------

#### Objective 10

To enable the datastore you can set the following values appropriately in any of the templates - you can refer to the specification [here](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/main/templatedconfigurations/specification.md) to see what the HOST_BASE value should be for your datastore and you need to generate the access_key and secret_key for yourself

export S3_ACCESS_KEY="xxxxx"<br>
export S3_SECRET_KEY="yyyyy"<br>
export S3_HOST_BASE="ams3.digitaloceanspaces.com"<br>
export S3_LOCATION="US"<br>
export DATASTORE_CHOICE="digitalocean"<br>

--------------------------------------------------------------

#### Objective 11

To mount an application's asseta directory set the following values appropriately in template 3. In this example I use joomla where the assets directory is the images subdirectory

export DIRECTORIES_TO_MOUNT="images"<br>
export PERSIST_ASSETS_TO_CLOUD="1"<br>

--------------------------------------------------------------

#### Objective 12

To deploy to Debian 12 machines, set these values in any of your templates

export BUILDOS="debian"<br>
export BUILDOS_VERSION="12"<br>

#### Objective 13

To deploy to Ubuntu 24.04 machines, set these values in any of your templates

export BUILDOS="ubuntu"<br>
export BUILDOS_VERSION="22.04"<br>

--------------------------------------------------------------

#### Objective 14

To set your DNS provider, set the following values in your templates

export DNS_USERNAME="dns_provider_email/Username"<br>
export DNS_SECURITY_KEY="xxxx"<br>
export DNS_CHOICE="cloudflare"<br>

-----------------------------------------------------------------

#### Objective 15

To set your website characteristics set the following values in any template:

export WEBSITE_DISPLAY_NAME="My Example Website"<br>
export WEBSITE_NAME="testwebsite"<br>
export WEBSITE_URL="www.testwebsite.uk"<br>



























