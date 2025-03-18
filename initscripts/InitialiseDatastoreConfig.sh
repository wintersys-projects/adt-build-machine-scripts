#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This will initialise the s3cmd configuration file for your datastore provider
# that you are using. Template is held in the "configfiles"
# subdirectory
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
        /bin/echo "${script_name}: ${1}" >> /dev/fd/4  2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
S3_ACCESS_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_ACCESS_KEY`"
S3_SECRET_KEY="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_SECRET_KEY`"
S3_LOCATION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_LOCATION`"
S3_HOST_BASE="`${BUILD_HOME}/helperscripts/GetVariableValue.sh S3_HOST_BASE`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
SERVER_USER="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER`"

status ""
status "##############################"
status "Configuring datastore tools..."
status "##############################"

if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s3cmd`" != "" ] )
then
  if ( [ -f ${BUILD_HOME}/.s3cfg ] )
  then
    /bin/rm ${BUILD_HOME}/.s3cfg
  fi
  
  /bin/cp ${BUILD_HOME}/initscripts/configfiles/datastore/s3-cfg.tmpl  ${BUILD_HOME}/.s3cfg

  if ( [ "${S3_ACCESS_KEY}" != "" ] )
  then
        /bin/sed -i "s/XXXXACCESSKEYXXXX/${S3_ACCESS_KEY}/" ${BUILD_HOME}/.s3cfg
  else 
        status "Couldn't find the access key for your datastore, can't go on without it, will have to exit"
        /usr/bin/kill -9 $PPID  
fi

  if ( [ "${S3_SECRET_KEY}" != "" ] )
  then
        /bin/sed -i "s/XXXXSECRETKEYXXXX/${S3_SECRET_KEY}/" ${BUILD_HOME}/.s3cfg
  else 
        status "Couldn't find the secret key for your datastore, can't go on without it, will have to exit"
        /usr/bin/kill -9 $PPID  
  fi

  if ( [ "${S3_LOCATION}" != "" ] )
  then
    /bin/sed -i "s/XXXXLOCATIONXXXX/${S3_LOCATION}/" ${BUILD_HOME}/.s3cfg
  else 
    status "Couldn't find the secret key for your datastore, can't go on without it, will have to exit"  
    /usr/bin/kill -9 $PPID  
  fi

  if ( [ "${S3_HOST_BASE}" != "" ] )
  then
       host_base="`/bin/echo ${S3_HOST_BASE} | /usr/bin/awk -F':' '{print $1}'`"
       /bin/sed -i "s/XXXXHOSTBASEXXXX/${host_base}/" ${BUILD_HOME}/.s3cfg
  else 
        status "Couldn't find the hostbase parameter for your datastore, can't go on without it, will have to exit"
        /usr/bin/kill -9 $PPID  
fi
  
  if ( [ -f /root/.s3cfg ] )
  then
        /bin/rm /root/.s3cfg
  fi
  
  /bin/cp ${BUILD_HOME}/.s3cfg /root/.s3cfg
fi

if ( [ "`/bin/grep "^DATASTORETOOL:*" ${BUILD_HOME}/builddescriptors/buildstyles.dat | /bin/grep s5cmd`" != "" ] )
then
  if ( [ -f ${BUILD_HOME}/.s5cfg ] )
  then
        /bin/rm ${BUILD_HOME}/.s5cfg
  fi
  
  if ( [ "${S3_ACCESS_KEY}" != "" ] )
  then
        /bin/echo "[default]" > ${BUILD_HOME}/.s5cfg 
        /bin/echo "aws_access_key_id = ${S3_ACCESS_KEY}" >> ${BUILD_HOME}/.s5cfg
  else 
        status "Couldn't find the access key for your datastore, can't go on without it, will have to exit"
        /usr/bin/kill -9 $PPID  
  fi

  if ( [ "${S3_SECRET_KEY}" != "" ] )
  then
        /bin/echo "aws_secret_access_key = ${S3_SECRET_KEY}" >> ${BUILD_HOME}/.s5cfg
  else 
        status "Couldn't find the secret key for your datastore, can't go on without it, will have to exit"
        /usr/bin/kill -9 $PPID  
  fi

  if ( [ "${S3_HOST_BASE}" != "" ] )
  then
        host_base="`/bin/echo ${S3_HOST_BASE} | /usr/bin/awk -F':' '{print $1}'`"
        /bin/echo "host_base = ${host_base}" >> ${BUILD_HOME}/.s5cfg
        /bin/echo "alias s5cmd='/usr/bin/s5cmd --credentials-file /root/.s5cfg --endpoint-url https://${host_base}'" >> /root/.bashrc
  else 
        status "Couldn't find the hostbase parameter for your datastore, can't go on without it, will have to exit"
        /usr/bin/kill -9 $PPID  
  fi

  if ( [ -f /root/.s5cfg ] )
  then
        /bin/rm /root/.s5cfg
  fi

  /bin/cp ${BUILD_HOME}/.s5cfg /root/.s5cfg
fi

${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh "1$$agile" 3>&1 2>/dev/null
${BUILD_HOME}/providerscripts/datastore/DeleteDatastore.sh "1$$agile" 3>&1 2>/dev/null

if ( [ "$?" != "0" ] )
then
        status "I can't access your datastore, it isn't possible to continue. Please check the following settings in the template you are using:"
        status "S3_ACCESS_KEY,S3_SECRET_KEY,S3_LOCATION and S3_HOST_BASE"
        /usr/bin/kill -9 $PPID
fi

website_bucket="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`"
identifier="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1 | /usr/bin/tr '[:upper:]' '[:lower:]'`"

for bucket in `${BUILD_HOME}/providerscripts/datastore/ListFromDatastore.sh | /bin/grep "${website_bucket}-config"  | /bin/grep -v "${identifier}" | /usr/bin/awk '{print  $NF}' | /bin/sed 's,s3://,,'`
do
        ${BUILD_HOME}/providerscripts/datastore/DeleteFromDatastore.sh ${bucket}
        ${BUILD_HOME}/providerscripts/datastore/DeleteDatastore.sh ${bucket}
done

${BUILD_HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh 

status "Creating a new configuration bucket for build (${BUILD_IDENTIFIER})"
${BUILD_HOME}/providerscripts/datastore/configwrapper/MountConfigDatastore.sh 
if ( [ "$?" = "0" ] )
then
        status "New configuration bucket is located at: (s3://${website_bucket}-config-${identifier}) for you"
fi
