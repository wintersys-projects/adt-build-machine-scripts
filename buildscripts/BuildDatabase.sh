#!/bin/sh
##############################################################################################################
# Author: Peter Winter
# Date  : 12/07/2016
# Description : This is the script to build the database. It will build a single database server and check
# that it seems to be running OK. These scripts look more complicated than they really are. All that is
# happening is we are copying over some files to our new database and executing a few commands (mostly to
# install software) remotely on the database.
###############################################################################################################
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
#######################################################################################################
#######################################################################################################
set -x
done=0
counter="0"
count="0"


status () {
        /bin/echo "$1" | /usr/bin/tee /dev/fd/3 2>/dev/null
}

#If done=1 then we know that we have build a database correctly so we don't need to run again
#If databases fail to build, we try again up to 5 times

status ""
status ""
status ""
status "#########################DATABASE#######################"

#For our remote commands, we have various options that we want to be set. To keep things as clean as possible
#We set out options for our ssh command and scp command here and pass them in through the variable ${OPTIONS}
DATABASE_PUBLIC_KEYS="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/database_keys"
OPTIONS="-o ConnectTimeout=10 -o ConnectionAttempts=5 -o UserKnownHostsFile=${DATABASE_PUBLIC_KEYS} -o StrictHostKeyChecking=yes "
PUBLIC_KEY_ID="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/PUBLICKEYID`"
SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"
SERVER_USER_PASSWORD="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSERPASSWORD`"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
DEFAULT_USER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DEFAULT_USER`"
DATABASE_INSTALLATION_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DATABASE_INSTALLATION_TYPE`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
DB_SIZE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DB_SIZE`"
BUILDOS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS`"
BUILDOS_VERSION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS_VERSION`"
DB_SERVER_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DB_SERVER_TYPE`"
BUILD_MACHINE_VPC="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_MACHINE_VPC`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh INFRASTRUCTURE_REPOSITORY_OWNER`"
BASELINE_DB_REPOSITORY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BASELINE_DB_REPOSITORY`"
BUILD_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_CHOICE`"
SSH_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"
 

if ( [ "${DEFAULT_USER}" = "root" ] )
then
        SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "
else
        SUDO="DEBIAN_FRONTEND=noninteractive /usr/bin/sudo -S -E "
fi

CUSTOM_USER_SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

#${BUILD_HOME}/initscripts/InitialiseDatabaseCredentials.sh

if ( [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
then
        DBaaS_HOSTNAME="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DBaaS_HOSTNAME`"
        DBaaS_DBNAME="`/bin/sed 1!d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred`"
        DBaaS_USERNAME="`/bin/sed 3!d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred`"
        DBaaS_PASSWORD="`/bin/sed 2!d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred`"
        DB_PORT="`/bin/sed 4!d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred`"
else
        rnd="n`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-8 | /usr/bin/tr '[:upper:]' '[:lower:]'`n"
        rnd1="p`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-8 | /usr/bin/tr '[:upper:]' '[:lower:]'`p"
        rnd2="u`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-8 | /usr/bin/tr '[:upper:]' '[:lower:]'`u"

        if ( [ -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials ] )
        then
                /bin/echo "${rnd}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred
                /bin/echo "${rnd1}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred
                /bin/echo "${rnd2}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred
        fi
fi

if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred ] )
then
        ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred credentials/db_cred
fi

#status ""
#status ""
#status ""
#status ""
#status "========================================================="
#status "=================BUILDING DATABASE======================="
#status "========================================================="
#
#status "Logging for this database build is located at ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${OUT_FILE}"
#status "The error stream for this database build is located at ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/logs/${ERR_FILE}"
#status "========================================================="

#If we don't need a database, then just skip the process of installing a database
#We may have an application which doesn't require a database
if ( [ "${DATABASE_INSTALLATION_TYPE}" = "None" ] )
then
        status "This deployment doesn't need a database passing...."
fi

built="0"

#If we are done then we can stop otherwise retry up to 5 times

