#!/bin/sh
###################################################################################
# Author : Peter Winter
# Date   : 13/07/2016
# Description : This script will spin up a new server of the size, region and os
# specified  on the hosting provider, cloudhost, of choice.
###################################################################################
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
####################################################################################
####################################################################################
#set -x

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

server_size="${1}"
server_name="${2}"

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_CLOUDHOST`"
BUILD_IDENTIFIER="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER`"

BUILDOS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS`"
BUILDOS_VERSION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILDOS_VERSION`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
DDOS_PROTECTION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ENABLE_DDOS_PROTECTION`"
VPC_IP_RANGE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh VPC_IP_RANGE`"
VPC_NAME="`${BUILD_HOME}/helperscripts/GetVariableValue.sh VPC_NAME`"
ACTIVE_FIREWALL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ACTIVE_FIREWALLS`"
ALGORITHM="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ALGORITHM`"
BUILD_FROM_SNAPSHOT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_FROM_SNAPSHOT`"
OS_CHOICE="`${BUILD_HOME}/providerscripts/server/GetOperatingSystemVersion.sh ${CLOUDHOST} ${BUILDOS} ${BUILDOS_VERSION} | /bin/sed "s/'//g"`"

if ( [ "`/bin/echo ${server_name} | /bin/grep -E "\-as-"`" != "" ] )
then


	if ( [ -f  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml ] )
	then
		server_name_match="`/bin/echo ${server_name} | /usr/bin/awk -F'-' 'NF{NF--};1' | /bin/sed 's/ /-/g'`"
		/bin/sed -i "s/XXXXAUTOSCALER_HOSTNAMEXXXX/${server_name}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
		/bin/sed -i "s/${server_name_match}.*$/${server_name}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml
		
		if ( [ "${CLOUDHOST}" = "linode" ] )
		then
			cloud_config="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml | /usr/bin/base64 -w 0`"
		else 
			cloud_config="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml"
		fi
	fi
elif ( [ "`/bin/echo ${server_name} | /bin/grep -E "^ws-"`" != "" ] )
then
	if ( [ -f  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml ] )
	then
		server_name_match="`/bin/echo ${server_name} | /usr/bin/awk -F'-' 'NF{NF--};1' | /bin/sed 's/ /-/g'`"
		/bin/sed -i "s/XXXXWEBSERVER_HOSTNAMEXXXX/${server_name}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
		/bin/sed -i "s/${server_name_match}.*$/${server_name}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
		
		if ( [ "${CLOUDHOST}" = "linode" ] )
		then
			cloud_config="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml | /usr/bin/base64 -w 0`"
		else 
			cloud_config="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml"
		fi       
	fi
elif ( [ "`/bin/echo ${server_name} | /bin/grep -E "^db-"`" != "" ] )
then
	if ( [ -f  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml ] )
	then
		/bin/sed -i "s/XXXXDATABASE_HOSTNAMEXXXX/${server_name}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml
		if ( [ "${CLOUDHOST}" = "linode" ] )
		then
			cloud_config="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml | /usr/bin/base64 -w 0`"
		else 
			cloud_config="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/database.yaml"
		fi           
	fi
elif ( [ "`/bin/echo ${server_name} | /bin/grep -E "^auth-"`" != "" ] )
then
	if ( [ -f  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/authenticator.yaml ] )
	then
		/bin/sed -i "s/XXXXAUTHENTICATOR_HOSTNAMEXXXX/${server_name}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/authenticator.yaml
		if ( [ "${CLOUDHOST}" = "linode" ] )
		then
			cloud_config="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/authenticator.yaml | /usr/bin/base64 -w 0`"
		else 
			cloud_config="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/authenticator.yaml"
		fi           
	fi
elif ( [ "`/bin/echo ${server_name} | /bin/grep -E "\-rp-"`" != "" ] )
then
	if ( [ -f  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/reverseproxy.yaml ] )
	then		
		server_name_match="`/bin/echo ${server_name} | /usr/bin/awk -F'-' 'NF{NF--};1' | /bin/sed 's/ /-/g'`"
		/bin/sed -i "s/XXXXREVERSEPROXY_HOSTNAMEXXXX/${server_name}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/reverseproxy.yaml
		/bin/sed -i "s/${server_name_match}.*$/${server_name}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/reverseproxy.yaml
		
		if ( [ "${CLOUDHOST}" = "linode" ] )
		then
			cloud_config="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/reverseproxy.yaml | /usr/bin/base64 -w 0`"
		else 
			cloud_config="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/reverseproxy.yaml"
		fi           
	fi
