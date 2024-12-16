BUILD_HOME="`/bin/cat /home/buildhome.dat`" 
CLOUDHOST="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_CLOUDHOST`"
BUILD_IDENTIFIER="`/bin/cat ${BUILD_HOME}/runtimedata/ACTIVE_BUILD_IDENTIFIER`"
BUILD_ENVIRONMENT="${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/build_environment"

if ( [ "${1}" = "" ] )
then
        exit
fi

/bin/grep ${1} ${BUILD_ENVIRONMENT} | /bin/sed 's/"//g' | /usr/bin/awk -F'=' '{print $NF}'
