#!/bin/sh
######################################################################################################
# Description: By creating a file: s3://authip-adt-allowed-<ip-address>/authorised-ips.dat in your S3 datastore with a list
# of ipaddresses, you can allow only machines with your listed ip addresses to access your build machine.
# The file authorised-ips.dat should be formatted with ip addresses on successive lines, for example:
#
# 111.111.111.111
# 222.222.222.222
#
# Would allow machines with ip addresses 111.111.111.111 and 222.222.222.222 to connect to your build machine
# over ssh. 
# The advice is to also manually add your build machine to a native firewall (the firewall provided by your
# cloudhost) only allowing access to your specific SSH port and your specific ip addresses. This means
# that your build machine is double firewalled and also you can add your laptop ip address to your native
# firewall when you start work for the day and need access to your build machine and you can close the machine
# off completely using the native firewall by setting the ip of your laptop to "deny" at the end of the day.
# That way your build machine is completely firewalled off except when you are working with it.
# Author: Peter Winter
# Date: 17/01/2021
#######################################################################################################
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
#set -x

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
BUILD_IDENTIFIER="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER`"
ip="`${BUILD_HOME}/helperscripts/GetBuildMachineIP.sh`"
${BUILD_HOME}/providerscripts/server/GetServerName.sh ${ip} "${CLOUDHOST}"
CLOUDHOST="`/bin/cat ${BUILD_HOME}/runtimedata/BUILD_MACHINE_CLOUDHOST`"
BUILDMACHINE_USER="`/bin/cat /root/buildmachine_user.dat`"

#If we are running the build from our personal laptop, then, we don't need to set up any firewall rules so we simply exit
#This isn't a foolproof way for establishing that we are on a laptop if there's additional files or directories in 
#${BUILD_HOME}/templatedconfigurations/templates that might mess us up and if you are running a build machine on a 3rd
#party unsupported VPS cloudhost that could cause a problem also because this will think that that machine is a laptop
#a very simple work around if you are using an unsupported cloudhost to run your build process is to create a file
#in the ${BUILD_HOME}/templatedconfigurations/templates templates directory for your unsupported cloudhost for example
#Rackspace or google that will match against the whois query
cloud_providers="`/bin/ls ${BUILD_HOME}/templatedconfigurations/templates`"
on_laptop="1"
for cloud_provider in ${cloud_providers}
do
        if ( [ "`/usr/bin/whois ${ip} | /bin/grep ${cloud_provider}`" != "" ] )
        then
                on_laptop="0"
        fi
done

if ( [ "${on_laptop}" = "1" ] )
then
        /bin/touch ${BUILD_HOME}/runtimedata/BUILDING_ON_LAPTOP
        exit
fi


if ( [ "`/bin/ls /root/FIREWALL-BUCKET:* 2>/dev/null`" = "" ] )
then
        auth_bucket="authip-adt-allowed-`/bin/echo ${ip} | /bin/sed 's/\./-/g'`"
        /bin/touch /root/FIREWALL-BUCKET:${auth_bucket}
else
        auth_bucket="`/bin/ls /root/FIREWALL-BUCKET:* | /usr/bin/awk -F':' '{print $NF}'  2>/dev/null`"
fi

