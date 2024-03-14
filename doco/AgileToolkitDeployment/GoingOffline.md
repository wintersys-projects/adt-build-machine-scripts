If you are running a website and you want to take it completely offline then you need to follow these steps to prevent possible dataloss:  

Shutdown procedure

1. Put CMS into maintenance mode following [this](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/doco/AgileToolkitDeployment/ApplicationConfigurationUpdate.md) procedure
2. Put infrastructure into maintenance mode by follwing [this](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/helperscripts/AdjustScaling.sh) procedure
3. Run backup hourly periodicity by running [this](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/helperscripts/PerformDatabaseBackup.sh) and [this](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/helperscripts/PerformWebsiteBackup.sh)
4. Shutdown and destroy machines by running [this](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/helperscripts/ShutdownInfrastructure.sh)
