#!/bin/sh
###############################################################################################
# Description: This is the main script that is called every time there is a build happening using
# the Agile Deployment Toolkit
# Author Peter Winter
# Date 22/9/2020
##############################################################################################
# This is the Expedited Agile Deployment toolkit. It REQUIRES a configuration template which has ALL 
# the necessary parameters populated within it templates for each cloudhost are stored under 
# ${BUILD_HOME}/templatedconfigurations/<yourcloudhost>/<yourcloudhost>[n].tmpl
# ALL of the configuration parameters must be sane and correct and without errors for a build to complete correctly
# There's a two ways you can run a build process the expedited way and the hardcore way. You can find out more about
# these in the wiki of this repository.
# This program can be called from cloud-init (a HARDCORE build) or started from the command line (an EXPEDITED build).
# You can pass a small set of parameters from the command line or enter then interactively. 
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

end_it_all() {
	cwd="`/usr/bin/pwd`"

	if ( [ -f /tmp/END_IT_ALL ] )
	then
		/bin/rm /tmp/END_IT_ALL
	fi

	if ( [ -f /tmp/END_IT_ALL_USER ] )
	then
		/bin/rm /tmp/END_IT_ALL_USER
	fi

	while ( [ 1 ] )
	do
		/bin/sleep 1
		if ( [ -f /tmp/END_IT_ALL ] )
		then
			cd ${cwd}
			/bin/echo ""
			/bin/echo "----------------------------------------------------------"
			/bin/echo "FAILURE INDUCED TERMINATION PLEASE CHECK THE ERROR LOGS"
			/bin/echo "----------------------------------------------------------"
			/bin/echo ""
		elif ( [ -f /tmp/END_IT_ALL_USER ] )
		then
			cd ${cwd}
			/bin/echo ""
			/bin/echo "----------------------------------------------------------"
			/bin/echo "USER INITIATED TERMINATION ... please wait"
			/bin/echo "----------------------------------------------------------"
			/bin/echo ""
		fi

		if ( [ -f /tmp/END_IT_ALL ] || [ -f /tmp/END_IT_ALL_USER ] )
		then
			if ( [ -f /tmp/END_IT_ALL ] )
			then
				/bin/rm /tmp/END_IT_ALL
			fi

			if ( [ -f /tmp/END_IT_ALL_USER ] )
			then
				/bin/rm /tmp/END_IT_ALL_USER
			fi
			/usr/bin/kill 0
    	fi
	done
}

end_it_all  &

trap '/bin/sleep 2; /usr/bin/pwd' EXIT
trap '/bin/touch /tmp/END_IT_ALL_USER; exit' INT

#Set the hostname of the build machine
if ( [ "`/usr/bin/hostname`" != "build-machine" ] )
then
	/bin/sed 's/^127.0.0.1.*/127.0.0.1       build-machine/' /etc/hosts
	/usr/bin/hostnamectl set-hostname build-machine
fi

#Set up the intial logging  output. This is where the logging messages will be stored when they occur before
#the main logging configuration has been set up. There is an output log for stdout and and error log for stderr
if ( [ ! -d /root/logs ] )
then
	/bin/mkdir /root/logs
fi

exec 3>&1
out_file="initiallogging-out-`/bin/date | /bin/sed 's/ //g'`"
exec 1>>/root/logs/${out_file}
err_file="initiallogging-err-`/bin/date | /bin/sed 's/ //g'`"
exec 2>>/root/logs/${err_file}
status_file="initiallogging-status-`/bin/date | /bin/sed 's/ //g'`"
exec 4>>/root/logs/${status_file}

