#!/bin/sh
###############################################################################################
# Description: Not all providers play the same so if you have any preprocessing messages you want
# to display before the build begins, you can add then into this file and it will get executed
# prior to the build commencing.
# Author: Peter Winter
# Date : 17/01/2017
###############################################################################################
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
#set -x

status ""
status ""
status "#########################################"
status "You are deploying to region: ${REGION_ID}"
status "#########################################"
status ""

if ( [ "${PRODUCTION}" = "1" ] )
then
    status "############################################"
    status "Number of autoscalers is set to: ${NO_AUTOSCALERS}"
    status "############################################"
    status "Initial number of webservers is set to: ${NUMBER_WS}"
    status "###########################################################################################################"
    status "Modify your template  (${templatefile})"
    status "and restart the build process to alter number of autoscalers or webservers values or press <enter> to accept"
    status "###########################################################################################################"
    read x
fi

if ( [ "${AUTOSCALE_FROM_BACKUP}" = "1" ] )
then
    status "You have chosen to scale your webservers from backups of entire machines this means that the initial webserver build will take a little longer"
    status "Whilst a backup of the webserver's filesystem is made to your datastore"
    status "Press <enter> to acknowledge"
    read x
fi

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
    export ENABLE_DDOS_PROTECION="0"
    status "You are deploying to the Vultr VPS cloud which has an option to switch on DDOS protection for your machines."
    status "If you want to switch on DDOS projection, enter 'Y' or 'y' below, anything else and DDOS protection won't be enabled". 
    status " DDoS Protection adds 10Gbps of mitigation capacity per instance and costs an additional \$10/mo."
    status "Do you want to enable DDOS protection 'Y' or 'N'"
    read response
    if ( [ "${response}" = "Y" ] || [ "${response}" = "y" ] )
    then
        status "DDOS protection has been enabled"
        status "Prsss <enter>"
        read x
        export ENABLE_DDOS_PROTECION="1"
    else
        status "DDOS protection has not been enabled"
        status "Press <enter>"
        read x
    fi
fi

#If you have any pre-processing messages to add, you can add them here. These messages will be displayed before the build
#truly gets going.

if ( [ "${SUPERSAFE_WEBROOT}" = "0" ] || [ "${SUPERSAFE_WEBROOT}" = "1" ] || [ "${SUPERSAFE_DB}" = "0" ] || [ "${SUPERSAFE_DB}" = "1" ] )
then
    if ( [ "${HARDCORE}" != "1" ] )
    then
        status "############################################################################################################################################"
        status "WARNING: you are making backups to your git repository system, check your provider's cost metrics (especially if hourly backups are enabled)"
        status "Data to a git repo is sometimes classified as 'data out' meaning it can rack up a heafty bill especially if it is hundreds of megabytes repeatedly"
        status "If you are satisfied that you are not going to be hammering your bank card by making backups to your git repo, you can contine"
        status "Otherwise considered deploying a build which only makes backups to S3 using the SUPERSAFE_WEBROOT="2" and SUPERSAFE_DB="2" options"
        status "#############################################################################################################################################"
        status "Once you have understood this and actioned it, press <enter>"
        read x
    fi
fi

if ( [ "${AUTOSCALE_FROM_BACKUP}" = "1" ] )
then
    if ( [ "${HARDCORE}" != "1" ] )
    then
        status "############################################################################################################################################"
        status "WARNING: It looks like you are autoscaling from backups of an entire webserver this will write large files to and from your S3 compatable"
        status "Datastore. Please make sure you know what your provider's billing is for data in and out before you go full steamahead with this"
        status "This will likely vary depending upon the location of your S3 datastore relative to where your main VPS machines are located"
        status "I don't want you getting some hefty bill after three weeks of running in this configuration"
        status "############################################################################################################################################"
        status "Once you have understood this and actioned in, press <enter>"
        read x
    fi
fi

