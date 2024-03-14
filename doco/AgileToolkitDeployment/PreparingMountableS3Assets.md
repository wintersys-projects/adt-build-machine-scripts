When your baseline is ready depending on your configuration you might want to prepare assets from your application to be mounted from a remote service such as S3

To prepare you assets for usage from a mount follow these steps:

1. Find which directories your application is set to treat as mountable

root@nuocialWS:/home/X3nuDHGtfjChlPTzI3RX/.ssh# cat web* | grep DIRECTORIESTOMOUNT  
DIRECTORIESTOMOUNT:images:assets  

2. Check that these directories are not mounted already  

root@nuocialWS:/home/X3nuDHGtfjChlPTzI3RX/.ssh# mount | grep "/var/www/html/images"  
root@nuocialWS:/home/X3nuDHGtfjChlPTzI3RX/.ssh#   

root@nuocialWS:/home/X3nuDHGtfjChlPTzI3RX/.ssh# mount | grep "/var/www/html/assets"  
root@nuocialWS:/home/X3nuDHGtfjChlPTzI3RX/.ssh#   

if there are mounts unmount them  

umount /var/www/html/assets   
umount /var/www/html/images   

3. Once you are sure that there's no mounts, find out how many files there are in each mountable directory  

root@nuocialWS:/home/X3nuDHGtfjChlPTzI3RX/.ssh# ls -lR /var/www/html/images | wc -l  
23  
root@nuocialWS:/home/X3nuDHGtfjChlPTzI3RX/.ssh# ls -lR /var/www/html/assets | wc -l  
12276  

4. Run the script to setup the assets for you  

root@nuocialWS:/home/X3nuDHGtfjChlPTzI3RX/.ssh# run ${HOME}/providerscripts/datastore/SetupAssetsMounts.sh  
root@nuocialWS:/home/X3nuDHGtfjChlPTzI3RX/.ssh# mount  

s3fs on /var/www/html/images type fuse.s3fs (rw,nosuid,nodev,relatime,user_id=0,group_id=0,allow_other)  
s3fs on /var/www/html/assets type fuse.s3fs (rw,nosuid,nodev,relatime,user_id=0,group_id=0,allow_other)  

5. Make sure that there's the same number of files in on your mounts as there were original so recursively list on the mounts:  

root@nuocialWS:/home/X3nuDHGtfjChlPTzI3RX/.ssh# ls -lR /var/www/html/images | wc -l  
23  
root@nuocialWS:/home/X3nuDHGtfjChlPTzI3RX/.ssh# ls -lR /var/www/html/assets | wc -l  
12276  

If the numbers are the same in step 5 as in step 2 and the mounts are active, then, you are all set. You MUST create the following file to signal that you are happy:  

/bin/touch ${HOME}/runtime/ASSETMOUNTSPREPARED  

6. Once you have setup your S3 mounts you need to keep them mounted if you intend to add more assets to your application because otherwise the assets will be lost to the local filesystem. You can of course unmount the assets buckets and use the underlying local filesystem for your baseline updates but you will need to rerun this script in alignment with your final baseline and so you do that by:

/bin/rm ${HOME}/runtime/ASSETMOUNTSPREPARED

run ${HOME}/providerscripts/datastore/SetupAssetsMounts.sh  

Note: do not use S3CMD to upload assets files because S3FS will not be able to see them. For S3FS to see a file in S3FS it must be created by S3FS  
