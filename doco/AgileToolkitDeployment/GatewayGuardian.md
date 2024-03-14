### THE GUARDIAN GATEWAY

The guardian gateway part of the toolkit enables you to configure your deployment so that sensitive directories of your application are protected using the "basic auth" mechanism built into your browser.

What this means is that to access protected directories a user will need a username and a password before they can even get to the CMS application itself. 

The way I have set this up is I use the same username for the gateway guardian as the user has for the CMS application they are trying to access. So, for example, if your username is, "Ethel123" for, say, Joomla, Wordpress, Drupal or Moodle that you are trying to access, then, your username for "basic auth" will be "Ethel123" also. The way the system works is it is set up to generate a random password for you when you first register with the site you are trying to access and it sends you your password by email. It doesn't have to be massively secure, it is only the first line of defence and it should cause at least some problems for bad actors.

----------------------

#### IMPORTANT NOTE FOR DEVELOPERS:

I generate the gateway guardian credentials from the application database and the problem with this is that some applications have empty user tables by default. To get round this, I create a "bootstrap_user" which you can use to get past the "gateway guardian" when you are installing the CMS. To find out the username and password of the cases where its needed during a fresh installation, you can ssh onto your build machine and issue the following command

##### /usr/bin/s3cmd get s3://gatewayguardian-${BUILD_IDENTIFIER}/htpasswd_plaintext_history

this will create a file **./htpasswd_plaintext_history** which you can look for the  bootstrap_user in. The format will be something like:

**LIVE:   bootstrap_user:ek+60uLrksm2Aw==:bootstrap@dummyemail.com**

In this case, the username you want to put into the guardian gateway dialogue is: **bootstrap_user** and the password is: **ek+60uLrksm2Aw==**

---------------------------------

Ordinarily, then, when you are prompted with a "basic auth" dialog as a regular user, you would use your application username and the password which has been sent to you by email. Getting past basic auth would grant you access to the CMS system.

As the technical person using this toolkit you will find a commented out option in the crontab of your database server with a @weekly periodicity to run the GatewayGuardian.sh shell script. 

You can uncoment this and vary the periodicity if you want to and what this will do is generate new passwords for the basic auth mechanism (and email them to the email your users have registered to the CMS with) and the next time they come to your site they will need to check their email and enter their new username and password to get passed the basic auth mechanism. This requires that the users understand that they need to do this. You don't have to have this switched on you can set the user's password when they first registered and make it everlasting but if you want to be as secure as possible about it setting new passwords periodically is the advisory from security specialists. As you know increased security is stalked by decreased usability in almost all cases. 

-------------------------------

You can find the "live" passwords for the users of the Gateway Guardian mechanism in two places:

1. On your database server you can find your live passwords in the following file:

##### ${HOME}/runtime/credentials/htpasswd_plaintext_history

2. In your datastore in a bucket called:

#####  s3://gatewayguardian-${BUILD_IDENTIFIER}

----------------------------------

By default, when you enable "Gateway Guardian", it protects the administation directories so, for joomla that would be, "/administrator" and for wordpress that would be "/wp-admin" and so anyone wanting to access those directories will need to pass basic auth.

The whole point of this, thought is to set up basic auth so that users can't access your application at all without getting past basic auth by configuring it to use the protect the webroot directory "/var/www/html".

You can do this by altering the directories that the basic auth is active for in these files in your fork of the build kit:

-----------
### For APACHE:  

##### ${HOME}/providerscripts/webserver/configuration/CustomiseApacheByApplication.sh

and for **Joomla**, alter:

**/bin/echo "    <Directory /var/www/html/administrator>**

to 

**/bin/echo "    <Directory /var/www/html/>**

and for **Wordpress**, alter:

**/bin/echo "    <Directory /var/www/html/wp-admin>**

to 

**/bin/echo "    <Directory /var/www/html/>**

and for **Moodle**, alter:

**/bin/echo "    <Directory /var/www/html/moodle/admin>**

to 

**/bin/echo "    <Directory /var/www/html/moodle/>**

and for **Drupal**, alter:

**/bin/echo "    <Directory /var/www/html/>**

to 

**/bin/echo "    <Directory /var/www/html>**

NOTE: Because of the way drupal works I couldn't get this mechanism to work satisfactorily with drupal admin. The only solution is to gateway the whole of drupal but it means your users won't be able to register if you switch it on and you will need to implement a solution like I have described below.

----------------
### For NGINX:  

##### ${HOME}/providerscripts/webserver/configuration/CustomiseNginxByApplication.sh

and follow a similar process as described above for apache

-----------------

### For LIGHTTPD:

##### ${HOME}/providerscripts/webserver/configuration/CustomiseLighttpdByApplication.sh

and follow a similar process as described above for apache

----------------


##### NOTE: If you protect your top level webroot directory using basic auth, then, clearly your users won't be able to register at your site. So, there's a couple of ways to deal with this. 

1. If your social network is for a local community, have people in your local community, for example, you might want to vet that they live in a particular postcode area, for example, apply to you offline and then have an adminstrator create accounts for them who alread has access through the basic auth system.  

2. Create a [proxy registration site](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/doco/AgileToolkitDeployment/RegistrationServer.md) which is completely separate from your main deployment here. Have the proxy registration site collect minimal details (username and email) and then have your proxy site export new registrations it has received to your main deployment here and then have a script create the users based on application type in your database and implement a process to send out the basic auth password to the user. This way your proxy site is a completely separate system and you are free, if you want to process the users applying to join your community and accept or reject them. Using a process like this, you can fully protect your webroot using basic auth automatically and thats a useful layer of protect to have. There is the added overhead that users have to juggle a couple of passwords and if they change browser, for example, they will need to know their basic auth password and also if you implement password changing on a periodic basis for your basic auth mechanism, then, they will be abruptly prompted for a new password every month, two months and so on, and they will need to know that their new password will have been email to them by the system  
