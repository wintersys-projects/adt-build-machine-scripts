#!/bin/sh
#############################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This script will get the version of the operating system that we are building for
#############################################################################################
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
############################################################################################
############################################################################################
#set -x

instance_size="${1}"
cloudhost="${2}"
buildos="${3}"
buildos_version="${4}"

if ( [ "${cloudhost}" = "digitalocean" ] )
then
    if ( [ "${buildos}" = "ubuntu" ] )
    then
        buildos_version="`/bin/echo ${buildos_version} | /bin/sed 's/\./-/g'`"
        /bin/echo "ubuntu-${buildos_version}-x64"
    elif ( [ "${buildos}" = "debian" ] )
    then
        /bin/echo "debian-${buildos_version}-x64"
    fi
fi

if ( [ "${cloudhost}" = "exoscale" ] )
then
    if ( [ "${buildos}" = "ubuntu" ] )
    then
        if ( [ "${buildos_version}" = "20.04" ] )
        then
            /bin/echo "Linux Ubuntu ${buildos_version} LTS 64-bit"
        elif ( [ "${buildos_version}" = "22.04" ] )
        then
            /bin/echo "Linux Ubuntu ${buildos_version} LTS 64-bit"
        fi
    elif ( [ "${buildos}" = "debian" ] )
    then
        if ( [ "${buildos_version}" = "11" ] )
        then 
            /bin/echo "Linux Debian ${buildos_version} (Bullseye) 64-bit"
        elif ( [ "${buildos_version}" = "12" ] )
        then
            /bin/echo "Linux Debian ${buildos_version} (Bookworm) 64-bit"
        fi
    fi
fi

if ( [ "${cloudhost}" = "linode" ] )
then
    if ( [ "${buildos}" = "ubuntu" ] )
    then
        /bin/echo "Ubuntu ${buildos_version}"
    elif ( [ "${buildos}" = "debian" ] )
    then
        /bin/echo "Debian ${buildos_version}"
    fi
fi

if ( [ "${cloudhost}" = "vultr" ] )
then
    if ( [ "${buildos}" = "ubuntu" ] )
    then
        /bin/echo "Ubuntu ${buildos_version} LTS x64"
    elif ( [ "${buildos}" = "debian" ] )
    then
        /bin/echo "Debian ${buildos_version} x64"
    fi
fi

if ( [ "${cloudhost}" = "aws" ] )
then
    if ( [ "${OS_TYPE}" != "" ] )
    then
        /bin/echo "${OS_TYPE}"
    elif ( [ "${buildos}" = "ubuntu" ] )
    then
        /bin/echo "################################################################################################################" >&3
        /bin/echo "Please enter the ami in the format ami-xxxxxxxxxxxxxxx that you wish to use for this ubuntu based machine" >&3
        /bin/echo "You can find ami identifiers here: https://cloud-images.ubuntu.com/locator/ec2" >&3
        /bin/echo "You are expecting an installation of ${buildos_version} of ubuntu" >&3
        /bin/echo "Make sure that it supports your intended PHP version (if any) and is in the correct AWS region" >&3
        /bin/echo "################################################################################################################" >&3
        /bin/echo "OK, please enter your prefered AMI identifier" >&3
        read ami_identifier
    
        while ( [ "${ami_identifier}" = "" ] )
        do
            /bin/echo "You need to select an identifier, please try again...."
            read ami_identifier
        done
    
        /bin/cp /dev/null /dev/stdout
        /bin/echo "${ami_identifier}"
elif ( [ "${buildos}" = "debian" ] )
    then
        if ( [ "${buildos_version}" = "10" ] )
        then
            /bin/echo "     AMI                            OS" >&3
            /bin/echo "=====================================================" >&3
            /usr/bin/aws ec2 describe-images --owners 136693071363 | /usr/bin/jq '.Images[] | .ImageId + "  |   " + .Name' | /bin/grep debian-10-amd64 | /bin/grep "2023\|2024\|2025\|2026\|2027\|2028\|2029\|2030" | /bin/sed 's/"//g' >&3
            /bin/echo "Please enter the ami identifier for the OS you wish to use" >&3
            read ami_identifier  
            while ( [ "${ami_identifier}" = "" ] )
            do
                /bin/echo "You need to select an identifier, please try again...."
                read ami_identifier
            done
            /bin/cp /dev/null /dev/stdout
            /bin/echo "${ami_identifier}"
        fi
        if ( [ "${buildos_version}" = "11" ] )
        then
            /bin/echo "     AMI                             OS" >&3
            /bin/echo "======================================================" >&3
            /usr/bin/aws ec2 describe-images --owners 136693071363 | /usr/bin/jq '.Images[] | .ImageId + "  |   " + .Name' | /bin/grep debian-11-amd64 | /bin/grep "2023\|2024\|2025\|2026\|2027\|2028\|2029\|2030" | /bin/sed 's/"//g' >&3
            /bin/echo "Please enter the ami identifier for the OS you wish to use" >&3
            read ami_identifier          
            while ( [ "${ami_identifier}" = "" ] )
            do
                /bin/echo "You need to select an identifier, please try again...."
                read ami_identifier
            done      
            /bin/cp /dev/null /dev/stdout
            /bin/echo "${ami_identifier}"
        fi
        if ( [ "${buildos_version}" = "12" ] )
        then
            /bin/echo "     AMI                             OS" >&3
            /bin/echo "======================================================" >&3
            /usr/bin/aws ec2 describe-images --owners 136693071363 | /usr/bin/jq '.Images[] | .ImageId + "  |   " + .Name' | /bin/grep debian-12-amd64 | /bin/grep "2023\|2024\|2025\|2026\|2027\|2028\|2029\|2030" | /bin/sed 's/"//g' >&3
            /bin/echo "Please enter the ami identifier for the OS you wish to use" >&3
            read ami_identifier          
            while ( [ "${ami_identifier}" = "" ] )
            do
                /bin/echo "You need to select an identifier, please try again...."
                read ami_identifier
            done      
            /bin/cp /dev/null /dev/stdout
            /bin/echo "${ami_identifier}"
        fi
    fi
fi



