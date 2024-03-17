The heart of this toolkit is the templating system. You set the configurations you want in your templates and the build process will be dependant on the values that you set.  

What I want to do here is simply show you how you might go about configuring your template values for some different scenarious you might like to configure a deployment to support.  
Any valid configuration will undoubtably have some combination of these scenarios for the deployment to be successful, for example, its no use configuring this toolkit make a  
postgres database deployment if you are deploying wordpress because as far as I know wordpress doesn't support postgres and so such a configuration would result in a failed build.  
The onus is therefore on you as a deployer to know what configurations are appropriate for what you are trying to achieve. 
