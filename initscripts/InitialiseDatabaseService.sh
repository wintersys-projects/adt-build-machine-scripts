#!/bin/sh
########################################################################################
# Author: Peter Winter
# Date  : 12/07/2021
# Description : This is a script which enables you to shortcut the deployment of DBaaS systems
# when using the hardcore or expedited build. You do it by setting the DATABASE_DBaaS_INSTALLATION_TYPE
# variable in the way described for each provider. When set as described for your provider,
# when you make the deployment this script will try and spin up a DBaaS system and use that. 
# Alternative you can pre-provision your DBaaS database using the GUI system if you don't want to wait
# for it to provision whilst the script is running (which for some providers can take a bit of time)
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
        /bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
DATABASE_DBaaS_INSTALLATION_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DATABASE_DBaaS_INSTALLATION_TYPE`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
DATABASE_INSTALLATION_TYPE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DATABASE_INSTALLATION_TYPE`"
DB_INSTALL_MODE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DB_INSTALL_MODE`"
VPC_IP_RANGE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh VPC_IP_RANGE`"
DB_PORT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DB_PORT`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
BUILD_FROM_SNAPSHOT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_FROM_SNAPSHOT`"
MULTI_REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh MULTI_REGION`"
PRIMARY_REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRIMARY_REGION`"
DBaaS_PUBLIC_ENDPOINT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DBaaS_PUBLIC_ENDPOINT`"
DNS_CHOICE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_CHOICE`"


WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"

dbaas_bucket="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`"
dbaas_bucket="${dbaas_bucket}-${DNS_CHOICE}-dbaas"

