The webroot syncing mechanism works by every short while looking in its webroot for modified, created and deleted files.
Using an intermediate directory

>     ${HOME}/runtime/webroot_audit

tar archives of these file types are made and are then synchronised to all other webservers and extracted/actioned. The way the extraction process works, is that if the same file were to have been modified on two different webservers, then the file with the newest timestamp will be the accepted version. 
