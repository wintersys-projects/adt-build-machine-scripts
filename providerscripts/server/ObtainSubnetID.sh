#!/bin/sh
############################################################################################
# Author : Peter Winter
# Date   : 13/07/2016
# Description : For providers with subnets, this will obtain the subnet ID
############################################################################################
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
##########################################################################################
##########################################################################################
#set -x

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
    :
fi
if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
    :
fi
if ( [ "${CLOUDHOST}" = "linode" ] )
then
    :
fi
if ( [ "${CLOUDHOST}" = "vultr" ] )
then
    :
fi

if ( [ "${CLOUDHOST}" = "aws" ] )
then
    status ""
    status ""
    status "############################################################################################################"
    status "AWS makes use of subnets. As such we need to select a subnet to use. Please answer the following questions:"
    status "Note: The subnet needs to be in the same VPC as the security group that you set for your EC2 instances"
    status "############################################################################################################"
    status ""

    security_group_id="`/usr/bin/aws ec2 describe-security-groups | /usr/bin/jq '.SecurityGroups[] | .GroupName + " " + .GroupId' | /bin/grep AgileDeploymentToolkitSecurityGroup | /bin/sed 's/\"//g' | /usr/bin/awk '{print $NF}'`"

    if ( [ "${security_group_id}" = "" ] )
    then
         status "I couldn't find a security group to use for your servers. I need to know which VPC you want to use"
         status "Here is a list of VPCs that are available please copy and paste to the prompt the VPC you want to use"
         /usr/bin/aws ec2 describe-vpcs | /usr/bin/jq '.Vpcs[] | .VpcId' | /bin/sed 's/\"//g' >&3
         read vpc_id
         /usr/bin/aws ec2 create-security-group --description "This is the security group for your agile deployment toolkit" --group-name "AgileDeploymentToolkitSecurityGroup" --vpc-id=${vpc_id}
         if ( [ "$?" != "0" ] )
         then
             status "Couldn't create the Security Group"
             exit
         fi
    else
         vpc_id="`/usr/bin/aws ec2 describe-security-groups --group-ids ${security_group_id} | /usr/bin/jq '.SecurityGroups[] | .VpcId' | /bin/sed 's/\"//g'`"
    fi

    export SUBNET_ID="`/bin/grep "SUBNET_ID" ${BUILD_HOME}/buildconfiguration/${CLOUDHOST}/${BUILD_IDENTIFIER} | /usr/bin/awk -F'=' '{print $NF}' | /usr/bin/tr -d '"'`"
    if ( [ "${SUBNET_ID}" != "" ] )
    then
        status "Found a Subnet ID which is set to : ${SUBNET_ID}"
        status "Is this correct (Y|N)?"
        read answer
        if ( [ "${answer}" = "N" ] || [ "${answer}" = "n" ] )
        then
            status "Please enter a subnet ID to use. Your available regions and subnets are:"
            status "REGIONS         SUBNETS         VPC"
            /usr/bin/aws ec2 describe-subnets | /usr/bin/jq '.Subnets[] | .AvailabilityZone + " " + .SubnetId + " " + .VpcId'  | /bin/grep ${vpc_id} | /bin/grep ${REGION_ID} | /bin/sed 's/\"//g' >&3
            status "######################################################"
            status "If no values are listed you do not have any suitable subnets to use, and you will need to create one otherwise:"
            status "Copy and paste the subnet (2nd column value) you want to use below please..."
            read subnet_id
            while ( [ "${subnet_id}" = "" ] )
            do
                status "The subnet id cannot be blank, please try again"
                read subnet_id
            done
            
            if ( [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
            then
                status "You are deploying for DBaaS which means you need to choose a second or additional subnet (in a different availability zone)"
                read subnet_id1
                while ( [ "${subnet_id}" = "${subnet_id1}" ] )
                do
                   status "You can't pick the same subnet twice. Please choose a subnet in a different availability zone to ${subnet_id}"
                   read subnet_id1
                done
            fi
        fi     
        export SUBNET_ID=${subnet_id}
        export SUBNET_ID1=${subnet_id1}
    else
        status "Please enter a subnet ID to use. Your available regions and subnets are:"
        status "REGIONS        SUBNETS           VPC"
        /usr/bin/aws ec2 describe-subnets | /usr/bin/jq '.Subnets[] | .AvailabilityZone + " " + .SubnetId + " " + .VpcId' | /bin/grep ${vpc_id} | /bin/grep ${REGION_ID} | /bin/sed 's/\"//g' >&3
        status "###########################################################"
        status "If no values are listed you do not have any suitable subnets to use, and you will need to create one otherwise:"
        status "Copy and paste the subnet (2nd column value) you want to use below please..."
        read subnet_id
        while ( [ "${subnet_id}" = "" ] )
        do
           status "The subnet id cannot be blank, please try again"
           read subnet_id
        done   
        
        if ( [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
        then
            status "You are deploying for DBaaS which means you need to choose a second or additional subnet (in a different availability zone)"
            status "Please enter the subnet id of a second subnet from the list above"
            read subnet_id1
            while ( [ "${subnet_id}" = "${subnet_id1}" ] )
            do
               status "You can't pick the same subnet twice. Please choose a subnet in a different availability zone to ${subnet_id}"
               read subnet_id1
            done        
        fi
        export SUBNET_ID=${subnet_id}
        export SUBNET_ID1=${subnet_id1}
    fi

    /bin/sed -i '/SUBNET_ID=/d' ${BUILD_HOME}/buildconfiguration/${CLOUDHOST}/${BUILD_IDENTIFIER}
    /bin/echo "export SUBNET_ID=\"${SUBNET_ID}\"" >> ${BUILD_HOME}/buildconfiguration/${CLOUDHOST}/${BUILD_IDENTIFIER}
fi