#See if we are a managed database or not
if ( [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] && ( [ "${MULTI_REGION}" = "0" ] || ( [ "${MULTI_REGION}" = "1" ] && [ "${PRIMARY_REGION}" = "1" ] ) ) )
then
        #########################################################################################################
        #If you are deploying to digitalocean provide a setting with the following format in your template
        #DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:<cluster_engine>:<cluster_region>:<cluster_nodes>:<cluster_size>:<cluster_version>:<cluster_name>:<db_name>:<db_username>:<db_password>:<vpc_id>"
        #DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:mysql:lon1:1:db-s-1vcpu-1gb:8:testdbcluster1:testdb1:testuser1:testpassword1:e265abcb-1295-1d8b-af36-0129f89456c2"
        #DATABASE_DBaaS_INSTALLATION_TYPE="Postgres:DBAAS:pg:lon1:1:db-s-1vcpu-1gb:17:testdbcluster1:testdb1:testuser1:testpassword1:e265abcb-1295-1d8b-af36-0129f89456c2"
        #########################################################################################################


        if ( [ "${CLOUDHOST}" = "digitalocean" ] && [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
        then
                #If we are here then this is a digital ocean deployment
                if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep DBAAS`" != "" ] )
                then
                        #Extract all our configuration values from the DATABASE_DBaaS_INSTALLATION_TYPE setting
                        database_details="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/sed 's/^.*DBAAS://g'`"
                        cluster_engine="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $1}'`"
                        cluster_region="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $2}'`"
                        cluster_nodes="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $3}'`"
                        cluster_size="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $4}'`"
                        cluster_version="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $5}'`"
                        cluster_name="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $6}'`"
                        db_name="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $7}'`"
                        db_username="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $8}'`"
                        db_password="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $9}'`"
                        adt_vpc="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $10}'`"

                        status "Configuring database cluster ${cluster_name}, please wait..."

                        #see if a cluster id already exists for the cluster name we have been given
                        cluster_id1="`/usr/local/bin/doctl databases list -o json | /usr/bin/jq -r '.[] | select (.name == "'${cluster_name}'" and .engine == "'${cluster_engine}'").id'`"
                        cluster_id="`/usr/local/bin/doctl databases list -o json | /usr/bin/jq -r '.[] | select (.name == "'${cluster_name}'").id'`"

                        if ( [ "${cluster_id1}" = "" ] && [ "${cluster_id}" != "" ] )
                        then
                                status "A cluster with the name ${cluster_name} exists for a different database engine. You are trying to deploy with a ${cluster_engine} engine"
                                status "Please choose a different name by updating your template with a distinct name for the new cluster you are trying to deploy"
                                /bin/touch /tmp/END_IT_ALL
                        fi
                        if ( [ "${cluster_id}" = "" ] )
                        then
                                #if the cluster doesn't exist we need to create one, so, we are here
                                if ( [ "${DB_INSTALL_MODE}" = "0" ] || [ "${DB_INSTALL_MODE}" = "2" ] )
                                then
                                        status "You must have DB_INSTALL_MODE set to 1 for a newly provisioned database"
                                        status "Do want me to set DB_INSTALL_MODE to '1' so that the build will continue (Y|y) otherwise I will have to exit"
                                        read response
                                        if ( [ "${response}" = "y" ] || [ "${response}" = "Y" ] )
                                        then
                                                DB_INSTALL_MODE="1"
                                        else
                                                /bin/touch /tmp/END_IT_ALL
                                        fi
                                fi
                                status "Creating the database cluster ${cluster_name}"

                                /usr/local/bin/doctl databases create ${cluster_name} --engine ${cluster_engine} --region ${cluster_region}  --num-nodes ${cluster_nodes} --size ${cluster_size} --version ${cluster_version} --private-network-uuid ${adt_vpc} 

                                if ( [ "$?" != "0" ] )
                                then
                                        status "I had trouble creating the database cluster will have to exit....."
                                        /bin/touch /tmp/END_IT_ALL
                                fi
                        fi

                        #The cluster takes a while to provision, so, wait on it
                        while ( [ "${cluster_id}" = "" ] )
                        do
                                status "Trying to obtain cluster id for the ${cluster_name} cluster..."
                                cluster_id="`/usr/local/bin/doctl databases list -o json | /usr/bin/jq -r '.[] | select (.name == "'${cluster_name}'").id'`"
                                /bin/sleep 30
                        done

                        status "Probing for the database cluster ${cluster_name} to reach online status - Please Wait...."

                        while ( [ "`/usr/local/bin/doctl databases list -o json | /usr/bin/jq -r '.[] | select (.name == "'${cluster_name}'" and .engine == "'${cluster_engine}'").status'`" != "online" ] )
                        do
                                /bin/sleep 5
                        done

                        status "######################################################################################################################################################"
                        status "I have detected that your database cluster has provisioned"
                        status "You might want to check that a database cluster called ${cluster_name} with a database ${db_name} is present using your Digital Ocean gui system"
                        status "######################################################################################################################################################"
                        status "Press <enter> when you are satisfied"

                        if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
                        then
                                read x
                        fi

                        #Allow connections from machines that are in the same VPC as the database cluster
                        if ( [ "`/usr/local/bin/doctl database firewalls list ${cluster_id} -o json | /usr/bin/jq -r '.[] | select (.value == "'${VPC_IP_RANGE}'").id'`" = "" ] )
                        then
                                /usr/local/bin/doctl databases firewalls append ${cluster_id} --rule ip_addr:${VPC_IP_RANGE}
                        fi

                        #have we actioned a MySQL or a Postgres database engine type
                        if ( [ "${cluster_engine}" = "mysql" ] )
                        then
                                export DATABASE_DBaaS_INSTALLATION_TYPE="MySQL"
                        elif ( [ "${cluster_engine}" = "postgres" ] )
                        then
                                export DATABASE_DBaaS_INSTALLATION_TYPE="Postgres"
                        fi

                        #gather together all the configuration properties of our database cluster
                        export DATABASE_INSTALLATION_TYPE="DBaaS"
                        export DATABASE_DBaaS_INSTALLATION_TYPE="${DATABASE_DBaaS_INSTALLATION_TYPE}:${cluster_id}"
                        export DB_IDENTIFIER="private-`/usr/local/bin/doctl databases connection ${cluster_id} -o json | /usr/bin/jq -r '.host'`"
                        export DB_USERNAME="doadmin"
                        #export DB_USERNAME="`/usr/local/bin/doctl databases connection ${cluster_id} -o json | /usr/bin/jq -r '.user'`"
                        export DB_PASSWORD="`/usr/local/bin/doctl databases user get ${cluster_id} doadmin -o json | /usr/bin/jq -r '.[].password'`"
                        export DB_NAME="${db_name}"
                        export DB_PORT="`/usr/local/bin/doctl -o json databases connection ${cluster_id} | /usr/bin/jq -r '.port'`"

                        # record a certificate in case we ever need it
                        /usr/local/bin/doctl databases get-ca ${cluster_id} > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DBaaS_CERT
                fi
        fi

        #########################################################################################################
        #If you are deploying to exoscale provide a setting with the following format in your template
        #DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:mysql:ch-gva-2:hobbyist-2:testdb1:testuser1:testpassword1"
        #DATABASE_DBaaS_INSTALLATION_TYPE="Postgres:DBAAS:pg:ch-gva-2:hobbyist-2:testdb1:testuser1:testpassword1"
        #If you need to you can turn off termination protection as in the following example:
        #exo dbaas update testdb1 -z ch-gva-2 --termination-protection=false
        #########################################################################################################
        if ( [ "${CLOUDHOST}" = "exoscale" ] && [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
        then
                #If we are here then this is an exoscale deployment
                if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep DBAAS`" != "" ] )
                then
                        #extract the database's configuration detaila from DATABASE_DBaaS_INSTALLATION_TYPE

                        database_details="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/sed 's/^.*DBAAS://g'`"
                        database_engine="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $1}'`"
                        database_region="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $2}'`"
                        database_size="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $3}'`"
                        db_name="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $4}'`"
                        db_username="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $5}'`"
                        db_password="`/bin/echo ${database_details} | /usr/bin/awk -F':' '{print $6}'`"


                        if ( [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/.DBAAS_CREDENTIALS ] )
                        then
                                if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${dbaas_bucket}/.DBAAS_CREDENTIALS`" != "" ] )
                                then
                                        ${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${dbaas_bucket}/.DBAAS_CREDENTIALS ${BUILD_HOME}/runtimedata/${CLOUDHOST}
                                fi
                        fi
                        
                        #See if there is an existing database that we can use
                        existing_db_name="`/usr/bin/exo dbaas list -O json | /usr/bin/jq -r '.[]  | select (.name=="'${db_name}'" and .type=="'${database_engine}'").name'`"   
                        new=""
                        if ( [ "${existing_db_name}" = "" ] )
                        then
                                #If we are here there is no existing database and we need to create one
                                if ( [ "${DB_INSTALL_MODE}" = "0" ] || [ "${DB_INSTALL_MODE}" = "2" ] )
                                then
                                        status "You must have DB_INSTALL_MODE set to 1 for a newly provisioned database"
                                        status "Do want me to set DB_INSTALL_MODE to '1' so that the build will continue (Y|y) otherwise I will have to exit"
                                        read response
                                        if ( [ "${response}" = "y" ] || [ "${response}" = "Y" ] )
                                        then
                                                DB_INSTALL_MODE="1"
                                        else
                                                /bin/touch /tmp/END_IT_ALL
                                        fi
                                fi

                                admin_username="adt-dbadmin"
                                admin_password="`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-12`"
                                if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/.DBAAS_CREDENTIALS ] )
                                then
                                        /bin/cp ${BUILD_HOME}/runtimedata/${CLOUDHOST}/.DBAAS_CREDENTIALS ${BUILD_HOME}/runtimedata/${CLOUDHOST}/.DBAAS_CREDENTIALS.$$
                                fi
                                /bin/echo "DB ADMIN USERNAME: ${admin_username}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/.DBAAS_CREDENTIALS
                                /bin/echo "DB ADMIN PASSWORD: ${admin_password}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/.DBAAS_CREDENTIALS

                                ${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh ${dbaas_bucket}
                                ${BUILD_HOME}/providerscripts/datastore/PutToDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/.DBAAS_CREDENTIALS ${dbaas_bucket}

                                status "Creating  database ${db_name}, with engine: ${database_engine}, in region: ${database_region} and at size: ${database_size} please wait..."
                                if ( [ "${database_engine}" = "mysql" ] )
                                then
                                        /usr/bin/exo dbaas create ${database_engine} ${database_size} ${db_name} --zone ${database_region} --mysql-admin-username "${admin_username}" --mysql-admin-password  "${admin_password}"
                                elif ( [ "${database_engine}" = "pg" ] )
                                then
                                        /usr/bin/exo dbaas create ${database_engine} ${database_size} ${db_name} --zone ${database_region} --pg-admin-username "${admin_username}" --pg-admin-password  "${admin_password}"
                                fi

                                if ( [ "$?" = "0" ] )
                                then
                                        new="newly provisioned"
                                fi
                        else
                                new="previously existing"
                                admin_username="`/bin/grep "USERNAME" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/.DBAAS_CREDENTIALS | /usr/bin/awk '{print $NF}'`"
                                admin_password="`/bin/grep "PASSWORD" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/.DBAAS_CREDENTIALS | /usr/bin/awk '{print $NF}'`"
                        fi

                        #Wait for the database to be in a "running" state
                        status "Waiting for your new database cluster to be responsive and online (this may take a little while)"
                        while ( [ "`/usr/bin/exo dbaas show ${db_name} -O json | /usr/bin/jq -r 'select (.name == "'${db_name}'" and .type=="'${database_engine}'").state'`" != "running" ] )
                        do
                                /bin/sleep 10
                        done

                        status ""
                        status "Database with name ${db_name} is now running"
                        status ""

                        #Take note of all of the database's configuration details
                        export DB_USERNAME="${admin_username}"
                        export DB_PASSWORD="${admin_password}"
                        export DATABASE_INSTALLATION_TYPE="DBaaS"
                        export DB_IDENTIFIER="`/usr/bin/exo -O json dbaas show --zone ${database_region} ${db_name} | /usr/bin/jq -r ".${database_engine}.uri_params.host"`"
                        export DB_NAME="${db_name}"
                        export DB_PORT="`/usr/bin/exo -O json dbaas show --zone ${database_region} ${db_name} | /usr/bin/jq -r ".${database_engine}.uri_params.port"`" 
                        export DATABASE_REGION="${database_region}"

                        #Open up fully until we are installed and then tighten up the firewall later on from the autoscaler
                     #   if ( [ "${database_engine}" = "mysql" ] )
                     #   then 
                     #           /usr/bin/exo dbaas update --quiet --zone ${database_region} ${db_name} --mysql-ip-filter="0.0.0.0/0"
                     #   elif ( [ "${database_engine}" = "pg" ] )
                     #   then
                     #           /usr/bin/exo dbaas update --quiet --zone ${database_region} ${db_name} --pg-ip-filter="0.0.0.0/0"
                     #   fi

                        status "Please go to the Exoscale GUI system of your new database and switch off 'STRICT_ALL_TABLES' and 'sql_require_primary_key'"
                        status "Press <enter> once this is done, failure to do this could result in a blocked/failed installation"
                        read x

                        #record a certificate in case we need it
                        /usr/bin/exo dbaas ca-certificate > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DBaaS_CERT
                fi
        fi

        #########################################################################################################
        #DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:<engine>:<region>:<machine_type>:<cluster_size>:<cluster_label>:<db_name>:<db_username>:<db_password>:<vpc_id>:<subnet_id>
        #DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:mysql/8:nl-ams:g6-nanode-1:1:test-cluster:testdb1:testdbuser:gdhf76gdfgsh:266632:266052"
        #DATABASE_DBaaS_INSTALLATION_TYPE="Postgres:DBAAS:<engine>:<region>:<machine_type>:<cluster_size>:<cluster_label>:<db_name>:<db_username>:<db_password>:<vpc_id>:<subnet_id>
        #DATABASE_DBaaS_INSTALLATION_TYPE="Postgres:DBAAS:postgresql/14.4:nl-ams:g6-nanode-1:1:test-cluster:testdb1:testdbuser:gdhf76gdfgsh:266632:266052"
        #########################################################################################################
        if ( [ "${CLOUDHOST}" = "linode" ] && [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
        then
                #If we are here then this is a linode deployment
                if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep DBAAS`" != "" ] )
                then
                        #extract the database's configuration detaila from DATABASE_DBaaS_INSTALLATION_TYPE
                        database_type="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $1}'`"
                        engine="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $3}'`"
                        cluster_size="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $6}'`" 
                        db_region="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $4}'`"
                        machine_type="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $5}'`"
                        label="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $7}'`"
                        db_name="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $8}'`"
                        db_username="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $9}'`"
                        db_password="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $10}'`"
                        vpc_id="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $11}'`"
                        subnet_id="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $12}'`"

                        if ( [ "${MULTI_REGION}" = "1" ] )
                        then
                                public_access="--private_network.public_access true"
                                db_scope_prefix="public-"
                        else
                                public_access="--private_network.public_access false"
                                db_scope_prefix="private-"
                        fi

                        if ( [ "${database_type}" = "MySQL" ] )
                        then
                                #We are obviously a MYSQL database type so check if there is an existing database
                                status "Your database is being provisioned, please wait....."
                                database_id="`/usr/local/bin/linode-cli databases mysql-list --no-defaults --json | jq '.[] | select(.label | contains ("'${label}'")) | .id'`"

                                if ( [ "${database_id}" = "" ] )
                                then
                                        #there is no existing MySQL database so create one
                                        if ( [ "${DB_INSTALL_MODE}" = "0" ] || [ "${DB_INSTALL_MODE}" = "2" ] )
                                        then
                                                status "You must have DB_INSTALL_MODE set to 1 for a newly provisioned database"
                                                status "Do want me to set DB_INSTALL_MODE to '1' so that the build will continue (Y|y) otherwise I will have to exit"
                                                read response
                                                
                                                if ( [ "${response}" = "y" ] || [ "${response}" = "Y" ] )
                                                then
                                                        DB_INSTALL_MODE="1"
                                                else 
                                                        /bin/touch /tmp/END_IT_ALL
                                                fi
                                        fi
                                        /usr/local/bin/linode-cli databases mysql-create --no-defaults --label "${label}" --region "${db_region}" --type "${machine_type}" --cluster_size "${cluster_size}" --engine "${engine}" --ssl_connection "true" --allow_list "0.0.0.0/0" --private_network.vpc_id "${vpc_id}"  --private_network.subnet_id "${subnet_id}" ${public_access}

                                        #Wait for the database to be considered available which is once we can get its id
                                        database_id="`/usr/local/bin/linode-cli databases mysql-list --no-defaults --json | jq -r '.[] | select(.label | contains ("'${label}'")) | .id'`"
                                        while ( [ "${database_id}" = "" ] )
                                        do
                                                status "Attempting to get database id...if I am looking for more than a few minutes something must be wrong"
                                                /bin/sleep 20
                                                database_id="`/usr/local/bin/linode-cli databases mysql-list --no-defaults --json | jq -r '.[] | select(.label | contains ("'${label}'")) | .id'`"
                                        done


                                        #Wait until the database has a status of "active" which can take a while
                                        status "Have got the database id which is: ${database_id}"
                                        status "Its now the wait for the database to become active (this can take a few minutes)"

                                        status="`/usr/local/bin/linode-cli databases mysql-list --no-defaults --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}').status'`"

                                        while ( [ "${status}" != "active" ] )
                                        do
                                                /bin/sleep 20
                                                status="`/usr/local/bin/linode-cli databases mysql-list --no-defaults --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}').status'`"
                                        done
                                else
                                        #open up for the build and tighten once the build is complete
                                        /usr/local/bin/linode-cli databases mysql-update ${database_id} --allow_list "0.0.0.0/0" --no-defaults
                                fi

                                #Take a note of all our database details
                                export CLUSTER_NAME="`/usr/local/bin/linode-cli databases mysql-list --no-defaults --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}') | .label'`" 
                                export DB_IDENTIFIER="${db_scope_prefix}`/usr/local/bin/linode-cli databases mysql-list --no-defaults --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}') | .hosts.primary'`"
                                export DB_USERNAME="`/usr/local/bin/linode-cli databases mysql-creds-view ${database_id} --no-defaults --json | /usr/bin/jq -r '.[].username'`"
                                export DB_PASSWORD="`/usr/local/bin/linode-cli databases mysql-creds-view ${database_id} --no-defaults --json | /usr/bin/jq -r '.[].password'`"
                                export DB_PORT="`/usr/local/bin/linode-cli databases mysql-list --no-defaults --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}').port'`"
                                export DB_NAME="${db_name}"

                                #take a certificate copy in case we need it
                                /bin/echo "`/usr/local/bin/linode-cli databases mysql-ssl-cert ${database_id} --no-defaults --json | /usr/bin/jq -r '.[].ca_certificate'`" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DBaaS_CERT
                        elif ( [ "${database_type}" = "Postgres" ] )
                        then
                                #if we are here then this is a postgres build
                                status "Your database is being provisioned, please wait....."
                                database_id="`/usr/local/bin/linode-cli databases postgresql-list --no-defaults --json | jq '.[] | select(.label | contains ("'${label}'")) | .id'`"

                                if ( [ "${database_id}" = "" ] )
                                then   
                                        #there was no existing database, so, create one
                                        if ( [ "${DB_INSTALL_MODE}" = "0" ] || [ "${DB_INSTALL_MODE}" = "2" ] )
                                        then
                                                status "You must have DB_INSTALL_MODE set to 1 for a newly provisioned database"
                                                status "Do want me to set DB_INSTALL_MODE to '1' so that the build will continue (Y|y) otherwise I will have to exit"
                                                read response
                                                if ( [ "${response}" = "y" ] || [ "${response}" = "Y" ] )
                                                then
                                                        DB_INSTALL_MODE="1"
                                                else
                                                        /bin/touch /tmp/END_IT_ALL
                                                fi
                                        fi
                                        /usr/local/bin/linode-cli databases postgresql-create --no-defaults --label "${label}" --region "${db_region}" --type "${machine_type}" --cluster_size "${cluster_size}" --engine "${engine}" --ssl_connection "true" --allow_list "0.0.0.0/0" --private_network.vpc_id "${vpc_id}"  --private_network.subnet_id "${subnet_id}" ${public_access}

                                        database_id="`/usr/local/bin/linode-cli databases postgresql-list --no-defaults --json | jq -r '.[] | select(.label | contains ("'${label}'")) | .id'`"

                                        while ( [ "${database_id}" = "" ] ) 
                                        do
                                                status "Attempting to get database id...if I am looking for more than a few minutes something must be wrong"
                                                /bin/sleep 20
                                                database_id="`/usr/local/bin/linode-cli databases postgresql-list --no-defaults --json | jq -r '.[] | select(.label | contains ("'${label}'")) | .id'`"
                                        done


                                        #Wait for the database we have provisioned to become active
                                        status "Have got the database id which is: ${database_id}"
                                        status "Its now the wait for the database to become active (this can take a few minutes)"

                                        status="`/usr/local/bin/linode-cli databases postgresql-list --no-defaults --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}').status'`"

                                        while ( [ "${status}" != "active" ] ) 
                                        do
                                                /bin/sleep 20
                                                status="`/usr/local/bin/linode-cli databases postgresql-list --no-defaults --json  | /usr/bin/jq -r '.[] | select (.id == '${database_id}').status'`"
                                        done
                                else
                                        #Open up during the build and tighten up afterwards
                                        /usr/local/bin/linode-cli databases postgresql-update ${database_id} --allow_list "0.0.0.0/0" --no-defaults 
                                fi

                                #take a note of all our configuration settings
                                export CLUSTER_NAME="`/usr/local/bin/linode-cli databases postgresql-list --no-defaults --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}') | .label'`" 
                                export DB_IDENTIFIER="`/usr/local/bin/linode-cli databases postgresql-list --no-defaults --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}') | .hosts.primary'`"
                                export DB_USERNAME="`/usr/local/bin/linode-cli databases postgresql-creds-view ${database_id} --no-defaults --json | /usr/bin/jq -r '.[].username'`"
                                export DB_PASSWORD="`/usr/local/bin/linode-cli databases postgresql-creds-view ${database_id} --no-defaults --json  | /usr/bin/jq -r '.[].password'`"
                                export DB_PORT="`/usr/local/bin/linode-cli databases postgresql-list --no-defaults --json | /usr/bin/jq -r '.[] | select (.id == '${database_id}').port'`"
                                export DB_NAME="${db_name}"

                                #grab the cert, why not, we might need it
                                /bin/echo "`/usr/local/bin/linode-cli databases postgresql-ssl-cert ${database_id} --no-defaults --json | /usr/bin/jq -r '.[].ca_certificate'`" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DBaaS_CERT
                        fi
                fi
        fi

        #########################################################################################################
        #If you are deploying to vultr provide a setting with the following format in your template
        #DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:mysql:8:lhr:vultr-dbaas-hobbyist-cc-1-25-1:testdb:testuser1:testpassword1:TestDatabase:2fb13fd1-3145-3127-7132-13f28f1912c1"
        #DATABASE_DBaaS_INSTALLATION_TYPE="Postgres:DBAAS:pg:17:lhr:vultr-dbaas-hobbyist-cc-1-25-1:testdb:testuser1:testpassword1:TestDatabase:2fb13fd1-3145-3127-7132-13f28f1912c1"
        #########################################################################################################

        if ( [ "${CLOUDHOST}" = "vultr" ] && [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
        then
                #If we are here then this is a vultr database build
                if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep DBAAS`" != "" ] )
                then
                        #extract the database's configuration detaila from DATABASE_DBaaS_INSTALLATION_TYPE
                        database_type="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $1}'`"
                        label="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $10}'`"
                        engine="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $3}'`"
                        engine_version="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $4}'`"
                        db_region="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $5}'`"
                        machine_type="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $6}'`"
                        db_name="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $7}'`"
                        db_username="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $8}'`"
                        db_password="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $9}'`"
                        vpc_id="`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /usr/bin/awk -F':' '{print $11}'`"

                        #See if an existing cluster is available
                        cluster_id="`/usr/bin/vultr database list -o json | /usr/bin/jq -r '.databases[] | select (.label == "'${label}'" and .database_engine == "'${engine}'").id'`"

                        new=""
                        if ( [ "${cluster_id}" = "" ] )
                        then
                                #There was no existing cluster, so create one
                                if ( [ "${BYPASS_DB_LAYER}" = "1" ] )
                                then
                                        status "You can't have the BYPASS_DB_LAYER set to on for a newly provisioned database"
                                        status "Do want me to set BYPASS_DB_LAYER to off so that the build will continue (Y|y) otherwise I will have to exit"
                                        read response
                                        if ( [ "${response}" = "y" ] || [ "${response}" = "Y" ] )
                                        then
                                                DB_INSTALL_MODE="1"
                                        else
                                                /bin/touch /tmp/END_IT_ALL
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

                        #Wait fot the cluster to be online
                        while ( [ "${cluster_id}" = "" ] )
                        do
                                cluster_id="`/usr/bin/vultr database list -o json | /usr/bin/jq -r '.databases[] | select (.label == "'${label}'").id'`"
                                /bin/sleep 10
                                status "Waiting for your new database cluster to be reponsive and online"
                        done

                        status "A ${new} database cluster is available with id ${cluster_id}"

                        #Take a not of all our configuration settings
                        export DB_USERNAME="`/usr/bin/vultr database list -o json | /usr/bin/jq -r '.databases[] | select (.id == "'${cluster_id}'").user'`"  
                        export DB_PASSWORD="`/usr/bin/vultr database list -o json | /usr/bin/jq -r '.databases[] | select (.id == "'${cluster_id}'").password'`"
                        export DB_IDENTIFIER="`/usr/bin/vultr database list -o json | /usr/bin/jq -r '.databases[] | select (.id == "'${cluster_id}'").host'`"
                        export DB_PORT="`/usr/bin/vultr database list -o json | /usr/bin/jq -r '.databases[] | select (.id == "'${cluster_id}'").port'`"
                        export DB_NAME="${db_name}"

                        #Allow connections from our VPC alone
                        /usr/bin/vultr database update ${cluster_id} --trusted-ips "${VPC_IP_RANGE}"
                fi
                status "...Waiting for the database to be in a running state"
                while ( [ "`/usr/bin/vultr database list -o json | /usr/bin/jq -r '.databases[] | select ( .label == "'${label}'" and .database_engine == "'${engine}'").status'`" != "Running" ] )
                do
                        /bin/sleep 10
                done
        fi

        status "Database considered to be in a running state"

        export DB_USERNAME="${DB_USERNAME}:::${db_username}"
        export DB_PASSWORD="${DB_PASSWORD}:::${db_password}"

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
else
        #If we are here then we are self managed so we generate our own username and passwords here which will be used to access
        #our self managed database everywhere in the deployment. These are generated fresh for each deployment
        DB_NAME="n`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-8 | /usr/bin/tr '[:upper:]' '[:lower:]'`n"
        DB_PASSWORD="p`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-8 | /usr/bin/tr '[:upper:]' '[:lower:]'`p"
        DB_USERNAME="u`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-8 | /usr/bin/tr '[:upper:]' '[:lower:]'`u"
        DB_IDENTIFIER="self-managed"
fi

if ( [ "${MULTI_REGION}" = "1" ] && [ "${PRIMARY_REGION}" = "0" ] ) 
then
        multi_region_bucket="`/bin/echo "${WEBSITE_URL}" | /bin/sed 's/\./-/g'`-multi-region"
        if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${multi_region_bucket}/credentials.dat`" != "" ] )
        then
                ${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${multi_region_bucket}/credentials.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials.dat
                DB_NAME="`/bin/grep DB_NAME ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials.dat | /usr/bin/awk -F'=' '{print $NF}'`"
                DB_PASSWORD="`/bin/grep DB_PASSWORD ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials.dat| /usr/bin/awk -F'=' '{print $NF}'`"
                DB_USERNAME="`/bin/grep DB_USERNAME ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials.dat | /usr/bin/awk -F'=' '{print $NF}'`"
                DB_PORT="`/bin/grep DB_PORT ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials.dat | /usr/bin/awk -F'=' '{print $NF}'`"
                DB_IDENTIFIER="${DBaaS_PUBLIC_ENDPOINT}"
        else
                status "Credentials not found when making a multi region deployment to a non primary region"
                /bin/touch /tmp/END_IT_ALL
        fi
fi

if ( [ "${BUILD_FROM_SNAPSHOT}" = "1" ] && [ -f ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/db_credentials.dat ] )
then
        DB_USERNAME="`/bin/grep USERNAME ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/db_credentials.dat | /usr/bin/awk -F':' '{print $NF}'`"
        DB_PASSWORD="`/bin/grep PASSWORD ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/db_credentials.dat | /usr/bin/awk -F':' '{print $NF}'`"
        DB_NAME="`/bin/grep DBNAME ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/db_credentials.dat | /usr/bin/awk -F':' '{print $NF}'`"

        if ( [ ! -d ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots ] )
        then
                /bin/mkdir -p ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots
        fi

        /bin/echo "USERNAME:${DB_USERNAME}" > ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/db_credentials.dat.candidate
        /bin/echo "PASSWORD:${DB_PASSWORD}" >> ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/db_credentials.dat.candidate
        /bin/echo "DBNAME:${DB_NAME}" >> ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/db_credentials.dat.candidate
fi

if ( [ "${MULTI_REGION}" = "1" ] && [ "${PRIMARY_REGION}" = "1" ] )
then
        /bin/echo "DB_NAME=${DB_NAME}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials.dat
        /bin/echo "DB_PASSWORD=${DB_PASSWORD}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials.dat
        /bin/echo "DB_USERNAME=${DB_USERNAME}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials.dat
        /bin/echo "DB_PORT=${DB_PORT}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials.dat

        multi_region_bucket="`/bin/echo "${WEBSITE_URL}" | /bin/sed 's/\./-/g'`-multi-region"
        ${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh ${multi_region_bucket}

        if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${multi_region_bucket}/credentials.dat`" != "" ] )
        then
                ${BUILD_HOME}/providerscripts/datastore/DeleteFromDatastore.sh ${multi_region_bucket}/credentials.dat
        fi

        ${BUILD_HOME}/providerscripts/datastore/PutToDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials.dat ${multi_region_bucket}
fi

#Persist our credentials to the file system to be used at will      
${BUILD_HOME}/helperscripts/SetVariableValue.sh "DB_NAME=${DB_NAME}"
${BUILD_HOME}/helperscripts/SetVariableValue.sh "DB_PASSWORD=${DB_PASSWORD}"
${BUILD_HOME}/helperscripts/SetVariableValue.sh "DB_USERNAME=${DB_USERNAME}"
${BUILD_HOME}/helperscripts/SetVariableValue.sh "DB_PORT=${DB_PORT}"
${BUILD_HOME}/helperscripts/SetVariableValue.sh "DB_IDENTIFIER=${DB_IDENTIFIER}"
