**NOTE: THE SMTP CREDENTIALS THAT YOU SET AT BUILD TIME FOR YOUR APPLICATION ARE AVAILABLE AS FOLLOWS POST DEPLOYMENT:**  

**For wordpress: /var/www/wordpresssmtp**  
**For moodle: /var/www/moodlesmtp**  
**For Drupal: /var/www/drupalsmtp**  
**For Joomla: /var/www/html/configuration.php**  

The SMTP service is used to send emails from the deployed applications and also system messages from the deployment infrastructure itself. 
At the time of writing, I have added 3 SMTP services for a deployer to choose from when making a build. One is www.sendpulse.com and the other mailjet (mailjet.com) and the 3rd one is Amazon SES

To send SMTP mail, the first thing you will need to do is set yourself up an account with your provider of choice. With sendpulse, you have to use an existing email address that you already own. Similarly you will have to sign up for mailjet to use it as your relay. 

Note: If you have deployed a domain specific email server which you can do using iRedmail, so, if your domain is "darren's social network", www.darrensnet.com with emails from mail.darrensnet.com. then with Send Pulse and possibly other providers, if you register with them using your domain specific emails then the source email address will be set to your own domain name. If you use darren@yahoo.com. then that is the address your emails will be sent from telling little about the originator.

-------------------------
For an expedited build or a hardcore build, you will need to set the following environment variables to enable the SMTP service which will send you system notification messages. I Joomla install will automatically pick up the credentials you set here and SMTP will be avaiable within Joomla. For other CMSs you will have to install SMTP plugins or extensions and configure the parameters manually. In all cases, system email will be sent according to these parameters.  

**export SYSTEM_EMAIL_PROVIDER=""  
export SYSTEM_TOEMAIL_ADDRESS=""  
export SYSTEM_FROMEMAIL_ADDRESS=""  
export SYSTEM_EMAIL_USERNAME=""  
export SYSTEM_EMAIL_PASSWORD=""** 

So, assuming we have an address notifications@darrensnet.com, then we can see how we need to configure the settings for our two SMTP service providers.

The specification describes in more detail how to set these parameters. 
