**IMPORTANT: If you fork these repositories, and have them as public repositories, do not enter and commit sensitive parameters into the templating configruation files. Either make sure you are not committing sensitive information or override them using the user data init script and the hardcore build method of your build server. To see how to override using the user data init script of your webserver (or stack script if you are on linode) plese refer to:**

[Override](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/master/templatedconfigurations/templateoverrides.md)

I keep a copy of the override script I am using on my laptop setup for the provider I am using and use it for userdata on my build client as required. It is important to keep your bespoke override script secure because it will have access credentials to your infrastrucuture within it. Similarly, the VM which you are using as your build machine must also be kept secured because it also will have sensitive data on it. 

#### Forking the Agile Deployment Toolkit

You can build your deployments direct from the home github account of the Agile Deployment toolkit in other words, the "wintersys-projects" user name.
However, you are most likely going to want to fork the repositories to your own account so that you can (for example) set template configuration parameters in the build client scripts in your **PRIVATE** forked repository.

The infrastructure repositories are located on github and so, to fork them, you will need a github account. I have a second github account called "adt-demos" where I keep my application sourcecode, for example, Wordpress, that I deploy with the ADT. If I wanted to use this account as an example 3rd party (in relation to the wintersys-projects account) developer, I would do it as follows.

1. Login as the "adt-demos" user on github
2. Find the build-client, autoscaler, webserver and database repositories of the wintersys-projects account and fork them.
3. If my fork is public, I would then edit (or override in my build server init script) the following template parameters, if my fork is private I can change the templates directly. You do have to be cautious with this because if you are storing credentials like Personal Access Tokens to your cloudhost in your private repositories if you accidentally make the repository public, then you can rest assured that bad actors will detect your lapse quick smart and the security of your clouhost acccount will be compromised. The ultimate recommendation is not to store your templates in with any repository provider but, rather, keep copies of your templates on your build machine or even your laptop and fire up builds from these templates as you need to. 

If my fork is under my adt-demos account on github then I will need to change the following:

export APPLICATION_REPOSITORY_TOKEN=""  
export INFRASTRUCTURE_REPOSITORY_PROVIDER="github"  
export INFRASTRUCTURE_REPOSITORY_OWNER="wintersys-projects"  
export INFRASTRUCTURE_REPOSITORY_USERNAME="wintersys-projects"  
export INFRASTRUCTURE_REPOSITORY_PASSWORD="none"  

and change them to:

export APPLICATION_REPOSITORY_TOKEN=""  
export INFRASTRUCTURE_REPOSITORY_PROVIDER="github"  
export INFRASTRUCTURE_REPOSITORY_OWNER="adt-demos"  
export INFRASTRUCTURE_REPOSITORY_USERNAME="adt-demos"  
export INFRASTRUCTURE_REPOSITORY_PASSWORD="none"  

If you are running a full build process (not via templating) and setting all your parameters at build time, then, you can set your infrastructure repositories owner and name to, for example, "adt-demos" or whatever your username when you are prompted with the following questions:

----------------
##### So, please enter the provider with which the agile deployment toolkit is currently kept  
 We currently support: 1)BITBUCKET 2)GITHUB 3)GITLAB                                    
  
<enter 3 for github>  

---------------
  
##### Please enter the username of the person who owns the Agile Infrastructure repos 

INFRASRUCTURE REPOSITORIES OWNER USERNAME:"  

<enter your github username for the owner of your forked repositories, in my case, "adt-demos">  
  
------------------
  
##### Please enter **YOUR** credentials for the repo provider where the Agile Deployment Toolkit is stored
##### YOUR github USERNAME  

<enter your github username as the username of the account in my case: "adt-demos">   
 
##### YOUR github PASSWORD (leave blank for no password if the infrastructure repos are public):  

<enter your github password or blank if the repos are public (should be)>  