if ( [ "${BUILD_CHOICE}" = "1" ] && [ "${BUILD_ARCHIVE_CHOICE}" = "baseline" ] )
then
    if ( [ "${SUPERSAFE_WEBROOT}" = "2" ] || [ "${SUPERSAFE_DB}" = "2" ] )
    then
         status "You are making a baselined build and a baseline build expects its sourcecode to be in a git repository. You are configured to look in your datastore rather than git"
         status "And that would be a problem so I am overriding your backup settings to look in your respository for your sourcecode, if I don't do this the build will fail"
         status "Press <enter> to accept what I am saying"
         read x
         export SUPERSAFE_WEBROOT="1"
         export SUPERSAFE_DB="1"
    fi
fi

if ( [ "${APPLICATION}" = "joomla" ] && [ "${APPLICATION_IDENTIFIER}" != "1" ] )
then
    status "Your application is set to joomla and your application identifier is set to ${APPLICATION_IDENTIFIER}"
    status "The application identifier must be set to 1 for joomla otherwise bad things can happen"
    status "I am setting your application identifier to 1"
    export APPLICATION_IDENTIFIER="1"
    export APPLICATION="joomla"
    status "Press <enter> to accept"
    read x
fi

if ( [ "${APPLICATION}" = "wordpress" ] && [ "${APPLICATION_IDENTIFIER}" != "2" ] )
then
    status "Your application is set to wordpress and your application identifier is set to ${APPLICATION_IDENTIFIER}"
    status "The application identifier must be set to 2 for wordpress otherwise bad things can happen"
    status "I am setting your application identifier to 2"
    export APPLICATION_IDENTIFIER="2"
    export APPLICATION="wordpress"
    status "Press <enter> to accept"
    read x
fi

if ( [ "${APPLICATION}" = "drupal" ] && [ "${APPLICATION_IDENTIFIER}" != "3" ] )
then
    status "Your application is set to drupal and your application identifier is set to ${APPLICATION_IDENTIFIER}"
    status "The application identifier must be set to 3 for drupal otherwise bad things can happen"
    status "I am setting your application identifier to 3"
    export APPLICATION_IDENTIFIER="3"
    export APPLICATION="drupal"
    status "Press <enter> to accept"
    read x
fi

if ( [ "${APPLICATION}" = "moodle" ] && [ "${APPLICATION_IDENTIFIER}" != "4" ] )
then
    status "Your application is set to moodle and your application identifier is set to ${APPLICATION_IDENTIFIER}"
    status "The application identifier must be set to 4 for moodle otherwise bad things can happen"
    status "I am setting your application identifier to 4"
    export APPLICATION_IDENTIFIER="4"
    export APPLICATION="moodle"
    status "Press <enter> to accept"
    read x
fi

if ( [ "${CLOUDHOST}" = "aws" ] && [ "${DISABLE_HOURLY}" != "1" ] )
then
    /usr/bin/banner "WARNING" >&3
    status "############################################################################################################################################"
    status "Please be aware that you have hourly backups enabled which are counted as \"dataout\" by AWS. This can rack up quite some costs as such transfers"
    status "Are billable under AWS. It is recommended therefore that you switch off hourly backups and only rely on daily, weekly, monthly and bi-monthly"
    status "I recommend making very sure of your cost profile when using the AWS system because it can surprise bill you if you are not careful. I think its great"
    status "and all that, but, you know, we don't want to end up brassic"
    status "############################################################################################################################################"
fi

if ( [ "${BUILD_ARCHIVE_CHOICE}" = "virgin" ] || [ "${BUILD_ARCHIVE_CHOICE}" = "baseline" ] )
then
    PRODUCTION="0"
    DEVELOPMENT="1"
fi

if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Postgres" ] && [ "${APPLICATION}" = "wordpress" ] )
then
    status "################################################################"
    status "Apologies, but, Wordpress doesn't support the Postgres Database."
    status "I am defaulting to mariadb. Press <enter> to acknowledge"
    status "################################################################"
    read x
    DATABASE_INSTALLATION_TYPE="Maria"
fi

