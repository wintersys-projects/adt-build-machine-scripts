### SSH

This variable should be set to your public key for your laptop. This will enable you to access the build machine from a private key that you have generated and stored on your laptop

-----

### BUILDOS

This is the BUILDOS you wish to use for your servers, it can be one of "ubutnu" or "debian"

-----

### BUILDOS_VERSION

This is the BUILDOS_VERSION you are deploying for this can be    
"24.04"  
and later LTS releases if BUILDOS is "ubuntu". 
 
"12"  
and later releases if BUILDOS is "debian"

-----


### BUILD_IDENTIFIER

This is a unique string to describe your build. If you have multiple builds that you want to give similar names you should call them, for example, "1-testbuild" or "2-testbuild" or "3-testbuild"

-----

### APPLICATION

This can be set to one of "none", "joomla", "wordpress", "drupal", "moodle"

---- 

### JOOMLA_VERSION

If you are deploying a virgin joomla installation, you must give the version number of joomla that you are deploying here. In such a template, you will likely want to update this version number to be the latest available.

---- 

### DRUPAL_VERSION

If you are deploying a virgin drupal installation, you must give the version number of drupal that you are deploying here. In such a template, you will likely want to update this version number to be the latest available.

---- 

### APPLICATION_BASELINE_SOURCECODE_REPOSITORY

If you are deploying a virgin application, you can set APPLICATION_BASELINE_SOURCECODE_REPOSITORY to   

- "JOOMLA:{latest_version}"  for example "JOOMLA:5.3.0"  

- "WORDPRESS"   

- "DRUPAL:{latest_version}" for example "DRUPAL:11.0.1"
  
