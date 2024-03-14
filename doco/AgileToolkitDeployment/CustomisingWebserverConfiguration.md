I am in no way an expert at configuring NGINX, APACHE or LIGHTTPD for optimum usage and so I would be grateful for any help with more considered configuration suggestions that what I have provided by default which is likely functional but not ideal.

In order to adjust the configurations settings for the webserver you are deploying, in your fork of the webserver repository, you can edit the appropriate file(s) in the 

##### ${HOME}/providerscripts/webserver/configuration/* 

Directory. 

If you edit the files to be your ideal configuration and updated them in github, the next time you deploy the build kit your webserver will be configured using the changes you have made. This is an efficient way of being able to set up different configurations easily.
If you have different applications which need different webserver configurations, then, obviously, you can have a fork for each of the different configurations and so use the same deployment methods to deploy differently configured servers. 
If you really wanted to you could add a flag which you set during the deployment which selects from several different webserver configurations which you have set for example, if you had an apache configuration for your social networking application and a different one for your ecommerce site, you could modify the code such that you can select one or the other as a switch, for example, WEBSERVER_CONFIG:1 or WEBSERVER_CONFIG:2 and in that way have a very fine grained control over your webserver configuration. Most likely though you will just want to have seperate forks for each configuration. 

 
