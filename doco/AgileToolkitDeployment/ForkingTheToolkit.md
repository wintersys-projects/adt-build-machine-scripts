You might want to fork the toolkit at deployment time because, for example, you might want to have values set for the buildstyles.dat file directly in your fork of the repository when you are using template overrides method to deploy with. Just be open to the idea that there are scenarios where you will likely want to deploy from a fork rather than from the toolkit directly. In fact it is recommended best practice to deploy from your own fork.

**IMPORTANT: If you fork these repositories, and have them as public repositories, do not commit sensitive parameters into the templating configuration files without first making them private. Instead override them using the user data init script of your build server. To see how to override using the user data init script of your webserver (or stack script if you are on linode) plese refer to:**

[Override](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/templatedconfigurations/templateoverrides.md)

I keep a copy of the override script I am using on my laptop setup for the provider I am using and use it for userdata on my build machine as required. It is important to keep your bespoke override script secure because it will have access credentials to your infrastrucuture within it. Similarly, the VM which you are using as your build machine must also be kept secured because it also will have sensitive data on it. 

#### Forking the Agile Deployment Toolkit

You can build your deployments direct from the home account of the Agile Deployment toolkit in other words, the "wintersys-projects" user name.
However, you are most likely going to want to fork the repositories to your own account so that you can (for example) set template configuration parameters in the build client scripts.

The infrastructure repositories are located on github and so, to fork them, you will need a github account. I have a second github account called "adt-demos" where I keep my application sourcecode, for example, wordpress, that I deploy with the ADT. If I wanted to use this account as an example of what a 3rd party developer would do, I would do it as follows from the adt-demos github account.

1. Login as the "adt-demos" user on github
2. Find the original build-client, autoscaler, webserver and database repositories of the wintersys-projects account and fork them in turn.
3. I would need to make sure that whatever my build method, Full, Expedited or Hardcore I need to make sure that the following environment variables are set or updated:

**export APPLICATION_REPOSITORY_TOKEN=""  
export INFRASTRUCTURE_REPOSITORY_PROVIDER="github"  
export INFRASTRUCTURE_REPOSITORY_OWNER="wintersys-projects"  
export INFRASTRUCTURE_REPOSITORY_USERNAME="wintersys-projects"  
export INFRASTRUCTURE_REPOSITORY_PASSWORD="none"**  

and change them to:

**export APPLICATION_REPOSITORY_TOKEN="" (provided if needed)  
export INFRASTRUCTURE_REPOSITORY_PROVIDER="github"  
export INFRASTRUCTURE_REPOSITORY_OWNER="adt-demos"  
export INFRASTRUCTURE_REPOSITORY_USERNAME="adt-demos"  
export INFRASTRUCTURE_REPOSITORY_PASSWORD="none" (provided if needed)**

If you are running a full build process (not via templating) and setting all your parameters at build time, then, you can set your infrastructure repositories owner and name to, for example, "adt-demos" or whatever your username when you are prompted with the following questions:

----------------
##### So, please enter the provider with which the agile deployment toolkit is currently kept  
 We currently support: 1)BITBUCKET 2)GITHUB 3)GITLAB                                    
  
<enter 2 for GitHub>  

---------------
  
##### Please enter the username of the person who owns the Agile Infrastructure repos 

INFRASRUCTURE REPOSITORIES OWNER USERNAME:"  

<enter your GitHub username for the owner of your forked repositories, in my case, "adt-demos">  
  
------------------
  
##### Please enter **YOUR** credentials for the repo provider where the Agile Deployment Toolkit is stored
##### YOUR github USERNAME  

<enter your GitHub username as the username of the account in my case: "adt-demos">   
 
##### YOUR github PASSWORD (leave blank for no password if the infrastructure repos are public):  

<enter your GitHub password or blank if the repos are public (should be)>  

Once you have forked the repositories and updated your build script accordingly, you will be building and deploying off the fork (which you can modify to your hearts desire) rather than the original repositories (which you can't modify, obviously). 
