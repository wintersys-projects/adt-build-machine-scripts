BUILD_HOME="`/bin/cat /home/buildhome.dat`"

cloudhost="${1}"
build_identifier="${2}"

if ( [ "${cloudhost}" = "" ] )
then
        CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
else
        CLOUDHOST="${cloudhost}"
fi

if ( [ "${build_identifier}" = "" ] )
then
        BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
else
        BUILD_IDENTIFIER="${build_identifier}"
fi

if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/application_credentials.dat ] )
then
        /bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/application_credentials.dat 
else
        /bin/echo "Couldn't find any credentials for your application, sorry"
fi
