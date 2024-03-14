If you have a website, lets say a Joomla website with another hosting provider that you want to migrate to running with the ADT, then, I haven't provided any official way of doing that, but, its not impossible, you would have to follow these steps.

1. make a tar archive of your joomla website from your current hosting provider
2. make a mysqldump of your joomla website's database from your current hosting provider
3. make a virgin deployment of joomla (if your application is wordpress then make a virgin deployment of wordpress, and so on)
4. Once the virgin deployment is complete, copy the file from 1. to the webserver and the file from 2 to the database server
5. Delete the application files that exist under /var/www/html on your webserver and replace them with the extracted files from 1. above and make sure the permissions are correct
6. connect to the database that was installed during step 3 above and drop all the tables. Setup the new database by running the sql script from 2. above against the database generated during 3. above. 
7. Check that your application is running correctly and then make a baseline of it. You can then in future deploy off the baseline you have made. 