if ( [ "`/usr/bin/find /root/logs -name "*build*" -type f`" != "" ] )
then
	if ( [ ! -d /root/logs/archive ] )
	then
		/bin/mkdir -p /root/logs/archive
	fi
	/bin/mv /root/logs/*build* /root/logs/archive
fi

#Set up a status function that can be called to log the status messages
status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

# It is required that this script is only run directly from the directory it is installed in
if ( [ ! -f ./ExpeditedAgileDeploymentToolkit.sh ] )
then
	status "You can only run this script from its own directory"
	exit
else
	BUILD_HOME="`/usr/bin/pwd`"
fi

# If parametes have been set from the command line then populate the respective variables
# which means we don't have to obtain them interactively
# ./ExpeditedAgileDeploymentToolkit.sh <cloudhost> <buildos> <selected template> <build identifier>
if ( [ "${1}" != "" ] && [ "${2}" != "" ] && [ "${3}" != "" ] && [ "${4}" != "" ] )
then
	HARDCORE="1"
	PARAMETERS="1"
	CLOUDHOST="$1"
	BUILDOS="$2"
	SELECTED_TEMPLATE="$3"
	BUILD_IDENTIFIER="$4"
	shift 4

	# Do some basic sanity checks on any parameters that have been given from the command line
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

# Set a name for the PUBLIC KEY which can be used everywhere
export PUBLIC_KEY_NAME="AGILE_TOOLKIT_PUBLIC_KEY"

# Set a persistent way of letting us know if we are a HARDCORE build or not
if ( [ "${HARDCORE}" = "1" ] )
then
	/bin/touch /root/HARDCORE
else
	if ( [ -f /root/HARDCORE ] )
	then
		/bin/rm /root/HARDCORE
	fi
fi

# Set a persistent way of letting us know if we are a PARAMETER build or not
if ( [ "${PARAMETERS}" = "1" ] )
then
	/bin/touch /root/PARAMETER
else
	if ( [ -f /root/PARAMETER ] )
	then
		/bin/rm /root/PARAMETER
	fi
fi

#Tell the user where the intial log files are so they know where to look if they need to
status "The initial output log file is located at /root/logs/${out_file}"
status "The initial error log file is located at /root/logs/${err_file}"

if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
then
	status "Press <enter> to acknowledge"
	read x
fi

# Set BUILD_HOME which is the directory where the Agile Deployment Toolkit is
# Also set a persistent place on the file system where the value of BUILD_HOME is stored 
# for reference anywhere
if ( [ "${BUILD_HOME}" = "" ] )
then
	export BUILD_HOME="`/bin/pwd`"
	/bin/echo ${BUILD_HOME} > /home/buildhome.dat
fi

# Set the USER value based on what "whoami" tells us
export USER="`/usr/bin/whoami`"
/bin/chmod -R 700 ${BUILD_HOME}/.

#Get the IP value of the build machine that the Agile Deployment Toolkit is running on
export BUILD_MACHINE_IP="`${BUILD_HOME}/helperscripts/GetBuildMachineIP.sh`"

# Set up the runtimedata directory this is where data and information will be stored that is generated at runtime
if ( [ ! -d ${BUILD_HOME}/runtimedata ] )
then
	/bin/mkdir ${BUILD_HOME}/runtimedata 
fi

#Reminid the user that we likely will be making some changes to whatever machine they are running this script on so if it is their
#home laptop they need to be aware
status "##################################################################################################################################"
status "WARNING, ONLY RUN THIS ON A DEDICATED MACHINE IT WILL INSTALL SOFTWARE AND MAKE MACHINE CHANGES THAT YOU MAY NOT WANT ON YOUR"
status "DAY TO DAY LAPTOP. YOU CAN RUN THIS FROM A DEDICATED VPS MACHINE OR POSSIBLY FROM A DEDICATED LINUX DISTRO FROM A PERSISTENT"
status "USB WHICH YOU CARRY AROUND AS YOUR DEPLOYMENT IMAGE"
status "##################################################################################################################################"
status "Build Machine IP Address has been found as: ${BUILD_MACHINE_IP}"
status "##################################################################################################################################"
status "PRESS ENTER KEY TO CONTINUE"

if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
then
	read x
fi

# Make sure that we know which OS this machine is (currently debian or ubuntu
if ( [ "${BUILDOS}" = "" ] )
then
	export BUILDOS="`/bin/cat /etc/issue | /usr/bin/tr '[:upper:]' '[:lower:]' | /bin/egrep -o '(ubuntu|debian)'`"
fi

# Make sure that ssh connections to the servers we will build are long lasting. A build can take several minutes over SSH and a short lasting
# connection might drop during  the build proccess
${BUILD_HOME}/initscripts/InitialiseLongLastingConnection.sh

#Set up anything that we would like to set for the code editors we are using
${BUILD_HOME}/initscripts/InitialiseEditor.sh

# There is a core set of software that is needed by this toolkit. We install the software on the intial build and update the software
# if its been more than 1 day since this script was run on the current machine


${BUILD_HOME}/installscripts/InstallCoreSoftware.sh ${BUILDOS} 

software_updated="0"

if ( [ "`/usr/bin/find ~/UPDATEDSOFTWARE -mmin -20 -print`" != "" ] )
then
	software_updated="1"
fi

# Find out which cloudhost we are deploying to. If we are a HARDCORE build then the CLOUDHOST variable value is already in our
# environment if not we ask the user for it interactively. The value of $CLOUDHOST is persistently stored on the filesystem
# for reference from anywhere

if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
then
	${BUILD_HOME}/selectionscripts/SelectCloudhost.sh ${BUILDOS}
	CLOUDHOST="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_CLOUDHOST`"
else
	${BUILD_HOME}/installscripts/InstallCloudhostTools.sh ${CLOUDHOST} ${BUILDOS} 
	/bin/echo "${CLOUDHOST}" > ${BUILD_HOME}/runtimedata/ACTIVE_CLOUDHOST
fi

# Certain providers need their Eth1 interface configured for private networking to be possible
${BUILD_HOME}/initscripts/InitialisePrivateNetworking.sh ${CLOUDHOST}

#Run some arbitrary compatibility checks
${BUILD_HOME}/initscripts/InitialiseCompatibilityChecks.sh

status ""
status ""

# Find out what the BUILD_IDENTIFER is to be. The BUILD_IDENTIFIER will be written to the filesystem for persistent reference
# in the file ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER
${BUILD_HOME}/selectionscripts/SelectBuildIdentifier.sh 

# If we are a HARDCORE build then the BUILD_IDENTIFIER is already in our enviornment, if we are EXPEDITED then we need to remind ourselves
# of what the BUILD_IDENTIFIER has just been set to from the filesystem
if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
then
	BUILD_IDENTIFIER="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER`"
fi

# We now have  all the information we need to switch from our intial logging to the main logging location that is going to be used
# for the rest of the build. Anything that happens after this point in the build process will be logged to the logging location
# mentioned below  rather than the initial logging location in the root directory that has been used up until now
# The main logging also includes a status stream which has the filename included in its output

if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs ] )
then
	/bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs
fi

if ( [ "`/usr/bin/find ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs -name "*build*" -type f`" != "" ] )
then

	if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/archive ] )
	then
		/bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/archive
	fi

	/bin/mv ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/*build* ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/archive
fi

out_file="build_output_stream-`/bin/date | /bin/sed 's/ //g'`"
exec 1>>${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${out_file}
err_file="build_error_stream-`/bin/date | /bin/sed 's/ //g'`"
exec 2>>${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${err_file}
status_file="build_status_stream-`/bin/date | /bin/sed 's/ //g'`"
exec 4>>${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${status_file}

# Tell the user where the logging output can be found
status "The main output log file is located at ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${out_file}"
status "The main error log file is located at ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${err_file}"
status "To refer to the logs you can run the script ${BUILD_HOME}/Log.sh"
status "Press <enter> to acknowledge"

# We store the entire environment in a file ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/build_environment
# We then reference this file for variable values anywhere we need using the scripts
#
# ${BUILD_HOME}/helperscripts/GetVariableValue.sh
# ${BUILD_HOME}/helperscripts/SetVariableValue.sh
#
# This is a clean way to work rather than passing huge numbers of parameters all over the place to various subscripts
# and I prefer it to simply exporting all the variables because it is more explicit in the sense that you have to
# explicitly access a variable to change its value rather than being able to arbitrarily change it
# Anyway, if we are a HARDCORE build then we already have all our variables set so we store them in our build_environment file
# here.

if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] || [ -f /root/PARAMETER ] )
then
	if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
	then
		read x
	fi
	if ( [ -f /root/PARAMETER ] )
	then
		/usr/bin/env > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/build_environment 2>/dev/null
	fi
	# What we do now is that we load/configure the eniroment based on the values of the template and load it into memory
	# We also store the template name to the filesystem for later reference.
	${BUILD_HOME}/templatedconfigurations/ConfigureTemplate.sh ${CLOUDHOST} ${BUILD_IDENTIFIER} ${SELECTED_TEMPLATE}
	template_name="`/bin/cat ${BUILD_HOME}/runtimedata/current_template_name`"
	. ${template_name}
	/bin/echo "${BUILD_IDENTIFIER}" > ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER
else
	/bin/echo "${BUILD_IDENTIFIER}" > ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER
fi

if ( [ -f ${BUILD_HOME}/runtimedata/BUILDMACHINEPORT:* ] )
then
        /bin/rm ${BUILD_HOME}/runtimedata/BUILDMACHINEPORT:*
fi
/bin/touch ${BUILD_HOME}/runtimedata/BUILDMACHINEPORT:${SSH_PORT}

export WEBSITE_DISPLAY_NAME="`/bin/echo ${WEBSITE_DISPLAY_NAME} | /bin/sed "s/\'//g" | /bin/sed 's/ /_/g'`"
${BUILD_HOME}/initscripts/InitialiseDirectoryStructure.sh ${CLOUDHOST} ${BUILD_IDENTIFIER} 

/usr/bin/env > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/build_environment 2>/dev/null

# Intialise the configuration values for the VPS provider we are using (access tokens/keys) and so on
${BUILD_HOME}/initscripts/InitialiseCloudhostConfig.sh 

# Ask the user if they want to set any SMTP settings if they are not already set
${BUILD_HOME}/selectionscripts/SelectSMTPSettings.sh 

# Set up the credentials for the server user
${BUILD_HOME}/initscripts/InitialiseServerUserCredentials.sh 

# Initialise/configure the datastore ready for use (access keys, tokens, host base values and so on)
#${BUILD_HOME}/initscripts/InitialiseDatastoreConfig.sh
${BUILD_HOME}/providerscripts/datastore/InitialiseDatastoreConfig.sh

if (  [ "${BUILD_FROM_SNAPSHOT}" = "1" ] )
then
	export SNAPSHOT_ID="`${BUILD_HOME}/initscripts/InitialiseSnapshots.sh`"
 	/usr/bin/env > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/build_environment 2>/dev/null
fi

${BUILD_HOME}/initscripts/InitialiseUniqueConfigDatastore.sh

# Make a few pre-flight checks to check that we are good to go
${BUILD_HOME}/initscripts/PreFlightChecks.sh 

# If the build machine is configured to be part of the same VPC as the servers are, then, just perform a crude check to make sure that the build
# machine has been added to the same VPC when it was provisioned. If the build machine is verified as attached to a VPC we assume it is the 
# correct VPC and let the test pass

if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
then
	status "Checking for your build machine VPC network"
	if ( [ "`${BUILD_HOME}/providerscripts/server/CheckBuildMachineVPC.sh ${CLOUDHOST} ${BUILD_MACHINE_IP}`" = "" ] )
	then
		status "It looks like the build machine (${server_name}) is not attached to a VPC when BUILD_MACHINE_VPC=1"
		status "Will have to exit (change BUILD_MACHINE_VPC if necessary in your template)"
		exit
	else
		status "Have successfully verified the presence of a usable VPC network on your build machine"
	fi
	/bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}
	/bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/VPC-ACTIVE
else
	if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/VPC-ACTIVE ] )
	then
		/bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/VPC-ACTIVE
	fi
fi

# Output any pre-processing messages
${BUILD_HOME}/processingscripts/PreProcessingMessages.sh

# If we are installing an application (for example, Joomla or Wordpress) we don't know what application type we are until we check
# so here we perform some checks to find out what application type we are
# We also setup the assets datastore if we expect that our application is going to want to store its assets in the datastore
if ( [ "${BUILD_ARCHIVE_CHOICE}" != "virgin"  ] )
then
	status ""
	status ""
	status "#############################################################"
	status "Interrogating to see what Application you are running, if any"
	status "#############################################################"
	${BUILD_HOME}/application/InterrogateApplicationType.sh
	if ( [ "${BUILD_ARCHIVE_CHOICE}" = "baseline" ] )
	then
		${BUILD_HOME}/application/CheckForAssetsOverwrite.sh
	fi        
	status ""
	status "#############################################################"
	status "Initialising assets datastore, this may or may not take a while"
	status "#############################################################"
	${BUILD_HOME}/initscripts/InitialiseAssetDatastore.sh
fi

if (  [ "${BUILD_FROM_SNAPSHOT}" != "1" ] )
then
	# Initialise all of our security keys and store the PUBLIC_KEY_ID on the filesystem for reference from anywhere
	${BUILD_HOME}/initscripts/InitialiseSecurityKeys.sh
fi

# Store our scaling requirements in the datastore (how many webservers to provision)
${BUILD_HOME}/initscripts/InitialiseScalingProfile.sh
#Provision any DBaaS database service that the build requires 
${BUILD_HOME}/initscripts/InitialiseDatabaseService.sh
# If there is a DBaaS instance running then we can adjust its firewall by only allowing connections from machines in the same VPC
# where and if this is possible
${BUILD_HOME}/providerscripts/dbaas/AdjustDBaaSFirewall.sh

# If we are building an authentication server then that server will require its own SSL certificate, so, generate one here
if ( [ "${NO_AUTHENTICATORS}" != "0" ] )
then
	${BUILD_HOME}/initscripts/InitialiseNewSSLCertificate.sh "FILLER" "yes" 
fi

# Generate the SSL certificate that will be used by our webservers
${BUILD_HOME}/initscripts/InitialiseNewSSLCertificate.sh 

# We perform the build using cloud-init scripts passed to the server being provisioned when it is created using the CLI
# This script will substitute placeholder tokens for live values
${BUILD_HOME}/initscripts/InitialiseCloudInit.sh 


if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
then
        status ""
        status "####FIREWALL ATTENTION NOTICE######"
        status "Your firewalling system is configured as follows:"
        status ""
        status "`/bin/grep -v '^#' ${BUILD_HOME}/builddescriptors/firewallports.dat`"
        status ""
        status "If your firewall is not set correctly the connection to your webserver/reverse proxy will timeout"
        status "If you are sure this configuration is what you want press <enter> otherwise you can modify the file ${BUILD_HOME}/builddescriptors/firewallports.dat"
        read x
fi

#Just check that its 'all systems go'
if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
then
	status ""
	status "#######################################################################################################################"
	status "Are you happy for the build to proceed? Pressing <enter> now will initiate the process of building your server machines"
	status "#######################################################################################################################"
	read x
fi

#Set a timestamp so we can tell how long the build took. It various considerably by cloudhost provider.
start=`/bin/date +%s`

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

# Put out any post processing messages to the user
${BUILD_HOME}/processingscripts/PostProcessingMessages.sh


if ( [ ! -f ${BUILD_HOME}/runtimedata/BUILDING_ON_LAPTOP ] )
then

	#IMPORTANT:
	#########################################################################################################################
	#If we are building on a personal laptop and not a cloudhosted VPS server then we don't mess with the laptop's crontab.
	#If you want these crontab processes to be active on your laptop you are of course free to set them up but
	#if you build from your laptop then likelyhood is that it won't be online 24-7 so the cronjobs might not run anyway
	#this does mean that if you are running your build from your personal laptop and not a cloudhosted VPS server online 24-7
	#processes such as SSL certificate renewals (which are initiated from the build machine's crontab) and software upgrades
	#for the build machine will have to be manually taken care of as a maintenance task.
	#It can be useful to carry a USB stick with MX Linux on it that you can plug in to almost any available machine to run
	#your build from rather than having a VPS server running in a datacentre but with the provisos that I have just mentioned
	#Remmeber if you are building from a personal laptop you will have to set BUILD_MACHINE_VPC="0" so that it is clear
	#that the build machine is not in the same VPC as the server machines are (which has implications for firewalling etc). 
	#######################################################################################################################
	
	${BUILD_HOME}/cron/InitialiseCrontabs.sh
fi

#We inform the users of their credentials. Sometimes, depending on the application, the user needs to know more or less

SERVER_USER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SERVER_USER`"
SERVER_USER_PASSWORD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SERVER_USER_PASSWORD`"

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

trap - EXIT INT

if ( [ "${software_updated}" = "1" ] )
then
	/usr/sbin/shutdown -r now
fi 

