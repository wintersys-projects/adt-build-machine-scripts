### IF YOU NO LONGER HAVE ACCESS TO THE BUILD MACHINE ITSELF, YOU MUST HAVE KEPT A RECORD OF THE PASSWORD FOR THE BACKUP.  
You can find the password by issuing the command:  

>     crontab -l | grep BackupBuildMachine | awk '{print $6}'  

As long as you know the password for the build you wish to access, you can access it as follows:  

In this case, my build_identifier is "nuocial" you should use your build identifier for yours.  

>     s3cmd ls s3://buildmachine-backup-nuocial  

2021-12-31 23:40     38819840  s3://buildmachine-backup-nuocial/backup-December312021-0.tar.gz  

Get the backup you want to restore, in this case, there is only one  

>     s3cmd get s3://buildmachine-backup-nuocial/backup-December312021-0.tar.gz  

Get the password for your backup:  

>     crontab -l | grep BackupBuildMachine | awk '{print $6}'  

In this case: "_KR8Y_2t"  

Decrypt the backup into the directory ./home in your current directory  

>      openssl enc -d -pbkdf2  -md md5 -pass pass:_KR8Y_2t -in ./backup-*Dec*31*.tar.gz  | /bin/tar -xv  
 
