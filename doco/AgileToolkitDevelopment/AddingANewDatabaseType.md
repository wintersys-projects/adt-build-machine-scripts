To support a new database engine type you will need to modify or add to the following files:

>      adt-webserver-scripts/ws.sh
>      adt-webserver-scripts/providerscripts/utilities/remote/
>      adt-webserver-scripts/providerscripts/installscripts/InstallDatabaseClient.sh
>      adt-webserver-scripts/providerscripts/utilities/status/CheckServerAlive.sh

>      adt-database-scripts/providerscripts/utilities/status/IsDatabaseUp.sh
>      adt-database-scripts/providerscripts/utilities/security/EnsureAccessForWebservers.sh
>      adt-database-scripts/providerscripts/utilities/remote/AccessDB.sh
>      adt-database-scripts/providerscripts/git/utilities/PlainDumpDatabase.sh
>      adt-database-scripts/providerscripts/database/singledb
>      adt-database-scripts/applicationdb
>      adt-database-scripts/applicationdb/InstallApplicationDB.sh

>      adt-build-machine-scripts/buildscripts/BuildAndDeployDBaaS.sh
