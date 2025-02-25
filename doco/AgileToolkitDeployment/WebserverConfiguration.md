The technique I uses is to have "base" configurations for the webserver I am deploying. What this means is that I could have a "library" of configurations stored in my forked webserver repository for different application types that I might want to deploy. I could have configurations that are optimised for high traffic, I could have configurations that are optimised for maximum security and I could have configurations that have additional featues such as if I want to install some sort of monitoring  tool during testing and so on. So, each of these configurations are stored in the directory structure made distinct by application type and webserver type. The structure of the directory system is as follows:


>     ${HOME}/providerscripts/webserver/configuration/joomla/apache/online/source
>     ${HOME}/providerscripts/webserver/configuration/joomla/apache/online/repo
>     ${HOME}/providerscripts/webserver/configuration/joomla/nginx/online/source
>     ${HOME}/providerscripts/webserver/configuration/joomla/nginx/online/repo
>     ${HOME}/providerscripts/webserver/configuration/joomla/lighttpd/online/source
>     ${HOME}/providerscripts/webserver/configuration/joomla/lighttpd/online/repo
>
>     ${HOME}/providerscripts/webserver/configuration/wordpress/apache/online/source
>     ${HOME}/providerscripts/webserver/configuration/wordpress/apache/online/repo
>     ${HOME}/providerscripts/webserver/configuration/wordpress/nginx/online/source
>     ${HOME}/providerscripts/webserver/configuration/wordpress/nginx/online/repo
>     ${HOME}/providerscripts/webserver/configuration/wordpress/lighttpd/online/source
>     ${HOME}/providerscripts/webserver/configuration/wordpress/lighttpd/online/repo


And so on for other application types (currently drupal and moodle) but you will have to make enhancements here if you want to integrate additional applicationt types into your fork. And so by modifying the files in these locations I can control the configuration of my websevers on an application and webserver type basis.

Like there are online directories where I can control my "live" configurations, there are offline directories where I can store my library of alternative configurations. All I have to do to switch from one configuration to another is move the current "online" files to "offline" and move the "offline" files to "online" and then I can deploy with a completely different webserver configuration according to my needs. 

An example offline directory is:

>     ${HOME}/providerscripts/webserver/configuration/joomla/apache/offline

If you have some additional requirement to make the configuration you want pop, you  can modify the files:

>     ${HOME}/providerscripts/webserver/configuration/*
