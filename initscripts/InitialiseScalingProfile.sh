

status () {
        /bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        /bin/echo "${0}: ${1}" >> /dev/fd/4
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
PRODUCTION="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PRODUCTION`"
DEVELOPMENT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DEVELOPMENT`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"
NUMBER_WS="`${BUILD_HOME}/helperscripts/GetVariableValue.sh NUMBER_WS`"

if ( [ "${PRODUCTION}" = "1" ] && [ "${DEVELOPMENT}" = "0" ] )
then
  if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:* ] )
  then
    /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:*
  fi
  status ""
  status "#############################################################"
  status "Setting scaling value for number of webservers to ${NUMBER_WS}"
  status "#############################################################"
  status ""
  
  /bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:${NUMBER_WS}
  ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:${NUMBER_WS}
 	if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
	then
   status ""
   status "Press <enter> to accept these values"
		  status ""
    read x
  	fi

fi

