To use this toolkit productively its necessary to understand the intended workflows. Here is an overview of how I would expect the workflows to operate in common scenarios.

#### Building and deploying your own custom application

1. The deployment in development mode of a virgin application such as joomla by configuring template 1 and running a build either using the expedited or the hardcore method
2. The customisation of the the virgin application (installing modules/components and plugins) that you have deployed in 1 until it meets your business need
3. Making a baseline of your completed application to a (private) repository by running on the build machine the

>     for the website baseline: ${BUILD_HOME}/helperscripts/PerformWebsiteBaseline.sh

>     for the website baseline: ${BUILD_HOME}/helperscripts/PerformDatabaseBaseline.sh

 4. Once you have a baselined application (once you make very sure that the database/webroot) do not contain any sensitive information you can either share that baseline with 3rd parties who have a similar business need or you can use it yourself. It is essential that you are very sure that your baselined application repositories do not contain any sensitive information before you make them public of you share them. If you aren't sure about this I would advise you not to share them.

5. If your intention is to use your new application in a production scenario for yourself then you will need to generate temporal backups of your application to preferably to both git repositories and your datastore as well. The way you generate your temporal backups is to run the following scripts on your build machine:

>     for the website temporal backup:  ${BUILD_HOME}/helperscripts/PerformWebsiteBackup.sh
>     for the database temporal backup: ${BUILD_HOME}/helperscripts/PerformDatabaseBackup.sh

6. You can then take your development servers offline and deploy in production mode by customising a template 3 to your needs complete with autoscaler provisioning and so on.




   
