#!/bin/sh
###############################################################################################
# Description: This is the the expedited version of the top level build script for the 
# Agile Deployment Toolkit.
# Author Peter Winter
# Date 22/9/2020
##############################################################################################
#This is the Expedited Agile Deployment toolkit. It REQUIRES a configuration template which has ALL 
#the necessary parameters populated within it templates for each cloudhost are stored under 
#${BUILD_HOME}/templatedconfigurations/<yourcloudhost>/<yourcloudhost>[n].tmpl
#You can create a new template for selection by naming it 
#${BUILD_HOME}/templatedconfigurations/<yourcloudhost>/<yourcloudhost>[n+1].tmpl
#ALL of the configuration parameters must be sane and correct and without errors for a build to complete correctly
#There's a two ways you can run a build process the expedited way and the hardcore way. You can find out more about
#these in the wiki of this repository.
# License Agreement:
# This file is part of The Agile Deployment Toolkit.
# The Agile Deployment Toolkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# The Agile Deployment Toolkit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with The Agile Deployment Toolkit.  If not, see <http://www.gnu.org/licenses/>.
################################################################################################
###############################################################################################
#set -x

/bin/echo "set mouse=r
syntax on" > /root/.vimrc

if ( [ ! -d /root/logs ] )
then
        /bin/mkdir /root/logs
fi

exec 3>&1
out_file="initiallogging-out-`/bin/date | /bin/sed 's/ //g'`"
exec 1>>/root/logs/${out_file}
err_file="initiallogging-err-`/bin/date | /bin/sed 's/ //g'`"
exec 2>>/root/logs/${err_file}

status () {
        /bin/echo "$1" | /usr/bin/tee /dev/fd/3 2>/dev/null
}

status "The initial output log file is located at /root/logs/${out_file}"
status "The initial error log file is located at /root/logs/${err_file}"
status "Press <enter> to acknowledge"
if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
then
    read x
fi

if ( [ ! -f ./ExpeditedAgileDeploymentToolkit.sh ] )
then
         status "You can only run this script from its own directory"
         exit
fi

if ( [ "${1}" != "" ] && [ "${2}" != "" ] && [ "${3}" != "" ] && [ "${4}" != "" ] )
then
        HARDCORE="1"
        PARAMETERS="1"
        CLOUDHOST="$1"
        BUILDOS="$2"
        SELECTED_TEMPLATE="$3"
        BUILD_IDENTIFIER="$4"
        shift 4

        if ( [ "`/bin/echo "digitalocean exoscale linode vultr" | /bin/grep ${CLOUDHOST}`" = "" ] )
        then
                status "Unknown cloudhost passed as a parameter"
                exit
        fi
        if ( [ "`/bin/echo "ubuntu debian" | /bin/grep ${BUILDOS}`" = "" ] )
        then
                status "Unknown build os passed as a parameter"
                exit
        fi
        if ( [ "`/bin/echo "1 2 3" | /bin/grep ${SELECTED_TEMPLATE}`" = "" ] )
        then
                status "Unknown template passed as a parameter"
                exit
        fi
fi

export PUBLIC_KEY_NAME="AGILE_TOOLKIT_PUBLIC_KEY"

if ( [ "${HARDCORE}" = "1" ] )
then
        /bin/touch /root/HARDCORE
else
        if ( [ -f /root/HARDCORE ] )
        then
                /bin/rm /root/HARDCORE
        fi
fi

if ( [ "${PARAMETER}" = "1" ] )
then
        /bin/touch /root/PARAMETER
else
        if ( [ -f /root/PARAMETER ] )
        then
                /bin/rm /root/PARAMETER
        fi
fi

if ( [ "${BUILD_HOME}" = "" ] )
then
        export BUILD_HOME="`/bin/pwd`"
        /bin/echo ${BUILD_HOME} > /home/buildhome.dat
fi
export USER="`/usr/bin/whoami`"
/bin/chmod -R 700 ${BUILD_HOME}/.

export BUILD_CLIENT_IP="`${BUILD_HOME}/helperscripts/GetBuildClientIP.sh`"

if ( [ ! -d ${BUILD_HOME}/runtimedata ] )
then
        /bin/mkdir ${BUILD_HOME}/runtimedata 
fi

status "##################################################################################################################################"
status "WARNING, ONLY RUN THIS ON A DEDICATED MACHINE IT WILL INSTALL SOFTWARE AND MAKE MACHINE CHANGES THAT YOU MAY NOT WANT ON YOUR"
status "DAY TO DAY LAPTOP. YOU CAN RUN THIS FROM A DEDICATED VPS MACHINE OR POSSIBLY FROM A DEDICATED LINUX DISTRO FROM A PERSISTENT"
status "USB WHICH YOU CARRY AROUND AS YOUR DEPLOYMENT IMAGE"
status "##################################################################################################################################"
status "Build Machine IP Address has been found as: ${BUILD_CLIENT_IP}"
status "##################################################################################################################################"
status "PRESS ENTER KEY TO CONTINUE"
if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
then
        read x
