There is a file in the webroot of baselined applications which tell you which database it was built with.  

This file is 

>     /var/www/html/dbe.dat  

and it will tell you  whether the application was baselined with MariaDB, MySQL or Postgres  

You should only deploy using the same database as is written to this file in other words, MariaDB and MySQL are not considered 100% interchangeable although they are supposed to be drop in replacements. 
Also, if you intend to deploy to a managed database that runs MARIADB, for example, you should do your application development against a MARIADB instance you shouldn't develop against MySQL if your ultimate target is a MARIADB instance managed database. 
To be clear, you could probably get away with using MySQL and MariaDB interchangeably, but, caution and wanting to avoid issues makes me say try not to if at all possible. 
