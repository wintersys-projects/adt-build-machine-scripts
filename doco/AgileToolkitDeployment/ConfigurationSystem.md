To understand how the configuration system works you can review the scripts for webserver, autoscaler or database machine types.
I needed some way to share configuration settings between machine types. The way I wanted to do this was to use the S3 Object Storage service from the current provider and I decided to code up wrappers for the s3cmd tool and explicitly write and retrieve the configuration settings that the servers were using from a shared S3 bucket or configuration datastore. In this way, machines can share their ip addresses and other configuration settings with each other in a defined way and from that firewall access and other necessities can be taken care of once a machine publishes its ip address to the configration system.

**${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh**  
**${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh**  
**${HOME}/providerscripts/datastore/configwrapper/GetDBCredential.sh**  
**${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh**  
**${HOME}/providerscripts/datastore/configwrapper/GetFromConfigDatastore.sh**  
**${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh**  
**${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh**  

The configration bucket as a whole is cleaned out for each new build and so has to be reconstructed for the current build set up. Using this technique, is a useful way for sharing configuration setting without having to rely on the method of using tools such as "s3fs" to mount bucket and so on and create filesystems etc.

In most cases you aren't going to want to touch anything in the S3 configuration bucket directly, an exception to this is the scaling mechanism. 
You will find a script 

**${BUILD_HOME}/helperscripts/AdjustScaling.sh**  

on the build client machine which you can run to adjust the number of webservers being provisioned.

And on the autoscaler, there is a script:

**${HOME}/providerscripts/utilities/ManuallyScale.sh <no_webservers>**  
