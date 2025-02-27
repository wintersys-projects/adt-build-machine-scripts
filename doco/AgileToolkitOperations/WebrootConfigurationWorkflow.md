Website assets can be treated in a few ways.

1. Use a plugin at an application level to offload assets without using any of what I mention here
2. Don't offload any assets at an application level and set SYNC_WEBROOTS to 1 (this only works if your application doesn't create bontiful asset files)
3. If you can't use an application plugin for some reason or there isn't a suitable one and you have a large amount of assets you could fall back to what I am describing here which is to have this tooolkit mount assets from your S3 bucket in a way that makes the filesystem look just like a regular filesystem to your application but backed up by your S3 datastore rather than just your hard-disk. 

The most relevant parts of the configuration are the 

>     PERSIST_ASSETS_TO_CLOUD

and 

>     DIRECTORIES_TO_MOUNT
>     SYNC_WEBROOTS

settings in your template.

- If you are deploying a virgin website installation or a baseline website installation then PERIST_ASSETS_TO_CLOUD should always be 0.

- If you are deploying from a temporal backup then PERSIST ASSETS TO CLOUD CAN BE 1.

- When PERSIST_ASSETS_TO_CLOUD is 1, then you can set which directories of your applications webroot you wish to be stored in the cloud (the S3 Data storage). Please refer to the specification for more details on how to set the value of DIRECTORIES_TO_MOUNT. If SYNC_WEBROOTS is 1, the directories mounted from S3 will not be included in the syncing process

--------
There is a special case where if 

>     PERSIST_ASSETS_TO_CLOUD=1

you can set 

>     DIRECTORIES_TO_MOUNT="WHOLE-WEBROOT"

What this will do is it will mount the entire webroot of your application from the Datastore. There will be performance issues and in my testing I can only get this approach to work if I use the rclone option in ${BUILD_HOME}/builddescriptors/buildstyles.dat on the build  machine. You are welcome to see if you can get this to work using one of the other solutions such as "s3fs", "goofys" or "geesefs".

I haven't done any testing as to what your costs would be if you used this technique if they are high it might be possible to get them down using finely configured caching for rclone

--------

The workflow for the assets for the application are arranged as follows. 

As part of the preparation for the build process on the build machine when you run "ExpeditedAgileDeploymentToolkit.sh" when you build from a temporal backup, PERSIST_ASSETS_TO_CLOUD is set to 1 and DIRECTORIES_TO_MOUNT has a value that matches the webroot structure of your application, then the assets will be copied from the temporal backup to the S3 datastore and mounted in place of the assets actually being on the webserver as part of your application.

Here is the workflow.

- You deploy from a baselined copy of your application (PERSIST_ASSETS_TO_CLOUD) must be "0".

- You make an HOURLY backup from this active version of your website (because PERIST_ASSETS_TO_CLOUD="0" the assets of the application will be stored as part of the backup)

- Once you have temporal backups of your website that contain all assets you take the active deployment that you made the backups from offline.

- You then confligure your system to deploy from a temporal backup setting PERSIST_ASSETS_TO_CLOUD to "1" and DIRECTORIES_TO_MOUNT to (for example if you are deploying joomla) to "images"

- When you deploy from the temporal backup the build machine will make a copy of the assets from your temporal backup to the S3 datastore in an identifiable bucket (one bucket for each specific directory that you set for your application)

- The application is then deployed and on each webserver, the assets that were in the temporal backup that match to your "DIRECTORIES_TO_MOUNT" are deleted from your direct filesystem and instead are mounted from the identifiable bucket.

- When subsequent temporal backups are made of your webserver the directories that have been mounted from S3 will be omitted from the backup leaving only a single place of truth for your assets which is the identifiable bucket mentioned above. It is recommeneded therefore if you use this technique that you make backups of your assets manually (in other words, sync your assets to a secondary bucket in another region for safety reasons).

This means that the S3 capacity is your SHARED limit across all your webservers for how many assets you have and not the size of each webservers disk space.