${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh "${auth_bucket}"

if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${auth_bucket}/FIREWALL-EVENT`" != "" ] )
then
        ${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${auth_bucket}/FIREWALL-EVENT ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}
fi

if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/FIREWALL-EVENT ] || [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/PRIME_FIREWALL ] )
then
        if ( [ -f  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/FIREWALL-EVENT ] )
        then
                /bin/rm  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/FIREWALL-EVENT 
        fi

        if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/PRIME_FIREWALL ] )
        then
                /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/PRIME_FIREWALL
        fi

        if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${auth_bucket}/FIREWALL-EVENT`" != "" ] )
        then
                ${BUILD_HOME}/providerscripts/datastore/DeleteFromDatastore.sh ${auth_bucket}/FIREWALL-EVENT 
        fi

        if ( [ "`${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh ${auth_bucket}/authorised-ips.dat`" != "" ] )
        then
                ${BUILD_HOME}/providerscripts/datastore/GetFromDatastore.sh ${auth_bucket}/authorised-ips.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat  
        fi

        if ( [ "${laptop_ip}" = "" ] )
        then
                if ( [ -f ${BUILD_HOME}/runtimedata/LAPTOPIP:* ] )
                then
                        laptop_ip="`/bin/ls ${BUILD_HOME}/runtimedata/LAPTOPIP:* | /usr/bin/awk -F':' '{print $NF}'  2>/dev/null`"
                fi
        fi 

        if ( [ "${laptop_ip}" != "" ] )
        then
                if ( [ "${laptop_ip}" != "BYPASS" ] )
                then

                        if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips ] )
                        then
                                /bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips
                        fi

                        /bin/echo "${laptop_ip}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat
                        /usr/bin/uniq ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat.$$
                        /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat
                        /bin/mv ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat.$$ ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat

                        count="0"
                        while ( [ "`${BUILD_HOME}/providerscripts/datastore/ListDatastore.sh ${auth_bucket}`" = "" ] && [ "${count}" -lt "5" ] )
                        do
                                ${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh ${auth_bucket}
                                count="`/usr/bin/expr ${count} + 1`"
                        done

                        if ( [ ! -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat ] )
                        then    
                                /bin/echo "${laptop_ip}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat
                        fi

                        ${BUILD_HOME}/providerscripts/datastore/PutToDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat ${auth_bucket} "no"
                fi
        fi

        ips="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat | /bin/tr '\n' ' '`"

        if ( [ "${ips}" != "" ] )
        then
                updated="0"

                for ip in ${ips}
                do
                        if ( [ "`/bin/grep ${ip} /etc/ssh/sshd_config`" = "" ] )
                        then
                                /bin/echo "AllowUsers ${BUILDMACHINE_USER}@${ip}" >> /etc/ssh/sshd_config
                                updated="1"
                        fi
                done

                if ( [ "${updated}" = "1" ] )
                then
                        /bin/sh ${BUILD_HOME}/helperscripts/RunServiceCommand.sh ssh restart
                fi
                firewall=""
                if ( [ "`/bin/grep "^FIREWALL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $2}'`" = "ufw" ] )
                then
                        firewall="ufw"
                elif ( [ "`/bin/grep "^FIREWALL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /usr/bin/awk -F':' '{print $2}'`" = "iptables" ] )
                then
                        firewall="iptables"
                fi

                #Add any new IP addresses that we need to add in response to a "FIREWALL-EVENT"

                if ( [ "${firewall}" = "ufw" ] )
                then
                        /usr/bin/yes | /usr/sbin/ufw reset
                        /usr/sbin/ufw default deny incoming
                        /usr/sbin/ufw default allow outgoing

                        buildmachine_ssh_port="`/bin/ls ${BUILD_HOME}/runtimedata/BUILDMACHINEPORT:* | /usr/bin/awk -F':' '{print $NF}'`"

                        if ( [ "${buildmachine_ssh_port}" = "" ] )
                        then
                                buildmachine_ssh_port="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SSH_PORT`"
                        fi

                        if ( [ "${buildmachine_ssh_port}" = "" ] )
                        then
                                for ip in ${ips}
                                do
                                        /usr/sbin/ufw allow from ${ip}
                                done       
                        else
                                for ip in ${ips}
                                do
                                        /usr/sbin/ufw allow from ${ip} proto tcp to any port ${buildmachine_ssh_port}
                                done
                        fi
                        /usr/bin/yes | /usr/sbin/ufw enable
                elif ( [ "${firewall}" = "iptables" ] )
                then
                        /usr/sbin/iptables -F
                        buildmachine_ssh_port="`/bin/ls ${BUILD_HOME}/runtimedata/BUILDMACHINEPORT:* | /usr/bin/awk -F':' '{print $NF}'`"

                        /usr/sbin/iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
                        /usr/sbin/iptables -A INPUT -s `/bin/echo ${ips} | /bin/sed 's/ /,/g'` -p ICMP --icmp-type 8 -j ACCEPT
                        /usr/sbin/iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j DROP
                        /usr/sbin/iptables -I INPUT  -s `/bin/echo ${ips} | /bin/sed 's/ /,/g'` -m state --state NEW,RELATED,ESTABLISHED,NEW -p tcp --dport ${buildmachine_ssh_port} -j ACCEPT
                        /usr/sbin/iptables -A INPUT  -s `/bin/echo ${ips} | /bin/sed 's/ /,/g'` -p icmp -m state --state RELATED,ESTABLISHED,NEW -m icmp --icmp-type 8 -j ACCEPT
                        /usr/sbin/iptables -A INPUT -i lo -j ACCEPT
                        /usr/sbin/iptables -A OUTPUT -o lo -j ACCEPT
                        /usr/sbin/iptables -P INPUT DROP
                        /usr/sbin/iptables -P FORWARD DROP
                        /usr/sbin/iptables -P OUTPUT ACCEPT
                        /usr/sbin/ip6tables -P INPUT DROP
                        /usr/sbin/ip6tables -P FORWARD DROP
                        /usr/sbin/ip6tables -P OUTPUT DROP
                        /usr/sbin/ip6tables -A INPUT -i lo -j ACCEPT
                        /usr/sbin/ip6tables -A OUTPUT -o lo -j ACCEPT
                        /usr/sbin/iptables-save > /etc/iptables/rules.v4
                        /usr/sbin/ip6tables-save > /etc/iptables/rules.v6
                fi
        fi

        #Remove any existing IP addresses that we need to remove in response to a "FIREWALL-EVENT"
        authorised_ips="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat`"
        /usr/bin/sort -u ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat  > /tmp/authorised-ips.dat && /bin/mv /tmp/authorised-ips.dat  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat

        if ( [ "${firewall}" = "ufw" ] )
        then
                live_ips="`/usr/sbin/ufw status |  /bin/grep -Eo "[^^][0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}" | /bin/sed 's/ //g' | /usr/bin/sort -u`"
                for ip in ${live_ips}
                do
                        if ( [ "`/bin/echo "${authorised_ips}" | /bin/grep "${ip}"`" = "" ] )
                        then
                                rule_no="`/usr/sbin/ufw status numbered | /bin/grep ${ip} | /bin/grep -Po '\[\K[^]]*' | /bin/sed 's/ //g'`"
                                if ( [ "${rule_no}" != "" ] )
                                then
                                        /usr/sbin/ufw delete ${rule_no}
                                fi
                        fi
                done
        elif ( [ "${firewall}" = "iptables" ] )
        then
                live_ips="`/usr/sbin/iptables --list-rules |  /bin/grep -Eo "[^^][0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}" | /bin/sed 's/ //g' | /usr/bin/sort -u`"
                for ip in ${live_ips}
                do
                        if ( [ "`/bin/echo "${authorised_ips}" | /bin/grep "${ip}"`" = "" ] )
                        then
                                /usr/sbin/iptables -D INPUT -s ${ip} -p ICMP --icmp-type 8 -j ACCEPT
                                /usr/sbin/iptables -D INPUT  -s ${ip} -m state --state NEW,RELATED,ESTABLISHED,NEW -p tcp --dport ${buildmachine_ssh_port} -j ACCEPT
                                /usr/sbin/iptables -D INPUT  -s ${ip} -p icmp -m state --state RELATED,ESTABLISHED,NEW -m icmp --icmp-type 8 -j ACCEPT
                        fi
                done
        fi

        if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat.$$ ] && [ "`/usr/bin/diff ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat.$$ ${BUILD_HOME}/runtimedata/${CLOUDHOST}/ips/authorised-ips.dat`" != "" ] )
        then
                /bin/cp ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ips/authorised-ips.dat.$$
        fi
fi