fi

if ( [ "`/bin/echo ${server_name} | /bin/grep -E "\-as-"`" != "" ] )
then
	machine_type="adt-autoscaler"
	if ( [ "${BUILD_FROM_SNAPSHOT}" = "1" ] && [ -f ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat ] )
	then
		snapshot_id="`/bin/grep autoscaler ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat | /usr/bin/awk -F':' '{print $NF}'`"
	 	status "Deploying autoscaler machine from snapshot with ID ${snapshot_id}"
 	fi
elif ( [ "`/bin/echo ${server_name} | /bin/grep -E "^ws-"`" != "" ] )
then
	machine_type="adt-webserver"
	if (  [ "${BUILD_FROM_SNAPSHOT}" = "1" ] && [ -f ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat ] )
	then
		snapshot_id="`/bin/grep webserver ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat | /usr/bin/awk -F':' '{print $NF}'`"
	 	status "Deploying webserver machine from snapshot with ID ${snapshot_id}"	
		${BUILD_HOME}/helperscripts/SetVariableValue.sh SNAPSHOT_ID=${snapshot_id}
 	fi
elif ( [ "`/bin/echo ${server_name} | /bin/grep -E "^db-"`" != "" ] )
then
	machine_type="adt-database"
	if (  [ "${BUILD_FROM_SNAPSHOT}" = "1" ] && [ -f ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat ] )
	then
		snapshot_id="`/bin/grep database ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat | /usr/bin/awk -F':' '{print $NF}'`"
		status "Deploying database machine from snapshot with ID ${snapshot_id}"	
 	fi
elif ( [ "`/bin/echo ${server_name} | /bin/grep -E "^auth-"`" != "" ] )
then
	machine_type="adt-authenticator"
	if (  [ "${BUILD_FROM_SNAPSHOT}" = "1" ] && [ -f ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat ] )
	then
		snapshot_id="`/bin/grep authenticator ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat | /usr/bin/awk -F':' '{print $NF}'`"
		status "Deploying authenticator machine from snapshot with ID ${snapshot_id}"	
 	fi
elif ( [ "`/bin/echo ${server_name} | /bin/grep -E "\-rp-"`" != "" ] )
then
	machine_type="adt-reverseproxy"
	if (  [ "${BUILD_FROM_SNAPSHOT}" = "1" ] && [ -f ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat ] )
	then
		snapshot_id="`/bin/grep reverseproxy ${BUILD_HOME}/runtimedata/wholemachinesnapshots/${WEBSITE_URL}/snapshots/snapshot_ids.dat | /usr/bin/awk -F':' '{print $NF}'`"
		status "Deploying reverse proxy machine from snapshot with ID ${snapshot_id}"	
 	fi
fi

if ( [ "${CLOUDHOST}" = "exoscale" ] || [ "${CLOUDHOST}" = "linode" ] || [ "${CLOUDHOST}" = "vultr" ] )
then
	firewall_id="`${BUILD_HOME}/providerscripts/security/firewall/ConfigureNativeFirewall.sh "${machine_type}" | /bin/grep 'ADT_FIREWALL_ID:' | /usr/bin/awk -F':' '{print  $NF}'`"
