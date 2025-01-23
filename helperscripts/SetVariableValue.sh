BUILD_HOME="`/bin/cat /home/buildhome.dat`" 
CLOUDHOST="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_CLOUDHOST`"
BUILD_IDENTIFIER="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER`"
BUILD_ENVIRONMENT="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/build_environment"

if ( [ "${1}" != "" ] )
then
  key-value="${1}"
fi

key="`/bin/echo ${key-value} | /usr/bin/awk -F'=' '{print $1}'`"

/bin/sed -i "s/${key}=.*/${key-value}/" ${BUILD_ENVIRONMENT}
