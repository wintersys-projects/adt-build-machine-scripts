##### IMPORTANT: This system does not allow updates to configuration files (such as wp-config.php or configuration.php) through the application's GUI system.

Instead use the following process which will automatically update all of your webserver configurations in one go:

If you want to update your, for example, Joomla "configuration.php" file or your Wordpress "wp-config.php" files, then there's a few ways to go about it.
Presuming that you have several webservers running if you change the configuration file on one of them using this method it will get pushed out to all the others. This is powerful but also requires caution because a change made to a configuration file with errors in it could take your whole website offline.

The shortcut way to update your application's configuration is as the following 3 step process:

1. Login to one of your webservers using the helperscript on your build machine
2. Go to ${HOME}/runtime and make your updates to the appropriate configuration file, one of, joomla_configuration.php, wordpress_config.php, drupal_settings.php, moodle_config.php
3. Once your updates are made to your configuration file run the script /usr/bin/config to push it to your S3 datastore. Syntax checking has to be passed before the changes you make are accepted by the system. 

WARNING RUNNING THIS SCRIPT (/usr/bin/config) WILL PUSH YOUR CHANGES TO ALL YOUR WEBSERVERS  

Configuration changes you make using the application's GUI system to an individual webserver will be overwritten by default. The reason for this is that when you have say 8 webservers running if you use the GUI system to make your configuration updates it will only update one of the webservers and the rest will remain as they were because this system doesn't use shared filesystems for the webserver webroot. You can't tell which webserver you have updated and which webserver you haven't. I chose to make needed update changes to the 

>     ${HOME}/runtime/<config-file>

and have that file as the authoritative file instead and push the changes out to other webservers from there there in a conscious and deliberate way.

If you make a change to 

>     ${HOME}/runtime/<config-file>

and then run /usr/bin/config, here are the steps that the system goes through to push the changes you have made to all webservers.

1. The script

>     ${HOME}/providerscripts/application/configuration/ApplicationConfigurationUpdate.sh

will be run and this will run a syntax check anc copy the configuration file to the S3 datastore.

2. Every minute, each webserver looks for an updated configuration file for the installed application type when the script:

>     ${HOME}/providerscripts/application/configuration/SetApplicationConfiguration.sh

is run. When this script is run and a new configuration file is discovered in the S3 datastore, the new configuration file is copied by the current webserver and each other webserver in turn to their

>     ${HOME}/runtime

directory where a second syntax check is made using PHP validation. If the syntax check is passed, then the new configuration file that the current webserver has retrived from the datastore is presumed to be valid and is copied to the current applications configuration file location under the directory

>     /var/www/html/


If all has gone well,then the applications configuration will have been updated





