How to prepare assets in the S3 datastore for temporal builds if you are using S3FS to remote mount them. 

1. You build your baseline with PERSIST_ASSETS_TO_CLOUD="0" and DIRECTORIES_TO_MOUNT=""

2. Your baseline is running and you are ready to prepare it for usage as a production temporal build deployment with the assets stored in S3 and mounted using S3FS or GOOFYS. You need to examine the sourcecode of your application and decide which directories you want to be stored in S3 - they will be directories where users generate dynamic files such as images and videos. In my case I have done this and the directories I have decided I want to be offloaded for S3 storage are:

/var/www/html/wp-content/uploads 
/var/www/html/wp-content/peepso

3. To transfer these assets to my S3 datastore and use them from a temporal build I need to:

On the webserver my baseline's sourcecode is on I need to edit the file

${HOME}/.ssh/webserver_configuration.dat

I need to change the following values:

PERSIST_ASSETS_TO_CLOUD="1"
DIRECTRORIES_TO_MOUNT="wp-content.uploads:wp-content.peepso"

I then need to run the script (on the webserver)

run ${HOME}/providerscripts/datastore/SetupAssets.sh

This will transfer the files from the directories I have chosen to new buckets in S3 and you will be able to see those buckets in your S3 datastore.

Then make temporal backups of your webserver and database (this will exclude from these temoral backups the files that are now in S3). 

Shutdown your webserver and database

Deploy a temporal deployment from your temporal backups with the settings in your template of:

PERSIST_ASSETS_TO_CLOUD="1"
DIRECTRORIES_TO_MOUNT="wp-content.uploads:wp-content.peepso"
