If you are on a webserver and your application is using an SQL based database you can connect straight to your tables by running:

>     ${HOME}/providerscripts/utilities/ConnectToRemoteMYSQLDB.sh

If you are on a webserver and your application is using an Postgres based database you can connect straight to your tables by running:

>     ${HOME}/providerscripts/utilities/ConnectToRemotePostgresDB.sh

If you are on your database machine already and running an SQL database rarther than faffing around with credentials and so on you can run:

>     ${HOME}/providerscripts/utilities/ConnectToMySQLDB.sh

If you are on your database machine already and running a Postgres database rather than faffing around with credentials and so on you can run:

>     ${HOME}/providerscripts/utilities/ConnectToPostgresDB.sh

These scripts are my idea of PHPMYADMIN which I prefer because I am not much of a graphical guy and I am not convinced that phpmyadmin is robustly securable. 

