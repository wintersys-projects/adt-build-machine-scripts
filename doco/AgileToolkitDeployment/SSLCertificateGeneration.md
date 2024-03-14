Here is the architectural overview of how SSL Certificates are automatically generated. It might seem a little unweildy, but I have considered the different options and can't come up with a better one.

**ON THE BUILD CLIENT**

For a new deployment, the first time a webserver is built, we generate an SSL certificate using Let's Encrypt. Once a certificate is generated, we save it on the filesystem of the build client.
The next time a deployment is made for a given url, we check the file system to see if  

**a) There is a certificate from a previous build that we can use (we check that it is not expired)**  
**b) That it is not out of date or expired. If it is, then we generate a new one and copy that to the filesystem**  

Either way, if we are generating a new one or using an older previously generated one, by the time we get to here, we have a certificate on our build client filesystem

We then remote copy our certificate onto our new webserver and also onto our autoscaler so that it can give it to new servers that are created as the result of an autoscaling event

Once the deployment is complete, the webservers monitor for expired certificates or certificates that are getting close to expiring. When a certificate gets near to its expiration date, it is renewed by the servers in an automated process. 

**ON THE WEBSERVERS**  

The following description describes how the servers monitor and renew expired certificates

**1) Once a day, the webservers check for expired certificates. All the servers use the same certificate all the time, so, if it is expired on one, it is expired on them all**

So, during the small hours of the night, a cron job is run called InstallSSLCertificateFromCron.sh. This is run at the same time on all the webservers, which should be the lowest number during the daily scaling cycle as it is the quietest time. The cron scipt implements locking so that once one webserver has the lock for this run, the other servers are locked out and exit. So, you could say that 1 of n servers is delegated (by obtaining the shared lock) as the server that is going to manage the SSL cert for this run. 

**2) Once a webserver has the lock, then it performs the following steps**

It calls a security script **${HOME}/security/InstallSSLCertificate.sh**

This script will look for the currently installed certificate and work out if it is about to expire. If it isn't then the script exits and that's it. If the certificate isn't going to expire on one of the webservers, then it won't be going to expire on any of them so there is nothing more to do.

If the script detemines that the certificate has short life left on it, then, it calls 

**${HOME}/security/ObtainSSLCertificate.sh**  

The **ObtainSSLCertificate.sh** script will then actually go and generate a new certificate with long life validity.                                                                                                      
Once the new certificate is generated, it is stored in **${HOME}/.lego/certificates**  

So, this newly generated certificate is replicated to three places:  

**1) /home/${SERVER_USER}/ssl/letsencrypt/live/\\${WEBSITE_URL}/cert.pem**  
**2) s3://${config_bucket}/ssl/cert.pem**  
**3) ${HOME}/.ssh/cert.pem**  
  
The one that the webservers use is **/home/${SERVER_USER}/ssl/letsencrypt/live/\\${WEBSITE_URL}/cert.pem**  

The config bucket copy is used for replication. Each of the webservers (the ones that didn't obtain the lock previously) monitor the  

**s3://${config_bucket}/ssl/** directory

for newly generated certificates and replicate a new one to their file systems. The script which monitors the config directory for newly generated certificates is: 

**${HOME}/security/MonitorForNewSSLCertificate.sh**  

If any of the webservers find a newly generated certificate it is assumed that this is the certificate that should be used and it is replicated to 

**/home/${SERVER_USER}/ssl/letsencrypt/live/\\${WEBSITE_URL}/cert.pem** on that machine.  

The **${HOME}/.ssh** directory is used to keep a history of issued certificates. When a new certificate is issued, the preceeding one is annoted with 'previous' and the date giving a trail of previously issued certificates.  

NB. the autoscaler also continually monitors the **s3://${config_bucket}/ssl** directory for new certificates and grabs a copy for itself of any new ones. It then uses the new certificate to give to any newly spawned webservers as a result of an autoscaling event.  

NB2. If a certificate is ever failed to be issued, an email is sent out to the admin and also, letsencrypt themselves send out reminder emails if a certificate is getting long in the tooth according to their records and hasn't been renewed.  
