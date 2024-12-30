if ( [ "${PRODUCTION}" = "1" ] && [ "${DEVELOPMENT}" = "0" ] )
then
NUMBER_WS

${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh INSTALLEDSUCCESSFULLY INSTALLEDSUCCESSFULLY

fi

