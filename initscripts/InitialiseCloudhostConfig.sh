
#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This will initialise the configuration files for the cloudhost
# provider's cli tool (doctl,exo,linode-cli or vultr-cli) that you are using. 
# Templates are held in the "${BUILD_HOME}/initscripts/configfiles" subdirectory
##################################################################################
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

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
TOKEN="`${BUILD_HOME}/helperscripts/GetVariableValue.sh TOKEN`"
CLOUDHOST_ACCOUNT_ID="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST_ACCOUNT_ID`"
REGION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh REGION`"
ACCESS_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh ACCESS_KEY`"
SECRET_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh SECRET_KEY`"
DNS_SECURITY_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DNS_SECURITY_KEY`"

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
	if ( [ -f ${BUILD_HOME}/.config/doctl/config.yaml ] )
	then
		/bin/rm ${BUILD_HOME}/.config/doctl/config.yaml
	fi

	status "Configuring Digital Ocean CLI tool"

	if ( [ ! -d ${BUILD_HOME}/.config/doctl ] )
	then
		/bin/mkdir -p ${BUILD_HOME}/.config/doctl
	fi

	/bin/cp ${BUILD_HOME}/initscripts/configfiles/digitalocean/digitalocean.tmpl ${BUILD_HOME}/.config/doctl/config.yaml

	if ( [ "${TOKEN}" != "" ] )
	then
		/bin/sed -i "s/XXXXTOKENXXXX/${TOKEN}/" ${BUILD_HOME}/.config/doctl/config.yaml
	else 
		status "Couldn't find your digital ocean account personal access token in your template, will have to exit"
		/bin/touch /tmp/END_IT_ALL
	fi

	if ( [ ! -d /root/.config/doctl ] )
	then
		/bin/mkdir -p /root/.config/doctl
	fi

	/bin/echo "${TOKEN}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/TOKEN
	/bin/chmod 700 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/TOKEN

	/bin/cp ${BUILD_HOME}/.config/doctl/config.yaml /root/.config/doctl/config.yaml
	/bin/chown root:root ${BUILD_HOME}/.config/doctl/config.yaml /root/.config/doctl/config.yaml
	/bin/chmod 400 ${BUILD_HOME}/.config/doctl/config.yaml /root/.config/doctl/config.yaml

	/bin/cp ${BUILD_HOME}/.config/doctl/config.yaml ${BUILD_HOME}/.config/doctl/dns-do-config.yaml
	/bin/cp ${BUILD_HOME}/.config/doctl/config.yaml /root/.config/doctl/dns-do-config.yaml
	/bin/chown root:root ${BUILD_HOME}/.config/doctl/dns-do-config.yaml /root/.config/doctl/dns-do-config.yaml
	/bin/chmod 400 ${BUILD_HOME}/.config/doctl/dns-do-config.yaml /root/.config/doctl/dns-do-config.yaml

	/bin/sed -i "s/^access-token.*/access-token: ${DNS_SECURITY_KEY}/" ${BUILD_HOME}/.config/doctl/dns-do-config.yaml
	/bin/sed -i "s/^access-token.*/access-token: ${DNS_SECURITY_KEY}/" /root/.config/doctl/dns-do-config.yaml

	if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" = "0" ] )
	then
		/usr/local/bin/doctl balance get >&3
	else
		/usr/local/bin/doctl balance get
	fi

	if ( [ "$?" != "0" ] )
	then
		status "Couldn't get the Digitalocean CLI tool to work. Is your personal access token valid in your template?"
		/bin/touch /tmp/END_IT_ALL
	fi 