fi

#export BUILDOS="`/bin/grep ^ID /etc/*-release | /usr/bin/awk -F'=' '{print $NF}' | /usr/bin/tr '[:upper:]' '[:lower:]' | /bin/egrep '(ubuntu|debian)'`"
export BUILDOS="`/bin/cat /etc/issue | /usr/bin/tr '[:upper:]' '[:lower:]' | /bin/egrep -o '(ubuntu|debian)'`"

${BUILD_HOME}/initscripts/InitialiseLongLastingConnection.sh
${BUILD_HOME}/installscripts/InstallCoreSoftware.sh ${BUILDOS}

if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
then
        ${BUILD_HOME}/selectionscripts/SelectCloudhost.sh ${BUILDOS}
        CLOUDHOST="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_CLOUDHOST`"
else
        ${BUILD_HOME}/installscripts/InstallCloudhostTools.sh ${CLOUDHOST} ${BUILDOS}
        /bin/echo "${CLOUDHOST}" > ${BUILD_HOME}/runtimedata/ACTIVE_CLOUDHOST
fi

${BUILD_HOME}/helperscripts/SetupEth1.sh ${CLOUDHOST}
${BUILD_HOME}/initscripts/InitialiseCompatibilityChecks.sh

status ""
status ""

${BUILD_HOME}/selectionscripts/SelectBuildIdentifier.sh
BUILD_IDENTIFIER="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER`"

if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs ] )
then
        /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs
fi

out_file="build_out-`/bin/date | /bin/sed 's/ //g'`"
exec 1>>${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${out_file}
err_file="build_err-`/bin/date | /bin/sed 's/ //g'`"
exec 2>>${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${err_file}

status "The main output log file is located at ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${out_file}"
status "The main error log file is located at ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${err_file}"
status "Press <enter> to acknowledge"
if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
then
    read x
fi

${BUILD_HOME}/templatedconfigurations/ConfigureTemplate.sh ${CLOUDHOST} ${BUILD_IDENTIFIER} ${SELECTED_TEMPLATE}
template_name="`/bin/cat ${BUILD_HOME}/runtimedata/current_template_name`"
. ${template_name}

#Take care of special case when a space is input in the website display name
export WEBSITE_DISPLAY_NAME="`/bin/echo ${WEBSITE_DISPLAY_NAME} | /bin/sed "s/'//g" | /bin/sed 's/ /_/g'`"

${BUILD_HOME}/initscripts/InitialiseDirectoryStructure.sh ${CLOUDHOST} ${BUILD_IDENTIFIER} 

/usr/bin/env > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/build_environment

${BUILD_HOME}/initscripts/InitialiseCloudhostConfig.sh
${BUILD_HOME}/selectionscripts/SelectSMTPSettings.sh
${BUILD_HOME}/initscripts/InitialiseServerUserCredentials.sh
${BUILD_HOME}/initscripts/InitialiseDatastoreConfig.sh
${BUILD_HOME}/initscripts/PreFlightChecks.sh
#. ${BUILD_HOME}/providerscripts/datastore/PersistBuildClientIP.sh

if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
then
        status "Checking for your build machine VPC network"
        if ( [ "`${BUILD_HOME}/providerscripts/server/CheckBuildMachineVPC.sh ${CLOUDHOST} ${BUILD_CLIENT_IP}`" = "" ] )
        then
                status "It looks like the build machine (${server_name}) is not attached to a VPC when BUILD_MACHINE_VPC=1"
                status "Will have to exit (change BUILD_MACHINE_VPC if necessary in your template)"
                exit
        else
                status "Have successfully verified the presence of a usable VPC network on your build machine"
        fi
fi

if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" = "0" ] || [ "`${BUILD_HOME}/helperscripts/IsParameterBuild.sh`" = "1" ] )
then
        #For anything other than a virgin build, we won't know what application type we are, so interrogate to find out
        if ( [ "${BUILD_CHOICE}" -ne "0"  ] )
        then
                status ""
                status ""
                status "#############################################################"
                status "Interrogating to see what Application you are running, if any"
                status "#############################################################"
                ${BUILD_HOME}/providerscripts/application/InterrogateApplicationType.sh
                ${BUILD_HOME}/providerscripts/application/CheckForAssetsOverwrite.sh
                
                status ""
                status "#############################################################"
                status "Initialising assets datastore, this may or may not take a while"
                status "#############################################################"
                ${BUILD_HOME}/initscripts/InitialiseAssetDatastore.sh
        fi
fi

#if ( [ "${AUTOSCALER_IMAGE_ID}" = "" ] && [ "${WEBSERVER_IMAGE_ID}" = "" ] && [ "${DATABASE_IMAGE_ID}" = "" ] )
#then
         ${BUILD_HOME}/providerscripts/security/firewall/SetupNativeFirewall.sh "1"
#fi

#if ( [ "`/bin/echo ${BUILD_IDENTIFIER} | /bin/grep -o "^s-"`" = "" ] )
#then
         ${BUILD_HOME}/initscripts/InitialiseSecurityKeys.sh
#fi

PUBLIC_KEY_ID="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/PUBLICKEYID`"

#If this build machine doesn't have a VPC (the user should have created one when they spun it up from the GUI) then try
#To create and add one. This will most likely drop the user's ssh connection to their build machine and so they will have
#to reconnect but maybe that will encourage them to add the next build machine to a the VPC from the GUI system of their provider

if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
then
        /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}
        /bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/VPC-ACTIVE
else
        if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/VPC-ACTIVE ] )
        then
                /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/VPC-ACTIVE
        fi
