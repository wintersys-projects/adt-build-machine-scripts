# README #

**DO NOT DEPLOY THIS ON YOUR DAY TO DAY LINUX LAPTOP AS IT WILL MAKE CHANGES TO THE MACHINE'S CONFIGURATION**

**If you are interested in self managed server systems this tool could make your life easier; it's a custom solution for server deployment management**

##### EXPLANATORY WIKI: [WIKI](https://github.com/wintersys-projects/adt-build-machine-scripts/wiki)
##### DETAILED USAGE TUTORIALS: [TUTORIALS](https://github.com/wintersys-projects/adt-build-machine-scripts/wiki/Tutorials)
##### DETAILED DOCUMENTATION FOR DEPLOYERS: [DEPLOYMENT DOCO](./doco/AgileToolkitDeployment)
##### DETAILED DOCUMENTATION FOR DEVELOPERS: [DEVELOPMENT DOCO](./doco/AgileToolkitDevelopment)
##### OPERATIONS DOCUMENTATION FOR DEPLOYERS: [OPERATIONS DOCO](./doco/AgileToolkitOperations)
##### THE SPECIFICATION: [SPECIFICATION](./templatedconfigurations/specification.md)
##### QUICK SPECIFICATION: [QUICK SPECIFICATION](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/main/templatedconfigurations/quick_specification.dat)

There are four repositories associated with this toolkit, this one, and the one's listed below. 

##### [Agile Infrastructure Autoscaler Scripts](https://github.com/wintersys-projects/adt-autoscaler-scripts)  
##### [Agile Infrastructure Webserver Scripts](https://github.com/wintersys-projects/adt-webserver-scripts)
##### [Agile Infrastructure Database Scripts](https://github.com/wintersys-projects/adt-database-scripts) 

------------------------

There's a lot of different interactions and dependencies with thus toolkit and 3rd party changes might introduce breakages. If you find any such breaks, reporting what you have found as an issue on this repository will really help me. Thanks.

-----------------------------------
#### CONCISE SUMMARY

If you want to run your own custom servers with full configuration access or you are a student wishing to learn about server configuration for your CMS systems, this script can help. This is a powertool and its not unlike learning a CMS but for deployment.

----------------------------------

#### WHAT IS A DMS (Deployment Management System)

A DMS, like this one, is a powertool for helping you deploy your servers using well tested and secured processes. Its power is that it can be extended easily and is very similar to a CMS system but for deployment rather than content. The ultimate objective is to make it possible to have a JAD (Joomla Applications Directory) as well as a JED (Joomla Extensions Directory) where whole applications have been built (by expert developers to meet a particular business need) and then the whole application is installed (complete with all necessary extensions and plugins already configured) ready for use "off the shelf" to meet a particular business case. Very simple examples of this are shown in the "Quick Start Demos" above. A DMS does require learning just like a CMS does but would you want to go back to coding in basic HTML once you have discovered CMS systems, probably not and so it is with server deployments for people who want to roll their own server solutions. Application developers using this toolkit should be able to produce high quality COTS (Commerical Off The Shelf) web applications using their CMS of choice.

-----------------------------------

#### SUPPORT NEEDED

**This toolkit has a lot of combined configurations and if for example one of the CMS systems changed how the sourcecode for it is downloaded or downloadable, that would break the installation of that CMS. For this reason its important to get feedback from people using the toolkit to discover if there are any breaks in how it is functioning. Its impossible as a single developer to monitor all configuration interplays and so the greatest help that a user of this software can be is if they report back if and when they find any breaks that have been introduced by 3rd party process changes that it depends on.** 


------------------------

#### THE CORE:

With the core of the Agile Deployment Toolkit, it will make use of a set of services and providers. I elected to use Digital Ocean, Exoscale, Linode and Vultr to deploy on or as deployment options, but, the toolkit is designed to be forked and extended to support other providers. The system is fully configurable by you and if you wish to change default configurations that are provided for, for example, Apache, NGINX or MariaDB, then you will need to fork the respoitories, alter your copy of the scripts and have them deploy according to your configuration requirements. A useful thing to be aware of if you are changing these scripts is you can check them syntactically with using <br><br>      "**/bin/sh -n <script.sh>**" <br><br> before you redeploy only to find you had a syntax error during deployment. 

The full set of services that are supported by the core of the toolkit and which you can extend in your forks is:

1. For VPS services, one of - Digital Ocean, Linode, Exoscale or Vultr
2. For Email services, one of - Amazon SES, Mailjet or Sendpulse
3. For Git based services, one of - Bitbucket, Github or Gitlab
4. For DNS services, one of - Cloudflare, Digital Ocean, Exoscale, Linode, Vultr (note, Cloudflare has additional security features which are absent from naked dns services which is why it is probably best practice to use Cloudflare even if there is some extra hassle to set it up which you can find out about here: [Cloudflare DNS](https://community.cloudflare.com/t/step-1-adding-your-domain-to-cloudflare/64309))
5. For object store services, one of - Digital Ocean Spaces, Exoscale Object Store, Linode Object Store, Vultr Object Store
6. I chose these VPS providers to deploy with because they have managed database offerings, if you wish to make a production ready deployment with this toolkit it is recommended that you make your deloyment using their managed database offerings. For development deployments, you can use the custom database install. 

--------------------------------

#### BUILD METHODS OVERVIEW

There are two types of build method you can employ to get a functioning application. These is the hardcore build (only use once you are more experienced with this tool), and the expedited build method. To use the expedited build method you basically have to configure a template with your sane custom varibles and then run the **ExpeditedAgileDeploymenToolkit.sh** script. To use the hardcore build method you need to generate a userdata script on your laptop using the helperscripts of this repository and then paste your full userdata script into the cloud-init area of a newly provisioned VPS server with your chosen cloudhost provider. There might be situations in which you want to use the hardcore build method and there might be situations when you want to use the expedited build method. In truth it is expected that most of the time you will want to use the expedited build method. In both cases you need to have a thorough understanding of the specification which you can reference [here](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/templatedconfigurations/specification.md) of course. 

For an overview of the core steps involoved in an expedited or hardocore build, please look [here](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/main/doco/AgileToolkitDeployment/BuildStrategiesOverview.md))

-----

#### THE CONCLUSION

A DMS system such as this one can certainly speed your server deployments. It does require skill, and therefore learning to use. I have to leave this up to divine providence either other developers will want to take this forward and extend it, or, its operational footprint will stay as it is. My hope of course, is that there's interest from other developers in extending what has been done so far. As I was developing this timewise I would say that 30% of the effort was on developing it and 70% of the effort was on testing its function. That's why this toolkit will stand or fall on how earnestly it is used because with earnest use it can remain well maintained as issues are reported as they arise.   


