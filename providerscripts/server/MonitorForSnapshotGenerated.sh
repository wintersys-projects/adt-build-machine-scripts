

rnd="`/bin/cat ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/credentials/SERVERUSER | /usr/bin/fold -w 4 | /usr/bin/head -n 1`"
prefixes="as- ws- db-"


if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
  creation_time="`/usr/local/bin/doctl compute snapshot list -o json | /usr/bin/jq -r '.[] | select ( .name | contains ("'${REGION}-${BUILD_IDENTIFIER}-${rnd}'")).created_at' | /usr/bin/head -1`"
  creation_time_seconds="`/usr/bin/date -d "${creation_time}" +"%s"`"
  current_time_seconds="`/usr/bin/date  +"%s"`"
  
  while ( [ "`/usr/bin/expr ${current_time_seconds} - ${creation_time_seconds}`" -lt "120" ] )
  do
          /bin/sleep 10
          current_time_seconds="`/usr/bin/date  +"%s"`"
  done
fi

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
  while ( [ "`/bin/echo ${prefixes} | /bin/sed 's/ //g'`" != "" ] )
  do
    for prefix in ${prefixes}
    do
      result="`/usr/bin/exo compute instance snapshot list -O json | /usr/bin/jq -r '.[] | select ( .instance | contains ("'${prefix}${REGION}-${BUILD_IDENTIFIER}-${rnd}'")).state'`" 
      if ( [ "${result}" = "exported" ] )
      then
        prefixes="`/bin/echo ${prefixes} | /bin/sed "s/${prefix}//g"`"
      fi
    done
  done
  status "All snapshots generated"
fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then
  while ( [ "`/bin/echo ${prefixes} | /bin/sed 's/ //g'`" != "" ] )
  do
    for prefix in ${prefixes}
    do
      result="`/usr/local/bin/linode-cli images list --json | /usr/bin/jq -r '.[] | select ( .label | contains ("'${prefix}${REGION}-${BUILD_IDENTIFIER}-${rnd}'")).status'`" 
      if ( [ "${result}" = "available" ] )
      then
        prefixes="`/bin/echo ${prefixes} | /bin/sed "s/${prefix}//g"`"
      fi
    done
  done
  status "All snapshots generated"
fi

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
  while ( [ "`/bin/echo ${prefixes} | /bin/sed 's/ //g'`" != "" ] )
  do
    for prefix in ${prefixes}
    do
      result="`/usr/bin/vultr snapshot list -o json | /usr/bin/jq -r '.snapshots[] | select ( .description | contains ("'${prefix}${REGION}-${BUILD_IDENTIFIER}-${rnd}'")).status'`" 
      if ( [ "${result}" = "complete" ] )
      then
        prefixes="`/bin/echo ${prefixes} | /bin/sed "s/${prefix}//g"`"
      fi
    done
  done
  status "All snapshots generated"
fi

