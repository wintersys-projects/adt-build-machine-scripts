#!/bin/sh
########################################################################################
# Author: Peter Winter
# Date  : 12/07/2021
# Description : This is a script which enables you to shortcut the deployment of DBaaS systems
# when using the hardcore or expedited build. You do it by setting the DATABASE_DBaaS_INSTALLATION_TYPE
# variable in the way described for each provider. When set as described for your provider,
# when you make the deployment this script will try and spin up a DBaaS system and use that. 
########################################################################################
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
#########################################################################################
#########################################################################################
#set -x

status () {
        /bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
        /bin/echo "${script_name}: ${1}" >> /dev/fd/4
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
DATABASE_DBaaS_INSTALLATION_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DATABASE_DBaaS_INSTALLATION_TYPE`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
DATABASE_INSTALLATION_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DATABASE_INSTALLATION_TYPE`"
BYPASS_DB_LAYER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BYPASS_DB_LAYER`"
VPC_IP_RANGE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh VPC_IP_RANGE`"
DB_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DB_PORT`"
BYPASS_DB_LAYER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BYPASS_DB_LAYER`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"


if ( [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
then
        #########################################################################################################
        #If you are deploying to digitalocean provide a setting with the following format in your template
        #DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:<cluster_engine>:<cluster_region>:<cluster_nodes>:<cluster_size>:<cluster_version>:<cluster_name>:<db_name>:<vpc_id>:<database_username>"
        #DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:mysql:lon1:1:db-s-1vcpu-1gb:8:testdbcluster1:testdb1:e265abcb-1295-1d8b-af36-0129f89456c2:example-username"
        #DATABASE_DBaaS_INSTALLATION_TYPE="Postgres:DBAAS:pg:lon1:1:db-s-1vcpu-1gb:8:testdbcluster1:testdb1:e265abcb-1295-1d8b-af36-0129f89456c2:example-username"
        #########################################################################################################


        if ( [ "${CLOUDHOST}" = "digitalocean" ] && [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
        then
                if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep DBAAS`" != "" ] )
                then
                        database_details="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/sed 's/^.*DBAAS://g'`"
                        cluster_engine="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $1}'`"
                        cluster_region="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $2}'`"
                        cluster_nodes="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $3}'`"
                        cluster_size="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $4}'`"
                        cluster_version="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $5}'`"
                        cluster_name="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $6}'`"
                        db_name="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $7}'`"
                        adt_vpc="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $8}'`"
                        database_user="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $9}'`"


                        status "Configuring database cluster ${cluster_name}, please wait..."

                        cluster_id="`/usr/local/bin/doctl databases list -o json | /usr/bin/jq -r '.[] | select (.name == "'${cluster_name}'").id'`"

                        if ( [ "${cluster_id}" = "" ] )
                        then

                                if ( [ "${BYPASS_DB_LAYER}" = "1" ] )
                                then
                                        status "You can't have the BYPASS_DB_LAYER set to on for a newly provisioned database"
                                        status "Do want me to set BYPASS_DB_LAYER to off so that the build will continue (Y|y) otherwise I will have to exit"
                                        read response
                                        if ( [ "${response}" = "y" ] || [ "${response}" = "Y" ] )
                                        then
                                                BYPASS_DB_LAYER="0"
                                        else
                                                /usr/bin/kill -9 $PPID                                        
                                        fi
                                fi
                                status "Creating the database cluster ${cluster_name}"

                                /usr/local/bin/doctl databases create ${cluster_name} --engine ${cluster_engine} --region ${cluster_region}  --num-nodes ${cluster_nodes} --size ${cluster_size} --version ${cluster_version} --private-network-uuid ${adt_vpc} 
                                if ( [ "$?" != "0" ] )
                                then
                                        status "I had trouble creating the database cluster will have to exit....."
                                        /usr/bin/kill -9 $PPID                                
                                fi
                        fi

                        while ( [ "${cluster_id}" = "" ] )
                        do
                                status "Trying to obtain cluster id for the ${cluster_name} cluster..."
                                cluster_id="`/usr/local/bin/doctl databases list -o json | /usr/bin/jq -r '.[] | select (.name == "'${cluster_name}'").id'`"
                                /bin/sleep 30
                        done

                        status "Tightening the firewall on your database cluster"

                        #uuids="`/usr/local/bin/doctl databases firewalls list ${cluster_id} | /usr/bin/tail -n +2 | /usr/bin/awk '{print $1}'`"
                        uuids="`/usr/local/bin/doctl databases firewalls list ${cluster_id} -o json | /usr/bin/jq -r '.[] | select (.cluster_uuid == "'${cluster_id}'").uuid'`"

                        if ( [ "${uuids}" != "" ] )
                        then
                                for uuid in ${uuids}  
                                do
                                        /usr/local/bin/doctl databases firewalls remove ${cluster_id} --uuid ${uuid}
                                done
                        fi

                        status "Creating a database named ${db_name} in cluster: ${cluster_id}"

                        /usr/local/bin/doctl databases db create ${cluster_id} ${db_name}

                        while ( [ "`/usr/local/bin/doctl databases db list ${cluster_id} -o json | /usr/bin/jq -r '.[] | select (.name == "'${db_name}'").name'`" = "" ] )
                        do
                                status "Probing for a database called ${db_name} in the cluster called ${cluster_name} - Please Wait...."
                                status "Note: you can get a %age progress update by referring to the Digital Ocean GUI for your database cluster as it provisions"
                                /bin/sleep 30
                                /usr/local/bin/doctl databases db create ${cluster_id} ${db_name}
                        done

                        database_password=""

                        if ( [ "`/usr/local/bin/doctl database user list ${cluster_id} -o json | /usr/bin/jq -r '.[] | select (.name == "'${database_user}'").name'`" = "" ] )
                        then
                                database_password="`/usr/local/bin/doctl databases user create  ${cluster_id} ${database_user} -o json | /usr/bin/jq -r '.[].password'`"
                        else 
                                database_password="`/usr/local/bin/doctl database user list ${cluster_id} -o json | /usr/bin/jq -r '.[] | select (.name == "'${database_user}'").password'`"
                        fi

                        status "######################################################################################################################################################"
                        status "You might want to check that a database cluster called ${cluster_name} with a database ${db_name} is present using your Digital Ocean gui system"
                        status "######################################################################################################################################################"
                        status "Press <enter> when you are satisfied"

                        if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
                        then
                                read x
                        fi

                        if ( [ "`/usr/local/bin/doctl database firewalls list ${cluster_id} -o json | /usr/bin/jq -r '.[] | select (.value == "'${VPC_IP_RANGE}'").id'`" = "" ] )
                        then
                                /usr/local/bin/doctl databases firewalls append ${cluster_id} --rule ip_addr:${VPC_IP_RANGE}
                        fi

                        if ( [ "${cluster_engine}" = "mysql" ] )
                        then
                                export DATABASE_DBaaS_INSTALLATION_TYPE="MySQL"
                        elif ( [ "${cluster_engine}" = "postgres" ] )
                        then
                                export DATABASE_DBaaS_INSTALLATION_TYPE="Postgres"
                        fi

                        export DATABASE_INSTALLATION_TYPE="DBaaS"
                        export DATABASE_DBaaS_INSTALLATION_TYPE="${DATABASE_DBaaS_INSTALLATION_TYPE}:${cluster_id}"
                        export DB_IDENTIFIER="private-`/usr/local/bin/doctl databases connection ${cluster_id} -o json | /usr/bin/jq -r '.host'`"
                        export DB_USERNAME="${database_user}"
                        export DB_PASSWORD="${database_password}"
                        export DB_NAME="${db_name}"
                        export DB_PORT="${DB_PORT}"

                        status "The Values I have retrieved for your database setup are:"
                        status "##########################################################"
                        status "HOSTNAME:${DB_IDENTIFIER}"
                        status "USERNAME:${DB_USERNAME}"
                        status "PASSWORD:${DB_PASSWORD}"
                        status "DATABASENAME:${DB_NAME}"
                        status "PORT:${DB_PORT}"
                        status "##########################################################"
                        status "If these settings look OK to you, press <enter>"

                        if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
                        then
                                read x
                        fi
                        /usr/local/bin/doctl databases get-ca ${cluster_id} > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DBaaS_CERT
                fi
        fi


        #########################################################################################################
        #If you are deploying to exoscale provide a setting with the following format in your template
        #DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:mysql:ch-gva-2:hobbyist-2:testdb1"
        #DATABASE_DBaaS_INSTALLATION_TYPE="Postgres:DBAAS:pg:ch-gva-2:hobbyist-2:testdb1"
        #If you need to you can turn off termination protection as in the following example:
        #exo dbaas update testdb1 -z ch-gva-2 --termination-protection=false
        #########################################################################################################
        if ( [ "${CLOUDHOST}" = "exoscale" ] && [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
        then
                if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep DBAAS`" != "" ] )
                then
                        database_details="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/sed 's/^.*DBAAS://g'`"
                        database_engine="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $1}'`"
                        database_region="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $2}'`"
                        database_size="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $3}'`"
                        db_name="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $4}'`"

                        existing_db_name="`/usr/bin/exo dbaas list -O json | /usr/bin/jq -r '.[] | select (.name == "'${db_name}'").name'`"

                        new=""
                        if ( [ "${existing_db_name}" = "" ] )
                        then
                                if ( [ "${BYPASS_DB_LAYER}" = "1" ] )
                                then
                                        status "You can't have the BYPASS_DB_LAYER set to on for a newly provisioned database"
                                        status "Do want me to set BYPASS_DB_LAYER to off so that the build will continue (Y|y) otherwise I will have to exit"
                                        read response
                                        if ( [ "${response}" = "y" ] || [ "${response}" = "Y" ] )
                                        then
                                                BYPASS_DB_LAYER="0"
                                        else
                                                /usr/bin/kill -9 $PPID                                        
                                        fi
                                fi
                                status "Creating  database ${db_name}, with engine: ${database_engine}, in region: ${database_region} and at size: ${database_size} please wait..."
                                /usr/bin/exo dbaas create ${database_engine} ${database_size} ${db_name}  --zone ${database_region}

                                if ( [ "$?" = "0" ] )
                                then
                                        new="newly provisioned"
                                fi
                        else
                                new="previously existing"
                        fi


                        status "Waiting for your new database cluster to be reponsive and online (this may take a little while)"

                        while ( [ "`/usr/bin/exo dbaas show ${db_name} -O json | /usr/bin/jq -r 'select (.name == "'${db_name}'").state'`" != "running" ] )
                        do
                                /bin/sleep 10
                        done

                        status ""
                        status "Database with name ${db_name} is now running"
                        status ""
                        
                        export DB_USERNAME="`/usr/bin/exo -O json dbaas show --zone ${database_region} ${db_name} | /usr/bin/jq -r ".${database_engine}.uri_params.user"`"
                        export DB_PASSWORD="`/usr/bin/exo -O json dbaas show --zone ${database_region} ${db_name} | /usr/bin/jq -r ".${database_engine}.uri_params.password"`"
                        export DATABASE_INSTALLATION_TYPE="DBaaS"
                        export DB_IDENTIFIER="`/usr/bin/exo -O json dbaas show --zone ${database_region} ${db_name} | /usr/bin/jq -r ".${database_engine}.uri_params.host"`"
                        export DB_NAME="${db_name}"
                        export DB_PORT="`/usr/bin/exo -O json dbaas show --zone ${database_region} ${db_name} | /usr/bin/jq -r ".${database_engine}.uri_params.port"`"
                        export DATABASE_REGION="${database_region}"
                        
                        #Open up fully until we are installed and then tighten up the firewall
                        if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep Postgres`" = "" ] )
                        then 
                                /usr/bin/exo dbaas update --zone ${database_region} ${db_name} --mysql-ip-filter="0.0.0.0/0"
                        else
                                /usr/bin/exo dbaas update --zone ${database_region} ${db_name} --pg-ip-filter="0.0.0.0/0"
                        fi


                        status "The Values I have retrieved for your database setup are:"
                        status "##########################################################"
                        status "HOSTNAME:${DB_IDENTIFIER}"
                        status "USERNAME:${DB_USERNAME}"
                        status "PASSWORD:${DB_PASSWORD}"
                        status "DATABASENAME:${DB_NAME}"
                        status "PORT:${DB_PORT}"
                        status "##########################################################"
                        status "If these settings look OK to you, press <enter>"

                        if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
                        then
                                read x
                        fi

                        /usr/bin/exo dbaas ca-certificate > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DBaaS_CERT
                fi
        fi

        #########################################################################################################
        #DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:<engine>:<region>:<machine_type>:<cluster_size>:<cluster_label>:<db_name>
        #DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:mysql/8:nl-ams:g6-nanode-1:1:test-cluster:testdb1"
        #DATABASE_DBaaS_INSTALLATION_TYPE="Postgres:DBAAS:<engine>:<region>:<machine_type>:<cluster_size>:<cluster_label>:<db_name>
        #DATABASE_DBaaS_INSTALLATION_TYPE="Postgres:DBAAS:postgresql/14.4:nl-ams:g6-nanode-1:1:test-cluster:testdb1"
        #########################################################################################################
        if ( [ "${CLOUDHOST}" = "linode" ] && [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
        then
                if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep DBAAS`" != "" ] )
                then
                        database_type="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $1}'`"
                        engine="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $3}'`"
                        cluster_size="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $6}'`" 
                        db_region="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $4}'`"
                        machine_type="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $5}'`"
                        label="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $7}'`"
                        db_name="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $8}'`"

                        if ( [ "${database_type}" = "MySQL" ] )
                        then
                                status "Your database is being provisioned, please wait....."
                                database_id="`/usr/local/bin/linode-cli --json databases mysql-list | jq '.[] | select(.label | contains ("'${label}'")) | .id'`"

                                if ( [ "${database_id}" = "" ] )
                                then
                                        if ( [ "${BYPASS_DB_LAYER}" = "1" ] )
                                        then
                                                status "You can't have the BYPASS_DB_LAYER set to on for a newly provisioned database"
                                                status "Do want me to set BYPASS_DB_LAYER to off so that the build will continue (Y|y) otherwise I will have to exit"
                                                read response
                                                if ( [ "${response}" = "y" ] || [ "${response}" = "Y" ] )
                                                then
                                                        BYPASS_DB_LAYER="0"
                                                else
                                                        /usr/bin/kill -9 $PPID                                                
                                                fi
                                        fi

                                        /usr/local/bin/linode-cli databases mysql-create --label "${label}" --region "${db_region}" --type "${machine_type}" --cluster_size "${cluster_size}" --engine "${engine}" --ssl_connection "true" --allow_list "0.0.0.0/0"

                                        database_id="`/usr/local/bin/linode-cli --json databases mysql-list | jq -r '.[] | select(.label | contains ("'${label}'")) | .id'`"

                                        while ( [ "${database_id}" = "" ] )
                                        do
                                                status "Attempting to get database id...if I am looking for more than a few minutes something must be wrong"
                                                /bin/sleep 20
                                                database_id="`/usr/local/bin/linode-cli --json databases mysql-list | jq -r '.[] | select(.label | contains ("'${label}'")) | .id'`"
                                        done

                                        status "Have got the database id which is: ${database_id}"
                                        status "Its now the long wait for the database to become active (this can take 10s of minutes)"

                                        status="`/usr/local/bin/linode-cli databases mysql-list --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}').status'`"

                                        while ( [ "${status}" != "active" ] )
                                        do
                                                /bin/sleep 20
                                                status="`/usr/local/bin/linode-cli databases mysql-list --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}').status'`"
                                        done
                                else
                                        /usr/local/bin/linode-cli databases mysql-update ${database_id} --allow_list "0.0.0.0/0"
                                fi

                                export CLUSTER_NAME="`/usr/local/bin/linode-cli databases mysql-list --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}') | .label'`"
                                export DB_IDENTIFIER="`/usr/local/bin/linode-cli databases mysql-list --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}') | .hosts.primary'`"
                                export DB_USERNAME="`/usr/local/bin/linode-cli databases mysql-creds-view ${database_id} --json | /usr/bin/jq -r '.[].username'`"
                                export DB_PASSWORD="`/usr/local/bin/linode-cli databases mysql-creds-view ${database_id} --json | /usr/bin/jq -r '.[].password'`"
                                export DB_PORT="`/usr/local/bin/linode-cli databases mysql-list --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}').port'`"
                                export DB_NAME="${db_name}"

                                /bin/echo "`/usr/local/bin/linode-cli --json databases mysql-ssl-cert ${database_id} | /usr/bin/jq -r '.[].ca_certificate'`" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DBaaS_CERT
                        elif ( [ "${database_type}" = "Postgres" ] )
                        then
                                status "Your database is being provisioned, please wait (this can take 10s of minutes)....."
                                database_id="`/usr/local/bin/linode-cli --json databases postgresql-list | jq '.[] | select(.label | contains ("'${label}'")) | .id'`"

                                if ( [ "${database_id}" = "" ] )
                                then   
                                        if ( [ "${BYPASS_DB_LAYER}" = "1" ] )
                                        then
                                                status "You can't have the BYPASS_DB_LAYER set to on for a newly provisioned database"
                                                status "Do want me to set BYPASS_DB_LAYER to off so that the build will continue (Y|y) otherwise I will have to exit"
                                                read response
                                                if ( [ "${response}" = "y" ] || [ "${response}" = "Y" ] )
                                                then
                                                        BYPASS_DB_LAYER="0"
                                                else
                                                        /usr/bin/kill -9 $PPID                                                
                                                fi
                                        fi

                                        /usr/local/bin/linode-cli databases postgresql-create --label "${label}" --region "${db_region}" --type "${machine_type}" --cluster_size "${cluster_size}" --engine "${engine}" --ssl_connection "true" --allow_list "0.0.0.0/0"


                                        database_id="`/usr/local/bin/linode-cli --json databases postgresql-list | jq -r '.[] | select(.label | contains ("'${label}'")) | .id'`"

                                        while ( [ "${database_id}" = "" ] )
                                        do
                                                status "Attempting to get database id...if I am looking for more than a few minutes something must be wrong"
                                                /bin/sleep 20
                                                database_id="`/usr/local/bin/linode-cli --json databases postgresql-list | jq -r '.[] | select(.label | contains ("'${label}'")) | .id'`"
                                        done

                                        status "Have got the database id which is: ${database_id}"
                                        status "Its now the long wait for the database to become active (this can take 10s of minutes)"

                                        status="`/usr/local/bin/linode-cli databases postgresql-list --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}').status'`"

                                        while ( [ "${status}" != "active" ] )
                                        do
                                                /bin/sleep 20
                                                status="`/usr/local/bin/linode-cli databases postgresql-list --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}').status'`"
                                        done
                                else
                                        /usr/local/bin/linode-cli databases mysql-update ${database_id} --allow_list "0.0.0.0/0"
                                fi

                                export CLUSTER_NAME="`/usr/local/bin/linode-cli databases postgresql-list --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}') | .label'`"
                                export DB_IDENTIFIER="`/usr/local/bin/linode-cli databases postgresql-list --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}') | .hosts.primary'`"
                                export DB_USERNAME="`/usr/local/bin/linode-cli databases postgresql-creds-view ${database_id} --json | /usr/bin/jq -r '.[].username'`"
                                export DB_PASSWORD="`/usr/local/bin/linode-cli databases postgresql-creds-view ${database_id} --json | /usr/bin/jq -r '.[].password'`"
                                export DB_PORT="`/usr/local/bin/linode-cli databases postgresql-list --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}').port'`"
                                export DB_NAME="${db_name}"

                                /bin/echo "`/usr/local/bin/linode-cli --json databases postgresql-ssl-cert ${database_id} | /usr/bin/jq -r '.[].ca_certificate'`" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DBaaS_CERT
                        fi

                        status "The Values I have retrieved for your database setup are:"
                        status "##########################################################"
                        status "CLUSTERNAME:${CLUSTER_NAME}"
                        status "HOSTNAME:${DB_IDENTIFIER}"
                        status "USERNAME:${DB_USERNAME}"
                        status "PASSWORD:${DB_PASSWORD}"
                        status "DATABASENAME:${DB_NAME}"
                        status "PORT:${DB_PORT}"
                        status "##########################################################"
                        status "If these settings look OK to you, press <enter>"

                        if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
                        then
                                read x
                        fi
                fi
        fi

        #########################################################################################################
        #If you are deploying to vultr provide a setting with the following format in your template
        #DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:mysql:8:lhr:vultr-dbaas-hobbyist-cc-1-25-1:testdb:TestDatabase:2fb13fd1-3145-3127-7132-13f28f1912c1
        #DATABASE_DBaaS_INSTALLATION_TYPE="Postgres:DBAAS:pg:14:lhr:vultr-dbaas-hobbyist-cc-1-25-1:testdb:TestDatabase:2fb13fd1-3145-3127-7132-13f28f1912c1
        #########################################################################################################

        if ( [ "${CLOUDHOST}" = "vultr" ] && [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
        then
                if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep DBAAS`" != "" ] )
                then
                        database_type="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $1}'`"
                        label="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $8}'`"
                        engine="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $3}'`"
                        engine_version="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $4}'`"
                        db_region="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $5}'`"
                        machine_type="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $6}'`"
                        db_name="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $7}'`"
                        vpc_id="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $9}'`"

                        cluster_id="`/usr/bin/vultr database list -o json | /usr/bin/jq -r '.databases[] | select (.label == "'${label}'").id'`"

                        new=""
                        if ( [ "${cluster_id}" = "" ] )
                        then
                                if ( [ "${BYPASS_DB_LAYER}" = "1" ] )
                                then
                                        status "You can't have the BYPASS_DB_LAYER set to on for a newly provisioned database"
                                        status "Do want me to set BYPASS_DB_LAYER to off so that the build will continue (Y|y) otherwise I will have to exit"
                                        read response
                                        if ( [ "${response}" = "y" ] || [ "${response}" = "Y" ] )
                                        then
                                                BYPASS_DB_LAYER="0"
                                        else
                                                /usr/bin/kill -9 $PPID                                        
                                        fi
                                fi

                                status "Creating  database ${label}, with engine: ${engine}, in region: ${db_region} and at size: ${machine_type} please wait..."
                                /usr/bin/vultr database create --database-engine="${engine}" --database-engine-version="${engine_version}" --region="${db_region}" --plan="${machine_type}" --label="${label}" --vpc-id="${vpc_id}"

                                if ( [ "$?" = "0" ] )
                                then
                                        new="newly provisioned"
                                fi
                        else
                                new="previously existing"
                        fi

                        while ( [ "${cluster_id}" = "" ] )
                        do
                                cluster_id="`/usr/bin/vultr database list -o json | /usr/bin/jq -r '.databases[] | select (.label == "'${label}'").id'`"
                                /bin/sleep 10
                                status "Waiting for your new database cluster to be reponsive and online"
                        done

                        status "A ${new} database cluster is available with id ${cluster_id}"

                        export DB_USERNAME="`/usr/bin/vultr database list -o json | /usr/bin/jq -r '.databases[] | select (.id == "'${cluster_id}'").user'`"
                        export DB_PASSWORD="`/usr/bin/vultr database list -o json | /usr/bin/jq -r '.databases[] | select (.id == "'${cluster_id}'").password'`"
                        export DB_IDENTIFIER="`/usr/bin/vultr database list -o json | /usr/bin/jq -r '.databases[] | select (.id == "'${cluster_id}'").host'`"
                        export DB_PORT="`/usr/bin/vultr database list -o json | /usr/bin/jq -r '.databases[] | select (.id == "'${cluster_id}'").port'`"
                        export DB_NAME="${db_name}"

                        status ""
                        status "The rest of the settings for your database are as follows:"
                        status "##########################################################"
                        status "USERNAME:${DB_USERNAME}"
                        status "PASSWORD:${DB_PASSWORD}"
                        status "HOST:${DB_IDENTIFIER}"
                        status "PORT:${DB_PORT}"
                        status "DB NAME:${DB_NAME}"
                        status "##########################################################"
                        status "If these settings look OK to you, press <enter>"
                        
                        if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
                        then
                                read x
                        fi

                        /usr/bin/vultr database update ${cluster_id} --trusted-ips "${VPC_IP_RANGE}"
                fi
        fi
else
        DB_NAME="n`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-8 | /usr/bin/tr '[:upper:]' '[:lower:]'`n"
        DB_PASSWORD="p`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-8 | /usr/bin/tr '[:upper:]' '[:lower:]'`p"
        DB_USERNAME="u`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-8 | /usr/bin/tr '[:upper:]' '[:lower:]'`u"
        DB_IDENTIFIER="self-managed"
fi
      
${BUILD_HOME}/helperscripts/SetVariableValue.sh "DB_NAME=${DB_NAME}"
${BUILD_HOME}/helperscripts/SetVariableValue.sh "DB_PASSWORD=${DB_PASSWORD}"
${BUILD_HOME}/helperscripts/SetVariableValue.sh "DB_USERNAME=${DB_USERNAME}"
${BUILD_HOME}/helperscripts/SetVariableValue.sh "DB_PORT=${DB_PORT}"
${BUILD_HOME}/helperscripts/SetVariableValue.sh "DB_IDENTIFIER=${DB_IDENTIFIER}"
