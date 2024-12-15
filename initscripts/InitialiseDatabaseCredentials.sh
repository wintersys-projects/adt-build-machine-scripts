if ( [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
then
    DBaaS_DBNAME="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DBaaSDBNAME'`"
    DBaaS_PASSWORD="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DBaaSPASSWORD'`"
    DBaaS_USERNAME="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DBaaSUSERNAME'`"

    /bin/echo "${DBaaS_DBNAME}" >>  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/shit
    /bin/echo "${DBaaS_PASSWORD}" >>  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/shit
    /bin/echo "${DBaaS_USERNAME}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/shit

else
    rnd="n`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-8 | /usr/bin/tr '[:upper:]' '[:lower:]'`n"
    rnd1="p`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-8 | /usr/bin/tr '[:upper:]' '[:lower:]'`p"
    rnd2="u`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-8 | /usr/bin/tr '[:upper:]' '[:lower:]'`u"

    /bin/echo "${rnd}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/shit
    /bin/echo "${rnd1}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/shit
    /bin/echo "${rnd2}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/shit

fi

${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${WEBSITE_URL} ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/shit credentials/shit 
