The heart of this toolkit is the templating system. You set the configurations you want in your templates and the build process will be dependant on the values that you set.  

What I want to do here is simply show you how you might go about configuring your template values for some different scenarious you might like to configure a deployment to support.   

Any valid configuration will undoubtably have some combination of these scenarios for the deployment to be successful, for example, its no use configuring this toolkit make a  
Postgres database deployment if you are deploying Wordpress because as far as I know Wordpress doesn't support postgres out of the box and so such a configuration would result in a failed build with the way that I do things. Its not impossible for wordpress using postrgres to be supported here, but, I chose not to because Postgres is not commonly used or supported by plugin developers?  

If you look  

[here](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/main/processingscripts/PreProcessingMessages.sh)  

then about line 170 you will see that this suggested scenario of misconfiguration is checked for but its not clear that all such misconfigurations can be checked for and  therefore, the onus is on you, as a deployer to know what configurations are appropriate for what you are trying to achieve.  

---------------------------------