fi

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
	if ( [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/SSH_KEY_ASSIGNED ] )
	then
		/bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/SSH_KEY_ASSIGNED
		key_id="`/usr/local/bin/doctl compute ssh-key list -o json | /usr/bin/jq -r '.[] | select ( .name == "AGILE_TOOLKIT_PUBLIC_KEY-'${BUILD_IDENTIFIER}'" ).id'`"
		if ( [ "${key_id}" != "" ] )
		then
			/usr/local/bin/doctl compute ssh-key delete ${key_id} --force
		fi

		/usr/local/bin/doctl compute ssh-key create "AGILE_TOOLKIT_PUBLIC_KEY-${BUILD_IDENTIFIER}" --public-key "`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/keys/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub`"

	fi

	while ( [ "`/usr/local/bin/doctl compute ssh-key list -o json | /usr/bin/jq '.[] | select (.name == "AGILE_TOOLKIT_PUBLIC_KEY-'${BUILD_IDENTIFIER}'").id'`" = "" ] )
	do
		/bin/sleep 2
	done

	key_id="`/usr/local/bin/doctl compute ssh-key list -o json | /usr/bin/jq '.[] | select (.name == "AGILE_TOOLKIT_PUBLIC_KEY-'${BUILD_IDENTIFIER}'").id'`" 

	if ( [ "${key_id}" = "" ] )
	then
		/bin/touch /tmp/END_IT_ALL
	fi

	if ( [ "`/usr/local/bin/doctl vpcs list -o json | /usr/bin/jq -r '.[] | select (.region == "'${REGION}'") | select (.name == ("'${VPC_NAME}'")).id'`" = "" ] )
	then
		/usr/local/bin/doctl vpcs create --name "${VPC_NAME}" --region "${REGION}" --ip-range "${VPC_IP_RANGE}"
	fi

	vpc_id="`/usr/local/bin/doctl vpcs list -o json | /usr/bin/jq -r '.[] | select (.region == "'${REGION}'") | select (.name == ("'${VPC_NAME}'")).id'`"

	image="--image ${OS_CHOICE}"
	if ( [ "${BUILD_FROM_SNAPSHOT}" = "1" ] )
	then
		image="--image ${snapshot_id}"
  	fi

	/usr/local/bin/doctl compute droplet create "${server_name}" --ssh-keys "${key_id}" --size "${server_size}" ${image} --region "${REGION}"  --vpc-uuid "${vpc_id}" --user-data-file "${cloud_config}"
fi

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
	template_visibility="--template-visibility public"

	if ( [ "${BUILD_FROM_SNAPSHOT}" = "1" ] )
	then
		OS_CHOICE="${snapshot_id}"
		template_visibility="--template-visibility private"
	fi
 		
	user_data="--cloud-init ${cloud_config}"

	firewall=""

	if ( [ "${ACTIVE_FIREWALL}" = "2" ] || [ "${ACTIVE_FIREWALL}" = "3" ] )
	then
		firewall=" --security-group ${firewall_id}"
	fi

	/usr/bin/exo compute instance create ${server_name} --instance-type standard.${server_size} ${firewall} --template "${OS_CHOICE}" --zone ${REGION}  ${template_visibility} ${user_data}

	if ( [ "`/usr/bin/exo compute private-network list -O json | /usr/bin/jq -r '.[] | select (.name == "adt_private_net_'${REGION}'").id'`" = "" ] )
	then
		/usr/bin/exo compute private-network create adt_private_net_${REGION} --zone ${REGION} --start-ip 10.0.0.20 --end-ip 10.0.0.200 --netmask 255.255.255.0
	fi
	/usr/bin/exo compute instance private-network attach  ${server_name} adt_private_net_${REGION} --zone ${REGION}
fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then
	if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/EMERGENCY_PASSWORD ] )
	then    
		emergency_password="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/EMERGENCY_PASSWORD`"
	else
		emergency_password="`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-11`"
		/bin/echo "${emergency_password}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/EMERGENCY_PASSWORD
    fi

	if ( [ "`/usr/local/bin/linode-cli vpcs list --no-defaults --json | /usr/bin/jq -r '.[] | select (.label == "'${VPC_NAME}'").id'`" = "" ] )
	then
		/usr/local/bin/linode-cli vpcs create --no-defaults --label ${VPC_NAME} --region ${REGION} --subnets.label adt-subnet --subnets.ipv4 ${VPC_IP_RANGE}
	fi

	vpc_id="`/usr/local/bin/linode-cli vpcs list --no-defaults --json | /usr/bin/jq -r '.[] | select (.label == "'${VPC_NAME}'").id'`"
	subnet_id="`/usr/local/bin/linode-cli vpcs subnets-list ${vpc_id} --no-defaults --json  | /usr/bin/jq  -r '.[] | select (.label == "adt-subnet").id'`"

	image="--image ${OS_CHOICE}" 
	if ( [ "${BUILD_FROM_SNAPSHOT}" = "1" ] )
	then
		image="--image ${snapshot_id}"
	fi

	user_data="--metadata.user_data ${cloud_config}"	

	if ( [ "${ACTIVE_FIREWALL}" = "2" ] || [ "${ACTIVE_FIREWALL}" = "3" ] )
	then
		/usr/local/bin/linode-cli linodes create  --root_pass "${emergency_password}" --region ${REGION} ${image} --type ${server_size} --label "${server_name}" --no-defaults --interface_generation "linode" --interfaces ' [ { "purpose": "public", "firewall_id": '${firewall_id}', "default_route": { "ipv4": true }, "public": { "ipv4": { "addresses": [ { "address": "auto", "primary": true } ] } } }, { "purpose": "vpc", "firewall_id": '${firewall_id}',  "vpc": { "ipv4": { "addresses": [ { "address": "auto", "primary": true } ] } , "subnet_id": '${subnet_id}' } } ]' ${user_data} --disk_encryption "enabled"
	else
		/usr/local/bin/linode-cli linodes create  --authorized_keys "${key}" --root_pass "${emergency_password}" --region ${REGION} ${image} --type ${server_size} --label "${server_name}" --no-defaults --interface_generation "linode" --interfaces ' [ { "purpose": "public", "default_route": { "ipv4": true }, "public": { "ipv4": { "addresses": [ { "address": "auto", "primary": true } ] } } }, { "purpose": "vpc",  "vpc": { "ipv4": { "addresses": [ { "address": "auto", "primary": true } ] } , "subnet_id": '${subnet_id}' } } ]' ${user_data} --disk_encryption "enabled"
	fi        
fi

if (  [ "${CLOUDHOST}" = "vultr" ] )
then
	if ( [ "`/usr/bin/vultr vpc list -o json | /usr/bin/jq -r '.vpcs[] | select (.description == "'${VPC_NAME}'").id'`" = "" ] )
	then
		# ip_block="`/bin/echo ${VPC_IP_RANGE} | /usr/bin/awk -F'/' '{print $1}'`"
		# /usr/bin/vultr vpc2 create --region="${REGION}" --description="adt-vpc" --ip-type="v4" --ip-block="${ip_block}" --prefix-length="16"
		subnet="`/bin/echo ${VPC_IP_RANGE} | /usr/bin/awk -F'/' '{print $1}'`"
		size="`/bin/echo ${VPC_IP_RANGE} | /usr/bin/awk -F'/' '{print $2}'`"
		/usr/bin/vultr vpc create --region="${REGION}" --description="${VPC_NAME}" --subnet="${subnet}" --size="${size}"
	fi

	# vpc_id="`/usr/bin/vultr vpc2 list -o json | /usr/bin/jq -r '.vpcs[] | select (.description == "'${VPC_NAME}'").id'`"
	vpc_id="`/usr/bin/vultr vpc list -o json | /usr/bin/jq -r '.vpcs[] | select (.description == "'${VPC_NAME}'").id'`"
	OS_CHOICE="`/usr/bin/vultr os list -o json | /usr/bin/jq -r --arg os_choice "${OS_CHOICE}" '.os[] | select (.name | contains ($os_choice)).id'`"
	cloud_config="`/bin/cat ${cloud_config}`"
	
 	snapshot=""
	os="--os=${OS_CHOICE}"

	if ( [ "${BUILD_FROM_SNAPSHOT}" = "1" ] )
	then
		snapshot="--snapshot=${snapshot_id}"
		os=""
	fi

	if ( [ "${DDOS_PROTECTION}" = "1" ] )
	then
		ddos="--ddos=true"
	else
		ddos="--ddos=false"
	fi

	firewall=""

	if ( [ "${ACTIVE_FIREWALL}" = "2" ] || [ "${ACTIVE_FIREWALL}" = "3" ] )
	then
		firewall="--firewall-group ${firewall_id}"
	fi

	/usr/bin/vultr instance create --label="${server_name}" --region="${REGION}" --plan="${server_size}" ${snapshot} ${os} --ipv6=false ${firewall} ${ddos} --userdata="${cloud_config}" --vpc-enable --vpc-ids ${vpc_id} 
fi

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
	${BUILD_HOME}/providerscripts/security/firewall/ConfigureNativeFirewall.sh "${machine_type}" 
fi