fi

#Set a timestamp so we can tell how long the build took. It various considerably by cloudhost provider.
start=`/bin/date +%s`

#If we have anything to say here, on an application by application basis before the build really begins we put it in this
#script
${BUILD_HOME}/processingscripts/PreProcessingMessages.sh
${BUILD_HOME}/initscripts/InitialiseScalingProfile.sh
${BUILD_HOME}/initscripts/InitialiseKeystore.sh
${BUILD_HOME}/initscripts/InitialiseDatabaseService.sh
if ( [ "${AUTHENTICATION_SERVER}" = "1" ] )
then
        WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
        auth_website_url="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/[^.]*./auth./'`"
        ${BUILD_HOME}/initscripts/InitialiseNewSSLCertificate.sh ${auth_website_url}
fi
${BUILD_HOME}/initscripts/InitialiseNewSSLCertificate.sh
${BUILD_HOME}/initscripts/InitialiseCloudInit.sh

status "Are you happy for the build to proceed? Pressing <enter> now will begin the process of building your server machines"
read x

# I think the usual phrase is, 'we are all set'. So, tell the user we are starting the build proper.
status ""
status ""
status ""
status "`/usr/bin/banner "Starting......"`" 
status "##############################################################################################"
status "OK, about to begin building your deployment........"
status "##############################################################################################"
status ""
status ""
status ""

#This option will perform a standard build process (autoscaler, webserver, database)
if ( [ "`/bin/grep "^BUILDCHAINTYPE:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "standard" ] )
then
         ${BUILD_HOME}/buildscripts/PerformStandardBuildChain.sh
fi
#This option will only build a webserver (which you might want if you are building a static site)
if ( [ "`/bin/grep "^BUILDCHAINTYPE:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "webserver" ] )
then
         ${BUILD_HOME}/buildscripts/BuildWebserver.sh
fi
#This option will only build a database if you want an easily deployed and secured database to use)
if ( [ "`/bin/grep "^BUILDCHAINTYPE:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $NF}'`" = "database" ] )
then
         ${BUILD_HOME}/buildscripts/BuildDatabase.sh
fi

${BUILD_HOME}/providerscripts/security/firewall/TightenDBaaSFirewall.sh

#if ( [ "${AUTOSCALER_IMAGE_ID}" = "" ] && [ "${WEBSERVER_IMAGE_ID}" = "" ] && [ "${DATABASE_IMAGE_ID}" = "" ] )
#then
#         ${BUILD_HOME}/providerscripts/security/firewall/SetupNativeFirewall.sh "0"
#else
#         ${BUILD_HOME}/providerscripts/security/firewall/OnlyAddMachinesToFirewall.sh
#fi
#If we have any messages to put out to the user post build, we add them to this script
${BUILD_HOME}/processingscripts/PostProcessingMessages.sh

#We inform the users of their credentials. Sometimes, depending on the application, the user needs to know more or less
#Some applications we can configure for use behind the scenes, other times, the user has to do some stuff in the gui to
#get to the point where the application can be used. In the later case, any additional information will be added here.
 

status ""
status "###################################################################################################################"
status "IMPORTANT, THE USERNAME FOR YOUR SERVERS IS: ${SERVER_USER}"
status "THE PASSWORD FOR YOUR SERVERS IS: ${SERVER_USER_PASSWORD}"
status "CONSIDER ANY COMPROMISE OF THESE CREDENTIALS AS POTENTIALLY GIVING ROOT ACCESS TO YOUR SERVERS. KEEP THEM VERY SECURE"
status "A COPY OF THESE CREDENTIALS IS STORED IN:"
status "SERVER USERNAME :  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER"
status "SERVER PASSWORD :  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD"
status "###################################################################################################################"
status "That should be your application built and online."
status "OK, have fun with it...."

#Output how long the build took
end=`/bin/date +%s`
runtime="`/usr/bin/expr ${end} - ${start}`"
status "This script completed at `/bin/date` and took `/bin/date -u -d @${runtime} +\"%T\"` to complete"

${BUILD_HOME}/providerscripts/security/firewall/SetupNativeFirewall.sh "0"

/usr/sbin/shutdown -r now

