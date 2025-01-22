
${DATABASE_INSTALLATION_TYPE}
${DBaaS_HOSTNAME}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}
${DBaaS_DBNAME}" >  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}
${DBaaS_PASSWORD}" >>  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}
${DBaaS_USERNAME}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}
${BUILD_HOME}
${CLOUDHOST}
${BUILD_IDENTIFIER}


if ( [ "${DATABASE_INSTALLATION_TYPE}" = "DBaaS" ] )
then
        /bin/echo "${DBaaS_HOSTNAME}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/DBaaS_HOSTNAME
        /bin/echo "${DBaaS_DBNAME}" >  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred
        /bin/echo "${DBaaS_PASSWORD}" >>  ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred
        /bin/echo "${DBaaS_USERNAME}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred
else
    rnd="n`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-8 | /usr/bin/tr '[:upper:]' '[:lower:]'`n"
    rnd1="p`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-8 | /usr/bin/tr '[:upper:]' '[:lower:]'`p"
    rnd2="u`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-8 | /usr/bin/tr '[:upper:]' '[:lower:]'`u"

    /bin/echo "${rnd}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred
    /bin/echo "${rnd1}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred
    /bin/echo "${rnd2}" >> ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred
fi

${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/db_cred credentials/db_cred
