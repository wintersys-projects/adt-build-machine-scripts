Some ideas for how this work could be enhanced/extended

1. I am not an expert in configuring apache,nginx, and in particular lighttpd. If you are an expert in any of these technologies I would be happy for you to review what I have done to configure these softwares by default which work but it might be possible to have them work better in the hands of an expert.
The relevant files are: [Apache](https://github.com/wintersys-projects/adt-webserver-scripts/blob/master/providerscripts/webserver/configuration/InstallApache.sh) [Nginx](https://github.com/wintersys-projects/adt-webserver-scripts/blob/master/providerscripts/webserver/configuration/InstallNginx.sh) [Lighttpd](https://github.com/wintersys-projects/adt-webserver-scripts/blob/master/providerscripts/webserver/configuration/InstallLighttpd.sh)

3. The toolkit can be forked and extended to support additional PHP applications such as Nextcloud or hubzilla or other PHP frameworks. There's many many PHP applications out there which would be cool to support and possibly quite fun to integrate into the tookit.
4. The toolkit can be forked and extended to suport other hosting providers such as upcloud or google cloud
5. It would be nice to fork and extend the toolkit to support openlitespeed as a webserver
6. This toolkit is not tied to only supporting PHP. As it stands the base language is PHP but by changing the APPLICATION_LANGUAGE which is installed to be. for example, Java or NodeJS then the toolkit could be expanded beyond PHP to support, for example, tomcat or strapi CMS or ruby on rails
7. General additional provider support such as integrating new SMTP mail service providers or a currently unsupported DNS system like route53. 
8. Add support for dynamic scaling in addition to the static scaling which is provided by default. This is only possible if a provider supports dynamic scaling (for example, AWS).  
9. The core toolkit supports 3 server types, the Autoscaler class of machine, the webserver class of machine and the database class of machine. The toolkit is structured such that it is easy to integrate other types of machines or servers if you wanted to, for example you could develop an email server if you wanted to roll your own email server solution and put that into the deployment chain if you chose to or you could have an application server and so on. The toolkit is designed not to be limited to just 3 classes of machines and you are free to extend it in such a way if you chose to.
10. Provide an option to install ftp onto webserver type machines. This will allow 3rd party support providers to be granted ftp access to your machine to troubleshoot. 
11. Provide an option to install phpmyadmin for managing the database and database tables.  


