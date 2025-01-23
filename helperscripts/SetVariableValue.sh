#set -x

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_CLOUDHOST`"
BUILD_IDENTIFIER="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER`"
BUILD_ENVIRONMENT="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/build_environment"

if ( [ "${1}" != "" ] )
then
  keyvalue="${1}"
fi

key="`/bin/echo ${keyvalue} | /usr/bin/awk -F'=' '{print $1}'`"

if ( [ "`/bin/grep "^${key}=" ${BUILD_ENVIRONMENT}`" = "" ] )
then
        /bin/echo "${keyvalue}" >> ${BUILD_ENVIRONMENT}
else
        /bin/sed -i "s/${key}=.*/${keyvalue}/" ${BUILD_ENVIRONMENT}
fi
