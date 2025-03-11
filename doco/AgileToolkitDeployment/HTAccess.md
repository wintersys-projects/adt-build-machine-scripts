If you want to modify the htaccess file for you application for some reason you can edit these files in the webserver files of your fork:  

>     ${BUILD_HOME}/providerscripts/application/configuration/joomla-htaccess.txt  
>     ${BUILD_HOME}/providerscripts/application/configuration/moodle-htaccess.txt  
>     ${BUILD_HOME}/providerscripts/application/configuration/wordpress-htaccess.txt
>     ${BUILD_HOME}/providerscripts/application/configuration/drupal-htaccess.txt

When you deploy Apache for your application types the htaccess file that you have defined here will be copied to /var/www/html/.htaccess and access permissions set accordingly. If you want to add dynamic data only available in real time you can modify the configuration scripts for your webserver to include the dynamic data. 