**NOTE: if you want to install [opensocial](https://www.getopensocial.com/)  or [drupal cms](https://new.drupal.org/drupal-cms) you can set latest_version to "DRUPAL:social" and "DRUPAL:cms" and the system will install opensocial or drupal CMS respectively.**  

- "MOODLE"  

-----

### S3_ACCESS_KEY 
### S3_SECRET_KEY

These grant you access to manipulate an object store. Under the principle of least privileges, you should grant as few privileges to these keys when you create them as possible. The DATASTORE_CHOICE setting (see below) will determine which Object Storage you are using and you will need to generate access keys appropriate to that setting. 

You can get your S3_ACCESS_KEY and S3_SECRET KEY as follows:

**digital ocean** - Login to your digital ocean account and go to the API submenu (on the left bottom) and generate "Digital Ocean Spaces Keys". This will give you an access key which you can paste into your template. The first key is the S3_ACCESS_KEY and the second key is the S3_SECRET_KEY

**exoscale** - Login to your exoscale account and go to the IAM menu (on the right) and generate a pair of API keys which have access to object storage capabilities. The first key is the S3_ACCESS_KEY and the second key is the S3_SECRET_KEY which you can post into your template.

**linode** - Login to your Linode account and go to the Object Storage menu on the right then select the Access Key menu and select "Create an Access Key" and that will generate an access key and a secret key which you can copy into your template as S3_ACCESS_KEY and S3_SECRET_KEY.

**vultr** - You need to subscribe to S3 Object Storage and this will grant you a pair of S3 access keys which you can copy and paste into your template. 

-----

### S3_HOST_BASE 

This parameter is the S3 endpoint for your deployment. It should be located as near as possible to where (in the world) you plan to run your VPS systems.

**digital ocean** - Available endpoints to choose from (2020) - nyc3.digitaloceanspaces.com, ams3.digitaloceanspaces.com, sfo2.digitaloceanspaces.com, sgp1.digitaloceanspaces.com, fra1.digitaloceanspaces.com

**exoscale** - Available endpoints to choose from (2024) - sos-ch-gva-2.exo.io, sos-ch-dk-2.exo.io, sos-de-fra-1.exo.io, sos-de-muc-1.exo.io, sos-at-vie-1.exo.io, sos-at-vie-2.exo.io, sos-bg-sof-1

**linode** - Available endpoints to choose from (2025) - us-east-1.linodeobjects.com eu-central-1.linodeobjects.com ap-south-1.linodeobjects.com us-southeast-1.linodeobjects.com us-iad-1.linodeobjects.com fr-par-1.linodeobjects.com us-ord-1.linodeobjects.com in-maa-1.linodeobjects.com se-sto-1.linodeobjects.com it-mil-1.linodeobjects.com us-sea-1.linodeobjects.com id-cgk-1.linodeobjects.com jp-osa-1.linodeobjects.com br-gru-1.linodeobjects.com us-lax-1.linodeobjects.com nl-ams-1.linodeobjects.com us-mia-1.linodeobjects.com es-mad-1.linodeobjects.com us-iad-10.linodeobjects.com au-mel-1.linodeobjects.com gb-lon-1.linodeobjects.com sg-sin-1.linodeobjects.com jp-tyo-1.linodeobjects.com 

**vultr** - Available endpints to choose from (2024) - ewr1.vultrobjects.com, ams1.vultrobjects.com, sjc1.vultrobjects.com, sgp1.vultrobjects.com

**SPECIAL NOTE:**  

A trick you can use with this value is that you can provide a "chain" of S3_HOST_BASE values in your template. What this will do is that whenever the system makes a backup it will make backups to all the regions in your s3_HOST_BASE region chain and that means you can make backups of your sourcecode/databases to multiple regions therefore making yourself more resilient. If a region for your provider is down you will still have backups in different regions that you can fall back on.
To make a region chain you just set your template value to be a colon separated list. Using linode as an example your region chain could look like:  

**S3_HOST_BASE="nl-ams-1.linodeobjects.com:us-southeast-1.linodeobjects.com:in-maa-1.linodeobjects.com"**   

To make it clear just setting this value as described to a region chain will get you backups to **nl-ams-1,us-southeast-1 and in-maa-1**  

-----

### S3_LOCATION

**digital ocean** - the location should always be set to one of nyc1 sfo1 nyc2 ams2 sgp1 lon1 nyc3 ams3 fra1 tor1 sfo2 blr1 sfo3  

**exoscale** - the location should always be set to one of ch-gva-2 ch-dk-2 at-vie-1 de-fra-1 bg-sof-1 de-muc-1  

**linode** - the location should always be set to one of ap-west ca-central ap-southeast us-iad us-ord fr-par us-sea br-gru nl-ams se-sto in-maa jp-osa it-mil us-mia id-cgk us-lax us-central us-west us-southeast us-east eu-west ap-south eu-central ap-northeast   

**vultr** - the location should always be set to one of ams atl cdg dfw ewr fra icn lax lhr mex mia nrt ord sea sgp sjc sto syd yto  

-----

### TOKEN

Some providers use personal access tokens rather than access keys and secret keys. In such a case, the personal access token can be stored in this variable. If the provider uses a personal access token, you can store it here, basically, othewise presume that an access key and a secret key are utilised.

**digital ocean** - Login to your digital ocean account and go to the API submenu (on the left bottom) and generate a "Digital Ocean Personal Access Token". This will give you a personal access token which you can paste into your template as the value of the TOKEN variable.

**exoscale** - exoscale does not need this see ACCESS_KEY and SECRET_KEY

**linode** - Login to your Linode account, go to your Profile (top right) and select "API Tokens" and from there you can generate a "personal access token" to use as your TOKEN

**vultr** - Login to your vultr account and go to your account on the top right. Then enable your personal access token and you can set it here.

-----

### ACCESS_KEY
### SECRET_KEY

Some providers use an access key and a secret key to control access to their compute resources. You need to generate an access and secret key for your provider and use them here as ACCESS_KEY and SECRET_KEY respectively

**digital ocean** - Does not use access keys and secret keys, see TOKEN

**exoscale** - You can generate access keys and secret keys to control access to your compute resources. Note, this is distinct from the object storage access keys

**linode** - Does not use access keys and secret keys, see TOKEN

**Vultr** - Does not use access keys and secret keys, see TOKEN


-----

### EMAIL_NOTIFICATION_LEVEL

This will set the email notification level for system status emails and it can be set to either "INFO" or "ERROR" or "MANDATORY".

If you set it to INFO you will get status emails such as "A database backup has completed successfully" every time a backup is made
If you set it to ERROR you will only get error message emails if, for example, "A database backup has failed to complete". 
If you set it to MANDATORY it means its not an error but it must be sent

NOTE: INFO will report INFO and ERROR messages, ERROR will only report ERROR messages

Clearly if you set it to ERROR, you will only get emails if there is a problem if you set it to INFO you will get emails reporting back on how the system is running under normal function. 

------

### DNS_USERNAME

This will be the username for your nameserver provider

- If you are using cloudflare DNS to provide your DNS services then DNS_USERNAME is  the emal address of your cloudflare account
- If you are using digitalocean DNS to provide your DNS services then DNS_USERNAME is  the emal address of your digital ocean account
- If you are using exoscale DNS to provide your DNS services then DNS_USERNAME is  the emal address of your exoscale account
- If you are using linode DNS to provide your DNS services then DNS_USERNAME is  the emal address of your linode account
- If you are using vultr DNS to provide your DNS services then DNS_USERNAME is  the emal address of your vultr account


-----

### DNS_SECURITY_KEY 

This is the security key which will enable us to manipulate records as needed with your nameserver provider. You can find this key as follows for each provider:

**cloudflare** - You need your Cloudflare account ID and you need to generate an API token with DNS Edit scope and function.   
You can then present your credentials to the toolkit as:  

>     export DNS_SECURITY_KEY="<account-id>:<api-token>"  

If you are unsure how to find your account ID and how to generate your API token with DNS Edit scope you can look [here](https://www.wintersys-projects.uk/Agile%20Deployment%20Toolkit/Deployment/CloudflareAPITokens)

**digital ocean** - The access token for your digital ocean account, (can be the same as TOKEN)

**exoscale**  - The access key and secret key for your exoscale account. You need to enter this as ${ACCESS_KEY}:${SECRET_KEY}.   
In other words, if you have an ACCESS_KEY="123" and a SECRET_KEY="456" then you would configure this setting as:  

>     export DNS_SECURITY_KEY="123:456"  

You can use the same access key and secret key as your main account or you can create separate ones with only DNS manipulation rights. 

**linode** - A personal access token with DNS manipulation rights (can be the same value as TOKEN)

**vultr** - A personal access token with DNS manipulation rights (can be the same as TOKEN)

-----

### DNS_CHOICE  

This can be set to one of these values 

"cloudflare"   
"digitalocean"   
"exoscale"  
"linode"  
"vultr"  

It defines which of the (supported) DNS service you would like to use with your deployment.

---------------

### WEBSITE_DISPLAY_NAME

This is simply the display name of your application, for example, "My Social Network", or "My Blog" and so on. It should be descriptive of your website and likely will be similar to the core part of the WEBSITE_URL described below

-----

### WEBSITE_NAME

This HAS to be exactly the same of the core part of the URL name of your website. So, if your website is called www.nuocial.org.uk, then, this value MUST be "nuocial"

-----

### WEBSITE_URL

This is the URL of your website. It can be any valid URL

-----

### USER_EMAIL_DOMAIN

I don't know what your DNS system setup will be but there's a good chance that the provider servicing your user's email addresses (for example I use cloudflare email routing) will be a different DNS system to that which is serving your website when you deploy with an authenticator machine. What this feature is for then is to allow you to define your user's email adress domain which will have to be different from your actual website domain. So, if your website domain is "www.nuocial.uk" and you are deploying with an authenticator and your email provider (it might be pre-existing for example if you are using this to add social.nuocial.uk as an addition to your existing setup), then, here is where you can define your user's email addresses domain name so that the system can filter for valid and invalid email addresses. For example, if your website domain is www.nuocial.uk you will likely need to set up a separate domain, nuocialmail.uk or something like that to service your email address allocation. Your users will then use the nuocial.uk address for your website and nuocialmail.uk as the domain of their email. You will only need to use this if you are deploying an authenticator machine.

-----

### APPLICATION_REPOSITORY_PROVIDER

This is the git service provider where your application repositories are hosted. It has to be one of "github", "bitbucket" or "gitlab". If you fill this variable with one of those three exact strings, then, that will tell us who your application code is hosted with. It may or may not be hosted with the same provider as the infrastructure code for the agile deployment toolkit

-----

### APPLICATION_REPOSITORY_OWNER

This is the username of the user who owns (or created) your application repositories with your chosen git service provider

-----

### APPLICATION_REPOSITORY_USERNAME

This is the username of the user that you are currently using to access the application repositories. For example, the repositories might be owned by userA and are kept private but, userB is granted access. In this case the APPLICATION_REPOSITORY_OWNER would be userA and the APPLICATION_REPOSITORY_USERNAME would be userB. If you are the application repository owner, then this username and the owner name above will be the same.

-----

### APPLICATION_REPOSITORY_PASSWORD  

This is the password for the APPLICATION_REPOSITORY_USERNAME or the application repository user. This is the password for your user account with your git provider. If the application repositories are public, then a password is not needed in which case this can be set to "".

-----

### APPLICATION_REPOSITORY_TOKEN

Github and Gitlab prefer personal access tokens to passwords, so, if you wish to, you can generate personal access tokens at:

Github: www.github.com/settings/tokens  
Gitlab: www.gitlab.com/profile/personal_access_tokens

Make sure these tokens have the rights to create and destroy repositories as well as to read and write from them. Most likely, you want to have a separate git provider account for your associated deployments. This will override APPLICATION_REPOSITORY_PASSWORD

------

### BUILD_MACHINE_VPC

"0" Means that your build machine isn't in the same VPC as your deployed machines (your build machine might be a dedicated laptop or even running on a different cloudhost VPS). Becuase of this public IP addresses will have to be used for all communications between the build machine and the deployed machines

"1" means that your build machine is in the same VPC as your deployment machines and so private networking (private ip addresses in other words) can be used to commincate from the build machine to the deployment machines. This is the more secure option. 

##### MAKE SURE THAT THE VALUE YOU SET HERE CORROLATES WITH THE VALUE THAT YOU HAVE SET FOR THE "REGION" VALUE

------

### VPC_IP_RANGE

You need to put the address range of your VPC in here. This is mandatory because without it the firewalling won't function correctly and your website will likely timeoout. An example value of this might be 10.116.0.0/24 for a VPC in digital ocean's lon1 datacentre. This value will be different for each region where your VPC is and the you must have a VPC (or private network if you are on exoscale) called, for example, "adt-vpc". You can get the VPC_IP_RANGE from the GUI system for each provider and the value you place here needs to be the same as is displayed in the GUI system. Don't forget also that if you change your deployment region from, for example, london to amsterdam then your VPC_IP_RANGE will change also to reflect the new region and you will need to update this value as well. 

------

### VPC_NAME

You can set the name of your VPC here. By giving your VPCs different names you can have VPCs in different regions of the same provider, for example, you could call your VPCs "adt-vpc-lon" and "adt-vpc-ams" and so on. Remember, if you have BUILD_MACHINE_VPC set to 1, then your build-machine will have to be attached to the same VPC as is named here. 

-------

### SYSTEM_EMAIL_PROVIDER

At the moment, there are three SMTP email service providers. Enter the number value, "1", "2" or "3" to select which provider you want to use for your SMTP service. If you leave these variables blank, you simply won't receive any system emails to give status updated on build progression, server intialisations and so on. You are free to leave these variables blank, as you choose.

Enter "1" - Sendpulse (www.sendpulse.com). 

Enter "2" - Mailjet. 

Enter "3" - AWS SES. 


-----

### SYSTEM_TOEMAIL_ADDRESS 

The email address that system emails will be sent to this can be any email address that you have access to. MAYBE, the emails get marked as spam depending on your provider. If you take them out of the spam folder, then, the system should learn they are not spam. Most likely you will want to have a dedicated email address for your system emails for your deployed application as they will likely fill up your inbox otherwise.

-----

### SYSTEM_FROMEMAIL_ADDRESS

The email address that system emails will be sent from. This should be an email address that the system emails are sent from. In your SYSTEM_TOEMAIL_ADDRESS inbox, this will be the email address that the system messages are seen to be sent from or to have originated from.

-----

### SYSTEM_EMAIL_USERNAME

This is the username of your SMTP user. For Amazon SES, for example, this will be the username generated when you enable the SES service. This is the SMTP username. 

-----

### SYSTEM_EMAIL_PASSWORD

This is the password of your SMTP user. For Amazon SES, for example, this will be the password generated when you enable the SES service. This is the SMTP password. 

----

### DIRECTORIES_TO_MOUNT

Each CMS system is likely to have directories where assets are generated from application usage and so on. Assets and media that are generated at runtime need to be immediately shared between all webservers and the way I do this is as a general solution, I mount the assets directories specific to the CMS type from a shared S3 bucket to each webserver.  

Joomla  

>     export DIRECTORIES_TO_MOUNT="/var/www/html/images"

 When the CMS is joomla, and PERSIST_ASSETS_TO_DATASTORE="1", this will mount 
 
 >      /var/www/html/images

 from an associated asset bucket in your datastore

Worpress  

>     export DIRECTORIES_TO_MOUNT="/var/www/html/wp-content/uploads"

When the CMS is WordPress, and PERSIST_ASSETS_TO_DATASTORE="1", this will mount 

>     /var/www/html/wp-content/uploads

from an associated asset bucket in your datastore

Drupal  

>     export DIRECTORIES_TO_MOUNT="/var/www/html/sites/default/files"

When the CMS is Drupal, and PERSIST_ASSETS_TO_DATASTORE="1", this will mount 

>     /var/www/html/sites/default/files

from an associated asset bucket in your datastore
 
Opensocial 

>     export DIRECTORIES_TO_MOUNT="/var/www/html/sites/default/files:/var/www/private"

When the CMS is Opensocial, and PERSIST_ASSETS_TO_DATASTORE="1", this will mount  

>     /var/www/html/sites/default/files  and /var/www/private

from associated asset buckets in your datastore

Moodle 

>     export DIRECTORIES_TO_MOUNT="moodledata.filedir"

When the CMS is Moodle, and PERSIST_ASSETS_TO_DATASTORE="1", this will mount  

>     /var/www/html/moodledata/filedir

from an associated asset bucket in your datastore

The associated asset buckets are generated when you make your first temporal backup of a baselined application according to what you have the DIRECTORIES_TO_MOUNT value set to along with PERSIST_ASSETS_TO_DATASTORE being set to "1"

----- 

### SYNC_WEBROOTS

When you are deploying multiple webservers you want to keep all of their webroots in sync. If you swtich this option on then if updates are made to the webroot on one server those changes are synced to all the other webservers that are active within a few seconds. This means that the webservers are kept in sync with any maintenance updates you make to one webserver with only a brief couple of seconds when there is a possibility of them being unsynchronised.

Set this to 0 if you don't want to synchronise the webroots of your webservers set it to 1 if you do want to synchronise them

-------

### PRODUCTION 
### DEVELOPMENT

These settings are twinned. It only makes sense for them to be in one of two configurations:

Production mode :   
PRODUCTION="1", DEVELOPMENT="0"  

Development mode :   
PRODUCTION="0", DEVELOPMENT="1"  

These settings must be altered as a pair. When in production, an autoscaler or autoscalers are deployed and you can configure how many webservers you want to be running. In development mode there will be at most one webserver running.

-----

### NO_WEBSERVERS

This will set the number of webservers to deploy by default. If you set this to 3, for example, then 3 webservers will be spun up by default

-----

### MAX_WEBSERVERS

This needs to be set to an integer that determines the maximum number of webservers that an autoscaler can start. If you set MAX_WEBSERVERS to 10 and you are running with  3 autoscaler machines then each autoscaler will be able to start a maximum of 10 webservers meaning 30 webservers overall. If you are running only 1 autoscaler machine and MAX_WEBSERVERS is set to 10 then that will mean that there will be a maximum of 10 webservers running. Its important to have MAX_WEBSERVERS set to prevent any run away scaling conditions from occuring. 

-----

### WEBSERVER_CHOICE

You have a choice of webserver that you want to deploy to. You can set this to "NGINX, "APACHE" or "LIGHTTPD". What you set this to will determine which webserver gets installed and used. 

--------

### REVERSE_PROXY_WEBSERVER

This sets which webserver is to be used for the reverse proxy webserver which can be different to what you use as your main webserver. For example you can set this to "NGINX" and your main webserver to "APACHE"

-----

### REVERSE_PROXY

if you want to deploy reverse proxy/proxies then you can set REVERSE_PROXY to "1" in your template. So, this setting has two options
 
 
- "1" - Deploy reverse proxy/proxies
- "0" - Do not deploy reverse proxy/proxies
 
When this is set to "0" any reverse proxies in the build chain will be omitted

----------
 
### NO_REVERSE_PROXY
 
This tells the system how many reverse proxy servers to deploy this can be up to 5 servers. So, you set this value to any integer between 1 and 5

### DATABASE_INSTALLATION_TYPE

If you are installing a database on a VPS system, you have three types of database you can choose from by default. Obviously, your choice here has to be supported by your CMS system. The choices are: "Maria", "MySQL", and "Postgres" and if you are installing a managed darabase you will want to set this to DBaaS

-----

### SERVER_TIMEZONE_CONTINENT

This is the continent where your servers are located. You can get a list of continents is as follows:


```
    continents="Africa America Antarctica Arctic Asia Atlantic Australia Europe Indian Pacific"

e.g. continent="Europe"

```


-----

### SERVER_TIMEZONE_CITY

This is the city where your servers are located. You can get a list of cities by issuing the following commands where continent is from above:

```

    cities="`cd /usr/share/zoneinfo/${continent} && /usr/bin/find * -type f -or -type l | /usr/bin/sort`"

eg city="London"


```

-----

### DB_PORT

This is the port that your Database will be listening on. BE SURE that if you are using a managed database that you set this value to be the same as the port that you set when you setup the managed DB. If it is different, obviously, the scripts will not collect and things will go south. 

-----

### SSH_PORT

This is the port that the SSH daemon will be listening on for connections. You can set this as you would normally set a port. Obviously, the port you set has to be free on your server. The firewall will work with whatever setting you set and allow connections to that port. 

-----

### PERSIST_ASSETS_TO_DATASTORE 

There are three settings you can use:

"0" means just use the webservers actual directories for asset storage (this will likely only be the case if you have very few assets to store). The literal webroot is used for asset storage you can't deploy multiple webservers if you use this setting because the asset files will not be shared between the webservers. If someone can think of a good way of automatically (and easily) synchronising  the asset folder of n webservers, that would be cool.  

"1" means use S3FS (or another supported solution, for example goofys) to mount assets buckets into your webserver's filesystem assets are then written directly to these services when your application stores an asset. This is suitable for production mode.   

-----

### BASELINE_DB_REPOSITORY

When you baseline your application database, you will need to create a repository <unique_identifier>-db-baseline. From here your baseline will be pulled during installation. 
If for example, your unique identifier is "wordydemo", then, the repository would be "wordydemo-db-baseline" and 

BASELINE_DB_REPOSITORY would be set to "wordydemo-db-baseline"

-----

### APPLICATION_BASELINE_SOURCECODE_REPOSITORY

When you baseline your application sourcecode, you will need to create a repository <unique_identifier>-webroot-sourcecode-baseline. From here your baseline will be pulled during installation. 

If for example, your unique identifier is "wordydemo", then, APPLICATION_BASELINE_SOURCECODE_REPOSITORY would be "wordydemo-webroot-sourcecode-baseline" 

-----

### BUILD_ARCHIVE_CHOICE

You need to set BUILD_ARCHIVE_CHOICE based on where you are deploying from. The settings can be as follows for each option:  

 BUILD_ARCHIVE_CHOICE="virgin"
 BUILD_ARCHIVE_CHOICE="baseline"  
 BUILD_ARCHIVE_CHOICE="hourly"  
 BUILD_ARCHIVE_CHOICE="daily"  
 BUILD_ARCHIVE_CHOICE="weekly"  
 BUILD_ARCHIVE_CHOICE="monthly"  
 BUILD_ARCHIVE_CHOICE="bimonthly"

-----

### APPLICATION_LANGUAGE

You can set this to "HTML" or "PHP" based on the language you are deploying for.

------

### PHP_VERSION

If you are deploying PHP, then you can set which version of PHP you are deploying here. Ordinarily, it should be the latest available version (currently 7.4).
So, to use 7.4 you would set PHP_VERSION="7.4"

-------------

### REGION

This is the region id where you wish to deploy the servers to.

Available region ids to choose from for each provider are:

Digital Ocean: Available region IDs you can set for digital ocean are:  

"nyc1","sfo1","nyc2","ams2","sgp1","lon1","nyc3","ams3","fra1","tor1","sfo2","blr1","sfo3","syd1", "atl1"

Exoscale: Available region IDs you can set for exoscale are:   

"ch-gva-2", "ch-dk-2", "at-vie-1", "at-vie-2", "de-fra-1", "bg-sof-1", "de-muc-1", "hr-zag-1"   

Linode: Available regions you can set for linode are:   

"ap-west", "ca-central", "ap-southeast", "us-iad", "us-ord", "fr-par", "us-sea", "br-gru", "nl-ams", "se-sto", "es-mad", "in-maa", "jp-osa", "it-mil", "us-mia", "id-cgk", "us-lax", "gb-lon", "au-mel", "in-bom-2", "de-fra-2", "sg-sin-2", "jp-tyo-3", "us-central", "us-west", "us-southeast", "us-east", "eu-west", "ap-south", "eu-central", "ap-northeast" 

Vultr: Available regions you can set for vultr are:   

"ams", "atl", "blr", "bom", "cdg", "del", "dfw", "ewr", "fra", "hnl", "icn", "itm", "jnb", "lax", "lhr", "mad", "man", "mel", "mex", "mia", "nrt", "ord", "sao", "scl", "sea", "sgp", "sjc", "sto", "syd", "tlv", "waw" "yto"

-------

### DB_SERVER_TYPE 
### AS_SERVER_TYPE 
### WS_SERVER_TYPE
### AUTH_SERVER_TYPE

For each machine size SIZE it needs to have the appropriate machine type set. The following machine types correspond to the appropriate _SIZE parameter directly above

DigitalOcean: s-1vcpu-512mb-10gb s-1vcpu-1gb s-1vcpu-1gb-amd s-1vcpu-1gb-intel s-1vcpu-1gb-35gb-intel s-1vcpu-2gb s-1vcpu-2gb-amd s-1vcpu-2gb-intel s-1vcpu-2gb-70gb-intel s-2vcpu-2gb s-2vcpu-2gb-amd s-2vcpu-2gb-intel s-2vcpu-2gb-90gb-intel s-2vcpu-4gb s-2vcpu-4gb-amd s-2vcpu-4gb-intel s-2vcpu-4gb-120gb-intel s-2vcpu-8gb-amd c-2 c2-2vcpu-4gb s-2vcpu-8gb-160gb-intel s-4vcpu-8gb s-4vcpu-8gb-amd s-4vcpu-8gb-intel g-2vcpu-8gb s-4vcpu-8gb-240gb-intel gd-2vcpu-8gb g-2vcpu-8gb-intel gd-2vcpu-8gb-intel s-4vcpu-16gb-amd m-2vcpu-16gb c-4 c2-4vcpu-8gb s-4vcpu-16gb-320gb-intel s-8vcpu-16gb m3-2vcpu-16gb c-4-intel s-8vcpu-16gb-amd s-8vcpu-16gb-intel c2-4vcpu-8gb-intel g-4vcpu-16gb s-8vcpu-16gb-480gb-intel so-2vcpu-16gb m6-2vcpu-16gb gd-4vcpu-16gb g-4vcpu-16gb-intel gd-4vcpu-16gb-intel so1_5-2vcpu-16gb s-8vcpu-32gb-amd m-4vcpu-32gb c-8 c2-8vcpu-16gb s-8vcpu-32gb-640gb-intel m3-4vcpu-32gb c-8-intel c2-8vcpu-16gb-intel g-8vcpu-32gb so-4vcpu-32gb m6-4vcpu-32gb gd-8vcpu-32gb g-8vcpu-32gb-intel gd-8vcpu-32gb-intel so1_5-4vcpu-32gb m-8vcpu-64gb c-16 c2-16vcpu-32gb m3-8vcpu-64gb c-16-intel c2-16vcpu-32gb-intel g-16vcpu-64gb so-8vcpu-64gb m6-8vcpu-64gb gd-16vcpu-64gb g-16vcpu-64gb-intel gd-16vcpu-64gb-intel so1_5-8vcpu-64gb m-16vcpu-128gb c-32 c2-32vcpu-64gb m3-16vcpu-128gb c-32-intel c2-32vcpu-64gb-intel c-48 m-24vcpu-192gb g-32vcpu-128gb so-16vcpu-128gb m6-16vcpu-128gb gd-32vcpu-128gb c2-48vcpu-96gb g-32vcpu-128gb-intel m3-24vcpu-192gb g-40vcpu-160gb gd-32vcpu-128gb-intel so1_5-16vcpu-128gb c-48-intel m-32vcpu-256gb gd-40vcpu-160gb c2-48vcpu-96gb-intel so-24vcpu-192gb m6-24vcpu-192gb m3-32vcpu-256gb g-48vcpu-192gb-intel gd-48vcpu-192gb-intel so1_5-24vcpu-192gb so-32vcpu-256gb m6-32vcpu-256gb so1_5-32vcpu-256gb 

Exoscale: micro,tiny,small,medium,large,extra-large,huge,mega,titan,jumbo,colossus

Linode: g6-nanode-1,g6-standard-1,g6-standard-2,g6-standard-4,g6-standard-6,g6-standard-8,g6-standard-16,g6-standard-20,g6-standard-24,g6-standard-32

Vultr: vc2-1c-1gb, vc2-1c-2gb, vc2-2c-4gb, vc2-4c-8gb, vc2-6c-16gb, vc2-8c-32gb

---------

### CLOUDHOST

This is the cloudhost you are deploying to. The current choices are:

"digitalocean", "exoscale", "linode", "vultr", "aws"

You can set the cloudhost to Digital Ocean, for example by setting the CLOUDHOST variable as CLOUDHOST="digitalocean"

-----------

### AUTHENTICATION_SERVER

If you want to deploy an authentication server then set this to "1" otherwise set it to "0"

------------

### AUTH_SERVER_URL  

The website URL for your authentication server  

-------------

### AUTH_DNS_USERNAME  

The username for the DNS service that your authentication server's URL is managed with. Your authentication server needs to be a different domain to your main website. For examle, if your main application domain is www.nuocial.uk then your authentication server might be auth.nuocialauth.uk which is a separate domain so that it can be hosted by a different DNS provider to your main application. For example, your main application might be hosted by linode DNS provider and your authentication server DNS might be hosted by cloudflare DNS.   

-----------------------

### AUTH_DNS_SECURITY_KEY  

The security key that is paired with your AUTH_DNS_USERNAME for the DNS service provider for the authentication server DNS provider.  

---------------------------

### AUTH_DNS_CHOICE  

This is the name of the DNS provider for your authentication server. This can be  

1. cloudflare
2. digitalocean
3. exoscale
4. linode
5. vultr

---------

### MACHINE_TYPE

This is just an identifier which we can check for on our servers. It can be set to

"DROPLET", "EXOSCALE", "LINODE", "VULTR"

------------

### ALGORITHM

This is the algorithm that the ssh uses to form connections it can be set to "rsa", or, "ecdsa"

------

### USER

This is the user that the scripts is running as. It can be set, as, USER="root" and so on

--------

### ACTIVE_FIREWALLS

This will set which (if any) firewalls are active on your machines
 0 - No active firewalls (not recommended)  
 
 1 - UFW or iptables firewall only active on all machines  
 
 2 - Native firewall only active on all machines   
 
 3 - UFW or iptables and Native Firewall active on all machines (recommended)   
 
 NOTE: the UFW firewalls are always active on your build machine regardless of this setting for security reasons  


----------

### CLOUDHOST_ACCOUNT_ID

This is whatever attribute you use to login to the cloudprovider portal it can be a username or an email address
This is mandatory for linode and exoscale because it is how the configuration file for the CLI tool is setup and configured. 

digitalocean - not needed  
exoscale - The email address that you use to login to the exoscale portal at www.exoscale.com  
linode - The username that you use to login to the linode portal at www.linode.com  
vultr - not needed

------

### GIT_USER 
### GIT_EMAIL_ADDRESS

These are the values for the git user that your commits are made by. Obviously, I don't know what those will be, so they are set to some placeholder values in the templates I have provided, but, you can change them to your own values, of course. These values correspong to **git config --global user.name "Template User"** and  **git config --global user.email "templateuser@dummyemailX1.com"** 

-----

### APPLICATION_REPOSITORY_TOKEN

This is a gitlab and github specific token. When you have a private application repository with gitlab or github, you need to generate a private auithorisation token.
For github, you can do this by logging into your account and going to: https://github.com/settings/tokens and then generate one
    gitlab, you can do this by logging into your account with them and clicking on Profile Settings -> Access Tokens and then generating one"
The token that you generate can be placed here in your template instead of a password (for your application repositories)

-----

### INFRASTRUCTURE_REPOSITORY_PROVIDER
### INFRASTRUCTURE_REPOSITORY_OWNER
### INFRASTRUCTURE_REPOSITORY_USERNAME
### INFRASTRUCTURE_REPOSITORY_PASSWORD

By default these values are set as shown below, if you are building from your own forks you will need to set these according to your fork's criteria 

INFRASTRUCTURE_REPOSITORY_PROVIDER="github"  

INFRASTRUCTURE_REPOSITORY_OWNER="wintersys-projects"  

INFRASTRUCTURE_REPOSITORY_USERNAME="wintersys-projects"  

INFRASTRUCTURE_REPOSITORY_PASSWORD=""


-----

### DATASTORE_CHOICE

This value determines who your object store provider will be (very likely the same as your compute services provider, but, doesn't have to be)
DATASTORE_CHOICE should be set to one of the following values:
  
 For DigitalOcean spaces: "digitalocean"  
 
 For Exoscale Object Store: "exoscale"  
 
 For Linode Object Store: "linode"  
 
 For Vultr Object Store: "vultr"  
 

------

### DATABASE_DBaaS_INSTALLATION_TYPE

Please review [this](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/doco/AgileToolkitDeployment/DeployingDBaaS.md) for how to set the shortcut values for your DBaaS provider.
Otherwise, set this value to one of "MySQL", "Maria" or "Postgres" when you have set DATABASE_INSTALLATION_TYPE to "DBaaS"

-----

### BYPASS_DB_LAYER

0 : install application as normal

1 : Don't install the application because you have already got a DBaaS running with the application installed in it from a previous build and so, use that.

2 : Completely bypass installing the DB layer. You might want this if you are installing to multiple regions and you don't want a DB layer on your secondary region(s). 

-----

### APPLICATION_NAME

This is just a text string descriptor for your application it could be "My Test Blog", "My Social Network", "Nuocial Online Community" and so on
        
        
-----

### SSL_GENERATION_METHOD

This can be set to "AUTOMATIC" or "MANUAL". If it is set to automatic, then an attempt to provision an SSL certificate from an automated authority will be made. If it is set to manual, you will have to manually obtain and present your own certificate. 

-----

### SSL_GENERATION_SERVICE

This can be set to one of two values:

1. LETSENCRYPT (letsencrypt certificates can only be issued when **lego** is the SSLCERTCLIENT in buildstyles.dat on the build machine)
2. ZEROSSL     (zerossl certificates can only be issued when **acme** is the SSLCERTCLIENT in buildstyles.dat on the build machine)

If SSL_GENERATION_SERVICE is set to "LETSENCRYPT" then the "lets encrypt" service will be used to generate the SSL certificates for your deployment
If SSL_GENERATION_SERVICE is set to "ZEROSSL" then the "zero ssl" service will be used to generate the SSL certificates for your deployment

------

### SSL_LIVE_CERT

This will tell the toolkit whether to use live cerificates (which are subject to issuance limits) or staging certificates (which are subject to browser warnings). Live certificates should always be used in production.

if SSL_LIV£_CERT="1" then this says "generate a live (production ready) certificate
if SSL_LIVE_CERT="0" then this says "generate a staging (development mode) certificate

The templating system is set up to use live certificates by default in all cases

-----------------------

### SELECTED_TEMPLATE

When you are making a "hardcore" build, you need to supply the number of the template you are generating a script for, for example, "1", "2", "3"

-------------
### INPARALLEL

Whether to build the machines you are deploying in paralel or not on the build machine. If you build them in parallel they will build quicker but it might not be so easy to see what is going on.

0 Do not build in parallel
1 Build in parallel

-------------

### NO_AUTOSCALERS

How many autoscalers to deploy. An Interger value between 0 and 5

---------------

### MULTI_REGION

If you wish to make a deployment using multiple regions then you need to set this as follows:

0 - single region deployment
1 - multi region deployment

-----------------
### PRIMARY_REGION

If you are making a multi-region deployment you need to have a primary region (this is the first region you will built out servers for) and all the other regions that you are deploying will not be primary. When you making multi region deployments, then, you need to set this as follows:

0 - the current region is not the primary region
1 - the current region is the primary region

The setting of "PRIMARY_REGION" doesn't have any effect if you are not deploying to multiple regions
