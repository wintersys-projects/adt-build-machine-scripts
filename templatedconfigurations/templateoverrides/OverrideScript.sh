#!/bin/sh

################################################################################################
# This script is a preparatory script for your build machine. Your build machine is the machine
# that is responsible for initiating the build process of your server fleet. 
# As a minimum you will need a copy of this script with the following dynamic or changeable values 
# set:
#
#   BUILDMACHINE_USER
#   BUILDMACHINE_PASSWORD
#   BUILDMACHINE_SSH_PORT
#   LAPTOP_IP
#   SSH
#
# You will then need to pass a copy of the entire script with these values set to the "user data"
# area of the build machine you are provisioning. How to do this will vary by provider.
# Once your build machine is provisioned you can SSH onto it in a way similar to this:
#
#     > ssh -i <ssh-private-key> -p ${BUILDMACHINE_SSH_PORT} ${BUILDMACHINE_USER}@<buildmachineip>
#     > sudo su
#     > password:${BUILDMACHINE_PASSWORD}
#     > cd adt-build-machine-scripts
#
#################################################################################################
export BUILDMACHINE_USER="agile-user"
export BUILDMACHINE_PASSWORD="Hjdhfb34hd£" #Make sure any password you choose is strong enough to pass any strength enforcement rules of your OS (vultr is really strict and a weak password will be a problem) also, do not use the dollar symbol in your password
export BUILDMACHINE_SSH_PORT="1035"
export LAPTOP_IP=""
git_branch="main"

/bin/echo '
#BASE OVERRIDES
export SSH="" #paste your public key here
export SELECTED_TEMPLATE="" #set if using hardcore build
' > /root/Environment.env

#XXXECHOZZZ
#XXXYYYZZZ
#XXXROOTENVZZZ

. /root/Environment.env

#XXXSTACKYYY

#set -x

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

export BUILD_HOME="/home/${BUILDMACHINE_USER}/adt-build-machine-scripts"
/bin/echo ${BUILD_HOME} > /home/buildhome.dat
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

/bin/sh ${BUILD_HOME}/installscripts/InstallFirewall.sh "`/bin/cat /etc/issue | /usr/bin/tr '[:upper:]' '[:lower:]' | /bin/egrep -o '(ubuntu|debian)'`"
${BUILD_HOME}/security/firewall/InitialiseFirewall.sh 