while ( [ "${done}" != "1" ] && [ "${counter}" -lt "5" ] && [ "${DATABASE_INSTALLATION_TYPE}" != "None" ] )
do
        counter="`/usr/bin/expr ${counter} + 1`"
        status "OK... building a database server. This is attempt ${counter} of 5"

        #Make sure a database is not already running
        WEBSITE_IDENTIFIER="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`"
        if ( [ "`${BUILD_HOME}/providerscripts/server/NumberOfServers.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} 2>/dev/null`" -eq "0" ] )
        then

                ip=""
                #Create an identifier from our the user name we allocated to identify the database server
                RND="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1`"
                #database_name="database-${RND}-`/bin/echo ${BUILD_IDENTIFIER} | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                database_name="db-${REGION}-${BUILD_IDENTIFIER}-${RND}"

              #  database_name="`/bin/echo ${database_name} | /usr/bin/cut -c -32 | /bin/sed 's/-$//g'`"

                #What type of OS are we building for. Currently, (April 2018) only ubuntu and debian are supported
             #   if ( [ "${OS_TYPE}" = "" ] )
             #   then
             #           OS_TYPE="`${BUILD_HOME}/providerscripts/cloudhost/GetOperatingSystemVersion.sh ${DB_SIZE} ${CLOUDHOST} ${BUILDOS} ${BUILDOS_VERSION}`"
             #   fi

                status "Initialising a new server machine, please wait......"

                server_started="0"
                while ( [ "${server_started}" = "0" ] )
                do
                         count="0"
                        #Actually spin up the machine we are going to build on
                        ${BUILD_HOME}/providerscripts/server/CreateServer.sh "${DB_SERVER_TYPE}" "${database_name}"

                        #If for some reason, we failed to build the machine, then, give it another try
                        while ( [ "$?" != "0" ] && [ "${count}" -lt "10" ] )
                        do
                                count="`/usr/bin/expr ${count} + 1`"
                                /bin/sleep 10
                                ${BUILD_HOME}/providerscripts/server/CreateServer.sh "${DB_SERVER_TYPE}" "${database_name}" 
                        done

                        if ( [ "${count}" = "10" ] )
                        then
                                status "Couldn't create database server"
                                exit
                        fi

                        #Check that the server has been assigned its IP addresses and that they are active
                   ip=""
                   private_ip=""
                   count="0"

                   while ( ( [ "${ip}" = "" ] || [ "${private_ip}" = "" ] ) && [ "${count}" -lt "20" ] )
                   do
                           status "Interrogating for database ip address....."
                           ip="`${BUILD_HOME}/providerscripts/server/GetServerIPAddresses.sh "${database_name}" ${CLOUDHOST} | /bin/grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`"
                           private_ip="`${BUILD_HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "${database_name}" ${CLOUDHOST} | /bin/grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`"
                           /bin/sleep 10
                           count="`/usr/bin/expr ${count} + 1`"
                   done
                   if ( [ "${ip}" != "" ] && [ "${private_ip}" != "" ] )
                   then
                           server_started="1"
                   elif ( [ "${ip}" != "" ] && [ "${private_ip}" = "" ] )
                   then
                        status "Found a public ip address but not a private ip address"
                        status "This likely means that there is some sort problem with the VPC"
                   else
                           status "Haven't been able to start your server, I will try again....."
                   fi
                done

           #     ${BUILD_HOME}/providerscripts/server/EnsureServerAttachedToVPC.sh "${CLOUDHOST}" "${database_name}" "${private_ip}"

                DBIP_PUBLIC="${ip}"
                DBIP_PRIVATE="${private_ip}"

                ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${ip} databasepublicip/${ip}
                ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${private_ip} databaseip/${private_ip}

                if ( [ "${BUILD_MACHINE_VPC}" = "1" ] )
                then
                        db_active_ip="${DBIP_PRIVATE}"
                elif ( [ "${BUILD_MACHINE_VPC}" = "0" ] )
                then
                        db_active_ip="${DBIP_PUBLIC}"
                fi

                if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/DBIP:* ] )
                then
                        /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/DBIP:*
                fi
     
                if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/DBPRIVATEIP:* ] )
                then
                        /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/DBPRIVATEIP:*
                fi

                if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips ] )
                then
                        /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips
                fi
    
                /bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/DBIP:${DBIP_PUBLIC}
                /bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/DBPRIVATEIP:${DBIP_PRIVATE}

                #We create an ip mask for our server this is used when we set access privileges and so on within the database
                #and we want to allow access from machines on our private network
                IP_MASK="`/bin/echo ${DBIP_PRIVATE} | /bin/grep -oE '[0-9]{1,3}\.[0-9]{1,3}' | /usr/bin/head -1`"
                IP_MASK=${IP_MASK}".%.%"

                status "Have got the ip addresses for your database (${database_name})"
                status "Public IP address: ${DBIP_PUBLIC}"
                status "Private IP address: ${DBIP_PRIVATE}"

                if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys ] )
                then
                        /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys
                fi

                status "Performing SSH keyscan on your new database machine (I allow up to 15 attempts). If this does fail, check BUILD_MACHINE_VPC in your template"

                if ( [ -f ${DATABASE_PUBLIC_KEYS} ] )
                then
                        /bin/cp /dev/null ${DATABASE_PUBLIC_KEYS}
                fi

                /usr/bin/ssh-keyscan -T 60 ${db_active_ip} >> ${DATABASE_PUBLIC_KEYS}

                keytry="1"
                while ( [ "`/usr/bin/diff -s /dev/null ${DATABASE_PUBLIC_KEYS} | /bin/grep identical`" != "" ] && [ "${keytry}" -lt "15" ] )
                do
                        status "Couldn't scan for database ${database_name} ssh-keys attempt ${keytry} (this is normal and expected) .... trying again"
                        /bin/sleep 10
                        keytry="`/usr/bin/expr ${keytry} + 1`"
                        /usr/bin/ssh-keyscan -T 60 ${db_active_ip} >> ${DATABASE_PUBLIC_KEYS}
                done 

                if ( [ "${keytry}" = "15" ] )
                then
                        status "Couldn't obtain ssh-keys, having to destroy the machine and try again"
                        ${BUILD_HOME}/providerscripts/server/DestroyServer.sh ${DBIP_PUBLIC} ${CLOUDHOST}
                else
                        status "Successfully scanned remote database ${database_name} for ssh-keys"

                        #We don't want to pass in our private keys to our remote commands every time from the command line as it will look unwieldy.
                        #So, we previously setup unique key files with out ssh private keys in them and now that we know the ip address of our autoscaler,
                        #We can tell ourselves where to look for the private key to that ip address by configuring the config file to point to it
