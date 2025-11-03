#!/bin/bash
################################################################################################
# This script is a preparatory script for your build machine. Your build machine is the machine
# that is responsible for initiating the build process of your server fleet. 
# You can use this script as a stack script if you are deploying for Linode. You will then need
# to populate the "UDF" values that the stack script displays for you that you can see below.
# You then use it as you would any other stack script to deploy your build machine
#
# Once your stack script is deployed you connect to it similar to the following:
#
#     > ssh -i <ssh-private-key> -p ${BUILDMACHINE_SSH_PORT} ${BUILDMACHINE_USER}@<buildmachineip>
#     > sudo su
#     > password: ${BUILDMACHINE_PASSWORD}
#     > cd adt-build-machine-scripts
#
#################################################################################################
# <UDF name="SSH" label="SSH Public Key from your laptop" />
# <UDF name="BUILDMACHINE_USER" label="The username for your build machine" />
# <UDF name="BUILDMACHINE_PASSWORD" label="The password for your build machine user" />
# <UDF name="BUILDMACHINE_SSH_PORT" label="The SSH port for your build machine" />
# <UDF name="LAPTOP_IP" label="IP address of your laptop" />
##################################################################################################

#XXXSTACKYYY

#set -x

git_branch="main"

/bin/echo "${BUILDMACHINE_USER}" > /root/buildmachine_user.dat

OUT_FILE="buildmachine-out-`/bin/date | /bin/sed 's/ //g'`"
exec 1>>/root/${OUT_FILE}
ERR_FILE="buildmachine-err-`/bin/date | /bin/sed 's/ //g'`"
exec 2>>/root/${ERR_FILE}

/usr/sbin/adduser --disabled-password --gecos "" ${BUILDMACHINE_USER} 
/bin/sed -i '$ a\ ClientAliveInterval 60\nTCPKeepAlive yes\nClientAliveCountMax 10000' /etc/ssh/sshd_config
/bin/echo ${BUILDMACHINE_USER}:${BUILDMACHINE_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/chpasswd 
 /usr/bin/gpasswd -a ${BUILDMACHINE_USER} sudo 

/bin/mkdir -p /home/${BUILDMACHINE_USER}/.ssh
/bin/echo "${SSH}" >> /home/${BUILDMACHINE_USER}/.ssh/authorized_keys

/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/g' {} +
/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/g' {} +
/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^PermitRootLogin.*/PermitRootLogin no/g' {} +
/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/g' {} +
/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/g' {} +
/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^#KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/g' {} +
/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/g' {} +
/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/g' {} +
/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^AddressFamily.*/AddressFamily inet/g' {} +
/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^#AddressFamily.*/AddressFamily inet/g' {} +


if ( [ "${BUILDMACHINE_SSH_PORT}" = "" ] )
then
	BUILDMACHINE_SSH_PORT="22"
fi

/bin/sed -i "s/^Port.*$/Port ${BUILDMACHINE_SSH_PORT}/g" /etc/ssh/sshd_config
/bin/sed -i "s/^#Port.*$/Port ${BUILDMACHINE_SSH_PORT}/g" /etc/ssh/sshd_config
/bin/echo "AllowUsers ${BUILDMACHINE_USER}@${LAPTOP_IP}" >> /etc/ssh/sshd_config

/usr/bin/apt-get -qq -y update
/usr/bin/apt-get -qq -y install git

cd /home/${BUILDMACHINE_USER}

if ( [ "${INFRASTRUCTURE_REPOSITORY_OWNER}" != "" ] )
then
	/usr/bin/git clone  -b ${git_branch} --single-branch https://github.com/${INFRASTRUCTURE_REPOSITORY_OWNER}/adt-build-machine-scripts.git
else
	/usr/bin/git clone  -b ${git_branch} --single-branch https://github.com/wintersys-projects/adt-build-machine-scripts.git
fi

/usr/bin/find /home/${BUILDMACHINE_USER} -type d -exec chmod 755 {} \;
/usr/bin/find /home/${BUILDMACHINE_USER} -type f -exec chmod 744 {} \;

BUILD_HOME="/home/${BUILDMACHINE_USER}/adt-build-machine-scripts"
/bin/echo ${BUILD_HOME} > /home/buildhome.dat

if ( [ -f ${HOME}/helperscripts/PushInfrastructureScriptsUpdates.sh ] )
then
	/bin/cp ${HOME}/helperscripts/PushInfrastructureScriptsUpdates.sh /usr/sbin/push
	/bin/chmod 755 /usr/bin/push
	/bin/chown root:root /usr/bin/push
fi

/bin/sh ${BUILD_HOME}/helperscripts/RunServiceCommand.sh ssh restart

/bin/sed -i "s/^GITBRANCH:.*/GITBRANCH:${git_branch}/g" ${BUILD_HOME}/builddescriptors/buildstyles.dat
 
if ( [ ! -d ${BUILD_HOME}/runtimedata ] )
then
	/bin/mkdir -p ${BUILD_HOME}/runtimedata
fi
/bin/touch ${BUILD_HOME}/runtimedata/LAPTOPIP:${LAPTOP_IP}
/bin/touch ${BUILD_HOME}/runtimedata/BUILDMACHINEPORT:${BUILDMACHINE_SSH_PORT}

if ( [ "${BUILD_IDENTIFIER}" != "" ] )
then
	/bin/echo ${BUILD_IDENTIFIER} > ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER
fi

#The StackScript capitalises the var names

if ( [ "${DATABASE_DBAAS_INSTALLATION_TYPE}" != "" ] )
then
     export DATABASE_DBaaS_INSTALLATION_TYPE="${DATABASE_DBAAS_INSTALLATION_TYPE}"
     unset DATABASE_DBAAS_INSTALLATION_TYPE
fi

/bin/sh ${BUILD_HOME}/installscripts/InstallFirewall.sh "`/bin/cat /etc/issue | /usr/bin/tr '[:upper:]' '[:lower:]' | /bin/egrep -o '(ubuntu|debian)'`"
${BUILD_HOME}/security/firewall/InitialiseFirewall.sh 
