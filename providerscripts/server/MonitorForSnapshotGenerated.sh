

rnd="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER | /usr/bin/fold -w 4 | /usr/bin/head -n 1`"
prefixes="as- ws- db-"

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
  if ( [ "`/bin/echo ${prefixes} | /bin/sed 's/ //g'`" != "" ] )
  then
        for prefix in ${prefixes}
        do
                result="`/usr/bin/exo compute instance snapshot list -O json | /usr/bin/jq -r '.[] | select ( .instance | contains ("'${prefix}${REGION}-${BUILD_IDENTIFIER}-${rnd}'")).state'`" 
                if ( [ "${result}" = "exported" ] )
                then
                        prefixes="`/bin/echo ${prefixes} | /bin/sed "s/${prefix}//g"`"
                fi
        done
  fi
  status "All snapshots generated"
fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then
  for prefix in ${prefixes}
  do
    result="`/usr/local/bin/linode-cli images list --json | /usr/bin/jq -r '.[] | select ( .label | contains ("'${prefix}${REGION}-${BUILD_IDENTIFIER}-${rnd}'")).status'`" 
    if ( [ "${result}" = "available" ] )
    then
      prefixes="`/bin/echo ${prefixes} | /bin/sed "s/${prefix}//g"`"
    fi
  done
  status "All snapshots generated"
fi
