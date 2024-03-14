#!/bin/sh
############################################################################################
# Author : Peter Winter
# Date   : 13/07/2018
# Description : If Elastic File Systems are offered, see if the user wants to provision one
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
    status "AWS has an Elastic File System Service. This is the prefered way to provision disk space for you application"
    status "assets and you configuration files when using AWS. This is an alternative to the S3 based solution which will"
    status "likely save you from incurring some costs when using AWS"
    status "############################################################################################################"
    status "" 

    status "Do you want to use Elastic File System (make sure that your AWS IAM security keys allow EFS actions in their policy)"
    status "Please enter Y or N"

    read answer

    if ( [ "${answer}" = "Y" ] || [ "${answer}" = "y" ] )
    then
        ENABLE_EFS="1"
    else
        ENABLE_EFS="0"
    fi
    
    if ( [ "${ENABLE_EFS}" = "1" ] )
    then
        aws_region="`/bin/grep region ~/.aws/config | /usr/bin/awk '{print $NF}'`"

        DIRECTORIES_TO_MOUNT="${DIRECTORIES_TO_MOUNT}"
    
        for assettype in `/bin/echo ${DIRECTORIES_TO_MOUNT} | /bin/sed 's/:/ /g'`
        do
            fsprefix="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{ for(i = 1; i <= NF; i++) { print $i; } }' | /usr/bin/cut -c1-3 | /usr/bin/tr '\n' '-' | /bin/sed 's/-//g'`"
            EFS_IDENTIFIER="`/bin/echo ${fsprefix} | /bin/sed 's/\./-/g'`-${assettype}"
            EFS_IDENTIFIER="`/bin/echo ${EFS_IDENTIFIER} | /bin/sed 's/\./-/g'`"

            existing=""

            /usr/bin/aws efs create-file-system --creation-token "${EFS_IDENTIFIER}" --region "${aws_region}"

            while ( [ "$?" != "0" ] )
            do
                status "A file system with creation tokem ${EFS_IDENTIFIER} already exists. If you want to use it as is, please press Y"
                status "Otherwise take action (through the AWS console) to remove the resource before continuing"
                read answer

                if ( [ "${answer}" = "Y" ] || [ "${answer}" = "y" ] )
                then
                    /bin/echo "OK, thanks using existing file system"
                    existing="1"
                else
                    existing="0"    
                    /usr/bin/aws efs create-file-system --creation-token "${EFS_IDENTIFIER}" --region "${aws_region}"
                fi
            done

            if ( [ "${existing}" = "" ] )
            then
                existing="0"
            fi
        
            if ( [ "${existing}" = "0" ] )
            then
                filesystemid="`/usr/bin/aws efs describe-file-systems | /usr/bin/jq '.FileSystems[] | .CreationToken + " " + .FileSystemId' | /bin/sed 's/\"//g' | /bin/grep ${EFS_IDENTIFIER} | /usr/bin/awk '{print $NF}'`"
                security_group_id="`/usr/bin/aws ec2 describe-security-groups | /usr/bin/jq '.SecurityGroups[] | .GroupName + " " + .GroupId' | /bin/grep AgileDeploymentToolkitSecurityGroup | /bin/sed 's/\"//g' | /usr/bin/awk '{print $NF}'`"

                if ( [ "`/usr/bin/aws efs describe-mount-targets --file-system-id ${filesystemid}`" = "" ] )
                then
                    status "There is no mount target for EFS filesystem ${filesystemid}"
                    status "I will try to create one...."
                    status "##################################################################"
                fi
        
                /usr/bin/aws efs create-mount-target --file-system-id ${filesystemid} --subnet-id ${SUBNET_ID} --security-group ${security_group_id} --region ${aws_region}

                while ( [ "$?" != "0" ] )
                do
                    status "Failed to create mount target for EFS system with ID: ${filesystemid} I will sleep for 30 seconds and try again...."
                
                    /bin/sleep 30
                
                    /usr/bin/aws efs create-mount-target --file-system-id ${filesystemid} --subnet-id ${SUBNET_ID} --security-group ${security_group_id} --region ${aws_region}
                    if ( [ "$?" = "0" ] )
                    then
                        status "Successfully created mount target for EFS system with ID: ${filesystemid}" 
                        status "#########################################################################"
                    fi
               done
            fi
         done

         status "You have elastic file systems available with the following identities and mount points"
         status "  FILESYSTEM ID    |         ID            |     NO MOUNT POINTS (must not be 0)"
         status "########################################################################################"
         status "`/usr/bin/aws efs describe-file-systems | /usr/bin/jq '.FileSystems[] | .CreationToken + "      " + .FileSystemId + "      " + (.NumberOfMountTargets|tostring)' | /bin/sed 's/\"//g'`"
         status "Press <enter> to continue with the build"
         read x
    fi
fi
