1. To shutdown your infrastructure it is important not to simply shutdown the machines using a provider's GUI system or the cli tools. There's a script in the **helperscripts** directory called **ShutdownInfrastructure.sh** which you must run each time you want to shut your system down. This gives the machines a chance to clean up, make backups and so on which means that your data will be consistent. If your application is online and you need to shutdown your servers for some reason, then, if your most recent backup was 1 hour ago then if you don't make a "shutdown" backup then there's the potential for an hour's worth of data to be lost, worse still if you only make daily backups. This is why it is ESSENTIAL that you shutdown using the helperscripts. 

2. If you are using Cloudflare as your DNS Service provider, you need to, at a minimum, switch on 'Full SSL' and also, you need to create a page rule which directs all calls to http://www.website.com to https://www.website.com. This way, you can be sure that all your requests are being issued securly. Also, when you are in development mode, letsencrypt will issue a "testing" certificate which Cloudflare will not accept in "strict mode". If you drop it back down to "full" during development and using staging SSL certificates and up to "strict" once you are ready for production (which doesn't use the staging SSL certificates that strict mode doesn't like), this should allow you to make most efficient use of the certificate issuing process. I say this because staging certificates have no issuing limits on them where as production ones do and if you start issuing production certificates repeatedly you will rapidly start getting error messages and failed certificate issuance. 

3. Remember if you change from deploying to one DNS service and choose another, you will have to change the nameservers with the service you bought your domain names from. This is called a "Nameserver update" and has a propagation delay of up to 48 hrs before your webproperty will be accessible through the new nameservers. 

4. If you want to customise the configuration of your webserver, you can easily do it by altering the scripts in

>     Agile-Infrastructure-Webserver-Scripts/providerscripts/webserver/configuration/

5. To alter your test database configuration, you can modify the file:

>     Agile-Infrastructure-Database-Scripts/providerscripts/database/singledb/mariadb/InitialiseMariaDB.sh

for Maria DB
 
 and the file
 
>     Agile-Infrastructure-Database-Scripts/providerscripts/database/singledb/postgres/InitialisePostgresDB.sh**

for Postgres
 
6. If you are using s3fs for your shared storage, then, if you delete the buckets using the Cloudhost provider's gui system (digital ocean at least has a period when a deleted bucket cannot be recreated) or the s3cmd tool there tends to be a period of time with some providers when buckets of the same name cannot be created again. If you run the scripts during this period and they require the same bucket name as a bucket that you have recently deleted using the GUI, you will get unpredictable behaviour. If you wait till the grace period expires, then, you will be able to complete the execution of the scripts successfully or, better yet, don't delete the buckets using the gui unless you are finished with them entirely.  

7. If you make multiple builds and have, for example, "testbuild-1", "testbuild-2" and so on, you need to name them (<identifier>-BUILD_IDENTIFIER), "1-testbuild", "2-testbuild" rather than "testbuild-1" and "testbuild-2", this is because in some places the "BUILD_IDENTIFIER" might get truncated and you would lose the distinction.    

8. The Agile Deployment Toolkit supports the following application database:

##### Joomla 5 using MySQL, MariaDB or Postgres is supported  
##### Wordpress using MySQL or MariaDB is supported (Postgres needs some faff with wordpress,but you are welcome to modify the toolkit)   
##### Drupal using MySQL, MariaDB or Postgres is supported  
##### Moodle using MySQL, MariaDB or Postgres is supported
 
9. These builds depend on external services, if a service is down, github for example, the build may well not complete.

10. If you get problems with SSL certificate issuance during a build, it is most likely because of "rate limiting". This is most likely to occur if you are using the "hardcore" build method because the other build methods reuse previously issued certificates that are still valid. 

11. Be aware of firewall rules limits which are different by provider. If you had a great number of servers for some providers, the number of firewall rules might be a limiter. 
 
12. This toolkit is intended to by used in such a way that managed DBs are only used when making PRODUCTION deployments. When you are in development mode it is expected that you will use the database that these scripts install on your VPS servers.  
 
13. Remove termination protection for a managed database on Exoscale as follows:
 
 exo dbaas update <db-name - eg: testdb1> -z <region: eg. ch-gva-2> --termination-protection=false

14. If you are planning to deploy to a DBaaS solution then you should do your development on equivalent database types. For example if your final DBaaS deployment is to a MYSQL instance then you should baseline using MySQL as your development database type, not Maria and likewise if your final DBaaS type is Maria DB, you should develop against Maria DB rarther than MySQL. You do this by setting DATABASE_INSTALLATION_TYPE in your template

 
