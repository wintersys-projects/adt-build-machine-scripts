# README #

**DO NOT DEPLOY THIS ON YOUR DAY TO DAY LINUX LAPTOP AS IT WILL MAKE CHANGES TO THE MACHINE'S CONFIGURATION**

**If you are interested in self managed server systems this tool could make your life easier; it's a custom solution for server deployment management**

##### EXPLANATORY WIKI: [WIKI](https://github.com/wintersys-projects/adt-build-machine-scripts/wiki)
##### DETAILED USAGE TUTORIALS: [TUTORIALS](https://github.com/wintersys-projects/adt-build-machine-scripts/wiki/Tutorials)
##### DETAILED DOCUMENTATION FOR DEPLOYERS: [DEPLOYMENT DOCO](./doco/AgileToolkitDeployment)
##### DETAILED DOCUMENTATION FOR DEVELOPERS: [DEVELOPMENT DOCO](./doco/AgileToolkitDevelopment)
##### THE SPECIFICATION: [SPECIFICATION](./templatedconfigurations/specification.md)
##### QUICK START DEMOS: [QUICK START DEMOS](https://github.com/wintersys-projects/adt-build-machine-scripts/wiki/Quick-Start-Demo)

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

A DMS, like this one, is a powertool for helping you deploy your servers using well tested and secured processes. Its power is that it can be extended easily and is very similar to a CMS system but for deployment rather than content. The ultimate objective is to make it possible to have a JAD (Joomla Applications Directory) as well as a JED (Joomla Extensions Directory) where whole applications have been built (by expert developers to meet a particular business need) and then the whole application is installed (complete with all necessary extensions and plugins already configured) ready for use "off the shelf" to meet a particular business case. Very simple examples of this are shown in the "Quick Start Demos" above. A DMS does require learning just like a CMS does but would you want to go back to coding in basic HTML once you have discovered CMS systems, probably not and so it is with server deployments for people who want to roll their own server solutions. Application developers using this toolkit should be able to produce high quality COTS (Commerical Off the Shelf) web applications using their CMS of choice.

-----------------------------------

#### SUPPORT NEEDED

**This toolkit has a lot of combined configurations and if for example one of the CMS systems changed how the sourcecode for it is downloaded or downloadable, that would break the installation of that CMS. For this reason its important to get feedback from people using the toolkit to discover if there are any breaks in how it is functioning. Its impossible as a single developer to monitor all configuration interplays and so the greatest help that a user of this software can be is if they report back if and when they find any breaks that have been introduced by 3rd party process changes that it depends on.** 


------------------------

#### THE CORE:

With the core of the Agile Deployment Toolkit, it will make use of a set of services and providers. I elected to use Digital Ocean, Exoscale, Linode, Vultr and AWS to deploy on or as deployment options, but, the toolkit is designed to be forked and extended to support other providers. The system is fully configurable by you and if you wish to change default configurations that are provided for, for example, Apache, NGINX or MariaDB, then you will need to fork the respoitories, alter your copy of the scripts and have them deploy according to your configuration requirements. A useful thing to be aware of if you are changing these scripts is you can check them syntactically with using "**/bin/bash -n <script.sh>**" before you redeploy only to find you had a syntax error during deployment. 

The full set of services that are supported by the core of the toolkit and which you can extend in your forks is:

1. For VPS services, one of - Digital Ocean, Linode, Exoscale, Vultr, AWS
2. For Email services, one of - Amazon SES, Mailjet or Sendpulse
3. For Git based services, one of - Bitbucket, Github or Gitlab
4. For DNS services, one of - Cloudflare, Digital Ocean, Exoscale, Linode, Vultr (note, Cloudflare has additional security features which are absent from naked dns services which is why it is probably best practice to use Cloudflare even if there is some extra hassle to set it up which you can find out about here: [Cloudflare DNS](https://community.cloudflare.com/t/step-1-adding-your-domain-to-cloudflare/64309))
5. For object store services, one of - Digital Ocean Spaces, Exoscale Object Store, Linode Object Store, Vultr Object Store or Amazon S3
6. I chose these VPS providers to deploy with because they have managed database offerings, if you wish to make a production ready deployment with this toolkit it is recommended that you make your deloyment using their managed database offerings. For development deployments, you can use the custom database install. 

--------------------------------

#### BUILD METHODS OVERVIEW

There are three types of build method you can employ to get a functioning application. These are the hardcore build, the expedited build and the full build. There's pluses and minuses to all of them. The hardcore build and the expedited build you need to understand how the toolkit is working by studying the spec to find out what each parameter of your startup script is doing and making direct template modifications. The Expedited build shortcuts the full build process such that you have to deploy (and secure) a build machine VPS and then, clone the toolkit and provide a limited set of parameters to the **ExpeditedAgileDeploymenToolkit.sh** script. The final way is the full build where you will need to understand the toolkit the least but it means that you will be prompted for every parameter that the toolkit needs. For me I tend to use the expedited method, with reference to the [specification](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/templatedconfigurations/specification.md) of course. 

You need a dedicated build machine in the cloud **DO NOT DEPLOY THIS ON YOUR DAY TO DAY LAPTOP AS IT WILL MAKE CHANGES TO THE MACHINE'S CONFIGURATION** which you might not want.  If you don't want to pay for a dedicated build machine in the cloud, you could setup a dedicated USB image of Ubuntu or Debian which has persistent storage and use your local machine for running your builds directly from the usb stick. It is advised that you use an OS image dedicated for this process. 
I personally use [Linux Mint](https://linuxmint.com/) if I want to run my build processes from a USB on my local laptop. If you want to use a USB to run your builds from you will need to make sure that it has persistence or persistent storage active. 

-----

#### THE CONCLUSION

A DMS system such as this one can certainly speed your server deployments. It does require skill, and therefore learning to use. I have to leave this up to divine providence either other developers will want to take this forward and extend it, or, its operational footprint will stay as it is. My hope of course, is that there's interest from other developers in extending what has been done so far. As I was developing this timewise I would say that 30% of the effort was on developing it and 70% of the effort was on testing its function. That's why this toolkit will stand or fall on how earnestly it is used because with earnest use it can remain well maintained as issues are reported as they arise.   