fi

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
	if ( [ -f ${BUILD_HOME}/.exoscale.toml ] )
	then
		/bin/rm ${BUILD_HOME}/.exoscale.toml
	fi

	status "Configuring Exoscale CLI tool"

	/bin/cp ${BUILD_HOME}/initscripts/configfiles/exoscale/exoscale.tmpl  ${BUILD_HOME}/.exoscale.toml

	if ( [ "${CLOUDHOST_ACCOUNT_ID}" != "" ] )
	then
		/bin/sed -i "s/XXXXCLOUDEMAILADDRESSXXXX/${CLOUDHOST_ACCOUNT_ID}/" ${BUILD_HOME}/.exoscale.toml
	else 
		status "Couldn't find your exoscale cloud email address in your template, will have to exit"
		/bin/touch /tmp/END_IT_ALL
	fi

	if ( [ "${REGION}" != "" ] )
	then
		/bin/sed -i "s/XXXXREGIONXXXX/${REGION}/" ${BUILD_HOME}/.exoscale.toml
	else 
		status "Couldn't find your region in your template, will have to exit"
		/bin/touch /tmp/END_IT_ALL
	fi

	if ( [ "${ACCESS_KEY}" != "" ] )
	then 
		/bin/sed -i "s/XXXXACCESSKEYXXXX/${ACCESS_KEY}/" ${BUILD_HOME}/.exoscale.toml
		/bin/echo "${ACCESS_KEY}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ACCESS_KEY
	else 
		status "Couldn't find your access key in your template, will have to exit"
		/bin/touch /tmp/END_IT_ALL
	fi

	if ( [ "${SECRET_KEY}" != "" ] )
	then
		/bin/sed -i "s/XXXXSECRETKEYXXXX/${SECRET_KEY}/" ${BUILD_HOME}/.exoscale.toml
		/bin/echo "${SECRET_KEY}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/SECRET_KEY
	else 
		status "Couldn't find your secret key in your template, will have to exit"
		/bin/touch /tmp/END_IT_ALL
	fi

	if ( [ ! -d /root/.config/exoscale ] )
	then
		/bin/mkdir -p /root/.config/exoscale
	fi

	/bin/cp ${BUILD_HOME}/.exoscale.toml /root/.config/exoscale/exoscale.toml
	/bin/chown root:root ${BUILD_HOME}/.exoscale.toml /root/.config/exoscale/exoscale.toml
	/bin/chmod 400 ${BUILD_HOME}/.exoscale.toml /root/.config/exoscale/exoscale.toml

	/bin/cp ${BUILD_HOME}/.exoscale.toml ${BUILD_HOME}/.dns-exoscale.toml
    /bin/cp /root/.config/exoscale/exoscale.toml /root/.config/exoscale/dns-exoscale.toml

    DNS_ACCESS_KEY="`/bin/echo ${DNS_SECURITY_KEY} | /usr/bin/awk -F':' '{print $1}'`"
    DNS_SECRET_KEY="`/bin/echo ${DNS_SECURITY_KEY} | /usr/bin/awk -F':' '{print $2}'`"

    /bin/sed -i 's/key.*/key = "'${DNS_ACCESS_KEY}'"/' ${BUILD_HOME}/.dns-exoscale.toml
    /bin/sed -i 's/secret.*/secret = "'${DNS_SECRET_KEY}'"/' ${BUILD_HOME}/.dns-exoscale.toml
    /bin/sed -i 's/key.*/key = "'${DNS_ACCESS_KEY}'"/' /root/.config/exoscale/dns-exoscale.toml
    /bin/sed -i 's/secret.*/secret = "'${DNS_SECRET_KEY}'"/' /root/.config/exoscale/dns-exoscale.toml

	if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" = "0" ] )
	then
		/usr/bin/exo status >&3
	else
		/usr/bin/exo status
	fi

	if ( [ "$?" != "0" ] )
	then
		status "Couldn't get the Exoscale CLI tool to work. Is are your API access keys valid in your template?"
		/bin/touch /tmp/END_IT_ALL
	fi 
fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then
	if ( [ -f ${BUILD_HOME}/.linode-cli ] )
	then
		/bin/rm ${BUILD_HOME}/.linode-cli
	fi

	status "Configuring Linode CLI tool"

	/bin/cp ${BUILD_HOME}/initscripts/configfiles/linode/linode-cli.tmpl  ${BUILD_HOME}/.linode-cli

	if ( [ "${CLOUDHOST_ACCOUNT_ID}" != "" ] )
	then
		/bin/sed -i "s/XXXXLINODEACCOUNTUSERNAMEXXXX/${CLOUDHOST_ACCOUNT_ID}/" ${BUILD_HOME}/.linode-cli
	else 
		status "Couldn't find your linode account username in your template, will have to exit"
		/bin/touch /tmp/END_IT_ALL
	fi

	if ( [ "${TOKEN}" != "" ] )
	then
		/bin/sed -i "s/XXXXTOKENXXXX/${TOKEN}/" ${BUILD_HOME}/.linode-cli
	else 
		status "Couldn't find your linode account personal access token in your template, will have to exit"
		/bin/touch /tmp/END_IT_ALL
	fi

	if ( [ "${REGION}" != "" ] )
	then
		/bin/sed -i "s/XXXXREGIONXXXX/${REGION}/" ${BUILD_HOME}/.linode-cli
	else 
		status "Couldn't find your region id in your template, will have to exit"
		/bin/touch /tmp/END_IT_ALL
	fi

	if ( [ ! -d /root/.config ] )
	then
		/bin/mkdir /root/.config
	fi

	/bin/echo "${TOKEN}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/TOKEN
	/bin/chmod 700 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/TOKEN

	/bin/cp  ${BUILD_HOME}/.linode-cli /root/.config/linode-cli
	/bin/chown root:root /root/.config/linode-cli ${BUILD_HOME}/.linode-cli
	/bin/chmod 400 /root/.config/linode-cli ${BUILD_HOME}/.linode-cli

	/bin/cp ${BUILD_HOME}/.linode-cli ${BUILD_HOME}/.dns-linode-cli
	/bin/cp /root/.config/linode-cli /root/.config/dns-linode-cli

	/bin/sed -i "s/^token.*/token = ${DNS_SECURITY_KEY}/" ${BUILD_HOME}/.dns-linode-cli
	/bin/sed -i "s/^token.*/token = ${DNS_SECURITY_KEY}/" /root/.config/dns-linode-cli

	if ( [ -d /root/snap/linode-cli ] )
	then
		if ( [ ! -d /root/snap/linode-cli/current/.config ] )
		then
			/bin/mkdir -p /root/snap/linode-cli/current/.config
		fi
		
		/bin/cp /root/.config/dns-linode-cli /root/snap/linode-cli/current/.config/linode-cli
		/bin/cp /root/.config/dns-linode-cli /root/snap/linode-cli/current/.config/dns-linode-cli
	fi

	if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" = "0" ] )
	then
		/usr/local/bin/linode-cli account view >/dev/null 2>/dev/null >&3
	else
		/usr/local/bin/linode-cli account view >/dev/null 2>/dev/null
	fi

	if ( [ "$?" != "0" ] )
	then
		status "Couldn't get the Linode CLI tool to work. Is your personal access token valid in your template?"
		/bin/touch /tmp/END_IT_ALL
	fi 
	/usr/local/bin/linode-cli region-table >/dev/null 2>/dev/null >&3
fi

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
	if ( [ "${TOKEN}" != "" ] )
	then
		/bin/echo ${TOKEN} > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/TOKEN
		/bin/echo "api-key: ${TOKEN}" > ${BUILD_HOME}/.vultr-cli.yaml
		/bin/echo "api-key: ${TOKEN}" > /root/.vultr-cli.yaml
		/bin/chown root:root ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/TOKEN ${BUILD_HOME}/.vultr-cli.yaml /root/.vultr-cli.yaml
		/bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/TOKEN ${BUILD_HOME}/.vultr-cli.yaml /root/.vultr-cli.yaml
                
		/bin/echo ${DNS_SECURITY_KEY} > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DNS_TOKEN
        /bin/echo "api-key: ${DNS_SECURITY_KEY}" > ${BUILD_HOME}/.dns-vultr-cli.yaml
        /bin/echo "api-key: ${DNS_SECURITY_KEY}" > /root/.dns-vultr-cli.yaml
        /bin/chown root:root ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DNS_TOKEN ${BUILD_HOME}/.dns-vultr-cli.yaml /root/.dns-vultr-cli.yaml
        /bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DNS_TOKEN ${BUILD_HOME}/.dns-vultr-cli.yaml /root/.dns-vultr-cli.yaml
	else
		status "Couldn't find your vultr API key from your template - will have to exit...."
		/bin/touch /tmp/END_IT_ALL
	fi

	if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" = "0" ] )
	then	
		/usr/bin/vultr account info>&3
	else
		/usr/bin/vultr account info
	fi

	if ( [ "$?" != "0" ] )
	then
		status "Couldn't get the Vultr CLI tool to work. Is your personal access token valid in your template?"
		/bin/touch /tmp/END_IT_ALL
	fi 
fi

if ( [ ! -d ${BUILD_HOME}/runtimedata ] )
then
	/bin/mkdir ${BUILD_HOME}/runtimedata
fi

/bin/echo "${CLOUDHOST}" > ${BUILD_HOME}/runtimedata/BUILD_MACHINE_CLOUDHOST
