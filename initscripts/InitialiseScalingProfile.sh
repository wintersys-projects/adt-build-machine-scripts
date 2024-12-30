if ( [ "${PRODUCTION}" = "1" ] && [ "${DEVELOPMENT}" = "0" ] )
then
  if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:* ] )
  then
    /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:*
  fi
  /bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:${NUMBER_WS}
  ${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:${NUMBER_WS}
fi