#                        /bin/echo "Host ${db_active_ip}" >> ~/.ssh/config
#                        /bin/echo "IdentityFile ~/.ssh/${SERVER_USER}.key" >> ~/.ssh/config
#                        /bin/echo "IdentitiesOnly yes" >> ~/.ssh/config

                         initiation_ip="${db_active_ip}"
                         machine_type="database"

                        . ${BUILD_HOME}/buildscripts/InitiateNewMachine.sh

                        /bin/cp /dev/null ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/database_configuration_settings.dat

                        while read param
                        do
                                param1="`eval /bin/echo ${param}`"
                                if ( [ "${param1}" != "" ] )
                                then
                                        /bin/echo ${param1} >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/database_configuration_settings.dat
                                fi
                        done < ${BUILD_HOME}/builddescriptors/databasescp.dat

                        /usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/database_configuration_settings.dat ${SERVER_USER}@${db_active_ip}:/home/${SERVER_USER}/.ssh >/dev/null 2>&1

                                
                                /usr/bin/scp ${OPTIONS} -i ${BUILD_KEY} ${BUILD_HOME}/builddescriptors/buildstylesscp.dat ${SERVER_USER}@${db_active_ip}:/home/${SERVER_USER}/.ssh/buildstyles.dat >/dev/null 2>&1
                                /usr/bin/scp ${OPTIONS} -i ${BUILD_KEY} ${BUILD_HOME}/providerscripts/git/GitRemoteInstall.sh ${SERVER_USER}@${db_active_ip}:/home/${SERVER_USER}/InstallGit.sh
                                git_provider_domain="`${BUILD_HOME}/providerscripts/git/GitProviderDomain.sh`"
                                gitfetchno="0"
                                while ( [ "`/usr/bin/ssh ${OPTIONS} -i ${BUILD_KEY} ${SERVER_USER}@${db_active_ip} "${CUSTOM_USER_SUDO} /bin/ls /home/${SERVER_USER}/db.sh" 2>/dev/null`" = "" ] && [ "${gitfetchno}" -lt "5" ] )
                                do
                                        /usr/bin/ssh ${OPTIONS} -i ${BUILD_KEY} ${SERVER_USER}@${db_active_ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/InstallGit.sh ; cd /home/${SERVER_USER}; /usr/bin/git clone https://${git_provider_domain}/${INFRASTRUCTURE_REPOSITORY_OWNER}/adt-database-scripts.git; /bin/cp -r ./adt-database-scripts/* .; /bin/rm -r ./adt-database-scripts ; /bin/chown -R ${SERVER_USER}:${SERVER_USER} /home/${SERVER_USER}/*; /bin/chmod 500 /home/${SERVER_USER}/db.sh"
                                        /bin/sleep 5
                                        gitfetchno="`/usr/bin/expr ${gitfetchno} + 1`"
                                done

                                if ( [ "${gitfetchno}" = "5" ] )
                                then
                                        status "Had trouble getting the database infrastructure sourcecode, will have to exit"
                                        exit
                                fi
  
                                /bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/CLOUDHOST:${CLOUDHOST}

                                if ( [ "${BASELINE_DB_REPOSITORY}" != "" ] )
                                then
                                        /usr/bin/ssh ${OPTIONS} -i ${BUILD_KEY} ${SERVER_USER}@${db_active_ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/providerscripts/utilities/config/StoreConfigValue.sh 'BASELINEDBREPOSITORY' ${BASELINE_DB_REPOSITORY}" 
                                fi

                                status "We are about to run the build script to actually build the machine into a database server"
                                status "Please Note: The process of building the database is running on a remote machine with ip address : ${DBIP_PUBLIC}"
                                status "To access this machine once it has finished provisioning you can use the scripts in ${BUILD_HOME}/helperscripts"
                                status "Log files (stderr and stdout) are stored on the remote machine in /home/${SERVER_USER}/logs"
                                status "Starting to build the database proper"
                                status "`/bin/date`"

                                #Decide which build we are selecting to build from - virgin, hourly, daily, weekly, monthly, bimonthly
                                if ( [ "${BUILD_CHOICE}" = "0" ] )
                                then
                                        #We are building a virgin installation
                                        /usr/bin/ssh ${OPTIONS} -i ${BUILD_KEY} ${SERVER_USER}@${db_active_ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/db.sh"
                                elif ( [ "${BUILD_CHOICE}" = "1" ] )
                                then
                                        #We are building from a baseline
                                        /usr/bin/ssh ${OPTIONS} -i ${BUILD_KEY} ${SERVER_USER}@${db_active_ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/db.sh"
                                elif ( [ "${BUILD_CHOICE}" = "2" ] )
                                then
                                        #We are building from an hourly backup
                                        /usr/bin/ssh ${OPTIONS} -i ${BUILD_KEY} ${SERVER_USER}@${db_active_ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/db.sh"
                                elif ( [ "${BUILD_CHOICE}" = "3" ] )
                                then
                                        #We are building from an daily backup
                                        /usr/bin/ssh ${OPTIONS} -i ${BUILD_KEY} ${SERVER_USER}@${db_active_ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/db.sh"
                                elif ( [ "${BUILD_CHOICE}" = "4" ] )
                                then
                                        #We are building from an weekly backup
                                        /usr/bin/ssh ${OPTIONS} -i ${BUILD_KEY} ${SERVER_USER}@${db_active_ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/db.sh"
                                elif ( [ "${BUILD_CHOICE}" = "5" ] )
                                then
                                        #We are building from an monthly backup
                                        /usr/bin/ssh ${OPTIONS} -i ${BUILD_KEY} ${SERVER_USER}@${db_active_ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/db.sh"
                                elif ( [ "${BUILD_CHOICE}" = "6" ] )
                                then
                                        #We are building from an bimonthly backup
                                        /usr/bin/ssh ${OPTIONS} -i ${BUILD_KEY} ${SERVER_USER}@${db_active_ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/db.sh"
                                fi

                                status "Finished building the database server (${database_name})"
                                status "`/bin/date`"

                        #Check that the database is built and ready for action

                        done="0"
                        alive=""
                        count2="0"

                        alive="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${db_active_ip} "/bin/ls /home/${SERVER_USER}/runtime/DATABASE_READY"`"

                        count="0"
                        while ( [ "${alive}" != "/home/${SERVER_USER}/runtime/DATABASE_READY" ] && [ "${count}" -le "15" ] )
                        do
                                count="`/usr/bin/expr ${count} + 1`"
                                /bin/sleep 10
                                alive="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${db_active_ip} "/bin/ls /home/${SERVER_USER}/runtime/DATABASE_READY"`"
                        done 

                        if ( [ "${alive}" = "/home/${SERVER_USER}/runtime/DATABASE_READY" ] )
                        then
                                done=1
                                built="`/usr/bin/expr ${built} + 1`"
                        fi

                        #If $done != 1 then it means the DB server didn't build correctly and fully, so destroy the machine it was being built on
                        if ( [ "${done}" != "1" ] )
                        then
                                status "###########################################################################################################################"
                                status "Hi, a database server didn't seem to build correctly. I can destroy it and try again to build a new database server for you"
                                status "###########################################################################################################################"
                                status "Press the <enter> key to be continue with the next attempt <ctrl - c> to exit"

                                if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
                                then
                                        read response
                                fi

                                ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh databasepublicip
                                ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh databaseip

                                ${BUILD_HOME}/providerscripts/server/DestroyServer.sh ${DBIP_PUBLIC} ${CLOUDHOST}

                                #Wait until we are sure that the database server(s) are destroyed because of a faulty build
                                while ( [ "`${BUILD_HOME}/providerscripts/server/NumberOfServers.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST} 2>/dev/null`" != "${built}" ] )
                                do
                                        /bin/sleep 30
                                done

                                count1="`/usr/bin/expr ${count1} - 1`"

                        else
                                status "A database server (${database_name}) has built correctly (`/usr/bin/date`) and is accepting connections"
                                counter="`/usr/bin/expr ${counter} - 1`"
                        fi
                fi
        else
                status "A Database is already running, using that one......"
                status "Press enter if that is OK"

                if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
                then
                        read response
                fi
                done=1
        fi
done

#If we get to here then we know that the database hasn't built correctly, so report it and exit
if ( [ "${counter}" = "5" ] )
then
        status "The infrastructure failed to intialise because of a build problem, please investigate, correct and rebuild"
        exit
fi
