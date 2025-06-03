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

OS_CHOICE="`${BUILD_HOME}/providerscripts/cloudhost/GetOperatingSystemVersion.sh ${CLOUDHOST} ${BUILDOS} ${BUILDOS_VERSION} | /bin/sed "s/'//g"`"
KEY_ID="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/PUBLICKEYID`"

if ( [ "`/bin/echo ${server_name} | /bin/grep -E "\-as-"`" != "" ] )
then
	if ( [ -f  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml ] )
	then
		/bin/sed -i "s/XXXXAUTOSCALER_HOSTNAMEXXXX/${server_name}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/autoscaler.yaml

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
		/bin/sed -i "s/XXXXWEBSERVER_HOSTNAMEXXXX/${server_name}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/webserver.yaml
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
elif ( [ "`/bin/echo ${server_name} | /bin/grep -E "^rp-"`" != "" ] )
then
	if ( [ -f  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/reverseproxy.yaml ] )
	then
		/bin/sed -i "s/XXXXREVERSEPROXY_HOSTNAMEXXXX/${server_name}/g" ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/reverseproxy.yaml
		if ( [ "${CLOUDHOST}" = "linode" ] )
		then
			cloud_config="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/reverseproxy.yaml | /usr/bin/base64 -w 0`"
		else 
			cloud_config="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/cloud-init/reverseproxy.yaml"
		fi           
	fi
fi

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
	if ( [ "`/usr/local/bin/doctl vpcs list -o json | /usr/bin/jq -r '.[] | select (.region == "'${REGION}'") | select (.name | contains ("'${VPC_NAME}'")).id'`" ] )
	then
		/usr/local/bin/doctl vpcs create --name "${VPC_NAME}" --region "${REGION}" --ip-range "${VPC_IP_RANGE}"
	fi

	vpc_id="`/usr/local/bin/doctl vpcs list -o json | /usr/bin/jq -r '.[] | select (.region == "'${REGION}'") | select (.name | contains ("'${VPC_NAME}'")).id'`"
 	/usr/local/bin/doctl compute droplet create "${server_name}" --size "${server_size}" --image "${OS_CHOICE}"  --region "${REGION}" --ssh-keys "${KEY_ID}" --vpc-uuid "${vpc_id}" --user-data-file "${cloud_config}"
fi

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
	template_visibility=" --template-visibility public "
	/usr/bin/exo compute instance create ${server_name} --instance-type standard.${server_size} --template "${OS_CHOICE}" --zone ${REGION} --ssh-key ${KEY_ID} ${template_visibilty} --cloud-init "${cloud_config}"
        
	if ( [ "`/usr/bin/exo compute private-network list -O json | /usr/bin/jq -r '.[] | select (.name == "adt_private_net_'${REGION}'").id'`" = "" ] )
	then
		/usr/bin/exo compute private-network create adt_private_net_${REGION} --zone ${REGION} --start-ip 10.0.0.20 --end-ip 10.0.0.200 --netmask 255.255.255.0
	fi
	/usr/bin/exo compute instance private-network attach  ${server_name} adt_private_net_${REGION} --zone ${REGION} 
fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then
        key="`/usr/local/bin/linode-cli --json sshkeys view ${KEY_ID} | /usr/bin/jq -r '.[].ssh_key'`"
        emergency_password="`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-30`"
        /bin/echo "${emergency_password}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/EMERGENCY_PASSWORD

        if ( [ "`/usr/local/bin/linode-cli --json vpcs list | /usr/bin/jq -r '.[] | select (.label == "'${VPC_NAME}'").id'`" = "" ] )
        then
                /usr/local/bin/linode-cli vpcs create --label ${VPC_NAME} --region ${REGION} --subnets.label adt-subnet --subnets.ipv4 ${VPC_IP_RANGE}
        fi

        if ( [ "`/bin/echo ${server_name} | /bin/grep -E "\-as-"`" != "" ] )
        then
                firewall_id="`${BUILD_HOME}/providerscripts/security/firewall/ConfigurreNativeFirewall.sh "adt-autoscaler" | /bin/grep 'ADT_FIREWALL_ID:' | /usr/bin/awk -F':' '{print  $NF}'`"
        elif ( [ "`/bin/echo ${server_name} | /bin/grep -E "^ws-"`" != "" ] )
        then
                firewall_id="`${BUILD_HOME}/providerscripts/security/firewall/ConfigurreNativeFirewall.sh "adt-webserver" | /bin/grep 'ADT_FIREWALL_ID:' | /usr/bin/awk -F':' '{print  $NF}'`"
        elif ( [ "`/bin/echo ${server_name} | /bin/grep -E "^db-"`" != "" ] )
        then
                firewall_id="`${BUILD_HOME}/providerscripts/security/firewall/ConfigurreNativeFirewall.sh "adt-database" | /bin/grep 'ADT_FIREWALL_ID:' | /usr/bin/awk -F':' '{print  $NF}'`"
        elif ( [ "`/bin/echo ${server_name} | /bin/grep -E "^auth-"`" != "" ] )
        then
                firewall_id="`${BUILD_HOME}/providerscripts/security/firewall/ConfigurreNativeFirewall.sh "adt-authenticator" | /bin/grep 'ADT_FIREWALL_ID:' | /usr/bin/awk -F':' '{print  $NF}'`"
        elif ( [ "`/bin/echo ${server_name} | /bin/grep -E "^rp-"`" != "" ] )
        then
                firewall_id="`${BUILD_HOME}/providerscripts/security/firewall/ConfigurreNativeFirewall.sh "adt-remoteproxy" | /bin/grep 'ADT_FIREWALL_ID:' | /usr/bin/awk -F':' '{print  $NF}'`"
        fi
 
        vpc_id="`/usr/local/bin/linode-cli vpcs list --json | /usr/bin/jq -r '.[] | select (.label == "'${VPC_NAME}'").id'`"
        subnet_id="`/usr/local/bin/linode-cli --json vpcs subnets-list ${vpc_id} | /usr/bin/jq  -r '.[] | select (.label == "adt-subnet").id'`"
        /usr/local/bin/linode-cli linodes create --authorized_keys "${key}" --root_pass "${emergency_password}" --region ${REGION} --image "${OS_CHOICE}" --type ${server_size} --label "${server_name}" --no-defaults --interface_generation "linode" --interfaces ' [ { "purpose": "public", "firewall_id": '${firewall_id}', "default_route": { "ipv4": true }, "public": { "ipv4": { "addresses": [ { "address": "auto", "primary": true } ] } } }, { "purpose": "vpc", "firewall_id": '${firewall_id}',  "vpc": { "ipv4": { "addresses": [ { "address": "auto", "primary": true } ] } , "subnet_id": '${subnet_id}' } } ]' --metadata.user_data "${cloud_config}" --disk_encryption "enabled"
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
	OS_CHOICE="`/usr/bin/vultr os list -o json | /usr/bin/jq -r '.os[] | select (.name | contains ("'"${OS_CHOICE}"'")).id'`"
   
	if ( [ "${DDOS_PROTECTION}" = "1" ] )
	then
		/usr/bin/vultr instance create --label="${server_name}" --region="${REGION}" --plan="${server_size}" --os="${OS_CHOICE}" --ipv6=false -s ${KEY_ID} --ddos=true --userdata="`/bin/cat ${cloud_config}`" --vpc-enable --vpc-ids ${vpc_id}
	else
		/usr/bin/vultr instance create --label="${server_name}" --region="${REGION}" --plan="${server_size}" --os="${OS_CHOICE}" --ipv6=false -s ${KEY_ID} --ddos=false --userdata="`/bin/cat ${cloud_config}`" --vpc-enable --vpc-ids ${vpc_id}
	fi    
fi
