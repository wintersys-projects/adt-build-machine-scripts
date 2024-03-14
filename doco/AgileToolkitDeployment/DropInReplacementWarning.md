It is supposed to be the case that you can drop in replace MySQL with Mariadb and vice versa.  

This means that you could develop your application using Mariadb and then switch it to MySQL but this is NOT recommended.

When I tried this in both directions my Mariadb instance or my MySQL instances kept crashing.

You will find a file /var/www/html/dbe.dat in the webroot of applications built from the ground up with this toolkit which tells you whether it was built  
using maria mysql or postgres and you must use the same database for reliable functioning

If you have migrated your application from another provider you will need to know which database engine was being used with your previous host