if ( ( [ "${DATABASE_INSTALLATION_TYPE}" = "Postgres" ] || [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep "Postgres"`" != "" ] ) && [ "${APPLICATION}" = "joomla" ] )
then
    if ( [ "${DB_PORT}" != "5432" ] )
    then
        status "################################################################"
        status "Sorry, I don't know how to set anything other than the default port - 5432 for the postgres database when using joomla"
        status "Setting expected postgres port to 5432"
        status "################################################################"
        /bin/sed -i '/DB_PORT=/d' ${BUILD_HOME}/buildconfiguration/${CLOUDHOST}/${BUILD_IDENTIFIER}
        /bin/echo "export DB_PORT=\"5432\"" >> ${BUILD_HOME}/buildconfiguration/${CLOUDHOST}/${BUILD_IDENTIFIER}
        DB_PORT=5432
    fi
fi


if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Postgres" ] || [ "${DATABASE_DBaaS_INSTALLATION_TYPE}" = "Postgres" ] )
then
    response=""

    if ( [ "${DBaaS_DBNAME}" != "" ] )
    then
        /bin/bash -c "[[ '${DBaaS_DBNAME}' =~ [A-Z] ]] && /bin/touch ${BUILD_HOME}/LOWER && /bin/echo 'I know this is your worst nightmare, but, please read carefully. I have detected that you have some upper case letters in the databse name for your postgres database. By default postgres sets the database names to lower case and so chances are, this is what your postgres has done. Please review this to see if it is the case, but I thought I would give you a chance to change your database name to all lower case.' && /bin/echo && /bin/echo 'Your database name is currently set to: ${DBaaS_DBNAME}.' && /bin/echo 'enter (Y|y) and I will set the characters  of your database name all to lower case for you...' && /bin/echo 'Press <enter> to leave as it is '"
       
       if ( [ -f ${BUILD_HOME}/LOWER ] )
        then
            read response
        fi
       
        if ( [ "${response}" = "Y" ] || [ "${response}" = "y" ] )
        then
            if ( [ -f ${BUILD_HOME}/LOWER ] )
            then
                /bin/rm ${BUILD_HOME}/LOWER
                DBaaS_DBNAME="`/bin/echo "${DBaaS_DBNAME}" | /usr/bin/tr '[:upper:]' '[:lower:]'`"
            fi
        fi
        
        if ( [ -f ${BUILD_HOME}/LOWER ] )
        then
            status "#################################################"
            status "Your database name is now set to: ${DBaaS_DBNAME}"
            status "Press <enter> to accept"
            status "#################################################"
            read x
        fi
    fi
fi

if ( [ "${AUTOSCALE_FROM_BACKUP}" = "1" ] )
then
    status "########################################################################################################################"
    status "You have AUTOSCALE_FROM_BACKUP set to 1. This will take generate a tar image of a whole webserver machine and use it"
    status "To autoscale rapidly. The downside of this is that large files get written and read from your S3 datastore"
    status "When you chose this option makes sure you know how you are going to be billed because maybe it will get pricey?"
    status "########################################################################################################################"
    status "Press <enter> to acknowledge"
    read x
fi

if ( [ "${APPLICATION}" = "moodle" ] && ( [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] || [ "${DATABASE_DBaaS_INSTALLATION_TYPE}" = "MySQL" ] ) )
then
    status "###################################################################################################################################"
    status "Hi, it's me again... I am going to try and set some parameters for your database. Some providers, for example, AWS, don't"
    status "allow this to be done directly via scripts and so, with AWS, for example, I can't do this for you and you need to create "
    status "a parameter group and apply it to your database when you deploy iti through the AWS console. Other providers will vary."
    status ""
    status "The settings you need to have for moodle  in your parameter group (ref AWS documentation) are as follows:"
    status
    status "innodb_file_format=Barracuda , innodb_file_per_table=ON , innodb_large_prefix=1 , binlog_format = 'MIXED'"
    status
    status "###################################################################################################################################"
    read x
fi
