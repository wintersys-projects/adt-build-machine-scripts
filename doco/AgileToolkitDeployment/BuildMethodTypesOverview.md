#### BUILD STRATEGIES (ABRIDGED SUMMARY)

There are two basic build method types   

#### Expedited Build Type:

An expedited build type will involve the following steps to give you a high level overview  

1. You will start up a build machine for your chosen VPS provider using the following script [Build Machine](https://github.com/wintersys-projects/adt-build-machine-scripts/blob/main/templatedconfigurations/templateoverrides/OverrideScript.sh) as the userdata or cloud-init script for your build machine. The way you do that is you take a local copy of the script from the git repository and populate the following variables in it (which are at the top of the script).

>     BUILDMACHINE_USER,BUILDMACHINE_PASSWORD,BUILDMACHINE_SSH_PORT,LAPTOP_IP,SSH

Once these variables are suitably configured, you can copy the whole script to the cloud-init area of the machine you are provisioning as your build-machine.  

2. Once the build machine is provisioned you can SSH onto it at the SSH port that you set above. If you want to you can add your build machine to your cloudhosts firewalling system allowing only the SSH port through from your laptop IP address.

4. You should then issue the following command

>     sudo su

and enter the password "BUILDMACHINE_PASSWORD" that you configured in the user data script that you configured above 

4. You can then change directory to the adt-build-machine-scripts home directory which should be able to see by issuing a "ls" comamnd.
6. What you then need to do is go and configure your template. The template is located at

>     ${BUILD_HOME}/templatedconfigurations/templates/${CLOUDHOST}

You can choose template 1, 2 or 3 depending on whether you are deploying a virgin, baseline or temporal type of build. There's more information about how to configure your template in the tutorials section of this website and you should also refer to the specification.  

7. Once your template is configured you can run the script "ExpeditedAgileDeploymentToolkit.sh" by issuing the commands

>      cd /home/${BUILDMACHINE_USER}/adt-build-machine-scripts
>      /bin/sh ./ExpeditedAgileDeploymentToolkit.sh

The script will run and there will be some questions to answer. If you are an expert and you want to avoid answering questions you can use the parameters to the script to avoid the interaction:

>     CLOUDHOST, BUILDOS=, SELECTED_TEMPLATE, BUILD_IDENTIFIER

#### Hardcore Build Type:

During a **hardcore build**, you need to

1. On your local laptop clone the build client scripts for example (or from your fork):  

>     cd CLONE_DIR
>     /usr/bin/git clone https://github.com/wintersys-projects/adt-build-machine-scripts.git

2. Still on your local laptop set up your template, if you are using the hardcore build method you should be familiar with how to do that by now but if not you can refer to the tutorials

>     ${BUILD_HOME}/templatedconfigurations/templates/${CLOUDHOST} 

4. Return to the directory

>      CLONE_DIR/adt-build-machine-scripts

5. You now need to generate an override template that you will be using in the hardcore build method

>     /bin/sh ./helperscripts/GenerateOverrideTemplate.sh and answer the questions as it asks them  

6. You now need to generate a user data script which you can do:

>     /bin/sh ./helperscripts/GenerateHardcoreUserDataScript.sh and answer the questions as it asks them  

7. Then you need to use your user data script that you generated in step 6 in the as the cloud-init script of a VPS server with your chosen VPS provider

8. >     cd ${BUILD_HOME}/userdatascripts

and copy the script that has been generated and paste it into the user-data of a new VPS machine that will then become your build-machine.   
